#!/usr/bin/env bash

set -euo pipefail

{
    find /usr/local -type f \( -executable -o -name '*.so*' \) -exec ldd '{}' ';' 2>/dev/null
    if [ "$#" -gt 0 ]; then
        ldd "$@"
    fi
} > /var/tmp/ldd.out

if grep -i libreadline /var/tmp/ldd.out; then
    echo 'GPL libreadline is linked' >&2
    exit 1
fi
if grep 'not found' /var/tmp/ldd.out; then
    echo 'ldd: unresolved libraries' >&2
    exit 1
fi
# adapted from docker-library/php Dockerfile-linux.template (MIT, /usr/share/doc/docker-library-php/LICENSE)
awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' /var/tmp/ldd.out \
    | sort -u | xargs -r dpkg-query --search \
    | awk 'sub(":$", "", $1) { print $1 }' | sort -u > /var/tmp/runtime-deps
if ! test -s /var/tmp/runtime-deps; then
    echo 'runtime-deps empty: ldd scan found no dpkg-owned libraries' >&2
    exit 1
fi
cat /var/tmp/runtime-deps
rm /var/tmp/ldd.out
