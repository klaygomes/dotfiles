#!/usr/bin/env bats
# Offline tests for the tmux-pr-* screens. See docs/tmux-pr-menu.md#tests

PR_URL=https://github.com/acme/widgets/pull/7

setup() {
  MENU=$BATS_TEST_DIRNAME/tmux-pr-menu.sh
  FILES=$BATS_TEST_DIRNAME/tmux-pr-files.sh
  PATH=$BATS_TEST_DIRNAME/tmux-pr-fixtures/bin:$PATH
  export PR_STATE=$BATS_TEST_TMPDIR/state
  export GH_LOG=$BATS_TEST_TMPDIR/gh.log
  export XDG_CACHE_HOME=$BATS_TEST_TMPDIR/cache
  export PR_FILES_URL=$PR_URL
  export PR_PREVIEW_DEBOUNCE=0
  CACHE=$XDG_CACHE_HOME/tmux-pr-menu
  unset FZF_QUERY FZF_INPUT_STATE GH_FAIL GH_DELAY GH_SEARCH_FIXTURE PR_MENU_ORGS PR_CACHE_TTL PR_REFRESH_COOLDOWN
  mkdir -p "$PR_STATE/menu"
  printf '0\n' >"$PR_STATE/menu/tab"
  : >"$GH_LOG"
}

gh_calls() {
  grep -c "^${1}" "$GH_LOG" || true
}

set_tab() {
  printf '%s\n' "$1" >"$PR_STATE/menu/tab"
}

age_file() {
  touch -t 202001010000 "$1"
}

@test "menu: review-requested tab lists url and display, excluding dependabot" {
  run "$MENU" list
  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 2 ]
  [[ ${lines[0]} == "https://github.com/acme/widgets/pull/7"$'\t'*"widgets#7"*"Add sprocket support"*"@alice"* ]]
  [[ ${lines[1]} == *"[draft]"*"Fix gizmo timeout"* ]]
  grep -q -- '--review-requested=@me -- -author:app/dependabot' "$GH_LOG"
}

@test "menu: no-review and approved tabs query the author's own PRs" {
  set_tab 1
  run "$MENU" list
  grep -q -- '--author=@me --review=none' "$GH_LOG"
  set_tab 2
  run "$MENU" list
  grep -q -- '--author=@me --review=approved' "$GH_LOG"
}

@test "menu: list is cached across popups until the TTL expires" {
  "$MENU" list >/dev/null
  rm -rf "$PR_STATE"
  mkdir -p "$PR_STATE/menu"
  "$MENU" list >/dev/null
  [ "$(gh_calls 'search prs')" -eq 1 ]
  age_file "$CACHE/lists/0"
  "$MENU" list >/dev/null
  [ "$(gh_calls 'search prs')" -eq 2 ]
}

@test "menu: refresh drops the tab and its PR previews, then reloads" {
  "$MENU" list >/dev/null
  mkdir -p "$CACHE/pr/acme_widgets_7"
  : >"$CACHE/pr/acme_widgets_7/summary.80"
  PR_REFRESH_COOLDOWN=0 run "$MENU" refresh
  [ "$output" = "reload($MENU list)+refresh-preview" ]
  [ ! -e "$CACHE/lists/0" ]
  [ ! -d "$CACHE/pr/acme_widgets_7" ]
  "$MENU" list >/dev/null
  [ "$(gh_calls 'search prs')" -eq 2 ]
}

@test "menu: refresh is throttled right after a fetch" {
  "$MENU" list >/dev/null
  run "$MENU" refresh
  [[ $output == "change-footer-label: fetched "*"s ago, refresh again in "* ]]
  [ -f "$CACHE/lists/0" ]
}

@test "menu: concurrent identical requests share one gh call" {
  GH_DELAY=0.5 "$MENU" list >"$BATS_TEST_TMPDIR/a" &
  GH_DELAY=0.5 "$MENU" list >"$BATS_TEST_TMPDIR/b" &
  wait
  [ "$(gh_calls 'search prs')" -eq 1 ]
  cmp -s "$BATS_TEST_TMPDIR/a" "$BATS_TEST_TMPDIR/b"
}

