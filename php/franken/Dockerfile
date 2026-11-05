ARG     BASE_TAG
FROM    ghcr.io/valksor/php/zts${BASE_TAG} AS builder

ARG     CACHE_BUSTER=default
ARG     PHP_VERSION
ARG     FRANKENPHP_VERSION=dev

USER    root

ENV     PHP_VERSION=${PHP_VERSION}
ENV     PHP_INI_DIR=/usr/local/etc/php
ENV     PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O3 -ftree-vectorize -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -march=native -mtune=native"
ENV     PHP_CPPFLAGS="$PHP_CFLAGS"
ENV     PHP_LDFLAGS="-Wl,-O3 -pie"
ENV     PHP_BUILD_PROVIDER='https://github.com/valksor/docker-images'
ENV     PHP_UNAME="Linux (arm64) - Docker"
ENV     FRANKENPHP_VERSION=${FRANKENPHP_VERSION}
ENV     GOTOOLCHAIN=local

# Install Go toolchain
COPY    --from=golang:1.27   /usr/local/go /usr/local/go
ENV     PATH=/usr/local/go/bin:$PATH

# Install build dependencies for FrankenPHP
RUN     \
        set -eux \
&&      apt-get update \
&&      apt-get upgrade -y \
&&      apt-get install -y --no-install-recommends --allow-downgrades \
            libcap2-bin \
            make libc-dev libc6-dev gcc g++ \
            cmake git libargon2-dev libbrotli-dev libcurl4-openssl-dev \
            libonig-dev libedit-dev libsodium-dev libsqlite3-dev \
            libssl-dev libxml2-dev zlib1g-dev

# Install e-dant/watcher for file watching support
WORKDIR /usr/local/src/watcher
RUN     \
        set -eux \
&&      git clone --depth=1 --single-branch https://github.com/e-dant/watcher.git . \
&&      cmake -S . -B build -DCMAKE_BUILD_TYPE=Release \
&&      cmake --build build \
&&      cmake --install build \
&&      ldconfig

# Copy FrankenPHP source (cloned in GitHub Action)
WORKDIR /go/src/app
COPY    php/frankenphp/    /go/src/app/
# Upstream FrankenPHP now carries its own PHP_VERSION_ID gates for php-src master
# (at >= 80700: C11 atomics, the sapi initializer, and the output_handler API), so no
# local patches are needed against the php-src master this image builds from. If that
# changes, the build fails at the CGO compile; the retired grep-guarded patch pattern
# is recoverable via git log -- php/patches/
RUN     \
        set -eux \
&&      go mod download

# Set up CGO environment for linking against PHP
ENV     CGO_ENABLED=1
ENV     CGO_CFLAGS="-DFRANKENPHP_VERSION=${FRANKENPHP_VERSION} -I/usr/local/include/php -I/usr/local/include/php/main -I/usr/local/include/php/Zend -I/usr/local/include/php/TSRM -I/usr/local/include/php/ext ${PHP_CFLAGS}"
ENV     CGO_CPPFLAGS="-I/usr/local/include/php -I/usr/local/include/php/main -I/usr/local/include/php/Zend -I/usr/local/include/php/TSRM -I/usr/local/include/php/ext ${PHP_CPPFLAGS}"
ENV     CGO_LDFLAGS="-L/usr/local/lib -lphp -lssl -lcrypto -ledit -largon2 -lcurl -lonig -lz ${PHP_LDFLAGS}"

# Install xcaddy and build FrankenPHP
RUN     \
        set -eux \
&&      go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest \
&&      CGO_LDFLAGS="$CGO_LDFLAGS -s -w" /root/go/bin/xcaddy build \
            --output frankenphp \
            --with github.com/dunglas/frankenphp/caddy=/go/src/app/caddy \
            --with github.com/dunglas/frankenphp=/go/src/app \
            --with github.com/dunglas/mercure/caddy \
            --with github.com/dunglas/vulcain/caddy \
            --with github.com/dunglas/caddy-cbrotli \
