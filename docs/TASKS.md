# Task Board and File Claims

Both agents read this BEFORE writing code. Claim your files, commit the claim, then work.
Release the claim when you finish.

---

## Active claims

| Agent | Branch | Files claimed | Started |
|---|---|---|---|
| Codex | `codex/junctions-4-9` | `docs/TASKS.md`, `docs/VERTICAL_SLICE.md`, `docs/ADAPTATION.md`, `docs/ASSET_LEDGER.md`, `docs/handoff/codex-04-notes.md`, `tools/blender/**`, `art/models/**`, `game/project.godot`, `game/main.gd`, `game/core/**`, `game/scenes/**`, `game/ui/**`, `game/tests/**`, `game/assets/**`, `game/data/**`, `game/audio/**` | 2026-09-09 |

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
- [ ] Malek: name and define the three slice-1 playable characters (Kinetic / Wright specialist / ordinary skilled worker)
- [x] Claude: Godot project scaffold, folder structure, project settings
- [ ] Claude: third-person orbital exploration controller
- [x] Claude: incident-mode turn loop (82 assertions across 3 suites, all passing)
- [x] Claude: reserve and throughput as an enforced resource, not a display (25 assertions, all passing)
- [ ] Claude: one Kinetic ability with visible anchor preview and a readable failure reason
- [x] Claude: structural connection graph (32 assertions, all passing)
- [ ] Claude: save/load

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

- [ ] Dialogue system with explicit state and NPC knowledge tracking
- [ ] Investigation layer: evidence objects, conflicting accounts, reporting choice
- [ ] The rescue encounter
- [ ] Aftermath scene showing material consequence

## Blocked

- All narrative content is blocked on the CANON.md verification and the slice-1 character definitions.

## Done

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

Run the suites: `./tools/test.sh`
