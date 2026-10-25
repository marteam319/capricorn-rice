#!/usr/bin/env bash
# Roll back to the pre-Cyberpunk state (Catppuccin Mauve).
set -euo pipefail

B=$HOME/.config.backup_pre_cyberpunk
[ -d "$B" ] || { echo "No backup found at $B"; exit 1; }

for f in kdeglobals konsolerc plasma-org.kde.plasma.desktop-appletsrc; do
    [ -f "$B/$f" ] && cp -a "$B/$f" "$HOME/.config/$f"
done

plasma-apply-colorscheme CatppuccinMacchiatoMauve || true
kbuildsycoca6 --noincremental 2>/dev/null || true
echo "Reverted configs from $B. Reload Plasma (or log out) to fully refresh."