@test "menu: a lock file left behind does not block a fetch" {
  mkdir -p "$CACHE/lists"
  : >"$CACHE/lists/0.lock"
  run "$MENU" list
  [[ ${lines[0]} == "https://"* ]]
}

@test "menu: gh failure becomes an error row with the first line only" {
  GH_FAIL='HTTP 502: bad gateway' run "$MENU" list
  [ "${#lines[@]}" -eq 1 ]
  [[ ${lines[0]} == x$'\t'*"gh failed: HTTP 502: bad gateway"* ]]
  [[ ${lines[0]} != *"second line"* ]]
}

@test "menu: gh failure is not cached" {
  GH_FAIL='HTTP 502: bad gateway' "$MENU" list >/dev/null
  run "$MENU" list
  [[ ${lines[0]} == "https://"* ]]
  [ "$(gh_calls 'search prs')" -eq 2 ]
}

@test "menu: empty result becomes a placeholder row" {
  GH_SEARCH_FIXTURE=empty.json run "$MENU" list
  [[ ${lines[0]} == x$'\t'*"(nothing here)"* ]]
}

@test "menu: header counts fetched tabs and marks the rest as pending" {
  "$MENU" list >/dev/null
  run "$MENU" header
  [[ $output == *"Review requested (2)"*"No review (…)"*"By author (…)"* ]]
}

@test "menu: tab stepping wraps around both ends" {
  "$MENU" step -1
  [ "$(cat "$PR_STATE/menu/tab")" -eq 3 ]
  "$MENU" step 1
  [ "$(cat "$PR_STATE/menu/tab")" -eq 0 ]
}

@test "menu: author tab without an author shows a hint and skips gh" {
  set_tab 3
  run "$MENU" list
  [[ ${lines[0]} == x$'\t'*"press a to pick an author"* ]]
  [ "$(gh_calls 'search prs')" -eq 0 ]
}

@test "menu: stepping onto the empty author tab opens the picker" {
  set_tab 3
  run "$MENU" after-step
  [ -f "$PR_STATE/menu/author-mode" ]
  [[ $output == *"show-input"*"transform-header("*"reload("*"members)"* ]]
}

@test "menu: stepping onto a normal tab reloads the list" {
  set_tab 1
  run "$MENU" after-step
  [ ! -f "$PR_STATE/menu/author-mode" ]
  [[ $output == "transform-header("*"reload("*"list)+first" ]]
}

@test "menu: picker lists org members, display name first" {
  run "$MENU" members
  [ "${#lines[@]}" -eq 3 ]
  [[ ${lines[0]} == "alice"$'\t'"Alice Anders"* ]]
  [[ ${lines[2]} == "zed-acme"$'\t'*"@zed-acme"* ]]
}

@test "menu: members come from PR_MENU_ORGS and are cached for a day" {
  PR_MENU_ORGS='acme other' "$MENU" members >/dev/null
  [ "$(gh_calls 'api graphql --paginate -f org=acme')" -eq 1 ]
  [ "$(gh_calls 'api graphql --paginate -f org=other')" -eq 1 ]
  "$MENU" members >/dev/null
  [ "$(gh_calls 'api graphql')" -eq 2 ]
}

@test "menu: enter in the picker commits the highlighted login" {
  "$MENU" author-mode >/dev/null
  FZF_INPUT_STATE=enabled run "$MENU" key-enter bob
  [ "$(cat "$PR_STATE/menu/author")" = bob ]
  [ "$(cat "$PR_STATE/menu/tab")" -eq 3 ]
  [ ! -f "$PR_STATE/menu/author-mode" ]
  [[ $output == *"reload("*"list)+first" ]]
}

@test "menu: enter in the picker falls back to the typed login" {
  "$MENU" author-mode >/dev/null
  FZF_INPUT_STATE=enabled FZF_QUERY=@dave run "$MENU" key-enter ''""
  [ "$(cat "$PR_STATE/menu/author")" = dave ]
}

@test "menu: enter in the picker ignores an invalid login" {
  "$MENU" author-mode >/dev/null
  FZF_INPUT_STATE=enabled FZF_QUERY='not a login' run "$MENU" key-enter ''""
  [ ! -f "$PR_STATE/menu/author" ]
  [[ $output == "reload("*"list)+enable-search"* ]]
}

