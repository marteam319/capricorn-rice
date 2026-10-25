#!/usr/bin/env python3
"""Build ~/.local/share/icons/Capricorn-Wine — bar icons only.

Only the icons pinned to the bar plus the launcher are recoloured. Everything
else inherits Papirus-Dark unchanged (this is the version that looked right).
"""

import os
import subprocess
import tempfile

import numpy as np
from PIL import Image

THEME = os.path.expanduser("~/.local/share/icons/Capricorn-Wine")
SIZES = [16, 22, 24, 32, 48, 64, 128, 256]

SOURCES = {
    "utilities-terminal": "/usr/share/icons/breeze/apps/48/utilities-terminal.svg",
    "org.kde.dolphin": "/usr/share/icons/hicolor/scalable/apps/org.kde.dolphin.svg",
    "firefox": "/usr/share/icons/hicolor/scalable/apps/firefox.svg",
    "steam": "/usr/share/icons/hicolor/256x256/apps/steam.png",
    "com.heroicgameslauncher.hgl": "/usr/share/icons/hicolor/scalable/com.heroicgameslauncher.hgl.svg",
    "equibop": "/usr/share/pixmaps/equibop.png",
    "spotify-client": "/usr/share/icons/char-white/apps/16/spotify-client.svg",
    "start-here-kde": "/usr/share/icons/breeze/places/16/start-here-kde.svg",
}

STOPS = [
    (0.00, (16, 5, 9)),
    (0.22, (74, 10, 24)),
    (0.48, (140, 16, 38)),
    (0.72, (198, 28, 60)),
    (0.90, (236, 66, 98)),
    (1.00, (255, 152, 178)),
]
GRAD = [
    (0.00, (163, 18, 47)),
    (0.50, (177, 76, 255)),
    (1.00, (13, 255, 110)),
]


def ramp(t, stops):
    t = np.clip(t, 0, 1)[..., None]
    xs = np.array([s[0] for s in stops])
    cs = np.array([s[1] for s in stops], dtype=np.float32)
    out = np.zeros(t.shape[:-1] + (3,), dtype=np.float32)
    for c in range(3):
        out[..., c] = np.interp(t[..., 0], xs, cs[:, c])
    return out


def load_rgba(path, size=512):
    if path.lower().endswith(".svg"):
        fd, tmp = tempfile.mkstemp(suffix=".png")
        os.close(fd)
        subprocess.run(["rsvg-convert", "-w", str(size), "-o", tmp, path], check=True)
        im = Image.open(tmp).convert("RGBA")
        os.unlink(tmp)
    else:
        im = Image.open(path).convert("RGBA")
    return im


def recolor(im):
    im = im.resize((256, 256), Image.LANCZOS)
    a = np.array(im).astype(np.float32)
    rgb, alpha = a[..., :3], a[..., 3]
    lum = (0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]) / 255.0
    base = ramp(lum, STOPS)
    yy, xx = np.mgrid[0:256, 0:256].astype(np.float32)
    t = np.clip(xx / 255.0 * 0.55 + yy / 255.0 * 0.45, 0, 1)
    tint = ramp(t, GRAD)
    out = base * (0.55 + 0.45 * tint / 255.0)
    return Image.fromarray(np.dstack([np.clip(out, 0, 255), alpha]).astype(np.uint8), "RGBA")


def main():
    if os.path.isdir(THEME):
        import shutil
        shutil.rmtree(THEME)

    master = {}
    for name, src in SOURCES.items():
        if not os.path.exists(src):
            print("skip (missing):", name)
            continue
        master[name] = recolor(load_rgba(src))

    for s in SIZES:
        d = os.path.join(THEME, f"{s}x{s}", "apps")
        os.makedirs(d, exist_ok=True)
        for name, img in master.items():
            img.resize((s, s), Image.LANCZOS).save(os.path.join(d, name + ".png"))

    dirs = ",".join(f"{s}x{s}/apps" for s in SIZES)
    with open(os.path.join(THEME, "index.theme"), "w") as f:
        f.write("[Theme]\nName=Capricorn-Wine\nComment=Wine bar icons\n")
        f.write("Inherits=Papirus-Dark\nDirectories=" + dirs + "\n\n")
        for s in SIZES:
            f.write(f"[{s}x{s}/apps]\nSize={s}\nContext=Applications\nType=Fixed\n\n")
    print(f"bar icons rebuilt: {len(master)} icons")


if __name__ == "__main__":
    main()
