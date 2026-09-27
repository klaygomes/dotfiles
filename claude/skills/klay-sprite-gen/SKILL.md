---
name: klay-sprite-gen
description: Make animated sprites, sprite sheets, and transparent looping video clips (site mascots, hero animations, footer gags, game character states) from a still image using aldegad/sprite-gen and Grok Imagine, with bundled scripts for install, generation, chroma keying, and web encoding (alpha WebM + Safari HEVC + WebP poster). Use this whenever the user wants to animate a photo, illustration, or character, add a moving mascot or easter egg to a website, produce a transparent video or sprite atlas, or mentions sprite-gen or Grok Imagine, even if they do not name the tool.
---

# sprite-gen

All steps are scripts in `scripts/` (relative to this skill; `~/.claude/skills/klay-sprite-gen/scripts`). Call them instead of hand-writing ffmpeg or sprite-gen commands: they encode choices that were already tuned (green key, loop-back last frame, alias-free matte, alpha codecs) and they are idempotent.

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
   scripts/encode.sh --frames <out-dir>/frames/keyed --out-dir <project>/img --name mascot --width 600
   ```
   Produces `mascot.webm`, `mascot.mp4`, `mascot.webp`. Other knobs: `--fps`, `--crf`, `--feather`, `--poster-frame`.
5. **Check the edges.** `scripts/py scripts/edge_check.py <project>/img/mascot.webm <scratch>/edge.png`, then Read the image and the printed `key_spill`. See "Transparent edges" below for what to look for.
6. **Embed.** Follow `references/embedding.md` for markup, play-once rules, and why Playwright (not Claude-in-Chrome) is the way to verify.

## Transparent edges

A transparent subject is only as good as its edge: a stair-stepped matte, or a rim of key green or black around the subject, shows up on every background the site uses. `encode.sh` handles this through `scripts/matte.py` (its docstring has the measurements):

- **Resize with premultiplied alpha, never with ffmpeg `scale`.** A straight-alpha resize blends the colour hidden under transparent pixels into the edge; with green hidden there, half the edge pixels came out green-tinted. So do not add `-vf scale` to the encode, and resize any RGBA image with `matte.py` or Pillow.
- **Feather only when the edge is not already averaged.** sprite-gen's matte is nearly binary. At native size or a small downscale it would alias, so `--feather auto` softens it by 0.9px; a 1.5x+ downscale smooths it for free.
- **Pick `--width` as the displayed CSS width x 2**, capped at the source width, so a retina screen draws it 1:1. Much larger and the browser downscales it with bilinear filtering, which re-aliases the edge; smaller and it upscales into blur. The script refuses to upscale.
- **Read `edge_check.py` output before shipping.** It zooms into the busiest edge over white, black and magenta. Clean encodes measured `key_spill` <= 0.5%; a few percent or a visible green, dark or light rim means the key left colour behind: rerun `animate.sh` without `--gentle-key` (it turns decontamination off), or regenerate the take.

## Anything else

Atlases, seamless loops, batches, cutouts, recolors: see `references/other-pipelines.md` for which sprite-gen command and upstream doc to use. Helpers that work standalone: `scripts/contact_sheet.sh <frames-dir|clip> out.png`, `scripts/py` (python with Pillow/NumPy from the venv).

## After finishing

Record what a future run should know, one line each:
```bash
scripts/notes.sh add "hero wave: --shape tall needed, arm clipped on square; shipped 280px, webm 90KB"
```
Worth saving: the final prompt's key phrasing, flags that rescued a take, rejected takes and why, cost or time surprises. Skip anything already in this skill.
