#!/usr/bin/env bash
# Push the current wallpaper PNGs to the screens with fresh URLs.
# Plasma caches wallpapers by path, so rewriting the same filename does NOT
# reload the image. Each run writes a new versioned copy to defeat the cache.
set -euo pipefail

W=$HOME/.local/share/wallpapers
STAMP=$(date +%H%M%S)

cp "$W/capricorn-character.png"  "$W/capricorn-character-$STAMP.png"
cp "$W/capricorn-right-glow.png" "$W/capricorn-right-glow-$STAMP.png"

LEFT="file://$W/capricorn-character-$STAMP.png"
RIGHT="file://$W/capricorn-right-glow-$STAMP.png"

script=$(cat <<EOF
var ds = desktops();
var left = "$LEFT";
var right = "$RIGHT";
for (var i = 0; i < ds.length; i++) {
  var d = ds[i];
  var url = (d.screen === 0) ? left : right;
  d.wallpaperPlugin = "org.kde.image";
  d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  d.writeConfig("Image", url);
}
print("left  -> " + left.split("/").pop());
print("right -> " + right.split("/").pop());
EOF
)
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script"

# prune old versions, keep the 4 newest of each
ls -t "$W"/capricorn-character-*.png 2>/dev/null | tail -n +5 | xargs -r rm --
ls -t "$W"/capricorn-right-glow-*.png 2>/dev/null | tail -n +5 | xargs -r rm --
