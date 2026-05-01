#!/usr/bin/env bash
input=$(cat)

R=$'\033[0m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
RED=$'\033[0;31m'
GRAY=$'\033[0;90m'

parts=()

# Context window
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
ctx_int=$(printf '%.0f' "$ctx_used")
if   [ "$ctx_int" -ge 80 ]; then c=$RED
elif [ "$ctx_int" -ge 50 ]; then c=$YELLOW
else                              c=$GREEN
fi
parts+=("${c}󰍛 ${ctx_int}%${R}")

# Rate limits
_rate_segment() {
  local pct_used=$1 resets_at=$2 label=$3
  local used=$(printf '%.0f' "$pct_used")
  local reset_str=""
  if [ "$resets_at" -gt 0 ]; then
    reset_str=" ${GRAY}→$(date -r "$resets_at" +"%a %H:%M")${R}"
  fi
  if   [ "$used" -ge 80 ]; then c=$RED
  elif [ "$used" -ge 50 ]; then c=$YELLOW
  else                          c=$GREEN
  fi
  echo "${c}${label}:${used}%${R}${reset_str}"
}

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // 0')
if [ -n "$five_pct" ]; then
  parts+=("$(_rate_segment "$five_pct" "$five_reset" "5h")")
fi

week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // 0')
if [ -n "$week_pct" ]; then
  parts+=("$(_rate_segment "$week_pct" "$week_reset" "7d")")
fi


printf '%s' "$(IFS=' | '; echo "${parts[*]}")"
