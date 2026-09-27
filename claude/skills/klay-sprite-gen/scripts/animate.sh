#!/usr/bin/env bash
set -euo pipefail
# Still → keyed RGBA frames via Grok Imagine. Each paid step is skipped when its output exists,
# so a rerun after a failure or a prompt tweak only redoes what is missing (delete clip.mp4 to regenerate).
usage() {
  cat >&2 <<'USAGE'
usage: animate.sh --still still.png --prompt-file prompt.txt --out-dir DIR
                  [--shape square|tall|wide]  (default: tight fit, no room added) [--reference ref.png]... [--duration 5]
                  [--resolution 720p] [--no-return] [--gentle-key]
USAGE
  exit 1
}

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STILL="" PROMPT="" OUT="" SHAPE="" DURATION=5 RES="720p" RETURN=1 GENTLE=0 REFS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --still) STILL="$2"; shift 2 ;;
    --prompt-file) PROMPT="$2"; shift 2 ;;
    --out-dir) OUT="$2"; shift 2 ;;
    --shape) SHAPE="$2"; shift 2 ;;
    --reference) REFS+=(--reference "$2"); shift 2 ;;
    --duration) DURATION="$2"; shift 2 ;;
    --resolution) RES="$2"; shift 2 ;;
    --no-return) RETURN=0; shift ;;
    --gentle-key) GENTLE=1; shift ;;
    *) usage ;;
  esac
done
[ -n "$STILL" ] && [ -n "$PROMPT" ] && [ -n "$OUT" ] || usage
mkdir -p "$OUT"

FIT=(--fit tight); [ -n "$SHAPE" ] && FIT=(--fit state --shape "$SHAPE")
if [ ! -f "$OUT/canvas.png" ]; then
  "$HERE/py" "$HERE/green_composite.py" "$STILL" "$OUT/still-green.png"
  "$HERE/sg" video-canvas --still "$OUT/still-green.png" --out "$OUT/canvas.png" --key green "${FIT[@]}"
fi

if [ ! -f "$OUT/clip.mp4" ]; then
  LAST=(); [ "$RETURN" = 1 ] && LAST=(--last-frame "$OUT/canvas.png")
  cp "$PROMPT" "$OUT/prompt.txt"
  "$HERE/sg" video --image "$OUT/canvas.png" "${LAST[@]}" ${REFS[@]+"${REFS[@]}"} \
    --prompt-file "$OUT/prompt.txt" --out "$OUT/clip.mp4" \
    --duration "$DURATION" --resolution "$RES" --no-audio
fi

KEY=(--spill auto --decontam auto)
[ "$GENTLE" = 1 ] && KEY=(--spill small --decontam off --allow-subject-edge-contact)
rm -rf "$OUT/frames"
"$HERE/sg" video-frames --clip "$OUT/clip.mp4" --out-dir "$OUT/frames" --key green \
  --reference "$OUT/canvas.png" "${KEY[@]}"

"$HERE/contact_sheet.sh" "$OUT/frames/keyed" "$OUT/contact.png"
echo "KEYED=$OUT/frames/keyed"
echo "CONTACT=$OUT/contact.png"
