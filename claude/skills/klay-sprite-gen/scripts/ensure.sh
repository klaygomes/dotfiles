#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/aldegad/sprite-gen.git"
HOME_DIR="${SPRITE_GEN_HOME:-$HOME/.local/share/sprite-gen}"
BIN="$HOME_DIR/.venv/bin/sprite-gen"
STAMP="$HOME_DIR/.venv/.last-update"

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing dependency: $1 ($2)" >&2; exit 1; }; }
need git "xcode-select --install"
need python3 "brew install python@3.12"
need ffmpeg "brew install ffmpeg"
need cwebp "brew install webp"

python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' \
  || { echo "python3 >= 3.11 required" >&2; exit 1; }

if [ ! -d "$HOME_DIR/.git" ]; then
  echo "first run: cloning sprite-gen into $HOME_DIR" >&2
  mkdir -p "$(dirname "$HOME_DIR")"
  git clone --quiet "$REPO_URL" "$HOME_DIR"
fi

if [ ! -x "$BIN" ]; then
  python3 -m venv "$HOME_DIR/.venv"
  "$HOME_DIR/.venv/bin/pip" install --quiet --upgrade pip
  "$HOME_DIR/.venv/bin/pip" install --quiet -e "$HOME_DIR"
  date +%s > "$STAMP"
fi

if [ "${1:-}" = "--update" ] || [ ! -f "$STAMP" ] || [ $(( $(date +%s) - $(cat "$STAMP") )) -gt 604800 ]; then
  before=$(git -C "$HOME_DIR" rev-parse HEAD)
  if git -C "$HOME_DIR" pull --quiet --ff-only 2>/dev/null; then
    after=$(git -C "$HOME_DIR" rev-parse HEAD)
    if [ "$before" != "$after" ]; then
      echo "sprite-gen updated $before..$after" >&2
      "$HOME_DIR/.venv/bin/pip" install --quiet -e "$HOME_DIR"
    fi
  else
    echo "warning: git pull failed, using existing checkout" >&2
  fi
  date +%s > "$STAMP"
fi

"$BIN" --help >/dev/null
echo "SPRITE_GEN_HOME=$HOME_DIR"
echo "SPRITE_GEN=$BIN"
echo "VERSION=$(git -C "$HOME_DIR" describe --tags --always 2>/dev/null)"
