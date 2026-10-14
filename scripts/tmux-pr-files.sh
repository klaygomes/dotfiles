#!/usr/bin/env bash
# Files-changed screen for a PR, pushed from the PR menu with O. See docs/tmux-pr-menu.md
# shellcheck enable=check-unassigned-uppercase,require-double-brackets,quote-safe-variables,deprecate-which

set -u
# shellcheck source-path=SCRIPTDIR source=tmux-pr-lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/tmux-pr-lib.sh" || exit 1

URL=${PR_FILES_URL-}

screen_footer='⏎/o open file on GitHub  r refresh'
screen_binds=(
  "o:execute-silent($PR_RUN open {1})"
  "r,ctrl-r:transform($PR_RUN refresh)"
)
screen_fzf_opts=(--preview-window=right:70%:border-left)

cmd_fetch_title() {
  gh pr view "$URL" --json title --jq .title
}

cmd_fetch_files() {
  gh pr view "$URL" --json files --jq '.files[] | [
      .path,
      ((.path | split("/") | last)
        + "  \u001b[32m+" + (.additions | tostring) + "\u001b[0m"
        + " \u001b[31m-" + (.deletions | tostring) + "\u001b[0m"
        + "  \u001b[2m" + (.path | sub("[^/]*$"; "")) + "\u001b[0m")
    ] | @tsv'
}

cmd_fetch_patch() {
  gh pr diff "$URL" --color=never
}

screen_init() {
  if [[ ${1-} != https://* ]]; then
    printf 'usage: %s <pr-url>\n' "${0##*/}" >&2
    return 2
  fi
  export PR_FILES_URL=$1
  URL=$1
}

screen_header() {
  local title
  title=$(pr_cached "$(pr_dir "$URL")/title" fetch-title 2>/dev/null)
  printf '%s %s %s  %s' "$PR_ACCENT" "$(pr_ref "$URL")" "$PR_RESET" "$title"
}

screen_list() {
  local out
  if ! out=$(pr_cached "$(pr_dir "$URL")/files" fetch-files 2>&1); then
    pr_row_error "gh failed: ${out%%$'\n'*}"
  elif [[ -z $out ]]; then
    pr_row_empty 'no files'
  else
    printf '%s\n' "$out"
  fi
}

screen_preview() {
  local patch
  patch=$(pr_cached_preview "$(pr_dir "$URL")/patch" fetch-patch 2>&1) || {
    printf 'gh pr diff failed: %s\n' "${patch%%$'\n'*}"
    return 0
  }
  awk -v want=" b/$1" '
    /^diff --git / { show = substr($0, length($0) - length(want) + 1) == want }
    show
  ' <<<"$patch" \
    | delta --paging=never --width="${FZF_PREVIEW_COLUMNS:-80}" \
      --file-style=omit --hunk-header-style=line-number
}

screen_on_enter() {
  printf 'execute-silent(%s open {1})' "$PR_RUN"
}

cmd_refresh() {
  local files
  files=$(pr_dir "$URL")/files
  [[ -f $files ]] && pr_refresh_cooling "$files" && return 0
  pr_forget "$URL"
  printf 'reload(%s list)+refresh-preview+transform-header(%s header)' "$PR_RUN" "$PR_RUN"
}

cmd_open() {
  local hash
  [[ -z ${1-} || $1 == x ]] && return 0
  read -r hash _ < <(printf '%s' "$1" | shasum -a 256)
  open "$URL/files#diff-$hash"
}

pr_main "$@"
