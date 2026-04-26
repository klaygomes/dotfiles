#!/usr/bin/env python3
"""
Move classified meeting notes from ~/.notes_staging to ~/personal/meetings/.
Dates were extracted from content (high confidence) or inferred from content
clues and filename context (medium/low confidence).
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from notes_utils import unique_path

STAGING = Path.home() / ".notes_staging"
MEETINGS_DEST = Path.home() / "personal" / "meetings"

# filename -> (YYYY-MM-DD, source)
FILE_DATE_MAP = {
    # --- Content dates (extracted directly from file) ---
    "Notes__-----Card-DE-estimations---Meeting-Notes.txt":            ("2026-04-24", "content"),
    "Notes__Date-\xa02026-04-10.txt":                                 ("2026-04-10", "content"),
    "Notes__Date-\xa02026-04-13.txt":                                 ("2026-04-13", "content"),
    "Notes__Date-\xa02026-04-21.txt":                                 ("2026-04-21", "content"),
    "Notes__Date-\xa0April-17,-2026.txt":                             ("2026-04-17", "content"),
    "Notes__Date-\xa0April-24,-2026.txt":                             ("2026-04-24", "content"),
    "Notes__Date-\xa0April-9,-2026.txt":                              ("2026-04-09", "content"),
    "Notes__Project-\xa0ACQ---Sprint-planning.txt":                   ("2026-04-13", "content"),
    "Notes__Project-\xa0Cognito-going-live-sync.txt":                 ("2026-04-16", "content"),
    "Notes__Project-\xa0Vibe-coding-forum.txt":                       ("2026-04-22", "content"),
    "Notes__[[Acquisition--Standup]]---2026-04-16.txt":               ("2026-04-16", "content"),
    "Notes__[[Call--Qred-<>-CrediMaxx-(API-update)]].txt":            ("2026-04-15", "content"),

    # --- Inferred dates (high confidence) ---
    "Notes__The-discussion-covered-several-product-updates-and-team-logistics….txt":            ("2026-04-17", "inferred-high"),
    "Notes__The-standup-focused-on-recent-progress,-debugging-efforts,-and-a-discussion….txt":  ("2026-04-21", "inferred-high"),
    "Notes__UX-Audit-\xa0Lucas-moved-stale-tickets-and-initiated-a-new-ticket-for….txt":        ("2026-04-24", "inferred-high"),

    # --- Inferred dates (medium confidence) ---
    "Notes__API-Strategy-and-Kriya-Integration-\xa0Qred-will-use-its-embedded-API….txt":        ("2026-04-22", "inferred-medium"),
    "Notes__Based-on-the-context-from-your-current-meeting-and-other-workspace….txt":           ("2026-04-17", "inferred-medium"),
    "Notes__Completed-Tasks--The-first-standalone-page-was-successfully-moved….txt":            ("2026-04-10", "inferred-medium"),
    "Notes__Discussion-Summary.txt":                                                             ("2026-04-09", "inferred-medium"),
    "Notes__Gemini.txt":                                                                         ("2026-04-17", "inferred-medium"),
    "Notes__List-key-takeaways.txt":                                                             ("2026-04-16", "inferred-medium"),
    "Notes__Optimizing-Claude's-Context-with-a-Flat-File-(Philip-Vigus).txt":                   ("2026-04-21", "inferred-medium"),
    "Notes__Revenue-Domain;.txt":                                                                ("2026-04-07", "inferred-medium"),
    "Notes__Summary-of-Discussion.txt":                                                          ("2026-04-16", "inferred-medium"),
    "Notes__Team-Activities-\xa0Cleiton-Loiola-opened-the-discussion-by-asking-about….txt":     ("2026-03-26", "inferred-medium"),
    "Notes__Testing-for-the-new-Card-Widget-in-the-Netherlands-is-progressing….txt":            ("2026-04-14", "inferred-medium"),
    "Notes__Yue-Wang's-Progress-\xa0A-top-review-item-is-ready,-which-involves-minimal….txt":   ("2026-04-09", "inferred-medium"),
    "Notes__give-a-very-detailed-description-of-the-meeting.txt":                               ("2026-04-13", "inferred-medium"),
    "Notes__why-this-exist?.txt":                                                                ("2026-02-26", "inferred-medium"),
    "Notes__The-discussion-focused-on-the-progress-of-the-API-integration-between….txt":        ("2026-03-18", "inferred-medium"),

    # --- Inferred dates (low confidence) ---
    "Notes__.\xa0This-discussion-was-related-to-the-discovery-and-planning-tracked….txt":       ("2026-04-14", "inferred-low"),
    "Notes__Acquisition-Plugin-Development-\xa0Cleiton-announced-that-the-Cred-wide….txt":      ("2026-04-23", "inferred-low"),
    "Notes__Development-and-Design-Updates--A-feature-has-been-tested-locally….txt":            ("2026-04-09", "inferred-low"),
    "Notes__Development-and-Testing-Updates.txt":                                                ("2026-04-15", "inferred-low"),
    "Notes__How-to-have-access-token-for-accessing-the-sand-box-environment?.txt":              ("2026-04-08", "inferred-low"),
    "Notes__Key-Takeaways.txt":                                                                  ("2026-04-21", "inferred-low"),
    "Notes__Present-sprint-goal.-Is-it-clear-or-too-vague?-(5-min).txt":                       ("2026-04-21", "inferred-low"),
    "Notes__Problem-and-Impact.txt":                                                             ("2026-04-09", "inferred-low"),
}

UNDATABLE = [
    "Notes__The-meeting-introduced-the-Qred-team-working-on-the-partner-API-and….txt",
    "Notes__explain-the-question-made-to-christian.txt",
    "Notes__qosmos-tables.txt",
    "Notes__Task-\xa0https---stash.int.klarna.net-projects-TI-repos-front-end-interview….txt",
]


def main():
    moved, errors = [], []

    for filename, (iso_date, source) in FILE_DATE_MAP.items():
        src = STAGING / filename
        if not src.exists():
            errors.append(f"NOT FOUND: {filename}")
            continue
        content = src.read_text()
        dest = unique_path(MEETINGS_DEST, iso_date)
        dest.write_text(content)
        src.unlink()
        moved.append(f"[{source}] {filename} -> {dest.name}")

    print(f"Moved {len(moved)} files:")
    for m in moved:
        print(f"  {m}")

    if errors:
        print(f"\nErrors ({len(errors)}):")
        for e in errors:
            print(f"  {e}")

    print(f"\nUndatable (left in staging):")
    for u in UNDATABLE:
        exists = "exists" if (STAGING / u).exists() else "NOT FOUND"
        print(f"  [{exists}] {u}")


if __name__ == "__main__":
    main()
