#!/usr/bin/env python3
# cred — update ~/.aws/credentials from clipboard
# Profile name mapping lives in ~/.aws/profile_map (not tracked in dotfiles):
#   source_profile_name=canonical_name

import re
import subprocess
import sys
from pathlib import Path

CREDS_FILE = Path.home() / ".aws" / "credentials"
MAP_FILE = Path.home() / ".aws" / "profile_map"


def read_map():
    if not MAP_FILE.exists():
        print(f"error: {MAP_FILE} not found", file=sys.stderr)
        print("create it with lines like:  source_name=canonical_name", file=sys.stderr)
        sys.exit(1)
    mapping = {}
    for line in MAP_FILE.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        k, _, v = line.partition("=")
        if k and v:
            mapping[k.strip()] = v.strip()
    return mapping


def parse_block(text):
    header = None
    keys = {}
    for line in text.strip().splitlines():
        line = line.strip()
        if not line:
            continue
        m = re.match(r'^\[(.+)\]$', line)
        if m:
            header = m.group(1)
        elif "=" in line:
            k, _, v = line.partition("=")
            keys[k.strip()] = v.strip()
    return header, keys


def update_credentials(canonical, keys):
    CREDS_FILE.parent.mkdir(parents=True, exist_ok=True)
    content = CREDS_FILE.read_text() if CREDS_FILE.exists() else ""

    positions = [(m.start(), m.group(1)) for m in re.finditer(r'^\[([^\]]+)\]', content, re.MULTILINE)]
    sections = []
    for i, (start, name) in enumerate(positions):
        end = positions[i + 1][0] if i + 1 < len(positions) else len(content)
        sections.append((name, content[start:end]))

    new_block = f"[{canonical}]\n" + "\n".join(f"{k}={v}" for k, v in keys.items()) + "\n"

    replaced = False
    result = []
    for name, block in sections:
        if name == canonical:
            result.append(new_block)
            replaced = True
        else:
            result.append(block)

    if not replaced:
        if result and not result[-1].endswith("\n\n"):
            result.append("\n")
        result.append(new_block)

    CREDS_FILE.write_text("".join(result))


clipboard = subprocess.run(["pbpaste"], capture_output=True, text=True).stdout
source_name, keys = parse_block(clipboard)

if not source_name:
    print("error: no profile header found in clipboard", file=sys.stderr)
    sys.exit(1)

if not keys:
    print("error: no credentials found in clipboard", file=sys.stderr)
    sys.exit(1)

mapping = read_map()
canonical = mapping.get(source_name)

if not canonical:
    print(f"error: unknown profile '{source_name}'", file=sys.stderr)
    print(f"add it to {MAP_FILE}", file=sys.stderr)
    sys.exit(1)

update_credentials(canonical, keys)
print(f"updated [{canonical}] in {CREDS_FILE}")
