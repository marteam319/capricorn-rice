#!/usr/bin/env bash
journalctl --user -u plasma-kwin_wayland --no-pager -n 900 2>/dev/null | grep -o 'CAPRIWIN|.*' | tail -1
