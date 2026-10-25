#!/usr/bin/env bash
# Sets the Capricorn visor as your account avatar (lock screen, SDDM, user menu).
set -euo pipefail
AV="$HOME/Projekty/cyberpunk-capricorn/art/capricorn-avatar.png"
UID_N="$(id -u)"

cp "$AV" "$HOME/.face"
chmod 644 "$HOME/.face"

sudo install -Dm644 "$AV" /var/lib/AccountsService/icons/marteam
sudo dbus-send --system --print-reply \
  --dest=org.freedesktop.Accounts \
  /org/freedesktop/Accounts/User"$UID_N" \
  org.freedesktop.Accounts.User.SetIconFile \
  string:"$HOME/.face" >/dev/null 2>&1 || true

echo "Avatar set. New lock screen / logout screen will show it."
