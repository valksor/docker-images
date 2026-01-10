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
        zstd libbrotli1 libpsl5t64 libgsasl18 rtmpdump librtmp1 libnghttp3-9 nghttp2 libonig5 libpq5 libsodium23 libargon2-1 libtidy58 libfcgi-bin \
        libzip5 libgmp10 zlib1g libffi8 libssh2-1t64 libldap-common libldap-2.5-0 libldap2 libxslt1.1 libicu76 libvips42 libexif12 libheif1 \
        libsharpyuv0 liblzma5 libwebp7 libwebpdecoder3 libwebpdemux2 libwebpmux3 \
&&      apt-get install -y --no-install-recommends --allow-downgrades libxml2-dev libssl-dev libsqlite3-dev libbz2-dev libidn2-dev libzstd-dev \
        libbrotli-dev libpsl-dev libgsasl-dev librtmp-dev libnghttp2-dev libnghttp3-dev libonig-dev libpq-dev libsodium-dev libargon2-dev libtidy-dev \
        libzip-dev libgmp-dev zlib1g-dev libffi-dev libssh2-1-dev libldap-dev libxslt1-dev libicu-dev libexif-dev libheif-dev liblzma-dev libwebp-dev \
&&      chmod -R 1777 /usr/local/bin \
&&      mkdir --parents "$PHP_INI_DIR/conf.d" \
&&      [ ! -d /var/www/html ]; \
        mkdir --parents /var/www/html \
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
            --enable-embed=shared \
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
            --enable-zts \
            --enable-zend-max-execution-timers \
            --disable-zend-signals \
            --with-bz2 \
            --with-curl \
            --with-ffi \
            --with-gmp \
            --with-libxml \
            --with-openssl \
            --with-password-argon2 \
            --with-pear \
            --with-pic \
            --with-pdo-pgsql \
            --with-pdo-sqlite=/usr \
            --with-sodium=shared \
            --with-sqlite3=/usr \
            --with-tidy \
            --with-valgrind \
            --with-xsl \
            --with-zlib \
            --without-readline \
&&      make -j"$jobs" \
&&      find -type f -name '*.a' -delete \
&&      make install \
&&      make clean \
&&      mkdir --parents "$PHP_INI_DIR" \
&&      cp -v php.ini-* "$PHP_INI_DIR/" \
&&      cd / \
&&      pecl update-channels \
&&      rm -rf \
            /tmp/pear \
            ~/.pearrc \
&&      php --version \
&&      mkdir --parents "$PHP_INI_DIR/conf.d" \
&&      chmod -R 1777 /usr/local/bin \
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

LABEL org.opencontainers.image.title="Valksor PHP ZTS Base" \
    org.opencontainers.image.description="Optimized PHP base image with ZTS and embed SAPI support" \
    org.opencontainers.image.source="https://github.com/valksor/docker-images" \
    org.opencontainers.image.licenses="MIT"

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
COPY --from=builder /var/lib/php/ /var/lib/php/

RUN     \
        set -eux \
&&      apt-get update \
&&      apt-get upgrade -y \
&&      apt-get install -y --no-install-recommends --allow-downgrades \
            libxml2 libssl3t64 libsqlite3-0 libbz2-1.0 libidn2-0 \
            zstd libbrotli1 libpsl5t64 libgsasl18 rtmpdump librtmp1 libnghttp3-9 nghttp2 \
            libonig5 libpq5 libsodium23 libargon2-1 libtidy58 \
            libzip5 libgmp10 zlib1g libffi8 libssh2-1t64 libldap-common libldap-2.5-0 libldap2 \
            libxslt1.1 libicu76 libvips42 libexif12 libheif1 libsharpyuv0 liblzma5 libwebp7 libwebpdecoder3 libwebpdemux2 libwebpmux3 \
&&      apt-get autoremove -y --purge \
&&      rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/log/* /tmp/* /var/tmp/* \
&&      mkdir --parents "$PHP_INI_DIR/conf.d" \
&&      mkdir --parents /var/www/html \
&&      chown valksor:valksor /var/www/html \
&&      chmod 1777 -R /var/www/html \
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
            /usr/local/etc/php/php.ini-production \
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

COPY    php/ini/opcache.ini /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
COPY    php/preload.php /var/www/preload.php


RUN     \
        set -eux \
&&      chmod 644 /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
&&      git config --global --add safe.directory "*" \
&&      chown -R valksor:valksor /home/valksor \
&&      chown valksor:valksor /var/www/preload.php

USER    valksor

STOPSIGNAL SIGQUIT

WORKDIR /var/www/html

EXPOSE  80
EXPOSE  443
EXPOSE  443/udp
EXPOSE  2019

CMD     ["php", "-a"]
