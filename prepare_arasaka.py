#!/usr/bin/env python3
"""Cut the Arasaka enforcer out of his room shot, kill his optics, grade him.

Tight hand-traced silhouette (no reliable key for the teal room), eroded 2px
so no background rim survives, feathered, then black -> red duotone.
"""

import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SRC = "/tmp/opencode/arasaka.png"
OUT = os.path.expanduser("~/Projekty/cyberpunk-capricorn/art/arasaka.png")

# tight trace, no room between body and frame edge
pts = [(172, 50), (252, 45), (298, 70), (312, 118), (318, 170), (330, 195),
       (350, 205), (392, 214), (408, 245), (412, 300), (412, 754), (18, 754),
       (20, 640), (30, 500), (40, 380), (50, 300), (68, 255), (102, 235),
       (142, 214), (149, 172), (153, 128), (159, 88)]

img = Image.open(SRC).convert("RGB")
mask = Image.new("L", img.size, 0)
ImageDraw.Draw(mask).polygon(pts, fill=255)
mask = mask.filter(ImageFilter.MinFilter(5))       # erode ~2px
mask = mask.filter(ImageFilter.GaussianBlur(3))

a = np.array(img).astype(np.float32)
a = np.clip(a * 2.3, 0, 255)   # lift the suit out of the black
lum = (0.299 * a[..., 0] + 0.587 * a[..., 1] + 0.114 * a[..., 2]) / 255.0

stops = [(0.00, (6, 4, 9)), (0.28, (44, 6, 20)), (0.55, (120, 10, 42)),
         (0.78, (186, 16, 64)), (0.92, (238, 26, 92)), (1.00, (255, 140, 180))]
xs = np.array([s[0] for s in stops])
cs = np.array([s[1] for s in stops], dtype=np.float32)
out = np.zeros_like(a)
for c in range(3):
    out[..., c] = np.interp(lum, xs, cs[:, c])

# optics off: crush brightness in the visor region (dead)
yy, xx = np.mgrid[0:img.size[1], 0:img.size[0]]
eye = (((xx - 268) / 62.0) ** 2 + ((yy - 100) / 26.0) ** 2) < 1.0
out[eye] *= 0.22

# patch the room light bar with suit fabric instead of blacking it out
suit = out[380:450, 250:320].reshape(-1, 3).mean(axis=0)
panel = (xx > 330) & (yy > 280) & (yy < 392)
out[panel] = suit
panel2 = (xx > 378) & (yy > 520) & (yy < 754)
out[panel2] = suit * 0.85

out = np.dstack([np.clip(out, 0, 255), np.array(mask)]).astype(np.uint8)
im = Image.fromarray(out, "RGBA").crop((0, 0, 372, 754))
im.save(OUT)
print(OUT)
