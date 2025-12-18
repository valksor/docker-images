ARG     BASE_TAG
FROM    ghcr.io/valksor/php/fpm${BASE_TAG}

ARG     CACHE_BUSTER=default

LABEL org.opencontainers.image.title="Valksor PHP FPM Socket" \
    org.opencontainers.image.description="Optimized PHP-FPM image with Unix socket support" \
    org.opencontainers.image.source="https://github.com/valksor/docker-images" \
    org.opencontainers.image.licenses="MIT"

USER    root

RUN     \
        set -eux \
&&      sed -i -e "s|listen = 9000|listen = /tmp/sockets/php-fpm.sock|g" /usr/local/etc/php-fpm.d/www.conf

USER    valksor

ENV     FCGI_CONNECT=/tmp/sockets/php-fpm.sock
