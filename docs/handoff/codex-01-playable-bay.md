# Codex task 01: make the rescue playable

**Agent:** Codex (Astra)
**Branch:** `codex/playable-bay`
**Read first:** `AGENTS.md` at the repo root. It is binding. Section 2 is the two-agent
protocol, section 3 is canon, section 4 is code conventions, section 4b is how to run tests.

---

## What already exists

The entire rescue works, headless, with 82 passing assertions. **Do not rebuild any of it.**
Read these, call into them, and change none of them:

| File | What it gives you |
|---|---|
| `game/core/etherbound.gd` | Reserve, throughput, six junctions, `commit()`, `preview()`, `tick()` |
| `game/core/structure.gd` | Load graph, `anchor_report()`, `overloaded()`, `add_external_support()` |
| `game/core/incident.gd` | Turn loop, `brace()`, `prop()`, `rounds_sustainable()`, `end_round()` |
| `game/core/unit.gd` | Unit with an OPTIONAL Etherbound component |
| `game/tests/incident_test.gd` | `_failing_bay()` is the exact scenario to put on screen |

Run `./tools/test.sh` before you start and after every change. It must keep printing
`=== ALL PASS ===` three times.

---

## Your job

Put the gantry bay on screen and make it playable. Greybox only. Untextured boxes.
**No art, no models, no Blender, no downloaded assets.** Prove the loop, not the look.

The scenario is `_failing_bay()` from `game/tests/incident_test.gd`: a footing, a column,
a main beam, a walkway hanging off a corroded bracket, and a feedstock crate on the walkway.
It is already overloaded. Left alone the bracket goes.

Two units: **Kess**, a Kinetic (reserve 150, throughput 10). **Maren**, ordinary, directable.

### Acceptance criteria

A person who has never seen this repo can sit down and do all of the following:

1. See the bay in 3D. Orbit and zoom with the mouse.
2. Click any member and read its label, load, capacity and utilisation percentage.
3. See at a glance that the corroded bracket is over capacity before anyone acts.
4. Select Kess, hover a member, and read the real text from `Structure.anchor_report()`,
   including which element would fail and what percentage it is already at.
5. Brace the walkway with Kess. The bracket stops being over capacity.
6. See Kess's reserve, and see the rounds-remaining number from `rounds_sustainable()`.
7. Press End Turn twice. Watch the reserve drain and the number count down.
8. Press End Turn a third time. Kess loses the hold and the walkway visibly falls.
9. Restart, brace with Kess, and on round 2 prop the walkway with Maren. On round 3 Kess
   still loses the hold and **nothing falls**.
10. Read a running event log of everything that happened, in order, in plain sentences.

Point 9 is the point of the whole task. If it works, the design is proven on screen.

---

## Constraints

**Files you may create or edit:**
```
game/scenes/**
game/ui/**
game/main.gd
game/project.godot        (main scene + input map only)
docs/TASKS.md             (claim your files, then release them)
```

**Files you must NOT touch:**
```
game/core/**              mine. Read it, call it, never edit it.
game/tests/**             mine.
tools/**
AGENTS.md, docs/CANON.md, docs/ADAPTATION.md
```

If you believe something in `game/core/` is wrong, **do not fix it**. Write the problem into
`docs/TASKS.md` under a heading `## For Claude` and carry on. That is the handoff channel.

**Build scenes procedurally in GDScript, not as hand-authored `.tscn` files.** A prototype
scene written in code is diffable, reviewable, and you can verify it. Hand-written `.tscn`
is error-prone and merges badly between two agents.

**Godot registers `class_name` globals only after an import pass.** Run `./tools/test.sh`,
never Godot directly, or your new classes will fail to parse.

**No canon invention.** Kess and Maren are placeholder names for this prototype only, and
`docs/CANON.md` records them as `[NEEDS AUTHOR]`. Do not name the site, the company, the
district, the year, or anyone else. Do not write dialogue. Do not invent an affinity, a
rule, or an institution. Where you need a fact you do not have, put `[NEEDS AUTHOR]` on
screen as literal placeholder text and move on.

**No damage numbers.** Nothing in this game does X damage in radius Y. Every effect goes
through the physical model in `game/core/`.

**Conventions:** GDScript, statically typed, `snake_case` files and functions, one
responsibility per script, German never (this project is English), every failure the player
can cause shows a readable reason naming the specific element.

---

## What "done" means

- `./tools/test.sh` prints `=== ALL PASS ===` three times, unchanged, 82 assertions.
- All ten acceptance criteria above work when the project is run.
- A short `docs/handoff/codex-01-notes.md` recording what you built, anything you could
  not verify because you cannot see the screen, and anything you left for Malek to judge.
- Committed on `codex/playable-bay`, pushed, and `docs/TASKS.md` claims released.

Do not merge to `main`. Malek reviews it by running it.
