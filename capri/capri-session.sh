#!/usr/bin/env bash
# Start the full desktop session: Discord (Equibop), Firefox, Spotify, Steam.
set -u

launch() {
    setsid "$@" >/dev/null 2>&1 < /dev/null &
    sleep 0.35
}

# "Discord" on this machine is Equibop. Fall back to the official client.
if command -v equibop >/dev/null 2>&1; then
    launch equibop
else
    latest=$(ls -d "$HOME"/.config/discord/app-*/Discord 2>/dev/null | sort -V | tail -1)
    [ -n "${latest:-}" ] && [ -x "$latest" ] && launch "$latest"
fi

launch firefox
launch spotify
launch steam
