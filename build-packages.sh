#!/bin/bash
# Build both deb packages from the assembled pkg/ trees.
# Run fetch-sources.sh first (build-in-docker.sh does this automatically).
#
# Produces:
#   dist/network-manager-strongswan_1.6.4-1+certeap1_amd64.deb
#   dist/strongswan-nm_6.0.4-1ubuntu3.2+certeap1_amd64.deb  (+ other strongswan debs)
set -e
cd "$(dirname "$0")"

for d in pkg/network-manager-strongswan-1.6.4 pkg/strongswan-6.0.4 pkg/strongswan-fortigate-*; do
    [ -d "$d" ] || { echo "ERROR: $d missing — run fetch-sources.sh first"; exit 1; }
done
mkdir -p dist

echo "==> [1/3] building network-manager-strongswan 1.6.4-1+certeap1"
(cd pkg/network-manager-strongswan-1.6.4 && dpkg-buildpackage -b -uc -us)

echo "==> [2/3] building strongswan 6.0.4-1ubuntu3.2+fortigate1"
(cd pkg/strongswan-6.0.4 && dpkg-buildpackage -b -uc -us)

echo "==> [3/3] building strongswan-fortigate metapackage"
(cd pkg/strongswan-fortigate-*/ && dpkg-buildpackage -b -uc -us)

echo "==> collecting debs into dist/"
cp -v pkg/*.deb dist/
rm -f pkg/*.deb pkg/*.build pkg/*.buildinfo pkg/*.changes 2>/dev/null || true

echo
echo "=== Metapackage (install this one):"
ls -la dist/strongswan-fortigate_*.deb
