class_name VerticalSlice
extends Node3D

const DATA_PATH: String = "res://data/vertical_slice.json"
const WALKWAY_ID: StringName = &"walkway"
const BEAM_ID: StringName = &"beam"

var _data: Dictionary = {}
var _state := SliceState.new()
var _environment: SliceEnvironment
var _party: SlicePartyController
var _camera_rig: SliceCameraRig
var _hud: VerticalSliceHud
var _audio: SliceAudio

var _structure: Structure
var _incident: Incident
var _units: Dictionary = {}
var _dialogue_index: int = 0
var _current_item: Dictionary = {}
var _pending_incident: bool = false
var _interaction_locked: bool = true
var _elapsed: float = 0.0
var _performance_elapsed: float = 0.0
var _capture_phase: String = ""
var _capture_elapsed: float = 0.0


func _ready() -> void:
	_data = _load_data()
	if _data.is_empty():
		push_error("Could not load vertical-slice data: %s" % DATA_PATH)
		return
	get_window().content_scale_size = Vector2i(1440, 810)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1280, 720)

	_environment = SliceEnvironment.new()
	_environment.name = "SliceEnvironment"
	add_child(_environment)
	_environment.build()

	_party = SlicePartyController.new()
	_party.name = "PartyController"
	add_child(_party)
	_party.build()

	_camera_rig = SliceCameraRig.new()
	_camera_rig.name = "SliceCameraRig"
	add_child(_camera_rig)
	_camera_rig.build()
	_camera_rig.set_follow(_party.character(&"kinetic"), false)

	_audio = SliceAudio.new()
	_audio.name = "SliceAudio"
	add_child(_audio)
	_audio.build()

	_hud = VerticalSliceHud.new()
	_hud.name = "VerticalSliceHud"
	add_child(_hud)
	_hud.build(tr(str(_data["title"])), tr(str(_data["prototype_notice"])))
	_hud.dialogue_advanced.connect(_on_dialogue_advanced)
	_hud.inspection_closed.connect(_on_inspection_closed)
	_hud.incident_action_requested.connect(_on_incident_action)
	_hud.incident_round_requested.connect(_on_incident_round)
	_hud.incident_restart_requested.connect(_restart_incident)
	_hud.report_requested.connect(_on_report_requested)
	_hud.slice_restart_requested.connect(_restart_slice)

	_capture_phase = _requested_capture_phase()
	if _capture_phase.is_empty():
		_start_arrival()
	else:
		_stage_capture(_capture_phase)


func _process(delta: float) -> void:
	_elapsed += delta
	_performance_elapsed += delta
	if _performance_elapsed >= 0.5 and _hud != null:
		_performance_elapsed = 0.0
		_hud.set_performance(Engine.get_frames_per_second(), int(Performance.get_monitor(Performance.OBJECT_COUNT)), _elapsed)
	if _capture_phase.is_empty():
		_update_interaction_prompt()
	else:
		_capture_elapsed += delta
		if _capture_elapsed >= 2.2:
			_capture_review(_capture_phase)
			_capture_phase = ""
			get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		match key_event.keycode:
			KEY_E:
				_interact()
			KEY_F5:
				_save_checkpoint()
			KEY_F9:
				_load_checkpoint()
			KEY_F12:
				_capture_review("manual")
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT and _party.movement_enabled:
			var hit: Variant = _ground_hit(mouse_event.position)
			if hit is Vector3:
				_party.set_move_target(hit)


func _start_arrival() -> void:
	_state = SliceState.new()
	_dialogue_index = 0
	_interaction_locked = true
	_party.movement_enabled = false
	_hud.set_phase("Arrival", _objective("arrival"))
	_hud.set_prompt("", false)
	_hud.show_incident(false)
	_hud.show_report(false)
	_camera_rig.frame(Vector3(-12.0, 1.6, 0.0), 13.8, -1.10, -0.34, 0.01)
	_show_arrival_line()


