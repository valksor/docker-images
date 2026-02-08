ARG     BASE_TAG
FROM    ghcr.io/valksor/php/zts-base${BASE_TAG} AS builder

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
&&      chmod -R 1777 /usr/local/bin \
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
COPY    php/simdjson_php/ /tmp/extensions/simdjson_php/
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
&&      (strip --strip-unneeded /usr/local/lib/libgrpc*.so* || true) \
&&      ldconfig \
&&      chmod -R 1777 /usr/local/bin \
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
            /usr/share/vim/vim90/doc \
            /usr/local/bin/install-php-extensions \
            /usr/share/man/* \
            /usr/lib/python3.*/__pycache__ \
            /usr/lib/python3.*/__phello__ \
            /usr/lib/python3.*/__hello__.py \
            ~/.pearrc \
&&      env | sed 's/=\(.*\)/="\1"/' | sed 's/^/export /' > /tmp/build_environment

FROM    ghcr.io/valksor/php/zts-base${BASE_TAG}

ARG     CACHE_BUSTER=default
ARG     PHP_VERSION

LABEL org.opencontainers.image.title="Valksor PHP ZTS" \
    org.opencontainers.image.description="Optimized PHP ZTS image with extensions" \
    org.opencontainers.image.source="https://github.com/valksor/docker-images" \
    org.opencontainers.image.licenses="MIT"

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
COPY --from=builder /var/lib/php/ /var/lib/php/

RUN     \
        set -eux \
&&      apt-get update \
&&      apt-get upgrade -y \
&&      apt-get install -y --no-install-recommends --allow-downgrades \
            libpng16-16t64 libjpeg62-turbo libbrotli1 libwebp7 libfreetype6 \
            libevent-2.1-7t64 libevent-core-2.1-7t64 libevent-extra-2.1-7t64 libevent-openssl-2.1-7t64 libevent-pthreads-2.1-7t64 \
            liblz4-1 liblzf1 libhiredis1.1.0 \
            libmagickcore-7.q16-10 libmagickwand-7.q16-10 \
&&      apt-get autoremove -y --purge \
&&      rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/log/* /tmp/* /var/tmp/* \
&&      ldconfig \
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
            ~/.pearrc

COPY    php/ini/zz.ini /usr/local/etc/php/conf.d/zz.ini

USER    valksor

STOPSIGNAL SIGQUIT

WORKDIR /var/www/html

EXPOSE  80
EXPOSE  443
EXPOSE  443/udp
EXPOSE  2019

CMD     ["php", "-a"]
