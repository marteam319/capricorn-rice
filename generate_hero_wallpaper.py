#!/usr/bin/env python3
"""Capricorn hero wallpaper — v3.

Black scene, red/purple volumetric light, halo, embers, ghost wordmark and a
rim-lit character. Renders 2560x1440 to ~/.local/share/wallpapers/.
"""

import math

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage

W, H = 2560, 1440
ART = "/home/marteam/Projekty/cyberpunk-capricorn/art/capricorn.png"
OUT = "/home/marteam/.local/share/wallpapers/capricorn-character.png"

INK = (5, 3, 8)
MAGENTA = (255, 32, 56)
DEEP = (120, 4, 30)
GREEN = (13, 255, 110)
VIOLET = (177, 76, 255)
PAPER = (244, 239, 241)

FONT_DIR = "/home/marteam/.local/share/fonts/cyberpunk"
F_BOLD = f"{FONT_DIR}/ChakraPetch-Bold.ttf"
F_RAJ = f"{FONT_DIR}/Rajdhani-SemiBold.ttf"

rng = np.random.default_rng(2026)


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def spaced(draw, xy, text, fnt, fill, spacing=0):
    x, y = xy
    for ch in text:
        draw.text((x, y), ch, font=fnt, fill=fill)
        x += draw.textlength(ch, font=fnt) + spacing


# ── 1. character: drop the paper, keep the flat fills ────────────────
src = Image.open(ART).convert("RGB").crop((80, 0, 374, 534))
a = np.array(src).astype(np.int16)
hsv = np.array(src.convert("HSV")).astype(np.int16)
Hh, Ss, Vv = hsv[..., 0], hsv[..., 1], hsv[..., 2]

paper = (Vv > 195) & (Ss < 55)
ink = Vv < 70
green = (Hh > 55) & (Hh < 135) & (Ss > 70) & ~ink
violet = (Hh >= 135) & (Hh <= 195) & (Ss > 60)
magenta = (((Hh > 195) | (Hh < 15))) & (Ss > 70) & ~ink

labels, n = ndimage.label(paper)
border = set(labels[0, :]) | set(labels[-1, :]) | set(labels[:, 0]) | set(labels[:, -1])
border.discard(0)
outer_paper = np.isin(labels, list(border))
inner_white = paper & ~outer_paper
char = ~outer_paper

out = np.zeros_like(a)
out[...] = INK
out[ink] = (15, 10, 16)
out[inner_white] = PAPER
out[magenta] = (78, 6, 20)
out[green] = GREEN
out[violet] = VIOLET

art = Image.fromarray(out.astype("uint8"))
mask = Image.fromarray((char * 255).astype("uint8"))

TARGET_H = 1460
scale = TARGET_H / src.height
size = (int(src.width * scale), TARGET_H)
art = art.resize(size, Image.LANCZOS)
mask = mask.resize(size, Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)

# halo of hair above the crop (mirror + fade)
E = int(size[1] * 0.075)
strip_a = art.crop((0, 0, size[0], E)).transpose(Image.FLIP_TOP_BOTTOM)
strip_m = mask.crop((0, 0, size[0], E)).transpose(Image.FLIP_TOP_BOTTOM)
fade = Image.linear_gradient("L").resize((size[0], E))
strip_m = ImageChops.multiply(strip_m, fade)
ext_a = Image.new("RGBA", (size[0], E + size[1]), (0, 0, 0, 0))
ext_m = Image.new("L", (size[0], E + size[1]), 0)
ext_a.paste(strip_a, (0, 0), strip_m)
ext_a.paste(art, (0, E), mask)
ext_m.paste(strip_m, (0, 0))
ext_m.paste(mask, (0, E))
art, mask = ext_a, ext_m
size = (size[0], E + size[1])

# rim
sil = mask.point(lambda v: 255 if v > 120 else 0)
solid = sil.filter(ImageFilter.MaxFilter(15)).filter(ImageFilter.MinFilter(15))
rim = ImageChops.subtract(solid, solid.filter(ImageFilter.MinFilter(13)))
rim = rim.filter(ImageFilter.MaxFilter(3))
top_fade = Image.new("L", size, 255)
td = ImageDraw.Draw(top_fade)
for y in range(E + 40):
    td.line([(0, y), (size[0], y)], fill=int(255 * min(1.0, max(0.0, (y - E * 0.5) / (E * 0.5)))))
rim = ImageChops.multiply(rim, top_fade)
rim_col = Image.new("RGBA", size, MAGENTA + (255,))
rim_col.putalpha(rim)
rim_core = Image.new("RGBA", size, (255, 220, 230, 255))
rim_core.putalpha(rim.point(lambda v: int(v * 0.35)))
rim_glow = rim_col.filter(ImageFilter.GaussianBlur(7))
rim_halo = rim_col.filter(ImageFilter.GaussianBlur(32))

