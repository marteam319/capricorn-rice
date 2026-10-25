#!/usr/bin/env python3
"""Cyberpunk Capricorn // Ink — screen-print wallpaper generator.

Palette taken from the character art: hot magenta, ink black, acid green,
white splatter. Run with --dark for a near-black variant for bright rooms.
"""

import math
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

W, H = 2560, 1440
DARK = "--dark" in sys.argv
random.seed(2077)

MAGENTA = (255, 10, 84)
MAGENTA_DEEP = (205, 6, 60)
INK = (10, 7, 9)
GREEN = (13, 255, 110)
VIOLET = (177, 76, 255)
PAPER = (246, 241, 240)

FONT_DIR = "/home/marteam/.local/share/fonts/cyberpunk"
F_BOLD = f"{FONT_DIR}/ChakraPetch-Bold.ttf"
F_SEMI = f"{FONT_DIR}/ChakraPetch-SemiBold.ttf"
F_RAJ = f"{FONT_DIR}/Rajdhani-SemiBold.ttf"


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def spaced_text(draw, xy, text, fnt, fill, spacing=0, align_right=False):
    widths = [draw.textlength(ch, font=fnt) for ch in text]
    total = sum(widths) + spacing * (len(text) - 1)
    x, y = xy
    if align_right:
        x -= total
    for ch, w in zip(text, widths):
        draw.text((x, y), ch, font=fnt, fill=fill)
        x += w + spacing


def shard(draw, cx, cy, r, n=7, thin=0.24, fill=INK, jitter=0.14):
    pts = []
    for i in range(n * 2):
        ang = 2 * math.pi * i / (n * 2) + random.uniform(-jitter, jitter)
        rad = r if i % 2 == 0 else r * thin * random.uniform(0.45, 1.25)
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    draw.polygon(pts, fill=fill)


def bolt(draw, start, end, width, fill=INK, segments=7, spread=90):
    x0, y0 = start
    x1, y1 = end
    pts = [(x0, y0)]
    for i in range(1, segments):
        t = i / segments
        pts.append((x0 + (x1 - x0) * t + random.uniform(-spread, spread),
                    y0 + (y1 - y0) * t + random.uniform(-spread, spread)))
    pts.append((x1, y1))
    draw.line(pts, fill=fill, width=width, joint="curve")


def splatter(draw, cx, cy, count, radius, color, alpha=235):
    for _ in range(count):
        ang = random.random() * 2 * math.pi
        d = abs(random.gauss(0, radius * 0.45))
        x = cx + math.cos(ang) * d
        y = cy + math.sin(ang) * d
        r = max(0.6, random.gauss(radius * 0.035, radius * 0.03))
        draw.ellipse([x - r, y - r, x + r, y + r], fill=color + (alpha,))


# ── base ──────────────────────────────────────────────────────────────
if DARK:
    img = Image.new("RGBA", (W, H), (8, 6, 9, 255))
    img = Image.alpha_composite(img, Image.new("RGBA", (W, H), MAGENTA + (26,)))
    base2 = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    bd = ImageDraw.Draw(base2)
    bd.ellipse([W * 0.35, -H * 0.5, W * 1.25, H * 0.95], fill=MAGENTA + (22,))
    img = Image.alpha_composite(img, base2.filter(ImageFilter.GaussianBlur(260)))
else:
    img = Image.new("RGB", (W, H), MAGENTA)
    grad = Image.new("RGB", (1, H))
    for y in range(H):
        t = y / H
        grad.putpixel((0, y), tuple(int(MAGENTA[i] + (MAGENTA_DEEP[i] - MAGENTA[i]) * t) for i in range(3)))
    img = grad.resize((W, H)).convert("RGBA")

# halftone dot field (screen-print texture)
halftone = Image.new("RGBA", (W, H), (0, 0, 0, 0))
hd = ImageDraw.Draw(halftone)
step = 17
for y in range(0, H, step):
    for x in range(0, W, step):
        d = math.hypot((x - W * 0.12) / W, (y - H * 0.1) / H)
        if d > 0.42:
            continue
        r = max(0.0, (0.42 - d) * 16)
        if r < 0.7:
            continue
        hd.ellipse([x - r, y - r, x + r, y + r], fill=(255, 255, 255, 60))
img = Image.alpha_composite(img, halftone)

# ── shards / ink ──────────────────────────────────────────────────────
ink = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(ink)

