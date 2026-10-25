#!/usr/bin/env python3
"""Left-screen hero: the red-lit / motion-blurred Capricorn frame, graded to
sit in the same family as the rest of the rice, with a Blackwall overlay.

Source: art/capricorn-lighting.png (the frame the user sent).
"""

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

W, H = 2560, 1440
SRC = "/home/marteam/Projekty/cyberpunk-capricorn/art/capricorn-lighting.png"
OUT = "/home/marteam/.local/share/wallpapers/capricorn-left-lighting.png"

INK = (6, 4, 9)
MAGENTA = (255, 10, 84)
GREEN = (13, 255, 110)
VIOLET = (177, 76, 255)
PAPER = (244, 239, 241)

FONT_DIR = "/home/marteam/.local/share/fonts/cyberpunk"
F_BOLD = f"{FONT_DIR}/ChakraPetch-Bold.ttf"
F_RAJ = f"{FONT_DIR}/Rajdhani-SemiBold.ttf"
F_MONO = "/usr/share/fonts/TTF/DejaVuSansMono.ttf"

rng = np.random.default_rng(54)


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


# ── 1. cover-fit to 2560x1440 ─────────────────────────────────────────
src = Image.open(SRC).convert("RGB")
scale = max(W / src.width, H / src.height)
nw, nh = int(src.width * scale + 0.5), int(src.height * scale + 0.5)
img = src.resize((nw, nh), Image.LANCZOS)
left = (nw - W) // 2
top = (nh - H) // 2
img = img.crop((left, top, left + W, top + H))

# ── 2. grade: crush blacks, violet shadows, magenta mids, red bloom ───
a = np.array(img).astype(np.float32)

# contrast + shadow crush
a = np.clip((a / 255.0) ** 1.12 * 255.0, 0, 255)
lum = a.mean(axis=2, keepdims=True)
a *= 0.78 + 0.22 * (lum / 255.0)

# violet in the darks, magenta in the mids
sh = (1.0 - lum / 255.0)
a[..., 2] += sh[..., 0] * 22          # blue
a[..., 0] += sh[..., 0] * 9           # red
a[..., 0] += (lum[..., 0] / 255.0) * 12
a = np.clip(a, 0, 255)

img = Image.fromarray(a.astype(np.uint8)).convert("RGBA")

# soft red bloom
bloom = img.filter(ImageFilter.GaussianBlur(70))
img = Image.alpha_composite(bloom, img)

# ── 3. edge falloff into black ────────────────────────────────────────
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
edge = np.minimum(
    np.clip(xx / (W * 0.16), 0, 1),
    np.clip((W - xx) / (W * 0.16), 0, 1),
)
edge = np.minimum(edge, np.clip(yy / (H * 0.14), 0, 1))
edge = np.minimum(edge, np.clip((H - yy) / (H * 0.14), 0, 1))
edge = (edge ** 0.85)
mask = Image.fromarray((edge * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(70))
img = Image.composite(img, Image.new("RGBA", (W, H), INK + (255,)), mask)

# ── 4. Blackwall glyph rain, framing the edges ───────────────────────
GLYPHS = "0123456789ABCDEF/\\|<>[]{}#$%&*+=アイウエオカキクケコサシスセソ"
rain = Image.new("RGBA", (W, H), (0, 0, 0, 0))
rd = ImageDraw.Draw(rain)
gf = font(F_MONO, 17)
for x in list(range(26, int(W * 0.22), 25)) + list(range(int(W * 0.80), W - 20, 25)):
    if rng.random() < 0.40:
        continue
    col = GREEN if rng.random() < 0.6 else VIOLET
    y = rng.uniform(-H * 0.2, H * 0.85)
    for i in range(int(rng.integers(5, 16))):
        ch = GLYPHS[int(rng.integers(0, len(GLYPHS)))]
        al = int(125 * (1 - i / 16) * rng.uniform(0.35, 1.0))
        rd.text((x, y + i * 21), ch, font=gf, fill=col + (al,))
img = Image.alpha_composite(img, rain.filter(ImageFilter.GaussianBlur(1)))

# ── 5. HUD ───────────────────────────────────────────────────────────
hud = Image.new("RGBA", (W, H), (0, 0, 0, 0))
hd = ImageDraw.Draw(hud)
mono = font(F_MONO, 16)
# top-right corner bracket
bx1, by0 = W - 70, 70
L = 46
hd.line([(bx1, by0 + L), (bx1, by0), (bx1 - L, by0)], fill=GREEN + (210,), width=3)
hd.text((bx1 - 300, by0 + 8), "ICE // ACTIVE", font=mono, fill=GREEN + (225,))
# bottom-left corner bracket
hd.line([(70, H - 70 - L), (70, H - 70), (70 + L, H - 70)], fill=VIOLET + (210,), width=3)

# thin scan ticks along the left edge
for i in range(9):
    y = H * 0.30 + i * 26
    hd.line([(70, y), (70 + (14 if i % 2 else 24), y)], fill=GREEN + (110,), width=2)
img = Image.alpha_composite(img, hud)

# ── 6. typography (small, doesn't fight the art) ─────────────────────
txt = Image.new("RGBA", (W, H), (0, 0, 0, 0))
td = ImageDraw.Draw(txt)

spaced(td, (146, H - 268), "CAPRICORN", font(F_BOLD, 76), GREEN + (70,), spacing=9)
spaced(td, (136, H - 274), "CAPRICORN", font(F_BOLD, 76), VIOLET + (80,), spacing=9)
spaced(td, (141, H - 274), "CAPRICORN", font(F_BOLD, 76), PAPER + (255,), spacing=9)

td.rectangle([144, H - 176, 144 + 220, H - 173], fill=GREEN + (225,))
td.rectangle([374, H - 176, 374 + 64, H - 173], fill=VIOLET + (225,))
spaced(td, (144, H - 164), "NET_54.7 // BLACKWALL", font(F_RAJ, 24),
       (176, 168, 180) + (255,), spacing=4)

img = Image.alpha_composite(img, txt)

# ── 7. glitch bands + chromatic split on the vertical centre ─────────
for _ in range(4):
    y = int(rng.uniform(H * 0.08, H * 0.9))
    h = int(rng.uniform(3, 9))
    shift = int(rng.uniform(-22, 22))
    strip = img.crop((0, y, W, y + h))
    img.paste(strip, (shift, y))

# ── 8. texture ────────────────────────────────────────────────────────
scan = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd = ImageDraw.Draw(scan)
for y in range(0, H, 4):
    sd.line([(0, y), (W, y)], fill=(0, 0, 0, 16))
img = Image.alpha_composite(img, scan)

vig = Image.new("L", (W, H), 0)
ImageDraw.Draw(vig).ellipse([-W * 0.2, -H * 0.28, W * 1.2, H * 1.28], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(320))
dark = Image.new("RGBA", (W, H), (0, 0, 0, 255))
dark.putalpha(ImageChops.invert(vig).point(lambda v: int(v * 0.42)))
img = Image.alpha_composite(img, dark)

noise = Image.effect_noise((W, H), 20).convert("RGB")
img = Image.blend(img.convert("RGB"), noise, 0.03).convert("RGBA")

img.convert("RGB").save(OUT, quality=95)
print(OUT)
