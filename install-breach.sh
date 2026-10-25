#!/usr/bin/env bash
# Install the small Breach launcher widget and the big frameless panel it opens.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.local/share/capricorn" "$HOME/.local/bin" "$HOME/.local/share/plasma/plasmoids"

install -m 644 "$ROOT/breach/breach-window.qml" "$HOME/.local/share/capricorn/breach-window.qml"
install -m 755 "$ROOT/breach/capricorn-breach-open.sh" "$HOME/.local/bin/capricorn-breach-open.sh"

rm -rf "$HOME/.local/share/plasma/plasmoids/com.capricorn.breachlauncher"
cp -r "$ROOT/plasmoid/com.capricorn.breachlauncher" "$HOME/.local/share/plasma/plasmoids/com.capricorn.breachlauncher"
sed -i "s|/home/marteam/.local/bin|$HOME/.local/bin|g" \
    "$HOME/.local/share/plasma/plasmoids/com.capricorn.breachlauncher/contents/ui/main.qml"

# drop the old always-visible desktop panel if it is still installed
rm -rf "$HOME/.local/share/plasma/plasmoids/com.capricorn.breach"

systemctl --user restart plasma-plasmashell

echo "Installed: Breach launcher widget + big panel."
echo "Add 'Breach Protocol Launcher' from Add Widgets, then click it to open/close the panel."
