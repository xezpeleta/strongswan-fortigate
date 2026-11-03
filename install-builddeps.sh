#!/bin/bash
# Install all build dependencies for both packages (run with sudo).
# Compatible with: Ubuntu 26.04 (resolute)
set -e

apt-get update

# common build tooling
apt-get install -y --no-install-recommends \
    build-essential devscripts debhelper quilt fakeroot \
    bzip2 xz-utils pkgconf autoconf automake libtool intltool

# network-manager-strongswan (1.6.4) build-deps
apt-get install -y --no-install-recommends \
    network-manager-dev libnma-dev libnma-gtk4-dev libnm-dev \
    libgtk-3-dev libgtk-4-dev libgtk-4-bin libsecret-1-dev

# strongswan (6.0.4) build-deps (from strongswan_6.0.4-1ubuntu3.2.dsc)
apt-get install -y --no-install-recommends \
    bison flex gperf dh-apparmor dpkg-dev \
    libiptc-dev libcap-dev libcurl4-openssl-dev libgcrypt20-dev \
    libgmp3-dev libkrb5-dev libldap2-dev libpam0g-dev libsqlite3-dev \
    libssl-dev libsystemd-dev libtss2-dev libxml2-dev po-debconf \
    systemd-dev tzdata

echo
echo "All build dependencies installed."
