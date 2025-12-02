#!/bin/bash

set -eu

source_repository=https://${GH_TOKEN}@github.com/${REPO}.git
source_branch=${BRANCH}

typeset -A components

# Accept components path and fallback url as arguments or env
COMPONENTS_JSON_PATH="${1:-${COMPONENTS_JSON_PATH:-.github/deploy/components.json}}"
COMPONENTS_JSON_URL="${2:-${COMPONENTS_JSON_URL:-}}"

if [[ -f "${COMPONENTS_JSON_PATH}" ]]; then
    json_source="${COMPONENTS_JSON_PATH}"
elif [[ -n "${COMPONENTS_JSON_URL}" ]]; then
    wget "${COMPONENTS_JSON_URL}" -O /tmp/components.json
    json_source="/tmp/components.json"
else
    echo "components.json not found at ${COMPONENTS_JSON_PATH} and no URL provided"
    exit 1
fi

while IFS== read -r path repo; do
    components["$path"]="$repo"
done < <(jq -r '.[] | .path + "=" + .repo ' "${json_source}")

for K in "${!components[@]}"; do
    temp_remote=${components[$K]//GH_TOKEN@/${GH_TOKEN}@}
    echo -e "\n${temp_remote}\n"
    # The rest shouldn't need changing.
    temp_repo=$(mktemp -d)
    # shellcheck disable=SC2002
    temp_branch=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8 ; echo '')

    # Checkout the old repository, make it safe and checkout a temp branch
    git clone ${source_repository} "${temp_repo}"
    cd "${temp_repo}"
    git checkout "${source_branch}"
    git remote remove origin
    git checkout -b "${temp_branch}"

    sha1=$(git subtree split --prefix="${K}" 2>/dev/null)
    git reset --hard "${sha1}"
    git remote add remote "${temp_remote}"
    git push -u remote "${temp_branch}":"${source_branch}" --force
    git remote rm remote

    ## Cleanup
    cd /tmp
    rm -rf "${temp_repo}"
done
