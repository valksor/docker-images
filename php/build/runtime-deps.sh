#!/usr/bin/env bash

set -euo pipefail

find /usr/local -type f \( -executable -o -name '*.so*' \) -exec ldd '{}' ';' > /var/tmp/ldd.out 2>/dev/null || { echo 'runtime-deps: ldd scan of /usr/local failed' >&2; exit 1; }
if [ "$#" -gt 0 ]; then
    ldd "$@" >> /var/tmp/ldd.out || { echo 'runtime-deps: ldd of extra binaries failed' >&2; exit 1; }
fi

if grep -i libreadline /var/tmp/ldd.out; then
    echo 'GPL libreadline is linked' >&2
    exit 1
fi
if grep 'not found' /var/tmp/ldd.out; then
    echo 'ldd: unresolved libraries' >&2
    exit 1
fi
while IFS= read -r -d '' f; do
    # non-ELF files (scripts) make readelf fail; ldd above already covered the ELF ones
    d="$(readelf -d "$f" 2>/dev/null)" || continue
    if grep -E '\(R(UN)?PATH\).*(\[|:)/(var/)?tmp/' <<<"$d"; then
        echo "runtime-deps: $f has an RPATH/RUNPATH into world-writable /tmp or /var/tmp" >&2
        exit 1
    fi
done < <(find /usr/local -type f \( -executable -o -name '*.so*' \) -print0)
# adapted from docker-library/php Dockerfile-linux.template (MIT, /usr/share/doc/docker-library-php/LICENSE)
if ! awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' /var/tmp/ldd.out \
    | sort -u | xargs -r dpkg-query --search \
    | awk 'sub(":$", "", $1) { print $1 }' | sort -u > /var/tmp/runtime-deps; then
    echo 'runtime-deps: library-to-package mapping failed (awk/sort/xargs/dpkg-query); most often dpkg-query could not find the package owning a library' >&2
    exit 1
fi
if ! test -s /var/tmp/runtime-deps; then
    echo 'runtime-deps empty: ldd scan found no dpkg-owned libraries' >&2
    exit 1
fi
cat /var/tmp/runtime-deps
rm /var/tmp/ldd.out
