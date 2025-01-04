#!/bin/bash -euo pipefail

. ./zsh/functions.sh

# https://apple.stackexchange.com/a/269106
username="$(stat -f%Su /dev/console)"
realname="$(dscl . -read /Users/$username RealName | cut -d: -f2 | sed -e 's/^[ \t]*//' | grep -v "^$")"

get_input "Inform your name" NAME '[A-Za-z ]' "$realname"
get_input "Inform your personal email" EMAIL_PERSONAL '[A-Za-z0-9._%+-]*@[A-Za-z0-9.-]*'
get_input "Inform your work email" EMAIL_WORK '[A-Za-z0-9._%+-]*@[A-Za-z0-9.-]*' "$EMAIL_PERSONAL"