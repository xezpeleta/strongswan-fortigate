#!/bin/bash
# Assemble the buildable source trees in pkg/ from:
#   - sources/        : original Ubuntu 26.04 source packages (committed to git)
#   - debian-overlay/ : our changelog + cert-eap backport patches
# If a source file is missing from sources/, it is downloaded from
# archive.ubuntu.com first.
set -e
cd "$(dirname "$0")"

NM_BASE=http://archive.ubuntu.com/ubuntu/pool/universe/n/network-manager-strongswan
SS_BASE=http://archive.ubuntu.com/ubuntu/pool/main/s/strongswan

fetch() { # fetch <url> <file>
    [ -f "sources/$2" ] || { echo "download: $2"; curl -fL --retry 3 -o "sources/$2" "$1/$2"; }
}

mkdir -p sources
fetch $NM_BASE network-manager-strongswan_1.6.4.orig.tar.bz2
fetch $NM_BASE network-manager-strongswan_1.6.4-1.debian.tar.xz
fetch $SS_BASE strongswan_6.0.4.orig.tar.bz2
fetch $SS_BASE strongswan_6.0.4-1ubuntu3.2.debian.tar.xz

echo "==> assembling pkg/ source trees"
rm -rf pkg
mkdir -p pkg

tar xjf sources/network-manager-strongswan_1.6.4.orig.tar.bz2 -C pkg
mv pkg/NetworkManager-strongswan-1.6.4 pkg/network-manager-strongswan-1.6.4
tar xJf sources/network-manager-strongswan_1.6.4-1.debian.tar.xz \
    -C pkg/network-manager-strongswan-1.6.4
cp -r debian-overlay/network-manager-strongswan/* pkg/network-manager-strongswan-1.6.4/debian/

tar xjf sources/strongswan_6.0.4.orig.tar.bz2 -C pkg
tar xJf sources/strongswan_6.0.4-1ubuntu3.2.debian.tar.xz \
    -C pkg/strongswan-6.0.4
cp -r debian-overlay/strongswan/* pkg/strongswan-6.0.4/debian/

echo "==> pkg/ ready:"
ls -d pkg/*
