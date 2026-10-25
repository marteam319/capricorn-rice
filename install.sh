#!/usr/bin/env bash
# Rebuild the Capricorn setup on this machine (or a fresh install).
# Requires: Plasma 6, Konsole, fish, fastfetch, rsvg-convert, python3-Pillow.
set -euo pipefail
cd "$(dirname "$0")"

echo "== colours + wallpaper + lock screen =="
./apply.sh
kwriteconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin "org.kde.image"
kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General \
  --key Image "file://$HOME/.local/share/wallpapers/capricorn-character.png"

echo "== glass panels =="
mkdir -p "$HOME/.local/share/plasma/desktoptheme"
[ -d "$HOME/.local/share/plasma/desktoptheme/Capricorn-Glass" ] || \
  cp -a /usr/share/plasma/desktoptheme/default "$HOME/.local/share/plasma/desktoptheme/Capricorn-Glass"
kwriteconfig6 --file plasmarc --group Theme --key name "Capricorn-Glass"

echo "== window decoration =="
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library "org.kde.kwin.aurorae.v2"
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme "__aurorae__svg__Capricorn"

echo "== terminal =="
kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "CyberpunkCapricorn.profile"
kwriteconfig6 --file "$HOME/.local/share/konsole/CyberpunkCapricorn.profile" \
  --group General --key LocalTabTitleFormat "capricorn"

echo "== animation + splash =="
./animations.sh

echo "== animated wallpaper =="
python3 generate_glitch_frames.py
cp -a . "$HOME/.local/share/plasma/wallpapers/com.capricorn.glitch" 2>/dev/null || true

echo "== screens =="
./set-screens.sh
echo
echo "Done. Log out/in for the decoration and title to refresh."
echo "SDDM theme is staged in ./sddm/capricorn — install with:"
echo "  sudo cp -r sddm/capricorn /usr/share/sddm/themes/"
echo "  echo -e '[Theme]\\nCurrent=capricorn' | sudo tee /etc/sddm.conf.d/10-capricorn.conf"
