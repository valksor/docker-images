# syntax=docker/dockerfile:1.19.0
FROM ghcr.io/valksor/debian:latest

ARG CACHE_BUSTER=default

ENV container=docker \
    DEBIAN_FRONTEND=noninteractive

ARG GO_VERSION
ENV GO_VERSION=${GO_VERSION}

ARG GO_ROOT

LABEL org.opencontainers.image.title="Valksor Go" \
    org.opencontainers.image.description="Go development image" \
    org.opencontainers.image.source="https://github.com/valksor/docker-images" \
    org.opencontainers.image.licenses="MIT"

USER root

RUN \
    set -eux \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends make g++ gcc libc6-dev \
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

ENV GOTOOLCHAIN=local
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

COPY ${GO_ROOT}/go /usr/local/go

RUN \
    set -eux \
    && mkdir -p "$GOPATH/src" "$GOPATH/bin" \
    && chmod -R 1777 "$GOPATH" \
    && chown -R valksor:valksor $GOPATH

WORKDIR $GOPATH

USER valksor
