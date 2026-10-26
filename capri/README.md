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
- **Little idle acts** — right-click → **BOX FORM**: she folds into a chamfered biochip box with her face in it,
  floats, and unfolds. **SHOOT STAR**: she looks up and fires a four-point green star at the little star above her.
  Both also happen on their own while she wanders.
- **Intro** — the reference intro cels (grab, mouth, wave, smear) play behind a shutter, with the
  `hi` / `you're back` / `let's go` lines, her face and waving hand on the wallpaper.
- **Perch** — right-click her → **PERCH**. The active window is tracked via a KWin script; she shows her upper body
  on the window's top edge, cropped to the torso, legs hidden behind the window. She stays in the Below layer, so
  the app still covers her lower half and she never draws over app content. Maximized windows cannot be perched on.
- **Sleep mask** — right-click → **SLEEP** (or 10 quiet minutes): she leans back wearing a green sleep mask over her
  face, body still visible, and wakes on hover/click.
- **INTRO** in her menu replays the intro cel sequence (her face, mouth and wave).
- Remaining reference features (window possession with eyes, Claude Code window tracking/pointing) need a topmost
  overlay that draws over apps; they are not enabled in wallpaper-only mode.
- Clicking the portrait widget fires `/summon`: the card flashes and pulses, the pet teleports to the card's
  exact screen position and pops out of it (0.05 → 1.12 → 1 scale, glitch ghosts/slices, shards, "hey!"),
  then the chat opens after 1.5 s.

The Windows-only tricks from the original (sitting on arbitrary windows, possessing them, tracking Claude Code
via hooks) are not ported; the overlay roams the screen, peeks from edges, sleeps, and reacts instead.
