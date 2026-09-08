# Etherbound Game: Agent Brief

Single source of truth for every AI agent working in this repo.
`CLAUDE.md` imports this file. Codex (Astra) reads it natively. Do not duplicate rules elsewhere.

Last updated: 2026-09-08

---

## 1. What this project is

A game adaptation of the **Etherbound** novel series by Malek Khoudi.

**Chosen route:** single-player **narrative tactical RPG** in **Godot 4** (standard build, GDScript).
Compact locations, small party, consequential investigation, environmental problem-solving.

**Current milestone:** build ONE complete playable incident (30 to 60 minutes of finished play)
before committing to a campaign. Nothing beyond that milestone is approved scope.

The 3D action route is explicitly deferred. Do not scaffold Unity or Unreal projects.
Do not add 3D animation systems, character rigs, or third-person camera controllers.

---

## 2. The two-agent protocol

Two agents work in this repo: **Claude Code** and **Codex (Astra)**.
We have no shared memory. Git is the only channel between us.

**Rules, non-negotiable:**

1. **Branch per agent.** `claude/<topic>` or `codex/<topic>`. Never commit directly to `main`.
2. **Pull before you start.** `git pull --rebase origin main`. Always. Every session.
3. **Never work on the same file as the other agent at the same time.** Check `docs/TASKS.md` first, claim your files there, commit that claim before writing code.
4. **Small commits, descriptive messages.** A commit that touches 30 files is unreviewable by a human on a phone.
5. **Never rewrite the other agent's work without saying so in the commit message.**
6. **Update `docs/TASKS.md` when you finish.** Release your file claims.

If `docs/TASKS.md` shows an open claim by the other agent on a file you need, stop and tell Malek. Do not race.

---

## 3. Canon rules, non-negotiable

The novels are the authority. The game bends to them, never the reverse.

1. **Never invent canon.** Characters, places, dates, institutions, history and power mechanics come from the Notion corpus. If a fact is not in `docs/CANON.md` or the corpus, it does not exist. Write `[NEEDS AUTHOR]` and stop.
2. **Adaptation is not canon.** Turn length, action points, injury categories, numeric UI, grid movement and simplified structural models are game abstractions. They go in `docs/ADAPTATION.md`, never in `docs/CANON.md`.
3. **Respect the disclosure ceiling.** See `docs/CANON.md` section "Protected revelations". The Anchor's true nature, primordial linkage, historical identity and Reaching causality are staged for the novels. This game must not reveal them.
4. **Hald is not a template.** His anomalous effects must never become a selectable player affinity.
5. **Powers are physically constrained.** Kinetic needs an anchor that can fail. Thermic cooling needs a sink. Vital repair is not recovery. A player who ignores physics must fail, and the failure reason must be shown in plain language.
6. **One reserve, six junctions.** Natural Etherbound share one reserve and one whole-body throughput ceiling. More simultaneous tasks means less output each. Reserve, throughput, mastery and exhaustion are four different things. Never collapse them.
7. **Progression adds control, technique, preparation and understanding.** It never sells a character an unrelated affinity.
8. **Ordinary people stay essential.** Mechanical skill, judgment and institutional knowledge must remain mechanically useful, not flavour text.
9. **Companion story, not novel retelling.** Playable characters for the first slice are new. Hald and Vara are not player characters.
10. **The Battle of Sorn Weir is marked potential/noncanon.** Test scenario only, always labelled as such.

---

## 4. Code conventions

- **Godot 4.x standard build. GDScript.** No C#, no .NET build, no external engine plugins without Malek's approval.
- Static typing everywhere: `var hp: int = 0`, `func apply(dmg: int) -> void:`.
- `snake_case` for files, functions and variables. `PascalCase` for classes and nodes.
- One responsibility per script. No 800-line god scripts.
- **Data lives in `.tres` resources or JSON, not hardcoded in scripts.** Abilities, units, dialogue and encounters must be editable without touching code.
- **Every failure the player can cause must produce a readable reason string.** "Anchor failed: crate was not braced" beats a silent no-op.
- Comments in English. All player-facing text goes through a translation layer from day one, even if only English exists at first.
- No runtime AI API calls. Dialogue is authored and stateful.

---

## 5. Repo layout

```
game/     Godot project (project.godot lives here)
docs/     CANON.md, ADAPTATION.md, TASKS.md, design notes
art/      concept/ portraits/ tilesets/ ui/   (LFS tracked)
audio/    music and sfx                        (LFS tracked)
tools/    scripts, generators, pipeline helpers
```

Binary assets are Git LFS tracked via `.gitattributes`. Run `git lfs install` once per machine
before your first clone or you will commit broken pointer files.

---

## 6. Machines

- **M4 MacBook Air, 16 GB, ~25 GB free disk.** Writing, design, code, scene editing. Godot only. Never install Unreal here.
- **Windows PC, RTX 4070 Super 12 GB, Ryzen 5 2600X.** Engine work, running builds, Blender, local image generation.

The 2600X is a 2018 CPU and is the bottleneck. This is one reason the project is Godot and not Unreal.

---

## 7. When you are unsure

Stop and ask. Do not guess at canon, do not guess at scope, do not expand the milestone.
Write `[NEEDS AUTHOR]` inline and surface it in your summary.
