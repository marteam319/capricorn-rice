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
mkdir -p "$HOME/.config/kitty"
cp "$(dirname "$0")/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
kwriteconfig6 --file kdeglobals --group General --key TerminalService kitty.desktop
kwriteconfig6 --file konsolerc --group "Desktop Entry" --key DefaultProfile "$SCHEME.profile"
kwriteconfig6 --file kdeglobals --group WM --key activeFont "Chakra Petch,11,-1,5,50,0,0,0,0,0"

# Konsole needs a nudge to pick up a newly created profile
kbuildsycoca6 --noincremental 2>/dev/null || true

echo "Applied $SCHEME."
