# Codex handoff 03: local authoring-tool snapshot

Date: 2026-09-09  
Branch: `codex/tooling-snapshot`

## Outcome

The user-supplied concept-art batch and both MCP add-on snapshots are recorded in Git with
their provenance status. The Godot editor configuration is kept on the standard GDScript
build: the Godot 4.7 feature marker is preserved, while the accidental `.NET` assembly setting
is deliberately excluded.

## Tool status

- Blender 5.2 has the Blender Lab MCP add-on v1.0.0 enabled for localhost authoring.
- The matching local stdio bridge is installed outside the repository and registered in the
  Codex user configuration. It was independently verified against the open Blender scene.
- The current Godot MCP download contains the editor add-on only. It has no Node.js MCP server,
  so it is intentionally not copied into `game/addons/` or enabled.
- Godot MCP is not required for Junctions 4–9. Godot CLI, the repository test wrapper, Blender
  automation and ordinary scene/script editing remain sufficient.
- Git push authentication works through Git Credential Manager. The separate GitHub CLI token
  currently reports invalid and must be re-authenticated before `gh`-specific workflows such
  as pull-request inspection are used.

## Security and scope

MCP authoring bridges can execute code inside their host applications. Keep both servers bound
to localhost, enable them only during development, and do not expose their ports to a network.
Neither tool is a runtime dependency or part of a game export.

## Verification

- All four headless Godot suites pass under Godot 4.7.2 standard.
- The editor-added `compatibility/default_parent_skeleton_in_mesh_instance_3d` setting made
  Godot 4.7.2 crash during the required headless import pass, before tests began. It is excluded
  from the committed project configuration; removing it restored a clean import and full pass.

## Remaining author gates

Technical work can proceed through Junction 9, using neutral placeholders where necessary.
Final hero identity/art and narrative content remain blocked by the `[NEEDS AUTHOR]` decisions
listed in `docs/VERTICAL_SLICE.md` and by verification of `docs/CANON.md`.
