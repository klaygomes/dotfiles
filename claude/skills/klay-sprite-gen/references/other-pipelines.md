# Other sprite-gen pipelines

The upstream checkout (`$SPRITE_GEN_HOME`, default `~/.local/share/sprite-gen`) has its own `SKILL.md` and `docs/`. Read the doc named here before running an unfamiliar command; `scripts/sg <tool> --help` lists flags.

| Goal | Commands | Doc |
|---|---|---|
| Not sure which path fits | `sg workflow` | `docs/user-workflow.md` |
| Game sprite atlas rows | `prepare → gen / gen-set → extract → compose-atlas` | `docs/run-contract.md`, `docs/atlas-workflow.md` |
| Seamless looping cycle (idle, walk) | `animate.sh`, then `sg video-loop` on the keyed frames | `docs/seamless-video-loop.md` |
| Many directions × states | `sg video-set` | `docs/video-pipeline.md` |
| Longer clip / edit a clip | `sg video-extend`, `sg video-edit` | `docs/video.md` |
| Remove a flat background from an image | `sg cutout` | `docs/sheet-slicing.md` |
| Slice a grid sheet | `sg slice-sheet` | `docs/sheet-slicing.md` |
| Recolor, layers, Aseprite export | `sg recolor`, `compose-layers`, `export-aseprite` | `docs/recolor.md`, `docs/engine-export.md` |
| Keying problems | | `docs/chroma-alpha.md`, `docs/troubleshooting.md` |
