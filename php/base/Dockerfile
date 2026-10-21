FROM    ghcr.io/valksor/curl:latest AS builder

ARG     CACHE_BUSTER=default

ARG     PHP_COMMIT_HASH
ARG     PHP_VERSION

USER    root

ENV     PHP_VERSION=${PHP_VERSION}
ENV     PHP_INI_DIR=/usr/local/etc/php
ENV     PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O3 -ftree-vectorize -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -march=native -mtune=native"
ENV     PHP_CPPFLAGS="$PHP_CFLAGS"
ENV     PHP_LDFLAGS="-Wl,-O3 -pie"
ENV     PHP_COMMIT_HASH=${PHP_COMMIT_HASH}
ENV     PHP_BUILD_PROVIDER='https://github.com/valksor/docker-images'
ENV     PHP_UNAME="Linux (arm64) - Docker"

COPY    php/no-debian-php /etc/apt/preferences.d/no-debian-php
COPY    php/source/          /usr/src/php

COPY    php/docker/fpm/docker-php-entrypoint    /usr/local/bin/docker-php-entrypoint
COPY    php/docker/docker-php-ext-configure     /usr/local/bin/docker-php-ext-configure
COPY    php/docker/docker-php-ext-enable        /usr/local/bin/docker-php-ext-enable
COPY    php/docker/docker-php-ext-install       /usr/local/bin/docker-php-ext-install
COPY    php/docker/docker-php-source            /usr/local/bin/docker-php-source
# php-fpm-healthcheck, vendored from https://github.com/renatomefi/php-fpm-healthcheck
# at commit a2d45de918787f761754b96b94a59f4f6acebc25 (sha256 53bc616c4a30f029b98bff48fdeb0c4da252cb11e4f86656a8222a67dc4e5009)
COPY    php/healthcheck/php-fpm-healthcheck /usr/local/bin/php-fpm-healthcheck

STOPSIGNAL SIGQUIT

WORKDIR /home/valksor

RUN     \
        set -eux \
;       jobs="$(( $(nproc) - 1 ))" \
;       [ "$jobs" -lt 1 ] && jobs=1 \
;       apt-get update \
&&      apt-get upgrade -y \
&&      apt-get install -y --no-install-recommends --allow-downgrades make libc-dev libc6-dev gcc g++ cpp git dpkg-dev autoconf jq wget \
&&      apt-get install -y --no-install-recommends --allow-downgrades bison re2c valgrind libxml2 libssl3t64 libsqlite3-0 libbz2-1.0 libidn2-0 gdb-minimal \
        zstd libbrotli1 libpsl5t64 libgsasl18 rtmpdump librtmp1 libnghttp3-9 nghttp2 libonig5 libpq5 libsodium26 libargon2-1 libtidy58 libfcgi-bin \
        libzip5 libgmp10 zlib1g libffi8 libssh2-1t64 libldap-common libldap2 libxslt1.1 libicu78 libvips42 libexif12 libheif1 \
        libsharpyuv0 liblzma5 libwebp7 libwebpdecoder3 libwebpdemux2 libwebpmux3 \
&&      apt-get install -y --no-install-recommends --allow-downgrades libxml2-dev libssl-dev libsqlite3-dev libbz2-dev libidn2-dev libzstd-dev \
        libbrotli-dev libpsl-dev libgsasl-dev librtmp-dev libnghttp2-dev libnghttp3-dev libonig-dev libpq-dev libsodium-dev libargon2-dev libtidy-dev \
        libzip-dev libgmp-dev zlib1g-dev libffi-dev libssh2-1-dev libldap-dev libxslt1-dev libicu-dev libexif-dev libheif-dev liblzma-dev libwebp-dev \
        libedit-dev libncurses-dev \
&&      chmod 0755 /usr/local/bin && find /usr/local/bin -mindepth 1 -maxdepth 1 -type f -exec chmod 0755 '{}' + \
&&      mkdir --parents "$PHP_INI_DIR/conf.d" \
&&      mkdir --parents /var/www/html \
&&      chown valksor:valksor /var/www/html \
&&      chmod 1777 -R /var/www/html \
&&      export \
            CFLAGS="$PHP_CFLAGS" \
            CPPFLAGS="$PHP_CPPFLAGS" \
            LDFLAGS="$PHP_LDFLAGS" \
