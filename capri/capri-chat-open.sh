#!/usr/bin/env bash
# Open (or close, when already open) Capri's little dialogue window.
if pgrep -f "^qml6 .*capri-chat\.qml$" >/dev/null 2>&1; then
    pkill -f "^qml6 .*capri-chat\.qml$"
    exit 0
fi
setsid qml6 "$HOME/.local/share/capricorn/capri-chat.qml" >/tmp/capri-chat.log 2>&1 < /dev/null &
