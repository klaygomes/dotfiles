#!/usr/bin/env bash
# Drives the real menu through tmux with the fake gh. See docs/tmux-pr-menu.md#tests
# shellcheck enable=check-unassigned-uppercase,require-double-brackets,quote-safe-variables,deprecate-which

set -u

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || exit 1
readonly HERE
readonly SOCKET=tmux-pr-smoke
readonly SESSION=smoke
readonly TIMEOUT_TICKS=50
LOG=$(mktemp "${TMPDIR:-/tmp}/tmux-pr-smoke.XXXXXX") || exit 1
readonly LOG

failed=0

tm() {
  tmux -L "$SOCKET" -f /dev/null "$@"
}

screen() {
  tm capture-pane -p -t "$SESSION" 2>/dev/null
}

wait_for() {
  local text=$1 tick
  for ((tick = 0; tick < TIMEOUT_TICKS; tick++)); do
    [[ $(screen) == *"$text"* ]] && return 0
    sleep 0.2
  done
  return 1
}

wait_log() {
  local text=$1 tick
  for ((tick = 0; tick < TIMEOUT_TICKS; tick++)); do
    grep -qF -- "$text" "$LOG" && return 0
    sleep 0.2
  done
  return 1
}

wait_gone() {
  local tick
  for ((tick = 0; tick < TIMEOUT_TICKS; tick++)); do
    tm has-session -t "$SESSION" 2>/dev/null || return 0
    sleep 0.2
  done
  return 1
}

check() {
  local name=$1
  shift
  if "$@"; then
    printf 'ok   %s\n' "$name"
  else
    printf 'FAIL %s\n' "$name"
    printf '%s\n' '--- screen ---' "$(screen)" '--------------'
    failed=1
  fi
}

cleanup() {
  tm kill-server 2>/dev/null
  rm -f -- "$LOG"
}

command -v fzf >/dev/null || {
  printf 'smoke: fzf is required\n' >&2
  exit 1
}
trap cleanup EXIT
tm kill-server 2>/dev/null

tm new-session -d -s "$SESSION" -x 160 -y 30 \
  env PATH="$HERE/tmux-pr-fixtures/bin:$PATH" GH_LOG="$LOG" \
  XDG_CACHE_HOME="${TMPDIR:-/tmp}/tmux-pr-smoke-cache" PR_MENU_FAVORITES=/dev/null \
  "$HERE/tmux-pr-menu.sh"

check 'menu opens on the review-requested tab' wait_for 'Add sprocket support'
tm send-keys -t "$SESSION" o
check 'o opens the PR and keeps the menu' wait_for 'opened widgets#7'
tm send-keys -t "$SESSION" Enter
check 'enter opens the PR and keeps the menu' wait_log 'open https://github.com/acme/widgets/pull/7'
tm send-keys -t "$SESSION" O
check 'O pushes the files screen' wait_for 'my notes.md'
tm send-keys -t "$SESSION" Enter
check 'enter opens the selected file on GitHub' \
  wait_log 'open https://github.com/acme/widgets/pull/7/files#diff-'
tm send-keys -t "$SESSION" Escape
check 'esc pops back to the menu' wait_for 'Review requested'
tm send-keys -t "$SESSION" l
check 'l switches tab' wait_for 'No review (2)'
tm send-keys -t "$SESSION" / e x i t Enter
check 'typing exit closes the root screen' wait_gone

((failed)) && exit 1
printf 'smoke ok\n'
