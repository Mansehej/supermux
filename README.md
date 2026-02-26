# supermux

Directory-scoped tmux session manager + OpenTUI picker (sessions + windows).

## Install

- tmux is required
- bun is required for interactive commands (`supermux`, `supermux kill`, `supermux detach` outside tmux)

```sh
./scripts/install.sh
```

Then append the snippet to your tmux config and reload tmux:

```sh
cat ./config/tmux.conf.snippet >> ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

## Usage

```sh
supermux new hello-world   # create/switch session scoped to current dir
supermux list              # list sessions scoped to current dir
supermux                   # interactive picker (OpenTUI; sessions + windows, Ctrl-N to create)
supermux kill              # interactive kill (OpenTUI)
supermux detach            # if inside tmux: detach current client
supermux detach NAME       # detach clients attached to scoped session NAME
```

## Notes

- Scope mode: set `TMX_SCOPE_MODE=git` to scope sessions by git root instead of exact `pwd`.
- tmux snippet keybind settings: `@tmx_bind_split`, `@tmx_bind_kill_pane`, `@tmx_bind_detach`, `@tmx_bind_rename_pane` (`on`/`off`).
- Example toggle: `tmux set -g @tmx_bind_split off; tmux source-file ~/.tmux.conf`
- If `Ctrl-s` detach is enabled and your terminal uses XON/XOFF flow control, run `stty -ixon`.
