# Build provenance

This document records how the distributed `.deb` was produced, so the build is
transparent and reproducible.

## Summary

| Field | Value |
|---|---|
| Application | GitHub Desktop |
| Version | `3.5.13-beta1` |
| Package version | `3.5.13~beta1-1` |
| Architecture | `amd64` |
| Electron | `42.0.1` |
| Source | [`desktop/desktop`](https://github.com/desktop/desktop) (development branch) |
| Packaged by | falcnix &lt;falcnix@gmail.com&gt; |
| Format | Debian binary package (`.deb`) |

## Package metadata

Extracted from the `.deb` control file:

```
Package: github-desktop
Version: 3.5.13~beta1-1
Section: devel
Priority: optional
Architecture: amd64
Maintainer: falcnix <falcnix@gmail.com>
Homepage: https://github.com/desktop/desktop
Description: Simple collaboration from your desktop
 GitHub Desktop is an open source, Electron-based Git client. This package was
 built locally from the desktop/desktop development branch.
```

## Reproducing a build

The upstream project documents its own setup; the high-level flow is:

```bash
# 1. Clone the open-source source
git clone https://github.com/desktop/desktop.git
cd desktop

# 2. Install dependencies (see upstream docs for required Node version)
yarn

# 3. Build the production app
yarn build:prod

# 4. Produce the Linux package(s) with the project's packaging tooling
yarn package
```

The resulting `.deb` is what this repository distributes. Exact toolchain
versions (Node, Yarn, OS) affect the output; consult the upstream
[CONTRIBUTING / setup docs](https://github.com/desktop/desktop/blob/development/docs/contributing/setup.md)
for current requirements.

## Verification

Each release publishes a SHA-256 checksum alongside the `.deb`:

```bash
sha256sum -c github-desktop_3.5.13~beta1-1_amd64.deb.sha256
```
