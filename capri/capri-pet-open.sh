#!/usr/bin/env bash
# Start Capri's wallpaper-level overlay (XWayland so she can move herself).
if pgrep -f '^qml6 .*capri-pet\.qml$' >/dev/null 2>&1; then
    exit 0
fi
for i in $(seq 1 24); do
    xdpyinfo -display "${DISPLAY:-:0}" >/dev/null 2>&1 && break
    sleep 0.25
done
setsid env QT_QPA_PLATFORM=xcb DISPLAY="${DISPLAY:-:0}" \
    qml6 "$HOME/.local/share/capricorn/capri-pet.qml" >/tmp/capri-pet.log 2>&1 < /dev/null &
"$HOME/.local/bin/capri-intro-open.sh"
sleep 1
# ensure KWin keeps her below normal windows and out of the taskbar
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript \
    "$HOME/.local/share/capricorn/capri-pet-rule.js" >/dev/null 2>&1 || true
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.start >/dev/null 2>&1 || true
