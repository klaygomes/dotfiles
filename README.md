```text
        d8888b.  .d88b.  d888888b d88888b d888888b db      d88888b .d8888.
        88  `8D .8P  Y8. `~~88~~' 88'       `88'   88      88'     88'  YP
        88   88 88    88    88    88ooo      88    88      88ooooo `8bo.
        88   88 88    88    88    88~~~      88    88      88~~~~~   `Y8b.
        88  .8D `8b  d8'    88    88        .88.   88booo. 88.     db   8D
        Y8888D'  `Y88P'     YP    YP      Y888888P Y88888P Y88888P `8888Y'
```

[![ShellCheck](https://github.com/klaygomes/dotfiles/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/klaygomes/dotfiles/actions/workflows/shellcheck.yml)

These are Mac only configuration files. If, for some crazy reason, you want to use have it in
mind.

## How to use

Install Xcode Command Line Tools:

```bash
xcode-select --install
```

Clone this repository by typing:
```bash
git clone git@github.com:klaygomes/dotfiles.git ~/dotfiles && cd $_
```

If you want to configure everything just run:

```bash
make all
```

You may also configure components individually:

```bash
make [ nvim | git | brew | zsh | node | tmux | ghostty | ranger | bat ]
```
> You can type more than one item at same time `make nvim git` for example

You may also force a full update whenever you want by typing:

```bash
make all -B
```

If you need help type:

```bash
make help
```

```text
+-----------------------------------------------------------------------------+
|              This Makefile should work in most shell environments.          |
|             But it was only tested on Mac running with Apple sillicon.      |
+--------------------+--------------------------------------------------------+
| commands:          | description:                                           |
+--------------------+--------------------------------------------------------+
| vim                | Install neovim configuration                           |
| ghostty            | Install ghostty configuration                         |
| zsh                | Configure zsh default alias, functions and etc.        |
| mac                | Configure mac settings                                 |
| brew               | Install brew packages                                  |
| git                | Install git configuration                              |
| node               | Install nvm, node lts and global packages              |
| tmux               | Install tmux configuration                             |
| ranger             | Install ranger configuration                           |
| bat                | Install bat configuration                              |
| help               | Show this help                                         |
+--------------------+--------------------------------------------------------+
```

## Shell commands

| Command | Description |
|---------|-------------|
| `mp` | Copy a structured meeting notes prompt to clipboard |
| `sm` | Save clipboard content as a dated Markdown note in `~/personal/meetings/`. Date is extracted from content; falls back to today |
| `export_notes [folder]` | Export Apple Notes to `~/.notes_staging/` as plain text. Omit folder to export all |

### Meeting notes workflow

```bash
# 1. Export notes from Apple Notes
export_notes "Meetings"

# 2. Migrate staged notes to ~/personal/meetings/
python3 ~/dotfiles/scripts/migrate_notes.py

# 3. Or save clipboard directly as a meeting note
sm
```

## tmux bindings

Prefix key: `§`

| Binding | Description |
|---------|-------------|
| `§ a` | Fuzzy search files and directories from `/`; open or switch to a session for the selection |
| `§ N` | New session by name or GitHub URL. If clipboard contains a GitHub URL, uses it automatically |
| `§ s` | Switch between existing sessions (fzf) |
| `§ g` | Open lazygit in a popup |
| `§ e` | Open ranger file browser in a popup |
| `§ \|` | Split pane horizontally |
| `§ -` | Split pane vertically |
| `§ h/j/k/l` | Move between panes |
| `§ z` | Zoom/unzoom current pane |
| `§ X` | Kill current session and switch to previous |
| `§ r` | Reload tmux config |

## How it works

If you want to understand how I'm managing my dotfiles, I wrote a [complete article
teach](https://www.estacouveflor.com/dotfiles-configuration/) what each line of my Makefile does.

## License

DO WHAT THE F**K YOU WANT TO PUBLIC LICENSE, Version 2, December 2004

[READ MORE](/blob/master/LICENSE)
