# Docker build environment for the cert-eap strongSwan backport debs.
# Target: Ubuntu 26.04 (resolute) amd64 — matches the host release, so the
# resulting packages install cleanly on any Ubuntu 26.04 machine.
#
# Build image:      docker build -t tknika/strongswan-deb .
# Build packages:   bash build-in-docker.sh     (or see that script)
FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential devscripts debhelper quilt fakeroot \
        bzip2 xz-utils pkgconf autoconf automake libtool intltool curl \
        network-manager-dev libnma-dev libnma-gtk4-dev libnm-dev \
        libgtk-3-dev libgtk-4-dev libgtk-4-bin libsecret-1-dev \
        bison flex gperf dh-apparmor dpkg-dev \
        libiptc-dev libcap-dev libcurl4-openssl-dev libgcrypt20-dev \
        libgmp3-dev libkrb5-dev libldap2-dev libpam0g-dev libsqlite3-dev \
        libssl-dev libsystemd-dev libtss2-dev libxml2-dev po-debconf \
        systemd-dev tzdata \
    && rm -rf /var/lib/apt/lists/*

# unprivileged build user (uid 1000 matches the typical first user on Ubuntu;
# the ubuntu base image already ships this user, and the wrapper passes the
# host uid so artifacts are owned by the caller)
USER ubuntu
WORKDIR /work

CMD ["bash", "build-packages.sh"]
