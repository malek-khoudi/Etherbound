# Junction 10: independent slice audit

Date: 2026-09-10. Auditor: Codex (Astra). Baseline: `35b49cc8c10ce1bd1d248b1565dd5e57738064cc`.

**Verdict: NOT ACCEPTED as the finished 12–15 minute vertical slice.** The technical
audit is complete; acceptance remains failed/pending. Junctions 4–9 delivered prototype
implementations, not evidence that their full quality gates passed. This report supersedes
the earlier completion wording where it implies production readiness.

The Blender/GLB pipeline, core structural graph, reserve model and prototype phase flow are
useful foundations. Preserve them. The game currently presents a short scripted demonstration
with coarse characters, direct movement and an action checklist. It does not yet deliver the
requested visual fidelity, systemic rescue or demonstrated fifteen minutes of finished play.

## Evidence and limits

- Read the active main scene, state, party, camera, environment, HUD, audio, data, generators,
  core incident/physiology systems, tests, canon seed and asset ledger.
- Ran `./tools/test.sh` through Git Bash on the Windows PC with normal user-data access:
  all five suites pass, Godot `4.7.2.stable.official.ed1daf0bf`.
- Visually inspected committed `junction_exploration.png`, `junction_characters.png` and
  `junction_polish.png`; compared representative supplied concept art and the model builders.
  These are historical staged captures, not a new continuous gameplay recording.
- Inspected the checked-in Godot MCP licence and current official asset/engine guidance.
  No external character, animation, texture or marketplace pack was acquired in this audit.
- Did not perform an unfamiliar-player playtest, Mac performance run, export smoke test,
  acoustic listening session or full corpus verification. No fresh FPS measurement is claimed.
- Findings below are source-traced unless explicitly described as screenshot observations.
  Reproduction recipes and required regression coverage are provided; they are not claims
  that an interactive reproduction was performed for every item.

## Gate results

| Gate | Result | Evidence / remaining requirement |
|---|---|---|
| Blender-to-Godot interchange | Pass, technical contract only | Four role GLBs, rig and eight clip names import; this does not prove motion quality. |
| Existing automated checks | Pass | Five suites; scene integration defects below are outside their current coverage. |
| Code / systemic behaviour | Fail | Split outcome authority, incomplete effect lifecycle, misleading preview and lossy restore. |
| Presentation / visual target | Fail | Coarse mannequin derivatives, flat surfaces, obstructed framing and dominant debug-style UI. |
| Canon | Pending author + technical corrections | Seed explicitly unverified; overlay presentation conflicts with the documented rule. |
| Provenance / export licence readiness | Partial, not cleared for shipping | Project-authored runtime assets recorded; exact external notices/export contents unverified. |
| Accessibility | Incomplete | Readable text exists, but settings, remapping, focus flow and scaling are not established. |
| Performance | Incomplete | Prior short 720p staged FPS readings are insufficient; object counter was misinterpreted. |
| 12–15 minute experience | Unverified; substantial design gap | No timing study; four clicks and one round can resolve the scripted encounter. |
| Unfamiliar-player acceptance | Pending human session | No independent user observation in the repository. |

## Prioritised findings

### J10-01 — P1: checklist overrides physical outcomes

`game/core/slice_state.gd:75` decides success from four action flags and failure from a
separate set of flags/three-round cutoff. `game/scenes/vertical_slice/vertical_slice.gd:279`
calls the real incident but only appends its events to a reason string; the state result
controls collapse and progression.

Concrete counterexample: select only Gravitic and end the round. The configured walkway
and crate load becomes `(100 + 300) * 0.55 = 220`, below the bracket's 350 capacity. Yet
SliceState fails because it only recognises Kinetic, worker or Transmutative support.
Conversely, worker support alone makes the bracket stable at 250/350, but the fourth round
fails the checklist regardless. Selecting all four actions before one end-round resolves
immediately, independent of a rescued person or sustained extraction objective.

Repair: let one incident model own physical failure, rescue progress and success. Keep
tutorial completion separate. An incomplete lesson must not be rendered as a physical
collapse. Add integrated regressions for Gravitic-only stability, enduring prop stability,
actual overload, exhaustion and the completed rescue objective.

### J10-02 — P1: Kinetic anchor preview does not govern the action

