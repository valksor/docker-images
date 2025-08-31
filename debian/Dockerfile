FROM debian:sid-slim AS builder

ARG CACHE_BUSTER=default

ENV container=docker
ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY global/01_nodoc /etc/dpkg/dpkg.cfg.d/01_nodoc
COPY global/02_nocache /etc/apt/apt.conf.d/02_nocache
COPY global/compress /etc/initramfs-tools/conf.d/compress
COPY global/modules /etc/initramfs-tools/conf.d/modules
COPY global/90parallel /etc/apt/apt.conf.d/90parallel

COPY --chmod=0755 global/wait-for-it.sh /usr/local/bin/wait-for-it

USER root

RUN  \
  set -eux \
&& apt-get update \
&& groupadd --system --gid 1000 valksor \
&& useradd --system --uid 1000 -g valksor --shell /bin/bash --home /home/valksor valksor \
&& passwd -d valksor \
&& mkdir --parents /home/valksor \
&& echo 'alias ll="ls -lahs"' >> /home/valksor/.bashrc \
&& echo 'alias ll="ls -lahs"' >> /root/.bashrc \
&& chown -R valksor:valksor /home/valksor \
&& apt-get install -y --no-install-recommends \
   bash ca-certificates cron git iputils-ping jq openssh-client pkg-config procps telnet tzdata unzip util-linux vim-tiny wget \
&& chown valksor:valksor /usr/local/bin/wait-for-it \
&& chmod +x /usr/local/bin/wait-for-it \
&& ln -sf /usr/bin/vi /usr/bin/vim \
&& update-ca-certificates \
&& rm -rf \
   /var/cache/* \
   /usr/share/man \
   /usr/share/doc \
   /usr/local/share/man \
   /var/lib/apt/lists/* \
   /*.deb \
   /var/cache/apt/archives/*

RUN  \
  set -eux \
&& mkdir --parents /home/valksor/environment \
&& env | grep -v '^HOME=' | sed 's/^\([^=]*\)=\(.*\)$/\1=\2/' >> /home/valksor/environment/environment.txt

COPY --chmod=0755 debian/env_entrypoint.sh /home/valksor/env_entrypoint.sh

FROM debian:sid-slim

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY global/01_nodoc /etc/dpkg/dpkg.cfg.d/01_nodoc
COPY global/02_nocache /etc/apt/apt.conf.d/02_nocache
COPY global/compress /etc/initramfs-tools/conf.d/compress
COPY global/modules /etc/initramfs-tools/conf.d/modules
COPY global/90parallel /etc/apt/apt.conf.d/90parallel

COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /etc/shadow /etc/shadow

COPY --from=builder /usr/local/share/ca-certificates /usr/local/share/ca-certificates

COPY --from=builder /home/valksor /home/valksor
COPY --from=builder /root /root

COPY --from=builder /usr /usr
COPY --from=builder /lib /lib
COPY --from=builder /sbin /sbin
COPY --from=builder /bin /bin

COPY --from=builder /usr/local/bin/wait-for-it /usr/local/bin/wait-for-it

USER root

RUN chown -R valksor:valksor /home/valksor

USER valksor

WORKDIR /home/valksor

ENTRYPOINT ["/home/valksor/env_entrypoint.sh"]
