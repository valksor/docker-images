# syntax=docker/dockerfile:1.19.0
# Build stage - all compilation happens here
FROM    ghcr.io/valksor/debian:latest AS builder

ARG     CACHE_BUSTER=default

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV     container=docker \
        DEBIAN_FRONTEND=noninteractive \
        LANG=C.UTF-8 \
        LC_ALL=C.UTF-8

USER    root

WORKDIR /home/valksor

# Copy source code (only in builder stage - creates layers but they're discarded)
COPY    curl/source/ /home/valksor/curl
COPY    curl/wolfssl/ /home/valksor/wolfssl
COPY    curl/ngtcp2/ /home/valksor/ngtcp2
COPY    curl/nghttp3/ /home/valksor/nghttp3

RUN     \
        set -eux \
;       jobs="$(( $(nproc) - 1 ))" \
;       [ "$jobs" -lt 1 ] && jobs=1 \
;       apt-get update \
&&      apt-get upgrade -y \
&&      apt-get purge -y curl* \
&&      apt-get install -y --no-install-recommends make automake autoconf libtool gcc g++ libbrotli1 libbrotli-dev zstd libzstd-dev librtmp-dev librtmp1 rtmpdump \
        libgsasl-dev libgsasl18 libpsl-dev perl libnghttp2-dev nghttp2 libssl-dev libssl3t64 libpsl5t64 libssh2-1-dev libssh2-1t64 libldap-dev libldap2-dev libldap-common libldap-2.5-0 libldap2 \
&&      cd nghttp3 \
&&      autoreconf -fi \
&&      ./configure --prefix=/usr/local --enable-lib-only \
&&      make -j"$jobs" \
&&      make install \
&&      cd ../wolfssl \
&&      autoreconf -fi \
&&      CFLAGS="-DWOLFSSL_NO_STRICT -DWOLFSSL_NO_ASN_STRICT" ./configure \
          --disable-crypttests \
          --disable-examples \
          --disable-lighty \
          --disable-sniffer \
          --disable-wpas \
          --enable-alpn \
          --enable-altcertchains \
          --enable-base64encode \
          --enable-certgen \
          --enable-certgencache \
          --enable-certreq \
          --enable-chacha \
          --enable-curve25519 \
          --enable-earlydata \
          --enable-ecc \
          --enable-ed25519 \
          --enable-fastmath \
          --enable-openldap \
          --enable-opensslall \
          --enable-opensslextra \
          --enable-psk \
          --enable-quic \
          --enable-rsapss \
          --enable-secure-renegotiation \
          --enable-session-ticket \
          --enable-sha512 \
          --enable-tlsx \
&&      make -j"$jobs" \
&&      make install \
&&      cd ../ngtcp2 \
&&      autoreconf -fi \
&&      CFLAGS="-DWOLFSSL_NO_STRICT -DWOLFSSL_NO_ASN_STRICT" ./configure LDFLAGS="-Wl,-rpath,/usr/local/lib" --prefix=/usr/local --with-wolfssl --with-crypto-backend=wolfssl --enable-lib-only \
&&      make -j"$jobs" \
&&      make install \
&&      cd ../curl \
&&      autoreconf -fi \
&&      ./configure CFLAGS='-fstack-protector-strong -fpic -fpie -O3 -ftree-vectorize -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -march=native -mtune=native -DWOLFSSL_NO_STRICT -DWOLFSSL_NO_ASN_STRICT' LDFLAGS='-Wl,-rpath,/usr/local/lib' --prefix=/usr/local \
            --with-wolfssl --with-zlib --with-brotli --enable-ipv6 --with-libidn2 --enable-sspi --with-librtmp --with-ngtcp2 --with-nghttp3 --with-nghttp2 --enable-websockets --with-zstd --disable-manual --disable-docs \
            --with-libssh2 --enable-ldap --enable-ldaps \
&&      make -j"$jobs" \
&&      make install \
&&      env | sed 's/=\(.*\)/="\1"/' | sed 's/^/export /' > /tmp/build_environment \
&&      rm -rf /home/valksor/curl /home/valksor/wolfssl /home/valksor/ngtcp2 /home/valksor/nghttp3

# Final stage - minimal runtime image
FROM    ghcr.io/valksor/debian:latest

ARG     CACHE_BUSTER=default

LABEL org.opencontainers.image.title="Valksor cURL" \
    org.opencontainers.image.description="Optimized cURL image with wolfSSL, HTTP/3 support" \
    org.opencontainers.image.version="1.0.0" \
    org.opencontainers.image.source="https://github.com/valksor/docker-images" \
    org.opencontainers.image.licenses="MIT"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# CRITICAL: Preserve ALL environment variables from build process
COPY --from=builder /tmp/build_environment /tmp/
RUN set -a && source /tmp/build_environment && set +a

USER    root

WORKDIR /home/valksor

# Copy ONLY necessary files from builder stage
COPY --from=builder /usr/local/bin/curl /usr/local/bin/
COPY --from=builder /usr/local/lib/ /usr/local/lib/
COPY --from=builder /usr/local/include/ /usr/local/include/
COPY --from=builder /usr/local/share/ /usr/local/share/
COPY --from=builder /etc/ld.so.cache /etc/

# Install runtime dependencies only
RUN \
    set -eux \
;   apt-get update \
&&  apt-get upgrade -y \
&&  apt-get install -y --no-install-recommends \
        ca-certificates \
        libbrotli1 \
        zstd \
        libzstd1 \
        librtmp1 \
        libgsasl18 \
        libpsl5 \
        libnghttp2-14 \
        libssl3t64 \
        libssh2-1t64 \
        libldap-2.5-0 \
        libldap-common \
&&  apt-get autoremove -y --purge \
&&  rm -rf /var/cache/apt/* /var/lib/apt/lists/* /var/log/* /tmp/* /var/tmp/* \
&&  ldconfig

STOPSIGNAL SIGTERM

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl --version || exit 1

USER    valksor
