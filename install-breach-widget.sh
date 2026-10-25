#!/usr/bin/env bash
# Install the Breach Protocol desktop widget (plasmoid).
set -e
SRC="$(cd "$(dirname "$0")" && pwd)/plasmoid/com.capricorn.breach"
DEST="$HOME/.local/share/plasma/plasmoids/com.capricorn.breach"
mkdir -p "$DEST"
cp -r "$SRC"/. "$DEST"/
systemctl --user restart plasma-plasmashell
echo "Breach Protocol widget installed."
echo "Enable it: right-click desktop -> Enter Edit Mode -> Add Widgets -> Breach Protocol."
