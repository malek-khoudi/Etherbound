# Etherbound: production plan after the Junction 10 audit

Date: 2026-09-10. Status: proposed plan for the existing fifteen-minute demo.
Read `JUNCTION_10_AUDIT.md` first. No campaign implementation or asset purchase is approved
by this document. The user's current request explicitly prioritises closer BG3-style visuals.

## Recommended target

A small, richly staged narrative tactical RPG: believable human proportions, expressive faces,
carefully textured industrial environments, orbital exploration and authored dialogue coverage.
Use original Etherbound visual language and physical rules. Concentrate detail in a compact
location and four visible people so every camera shot earns its cost.

The old brief uses "stylized low-poly" and excludes facial performance. That is materially
different from the visual aspiration now expressed. Recommended revision: **detailed stylized
realism, with restrained facial performance in a few close conversations**. This is a proposal
for Malek's visual approval, not a silent rewrite of AGENTS.md or a promise of BG3 production
parity. Godot 4 standard/GDScript, real-time exploration, turn-based incidents and the small
scope remain appropriate constraints.

BG3-like presentation requires character art, acting, scene direction, lighting and sound
working together. An engine or model switch does not supply those assets. Automated Blender
builders remain valuable for blockouts, modular assembly, export and validation; hero faces,
clothing, deformation and acting need deliberate asset work and visual iteration.

## Translate the reference into deliverables

| Desired experience | Etherbound implementation | Acceptance evidence |
|---|---|---|
| Convincing people at dialogue distance | One cohesive hero body, face/eyes/hair, clothing layers and a tested rig; distinct outfits for the other roles | Face close-up, neutral turntable, moving elbows/knees, blink/look/listen/talk in Godot |
| Dense, tactile world | Stone, weathered iron, restrained brass, cloth/leather; believable joints, wear and ordinary work tools | Matched stills under neutral light and final lighting; surfaces distinguishable without emissive outlines |
| Readable party exploration | Collision and navigation, formations, character selection, unobstructed camera | Continuous route recording through props/corners and a controlled elevation change if included |
| Cinematic conversations | Actor marks, eye lines, shot/reverse-shot, reaction shots, gestures and captions | A 30–45 second conversation with clear speaker/listener and no clipped faces or camera obstruction |
| Tactical agency | Preview/commit share one simulation; sustained tasks, positioning, extraction and enduring support | Different action sequences produce physically explained outcomes; worker contribution demonstrated |
| Consequential decisions | Authored observations, character knowledge and reporting with an actual tradeoff | Report changes one visible worker/environment state and survives save/load |
| Finished sound and interface | Footsteps/contact cues, located machinery, restrained ambience, readable HUD and settings | Full route can be understood visually and with reduced effects; audio mix has independent controls |

## Art direction from the supplied references

Reviewed `art/concept/image-gen-1(20260902-143749).png` (field signal apparatus) and
`art/concept/Gilded Etherbound Floating Realm.png` (book-cover composition). These are visual
references only; text or labelled mechanisms in an image do not establish canon.

Use the equipment sheet for construction vocabulary: hinges, handles, layered assemblies,
fasteners, protective casing, worn edges, fabric and a human scale reference. The current
single-colour primitive props omit most of this language. Translate selected details into
readable geometry at the camera's actual distance, with smaller detail in surface maps.

Use the cover's contrast and restrained gold as a palette reference, not as approval for a
floating-world level or constant glowing powers. Establish warm work-light focal points
against cool environmental fill. Keep metal dark but readable; avoid losing faces in black
or making every surface equally glossy. Keep a mid-distance silhouette and background depth
so the level feels situated rather than suspended against an empty background.

The first test area should be approximately a 10x12 metre work bay plus a short approach,
reusing the same rescue location. This is a production test size, not geography or canon.
Use one doorway or arch to frame entry, one hero machine/bench, the readable structural
connection and one strong dialogue background. Props should indicate work and access routes.

## Work sequence and gates

### A. Repair the trustworthy playable foundation

Owner: Codex engineering; Malek resolves disputed power semantics.

Implement J10-01–05 before expanding content: a single authoritative incident outcome,
validated reaction anchors, maintained effect lifecycle, truthful snapshot/phase checkpoint
behaviour and collision/navigation. Render actions and UI from model state. Keep the tested
core graph and physiology; repair their integration with the new slice.

