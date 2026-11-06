#!/usr/bin/env bash
# Keeps a homelab Mac awake and logged in. See docs/server.md
set -euo pipefail

readonly AC_SETTINGS=(sleep:0 disksleep:0 standby:0 womp:1 tcpkeepalive:1 autorestart:1)

if ! fdesetup status | grep -q 'FileVault is Off.'; then
  printf 'FileVault is on or still decrypting: %s\n' "$(fdesetup status)" >&2
  printf 'Turn it off in System Settings, Privacy and Security, FileVault, then run again.\n' >&2
  exit 1
fi

capabilities=$(pmset -g cap)
for setting in "${AC_SETTINGS[@]}"; do
  key=${setting%%:*}
  value=${setting#*:}
  if grep -qw "$key" <<<"$capabilities"; then
    sudo pmset -c "$key" "$value"
  else
    printf 'Skipping %s: not supported on this Mac\n' "$key"
  fi
done

if pmset -g batt | grep -q InternalBattery; then
  sudo pmset -a disablesleep 1
fi

if [[ $(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || :) != "$USER" ]]; then
  printf 'Turning on automatic login for %s. Type the login password of %s.\n' "$USER" "$USER"
  sudo sysadminctl -autologin set -userName "$USER" -password -
fi

if ! nc -z -G 2 localhost 22 2>/dev/null; then
  sudo systemsetup -f -setremotelogin on \
    || printf 'Turn on Remote Login in System Settings, General, Sharing.\n' >&2
fi

pmset -g custom
printf 'Automatic login: %s\n' "$(defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser)"
