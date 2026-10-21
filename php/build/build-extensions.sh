#!/usr/bin/env bash

set -eux

# Use the SAME flags as FrankenPHP
export CFLAGS="$PHP_CFLAGS"
export CPPFLAGS="$PHP_CPPFLAGS"
export LDFLAGS="$PHP_LDFLAGS"

if [[ ! -f /tmp/extensions.json ]]; then
   echo "Error: extensions.json not found. Terminating script."
   exit 1
fi

jobs="$(( $(nproc) - 1 ))"
[ "$jobs" -lt 1 ] && jobs=1

failed_extensions=()

while IFS= read -r extension; do
    enable=$(jq -r '.["'"${extension}"'"].enable // "false"' extensions.json)
    source_dir=$(jq -r '.["'"${extension}"'"].source' extensions.json)

    if [[ "${enable}" == "true" ]]; then
        echo "========================================="
        echo "Building extension: ${extension}"
        echo "========================================="

        if (
            set -eux

            configure_flags=$(jq -r '.["'"${extension}"'"].configure' extensions.json)
            remove=$(jq -r '.["'"${extension}"'"].remove' extensions.json)
            req=$(jq -r '.["'"${extension}"'"].req' extensions.json)
            env_vars=$(jq -r '.["'"${extension}"'"].env // ""' extensions.json)

            if [[ -n "${req}" && "${req}" != "null" ]]; then
                apt-get install -y ${req}
            fi

            cd ${source_dir}
            phpize

            if [[ -n "${configure_flags}" && "${configure_flags}" != "null" ]]; then
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

            if [[ -n "${env_vars}" ]]; then
                env ${env_vars} make -j"${jobs}"
            else
                make -j"${jobs}"
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
            for license_source in "${license_dirs[@]}"; do
                for license_candidate in "${license_source}"/LICENSE* "${license_source}"/LICENCE* "${license_source}"/COPYING*; do
                    if [[ -f "${license_candidate}" ]]; then
                        cp -v "${license_candidate}" "${license_dir}/"
                        license_found=1
                    fi
                done
            done
            if [[ "${license_found}" -eq 0 ]]; then
                echo "WARNING: no license file found for ${extension}" >&2
            fi

            docker-php-ext-enable ${extension}

            if (jq -e '.["'"${extension}"'"].scripts | type == "array"' /tmp/extensions.json); then
                temp_script=$(mktemp)

                while IFS= read -r script; do
                    echo "${script}" >> "${temp_script}"
                done < <(jq -r '.["'"${extension}"'"].scripts[]' /tmp/extensions.json)

                chmod +x "${temp_script}"

                "${temp_script}"

                rm "${temp_script}"
            fi

            if [[ -n "${remove}" && "${remove}" != "null" ]]; then
                apt-get purge -y ${remove}
            fi
        ); then
            echo "SUCCESS: ${extension}"
        else
            echo "FAILED: ${extension}"
            failed_extensions+=("${extension}")
        fi

        cd /tmp
    fi

    rm -rf ${source_dir}
done < <(jq -r 'keys[]' extensions.json)

# strip debug symbols from all built extensions
find "$(php-config --extension-dir)" -name '*.so' -exec strip --strip-all '{}' + || :

if [[ ${#failed_extensions[@]} -gt 0 ]]; then
    echo ""
    echo "========================================="
    echo "FAILED EXTENSIONS: ${failed_extensions[*]}"
    echo "========================================="
    exit 1
fi
