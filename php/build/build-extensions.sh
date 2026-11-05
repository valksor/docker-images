#!/usr/bin/env bash

set -eux

# Use the SAME flags as FrankenPHP
export CFLAGS="$PHP_CFLAGS"
export CPPFLAGS="$PHP_CPPFLAGS"
export LDFLAGS="$PHP_LDFLAGS"
# ccache is installed only by the zts/zts-base builders; other consumers (zts-testing)
# build without it. Probe functionally, not just by name: an orphaned ccache binary
# copied without its shared libraries would pass command -v and then fail at runtime.
CCACHE_AVAILABLE=""
if command -v ccache >/dev/null 2>&1 && ccache --version >/dev/null 2>&1; then
    export PATH="/usr/lib/ccache:$PATH" CCACHE_COMPILERCHECK=content
    ccache -M 20G
    CCACHE_AVAILABLE=1
fi

if [[ ! -f /tmp/extensions.json ]]; then
   echo "Error: extensions.json not found. Terminating script."
   exit 1
fi

LANES=3

mkdir -p /tmp/ext-status /tmp/ext-logs /tmp/ext-scripts

declare -A EXT_SOURCE EXT_CONFIGURE EXT_ENV EXT_REQ EXT_REMOVE EXT_HAS_SCRIPTS EXT_PASS0
enabled_extensions=()

# Pass 1 (serial, apt-locked): read all fields up front — the bodies cd away and must
# not re-read the json cwd-relatively — install the union of req packages in ONE
# apt-get, and defer the union of remove packages to Pass 3.
while IFS= read -r extension; do
    enable=$(jq -r '.["'"${extension}"'"].enable // "false"' /tmp/extensions.json)
    if [[ "${enable}" != "true" ]]; then
        continue
    fi
    enabled_extensions+=("${extension}")
    EXT_SOURCE["${extension}"]=$(jq -r '.["'"${extension}"'"].source' /tmp/extensions.json)
    EXT_CONFIGURE["${extension}"]=$(jq -r '.["'"${extension}"'"].configure // ""' /tmp/extensions.json)
    EXT_ENV["${extension}"]=$(jq -r '.["'"${extension}"'"].env // ""' /tmp/extensions.json)
    EXT_REQ["${extension}"]=$(jq -r '.["'"${extension}"'"].req // ""' /tmp/extensions.json)
    EXT_REMOVE["${extension}"]=$(jq -r '.["'"${extension}"'"].remove // ""' /tmp/extensions.json)
    if jq -e '.["'"${extension}"'"].scripts | type == "array"' /tmp/extensions.json > /dev/null; then
        EXT_HAS_SCRIPTS["${extension}"]=1
        jq -r '.["'"${extension}"'"].scripts[]' /tmp/extensions.json > "/tmp/ext-scripts/${extension}.sh"
        chmod +x "/tmp/ext-scripts/${extension}.sh"
    fi
done < <(jq -r 'keys[]' /tmp/extensions.json)

req_union=""
for req in "${EXT_REQ[@]}"; do
    if [[ -n "${req}" ]]; then
        req_union+="${req}"$'\n'
    fi
done
req_union="$(tr ' ' '\n' <<< "${req_union}" | sed '/^$/d' | sort -u | tr '\n' ' ')"
req_union="${req_union% }"
if [[ -n "${req_union}" ]]; then
    apt-get install -y ${req_union}
fi

remove_union=""
for remove in "${EXT_REMOVE[@]}"; do
    if [[ -n "${remove}" ]]; then
        remove_union+="${remove}"$'\n'
    fi
done
remove_union="$(tr ' ' '\n' <<< "${remove_union}" | sed '/^$/d' | sort -u | tr '\n' ' ')"
remove_union="${remove_union% }"

