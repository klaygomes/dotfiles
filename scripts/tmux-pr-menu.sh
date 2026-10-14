#!/usr/bin/env bash
# GitHub PR menu (§ g), the root screen of the tmux-pr stack. See docs/tmux-pr-menu.md
# shellcheck enable=check-unassigned-uppercase,require-double-brackets,quote-safe-variables,deprecate-which

set -u
# shellcheck source-path=SCRIPTDIR source=tmux-pr-lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/tmux-pr-lib.sh" || exit 1

readonly GH_WEB=https://github.com/pulls
readonly MEMBERS=${XDG_CACHE_HOME:-$HOME/.cache}/tmux-pr-menu/members.tsv
readonly FAVORITES=${PR_MENU_FAVORITES:-${XDG_CONFIG_HOME:-$HOME/.config}/tmux-pr-menu/favorites}
readonly TEAM_CACHE_TTL=86400
readonly LOGIN_RE='^[A-Za-z0-9-]+$'
readonly TEAM_RE='^@?([A-Za-z0-9-]+)/([A-Za-z0-9_.-]+)$'
readonly AUTHOR_TAB=3
readonly TAB_NAMES=('Review requested' 'No review' 'Approved' 'By author')
readonly TAB_WEB=(
  'reviews?q=is%3Apr+review-requested%3A%40me+state%3Aopen+archived%3Afalse+sort%3Aupdated-desc+-author%3Aapp%2Fdependabot'
  'search?q=is%3Apr+author%3A%40me+state%3Aopen+archived%3Afalse+review%3Anone+sort%3Aupdated-desc'
  'search?q=is%3Apr+author%3A%40me+state%3Aopen+archived%3Afalse+review%3Aapproved+sort%3Aupdated-desc'
)

screen_footer='⏎/o open  O files  h/l tab  p approve  a author  w GitHub page  r refresh'
screen_binds=(
  "start:reload($PR_RUN list)+execute-silent($PR_RUN prefetch >/dev/null 2>&1 &)"
  "l,right,tab:execute-silent($PR_RUN step 1)+transform($PR_RUN after-step)"
  "h,left,shift-tab:execute-silent($PR_RUN step -1)+transform($PR_RUN after-step)"
  "o:transform($PR_RUN open {1})"
  "O:$(pr_push files)"
  "w:execute-silent($PR_RUN open-list)"
  "r,ctrl-r:transform($PR_RUN refresh)"
  "p:transform($PR_RUN approve {1})"
  "a:transform($PR_RUN author-mode)"
)
screen_fzf_opts=(--no-hscroll)

state_file() {
  printf '%s/menu/%s' "$PR_STATE" "$1"
}

read_state() {
  local value=
  { IFS= read -r value <"$(state_file "$1")"; } 2>/dev/null
  printf '%s' "${value:-${2-}}"
}

write_state() {
  printf '%s\n' "$2" >"$(state_file "$1")"
}

current_tab() {
  read_state tab 0
}

current_author() {
  read_state author
}

list_file() {
  local author
  if (($1 == AUTHOR_TAB)); then
    author=$(current_author)
    [[ -n $author ]] || return 1
    printf '%s/lists/author.%s' "$PR_CACHE" "$author"
  else
    printf '%s/lists/%s' "$PR_CACHE" "$1"
  fi
}

in_author_mode() {
  [[ -f $(state_file author-mode) ]]
}

tab_name() {
  local author
  author=$(current_author)
  if (($1 == AUTHOR_TAB)) && [[ -n $author ]]; then
    printf '@%s' "$author"
  else
    printf '%s' "${TAB_NAMES[$1]}"
  fi
}

tab_args() {
  case $1 in
    0) TAB_ARGS=(--review-requested=@me -- -author:app/dependabot) ;;
    1) TAB_ARGS=(--author=@me --review=none) ;;
    2) TAB_ARGS=(--author=@me --review=approved) ;;
    "$AUTHOR_TAB") TAB_ARGS=(--author="$(current_author)") ;;
  esac
}

tab_web() {
  local tab
  tab=$(current_tab)
  if ((tab == AUTHOR_TAB)); then
    printf 'search?q=is%%3Apr+author%%3A%s+state%%3Aopen+archived%%3Afalse+sort%%3Aupdated-desc' "$(current_author)"
  else
    printf '%s' "${TAB_WEB[$tab]}"
  fi
}

tab_count() {
  local file
  file=$(list_file "$1")
  if [[ -n $file && -s $file ]]; then
    grep -vc $'^x\t' -- "$file"
  else
    printf '…'
  fi
}

screen_start() {
  mkdir -p -- "$PR_STATE/menu" && write_state tab 0
}

