#!/usr/bin/env bash
# Interactive GitHub PR menu (§ g). See docs/tmux-pr-menu.md

set -u

DIR="${PR_MENU_DIR:-}"
MEMBERS="${XDG_CACHE_HOME:-$HOME/.cache}/tmux-pr-menu/members.tsv"
GH_WEB="https://github.com/pulls"
ACCENT=$'\033[1;30;48;5;173m'
DIM=$'\033[2m'
RESET=$'\033[0m'

TAB_NAMES=("Review requested" "No review" "Approved" "By author")
AUTHOR_TAB=3
TAB_QUERIES=(
  "review-requested=@me"
  "author=@me review=none"
  "author=@me review=approved"
  ""
)
TAB_WEB=(
  "reviews?q=is%3Apr+review-requested%3A%40me+state%3Aopen+archived%3Afalse+sort%3Aupdated-desc+-author%3Aapp%2Fdependabot"
  "search?q=is%3Apr+author%3A%40me+state%3Aopen+archived%3Afalse+review%3Anone+sort%3Aupdated-desc"
  "search?q=is%3Apr+author%3A%40me+state%3Aopen+archived%3Afalse+review%3Aapproved+sort%3Aupdated-desc"
  ""
)

current_tab() { cat "$DIR/tab" 2>/dev/null || echo 0; }

current_author() { cat "$DIR/author" 2>/dev/null; }

tab_name() {
  local author
  author=$(current_author)
  if [ "$1" -eq "$AUTHOR_TAB" ] && [ -n "$author" ]; then
    echo "@$author"
  else
    echo "${TAB_NAMES[$1]}"
  fi
}

tab_query() {
  if [ "$1" -eq "$AUTHOR_TAB" ]; then
    echo "author=$(current_author)"
  else
    echo "${TAB_QUERIES[$1]}"
  fi
}

tab_web() {
  if [ "$1" -eq "$AUTHOR_TAB" ]; then
    echo "search?q=is%3Apr+author%3A$(current_author)+state%3Aopen+archived%3Afalse+sort%3Aupdated-desc"
  else
    echo "${TAB_WEB[$1]}"
  fi
}