&&      mv frankenphp /usr/local/bin/frankenphp \
&&      mkdir --parents /usr/local/share/doc/frankenphp /usr/local/share/doc/caddy /usr/local/share/doc/watcher \
&&      cp /go/src/app/LICENSE /usr/local/share/doc/frankenphp/LICENSE \
&&      watcher_license="$(find /usr/local/src/watcher -maxdepth 1 -type f -iname 'LICENSE*' -print -quit)" \
&&      if [ -z "$watcher_license" ]; then echo 'watcher: no LICENSE file in /usr/local/src/watcher' >&2; exit 1; fi \
&&      cp "$watcher_license" /usr/local/share/doc/watcher/LICENSE \
&&      go_mod_info="$(go version -m /usr/local/bin/frankenphp)" \
&&      caddy_version="$(printf '%s\n' "$go_mod_info" | awk '$2 == "github.com/caddyserver/caddy/v2" { print $3 }')" \
&&      if [ -z "$caddy_version" ]; then echo 'caddy: version not found in frankenphp build info' >&2; exit 1; fi \
&&      caddy_license="$(go env GOMODCACHE)/github.com/caddyserver/caddy/v2@${caddy_version}/LICENSE" \
&&      if [ ! -f "$caddy_license" ]; then echo "caddy: no LICENSE at $caddy_license" >&2; exit 1; fi \
&&      cp "$caddy_license" /usr/local/share/doc/caddy/ \
&&      for caddy_notice in "$(dirname "$caddy_license")"/NOTICE*; do \
            if [ -f "$caddy_notice" ]; then cp "$caddy_notice" /usr/local/share/doc/caddy/; fi \
        done \
&&      setcap cap_net_bind_service=+ep /usr/local/bin/frankenphp \
&&      /usr/local/bin/frankenphp version

# Create Caddyfile directory and copy example
RUN     mkdir -p /etc/caddy
COPY    php/caddy/Caddyfile.example /etc/caddy/Caddyfile

RUN     \
        set -eux \
&&      apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
            make libc-dev libc6-dev gcc g++ cmake git \
            libargon2-dev libbrotli-dev libcurl4-openssl-dev libonig-dev \
            libedit-dev libsodium-dev libsqlite3-dev libssl-dev \
            libxml2-dev zlib1g-dev \
&&      rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/log/* /tmp/* /var/tmp/* \
            /usr/local/src/watcher /root/go /usr/local/go

FROM    ghcr.io/valksor/php/zts${BASE_TAG}

ARG     CACHE_BUSTER=default
ARG     PHP_VERSION

LABEL org.opencontainers.image.title="Valksor FrankenPHP" \
    org.opencontainers.image.description="FrankenPHP - Modern PHP application server with extensions" \
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
ENV     XDG_CONFIG_HOME=/config
ENV     XDG_DATA_HOME=/data

# Copy FrankenPHP binary and watcher library
COPY --from=builder /usr/local/bin/frankenphp /usr/local/bin/frankenphp
COPY --from=builder /usr/local/lib/libwatcher* /usr/local/lib/
COPY --from=builder /usr/local/share/doc/frankenphp /usr/local/share/doc/frankenphp
COPY --from=builder /usr/local/share/doc/caddy /usr/local/share/doc/caddy
COPY --from=builder /usr/local/share/doc/watcher /usr/local/share/doc/watcher

# Copy Caddyfile configuration
COPY --from=builder /etc/caddy /etc/caddy

# Copy PHP configuration
COPY    php/ini/zz.ini /usr/local/etc/php/conf.d/zz.ini
COPY    php/ini/opcache.ini /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

# Install runtime dependencies
RUN     \
        set -eux \
&&      apt-get update \
# dist-upgrade, not upgrade: sid transitions can need package adds/removals to move perl-base; plain upgrade holds it back and perl postinsts break on the skew
&&      apt-get dist-upgrade -y --no-install-recommends \
&&      apt-get install -y --no-install-recommends --allow-downgrades \
            libcap2-bin libstdc++6 \
&&      apt-get autoremove -y --purge \
&&      rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/log/* /tmp/* /var/tmp/* \
&&      ldconfig \
&&      setcap cap_net_bind_service=+ep /usr/local/bin/frankenphp \
&&      /usr/local/bin/frankenphp version \
&&      mkdir -p /config /data /var/log/caddy \
&&      chown -R valksor:valksor /config /data /var/log/caddy \
&&      out="$(ldd /usr/local/bin/frankenphp)" \
&&      if grep 'not found' <<<"$out"; then echo 'ldd: unresolved libraries' >&2; exit 1; fi \
&&      if grep -i readline <<<"$out"; then echo 'GPL libreadline is linked' >&2; exit 1; fi \
&&      for shipped_license in /usr/local/share/doc/frankenphp/LICENSE /usr/local/share/doc/caddy/LICENSE /usr/local/share/doc/watcher/LICENSE; do \
            if [ ! -s "$shipped_license" ]; then echo "missing or empty license: $shipped_license" >&2; exit 1; fi \
        done

USER    valksor

STOPSIGNAL SIGQUIT

WORKDIR /var/www/html

EXPOSE  80
EXPOSE  443
EXPOSE  443/udp
EXPOSE  2019

HEALTHCHECK CMD curl -f http://localhost:2019/metrics || exit 1

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
