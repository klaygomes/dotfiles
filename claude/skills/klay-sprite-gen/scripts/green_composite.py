import sys
from PIL import Image

if len(sys.argv) != 3:
    sys.exit("usage: green_composite.py <still-rgba.png> <out-green.png>")

still = Image.open(sys.argv[1]).convert("RGBA")
green = Image.new("RGBA", still.size, (0, 255, 0, 255))
Image.alpha_composite(green, still).convert("RGB").save(sys.argv[2])
