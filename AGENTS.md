# AGENTS.md

This repository is a small Bash project: `supermux`, a directory-scoped tmux session manager with an OpenTUI picker.

## Repository layout

- `bin/supermux` - main CLI (Bash; installed entrypoint)
- `scripts/install.sh` - installs the CLI into `~/.local/bin/`
- `scripts/opentui-picker.ts` - OpenTUI picker/kill/detach UI
- `scripts/build-deb.sh` - builds Debian `.deb` packages
- `scripts/release.sh` - release automation (version bump + tag + brew formula sha)
- `config/tmux.conf.snippet` - optional tmux statusline + keybinds snippet
- `packaging/homebrew/supermux.rb` - Homebrew formula
- `package.json` - npm package metadata

## Prerequisites

- `bash` (keep compatible with macOS default Bash 3.2)
- `tmux` (required)
- `bun` (required for interactive commands: picker/kill/detach UI)
- Optional tooling used opportunistically:
  - `git` (for `TMX_SCOPE_MODE=git`)
  - `shasum` or `python3` (hashing fallback); `cksum` as last resort
  - `column` (pretty table output)
  - `pilotty` (for e2e tests)
  - `dpkg-deb` (for `.deb` packaging)

## Build / lint / test commands

There is no build step (scripts are run directly).

### Run locally

- Help: `./bin/supermux --help`
- Create/switch scoped session: `./bin/supermux new NAME`
- List scoped sessions: `./bin/supermux list`
- Interactive picker (requires `bun`): `./bin/supermux`
- Interactive kill (requires `bun`): `./bin/supermux kill`

### Install

- Install to `~/.local/bin`: `./scripts/install.sh`
- Apply tmux snippet to dedicated supermux server:
  - `tmux -L supermux source-file ~/.local/share/supermux/tmux.conf.snippet`

### Packaging

- npm tarball: `npm pack`
- Homebrew local install: `brew install --HEAD ./packaging/homebrew/supermux.rb`
- Debian package: `./scripts/build-deb.sh 0.2.0`
- Release automation: `./scripts/release.sh 0.3.0`

### Lint (ShellCheck)

- Lint everything: `shellcheck bin/supermux scripts/install.sh`
- Lint a single file: `shellcheck bin/supermux`
- Fast syntax-only check (no lint rules): `bash -n bin/supermux`

### Format (shfmt)

- Format everything: `shfmt -w -i 2 -ci bin/supermux scripts/install.sh`
- Format a single file: `shfmt -w -i 2 -ci bin/supermux`

### Tests

- Unit tests: `./test/run.sh unit`
- E2E tests (tmux + pilotty): `./test/run.sh e2e`
- Full suite: `./test/run.sh all`
- Quick smoke checks:
  - `./bin/supermux list --tsv` (should exit 0 even if no tmux server exists)
  - `./bin/supermux list` (human-readable; same behavior)

## CLI behavior and extension points

- Session scoping is driven by `TMX_SCOPE_DIR` + `TMX_SCOPE_MODE` (default: current `pwd`).
- Session names are sanitized via `sanitize_session_name`; tmux session IDs must remain valid.
- Session metadata is stored in tmux options: `@tmx_root` and `@tmx_name`.
- The `list`/picker pipeline relies on tab-separated rows; keep column order stable.

## Flags and environment variables

These are part of the user-facing interface; keep them stable.

- `TMX_TMUX_BIN` - override tmux binary (default: `tmux`)
- `TMX_TMUX_SOCKET` / `--socket NAME` - tmux socket name (default: `supermux`)
- `TMX_TMUX_SOCKET_PATH` / `--socket-path PATH` - tmux socket path override
- `TMX_SCOPE_DIR` / `--scope DIR` - override scope directory
- `TMX_SCOPE_MODE` / `--scope-mode pwd|git` - scope by exact dir or git root
- `TMX_QUERY` / `TMX_PROCESS_QUERY` / `--query STR` - prefilter picker entries
- `TMX_ALL` / `--all` - include sessions outside the current scope (list/picker/kill)

## Code style guidelines

### General

- Prefer clear code over comments; only add comments when the intent is genuinely non-obvious.
- Avoid introducing new runtime dependencies unless they materially improve UX.

### Bash compatibility (important)

- Target Bash 3.2+ (macOS default). Avoid Bash 4+ features:
  - No `mapfile`/`readarray`, no associative arrays, no `globstar`, no `declare -g`, etc.
- Keep `#!/usr/bin/env bash` and strict mode in executable scripts: `set -euo pipefail`.

### Imports / sourcing

- Prefer keeping logic inside `bin/supermux`.
- If you must split files, resolve paths from `BASH_SOURCE[0]` and keep ShellCheck happy.
- Do not rely on a caller's working directory when sourcing.

### Formatting

- Indentation: 2 spaces; no tabs.
- Prefer `printf` over `echo` (portable, predictable escaping).
- Use `<<'EOF'` (single-quoted heredocs) when you need literal blocks.

### Naming conventions

- Functions: `snake_case` (repo convention)
- Globals/config: `UPPER_SNAKE_CASE` (often derived from `TMX_*` env vars)
- Locals: `lower_snake_case` and always declared with `local`
- Keep user-visible identifiers consistent:
  - `TMX_*` env vars
  - tmux user options: `@tmx_*`

### “Types” and data handling

- Treat variables as strings unless you are in arithmetic context: `i=$((i + 1))`.
- Use `${var:-}` when reading potentially-unset variables (repo uses this pattern heavily).
- Prefer arrays for argument lists; avoid building command strings.

### Quoting and word splitting

- Quote expansions by default: `"$var"`, `"$@"`.
- Never use `for x in $(...)`; use `while IFS= read -r ...`.
- When parsing TSV output, always set `IFS=$'\t'` and use `read -r`.

### Error handling

- Use `die "message"` for user-facing fatal errors; it prints `supermux:` prefix and exits.
- Use `require_tmux`/`require_bun` for dependency checks.
- Use `|| true` only for expected failures you deliberately ignore (e.g., tmux server not running).
- Send interactive prompts to `/dev/tty` (see existing `kill` confirmation) to avoid breaking pipes.

### External commands and portability

- Prefer tmux format strings (`tmux ... -F`) over parsing human output.
- Avoid GNU-only flags; assume macOS/BSD userland.
- When adding new helpers, consider fallbacks like `short_hash` does.
- Keep `have()` as the one way to detect executables (`command -v ...`).

### Security / robustness

- Avoid `eval`.
- Treat user-provided strings as untrusted:
  - sanitize anything that becomes a tmux session name
  - quote every tmux argument
- Ensure the picker result protocol remains tab-separated and safely parsed with `IFS=$'\t' read -r`.

## Editing `config/tmux.conf.snippet`

- Keep it appendable and self-contained (no plugin-manager assumptions).
- Preserve existing keybinds unless there is a strong reason:
  - `C-d` split, `C-w` kill pane, `C-s` detach, `P` rename pane label
- If you change UX defaults, update `README.md` accordingly.

## Editor/AI instruction files

- Cursor rules: none found (no `.cursor/rules/` or `.cursorrules`).
- Copilot rules: none found (no `.github/copilot-instructions.md`).
