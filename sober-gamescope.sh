#!/usr/bin/env bash
# Run Sober inside gamescope — fixes the host cursor freezing in Roblox.
exec gamescope -f -W 1920 -H 1080 -- flatpak run org.vinegarhq.Sober "$@"
