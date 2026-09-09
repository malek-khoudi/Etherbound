# Codex handoff 04: Junctions 4–9 playable vertical slice

Date: 2026-09-09  
Branch: `codex/junctions-4-9`

## Outcome

Junctions 4–9 are implemented and Junction 10 has not begun. Running the Godot project now
opens a compact continuous 3D demo rather than the pipeline proof. It includes arrival framing,
exploration, animated party followers, a four-role turn-based rescue, failure/collapse, exactly
three evidence interactions, a reporting choice, immediate consequence, local audio, VFX,
checkpoint save/load and performance readout.

Every unresolved identity, site and recipient is labelled `[PROTOTYPE]`; no protected
revelation, novel character, institution, date or location was invented.

## Controls

- `WASD` or left-click ground: move the Kinetic leader.
- Right-drag / wheel: orbit and zoom.
- `E`: inspect a nearby marked object.
- Incident buttons: perform the four visible physical roles, then end the round.
- `F5` / `F9`: save and load the phase checkpoint.
- `F12`: save a runtime review capture under `art/review/`.

## Blender deliverables

- `art/models/kit/slice_environment.blend`: 171 meshes, 12,052 triangles, six materials and
  four named zones. Runtime output: `game/assets/models/environment/slice_environment.glb`.
- Four editable character sources in `art/models/characters/slice_*.blend`, with corresponding
  GLBs. Each uses the same 18-bone rig and has `idle`, `walk`, `inspect`, `brace`, `point`,
  `operate`, `kneel` and `stagger`.
- Rebuild with Blender 5.2 using `tools/blender/build_vertical_slice.py`.

## Godot implementation

- `game/data/vertical_slice.json` contains all dialogue, objectives, interactions, evidence,
  report outcomes and incident tuning.
- `SliceState` owns explicit phase/evidence/action/report/checkpoint state.
- `VerticalSlice`, `SliceEnvironment`, `SlicePartyController`, `SliceCameraRig`, `SliceAudio`
  and `VerticalSliceHud` divide runtime responsibilities.
- The rescue uses the existing `Structure`, `Incident`, `Etherbound`, `Commitment` and `Unit`
  systems. It does not substitute scripted flavour for the load-path calculation.

## Verification

- `./tools/test.sh`: all five suites pass, including the new Junctions 4–9 contract.
- Four final role GLBs import with 18 bones and all eight required clips.
- The environment imports with more than 100 mesh nodes and all four zone prefixes.
- Anchor preview is tested at 89% before and 111% after the projected reaction.
- Failure, exact three-clue gating, two report paths, dictionary checkpoint and disk checkpoint
  are covered.
- `tools/capture_slice.ps1` produced six runtime captures and found no script/runtime errors.
- Captured views ran at roughly 90–120 FPS and around 2,620 rendered objects on this PC.

## Junction 10 remains

Do not call final identity, dialogue, canon, licence, accessibility or unfamiliar-player quality
approved. Junction 10 requires author decisions, an Astra audit and a human playtest. This
handoff stops at the user's requested boundary: Junction 9.
