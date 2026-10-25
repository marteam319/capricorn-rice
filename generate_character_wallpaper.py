#!/usr/bin/env python3
"""Character wallpaper: Capricorn lifted out of the print and put on black.

Source art is flat: white paper, black ink, magenta hair, acid green, violet.
- paper connected to the border is dropped to black (background)
- enclosed white (her face, highlights) is kept as paper white
- a neon rim traces only the outer silhouette so the black-on-black works
- the left edge is feathered so she emerges from the dark
- Blackwall layer: glyph rain, netrunner HUD brackets, green/violet washes
"""

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont
from scipy import ndimage

W, H = 2560, 1440
ART = "/home/marteam/Projekty/cyberpunk-capricorn/art/capricorn.png"
OUT = "/home/marteam/.local/share/wallpapers/capricorn-character.png"

INK = (7, 5, 10)
MAGENTA = (255, 10, 84)
DEEP = (150, 4, 46)
GREEN = (13, 255, 110)
VIOLET = (177, 76, 255)
PAPER = (244, 239, 241)

FONT_DIR = "/home/marteam/.local/share/fonts/cyberpunk"
F_BOLD = f"{FONT_DIR}/ChakraPetch-Bold.ttf"
F_RAJ = f"{FONT_DIR}/Rajdhani-SemiBold.ttf"
F_MONO = "/usr/share/fonts/TTF/DejaVuSansMono.ttf"

rng = np.random.default_rng(2077)


def font(path, size):
    try:
        return ImageFont.truetype(path, size)
    except OSError:
        return ImageFont.load_default()


def spaced(draw, xy, text, fnt, fill, spacing=0):
    widths = [draw.textlength(ch, font=fnt) for ch in text]
    x, y = xy
    for ch, w in zip(text, widths):
        draw.text((x, y), ch, font=fnt, fill=fill)
        x += w + spacing


# ── 1. classify flat colours ──────────────────────────────────────────
src = Image.open(ART).convert("RGB")
small = np.array(src).astype(np.int16)
hsv = np.array(src.convert("HSV")).astype(np.int16)
Hh, Ss, Vv = hsv[..., 0], hsv[..., 1], hsv[..., 2]

paper = (Vv > 195) & (Ss < 55)
ink = Vv < 70
green = (Hh > 55) & (Hh < 135) & (Ss > 70) & ~ink
violet = (Hh >= 135) & (Hh <= 195) & (Ss > 60)
magenta = (((Hh > 195) | (Hh < 15))) & (Ss > 70) & ~ink

labels, n = ndimage.label(paper)
border_labels = set(labels[0, :]) | set(labels[-1, :]) | set(labels[:, 0]) | set(labels[:, -1])
border_labels.discard(0)
outer_paper = np.isin(labels, list(border_labels))
inner_white = paper & ~outer_paper
char = ~outer_paper

# ── 2. repaint ────────────────────────────────────────────────────────
out = np.zeros_like(small)
out[...] = INK
out[ink] = (17, 12, 19)
out[inner_white] = PAPER
out[magenta] = MAGENTA
out[green] = GREEN
out[violet] = VIOLET

art = Image.fromarray(out.astype("uint8"))
mask = Image.fromarray((char * 255).astype("uint8"))

# ── 3. upscale ────────────────────────────────────────────────────────
TARGET_H = 1500
scale = TARGET_H / src.height
size = (int(src.width * scale), TARGET_H)
art = art.resize(size, Image.LANCZOS)
mask = mask.resize(size, Image.LANCZOS).point(lambda v: 255 if v > 110 else 0)

# ── 3b. rebuild the hair above the source crop ────────────────────────
# the source art is cut at the hairline, so mirror the top strip upward
# and fade it into the background instead of leaving a hard horizontal edge
E = int(size[1] * 0.085)
strip_art = art.crop((0, 0, size[0], E)).transpose(Image.FLIP_TOP_BOTTOM)
strip_mask = mask.crop((0, 0, size[0], E)).transpose(Image.FLIP_TOP_BOTTOM)
fade = Image.linear_gradient("L").resize((size[0], E))
strip_mask = ImageChops.multiply(strip_mask, fade)

new_h = E + size[1]
ext_art = Image.new("RGBA", (size[0], new_h), (0, 0, 0, 0))
ext_mask = Image.new("L", (size[0], new_h), 0)
ext_art.paste(strip_art, (0, 0), strip_mask)
ext_art.paste(art, (0, E), mask)
ext_mask.paste(strip_mask, (0, 0))
ext_mask.paste(mask, (0, E))
art, mask = ext_art, ext_mask
size = (size[0], new_h)

