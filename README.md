# GitHub Desktop for Linux (`.deb`)

An unofficial Linux build of [GitHub Desktop](https://github.com/desktop/desktop),
packaged as a Debian/Ubuntu `.deb`. The upstream project does not ship official
Linux binaries, so this repository builds the open-source source tree and
distributes the result for Debian-based distributions.

> [!IMPORTANT]
> This is a community redistribution. It is not affiliated with, endorsed by,
> or supported by GitHub, Inc. "GitHub" and "GitHub Desktop" are trademarks of
> GitHub, Inc. All credit for the application itself goes to the upstream
> projects listed under [Credits](#credits).

## What's in this release

| | |
|---|---|
| Application | GitHub Desktop `3.6.5` |
| Package (download) | `github-desktop_3.6.5-1_amd64.deb` |
| Debian version | `3.6.5-1` |
| Architecture | `amd64` (x86-64) |
| Electron runtime | `42.0.1` |
| Built from | [`desktop/desktop`](https://github.com/desktop/desktop) tag [`release-3.6.5`](https://github.com/desktop/desktop/releases/tag/release-3.6.5) (MIT) |
| License | MIT, see [LICENSE](LICENSE) |

The `.deb` itself is published as a [Release](../../releases) asset rather than
committed to the repository (it is about 230 MB).

## Install

Download `github-desktop_3.6.5-1_amd64.deb` from the
[latest release](../../releases/latest), then:

```bash
# Recommended, resolves dependencies automatically
sudo apt install ./github-desktop_3.6.5-1_amd64.deb

# Or with dpkg (then fix any missing deps)
sudo dpkg -i ./github-desktop_3.6.5-1_amd64.deb
sudo apt-get install -f
```

Launch from your application menu, or run `github-desktop` from a terminal.

> [!NOTE]
> For pre-release builds the Debian version contains a `~` (for example
> `3.5.13~beta1-1`), but the file is named with a `.` instead
> (`github-desktop_3.5.13.beta1-1_amd64.deb`) because GitHub does not allow
> `~` in release asset names. The installed package version still has the `~`.

### Verify the download

```bash
sha256sum -c github-desktop_3.6.5-1_amd64.deb.sha256
```

Expected SHA-256:

```
7c25d868a64ce2e926611eeb646a39ce8aabf1fa970e57dc3a1dfc2a31b6e4df
```

Checksums for every release are also kept under [`checksums/`](checksums).

## Update / uninstall

```bash
# Update: install a newer .deb the same way (apt install ./<file>.deb)
# Uninstall:
sudo apt remove github-desktop
```

## Requirements and dependencies

Ubuntu 22.04 or newer, Debian 12 or newer, or a derivative (glibc 2.35+).

Pulled in automatically by `apt`: `libgtk-3-0`, `libnotify4`, `libnss3`,
`xdg-utils`, `libatspi2.0-0`, `libdrm2`, `libgbm1`, `libxcb-dri3-0`,
`libsecret-1-0`, `libcurl3-gnutls` and a trash handler
(`kde-cli-tools | kde-runtime | trash-cli | libglib2.0-bin | gvfs`).
Recommended: `gnome-keyring` (or another Secret Service provider such as
KWallet) so that sign-in tokens can be stored, and `libasound2`/`pulseaudio`.

## Troubleshooting

- **Signing in with the browser does nothing.** The package registers the
  `x-github-desktop-auth`/`x-github-desktop-dev-auth` URL schemes; if your
  desktop's MIME database was not refreshed, run
  `sudo update-desktop-database` and try again.
- **Blank or garbled window.** Try
  `GITHUB_DESKTOP_DISABLE_HARDWARE_ACCELERATION=1 github-desktop`.
- **Anything else.** Run `github-desktop` from a terminal and include the
  output when opening an issue here. Application bugs belong upstream at
  [`desktop/desktop`](https://github.com/desktop/desktop/issues).

## How this is built

See [docs/BUILD.md](docs/BUILD.md). In short: the
[Build .deb](.github/workflows/build-deb.yml) GitHub Actions workflow checks
out the official [`desktop/desktop`](https://github.com/desktop/desktop) source
at a release tag, runs upstream's own production build, packages the result
with `electron-installer-debian` using the configuration in
[`packaging/`](packaging), installs and launches the package on a clean Ubuntu
runner, and uploads it to a draft release. The same steps run locally with
`scripts/build-deb.sh`. A weekly workflow opens an issue when upstream
publishes a newer version than the one shipped here.

## Credits

This project is only packaging and redistribution. The application and its
ecosystem are the work of others:

- [GitHub Desktop (`desktop/desktop`)](https://github.com/desktop/desktop):
  copyright GitHub, Inc. and GitHub Desktop contributors. The entire
  application. Licensed under the
  [MIT License](https://github.com/desktop/desktop/blob/development/LICENSE).
- [GitHub Desktop Linux fork (`shiftkey/desktop`)](https://github.com/shiftkey/desktop):
  by Brendan Forster and contributors, the community effort that made Linux
  builds and packaging of GitHub Desktop possible.
- [Electron](https://github.com/electron/electron): copyright Electron
  contributors / OpenJS Foundation, the application runtime (v42.0.1).
- [`electron-installer-debian`](https://github.com/electron-userland/electron-installer-debian):
  the tool that turns the built app into a `.deb`.

See [CREDITS.md](CREDITS.md) and [NOTICE](NOTICE) for full attribution.

## License

The redistributed software is licensed under the MIT License, preserving the
upstream copyright of GitHub, Inc. and the Electron contributors. The original
files added by this repository (documentation, packaging scripts and metadata)
are also released under MIT. See [LICENSE](LICENSE).
