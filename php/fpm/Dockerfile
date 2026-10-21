ARG     BASE_TAG
FROM    ghcr.io/valksor/php/fpm-base${BASE_TAG} AS builder

ARG     CACHE_BUSTER=default
ARG     PHP_VERSION

ENV     PHP_VERSION=${PHP_VERSION}
ENV     PHP_INI_DIR=/usr/local/etc/php
ENV     PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O3 -ftree-vectorize -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -march=native -mtune=native"
ENV     PHP_CPPFLAGS="$PHP_CFLAGS"
ENV     PHP_LDFLAGS="-Wl,-O3 -pie"
ENV     PHP_BUILD_PROVIDER='https://github.com/valksor/docker-images'
ENV     PHP_UNAME="Linux (arm64) - Docker"

USER    root

COPY    php/source/                             /usr/src/php

COPY    php/docker/fpm/docker-php-entrypoint    /usr/local/bin/docker-php-entrypoint
COPY    php/docker/docker-php-ext-configure     /usr/local/bin/docker-php-ext-configure
COPY    php/docker/docker-php-ext-enable        /usr/local/bin/docker-php-ext-enable
COPY    php/docker/docker-php-ext-install       /usr/local/bin/docker-php-ext-install
COPY    php/docker/docker-php-source            /usr/local/bin/docker-php-source

COPY    php/build/build-extensions.sh           /tmp/build-extensions.sh
COPY    php/build/extensions.json               /tmp/extensions.json
COPY    php/build/runtime-deps.sh               /tmp/runtime-deps.sh

COPY    --from=composer:2                       /usr/bin/composer /usr/bin/

STOPSIGNAL SIGQUIT

WORKDIR /tmp

RUN     \
        set -eux \
&&      composer self-update --snapshot \
&&      mkdir --parents /tmp/extensions \
&&      apt-get update \
&&      apt-get upgrade -y \
&&      apt-get install -y --no-install-recommends --allow-downgrades make libc-dev libc6-dev gcc g++ cpp git dpkg-dev autoconf jq wget \
&&      apt-get install -y --no-install-recommends --allow-downgrades libpng16-16t64 libjpeg62-turbo libbrotli1 libwebp7 libfreetype6 \
&&      apt-get install -y --no-install-recommends --allow-downgrades zlib1g-dev libbrotli-dev libjpeg62-turbo-dev libpng-dev libwebp-dev libfreetype-dev libldap-dev \
&&      chmod 0755 /usr/local/bin && find /usr/local/bin -mindepth 1 -maxdepth 1 -type f -exec chmod 0755 '{}' + \
&&      export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
&&      docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ --with-webp=/usr/include/ \
&&      docker-php-ext-install gd \
&&      docker-php-ext-enable gd

COPY    php/apcu/ /tmp/extensions/apcu/
COPY    php/ext-ds/ /tmp/extensions/ext-ds/
COPY    php/igbinary/ /tmp/extensions/igbinary/
COPY    php/imagick/ /tmp/extensions/imagick/
COPY    php/mediawiki-php-excimer/ /tmp/extensions/mediawiki-php-excimer/
COPY    php/msgpack-php/ /tmp/extensions/msgpack-php/
COPY    php/pecl-ev/ /tmp/extensions/pecl-ev/
COPY    php/pecl-event/ /tmp/extensions/pecl-event/
COPY    php/pecl-file_formats-lzf/ /tmp/extensions/pecl-file_formats-lzf/
COPY    php/pecl-networking-uuid/ /tmp/extensions/pecl-networking-uuid/
COPY    php/php-ext-lz4/ /tmp/extensions/php-ext-lz4/
COPY    php/php-ext-zstd/ /tmp/extensions/php-ext-zstd/
COPY    php/php-inotify/ /tmp/extensions/php-inotify/
COPY    php/php-spx/ /tmp/extensions/php-spx/
COPY    php/php_zip/ /tmp/extensions/php_zip/
COPY    php/phpredis/ /tmp/extensions/phpredis/
COPY    php/simdjson-plus-php-ext/ /tmp/extensions/simdjson-plus-php-ext/
COPY    php/simdutf-php-ext/ /tmp/extensions/simdutf-php-ext/
COPY    php/grpc/ /tmp/extensions/grpc/
COPY    php/protobuf/ /tmp/extensions/protobuf/

RUN     \
        set -eux \
