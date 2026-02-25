# supermux

Directory-scoped tmux session manager + fzf TUI.

## Install

- tmux is required
- fzf is required for the interactive picker (`supermux` with no subcommand)

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
supermux                   # interactive picker (search includes pane processes)
supermux kill              # interactive kill
supermux detach            # if inside tmux: detach current client
supermux detach NAME       # detach clients attached to scoped session NAME
```

## Notes

- Scope mode: set `TMX_SCOPE_MODE=git` to scope sessions by git root instead of exact `pwd`.
- `Ctrl-s` is bound to detach in the snippet; if your terminal uses XON/XOFF flow control, run `stty -ixon`.