func _show_arrival_line() -> void:
	var lines: Array = _data["arrival"]
	if _dialogue_index >= lines.size():
		_hud.hide_dialogue()
		_start_exploration()
		return
	var line: Dictionary = lines[_dialogue_index]
	_hud.show_dialogue(str(line["speaker"]), str(line["line"]), _dialogue_index == lines.size() - 1)
	match _dialogue_index:
		0:
			_camera_rig.frame(Vector3(-10.8, 1.25, 0.75), 7.8, -1.25, -0.30, 0.7)
		1:
			_camera_rig.frame(Vector3(-15.5, 1.25, 0.0), 6.5, -1.05, -0.28, 0.7)
		_:
			_camera_rig.frame(Vector3(-16.4, 1.20, -0.55), 6.8, -0.80, -0.30, 0.7)


func _on_dialogue_advanced() -> void:
	_audio.play_ui()
	_dialogue_index += 1
	_show_arrival_line()


func _start_exploration() -> void:
	if _state.phase == SliceState.Phase.ARRIVAL:
		_state.begin_exploration()
	_interaction_locked = false
	_party.movement_enabled = true
	_camera_rig.set_follow(_party.character(&"kinetic"), true)
	_camera_rig.restore_exploration_control()
	_environment.show_interaction_markers(_data["interactions"], true)
	_hud.set_phase("Exploration", _objective("exploration"))
	_hud.set_prompt(tr("WASD or left-click to move. Approach a marked object and press E."))
	_auto_checkpoint()


func _interact() -> void:
	if _interaction_locked or _current_item.is_empty():
		return
	_audio.play_ui()
	_interaction_locked = true
	_party.movement_enabled = false
	var id := StringName(str(_current_item["id"]))
	if _state.phase == SliceState.Phase.EXPLORATION:
		_state.mark_inspected(id)
		_pending_incident = str(_current_item.get("kind", "")) == "incident_trigger"
	elif _state.phase == SliceState.Phase.INVESTIGATION:
		if not _state.collect_evidence(id):
			_hud.toast(_state.last_reason, true)
			_interaction_locked = false
			_party.movement_enabled = true
			return
		_hud.update_evidence_count(_state.evidence.size())
	_hud.show_inspection(
		str(_current_item["title"]),
		str(_current_item["observation"]),
		str(_current_item["inference"])
	)


func _on_inspection_closed() -> void:
	_audio.play_ui()
	_hud.hide_inspection()
	if _pending_incident:
		_pending_incident = false
		_start_incident()
		return
	_interaction_locked = false
	_party.movement_enabled = true
	if _state.phase == SliceState.Phase.INVESTIGATION and _state.evidence_complete():
		_environment.set_markers_visible(false)
		_party.movement_enabled = false
		_interaction_locked = true
		_hud.show_report(true, _state.evidence.size())
		_camera_rig.frame(Vector3(11.4, 1.35, 0.0), 8.2, -1.08, -0.34, 0.75)


func _start_incident() -> void:
	if _state.phase == SliceState.Phase.EXPLORATION:
		_state.start_incident()
	_build_core_incident()
	_interaction_locked = true
	_party.stage_for_incident()
	_environment.set_markers_visible(false)
	_environment.reset_incident_effects()
	_camera_rig.frame(Vector3(3.1, 2.40, 0.0), 11.2, -1.05, -0.33, 0.8)
	_hud.set_phase("Turn-based incident", _objective("incident"))
	_hud.set_prompt("", false)
	_hud.show_incident(true)
	_hud.set_incident_status(_state.incident_round, _state.incident_actions, "The corroded connection is overloaded. Preview each physical role before ending the round.")
	_audio.play_impact()
	_auto_checkpoint()


