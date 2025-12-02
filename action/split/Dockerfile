FROM    ghcr.io/valksor/debian:latest

ARG     CACHE_BUSTER=default

ENV     container=docker
ENV     DEBIAN_FRONTEND=noninteractive

USER    root

WORKDIR /

COPY    action/split/entrypoint.sh .

RUN     \
        set -eux \
&&      chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