glow = Image.new("RGBA", size, MAGENTA + (255,))
glow.putalpha(mask.point(lambda v: int(v * 0.5)))
glow = glow.filter(ImageFilter.GaussianBlur(60))

# feather the left edge
feather = Image.new("L", size, 255)
fd = ImageDraw.Draw(feather)
FADE = 420
for x in range(FADE):
    fd.line([(x, 0), (x, size[1])], fill=int(255 * (x / FADE) ** 1.4))


def feathered(layer):
    o = layer.copy()
    o.putalpha(ImageChops.multiply(layer.getchannel("A"), feather))
    return o


# ── 2. background ────────────────────────────────────────────────────
canvas = Image.new("RGBA", (W, H), INK + (255,))

grad = Image.new("RGB", (1, H))
for y in range(H):
    t = y / H
    top = (5, 3, 8)
    bot = (18, 3, 12)
    grad.putpixel((0, y), tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3)))
canvas = grad.resize((W, H)).convert("RGBA")

blooms = Image.new("RGBA", (W, H), (0, 0, 0, 0))
bd = ImageDraw.Draw(blooms)
bd.ellipse([W * 0.66, -H * 0.10, W * 1.10, H * 0.95], fill=(80, 3, 22, 55))
bd.ellipse([W * 0.82, -H * 0.30, W * 1.25, H * 0.35], fill=(177, 76, 255, 40))
bd.ellipse([-W * 0.15, H * 0.60, W * 0.45, H * 1.25], fill=(13, 255, 110, 40))
canvas = Image.alpha_composite(canvas, blooms.filter(ImageFilter.GaussianBlur(320)))

# volumetric beams from the left
beams = Image.new("RGBA", (W, H), (0, 0, 0, 0))
bm = ImageDraw.Draw(beams)
for k, (slope, width, alpha) in enumerate([(-0.55, 190, 26), (-0.28, 120, 20), (0.10, 240, 18),
                                           (0.38, 150, 14), (0.66, 90, 10)]):
    y0 = H * (0.05 + k * 0.16)
    bm.polygon([(0, y0), (W * 0.75, y0 + slope * W * 0.75),
                (W * 0.75, y0 + slope * W * 0.75 + width), (0, y0 + width)],
               fill=(255, 32, 56, alpha))
canvas = Image.alpha_composite(canvas, beams.filter(ImageFilter.GaussianBlur(90)))

# ghost wordmark
ghost = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(ghost)
big = font(F_BOLD, 380)
spaced(gd, (60, H - 560), "CAPRICORN", big, (255, 32, 56, 14), spacing=18)
canvas = Image.alpha_composite(canvas, ghost)

# glyph rain
GLYPHS = "0123456789ABCDEF/\\|<>[]{}#$%&*+=アイウエオカキクケコサシスセソ"
rain = Image.new("RGBA", (W, H), (0, 0, 0, 0))
rd = ImageDraw.Draw(rain)
gf = font("/usr/share/fonts/TTF/DejaVuSansMono.ttf", 17)
for x in range(26, int(W * 0.58), 24):
    if rng.random() < 0.4:
        continue
    col = GREEN if rng.random() < 0.55 else VIOLET
    y = rng.uniform(-H * 0.25, H * 0.75)
    for i in range(int(rng.integers(4, 16))):
        ch = GLYPHS[int(rng.integers(0, len(GLYPHS)))]
        al = int(120 * (1 - i / 16) * rng.uniform(0.35, 1.0))
        rd.text((x, y + i * 21), ch, font=gf, fill=col + (al,))
canvas = Image.alpha_composite(canvas, rain.filter(ImageFilter.GaussianBlur(1)))

