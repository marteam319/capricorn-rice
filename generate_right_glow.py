#!/usr/bin/env python3
"""Right-monitor wallpaper: black, with Capricorn's hair light and lightning
spilling in from the left edge (the seam with the main monitor).

Hair magenta sampled from the source art: #ff0a54.
"""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance

W, H = 2560, 1440
HAIR = (255, 10, 84)       # capricorn hair magenta
GREEN = (13, 255, 110)
VIOLET = (177, 76, 255)
HOT = (255, 228, 240)      # white-hot filament inside the bolt
INK = (6, 4, 9)
OUT = os.environ.get("BOLT_OUT", "/home/marteam/.local/share/wallpapers/capricorn-right-glow.png")

rng = np.random.default_rng(int(os.environ.get("BOLT_SEED", "7")))

# ── smooth spill gradient from the left edge ─────────────────────────
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)

fall = np.exp(-xx / 620.0)
band = 0.24 + 0.76 * np.exp(-((yy - H * 0.50) / (H * 0.80)) ** 2)
core = np.exp(-xx / 230.0) * band ** 1.4

field = np.clip(0.82 * fall * band + 0.50 * core, 0, 1.30)

rgb = np.zeros((H, W, 3), dtype=np.float32)
for i in range(3):
    rgb[..., i] = INK[i] + (HAIR[i] - INK[i]) * np.clip(field, 0, 1)

img = Image.fromarray(rgb.astype(np.uint8)).convert("RGBA")

# green / violet ambient washes
wash = Image.new("RGBA", (W, H), (0, 0, 0, 0))
wd = ImageDraw.Draw(wash)
wd.ellipse([W * 0.55, -H * 0.25, W * 1.30, H * 0.45], fill=(177, 76, 255, 46))
wd.ellipse([-W * 0.10, H * 0.58, W * 0.55, H * 1.30], fill=(255, 60, 130, 40))
img = Image.alpha_composite(img, wash.filter(ImageFilter.GaussianBlur(260)))

# blackwall glyph rain drifting off the seam
GLYPHS = "0123456789ABCDEF/\\|<>[]{}#$%&*+=アイウエオカキクケコ"
rain = Image.new("RGBA", (W, H), (0, 0, 0, 0))
rd = ImageDraw.Draw(rain)
gf = ImageFont.truetype("/usr/share/fonts/TTF/DejaVuSansMono.ttf", 17)
for x in range(30, int(W * 0.55), 27):
    if rng.random() < 0.45:
        continue
    col = HAIR if rng.random() < 0.6 else VIOLET
    y = rng.uniform(-H * 0.2, H * 0.85)
    for i in range(int(rng.integers(4, 14))):
        ch = GLYPHS[int(rng.integers(0, len(GLYPHS)))]
        a = int(120 * (1 - i / 14) * rng.uniform(0.3, 1.0))
        rd.text((x, y + i * 21), ch, font=gf, fill=col + (a,))
img = Image.alpha_composite(img, rain.filter(ImageFilter.GaussianBlur(1)))


# ── lightning ────────────────────────────────────────────────────────
def bolt_path(start, heading, reach, kinks=4):
    """Alternating lateral offsets = classic zigzag around a direction."""
    pts = [start]
    x, y = start
    travelled = 0.0
    sign = 1.0
    while travelled < reach:
        sign *= -1.0
        mag = rng.uniform(0.22, 0.62)
        if rng.random() < 0.10:
            mag = rng.uniform(0.85, 1.25)
        ang = heading + sign * mag
        seg = rng.uniform(24, 88)
        x += math.cos(ang) * seg
        y += math.sin(ang) * seg
        travelled += abs(math.cos(ang) * seg)
        pts.append((x, y))
    return pts


def draw_tapered(layer, pts, w0, w1, alpha, color):
    d = ImageDraw.Draw(layer)
    n = len(pts) - 1
    for i in range(n):
        t = i / max(1, n - 1)
        w = w0 + (w1 - w0) * t
        d.line([pts[i], pts[i + 1]], fill=color + (alpha,), width=max(1, int(round(w))))
        if w > 3:
            d.ellipse([pts[i][0] - w / 2, pts[i][1] - w / 2,
                       pts[i][0] + w / 2, pts[i][1] + w / 2], fill=color + (alpha,))


def bolt_to(start, end, segs=7):
    pts = [start]
    for i in range(1, segs):
        t = i / segs
        pts.append((start[0] + (end[0] - start[0]) * t + rng.uniform(-55, 55),
                    start[1] + (end[1] - start[1]) * t + rng.uniform(-55, 55)))
    pts.append(end)
    return pts


