# Codex handoff 02: vertical-slice foundation and Blender pipeline

Date: 2026-09-09  
Branch: `codex/vertical-slice`

## Outcome

Junctions 0–3 are complete. The earlier playable-bay branch was fast-forwarded into `main`
before this branch began. The 15-minute demo now has an experience-first production brief,
an asset/provenance policy and a repeatable Blender-to-Godot proof for both environment and
character content.

## What was added

- `docs/VERTICAL_SLICE.md`: 12–15 minute experience, content budgets and Junction 0–10 gates.
- `docs/ASSET_LEDGER.md`: directory contract, provenance policy, import rules and measured proof
  asset metrics.
- `tools/blender/build_pipeline_proof.py`: one-command deterministic builder for editable
  Blender sources, review renders, GLBs and the JSON manifest.
- `art/models/kit/pipeline_environment.blend`: modular industrial diorama source.
- `art/models/characters/pipeline_character.blend`: neutral 18-bone proof rig with four actions.
- `game/scenes/pipeline/pipeline_showcase.tscn`: Godot lighting, orbit camera, clip selection and
  an automatic animation review loop. Press `M` to return to the mechanics prototype.
- `game/tests/asset_pipeline_test.gd`: import, mesh, skeleton, bone-count and clip-name contract.

## Reproduce

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' `
  --background --factory-startup --python tools/blender/build_pipeline_proof.py
& 'C:\Program Files\Git\bin\bash.exe' ./tools/test.sh
```

Run the Godot project to open the pipeline showcase. It auto-cycles the clips; keys `1`–`4`
select `idle`, `walk`, `inspect` and `brace`. Right-drag orbits and the wheel zooms.

## Verification

- Blender 5.2.1 LTS generated and rendered both editable sources without export errors.
- Godot 4.7.2 standard imported both GLBs.
- Environment: 79 mesh objects, 4,316 triangles, 5 materials.
- Character: 19 mesh objects, 1,136 triangles, 5 materials, 18 bones, 4 named clips.
- All four headless suites passed, including the new asset-pipeline contract.
- Godot review captures visibly showed distinct walk, inspect and brace poses.

The Windows certificate-store warning printed by headless Godot remains non-fatal and is
unrelated to these local assets.

## Deliberate limits and author gate

The generated character is a non-canon technical mannequin, not hero art. No identity,
uniform, institution, final location or dialogue was invented. Before Junction 4 expands the
level, Malek must select the governing concept direction. Before Junction 5 produces hero
characters, the party identities and visual identifiers in `docs/VERTICAL_SLICE.md` require
author decisions.

User-supplied untracked concept images and the untracked Godot MCP download/archive were left
untouched.
