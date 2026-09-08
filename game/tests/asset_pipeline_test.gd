## Verifies that Blender deliverables survive import as usable Godot assets.
## Run: ./tools/test.sh
extends SceneTree

const ENVIRONMENT_PATH: String = "res://assets/models/environment/pipeline_environment.glb"
const CHARACTER_PATH: String = "res://assets/models/characters/pipeline_character.glb"
const REQUIRED_CLIPS: Array[String] = ["idle", "walk", "inspect", "brace"]

var _failures: int = 0


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("  PASS  ", label)
	else:
		_failures += 1
		print("  FAIL  ", label, "  ", detail)


func _initialize() -> void:
	print("\n=== Blender to Godot asset pipeline ===\n")
	var environment_scene: PackedScene = load(ENVIRONMENT_PATH) as PackedScene
	var character_scene: PackedScene = load(CHARACTER_PATH) as PackedScene
	_check("environment GLB imports", environment_scene != null, ENVIRONMENT_PATH)
	_check("character GLB imports", character_scene != null, CHARACTER_PATH)
	if environment_scene != null:
		_test_environment(environment_scene.instantiate())
	if character_scene != null:
		_test_character(character_scene.instantiate())
	print("\n=== %s ===\n" % ("ALL PASS" if _failures == 0 else "%d FAILURE(S)" % _failures))
	quit(1 if _failures > 0 else 0)


func _test_environment(root: Node) -> void:
	var mesh_count: int = _count_nodes_of_type(root, "MeshInstance3D")
	_check("environment contains authored meshes", mesh_count >= 20, "got %d" % mesh_count)
	_check("environment is not a one-mesh placeholder", root.get_child_count() >= 10, "got %d root children" % root.get_child_count())
	root.free()


func _test_character(root: Node) -> void:
	var skeleton: Skeleton3D = _find_skeleton(root)
	var player: AnimationPlayer = _find_animation_player(root)
	_check("character contains a Skeleton3D", skeleton != null)
	if skeleton != null:
		_check("rig has the expected proof bones", skeleton.get_bone_count() == 18, "got %d" % skeleton.get_bone_count())
	_check("character contains an AnimationPlayer", player != null)
	if player != null:
		var available: PackedStringArray = PackedStringArray()
		for animation_name: StringName in player.get_animation_list():
			available.append(String(animation_name))
		for required: String in REQUIRED_CLIPS:
			_check("animation imports: %s" % required, _has_clip(available, required), str(available))
	root.free()


func _has_clip(available: PackedStringArray, required: String) -> bool:
	for animation_name: String in available:
		var normalized: String = animation_name.to_lower()
		if normalized == required or normalized.ends_with("/" + required) or normalized.ends_with("|" + required):
			return true
	return false


func _count_nodes_of_type(node: Node, type_name: String) -> int:
	var count: int = 1 if node.is_class(type_name) else 0
	for child: Node in node.get_children():
		count += _count_nodes_of_type(child, type_name)
	return count


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child: Node in node.get_children():
		var result: Skeleton3D = _find_skeleton(child)
		if result != null:
			return result
	return null


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child: Node in node.get_children():
		var result: AnimationPlayer = _find_animation_player(child)
		if result != null:
			return result
	return null
