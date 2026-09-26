# GitHub Desktop for Linux, v3.6.5-deb2

Packaging re-release of
[GitHub Desktop `3.6.5`](https://github.com/desktop/desktop/releases/tag/release-3.6.5)
(upstream commit `13b57bd28dcaa94ec55374f814dab7a1645ae3b0`), on Electron
`42.0.1`. Debian package version `3.6.5-2`, architecture `amd64`. The
application is unchanged from `v3.6.5`.

## Install

```bash
sudo apt install ./github-desktop_3.6.5-2_amd64.deb
```

## Verify

```
SHA-256: see checksums/github-desktop_3.6.5-2_amd64.deb.sha256
```

```bash
sha256sum -c github-desktop_3.6.5-2_amd64.deb.sha256
```

## What's new in this package

- **Updates on every start.** `github-desktop` now checks this repository
  for a newer package each time it launches. When one is published it is
  downloaded, its SHA-256 checksum verified, installed through a polkit
  password prompt, and the new version starts. A declined version is not
  offered again until an even newer one appears. Pre-releases are never
  installed automatically.
- `github-desktop-update` checks and installs by hand.
- `GITHUB_DESKTOP_NO_UPDATE_CHECK=1` disables the startup check.
- New dependency `curl`; new recommended packages `pkexec` and
  `libnotify-bin` for the prompt and notifications.

Users of `3.6.5-1` need to install this package once by hand; from then on
updates are automatic.

## Credits

All credit for the application goes to the upstream projects:

- [`desktop/desktop`](https://github.com/desktop/desktop): GitHub, Inc. (MIT)
- [`shiftkey/desktop`](https://github.com/shiftkey/desktop): Linux fork (MIT)
- [Electron](https://github.com/electron/electron): runtime (MIT)

This package is community redistribution only and is not affiliated with or
endorsed by GitHub, Inc.
