#!/usr/bin/env python3
"""
Save clipboard content to ~/personal/meetings/YYYY-MM-DD.md.

The date is extracted from the clipboard text using the same patterns as
migrate_notes.py. Falls back to today's date if none is found.
Called by the sm() shell function in dotfiles/zsh/functions.sh.
"""

import subprocess
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from notes_utils import find_date, unique_path

MEETINGS_DIR = Path.home() / "personal" / "meetings"


def main():
    content = subprocess.run(["pbpaste"], capture_output=True, text=True).stdout

    extracted = find_date(content)
    if extracted:
        iso_date = extracted
        date_source = "found in content"
    else:
        iso_date = date.today().isoformat()
        date_source = "defaulted to today"

    dest = unique_path(MEETINGS_DIR, iso_date)
    dest.write_text(content)
    print(f"Saved: {dest}  (date {iso_date} — {date_source})")


if __name__ == "__main__":
    main()
