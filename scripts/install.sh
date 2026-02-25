#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)"

mkdir -p "${HOME}/.local/bin"
cp "${repo_root}/bin/tmx" "${HOME}/.local/bin/tmx"
chmod +x "${HOME}/.local/bin/tmx"

printf 'installed: %s\n' "${HOME}/.local/bin/tmx"
printf 'tmux config snippet: %s\n' "${repo_root}/config/tmux.conf.snippet"
