#!/usr/bin/env bash
# Open (or close, when already open) the big Breach Protocol panel.
if pgrep -f "qml6 .*breach-window.qml" >/dev/null 2>&1; then
    pkill -f "qml6 .*breach-window.qml"
    exit 0
fi
setsid qml6 "$HOME/.local/share/capricorn/breach-window.qml" >/tmp/capricorn-breach-window.log 2>&1 < /dev/null &
