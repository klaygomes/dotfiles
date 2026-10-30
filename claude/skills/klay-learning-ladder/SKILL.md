---
name: klay-learning-ladder
description: 'Turns a topic into a deep, story-driven lesson built as four representations that each must improve understanding: the lesson prose in a natural teacher-storyteller voice, one diagram, a 15-20 minute interactive page where the learner fixes a bug with their own hands, and a 2-3 minute narrated explainer video, then cross-checks that all four teach the same mental model. Lessons from one source form a series with one story world. Uses diagram-design for the diagram, its own lesson style plus the iwrzwr visual archive for the page, motionmaxxing for the film and agent-voice (local OmniVoice) for the narration. Use when the user asks to teach, explain, or make a lesson, explainer, tutorial, course, learning page, or explainer video about a topic (a concept, a paper, a book or a chapter), asks for "the next topic" or "the next lesson" in a series, or asks for "the learning ladder" on something. Also when asked for only the prose, only the diagram, only the page, or only the video of an explanation.'
---

# Learning ladder

Turn `TOPIC` into a lesson for `AUDIENCE`. Each rung is a new representation of the same idea: prose, then diagram, then interactive page, then video. A rung exists only if it improves understanding.

Role: teacher, storyteller, information designer, motion director, creative technologist. Explain hard ideas through visible cause and effect. Concrete before abstract. When details are missing, make the call, write it down as an assumption, and keep going.

The output is for a learner, not a stakeholder. Never use `klay-artifact-style` on any rung, even though the global rules say every Artifact uses it. Every rung uses `assets/lesson.css`.

## The voice of every lesson

Write like a good teacher talking to one curious person: a natural voice with a storyteller's playfulness, the way Karpathy builds things live or 3Blue1Brown asks "but why?". Talk to the reader, vary the rhythm, ask before you tell, admit what is surprising, play lightly. Never controlled English or ASD-STE100: strings of one-fact sentences read like a manual. Keep the rigor: one term for one thing, every term defined before use, real numbers before rules. `references/writing.md` has the full rules and gates.

## Code the lesson produces

Pages, films and scripts are code: self-documenting, with no comments. No section banners (`/* S1 HOOK */`), no restating what a line does, no journal notes. Keep only a license notice the source requires (the iwrzwr MIT attribution) and one-line notes for a constraint the syntax cannot express. The motionmaxxing film template ships with guide comments: delete them when you fill it in.

## Series and story

Lessons from one source form a series in `~/personal/lessons/<series>/`, with one story world in `series.md` (`references/series.md`). Read it first, update it last. Every lesson opens on a bug in that world, and ends when the learner fixes it in the lab.

One lesson teaches one idea, deeply. When the topic is bigger (a book, a course), pick its central idea, say which one in the first line to the user, and record the rest as next bugs in `series.md`. Do not ask before starting.

## Modes

- **Full ladder** (default): all four rungs, then verification.
- **One rung**: when the user names one. Write the prose and the sheet first anyway.

## Setup

```bash
scripts/ensure.sh
```

Run it by its absolute path in this folder. It clones the upstream tools at pinned commits into `~/.local/share/klay-learning-ladder`, installs Temml for math, and prints the paths (`LADDER_SKILL`, `DIAGRAM_DESIGN`, `DIAGRAM_SKILL`, `MOTIONMAXXING`, `IWRZWR_VISUAL_ARCHIVE`, `IMG2THREEJS`, `AGENT_VOICE`). `$LADDER_SKILL` is this folder. In motionmaxxing's own docs, `$SKILL` means `$MOTIONMAXXING`.

Then run `agent-voice doctor`. Stages 1 and 4 need it. If `ready` is false, tell the user `download_gb` and ask once, here. If they decline: stage 1 reads the prose aloud by hand, and stage 4 stops at the storyboard. There is no fallback voice. `references/tools.md` says which upstream file to read at which stage, and how to bump a pin.

Work in `~/personal/lessons/<series>/<NN>-<lesson-slug>/`. Copy `assets/lesson.css` there. Never delete an attempt with `rm -rf`. A full redo goes to `<NN>-<lesson-slug>-v2/`, and its `series.md` row points there.

## Principles

1. Build it from scratch. Show every idea working, step by step, before you name it.
2. Learning should feel like effort. Make the learner predict before you reveal.
3. Small, verifiable steps. Generate, then judge, in a fast loop. Each rung has a gate.
4. Give the learner an autonomy slider, from guided to free exploration.
5. Each step gets exactly the information it needs.
6. The teacher designs the course. The tools help each learner through it.
7. Your own judgment is not enough. Subagents with no context judge every rung.

## Stage 1: prose and teacher's sheet

Follow `references/writing.md`. Write `1-prose.md`, the full lesson text (15 to 20 minutes, two worked examples, the derivation), and `1-sheet.md`, the teacher's sheet the learner never sees (objective, bug and fix, key words, terms, misconception, next bug).

**Gate:** read-aloud pass with `agent-voice`, then a fresh-reader subagent. Then **stop and show the user the prose and the sheet** before building anything else.

## Stage 2: diagram

Read `$DIAGRAM_SKILL/SKILL.md` and follow it. For its style-guide gate, choose "paste tokens" with the colors from `assets/lesson.css`. Typography: Instrument Serif for the title and callouts, Geist for names, Geist Mono for labels. Never JetBrains Mono. Pick the one type that fits, or a custom figure on its primitives when the idea is geometric (say which, and why).

- One reading direction. At most seven primary elements. Every arrow has one stated meaning.
- Labels work without narration and read in grayscale. Separate series by line style as well as color.

```bash
python3 -I "$DIAGRAM_SKILL/scripts/self_check.py" 2-diagram.html
python3 -I "$DIAGRAM_DESIGN/scripts/verify-geometry.py" 2-diagram.html
```

Render it once in each theme and look for label masks hiding chart lines, which the geometry check misses.

**Gate:** the diagram reader judge (`verification.md`) states the main relationship after one look.

## Stage 3: interactive page

Follow `references/page.md`: the prose's order, the two-act lab (explore, then fix the bug), sound or images the learner can perceive when the topic is perceptible, MathML math via `scripts/math.mjs`, the color jobs. Load `artifact-design` for the page contract only. For drawing code, adapt a study from the iwrzwr archive. Use img2threejs only for a physical object the learner must see in 3D.

**Gate:** the checks at the end of `references/page.md`, including the learner judge. Publish with `lesson.css` alongside. Store the page link in `series.md` right after the first publish. The rest of `series.md` is updated at delivery.

## Stage 4: explainer video

Follow `references/video.md`: 2 to 3 minutes, the story arc only, narration cut from the prose and voiced with `agent-voice script` (one passage per scene, natural speed, pauses by meaning). If the user declined the model download at setup, stop at the storyboard.

**Gate:** G0, G2 and G3 pass, G1 and G4 pass by eye, every G5 flag is fixed or justified, and the viewer judge has read the sheet. Quote the numbers.

## Verification

Follow `references/verification.md`: four views, one mental model, judges with no context. Fix each inconsistency at the earliest rung that has it.

## Delivery

**Stop and show the user** the published page and the video. Then report: the page link, every file as a full path, the storyboard, the narration and voice, motion and sound notes, accessibility notes, export specs, judge findings and what changed, sources and asset licenses. Update `series.md`: the lesson row, new glossary terms, the next bug.
