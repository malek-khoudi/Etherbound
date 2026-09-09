## Junctions 4–9 contract: assets, phase logic, physics data and checkpoint state.
## Run: ./tools/test.sh
extends SceneTree

const DATA_PATH: String = "res://data/vertical_slice.json"
const SCENE_PATH: String = "res://scenes/vertical_slice/vertical_slice.tscn"
const ENVIRONMENT_PATH: String = "res://assets/models/environment/slice_environment.glb"
const ROLE_PATHS: Dictionary = {
	&"kinetic": "res://assets/models/characters/slice_kinetic.glb",
	&"gravitic": "res://assets/models/characters/slice_gravitic.glb",
	&"transmutative": "res://assets/models/characters/slice_transmutative.glb",
	&"worker": "res://assets/models/characters/slice_worker.glb",
}
const REQUIRED_CLIPS: Array[String] = ["idle", "walk", "inspect", "brace", "point", "operate", "kneel", "stagger"]

var _failures: int = 0


func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("  PASS  ", label)
	else:
		_failures += 1
		print("  FAIL  ", label, "  ", detail)


func _initialize() -> void:
	print("\n=== Junctions 4–9 vertical slice ===\n")
	_test_data_and_scene()
	_test_environment()
	_test_characters()
	_test_slice_state()
	_test_structural_contract()
	print("\n=== %s ===\n" % ("ALL PASS" if _failures == 0 else "%d FAILURE(S)" % _failures))
	quit(1 if _failures > 0 else 0)


func _test_data_and_scene() -> void:
	var data: Dictionary = _load_data()
	_check("authored vertical-slice data loads", not data.is_empty())
	_check("exactly three post-incident clues", (data.get("evidence", []) as Array).size() == 3)
	_check("two reporting choices", (data.get("report_choices", []) as Array).size() == 2)
	var scene: PackedScene = load(SCENE_PATH) as PackedScene
	_check("vertical-slice scene parses", scene != null, SCENE_PATH)
	if scene != null:
		var instance: Node = scene.instantiate()
		_check("vertical-slice root script is valid", instance.get_script() != null)
		instance.free()
	_check("vertical slice is the main scene", str(ProjectSettings.get_setting("application/run/main_scene")) == SCENE_PATH)


func _test_environment() -> void:
	var scene: PackedScene = load(ENVIRONMENT_PATH) as PackedScene
	_check("final slice environment imports", scene != null, ENVIRONMENT_PATH)
	if scene == null:
		return
	var instance: Node = scene.instantiate()
	var mesh_count: int = _count_type(instance, "MeshInstance3D")
	_check("environment is expanded beyond the proof", mesh_count >= 100, "got %d meshes" % mesh_count)
	for zone_name: String in ["Approach", "Control", "Gantry", "Consequence"]:
		_check("environment names the %s zone" % zone_name, _tree_contains(instance, zone_name), "missing prefix")
	instance.free()


func _test_characters() -> void:
	for role: StringName in ROLE_PATHS:
		var path: String = str(ROLE_PATHS[role])
		var scene: PackedScene = load(path) as PackedScene
		_check("%s character imports" % role, scene != null, path)
		if scene == null:
			continue
		var instance: Node = scene.instantiate()
		var skeleton: Skeleton3D = _find_skeleton(instance)
		var player: AnimationPlayer = _find_animation_player(instance)
		_check("%s uses the shared 18-bone rig" % role, skeleton != null and skeleton.get_bone_count() == 18)
		_check("%s has an AnimationPlayer" % role, player != null)
		if player != null:
			var available: PackedStringArray = player.get_animation_list()
			for clip: String in REQUIRED_CLIPS:
				_check("%s animation: %s" % [role, clip], _has_clip(available, clip), str(available))
		instance.free()


