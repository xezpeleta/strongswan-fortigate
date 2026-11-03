#!/bin/bash
# Enable the strongswan-deb-packages apt repository on Ubuntu 26.04 and
# (optionally) install the cert-eap backport.
#
# Usage:
#   sudo bash add-apt-source.sh              # just enable the repo
#   sudo bash add-apt-source.sh --install    # enable + install packages
#
# Or one-liner (check the URL in a browser first!):
#   curl -fsSL https://xezpeleta.github.io/strongswan-deb-packages/add-apt-source.sh | sudo bash -s -- --install
set -e

REPO_URL="https://xezpeleta.github.io/strongswan-deb-packages"
KEYRING="/usr/share/keyrings/xezpeleta-strongswan-certeap.gpg"
SOURCES_FILE="/etc/apt/sources.list.d/xezpeleta-strongswan-certeap.sources"
PACKAGES="network-manager-strongswan strongswan-nm"

[ "$(id -u)" = 0 ] || { echo "ERROR: run as root (sudo)"; exit 1; }

. /etc/os-release
if [ "${ID_LIKE:-$ID}" != ubuntu ] || [ "$VERSION_ID" != "26.04" ]; then
    echo "ERROR: this repository targets Ubuntu 26.04 (resolute); you are on ${PRETTY_NAME}."
    exit 1
fi

echo "==> fetching repository signing key"
curl -fsSL "$REPO_URL/apt-repo.key" | gpg --dearmor -o "$KEYRING"
chmod 0644 "$KEYRING"

echo "==> writing apt source (suite: resolute)"
cat > "$SOURCES_FILE" <<EOF
Types: deb
URIs: $REPO_URL
Suites: resolute
Components: main
Signed-By: $KEYRING
EOF

echo "==> apt update"
apt-get update || { echo "ERROR: apt update failed — see errors above"; exit 1; }

echo
echo "Repository enabled. Install the backport with:"
echo "  sudo apt install $PACKAGES"
echo "(future official Ubuntu updates automatically take precedence)"

if [ "${1:-}" = "--install" ]; then
    echo
    echo "==> installing $PACKAGES"
    apt-get install -y $PACKAGES
fi
