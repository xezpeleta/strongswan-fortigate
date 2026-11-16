#!/bin/bash
# Publish everything to GitHub (run after update-apt-repo.sh):
#   - main branch  : this source repo
#   - gh-pages     : the signed apt repository (served by GitHub Pages)
#   - GitHub release: dist/*.deb as release assets
#
# First run requires the gh CLI authenticated (gh auth login) with repo scope.
set -e
cd "$(dirname "$0")"

REPO="${GITHUB_REPOSITORY:-xezpeleta/strongswan-fortigate}"
TAG="${RELEASE_TAG:-fortigate-1}"

[ -d apt-repo/dists ] || { echo "ERROR: apt-repo/ missing — run update-apt-repo.sh first"; exit 1; }
git rev-parse -q --verify HEAD >/dev/null || { echo "ERROR: nothing committed yet"; exit 1; }

# Make git over https work with the gh token
gh auth setup-git >/dev/null

# Create the GitHub repo on first run
if ! gh repo view "$REPO" >/dev/null 2>&1; then
    echo "==> creating GitHub repository $REPO (public)"
    gh repo create "$REPO" --public \
        --description "Unofficial strongSwan builds for FortiGate IPsec VPN (certificate + EAP) — Ubuntu 26.04" \
        --homepage "https://xezpeleta.github.io/strongswan-fortigate/"
fi
gh repo edit "$REPO" --description "Unofficial strongSwan builds for FortiGate IPsec VPN (certificate + EAP) — Ubuntu 26.04" >/dev/null 2>&1 || true

if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "https://github.com/$REPO.git"
fi

echo "==> pushing main"
git push -q -u origin HEAD:main

echo "==> assembling gh-pages"
rm -rf .gh-pages
mkdir .gh-pages
cp -r apt-repo/. .gh-pages/
cp add-apt-source.sh .gh-pages/
cat > .gh-pages/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>strongswan-fortigate</title></head>
<body style="font-family: sans-serif; max-width: 46rem; margin: 3rem auto; line-height: 1.5">
<h1>Unofficial strongSwan for FortiGate IPsec VPN — Ubuntu 26.04</h1>
<p><strong>Unofficial, third-party builds</strong> — not affiliated with the
strongSwan project, Fortinet or Ubuntu. They patch Ubuntu 26.04's strongSwan
so NetworkManager's <strong>"Certificate + EAP"</strong> method works with
FortiGate IPsec dial-up VPNs using
<code>eap-cert-auth enable</code> (FortiOS&nbsp;7.4.12&nbsp;/&nbsp;7.6.7+
enforces the client certificate and silently drops EAP-only clients;
the gateway does not implement RFC&nbsp;4739).
Details: <a href="https://github.com/strongswan/strongswan/issues/3120">strongswan#3120</a>,
<a href="https://github.com/xezpeleta/strongswan-fortigate">source &amp; releases</a>.</p>
<p>Enable on Ubuntu 26.04:</p>
<pre>curl -fsSL https://xezpeleta.github.io/strongswan-fortigate/add-apt-source.sh | sudo bash
sudo apt install strongswan-fortigate</pre>
<p>The repository is signed; the <code>InRelease</code> GPG signature is the
trust anchor. Review the (small) patches and rebuild from source if you
prefer your own binaries.</p>
</body>
</html>
EOF

echo "==> pushing gh-pages (force)"
(
    cd .gh-pages
    git init -q .
    git add -A
    git commit -qm "apt repository update $(date -u '+%Y-%m-%d %H:%M UTC')"
    git push -qf "https://github.com/$REPO.git" HEAD:gh-pages
)

echo "==> enabling GitHub Pages (idempotent)"
gh api -X POST "repos/$REPO/pages" -f 'source[branch]=gh-pages' -f 'source[path]=/' >/dev/null 2>&1 \
    || echo "    (Pages already enabled or must be enabled manually: Settings → Pages → gh-pages)"

echo "==> publishing release $TAG"
NOTES=$(mktemp)
cat > "$NOTES" <<EOF
Unofficial strongSwan builds for FortiGate IPsec VPN (Ubuntu 26.04, resolute, amd64).

Ubuntu's strongSwan 6.0.4 cannot connect to a FortiGate IPsec dial-up VPN
with eap-cert-auth enable (FortiOS 7.4.12/7.6.7+): the gateway requires
the client certificate in the first IKE_AUTH request, does not implement
RFC 4739 multiple authentication, and silently drops EAP-only requests.
Stock strongSwan never attaches a certificate to an EAP-only round.

These packages backport the upstream cert-eap NetworkManager method and
add a compatibility patch: with these installed, NetworkManager's
"Certificate + EAP (Username/Password)" method sends a single EAP-only
authentication round carrying the client certificate, which the FortiGate
accepts. See https://github.com/strongswan/strongswan/issues/3120 and
https://github.com/strongswan/strongswan/discussions/3014

Easier and recommended: use the apt repository —
https://xezpeleta.github.io/strongswan-fortigate/

    curl -fsSL https://xezpeleta.github.io/strongswan-fortigate/add-apt-source.sh | sudo bash
    sudo apt install strongswan-fortigate

Unofficial third-party builds; not affiliated with the strongSwan project,
Fortinet or Ubuntu. Tested on FortiGate 101F / FortiOS 7.4.13 / Ubuntu 26.04.
All Ubuntu security patches are preserved; a future official Ubuntu update
replaces these builds automatically.
EOF
REL_ASSETS="dist/*fortigate1*.deb dist/network-manager-strongswan_*certeap1_amd64.deb"
if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    gh release upload "$TAG" -R "$REPO" $REL_ASSETS --clobber
else
    # shellcheck disable=SC2086
    gh release create "$TAG" -R "$REPO" $REL_ASSETS \
        --title "strongSwan for FortiGate IPsec VPN (+fortigate1)" \
        --notes-file "$NOTES"
fi
rm -f "$NOTES"

echo
echo "Published:"
echo "  code:    https://github.com/$REPO"
echo "  apt:     https://xezpeleta.github.io/strongswan-fortigate/"
echo "  release: https://github.com/$REPO/releases/tag/$TAG"
