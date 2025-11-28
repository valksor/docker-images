# syntax=docker/dockerfile:1.4
FROM ghcr.io/valksor/minideb:sid

ARG CACHE_BUSTER=default

# Environment variables
ENV container=docker \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Labels
LABEL org.opencontainers.image.title="Valksor Debian Base" \
      org.opencontainers.image.description="Optimized Debian base image" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.source="https://github.com/valksor/docker-images" \
      org.opencontainers.image.licenses="MIT"

# Configuration files
COPY global/01_nodoc /etc/dpkg/dpkg.cfg.d/01_nodoc
COPY global/02_nocache /etc/apt/apt.conf.d/02_nocache
COPY global/compress /etc/initramfs-tools/conf.d/compress
COPY global/modules /etc/initramfs-tools/conf.d/modules
COPY global/90parallel /etc/apt/apt.conf.d/90parallel

COPY --chmod=0755 global/wait-for-it.sh /usr/local/bin/wait-for-it

# Main setup - consolidated into single layer
RUN \
    set -eux \
    && apt-get update \
    # Install only essential packages with no recommends \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        ca-certificates \
    # Create user and setup home directory \
    && groupadd --system --gid 1000 valksor \
    && useradd --system --uid 1000 -g valksor --shell /bin/bash --home /home/valksor valksor \
    && mkdir --parents /home/valksor \
    # Setup shell aliases \
    && echo 'alias ll="ls -lahs"' >> /home/valksor/.bashrc \
    && echo 'alias ll="ls -lahs"' >> /root/.bashrc \
    # Setup vim symlink \
    && ln -sf /usr/bin/vi /usr/bin/vim \
    # Update certificates \
    && update-ca-certificates \
    # Set proper permissions \
    && chown -R valksor:valksor /home/valksor \
    && chown root:root /usr/local/bin/wait-for-it \
    && chmod 0755 /usr/local/bin/wait-for-it \
    # Remove unnecessary SUID/SGID binaries (keeping essential ones) \
    && find /usr/local/bin /usr/bin /bin /sbin -type f \
        -a \( -perm -4000 -o -perm -2000 \) \
        -a ! -name 'su' -a ! -name 'sudo' -a ! -name 'passwd' -a ! -name 'gpasswd' \
        -exec chmod -s {} \; \
    # Comprehensive cleanup \
    && apt-get autoremove -y \
    && rm -rf \
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
        /*.deb

# Set proper signal handling
STOPSIGNAL SIGTERM

# Health check (basic - can be overridden)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD test -d /home/valksor || exit 1

# Switch to non-root user
USER valksor

WORKDIR /home/valksor
