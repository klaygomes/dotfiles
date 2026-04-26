#!/usr/bin/env bash
# Thin wrapper so the skill can declare a Bash(bash *tools/query.sh*) permission.
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
exec "$SKILL_DIR/.venv/bin/python" "$SKILL_DIR/tools/query.py" "$@"
