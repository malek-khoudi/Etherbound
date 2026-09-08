# Codex task 01 notes: playable gantry bay

Completed on `codex/playable-bay` on 2026-09-08.

## What is on screen

- A procedural 3D greybox of the footing, column, main beam, walkway, feedstock crate and
  visibly overloaded corroded bracket from `incident_test.gd`.
- Right-drag orbital camera and mouse-wheel zoom.
- Clickable structural members with member load, capacity and utilisation plus the carrying
  connection's own load, capacity and utilisation.
- Kess and Maren selectors, Kess reserve and the real `Incident.rounds_sustainable()` value.
- The real `Structure.anchor_report()` reason while Kess hovers a structural member.
- Brace, prop, End Turn and restart controls; a chronological incident log; visible brace,
  physical prop and walkway/crate collapse states.
- Failure after the third turn without a prop, and success when Maren props the walkway in
  round two before Kess loses the hold.

The scene data is in `game/scenes/playable_bay.json`; the bay, camera and HUD are constructed
in GDScript. `game/scenes/main.tscn` is only the minimum Node3D/script bootstrap required for
Godot's normal Run Project command. It contains no authored scene content.

## Visual direction

Malek's untracked images in `art/concept/` were consulted as mood references only. The
prototype uses their dark iron/stone, restrained brass, amber diagnostic and red hazard
language while remaining an untextured box greybox. Text visible inside generated concept
art was not treated as canon or copied into the game.

## Verification

- `./tools/test.sh`: all three existing suites print `=== ALL PASS ===`.
- A temporary headless presentation harness exercised both paths end to end and printed
  `=== PRESENTATION FLOW PASS ===`: brace, 90 reserve, 30 reserve, zero/fall; then restart,
  brace, round-two prop, zero reserve with no overload and no fall. The harness was removed.
- A rendered 1440×810 frame was captured and inspected: the bay, 114% bracket warning,
  selected-member 400/900 readout, 400/350 connection readout, anchor reason, controls and
  log are all visible without overlap. Temporary capture files were removed.

The Windows app-control bridge exposed no native-app target, so mouse-driven orbit, hover
and click feel still need Malek's manual judgement. Their code paths compile and the
coordinator path is covered by the presentation harness above.

## Core issue left untouched

`Structure.anchor_report()` builds the failure percentage from the post-reaction probe but
calls it "before you push." The presentation intentionally renders the returned core text
unchanged. This is recorded in `docs/TASKS.md` for the next core owner.
