# Task Board and File Claims

Both agents read this BEFORE writing code. Claim your files, commit the claim, then work.
Release the claim when you finish.

---

## Active claims

| Agent | Branch | Files claimed | Started |
|---|---|---|---|
| Codex | `codex/windows-toolchain` | `.gitattributes`, `docs/TASKS.md`, `README.md`, `tools/test.sh`, `tools/toolchain.ps1` | 2026-09-08 |

---

## Decision log

- **2026-09-08 LOCKED.** BG3-shaped narrative tactical RPG. Godot 4, stylized low-poly 3D,
  real-time exploration + turn-based incident mode, three-character party.
  Non-goals are listed in `AGENTS.md` section 1 and are decisions, not deferrals.

---

## Now

- [x] Repo created and pushed
- [x] Git LFS installed on the Mac
- [ ] Malek: install Godot 4 standard, Blender, Krita on the **PC**, plus Git + Git LFS
- [ ] Malek: report PC RAM
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

Run the suites: `./tools/test.sh`
