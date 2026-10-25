#!/usr/bin/env bash
# Assign a wallpaper per physical screen.
# usage: ./set-screens.sh [left-image] [right-image]
# Defaults: character art on the left screen, hair-glow on the right one.
set -euo pipefail

LEFT="${1:-$HOME/.local/share/wallpapers/capricorn-character.png}"
RIGHT="${2:-$HOME/.local/share/wallpapers/capricorn-right-glow.png}"

script=$(cat <<EOF
var left  = "file://$LEFT";
var right = "file://$RIGHT";
var ds = desktops();
var out = [];
for (var i = 0; i < ds.length; i++) {
  var d = ds[i];
  var url = (d.screen === 0) ? left : right;
  d.wallpaperPlugin = "org.kde.image";
  d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
  d.writeConfig("Image", url);
  out.push("screen " + d.screen + " -> " + url.split("/").pop());
}
print(out.join("\n"));
EOF
)
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$script"

# swap sides:  ./set-screens.sh "$RIGHT" "$LEFT"
