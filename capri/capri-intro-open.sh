#!/usr/bin/env bash
if pgrep -f '^qml6 .*capri-intro\.qml$' >/dev/null 2>&1; then exit 0; fi
setsid env QT_QPA_PLATFORM=xcb DISPLAY="${DISPLAY:-:0}" \
    qml6 "$HOME/.local/share/capricorn/capri-intro.qml" >/tmp/capri-intro.log 2>&1 < /dev/null &
