#!/usr/bin/env bash
# Installs the Capricorn SDDM theme. Needs your password (run it yourself).
set -euo pipefail
cd "$(dirname "$0")"

sudo cp -r sddm/capricorn /usr/share/sddm/themes/
sudo chmod -R a+rX /usr/share/sddm/themes/capricorn
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=capricorn\n' | sudo tee /etc/sddm.conf.d/10-capricorn.conf >/dev/null

echo "Installed. Preview without logging out:"
echo "  sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/capricorn"
echo "It takes effect on the next logout/reboot."
