extends Node3D

const INCIDENT_DATA_PATH := "res://scenes/playable_bay.json"
const WALKWAY_ID: StringName = &"walkway"
const BEAM_ID: StringName = &"beam"

var _data: Dictionary = {}
var _structure: Structure
var _incident: Incident
var _kess: Unit
var _maren: Unit

var _camera_rig: OrbitCameraRig
var _bay_view: BayView
var _hud: IncidentHud

var _selected_unit_id: StringName = &"kess"
var _selected_member_id: StringName = WALKWAY_ID
var _hovered_member_id: StringName = &""
var _prop_placed: bool = false
var _resolved: bool = false
var _core_log_count: int = 0
var _timeline: Array[String] = []


func _ready() -> void:
	_data = _load_incident_data()
	if _data.is_empty():
		push_error("Could not load %s" % INCIDENT_DATA_PATH)
		return
	get_window().content_scale_size = Vector2i(1440, 810)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().size = Vector2i(1280, 720)

	_camera_rig = OrbitCameraRig.new()
	_camera_rig.name = "OrbitCameraRig"
	add_child(_camera_rig)

	_bay_view = BayView.new()
	_bay_view.name = "BayView"
	add_child(_bay_view)
	_bay_view.build(_data["members"], _camera_rig.camera())
	_bay_view.member_clicked.connect(_on_member_clicked)
	_bay_view.member_hovered.connect(_on_member_hovered)

	_hud = IncidentHud.new()
	_hud.name = "IncidentHud"
	add_child(_hud)
	_hud.build(tr(str(_data["prototype_notice"])), tr(str(_data["title"])))
	_hud.unit_selected.connect(_on_unit_selected)
	_hud.brace_requested.connect(_on_brace_requested)
	_hud.prop_requested.connect(_on_prop_requested)
	_hud.end_turn_requested.connect(_on_end_turn_requested)
	_hud.restart_requested.connect(_restart_demo)

	_restart_demo()


