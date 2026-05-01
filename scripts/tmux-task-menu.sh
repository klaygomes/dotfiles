#!/usr/bin/env zsh

clear

W=120  # total table width (2 sections of 60)
PAD=$(( (COLUMNS - W) / 2 ))
pad=$(printf '%*s' $PAD '')

# Each section: | %-28s| %-27s|  = 60 chars wide
row2() {
  printf "${pad}│ %-27s│ %-28s║ %-27s│ %-28s│\n" "$1" "$2" "$3" "$4"
}
div2() {
  printf "${pad}├%s┼%s╬%s┼%s┤\n" \
    "$(printf '─%.0s' {1..28})" "$(printf '─%.0s' {1..29})" \
    "$(printf '─%.0s' {1..28})" "$(printf '─%.0s' {1..29})"
}
top2() {
  printf "${pad}┌%s┬%s╦%s┬%s┐\n" \
    "$(printf '─%.0s' {1..28})" "$(printf '─%.0s' {1..29})" \
    "$(printf '─%.0s' {1..28})" "$(printf '─%.0s' {1..29})"
}
bot2() {
  printf "${pad}└%s┴%s╩%s┴%s┘\n" \
    "$(printf '─%.0s' {1..28})" "$(printf '─%.0s' {1..29})" \
    "$(printf '─%.0s' {1..28})" "$(printf '─%.0s' {1..29})"
}

cheatsheet() {
  echo ""
  top2
  row2 "COMMAND" "EXAMPLE" "COMMAND" "EXAMPLE"
  div2
  row2 "add <desc>"                  "add Buy milk"               "<id> start / stop"      "1 start"
  row2 "add <desc> project:<name>"   "add Fix bug project:work"   "<id> done"              "2 done"
  row2 "add <desc> due:<date>"       "add Task due:friday"        "<id> delete"            "3 delete"
  row2 "add <desc> priority:H"       "add Urgent task priority:H" "<id> modify due:<date>" "2 modify due:tomorrow"
  row2 "add <desc> +<tag>"           "add Fix +work +bug"         "<id> modify priority:H" "1 modify priority:H"
  row2 "list"                        "all pending tasks"          "<id> modify +<tag>"     "1 modify +urgent"
  row2 "next"                        "by urgency"                 "<id> annotate <note>"   "1 annotate check logs"
  row2 "due:today"                   "tasks due today"            "<id> info"              "2 info"
  row2 "due:tomorrow"                "tasks due tomorrow"         "<id> edit"              "open in \$EDITOR"
  row2 "project:<name>"              "project:work"               "summary"                "project overview"
  row2 "projects"                    "list all projects"          "+<tag>"                 "+work (filter by tag)"
  bot2
  echo ""
}

cheatsheet

while true; do
  printf "task> "
  read cmd || break
  [[ -z "$cmd" ]] && continue
  [[ "$cmd" == "quit" || "$cmd" == "exit" || "$cmd" == "q" ]] && break
  [[ "$cmd" == "h" || "$cmd" == "help" ]] && cheatsheet && continue
  eval "task $cmd"
  echo ""
done