# ── 4. rim ────────────────────────────────────────────────────────────
sil = mask.point(lambda v: 255 if v > 120 else 0)
solid = sil.filter(ImageFilter.MaxFilter(15)).filter(ImageFilter.MinFilter(15))
rim = ImageChops.subtract(solid, solid.filter(ImageFilter.MinFilter(13)))
rim = rim.filter(ImageFilter.MaxFilter(3))

# no rim across the reconstructed hair — it has to dissolve, not outline
top_fade = Image.new("L", size, 255)
tfd = ImageDraw.Draw(top_fade)
for y in range(E + 40):
    tfd.line([(0, y), (size[0], y)], fill=int(255 * min(1.0, max(0.0, (y - E * 0.5) / (E * 0.5)))))
rim = ImageChops.multiply(rim, top_fade)
rim_col = Image.new("RGBA", size, MAGENTA + (255,))
rim_col.putalpha(rim)
rim_core = Image.new("RGBA", size, (255, 255, 255, 255))
rim_core.putalpha(rim.point(lambda v: int(v * 0.35)))
rim_glow = rim_col.filter(ImageFilter.GaussianBlur(8))
rim_halo = rim_col.filter(ImageFilter.GaussianBlur(36))

body_glow = Image.new("RGBA", size, MAGENTA + (255,))
body_glow.putalpha(mask.point(lambda v: int(v * 0.55)))
body_glow = body_glow.filter(ImageFilter.GaussianBlur(55))

# ── 5. feather left edge ──────────────────────────────────────────────
feather = Image.new("L", size, 255)
fd = ImageDraw.Draw(feather)
FADE = 260
for x in range(FADE):
    fd.line([(x, 0), (x, size[1])], fill=int(255 * (x / FADE) ** 1.4))


def feathered(layer):
    o = layer.copy()
    o.putalpha(ImageChops.multiply(layer.getchannel("A"), feather))
    return o


# ── 6. canvas ─────────────────────────────────────────────────────────
canvas = Image.new("RGBA", (W, H), INK + (255,))

# green / violet / magenta washes
wash = Image.new("RGBA", (W, H), (0, 0, 0, 0))
wd = ImageDraw.Draw(wash)
wd.ellipse([-W * 0.25, H * 0.45, W * 0.55, H * 1.30], fill=GREEN + (42,))
wd.ellipse([W * 0.50, -H * 0.30, W * 1.25, H * 0.60], fill=VIOLET + (46,))
wd.ellipse([W * 0.55, H * 0.30, W * 1.15, H * 1.15], fill=DEEP + (80,))
canvas = Image.alpha_composite(canvas, wash.filter(ImageFilter.GaussianBlur(260)))