build_extension() {
    local extension="$1"
    local source_dir="${EXT_SOURCE[${extension}]}"
    local configure_flags="${EXT_CONFIGURE[${extension}]}"
    local env_vars="${EXT_ENV[${extension}]}"
    local JOBS
    local license_dir checkout_dir license_dirs license_source license_candidate license_target
    local license_found composer_license composer_candidate

    set -eux

    cd "${source_dir}"
    phpize

    if [[ -n "${configure_flags}" ]]; then
        if [[ -n "${env_vars}" ]]; then
            env ${env_vars} ./configure ${configure_flags}
        else
            ./configure ${configure_flags}
        fi
    else
        if [[ -n "${env_vars}" ]]; then
            env ${env_vars} ./configure
        else
            ./configure
        fi
    fi

    JOBS="$(( $(nproc) / LANES ))"
    [ "$JOBS" -lt 1 ] && JOBS=1

    if [[ -n "${env_vars}" ]]; then
        env ${env_vars} make -j"${JOBS}"
    else
        make -j"${JOBS}"
    fi
    make install

    license_dir="/usr/local/share/doc/php-ext/${extension}"
    checkout_dir="${source_dir#/tmp/extensions/}"
    checkout_dir="/tmp/extensions/${checkout_dir%%/*}"
    license_dirs=("${source_dir}")
    if [[ "${checkout_dir%/}" != "${source_dir%/}" ]]; then
        license_dirs+=("${checkout_dir}")
    fi
    mkdir --parents "${license_dir}"
    license_found=0
    shopt -s nocaseglob
    for license_source in "${license_dirs[@]}"; do
        for license_candidate in "${license_source}"/LICENSE* "${license_source}"/LICENCE* "${license_source}"/COPYING* "${license_source}"/NOTICE*; do
            if [[ -f "${license_candidate}" ]]; then
                license_target="${license_dir}/$(basename "${license_candidate}")"
                if [[ "${license_source}" == "${checkout_dir}" && -e "${license_target}" ]]; then
                    license_target="${license_dir}/repo-$(basename "${license_candidate}")"
                fi
                cp -v "${license_candidate}" "${license_target}" || exit 1
                license_found=1
            fi
        done
    done
    shopt -u nocaseglob
    if [[ "${license_found}" -eq 0 ]]; then
        composer_license=""
        for composer_candidate in "${source_dir}/composer.json" "${checkout_dir}/composer.json"; do
            if [[ -f "${composer_candidate}" ]]; then
                composer_license="$(jq -r '.license | if type == "string" then . elif type == "array" then join(" OR ") else empty end' "${composer_candidate}")"
                if [[ -n "${composer_license}" ]]; then
                    break
                fi
            fi
        done
        if [[ -n "${composer_license}" ]]; then
            {
                echo "SPDX-License-Identifier: ${composer_license}"
                echo 'Upstream ships no license file; license declared in composer.json'
            } > "${license_dir}/LICENSE-SPDX"
            echo "NOTE: no license file for ${extension}; wrote ${license_dir}/LICENSE-SPDX from composer.json (${composer_license})" >&2
        else
            echo "no license file found for ${extension}" >&2
            exit 1
        fi
    fi

    docker-php-ext-enable ${extension}

    if [[ -n "${EXT_HAS_SCRIPTS[${extension}]:-}" ]]; then
        "/tmp/ext-scripts/${extension}.sh"
    fi

    rm -rf "${source_dir}"
}

# Pass 0 — dependency barrier: redis needs igbinary+msgpack headers (--enable-redis-igbinary/msgpack), apcu autodetects the igbinary serializer at configure time; extensions.json key order is no longer load-bearing
for extension in igbinary msgpack; do
    if [[ -z "${EXT_SOURCE[${extension}]:-}" ]]; then
        echo "pass 0: ${extension} is not enabled, skipping barrier build"
        continue
    fi
    EXT_PASS0["${extension}"]=1
    # no &&/|| around build_extension: a conditional context suspends errexit inside the
    # function, so a failed build would run to the always-succeeding rm -rf and record OK.
    # The subshell inherits set -eux and dies on the failure; a missing status file is FAILED in Pass 3.
    ( build_extension "${extension}"; echo OK > "/tmp/ext-status/${extension}" ) > "/tmp/ext-logs/${extension}.log" 2>&1 &
done
wait

# Pass 2 (parallel, bounded): every remaining enabled extension runs as a background
# subshell, at most LANES at a time; each body's full output goes to its
# /tmp/ext-logs/<name>.log and its outcome to /tmp/ext-status/<name>.
running=0
for extension in "${!EXT_SOURCE[@]}"; do
    if [[ -n "${EXT_PASS0[${extension}]:-}" ]]; then
        continue
    fi
    echo "lane dispatch: ${extension}"
    ( build_extension "${extension}"; echo OK > "/tmp/ext-status/${extension}" ) > "/tmp/ext-logs/${extension}.log" 2>&1 &
    running="$(( running + 1 ))"
    if [[ "${running}" -ge "${LANES}" ]]; then
        wait -n || :
        echo "lane finished"
        running="$(( running - 1 ))"
    fi
done

# Pass 3 (serial): collect outcomes, surface each failed body's log, assert licenses,
# then purge the deferred remove union, strip, and log ccache stats.
wait

failed_extensions=()
for extension in "${enabled_extensions[@]}"; do
    status="$(cat "/tmp/ext-status/${extension}" 2>/dev/null || true)"
    if [[ "${status}" != "OK" ]]; then
        echo "--- ${extension} log ---"
        cat "/tmp/ext-logs/${extension}.log"
        failed_extensions+=("${extension}")
    fi
done

# license assertion runs only for extensions that built OK: a failed build has no license
# dir by construction; a license failure joins the banner instead of exiting here, so it
# cannot mask the FAILED EXTENSIONS summary when both failure kinds coexist
for extension in "${enabled_extensions[@]}"; do
    status="$(cat "/tmp/ext-status/${extension}" 2>/dev/null || true)"
    if [[ "${status}" != "OK" ]]; then
        continue
    fi
    if [[ -z "$(find "/usr/local/share/doc/php-ext/${extension}" -type f -print -quit)" ]]; then
        echo "license directory for ${extension} is missing or empty" >&2
        failed_extensions+=("${extension}")
    fi
done

if [[ -n "${remove_union}" ]]; then
    apt-get purge -y ${remove_union}
fi

# strip debug symbols from all built extensions
find "$(php-config --extension-dir)" -name '*.so' -exec strip --strip-all '{}' +

if [[ -n "${CCACHE_AVAILABLE}" ]]; then
    ccache -s
fi

if [[ ${#failed_extensions[@]} -gt 0 ]]; then
    echo ""
    echo "========================================="
    echo "FAILED EXTENSIONS: ${failed_extensions[*]}"
    echo "========================================="
    exit 1
fi
