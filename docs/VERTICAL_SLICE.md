# Etherbound 15-minute vertical slice

Status: production brief for Junctions 0–10. This is an adaptation plan, not story canon.

Last updated: 2026-09-09

Current gate: Junctions 0–9 complete as a non-canon vertical-slice implementation. Junction 10
is deliberately not started. Final narrative identity and canon approval remain author gates.

Prototype visual direction accepted through Malek's instruction to build from the supplied
concept collection: weathered dark iron and stone, restrained brass, amber work light, cool
wet-environment fill and practical workwear silhouettes. Selection of one final governing image
remains `[NEEDS AUTHOR]` and may revise, but does not block evaluation of this prototype.

## North star

Deliver one replayable 12–15 minute desktop incident that communicates the eventual game's
presentation language: a compact stylized-low-poly 3D location, orbital exploration, three
visible party members, authored cinematic dialogue, a turn-based physical rescue, a short
investigation and an immediate material consequence.

"BG3-style" means the shape of the experience—party exploration, readable tactical space,
cinematic conversations and consequential choices. It does not mean copying Baldur's Gate 3
assets, interface, writing, rules, scale or production fidelity.

## Author lock required

The following are deliberately unresolved. Technical production can continue with neutral
prototypes, but dialogue and final character art cannot be called finished until Malek sets
them.

| Decision | Status |
|---|---|
| Exact era/date | `[NEEDS AUTHOR]` |
| Exact site and location | `[NEEDS AUTHOR]` |
| Kinetic name, role and visual identifiers | `[NEEDS AUTHOR]` |
| Gravitic name, role and visual identifiers | `[NEEDS AUTHOR]` |
| Transmutative name, role and visual identifiers | `[NEEDS AUTHOR]` |
| Ordinary worker name, role and relationship to the party | `[NEEDS AUTHOR]` |
| Dialogue voice and interpersonal tension | `[NEEDS AUTHOR]` |
| Primary concept image to govern the final slice | `[NEEDS AUTHOR]` |

Prototype names such as Kess and Maren remain noncanon test labels.

## The playable fifteen minutes

### 0:00–1:30 — Arrival

- A short authored camera move establishes a wet, unevenly industrial site.
- Three party members enter together and meet one ordinary worker.
- Dialogue introduces one practical job and one visible concern without revealing protected
  novel information.

### 1:30–4:30 — Exploration and diagnosis

- Player uses an orbital camera and click-to-move navigation through an approach corridor,
  a compact control/work area and the gantry bay.
- Party followers maintain a readable formation and idle contextually.
- Three optional inspections teach that machinery, workers and Etherbound do different work.
- The failing bracket can be inspected before the incident; predictions use the real
  structural model rather than scripted flavour.

### 4:30–11:30 — Turn-based rescue

- The mode transition is visible through camera framing, overlays, audio and unit controls.
- Kinetic commitment takes load while consuming reserve and throughput.
- Gravitic intervention changes acceleration/load behaviour without changing mass.
- Transmutative intervention works through a contiguous material front and a maintained task.
- The ordinary worker can place the enduring physical prop while every Etherbound is busy.
- Failure is allowed and produces a visible structural collapse with a named physical reason.

### 11:30–14:00 — Investigation and report

- The player examines exactly three evidence objects after the incident.
- Evidence and character knowledge are explicit state; no live AI dialogue is used.
- One authored reporting choice asks the player to distinguish observation from inference.
- Exact evidence, speaker and institutional recipient are `[NEEDS AUTHOR]`.

### 14:00–15:00 — Consequence

- A short camera sequence shows the saved, damaged or collapsed state of the same place.
- One worker response and one environmental change reflect the player's actions.
- The slice ends locally; it does not expose any protected revelation or promise a campaign.

## Space budget

One continuous map, sized for density rather than distance:

1. Approach passage or covered exterior.
2. Work/control area with evidence and machinery.
3. Gantry bay containing the rescue geometry.
4. Small consequence framing area using the same assets and sightlines.

