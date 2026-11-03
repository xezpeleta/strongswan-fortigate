-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

Format: 3.0 (quilt)
Source: strongswan
Binary: strongswan, libstrongswan, libstrongswan-standard-plugins, libstrongswan-extra-plugins, libcharon-extauth-plugins, libcharon-extra-plugins, strongswan-starter, strongswan-libcharon, strongswan-charon, strongswan-nm, charon-cmd, strongswan-pki, strongswan-swanctl, charon-systemd
Architecture: any all
Version: 6.0.4-1ubuntu3.2
Maintainer: Ubuntu Developers <ubuntu-devel-discuss@lists.ubuntu.com>
Uploaders: Yves-Alexis Perez <corsac@debian.org>
Homepage: http://www.strongswan.org
Standards-Version: 4.7.1
Vcs-Browser: https://salsa.debian.org/debian/strongswan
Vcs-Git: https://salsa.debian.org/debian/strongswan.git
Testsuite: autopkgtest
Testsuite-Triggers: bind9-dnsutils, dctrl-tools, libtss2-tcti-tabrmd0, lsb-release, snapd
Build-Depends: bison, bzip2, debhelper-compat (= 12), dh-apparmor, dpkg-dev (>= 1.16.2), flex, gperf, libiptc-dev [linux-any], libcap-dev [linux-any], libcurl4-openssl-dev | libcurl3-dev | libcurl2-dev, libgcrypt20-dev | libgcrypt11-dev, libgmp3-dev, libkrb5-dev, libldap2-dev, libnm-dev [linux-any], libpam0g-dev, libsqlite3-dev, libssl-dev (>= 0.9.8), libsystemd-dev [linux-any], libtool, libtss2-dev, libxml2-dev, pkgconf, po-debconf, systemd-dev [linux-any], tzdata
Package-List:
 charon-cmd deb net optional arch=any
 charon-systemd deb net optional arch=linux-any
 libcharon-extauth-plugins deb net optional arch=any
 libcharon-extra-plugins deb net optional arch=any
 libstrongswan deb net optional arch=any
 libstrongswan-extra-plugins deb net optional arch=any
 libstrongswan-standard-plugins deb net optional arch=any
 strongswan deb net optional arch=all
 strongswan-charon deb net optional arch=any
 strongswan-libcharon deb net optional arch=any
 strongswan-nm deb net optional arch=linux-any
 strongswan-pki deb net optional arch=any
 strongswan-starter deb net optional arch=any
 strongswan-swanctl deb net optional arch=any
Checksums-Sha1:
 26db9e098fd0ec608c70810d65bf62ba927ff3a6 4915290 strongswan_6.0.4.orig.tar.bz2
 b204ff9fbbd570ac01e3e8d99c106834fb1ea82e 165564 strongswan_6.0.4-1ubuntu3.2.debian.tar.xz
Checksums-Sha256:
 79576bb61b9a406cea9eb73d0c565cc6254a6b6d2e7198f44758d2d7c61a7aec 4915290 strongswan_6.0.4.orig.tar.bz2
 1f6cfddbefa64298e0cd7dbfcf8dde7eb0b81f708a70f180698a9addbc77e631 165564 strongswan_6.0.4-1ubuntu3.2.debian.tar.xz
Files:
 f6b78a99e95179b6a65df218d75da7ca 4915290 strongswan_6.0.4.orig.tar.bz2
 d8cd805a3c720fc25e6375c4e2d14f11 165564 strongswan_6.0.4-1ubuntu3.2.debian.tar.xz
Original-Maintainer: strongSwan Maintainers <pkg-swan-devel@lists.alioth.debian.org>

-----BEGIN PGP SIGNATURE-----

iQIzBAEBCgAdFiEEUMSg3c8x5FLOsZtRZWnYVadEvpMFAmqiqqkACgkQZWnYVadE
vpOVww//bg4BaBmzRFJEa3aahU8IoMag3FGtP0E3QbsyOHPwaat+maEn1nXtbhHP
2ePPDknfvfmUU9uQmEf5FKSUxqY9lDXqcFxDOK8uzjvk0RJhSWxJiGPXHGQpjnGH
qlbb8OlKpJvQCfPtt04gICx+K73giJG0tDsIxY5nVGL1hHWQtWX+niP8yqltedY9
2S5p5NqeuUSgRvJu84mhIwdkDVdSmsW2AjSJNaT2duj/lfjPvTRAyQt+UrAT1IuH
r+sEiPREh5eslOJfstUAofMM5Ilo16NLIjTW8XSjC2zAP2M3dOtpTpS+0gFISm9d
ojrSg5ig0flNmDezYumuISwP/88kz98kv8bSHkuPqUBYyKnk/srrjpxpFy7xleTd
VVgjtDHNRDwAtL1DvYD3GyEKuqQ00L5HzfR1blsBHsmp2xBqhaAV9wQo2DTlebuH
mDEUBHnzO8DFhXWm77F8Btj0JiczNZlpAgptz6m/8TRTCd4lAb3jQaQs6qVePTsj
glEynghDgAgH+EeJPDxMskjpupG6DPioGFr70cDBym3oWrChCrezKAoHQc2U1Y+F
eSTsEhzL7GDvUMx1fvRrQs63/obeO7757Zy1sDKoWVy06Nj3/6Qi8rufutXP2GWr
8qc1n6pWzvsw/bmdItfEpDak2Iybl8RiR1Ql1cU6f4rwU4qlWpg=
=VO84
-----END PGP SIGNATURE-----
