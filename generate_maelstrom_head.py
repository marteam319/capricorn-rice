#!/usr/bin/env python3
"""Procedural Maelstrom-style cybernetic head, transparent PNG.

Front-facing chrome skull: dark plates, red optics, jaw vents, cables, rim light.
Drawn at 2x then downscaled for clean edges.
"""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 2
W, H = 700 * S, 900 * S
OUT = os.path.expanduser("~/Projekty/cyberpunk-capricorn/art/maelstrom-head.png")

DARK = (10, 10, 13)
PLATE = (30, 30, 36)
PLATE_HI = (74, 74, 84)
PLATE_LO = (18, 18, 22)
RED = (255, 28, 58)
RED_DIM = (120, 8, 22)
WIRE = (16, 16, 20)

img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img)


def poly(pts, fill):
    d.polygon([(x * S, y * S) for x, y in pts], fill=fill)


# ── shoulders + neck ─────────────────────────────────────────────────
poly([(40, 900), (660, 900), (610, 760), (470, 700), (230, 700), (90, 760)], DARK)
poly([(230, 700), (470, 700), (500, 640), (200, 640)], (14, 14, 18))
# neck cables
for i in range(4):
    x = 250 + i * 55
    d.line([(x * S, 700 * S), ((x - 10) * S, 640 * S)], fill=WIRE, width=10 * S)

# ── skull silhouette ─────────────────────────────────────────────────
skull = [(180, 250), (200, 150), (300, 95), (400, 95), (500, 150), (520, 250),
         (515, 380), (490, 470), (450, 540), (430, 640), (270, 640), (250, 540),
         (210, 470), (185, 380)]
poly(skull, DARK)
# jaw
poly([(250, 540), (450, 540), (470, 660), (430, 700), (270, 700), (230, 660)], (16, 16, 20))

# ── chrome plates ────────────────────────────────────────────────────
poly([(205, 250), (300, 200), (400, 200), (495, 250), (480, 300), (220, 300)], PLATE)
poly([(220, 300), (480, 300), (470, 345), (230, 345)], PLATE_LO)
poly([(210, 350), (290, 330), (300, 470), (245, 500), (215, 440)], PLATE)
poly([(490, 350), (410, 330), (400, 470), (455, 500), (485, 440)], PLATE)
poly([(250, 545), (450, 545), (455, 640), (245, 640)], (22, 22, 27))
# jaw vents
for i in range(3):
    y = 570 + i * 22
    d.rounded_rectangle([300 * S, y * S, 400 * S, (y + 8) * S], radius=4 * S,
                        fill=(8, 8, 10))
# cheek highlights
poly([(230, 360), (285, 345), (290, 360), (235, 375)], PLATE_HI)
poly([(470, 360), (415, 345), (410, 360), (465, 375)], PLATE_HI)

# ── optics ───────────────────────────────────────────────────────────
for cx in (295, 405):
    d.ellipse([(cx - 42) * S, (395 - 30) * S, (cx + 42) * S, (395 + 30) * S],
              fill=(8, 4, 6))
    d.ellipse([(cx - 34) * S, (395 - 22) * S, (cx + 34) * S, (395 + 22) * S],
              fill=RED_DIM)
    d.ellipse([(cx - 22) * S, (395 - 13) * S, (cx + 22) * S, (395 + 13) * S],
              fill=RED)
    d.ellipse([(cx - 8) * S, (395 - 5) * S, (cx + 8) * S, (395 + 5) * S],
              fill=(255, 220, 225))

# nose vent
poly([(340, 450), (360, 450), (365, 500), (335, 500)], (12, 12, 15))
d.line([(345 * S, 460 * S), (355 * S, 460 * S)], fill=(6, 6, 8), width=4 * S)

# ── cables out of the skull ──────────────────────────────────────────
def cable(start, ctrl, end, width, col):
    pts = []
    for t in np.linspace(0, 1, 40):
        x = (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * ctrl[0] + t * t * end[0]
        y = (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * ctrl[1] + t * t * end[1]
        pts.append((x * S, y * S))
    d.line(pts, fill=col, width=int(width * S), joint="curve")


for i, (sy, ey) in enumerate([(300, 220), (360, 340), (430, 470), (500, 600)]):
    cable((505, sy), (640, (sy + ey) / 2), (700, ey), 5 + i % 2 * 3, WIRE)
    cable((505, sy), (640, (sy + ey) / 2), (700, ey), 1.2, (90, 10, 24))
cable((195, 330), (90, 360), (0, 430), 5, WIRE)
cable((195, 330), (90, 360), (0, 430), 1.2, (90, 10, 24))

# ── rim light (from the arc, left side) ──────────────────────────────
rim = Image.new("RGBA", (W, H), (0, 0, 0, 0))
rd = ImageDraw.Draw(rim)
rim_pts = [(x - 14, y - 6) for x, y in skull] + [(250 - 14, 540 - 6), (270 - 14, 700 - 6)]
rd.polygon([(x * S, y * S) for x, y in rim_pts], fill=(255, 40, 80, 150))
rim = rim.filter(ImageFilter.GaussianBlur(10 * S))
img = Image.alpha_composite(rim, img)

# ── red optic bloom ──────────────────────────────────────────────────
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
for cx in (295, 405):
    gd.ellipse([(cx - 60) * S, (395 - 45) * S, (cx + 60) * S, (395 + 45) * S],
               fill=(255, 20, 50, 120))
glow = glow.filter(ImageFilter.GaussianBlur(24 * S))
img = Image.alpha_composite(glow, img)

# ── plate seams ──────────────────────────────────────────────────────
seams = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(seams)
for a, b in [((205, 250), (495, 250)), ((220, 300), (480, 300)),
             ((300, 200), (300, 470)), ((400, 200), (400, 470)),
             ((250, 545), (450, 545))]:
    sd.line([(a[0] * S, a[1] * S), (b[0] * S, b[1] * S)], fill=(90, 12, 26, 160), width=2 * S)
img = Image.alpha_composite(img, seams)

img = img.resize((W // S, H // S), Image.LANCZOS)
os.makedirs(os.path.dirname(OUT), exist_ok=True)
img.save(OUT)
print(OUT, img.size)
