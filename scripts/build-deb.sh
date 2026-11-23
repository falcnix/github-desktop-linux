#!/usr/bin/env bash
#
# Build GitHub Desktop from the upstream desktop/desktop source tree and
# package it as a Debian package.
#
#   scripts/build-deb.sh --ref release-3.6.5 [--work build] [--out dist]
#   scripts/build-deb.sh --src-tree /path/to/desktop-checkout [--out dist]
#
# Options:
#   --ref <git ref>     Upstream tag/branch to clone (e.g. release-3.6.5).
#   --src-tree <dir>    Use an existing upstream checkout instead of cloning.
#   --work <dir>        Where to clone into (default: ./build). Ignored with --src-tree.
#   --out <dir>         Where to put the .deb and .sha256 (default: ./dist).
#   --channel <name>    RELEASE_CHANNEL for the build (production|beta|test).
#                       Defaults to a value derived from the upstream version.
#   --skip-build        Reuse an existing dist/desktop-linux-* build directory.
#   --revision <n>      Debian package revision (default 1). Bump it to
#                       re-release the same upstream version with packaging
#                       changes; the release is then tagged v<version>-deb<n>.
#
# Environment:
#   DESKTOP_OAUTH_CLIENT_ID / DESKTOP_OAUTH_CLIENT_SECRET
#                       Optional OAuth app credentials. Without them upstream
#                       falls back to its development OAuth app, which works
#                       but is shared with every other community build.
#
# Requirements: git, node + npm (see upstream .node-version), yarn 1.x only
#   for upstream releases before 3.7.0, dpkg-deb,
#   a C/C++ toolchain and python3 (native modules), libsecret-1-dev (keytar).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_URL="https://github.com/desktop/desktop.git"

REF=""
SRC_TREE=""
WORK="$PWD/build"
OUT="$PWD/dist"
CHANNEL="${RELEASE_CHANNEL:-}"
SKIP_BUILD=0
REVISION=1

usage() { sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --ref) REF="$2"; shift 2 ;;
    --src-tree) SRC_TREE="$2"; shift 2 ;;
    --work) WORK="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --channel) CHANNEL="$2"; shift 2 ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    --revision) REVISION="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$REF" ] && [ -z "$SRC_TREE" ]; then
  echo "error: one of --ref or --src-tree is required" >&2
  usage >&2
  exit 2
fi
case "$REVISION" in
  ''|*[!0-9]*|0*) echo "error: --revision must be a positive integer" >&2; exit 2 ;;
esac

log() { printf '\n==> %s\n' "$*"; }

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required tool '$1' not found in PATH" >&2
    exit 1
  fi
}
for tool in git node npm dpkg-deb sha256sum; do need "$tool"; done

# ---------------------------------------------------------------------------
# 1. Obtain the upstream source tree
# ---------------------------------------------------------------------------
if [ -n "$SRC_TREE" ]; then
  SRC="$(cd "$SRC_TREE" && pwd)"
else
  SRC="$WORK/src"
  if [ -d "$SRC/.git" ]; then
    log "Reusing existing checkout in $SRC"
  else
    log "Cloning desktop/desktop@$REF into $SRC"
    mkdir -p "$WORK"
    git clone --depth 1 --branch "$REF" "$UPSTREAM_URL" "$SRC"
  fi
fi

if [ ! -f "$SRC/app/package.json" ]; then
  echo "error: $SRC does not look like a desktop/desktop checkout" >&2
  exit 1
fi

APP_VERSION="$(node -p "require('$SRC/app/package.json').version")"
UPSTREAM_COMMIT="$(git -C "$SRC" rev-parse HEAD)"
WANT_NODE="$(cat "$SRC/.node-version" 2>/dev/null || true)"
HAVE_NODE="$(node --version | sed 's/^v//')"

if [ -z "$CHANNEL" ]; then
  case "$APP_VERSION" in
    *-beta*) CHANNEL=beta ;;
    *-test*) CHANNEL=test ;;
    *) CHANNEL=production ;;
  esac
fi

# Upstream switched from Yarn 1 to npm in 3.7.0. Follow whichever lockfile
# the checked-out tree has, so both older and newer releases still build.
if [ -f "$SRC/package-lock.json" ]; then
  PM=npm
elif [ -f "$SRC/yarn.lock" ]; then
  PM=yarn
  need yarn
else
  echo "error: $SRC has neither package-lock.json nor yarn.lock" >&2
  exit 1
