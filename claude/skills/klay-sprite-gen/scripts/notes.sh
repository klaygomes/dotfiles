#!/usr/bin/env bash
set -euo pipefail
# notes.sh              print accumulated learnings
# notes.sh add "text"   append a dated learning
NOTES="${SPRITE_GEN_NOTES:-$HOME/.local/share/sprite-gen-notes.md}"
[ -f "$NOTES" ] || printf '# sprite-gen learnings\n\n' > "$NOTES"
case "${1:-show}" in
  show) cat "$NOTES" ;;
  add) shift; [ $# -gt 0 ] || { echo 'usage: notes.sh add "text"' >&2; exit 1; }; printf -- '- %s: %s\n' "$(date +%F)" "$*" >> "$NOTES"; echo "saved to $NOTES" ;;
  *) echo 'usage: notes.sh [show | add "text"]' >&2; exit 1 ;;
esac
