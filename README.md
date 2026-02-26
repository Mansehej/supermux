# supermux

Directory-scoped tmux session manager + OpenTUI picker (sessions + windows).

## Install

- tmux is required
- bun is required for interactive commands (`supermux`, `supermux kill`, `supermux detach` outside tmux)
- supermux uses a dedicated tmux socket (`supermux`) by default

```sh
./scripts/install.sh
```

Apply snippet styling to the dedicated supermux server:

```sh
tmux -L supermux source-file ./config/tmux.conf.snippet
```

If you want the same styling and keybinds on your regular tmux server too, append the snippet to `~/.tmux.conf` and reload.

## Usage

```sh
supermux new hello-world   # create/switch session scoped to current dir
supermux list              # list sessions scoped to current dir
supermux                   # interactive picker (OpenTUI; sessions + windows, Ctrl-N to create)
supermux kill              # interactive kill (OpenTUI)
supermux detach            # if inside tmux: detach current client
supermux detach NAME       # detach clients attached to scoped session NAME
```

## Testing

```sh
./test/run.sh unit   # unit tests (Bash helpers)
./test/run.sh e2e    # end-to-end tab keybind test (tmux + pilotty)
./test/run.sh all    # run everything
```

## Packaging

```sh
npm pack                          # npm tarball
brew install --HEAD ./packaging/homebrew/supermux.rb
./scripts/build-deb.sh 0.2.0      # Debian package to dist/
./scripts/release.sh 0.3.0         # bump version, tag, and update Homebrew sha
```

See `packaging/README.md` for publish/distribution notes.

## Notes

- Scope mode: set `TMX_SCOPE_MODE=git` to scope sessions by git root instead of exact `pwd`.
- Socket selection: use `--socket NAME` / `TMX_TMUX_SOCKET` (or `--socket-path PATH` / `TMX_TMUX_SOCKET_PATH`).
- Opt out of the dedicated server: set `TMX_TMUX_SOCKET=` to use your default tmux server.
- Split keybinds: `Ctrl-D` splits right; `Ctrl-Shift-D` (or `Alt/Option-Shift-D`) splits down.
- tmux snippet keybind settings: `@tmx_bind_split`, `@tmx_bind_split_vertical`, `@tmx_bind_kill_pane`, `@tmx_bind_detach`, `@tmx_bind_rename_pane` (`on`/`off`).
- Tab-like window controls in tmux snippet: `Ctrl-T` (or `Alt/Option-T`) creates/switches to a new window; `Ctrl-1`..`Ctrl-9` (or `Alt/Option-1`..`Alt/Option-9`) jump to windows 1..9 (plus `Ctrl/Alt-0` for 10).
- Tab keybind settings: `@tmx_bind_new_tab`, `@tmx_bind_tab_select` (`on`/`off`).
- For macOS terminals, Option usually needs to be configured as Meta/Alt for `Alt/Option-*` bindings.
- Example toggle: `tmux set -g @tmx_bind_split off; tmux source-file ~/.tmux.conf`
- If `Ctrl-s` detach is enabled and your terminal uses XON/XOFF flow control, run `stty -ixon`.
