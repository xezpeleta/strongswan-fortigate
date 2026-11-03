#!/bin/bash
# Rebuild and sign the apt repository (for GitHub Pages) from dist/*.deb.
#
# - Packages index and Release metadata are generated inside the Docker
#   image (dpkg-scanpackages is needed and lives there).
# - Signing happens on the host with the dedicated repo key.
# - Result: apt-repo/ — publish its contents to the gh-pages branch
#   (see README.md, "Publishing").
set -e
cd "$(dirname "$0")"

SUITE=resolute
KEYID=$(gpg --list-secret-keys --keyid-format long --with-colons 2>/dev/null \
        | awk -F: '/^sec/ {print $5; exit}')
[ -n "$KEYID" ] || { echo "ERROR: no GPG secret key found"; exit 1; }

for f in dist/network-manager-strongswan_*+certeap1_amd64.deb dist/strongswan-nm_*+certeap1_amd64.deb; do
    [ -e "$f" ] || { echo "ERROR: $f missing — run build-in-docker.sh first"; exit 1; }
done

echo "==> assembling apt-repo/ (suite: $SUITE)"
rm -rf apt-repo
docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/home/ubuntu -e SUITE="$SUITE" \
    -v "$PWD":/work -w /work \
    tknika/strongswan-deb \
    bash -euc '
        set -x
        mkdir -p apt-repo/pool/main/n/network-manager-strongswan \
                 apt-repo/pool/main/s/strongswan \
                 "apt-repo/dists/$SUITE/main/binary-amd64"
        cp dist/network-manager-strongswan_*+certeap1_amd64.deb apt-repo/pool/main/n/network-manager-strongswan/
        cp dist/strongswan-nm_*+certeap1_amd64.deb apt-repo/pool/main/s/strongswan/
        cd apt-repo

        dpkg-scanpackages --arch amd64 pool > "dists/$SUITE/main/binary-amd64/Packages"
        gzip -9kn "dists/$SUITE/main/binary-amd64/Packages"

        cd "dists/$SUITE"
        {
            echo "Origin: strongswan-deb-packages"
            echo "Label: strongswan-deb-packages"
            echo "Suite: $SUITE"
            echo "Codename: $SUITE"
            echo "Architectures: amd64"
            echo "Components: main"
            echo "Description: strongSwan cert-eap backport for Ubuntu 26.04"
            echo "Date: $(date -Ru)"
            echo "Valid-Until: $(date -Ru -d "+7 days")"
            echo "MD5Sum:"
            while read -r f; do
                printf " %s %8d %s\n" "$(md5sum < "$f" | cut -d" " -f1)" "$(stat -c%s "$f")" "$f"
            done < <(find main -type f)
            echo "SHA256:"
            while read -r f; do
                printf " %s %8d %s\n" "$(sha256sum < "$f" | cut -d" " -f1)" "$(stat -c%s "$f")" "$f"
            done < <(find main -type f)
        } > Release
        set +x
    '

echo "==> signing (key $KEYID)"
gpg --batch --yes --default-key "$KEYID" --clearsign \
    -o apt-repo/dists/$SUITE/InRelease apt-repo/dists/$SUITE/Release
gpg --batch --yes --default-key "$KEYID" --armor --detach-sign \
    -o apt-repo/dists/$SUITE/Release.gpg apt-repo/dists/$SUITE/Release
gpg --armor --export "$KEYID" > apt-repo/apt-repo.key

echo "==> apt-repo/ ready:"
find apt-repo -type f | sort
