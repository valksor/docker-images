FROM    ghcr.io/valksor/php/fpm:latest AS builder

ARG     CACHE_BUSTER=default
ARG     ARCH

USER    root

ENV     PHP_VERSION=8.5.0-dev
ENV     PHP_INI_DIR=/usr/local/etc/php
ENV     PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O3 -ftree-vectorize -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -march=native -mtune=native"
ENV     PHP_CPPFLAGS="$PHP_CFLAGS"
ENV     PHP_LDFLAGS="-Wl,-O3 -pie"

COPY    php/docker/docker-php-ext-enable    /usr/local/bin/docker-php-ext-enable
COPY    php/build/build-extensions.sh /tmp/build-extensions.sh
COPY    php/build/extensions-dev.json /tmp/extensions.json

COPY    --from=composer:2                       /usr/bin/composer /usr/bin/

WORKDIR /tmp

RUN    \
        set -eux \
&&      composer self-update --snapshot \
&&      mkdir --parents /tmp/extensions \
&&      apt-get update \
&&      apt-get upgrade -y \
&&      apt-get install -y --no-install-recommends --allow-downgrades make libc-dev libc6-dev gcc g++ cpp git dpkg-dev autoconf fontconfig watchman

COPY    php/pcov/ /tmp/extensions/pcov/
COPY    php/xdebug/ /tmp/extensions/xdebug/

RUN     \
        set -eux \
&&      chmod +x /tmp/build-extensions.sh \
&&      /tmp/build-extensions.sh \
&&      chmod -R 1777 /usr/local/bin \
&&      apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false make libc-dev libc6-dev cpp gcc g++ autoconf dpkg-dev fontconfig \
&&      rm -rf \
            ~/.pearrc \
            /home/valksor/*.deb \
            /home/valksor/*.gz \
            /*.deb \
            /tmp/* \
            /usr/local/bin/docker-php-ext-enable \
            /usr/local/bin/phpdbg \
            /usr/local/php/man/* \
            /usr/src/php \
            /var/cache/* \
            /usr/share/vim/vim90/doc \
            /usr/local/bin/install-php-extensions \
            /usr/share/man/* \
            /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
            /usr/local/etc/php/php.ini \
            /usr/local/etc/php-fpm.d/www.conf \
            /usr/lib/python3.*/__pycache__ \
            /usr/lib/python3.*/__phello__ \
            /usr/lib/python3.*/__hello__.py \
&&      mv /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini \
&&      env | sed 's/=\(.*\)/="\1"/' | sed 's/^/export /' > /tmp/build_environment \
&&      chown -R valksor:valksor /home/valksor \
&&      echo 'alias upd="composer update -nW --ignore-platform-reqs"' >> /home/valksor/.bashrc \
&&      echo 'alias ins="composer install -n --ignore-platform-reqs"' >> /home/valksor/.bashrc \
&&      echo 'alias req="composer require -nW --ignore-platform-reqs"' >> /home/valksor/.bashrc \
&&      echo 'alias rem="composer remove -nW --ignore-platform-reqs"' >> /home/valksor/.bashrc \
&&      rm -rf \
            /usr/src/php \
            ~/.pearrc

FROM    ghcr.io/valksor/php/fpm:latest

ARG     CACHE_BUSTER=default
ARG     ARCH

USER    root

ENV     PHP_VERSION=8.5.0-dev
ENV     PHP_INI_DIR=/usr/local/etc/php
ENV     PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O3 -ftree-vectorize -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -march=native -mtune=native"
ENV     PHP_CPPFLAGS="$PHP_CFLAGS"
ENV     PHP_LDFLAGS="-Wl,-O3 -pie"

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
COPY --from=builder /usr/local/sbin/ /usr/local/sbin/
COPY --from=builder /usr/bin/ /usr/bin/
COPY --from=builder /run/php-fpm/ /run/php-fpm/

COPY    --from=composer:2                       /usr/bin/composer /usr/bin/

RUN     \
        set -eux \
&&      apt-get update \
&&      apt-get upgrade -y \
&&      apt-get install -y --no-install-recommends --allow-downgrades \
            fontconfig \
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
            /usr/local/bin/docker-php-ext-enable \
            /usr/local/bin/phpdbg \
            /usr/local/php/man/* \
            /usr/src/php \
            /var/cache/* \
            /usr/share/vim/vim90/doc \
            /usr/local/bin/install-php-extensions \
            /usr/share/man/* \
            /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini \
            /usr/local/etc/php/php.ini \
            /usr/local/etc/php-fpm.d/www.conf \
            /usr/lib/python3.*/__pycache__ \
            /usr/lib/python3.*/__phello__ \
            /usr/lib/python3.*/__hello__.py

COPY    php/ini/opcache.no-jit.ini /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini
COPY    php/ini/fpm/www-dev.conf /usr/local/etc/php-fpm.d/www.conf

USER    valksor

STOPSIGNAL SIGQUIT

WORKDIR /var/www/html

EXPOSE  9000

RUN     \
        set -eux \
&&      git config --global --add safe.directory "*"

CMD     ["php-fpm"]