func _test_slice_state() -> void:
	var state := SliceState.new()
	_check("slice begins at arrival", state.phase == SliceState.Phase.ARRIVAL)
	state.begin_exploration()
	_check("arrival advances to exploration", state.phase == SliceState.Phase.EXPLORATION)
	_check("inspection records", state.mark_inspected(&"signal_set"))
	_check("incident starts from exploration", state.start_incident())
	_check("incident refuses unknown roles", not state.perform_incident_action(&"thermic"), state.last_reason)
	for role: StringName in SliceState.REQUIRED_ACTIONS:
		_check("incident accepts %s" % role, state.perform_incident_action(role), state.last_reason)
	_check("four roles complete the incident", state.incident_actions_complete())
	var result: Dictionary = state.end_incident_round()
	_check("complete incident advances", bool(result.get("resolved", false)))
	_check("phase becomes investigation", state.phase == SliceState.Phase.INVESTIGATION)
	_check("report is gated before evidence", not state.choose_report(&"observations_only"), state.last_reason)
	for id: StringName in SliceState.REQUIRED_EVIDENCE:
		_check("records evidence %s" % id, state.collect_evidence(id), state.last_reason)
	_check("exact three-clue set completes", state.evidence_complete())
	_check("observation-first report accepted", state.choose_report(&"observations_only"), state.last_reason)
	_check("report advances to consequence", state.phase == SliceState.Phase.CONSEQUENCE)

	state.player_position = Vector3(4.0, 0.22, -1.0)
	var snapshot: Dictionary = state.to_dictionary()
	var restored := SliceState.new()
	_check("checkpoint dictionary restores", restored.from_dictionary(snapshot), restored.last_reason)
	_check("checkpoint preserves phase", restored.phase == SliceState.Phase.CONSEQUENCE)
	_check("checkpoint preserves report", restored.report_choice == &"observations_only")
	_check("checkpoint preserves position", restored.player_position.is_equal_approx(state.player_position))
	var save_path: String = "user://etherbound_vertical_slice_test_checkpoint.json"
	_check("checkpoint writes to disk", state.save_checkpoint(save_path), state.last_reason)
	var disk_restored := SliceState.new()
	_check("checkpoint loads from disk", disk_restored.load_checkpoint(save_path), disk_restored.last_reason)
	_check("disk checkpoint preserves evidence", disk_restored.evidence_complete())
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	var failure_state := SliceState.new()
	failure_state.begin_exploration()
	failure_state.start_incident()
	var failure: Dictionary = failure_state.end_incident_round()
	_check("unsupported walkway can still fail", bool(failure.get("failed", false)))
	_check("failure reason is readable", not str(failure.get("reason", "")).is_empty())


func _test_structural_contract() -> void:
	var data: Dictionary = _load_data()
	var model: Dictionary = data["incident_model"]
	var structure := Structure.new()
	for raw_member: Variant in model["members"]:
		var member: Dictionary = raw_member
		structure.add_member(StringName(str(member["id"])), str(member["label"]), float(member["mass"]), float(member["capacity"]), bool(member["grounded"]))
	for raw_connection: Variant in model["connections"]:
		var connection: Dictionary = raw_connection
		structure.connect_members(StringName(str(connection["from"])), StringName(str(connection["to"])), float(connection["capacity"]), str(connection["kind"]))
	structure.solve()
	var report: Dictionary = structure.anchor_report(&"walkway", float(model["anchor_reaction"]))
	_check("pre-incident bracket is 89%", int(round(float(report["failing_utilisation_before"]) * 100.0)) == 89, str(report))
	_check("added reaction makes it 111%", int(round(float(report["failing_utilisation_after"]) * 100.0)) == 111, str(report))
	_check("anchor preview explains failure", not bool(report["holds"]) and str(report["reason"]).contains("before"), str(report))


func _load_data() -> Dictionary:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _has_clip(available: PackedStringArray, required: String) -> bool:
	for animation_name: String in available:
		var normalized: String = animation_name.to_lower()
		if normalized == required or normalized.ends_with("/" + required) or normalized.ends_with("|" + required):
			return true
	return false


func _count_type(node: Node, type_name: String) -> int:
	var count: int = 1 if node.is_class(type_name) else 0
	for child: Node in node.get_children():
		count += _count_type(child, type_name)
	return count


func _tree_contains(node: Node, fragment: String) -> bool:
	if String(node.name).contains(fragment):
		return true
	for child: Node in node.get_children():
		if _tree_contains(child, fragment):
			return true
	return false


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
