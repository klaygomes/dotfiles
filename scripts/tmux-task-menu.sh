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
  hdr2 "COMMAND" "EXAMPLE" "ACTIONS" "EXAMPLE"
  div2
  row2 "add <desc>"               "add Buy milk"            "<id> done / delete"     "2 done  /  3 delete"
  row2 "add ... project:<p>"      "add Fix project:work"    "<id> start / stop"      "1 start"
  row2 "add ... +<tag>"           "add Fix +work +bug"      "<id> modify <attr>"     "2 modify due:+2d"
  row2 "add ... priority:H/M/L"  "add Task priority:H"     "<id> annotate <note>"   "1 annotate check log"
  row2 "add ... due:<date>"       "add Task due:friday"     "<id> info / edit"       "2 info / open \$EDITOR"
  row2 "add ... until:<date>"     "add Task until:eow"      "list / next / waiting"  "all / urgency / hidden"
  row2 "add ... wait:<date>"      "hides task until date"   "project:<p> / +<tag>"   "project:work / +bug"
  row2 "add ... scheduled:<date>" "add Task scheduled:+1w"  "due:today / tomorrow"   "filter by due date"
  row2 "add ... recur:<freq>"     "add Bills recur:monthly" "summary / projects"     "overview / list all"
  div2
  hdr2 "DATE KEYWORDS" "" "RELATIVE DATES" ""
  div2
  row2 "today  tomorrow  eod"     "end of day"              "+1d  +2w  +3m  +1y"    "days/weeks/months/years"
  row2 "eow  eom  eoy"            "end of week/month/year"  "mon  tue  wed  thu  fri" "next weekday occurrence"
  bot2
  echo ""
}

cheatsheet

zmodload zsh/zle

typeset _exit_modal=0
_modal_exit() { _exit_modal=1; BUFFER=''; zle accept-line }
zle -N _modal_exit
bindkey '\e' _modal_exit

while true; do
  typeset cmd=''
  _exit_modal=0
  vared -p 'task> ' cmd || break
  [[ $_exit_modal -eq 1 ]] && break
  [[ -z "$cmd" ]] && continue
  [[ "$cmd" == "quit" || "$cmd" == "exit" || "$cmd" == "q" ]] && break
  [[ "$cmd" == "h" || "$cmd" == "help" ]] && cheatsheet && continue
  eval "task $cmd"
  echo ""
done