screen_header() {
  local active i last=$((${#TAB_NAMES[@]} - 1)) label out="${PR_DIM}◀${PR_RESET}  "
  active=$(current_tab)
  for i in "${!TAB_NAMES[@]}"; do
    label=" $(tab_name "$i") ($(tab_count "$i")) "
    if ((i == active)); then
      out+="${PR_ACCENT}${label}${PR_RESET}"
    else
      out+="${PR_DIM}${label}${PR_RESET}"
    fi
    ((i < last)) && out+="${PR_DIM}│${PR_RESET}"
  done
  printf '%s  %s▶%s' "$out" "$PR_DIM" "$PR_RESET"
}

# shellcheck disable=SC2016
readonly ROWS_JQ='def ref: .repository.name + "#" + (.number | tostring);
  (map(ref | length) | max) as $width | .[] | ref as $ref | [
    .url,
    ("\u001b[38;5;173m" + $ref + "\u001b[0m" + (" " * ($width - ($ref | length) + 2))
      + (if .isDraft then "\u001b[2m[draft]\u001b[0m " else "" end)
      + .title + "  \u001b[2m@" + .author.login + "\u001b[0m")
  ] | @tsv'

cmd_fetch_tab() {
  local out
  tab_args "$1"
  out=$(gh search prs --state=open --archived=false --sort=updated --limit=100 \
    --json url,repository,number,title,author,isDraft --jq "$ROWS_JQ" \
    "${TAB_ARGS[@]}") || return 1
  if [[ -z $out ]]; then
    pr_row_empty
  else
    printf '%s\n' "$out"
  fi
}

screen_list() {
  local file out
  if ! file=$(list_file "$(current_tab)"); then
    pr_row_empty 'press a to pick an author'
  elif ! out=$(pr_cached "$file" fetch-tab "$(current_tab)" 2>&1); then
    pr_row_error "gh failed: ${out%%$'\n'*}"
  else
    printf '%s\n' "$out"
  fi
}

cmd_refresh() {
  local file url
  if file=$(list_file "$(current_tab)") && [[ -f $file ]]; then
    pr_refresh_cooling "$file" && return 0
    while IFS=$'\t' read -r url _; do
      [[ $url == https://* ]] && pr_forget "$url"
    done <"$file"
    rm -f -- "$file"
  fi
  printf 'reload(%s list)+refresh-preview' "$PR_RUN"
}

cmd_step() {
  local count=${#TAB_NAMES[@]} tab
  tab=$(current_tab)
  write_state tab $(((tab + $1 + count) % count))
}

cmd_after_step() {
  if (($(current_tab) == AUTHOR_TAB)) && [[ -z $(current_author) ]]; then
    cmd_author_mode
  else
    printf 'transform-header(%s header)+reload(%s list)+first' "$PR_RUN" "$PR_RUN"
  fi
}

cmd_prefetch() {
  local i port=${FZF_PORT-}
  fetch_members &
  list_favorites >/dev/null 2>&1 &
  for i in "${!TAB_NAMES[@]}"; do
    ((i == $(current_tab) || i == AUTHOR_TAB)) && continue
    pr_cached "$(list_file "$i")" fetch-tab "$i" >/dev/null 2>&1 &
  done
  wait
  [[ -n $port ]] || return 0
  curl -s --noproxy '*' -XPOST "localhost:$port" -d "transform-header($PR_RUN header)" >/dev/null
}

cmd_open_list() {
  open "$GH_WEB/$(tab_web)"
}

list_orgs() {
  local -a orgs
  if [[ -n ${PR_MENU_ORGS-} ]]; then
    read -r -a orgs <<<"$PR_MENU_ORGS"
    printf '%s\n' "${orgs[@]}"
  else
    gh api graphql -f query='{ viewer { organizations(first: 100) { nodes { login } } } }' \
      --jq '.data.viewer.organizations.nodes[].login'
  fi
}

fetch_org_members() {
  # shellcheck disable=SC2016
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
  local org tmp
  [[ -n $(find "$MEMBERS" -mtime -1 2>/dev/null) ]] && return 0
  mkdir -p -- "${MEMBERS%/*}" || return 1
  tmp=$(mktemp "$MEMBERS.XXXXXX") || return 1
  while IFS= read -r org; do
    fetch_org_members "$org" 2>/dev/null
  done < <(list_orgs 2>/dev/null) \
    | sort -u -t $'\t' -k2,2 | sort -f | cut -f2- >"$tmp"
  if [[ -s $tmp ]]; then
    mv -f -- "$tmp" "$MEMBERS"
  else
    rm -f -- "$tmp"
  fi
}

cmd_fetch_team() {
  # shellcheck disable=SC2016
  gh api graphql --paginate -f org="$1" -f team="$2" -f query='
    query($org: String!, $team: String!, $endCursor: String) {
      organization(login: $org) {
        team(slug: $team) {
          members(first: 100, after: $endCursor, membership: ALL) {
            pageInfo { hasNextPage endCursor }
            nodes { login }
          }
        }
      }
    }' --jq '.data.organization.team.members.nodes[].login' | sort -f
}

list_team() {
  PR_CACHE_TTL=$TEAM_CACHE_TTL pr_cached "$PR_CACHE/teams/$1_$2" fetch-team "$1" "$2" 2>/dev/null
}

list_favorites() {
  local line
  [[ -f $FAVORITES ]] || return 0
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%%#*}
    line=${line//[[:space:]]/}
    if [[ $line =~ $TEAM_RE ]]; then
      list_team "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    elif [[ ${line#@} =~ $LOGIN_RE ]]; then
      printf '%s\n' "${line#@}"
    fi
  done <"$FAVORITES"
}

cmd_members() {
  fetch_members
  {
    list_favorites | sed 's/^/F\t/'
    sed 's/^/M\t/' -- "$MEMBERS" 2>/dev/null
  } | awk -F '\t' -v star='★ ' -v dim="$PR_DIM" -v reset="$PR_RESET" '
    $1 == "F" { if (!($2 in fav)) { fav[$2] = 1; order[++n] = $2 }; next }
    { display[$2] = $3; logins[++m] = $2 }
    END {
      for (i = 1; i <= n; i++) {
        login = order[i]
        print login "\t" star (login in display ? display[login] : dim "@" login reset)
      }
      for (i = 1; i <= m; i++) {
        if (!(logins[i] in fav)) print logins[i] "\t" display[logins[i]]
      }
    }'
}

cmd_author_mode() {
  : >"$(state_file author-mode)"
  printf '%s+clear-query+change-prompt(  author › )+change-footer-label( type a name or login, enter to pick, esc to cancel )+transform-header(%s header)+reload(%s members)+first' \
    "$PR_FILTER" "$PR_RUN" "$PR_RUN"
}

commit_author() {
  local login=$1
  [[ $login =~ $LOGIN_RE ]] || login=${FZF_QUERY#@}
  rm -f -- "$(state_file author-mode)"
  if [[ ! $login =~ $LOGIN_RE ]]; then
    printf 'reload(%s list)+%s' "$PR_RUN" "$PR_RESTORE"
    return 0
  fi
  write_state author "$login"
  write_state tab "$AUTHOR_TAB"
  printf '%s+transform-header(%s header)+reload(%s list)+first' "$PR_RESTORE" "$PR_RUN" "$PR_RUN"
}

screen_enter_hook() {
  in_author_mode || return 1
  commit_author "$1"
}

screen_esc_hook() {
  in_author_mode || return 1
  rm -f -- "$(state_file author-mode)"
  printf 'reload(%s list)+%s' "$PR_RUN" "$PR_RESTORE"
}

cmd_approve() {
  local url=$1 out
  [[ $url == x ]] && return 0
  if out=$(gh pr review "$url" --approve 2>&1); then
    pr_forget "$url"
    rm -rf -- "$PR_CACHE/lists"
    printf 'reload(%s list)+refresh-preview+execute-silent(%s prefetch >/dev/null 2>&1 &)+change-footer-label: ✓ approved %s ' \
      "$PR_RUN" "$PR_RUN" "$(pr_ref "$url")"
  else
    printf 'change-footer-label: ✗ %s ' "${out%%$'\n'*}"
  fi
}

# shellcheck disable=SC2016
readonly SUMMARY_JQ='def bucket: (.conclusion // .state // "") as $c
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
(if (.body | length) > 0 then .body else "_No description._" end)'

cmd_render_summary() {
  gh pr view "$1" --json title,url,number,author,headRefName,baseRefName,state,isDraft,reviewDecision,statusCheckRollup,additions,deletions,changedFiles,reviewRequests,labels,body \
    --jq "$SUMMARY_JQ" 2>&1 \
    | CLICOLOR_FORCE=1 glow -s dark -w "$2" -
}

screen_preview() {
  local width=$((${FZF_PREVIEW_COLUMNS:-80} - 2))
  in_author_mode && return 0
  pr_cached_preview "$(pr_dir "$1")/summary.$width" render-summary "$1" "$width"
}

screen_on_enter() {
  cmd_open "$1"
}

cmd_open() {
  [[ ${1-} == https://* ]] || return 0
  open "$1"
  printf 'change-footer-label: ↗ opened %s ' "$(pr_ref "$1")"
}

pr_main "$@"