`game/data/vertical_slice.json` stores the literal 89%/111% observation. `_interact()`
displays that string. The existing structural test computes those numbers independently,
but does not verify that the runtime display uses that computation. `_apply_core_action()`
at `vertical_slice.gd:248` calls `Incident.brace()`, which adds external support without
selecting or validating the actor's reaction anchor. Its post-action report uses zero
additional reaction on the walkway.

Repair: preview and commit must use the same command, target, reaction path and world
snapshot. A bracing action also needs a valid reaction path; if its semantics differ from
the inspected push, explain and model that distinction. Changing bracket capacity in data
must update the displayed numbers and refusal without editing dialogue.

### J10-03 — P1: maintained effects and throughput are incompletely integrated

Gravitic creates a commitment then directly sets gravity; Transmutative creates a commitment
then directly increases capacity. `game/core/incident.gd:147` withdraws expired Kinetic
braces, but has no equivalent tracking for the other two effects. Nor do these effects
scale with granted throughput. A repaired material state may legitimately remain, but the
current instantaneous capacity increase is not a progressing maintained front.

The configured Gravitic demand is 5 against a ceiling of 9; Transmutative is 6 against 9.
Therefore the advertised situation in which all three are at capacity is not produced by
these actions. The HUD displays action completion but not the resource decisions.

Repair: model effect ownership, delivered output, cancellation/exhaustion and completed
material change explicitly. Tune the incident to demonstrate occupied Etherbound and an
essential ordinary worker through actual jobs. Test withdrawal and partial output; obtain
author confirmation for any disputed power detail before codifying it.

### J10-04 — P1: F9 does not restore an equivalent playable world

`slice_state.gd:141` saves flags and a position, but not reserves, exhaustion, commitments,
structural changes or the core round. `_restore_phase()` at `vertical_slice.gd:437`
rebuilds the core with full reserves and replays action flags. `_start_incident()` also
auto-saves before replaying those flags. Investigation restore uses fixed staging instead
of the saved position. The consequence panel is never hidden by `_restore_phase()`.

Reproduction paths to cover: save after two Kinetic rounds (reserve 30), load and compare
reserve (rebuilt to 150); save investigation at a moved position and reload; load an earlier
checkpoint while the consequence panel is visible; save/load a failed incident and compare
collapse geometry and disabled controls.

Repair: either implement a complete versioned snapshot, or explicitly restrict checkpoint
semantics to a named phase restart. Current F5 arbitrary saving implies more than is restored.
Test through the scene coordinator, not only a SliceState dictionary round trip. Hide all
modal panels and reconstruct world effects consistently before resuming input.

### J10-05 — P1: exploration has no obstacle-aware route or camera protection

`party_controller.gd:95` directly moves Node3D positions; `_clamp_to_route()` at line 209
restricts a flat rectangle. `_ground_hit()` intersects an infinite plane. There is no
navigation mesh, collision body or obstacle query in this controller. Followers interpolate
toward offsets and can intersect machinery/each other. `slice_camera.gd` has no occlusion
handling. The exploration/cast captures show characters hidden by machinery and columns.

Repair: collision-aware actors, a baked navigable surface, valid ground picking, unreachable
target feedback, follower recovery and camera obstruction handling. Verify narrow passages,
corners, stairs if introduced, blocked clicks and regrouping in an actual route test.

### J10-06 — P1 for presentation acceptance: proof mannequins were promoted to cast

`tools/blender/build_vertical_slice.py:296` reuses `add_character_meshes()` from the pipeline
proof, then adds accessories. The proof generator uses separate primitives rigidly weighted
to individual bones, an ico-sphere head and no expressive facial system. This is well below
the ledger's eventual 15k–35k hero budget and, more importantly, below close-up quality.
The cast capture shows rear views, raised arms, coarse silhouettes and foreground occlusion.
Eight named clips prove import, not grounded walking, convincing contact or acting.

Repair: finish one human character and one dialogue shot to an agreed visual standard before
replicating the cast. Review turntable, face, elbow/knee deformation, foot contact and hand
contact in motion. Raw polygon count alone is not an acceptance criterion.

### J10-07 — P1 canon-presentation gate: tactical overlays read as physical magic

