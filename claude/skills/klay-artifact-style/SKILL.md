---
name: klay-artifact-style
description: 'House style for every Artifact page: plain short sentences, one reading column, numbered sections that tell problem, evidence, cause, fix, steps, each with one visual. Automatically invoke, without waiting for the user to ask, before writing or republishing any Artifact (HTML page, report, explainer, incident write-up, design note, plan page). Load after artifact-design; this skill sets voice and layout on top of its page contract.'
---

# Artifact style

Every Artifact uses this style. Same voice, same skeleton, same visual language. Start from `template.html` in this folder.

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
eyebrow     area · sub-area                     (mono, uppercase, muted)
eyebrow     identifier · ticket link            (optional)
h1          2 to 4 word name of the thing
lede        1 to 2 sentences: what happens, what the reader sees
stats       2 to 4 tiles: number + short label; bad numbers in the bad color

1  What goes wrong        paragraph + flow diagram
2  Real example           paragraph + facts list + sequence diagram + shortened evidence + query to find it again
3  Why it happens         cause cards (where · title · one or two sentences)
4  The fix                one-sentence principle + target diagram + before/after code pair
5  Steps                  numbered cards: bold action + one muted detail line

footer      links + "Data checked <where>, <date>"
```

Adapt section titles to the topic, keep the arc: what, proof, why, fix, how to ship. Drop a section that has nothing real in it. Never pad one.

Section titles are plain phrases a reader would say aloud: "What goes wrong", "Why the account is not found", "The fix", "Release steps".

## Visual rules

1. Every section is one short paragraph plus one visual. Visual choices: Mermaid flowchart, Mermaid sequence, facts list (`dl.facts`), cause cards, before/after code, step cards.
2. Diagrams use 3 to 6 nodes. Node labels are short plain phrases with `<br/>` breaks. Color nodes by role with `classDef`: `step`, `ext`, `good`, `bad`.
3. Use the same diagram shape for the problem and the fix so the reader sees what changed.
4. Evidence is real: timestamps, ids, counts, a shortened log, and the query that finds it again. Mark shortened content as "(shortened)". Mask personal data.
5. Code pairs show only the lines that change, with one comment per step. Highlight the failing line with `.bad` and the new line with `.ok`.
6. Colors: one accent, one bad color, their soft tints, neutral surface and line. No other hues.
7. Type: Rubik for h1, h2, h3, stat numbers and step titles. Literata for body text. JetBrains Mono for eyebrows, numbers in labels, code and facts. h1 weight 800.
8. One column, max 860px, 40px between sections. Works at phone width with no horizontal scroll.

## Pre-publish check

1. Read only the h1, lede and stats. Does the reader know what broke and how bad it is?
2. Read only the section titles. Do they tell the story in order?
3. Any sentence over 20 words? Split it.
4. Any paragraph without a visual next to it? Add one or merge it.
5. Any claim without a number, id or link behind it? Add the evidence or cut the claim.
6. `grep -n "—"` on the file returns nothing.
