# syntax=docker/dockerfile:1

# renovate: datasource=github-releases depName=rclone/rclone extractVersion=v(?<version>.*)$
ARG RCLONE_VERSION=1.73.2
# renovate: datasource=github-releases depName=restic/restic extractVersion=v(?<version>.*)$
ARG RESTIC_VERSION=0.18.1

FROM --platform=$TARGETPLATFORM docker.io/rclone/rclone:${RCLONE_VERSION} AS rclone

FROM --platform=$TARGETPLATFORM docker.io/restic/restic:${RESTIC_VERSION} AS restic

FROM ghcr.io/linuxserver/baseimage-alpine:3.23

ARG BUILD_DATE
ARG VERSION
LABEL build_version="Restic backup version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="restic-backup-docker"

RUN \
    echo "**** install runtime packages ****" && \
    apk add --no-cache \
        curl \
        mailx \
        nfs-utils \
        util-linux && \
    echo "**** cleanup ****" && \
    rm -rf /tmp/*

COPY --from=rclone /usr/local/bin/rclone /usr/bin/rclone
COPY --from=restic /usr/bin/restic /usr/bin/restic

RUN \
    mkdir -p /mnt/restic /config/logs && \
    touch /config/logs/cron.log

ENV RESTIC_REPOSITORY=/mnt/restic
ENV RESTIC_PASSWORD=""
ENV RESTIC_TAG=""
ENV NFS_TARGET=""
ENV BACKUP_CRON="0 */6 * * *"
ENV CHECK_CRON=""
ENV RESTIC_INIT_ARGS=""
ENV RESTIC_FORGET_ARGS=""
ENV RESTIC_JOB_ARGS=""
ENV RESTIC_DATA_SUBSET=""
ENV MAILX_ARGS=""
ENV RESTIC_LOG_DIR=/config/logs
ENV OS_AUTH_URL=""
ENV OS_PROJECT_ID=""
ENV OS_PROJECT_NAME=""
ENV OS_USER_DOMAIN_NAME="Default"
ENV OS_PROJECT_DOMAIN_ID="default"
ENV OS_USERNAME=""
ENV OS_PASSWORD=""
ENV OS_REGION_NAME=""
ENV OS_INTERFACE=""
ENV OS_IDENTITY_API_VERSION=3
ENV BACKUP_SOURCES=""

VOLUME /data /config

COPY backup.sh /bin/backup
COPY check.sh /bin/check
COPY root/ /

RUN \
    chmod +x /etc/s6-overlay/s6-rc.d/init-restic-config/run && \
    chmod +x /bin/backup /bin/check
