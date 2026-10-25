#!/usr/bin/env bash
# Re-apply the Cyberpunk Capricorn theme (idempotent).
set -euo pipefail

SCHEME=CyberpunkCapricorn
WALL=$HOME/.local/share/wallpapers/capricorn-character.png

plasma-apply-colorscheme "$SCHEME" 2>/dev/null || true

# Plasma 6 accent colour overrides the scheme's highlight colours, so pin it
# and force a real re-apply (plasma-apply no-ops if the scheme already matches).
kwriteconfig6 --file kdeglobals --group General --key AccentColor "255,10,84"
plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
plasma-apply-colorscheme "$SCHEME" >/dev/null 2>&1 || true

plasma-apply-wallpaperimage "$WALL"
mkdir -p "$HOME/.config/kitty" "$HOME/.local/bin" "$HOME/.local/share/applications" \
  "$HOME/.local/share/icons/hicolor/256x256/apps" "$HOME/.config/fish/functions"
cp "$(dirname "$0")/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
cp "$(dirname "$0")/terminal/capricorn-terminal" "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/capricorn-terminal"
cp "$(dirname "$0")/terminal/capricorn-terminal.desktop" "$HOME/.local/share/applications/"
sed -i "s|/home/marteam|$HOME|g" "$HOME/.local/share/applications/capricorn-terminal.desktop"
cp "$(dirname "$0")/terminal/capricorn-terminal.png" "$HOME/.local/share/icons/hicolor/256x256/apps/"
cp "$(dirname "$0")/fish/fish_title.fish" "$HOME/.config/fish/functions/fish_title.fish"
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "$HOME/.local/bin/capricorn-terminal"
kwriteconfig6 --file kdeglobals --group General --key TerminalService capricorn-terminal.desktop
kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "$SCHEME.profile"
kwriteconfig6 --file kdeglobals --group WM --key activeFont "Chakra Petch,11,-1,5,50,0,0,0,0,0"

# Konsole needs a nudge to pick up a newly created profile
kbuildsycoca6 --noincremental 2>/dev/null || true

echo "Applied $SCHEME."