&&      cd /usr/src/php \
&&      gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
&&      ./buildconf --force \
&&      ./configure \
            --build="${gnuArch}" \
            --with-config-file-path="$PHP_INI_DIR" \
            --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
            --disable-cgi \
            --disable-ftp \
            --disable-short-tags \
            --disable-mysqlnd \
            --disable-phpdbg \
            --enable-bcmath \
            --enable-calendar \
            --enable-exif \
            --enable-fpm \
            --enable-huge-code-pages \
            --enable-intl \
            --enable-mbstring \
            --enable-option-checking=fatal \
            --enable-pcntl \
            --enable-sysvsem \
            --enable-sysvshm \
            --enable-sysvmsg \
            --enable-shmop \
            --enable-soap \
            --enable-sockets \
            --with-bz2 \
            --with-curl \
            --with-ffi \
            --with-fpm-group=valksor \
            --with-fpm-user=valksor \
            --with-gmp \
            --with-libxml \
            --with-openssl \
            --with-password-argon2 \
            --with-pdo-pgsql \
            --with-pdo-sqlite=/usr \
            --with-sodium=shared \
            --with-sqlite3=/usr \
            --with-tidy \
            --with-valgrind \
            --with-xsl \
            --with-zlib \
            --with-libedit \
&&      make -j"$jobs" \
&&      find -type f -name '*.a' -delete \
&&      make install \
&&      strip --strip-all /usr/local/bin/php /usr/local/sbin/php-fpm "$(php-config --extension-dir)"/*.so \
&&      for f in /usr/local/bin/php /usr/local/sbin/php-fpm "$(php-config --extension-dir)"/*.so; do s="$(readelf -S "$f")" || exit 1; if grep -q '\.symtab' <<<"$s"; then echo "strip left .symtab in $f" >&2; exit 1; fi; done \
&&      make clean \
&&      mkdir --parents "$PHP_INI_DIR" \
&&      cp -v php.ini-* "$PHP_INI_DIR/" \
&&      mkdir --parents /usr/local/share/doc/php && cp -v LICENSE /usr/local/share/doc/php/LICENSE \
&&      cd / \
&&      php --version \
&&      docker-php-ext-enable sodium \
&&      mkdir --parents "$PHP_INI_DIR/conf.d" \
&&      chmod 0755 /usr/local/bin && find /usr/local/bin -mindepth 1 -maxdepth 1 -type f -exec chmod 0755 '{}' + \
&&      mkdir --parents --mode=777 --verbose /run/php-fpm \
&&      touch /run/php-fpm/.keep_dir \
&&      { find /usr/local -type f \( -executable -o -name '*.so*' \) -exec ldd '{}' ';' 2>/dev/null; ldd /usr/bin/cgi-fcgi /usr/bin/jq /usr/bin/git /usr/bin/wget; } > /var/tmp/ldd.out \
&&      if grep -i libreadline /var/tmp/ldd.out; then echo 'GPL libreadline is linked' >&2; exit 1; fi \
&&      if grep 'not found' /var/tmp/ldd.out; then echo 'ldd: unresolved libraries' >&2; exit 1; fi \
# adapted from docker-library/php Dockerfile-linux.template (MIT, /usr/share/doc/docker-library-php/LICENSE)
&&      awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' /var/tmp/ldd.out \
        | sort -u | xargs -r dpkg-query --search \
        | awk 'sub(":$", "", $1) { print $1 }' | sort -u > /var/tmp/runtime-deps \
&&      { test -s /var/tmp/runtime-deps || { echo 'runtime-deps empty: ldd scan found no dpkg-owned libraries' >&2; exit 1; }; } \
&&      cat /var/tmp/runtime-deps \
&&      rm /var/tmp/ldd.out \
&&      apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false make libc-dev libc6-dev cpp gcc g++ autoconf dpkg-dev libwebp-dev \
&&      apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false libxml2-dev libssl-dev libsqlite3-dev libbz2-dev libidn2-dev \
        libzstd-dev libbrotli-dev libpsl-dev libgsasl-dev librtmp-dev libnghttp2-dev libnghttp3-dev libonig-dev libpq-dev libsodium-dev liblzma-dev \
        libargon2-dev libtidy-dev libzip-dev libgmp-dev zlib1g-dev libffi-dev libssh2-1-dev libldap-dev libxslt1-dev libicu-dev libexif-dev libheif-dev \
&&      echo "/usr/local/lib" > /etc/ld.so.conf.d/local-lib.conf \
&&      ldconfig \
&&      mkdir --parents /var/lib/php/sessions \
&&      chown -R valksor:valksor /var/lib/php/sessions \
&&      mkdir --parents /var/lib/php/opcache \
&&      chown -R valksor:valksor /var/lib/php/opcache \
&&      rm -rf \
            ~/.pearrc \
            /home/valksor/*.deb \
            /home/valksor/*.gz \
            /*.deb \
            /tmp/* \
            /usr/local/bin/docker-php-ext-configure \
            /usr/local/bin/docker-php-ext-enable \
            /usr/local/bin/docker-php-ext-install \
            /usr/local/bin/docker-php-source \
            /usr/local/bin/phpdbg \
            /usr/local/etc/php-fpm.conf \
            /usr/local/etc/php-fpm.d/* \
            /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
            /usr/local/etc/php/php.ini \
            /usr/local/php/man/* \
            /usr/src/php \
            /var/cache/* \
            /usr/share/vim/vim90/doc \
            /usr/local/bin/install-php-extensions \
            /usr/share/man/* \
            /home/valksor/env_entrypoint.sh \
            /usr/lib/python3.*/__pycache__ \
            /usr/lib/python3.*/__phello__ \
            /usr/lib/python3.*/__hello__.py \
            ~/.pearrc \
