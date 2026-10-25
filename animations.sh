#!/usr/bin/env bash
# Enable the motion pass: KWin effects, Plasma animation speed, boot splash.
set -euo pipefail

for e in blur contrast diminactive fadingpopups fadedesktop magiclamp scale \
         slidingpopups squash translucency windowaperture slide maximize \
         frozenapp logout sessionquit highlightwindow glide wobblywindows; do
    kwriteconfig6 --file kwinrc --group Plugins --key "${e}Enabled" true
done

kwriteconfig6 --file kwinrc --group Effect-blur --key blurStrength 9
kwriteconfig6 --file kwinrc --group Effect-blur --key noiseStrength 1
kwriteconfig6 --file kwinrc --group Effect-diminactive --key strength 0.45
kwriteconfig6 --file kwinrc --group Effect-magiclamp --key animationDuration 300
kwriteconfig6 --file kwinrc --group Effect-scale --key duration 220
kwriteconfig6 --file kwinrc --group Compositing --key AnimationSpeed 3
kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 0.9

install -Dm644 "$(dirname "$0")/splash/splash.qml" \
    "$HOME/.config/capricorn-splash.qml"
cat > "$HOME/.config/autostart/capricorn-splash.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Capricorn Boot Splash
Exec=bash -c "sleep 1; timeout 8 qml6 $HOME/.config/capricorn-splash.qml >/dev/null 2>&1"
Terminal=false
NoDisplay=true
OnlyShowIn=KDE;
EOF

qdbus6 org.kde.KWin /KWin reconfigure || true
echo "Motion enabled. Disable splash: rm ~/.config/autostart/capricorn-splash.desktop"
echo "Preview splash: qml6 $HOME/.config/capricorn-splash.qml"
