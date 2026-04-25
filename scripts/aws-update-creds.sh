#!/usr/bin/env bash
set -euo pipefail

CREDS_FILE="$HOME/.aws/credentials"
MAP_FILE="$HOME/.aws/profile_map"

if [[ ! -f "$MAP_FILE" ]]; then
  echo "error: $MAP_FILE not found" >&2
  echo "create it with lines like:  source_name=canonical_name" >&2
  exit 1
fi

read_canonical() {
  local source_name="$1"
  while IFS='=' read -r k v; do
    [[ "$k" == "$source_name" ]] && { echo "$v"; return; }
  done < "$MAP_FILE"
}

parse_block() {
  local text="$1"
  profile_name=""
  declare -gA cred_keys=()
  while IFS= read -r line; do
    line="${line//[$'\r']}"
    [[ -z "$line" ]] && continue
    if [[ "$line" =~ ^\[(.+)\]$ ]]; then
      profile_name="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
      cred_keys["${BASH_REMATCH[1]// /}"]="${BASH_REMATCH[2]}"
    fi
  done <<< "$text"
}

update_credentials() {
  local canonical="$1"
  local new_block="[$canonical]"$'\n'
  for k in "${!cred_keys[@]}"; do
    new_block+="$k=${cred_keys[$k]}"$'\n'
  done

  mkdir -p "$(dirname "$CREDS_FILE")"
  touch "$CREDS_FILE"

  if grep -q "^\[$canonical\]" "$CREDS_FILE"; then
    # Replace existing section: remove old block, insert new one
    awk -v canon="$canonical" -v block="$new_block" '
      /^\[/ { if (in_section) { in_section=0 } }
      /^\[/ && $0 == "[" canon "]" { print block; in_section=1; next }
      !in_section { print }
    ' "$CREDS_FILE" > "$CREDS_FILE.tmp" && mv "$CREDS_FILE.tmp" "$CREDS_FILE"
  else
    printf '\n%s' "$new_block" >> "$CREDS_FILE"
  fi
}

block="$(pbpaste)"
parse_block "$block"

if [[ -z "$profile_name" ]] || [[ "${#cred_keys[@]}" -eq 0 ]]; then
  echo "Paste your AWS credentials block (end with an empty line):"
  lines=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && break
    lines+=("$line")
  done
  block="$(printf '%s\n' "${lines[@]}")"
  parse_block "$block"
fi

if [[ -z "$profile_name" ]] || [[ "${#cred_keys[@]}" -eq 0 ]]; then
  echo "error: could not parse credentials" >&2
  exit 1
fi

canonical="$(read_canonical "$profile_name")"

if [[ -z "$canonical" ]]; then
  echo "error: unknown profile '$profile_name'" >&2
  echo "add it to $MAP_FILE" >&2
  exit 1
fi

update_credentials "$canonical"
echo "updated [$canonical] in $CREDS_FILE"
