# syntax=docker/dockerfile:1.19.0

ARG     VERSION

FROM    postgres:${VERSION}-trixie

ARG     VERSION
ARG     CACHE_BUSTER=default

LABEL org.opencontainers.image.title="Valksor Postgres ${VERSION}" \
    org.opencontainers.image.description="Optimized Postgres ${VERSION} image" \
    org.opencontainers.image.source="https://github.com/valksor/docker-images" \
    org.opencontainers.image.licenses="MIT"

SHELL   ["/bin/bash", "-o", "pipefail", "-c"]

ENV     container=docker \
        DEBIAN_FRONTEND=noninteractive \
        LANG=C.UTF-8 \
        LC_ALL=C.UTF-8

COPY    global/01_nodoc   /etc/dpkg/dpkg.cfg.d/01_nodoc
COPY    global/02_nocache /etc/apt/apt.conf.d/02_nocache
COPY    global/compress   /etc/initramfs-tools/conf.d/compress
COPY    global/modules    /etc/initramfs-tools/conf.d/modules
COPY    global/90parallel /etc/apt/apt.conf.d/90parallel

ARG     POSTGRES_LOCALE=en_US

USER    root

RUN     chown -R postgres:postgres /var/lib/postgresql/
RUN     localedef -i $POSTGRES_LOCALE -c -f UTF-8 -A /usr/share/locale/locale.alias ${POSTGRES_LOCALE}.UTF-8

USER    postgres

ENV     POSTGRES_INITDB_ARGS="--lc-collate=${POSTGRES_LOCALE}.utf8 --lc-ctype=${POSTGRES_LOCALE}.utf8"

USER    root

RUN     \
        set -eux \
&&      apt-get update \
&&      apt-get upgrade -y \
&&      apt-get install -y --no-install-recommends --no-install-suggests \
            postgresql-contrib ca-certificates \
&&      mkdir -p /backup \
&&      chown -R postgres:postgres /backup \
&&      mkdir -p /docker-entrypoint-initdb.d \
&&      mkdir -p /backup/scripts \
&&      mkdir -p /backup/dumps \
&&      update-ca-certificates \
&&      find /usr/local/bin /usr/bin /bin /sbin -type f \
            -a \( -perm -4000 -o -perm -2000 \) \
            -a ! -name 'su' -a ! -name 'sudo' -a ! -name 'passwd' -a ! -name 'gpasswd' \
            -exec chmod -s {} \; \
&&      apt-get autoremove -y --purge \
&&      rm -rf \
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
            /usr/lib/python3.*/__phello__ \
            /usr/lib/python3.*/__hello__.py \
            /root/.cache

COPY    --chmod=0755 postgres/pg_backup.config /backup/scripts/pg_backup.config
COPY    --chmod=0755 postgres/pg_backup_rotated.sh /backup/scripts/pg_backup_rotated.sh
COPY    --chmod=0755 postgres/init.sh /docker-entrypoint-initdb.d/init.sh
COPY    --chmod=0755 postgres/custom_entrypoint.sh /usr/local/bin/custom_entrypoint.sh
COPY    --chmod=0755 postgres/custom_entrypoint_18.sh /usr/local/bin/custom_entrypoint_18.sh

RUN     \
        if [ "${VERSION}" = "18" ]; then \
            cp /usr/local/bin/custom_entrypoint_18.sh /usr/local/bin/custom_entrypoint.sh; \
        fi
COPY    --chmod=0755 postgres/install_extensions.sql /install_extensions.sql

ENTRYPOINT ["/usr/local/bin/custom_entrypoint.sh"]
