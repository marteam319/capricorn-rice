#!/usr/bin/env python3
"""Glitch frames for the animated Capricorn wallpaper plugin."""
import os
import numpy as np
from PIL import Image, ImageDraw

SRC = "/home/marteam/.local/share/wallpapers/capricorn-character.png"
OUT = os.path.expanduser("~/.local/share/plasma/wallpapers/com.capricorn.glitch/contents/ui/frames")
N = 4
rng = np.random.default_rng(2077)

base = Image.open(SRC).convert("RGB")
w, h = base.size

for i in range(N):
    im = base.copy()
    if i > 0:
        a = np.array(im)
        # horizontal tearing
        for _ in range(7):
            y = int(rng.uniform(0, h - 40))
            hh = int(rng.uniform(4, 46))
            shift = int(rng.uniform(-70, 70))
            a[y:y + hh] = np.roll(a[y:y + hh], shift, axis=1)
        im = Image.fromarray(a)
        # chromatic split on a couple of bands
        for _ in range(3):
            y = int(rng.uniform(0, h - 80))
            hh = int(rng.uniform(12, 70))
            band = im.crop((0, y, w, y + hh))
            r, g, b = band.split()
            r = r.point(lambda v: v)
            im.paste(Image.merge("RGB", (r, g, b)).transform(
                (w, hh), Image.AFFINE, (1, 0, rng.uniform(-14, 14), 0, 1, 0)), (0, y))
        # flicker
        f = rng.uniform(0.9, 1.08)
        im = Image.eval(im, lambda v: int(min(255, v * f)))
        # colour flash bars
        d = ImageDraw.Draw(im, "RGBA")
        for _ in range(2):
            y = int(rng.uniform(0, h - 20))
            hh = int(rng.uniform(2, 8))
            col = (13, 255, 110, 40) if rng.random() < 0.5 else (177, 76, 255, 40)
            d.rectangle([0, y, w, y + hh], fill=col)
    im.save(os.path.join(OUT, f"frame{i}.png"))
    print("frame", i)
