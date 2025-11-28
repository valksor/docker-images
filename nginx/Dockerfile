# syntax=docker/dockerfile:1.19.0

FROM    nginx:mainline-trixie AS builder

ARG     CACHE_BUSTER=default

ENV     container=docker \
        DEBIAN_FRONTEND=noninteractive \
        LANG=C.UTF-8 \
        LC_ALL=C.UTF-8

SHELL   ["/bin/bash", "-o", "pipefail", "-c"]

# Labels
LABEL org.opencontainers.image.title="Valksor Nginx" \
    org.opencontainers.image.description="Optimized Nginx image" \
    org.opencontainers.image.version="1.0.0" \
    org.opencontainers.image.source="https://github.com/valksor/docker-images" \
    org.opencontainers.image.licenses="MIT"


COPY    global/01_nodoc  /etc/dpkg/dpkg.cfg.d/01_nodoc
COPY    global/02_nocache /etc/apt/apt.conf.d/02_nocache
COPY    global/compress  /etc/initramfs-tools/conf.d/compress
COPY    global/modules   /etc/initramfs-tools/conf.d/modules
COPY    global/90parallel   /etc/apt/apt.conf.d/90parallel

USER    root

RUN     \
        set -eux \
&&      usermod -l valksor nginx \
&&      usermod -d /home/valksor -m valksor \
&&      groupmod -n valksor nginx \
&&      usermod -u 1000 valksor \
&&      groupmod -g 1000 valksor \
&&      mkdir --parents /home/valksor \
&&      mkdir --parents /etc/nginx/stream.d \
&&      mkdir --parents /etc/nginx/modules \
&&      echo >> /home/valksor/.bashrc \
&&      echo 'alias ll="ls -lahs"' >> /home/valksor/.bashrc \
&&      echo 'alias ll="ls -lahs"' >> /root/.bashrc \
&&      apt-get update \
&&      apt-get upgrade -y \
&&      apt-get install -y --no-install-recommends --no-install-suggests \
            bash procps telnet iputils-ping build-essential libpcre2-dev zlib1g-dev libssl-dev git wget cmake ca-certificates \
&&      update-ca-certificates \
&&      find /usr/local/bin /usr/bin /bin /sbin -type f \
            -a \( -perm -4000 -o -perm -2000 \) \
            -a ! -name 'su' -a ! -name 'sudo' -a ! -name 'passwd' -a ! -name 'gpasswd' \
            -exec chmod -s {} \; \
&&      NGINX_VERSION=$(nginx -v 2>&1 | sed 's/.*nginx\///; s/ .*//') \
&&      cd /tmp \
&&      wget "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
&&      tar xzf "nginx-${NGINX_VERSION}.tar.gz" \
&&      git clone --recursive https://github.com/google/ngx_brotli.git \
&&      cd ngx_brotli/deps/brotli \
&&      mkdir out && cd out \
&&      cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF .. \
&&      cmake --build . --config Release --target brotlienc \
&&      cd /tmp/nginx-${NGINX_VERSION} \
&&      nginx -V 2>&1 | grep -o 'configure arguments: .*' | sed 's/configure arguments: //' > /tmp/nginx_args \
&&      eval "./configure $(cat /tmp/nginx_args) --with-compat --add-dynamic-module=../ngx_brotli" \
&&      make modules \
&&      cp objs/ngx_http_brotli_*.so /etc/nginx/modules/ \
&&      cd / && rm -rf /tmp/* \
&&      apt-get purge -y build-essential libpcre2-dev zlib1g-dev libssl-dev git wget cmake \
&&      apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
&&      apt-get autoremove -y --purge \
&&      rm -rf \
            /etc/nginx/conf.d/* \
            /home/valksor/*.deb \
            /*.deb \
            /var/cache/apt/* \
            /var/lib/apt/lists/* \
            /var/log/* \
            /var/cache/debconf/*-old \
            /tmp/* \
            /var/tmp/* \
            /usr/share/man \
            /usr/share/doc \
            /usr/share/info \
            /usr/share/groff \
            /usr/share/locale/?? \
            /usr/share/locale/??_* \
            /usr/share/i18n \
            /usr/local/share/man \
            /usr/lib/python3.*/__pycache__ \
            /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh \
            /etc/nginx/nginx.conf \
&&      mkdir -p /var/log/nginx \
&&      chown -R valksor:valksor /var/cache/nginx \
&&      chown -R valksor:valksor /var/log/nginx \
&&      chown -R valksor:valksor /etc/nginx/conf.d \
&&      chown -R valksor:valksor /etc/nginx/stream.d \
&&      chown -R valksor:valksor /etc/nginx/modules \
&&      touch /var/run/nginx.pid \
&&      chown -R valksor:valksor /var/run/nginx.pid \
&&      usermod -a -G dialout valksor \
&&      ls -la /etc/nginx/modules/

COPY    nginx/nginx.conf /etc/nginx/nginx.conf

WORKDIR /var/www/html

STOPSIGNAL SIGQUIT

EXPOSE  80
EXPOSE  443/tcp
EXPOSE  443/udp

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD     ["nginx", "-g", "daemon off;"]

USER    valksor
