const ws = workspace.windowList ? workspace.windowList() : workspace.clientList();
for (const w of ws) {
    if (w.caption === "CAPRI // PROJECT CAPRICORN" || w.caption === "CAPRI // TRANSMISSION"
            || w.caption === "CAPRI // INTRO" || w.caption === "CAPRI // PERCH") {
        w.keepBelow = true;
        w.skipTaskbar = true;
    }
}
