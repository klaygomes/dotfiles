#!/usr/bin/env python3
"""
Save clipboard content to ~/personal/meetings/YYYY-MM-DD.md.

The date is extracted from the clipboard text using the same patterns as
migrate_notes.py. Falls back to today's date if none is found.
Called by the sm() shell function in dotfiles/zsh/functions.sh.
"""

import subprocess
import sys
from datetime import date, datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from notes_utils import find_date, unique_path
from ingest_meeting import _load_env, ingest

MEETINGS_DIR = Path.home() / "personal" / "meetings"

_INPUT_FORMATS = [
    "%d-%m-%Y",
    "%d/%m/%Y",
    "%Y-%m-%d",
    "%Y/%m/%d",
]


def _parse_user_date(raw: str) -> str | None:
    raw = raw.strip()
    if raw.lower() == "today":
        return date.today().isoformat()
    for fmt in _INPUT_FORMATS:
        try:
            return datetime.strptime(raw, fmt).strftime("%Y-%m-%d")
        except ValueError:
            continue
    return None


def _prompt_date() -> str:
    today = date.today().isoformat()
    while True:
        raw = input(f"Date not found. Date [{today}]: ").strip()
        if not raw:
            return today
        parsed = _parse_user_date(raw)
        if parsed:
            return parsed
        print(f"  Could not parse '{raw}', try again.")


def main():
    content = subprocess.run(["pbpaste"], capture_output=True, text=True).stdout

    if not content.strip():
        print("Clipboard is empty, nothing to save.")
        sys.exit(0)

    extracted = find_date(content)
    if extracted:
        iso_date = extracted
        date_source = "found in content"
    else:
        iso_date = _prompt_date()
        date_source = "today" if iso_date == date.today().isoformat() else "provided by user"

    dest = unique_path(MEETINGS_DIR, iso_date)
    dest.write_text(content)
    print(f"Saved: {dest}  (date {iso_date} — {date_source})")

    _load_env()
    ingest(dest, date=iso_date)


if __name__ == "__main__":
    main()