Acceptance: regressions for stable alternative sequences, actual overload, reserve depletion,
partial throughput, cancellation and a saved incident that resumes equivalently. Play a route
around a solid obstacle and reject an unreachable click. No final art is needed to verify this.

### B. Set a visual standard in one room

Owner: Codex technical art and environment integration; Malek art direction.

Create a contact sheet of the supplied reference collection, then select governing environment,
character and material references. Obtain explicit identity/era decisions before bespoke canon
equipment or faces. Until then use clearly labelled neutral asset trials.

Build the test bay with a small reusable kit, clean normals/bevels, consistent scale, UVs,
collision and four material families. Add selected textured surface maps, restrained wear,
background composition and authored lighting in Godot. Use shadow and lightmap approaches
appropriate to static versus moving objects, and measure rather than increasing light counts.

Acceptance: three fixed 1080p engine views (entry, tactical, dialogue background), HUD hidden,
plus an orbit around the playable space. Malek approves whether this looks like Etherbound.
If it fails visually, revise this room before copying the kit across the map.

### C. Finish one character and the animation contract

Owner: Codex pipeline/rig integration; artist or approved source for hero mesh quality;
Malek approves character identity and visual identifiers.

Replace the proof mesh with a cohesive humanoid: believable proportions, deforming shoulders,
elbows and knees, separate eyes, usable eyelids/mouth, controlled hair and layered workwear.
Use baked normal detail and roughness variation; select skin/hair treatment by actual engine
close-up tests. Keep the original hero target of roughly 15k–35k triangles as a starting
budget, not an instruction to add geometry. Begin with 2K texture sets and profile the cast
together before increasing them.

Establish a stable rest pose, scale, bone mapping and root-motion convention. Preserve names
where useful, but do not force the 18-bone proof rig to be the permanent facial/hand solution.
Use animation retargeting deliberately and inspect every imported clip for axis, contact,
loop and deformation errors. Blend locomotion states; add look-at/foot and hand adjustments
only after base clips work. A meaningful small set can cover idle, walk, starts/stops, turns,
inspect, reach/operate, brace start/hold/release, kneel/rise and stagger/recover.

Acceptance: neutral lit turntable and a 20-second locomotion/contact reel in Godot, plus a
face close-up showing blink, gaze and restrained expression. No permanent spread-arm idle,
sliding feet, exploding skin or unrelated glowing costume features.

### D. Prove a 60–90 second playable presentation sequence

Owner: Codex scene direction/implementation; Malek approves writing and staging.

Enter the finished bay, walk around its central obstacle with one companion, meet the worker,
play a short conversation, inspect the structural joint and perform one physically explained
action. Add a second character of compatible visual quality for the dialogue. Use authored
camera marks, speaker/listener gaze, reaction timing, hand contact and clear subtitles.

Keep the full world camera controllable during exploration. For dialogue, choose lens/distance
for faces and eye lines, then test cut timing and return to play. Keep roof/column occlusion
out of the dialogue shots and use a camera fade/cutaway policy for exploration.

For voice, record a small approved script with willing performers (Malek scratch lines are
enough for timing), then replace when final. Use simple authored mouth/face animation matched
to that audio before attempting an automated facial pipeline. A voiced script requires
approved voices and recorded performance rights. Do not spend on a full voice cast yet.

Acceptance: a continuous player-driven clip at target resolution, including exploration,
conversation and action. Malek judges it against the desired game presentation. This is the
next major visual approval gate and should precede making all four cast assets final.

### E. Assemble the complete fifteen-minute experience

Owner: Codex engineering/content integration; Malek narrative decisions.

Expand the approved kit over the existing four compact zones; apply the accepted cast pipeline
to three party members and the directable worker. Finish one rescue with actual danger,
preparation, maintained commitments, worker access/physical intervention and visible extraction.
Keep the environment responsible for the tactics: load, footing, material and approach matter.
Do not introduce a new affinity, combat subsystem or larger map to fill runtime.

Proposed first-play rhythm (to validate, not enforce with delays):

| Segment | Target | Player work |
|---|---:|---|
| Arrival and worker exchange | 1–1.5 min | Understand the people and immediate task |
| Exploration and diagnosis | 2–3 min | Inspect the site, identify risk and choose preparation |
| Rescue | 5–6 min | Allocate maintained jobs, direct worker/extraction, adapt to pressure |
| Evidence and reporting | 2–3 min | Compare three observations, separate belief from proof, choose a report |
| Visible aftermath | 1–1.5 min | See the changed situation and a character response |

