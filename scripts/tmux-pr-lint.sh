#!/usr/bin/env bash
# Shell lint for the repo, strict for tmux-pr-*. See docs/tmux-pr-menu.md#lint
# shellcheck enable=check-unassigned-uppercase,require-double-brackets,quote-safe-variables,deprecate-which

set -u

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P) || exit 1
readonly ROOT
readonly SELF=$ROOT/scripts/${BASH_SOURCE[0]##*/}
readonly SKIP_SHELLCHECK=(zsh/ gh-cp.sh tmux-fuzzy-session.sh tmux-task-menu.sh)
readonly SHFMT_FLAGS=(-i 2 -ci -bn)
readonly BASH4_PATTERNS=(
  '(^|[^[:alnum:]_])(mapfile|readarray|coproc)([^[:alnum:]_]|$)'
  '(declare|local|typeset)[[:space:]]+-[[:alpha:]]*[An]'
  '\$\{[[:alnum:]_]+(\[[^]]*\])?(,,?|\^\^?|@[QEPAaKkUuL])\}'
  ';;&|;&[[:space:]]*$'
  '\|&'
  '&>>'
  'wait[[:space:]]+-n'
  '\$\{?EPOCH(SECONDS|REALTIME)'
  '\[-[0-9]+\]'
)

failed=0

note() {
  printf '%s\n' "$*" >&2
}

fail() {
  note "FAIL: $*"
  failed=1
}

is_skipped() {
  local file=$1 skip
  for skip in "${SKIP_SHELLCHECK[@]}"; do
    [[ $file == "$skip"* || ${file##*/} == "$skip" ]] && return 0
  done
  return 1
}

list_shell_files() {
  git -C "$ROOT" ls-files --cached --others --exclude-standard -- '*.sh'
}

lint_shellcheck() {
  local file files=()
  while IFS= read -r file; do
    is_skipped "$file" || files+=("$file")
  done < <(list_shell_files)
  (cd -- "$ROOT" && shellcheck -x -- "${files[@]}") || fail "shellcheck"
}

lint_strict() {
  local file
  for file in "$ROOT"/scripts/tmux-pr-*.sh "$ROOT"/scripts/tmux-pr-*.bats "$ROOT"/scripts/tmux-pr-fixtures/bin/*; do
    [[ -e $file ]] || continue
    [[ $file == *.sh ]] || (cd -- "$ROOT" && shellcheck -x -- "${file#"$ROOT"/}") || fail "shellcheck ${file#"$ROOT"/}"
    shfmt "${SHFMT_FLAGS[@]}" -d -- "$file" || fail "shfmt ${file#"$ROOT"/}"
    [[ $file == *.bats ]] || /bin/bash -n -- "$file" || fail "/bin/bash -n ${file#"$ROOT"/}"
    lint_bash4 "$file"
  done
}

lint_bash4() {
  local file=$1 pattern hits
  [[ $file -ef $SELF ]] && return 0
  for pattern in "${BASH4_PATTERNS[@]}"; do
    hits=$(grep -nE -- "$pattern" "$file") || continue
    fail "bash 4+ syntax in ${file#"$ROOT"/} (macOS ships bash 3.2):"
    note "$hits"
  done
}

lint_shellcheck
lint_strict
((failed)) && exit 1
note "lint ok"