func _on_incident_action(role: StringName) -> void:
	if not _state.perform_incident_action(role):
		_hud.toast(_state.last_reason, true)
		return
	var accepted: bool = _apply_core_action(role)
	if not accepted:
		_state.incident_actions.erase(role)
		_hud.toast(_state.last_reason, true)
		return
	_environment.show_action_effect(role)
	_audio.play_ether() if role != &"worker" else _audio.play_ui()
	match role:
		&"kinetic":
			_party.play_role_action(role, "brace")
		&"gravitic":
			_party.play_role_action(role, "operate")
		&"transmutative":
			_party.play_role_action(role, "kneel")
		&"worker":
			_party.play_role_action(role, "operate")
	var report: Dictionary = _structure.anchor_report(WALKWAY_ID, 0.0)
	var reason: String = "%s complete. %s" % [String(role).capitalize(), str(report.get("reason", "The load path has changed."))]
	_hud.set_incident_status(_state.incident_round, _state.incident_actions, reason)


func _apply_core_action(role: StringName) -> bool:
	var model: Dictionary = _data["incident_model"]
	var unit: Unit = _units.get(role)
	match role:
		&"kinetic":
			var accepted: bool = _incident.brace(unit, WALKWAY_ID, float(model["brace_relief"]), 10.0)
			if not accepted:
				_state.last_reason = _incident.last_refusal()
			return accepted
		&"gravitic":
			var commitment := Commitment.new(&"gravitic_relief", "Gravitic reducing acceleration over the walkway load", 5.0)
			if not unit.etherbound.commit(commitment):
				_state.last_reason = unit.etherbound.last_refusal()
				return false
			_structure.set_gravity_factor([WALKWAY_ID, &"crate"], float(model["gravitic_factor"]))
			return true
		&"transmutative":
			var commitment := Commitment.new(&"transmutative_front", "Transmutative maintaining a contiguous repair front", 6.0)
			if not unit.etherbound.commit(commitment):
				_state.last_reason = unit.etherbound.last_refusal()
				return false
			return _structure.reinforce(WALKWAY_ID, BEAM_ID, float(model["repair_capacity"]))
		&"worker":
			var accepted: bool = _incident.prop(unit, WALKWAY_ID, float(model["prop_support"]))
			if not accepted:
				_state.last_reason = _incident.last_refusal()
			return accepted
	_state.last_reason = "No physical action is defined for that role."
	return false


func _on_incident_round() -> void:
	_audio.play_ui()
	var core_events: Array[String] = _incident.end_round()
	var result: Dictionary = _state.end_incident_round()
	var reason: String = str(result.get("reason", ""))
	if not core_events.is_empty():
		reason += " " + " ".join(core_events)
	if bool(result.get("failed", false)):
		_environment.play_collapse()
		_audio.play_impact()
		for role: StringName in [&"kinetic", &"gravitic", &"transmutative", &"worker"]:
			_party.play_role_action(role, "stagger")
		_hud.set_incident_status(_state.incident_round, _state.incident_actions, reason, true)
		return
	if bool(result.get("resolved", false)):
		_hud.show_incident(false)
		_start_investigation()
		return
	_hud.set_incident_status(_state.incident_round, _state.incident_actions, reason)


func _restart_incident() -> void:
	_audio.play_ui()
	_state.restart_incident()
	_build_core_incident()
	_environment.reset_incident_effects()
	_party.stage_for_incident()
	_hud.set_incident_status(_state.incident_round, _state.incident_actions, "The incident is reset. Four roles, four physical jobs, three rounds.")


func _start_investigation() -> void:
	_interaction_locked = false
	_party.stage_for_investigation()
	_camera_rig.set_follow(_party.character(&"kinetic"), true)
	_camera_rig.restore_exploration_control()
	_environment.show_interaction_markers(_data["evidence"], true)
	_hud.set_phase("Investigation", _objective("investigation"))
	_hud.set_prompt(tr("Move through the consequence area. Press E at each of the three evidence markers."))
	_hud.show_report(false, _state.evidence.size())
	_auto_checkpoint()


func _on_report_requested(choice: StringName) -> void:
	_audio.play_ui()
	if not _state.choose_report(choice):
		_hud.toast(_state.last_reason, true)
		return
	_hud.show_report(false)
	_show_consequence()


