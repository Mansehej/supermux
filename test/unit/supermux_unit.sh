#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd -P)"
source "${ROOT}/bin/supermux"

TESTS_RUN=0
TESTS_FAILED=0

assert_eq() {
  local expected="$1"
  local actual="$2"
  local name="$3"

  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$expected" == "$actual" ]]; then
    printf 'ok - %s\n' "$name"
    return 0
  fi

  TESTS_FAILED=$((TESTS_FAILED + 1))
  printf 'not ok - %s\n' "$name"
  printf '  expected: %s\n' "$expected"
  printf '  actual:   %s\n' "$actual"
}

sanitize_tests() {
  assert_eq "hello-world" "$(sanitize_session_name "hello world")" "sanitize replaces spaces"
  assert_eq "abc_xyz-123" "$(sanitize_session_name "abc_xyz-123")" "sanitize keeps safe chars"
  assert_eq "session" "$(sanitize_session_name "!!!")" "sanitize falls back to session"
  assert_eq "trailing" "$(sanitize_session_name "--trailing--")" "sanitize trims leading trailing dashes"
}

short_path_tests() {
  local old_home="${HOME:-}"
  HOME="/Users/tester"

  assert_eq "~" "$(short_path "/Users/tester")" "short_path shortens home"
  assert_eq "~/work/supermux" "$(short_path "/Users/tester/work/supermux")" "short_path keeps short home path"
  assert_eq ".../deeply-nested/super-long-directory-name-with-extra-chars" "$(short_path "/very/long/path/with/many/segments/and/more/parts/deeply-nested/super-long-directory-name-with-extra-chars")" "short_path truncates long path"

  HOME="$old_home"
}

tmux_cmd_socket_tests() {
  local stub out old_tmux_bin old_socket_name old_socket_path
  stub="$(mktemp "${TMPDIR:-/tmp}/supermux-tmux-stub.XXXXXX")"
  out="$(mktemp "${TMPDIR:-/tmp}/supermux-tmux-out.XXXXXX")"

  cat >"$stub" <<'TMUX_STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >"${TMUX_STUB_OUT}"
TMUX_STUB
  chmod +x "$stub"

  old_tmux_bin="$TMUX_BIN"
  old_socket_name="$TMUX_SOCKET_NAME"
  old_socket_path="$TMUX_SOCKET_PATH"

  TMUX_BIN="$stub"

  TMUX_SOCKET_PATH="/tmp/supermux.sock"
  TMUX_SOCKET_NAME="ignored"
  TMUX_STUB_OUT="$out" tmux_cmd list-sessions
  assert_eq "-S /tmp/supermux.sock list-sessions" "$(cat "$out")" "tmux_cmd prefers socket path"

  TMUX_SOCKET_PATH=""
  TMUX_SOCKET_NAME="supermux-test"
  TMUX_STUB_OUT="$out" tmux_cmd list-sessions
  assert_eq "-L supermux-test list-sessions" "$(cat "$out")" "tmux_cmd uses socket name"

  TMUX_SOCKET_PATH=""
  TMUX_SOCKET_NAME=""
  TMUX_STUB_OUT="$out" tmux_cmd list-sessions
  assert_eq "list-sessions" "$(cat "$out")" "tmux_cmd uses default tmux when no socket"

  TMUX_BIN="$old_tmux_bin"
  TMUX_SOCKET_NAME="$old_socket_name"
  TMUX_SOCKET_PATH="$old_socket_path"
  rm -f "$stub" "$out"
}

sanitize_tests
short_path_tests
tmux_cmd_socket_tests

if [[ "$TESTS_FAILED" -gt 0 ]]; then
  printf '\n%d/%d tests failed\n' "$TESTS_FAILED" "$TESTS_RUN"
  exit 1
fi

printf '\nall %d tests passed\n' "$TESTS_RUN"
