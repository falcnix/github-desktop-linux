# Credits & Acknowledgements

This repository is a packaging and redistribution effort. None of the
application code is original to this project. Full credit and gratitude go to the
upstream projects and their maintainers and contributors.

## Primary upstream: GitHub Desktop

- Project: [`desktop/desktop`](https://github.com/desktop/desktop)
- Author: GitHub, Inc. and the GitHub Desktop contributors
- License: [MIT](https://github.com/desktop/desktop/blob/development/LICENSE)
- What they made: the entire GitHub Desktop application, including the user
  interface, the Git and GitHub integration, history/branching/PR workflows,
  and everything that makes the app what it is. This repository simply compiles
  their open-source code and packages it for Linux.

## Linux support: shiftkey/desktop

- Project: [`shiftkey/desktop`](https://github.com/shiftkey/desktop)
- Author: [Brendan Forster (@shiftkey)](https://github.com/shiftkey) and contributors
- License: MIT
- What they made: the long-running community fork that brought GitHub Desktop to
  Linux, including Linux build configuration, `.deb`/`.rpm`/AppImage packaging,
  dependency handling, and release automation. This `.deb` follows that lineage
  of Linux packaging work.

## Runtime: Electron

- Project: [`electron/electron`](https://github.com/electron/electron)
- Author: Electron contributors, under the OpenJS Foundation
- License: [MIT](https://github.com/electron/electron/blob/main/LICENSE)
- What they made: the cross-platform runtime (Chromium + Node.js) that GitHub
  Desktop is built on. Version `42.0.1` is bundled in this package.

## Everyone else

GitHub Desktop bundles a large number of additional open-source dependencies
(libgit2, dugite, Git, and many npm packages). Their authors deserve credit too;
their license texts ship inside the application bundle.

If you find this build useful, please consider starring and supporting the
upstream projects above, since they did the real work.