# floor grid
grid = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gr = ImageDraw.Draw(grid)
HZ = int(H * 0.78)
for i in range(-20, 21):
    gr.line([(W // 2, HZ), (W // 2 + i * (W / 16), H)], fill=(255, 32, 56, 22), width=2)
for k in range(1, 12):
    t = (k / 11) ** 2.1
    y = HZ + int(t * (H - HZ))
    gr.line([(0, y), (W, y)], fill=(255, 32, 56, int(8 + 22 * t)), width=1)
canvas = Image.alpha_composite(canvas, grid)

# halo ring behind her head
halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
hd = ImageDraw.Draw(halo)
cx, cy, r = int(W * 0.80), int(H * 0.38), 330
hd.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(255, 32, 56, 90), width=3)
hd.ellipse([cx - r - 26, cy - r - 26, cx + r + 26, cy + r + 26], outline=(177, 76, 255, 45), width=1)
canvas = Image.alpha_composite(canvas, halo.filter(ImageFilter.GaussianBlur(12)))

# ── 3. character ─────────────────────────────────────────────────────
px = W - size[0] + 40
py = 40
for layer in (glow, rim_halo, rim_glow):
    canvas.alpha_composite(feathered(layer), (px, py))

body = Image.new("RGBA", size, (0, 0, 0, 0))
body.paste(art, (0, 0), mask)
canvas.alpha_composite(feathered(body), (px, py))
canvas.alpha_composite(feathered(rim_col), (px, py))
canvas.alpha_composite(feathered(rim_core), (px, py))

# ── 4. embers / dust ─────────────────────────────────────────────────
embers = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ed = ImageDraw.Draw(embers)
for _ in range(320):
    x = rng.uniform(0, W)
    y = rng.uniform(0, H)
    r = abs(rng.normal(0, 1.6)) + 0.5
    col = MAGENTA if rng.random() < 0.6 else (GREEN if rng.random() < 0.5 else VIOLET)
    al = int(rng.uniform(30, 190))
    ed.ellipse([x - r, y - r, x + r, y + r], fill=col + (al,))
canvas = Image.alpha_composite(canvas, embers)
canvas = Image.alpha_composite(canvas, embers.filter(ImageFilter.GaussianBlur(6)))

# ── 5. typography ────────────────────────────────────────────────────
txt = Image.new("RGBA", (W, H), (0, 0, 0, 0))
td = ImageDraw.Draw(txt)

title = font(F_BOLD, 132)
spaced(td, (146, H - 372), "CAPRICORN", title, (177, 76, 255, 70), spacing=14)
spaced(td, (130, H - 380), "CAPRICORN", title, (255, 32, 56, 90), spacing=14)
spaced(td, (138, H - 378), "CAPRICORN", title, (247, 239, 242, 255), spacing=14)

td.rectangle([142, H - 212, 142 + 300, H - 208], fill=(255, 32, 56, 235))
td.rectangle([456, H - 212, 456 + 84, H - 208], fill=(177, 76, 255, 235))
spaced(td, (142, H - 200), "NET_54.7 // BLACKWALL", font(F_RAJ, 25), (176, 150, 160, 255), spacing=4)

# HUD brackets
hud = Image.new("RGBA", (W, H), (0, 0, 0, 0))
hu = ImageDraw.Draw(hud)
bx0 = px + size[0] * 0.18
by0 = max(py + size[1] * 0.06, 60)
bx1 = min(px + size[0] * 0.95, W - 24)
by1 = min(py + size[1] * 0.55, H - 40)
L = 48
for x, y, dx, dy in ((bx0, by0, 1, 1), (bx1, by0, -1, 1), (bx0, by1, 1, -1), (bx1, by1, -1, -1)):
    hu.line([(x, y + dy * L), (x, y), (x + dx * L, y)], fill=(13, 255, 110, 200), width=3)
mono = font("/usr/share/fonts/TTF/DejaVuSansMono.ttf", 17)
hu.text((bx0 + 6, max(by0 - 28, 24)), "ICE // ACTIVE", font=mono, fill=(13, 255, 110, 230))
canvas = Image.alpha_composite(canvas, txt)
canvas = Image.alpha_composite(canvas, hud)

# ── 6. texture ───────────────────────────────────────────────────────
gl = canvas.copy()
for _ in range(4):
    y = int(rng.uniform(H * 0.05, H * 0.9))
    h = int(rng.uniform(2, 8))
    sh = int(rng.uniform(-20, 20))
    gl.paste(canvas.crop((0, y, W, y + h)), (sh, y))
canvas = gl

scan = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(scan)
for y in range(0, H, 4):
    sd.line([(0, y), (W, y)], fill=(0, 0, 0, 18))
canvas = Image.alpha_composite(canvas, scan)

vig = Image.new("L", (W, H), 0)
ImageDraw.Draw(vig).ellipse([-W * 0.22, -H * 0.3, W * 1.22, H * 1.3], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(320))
dark = Image.new("RGBA", (W, H), (0, 0, 0, 255))
dark.putalpha(ImageChops.invert(vig).point(lambda v: int(v * 0.6)))
canvas = Image.alpha_composite(canvas, dark)

noise = Image.effect_noise((W, H), 18).convert("RGB")
canvas = Image.blend(canvas.convert("RGB"), noise, 0.03).convert("RGBA")

canvas.convert("RGB").save(OUT, quality=95)
print(OUT)
