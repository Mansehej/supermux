# tmx

Directory-scoped tmux session manager + fzf TUI.

## Install

- tmux is required
- fzf is required for the interactive picker (`tmx` with no subcommand)

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
tmx new hello-world   # create/switch session scoped to current dir
tmx list              # list sessions scoped to current dir
tmx                   # interactive picker (search includes pane processes)
tmx kill              # interactive kill
tmx detach            # if inside tmux: detach current client
tmx detach NAME       # detach clients attached to scoped session NAME
```

## Notes

- Scope mode: set `TMX_SCOPE_MODE=git` to scope sessions by git root instead of exact `pwd`.
- `Ctrl-s` is bound to detach in the snippet; if your terminal uses XON/XOFF flow control, run `stty -ixon`.
