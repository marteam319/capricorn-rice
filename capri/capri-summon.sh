#!/usr/bin/env bash
# Tell the wallpaper pet to pop out of the portrait, then open the chat.
gx="${1:-0}"; gy="${2:-0}"
[[ "$gx" =~ ^-?[0-9]+$ ]] || gx=0
[[ "$gy" =~ ^-?[0-9]+$ ]] || gy=0
curl -s --max-time 2 -X POST http://127.0.0.1:8787/summon \
    -H 'Content-Type: application/json' \
    -d "{\"x\":$gx,\"y\":$gy}" >/dev/null 2>&1 || true
sleep 1.5
"$HOME/.local/bin/capri-chat-open.sh"
