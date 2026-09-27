"""Anti-aliased matte for keyed RGBA frames, ready for alpha video/WebP encoding.

Per frame:
  1. feather   soften the keyed matte's stair-stepped edge (premultiplied gaussian, source resolution).
               sprite-gen's matte is nearly binary, so at native size the edge would alias. A downscale
               of 1.5x or more already averages the steps, so `auto` skips it there.
  2. resize    downscale in premultiplied space (Pillow does this for RGBA). A straight-alpha resize,
               like ffmpeg's scale filter, mixes the colour hidden under transparent pixels into the edge:
               with green hidden there it measured 2% of edge pixels visibly green-fringed.
               Bicubic: close to Lanczos on edge accuracy, less overshoot ringing at the alpha edge,
               ~30% smaller VP9 at the same CRF.
  3. clean     set RGB under fully transparent pixels to black. Encoders subsample chroma 2x2, so hidden
               colour bleeds into edge pixels; black carries no chroma, and flat black costs no bitrate.
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image

RESAMPLE = {
    "bicubic": Image.Resampling.BICUBIC,
    "lanczos": Image.Resampling.LANCZOS,
    "bilinear": Image.Resampling.BILINEAR,
}


def blur(channel, sigma):
    radius = max(1, int(np.ceil(3 * sigma)))
    offsets = np.arange(-radius, radius + 1)
    kernel = np.exp(-(offsets ** 2) / (2 * sigma * sigma))
    kernel /= kernel.sum()
    out = channel
    for axis in (0, 1):
        padded = np.pad(out, [(radius, radius) if a == axis else (0, 0) for a in (0, 1)], mode="edge")
        n = out.shape[axis]
        acc = np.zeros_like(out)
        for i, k in enumerate(kernel):
            acc += k * np.take(padded, np.arange(i, i + n), axis=axis)
        out = acc
    return out


def feather(rgba, sigma):
    if sigma <= 0:
        return rgba
    alpha = rgba[..., 3] / 255.0
    new_alpha = blur(alpha, sigma)
    safe = np.maximum(new_alpha, 1e-6)
    rgb = np.stack([blur(rgba[..., c] * alpha, sigma) / safe for c in range(3)], axis=-1)
    return np.dstack([rgb, new_alpha * 255.0])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src", type=Path, help="dir of keyed RGBA pngs")
    ap.add_argument("dst", type=Path, help="output dir (0000.png, 0001.png, ...)")
    ap.add_argument("--width", type=int, help="output width in px; downscale only")
    ap.add_argument("--feather", default="auto", help="edge feather sigma in source px, 0 = off, auto = 0.9 unless downscaling >= 1.5x")
    ap.add_argument("--resample", choices=RESAMPLE, default="bicubic")
    args = ap.parse_args()

    frames = sorted(args.src.glob("*.png"))
    if not frames:
        raise SystemExit(f"no png frames in {args.src}")
    args.dst.mkdir(parents=True, exist_ok=True)

    src_w = Image.open(frames[0]).width
    if args.width and args.width > src_w:
        raise SystemExit(f"refusing to upscale {src_w} -> {args.width}px; encode at native size")
    ratio = src_w / args.width if args.width else 1.0
    size = Image.open(frames[0]).size
    w, h = (args.width, round(size[1] / ratio)) if args.width else size
    w, h = w - w % 2, h - h % 2
    sigma = (0.9 if ratio < 1.5 else 0.0) if args.feather == "auto" else float(args.feather)

    for i, path in enumerate(frames):
        rgba = feather(np.asarray(Image.open(path).convert("RGBA"), dtype=np.float32), sigma)
        img = Image.fromarray(rgba.clip(0, 255).round().astype(np.uint8), "RGBA")
        if args.width:
            img = img.resize((args.width, round(img.height / ratio)), RESAMPLE[args.resample])
        out = np.array(img)
        out[out[..., 3] == 0, :3] = 0
        Image.fromarray(out[:h, :w], "RGBA").save(args.dst / f"{i:04d}.png")

    print(f"matted {len(frames)} frames -> {args.dst} ({w}x{h}, feather {sigma}, {args.resample})")


if __name__ == "__main__":
    main()