# perspective grid
grid = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(grid)
HZ = int(H * 0.74)
for i in range(-18, 19):
    gd.line([(W // 2, HZ), (W // 2 + i * (W / 15), H)], fill=MAGENTA + (26,), width=2)
for k in range(1, 16):
    t = (k / 15) ** 2.1
    y = HZ + int(t * (H - HZ))
    gd.line([(0, y), (W, y)], fill=MAGENTA + (int(10 + 30 * t),), width=1)
canvas = Image.alpha_composite(canvas, grid)

# ── 7. Blackwall glyph rain ───────────────────────────────────────────
GLYPHS = "0123456789ABCDEF/\\|<>[]{}#$%&*+=アイウエオカキクケコサシスセソタチツテト"
rain = Image.new("RGBA", (W, H), (0, 0, 0, 0))
rd = ImageDraw.Draw(rain)
glyph_font = font(F_MONO, 17)
for x in range(24, int(W * 0.62), 23):
    if rng.random() < 0.38:
        continue
    col = GREEN if rng.random() < 0.62 else VIOLET
    y = rng.uniform(-H * 0.25, H * 0.80)
    n_chars = int(rng.integers(5, 20))
    for i in range(n_chars):
        ch = GLYPHS[int(rng.integers(0, len(GLYPHS)))]
        a = int(140 * (1 - i / n_chars) * rng.uniform(0.40, 1.0))
        rd.text((x, y + i * 21), ch, font=glyph_font, fill=col + (a,))
# a few columns behind her, very faint
for x in range(int(W * 0.63), W, 34):
    col = GREEN if rng.random() < 0.5 else VIOLET
    y = rng.uniform(0, H * 0.7)
    for i in range(int(rng.integers(4, 10))):
        ch = GLYPHS[int(rng.integers(0, len(GLYPHS)))]
        rd.text((x, y + i * 21), ch, font=glyph_font, fill=col + (int(30 * rng.uniform(0.4, 1)),))
canvas = Image.alpha_composite(canvas, rain.filter(ImageFilter.GaussianBlur(1)))

# ── 8. place her ──────────────────────────────────────────────────────
px = W - size[0] + 60
py = -75
for layer in (body_glow, rim_halo, rim_glow):
    canvas.alpha_composite(feathered(layer), (px, py))

body = Image.new("RGBA", size, (0, 0, 0, 0))
body.paste(art, (0, 0), mask)
canvas.alpha_composite(feathered(body), (px, py))
canvas.alpha_composite(feathered(rim_col), (px, py))
canvas.alpha_composite(feathered(rim_core), (px, py))

# ── 9. netrunner HUD ──────────────────────────────────────────────────
hud = Image.new("RGBA", (W, H), (0, 0, 0, 0))
hd = ImageDraw.Draw(hud)
bx0 = px + size[0] * 0.12
by0 = max(py + size[1] * 0.06, 62)
bx1 = min(px + size[0] * 0.95, W - 24)
by1 = min(py + size[1] * 0.54, H - 40)
L = 54
for x, y, dx, dy in ((bx0, by0, 1, 1), (bx1, by0, -1, 1), (bx0, by1, 1, -1), (bx1, by1, -1, -1)):
    hd.line([(x, y + dy * L), (x, y), (x + dx * L, y)], fill=GREEN + (215,), width=3)
# tick marks
for i in range(6):
    hd.line([(bx0 + 40 + i * 26, by1), (bx0 + 40 + i * 26, by1 - 10)], fill=GREEN + (150,), width=2)
mono = font(F_MONO, 17)
hd.text((bx0 + 6, max(by0 - 28, 24)), "ICE // ACTIVE", font=mono, fill=GREEN + (235,))
hd.text((max(bx1 - 190, bx0), min(by1 + 12, H - 28)), "0x7F4A // BREACH", font=mono, fill=VIOLET + (235,))
canvas = Image.alpha_composite(canvas, hud)

# ── 10. typography ────────────────────────────────────────────────────
txt = Image.new("RGBA", (W, H), (0, 0, 0, 0))
td = ImageDraw.Draw(txt)

title = font(F_BOLD, 130)
spaced(td, (144, H - 364), "CAPRICORN", title, GREEN + (80,), spacing=14)
spaced(td, (128, H - 372), "CAPRICORN", title, VIOLET + (90,), spacing=14)
spaced(td, (136, H - 372), "CAPRICORN", title, PAPER + (255,), spacing=14)

td.rectangle([140, H - 214, 140 + 300, H - 210], fill=GREEN + (235,))
td.rectangle([452, H - 214, 452 + 90, H - 210], fill=VIOLET + (235,))
spaced(td, (140, H - 202), "NET_54.7 // BLACKWALL", font(F_RAJ, 25),
       (168, 160, 172) + (255,), spacing=4)

canvas = Image.alpha_composite(canvas, txt)

# ── 11. texture ───────────────────────────────────────────────────────
gl = canvas.copy()
for _ in range(5):
    y = int(rng.uniform(H * 0.05, H * 0.9))
    h = int(rng.uniform(3, 10))
    shift = int(rng.uniform(-26, 26))
    gl.paste(canvas.crop((0, y, W, y + h)), (shift, y))
canvas = gl

scan = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(scan)
for y in range(0, H, 4):
    sd.line([(0, y), (W, y)], fill=(0, 0, 0, 20))
canvas = Image.alpha_composite(canvas, scan)

vig = Image.new("L", (W, H), 0)
ImageDraw.Draw(vig).ellipse([-W * 0.22, -H * 0.3, W * 1.22, H * 1.3], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(300))
dark = Image.new("RGBA", (W, H), (0, 0, 0, 255))
dark.putalpha(ImageChops.invert(vig).point(lambda v: int(v * 0.55)))
canvas = Image.alpha_composite(canvas, dark)

noise = Image.effect_noise((W, H), 18).convert("RGB")
canvas = Image.blend(canvas.convert("RGB"), noise, 0.028).convert("RGBA")

canvas.convert("RGB").save(OUT, quality=95)
print(OUT)
