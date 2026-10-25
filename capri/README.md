# Capri // desktop construct

Port of the *look and behaviour* of [mochiiwuff/capri-desktop](https://github.com/mochiiwuff/capri-desktop)
into the Capricorn KDE Plasma 6 rice.

- **assets/** — Capri faces, cut-ins, icon and full-body cut-out from that repo (fan art from the show;
  the repo's MIT licence covers its code, not the character art — credit CD PROJEKT RED / Studio Trigger / Netflix).
- **capri-chat.qml** — chamfered violet transmission panel with the eight faces, Chakra Petch + JetBrains Mono,
  quick actions and a text input wired to a local OpenCode agent.
- **capri-pet.qml** — 300×540 XWayland overlay: cel-style float, teleports, peeks, shards, glitch, sleep,
  drag, right-click menu, speech ticker.
- **capri-agent.py** — 127.0.0.1 bridge that runs `opencode run` with a Capri persona, keeps one session,
  and returns the answer. `--auto` lets the agent act on the machine.
- **capri-pet.desktop** — autostart entry for the roaming overlay.

The Windows-only tricks from the original (sitting on arbitrary windows, possessing them, tracking Claude Code
via hooks) are not ported; the overlay roams the screen, peeks from edges, sleeps, and reacts instead.
