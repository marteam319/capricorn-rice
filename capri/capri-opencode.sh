#!/usr/bin/env bash
# Open a branded kitty window with OpenCode already running, detached from Capri's chat.
cd "$HOME/Projekty/cyberpunk-capricorn" 2>/dev/null || cd "$HOME"
setsid kitty --class capricorn-terminal -o shell_integration=no-title \
  --hold --directory "$PWD" --title "OpenCode // Capricorn" opencode >/dev/null 2>&1 < /dev/null &
