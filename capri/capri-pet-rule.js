// Keep Capri's overlay, popup and intro on the wallpaper, out of the taskbar.
const ws = workspace.windowList ? workspace.windowList() : workspace.clientList();
for (const w of ws) {
    if (w.caption === "CAPRI // PROJECT CAPRICORN" || w.caption === "CAPRI // TRANSMISSION"
            || w.caption === "CAPRI // INTRO") {
        w.keepBelow = true;
        w.skipTaskbar = true;
    }
}