Target total: approximately 12–15 minutes for an unfamiliar player. Experienced replay may
be faster. Never add walking distance, repeated clicks or unskippable waiting just to reach
a number. Use the first playtests to adjust decisions and teaching, not the timer.

Narrative work needs the four characters, era/site, dialogue tone, rescue subject and report
recipient from Malek. The incident is a companion story, not a novel retelling. Keep protected
revelations out of both dialogue and environmental implication. Pending facts stay `[NEEDS AUTHOR]`.

### F. Release candidate and repeat Junction 10 acceptance

Owner: Codex technical validation; Malek and unfamiliar players for experience approval.

Add remappable actions, scalable text/UI, subtitle/focus support, volume controls, reduced
camera motion and a labelled tactical-overlay toggle. Finish positional contact/structural
audio and material aftermath. Remove development banners from ordinary play while retaining
an accessible prototype notice and optional diagnostics.

Export a Windows build with applicable credits/notices and only approved runtime assets.
Run from outside the editor, test save/load and recovery, and capture the entire route. Target
1080p at 60 FPS on the stated Windows PC, subject to measurement; record frame-time distribution
and worst spikes, not just FPS. Track CPU/GPU time, draw calls, visible primitives, RAM/VRAM
and navigation costs. The old 720p 2.2-second capture readings do not establish this budget.
Use a separate measured preset for the Mac rather than assuming equal settings/performance.

Run the unfamiliar-player protocol in the audit. Acceptance requires repaired P1 findings,
no progression blockers, author/canon approval, agreed visual quality, licence/export review
and observed playtime. Only then consider the repo's later 30–60 minute incident milestone.
A campaign remains a separate scope decision.

## Practical asset and tool strategy

Use Godot for world assembly, gameplay, navigation, UI and final lighting; Blender for mesh,
UV, rig, animation cleanup and GLB export; Krita for paintovers and texture masks. Keep editable
sources in LFS and engine wrappers separate from generated/imported scenes. Re-exporting an
asset must not erase collision, interaction or camera work. This follows Godot's documented
[3D import workflow](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/index.html).

For humanoid animation candidates, Adobe's [Mixamo FAQ](https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html)
allows royalty-free use in games. That is a useful candidate source, not a download made or
a blanket clearance for every distribution arrangement. Use the approved acquisition process,
record originals/clip IDs and check redistribution before exposing raw source files in Git.
Retarget onto a coherent cast; a mix of unrelated stock characters will undermine the style.

[Poly Haven](https://polyhaven.com/license) publishes asset files under CC0 and is a candidate
for surface maps/HDRIs. Record exact sources even when attribution is optional. Do not
assume website code, logos or APIs have the asset licence. No acquisition happened in this audit.

For hero character fidelity, compare two concrete paths at gate C: adapt one compatible
licensed character/base, or commission/model a bespoke hero. Prefer proving the former if
budget is tight, with deliberate Etherbound clothing/material work. A specialised character
artist becomes the best use of outside budget if faces/deformation repeatedly fail review.
Do not buy a large pack before one asset has proved style, rig compatibility and engine quality.

Godot MCP Pro's missing paid server does not block this production sequence: editable project
files, Blender scripts and the tested import pipeline already work. MCP can improve interaction,
but purchasing it will not improve model anatomy, animation or scene direction by itself.

## Effort and collaboration

Plan in accepted outputs rather than model sessions. A–D are multiple engineering/art
iterations; E–F add content, testing and revision. This is a weeks-to-months production effort
depending on asset availability, human review and desired fidelity, not a credible one-prompt
completion promise. Estimate dates and external spend after the first finished character and
room reveal the actual cost per accepted asset. No spending is authorised by this estimate.

Codex can own the current engineering, Blender automation, import work, scene assembly and
regressions. Malek supplies canon, art direction and play experience decisions. If Claude
returns, assign a separate claimed file set through TASKS.md and Git; do not overlap files.
Use focused implementation sessions with visible before/after evidence, then an independent
audit at each major acceptance gate. Repeatedly generating more primitive assets is not the
route to the desired quality.

The decisions needed before final hero production are: (1) approve or revise the proposed
detailed stylized realism target; (2) choose governing environment/character references;
(3) lock era/site and four identities; (4) set any external asset/artist budget. Repairs and
neutral material/rig trials can proceed while these decisions are pending.
