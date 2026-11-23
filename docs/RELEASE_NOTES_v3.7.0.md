# GitHub Desktop for Linux, v3.7.0

Unofficial Debian/Ubuntu `.deb` build of
[GitHub Desktop `3.7.0`](https://github.com/desktop/desktop/releases/tag/release-3.7.0)
(upstream commit `f13859b69e7c22f11913adbb4e775621c3908d97`), on Electron
`44.9.1`. Debian package version `3.7.0-1`, architecture `amd64`.

## Install

```bash
sudo apt install ./github-desktop_3.7.0-1_amd64.deb
```

If you already run `3.6.5-2` (the `v3.6.5-deb2` release), you do not need to
do anything: the app offers this update the next time it starts.

## Verify

```
SHA-256: @SHA256@
```

```bash
sha256sum -c github-desktop_3.7.0-1_amd64.deb.sha256
```

## What's new

Application changes are upstream's; see the
[upstream release notes](https://github.com/desktop/desktop/releases) for
3.6.6 through 3.7.0. Highlights:

- Several GitHub accounts side by side, on GitHub.com and on the same GitHub
  Enterprise host, with an account picker when cloning and publishing.
- Optional automatic push after each commit.
- Short-lived tokens for newly signed-in users.
- Git 2.56.1, Git LFS 3.8.1 and Electron 44.9.1.
- Fixes for a crash when Copilot stops unexpectedly, a crash in Git LFS
  progress tracking, SSH host key prompts with newer OpenSSH, and branch,
  remote and tag names that start with a dash.

Packaging changes in this release:

- Built from upstream's new npm-based build (upstream moved from Yarn to npm
  in 3.7.0).
- The bundled Git's helper programs are symlinks again, as in 3.6.x. Upstream's
  3.7.0 packaging turned them into about 600 MB of identical copies; the
  package installs about 0.6 GB instead of 1.2 GB.
- The CI smoke test now also checks that the installed app's bundled Git runs
  and can fetch over HTTPS.

## Updates

The app checks this repository for a newer package every time it starts and
offers to install it. Set `GITHUB_DESKTOP_NO_UPDATE_CHECK=1` to turn that off,
or run `github-desktop-update` to check by hand.

## Credits

All credit for the application goes to the upstream projects:

- [`desktop/desktop`](https://github.com/desktop/desktop): GitHub, Inc. (MIT)
- [`shiftkey/desktop`](https://github.com/shiftkey/desktop): Linux fork (MIT)
- [Electron](https://github.com/electron/electron): runtime (MIT)

This package is community redistribution only and is not affiliated with or
endorsed by GitHub, Inc.
