#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)"

mode="all"
if [[ $# -gt 0 ]]; then
  mode="$1"
fi

case "$mode" in
  all)
    "${ROOT}/test/unit/supermux_unit.sh"
    "${ROOT}/test/e2e/tabs_pilotty.sh"
    ;;
  unit)
    "${ROOT}/test/unit/supermux_unit.sh"
    ;;
  e2e)
    "${ROOT}/test/e2e/tabs_pilotty.sh"
    ;;
  *)
    printf 'usage: %s [all|unit|e2e]\n' "$0" >&2
    exit 1
    ;;
esac
