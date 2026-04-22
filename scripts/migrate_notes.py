#!/usr/bin/env python3
"""
Migrate exported Apple Notes (.txt) from ~/.notes_staging to ~/personal/meetings.

Files exported by export_notes() are prefixed with their Apple Notes folder name
(e.g. "Meetings__Daily-Standup.txt"). This script uses that prefix to classify
each note:
  - "Meetings" folder → ~/personal/meetings/
  - Other folders    → prompts for destination (defaults to ~/personal/<FolderName>/)

Dates are extracted from the note content. Falls back to prompting the user.
Run with: python3 ~/dotfiles/scripts/migrate_notes.py
"""

import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from notes_utils import find_date, unique_path

STAGING = Path.home() / ".notes_staging"
MEETINGS_DEST = Path.home() / "personal" / "meetings"


def main():
    txt_files = sorted(STAGING.glob("*.txt"))
    if not txt_files:
        print(f"No .txt files found in {STAGING}")
        return

    for txt_file in txt_files:
        name = txt_file.stem  # e.g. "Meetings__Daily-Standup"
        parts = name.split("__", 1)
        folder_name = parts[0] if len(parts) == 2 else "Other"

        if folder_name.lower() == "meetings":
            dest_dir = MEETINGS_DEST
        else:
            default_dir = str(Path.home() / "personal" / folder_name)
            val = input(
                f"Note from '{folder_name}' folder. Destination dir [{default_dir}]: "
            ).strip()
            dest_dir = Path(val) if val else Path(default_dir)

        content = txt_file.read_text()
        iso_date = find_date(content)
        if not iso_date:
            default_date = date.today().isoformat()
            val = input(
                f"No date found in {txt_file.name}. Enter date [{default_date}]: "
            ).strip()
            iso_date = val if val else default_date

        dest = unique_path(dest_dir, iso_date)
        dest.write_text(content)
        print(f"{txt_file.name} -> {dest}")


if __name__ == "__main__":
    main()
