# GitHub Desktop for Linux, v3.6.5

Unofficial Debian/Ubuntu `.deb` build of
[GitHub Desktop `3.6.5`](https://github.com/desktop/desktop/releases/tag/release-3.6.5)
(upstream commit `13b57bd28dcaa94ec55374f814dab7a1645ae3b0`), on Electron
`42.0.1`. Debian package version `3.6.5-1`, architecture `amd64`.

Built by the [Build .deb](../.github/workflows/build-deb.yml) workflow on a
clean Ubuntu 22.04 runner; see [BUILD.md](BUILD.md).

## Install

```bash
sudo apt install ./github-desktop_3.6.5-1_amd64.deb
```

## Verify

```
SHA-256: 7c25d868a64ce2e926611eeb646a39ce8aabf1fa970e57dc3a1dfc2a31b6e4df
```

```bash
sha256sum -c github-desktop_3.6.5-1_amd64.deb.sha256
```

## What's new

Application changes since the previous package (3.5.13-beta1) are upstream's;
see the [upstream release notes](https://github.com/desktop/desktop/releases)
for 3.6.0 through 3.6.5. Highlights include Git worktree support, resolving
merge conflicts with Copilot, and a number of crash and freeze fixes.

Packaging changes in this release:

- Built reproducibly by CI from the upstream `release-3.6.5` tag instead of
  by hand, and installed and launched on a clean system before publishing.
- `libcurl3-gnutls` is now a declared dependency (the bundled Git's HTTPS
  helper needs it), and `gnome-keyring` is recommended for credential storage.
- The `.desktop` launcher now registers the `x-github-desktop-auth` and
  `x-github-desktop-dev-auth` URL schemes, so "Sign in using your browser"
  returns to the app.
- The application icon is installed into the hicolor icon theme.

## Credits

All credit for the application goes to the upstream projects:

- [`desktop/desktop`](https://github.com/desktop/desktop): GitHub, Inc. (MIT)
- [`shiftkey/desktop`](https://github.com/shiftkey/desktop): Linux fork (MIT)
- [Electron](https://github.com/electron/electron): runtime (MIT)

This package is community redistribution only and is not affiliated with or
endorsed by GitHub, Inc.
