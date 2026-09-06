#!/usr/bin/env node
// Turns a packaged GitHub Desktop Linux app directory (the output of upstream's
// `yarn build:prod`, e.g. `dist/desktop-linux-x64`) into a Debian package.
//
// Upstream's own `yarn package` only knows how to package for macOS and
// Windows, so this script drives electron-installer-debian directly with the
// metadata below. It is normally invoked by ../scripts/build-deb.sh.
//
//   node package-deb.mjs --src <app dir> --dest <out dir> --icon <png> [--arch amd64] [--revision 1]

import installer from 'electron-installer-debian'
import { existsSync, readFileSync } from 'node:fs'
import path from 'node:path'
import { parseArgs } from 'node:util'

const { values: args } = parseArgs({
  options: {
    src: { type: 'string' },
    dest: { type: 'string' },
    icon: { type: 'string' },
    arch: { type: 'string', default: 'amd64' },
    revision: { type: 'string', default: '1' },
    maintainer: { type: 'string', default: 'falcnix <falcnix@gmail.com>' },
    help: { type: 'boolean', short: 'h', default: false },
  },
})

if (args.help || !args.src || !args.dest || !args.icon) {
  console.error(
    'usage: node package-deb.mjs --src <app dir> --dest <out dir> --icon <png> [--arch amd64] [--revision 1]'
  )
  process.exit(args.help ? 0 : 2)
}

const src = path.resolve(args.src)
const dest = path.resolve(args.dest)
const icon = path.resolve(args.icon)
const here = path.dirname(new URL(import.meta.url).pathname)

// Sanity-check the input directory before handing it to the installer.
const appPackageJson = path.join(src, 'resources', 'app', 'package.json')
for (const required of [
  appPackageJson,
  path.join(src, 'desktop'), // upstream names the Linux executable `desktop`
  path.join(src, 'chrome-sandbox'),
  path.join(src, 'version'), // Electron version, read by the installer
]) {
  if (!existsSync(required)) {
    console.error(`error: ${required} not found; is --src a packaged Linux build?`)
    process.exit(1)
  }
}
if (!existsSync(icon)) {
  console.error(`error: icon ${icon} not found`)
  process.exit(1)
}

const appInfo = JSON.parse(readFileSync(appPackageJson, 'utf8'))
const electronVersion = readFileSync(path.join(src, 'version'), 'utf8').trim()

const options = {
  src,
  dest,
  arch: args.arch,
  revision: args.revision,

  name: 'github-desktop',
  productName: appInfo.productName ?? 'GitHub Desktop',
  genericName: 'Git Client',
  bin: 'desktop',
  description: appInfo.description ?? 'Simple collaboration from your desktop',
  productDescription:
    'GitHub Desktop is an open source, Electron-based Git client. ' +
    'This is an unofficial community build of the desktop/desktop source ' +
    'tree for Debian-based Linux distributions; it is not affiliated with ' +
    'or supported by GitHub, Inc. Packaging: ' +
    'https://github.com/falcnix/github-desktop-linux',
  maintainer: args.maintainer,
  homepage: 'https://github.com/desktop/desktop',
  section: 'devel',
  priority: 'optional',

  // Installed under /usr/share/icons/hicolor/512x512/apps/github-desktop.png
  icon: { '512x512': icon },
  categories: ['Development', 'RevisionControl'],
  desktopTemplate: path.join(here, 'github-desktop.desktop.ejs'),

  // The app registers these URL schemes for "sign in with browser" OAuth
  // callbacks and for github.com "Open in Desktop" links. On Linux the
  // handler only works when the .desktop file declares the schemes.
  mimeType: [
    'x-scheme-handler/x-github-client',
    'x-scheme-handler/x-github-desktop-auth',
    'x-scheme-handler/x-github-desktop-dev-auth',
  ],

  // electron-installer-debian derives the Electron/Chromium runtime
  // dependencies from the bundled Electron version; these are merged in.
  depends: [
    // The bundled Git (dugite) links git-remote-https against libcurl-gnutls.
    'libcurl3-gnutls',
  ],
  recommends: [
    // Credential storage goes through libsecret and needs a Secret Service
    // provider; GNOME Keyring is the common one (KDE users have KWallet).
    'gnome-keyring',
  ],
}

console.log(
  `Packaging ${options.productName} ${appInfo.version} (Electron ${electronVersion}) ` +
    `for ${options.arch} from ${src}`
)

try {
  await installer(options)
  console.log(`Successfully created package in ${dest}`)
} catch (err) {
  console.error(err)
  process.exit(1)
}
