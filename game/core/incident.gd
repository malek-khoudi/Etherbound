## Incident mode: the turn-based emergency layer.
##
## This is where the two systems meet. An Etherbound braces a failing structure,
## which relieves load and keeps it standing. Holding costs reserve every round.
## The player therefore has a countdown, and the question the whole slice turns
## on is what they spend it doing.
##
## Adaptation, not canon (see docs/ADAPTATION.md):
##   - Rounds. Harth has no rounds.
##   - SECONDS_PER_ROUND, which converts a per-second drain into a per-round one.
##   - Fixed turn order. No initiative roll.
class_name Incident
extends RefCounted

## How much world time one round represents. Chosen so a full-throughput
## commitment is survivable for a handful of rounds, not one and not thirty.
const SECONDS_PER_ROUND: float = 6.0

var round_number: int = 1
var structure: Structure = null

var _units: Array[Unit] = []
var _turn_index: int = 0
var _log: Array[String] = []
## commitment id -> { "unit": Unit, "member": StringName, "relief": float }
var _braces: Dictionary = {}
var _last_refusal: String = ""

func _init(p_structure: Structure) -> void:
	structure = p_structure


# --- setup ---------------------------------------------------------------

func add_unit(u: Unit) -> void:
	_units.append(u)

func units() -> Array[Unit]:
	return _units.duplicate()

func current_unit() -> Unit:
	if _units.is_empty():
		return null
	return _units[_turn_index]

func log_lines() -> Array[String]:
	return _log.duplicate()

func last_refusal() -> String:
	return _last_refusal


# --- actions -------------------------------------------------------------

## An Etherbound takes part of a member's load onto themselves.
## Returns false with a player-facing last_refusal() if they cannot.
func brace(u: Unit, member_id: StringName, relief: float, demand: float) -> bool:
	_last_refusal = ""
	if u.etherbound == null:
		_last_refusal = "%s has no affinity to brace with." % u.display_name
		return false
	var m: Structure.Member = structure.member(member_id)
	if m == null:
		_last_refusal = "There is nothing there to take hold of."
		return false

	var id := StringName("brace_%s_%s" % [u.display_name, member_id])
	var c := Commitment.new(id, "%s holding %s" % [u.display_name, m.label], demand)
	if not u.etherbound.commit(c):
		_last_refusal = u.etherbound.last_refusal()
		return false

	structure.add_external_support(member_id, relief)
	_braces[id] = {"unit": u, "member": member_id, "relief": relief}
	_note("%s takes the weight of %s." % [u.display_name, m.label])
	return true

## An ordinary unit props a member. Costs no reserve, holds indefinitely, and
## is the only option once every Etherbound is at capacity. This is the point
## of ordinary people. See AGENTS.md section 1.
func prop(u: Unit, member_id: StringName, amount: float) -> bool:
	_last_refusal = ""
	if not u.can_act():
		_last_refusal = "%s is already at capacity." % u.display_name
		return false
	var m: Structure.Member = structure.member(member_id)
	if m == null:
		_last_refusal = "There is nothing there to prop."
		return false
	structure.add_external_support(member_id, amount)
	_note("%s props %s. It will hold without anyone spending on it." % [u.display_name, m.label])
	return true

## How many more full rounds this unit can sustain what it is currently holding.
## The number the player actually plans around.
func rounds_sustainable(u: Unit) -> int:
	if u.etherbound == null:
		return 9999
	var e: Etherbound = u.etherbound
	var per_round: float = e.throughput_used() * SECONDS_PER_ROUND / maxf(e.mastery, 0.01)
	if per_round <= 0.0:
		return 9999
	return int(floor(e.reserve / per_round))


# --- turn flow -----------------------------------------------------------

func end_turn() -> Array[String]:
	_turn_index += 1
	if _turn_index >= _units.size():
		_turn_index = 0
		return end_round()
	return []

## Drain every committed Etherbound, drop what they can no longer hold, then
## ask the structure what that costs.
func end_round() -> Array[String]:
	var events: Array[String] = []

	for u in _units:
		if u.etherbound == null:
			continue
		for line in u.etherbound.tick(SECONDS_PER_ROUND):
			events.append(line)

	# Anything the body dropped stops relieving the structure.
	for id in _braces.keys():
		var brace_data: Dictionary = _braces[id]
		var u: Unit = brace_data["unit"]
		var still_held: bool = false
		for c in u.etherbound.commitments():
			if c.id == id:
				still_held = true
		if not still_held:
			structure.remove_external_support(brace_data["member"], brace_data["relief"])
			_braces.erase(id)

	structure.solve()
	for label in structure.overloaded():
		events.append("%s gives way." % label)

	for line in events:
		_note(line)
	round_number += 1
	return events


func _note(line: String) -> void:
	_log.append("Round %d: %s" % [round_number, line])
