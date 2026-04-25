#!/usr/bin/env bash
# Open or create a tmux session (§ N).
# If the clipboard contains a GitHub URL, use it directly without prompting.

source ~/dotfiles/zsh/functions.sh

clipboard=$(pbpaste)

if [[ "$clipboard" =~ ^https://github\.com/ ]]; then
  _tmux_new_session "$clipboard"
else
  printf "Session name or GitHub URL: "
  read -r input
  [[ -n "$input" ]] && _tmux_new_session "$input"
fi