fi

log "GitHub Desktop $APP_VERSION ($UPSTREAM_COMMIT), channel=$CHANNEL"
echo "node $HAVE_NODE (upstream wants ${WANT_NODE:-unknown}), $PM $($PM --version)"
if [ -n "$WANT_NODE" ] && [ "${WANT_NODE%%.*}" != "${HAVE_NODE%%.*}" ]; then
  echo "warning: Node major version differs from upstream's .node-version" >&2
fi

# Upstream's package.json may require a minimum npm (3.7.0: >= 11.17.0).
# npm does not enforce "engines" by itself, so check it here and fail with a
# clear message instead of an obscure install error later.
if [ "$PM" = npm ]; then
  WANT_NPM="$(node -p "((require('$SRC/package.json').engines||{}).npm||'').replace(/[^0-9.]/g,'')")"
  HAVE_NPM="$(npm --version)"
  if [ -n "$WANT_NPM" ] && [ "$(printf '%s\n%s\n' "$WANT_NPM" "$HAVE_NPM" | sort -V | head -n 1)" != "$WANT_NPM" ]; then
    echo "error: upstream needs npm >= $WANT_NPM, found $HAVE_NPM (use the Node version in .node-version)" >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# 2. Build the app (this is exactly what upstream CI runs)
# ---------------------------------------------------------------------------
DIST_APP="$SRC/dist/desktop-linux-x64"

if [ "$SKIP_BUILD" -eq 1 ] && [ -d "$DIST_APP" ]; then
  log "Skipping build, reusing $DIST_APP"
else
  # Ubuntu's gcc predefines _FORTIFY_SOURCE. Upstream's native helpers
  # (printenvz, desktop-trampoline) compile with -Werror -D_FORTIFY_SOURCE=1,
  # which then fails with "_FORTIFY_SOURCE redefined". Undefining it before
  # the module's own flags is harmless everywhere else.
  if [ "$(uname -s)" = "Linux" ]; then
    export CC="${CC:-cc} -U_FORTIFY_SOURCE"
    export CXX="${CXX:-c++} -U_FORTIFY_SOURCE"
  fi

  log "Installing dependencies ($PM)"
  if [ "$PM" = npm ]; then
    # Upstream's build scripts locate npm through npm_execpath, so they must
    # run via `npm run`, never directly with ts-node.
    (cd "$SRC" && npm ci --no-audit --no-fund)
  else
    (cd "$SRC" && yarn install --frozen-lockfile --network-timeout 600000)
  fi

  log "Building production app"
  if [ "$PM" = npm ]; then
    (cd "$SRC" && RELEASE_CHANNEL="$CHANNEL" npm run build:prod)
  else
    (cd "$SRC" && RELEASE_CHANNEL="$CHANNEL" yarn build:prod)
  fi
fi

if [ ! -x "$DIST_APP/desktop" ]; then
  echo "error: expected packaged app at $DIST_APP" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 2b. Restore the bundled Git's symlinks
