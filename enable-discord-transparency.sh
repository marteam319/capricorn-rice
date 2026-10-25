#!/usr/bin/env bash
# Equibop must be closed, otherwise it overwrites settings.json on exit.
set -e
if pgrep -f equibop >/dev/null; then
    echo "Equibop is running — quit it fully (tray icon → Quit), then run again."
    exit 1
fi
python3 - <<'PY'
import json
for p in ['/home/marteam/.config/equibop/settings/settings.json',
          '/home/marteam/.config/Equicord/settings/settings.json']:
    d = json.load(open(p))
    d['transparent'] = True
    json.dump(d, open(p, 'w'), indent=4)
    print("transparent=true ->", p)
PY
echo "Done. Start Equibop again."
