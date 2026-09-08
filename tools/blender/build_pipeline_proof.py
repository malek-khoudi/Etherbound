"""Build the Etherbound Blender-to-Godot pipeline proof assets.

Run with Blender, not Python:
    blender --background --factory-startup --python tools/blender/build_pipeline_proof.py

The script deliberately creates neutral, non-canon proof assets.  It writes editable
Blender sources, review renders, and runtime GLB exports to their repo-owned paths.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


REPO_ROOT = Path(__file__).resolve().parents[2]
ENV_BLEND = REPO_ROOT / "art/models/kit/pipeline_environment.blend"
ENV_PREVIEW = REPO_ROOT / "art/models/kit/pipeline_environment_preview.png"
ENV_GLB = REPO_ROOT / "game/assets/models/environment/pipeline_environment.glb"
CHAR_BLEND = REPO_ROOT / "art/models/characters/pipeline_character.blend"
CHAR_PREVIEW = REPO_ROOT / "art/models/characters/pipeline_character_preview.png"
CHAR_GLB = REPO_ROOT / "game/assets/models/characters/pipeline_character.glb"
MANIFEST = REPO_ROOT / "game/assets/models/pipeline_manifest.json"


def ensure_directories() -> None:
    for path in (ENV_BLEND, ENV_PREVIEW, ENV_GLB, CHAR_BLEND, CHAR_PREVIEW, CHAR_GLB, MANIFEST):
        path.parent.mkdir(parents=True, exist_ok=True)


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
    bpy.context.scene.render.resolution_x = 768
    bpy.context.scene.render.resolution_y = 768
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.render.image_settings.file_format = "PNG"
    world = bpy.data.worlds.new("PipelineWorld")
    world.color = (0.006, 0.008, 0.012)
    bpy.context.scene.world = world


def make_material(
    name: str,
    color: tuple[float, float, float, float],
    metallic: float = 0.0,
    roughness: float = 0.65,
    emission: tuple[float, float, float, float] | None = None,
    emission_strength: float = 0.0,
) -> bpy.types.Material:
    material = bpy.data.materials.new(name=name)
    material.diffuse_color = color
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = color
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    if emission is not None:
        shader.inputs["Emission Color"].default_value = emission
        shader.inputs["Emission Strength"].default_value = emission_strength
    return material


def assign_material(obj: bpy.types.Object, material: bpy.types.Material) -> None:
    obj.data.materials.append(material)


def add_box(
    name: str,
    location: tuple[float, float, float],
    dimensions: tuple[float, float, float],
    material: bpy.types.Material,
    bevel: float = 0.04,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        modifier = obj.modifiers.new(name="Edge softening", type="BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    assign_material(obj, material)
    return obj


def add_cylinder(
    name: str,
    location: tuple[float, float, float],
    radius: float,
    depth: float,
    material: bpy.types.Material,
    vertices: int = 12,
    rotation: tuple[float, float, float] = (0.0, 0.0, 0.0),
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=radius,
        depth=depth,
        location=location,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign_material(obj, material)
    return obj


def add_segment(
    name: str,
    start: tuple[float, float, float],
    end: tuple[float, float, float],
    radius: float,
    material: bpy.types.Material,
    vertices: int = 10,
) -> bpy.types.Object:
    start_vector = Vector(start)
    end_vector = Vector(end)
    direction = end_vector - start_vector
    midpoint = (start_vector + end_vector) * 0.5
    obj = add_cylinder(name, tuple(midpoint), radius, direction.length, material, vertices)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = direction.to_track_quat("Z", "Y")
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=False)
    return obj


def add_ico(
    name: str,
    location: tuple[float, float, float],
    scale: tuple[float, float, float],
    material: bpy.types.Material,
    subdivisions: int = 2,
) -> bpy.types.Object:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    assign_material(obj, material)
    return obj


def look_at(obj: bpy.types.Object, target: tuple[float, float, float]) -> None:
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def add_review_lighting(camera_location: tuple[float, float, float], target: tuple[float, float, float]) -> None:
    camera_data = bpy.data.cameras.new("ReviewCamera")
    camera = bpy.data.objects.new("ReviewCamera", camera_data)
    bpy.context.collection.objects.link(camera)
    camera.location = camera_location
    camera_data.lens = 48
    look_at(camera, target)
    bpy.context.scene.camera = camera

    for name, location, color, energy, size in (
        ("KeyLight", (5.0, -5.0, 10.0), (1.0, 0.62, 0.30), 1500.0, 5.0),
        ("FillLight", (-6.0, -2.0, 6.0), (0.20, 0.48, 1.0), 1100.0, 4.0),
        ("RimLight", (1.0, 6.0, 8.0), (0.35, 0.75, 1.0), 1300.0, 3.0),
    ):
        light_data = bpy.data.lights.new(name=name, type="AREA")
        light_data.energy = energy
        light_data.color = color
        light_data.shape = "DISK"
        light_data.size = size
        light = bpy.data.objects.new(name, light_data)
        bpy.context.collection.objects.link(light)
        light.location = location
        look_at(light, target)


def export_glb(path: Path) -> None:
    bpy.ops.export_scene.gltf(
        filepath=str(path),
        export_format="GLB",
        use_selection=False,
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_skins=True,
        export_yup=True,
        export_apply=True,
        export_cameras=False,
        export_lights=False,
    )


def build_environment() -> dict[str, int]:
    reset_scene()
    stone = make_material("Stone", (0.055, 0.067, 0.075, 1.0), roughness=0.92)
    iron = make_material("DarkIron", (0.035, 0.045, 0.052, 1.0), metallic=0.78, roughness=0.38)
    brass = make_material("AgedBrass", (0.31, 0.17, 0.055, 1.0), metallic=0.70, roughness=0.42)
    paint = make_material("OxidePaint", (0.08, 0.22, 0.23, 1.0), metallic=0.30, roughness=0.48)
    amber = make_material(
        "WarningAmber",
        (0.75, 0.20, 0.025, 1.0),
        metallic=0.08,
        roughness=0.32,
        emission=(1.0, 0.12, 0.01, 1.0),
        emission_strength=4.0,
    )

    add_box("Foundation", (0.0, 0.0, -0.18), (12.0, 8.0, 0.35), stone, 0.10)
    add_box("RaisedDeck", (0.2, 0.25, 0.16), (9.8, 5.6, 0.30), iron, 0.08)

    # Structural portal and suspended service gantry.
    for x in (-4.2, 4.2):
        add_box(f"PortalColumn_{x:+.0f}", (x, 1.2, 2.65), (0.55, 0.72, 5.0), iron, 0.08)
        add_box(f"ColumnFoot_{x:+.0f}", (x, 1.2, 0.48), (1.05, 1.20, 0.34), brass, 0.05)
    add_box("PortalHeader", (0.0, 1.2, 5.05), (9.0, 0.72, 0.65), iron, 0.09)
    add_box("GantryDeck", (0.0, 1.2, 3.55), (7.8, 1.55, 0.22), brass, 0.035)
    for x in (-3.7, -1.85, 0.0, 1.85, 3.7):
        add_box(f"GantryRib_{x:+.2f}", (x, 1.2, 3.80), (0.09, 1.48, 0.55), iron, 0.02)
    for y in (0.49, 1.91):
        add_segment(f"GantryRail_{y:+.2f}", (-3.9, y, 4.15), (3.9, y, 4.15), 0.055, iron, 10)
        for x in (-3.9, -2.6, -1.3, 0.0, 1.3, 2.6, 3.9):
            add_segment(f"RailPost_{x:+.1f}_{y:+.2f}", (x, y, 3.62), (x, y, 4.15), 0.045, iron, 8)

    # Industrial pipe run, machinery, and readable interactable shapes.
    add_segment("MainPipe", (-4.9, 2.9, 2.5), (4.9, 2.9, 2.5), 0.25, paint, 14)
    for x in (-4.1, -1.4, 1.4, 4.1):
        add_cylinder(f"PipeCollar_{x:+.1f}", (x, 2.9, 2.5), 0.34, 0.16, brass, 12, (0.0, math.pi / 2.0, 0.0))
    add_segment("PipeDrop", (3.65, 2.9, 2.5), (3.65, 2.9, 0.62), 0.20, paint, 14)

    add_box("MachineHousing", (-2.25, -1.55, 1.05), (2.25, 1.55, 1.75), paint, 0.12)
    add_box("MachineInset", (-2.25, -2.35, 1.10), (1.25, 0.16, 0.78), iron, 0.025)
    for x in (-2.62, -2.25, -1.88):
        add_cylinder(f"Indicator_{x:+.2f}", (x, -2.445, 1.20), 0.075, 0.05, amber, 10, (math.pi / 2.0, 0.0, 0.0))
    add_cylinder("Flywheel", (-1.05, -1.55, 1.08), 0.62, 0.20, brass, 16, (0.0, math.pi / 2.0, 0.0))
    for angle in range(0, 360, 45):
        radians = math.radians(angle)
        start = (-0.94, -1.55 + math.sin(radians) * 0.12, 1.08 + math.cos(radians) * 0.12)
        end = (-0.94, -1.55 + math.sin(radians) * 0.52, 1.08 + math.cos(radians) * 0.52)
        add_segment(f"FlywheelSpoke_{angle}", start, end, 0.035, iron, 8)

    add_box("SupplyCrate", (1.65, -1.72, 0.67), (1.35, 1.18, 1.15), stone, 0.07)
    for z in (0.28, 1.06):
        add_box(f"CrateBand_{z:.2f}", (1.65, -1.72, z), (1.43, 1.25, 0.12), brass, 0.02)
    for x in (1.03, 2.27):
        add_box(f"CrateSideBand_{x:.2f}", (x, -1.72, 0.67), (0.10, 1.25, 1.12), brass, 0.02)

    add_box("InspectionConsole", (3.15, -1.55, 0.85), (0.92, 0.70, 1.45), iron, 0.08)
    console_top = add_box("ConsoleFace", (3.15, -1.91, 1.34), (0.72, 0.10, 0.52), brass, 0.025)
    console_top.rotation_euler.x = math.radians(-14.0)
    for x in (2.95, 3.15, 3.35):
        add_cylinder(f"ConsoleLamp_{x:.2f}", (x, -1.985, 1.37), 0.045, 0.035, amber, 8, (math.pi / 2.0, 0.0, 0.0))

    # Floor navigation studs and a damaged brace make the kit more than a blockout.
    for x in range(-4, 5):
        for y in (-2.7, 2.7):
            add_cylinder(f"DeckStud_{x}_{y:+.1f}", (float(x), y, 0.35), 0.055, 0.035, brass, 8)
    damaged_brace = add_box("DamagedBrace", (0.15, 0.62, 2.35), (0.20, 0.24, 2.75), brass, 0.035)
    damaged_brace.rotation_euler.y = math.radians(-17.0)
    add_box("BraceWarning", (0.58, 0.34, 0.42), (0.74, 0.34, 0.14), amber, 0.025)

    bpy.context.scene["etherbound_asset_role"] = "neutral_pipeline_environment"
    bpy.context.scene["canon_status"] = "NON_CANON_PROOF"
    bpy.ops.wm.save_as_mainfile(filepath=str(ENV_BLEND))
    export_glb(ENV_GLB)
    add_review_lighting((10.5, -12.5, 8.6), (0.0, 0.0, 2.0))
    bpy.context.scene.render.filepath = str(ENV_PREVIEW)
    bpy.ops.render.render(write_still=True)

    mesh_count = sum(1 for obj in bpy.context.scene.objects if obj.type == "MESH")
    triangle_count = sum(len(obj.data.loop_triangles) for obj in bpy.context.scene.objects if obj.type == "MESH")
    return {"mesh_count": mesh_count, "triangle_count": triangle_count, "material_count": 5}


def create_armature() -> bpy.types.Object:
    armature_data = bpy.data.armatures.new("PipelineCharacterRig")
    armature = bpy.data.objects.new("PipelineCharacterRig", armature_data)
    bpy.context.collection.objects.link(armature)
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")

    bones = {
        "Root": ((0.0, 0.0, 0.0), (0.0, 0.0, 0.25), None),
        "Hips": ((0.0, 0.0, 0.92), (0.0, 0.0, 1.16), "Root"),
        "Spine": ((0.0, 0.0, 1.16), (0.0, 0.0, 1.52), "Hips"),
        "Chest": ((0.0, 0.0, 1.52), (0.0, 0.0, 1.82), "Spine"),
        "Neck": ((0.0, 0.0, 1.82), (0.0, 0.0, 2.02), "Chest"),
        "Head": ((0.0, 0.0, 2.02), (0.0, 0.0, 2.34), "Neck"),
        "UpperArm.L": ((0.18, 0.0, 1.76), (0.56, 0.0, 1.62), "Chest"),
        "Forearm.L": ((0.56, 0.0, 1.62), (0.88, 0.0, 1.43), "UpperArm.L"),
        "Hand.L": ((0.88, 0.0, 1.43), (1.02, 0.0, 1.35), "Forearm.L"),
        "UpperArm.R": ((-0.18, 0.0, 1.76), (-0.56, 0.0, 1.62), "Chest"),
        "Forearm.R": ((-0.56, 0.0, 1.62), (-0.88, 0.0, 1.43), "UpperArm.R"),
        "Hand.R": ((-0.88, 0.0, 1.43), (-1.02, 0.0, 1.35), "Forearm.R"),
        "Thigh.L": ((0.14, 0.0, 1.08), (0.16, 0.0, 0.65), "Hips"),
        "Shin.L": ((0.16, 0.0, 0.65), (0.16, 0.0, 0.20), "Thigh.L"),
        "Foot.L": ((0.16, 0.0, 0.20), (0.16, -0.28, 0.08), "Shin.L"),
        "Thigh.R": ((-0.14, 0.0, 1.08), (-0.16, 0.0, 0.65), "Hips"),
        "Shin.R": ((-0.16, 0.0, 0.65), (-0.16, 0.0, 0.20), "Thigh.R"),
        "Foot.R": ((-0.16, 0.0, 0.20), (-0.16, -0.28, 0.08), "Shin.R"),
    }
    created: dict[str, bpy.types.EditBone] = {}
    for name, (head, tail, parent_name) in bones.items():
        bone = armature_data.edit_bones.new(name)
        bone.head = head
        bone.tail = tail
        if parent_name is not None:
            bone.parent = created[parent_name]
        created[name] = bone

    bpy.ops.object.mode_set(mode="OBJECT")
    armature.show_in_front = True
    return armature


def skin_to_bone(obj: bpy.types.Object, armature: bpy.types.Object, bone_name: str) -> None:
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new(name="Armature", type="ARMATURE")
    modifier.object = armature
    obj.parent = armature


def add_character_meshes(armature: bpy.types.Object) -> int:
    cloth = make_material("ProofCloth", (0.045, 0.15, 0.17, 1.0), metallic=0.08, roughness=0.75)
    leather = make_material("ProofLeather", (0.105, 0.055, 0.032, 1.0), metallic=0.0, roughness=0.88)
    brass = make_material("ProofBrass", (0.39, 0.21, 0.055, 1.0), metallic=0.72, roughness=0.40)
    skin = make_material("ProofSkin", (0.33, 0.19, 0.13, 1.0), metallic=0.0, roughness=0.72)
    dark = make_material("ProofDark", (0.018, 0.025, 0.030, 1.0), metallic=0.18, roughness=0.58)

    parts: list[tuple[bpy.types.Object, str]] = []
    parts.append((add_box("Pelvis", (0.0, 0.0, 1.09), (0.54, 0.32, 0.27), leather, 0.06), "Hips"))
    parts.append((add_box("Torso", (0.0, 0.0, 1.50), (0.67, 0.36, 0.64), cloth, 0.10), "Spine"))
    parts.append((add_box("ShoulderMantle", (0.0, 0.0, 1.75), (0.82, 0.42, 0.18), leather, 0.05), "Chest"))
    parts.append((add_cylinder("NeckMesh", (0.0, 0.0, 1.94), 0.105, 0.18, skin, 10), "Neck"))
    parts.append((add_ico("HeadMesh", (0.0, -0.015, 2.15), (0.205, 0.18, 0.26), skin, 2), "Head"))
    parts.append((add_box("MaskBand", (0.0, -0.172, 2.16), (0.27, 0.035, 0.07), brass, 0.015), "Head"))
    parts.append((add_box("Belt", (0.0, -0.01, 1.20), (0.60, 0.37, 0.10), brass, 0.025), "Hips"))

    segment_specs = (
        ("UpperArm.L", (0.18, 0.0, 1.76), (0.56, 0.0, 1.62), 0.115, cloth),
        ("Forearm.L", (0.56, 0.0, 1.62), (0.88, 0.0, 1.43), 0.09, leather),
        ("UpperArm.R", (-0.18, 0.0, 1.76), (-0.56, 0.0, 1.62), 0.115, cloth),
        ("Forearm.R", (-0.56, 0.0, 1.62), (-0.88, 0.0, 1.43), 0.09, leather),
        ("Thigh.L", (0.14, 0.0, 1.08), (0.16, 0.0, 0.65), 0.14, cloth),
        ("Shin.L", (0.16, 0.0, 0.65), (0.16, 0.0, 0.20), 0.115, dark),
        ("Thigh.R", (-0.14, 0.0, 1.08), (-0.16, 0.0, 0.65), 0.14, cloth),
        ("Shin.R", (-0.16, 0.0, 0.65), (-0.16, 0.0, 0.20), 0.115, dark),
    )
    for bone_name, start, end, radius, material in segment_specs:
        parts.append((add_segment(f"{bone_name}Mesh", start, end, radius, material, 8), bone_name))

    for side, x in (("L", 0.97), ("R", -0.97)):
        parts.append((add_ico(f"Hand.{side}Mesh", (x, 0.0, 1.38), (0.105, 0.085, 0.13), skin, 1), f"Hand.{side}"))
        foot = add_box(f"Foot.{side}Mesh", (0.16 if side == "L" else -0.16, -0.14, 0.12), (0.24, 0.43, 0.20), dark, 0.045)
        parts.append((foot, f"Foot.{side}"))

    for obj, bone_name in parts:
        skin_to_bone(obj, armature, bone_name)
    return len(parts)


def reset_pose(armature: bpy.types.Object) -> None:
    for pose_bone in armature.pose.bones:
        pose_bone.rotation_mode = "XYZ"
        pose_bone.rotation_euler = (0.0, 0.0, 0.0)
        pose_bone.location = (0.0, 0.0, 0.0)
        pose_bone.scale = (1.0, 1.0, 1.0)


def key_pose(armature: bpy.types.Object, frame: int, changes: dict[str, tuple[float, float, float]]) -> None:
    reset_pose(armature)
    for bone_name, rotation_degrees in changes.items():
        pose_bone = armature.pose.bones[bone_name]
        pose_bone.rotation_euler = tuple(math.radians(value) for value in rotation_degrees)
    for pose_bone in armature.pose.bones:
        pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame, group=pose_bone.name)
        pose_bone.keyframe_insert(data_path="location", frame=frame, group=pose_bone.name)


def make_action(
    armature: bpy.types.Object,
    name: str,
    last_frame: int,
    poses: list[tuple[int, dict[str, tuple[float, float, float]]]],
) -> None:
    action = bpy.data.actions.new(name=name)
    armature.animation_data_create()
    armature.animation_data.action = action
    for frame, changes in poses:
        key_pose(armature, frame, changes)
    action.frame_start = 1
    action.frame_end = last_frame
    action.use_frame_range = True


def create_actions(armature: bpy.types.Object) -> list[str]:
    make_action(
        armature,
        "idle",
        40,
        [
            (1, {"Chest": (0.0, 0.0, -1.5), "Head": (0.0, 0.0, 2.0)}),
            (20, {"Chest": (1.2, 0.0, 1.5), "Head": (-1.0, 0.0, -2.0)}),
            (40, {"Chest": (0.0, 0.0, -1.5), "Head": (0.0, 0.0, 2.0)}),
        ],
    )
    make_action(
        armature,
        "walk",
        24,
        [
            (1, {"Thigh.L": (28.0, 0.0, 0.0), "Thigh.R": (-28.0, 0.0, 0.0), "UpperArm.L": (-22.0, 0.0, 4.0), "UpperArm.R": (22.0, 0.0, -4.0)}),
            (7, {"Thigh.L": (0.0, 0.0, 0.0), "Thigh.R": (0.0, 0.0, 0.0), "Shin.L": (-18.0, 0.0, 0.0)}),
            (13, {"Thigh.L": (-28.0, 0.0, 0.0), "Thigh.R": (28.0, 0.0, 0.0), "UpperArm.L": (22.0, 0.0, 4.0), "UpperArm.R": (-22.0, 0.0, -4.0)}),
            (19, {"Thigh.L": (0.0, 0.0, 0.0), "Thigh.R": (0.0, 0.0, 0.0), "Shin.R": (-18.0, 0.0, 0.0)}),
            (24, {"Thigh.L": (28.0, 0.0, 0.0), "Thigh.R": (-28.0, 0.0, 0.0), "UpperArm.L": (-22.0, 0.0, 4.0), "UpperArm.R": (22.0, 0.0, -4.0)}),
        ],
    )
    make_action(
        armature,
        "inspect",
        48,
        [
            (1, {}),
            (16, {"Chest": (0.0, 0.0, -8.0), "Head": (0.0, 0.0, -18.0), "UpperArm.R": (-12.0, -32.0, 18.0), "Forearm.R": (-36.0, 0.0, -12.0)}),
            (32, {"Chest": (0.0, 0.0, 8.0), "Head": (0.0, 0.0, 18.0), "UpperArm.L": (-12.0, 32.0, -18.0), "Forearm.L": (-36.0, 0.0, 12.0)}),
            (48, {}),
        ],
    )
    make_action(
        armature,
        "brace",
        48,
        [
            (1, {}),
            (12, {"Spine": (14.0, 0.0, 0.0), "Thigh.L": (-22.0, 0.0, 8.0), "Thigh.R": (-22.0, 0.0, -8.0), "Shin.L": (32.0, 0.0, 0.0), "Shin.R": (32.0, 0.0, 0.0), "UpperArm.L": (-38.0, -18.0, -18.0), "UpperArm.R": (-38.0, 18.0, 18.0), "Forearm.L": (-42.0, 0.0, 0.0), "Forearm.R": (-42.0, 0.0, 0.0)}),
            (30, {"Spine": (18.0, 0.0, 0.0), "Thigh.L": (-26.0, 0.0, 9.0), "Thigh.R": (-26.0, 0.0, -9.0), "Shin.L": (38.0, 0.0, 0.0), "Shin.R": (38.0, 0.0, 0.0), "UpperArm.L": (-44.0, -20.0, -20.0), "UpperArm.R": (-44.0, 20.0, 20.0), "Forearm.L": (-48.0, 0.0, 0.0), "Forearm.R": (-48.0, 0.0, 0.0)}),
            (48, {}),
        ],
    )
    armature.animation_data.action = bpy.data.actions["idle"]
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 48
    bpy.context.scene.render.fps = 24
    return ["idle", "walk", "inspect", "brace"]


def build_character() -> dict[str, int | list[str]]:
    reset_scene()
    armature = create_armature()
    mesh_count = add_character_meshes(armature)
    actions = create_actions(armature)
    armature["etherbound_asset_role"] = "neutral_pipeline_character"
    armature["canon_status"] = "NON_CANON_PROOF"

    bpy.context.scene.frame_set(30)
    bpy.ops.wm.save_as_mainfile(filepath=str(CHAR_BLEND))
    export_glb(CHAR_GLB)
    add_review_lighting((4.2, -7.0, 3.2), (0.0, 0.0, 1.2))
    bpy.context.scene.render.filepath = str(CHAR_PREVIEW)
    bpy.ops.render.render(write_still=True)

    triangle_count = sum(len(obj.data.loop_triangles) for obj in bpy.context.scene.objects if obj.type == "MESH")
    return {
        "mesh_count": mesh_count,
        "triangle_count": triangle_count,
        "material_count": 5,
        "bone_count": len(armature.data.bones),
        "animations": actions,
    }


def main() -> None:
    ensure_directories()
    environment = build_environment()
    character = build_character()
    manifest = {
        "schema_version": 1,
        "canon_status": "NON_CANON_PROOF",
        "generator": "tools/blender/build_pipeline_proof.py",
        "blender_version": bpy.app.version_string,
        "environment": {
            "source": "art/models/kit/pipeline_environment.blend",
            "runtime": "game/assets/models/environment/pipeline_environment.glb",
            **environment,
        },
        "character": {
            "source": "art/models/characters/pipeline_character.blend",
            "runtime": "game/assets/models/characters/pipeline_character.glb",
            **character,
        },
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(manifest, indent=2))


if __name__ == "__main__":
    main()
