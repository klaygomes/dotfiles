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
  local pct_used=$1 resets_at=$2 icon=$3
  local used
  used=$(printf '%.0f' "$pct_used")
  local reset_str=""
  if [ "$resets_at" -gt 0 ]; then
    local fmt="%H:%M"
    [ "$(date -r "$resets_at" +%F)" != "$(date +%F)" ] && fmt="%a %H:%M"
    reset_str=" ${GRAY}→$(date -r "$resets_at" +"$fmt")${R}"
  fi
  if   [ "$used" -ge 80 ]; then c=$RED
  elif [ "$used" -ge 50 ]; then c=$YELLOW
  else                          c=$GREEN
  fi
  echo "${c}${icon} ${used}%${R}${reset_str}"
}

five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // 0')
parts+=("$(_rate_segment "$five_pct" "$five_reset" "󱑿")")

week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // 0')
parts+=("$(_rate_segment "$week_pct" "$week_reset" "󰃭")")

# Model display name
model_name=$(echo "$input" | jq -r '.model.display_name // ""')
[ -n "$model_name" ] && parts+=("${GRAY}󰚩 ${model_name}${R}")

output="$(IFS=' | '; echo "${parts[*]}")"
# Only right-align when Claude passes a valid COLUMNS value; otherwise output as-is
if [ "${COLUMNS:-0}" -gt 0 ] 2>/dev/null; then
  visible=$(printf '%s' "$output" | sed 's/\033\[[0-9;]*m//g')
  pad=$(( COLUMNS - ${#visible} ))
  [ "$pad" -gt 0 ] && printf '%*s' "$pad" ""
fi
printf '%s' "$output"
