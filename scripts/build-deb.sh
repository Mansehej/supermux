#!/usr/bin/env bash
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }
die() { printf 'build-deb: %s\n' "$*" >&2; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)"

VERSION="${1:-}"
[[ -n "$VERSION" ]] || die "usage: $0 VERSION [ARCH]"

ARCH="${2:-all}"
OUT_DIR="${OUT_DIR:-${ROOT}/dist}"

have dpkg-deb || die "dpkg-deb not found"

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/supermux-deb.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

PKG_DIR="${WORKDIR}/supermux_${VERSION}_${ARCH}"
mkdir -p "${PKG_DIR}/DEBIAN"
mkdir -p "${PKG_DIR}/usr/bin"
mkdir -p "${PKG_DIR}/usr/share/supermux"

install -m 0755 "${ROOT}/bin/supermux" "${PKG_DIR}/usr/bin/supermux"
install -m 0644 "${ROOT}/scripts/opentui-picker.ts" "${PKG_DIR}/usr/share/supermux/opentui-picker.ts"
install -m 0644 "${ROOT}/config/tmux.conf.snippet" "${PKG_DIR}/usr/share/supermux/tmux.conf.snippet"

cat >"${PKG_DIR}/DEBIAN/control" <<EOF
Package: supermux
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: tmux, bun
Maintainer: supermux maintainers <noreply@users.noreply.github.com>
Description: Directory-scoped tmux session manager with OpenTUI picker
 supermux manages tmux sessions scoped by project directory and provides
 an OpenTUI picker for attach, detach, and kill flows.
EOF

mkdir -p "${OUT_DIR}"
OUTPUT_PATH="${OUT_DIR}/supermux_${VERSION}_${ARCH}.deb"
dpkg-deb --build "${PKG_DIR}" "${OUTPUT_PATH}" >/dev/null

printf 'built: %s\n' "${OUTPUT_PATH}"
