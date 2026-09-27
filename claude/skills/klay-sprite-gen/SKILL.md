---
name: klay-sprite-gen
description: Make animated sprites, sprite sheets, and transparent looping video clips (site mascots, hero animations, footer gags, game character states) from a still image using aldegad/sprite-gen and Grok Imagine, with bundled scripts for install, generation, chroma keying, and web encoding (alpha WebM + Safari HEVC + WebP poster). Use this whenever the user wants to animate a photo, illustration, or character, add a moving mascot or easter egg to a website, produce a transparent video or sprite atlas, or mentions sprite-gen or Grok Imagine, even if they do not name the tool.
---

# sprite-gen

All steps are scripts in `scripts/` (relative to this skill; `~/.claude/skills/klay-sprite-gen/scripts`). Call them instead of hand-writing ffmpeg or sprite-gen commands: they encode choices that were already tuned (green key, loop-back last frame, 0.9px feather, alpha codecs) and they are idempotent.

## Setup is automatic

Every script runs `ensure.sh` first. The first run clones sprite-gen into `~/.local/share/sprite-gen` and builds its venv (~15s); later runs cost ~0.2s and pull upstream at most weekly (`ensure.sh --update` forces it). Missing system tools (`ffmpeg`, `cwebp`, python ≥ 3.11) are named in the error.

`scripts/sg` is the sprite-gen CLI with `XAI_API_KEY` loaded from `~/personal/klaygomes.github.io/.env` (override with `SPRITE_GEN_ENV`). Use it for any sprite-gen command; it never prints the key, so do not echo it yourself either. Only the Grok provider is available (no codex).

## Before starting

Run `scripts/notes.sh` and read the learnings from past runs: prompts that worked, keying flags that fixed a subject, sizes that shipped. Work in the session scratchpad under a folder named after the asset; copy only final files into the project.

## Still → transparent clip (the common case)

1. **Prompt.** Write `prompt.txt` following `references/prompting.md` (locked camera, flat #00FF00, return to the start pose). Read it the first time in a session; the rules there are what make a clip keyable.
2. **Generate + key.**
   ```bash
   scripts/animate.sh --still mascot.png --prompt-file prompt.txt --out-dir <scratch>/mascot [--shape tall] [--reference prop.png]
   ```
   Generation is a paid Grok call (~1 min). The script skips steps whose outputs exist, so rerunning to retry keying costs nothing; delete `clip.mp4` to regenerate the video. Without `--shape` the canvas hugs the subject (right when the motion stays in place); pass `--shape tall|wide|square` when the motion needs room, e.g. a prop appearing above the head. `--no-return` drops the loop-back to the still.
3. **Review.** Read `<out-dir>/contact.png`. Look for a redesigned face, subject leaving the frame, green halos, or holes in the subject. A bad take is cheaper to regenerate than to fix. If keying ate parts of the subject, rerun with `--gentle-key`.
4. **Encode.**
   ```bash
   scripts/encode.sh --frames <out-dir>/frames/keyed --out-dir <project>/img --name mascot --width 300
   ```
   Produces `mascot.webm`, `mascot.mp4`, `mascot.webp`. `--width` is the display width in CSS pixels; the script refuses to upscale because upscaled mattes look jagged on retina. Other knobs: `--fps`, `--crf`, `--feather`, `--poster-frame`.
5. **Embed.** Follow `references/embedding.md` for markup, play-once rules, and why Playwright (not Claude-in-Chrome) is the way to verify.

## Anything else

Atlases, seamless loops, batches, cutouts, recolors: see `references/other-pipelines.md` for which sprite-gen command and upstream doc to use. Helpers that work standalone: `scripts/contact_sheet.sh <frames-dir|clip> out.png`, `scripts/py` (python with Pillow/NumPy from the venv).

## After finishing

Record what a future run should know, one line each:
```bash
scripts/notes.sh add "hero wave: --shape tall needed, arm clipped on square; shipped 280px, webm 90KB"
```
Worth saving: the final prompt's key phrasing, flags that rescued a take, rejected takes and why, cost or time surprises. Skip anything already in this skill.
