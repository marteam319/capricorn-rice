#!/usr/bin/env bash
# Install the Capri desktop companion (pet widget + floating dialogue).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$HOME/.local/share/capricorn" "$HOME/.local/bin" "$HOME/.local/share/plasma/plasmoids"

install -m 644 "$ROOT/capri/capri-chat.qml" "$HOME/.local/share/capricorn/capri-chat.qml"
install -m 644 "$ROOT/capri/capri-avatar.png" "$HOME/.local/share/capricorn/capri-avatar.png"
install -m 755 "$ROOT/capri/capri-chat-open.sh" "$HOME/.local/bin/capri-chat-open.sh"
install -m 755 "$ROOT/capri/capri-session.sh" "$HOME/.local/bin/capri-session.sh"

rm -rf "$HOME/.local/share/plasma/plasmoids/com.capricorn.capri"
cp -r "$ROOT/plasmoid/com.capricorn.capri" "$HOME/.local/share/plasma/plasmoids/com.capricorn.capri"

sed -i "s|/home/marteam|$HOME|g" \
    "$HOME/.local/share/capricorn/capri-chat.qml" \
    "$HOME/.local/bin/capri-chat-open.sh" \
    "$HOME/.local/bin/capri-session.sh" \
    "$HOME/.local/share/plasma/plasmoids/com.capricorn.capri/contents/ui/main.qml"

systemctl --user restart plasma-plasmashell
sleep 4

qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var d = desktops().filter(function(x){ return x.screen === 0 })[0]
var ws = d.widgets()
var found = false
for (var i = 0; i < ws.length; i++) if (ws[i].type === "com.capricorn.capri") found = true
if (!found) d.addWidget("com.capricorn.capri", 32, 430, 176, 176)
' >/dev/null 2>&1 || true

echo "Capri companion installed. Click the pet to open her dialogue."
