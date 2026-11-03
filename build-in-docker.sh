#!/bin/bash
# Build the cert-eap backport debs inside Docker (no root/sudo needed on host,
# no build dependencies installed on the host).
#
# Requirements: docker working as your user (e.g. "docker" group membership).
#
# Output: dist/*.deb owned by you, next to this script.
set -e
cd "$(dirname "$0")"

echo "==> building docker image tknika/strongswan-deb (cached after first run)"
docker build -t tknika/strongswan-deb .

echo "==> fetching sources (if needed) and building packages in container"
docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/home/ubuntu \
    -v "$PWD":/work \
    -w /work \
    tknika/strongswan-deb \
    bash -c "bash fetch-sources.sh && bash build-packages.sh"

echo
echo "Done. Install with:"
echo "  sudo apt install ./dist/network-manager-strongswan_1.6.4-1+certeap1_amd64.deb ./dist/strongswan-nm_6.0.4-1ubuntu3.2+certeap1_amd64.deb"