`slice_environment.gd:196` builds persistent emissive Kinetic beams, Gravitic rings and
Transmutative patches. There is no player overlay toggle or clear separation from world
effects. `docs/CANON.md` requires instructional lines to be optional tactical overlays.

Repair: a labelled, switchable analysis mode; physical outcomes remain legible through
movement, contact, deformation, dust and sound when the overlay is off. Review all glowing
costume accessories against the selected concept/era before treating them as world equipment.

### J10-08 — P2: narrative and consequence remain demonstrations

Arrival has three lines; inspection is text; knowledge is a global three-item checklist.
The report openly labels one answer as unsupported, leaving little interpretive tension.
`slice_environment.gd:78` changes light colour/energy by report choice, while the consequence
panel changes text. This does not demonstrate the promised material/social aftermath.
Evidence claims commitments ended, but the transition does not explicitly release them.

Repair: a compact authored knowledge model with speaker observations, beliefs and recorded
claims; a report with a believable tradeoff; a visible aftermath such as a changed access
state or worker action, subject to author approval. Establish an actual rescue subject and
extraction objective. Do not invent their identity or add protected lore.

### J10-09 — P2: accessibility, localisation and data separation incomplete

Keys are hardcoded; no InputMap settings/remapping or independent audio settings are present.
The fixed 1440x810 HUD uses small helper labels (13 logical pixels), large opaque panels and
colour-heavy distinctions. Focus/keyboard-only progression and alternate aspect ratios are
unverified. `vertical_slice_hud.gd:270` and `:313` hardcode actions/report labels despite JSON
report data. Some composed strings (ROUND, role names, completion text) bypass translation
or translate only after interpolation. No translation catalogue is committed.

Repair: settings and semantic actions; readable scalable layout, deliberate focus handling,
text/icons in addition to colour, reduced camera motion/flash controls, stable translation
keys with placeholders and UI generated from content data. Test 720p, 1080p and ultrawide,
large text and keyboard-only completion. Keep development status labels out of normal play.

### J10-10 — P2: performance and capture evidence are weaker than reported

`vertical_slice.gd:83` uses `Performance.OBJECT_COUNT`: total engine objects, not rendered
objects or draw calls. Capture mode stages flags/positions directly and quits after 2.2s.
It does not traverse the route or prove the seven-minute rescue. `capture_slice.ps1` accepts
an existing PNG if a new one was not written and does not assert freshness. Capture staging
also invokes gameplay autosave, potentially replacing the player's checkpoint.

Repair: isolate capture save data, require fresh outputs, record an actual route and collect
CPU/GPU frame time, draw calls, rendered primitives, RAM/VRAM and stalls. Profile a packaged
1080p build on the Windows target; separately measure the Mac before making Mac claims.

### J10-11 — P2: licence/export acceptance incomplete

Project-authored runtime geometry/audio is traceable to builders. Concept source history is
incomplete and those files are reference-only. The checked-in Godot MCP notice applies to
the editor plugin; it does not grant rights to the missing paid server. No export preset or
packaged credits/third-party notice review was found in the game project. The previous
Blender archive audit is recorded in the ledger but was not independently re-performed here.

Repair: inspect a real export and include applicable engine/third-party notices; exclude
development tooling and unapproved references. Record exact asset version, URL, licence,
receipt where applicable, files and intended distribution rights for future acquisitions.
This is an engineering provenance review, not a legal clearance certificate.

## Acceptance session still required

After repairs, give at least three unfamiliar players the same clean packaged build, without
coaching. Record start/end time, wrong turns, unreadable UI, assistance, failure/recovery and
whether they can explain why the structure held, why the worker mattered and what the
evidence did not establish. Proposed target: ordinary first completions around 12–15 minutes,
no forced waiting, all complete without a blocker. Report each result; do not substitute the
average for failures. Malek separately approves visual identity and canon.

Priority order: J10-01–05 correctness/navigation; J10-06–07 visual proof; J10-08–09 experience;
J10-10–11 measurement/export; then repeat human/author acceptance. Audit completion does not
mean these repairs have been implemented.

## Official references checked 2026-09-10

- [Godot 3D import](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/index.html)
- [Godot navigation agents](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html)
- [Godot performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- [Godot licence compliance](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)
- [Adobe Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)
- [Poly Haven licence](https://polyhaven.com/license)
