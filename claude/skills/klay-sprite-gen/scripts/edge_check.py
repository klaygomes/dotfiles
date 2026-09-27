"""Zoomed edge review for an RGBA frame or an alpha video.

Writes one image: the busiest edge region, nearest-neighbour zoomed, over white, black and magenta.
Dark rims on white, light rims on black, or green anywhere mean the matte will alias on the site.
Also prints `key_spill`: % of semi-transparent edge pixels tinted toward the key colour. The clean
lightbulb gag measured <= 0.5%; the same clip green-fringed by a straight-alpha resize measured ~50%.
"""
import argparse
import subprocess
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

BACKGROUNDS = [(255, 255, 255), (0, 0, 0), (255, 0, 255)]


def load(path, frame):
    if path.suffix.lower() in (".png", ".webp"):
        return Image.open(path).convert("RGBA")
    decoder = ["-c:v", "libvpx-vp9"] if path.suffix.lower() == ".webm" else []
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "f.png"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", *decoder, "-i", str(path),
                        "-vf", f"select=eq(n\\,{frame})", "-frames:v", "1", "-pix_fmt", "rgba", str(out)], check=True)
        return Image.open(out).convert("RGBA").copy()


def box(channel, size):
    r = max(1, size // 2)
    padded = np.pad(channel.astype(np.float64), r, mode="edge")
    c = np.pad(padded.cumsum(0).cumsum(1), ((1, 0), (1, 0)))
    k = 2 * r + 1
    h, w = channel.shape
    return (c[k:k + h, k:k + w] - c[:h, k:k + w] - c[k:k + h, :w] + c[:h, :w]) / (k * k)


def spill(img):
    """% of semi-transparent edge pixels tinted toward the key colour (green or magenta)."""
    a = np.asarray(img, dtype=np.float32)
    r, g, b, alpha = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    edge = (alpha > 16) & (alpha < 240)
    if not edge.any():
        return 0.0
    green = g - np.maximum(r, b)
    magenta = np.minimum(r, b) - g
    tinted = (green > 24) | (magenta > 24)
    return float(tinted[edge].mean() * 100)


def busiest_window(img, size):
    alpha = np.asarray(img)[..., 3]
    partial = ((alpha > 0) & (alpha < 255)).astype(np.float32)
    score = box(partial, size)
    y, x = np.unravel_index(np.argmax(score), score.shape)
    x0 = int(np.clip(x - size // 2, 0, max(img.width - size, 0)))
    y0 = int(np.clip(y - size // 2, 0, max(img.height - size, 0)))
    return (x0, y0, x0 + size, y0 + size)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src", type=Path, help="RGBA .png/.webp, or .webm/.mp4")
    ap.add_argument("out", type=Path, help="review png to write")
    ap.add_argument("--frame", type=int, default=60, help="video frame index")
    ap.add_argument("--crop", type=int, default=64, help="crop size in px")
    ap.add_argument("--zoom", type=int, default=5)
    args = ap.parse_args()

    img = load(args.src, args.frame)
    box = busiest_window(img, min(args.crop, img.width, img.height))
    crop = img.crop(box)
    tiles = []
    for bg in BACKGROUNDS:
        tile = Image.alpha_composite(Image.new("RGBA", crop.size, bg + (255,)), crop)
        tiles.append(tile.resize((crop.width * args.zoom, crop.height * args.zoom), Image.Resampling.NEAREST))
    sheet = Image.new("RGB", (sum(t.width for t in tiles) + 8 * (len(tiles) - 1), tiles[0].height), (128, 128, 128))
    x = 0
    for t in tiles:
        sheet.paste(t.convert("RGB"), (x, 0))
        x += t.width + 8
    sheet.save(args.out)
    print(f"{args.out}  crop={box}  key_spill={spill(img):.1f}% of edge pixels")


if __name__ == "__main__":
    main()
