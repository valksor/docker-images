#!/bin/bash

set -eu

# shellcheck disable=SC2153  # REPO/BRANCH/GH_TOKEN are provided via the environment
# GH_TOKEN is optional; when set it authenticates the source clone.
if [[ -n "${GH_TOKEN:-}" ]]; then
    source_repository="https://${GH_TOKEN}@github.com/${REPO}.git"
else
    source_repository="https://github.com/${REPO}.git"
fi
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

while IFS='=' read -r path repo; do
    components["$path"]="$repo"
done < <(jq -r '.[] | .path + "=" + .repo ' "${json_source}")

# ALLOWED_ENVS (space-separated env names permitted for NAME@ substitution) is required.
if [[ -z "${ALLOWED_ENVS:-}" ]]; then
    echo "ALLOWED_ENVS is required: space-separated env names allowed for NAME@ substitution" >&2
    exit 1
fi

# Pre-flight: validate and resolve every component URL before touching git, so we
# never force-push some destinations and then abort on a later missing env. Each
# NAME@ placeholder is substituted here once; the split loop reuses the result.
typeset -A resolved
missing=()
denied=()
for K in "${!components[@]}"; do
    repo_url="${components[$K]}"
    while read -r match; do
        [[ -z "$match" ]] && continue
        name="${match%@}"
        # Only names in the ALLOWED_ENVS allowlist may be substituted.
        case " ${ALLOWED_ENVS} " in
            *" ${name} "*) : ;;
            *) denied+=("component '${K}' references \$${name} (not in ALLOWED_ENVS)"); continue ;;
        esac
        if [[ ! -v "$name" || -z "${!name}" ]]; then
            missing+=("component '${K}' requires \$${name}")
            continue
        fi
        repo_url="${repo_url//${name}@/${!name}@}"
    done < <(grep -oE '[A-Za-z_][A-Za-z0-9_]*@' <<< "${components[$K]}" | sort -u)
    resolved["$K"]="$repo_url"
done
if (( ${#denied[@]} + ${#missing[@]} )); then
    echo "Cannot resolve component env placeholders:" >&2
    printf '  - %s\n' "${denied[@]}" "${missing[@]}" >&2
    echo "Add the missing var(s) to the workflow env/secrets." >&2
    exit 1
fi

# Clean up the temp clone even on interrupt (its .git/config holds a live token).
temp_repo=""
# if-form (not &&) so the trap returns 0 — a non-zero trap status would become
# the script's exit code and fail the run even when every split succeeded.
cleanup() { if [[ -n "$temp_repo" ]]; then rm -rf "$temp_repo"; fi; }
trap cleanup EXIT

for K in "${!components[@]}"; do
    temp_remote="${resolved[$K]}"
    # Log the target without the substituted secret (the placeholder form is safe).
    echo -e "\nSplitting '${K}' -> ${components[$K]}\n"
    # The rest shouldn't need changing.
    temp_repo=$(mktemp -d)
    # shellcheck disable=SC2002
    temp_branch=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 8 ; echo '')

    # Checkout the old repository, make it safe and checkout a temp branch
    git clone "${source_repository}" "${temp_repo}"
    cd "${temp_repo}"
    git checkout "${source_branch}"
    git remote remove origin
    git checkout -b "${temp_branch}"

    # 2>/dev/null suppresses subtree's per-commit progress counter (noise, not errors).
    sha1=$(git subtree split --prefix="${K}" 2>/dev/null) \
        || { echo "subtree split failed for '${K}'" >&2; exit 1; }
    [[ -n "$sha1" ]] || { echo "empty subtree SHA for '${K}'" >&2; exit 1; }
    git reset --hard "${sha1}"
    git remote add -- remote "${temp_remote}"
    git push -u remote "${temp_branch}":"${source_branch}" --force
    git remote rm remote

    ## Cleanup
    cd /tmp
    rm -rf "${temp_repo}"
    temp_repo=""
done
