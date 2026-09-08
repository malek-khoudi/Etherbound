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

### Windows toolchain

Verify Godot, Blender, Krita, Git LFS and Git Bash from PowerShell:

```powershell
.\tools\toolchain.ps1
```

The verifier accepts `GODOT`, `BLENDER`, `KRITA` and `GIT_BASH` environment
overrides. Otherwise it checks `PATH` and the normal Windows install locations.
It rejects Godot Mono/.NET because this project uses the standard GDScript build.

Run the required headless suites from PowerShell through Git Bash:

```powershell
& 'C:\Program Files\Git\bin\bash.exe' .\tools\test.sh
```

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
