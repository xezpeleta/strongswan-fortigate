#!/bin/bash
# Publish everything to GitHub (run after update-apt-repo.sh):
#   - main branch  : this source repo
#   - gh-pages     : the signed apt repository (served by GitHub Pages)
#   - GitHub release: dist/*.deb as release assets
#
# First run requires the gh CLI authenticated (gh auth login) with repo scope.
set -e
cd "$(dirname "$0")"

REPO="${GITHUB_REPOSITORY:-xezpeleta/strongswan-deb-packages}"
TAG="${RELEASE_TAG:-certeap-1}"

[ -d apt-repo/dists ] || { echo "ERROR: apt-repo/ missing — run update-apt-repo.sh first"; exit 1; }
git rev-parse -q --verify HEAD >/dev/null || { echo "ERROR: nothing committed yet"; exit 1; }

# Make git over https work with the gh token
gh auth setup-git >/dev/null

# Create the GitHub repo on first run
if ! gh repo view "$REPO" >/dev/null 2>&1; then
    echo "==> creating GitHub repository $REPO (public)"
    gh repo create "$REPO" --public \
        --description "strongSwan cert-eap (certificate + EAP, RFC 4739) backport for Ubuntu 26.04 — NetworkManager plugin" \
        --homepage "https://xezpeleta.github.io/strongswan-deb-packages/"
fi

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
<head><meta charset="utf-8"><title>strongswan-deb-packages</title></head>
<body style="font-family: sans-serif; max-width: 46rem; margin: 3rem auto; line-height: 1.5">
<h1>strongSwan <code>cert-eap</code> backport for Ubuntu 26.04</h1>
<p>Signed apt repository with NetworkManager strongSwan plugin packages
that support <strong>certificate + EAP two-factor authentication</strong>
(RFC 4739) — needed for FortiGate IPsec VPNs with
<code>eap-cert-auth enable</code> (FortiOS 7.4.13+).</p>
<p>Enable on Ubuntu 26.04:</p>
<pre>curl -fsSL https://xezpeleta.github.io/strongswan-deb-packages/add-apt-source.sh -o /tmp/a.sh
sudo bash /tmp/a.sh --install</pre>
<p>Source code and releases:
<a href="https://github.com/xezpeleta/strongswan-deb-packages">xezpeleta/strongswan-deb-packages</a></p>
</body>
</html>
EOF

echo "==> pushing gh-pages (force)"
(
    cd .gh-pages
    git init -q .
    git add -A
    git commit -qm "apt repository update $(date -u '+%Y-%m-%d %H:%M UTC')"
    git push -qf origin HEAD:gh-pages
)

echo "==> enabling GitHub Pages (idempotent)"
gh api -X POST "repos/$REPO/pages" -f 'source[branch]=gh-pages' -f 'source[path]=/' >/dev/null 2>&1 \
    || echo "    (Pages already enabled or must be enabled manually: Settings → Pages → gh-pages)"

echo "==> publishing release $TAG"
NOTES=$(mktemp)
cat > "$NOTES" <<EOF
strongSwan cert-eap backport for Ubuntu 26.04 (resolute, amd64).

Adds the "Certificate + EAP (Username/Password)" method to the
NetworkManager strongSwan plugin (RFC 4739: two authentication
rounds — client X.509 certificate + EAP username/password in one
IKE_SA). Needed for FortiGate IPsec dial-up VPNs with
eap-cert-auth enable (FortiOS 7.4.13+).

Easier: use the apt repository — see
https://xezpeleta.github.io/strongswan-deb-packages/

Minimal install from this release:
    sudo apt install ./network-manager-strongswan_1.6.4-1+certeap1_amd64.deb \\
                     ./strongswan-nm_6.0.4-1ubuntu3.2+certeap1_amd64.deb
EOF
if gh release view "$TAG" -R "$REPO" >/dev/null 2>&1; then
    gh release upload "$TAG" -R "$REPO" dist/*.deb --clobber
else
    gh release create "$TAG" -R "$REPO" dist/*.deb \
        --title "cert-eap backport for Ubuntu 26.04" \
        --notes-file "$NOTES"
fi
rm -f "$NOTES"

echo
echo "Published:"
echo "  code:    https://github.com/$REPO"
echo "  apt:     https://xezpeleta.github.io/strongswan-deb-packages/"
echo "  release: https://github.com/$REPO/releases/tag/$TAG"
