#!/bin/bash
# Enable the strongswan-fortigate apt repository on Ubuntu 26.04 and
# (optionally) install the FortiGate compatibility packages.
#
# Usage (one-liner):
#   curl -fsSL https://xezpeleta.github.io/strongswan-fortigate/add-apt-source.sh | sudo bash
#   sudo apt install strongswan-fortigate
#
# Or everything in one go:
#   curl -fsSL https://xezpeleta.github.io/strongswan-fortigate/add-apt-source.sh | sudo bash -s -- --install
#
# Or the cautious way (read the script first):
#   curl -fsSL .../add-apt-source.sh -o /tmp/add-apt-source.sh
#   less /tmp/add-apt-source.sh
#   sudo bash /tmp/add-apt-source.sh --install
set -e

REPO_URL="https://xezpeleta.github.io/strongswan-fortigate"
KEYRING="/usr/share/keyrings/xezpeleta-strongswan-fortigate.gpg"
SOURCES_FILE="/etc/apt/sources.list.d/xezpeleta-strongswan-fortigate.sources"

# remove files from the previous repo name/naming scheme, if present
rm -f /usr/share/keyrings/xezpeleta-strongswan-certeap.gpg \
      /etc/apt/sources.list.d/xezpeleta-strongswan-certeap.sources
PACKAGES="strongswan-fortigate"

[ "$(id -u)" = 0 ] || { echo "ERROR: run as root (sudo)"; exit 1; }

. /etc/os-release
if [ "${ID:-}" != ubuntu ] || [ "${VERSION_CODENAME:-}" != resolute ]; then
    echo "ERROR: this repository targets Ubuntu 26.04 'resolute' (any 26.04.x point release);"
    echo "       you are on ${PRETTY_NAME:-unknown}."
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
if [ "${1:-}" = "--install" ]; then
    echo "==> installing $PACKAGES"
    apt-get install -y $PACKAGES
else
    echo "Repository enabled. Install the FortiGate packages with:"
    echo "  sudo apt install $PACKAGES"
    echo "(future official Ubuntu updates automatically take precedence)"
fi
