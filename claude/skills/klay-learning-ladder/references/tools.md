# Upstream tools

`scripts/ensure.sh` puts each repo at a pinned commit under `~/.local/share/klay-learning-ladder`. Read the named file when you reach the stage, not before.

| Stage | Tool | Read first | Use it for |
|---|---|---|---|
| 2 | [diagram-design](https://github.com/cathrynlavery/diagram-design) (MIT) | `$DIAGRAM_SKILL/SKILL.md`, then the `references/` file it names for the chosen type | picking the diagram type, editorial SVG, `self_check.py` (in the skill) and `verify-geometry.py` (in the repo root `scripts/`), PNG/SVG export |
| 3 | [iwrzwr visual archive](https://github.com/kaganin/iwrzwr-visual-archive) (MIT) | `dist/catalog.json` (groups and study names), then the study's source under `sources/` | drawing and motion code to adapt for the one interaction: waveforms, particles, mechanical motion, rhythm, memory |
| 3 | [img2threejs](https://github.com/img2threejs/img2threejs) (Apache-2.0) | `SKILL.md` | a procedural Three.js model, only when the idea is a physical object the learner must rotate to understand |
| 4 | [motionmaxxing](https://github.com/Tejashmakwana/motionmaxxing) (Apache-2.0) | `SKILL.md`, `references/director.md`, `references/sound-sync.md` sections 3 to 6 | storyboard, GSAP film page, `render.mjs`, `look.py` gates, `mix.py` |
| 4 | [awesome-claude-video-skills](https://github.com/zhuyansen/awesome-claude-video-skills) | the README "Explainers" table | a different renderer when motionmaxxing does not fit (see below) |

## iwrzwr catalog

`catalog.json` labels are in Turkish. The study names are in English, so search by name (`Delay Vernier`, `Orbit Register`):

```bash
python3 -c "import json; [print(g['id'], '|', ', '.join(g['names'])) for g in json.load(open('$IWRZWR_VISUAL_ARCHIVE/dist/catalog.json'))]"
grep -l "Sample Hold Ladder" "$IWRZWR_VISUAL_ARCHIVE"/sources/*.html
```

Read the study in `sources/<series>.html`: it is the unminified file. Each study is one small function (`hold(time)`, `relay(time)`) over shared helpers (`line`, `rect`, `box`). The useful parts to adapt: 1px canvas strokes snapped to the device pixel ratio, a 30 fps loop that stops off screen, a pause under reduced motion, and the study's visual grammar. Copy the drawing code into the page. Do not link to the archive, because the page must be self-contained. Keep the MIT notice in the page source and credit the study in the footer.

Studies that fit common lessons: `Sample Hold Ladder` (sampling, quantization), `Phase Aperture` and `Delay Vernier` (phase, delay), `Spectrum Ribbon` and `Fine Spectrum` (frequency content), `Coupled Nodes` and `Causal Relay` (cause and effect, state), `Rank Sieve` (sorting, selection).

## Choosing another video tool

The voice is always `agent-voice`. Ignore motionmaxxing's ElevenLabs steps, its `voice.py`, and the fallbacks in `sound-sync.md` section 9. In motionmaxxing's docs, `$SKILL` means `$MOTIONMAXXING`.

Stay with motionmaxxing unless the topic needs one of these. The list grades each repo's security. Pick only repos marked SAFE, and read their install script before running it.

- **Math or proofs:** `adithya-s-k/manim_skill` (Manim, 3Blue1Brown style).

## Bumping a pin

```bash
gh api repos/<owner>/<repo>/commits/HEAD -q .sha
```

Read the upstream diff between the old and new commit, then put the new SHA in `REPOS` in `scripts/ensure.sh`. The next run refetches it. The pins exist so that no upstream change reaches a run without someone reading it first.
