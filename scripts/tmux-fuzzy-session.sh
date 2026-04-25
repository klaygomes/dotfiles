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
  fd . / --type d --hidden "${exclude_flags[@]}" --max-depth 7 2>/dev/null \
    | fzf --no-multi --height=100% \
        --preview 'ls -la {}' \
        --preview-window=right:50%:border-left \
        --bind 'esc:abort'
)

if [[ -n "$selected" ]]; then
  if [[ -f "$selected" ]]; then
    session_dir=$(dirname "$selected")
  else
    session_dir="$selected"
  fi
  session_name=$(basename "$session_dir" | sed 's/^\.//' | tr '. ' '--')

  fuzzy_win=$(tmux display-message -p '#{window_id}')

  if ! tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$session_dir"
  fi

  tmux switch-client -t "$session_name"
  tmux kill-window -t "$fuzzy_win"
fi