&&      mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
&&      env | sed 's/=\(.*\)/="\1"/' | sed 's/^/export /' > /tmp/build_environment

FROM    ghcr.io/valksor/curl:latest

ARG     PHP_COMMIT_HASH
ARG     PHP_VERSION

LABEL org.opencontainers.image.title="Valksor PHP Base" \
    org.opencontainers.image.description="Optimized PHP base image with FPM support" \
    org.opencontainers.image.source="https://github.com/valksor/docker-images" \
    org.opencontainers.image.licenses="BSD-3-Clause AND MIT"

USER    root

ENV     PHP_VERSION=${PHP_VERSION}
ENV     PHP_INI_DIR=/usr/local/etc/php
ENV     PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O3 -ftree-vectorize -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -march=native -mtune=native"
ENV     PHP_CPPFLAGS="$PHP_CFLAGS"
ENV     PHP_LDFLAGS="-Wl,-O3 -pie"
ENV     PHP_COMMIT_HASH=${PHP_COMMIT_HASH}
ENV     PHP_BUILD_PROVIDER='https://github.com/valksor/docker-images'
ENV     PHP_UNAME="Linux (arm64) - Docker"

# CRITICAL: Preserve ALL environment variables from build process
COPY --from=builder /tmp/build_environment /tmp/
RUN set -a && source /tmp/build_environment && set +a

COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/etc/ /usr/local/etc/
COPY --from=builder /usr/local/share/ /usr/local/share/
COPY --from=builder /var/www/ /var/www/
COPY --from=builder /home/valksor/ /home/valksor/
COPY --from=builder /etc/ld.so.cache /etc/
COPY --from=builder /usr/local/include/ /usr/local/include/
COPY --from=builder /usr/local/sbin/ /usr/local/sbin/
COPY --from=builder /usr/bin/ /usr/bin/
COPY --from=builder /run/php-fpm/ /run/php-fpm/
COPY --from=builder /var/lib/php/ /var/lib/php/
COPY --from=builder /var/tmp/runtime-deps /var/tmp/

RUN     \
        set -eux \
&&      apt-get update \
# dist-upgrade, not upgrade: sid transitions can need package adds/removals to move perl-base; plain upgrade holds it back and perl postinsts break on the skew
&&      apt-get dist-upgrade -y --no-install-recommends \
&&      xargs -a /var/tmp/runtime-deps apt-get install -y --no-install-recommends --allow-downgrades \
# ldd cannot see these: CLI tools (zstd rtmpdump nghttp2), FFI-only libraries (libvips42 libexif12 libheif1), config-only package (libldap-common ships /etc/ldap/ldap.conf)
&&      apt-get install -y --no-install-recommends --allow-downgrades zstd rtmpdump nghttp2 libvips42 libexif12 libheif1 libldap-common \
&&      apt-get autoremove -y --purge \
&&      rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/log/* /tmp/* /var/tmp/* \
&&      mkdir --parents "$PHP_INI_DIR/conf.d" \
&&      mkdir --parents /var/www/html \
&&      chown valksor:valksor /var/www/html \
&&      chmod 1777 -R /var/www/html \
&&      ldconfig \
&&      chown valksor:valksor /run/php-fpm \
&&      rm -rf \
            ~/.pearrc \
            /home/valksor/*.deb \
            /home/valksor/*.gz \
            /*.deb \
            /tmp/* \
            /usr/local/bin/docker-php-ext-configure \
            /usr/local/bin/docker-php-ext-enable \
            /usr/local/bin/docker-php-ext-install \
            /usr/local/bin/docker-php-source \
            /usr/local/bin/phpdbg \
            /usr/local/etc/php-fpm.conf \
            /usr/local/etc/php-fpm.d/* \
            /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
            /usr/local/php/man/* \
            /usr/src/php \
            /var/cache/* \
            /usr/share/vim/vim90/doc \
            /usr/local/bin/install-php-extensions \
            /usr/share/man/* \
            /home/valksor/env_entrypoint.sh \
            /usr/lib/python3.*/__pycache__ \
            /usr/lib/python3.*/__phello__ \
            /usr/lib/python3.*/__hello__.py \
            ~/.pearrc

