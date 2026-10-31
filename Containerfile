# syntax=docker/dockerfile:1
ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-gnome
ARG BASE_TAG=stable

# Build context stage: scripts and files are bind-mounted, never copied into the final layers.
FROM scratch AS ctx
COPY build_files /build_files
COPY config /config
COPY artwork /artwork
COPY system_files /system_files

FROM ${BASE_IMAGE}:${BASE_TAG}

# Passed by CI so the image can trust its own cosign signatures. Both optional.
ARG IMAGE_OWNER=""
ARG IMAGE_NAME=""

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    IMAGE_OWNER="${IMAGE_OWNER}" IMAGE_NAME="${IMAGE_NAME}" bash /ctx/build_files/build.sh

RUN bootc container lint
