#!/usr/bin/env bash
# Called by tmux hooks to update the @git_branch variable immediately.
# Unlike #() in the status bar, user variables are not cached by tmux.
branch=$(git -C "$1" branch --show-current 2>/dev/null)
# Truncate branch name to 27 chars, using '...' when longer
if [ -n "$branch" ]; then
	if [ ${#branch} -gt 27 ]; then
		branch="${branch:0:27}..."
	fi
fi
tmux set -g @git_branch "$branch"
tmux refresh-client -S
