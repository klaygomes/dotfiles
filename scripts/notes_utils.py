import re
from datetime import datetime
from pathlib import Path

DATE_PATTERNS = [
    (re.compile(r'[Dd]ate:\s*(\d{4}-\d{2}-\d{2})'), '%Y-%m-%d'),
    (re.compile(r'[Dd]ate:\s*([A-Za-z]+ \d{1,2},\s*\d{4})'), '%B %d, %Y'),
    (re.compile(r'-+date:\s*(\d{4}-\d{2}-\d{2})', re.I), '%Y-%m-%d'),
]


def find_date(text: str) -> str | None:
    for pattern, fmt in DATE_PATTERNS:
        m = pattern.search(text)
        if m:
            return datetime.strptime(m.group(1).strip(), fmt).strftime('%Y-%m-%d')
    return None


def unique_path(dest_dir: Path, base_date: str) -> Path:
    dest_dir.mkdir(parents=True, exist_ok=True)
    p = dest_dir / f"{base_date}.md"
    if not p.exists():
        return p
    i = 1
    while True:
        p = dest_dir / f"{base_date}_{i}.md"
        if not p.exists():
            return p
        i += 1
