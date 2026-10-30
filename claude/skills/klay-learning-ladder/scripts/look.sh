#!/usr/bin/env bash
set -euo pipefail

MOTIONMAXXING="${LEARNING_LADDER_HOME:-$HOME/.local/share/klay-learning-ladder}/motionmaxxing"
LOOK="$MOTIONMAXXING/scripts/look.py"

if ffmpeg -hide_banner -filters 2>/dev/null | grep -q " drawtext "; then
  exec python3 -I "$LOOK" "$@"
fi

echo "ffmpeg has no drawtext filter: running look.py without timecodes on the sheet" >&2
patched="$(mktemp -d)/look_nofont.py"
sed 's|^FONTS = \[|FONTS = [] and [|' "$LOOK" > "$patched"
exec python3 -I "$patched" "$@"
