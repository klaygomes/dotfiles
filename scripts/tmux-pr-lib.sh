# shellcheck shell=bash
# Screen runtime shared by the tmux-pr-* screens. See docs/tmux-pr-menu.md
# shellcheck enable=check-unassigned-uppercase,require-double-brackets,quote-safe-variables,deprecate-which
# shellcheck disable=SC2034

readonly PR_DIM=$'\033[2m'
readonly PR_RED=$'\033[31m'
readonly PR_ACCENT=$'\033[1;30;48;5;173m'
readonly PR_RESET=$'\033[0m'
readonly PR_BASE_KEYS='j,k,g,G,J,K,q,/'

PR_HOME=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P) || exit 1
PR_SELF=$(cd -- "$(dirname -- "$0")" && pwd -P)/${0##*/}
printf -v PR_RUN '%q' "$PR_SELF"
readonly PR_HOME PR_SELF PR_RUN

screen_footer=''
screen_binds=()
screen_fzf_opts=()

pr_row_error() {
  printf 'x\t%s%s%s\n' "$PR_RED" "$1" "$PR_RESET"
}

pr_row_empty() {
  printf 'x\t%s(%s)%s\n' "$PR_DIM" "${1:-nothing here}" "$PR_RESET"
}

pr_push() {
  local cmd
  printf -v cmd '%q' "$PR_HOME/tmux-pr-$1.sh"
  printf 'execute(%s {1})' "$cmd"
}

pr_key() {
  local owner repo number
  IFS=/ read -r _ _ _ owner repo _ number _ <<<"$1"
  printf '%s_%s_%s' "$owner" "$repo" "$number"
}

pr_ref() {
  local repo number
  IFS=/ read -r _ _ _ _ repo _ number _ <<<"$1"
  printf '%s#%s' "$repo" "$number"
}

pr_dir() {
  printf '%s/pr/%s' "$PR_STATE" "$(pr_key "$1")"
}

pr_forget() {
  rm -rf -- "$(pr_dir "$1")"
}

pr_cached() {
  local file=$1 tmp
  shift
  if [[ ! -s $file ]]; then
    mkdir -p -- "${file%/*}" || return 1
    tmp=$(mktemp "$file.XXXXXX") || return 1
    if ! "$@" >"$tmp"; then
      rm -f -- "$tmp"
      return 1
    fi
    mv -f -- "$tmp" "$file"
  fi
  cat -- "$file"
}

pr_vim_keys() {
  local keys=$PR_BASE_KEYS bind key
  local -a parts
  for bind in ${screen_binds[@]+"${screen_binds[@]}"}; do
    IFS=, read -r -a parts <<<"${bind%%:*}"
    for key in "${parts[@]}"; do
      [[ ${#key} -eq 1 ]] && keys+=",$key"
    done
  done
  printf '%s' "$keys"
}

pr_init_modes() {
  PR_VIM_KEYS=$(pr_vim_keys)
  PR_NORMAL="hide-input+rebind($PR_VIM_KEYS)"
  PR_FILTER="show-input+unbind($PR_VIM_KEYS)"
  PR_RESTORE="enable-search+clear-query+change-prompt(  / )+$PR_NORMAL+change-footer-label()"
}

pr_init_state() {
  [[ -n ${PR_STATE-} && -d $PR_STATE ]] && return 0
  PR_STATE=$(mktemp -d "${TMPDIR:-/tmp}/tmux-pr.XXXXXX") || exit 1
  export PR_STATE
  trap 'rm -rf -- "$PR_STATE"' EXIT
  trap 'exit 1' HUP INT TERM
}

cmd_list() {
  screen_list "$@"
}

cmd_preview() {
  [[ -z ${1-} || $1 == x ]] && return 0
  screen_preview "$1"
}

cmd_header() {
  declare -F screen_header >/dev/null && screen_header
}

cmd_key_enter() {
  local key=${1-} query=${FZF_QUERY-} state=${FZF_INPUT_STATE-}
  if [[ $query == exit ]]; then
    printf 'abort'
  elif declare -F screen_enter_hook >/dev/null && screen_enter_hook "$key"; then
    return 0
  elif [[ $state != enabled ]]; then
    [[ $key == x ]] || screen_on_enter "$key"
  elif [[ -n $query ]]; then
    printf '%s+change-footer-label( filter: %s )' "$PR_NORMAL" "$query"
  else
    printf '%s+change-footer-label()' "$PR_NORMAL"
  fi
}

cmd_key_esc() {
  if declare -F screen_esc_hook >/dev/null && screen_esc_hook; then
    return 0
  elif [[ ${FZF_INPUT_STATE-} != enabled && -z ${FZF_QUERY-} ]]; then
    printf 'abort'
  else
    printf '%s' "$PR_RESTORE"
  fi
}

screen_on_enter() {
  printf 'accept'
}

pr_run_fzf() {
  local header footer
  header=$(cmd_header)
  footer="${PR_DIM}j/k move  J/K ^d/^u scroll preview  ${screen_footer:+$screen_footer  }/ filter  esc back  q quit${PR_RESET}"
  local -a binds=(
    "start:reload($PR_RUN list)"
    "load:transform-header($PR_RUN header)"
    'j:down,k:up,g:first,G:last'
    'J:preview-down,K:preview-up'
    'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up'
    'q:abort'
    "/:$PR_FILTER"
    "enter:transform($PR_RUN key-enter {1})"
    "esc:transform($PR_RUN key-esc)"
    ${screen_binds[@]+"${screen_binds[@]}"}
  )
  local -a args=()
  local bind
  for bind in "${binds[@]}"; do
    args+=(--bind "$bind")
  done
  fzf --ansi --no-multi --layout=reverse --height=100% --no-input --listen \
    --delimiter=$'\t' --with-nth=2.. \
    --header-first --header "$header" --header-border=bottom \
    --footer "$footer" --footer-border=top \
    --prompt='  / ' --pointer='▸' --gutter=' ' --info=inline-right \
    --preview "$PR_RUN preview {1}" --preview-window=right:55%:border-left \
    "${args[@]}" ${screen_fzf_opts[@]+"${screen_fzf_opts[@]}"} </dev/null
}

pr_main() {
  local cmd=${1-} selected
  pr_init_modes
  if [[ -n $cmd ]] && declare -F "cmd_${cmd//-/_}" >/dev/null; then
    shift
    "cmd_${cmd//-/_}" "$@"
    exit
  fi
  [[ $cmd == x ]] && exit 0
  if declare -F screen_init >/dev/null; then
    screen_init "$@" || exit
  fi
  pr_init_state
  if declare -F screen_start >/dev/null; then
    screen_start || exit
  fi
  selected=$(pr_run_fzf) || exit 0
  if declare -F screen_on_accept >/dev/null; then
    screen_on_accept "${selected%%$'\t'*}"
  fi
}