@test "menu: esc in the picker cancels it" {
  "$MENU" author-mode >/dev/null
  run "$MENU" key-esc
  [ ! -f "$PR_STATE/menu/author-mode" ]
  [[ $output == "reload("*"list)+enable-search"* ]]
}

@test "menu: author tab queries the picked author" {
  printf 'bob\n' >"$PR_STATE/menu/author"
  set_tab 3
  run "$MENU" header
  [[ $output == *"@bob"* ]]
  "$MENU" list >/dev/null
  grep -q -- '--author=bob' "$GH_LOG"
}

@test "menu: author tab is cached per author" {
  set_tab 3
  printf 'bob\n' >"$PR_STATE/menu/author"
  "$MENU" list >/dev/null
  printf 'dave\n' >"$PR_STATE/menu/author"
  "$MENU" list >/dev/null
  printf 'bob\n' >"$PR_STATE/menu/author"
  "$MENU" list >/dev/null
  [ "$(gh_calls 'search prs')" -eq 2 ]
  [ -f "$CACHE/lists/author.bob" ]
  [ -f "$CACHE/lists/author.dave" ]
}

@test "menu: approve drops the PR and every list, then reloads" {
  mkdir -p "$CACHE/pr/acme_widgets_7" "$CACHE/lists"
  : >"$CACHE/pr/acme_widgets_7/summary.80"
  : >"$CACHE/lists/0"
  : >"$CACHE/lists/author.bob"
  run "$MENU" approve "$PR_URL"
  [[ $output == "reload($MENU list)+refresh-preview+execute-silent($MENU prefetch"*"✓ approved widgets#7"* ]]
  [ ! -d "$CACHE/pr/acme_widgets_7" ]
  [ ! -d "$CACHE/lists" ]
}

@test "menu: approve failure is reported in the footer" {
  GH_FAIL='cannot approve your own pull request' run "$MENU" approve "$PR_URL"
  [ "$output" = "change-footer-label: ✗ cannot approve your own pull request " ]
}

@test "menu: preview renders the PR summary and caches it per width" {
  FZF_PREVIEW_COLUMNS=82 run "$MENU" preview "$PR_URL"
  [[ $output == *"# Add sprocket support"* ]]
  [[ $output == *"✓ 1  ✗ 1  ● 1"* ]]
  [[ $output == *"Waiting on:** carol"* ]]
  [ -f "$CACHE/pr/acme_widgets_7/summary.80" ]
}

@test "menu: preview is blank on placeholder rows and in the picker" {
  run "$MENU" preview x
  [ -z "$output" ]
  "$MENU" author-mode >/dev/null
  run "$MENU" preview "$PR_URL"
  [ -z "$output" ]
}

@test "menu: O pushes the files screen" {
  # shellcheck disable=SC2016
  run grep -F 'O:$(pr_push files)' "$MENU"
  [ "$status" -eq 0 ]
  run bash -c "source '$BATS_TEST_DIRNAME/tmux-pr-lib.sh' && pr_push files"
  [ "$output" = "execute($BATS_TEST_DIRNAME/tmux-pr-files.sh {1})" ]
}

@test "menu: prefetch fills the other tabs and pokes fzf" {
  FZF_PORT=6266 "$MENU" prefetch
  [ -f "$CACHE/lists/1" ]
  [ -f "$CACHE/lists/2" ]
  [ ! -f "$CACHE/lists/0" ]
  [ -z "$(find "$CACHE/lists" -name 'author.*')" ]
  grep -q 'curl .*localhost:6266' "$GH_LOG"
}

@test "keys: typing exit pops the screen in every mode" {
  FZF_QUERY=exit FZF_INPUT_STATE=enabled run "$MENU" key-enter "$PR_URL"
  [ "$output" = abort ]
  FZF_QUERY=exit FZF_INPUT_STATE=enabled run "$FILES" key-enter src/app.ts
  [ "$output" = abort ]
}

