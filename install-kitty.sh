#!/usr/bin/env bash
# Install kitty + matching transparent OpenCode theme, and make kitty the default terminal.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.config/kitty" "$HOME/.config/opencode/themes"
install -m 644 "$ROOT/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf"
install -m 644 "$ROOT/opencode/themes/capricorn.json" "$HOME/.config/opencode/themes/capricorn.json"
[ -f "$HOME/.config/opencode/cli.json" ] || install -m 644 "$ROOT/opencode/cli.json" "$HOME/.config/opencode/cli.json"

kwriteconfig6 --file kdeglobals --group General --key TerminalApplication kitty
kwriteconfig6 --file kdeglobals --group General --key TerminalService kitty.desktop

systemctl --user restart plasma-plasmashell

echo "kitty installed and set as the default terminal."
echo "75% transparent, KDE Capricorn palette, OpenCode background transparent."