func _show_consequence() -> void:
	_party.movement_enabled = false
	_interaction_locked = true
	_environment.set_markers_visible(false)
	_environment.set_consequence(_state.report_choice)
	_camera_rig.frame(Vector3(12.0, 1.35, 0.0), 9.2, -1.02, -0.30, 0.85)
	_hud.set_phase("Consequence", _objective("consequence"))
	_hud.set_prompt("", false)
	var consequence: Dictionary = _data["consequences"][String(_state.report_choice)]
	_hud.show_consequence(
		str(consequence["heading"]),
		str(consequence["worker_line"]),
		str(consequence["detail"]),
		_state.report_choice
	)
	_auto_checkpoint()


func _build_core_incident() -> void:
	var model: Dictionary = _data["incident_model"]
	_structure = Structure.new()
	for raw_member: Variant in model["members"]:
		var member: Dictionary = raw_member
		_structure.add_member(
			StringName(str(member["id"])), tr(str(member["label"])), float(member["mass"]),
			float(member["capacity"]), bool(member["grounded"])
		)
	for raw_connection: Variant in model["connections"]:
		var connection: Dictionary = raw_connection
		var capacity: float = float(connection.get("incident_capacity", connection["capacity"]))
		_structure.connect_members(
			StringName(str(connection["from"])), StringName(str(connection["to"])),
			capacity, tr(str(connection["kind"]))
		)
	_structure.solve()
	_incident = Incident.new(_structure)
	_units.clear()
	_units[&"kinetic"] = _make_etherbound_unit("Kinetic [Prototype]", Affinity.Kind.KINETIC, 150.0, 10.0)
	_units[&"gravitic"] = _make_etherbound_unit("Gravitic [Prototype]", Affinity.Kind.GRAVITIC, 120.0, 9.0)
	_units[&"transmutative"] = _make_etherbound_unit("Transmutative [Prototype]", Affinity.Kind.TRANSMUTATIVE, 120.0, 9.0)
	var worker := Unit.new("Site Worker [Prototype]")
	worker.directable = true
	_units[&"worker"] = worker
	for role: StringName in [&"kinetic", &"gravitic", &"transmutative", &"worker"]:
		_incident.add_unit(_units[role])


func _make_etherbound_unit(label: String, affinity: Affinity.Kind, reserve: float, throughput: float) -> Unit:
	var etherbound := Etherbound.new(affinity)
	etherbound.reserve_max = reserve
	etherbound.reserve = reserve
	etherbound.throughput_max = throughput
	return Unit.new(label, etherbound)


func _update_interaction_prompt() -> void:
	if _interaction_locked or not _party.movement_enabled:
		return
	var items: Array = []
	if _state.phase == SliceState.Phase.EXPLORATION:
		items = _data["interactions"]
	elif _state.phase == SliceState.Phase.INVESTIGATION:
		items = _data["evidence"]
	else:
		_current_item = {}
		return
	var nearest: Dictionary = {}
	var nearest_distance: float = 2.15
	for raw_item: Variant in items:
		var item: Dictionary = raw_item
		var id := StringName(str(item["id"]))
		if _state.phase == SliceState.Phase.INVESTIGATION and _state.evidence.has(id):
			continue
		var distance: float = _party.leader_position().distance_to(_array_to_vector3(item["position"]) + Vector3(0.0, 0.22, 0.0))
		if distance < nearest_distance:
			nearest = item
			nearest_distance = distance
	_current_item = nearest
	if nearest.is_empty():
		_hud.set_prompt(tr("WASD / left-click move  •  Right-drag orbit  •  Wheel zoom"))
	else:
		_hud.set_prompt(tr("PRESS E — %s") % tr(str(nearest["title"])))


func _save_checkpoint() -> void:
	_state.player_position = _party.leader_position()
	if _state.save_checkpoint():
		_hud.toast(tr("Checkpoint saved."))
	else:
		_hud.toast(_state.last_reason, true)


func _auto_checkpoint() -> void:
	_state.player_position = _party.leader_position()
	_state.save_checkpoint()


