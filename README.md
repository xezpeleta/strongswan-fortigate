# Unofficial strongSwan builds for FortiGate IPsec VPN (Ubuntu 26.04)

> **These are unofficial, third-party packages.** They are not produced by
> or affiliated with the strongSwan project, Fortinet, or Ubuntu. They
> replace several system strongSwan packages with patched builds. The
> patches are small and readable in
> [`debian-overlay/`](debian-overlay/) — review them, and if you prefer,
> rebuild the binaries yourself with the scripts in this repo.

## The problem

FortiGate IPsec dial-up VPNs commonly require two-factor authentication:
a **client certificate** *and* **EAP username/password**
(`set eap-cert-auth enable` on the IPsec phase1-interface). Two things
make this combination impossible for stock Linux clients right now:

1. **FortiOS tightened enforcement.** In FortiOS 7.4.12 and 7.6.7 the
   behavior of `eap-cert-auth` changed: certificates are always passed to
   the FortiGate authentication daemon, and *only clients that present a
   valid certificate are allowed to connect*. Clients that previously
   connected with EAP alone (the certificate being checked but unenforced,
   or bypassed) stopped working after the firmware upgrade.
   ([Fortinet administration guide: IPsec IKEv2 VPN 2FA with EAP and certificate authentication](https://docs.fortinet.com/document/fortigate/7.4.13/administration-guide/298520/ipsec-ikev2-vpn-2fa-with-eap-and-certificate-authentication))

2. **The FortiGate does not implement RFC 4739** (multiple authentication
   exchanges), which is the standard IKEv2 way to combine certificate and
   EAP authentication. And when a client sends a single EAP-only
   authentication request, **stock strongSwan never attaches a certificate
   to it** — certificates are only sent together with an AUTH payload
   (a signature proving possession of the key). The FortiGate, seeing no
   certificate in the first IKE_AUTH request, **silently drops it**: the
   client just retransmits until it gives up. No error, no log hint on
   the client side.

The result: after a FortiOS 7.4.12+/7.6.7+ upgrade, certificate + EAP
dial-up VPNs cannot be established from Linux with stock strongSwan
(NetworkManager, swanctl, anything). Several users hit this independently —
see [strongswan#3120](https://github.com/strongswan/strongswan/issues/3120)
and the earlier analysis in
[strongswan discussion #3014](https://github.com/strongswan/strongswan/discussions/3014).

## What these packages do

They patch Ubuntu 26.04's strongSwan 6.0.4 in two ways:

1. **`cert-eap` backport** (upstream commits, listed below): adds the
   **"Certificate + EAP (Username/Password)"** method to the strongSwan
   NetworkManager plugin. This is the upstream-correct implementation of
   two authentication rounds in one IKE_SA (RFC 4739) and works with
   gateways that implement RFC 4739. (Shipped in the first release of
   this repo as `+certeap1`.)

2. **FortiGate compatibility patch** (ours, the reason for this release):
   makes the NetworkManager `cert-eap` method use a **single EAP-only
   authentication round that carries the client certificate**
   (`IDi + CERT + N(EAP_ONLY)`, no AUTH payload). The FortiGate accepts
   this shape: it validates the certificate, then runs the EAP exchange
   (e.g. MSCHAPv2) to completion, and authenticates the IKE_SA on the
   EAP-derived key.

With these packages installed, NetworkManager's
"Certificate + EAP (Username/Password)" method connects to a FortiGate
with `eap-cert-auth enable` on Ubuntu 26.04.

An opt-in version of the second change is being proposed for upstream
strongSwan (see [#3120](https://github.com/strongswan/strongswan/issues/3120)
for its status). This repo is the pragmatic workaround meanwhile, and it
may become obsolete once a fix lands upstream and reaches Ubuntu.

## Compatibility and status

- Tested against: **FortiGate 101F, FortiOS 7.4.13**
  (`eap-cert-auth enable`, EAP-MSCHAPv2), **Ubuntu 26.04** (resolute,
  amd64), GNOME NetworkManager.
- The full patch set passes strongSwan's own test suite (`make check`,
  all six suites) and a three-scenario matrix against the gateway
  (working cert+EAP flow; default configuration unchanged; no certificate
  configured = unchanged behavior).
- Only file-based client certificates (PEM / PKCS#12) were exercised.
- Replaces these Ubuntu packages (all Ubuntu security patches, including
  the 6.0.4-1ubuntu3.2 CVE series, are preserved):

| Package | Ubuntu 26.04 version | This build |
|---|---|---|
| network-manager-strongswan | 1.6.4-1 | 1.6.4-1+certeap1 |
| strongswan-nm | 6.0.4-1ubuntu3.2 | 6.0.4-1ubuntu3.2+fortigate1 |
| strongswan-libcharon, libstrongswan | 6.0.4-1ubuntu3.2 | +fortigate1 |
| strongswan-charon, strongswan-starter | 6.0.4-1ubuntu3.2 | +fortigate1 |
| libcharon-extauth-plugins, libcharon-extra-plugins | 6.0.4-1ubuntu3.2 | +fortigate1 |
| charon-cmd, charon-systemd, strongswan-pki, strongswan-swanctl | 6.0.4-1ubuntu3.2 | +fortigate1 |
| libstrongswan-extra-plugins, libstrongswan-standard-plugins | 6.0.4-1ubuntu3.2 | +fortigate1 |
| strongswan (metapackage) | 6.0.4-1ubuntu3.2 | +fortigate1 |

- The version suffix (`+fortigate1`) is deliberately ordered so that any
  future **official Ubuntu update replaces these builds automatically** —
  you are never pinned onto unofficial packages.
- If your gateway is *not* a FortiGate and does implement RFC 4739, you
  want the upstream behavior instead: use strongSwan ≥ 6.1 or the earlier
  `certeap-1` release assets from this repo.

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
sudo apt install network-manager-strongswan strongswan-charon \
                 libcharon-extauth-plugins libcharon-extra-plugins
```

The repository is signed; `add-apt-source.sh` fetches the key from the
same site and wires it into `/usr/share/keyrings/` (the GPG signature of
`InRelease` is the real trust anchor — if you do not want to trust a
third-party repo, use option 2 and read the patches).

### Option 2: direct .deb download

Grab the `+fortigate1` debs from the
[GitHub releases](https://github.com/xezpeleta/strongswan-deb-packages/releases)
(release `fortigate-1`) and:

```bash
sudo apt install ./network-manager-strongswan_1.6.4-1+certeap1_amd64.deb \
                 ./strongswan-nm_*fortigate1_amd64.deb \
                 ./strongswan-charon_*fortigate1_amd64.deb \
                 ./strongswan-libcharon_*fortigate1_amd64.deb \
                 ./libstrongswan_*fortigate1_amd64.deb \
                 ./strongswan-starter_*fortigate1_amd64.deb \
                 ./libcharon-extauth-plugins_*fortigate1_amd64.deb \
                 ./libcharon-extra-plugins_*fortigate1_amd64.deb
```

(If apt complains about the local file path syntax on older apt, use
`sudo dpkg -i <debs> && sudo apt -f install`.)

## Setting up the VPN connection (NetworkManager)

1. Obtain a **client certificate** issued by the CA your FortiGate
   trusts (the CA referenced by the peer group of the IPsec phase1).
   PEM or PKCS#12.
2. Network Settings → VPN → + → **IPsec/IKEv2 (strongSwan)**:
   - **Gateway**: your FortiGate's address
   - **Method**: **Certificate + EAP (Username/Password)**
   - **Certificate**: pick your client certificate (.pem/.p12)
   - **Username / Password**: your EAP credentials
3. If your private key is passphrase-protected, there is a separate
   "Private key password" prompt (stored under the `userkey-password`
   secret, independent from the EAP password).
4. **Trusting the gateway certificate**: if the FortiGate presents a
   certificate from a CA your system already trusts, nothing more is
   needed. Fortinet factory-signed certificates chain up to the built-in
   *Fortinet Factory* CA, which is not in Ubuntu trust stores; either
   import that CA into your system trust store, or pin the gateway
   certificate by setting `certificate = /path/to/ca-or-gateway-cert.pem`
   in the connection's vpn data (the plugin then treats it as the
   trusted peer certificate).
5. Connect.

Note: NetworkManager profiles created by netplan (e.g.
`/etc/netplan/90-NM-*.yaml`) should be edited there for persistent
changes; runtime profiles live in `/run/NetworkManager/system-connections/`.

## How it works (technical)

The first IKE_AUTH request a stock client sends for an EAP connection
carries no certificate (no AUTH payload → no CERT payload). The patch
set consists of:

- `debian-overlay/strongswan/patches/zz-cert-eap-backport.patch` —
  the upstream `cert-eap` commits backported onto 6.0.4:
  - strongswan (charon-nm): 137bfe8381be, 0e861e123e0c, c92a599d80ca
    ("charon-nm: Add combined certificate/EAP VPN method" + prerequisites)
  - network-manager-strongswan: 28d921822944, 06da609ebee4, 28a04fcb54ea,
    d64176ce90a6 ("nm: Add cert-eap method to GNOME editor and auth dialog"
    + prerequisites)
- `debian-overlay/strongswan/patches/zz-fortigate-cert-eap.patch` —
  the FortiGate compatibility change:
  - `ike_cert_post` (libcharon): attach the certificate configured for
    the local EAP auth round to the first IKE_AUTH request even if it
    does not carry an AUTH payload
  - `nm_service.c` (charon-nm): build one EAP auth round with
    certificate + EAP identity + password for the `cert-eap` method

The same patch is kept in reviewable form on the fork branch
[fortigate-cert-eap](https://github.com/xezpeleta/strongswan/tree/fortigate-cert-eap).
The opt-in variant being proposed upstream (gated on the existing
`send_cert = always` certificate policy instead of changing the
NetworkManager flow) is kept alongside it as
`debian-overlay/strongswan/patches/zz-cert-eap-proposal.patch`, for
reference; it is **not** applied by these packages.

**Proof-of-possession caveat**: because the round is EAP-only, the final
AUTH payload is keyed on the EAP-derived MSK, so the certificate is not
covered by a cryptographic proof of possession of the private key in the
IKE exchange itself. This matches what the FortiGate expects (certificate
presence as one factor, EAP as the other), but it is weaker than
RFC 4739's signature round; the upstream proposal therefore gates the
same message shape behind an explicit opt-in.

## Repository layout

```
├── Dockerfile, .dockerignore     Docker build environment (ubuntu:26.04)
├── fetch-sources.sh              assembles pkg/ from sources/ + debian-overlay/
├── build-packages.sh             builds all debs from pkg/ into dist/
├── build-in-docker.sh            fetch + build inside Docker (no sudo needed)
├── install-builddeps.sh          alternative: local build dependencies
├── sources/                      pristine Ubuntu 26.04 source packages (committed)
├── debian-overlay/               our changelog + quilt patches (the "code")
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
sources: `debian-overlay/strongswan/patches/zz-cert-eap-backport.patch`
and `…/zz-fortigate-cert-eap.patch`, series-appended after the Ubuntu CVE
patches. `dpkg-buildpackage -S` can produce source packages for a
PPA or other architectures.

## Publishing (maintainer)

After a successful build (`dist/` populated):

```bash
bash update-apt-repo.sh     # regenerate + sign apt-repo/
bash publish.sh             # push main, gh-pages, and create the release
```

`publish.sh` force-pushes the `apt-repo/` contents to the `gh-pages`
branch and uploads the `+fortigate1` debs (plus the NetworkManager
plugin deb) as a GitHub release.

## Caveats

- Built and tested on Ubuntu 26.04 amd64 with strongSwan 6.0.4 /
  network-manager-strongswan 1.6.4. For other Ubuntu releases,
  rebuild from the matching `-orig` source of that release (the
  backport patches may need fuzz adjustments).
- Tested against one gateway model/firmware combination (FortiGate 101F,
  FortiOS 7.4.13). Other FortiGate models should behave the same, but
  are untested here.
- `cert-eap` + ssh-agent / smartcard works in upstream code but was
  not exercised here; file-based certificates are the tested path.
- The FortiGate compatibility patch changes the `cert-eap` NetworkManager
  flow for *all* gateways (single EAP-only round with certificate
  attached). Gateways that implement RFC 4739 properly and require the
  two-round exchange are not served by this build; use upstream
  strongSwan ≥ 6.1 or the `certeap-1` release assets instead.
- When upstream strongSwan ships a fix and Ubuntu packages it, upgrade
  and forget this repo (the official update will take precedence
  automatically).

## Credits

- Upstream `cert-eap` implementation: Jarno Mäkelä, Tobias Brunner
  (strongSwan project) — commits of 2026-10-12/14, merged 2026-10-29.
- FortiGate compatibility patch, backport and packaging: xezpeleta
  (Tknika) — prompted by FortiOS 7.4.13 dropping certificate + EAP
  clients; see [#3120](https://github.com/strongswan/strongswan/issues/3120).
