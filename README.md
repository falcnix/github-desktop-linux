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
| Application | GitHub Desktop `3.5.13-beta1` |
| Package (download) | `github-desktop_3.5.13.beta1-1_amd64.deb` |
| Debian version | `3.5.13~beta1-1` |
| Architecture | `amd64` (x86-64) |
| Electron runtime | `42.0.1` |
| Built from | [`desktop/desktop`](https://github.com/desktop/desktop) (MIT) |
| License | MIT, see [LICENSE](LICENSE) |

The `.deb` itself is published as a [Release](../../releases) asset rather than
committed to the repository (it is about 152 MB).

## Install

Download `github-desktop_3.5.13.beta1-1_amd64.deb` from the
[latest release](../../releases/latest), then:

> [!NOTE]
> GitHub replaces the `~` in the Debian version with `.` in the release asset
> name, so the downloaded file is `github-desktop_3.5.13.beta1-1_amd64.deb`
> even though the installed package version is `3.5.13~beta1-1`.

```bash
# Recommended, resolves dependencies automatically
sudo apt install ./github-desktop_3.5.13.beta1-1_amd64.deb

# Or with dpkg (then fix any missing deps)
sudo dpkg -i ./github-desktop_3.5.13.beta1-1_amd64.deb
sudo apt-get install -f
```

Launch from your application menu, or run `github-desktop` from a terminal.

### Verify the download

```bash
sha256sum -c github-desktop_3.5.13.beta1-1_amd64.deb.sha256
```

Expected SHA-256:

```
1c4a0646d2a748839770f8bb71078fd05762cb03f3c67ebe45b7ab0ebb013cd0
```

## Update / uninstall

```bash
# Update: install a newer .deb the same way (apt install ./<file>.deb)
# Uninstall:
sudo apt remove github-desktop
```

## Dependencies

Pulled in automatically by `apt`: `libgtk-3-0`, `libnotify4`, `libnss3`,
`xdg-utils`, `libatspi2.0-0`, `libdrm2`, `libgbm1`, `libxcb-dri3-0`, `libxss1`,
`libxtst6`, `libsecret-1-0`, `libasound2`, and a trash-handler
(`kde-cli-tools | trash-cli | gvfs-bin`).

## How this was built

See [docs/BUILD.md](docs/BUILD.md) for the build provenance. In short: the
official open-source [`desktop/desktop`](https://github.com/desktop/desktop)
source was compiled locally and packaged into a `.deb` using the project's own
Linux packaging tooling.

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

See [CREDITS.md](CREDITS.md) and [NOTICE](NOTICE) for full attribution.

## License

The redistributed software is licensed under the MIT License, preserving the
upstream copyright of GitHub, Inc. and the Electron contributors. The original
files added by this repository (documentation, packaging metadata) are also
released under MIT. See [LICENSE](LICENSE).
