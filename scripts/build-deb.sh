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
#
# Environment:
#   DESKTOP_OAUTH_CLIENT_ID / DESKTOP_OAUTH_CLIENT_SECRET
#                       Optional OAuth app credentials. Without them upstream
#                       falls back to its development OAuth app, which works
#                       but is shared with every other community build.
#
# Requirements: git, node (see upstream .node-version), yarn 1.x, dpkg-deb,
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

usage() { sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --ref) REF="$2"; shift 2 ;;
    --src-tree) SRC_TREE="$2"; shift 2 ;;
    --work) WORK="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --channel) CHANNEL="$2"; shift 2 ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$REF" ] && [ -z "$SRC_TREE" ]; then
  echo "error: one of --ref or --src-tree is required" >&2
  usage >&2
  exit 2
fi

log() { printf '\n==> %s\n' "$*"; }

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required tool '$1' not found in PATH" >&2
    exit 1
  fi
}
for tool in git node yarn dpkg-deb sha256sum; do need "$tool"; done

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

log "GitHub Desktop $APP_VERSION ($UPSTREAM_COMMIT), channel=$CHANNEL"
echo "node $HAVE_NODE (upstream wants ${WANT_NODE:-unknown}), yarn $(yarn --version)"
if [ -n "$WANT_NODE" ] && [ "${WANT_NODE%%.*}" != "${HAVE_NODE%%.*}" ]; then
  echo "warning: Node major version differs from upstream's .node-version" >&2
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

  log "Installing dependencies"
  (cd "$SRC" && yarn install --frozen-lockfile --network-timeout 600000)

  log "Building production app"
  (cd "$SRC" && RELEASE_CHANNEL="$CHANNEL" yarn build:prod)
fi

if [ ! -x "$DIST_APP/desktop" ]; then
  echo "error: expected packaged app at $DIST_APP" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 3. Package it as a .deb
# ---------------------------------------------------------------------------
log "Installing packaging tooling"
(cd "$REPO_ROOT/packaging" && npm ci --no-audit --no-fund --silent)

log "Creating Debian package"
mkdir -p "$OUT"
node "$REPO_ROOT/packaging/package-deb.mjs" \
  --src "$DIST_APP" \
  --dest "$OUT" \
  --icon "$SRC/app/static/linux/icon-logo.png" \
  --arch amd64

DEB="$(ls -t "$OUT"/github-desktop_*_amd64.deb | head -n 1)"

# ---------------------------------------------------------------------------
# 4. Verify and checksum
# ---------------------------------------------------------------------------
log "Verifying $DEB"
dpkg-deb --info "$DEB"

# Chromium refuses to start (on systems where unprivileged user namespaces are
# restricted) unless chrome-sandbox is setuid root. Make sure the mode survived.
if ! dpkg-deb --contents "$DEB" | grep -E '^-rws' | grep -q 'chrome-sandbox'; then
  echo "error: chrome-sandbox is not setuid root inside the package" >&2
  exit 1
fi

for required in usr/bin/github-desktop usr/share/applications/github-desktop.desktop \
  usr/share/icons/hicolor/512x512/apps/github-desktop.png; do
  if ! dpkg-deb --contents "$DEB" | grep -q " \./$required"; then
    echo "error: $required missing from package" >&2
    exit 1
  fi
done

(cd "$OUT" && sha256sum "$(basename "$DEB")" > "$(basename "$DEB").sha256")

cat > "$OUT/build-info.txt" <<EOF
app_version=$APP_VERSION
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
