class_name SliceState
extends RefCounted

enum Phase {
	ARRIVAL,
	EXPLORATION,
	INCIDENT,
	INVESTIGATION,
	CONSEQUENCE,
}

const SAVE_PATH: String = "user://etherbound_slice_checkpoint.json"
const REQUIRED_ACTIONS: Array[StringName] = [&"kinetic", &"gravitic", &"transmutative", &"worker"]
const REQUIRED_EVIDENCE: Array[StringName] = [&"fracture_surface", &"control_record", &"prop_imprint"]

var phase: Phase = Phase.ARRIVAL
var inspections: Dictionary = {}
var incident_actions: Dictionary = {}
var evidence: Dictionary = {}
var incident_round: int = 1
var incident_failed: bool = false
var report_choice: StringName = &""
var last_reason: String = ""
var player_position: Vector3 = Vector3(-16.0, 0.22, 0.0)


func begin_exploration() -> void:
	phase = Phase.EXPLORATION
	last_reason = ""


func mark_inspected(id: StringName) -> bool:
	if phase != Phase.EXPLORATION:
		last_reason = "Inspection is unavailable outside exploration."
		return false
	inspections[id] = true
	last_reason = ""
	return true


func start_incident() -> bool:
	if phase != Phase.EXPLORATION:
		last_reason = "The incident cannot start from the current phase."
		return false
	phase = Phase.INCIDENT
	incident_round = 1
	incident_actions.clear()
	incident_failed = false
	last_reason = ""
	return true


func perform_incident_action(role: StringName) -> bool:
	if phase != Phase.INCIDENT:
		last_reason = "Field actions are available only during the incident."
		return false
	if not REQUIRED_ACTIONS.has(role):
		last_reason = "That role has no action in this incident."
		return false
	if incident_actions.has(role):
		last_reason = "%s has already completed their field action." % role.capitalize()
		return false
	incident_actions[role] = true
	last_reason = ""
	return true


func incident_actions_complete() -> bool:
	for role: StringName in REQUIRED_ACTIONS:
		if not incident_actions.has(role):
			return false
	return true


func end_incident_round() -> Dictionary:
	if phase != Phase.INCIDENT:
		last_reason = "There is no active incident round."
		return {"advanced": false, "failed": false, "reason": last_reason}
	if incident_actions_complete():
		phase = Phase.INVESTIGATION
		last_reason = "All four roles completed the stabilisation."
		return {"advanced": true, "failed": false, "resolved": true, "reason": last_reason}
	var kinetic_holding: bool = incident_actions.has(&"kinetic")
	var enduring_support: bool = incident_actions.has(&"worker") or incident_actions.has(&"transmutative")
	if not kinetic_holding and not enduring_support:
		incident_failed = true
		last_reason = "No maintained hold or enduring support carried the walkway."
		return {"advanced": false, "failed": true, "resolved": false, "reason": last_reason}
	incident_round += 1
	if incident_round > 3:
		incident_failed = true
		last_reason = "The third round ended before all four roles secured the load path."
		return {"advanced": false, "failed": true, "resolved": false, "reason": last_reason}
	last_reason = "The structure holds for another round, but the solution is incomplete."
	return {"advanced": true, "failed": false, "resolved": false, "reason": last_reason}


func restart_incident() -> void:
	phase = Phase.INCIDENT
	incident_round = 1
	incident_actions.clear()
	incident_failed = false
	last_reason = ""


func collect_evidence(id: StringName) -> bool:
	if phase != Phase.INVESTIGATION:
		last_reason = "Evidence can be recorded only after the incident."
		return false
	if not REQUIRED_EVIDENCE.has(id):
		last_reason = "That object is not part of the three-item evidence set."
		return false
	evidence[id] = true
	last_reason = ""
	return true


func evidence_complete() -> bool:
	for id: StringName in REQUIRED_EVIDENCE:
		if not evidence.has(id):
			return false
	return true


func choose_report(choice: StringName) -> bool:
	if phase != Phase.INVESTIGATION:
		last_reason = "A report can be filed only during the investigation."
		return false
	if not evidence_complete():
		last_reason = "Examine all three evidence objects before filing the report."
		return false
	if choice != &"observations_only" and choice != &"claim_cause":
		last_reason = "That reporting choice does not exist."
		return false
	report_choice = choice
	phase = Phase.CONSEQUENCE
	last_reason = ""
	return true


func to_dictionary() -> Dictionary:
	return {
		"schema_version": 1,
		"phase": int(phase),
		"inspections": inspections.duplicate(true),
		"incident_actions": incident_actions.duplicate(true),
		"evidence": evidence.duplicate(true),
		"incident_round": incident_round,
		"incident_failed": incident_failed,
		"report_choice": String(report_choice),
		"player_position": [player_position.x, player_position.y, player_position.z],
	}


func from_dictionary(data: Dictionary) -> bool:
	if int(data.get("schema_version", 0)) != 1:
		last_reason = "Checkpoint version is unsupported."
		return false
	var raw_phase: int = int(data.get("phase", -1))
	if raw_phase < int(Phase.ARRIVAL) or raw_phase > int(Phase.CONSEQUENCE):
		last_reason = "Checkpoint phase is invalid."
		return false
	phase = raw_phase
	inspections = _string_key_dictionary(data.get("inspections", {}))
	incident_actions = _string_key_dictionary(data.get("incident_actions", {}))
	evidence = _string_key_dictionary(data.get("evidence", {}))
	incident_round = maxi(int(data.get("incident_round", 1)), 1)
	incident_failed = bool(data.get("incident_failed", false))
	report_choice = StringName(str(data.get("report_choice", "")))
	var position_data: Variant = data.get("player_position", [-16.0, 0.22, 0.0])
	if position_data is Array and position_data.size() >= 3:
		player_position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))
	last_reason = ""
	return true


func save_checkpoint(path: String = SAVE_PATH) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_reason = "Checkpoint could not be written."
		return false
	file.store_string(JSON.stringify(to_dictionary(), "\t") + "\n")
	last_reason = ""
	return true


func load_checkpoint(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		last_reason = "No checkpoint exists yet."
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_reason = "Checkpoint could not be read."
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		last_reason = "Checkpoint data is not valid JSON."
		return false
	return from_dictionary(parsed)


func _string_key_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if value is Dictionary:
		for raw_key: Variant in value:
			result[StringName(str(raw_key))] = bool(value[raw_key])
	return result
