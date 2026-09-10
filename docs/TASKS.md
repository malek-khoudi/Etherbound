# Task Board and File Claims

Both agents read this BEFORE writing code. Claim your files, commit the claim, then work.
Release the claim when you finish.

---

## Active claims

| Agent | Branch | Files claimed | Started |
|---|---|---|---|

---

## Decision log

- **2026-09-08 LOCKED.** BG3-shaped narrative tactical RPG. Godot 4, stylized low-poly 3D,
  real-time exploration + turn-based incident mode, three-character party.
  Non-goals are listed in `AGENTS.md` section 1 and are decisions, not deferrals.

---

## Now

- [x] Repo created and pushed
- [x] Git LFS installed on the Mac
- [x] Malek: install Godot 4 standard, Blender, Krita on the **PC**, plus Git + Git LFS
- [x] Malek: report PC RAM — **16 GB**
- [ ] Malek: verify `docs/CANON.md` seed against the Notion corpus
- [ ] Malek: resolve the two `[NEEDS AUTHOR]` continuity items (Bren's Somatic Sense; Developing-vs-locked properties)
- [ ] Malek: name and define the three playable Etherbound (Kinetic / Gravitic / Transmutative) and the separate directable ordinary worker
- [x] Claude: Godot project scaffold, folder structure, project settings
- [x] Codex: orbital exploration camera, WASD/click navigation and animated party followers
- [x] Claude: incident-mode turn loop (82 assertions across 3 suites, all passing)
- [x] Claude: reserve and throughput as an enforced resource, not a display (25 assertions, all passing)
- [x] Codex: visible Kinetic anchor/load-path action with the real 89% before / 111% after preview
- [x] Claude: structural connection graph (32 assertions, all passing)
- [x] Codex: F5/F9 phase checkpoint save/load for the vertical slice

## Handed to Codex

- [x] `docs/handoff/codex-01-playable-bay.md` — put the rescue on screen, greybox only.
      Codex owns `game/scenes/**`, `game/ui/**`, `game/main.gd`.
      Claude owns `game/core/**`, `game/tests/**`. Neither crosses.

## For Claude

- [x] FIXED 2026-09-09. `Structure.anchor_report()` read the "before" figure off the
  post-reaction probe, so it printed the pushed value twice. Good catch by Codex, and the
  protocol worked: it reported rather than reaching into `game/core/`. `_first_overload()`
  now returns the element's identity and `_utilisation_of()` reads the genuine pre-push
  figure off the real structure. The reason string now states both. The test that let this
  through only checked the phrase was present, never the number; it now asserts both values
  and that they differ. No presentation change needed, the HUD renders the core text verbatim.

## Next

- [x] Prototype authored dialogue with explicit phase state; final voices remain `[NEEDS AUTHOR]`
- [x] Investigation layer: exactly three evidence objects, observation/inference split and report choice
- [x] Four-role 3D rescue encounter with a visible failure/collapse path
- [x] Consequence scene reflecting the reporting choice
- [x] Junction 10 technical audit and visual production plan recorded (2026-09-10)
- [ ] Junction 10 acceptance: FAILED/PENDING; see `docs/JUNCTION_10_AUDIT.md`
- [ ] Repair J10-01–05: authoritative outcomes, anchors/effects, save restore and navigation
- [ ] Prove one finished room, character and 60–90 second presentation sequence; see `docs/PRESENTATION_ROADMAP.md`
- [ ] Complete author/canon, export/licence, accessibility, measured performance and unfamiliar-player acceptance

## Blocked

- Final narrative and canon approval are blocked on CANON.md verification and the slice-1
  character definitions. The deliberately neutral `[PROTOTYPE]` slice remains playable.

## Done

The Junctions 4–9 entries below record delivered prototype features. They do not establish
acceptance; the independent Junction 10 findings supersede earlier quality/completion claims.

- [x] Repo scaffold, LFS config, agent brief (2026-09-08)
- [x] Route decision locked, non-goals written (2026-09-08)
- [x] Party decided: Kinetic / Gravitic / Transmutative, all Etherbound (2026-09-08)
- [x] Godot project + reserve/throughput core + headless test suite (2026-09-08)
- [x] Structural connection graph + tools/test.sh runner (2026-09-08)
- [x] Incident turn loop. The slice-1 rescue proven end to end (2026-09-08)
- [x] Windows toolchain verified and connected: Godot, Blender, Krita, Git LFS (2026-09-08)
- [x] Playable gantry-bay rescue greybox with anchor preview, countdown, failure and worker-prop solution (2026-09-08)
- [x] Junctions 0–2: playable-bay merge, 15-minute vertical-slice brief and licence/provenance ledger (2026-09-09)
- [x] Junction 3: editable Blender environment and rigged character exported to GLB, imported into Godot and covered by a headless contract test (2026-09-09)
- [x] User concept-art batch and audited Blender/Godot MCP development snapshots committed; Godot project verified on 4.7.2 standard (2026-09-09)
- [x] Junction 4: continuous four-zone Blender environment imported and runtime-reviewed (2026-09-09)
- [x] Junction 5: four distinct shared-rig role silhouettes with eight clips each (2026-09-09)
- [x] Junction 6: orbital traversal, party followers and proximity interactions (2026-09-09)
- [x] Junction 7: four-role structural rescue plus readable collapse failure (2026-09-09)
- [x] Junction 8: three clues, evidence-gated report and two consequences (2026-09-09)
- [x] Junction 9: audio, lighting, VFX, checkpoint, UI, runtime captures and performance pass (2026-09-09)

Run the suites: `./tools/test.sh`
