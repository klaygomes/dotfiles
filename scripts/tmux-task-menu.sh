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
  hdr2 "ADD MODIFIERS" "EXAMPLE" "ACTIONS" "EXAMPLE"
  div2
  row2 "add <desc>"                "add Buy milk"            "<id> done / delete"    "2 done  /  3 delete"
  row2 "+<tag>  project:<p>"       "+bug project:work"       "<id> start / stop"     "1 start  /  1 stop"
  row2 "priority:H/M/L  due:<d>"  "priority:H due:fri"      "<id> modify <attr>"    "2 modify due:+2d"
  row2 "wait:<d>  until:<d>"       "wait:mon until:eow"      "<id> annotate <note>"  "1 annotate see log"
  row2 "sched:<d>  recur:<freq>"   "sched:+1w recur:monthly" "list / next / waiting" "all / urgent / hidden"
  div2
  hdr2 "DATE KEYWORDS" "" "RELATIVE DATES" ""
  div2
  row2 "today  tomorrow  eod"      "end of day"              "+1d  +2w  +3m  +1y"   "days/weeks/months/years"
  row2 "eow  eom  eoy"             "end of week/month/year"  "mon  tue  wed  thu  fri" "next weekday occurrence"
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
