#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd -P)"
SNIPPET="${ROOT}/config/tmux.conf.snippet"
SOCKET="smx-e2e-tabs-$$"
TMUX_SESSION="e2e-tabs"
PILOTTY_SESSION="e2e-tabs-$$"

have() { command -v "$1" >/dev/null 2>&1; }
die() { printf 'e2e: %s\n' "$*" >&2; exit 1; }

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"
  if [[ "$expected" == "$actual" ]]; then
    printf 'ok - %s\n' "$label"
    return 0
  fi

  printf 'not ok - %s\n' "$label"
  printf '  expected: %s\n' "$expected"
  printf '  actual:   %s\n' "$actual"
  exit 1
}

cleanup() {
  pilotty kill -s "$PILOTTY_SESSION" >/dev/null 2>&1 || true
  tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true
}

trap cleanup EXIT

have tmux || die "tmux not found"
have pilotty || die "pilotty not found"

tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true
pilotty spawn --name "$PILOTTY_SESSION" tmux -L "$SOCKET" -f "$SNIPPET" new-session -A -s "$TMUX_SESSION" >/dev/null

local_ready=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if tmux -L "$SOCKET" has-session -t "$TMUX_SESSION" >/dev/null 2>&1; then
    local_ready=1
    break
  fi
  sleep 0.1
done
[[ "$local_ready" == "1" ]] || die "tmux test session did not start"

keys="$(tmux -L "$SOCKET" list-keys -T root)"
[[ "$keys" == *" C-t                    new-window"* ]] || die "missing Ctrl-T bind"
[[ "$keys" == *" M-t                    new-window"* ]] || die "missing Alt-T bind"
[[ "$keys" == *" C-1                    select-window -t 0"* ]] || die "missing Ctrl-1 bind"
[[ "$keys" == *" M-1                    select-window -t 0"* ]] || die "missing Alt-1 bind"
[[ "$keys" == *" C-Left                 previous-window"* ]] || die "missing Ctrl-Left tab cycle bind"
[[ "$keys" == *" C-Right                next-window"* ]] || die "missing Ctrl-Right tab cycle bind"
[[ "$keys" == *" M-Left                 previous-window"* ]] || die "missing Alt-Left tab cycle bind"
[[ "$keys" == *" M-Right                next-window"* ]] || die "missing Alt-Right tab cycle bind"
[[ "$keys" == *" C-PPage                previous-window"* ]] || die "missing Ctrl-PageUp tab cycle bind"
[[ "$keys" == *" C-NPage                next-window"* ]] || die "missing Ctrl-PageDown tab cycle bind"
[[ "$keys" == *" M-PPage                previous-window"* ]] || die "missing Alt-PageUp tab cycle bind"
[[ "$keys" == *" M-NPage                next-window"* ]] || die "missing Alt-PageDown tab cycle bind"
[[ "$keys" == *" C-D                    split-window -v -c \"#{pane_current_path}\""* ]] || die "missing Ctrl-Shift-D bind"
[[ "$keys" == *" M-D                    split-window -v -c \"#{pane_current_path}\""* ]] || die "missing Alt-Shift-D bind"
[[ "$keys" == *" MouseUp3Status         display-menu"* ]] || die "missing right-click tab menu bind"
printf 'ok - keybindings registered\n'

pilotty key -s "$PILOTTY_SESSION" Ctrl+T >/dev/null
pilotty key -s "$PILOTTY_SESSION" Ctrl+T >/dev/null
assert_eq "2" "$(tmux -L "$SOCKET" display-message -p -t "$TMUX_SESSION" '#{window_index}')" "Ctrl-T creates and switches windows"

pilotty type -s "$PILOTTY_SESSION" $'\e[49;5u' >/dev/null
assert_eq "0" "$(tmux -L "$SOCKET" display-message -p -t "$TMUX_SESSION" '#{window_index}')" "Ctrl-1 sequence switches to first tab"

pilotty type -s "$PILOTTY_SESSION" $'\e[51;5u' >/dev/null
assert_eq "2" "$(tmux -L "$SOCKET" display-message -p -t "$TMUX_SESSION" '#{window_index}')" "Ctrl-3 sequence switches to third tab"

pilotty type -s "$PILOTTY_SESSION" $'\e1' >/dev/null
assert_eq "0" "$(tmux -L "$SOCKET" display-message -p -t "$TMUX_SESSION" '#{window_index}')" "Alt-1 sequence switches to first tab"

pilotty type -s "$PILOTTY_SESSION" $'\e3' >/dev/null
assert_eq "2" "$(tmux -L "$SOCKET" display-message -p -t "$TMUX_SESSION" '#{window_index}')" "Alt-3 sequence switches to third tab"

pilotty type -s "$PILOTTY_SESSION" $'\e1' >/dev/null
pane_before="$(tmux -L "$SOCKET" display-message -p -t "${TMUX_SESSION}:0" '#{window_panes}')"
pilotty type -s "$PILOTTY_SESSION" $'\eD' >/dev/null
pane_after="$(tmux -L "$SOCKET" display-message -p -t "${TMUX_SESSION}:0" '#{window_panes}')"
assert_eq "$((pane_before + 1))" "$pane_after" "Alt-Shift-D splits current tab vertically"

tmux -L "$SOCKET" set -g @tmx_bind_new_tab off
tmux -L "$SOCKET" set -g @tmx_bind_tab_select off
tmux -L "$SOCKET" set -g @tmx_bind_split_vertical off
tmux -L "$SOCKET" source-file "$SNIPPET"

keys="$(tmux -L "$SOCKET" list-keys -T root)"
[[ "$keys" == *" C-t                    new-window"* ]] && die "Ctrl-T should be disabled"
[[ "$keys" == *" M-t                    new-window"* ]] && die "Alt-T should be disabled"
[[ "$keys" == *" C-1                    select-window -t 0"* ]] && die "Ctrl-1 should be disabled"
[[ "$keys" == *" M-1                    select-window -t 0"* ]] && die "Alt-1 should be disabled"
[[ "$keys" == *" C-Left                 previous-window"* ]] && die "Ctrl-Left should be disabled"
[[ "$keys" == *" C-Right                next-window"* ]] && die "Ctrl-Right should be disabled"
[[ "$keys" == *" M-Left                 previous-window"* ]] && die "Alt-Left should be disabled"
[[ "$keys" == *" M-Right                next-window"* ]] && die "Alt-Right should be disabled"
[[ "$keys" == *" C-PPage                previous-window"* ]] && die "Ctrl-PageUp should be disabled"
[[ "$keys" == *" C-NPage                next-window"* ]] && die "Ctrl-PageDown should be disabled"
[[ "$keys" == *" M-PPage                previous-window"* ]] && die "Alt-PageUp should be disabled"
[[ "$keys" == *" M-NPage                next-window"* ]] && die "Alt-PageDown should be disabled"
[[ "$keys" == *" C-D                    split-window -v -c \"#{pane_current_path}\""* ]] && die "Ctrl-Shift-D should be disabled"
[[ "$keys" == *" M-D                    split-window -v -c \"#{pane_current_path}\""* ]] && die "Alt-Shift-D should be disabled"
printf 'ok - keybinding toggles disable tab and vertical split bindings\n'

printf 'all e2e checks passed\n'
