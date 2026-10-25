#!/usr/bin/env bash
# Rebuild the Capricorn setup on this machine (or a fresh install).
# Requires: Plasma 6, kitty, fish, fastfetch, rsvg-convert, python3-Pillow.
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
mkdir -p "$HOME/.config/kitty" "$HOME/.config/opencode/themes" \
  "$HOME/.local/bin" "$HOME/.local/share/applications" \
  "$HOME/.local/share/icons/hicolor/256x256/apps" "$HOME/.config/fish/functions"
cp kitty/kitty.conf "$HOME/.config/kitty/kitty.conf"
cp opencode/themes/capricorn.json "$HOME/.config/opencode/themes/capricorn.json"
[ -f "$HOME/.config/opencode/cli.json" ] || cp opencode/cli.json "$HOME/.config/opencode/cli.json"
cp terminal/capricorn-terminal "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/capricorn-terminal"
cp terminal/capricorn-terminal.desktop "$HOME/.local/share/applications/"
sed -i "s|/home/marteam|$HOME|g" "$HOME/.local/share/applications/capricorn-terminal.desktop"
cp terminal/capricorn-terminal.png "$HOME/.local/share/icons/hicolor/256x256/apps/"
cp fish/fish_title.fish "$HOME/.config/fish/functions/fish_title.fish"
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "$HOME/.local/bin/capricorn-terminal"
kwriteconfig6 --file kdeglobals --group General --key TerminalService capricorn-terminal.desktop
# keep Konsole themed as a fallback
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
