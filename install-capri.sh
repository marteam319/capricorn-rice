#!/usr/bin/env bash
# Install the Capri desktop construct: transmission chat, roaming pet, agent bridge.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

# stop old companion processes so they load the new files
pkill -f '^qml6 .*capri-chat\.qml$' 2>/dev/null || true
pkill -f '^qml6 .*capri-pet\.qml$' 2>/dev/null || true

mkdir -p "$HOME/.local/share/capricorn/assets" "$HOME/.local/share/capricorn/workspace" \
         "$HOME/.local/bin" "$HOME/.local/share/plasma/plasmoids" \
         "$HOME/.config/systemd/user" "$HOME/.config/autostart"

install -m 644 "$ROOT"/capri/assets/* "$HOME/.local/share/capricorn/assets/"
install -m 644 "$ROOT/capri/capri-chat.qml" "$HOME/.local/share/capricorn/capri-chat.qml"
install -m 644 "$ROOT/capri/capri-pet.qml" "$HOME/.local/share/capricorn/capri-pet.qml"
install -m 644 "$ROOT/capri/capri-intro.qml" "$HOME/.local/share/capricorn/capri-intro.qml"
install -m 644 "$ROOT/capri/capri-pet-rule.js" "$HOME/.local/share/capricorn/capri-pet-rule.js"
install -m 644 "$ROOT/capri/capri-kwin-tracker.js" "$HOME/.local/share/capricorn/capri-kwin-tracker.js"
install -m 755 "$ROOT/capri/capri-active-window.sh" "$HOME/.local/share/capricorn/capri-active-window.sh"
install -m 644 "$ROOT/capri/capri-pet-rule.js" "$HOME/.local/share/capricorn/capri-pet-rule.js"
install -m 644 "$ROOT/capri/capri-kwin-tracker.js" "$HOME/.local/share/capricorn/capri-kwin-tracker.js"
install -m 755 "$ROOT/capri/capri-active-window.sh" "$HOME/.local/share/capricorn/capri-active-window.sh"
install -m 644 "$ROOT/capri/AGENTS.md" "$HOME/.local/share/capricorn/workspace/AGENTS.md"
install -m 755 "$ROOT/capri/capri-agent.py" "$HOME/.local/share/capricorn/capri-agent.py"
install -m 755 "$ROOT/capri/capri-chat-open.sh" "$HOME/.local/bin/capri-chat-open.sh"
install -m 755 "$ROOT/capri/capri-pet-open.sh" "$HOME/.local/bin/capri-pet-open.sh"
install -m 755 "$ROOT/capri/capri-intro-open.sh" "$HOME/.local/bin/capri-intro-open.sh"
install -m 755 "$ROOT/capri/capri-summon.sh" "$HOME/.local/bin/capri-summon.sh"
install -m 755 "$ROOT/capri/capri-opencode.sh" "$HOME/.local/bin/capri-opencode.sh"
install -m 755 "$ROOT/capri/capri-session.sh" "$HOME/.local/bin/capri-session.sh"
install -m 644 "$ROOT/capri/capri-agent.service" "$HOME/.config/systemd/user/capri-agent.service"
install -m 644 "$ROOT/capri/capri-pet.desktop" "$HOME/.config/autostart/capri-pet.desktop"

rm -rf "$HOME/.local/share/plasma/plasmoids/com.capricorn.capri"
cp -r "$ROOT/plasmoid/com.capricorn.capri" "$HOME/.local/share/plasma/plasmoids/com.capricorn.capri"

sed -i "s|/home/marteam|$HOME|g" \
    "$HOME/.local/share/capricorn/capri-chat.qml" \
    "$HOME/.local/share/capricorn/capri-pet.qml" \
    "$HOME/.local/share/capricorn/capri-intro.qml" \
    "$HOME/.local/bin/capri-chat-open.sh" \
    "$HOME/.local/bin/capri-summon.sh" \
    "$HOME/.local/bin/capri-opencode.sh" \
    "$HOME/.local/bin/capri-session.sh" \
    "$HOME/.config/autostart/capri-pet.desktop" \
    "$HOME/.local/share/plasma/plasmoids/com.capricorn.capri/contents/ui/main.qml"

kwriteconfig6 --file kwinrulesrc --group capipopup --key Description "Capri transmission popup"
kwriteconfig6 --file kwinrulesrc --group capipopup --key title "CAPRI // TRANSMISSION"
kwriteconfig6 --file kwinrulesrc --group capipopup --key titlematch 1
kwriteconfig6 --file kwinrulesrc --group capipopup --key skiptaskbar true
kwriteconfig6 --file kwinrulesrc --group capipopup --key skiptaskbarrule 2
kwriteconfig6 --file kwinrulesrc --group capipopup --key keepbelow true
kwriteconfig6 --file kwinrulesrc --group capipopup --key keepbelowrule 2
kwriteconfig6 --file kwinrulesrc --group capriintro --key Description "Capri intro"
kwriteconfig6 --file kwinrulesrc --group capriintro --key title "CAPRI // INTRO"
kwriteconfig6 --file kwinrulesrc --group capriintro --key titlematch 1
kwriteconfig6 --file kwinrulesrc --group capriintro --key skiptaskbar true
kwriteconfig6 --file kwinrulesrc --group capriintro --key skiptaskbarrule 2
kwriteconfig6 --file kwinrulesrc --group capriintro --key keepbelow true
kwriteconfig6 --file kwinrulesrc --group capriintro --key keepbelowrule 2
kwriteconfig6 --file kwinrulesrc --group capriperch --key Description "Capri perch"
kwriteconfig6 --file kwinrulesrc --group capriperch --key title "CAPRI // PERCH"
kwriteconfig6 --file kwinrulesrc --group capriperch --key titlematch 1
kwriteconfig6 --file kwinrulesrc --group capriperch --key skiptaskbar true
kwriteconfig6 --file kwinrulesrc --group capriperch --key skiptaskbarrule 2
kwriteconfig6 --file kwinrulesrc --group capriperch --key keepbelow true
kwriteconfig6 --file kwinrulesrc --group capriperch --key keepbelowrule 2
kwriteconfig6 --file kwinrulesrc --group General --key Order "steam,cap0,cap1,capipopup,capriintro,capriperch"
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true

systemctl --user daemon-reload
systemctl --user enable --now capri-agent.service
systemctl --user restart capri-agent.service

systemctl --user restart plasma-plasmashell
sleep 4

qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var d = desktops().filter(function(x){ return x.screen === 0 })[0]
var ws = d.widgets()
var found = false
for (var i = 0; i < ws.length; i++) if (ws[i].type === "com.capricorn.capri") found = true
if (!found) d.addWidget("com.capricorn.capri", 32, 430, 176, 176)
' >/dev/null 2>&1 || true

"$HOME/.local/bin/capri-pet-open.sh"

echo "Capri installed."
echo "  chat:  click the portrait widget or the roaming pet"
echo "  agent: systemctl --user status capri-agent"
echo "  model: CAPRI_MODEL (default opencode-go/deepseek-v4.1-flash)"
