// Announce the active window so the pet can sit on it.
function report() {
    const w = workspace.activeWindow;
    if (!w) return;
    print("CAPRIWIN|" + Math.round(w.frameGeometry.x) + "|" + Math.round(w.frameGeometry.y) + "|" +
          Math.round(w.frameGeometry.width) + "|" + Math.round(w.frameGeometry.height) + "|" +
          String(w.resourceClass) + "|" + String(w.caption));
}
workspace.windowActivated.connect(report);
report();
