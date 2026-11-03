# cert-eap backport for Ubuntu 26.04 — strongSwan NetworkManager plugin

## What this is

Deb packages for Ubuntu 26.04 (resolute, amd64) that backport the
**`cert-eap`** authentication method to the strongSwan NetworkManager
VPN plugin. `cert-eap` performs **two IKEv2 authentication rounds in
one IKE_SA (RFC 4739)**: the first with a **client X.509 certificate**,
the second with **EAP username/password**. The GUI gains a new method:
**"Certificate + EAP (Username/Password)"**.

This combination is required by VPN gateways that enforce
certificate + EAP two-factor authentication — e.g. **FortiGate IPsec
dial-up VPNs with `eap-cert-auth enable`** (FortiOS 7.4.x tightened
enforcement of this in 7.4.13, breaking pure-EAP clients).

Upstream implemented `cert-eap` in strongSwan git master on
2026-10-29 (after the 6.1.0 release); these packages backport it to
the versions shipped with Ubuntu 26.04:

| Package | Ubuntu 26.04 version | This build |
|---|---|---|
| network-manager-strongswan | 1.6.4-1 | **1.6.4-1+certeap1** |
| strongswan-nm (charon-nm backend) | 6.0.4-1ubuntu3.2 | **6.0.4-1ubuntu3.2+certeap1** |

Backported upstream commits:

- strongswan (charon-nm): 137bfe8381be, 0e861e123e0c, c92a599d80ca
  ("charon-nm: Add combined certificate/EAP VPN method" + prerequisites)
- network-manager-strongswan: 28d921822944, 06da609ebee4, 28a04fcb54ea,
  d64176ce90a6 ("nm: Add cert-eap method to GNOME editor and auth dialog" + prerequisites)

All Ubuntu security patches (including CVE-2025-9615 ssh-agent
hardening and the strongswan 6.0.4-1ubuntu3.2 CVE series) are
preserved. Version suffixes (`+certeap1`) are chosen so that any
future official Ubuntu update to these packages **replaces** these
builds automatically.

## Installing

### Option 1: apt repository (recommended)

The packages are served from this repo's GitHub Pages site:
<https://xezpeleta.github.io/strongswan-deb-packages/>

Enable it (and optionally install right away):

```bash
curl -fsSL https://xezpeleta.github.io/strongswan-deb-packages/add-apt-source.sh -o /tmp/add-apt-source.sh
sudo bash /tmp/add-apt-source.sh --install
```

Or manually:

```bash
sudo bash add-apt-source.sh            # enable repo only
sudo apt install network-manager-strongswan strongswan-nm
```

The repository is signed; `add-apt-source.sh` fetches the key from
the same site and wires it into `/usr/share/keyrings/` (the GPG
signature of `InRelease` is the real trust anchor).

### Option 2: direct .deb download

Grab the two debs from the
[GitHub releases](https://github.com/xezpeleta/strongswan-deb-packages/releases)
and:

```bash
sudo apt install ./network-manager-strongswan_1.6.4-1+certeap1_amd64.deb \
                 ./strongswan-nm_6.0.4-1ubuntu3.2+certeap1_amd64.deb
```

(If apt complains about the local file path syntax on older apt, use
`sudo dpkg -i <debs> && sudo apt -f install`.)

No other strongSwan packages are replaced: the rebuilt
`strongswan-nm` only ships `/usr/lib/ipsec/charon-nm`, which links
against the stock `libcharon`/`libstrongswan` 6.0.4.

## Using it (FortiGate with eap-cert-auth, or any cert+EAP IKEv2 server)

1. Obtain a **client certificate** issued by the CA your gateway
   trusts (on FortiGate: the CA referenced by the peer group of the
   IPsec phase1). PEM or PKCS#12.
2. Network Settings → VPN → + → IPsec/IKEv2 (strongSwan):
   - Gateway, as before
   - Method: **Certificate + EAP (Username/Password)**
   - Certificate: pick your client cert (.pem/.p12)
   - Username / password: your EAP credentials
3. If your private key is passphrase-protected, there is now a
   separate "Private key password" prompt (stored under the
   `userkey-password` secret, independent from the EAP password).

Note: NetworkManager profiles created by netplan (e.g.
`/etc/netplan/90-NM-*.yaml`) should be edited there for persistent
changes; runtime profiles live in `/run/NetworkManager/system-connections/`.

## Repository layout

```
├── Dockerfile, .dockerignore     Docker build environment (ubuntu:26.04)
├── fetch-sources.sh              assembles pkg/ from sources/ + debian-overlay/
├── build-packages.sh             builds all debs from pkg/ into dist/
├── build-in-docker.sh            fetch + build inside Docker (no sudo needed)
├── install-builddeps.sh          alternative: local build dependencies
├── sources/                      pristine Ubuntu 26.04 source packages (committed)
├── debian-overlay/               our changelog + cert-eap quilt patches (the "code")
│   ├── network-manager-strongswan/
│   └── strongswan/
├── patches/                      original upstream commits as .patch files (provenance)
├── update-apt-repo.sh            regenerates + signs apt-repo/ from dist/
├── add-apt-source.sh             end-user script: enable the apt repo
├── dist/                         build output (not committed; in GitHub releases)
└── apt-repo/                     generated apt repo (not committed; on gh-pages branch)
```

The gh-pages branch contains the signed apt repository
(`dists/resolute/…`, `pool/…`, `apt-repo.key`, `add-apt-source.sh`)
published via GitHub Pages.

## Rebuilding (Docker — recommended)

```bash
bash build-in-docker.sh
```

Builds the image `tknika/strongswan-deb` (ubuntu:26.04 + all build
dependencies), assembles the source trees (`fetch-sources.sh`) and
builds the packages inside the container as an unprivileged user.
The debs land in `dist/` owned by you. No root/sudo or build
dependencies needed on the host — only a working Docker.

## Rebuilding (locally, without Docker)

```bash
sudo bash install-builddeps.sh
bash fetch-sources.sh
bash build-packages.sh
```

Changes are quilt patches applied on top of the pristine Ubuntu
sources: `debian-overlay/*/patches/cert-eap-backport.patch` and
`…/zz-cert-eap-backport.patch`, series-appended after the Ubuntu CVE
patches. `dpkg-buildpackage -S` can produce source packages for a
PPA or other architectures.

## Publishing (maintainer)

After a successful build (`dist/` populated):

```bash
bash update-apt-repo.sh     # regenerate + sign apt-repo/
bash publish.sh             # push main, gh-pages, and create the release
```

`publish.sh` force-pushes the `apt-repo/` contents to the `gh-pages`
branch and uploads `dist/*.deb` as a GitHub release.

## Caveats

- Built and tested on Ubuntu 26.04 amd64 with strongSwan 6.0.4 /
  network-manager-strongswan 1.6.4. For other Ubuntu releases,
  rebuild from the matching `-orig` source of that release (the
  backport patches may need fuzz adjustments).
- `cert-eap` + ssh-agent / smartcard works in upstream code but was
  not exercised here; file-based certificates are the tested path.
- Upstream will ship this natively in strongSwan > 6.1.0; when
  Ubuntu packages it, upgrade and forget this repo.

## Credits

- Upstream `cert-eap` implementation: Jarno Mäkelä, Tobias Brunner
  (strongSwan project) — commits of 2026-10-12/14, merged 2026-10-29.
- Backport/packaging: xezpeleta (Tknika) — prompted by FortiOS
  7.4.13 dropping pure-EAP IKEv2 clients.
