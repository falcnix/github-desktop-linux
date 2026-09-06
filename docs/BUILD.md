# Build provenance

This document records how the distributed `.deb` is produced, so the build is
transparent and reproducible.

## Summary

| Field | Value |
|---|---|
| Application | GitHub Desktop |
| Version | `3.6.5` |
| Package version | `3.6.5-1` |
| Architecture | `amd64` |
| Electron | `42.0.1` |
| Source | [`desktop/desktop`](https://github.com/desktop/desktop) tag [`release-3.6.5`](https://github.com/desktop/desktop/releases/tag/release-3.6.5) |
| Packaged by | falcnix &lt;falcnix@gmail.com&gt; |
| Format | Debian binary package (`.deb`) |

Older releases and their provenance are listed in the
[Releases](../../../releases) page; each release carries its own checksum and
the exact upstream commit it was built from.

## How the package is built

Upstream's own `yarn package` step only knows how to package for macOS and
Windows, so this repository adds the Linux packaging step itself. Everything
lives in this repository and is driven by one script:

```
scripts/build-deb.sh          # clone (or reuse) upstream, build, package, verify, checksum
packaging/package-deb.mjs     # electron-installer-debian configuration (metadata, deps, icon, MIME types)
packaging/github-desktop.desktop.ejs   # template for the .desktop launcher
.github/workflows/build-deb.yml        # the same script on a clean GitHub Actions runner
```

The steps are:

1. Check out `desktop/desktop` at the release tag.
2. `yarn install --frozen-lockfile` and `yarn build:prod` with
   `RELEASE_CHANNEL=production` (or `beta`/`test`, derived from the version).
   This is exactly what upstream CI runs; it produces
   `dist/desktop-linux-x64/`, an Electron app directory.
3. Run [`electron-installer-debian`](https://github.com/electron-userland/electron-installer-debian)
   over that directory. Runtime dependencies for the bundled Electron are
   derived automatically; on top of those the package adds `libcurl3-gnutls`
   (the bundled Git's HTTPS helper links against it) and recommends
   `gnome-keyring` (credential storage uses libsecret).
4. Verify the result: `chrome-sandbox` is setuid root, the launcher, `.desktop`
   file and icon are present, and write a SHA-256 checksum next to the `.deb`.

The GitHub Actions workflow additionally installs the package on a clean
Ubuntu 22.04 runner, launches it under a virtual X server, checks that it is
still running after 20 seconds, and uploads the package to a draft release.

### Building it yourself

Requirements: `git`, Node (the version in upstream's `.node-version`, 24.x at
the time of writing), Yarn 1.x, `dpkg-deb`, a C/C++ toolchain, `python3` and
`libsecret-1-dev` (for the native modules).

```bash
git clone https://github.com/falcnix/github-desktop-linux.git
cd github-desktop-linux

# Build a specific upstream release (clones into ./build, output in ./dist)
scripts/build-deb.sh --ref release-3.6.5

# Or package an upstream checkout you already have
scripts/build-deb.sh --src-tree ~/src/desktop --out dist
```

Or run the **Build .deb** workflow from the Actions tab with `upstream_ref`
set to the tag you want. Exact toolchain versions (Node, OS) affect the
bytes of the output, so a rebuild will not be bit-for-bit identical, but the
contents and behaviour are.

### OAuth credentials

GitHub Desktop signs in through a GitHub OAuth app. If
`DESKTOP_OAUTH_CLIENT_ID` / `DESKTOP_OAUTH_CLIENT_SECRET` are not set at
build time, upstream falls back to its development OAuth app. This works,
but it is the same app every community build uses. Set the two repository
secrets to use your own.

### Staying current

The **Check upstream for new releases** workflow runs weekly and opens an
issue when `desktop/desktop` publishes a version newer than the newest release
here.

## Package metadata

Extracted from the `.deb` control file:

```
Package: github-desktop
Version: 3.6.5-1
Section: devel
Priority: optional
Architecture: amd64
Depends: libgtk-3-0, libnotify4, libnss3, xdg-utils, libatspi2.0-0, libdrm2, libgbm1, libxcb-dri3-0, libsecret-1-0, kde-cli-tools | kde-runtime | trash-cli | libglib2.0-bin | gvfs-bin, libcurl3-gnutls
Recommends: libasound2t64 | libasound2 | pulseaudio, gnome-keyring
Suggests: lsb-release
Maintainer: falcnix <falcnix@gmail.com>
Homepage: https://github.com/desktop/desktop
Description: Simple collaboration from your desktop
```

## Verification

Each release publishes a SHA-256 checksum alongside the `.deb`:

```bash
sha256sum -c github-desktop_3.6.5-1_amd64.deb.sha256
```

The checksums of every release are also committed under [`checksums/`](../checksums).
