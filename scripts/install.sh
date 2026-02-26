#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)"

mkdir -p "${HOME}/.local/bin"
cp "${repo_root}/bin/supermux" "${HOME}/.local/bin/supermux"
chmod +x "${HOME}/.local/bin/supermux"

mkdir -p "${HOME}/.local/share/supermux"
cp "${repo_root}/scripts/opentui-picker.ts" "${HOME}/.local/share/supermux/opentui-picker.ts"
cp "${repo_root}/config/tmux.conf.snippet" "${HOME}/.local/share/supermux/tmux.conf.snippet"

printf 'installed: %s\n' "${HOME}/.local/bin/supermux"
printf 'opentui picker: %s\n' "${HOME}/.local/share/supermux/opentui-picker.ts"
printf 'tmux config snippet: %s\n' "${HOME}/.local/share/supermux/tmux.conf.snippet"
