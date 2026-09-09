"""Build the non-canon Etherbound 15-minute vertical-slice art set.

Run with Blender, not system Python:
    blender --background --factory-startup --python tools/blender/build_vertical_slice.py

The four role silhouettes and site are adaptation prototypes. They deliberately avoid
names, insignia, institutions and location-specific lore until the author locks them.
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from build_pipeline_proof import (  # noqa: E402
    add_box,
    add_cylinder,
    add_ico,
    add_review_lighting,
    add_segment,
    assign_material,
    create_actions,
    create_armature,
    export_glb,
    make_action,
    make_material,
    reset_scene,
    skin_to_bone,
)


REPO_ROOT = SCRIPT_DIR.parents[1]
ENV_BLEND = REPO_ROOT / "art/models/kit/slice_environment.blend"
ENV_PREVIEW = REPO_ROOT / "art/models/kit/slice_environment_preview.png"
ENV_GLB = REPO_ROOT / "game/assets/models/environment/slice_environment.glb"
CAST_ROOT = REPO_ROOT / "art/models/characters"
CAST_GAME_ROOT = REPO_ROOT / "game/assets/models/characters"
MANIFEST = REPO_ROOT / "game/assets/models/vertical_slice_manifest.json"

ROLE_SPECS = {
    "kinetic": {
        "cloth": (0.16, 0.065, 0.028, 1.0),
        "metal": (0.42, 0.20, 0.045, 1.0),
        "accent": (1.0, 0.33, 0.035, 1.0),
    },
    "gravitic": {
        "cloth": (0.035, 0.11, 0.18, 1.0),
        "metal": (0.16, 0.28, 0.34, 1.0),
        "accent": (0.20, 0.74, 0.92, 1.0),
    },
    "transmutative": {
        "cloth": (0.075, 0.18, 0.12, 1.0),
        "metal": (0.32, 0.27, 0.075, 1.0),
        "accent": (0.35, 0.95, 0.58, 1.0),
    },
    "worker": {
        "cloth": (0.12, 0.13, 0.13, 1.0),
        "metal": (0.31, 0.24, 0.10, 1.0),
        "accent": (0.95, 0.67, 0.18, 1.0),
    },
}


def ensure_directories() -> None:
    for path in (ENV_BLEND, ENV_PREVIEW, ENV_GLB, MANIFEST):
        path.parent.mkdir(parents=True, exist_ok=True)
    CAST_ROOT.mkdir(parents=True, exist_ok=True)
    CAST_GAME_ROOT.mkdir(parents=True, exist_ok=True)


def add_floor_module(name: str, x: float, y: float, stone, iron, brass) -> None:
    add_box(f"{name}_StoneBed", (x, y, -0.18), (4.8, 5.4, 0.34), stone, 0.08)
    add_box(f"{name}_IronDeck", (x, y, 0.08), (4.35, 4.95, 0.18), iron, 0.035)
    for ix in (-1.7, 0.0, 1.7):
        for iy in (-2.0, 2.0):
            add_cylinder(f"{name}_Stud_{ix}_{iy}", (x + ix, y + iy, 0.20), 0.055, 0.04, brass, 8)


def build_environment() -> dict[str, int | list[str]]:
    reset_scene()
    bpy.context.scene.render.resolution_x = 1400
    bpy.context.scene.render.resolution_y = 700

    stone = make_material("SliceStone", (0.032, 0.043, 0.048, 1.0), roughness=0.93)
    iron = make_material("SliceDarkIron", (0.025, 0.034, 0.038, 1.0), metallic=0.82, roughness=0.39)
    brass = make_material("SliceAgedBrass", (0.30, 0.16, 0.045, 1.0), metallic=0.74, roughness=0.43)
    paint = make_material("SliceOxidePaint", (0.035, 0.15, 0.17, 1.0), metallic=0.36, roughness=0.52)
    rust = make_material("SliceCorrosion", (0.30, 0.065, 0.018, 1.0), metallic=0.14, roughness=0.88)
    amber = make_material(
        "SliceAmber",
        (0.92, 0.26, 0.025, 1.0),
        metallic=0.12,
        roughness=0.28,
        emission=(1.0, 0.10, 0.01, 1.0),
        emission_strength=5.5,
    )

    zones = [
        ("Approach", -15.0),
        ("ApproachLink", -10.5),
        ("Control", -6.0),
        ("ControlLink", -1.5),
        ("Gantry", 3.0),
        ("GantryLink", 7.5),
        ("Consequence", 12.0),
    ]
    for name, x in zones:
        add_floor_module(name, x, 0.0, stone, iron, brass)

    # Repeating portal kit defines a legible continuous route.
    for index, x in enumerate((-17.0, -12.7, -8.2, -3.7, 0.8, 5.3, 9.8, 14.1)):
        for side in (-1.0, 1.0):
            add_box(f"Portal_{index}_Column_{side:+.0f}", (x, side * 2.35, 2.35), (0.42, 0.48, 4.55), iron, 0.065)
            add_box(f"Portal_{index}_Foot_{side:+.0f}", (x, side * 2.35, 0.30), (0.80, 0.84, 0.26), brass, 0.04)
        add_box(f"Portal_{index}_Header", (x, 0.0, 4.50), (0.46, 5.10, 0.46), iron, 0.065)
        add_cylinder(f"Portal_{index}_Lamp", (x + 0.12, 0.0, 4.18), 0.13, 0.18, amber, 10, (0.0, math.pi / 2.0, 0.0))

    # Approach: covered exterior, wet drainage and warning silhouette.
    for x in (-16.0, -13.5, -11.0):
        add_box(f"Approach_Canopy_{x}", (x, 0.0, 4.75), (2.25, 5.25, 0.16), iron, 0.04)
        add_segment(f"Approach_Drain_{x}", (x - 0.8, -2.05, 0.25), (x + 0.8, -2.05, 0.25), 0.11, brass, 10)
    for x, y, scale in ((-16.1, -1.2, 0.75), (-14.2, 1.1, 1.0), (-11.8, -0.4, 0.65)):
        puddle = add_cylinder(f"Approach_Puddle_{x}", (x, y, 0.19), scale, 0.018, paint, 20)
        puddle.scale.y = 0.45
    add_box("Approach_WarningBoard", (-11.0, 1.95, 1.35), (0.14, 1.35, 1.65), brass, 0.03)
    add_box("Approach_WarningInset", (-10.91, 1.95, 1.42), (0.05, 1.05, 1.15), rust, 0.015)

    # Control zone: machinery, signal set and repair stores.
    add_box("Control_MainHousing", (-6.3, 1.12, 1.15), (2.60, 1.75, 2.05), paint, 0.12)
    add_box("Control_Panel", (-4.95, 1.12, 1.36), (0.16, 1.28, 1.05), brass, 0.03)
    for y in (0.72, 1.12, 1.52):
        add_cylinder(f"Control_Gauge_{y}", (-4.84, y, 1.55), 0.13, 0.04, amber, 12, (0.0, math.pi / 2.0, 0.0))
    add_box("Control_LedgerDesk", (-6.4, -1.34, 0.82), (1.9, 1.08, 1.45), iron, 0.07)
    add_box("Evidence_MaintenanceLedger", (-6.25, -1.46, 1.62), (0.74, 0.52, 0.07), brass, 0.015)
    add_box("Control_SignalCase", (-3.15, -1.30, 0.62), (1.15, 0.78, 0.92), stone, 0.06)
    add_segment("Control_SignalMast", (-3.15, -1.30, 1.08), (-3.15, -1.30, 3.20), 0.06, brass, 9)
    add_segment("Control_SignalYard", (-3.72, -1.30, 2.85), (-2.58, -1.30, 2.85), 0.045, brass, 9)

    # Gantry incident zone: bridge, corroded load path and physical prop rack.
    for side in (-1.0, 1.0):
        add_box(f"Gantry_Tower_{side:+.0f}", (3.0, side * 2.05, 2.75), (0.70, 0.70, 5.25), iron, 0.08)
        add_box(f"Gantry_TowerFoot_{side:+.0f}", (3.0, side * 2.05, 0.38), (1.15, 1.10, 0.36), brass, 0.04)
    add_box("Gantry_UpperBeam", (3.0, 0.0, 5.20), (0.72, 4.85, 0.62), iron, 0.08)
    add_box("Gantry_Walkway", (4.65, 0.0, 3.35), (3.75, 2.10, 0.24), brass, 0.035)
    for y in (-0.94, 0.94):
        add_segment(f"Gantry_Rail_{y}", (2.78, y, 4.02), (6.53, y, 4.02), 0.055, iron, 9)
        for x in (2.82, 3.72, 4.62, 5.52, 6.42):
            add_segment(f"Gantry_RailPost_{x}_{y}", (x, y, 3.46), (x, y, 4.02), 0.045, iron, 8)
    bracket = add_box("Evidence_CorrodedBracket", (2.92, 0.0, 3.76), (0.34, 1.30, 0.82), rust, 0.025)
    bracket.rotation_euler.y = math.radians(-14.0)
    add_box("Gantry_LoadCrate", (5.25, 0.0, 3.92), (1.25, 1.20, 0.94), stone, 0.055)
    for x in (4.70, 5.80):
        add_box(f"Gantry_CrateBand_{x}", (x, 0.0, 3.92), (0.10, 1.28, 0.94), brass, 0.02)
    add_box("Gantry_PropRack", (1.0, -1.65, 1.00), (1.65, 0.65, 1.65), iron, 0.06)
    for x in (0.55, 1.0, 1.45):
        prop = add_box(f"Gantry_Prop_{x}", (x, -1.65, 1.48), (0.16, 0.16, 2.55), brass, 0.025)
        prop.rotation_euler.y = math.radians(8.0 * (x - 1.0))

    # Consequence zone: inspection table, barrier pieces and a readable exit frame.
    add_box("Consequence_InspectionTable", (11.0, -1.10, 0.82), (2.20, 1.10, 1.45), iron, 0.07)
    add_box("Evidence_BracketFragment", (10.7, -1.15, 1.61), (0.62, 0.28, 0.12), rust, 0.02)
    add_box("Evidence_PropImprint", (12.0, 1.20, 0.23), (0.75, 0.42, 0.05), brass, 0.01)
    for y in (-1.45, 1.45):
        add_box(f"Consequence_Barrier_{y}", (13.6, y, 0.86), (2.15, 0.12, 0.95), brass, 0.025)
        for x in (12.65, 14.55):
            add_segment(f"Consequence_Post_{x}_{y}", (x, y, 0.20), (x, y, 1.52), 0.065, iron, 9)
    add_box("Consequence_EndFrame", (15.9, 0.0, 2.45), (0.55, 5.10, 4.85), stone, 0.09)
    add_box("Consequence_EndOpening", (15.55, 0.0, 2.45), (0.26, 3.55, 3.55), paint, 0.04)

    # One continuous pipe run ties all four zones together.
    add_segment("Utility_MainPipe", (-17.2, 2.70, 2.75), (15.4, 2.70, 2.75), 0.22, paint, 14)
    for x in (-15.0, -10.5, -6.0, -1.5, 3.0, 7.5, 12.0):
        add_cylinder(f"Utility_Collar_{x}", (x, 2.70, 2.75), 0.30, 0.14, brass, 12, (0.0, math.pi / 2.0, 0.0))
    add_segment("Utility_Drop", (8.8, 2.70, 2.75), (8.8, 2.70, 0.48), 0.18, paint, 12)

    bpy.context.scene["etherbound_asset_role"] = "vertical_slice_environment"
    bpy.context.scene["canon_status"] = "NON_CANON_ADAPTATION_PROTOTYPE"
    bpy.context.scene["zones"] = "approach,control,gantry,consequence"
    bpy.ops.wm.save_as_mainfile(filepath=str(ENV_BLEND))
    export_glb(ENV_GLB)
    add_review_lighting((4.0, -29.0, 19.0), (-1.0, 0.0, 1.8))
    bpy.context.scene.render.filepath = str(ENV_PREVIEW)
    bpy.ops.render.render(write_still=True)

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    return {
        "mesh_count": len(meshes),
        "triangle_count": sum(len(obj.data.loop_triangles) for obj in meshes),
        "material_count": 6,
        "zones": ["approach", "control", "gantry", "consequence"],
    }


def set_material_color(name: str, color: tuple[float, float, float, float]) -> None:
    material = bpy.data.materials.get(name)
    if material is None:
        return
    material.diffuse_color = color
    shader = material.node_tree.nodes.get("Principled BSDF") if material.use_nodes else None
    if shader is not None:
        shader.inputs["Base Color"].default_value = color


def add_accessory_box(name: str, location, dimensions, material, armature, bone: str, rotation=(0.0, 0.0, 0.0)) -> None:
    obj = add_box(name, location, dimensions, material, 0.035)
    obj.rotation_euler = tuple(math.radians(value) for value in rotation)
    skin_to_bone(obj, armature, bone)


def add_role_accessories(role: str, armature: bpy.types.Object, accent) -> None:
    if role == "kinetic":
        add_accessory_box("Kinetic_PauldronL", (0.34, 0.0, 1.78), (0.38, 0.50, 0.18), accent, armature, "UpperArm.L", (0.0, 0.0, -12.0))
        add_accessory_box("Kinetic_PauldronR", (-0.34, 0.0, 1.78), (0.38, 0.50, 0.18), accent, armature, "UpperArm.R", (0.0, 0.0, 12.0))
        add_accessory_box("Kinetic_AnchorPlate", (0.0, -0.23, 1.48), (0.42, 0.10, 0.44), accent, armature, "Spine")
    elif role == "gravitic":
        add_cylinder("Gravitic_Collar", (0.0, 0.0, 1.83), 0.33, 0.10, accent, 12)
        skin_to_bone(bpy.context.object, armature, "Chest")
        add_accessory_box("Gravitic_BackMass", (0.0, 0.24, 1.48), (0.46, 0.17, 0.72), accent, armature, "Spine")
        for side, x in (("L", 0.76), ("R", -0.76)):
            add_accessory_box(f"Gravitic_Wrist_{side}", (x, 0.0, 1.50), (0.24, 0.24, 0.28), accent, armature, f"Forearm.{side}")
    elif role == "transmutative":
        for side, x in (("L", 0.74), ("R", -0.74)):
            add_cylinder(f"Transmutative_Gauntlet_{side}", (x, 0.0, 1.50), 0.13, 0.34, accent, 10, (0.0, math.pi / 2.0, 0.0))
            skin_to_bone(bpy.context.object, armature, f"Forearm.{side}")
        add_accessory_box("Transmutative_Satchel", (-0.38, 0.18, 1.03), (0.35, 0.24, 0.48), accent, armature, "Hips", (0.0, 0.0, 8.0))
    else:
        add_cylinder("Worker_Helmet", (0.0, 0.0, 2.29), 0.26, 0.16, accent, 12)
        skin_to_bone(bpy.context.object, armature, "Head")
        add_accessory_box("Worker_HelmetBrim", (0.0, -0.055, 2.24), (0.62, 0.44, 0.07), accent, armature, "Head")
        add_accessory_box("Worker_ToolPack", (0.0, 0.25, 1.40), (0.48, 0.20, 0.65), accent, armature, "Spine")


def add_slice_actions(armature: bpy.types.Object) -> list[str]:
    base = create_actions(armature)
    make_action(
        armature,
        "point",
        42,
        [
            (1, {}),
            (14, {"Chest": (0.0, 0.0, -8.0), "UpperArm.R": (-8.0, 62.0, 18.0), "Forearm.R": (-18.0, 0.0, 0.0), "Head": (0.0, 0.0, -16.0)}),
            (32, {"Chest": (0.0, 0.0, -8.0), "UpperArm.R": (-8.0, 62.0, 18.0), "Forearm.R": (-18.0, 0.0, 0.0), "Head": (0.0, 0.0, -16.0)}),
            (42, {}),
        ],
    )
    make_action(
        armature,
        "operate",
        48,
        [
            (1, {}),
            (14, {"Spine": (12.0, 0.0, 0.0), "UpperArm.L": (-32.0, 28.0, -8.0), "UpperArm.R": (-32.0, -28.0, 8.0), "Forearm.L": (-52.0, 0.0, 0.0), "Forearm.R": (-52.0, 0.0, 0.0)}),
            (32, {"Spine": (10.0, 0.0, 0.0), "UpperArm.L": (-26.0, 22.0, -5.0), "UpperArm.R": (-38.0, -32.0, 10.0), "Forearm.L": (-44.0, 0.0, 0.0), "Forearm.R": (-58.0, 0.0, 0.0)}),
            (48, {}),
        ],
    )
    make_action(
        armature,
        "kneel",
        52,
        [
            (1, {}),
            (20, {"Spine": (18.0, 0.0, 0.0), "Thigh.L": (-56.0, 0.0, 8.0), "Shin.L": (88.0, 0.0, 0.0), "Thigh.R": (-28.0, 0.0, -8.0), "Shin.R": (38.0, 0.0, 0.0), "UpperArm.L": (-35.0, 14.0, 0.0), "Forearm.L": (-54.0, 0.0, 0.0)}),
            (42, {"Spine": (18.0, 0.0, 0.0), "Thigh.L": (-56.0, 0.0, 8.0), "Shin.L": (88.0, 0.0, 0.0), "Thigh.R": (-28.0, 0.0, -8.0), "Shin.R": (38.0, 0.0, 0.0), "UpperArm.R": (-35.0, -14.0, 0.0), "Forearm.R": (-54.0, 0.0, 0.0)}),
            (52, {}),
        ],
    )
    make_action(
        armature,
        "stagger",
        36,
        [
            (1, {}),
            (8, {"Spine": (-16.0, 0.0, 12.0), "Chest": (-10.0, 0.0, -18.0), "UpperArm.L": (24.0, -38.0, -28.0), "UpperArm.R": (24.0, 38.0, 28.0), "Thigh.L": (18.0, 0.0, 0.0), "Thigh.R": (-22.0, 0.0, 0.0)}),
            (22, {"Spine": (12.0, 0.0, -8.0), "Chest": (8.0, 0.0, 12.0), "UpperArm.L": (-18.0, 18.0, 16.0), "UpperArm.R": (-18.0, -18.0, -16.0)}),
            (36, {}),
        ],
    )
    bpy.context.scene.render.fps = 24
    return base + ["point", "operate", "kneel", "stagger"]


def build_character(role: str, index: int) -> dict[str, int | str | list[str]]:
    reset_scene()
    bpy.context.scene.render.resolution_x = 620
    bpy.context.scene.render.resolution_y = 760
    spec = ROLE_SPECS[role]
    armature = create_armature()

    # Import the proven shared rig/mesh construction, then create a role silhouette.
    from build_pipeline_proof import add_character_meshes

    mesh_count = add_character_meshes(armature)
    set_material_color("ProofCloth", spec["cloth"])
    set_material_color("ProofBrass", spec["metal"])
    accent = make_material(
        f"{role.title()}Accent",
        spec["accent"],
        metallic=0.58,
        roughness=0.36,
        emission=spec["accent"],
        emission_strength=0.65,
    )
    add_role_accessories(role, armature, accent)
    actions = add_slice_actions(armature)
    armature["etherbound_role"] = role
    armature["canon_status"] = "NON_CANON_ADAPTATION_PROTOTYPE"
    bpy.context.scene["prototype_role"] = role
    bpy.context.scene["canon_status"] = "NON_CANON_ADAPTATION_PROTOTYPE"

    blend_path = CAST_ROOT / f"slice_{role}.blend"
    glb_path = CAST_GAME_ROOT / f"slice_{role}.glb"
    preview_path = CAST_ROOT / f"slice_{role}_preview.png"
    bpy.context.scene.frame_set(30 if role == "kinetic" else 16 + index * 4)
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
    export_glb(glb_path)
    add_review_lighting((4.2, -7.1, 3.25), (0.0, 0.0, 1.2))
    bpy.context.scene.render.filepath = str(preview_path)
    bpy.ops.render.render(write_still=True)

    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    return {
        "role": role,
        "source": str(blend_path.relative_to(REPO_ROOT)).replace("\\", "/"),
        "runtime": str(glb_path.relative_to(REPO_ROOT)).replace("\\", "/"),
        "preview": str(preview_path.relative_to(REPO_ROOT)).replace("\\", "/"),
        "mesh_count": len(meshes),
        "triangle_count": sum(len(obj.data.loop_triangles) for obj in meshes),
        "material_count": len(bpy.data.materials),
        "bone_count": len(armature.data.bones),
        "animations": actions,
    }


def main() -> None:
    ensure_directories()
    environment = build_environment()
    characters = [build_character(role, index) for index, role in enumerate(ROLE_SPECS)]
    manifest = {
        "schema_version": 1,
        "canon_status": "NON_CANON_ADAPTATION_PROTOTYPE",
        "generator": "tools/blender/build_vertical_slice.py",
        "blender_version": bpy.app.version_string,
        "concept_direction": "weathered dark iron and stone, restrained brass, amber work light, cool wet fill",
        "environment": {
            "source": "art/models/kit/slice_environment.blend",
            "runtime": "game/assets/models/environment/slice_environment.glb",
            "preview": "art/models/kit/slice_environment_preview.png",
            **environment,
        },
        "characters": characters,
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