&&      cd /tmp/extensions/grpc \
&&      EXTRA_DEFINES=GRPC_POSIX_FORK_ALLOW_PTHREAD_ATFORK make -j$(nproc) shared_c CONFIG=opt \
&&      cd - \
&&      mkdir -p /tmp/extensions/protobuf/php/ext/google/protobuf/third_party \
&&      ln -sf /tmp/extensions/protobuf/third_party/utf8_range /tmp/extensions/protobuf/php/ext/google/protobuf/third_party/utf8_range \
&&      sed -i 's/zval_dtor/zval_ptr_dtor/g' /tmp/extensions/protobuf/php/ext/google/protobuf/map.c \
&&      sed -i 's/zval_dtor/zval_ptr_dtor/g' /tmp/extensions/protobuf/php/ext/google/protobuf/message.c \
&&      chmod +x /tmp/build-extensions.sh \
&&      /tmp/build-extensions.sh \
&&      cp /tmp/extensions/grpc/libs/opt/libgrpc*.so* /usr/local/lib/ \
&&      shopt -s nocaseglob \
&&      for third_party_dir in /tmp/extensions/grpc/third_party/*/; do \
            license_out="/usr/local/share/doc/php-ext/grpc/third_party/$(basename "${third_party_dir}")" \
            && { mkdir --parents "${license_out}" || exit 1; } \
            && for license_file in "${third_party_dir}"LICENSE* "${third_party_dir}"LICENCE* "${third_party_dir}"COPYING* "${third_party_dir}"NOTICE*; do \
                if [[ -f "${license_file}" ]]; then cp -v "${license_file}" "${license_out}/" || exit 1; fi \
            done \
        ; done \
&&      shopt -u nocaseglob \
&&      strip --strip-unneeded /usr/local/lib/libgrpc*.so* \
&&      ldconfig \
&&      chmod 0755 /usr/local/bin && find /usr/local/bin -mindepth 1 -maxdepth 1 -type f -exec chmod 0755 '{}' + \
&&      bash /tmp/runtime-deps.sh \
&&      apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false make libc-dev libc6-dev cpp gcc g++ autoconf dpkg-dev \
&&      apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false zlib1g-dev libbrotli-dev libjpeg62-turbo-dev libpng-dev libwebp-dev libfreetype-dev libldap-dev \
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
            /usr/local/php/man/* \
            /usr/src/php \
            /var/cache/* \
            /usr/local/etc/php/php.ini-production \
            /usr/share/vim/vim90/doc \
            /usr/local/bin/install-php-extensions \
            /usr/share/man/* \
            /usr/lib/python3.*/__pycache__ \
            /usr/lib/python3.*/__phello__ \
            /usr/lib/python3.*/__hello__.py \
            ~/.pearrc \
&&      env | sed 's/=\(.*\)/="\1"/' | sed 's/^/export /' > /tmp/build_environment

FROM    ghcr.io/valksor/php/fpm-base${BASE_TAG}

ARG     CACHE_BUSTER=default
ARG     PHP_VERSION

LABEL org.opencontainers.image.title="Valksor PHP FPM" \
    org.opencontainers.image.description="Optimized PHP-FPM image with extensions" \
    org.opencontainers.image.source="https://github.com/valksor/docker-images" \
    org.opencontainers.image.licenses="BSD-3-Clause AND MIT"

USER    root

ENV     PHP_VERSION=${PHP_VERSION}
ENV     PHP_INI_DIR=/usr/local/etc/php
ENV     PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O3 -ftree-vectorize -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -march=native -mtune=native"
ENV     PHP_CPPFLAGS="$PHP_CFLAGS"
ENV     PHP_LDFLAGS="-Wl,-O3 -pie"
ENV     PHP_BUILD_PROVIDER='https://github.com/valksor/docker-images'
ENV     PHP_UNAME="Linux (arm64) - Docker"

# CRITICAL: Preserve ALL environment variables from build process
COPY --from=builder /tmp/build_environment /tmp/
RUN set -a && source /tmp/build_environment && set +a

COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/etc/ /usr/local/etc/
COPY --from=builder /usr/local/share/ /usr/local/share/
COPY --from=builder /usr/share/ /usr/share/
COPY --from=builder /var/www/ /var/www/
COPY --from=builder /home/valksor/ /home/valksor/
COPY --from=builder /etc/ld.so.cache /etc/
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
&&      apt-get autoremove -y --purge \
&&      rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/log/* /tmp/* /var/tmp/* \
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
            /usr/local/php/man/* \
            /usr/src/php \
            /var/cache/* \
            /usr/local/etc/php/php.ini-production \
            /usr/share/vim/vim90/doc \
            /usr/local/bin/install-php-extensions \
            /usr/share/man/* \
            /usr/lib/python3.*/__pycache__ \
            /usr/lib/python3.*/__phello__ \
            /usr/lib/python3.*/__hello__.py \
            ~/.pearrc \
&&      out="$(php -d display_errors=stderr -d display_startup_errors=1 -d log_errors=0 -m 2>&1)" \
&&      if grep -qE 'PHP Startup|Unable to load|Fatal|already loaded' <<<"$out"; then echo "$out" >&2; exit 1; fi \
&&      out="$(ldd /usr/local/bin/php /usr/local/sbin/php-fpm "$(php-config --extension-dir)"/*.so)" \
&&      if grep 'not found' <<<"$out"; then echo "$out" >&2; exit 1; fi \
&&      php -r 'foreach (["sodium", "gd", "imagick", "zip", "event", "redis"] as $e) if (!extension_loaded($e)) { fwrite(STDERR, "missing extension: $e\n"); exit(1); }' \
&&      php-fpm -v \
&&      php-fpm -t \
&&      r="$(php --ri readline)" \
&&      if ! grep -q 'EditLine wrapper' <<<"$r"; then echo 'readline is not built against libedit' >&2; exit 1; fi \
&&      if ! php -r 'exit(function_exists("readline") ? 0 : 1);'; then echo 'readline() is missing' >&2; exit 1; fi \
&&      out="$(ldd /usr/local/bin/php)" \
&&      if grep -i readline <<<"$out"; then echo 'GPL libreadline is linked' >&2; exit 1; fi \
&&      w="$(find /usr/local/bin -perm /022 ! -type l)" \
&&      if [ -n "$w" ]; then echo "writable: $w" >&2; exit 1; fi

USER    valksor

STOPSIGNAL SIGQUIT

WORKDIR /var/www/html

EXPOSE  9000

CMD     ["php-fpm"]
