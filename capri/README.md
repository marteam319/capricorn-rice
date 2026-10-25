# Capri // desktop construct

Port of the *look and behaviour* of [mochiiwuff/capri-desktop](https://github.com/mochiiwuff/capri-desktop)
into the Capricorn KDE Plasma 6 rice.

- **assets/** — Capri faces, cut-ins, icon and full-body cut-out from that repo (fan art from the show;
  the repo's MIT licence covers its code, not the character art — credit CD PROJEKT RED / Studio Trigger / Netflix).
- **capri-chat.qml** — chamfered violet transmission panel with the eight faces, Chakra Petch + JetBrains Mono,
  quick actions and a text input wired to a local OpenCode agent.
- **capri-pet.qml** — 300×540 XWayland overlay: cel-style float, teleports, peeks, shards, glitch, sleep,
  drag, right-click menu, speech ticker. KWin keeps the overlay in the **Below** layer and out of the taskbar,
so normal applications cover her: she is only visible on the wallpaper.
- **capri-agent.py** — 127.0.0.1 bridge that runs `opencode run` with a Capri persona, keeps one session,
  and returns the answer. `--auto` lets the agent act on the machine.
- **capri-pet.desktop** — autostart entry for the roaming overlay.
- **capri-intro.qml** — the repo's `intro-face.webp` strip as a top-right shutter intro ("hi"), played at login.
- **Transmission popup** — a compact in-world panel beside her: "MISSION ACCOMPLIE, CHOOM.", the agent's reply,
  and "◆ N actions · Xs". Shown on summon and when the background agent finishes.
- **Teleport warp** — she collapses into a red line with shards and reassembles at the destination.
- **Window sitting is not enabled.** The reference app sits on (and possesses) windows by drawing above them.
  This pet is deliberately in KWin's Below layer ("only on wallpaper"), so an application always covers her legs.
  A real perch needs a topmost exception; see the installer notes.
- Clicking the portrait widget fires `/summon`: the card flashes and pulses, the pet teleports to the card's
  exact screen position and pops out of it (0.05 → 1.12 → 1 scale, glitch ghosts/slices, shards, "hey!"),
  then the chat opens after 1.5 s.

The Windows-only tricks from the original (sitting on arbitrary windows, possessing them, tracking Claude Code
via hooks) are not ported; the overlay roams the screen, peeks from edges, sleeps, and reacts instead.