func _load_incident_data() -> Dictionary:
	var file := FileAccess.open(INCIDENT_DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _restart_demo() -> void:
	_structure = _build_structure()
	_incident = Incident.new(_structure)

	var kinetic_data: Dictionary = _data["units"]["kinetic"]
	var kinetic := Etherbound.new(Affinity.Kind.KINETIC)
	kinetic.reserve_max = float(kinetic_data["reserve"])
	kinetic.reserve = kinetic.reserve_max
	kinetic.throughput_max = float(kinetic_data["throughput"])
	_kess = Unit.new(str(kinetic_data["name"]), kinetic)

	var worker_data: Dictionary = _data["units"]["worker"]
	_maren = Unit.new(str(worker_data["name"]))
	_maren.directable = true
	_incident.add_unit(_kess)
	_incident.add_unit(_maren)

	_selected_unit_id = &"kess"
	_selected_member_id = WALKWAY_ID
	_hovered_member_id = &""
	_prop_placed = false
	_resolved = false
	_core_log_count = 0
	_timeline = [tr("Round 1: The corroded bracket is already over capacity.")]
	_bay_view.reset_view()
	_bay_view.set_selected(_selected_member_id)
	_hud.clear_outcome()
	_hud.set_feedback(tr("Start with Kess: inspect the anchor path, then brace the walkway."))
	_refresh_all()


func _build_structure() -> Structure:
	var structure := Structure.new()
	for raw_member: Variant in _data["members"]:
		var spec: Dictionary = raw_member
		structure.add_member(
			StringName(str(spec["id"])),
			tr(str(spec["label"])),
			float(spec["mass"]),
			float(spec["capacity"]),
			bool(spec["grounded"])
		)
	for raw_connection: Variant in _data["connections"]:
		var spec: Dictionary = raw_connection
		structure.connect_members(
			StringName(str(spec["from"])),
			StringName(str(spec["to"])),
			float(spec["capacity"]),
			tr(str(spec["kind"]))
		)
	structure.solve()
	return structure


func _on_member_clicked(member_id: StringName) -> void:
	if member_id == &"":
		return
	_selected_member_id = member_id
	_bay_view.set_selected(member_id)
	_hud.set_feedback(tr("Selected %s.") % tr(_structure.member(member_id).label))
	_refresh_all()


func _on_member_hovered(member_id: StringName) -> void:
	_hovered_member_id = member_id
	_refresh_anchor_preview()


func _on_unit_selected(unit_id: StringName) -> void:
	_selected_unit_id = unit_id
	if unit_id == &"kess":
		_hud.set_feedback(tr("Hover any structural member to preview Kess's real anchor report."))
	else:
		_hud.set_feedback(tr("Maren spends no reserve. Select the walkway and place a physical prop."))
	_refresh_all()


func _on_brace_requested() -> void:
	if _selected_member_id != WALKWAY_ID:
		_hud.set_feedback(tr("Select the walkway before committing the brace."), true)
		return
	if not _kess.etherbound.commitments().is_empty():
		_hud.set_feedback(tr("Kess is already holding the walkway."), true)
		return
	var accepted: bool = _incident.brace(
		_kess,
		WALKWAY_ID,
		float(_data["brace_relief"]),
		float(_data["brace_demand"])
	)
	if not accepted:
		_hud.set_feedback(tr(_incident.last_refusal()), true)
		return
	_bay_view.set_brace_visible(true)
	_sync_core_log()
	_hud.set_feedback(tr("The bracket is stable for now. End Turn to spend one round of reserve."))
	_refresh_all()


func _on_prop_requested() -> void:
	if _selected_member_id != WALKWAY_ID:
		_hud.set_feedback(tr("Select the walkway before placing the prop."), true)
		return
	if _prop_placed:
		_hud.set_feedback(tr("Maren's prop is already carrying the walkway."), true)
		return
	var accepted: bool = _incident.prop(_maren, WALKWAY_ID, float(_data["prop_support"]))
	if not accepted:
		_hud.set_feedback(tr(_incident.last_refusal()), true)
		return
	_prop_placed = true
	_bay_view.set_prop_visible(true)
	_sync_core_log()
	_hud.set_feedback(tr("The physical prop will keep carrying load after Kess runs dry."))
	_refresh_all()


func _on_end_turn_requested() -> void:
	if _resolved:
		return
	var ended_round: int = _incident.round_number
	var events: Array[String] = _incident.end_round()
	_sync_core_log()
	if events.is_empty():
		_timeline.append(tr("Round %d: Time passes. The structure holds.") % ended_round)

	var hold_failed: bool = false
	var gave_way: bool = false
	for event_line: String in events:
		if event_line.contains("Reserve gone"):
			hold_failed = true
		if event_line.contains("gives way"):
			gave_way = true

	if hold_failed:
		_bay_view.set_brace_visible(false)
	if gave_way:
		_resolved = true
		_bay_view.start_collapse()
		_hud.set_feedback(tr("The bracket gives way. Restart and have Maren place the prop before the third turn."), true)
		_hud.show_outcome(
			tr("THE WALKWAY FALLS"),
			tr("Kess's reserve reached zero, the brace vanished, and the overloaded connection failed. Restart to test the worker solution."),
			false
		)
	elif hold_failed and _prop_placed:
		_resolved = true
		_timeline.append(tr("Round %d: Maren's prop carries the load. Nothing falls.") % ended_round)
		_hud.set_feedback(tr("The Etherbound hold is gone, but ordinary work keeps the structure standing."))
		_hud.show_outcome(
			tr("RESCUE LOOP PROVEN"),
			tr("Kess lost the hold exactly as projected. Maren's prop remained, so the walkway stayed up without spending reserve."),
			true
		)
	else:
		_hud.set_feedback(tr("One round elapsed. Watch Kess's reserve and the full-round countdown."))
	_refresh_all()


func _sync_core_log() -> void:
	var core_lines: Array[String] = _incident.log_lines()
	while _core_log_count < core_lines.size():
		_timeline.append(tr(core_lines[_core_log_count]))
		_core_log_count += 1


func _refresh_all() -> void:
	var bracket: Structure.Connection = _structure.connection_between(WALKWAY_ID, BEAM_ID)
	var bracket_utilisation: float = bracket.utilisation()
	var overloaded: bool = bracket_utilisation > 1.0
	_bay_view.set_overload(overloaded, bracket_utilisation)
	_hud.set_structure_status(overloaded, bracket_utilisation)

	var rounds_left: int = _incident.rounds_sustainable(_kess)
	_hud.set_round_status(
		_incident.round_number,
		_kess.etherbound.reserve,
		_kess.etherbound.reserve_max,
		rounds_left
	)
	_hud.set_unit_status(
		_selected_unit_id,
		_kess.status_line(),
		tr("%s (ordinary, directable) — no reserve cost") % _maren.display_name
	)
	_refresh_member_details()
	_refresh_anchor_preview()
	_hud.set_actions(
		not _resolved and _selected_unit_id == &"kess" and _selected_member_id == WALKWAY_ID and _kess.etherbound.commitments().is_empty(),
		not _resolved and _selected_unit_id == &"maren" and _selected_member_id == WALKWAY_ID and not _prop_placed,
		not _resolved
	)
	_hud.set_event_log(_timeline)


func _refresh_member_details() -> void:
	var member: Structure.Member = _structure.member(_selected_member_id)
	if member == null:
		return
	var connection_line: String = tr("This member has no carrying connection below it.")
	var supports: Array[StringName] = _structure.supports_of(_selected_member_id)
	if not supports.is_empty():
		var connection: Structure.Connection = _structure.connection_between(_selected_member_id, supports[0])
		connection_line = tr("%s connection: load %.0f / capacity %.0f (%d%%)") % [
			connection.kind.capitalize(),
			connection.load,
			connection.capacity,
			int(round(connection.utilisation() * 100.0)),
		]
	_hud.set_member_details(
		member.label,
		member.load,
		member.capacity,
		member.utilisation(),
		connection_line
	)


func _refresh_anchor_preview() -> void:
	if _selected_unit_id != &"kess":
		_hud.set_anchor_preview(
			tr("Maren does not make an Etherbound anchor test. A physical prop costs no reserve and remains after Kess loses the hold."),
			true,
			false
		)
		return
	var preview_id: StringName = _hovered_member_id if _hovered_member_id != &"" else _selected_member_id
	var report: Dictionary = _structure.anchor_report(preview_id, float(_data["anchor_reaction"]))
	_hud.set_anchor_preview(tr(str(report.get("reason", ""))), bool(report.get("holds", false)))
