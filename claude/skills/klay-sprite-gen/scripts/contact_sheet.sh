#!/usr/bin/env bash
set -euo pipefail
# contact_sheet.sh <frames-dir|clip.mp4> <out.png> [cols=6] [rows=2]
[ $# -ge 2 ] || { echo "usage: contact_sheet.sh <frames-dir|clip> <out.png> [cols] [rows]" >&2; exit 1; }
SRC="$1" OUT="$2" COLS="${3:-6}" ROWS="${4:-2}"

if [ -d "$SRC" ]; then
  N=$(find "$SRC" -maxdepth 1 -name '*.png' | wc -l | tr -d ' ')
  INPUT=(-pattern_type glob -i "$SRC/*.png")
else
  N=$(ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames -of csv=p=0 "$SRC")
  INPUT=(-i "$SRC")
fi
STEP=$(( N / (COLS * ROWS) )); [ "$STEP" -ge 1 ] || STEP=1

ffmpeg -loglevel error -y "${INPUT[@]}" \
  -vf "select=not(mod(n\,$STEP)),scale=240:-1,tile=${COLS}x${ROWS}" -frames:v 1 -update 1 "$OUT"
echo "$OUT ($N frames, every ${STEP}th)"
