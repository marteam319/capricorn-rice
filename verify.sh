#!/usr/bin/env bash
# Quick health check: run after a reboot to confirm the whole setup loaded.
fail=0
chk() { if [ -e "$1" ]; then printf "  ok   %s\n" "$2"; else printf "  MISS %s (%s)\n" "$2" "$1"; fail=1; fi; }

echo "files"
chk "$HOME/.local/share/color-schemes/CyberpunkCapricorn.colors"      "colour scheme"
chk "$HOME/.local/share/konsole/CyberpunkCapricorn.profile"           "konsole profile"
chk "$HOME/.local/share/plasma/desktoptheme/Capricorn-Glass/metadata.json" "glass panel theme"
chk "$HOME/.local/share/aurorae/themes/Capricorn/metadata.desktop"    "window decoration"
chk "$HOME/.local/share/plasma/wallpapers/com.capricorn.glitch/contents/ui/main.qml"    "animated wallpaper (left)"
chk "$HOME/.local/share/plasma/wallpapers/com.capricorn.blackwall/contents/ui/main.qml" "animated wallpaper (right)"
chk "$HOME/.local/share/plasma/look-and-feel/com.capricorn.lock/contents/lockscreen/LockScreenUi.qml" "lock screen"
chk "$HOME/.config/capricorn-splash.qml"                              "loading screen"
chk "$HOME/.local/bin/capricorn-unlock-splash.sh"                     "unlock trigger script"
chk "$HOME/.config/systemd/user/capricorn-unlock-splash.service"      "unlock service"
chk "$HOME/.local/bin/capricorn-login-splash.sh" "login splash launcher"
chk "$HOME/.config/systemd/user/capricorn-boot-splash.service" "boot splash unit"
chk "$HOME/.local/share/wallpapers/capricorn-avatar.png"             "lock screen avatar"
chk "$HOME/.config/fish/functions/fish_prompt.fish"                   "fish prompt"
chk "$HOME/.config/fastfetch/config.jsonc"                            "fastfetch"
chk "$HOME/.config/spicetify/Themes/Capricorn/color.ini"              "spotify theme"

echo "settings"
printf "  %-18s %s\n" "scheme"   "$(kreadconfig6 --file "$HOME/.config/kdeglobals" --group General --key ColorScheme)"
printf "  %-18s %s\n" "accent"   "$(kreadconfig6 --file "$HOME/.config/kdeglobals" --group General --key AccentColor)"
printf "  %-18s %s\n" "panel style" "$(kreadconfig6 --file "$HOME/.config/plasmarc" --group Theme --key name)"
printf "  %-18s %s\n" "decoration" "$(kreadconfig6 --file "$HOME/.config/kwinrc" --group org.kde.kdecoration2 --key theme)"
printf "  %-18s %s\n" "lock screen" "$(kreadconfig6 --file "$HOME/.config/kdeglobals" --group KDE --key LookAndFeelPackage)"
printf "  %-18s %s\n" "ksplash" "$(kreadconfig6 --file "$HOME/.config/ksplashrc" --group KSplash --key Theme)"
printf "  %-18s %s / %s\n" "unlock service" "$(systemctl --user is-enabled capricorn-unlock-splash.service)" "$(systemctl --user is-active capricorn-unlock-splash.service)"

echo "wallpapers"
python3 - "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" <<'EOF'
import re, os, sys
s = open(sys.argv[1]).read()
for m in re.finditer(r'Image=file://(\S+)', s):
    p = m.group(1)
    if '/home/lara' in p:
        continue
    print(("  ok   " if os.path.exists(p) else "  MISS ") + p.split('/')[-1])
for m in re.finditer(r'wallpaperplugin=(com\.capricorn\.\S+)', s):
    print("  plugin " + m.group(1))
EOF

echo
if [ "$fail" -eq 0 ]; then echo "Everything present."; else echo "Something is missing — restore from the backup tarball."; fi