No open world, settlement simulation, loading-screen travel, large roster or combat arena.

## Content budget

- 3 party character models and 1 directable worker model.
- 1 shared humanoid rig and roughly 8–10 reusable clips for the slice.
- 16–24 modular environment pieces and 12–18 props.
- 4–6 coherent materials with controlled variations.
- 3 evidence interactions, 1 reporting decision and 2–3 environmental outcomes.
- 1 ambient sound bed, footsteps, interface sounds and incident-specific structural sounds.
- 3 cinematic beats: arrival, incident transition and consequence.

## Presentation rules

- Dark iron/stone masses, restrained brass, warm amber work light and cool environmental
  fill come from the concept collection's common visual language.
- Gold/amber power and load-path lines are tactical overlays, never literal world beams.
- Structural danger must remain readable when the overlay is hidden through pose, sound,
  material wear, particles and camera composition.
- Cinematic dialogue uses authored shot/reverse-shot framing and restrained body gestures.
  Full facial performance and automated lip sync are outside this slice.
- The exploration HUD stays quiet. Dense structural numbers appear only while inspecting or
  during incident mode.

## Junction gates

| Junction | Gate before continuing |
|---|---|
| 0. Foundation | Playable-bay foundation is merged; branch and files are claimed. |
| 1. Experience | This brief exists; every unknown canon fact is marked. |
| 2. Assets | Asset ledger names provenance, licence, source and Godot output for every binary. |
| 3. Pipeline proof | An editable Blender environment and rigged character import into Godot; at least idle, walk and brace animations visibly play; a repeatable test scene and headless contract test pass. |
| 4. Environment | All four map zones are traversable with final slice modular geometry. |
| 5. Characters | Three party silhouettes and worker are readable in exploration and dialogue framing. |
| 6. Exploration | Camera, navigation, followers and interactions survive a full route playtest. |
| 7. Incident | All four mechanical roles act visibly in the 3D rescue and failure remains possible. |
| 8. Narrative | Three clues, report choice and consequence state work without invented canon. |
| 9. Polish | Audio, lighting, VFX, save/checkpoint, UI and performance pass are complete. |
| 10. Audit | Canon, code, licence, performance and unfamiliar-player review pass. |

## Junctions 4–9 implementation record

| Junction | Implemented evidence |
|---|---|
| 4. Environment | `slice_environment.blend` / `.glb`: one continuous approach, control area, gantry bay and consequence area; 171 Blender meshes, 12,052 triangles, six materials. |
| 5. Characters | Four separate `.blend` / `.glb` role silhouettes on a shared 18-bone rig; eight clips each. All identities remain `[PROTOTYPE]`. |
| 6. Exploration | WASD and click-to-move route traversal, player orbital camera, two animated followers, worker staging and proximity interactions. |
| 7. Incident | Kinetic load-taking, Gravitic acceleration change, Transmutative contiguous repair front and ordinary-worker prop all alter the real structural model and produce visible 3D feedback. Ending a round without support still collapses the walkway with a readable reason. |
| 8. Narrative | Three authored prototype evidence objects distinguish observation from inference; the report choice branches into two immediate consequence states without naming a canon institution or culprit. |
| 9. Polish | Rain/steam/dust VFX, warm/cool lighting, generated local ambience and action sounds, F5/F9 checkpoint save/load, F12 capture, quiet exploration HUD, incident UI and performance readout. Six named Godot review captures are committed. |

The automated capture pass measured 90–120 FPS at 1280×720 on the Windows development PC,
with roughly 2,620 rendered objects in the authored views. This is a local development reading,
not an unfamiliar-player or shipping-performance audit; those belong to Junction 10.

## Review loop

Each visual junction produces a named scene, state readout and captured review image. Codex
checks geometry, import structure, animation names and performance counters; Malek judges
silhouette, atmosphere, camera feel, animation feel and whether the result looks like
Etherbound. A render is evidence, not approval.