# ---------------------------------------------------------------------------
# dugite ships Git's dashed builtins (git-upload-pack, git-remote-https, ...)
# as symlinks to `git` and `git-remote-http`. Since 3.7.0 upstream packages
# with derefSymlinks, which turns each of them into a full copy of the
# binary: ~600 MB of identical files. Git dispatches on argv[0], so pointing
# them back at the one binary is exactly the layout dugite intended and the
# one 3.6.x shipped. Only byte-identical files are touched.
GIT_CORE="$DIST_APP/resources/app/git/libexec/git-core"
if [ -d "$GIT_CORE" ]; then
  relinked=0
  for target in git git-remote-http; do
    [ -f "$GIT_CORE/$target" ] && [ ! -L "$GIT_CORE/$target" ] || continue
    for f in "$GIT_CORE"/*; do
      [ -f "$f" ] && [ ! -L "$f" ] || continue
      case "$(basename "$f")" in git|git-remote-http) continue ;; esac
      if cmp -s "$f" "$GIT_CORE/$target"; then
        ln -sfn "$target" "$f"
        relinked=$((relinked + 1))
      fi
    done
  done
  log "Relinked $relinked duplicate Git helpers ($(du -sh "$DIST_APP/resources/app/git" | cut -f1) bundled Git)"

  # The bundled Git must still run, including a helper reached via symlink.
  "$DIST_APP/resources/app/git/bin/git" --version
  set +e
  "$GIT_CORE/git-upload-pack" >/dev/null 2>&1
  rc=$?
  set -e
  # Usage error (129) or success both prove the binary ran; 126/127 mean a
  # broken link or missing interpreter.
  case "$rc" in 0|129) ;; *) echo "error: bundled git-upload-pack failed to run ($rc)" >&2; exit 1 ;; esac
fi

# ---------------------------------------------------------------------------
# 3. Package it as a .deb
# ---------------------------------------------------------------------------
log "Installing packaging tooling"
(cd "$REPO_ROOT/packaging" && npm ci --no-audit --no-fund --silent)

log "Adding launcher and self-updater"
for f in github-desktop update-check github-desktop-update; do
  install -m 0755 "$REPO_ROOT/packaging/resources/$f" "$DIST_APP/$f"
done

log "Creating Debian package (revision $REVISION)"
mkdir -p "$OUT"
node "$REPO_ROOT/packaging/package-deb.mjs" \
  --src "$DIST_APP" \
  --dest "$OUT" \
  --icon "$SRC/app/static/linux/icon-logo.png" \
  --arch amd64 \
  --revision "$REVISION"

DEB="$(ls -t "$OUT"/github-desktop_*_amd64.deb | head -n 1)"

# Pre-release Debian versions contain "~" (3.6.6~beta1-1). GitHub Releases
# rewrites "~" to "." in asset names, so name the file that way ourselves:
# the checksum file, the release asset and the docs then all agree, and
# re-uploads with --clobber match the existing asset. The version inside the
# package is unchanged; dpkg and apt do not care about the file name.
case "$(basename "$DEB")" in
  *~*)
    RENAMED="$OUT/$(basename "$DEB" | tr '~' '.')"
    mv -f "$DEB" "$RENAMED"
    DEB="$RENAMED"
    ;;
esac

# ---------------------------------------------------------------------------
# 4. Verify and checksum
# ---------------------------------------------------------------------------
log "Verifying $DEB"
dpkg-deb --info "$DEB"

# Capture the listing once; piping dpkg-deb into `grep -q` would make tar fail
# with a write error when grep exits early.
CONTENTS="$(dpkg-deb --contents "$DEB")"

# Chromium refuses to start (on systems where unprivileged user namespaces are
# restricted) unless chrome-sandbox is setuid root. Make sure the mode survived.
if ! grep -E '^-rws.* \./usr/lib/github-desktop/chrome-sandbox$' <<<"$CONTENTS" >/dev/null; then
  echo "error: chrome-sandbox is not setuid root inside the package" >&2
  exit 1
fi

for required in usr/bin/github-desktop usr/share/applications/github-desktop.desktop \
  usr/share/icons/hicolor/512x512/apps/github-desktop.png \
  usr/lib/github-desktop/github-desktop usr/lib/github-desktop/update-check \
  usr/lib/github-desktop/github-desktop-update usr/lib/github-desktop/desktop; do
  if ! grep -F " ./$required" <<<"$CONTENTS" >/dev/null; then
    echo "error: $required missing from package" >&2
    exit 1
  fi
done

for script in postinst postrm; do
  if ! dpkg-deb --ctrl-tarfile "$DEB" | tar -t | grep -qx "./$script"; then
    echo "error: maintainer script $script missing from package" >&2
    exit 1
  fi
done

(cd "$OUT" && sha256sum "$(basename "$DEB")" > "$(basename "$DEB").sha256")

# Release tag: v<app version>, plus -deb<revision> for re-releases of the
# same upstream version. The self-updater parses this format.
RELEASE_TAG="v$APP_VERSION"
[ "$REVISION" != "1" ] && RELEASE_TAG="$RELEASE_TAG-deb$REVISION"

cat > "$OUT/build-info.txt" <<EOF
app_version=$APP_VERSION
release_tag=$RELEASE_TAG
revision=$REVISION
upstream_ref=${REF:-$(git -C "$SRC" describe --tags --always)}
upstream_commit=$UPSTREAM_COMMIT
electron_version=$(cat "$DIST_APP/version")
deb_version=$(dpkg-deb --field "$DEB" Version)
deb_file=$(basename "$DEB")
sha256=$(cut -d' ' -f1 "$OUT/$(basename "$DEB").sha256")
release_channel=$CHANNEL
node_version=$HAVE_NODE
built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

log "Done"
cat "$OUT/build-info.txt"
