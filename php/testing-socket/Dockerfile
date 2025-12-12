ARG     BASE_TAG=""
FROM    ghcr.io/valksor/php/fpm-testing${BASE_TAG}

ARG     CACHE_BUSTER=default

USER    root

RUN     \
        set -eux \
&&      sed -i -e "s|listen = 9000|listen = /tmp/sockets/php-fpm.sock|g" /usr/local/etc/php-fpm.d/www.conf

USER    valksor

ENV     FCGI_CONNECT=/tmp/sockets/php-fpm.sock