COPY    php/ini/fpm/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY    php/ini/fpm/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY    php/ini/zz.ini /usr/local/etc/php/conf.d/zz.ini
COPY    php/ini/fpm/fastcgi.ini /usr/local/etc/php/conf.d/zzz-fastcgi.ini
COPY    php/ini/opcache.ini /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
COPY    php/preload.php /var/www/preload.php
COPY    php/docker/LICENSE /usr/share/doc/docker-library-php/LICENSE
COPY    php/healthcheck/LICENSE /usr/share/doc/php-fpm-healthcheck/LICENSE

RUN     \
        set -eux \
&&      chmod 644 /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
&&      git config --global --add safe.directory "*" \
&&      chown -R valksor:valksor /home/valksor \
&&      chown valksor:valksor /var/www/preload.php \
&&      { [ -s /usr/local/share/doc/php/LICENSE ] || { echo 'php LICENSE is missing or empty' >&2; exit 1; }; } \
&&      out="$(php -d display_errors=stderr -d display_startup_errors=1 -d log_errors=0 -m 2>&1)" \
&&      if grep -qE 'PHP Startup|Unable to load|Fatal|already loaded' <<<"$out"; then echo "$out" >&2; exit 1; fi \
&&      out="$(ldd /usr/local/bin/php /usr/local/sbin/php-fpm /usr/bin/cgi-fcgi /usr/bin/jq /usr/bin/git /usr/bin/wget "$(php-config --extension-dir)"/*.so)" \
&&      if grep 'not found' <<<"$out"; then echo "$out" >&2; exit 1; fi \
&&      php -r 'foreach (["sodium"] as $e) if (!extension_loaded($e)) { fwrite(STDERR, "missing extension: $e\n"); exit(1); }' \
&&      php-fpm -v \
&&      php-fpm -t \
&&      r="$(php --ri readline)" \
&&      if ! grep -q 'EditLine wrapper' <<<"$r"; then echo 'readline is not built against libedit' >&2; exit 1; fi \
&&      if ! php -r 'exit(function_exists("readline") ? 0 : 1);'; then echo 'readline() is missing' >&2; exit 1; fi \
&&      out="$(ldd /usr/local/bin/php)" \
&&      if grep -i readline <<<"$out"; then echo 'GPL libreadline is linked' >&2; exit 1; fi \
&&      w="$(find /usr/local/bin -perm /022 ! -type l)" \
&&      if [ -n "$w" ]; then echo "writable: $w" >&2; exit 1; fi

ENV     FCGI_STATUS_PATH=/fpm/status

RUN     \
        set -eux; \
        php-fpm -D; \
        trap 'kill "$(cat /run/php-fpm/php-fpm.pid 2>/dev/null)" 2>/dev/null || :' EXIT; \
        ok=0; out=''; \
        for i in $(seq 1 20); do if out="$(php-fpm-healthcheck -v 2>&1)" && grep -q '^pool:' <<<"$out"; then ok=1; break; fi; sleep 0.5; done; \
        if [ "$ok" != 1 ]; then echo "healthcheck: no status page at $FCGI_STATUS_PATH: $out" >&2; exit 1; fi; \
# option parsing (getopt) and cgi-fcgi work; this does not prove the path, the pool: check above does
        php-fpm-healthcheck --listen-queue=1000; \
# negative control: the old default path must not serve the status page
        out="$(FCGI_STATUS_PATH=/status php-fpm-healthcheck -v 2>&1 || :)"; \
        if grep -q '^pool:' <<<"$out"; then echo 'healthcheck: /status unexpectedly serves the status page' >&2; exit 1; fi; \
        pid="$(cat /run/php-fpm/php-fpm.pid)"; \
        kill "$pid"; \
        n=0; while kill -0 "$pid" 2>/dev/null && [ "$n" -lt 50 ]; do sleep 0.1; n=$((n+1)); done; \
        if kill -0 "$pid" 2>/dev/null; then echo 'php-fpm did not stop' >&2; exit 1; fi; \
        rm -f /run/php-fpm/php-fpm.pid; \
        trap - EXIT

USER    valksor

STOPSIGNAL SIGQUIT

WORKDIR /var/www/html

EXPOSE  9000

CMD     ["php-fpm"]
