---
name: klay-artifact-style
description: 'House style for every Artifact page: a well-typeset engineering memo. Plain short sentences, one reading column, sections that tell problem, evidence, cause, fix, steps, each with one visual, ruled lines instead of cards. Automatically invoke, without waiting for the user to ask, before writing or republishing any Artifact (HTML page, report, explainer, incident write-up, design note, plan page). Load after artifact-design; this skill sets voice and layout on top of its page contract.'
---

# Artifact style

Every Artifact reads like a well-typeset engineering memo. Same voice, same skeleton, same visual language.

Files in this folder:

- `tokens.css`: design tokens. Palette, fonts, spacing, radii, dark mode. The only place the look is defined.
- `template.html`: page skeleton and components. It links `tokens.css` and uses no raw colors or font names.

Start a new page from `template.html`. Publish it with the tokens file next to it:

```
Artifact(file_path: "<page>.html", files: {"tokens.css": "<skill folder>/tokens.css"})
```

To change the look of all future pages, edit `tokens.css` only. Never put a color or font name inside a page.

## Voice

1. Short sentences. One fact per sentence. Most sentences stay under 15 words.
2. Plain words. Write for a reader whose first language is not English. "We cannot save them", not "persistence fails intermittently".
3. Say "we" for the team and the system. Present tense.
4. Name things the way the reader sees them: "the bank statement shows missing transactions", then the technical cause.
5. Technical names go in `<code>`: ids, tables, columns, functions, error codes. The sentence around them stays plain.
6. Numbers are exact or marked as approximate (`~190`). Never "many" or "a lot".
7. No adjectives that judge ("critical", "robust", "elegant"). No hedging unless the uncertainty is real. No em dashes.
8. Paragraphs are one to three sentences. If a paragraph grows, the rest belongs in a visual.

Bad: "Due to a race condition in the upsert logic, transaction persistence can intermittently fail for certain multi-currency scenarios."
Good: "We save the account first. Then we look for it again. If we do not find it, every page of transactions is lost."

## Skeleton

```
h1          2 to 4 word name of the thing, small: it is a label
meta        area · identifier · ticket link, one muted line under the title
lede        1 to 2 sentences, large: this is the hero, what happens and what the reader sees
figures     2 to 4 key numbers in one ruled band; bad numbers in the bad color

What goes wrong        paragraph + flow diagram with a caption
Real example           paragraph + facts table + sequence diagram + shortened evidence + query to find it again
Why it happens         cause list: where (bad color) · title · one or two sentences
The fix                one-sentence principle + target diagram + before/after code pair
Steps                  ruled numbered list: hanging numeral, bold action, one muted detail line

footer      links + "Data checked <where>, <date>"
```

Adapt section titles to the topic, keep the arc: what, proof, why, fix, how to ship. Drop a section that has nothing real in it. Never pad one.

Section titles are plain phrases a reader would say aloud: "What goes wrong", "Why the account is not found", "The fix", "Release steps". No section numbers. Numbers appear only where order is information: the steps list.

## Visual rules

1. Every section is one short paragraph plus one visual. Visual choices: Mermaid flowchart, Mermaid sequence, facts table (`dl.facts`), cause list (`dl.causes`), before/after code (`.pair`), steps (`ol.steps`).
2. Rules, not boxes. Content is separated by hairlines (`--rule`) and white space; the figures band and footer open with a 3px `--accent` rule. The only boxed element is code, because code is a different material. No cards, no eyebrows above the title, no shadows.
3. Diagrams use 3 to 6 nodes. Node labels are short plain phrases with `<br/>` breaks. Color nodes by role with `classDef`: `step`, `ext`, `good`, `bad`. Diagrams sit on the page with a one-line `figcaption`.
4. Use the same diagram shape for the problem and the fix so the reader sees what changed.
5. Evidence is real: timestamps, ids, counts, a shortened log, and the query that finds it again. Label shortened content "shortened". Mask personal data.
6. Code pairs show only the lines that change, with one comment per step. Mark the failing line with `.bad` and the new line with `.ok`.
7. Distribute the whole palette, each color with one job. `--accent` (pink) marks structure: section bars, the figures rule, step numerals, inline code, fixed lines, flow nodes. `--bad` (magenta) marks evidence and what went wrong: labels, bad numbers, failing lines, the lost node, the "where" of a cause. `--fg` (plum) is ink. `--bg` and `--surface` (cream) are paper and code. Use the `-soft` tints for backgrounds, the full colors for text and marks. Mermaid cannot read CSS variables, so each diagram repeats the `--node-*` values from `tokens.css` in its `classDef` lines.
8. Type: `--font-display` for h1, h2, cause titles, figure numbers, step numerals and labels, weight 600 to 700, tracking `--tracking-display`. `--font-body` for everything readable, including the lede. `--font-mono` only for code, ids and values in the facts table. Never mono for labels.
9. Browser surfaces are themed from tokens: selection, caret, focus ring, scrollbar, tabular numerals. Keep them when you copy the template.
10. One column, `--column` wide, `--section-gap` between sections. Works at phone width with no horizontal scroll.

## Pre-publish check

1. Read only the h1, lede and figures. Does the reader know what broke and how bad it is?
2. Read only the section titles. Do they tell the story in order?
3. Any sentence over 20 words? Split it.
4. Any paragraph without a visual next to it? Add one or merge it.
5. Any claim without a number, id or link behind it? Add the evidence or cut the claim.
6. Any box that is not code? Replace it with a rule or white space.
7. `grep -n "—"` on the file returns nothing.
8. `grep -nE "#[0-9A-Fa-f]{6}" <page>` matches only `classDef` lines.
9. `npx -y impeccable detect <page>` reports no anti-patterns.