cmd_step() {
  local n=${#TAB_NAMES[@]}
  echo $(( ($(current_tab) + $1 + n) % n )) > "$DIR/tab"
}

tab_count() {
  local file="$DIR/list.$1"
  [ -f "$file" ] || { echo "…"; return; }
  grep -vc $'^x\t' "$file"
}

cmd_header() {
  local active i label out="${DIM}◀${RESET}  "
  active=$(current_tab)
  for i in "${!TAB_NAMES[@]}"; do
    label=" $(tab_name "$i") ($(tab_count "$i")) "
    if [ "$i" -eq "$active" ]; then
      out+="${ACCENT}${label}${RESET}"
    else
      out+="${DIM}${label}${RESET}"
    fi
    [ "$i" -lt $(( ${#TAB_NAMES[@]} - 1 )) ] && out+="${DIM}│${RESET}"
  done
  printf '%s  %s▶%s' "$out" "$DIM" "$RESET"
}

fetch_tab() {
  local i=$1 kv out flags=() extra=()
  for kv in $(tab_query "$i"); do flags+=("--${kv}"); done
  [ "$i" -eq 0 ] && extra=(-- -author:app/dependabot)

  if [ "$i" -eq "$AUTHOR_TAB" ] && [ -z "$(current_author)" ]; then
    out=$(printf 'x\t%s(press a to pick an author)%s' "$DIM" "$RESET")
  elif ! out=$(gh search prs "${flags[@]}" --state=open --archived=false --sort=updated --limit=100 \
    --json url,repository,number,title,author,isDraft \
    --jq 'def ref: .repository.name + "#" + (.number|tostring);
      (map(ref | length) | max) as $width | .[] | ref as $ref | [
      .url,
      ("\u001b[38;5;173m" + $ref + "\u001b[0m" + (" " * ($width - ($ref|length) + 2))
        + (if .isDraft then "\u001b[2m[draft]\u001b[0m " else "" end)
        + .title + "  \u001b[2m@" + .author.login + "\u001b[0m")
    ] | @tsv' ${extra[@]+"${extra[@]}"} 2>&1); then
    out=$(printf 'x\t\033[31mgh failed: %s\033[0m' "$(printf '%s' "${out:-unknown error}" | head -1)")
  elif [ -z "$out" ]; then
    out=$(printf 'x\t%s(nothing here)%s' "$DIM" "$RESET")
  fi
  printf '%s\n' "$out" > "$DIR/list.$i.tmp"
  mv "$DIR/list.$i.tmp" "$DIR/list.$i"
}

cmd_list() {
  local i
  i=$(current_tab)
  [ "${1:-}" = "force" ] && rm -f "$DIR/list.$i"
  [ -f "$DIR/list.$i" ] || fetch_tab "$i"
  cat "$DIR/list.$i"
}

list_orgs() {
  if [ -n "${PR_MENU_ORGS:-}" ]; then
    printf '%s\n' $PR_MENU_ORGS
  else
    gh api graphql -f query='{ viewer { organizations(first: 100) { nodes { login } } } }' \
      --jq '.data.viewer.organizations.nodes[].login'
  fi
}

fetch_org_members() {
  gh api graphql --paginate -f org="$1" -f query='
    query($org: String!, $endCursor: String) {
      organization(login: $org) {
        membersWithRole(first: 100, after: $endCursor) {
          pageInfo { hasNextPage endCursor }
          nodes { login name }
        }
      }
    }' --jq '.data.organization.membersWithRole.nodes[]
      | [(.name // .login), .login, ((if .name then .name + "  " else "" end) + "\u001b[2m@" + .login + "\u001b[0m")]
      | @tsv'
}

fetch_members() {
  local org
  [ -n "$(find "$MEMBERS" -mtime -1 2>/dev/null)" ] && return
  mkdir -p "$(dirname "$MEMBERS")"
  for org in $(list_orgs 2>/dev/null); do
    fetch_org_members "$org" 2>/dev/null
  done | sort -u -t $'\t' -k2,2 | sort -f | cut -f2- > "$MEMBERS.tmp"
  [ -s "$MEMBERS.tmp" ] && mv "$MEMBERS.tmp" "$MEMBERS"
  rm -f "$MEMBERS.tmp"
}

cmd_members() {
  fetch_members
  cat "$MEMBERS" 2>/dev/null
}

cmd_prefetch() {
  local i
  fetch_members &
  for i in "${!TAB_NAMES[@]}"; do
    [ "$i" -eq 0 ] || [ "$i" -eq "$AUTHOR_TAB" ] && continue
    fetch_tab "$i" &
  done
  wait
  curl -s --noproxy '*' -XPOST "localhost:${FZF_PORT}" -d "transform-header($SELF header)" >/dev/null
}

read -r -d '' PREVIEW_JQ <<'JQ'
def bucket: (.conclusion // .state // "") as $c
  | if ($c | IN("SUCCESS", "NEUTRAL", "SKIPPED")) then "pass"
    elif ($c | IN("FAILURE", "ERROR", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE")) then "fail"
    else "pending" end;
def count($b): [.statusCheckRollup[] | select(bucket == $b)] | length;
def review: {
    "APPROVED": "✅ Approved",
    "CHANGES_REQUESTED": "🔴 Changes requested",
    "REVIEW_REQUIRED": "⏳ Review required"
  }[.reviewDecision // ""] // "none";
"# \(.title)\n",
"`\(.url | split("/")[3:5] | join("/"))#\(.number)` · @\(.author.login) · `\(.headRefName)` → `\(.baseRefName)`\n",
"- **State:** \(.state | ascii_downcase)\(if .isDraft then " (draft)" else "" end)",
"- **Review:** \(review)",
"- **Checks:** ✓ \(count("pass"))  ✗ \(count("fail"))  ● \(count("pending"))",
"- **Diff:** +\(.additions) −\(.deletions) in \(.changedFiles) files",
(if (.reviewRequests | length) > 0 then "- **Waiting on:** \([.reviewRequests[] | .login // .name] | join(", "))" else empty end),
(if (.labels | length) > 0 then "- **Labels:** \([.labels[].name] | join(", "))" else empty end),
"\n---\n",
(if (.body | length) > 0 then .body else "_No description._" end)
JQ

cmd_preview() {
  [ "$1" = "x" ] || [ -f "$DIR/author-mode" ] && exit 0
  local width=$(( ${FZF_PREVIEW_COLUMNS:-80} - 2 ))
  local cache="$DIR/preview.${width}.$(printf '%s' "$1" | tr -c 'a-zA-Z0-9' '_')"
  if [ ! -f "$cache" ]; then
    gh pr view "$1" --json title,url,number,author,headRefName,baseRefName,state,isDraft,reviewDecision,statusCheckRollup,additions,deletions,changedFiles,reviewRequests,labels,body \
      --jq "$PREVIEW_JQ" 2>&1 | CLICOLOR_FORCE=1 glow -s dark -w "$width" - > "$cache.tmp" \
      && mv "$cache.tmp" "$cache"
  fi
  cat "$cache" 2>/dev/null || cat "$cache.tmp"
}

VIM_KEYS="j,k,h,l,g,G,J,K,o,O,r,q,a,p,/"
NORMAL="hide-input+rebind($VIM_KEYS)"
RESTORE_INPUT="enable-search+clear-query+change-prompt(  / )+${NORMAL}+change-footer-label()"

cmd_commit_author() {
  local login=$1
  [[ "$login" =~ ^[A-Za-z0-9-]+$ ]] || login=${FZF_QUERY#@}
  rm -f "$DIR/author-mode"
  if [[ ! "$login" =~ ^[A-Za-z0-9-]+$ ]]; then
    echo "${RESTORE_INPUT}"
    return
  fi
  echo "$login" > "$DIR/author"
  echo "$AUTHOR_TAB" > "$DIR/tab"
  rm -f "$DIR/list.$AUTHOR_TAB"
  echo "${RESTORE_INPUT}+transform-header($SELF header)+reload($SELF list)+first"
}

cmd_approve() {
  [ "$1" = "x" ] && exit 0
  local ref out
  ref=$(printf '%s' "$1" | cut -d/ -f5,7 | tr / '#')
  if out=$(gh pr review "$1" --approve 2>&1); then
    rm -f "$DIR"/preview.*."$(printf '%s' "$1" | tr -c 'a-zA-Z0-9' '_')"
    find "$DIR" -name 'list.*' ! -name "list.$(current_tab)" -delete
    echo "refresh-preview+transform-header($SELF header)+change-footer-label: ✓ approved $ref "
  else
    echo "change-footer-label: ✗ $(printf '%s' "$out" | head -1) "
  fi
}

cmd_key_enter() {
  if [ -f "$DIR/author-mode" ]; then
    cmd_commit_author "${1:-}"
  elif [ "$FZF_INPUT_STATE" != enabled ]; then
    echo accept
  elif [ -n "$FZF_QUERY" ]; then
    echo "${NORMAL}+change-footer-label( filter: ${FZF_QUERY} )"
  else
    echo "${NORMAL}+change-footer-label()"
  fi
}

cmd_key_esc() {
  if [ -f "$DIR/author-mode" ]; then
    rm -f "$DIR/author-mode"
    echo "reload($SELF list)"
    return 0
  fi
  [ "$FZF_INPUT_STATE" != enabled ] && [ -z "$FZF_QUERY" ] && echo abort
  return 0
}

SELF="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

case "${1:-}" in
  step) cmd_step "$2"; exit 0 ;;
  header) cmd_header; exit 0 ;;
  list) cmd_list "${2:-}"; exit 0 ;;
  prefetch) cmd_prefetch; exit 0 ;;
  open-list) open "${GH_WEB}/$(tab_web "$(current_tab)")"; exit 0 ;;
  approve) cmd_approve "$2"; exit 0 ;;
  preview) cmd_preview "$2"; exit 0 ;;
  key-enter) cmd_key_enter "${2:-}"; exit 0 ;;
  members) cmd_members; exit 0 ;;
  key-esc) cmd_key_esc; exit 0 ;;
esac

DIR=$(mktemp -d "${TMPDIR:-/tmp}/tmux-pr-menu.XXXXXX")
export PR_MENU_DIR="$DIR"
trap 'rm -rf "$DIR"' EXIT
trap 'exit 1' HUP INT TERM
echo 0 > "$DIR/tab"

SWITCH="+transform-header($SELF header)+reload($SELF list)+first"
FOOTER="${DIM}h/l tab  j/k move  J/K ^d/^u scroll preview  ⏎/o open  O GitHub page  p approve  a author  / filter  r refresh  esc clear/quit${RESET}"

selected=$(
  : | fzf --ansi --no-multi --layout=reverse --height=100% --listen --no-input \
      --delimiter=$'\t' --with-nth=2.. \
      --header-first --header "$("$SELF" header)" --header-border=bottom \
      --footer "$FOOTER" --footer-border=top \
      --prompt='  / ' --pointer='▸' --gutter=' ' --info=inline-right --no-hscroll \
      --preview "$SELF preview {1}" \
      --preview-window=right:55%:border-left \
      --bind "start:reload($SELF list)+execute-silent($SELF prefetch >/dev/null 2>&1 &)" \
      --bind "load:transform-header($SELF header)" \
      --bind "l,right,tab:execute-silent($SELF step 1)${SWITCH}" \
      --bind "h,left,shift-tab:execute-silent($SELF step -1)${SWITCH}" \
      --bind 'j:down,k:up,g:first,G:last' \
      --bind 'J:preview-down,K:preview-up' \
      --bind 'ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up' \
      --bind "o:accept,O:execute-silent($SELF open-list)" \
      --bind "r,ctrl-r:reload($SELF list force)" \
      --bind 'q:abort' \
      --bind "p:transform($SELF approve {1})" \
      --bind "a:execute-silent(touch $DIR/author-mode)+show-input+unbind($VIM_KEYS)+clear-query+change-prompt(  author › )+change-footer-label( type a name or login, enter to pick, esc to cancel )+reload($SELF members)+first" \
      --bind "/:show-input+unbind($VIM_KEYS)" \
      --bind "enter:transform:$SELF key-enter {1}" \
      --bind "esc:transform($SELF key-esc)+show-input+clear-query+${NORMAL}+enable-search+change-prompt(  / )+change-footer-label()"
)

url=${selected%%$'\t'*}
case "$url" in https://*) open "$url" ;; esac