func _load_checkpoint() -> void:
	var loaded := SliceState.new()
	if not loaded.load_checkpoint():
		_hud.toast(loaded.last_reason, true)
		return
	_state = loaded
	_hud.toast(tr("Checkpoint loaded."))
	_restore_phase()


func _restore_phase() -> void:
	_hud.hide_dialogue()
	_hud.hide_inspection()
	_hud.show_incident(false)
	_hud.show_report(false)
	match _state.phase:
		SliceState.Phase.ARRIVAL:
			_start_arrival()
		SliceState.Phase.EXPLORATION:
			_party.teleport_party(_state.player_position)
			_start_exploration()
		SliceState.Phase.INCIDENT:
			var actions: Dictionary = _state.incident_actions.duplicate()
			_state.incident_actions.clear()
			_start_incident()
			for raw_role: Variant in actions:
				_on_incident_action(StringName(str(raw_role)))
		SliceState.Phase.INVESTIGATION:
			_start_investigation()
		SliceState.Phase.CONSEQUENCE:
			_party.stage_for_investigation()
			_show_consequence()


func _restart_slice() -> void:
	get_tree().reload_current_scene()


func _ground_hit(screen_position: Vector2) -> Variant:
	var camera: Camera3D = _camera_rig.camera()
	var origin: Vector3 = camera.project_ray_origin(screen_position)
	var direction: Vector3 = camera.project_ray_normal(screen_position)
	return Plane(Vector3.UP, 0.22).intersects_ray(origin, direction)


func _objective(key: String) -> String:
	return tr(str(_data["objectives"][key]))


func _load_data() -> Dictionary:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _array_to_vector3(value: Variant) -> Vector3:
	var array: Array = value
	return Vector3(float(array[0]), float(array[1]), float(array[2]))


func _requested_capture_phase() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture="):
			return argument.trim_prefix("--capture=")
	return ""


func _stage_capture(phase_name: String) -> void:
	match phase_name:
		"environment":
			_state.begin_exploration()
			_party.teleport_party(Vector3(-5.8, 0.22, 0.0))
			_start_exploration()
			_camera_rig.frame(Vector3(-1.0, 1.4, 0.0), 30.0, 0.0, -0.38, 0.01)
		"exploration":
			_state.begin_exploration()
			_party.teleport_party(Vector3(-6.0, 0.22, 0.0))
			_start_exploration()
			_camera_rig.frame(Vector3(-5.2, 1.35, 0.0), 11.5, 0.0, -0.34, 0.01)
		"characters":
			_state.begin_exploration()
			_state.start_incident()
			_start_incident()
			_hud.show_incident(false)
			_party.stage_for_cast_review()
			_camera_rig.frame(Vector3(-5.75, 1.15, 2.0), 8.8, 0.0, -0.18, 0.01)
		"incident":
			_state.begin_exploration()
			_state.start_incident()
			_start_incident()
			for role: StringName in SliceState.REQUIRED_ACTIONS:
				_on_incident_action(role)
		"narrative":
			_state.phase = SliceState.Phase.INVESTIGATION
			_start_investigation()
			for id: StringName in SliceState.REQUIRED_EVIDENCE:
				_state.collect_evidence(id)
			_hud.show_report(true, 3)
		"polish":
			_state.phase = SliceState.Phase.INVESTIGATION
			for id: StringName in SliceState.REQUIRED_EVIDENCE:
				_state.collect_evidence(id)
			_state.choose_report(&"observations_only")
			_party.stage_for_investigation()
			_show_consequence()
		_:
			_start_arrival()


func _capture_review(phase_name: String) -> void:
	var directory: String = ProjectSettings.globalize_path("res://../art/review")
	DirAccess.make_dir_recursive_absolute(directory)
	var image: Image = get_viewport().get_texture().get_image()
	var path: String = directory.path_join("junction_%s.png" % phase_name)
	var error: Error = image.save_png(path)
	_hud.toast(tr("Capture saved: %s") % path if error == OK else tr("Capture failed."), error != OK)
