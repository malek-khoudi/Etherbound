# Etherbound

Game adaptation of the Etherbound novel series.

**Route:** single-player narrative tactical RPG. Godot 4, GDScript, desktop first.
**Current milestone:** one complete playable incident, 30 to 60 minutes of finished play.

All rights reserved. This repository contains unpublished story canon. Private.

## Setup

Once per machine, before your first clone:

```bash
git lfs install
```

Then:

```bash
git clone git@github.com:malek-khoudi/Etherbound.git
cd Etherbound
```

Open `game/` in Godot 4 (standard build, not .NET).

## Layout

| Path | Contents |
|---|---|
| `game/` | Godot project |
| `docs/` | Canon ledger, adaptation ledger, task board |
| `art/` | Concept, portraits, tilesets, UI (Git LFS) |
| `audio/` | Music and SFX (Git LFS) |
| `tools/` | Pipeline scripts |

## Working with AI agents

`AGENTS.md` is the shared brief for Claude Code and Codex. `CLAUDE.md` imports it.
Read `docs/TASKS.md` and claim your files before writing anything.
