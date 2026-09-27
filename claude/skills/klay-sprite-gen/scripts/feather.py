import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

if len(sys.argv) not in (3, 4):
    sys.exit("usage: feather.py <keyed-dir> <out-dir> [radius=0.9]")

src, dst = Path(sys.argv[1]), Path(sys.argv[2])
radius = float(sys.argv[3]) if len(sys.argv) == 4 else 0.9
dst.mkdir(parents=True, exist_ok=True)


def blur(channel):
    img = Image.fromarray(np.clip(channel, 0, 255).astype(np.uint8))
    return np.asarray(img.filter(ImageFilter.GaussianBlur(radius)), dtype=np.float32)


frames = sorted(src.glob("*.png"))
if not frames:
    sys.exit(f"no png frames in {src}")

for i, path in enumerate(frames):
    rgba = np.asarray(Image.open(path).convert("RGBA"), dtype=np.float32)
    alpha = rgba[..., 3]
    premul = rgba[..., :3] * (alpha[..., None] / 255.0)
    new_alpha = blur(alpha)
    blurred = np.stack([blur(premul[..., c]) for c in range(3)], axis=-1)
    safe = np.maximum(new_alpha, 1e-3)[..., None]
    rgb = np.where(alpha[..., None] > 0, rgba[..., :3], blurred * 255.0 / safe)
    out = np.dstack([rgb, new_alpha]).clip(0, 255).astype(np.uint8)
    Image.fromarray(out, "RGBA").save(dst / f"{i:04d}.png")

print(f"feathered {len(frames)} frames -> {dst}")
