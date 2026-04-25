#!/usr/bin/env bash
# Switch to an existing tmux session using fzf (§ s)

tmux list-sessions -F '#{session_name}' \
  | fzf --no-multi --no-info --height=100% \
      --preview 'tmux capture-pane -ep -t {}' \
      --preview-window=up:~7:border-bottom:follow \
      --bind 'esc:abort' \
  | xargs -r tmux switch-client -t
