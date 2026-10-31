#!/usr/bin/env python3
"""Turn 1-prose.md into the page's HTML body. [[name]] lines become slots filled with --slot name=file."""
import argparse
import html
import re
import sys
from pathlib import Path

MATH = re.compile(r"(\\\(.+?\\\)|\\\[.+?\\\])", re.S)


def inline(text):
    parts = MATH.split(text)
    out = []
    for i, part in enumerate(parts):
        if i % 2:
            out.append(part)
            continue
        part = html.escape(part, quote=False)
        part = re.sub(r"`([^`]+)`", r"<code>\1</code>", part)
        part = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", part)
        part = re.sub(r"(?<![*\w])\*(?!\s)(.+?)(?<!\s)\*(?!\w)", r"<em>\1</em>", part)
        out.append(part)
    return "".join(out)


def table(rows):
    cells = [[c.strip() for c in r.strip().strip("|").split("|")] for r in rows]
    head, body = cells[0], [r for r in cells[2:]]
    th = "".join(f"<th scope=\"col\">{inline(c)}</th>" for c in head)
    tr = "".join("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in r) + "</tr>" for r in body)
    return f'<div class="table"><table class="alt worked"><thead><tr>{th}</tr></thead><tbody>{tr}</tbody></table></div>'


def blocks(lines, slots):
    out, i = [], 0
    while i < len(lines):
        line = lines[i]
        if not line.strip():
            i += 1
        elif line.startswith("```"):
            j = i + 1
            while not lines[j].startswith("```"):
                j += 1
            out.append('<pre class="code"><code>' + html.escape("\n".join(lines[i + 1:j])) + "</code></pre>")
            i = j + 1
        elif re.fullmatch(r"\[\[([\w:-]+)\]\]", line.strip()):
            name = line.strip()[2:-2]
            if name not in slots:
                sys.exit(f"no --slot for [[{name}]]")
            out.append(slots[name])
            i += 1
        elif line.startswith("|"):
            j = i
            while j < len(lines) and lines[j].startswith("|"):
                j += 1
            out.append(table(lines[i:j]))
            i = j
        elif line.startswith(">"):
            j = i
            while j < len(lines) and lines[j].startswith(">"):
                j += 1
            out.append('<p class="rule-box">' + inline(" ".join(l[1:].strip() for l in lines[i:j])) + "</p>")
            i = j
        elif re.match(r"(\d+\.|-) ", line):
            ordered = line[0].isdigit()
            j, items = i, []
            while j < len(lines) and re.match(r"(\d+\.|-) ", lines[j]):
                items.append(re.sub(r"^(\d+\.|-) ", "", lines[j]))
                j += 1
            tag = "ol" if ordered else "ul"
            first = int(line.split(".", 1)[0]) if ordered else 1
            start = f' start="{first}"' if first != 1 else ""
            out.append(f"<{tag}{start}>" + "".join(f"<li>{inline(t)}</li>" for t in items) + f"</{tag}>")
            i = j
        elif line.startswith("\\["):
            j = i
            while not lines[j].rstrip().endswith("\\]"):
                j += 1
            out.append('<div class="display-math">' + "\n".join(lines[i:j + 1]) + "</div>")
            i = j + 1
        else:
            j = i
            while j < len(lines) and lines[j].strip() and not re.match(r"(```|\||>|\[\[|\\\[|\d+\. |- )", lines[j]):
                j += 1
            out.append("<p>" + inline(" ".join(lines[i:j])) + "</p>")
            i = j
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("prose")
    ap.add_argument("--slot", action="append", default=[], help="name=file whose contents replace [[name]]")
    a = ap.parse_args()
    slots = {}
    for spec in a.slot:
        name, path = spec.split("=", 1)
        slots[name] = Path(path).read_text(encoding="utf-8")
    text = Path(a.prose).read_text(encoding="utf-8")
    sections = re.split(r"^## ", text, flags=re.M)
    body = []
    for section in sections[1:]:
        title, rest = section.split("\n", 1)
        slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
        body.append(f'<section id="{slug}">\n<h2>{inline(title.strip())}</h2>\n{blocks(rest.splitlines(), slots)}\n</section>')
    print("\n\n".join(body))


if __name__ == "__main__":
    main()
