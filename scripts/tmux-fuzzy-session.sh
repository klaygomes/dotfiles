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

if [[ -n "$selected" ]]; then
  if [[ -f "$selected" ]]; then
    session_dir=$(dirname "$selected")
  else
    session_dir="$selected"
  fi
  session_name=$(basename "$session_dir" | sed 's/^\.//' | tr '. ' '--')

  echo "selected:     $selected"      >> /tmp/tmux-fuzzy-debug.log
  echo "session_dir:  $session_dir"   >> /tmp/tmux-fuzzy-debug.log
  echo "session_name: $session_name"  >> /tmp/tmux-fuzzy-debug.log
  echo "parent_client: $TMUX_PARENT_CLIENT" >> /tmp/tmux-fuzzy-debug.log

  if ! tmux has-session -t "=$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$session_dir" 2>> /tmp/tmux-fuzzy-debug.log
  fi

  tmux switch-client -c "$TMUX_PARENT_CLIENT" -t "$session_name" 2>> /tmp/tmux-fuzzy-debug.log
  echo "switch exit: $?" >> /tmp/tmux-fuzzy-debug.log
fi
