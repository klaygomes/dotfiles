# Prompting Grok Imagine for keyable clips

The clip is only usable if the background can be keyed out and the subject stays on the canvas. Everything below serves that.

## Opening sentence (always)

> Locked-off static camera, no zoom, no pan. Keep the exact same <subject details: face, clothes, accessories>. The background stays a flat, solid pure green (#00FF00) for the whole clip, no shadows, no gradients, no text.

- Camera motion breaks the loop back to the still and makes the subject drift off the canvas.
- Naming the subject's details stops the model from redesigning the character mid-clip.
- Shadows and gradients on the green become holes or halos after keying.

## Motion paragraph

Describe the action as a short beat sequence: start pose, the gag, the return. When `animate.sh` pins the last frame (default), end with "...returns to exactly the original pose, ending on the same frame he started from." so the clip hands off seamlessly to the static image.

Keep added objects (a lightbulb, sparkles) inside the canvas; use `--shape tall` for anything above the head, `wide` for sideways actions.

## References

Each `--reference ref.png` is addressed in the prompt as `<IMAGE_0>`, `<IMAGE_1>` in order. Use them to pin a prop's look ("the lightbulb looks like <IMAGE_0>").

## Worked example (estacouveflor.com footer lightbulb, 2026-09-27)

```
Locked-off static camera, no zoom, no pan. Keep the exact same man, face, glasses, patterned short-sleeve shirt and wristwatch. The background stays a flat, solid pure green (#00FF00) for the whole clip, no shadows, no gradients, no text.
He starts in this exact thinking pose, hand on his chin, looking up. After a beat, a glowing cartoon lightbulb pops into existence in the empty space just above his head with a small sparkle. His eyebrows lift and his eyes widen in an "I've got it!" moment; he takes his hand off his chin, snaps his fingers and points up at the lightbulb with a big grin. The lightbulb then fades away and he calmly returns to exactly the original thinking pose, hand back on his chin, looking up, ending on the same frame he started from.
```
Result: 720x960, 24fps, 121 frames, shipped at 300px wide.
