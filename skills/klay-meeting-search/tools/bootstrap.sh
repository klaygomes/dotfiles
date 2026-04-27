#!/usr/bin/env bash
# Bootstrap checker for the meeting-search skill.
# Ensures .venv and .env exist; sets them up if not.
# Exits 0 on success, 1 on unrecoverable error.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOTFILES_DIR="$(cd "$SKILL_DIR/../.." && pwd)"

if [[ ! -x "$SKILL_DIR/.venv/bin/python" ]]; then
  echo "Creating venv..."
  python3 -m venv "$SKILL_DIR/.venv"
  "$SKILL_DIR/.venv/bin/pip" install -q -r "$SKILL_DIR/requirements.txt"
fi

if [[ ! -f "$DOTFILES_DIR/.env" ]]; then
  if [[ ! -f "$DOTFILES_DIR/.env.example" ]]; then
    echo "ERROR: .env.example missing at $DOTFILES_DIR" >&2; exit 1
  fi
  cp "$DOTFILES_DIR/.env.example" "$DOTFILES_DIR/.env"
fi

echo "OK"
