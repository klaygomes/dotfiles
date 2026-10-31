# Stage 3: the page

The page is the prose from stage 1, laid out for a learner, with the lab where the prose says "try it". It is not a stakeholder memo: never use `klay-artifact-style`. Use `assets/lesson.css`, which holds the palette, the type and the components.

Load `artifact-design` for the page contract only: no doctype of your own, a short `<title>`, theme tokens, a 16px gutter. Its house-style rules do not apply.

The page takes 15 to 20 minutes: the prose's length plus the two lab acts.

Load the fonts at the top of the page, or `lesson.css` falls back to system faces:

```html
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Geist:wght@400;500;600&family=Geist+Mono:wght@400;500&display=swap">
<link rel="stylesheet" href="lesson.css">
```

## Order

The prose's order (`writing.md`) is the page's order. The lab appears twice, as two acts of one tool:

| Prose section | On the page |
|---|---|
| The bug | header: topic line, title, the bug as the opening question |
| Worked example 1 | a `table.alt` or `ol.steps` the reader follows sample by sample |
| Lab act 1: explore | the lab, open on the bug's case: predict, reveal, slider, pin and compare |
| The rule | the stage 2 diagram, inline SVG |
| (optional) The machine | an anatomy figure, where the prose first shows the mechanism at work; inline its built SVG and live script |
| Worked example 2 | second table, where the first rule is not enough |
| The derivation | MathML formulas, one step per line, each with its plain sentence |
| Deeper idea | prose with a small inline figure if it needs one |
| Lab act 2: fix the bug | the same lab in challenge mode |
| What people get wrong | `.myth` block |
| Recap and next bug | `ol.steps` and a last line with the cliffhanger |

## The lab

One `.lab` element, reused by both acts, so the reader learns one tool.

**Act 1, explore.** The input is locked until the reader predicts. The answer comes with a "Right." or "Not X." and one sentence of why. Then the slider moves one real input from its minimum to its maximum, and the readout explains each region (below a limit, at it, above it, at the extreme). "Pin this" draws the frozen state dashed in `--input` and compares it to the current one.

**Act 2, fix the bug.** A button "Fix the bug" reframes the lab: a new case from the story (for example "the whine moved to a random frequency"), and the reader moves the control that fixes it. Every wrong try gets specific feedback that names the error in the reader's terms ("that zero removes 3,000 Hz; the whine is 1,000 Hz lower"). Success plays the story's ending in the readout. Give a new case on "Try another". Scale every percentage in a challenge against the filter's loudest tone, never against a reference tone the reader is not watching: "compared with 0 Hz" made a zero pair near 0 Hz show "241%". Show "unstable" instead of numbers when the filter is unstable.

**When the topic is perceptible, let the reader perceive it.** If the lesson is about sound, a "Play" button plays it through the lab's current state. Run the lesson's own difference equation in JavaScript, at the lesson's sample rate, then play the result from an `AudioBuffer` created at that rate. Do not use `IIRFilterNode`: it runs at the device's rate (usually 48 kHz), which moves every zero and pole to the wrong pitch. Re-render when a control changes and restart at the same offset. Start audio only on a click, cap the gain at about 0.3, refuse to play an unstable filter, and offer "Stop" and a filter on/off switch. Embed short clips (a sentence from `agent-voice speak`, resampled to the lesson's rate, under 150 KB) as base64, and parse the WAV PCM yourself so the browser does not resample it. For images, show the image the lab transforms.

Drawing: adapt a study from the iwrzwr archive (`tools.md`). Read colors from the CSS tokens at runtime, redraw on theme change, run at most 30 fps, stop when off screen. With reduced motion or "Pause", draw the finished state at once. The lesson still teaches then.

## Colors

| Token | Job |
|---|---|
| `--ink`, `--paper` | everything by default |
| `--input` (teal) | what the reader controls: sliders, draggable points, pressed buttons, pinned state |
| `--accent` (coral) | the result to notice: the removed tone, the changed output, the zero |
| `--ink-soft` | context: the true signal, captions, axes |

## Math

Write the page as `3-page.src.html`, with formulas as `\( ... \)` inline and `\[ ... \]` for display. Build `3-page.html` from it. Edit only the source:

```bash
node "$LADDER_SKILL/scripts/math.mjs" 3-page.src.html 3-page.html
```

It leaves `<script>` and `<style>` blocks untouched.

The output is native MathML. It needs no runtime library and renders in Chrome, Safari and Firefox. Style it with `math { font-size: 1.05em; }` and give display math `overflow-x: auto`.

## Delivering

The page lives in the lesson folder and ships with the repository: `3-page/3-page.html` beside `lesson.css`. Do not publish an Artifact unless the user asks for one.

## Checks before delivering

1. The page script parses (`node -e` on the inline script). `math.mjs` reports 0 failed.
2. Drive the lab in a browser: every prediction, the minimum, a typical value, each boundary, the maximum, pin with a match and with a mismatch, three resets in a row, act 2 with a wrong try and a right one, "Try another".
3. If there is sound: play, change a control while playing, stop, play again.
4. Phone width: headless Chrome cannot go below a 500px viewport, so compare `document.documentElement.scrollWidth` with `innerWidth` instead of trusting a cropped screenshot. Check that canvas labels are not clipped at the edges.
5. `grep -n "—"` returns nothing.
6. A learner judge (`verification.md`) opens the local `3-page.html` before you deliver, and reports what confused it, bored it, or did not work. Fix what it finds.
