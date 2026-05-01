#!/usr/bin/env zsh

clear

# One Double Dark palette
R='\033[0m'           # reset
BORDER='\033[38;5;8m' # gray  — box lines
HDR='\033[1;38;2;109;202;255m'  # bold blue  — column headers (#6dcaff)
CMD='\033[38;2;233;149;109m'    # orange     — commands (#e8956d)
EX='\033[38;2;140;197;112m'     # green      — examples (#8cc570)

W=120
PAD=$(( (COLUMNS - W) / 2 ))
pad=$(printf '%*s' $PAD '')

# helpers — column widths: 27 | 28 ║ 27 | 28
_line28() { printf '─%.0s' {1..28}; }
_line29() { printf '─%.0s' {1..29}; }

top2() {
  printf "${pad}${BORDER}┌$(_line28)┬$(_line29)╦$(_line28)┬$(_line29)┐${R}\n"
}
div2() {
  printf "${pad}${BORDER}├$(_line28)┼$(_line29)╬$(_line28)┼$(_line29)┤${R}\n"
}
bot2() {
  printf "${pad}${BORDER}└$(_line28)┴$(_line29)╩$(_line28)┴$(_line29)┘${R}\n"
}
hdr2() {
  printf "${pad}${BORDER}│${R} ${HDR}%-27s${R}${BORDER}│${R} ${HDR}%-28s${R}${BORDER}║${R} ${HDR}%-27s${R}${BORDER}│${R} ${HDR}%-28s${R}${BORDER}│${R}\n" "$1" "$2" "$3" "$4"
}
row2() {
  printf "${pad}${BORDER}│${R} ${CMD}%-27s${R}${BORDER}│${R} ${EX}%-28s${R}${BORDER}║${R} ${CMD}%-27s${R}${BORDER}│${R} ${EX}%-28s${R}${BORDER}│${R}\n" "$1" "$2" "$3" "$4"
}

cheatsheet() {
  echo ""
  top2
  hdr2 "COMMAND" "EXAMPLE" "COMMAND" "EXAMPLE"
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
