// Keep the Capri overlay on the wallpaper, out of the taskbar.
const ws = workspace.windowList ? workspace.windowList() : workspace.clientList();
for (const w of ws) {
    if (w.caption === "CAPRI // PROJECT CAPRICORN") {
        w.keepBelow = true;
        w.skipTaskbar = true;
    }
}
