#!/usr/bin/env bash
set -euo pipefail

have() { command -v "$1" >/dev/null 2>&1; }
die() { printf 'release: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage:
  ./scripts/release.sh VERSION [--full-tests] [--skip-tests]

Examples:
  ./scripts/release.sh 0.3.0
  ./scripts/release.sh 0.3.0 --full-tests
  ./scripts/release.sh 0.3.1 --skip-tests
EOF
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)"

VERSION=""
SKIP_TESTS=0
FULL_TESTS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-tests)
      SKIP_TESTS=1
      shift
      ;;
    --full-tests)
      FULL_TESTS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$VERSION" ]]; then
        VERSION="$1"
      else
        die "unexpected argument: $1"
      fi
      shift
      ;;
  esac
done

[[ -n "$VERSION" ]] || die "missing VERSION"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || die "invalid VERSION: $VERSION"

have git || die "git not found"
have npm || die "npm not found"
have curl || die "curl not found"
have python3 || die "python3 not found"
have shasum || die "shasum not found"

cd "$ROOT"

git diff --quiet || die "working tree has unstaged changes"
git diff --cached --quiet || die "working tree has staged changes"

TAG="v${VERSION}"
if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null 2>&1; then
  die "tag already exists: ${TAG}"
fi

REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
[[ -n "$REMOTE_URL" ]] || die "origin remote not found"

REPO_HTTP=""
case "$REMOTE_URL" in
  https://github.com/*)
    REPO_HTTP="${REMOTE_URL%.git}"
    ;;
  git@github.com:*)
    REPO_HTTP="https://github.com/${REMOTE_URL#git@github.com:}"
    REPO_HTTP="${REPO_HTTP%.git}"
    ;;
  *)
    die "origin must point to GitHub"
    ;;
esac

CURRENT_VERSION="$(
  python3 - "$ROOT/package.json" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

print(data.get("version", ""))
PY
)"

if [[ "$CURRENT_VERSION" == "$VERSION" ]]; then
  die "package.json already at version ${VERSION}"
fi

python3 - "$ROOT/package.json" "$VERSION" <<'PY'
import json
import sys

path = sys.argv[1]
version = sys.argv[2]

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

data["version"] = version

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY

if [[ "$SKIP_TESTS" != "1" ]]; then
  if [[ "$FULL_TESTS" == "1" ]]; then
    ./test/run.sh all
  else
    ./test/run.sh unit
  fi
fi

git add package.json
git commit -m "chore: release ${TAG}"
git tag -a "$TAG" -m "Release ${TAG}"

git push
git push origin "$TAG"

TARBALL_URL="${REPO_HTTP}/archive/refs/tags/${TAG}.tar.gz"
TARBALL_TMP="$(mktemp "${TMPDIR:-/tmp}/supermux-release-tarball.XXXXXX")"
cleanup() {
  rm -f "$TARBALL_TMP"
}
trap cleanup EXIT

download_ok=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if curl -fsSL "$TARBALL_URL" -o "$TARBALL_TMP"; then
    download_ok=1
    break
  fi
  sleep 2
done

[[ "$download_ok" == "1" ]] || die "failed to download ${TARBALL_URL}"

SHA256="$(shasum -a 256 "$TARBALL_TMP" | awk '{print $1}')"

cat >"$ROOT/packaging/homebrew/supermux.rb" <<EOF
class Supermux < Formula
  desc "Directory-scoped tmux session manager with OpenTUI picker"
  homepage "${REPO_HTTP}"
  url "${TARBALL_URL}"
  sha256 "${SHA256}"
  version "${VERSION}"
  license "UNLICENSED"
  head "${REPO_HTTP}.git", branch: "main"

  depends_on "bun"
  depends_on "tmux"

  def install
    bin.install "bin/supermux"
    (share/"supermux").install "scripts/opentui-picker.ts"
    (share/"supermux").install "config/tmux.conf.snippet"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/supermux --help")
  end
end
EOF

git add packaging/homebrew/supermux.rb
git commit -m "chore: update Homebrew formula for ${TAG}"
git push

printf 'released %s\n' "$TAG"
printf 'npm publish --tag %s\n' "latest"
