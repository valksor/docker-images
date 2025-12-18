FROM    ghcr.io/valksor/debian:latest

ARG     CACHE_BUSTER=default

LABEL org.opencontainers.image.title="Valksor Split Action" \
    org.opencontainers.image.description="GitHub Action for splitting monorepo" \
    org.opencontainers.image.source="https://github.com/valksor/docker-images" \
    org.opencontainers.image.licenses="MIT"

ENV     container=docker
ENV     DEBIAN_FRONTEND=noninteractive

USER    root

WORKDIR /

COPY    action/split/entrypoint.sh .

RUN     \
        set -eux \
&&      chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