strikes = [
    (0, H * 0.22, 0.22, W * 0.72),
    (-30, H * 0.56, -0.06, W * 0.68),
    (10, H * 0.86, -0.28, W * 0.52),
]
main_paths = [bolt_path((sx, sy), head, reach) for sx, sy, head, reach in strikes]

branch_paths = []
for path in main_paths:
    for _ in range(3):
        i = int(rng.integers(3, max(4, len(path) - 2)))
        bx, by = path[i]
        branch_paths.append(bolt_path((bx, by), rng.uniform(-1.0, 1.0),
                                      rng.uniform(80, 200), kinks=2))

glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
for p in main_paths:
    draw_tapered(glow, p, 78, 18, 150, HAIR)
for p in branch_paths:
    draw_tapered(glow, p, 36, 9, 110, HAIR)
glow = glow.filter(ImageFilter.GaussianBlur(44))

mid = Image.new("RGBA", (W, H), (0, 0, 0, 0))
for p in main_paths:
    draw_tapered(mid, p, 28, 7, 245, HAIR)
for p in branch_paths:
    draw_tapered(mid, p, 14, 4, 205, HAIR)
mid = mid.filter(ImageFilter.GaussianBlur(4))

core = Image.new("RGBA", (W, H), (0, 0, 0, 0))
for p in main_paths:
    draw_tapered(core, p, 14, 3, 255, HAIR)
for p in branch_paths:
    draw_tapered(core, p, 7, 2, 245, HAIR)

filament = Image.new("RGBA", (W, H), (0, 0, 0, 0))
for p in main_paths:
    draw_tapered(filament, p, 5, 1.2, 255, HOT)
for p in branch_paths:
    draw_tapered(filament, p, 2.5, 1.0, 215, HOT)

strike_glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sgd = ImageDraw.Draw(strike_glow)
for sx, sy, _, _ in strikes:
    r = 190
    sgd.ellipse([sx - r, sy - r, sx + r, sy + r], fill=HOT + (120,))
strike_glow = strike_glow.filter(ImageFilter.GaussianBlur(70))

sparks = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(sparks)
for p in main_paths + branch_paths:
    for _ in range(len(p)):
        px, py = p[int(rng.integers(0, len(p)))]
        if rng.random() < 0.5:
            continue
        r = rng.uniform(1.2, 4.2)
        sd.ellipse([px - r, py - r, px + r, py + r],
                   fill=HAIR + (int(rng.uniform(120, 230)),))

fade_x = np.exp(-xx / 1900.0)
layers = [glow, mid, core, filament, strike_glow, sparks]
for layer in layers:
    a = np.array(layer.getchannel("A")).astype(np.float32) * fade_x
    layer.putalpha(Image.fromarray(a.astype(np.uint8)))

bolts = Image.new("RGBA", (W, H), (0, 0, 0, 0))
for layer in layers:
    bolts = Image.alpha_composite(bolts, layer)

img = Image.alpha_composite(img, bolts)

# ── hair wisps at the seam ───────────────────────────────────────────
wisps = Image.new("RGBA", (W, H), (0, 0, 0, 0))
wd = ImageDraw.Draw(wisps)
for _ in range(5):
    y = rng.uniform(H * 0.2, H * 0.85)
    pts = [(-40, y)]
    for step in range(1, 6):
        pts.append((step * rng.uniform(90, 240), y + rng.uniform(-120, 120)))
    wd.line(pts, fill=HAIR + (int(rng.uniform(28, 62)),), width=int(rng.uniform(3, 9)),
            joint="curve")
img = Image.alpha_composite(img, wisps.filter(ImageFilter.GaussianBlur(16)))

# ── bloom ────────────────────────────────────────────────────────────
bloom = img.filter(ImageFilter.GaussianBlur(110))
img = Image.alpha_composite(bloom, img)

# ── print texture ────────────────────────────────────────────────────
scan = Image.new("RGBA", (W, H), (0, 0, 0, 0))
scd = ImageDraw.Draw(scan)
for y in range(0, H, 4):
    scd.line([(0, y), (W, y)], fill=(0, 0, 0, 18))
img = Image.alpha_composite(img, scan)

fade = np.clip((xx - W * 0.58) / (W * 0.38), 0, 1) ** 1.5
img = Image.composite(Image.new("RGBA", (W, H), INK + (255,)), img,
                      Image.fromarray((fade * 255).astype(np.uint8)).convert("L"))

noise = Image.effect_noise((W, H), 16).convert("RGB")
img = Image.blend(img.convert("RGB"), noise, 0.025).convert("RGBA")

img.convert("RGB").save(OUT, quality=95)
print(OUT)
