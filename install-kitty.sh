#!/usr/bin/env bash
# Install kitty + the branded Capricorn Terminal launcher, its transparent
# OpenCode theme, and make it the default terminal.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.config/kitty" "$HOME/.config/opencode/themes" \
         "$HOME/.local/bin" "$HOME/.local/share/applications" \
         "$HOME/.local/share/icons/hicolor/256x256/apps" \
         "$HOME/.config/fish/functions"

install -m 644 "$ROOT/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
install -m 644 "$ROOT/opencode/themes/capricorn.json" "$HOME/.config/opencode/themes/capricorn.json"
[ -f "$HOME/.config/opencode/cli.json" ] || install -m 644 "$ROOT/opencode/cli.json" "$HOME/.config/opencode/cli.json"

install -m 755 "$ROOT/terminal/capricorn-terminal" "$HOME/.local/bin/capricorn-terminal"
install -m 644 "$ROOT/terminal/capricorn-terminal.desktop" "$HOME/.local/share/applications/capricorn-terminal.desktop"
sed -i "s|/home/marteam|$HOME|g" "$HOME/.local/share/applications/capricorn-terminal.desktop"
install -m 644 "$ROOT/terminal/capricorn-terminal.png" "$HOME/.local/share/icons/hicolor/256x256/apps/capricorn-terminal.png"
install -m 644 "$ROOT/fish/fish_title.fish" "$HOME/.config/fish/functions/fish_title.fish"

kwriteconfig6 --file kdeglobals --group General --key TerminalApplication "$HOME/.local/bin/capricorn-terminal"
kwriteconfig6 --file kdeglobals --group General --key TerminalService capricorn-terminal.desktop

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
kbuildsycoca6 --noincremental 2>/dev/null || true
systemctl --user restart plasma-plasmashell

echo "Capricorn Terminal installed (kitty under the hood)."
echo "Title bar: CAPRICORN // TERMINAL — app name: Capricorn Terminal."
echo "Pin 'Capricorn Terminal' from the app menu / taskbar."