shard(d, W * 0.62, H * 0.40, 470, n=9, thin=0.20)
shard(d, W * 0.20, H * 0.20, 250, n=6, thin=0.26)
shard(d, W * 0.88, H * 0.16, 190, n=5, thin=0.22)
shard(d, W * 0.47, H * 0.86, 330, n=8, thin=0.18)
bolt(d, (180, H * 0.60), (W * 0.55, H * 0.30), 26, segments=6, spread=70)
bolt(d, (W * 0.95, H * 0.55), (W * 0.70, H * 0.92), 18, segments=5, spread=60)
img = Image.alpha_composite(img, ink)

# green accents
acc = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ad = ImageDraw.Draw(acc)
shard(ad, W * 0.70, H * 0.57, 210, n=5, thin=0.30, fill=GREEN + (255,))
shard(ad, W * 0.30, H * 0.70, 120, n=4, thin=0.35, fill=GREEN + (255,))
bolt(ad, (W * 0.10, H * 0.42), (W * 0.42, H * 0.58), 10,
     fill=GREEN + (230,), segments=5, spread=45)
ad.ellipse([W * 0.63 - 46, H * 0.44 - 46, W * 0.63 + 46, H * 0.44 + 46],
           fill=VIOLET + (190,))
img = Image.alpha_composite(img, acc)

# white splatter
sp = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(sp)
for cx, cy, n, r in ((W * 0.42, H * 0.30, 260, 340),
                     (W * 0.86, H * 0.78, 180, 260),
                     (W * 0.62, H * 0.66, 120, 180),
                     (W * 0.14, H * 0.80, 90, 160)):
    splatter(sd, cx, cy, n, r, (255, 255, 255))
img = Image.alpha_composite(img, sp)

# ── typography ────────────────────────────────────────────────────────
txt = Image.new("RGBA", (W, H), (0, 0, 0, 0))
td = ImageDraw.Draw(txt)

kicker_font = font(F_RAJ, 36)
title_font = font(F_BOLD, 170)

def shadowed(text, xy, fnt, fill, shadow, spacing, offset=8):
    spaced_text(td, (xy[0] + offset, xy[1] + offset), text, fnt, shadow, spacing)
    spaced_text(td, xy, text, fnt, fill, spacing)

shadowed("CYBERPUNK // EDGERUNNERS 2", (152, H - 372), kicker_font,
         GREEN + (255,), INK + (255,), 8, offset=4)
shadowed("CAPRICORN", (146, H - 318), title_font, PAPER + (255,), INK + (255,), 16, offset=9)

td.rectangle([152, H - 96, 152 + 640, H - 92], fill=GREEN + (255,))
spaced_text(td, (152, H - 82), "NIGHT CITY  //  NET_54.7  //  SIGNAL LOCKED",
            font(F_RAJ, 26), (PAPER if DARK else INK) + (230,), spacing=4)

spaced_text(td, (W - 150, 104), "▲ 02", font(F_BOLD, 52), PAPER + (255,), spacing=6,
            align_right=True)
spaced_text(td, (W - 150, 176), "STANDALONE ARC", font(F_RAJ, 26), PAPER + (220,), spacing=5,
            align_right=True)

img = Image.alpha_composite(img, txt)

# ── scanlines (print grain) + vignette ────────────────────────────────
scan = Image.new("RGBA", (W, H), (0, 0, 0, 0))
scd = ImageDraw.Draw(scan)
for y in range(0, H, 4):
    scd.line([(0, y), (W, y)], fill=(0, 0, 0, 16))
img = Image.alpha_composite(img, scan)

vig = Image.new("L", (W, H), 0)
ImageDraw.Draw(vig).ellipse([-W * 0.22, -H * 0.32, W * 1.22, H * 1.32], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(340))
dark = Image.new("RGBA", (W, H), (0, 0, 0, 255))
dark.putalpha(ImageChops.invert(vig).point(lambda v: int(v * (0.55 if DARK else 0.30))))
img = Image.alpha_composite(img, dark)

noise = Image.effect_noise((W, H), 20).convert("RGB")
img = Image.blend(img.convert("RGB"), noise, 0.03).convert("RGBA")

name = "cyberpunk-capricorn-void.png" if DARK else "cyberpunk-capricorn-ink.png"
out = f"/home/marteam/.local/share/wallpapers/{name}"
img.convert("RGB").save(out, quality=95)
print(out)
