#!/usr/bin/env bash
set -euo pipefail
# Keyed RGBA frames → feathered web deliverables: NAME.webm (VP9 alpha), NAME.mp4 (HEVC alpha, Safari), NAME.webp (poster).
usage() { echo "usage: encode.sh --frames DIR --out-dir DIR --name NAME [--width PX] [--fps 24] [--feather 0.9] [--crf 42] [--poster-frame first|last|N]" >&2; exit 1; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMES="" OUT="" NAME="" WIDTH="" FPS=24 FEATHER=0.9 CRF=42 POSTER=first
while [ $# -gt 0 ]; do
  case "$1" in
    --frames) FRAMES="$2"; shift 2 ;;
    --out-dir) OUT="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --width) WIDTH="$2"; shift 2 ;;
    --fps) FPS="$2"; shift 2 ;;
    --feather) FEATHER="$2"; shift 2 ;;
    --crf) CRF="$2"; shift 2 ;;
    --poster-frame) POSTER="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[ -n "$FRAMES" ] && [ -n "$OUT" ] && [ -n "$NAME" ] || usage
mkdir -p "$OUT"
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

"$HERE/py" "$HERE/feather.py" "$FRAMES" "$WORK/f" "$FEATHER" >/dev/null

SRC_W=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$WORK/f/0000.png")
SCALE="scale=trunc(iw/2)*2:trunc(ih/2)*2"
if [ -n "$WIDTH" ]; then
  [ "$WIDTH" -le "$SRC_W" ] || { echo "refusing to upscale $SRC_W -> $WIDTH px; encode at native size" >&2; exit 1; }
  SCALE="scale=$WIDTH:-2:flags=lanczos"
fi
IN=(-loglevel error -y -framerate "$FPS" -i "$WORK/f/%04d.png")

ffmpeg "${IN[@]}" -vf "$SCALE" -c:v libvpx-vp9 -pix_fmt yuva420p -crf "$CRF" -b:v 0 -row-mt 1 -an "$OUT/$NAME.webm"
ffmpeg "${IN[@]}" -vf "$SCALE,format=bgra" -c:v hevc_videotoolbox -allow_sw 1 -alpha_quality 0.7 -q:v 50 \
  -tag:v hvc1 -movflags +faststart -an "$OUT/$NAME.mp4"

N=$(find "$WORK/f" -name '*.png' | wc -l | tr -d ' ')
case "$POSTER" in first) P=0 ;; last) P=$((N - 1)) ;; *) P="$POSTER" ;; esac
ffmpeg -loglevel error -y -i "$WORK/f/$(printf %04d "$P").png" -vf "$SCALE" "$WORK/poster.png"
cwebp -quiet -q 85 -alpha_q 90 "$WORK/poster.png" -o "$OUT/$NAME.webp"

ls -l "$OUT/$NAME.webm" "$OUT/$NAME.mp4" "$OUT/$NAME.webp" | awk '{print $5"\t"$NF}'
