# Verification

Review the lesson four ways. Each must teach the same correct mental model.

| View | How | Pass when |
|---|---|---|
| Prose only | read `1-prose.md` alone | the bug is fixed and the objective met without any picture |
| Diagram only | look at `2-diagram.html` with no caption, in grayscale | the main relationship can be stated |
| Page without animation | open `3-page.html` with reduced motion on | both lab acts still show cause and effect |
| Video without sound, then sound without video | watch `4-video/final.mp4` muted, then listen with the picture hidden | each half carries the story on its own |

For each view, write the model it teaches in one sentence, then compare the four.

## Inconsistencies to hunt

- A term with two names, or two terms for one thing. Grep every rung for the synonyms on the teacher's sheet, including SVG labels, alt text, canvas text and the narration.
- An arrow, state, step or number that exists in one form and not another.
- A different example, different numbers, or a cause that flips direction.
- The misconception shown as true anywhere.
- A term defined differently from the series glossary.

Fix each at the earliest rung that has it, then regenerate the rungs above it.

## Judges

Use subagents with no context as judges, never yourself alone. Give each only the artifact and the audience description:

1. **Fresh reader** on the prose (stage 1 gate).
2. **Diagram reader** on `2-diagram.html` rendered in grayscale, with no caption: states the main relationship, or says what it cannot read.
3. **Learner** on the local `3-page.html` before publishing, driven in a browser: lost, bored, broken.
4. **Viewer** on the video's contact sheet and narration.

Report every finding and what you did about it.

## Accessibility notes to deliver

Alt text for the diagram, keyboard path through both lab acts, focus order, reduced-motion behaviour, audio controls and level, captions file, label contrast.
