#!/usr/bin/env zsh
# Fuzzy-search files and directories from / using fzf.
# On selection, opens or switches to a tmux session for that path.

source ~/dotfiles/zsh/functions.sh

EXCLUDES=(
  .git
  node_modules
  Library
  Applications
  .Trash
  System
  private
  dev
  Volumes
  proc
  bin
  sbin
  .npm
  .nvm
  .cache
  Caches
)

exclude_flags=()
for dir in "${EXCLUDES[@]}"; do
  exclude_flags+=(--exclude "$dir")
done

selected=$(
  fd . / --hidden "${exclude_flags[@]}" --max-depth 7 2>/dev/null \
    | fzf --no-multi --height=100% \
        --preview 'if [ -d {} ]; then ls -la {}; else bat --color=always --style=numbers --line-range :50 {}; fi' \
        --preview-window=right:50%:border-left \
        --bind 'esc:abort'
)

[[ -n "$selected" ]] && _tmux_open_local "$selected"