@test "keys: enter in normal mode runs the screen's action" {
  FZF_INPUT_STATE=disabled run "$MENU" key-enter "$PR_URL"
  [ "$output" = "change-footer-label: ↗ opened widgets#7 " ]
  grep -qx "open $PR_URL" "$GH_LOG"
  FZF_INPUT_STATE=disabled run "$FILES" key-enter src/app.ts
  [[ $output == "execute-silent("*"tmux-pr-files.sh open {1})" ]]
  FZF_INPUT_STATE=disabled run "$MENU" key-enter x
  [ -z "$output" ]
}

@test "keys: enter in filter mode keeps the filter and returns to normal" {
  FZF_INPUT_STATE=enabled FZF_QUERY=gizmo run "$MENU" key-enter "$PR_URL"
  [[ $output == "hide-input+rebind("*")+change-footer-label( filter: gizmo )" ]]
}

@test "keys: esc clears a filter, then pops the screen" {
  FZF_INPUT_STATE=enabled FZF_QUERY=gizmo run "$FILES" key-esc
  [[ $output == "enable-search+clear-query"* ]]
  run "$FILES" key-esc
  [ "$output" = abort ]
}

@test "keys: filter mode unbinds every single-letter key the screen binds" {
  FZF_INPUT_STATE=enabled run "$MENU" key-enter "$PR_URL"
  [[ $output == *"rebind(j,k,g,G,J,K,q,/,l,h,o,O,w,r,p,a)"* ]]
  FZF_INPUT_STATE=enabled run "$FILES" key-enter src/app.ts
  [[ $output == *"rebind(j,k,g,G,J,K,q,/,o,r)"* ]]
}

@test "files: list shows file name, counts, then the directory" {
  run "$FILES" list
  [ "${#lines[@]}" -eq 4 ]
  [[ ${lines[1]} == "docs/my notes.md"$'\t'"my notes.md"*"+2"*"-0"*"docs/"* ]]
}

@test "files: header shows repo#number and title" {
  run "$FILES" header
  [[ $output == *" widgets#7 "*"Add sprocket support" ]]
}

@test "files: preview shows only the selected file's diff" {
  run "$FILES" preview src/app.ts
  [[ $output == *"export const sprocket = true;"* ]]
  [[ $output != *"library copy of app"* ]]
  [[ $output != *"notes about sprockets"* ]]
}

@test "files: preview handles paths with spaces and renames" {
  run "$FILES" preview "docs/my notes.md"
  [[ $output == *"notes about sprockets"* ]]
  run "$FILES" preview new/name.ts
  [[ $output == *"renamed after"* ]]
}

@test "files: patch is fetched once per PR" {
  "$FILES" preview src/app.ts >/dev/null
  "$FILES" preview new/name.ts >/dev/null
  [ "$(gh_calls 'pr diff')" -eq 1 ]
}

@test "files: refresh refetches the PR, throttled right after a fetch" {
  "$FILES" list >/dev/null
  run "$FILES" refresh
  [[ $output == "change-footer-label: fetched "* ]]
  PR_REFRESH_COOLDOWN=0 run "$FILES" refresh
  [[ $output == "reload("*"list)+refresh-preview+transform-header("*"header)" ]]
  [ ! -d "$CACHE/pr/acme_widgets_7" ]
  "$FILES" list >/dev/null
  [ "$(gh_calls 'pr view')" -eq 2 ]
}

@test "menu: o opens the PR in the browser and keeps the popup" {
  # shellcheck disable=SC2016
  run grep -F 'o:transform($PR_RUN open {1})' "$MENU"
  [ "$status" -eq 0 ]
  run "$MENU" open x
  [ -z "$output" ]
  [ ! -s "$GH_LOG" ]
}

@test "files: open goes to the file's anchor on GitHub" {
  "$FILES" open src/app.ts
  hash=$(printf '%s' src/app.ts | shasum -a 256 | cut -d' ' -f1)
  grep -qx "open $PR_URL/files#diff-$hash" "$GH_LOG"
}

@test "files: placeholder row argument exits quietly, bad argument shows usage" {
  run "$FILES" x
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  run "$FILES" not-a-url
  [ "$status" -eq 2 ]
  [[ $output == usage:* ]]
}
