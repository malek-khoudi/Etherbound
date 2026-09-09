## Incident mode: the turn-based emergency layer, and the ONLY authority on how
## an incident ends.
##
## J10-01: outcome must never come from a checklist of actions taken. Whether
## people live is decided by the structure and the bodies holding it, not by
## whether the player pressed one button per role. A tutorial can track which
## lessons were covered; it must not be rendered as a physical collapse.
##
## J10-03: an effect that is "maintained" costs throughput for as long as it is
## held and is withdrawn when the body can no longer hold it. Gravitic lightening
## and a Transmutative front are maintained. A worker's prop and a COMPLETED
## material change are not: they persist because the world itself changed.
##
## Adaptation, not canon (see docs/ADAPTATION.md):
##   - Rounds, SECONDS_PER_ROUND, fixed turn order.
##   - Extraction modelled as N rounds of work under a standing load path.
class_name Incident
extends RefCounted

const SECONDS_PER_ROUND: float = 6.0


## One maintained or permanent change an actor has made to the world.
class Effect extends RefCounted:
	var id: StringName
	## brace | lighten | reshape | prop
	var kind: String
	var unit: Unit
	var member: StringName
	var to_id: StringName = &""
	## Relief, target gravity factor, or capacity to add.
	var magnitude: float = 0.0
	var members: Array = []
	var rounds_required: int = 0
	var rounds_done: int = 0
	var applied: float = 0.0
	var complete: bool = false

	func maintained() -> bool:
		return kind == "brace" or kind == "lighten" or (kind == "reshape" and not complete)

	func progress() -> float:
		if rounds_required <= 0:
			return 1.0
		return clampf(float(rounds_done) / float(rounds_required), 0.0, 1.0)


var round_number: int = 1
var structure: Structure = null

## The rescue objective. Extraction is work. It only advances while the load
## path over the casualty is standing.
var casualty_member: StringName = &""
var extraction_rounds_required: int = 3
var extraction_rounds_done: int = 0

var resolved: bool = false
var failed: bool = false

var _units: Array[Unit] = []
var _turn_index: int = 0
var _log: Array[String] = []
var _effects: Dictionary = {}
var _last_refusal: String = ""

func _init(p_structure: Structure) -> void:
	structure = p_structure


# --- setup ---------------------------------------------------------------

func add_unit(u: Unit) -> void:
	_units.append(u)

func units() -> Array[Unit]:
	return _units.duplicate()

func current_unit() -> Unit:
	return null if _units.is_empty() else _units[_turn_index]

func log_lines() -> Array[String]:
	return _log.duplicate()

func last_refusal() -> String:
	return _last_refusal

## Who is trapped and how long getting them out takes.
func set_objective(member_id: StringName, rounds: int) -> void:
	casualty_member = member_id
	extraction_rounds_required = maxi(rounds, 1)
	extraction_rounds_done = 0

func effects() -> Array:
	return _effects.values()


# --- the only outcome authority ------------------------------------------

## Physics decides. Never a checklist. `over` is what is currently past capacity.
func outcome() -> Dictionary:
	if failed:
		return {"resolved": false, "failed": true,
			"reason": "The load path gave way before the casualty was clear."}
	if resolved:
		return {"resolved": true, "failed": false,
			"reason": "The casualty is clear and the structure is still standing."}
	var remaining: int = extraction_rounds_required - extraction_rounds_done
	return {"resolved": false, "failed": false,
		"reason": "Extraction in progress. %d round%s of work left." % [
			remaining, "" if remaining == 1 else "s"]}

## Is the path over the casualty currently sound? This, not a flag, is what
## lets extraction continue.
func path_is_standing() -> bool:
	return structure.overloaded().is_empty()


# --- actions -------------------------------------------------------------

func _commit(u: Unit, id: StringName, label: String, demand: float) -> bool:
	if u.etherbound == null:
		_last_refusal = "%s has no affinity for that." % u.display_name
		return false
	var c := Commitment.new(id, label, demand)
	if not u.etherbound.commit(c):
		_last_refusal = u.etherbound.last_refusal()
		return false
	return true

## Kinetic. Takes part of a member's load onto the actor. Withdrawn if dropped.
func brace(u: Unit, member_id: StringName, relief: float, demand: float) -> bool:
	_last_refusal = ""
	var m: Structure.Member = structure.member(member_id)
	if m == null:
		_last_refusal = "There is nothing there to take hold of."
		return false
	var id := StringName("brace_%s_%s" % [u.display_name, member_id])
	if not _commit(u, id, "%s holding %s" % [u.display_name, m.label], demand):
		return false
	structure.add_external_support(member_id, relief)
	var e := Effect.new()
	e.id = id; e.kind = "brace"; e.unit = u; e.member = member_id
	e.magnitude = relief; e.applied = relief
	_effects[id] = e
	_note("%s takes the weight of %s." % [u.display_name, m.label])
	return true

## Gravitic. Alters acceleration over members, never their mass. Maintained:
## the region returns to normal the moment the actor cannot hold it.
func lighten(u: Unit, member_ids: Array, factor: float, demand: float) -> bool:
	_last_refusal = ""
	if member_ids.is_empty():
		_last_refusal = "Nothing selected to lighten."
		return false
	var id := StringName("lighten_%s" % u.display_name)
	if not _commit(u, id, "%s holding the region light" % u.display_name, demand):
		return false
	structure.set_gravity_factor(member_ids, factor)
	var e := Effect.new()
	e.id = id; e.kind = "lighten"; e.unit = u
	e.members = member_ids.duplicate(); e.magnitude = factor
	_effects[id] = e
	_note("%s lightens the region. Mass is unchanged; the load is not." % u.display_name)
	return true

## Transmutative. A maintained front on contiguous material. Capacity grows with
## the front's progress and is REVERTED if the front is dropped early. Once the
## front completes the material change is done, so it persists and stops costing.
func reshape(u: Unit, from_id: StringName, to_id: StringName, added_capacity: float,
		rounds: int, demand: float) -> bool:
	_last_refusal = ""
	if structure.connection_between(from_id, to_id) == null:
		_last_refusal = "There is no seam there to work."
		return false
	var id := StringName("reshape_%s_%s" % [from_id, to_id])
	if _effects.has(id):
		_last_refusal = "That seam is already being worked."
		return false
	if not _commit(u, id, "%s working the seam" % u.display_name, demand):
		return false
	var e := Effect.new()
	e.id = id; e.kind = "reshape"; e.unit = u
	e.member = from_id; e.to_id = to_id
	e.magnitude = added_capacity; e.rounds_required = maxi(rounds, 1)
	_effects[id] = e
	_note("%s begins working the seam. It is not sound yet." % u.display_name)
	return true

## An ordinary unit props a member. Costs no reserve, holds indefinitely, and is
## the only option once every Etherbound is at capacity. See AGENTS.md section 1.
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
	var e := Effect.new()
	e.id = StringName("prop_%s_%s" % [u.display_name, member_id])
	e.kind = "prop"; e.unit = u; e.member = member_id
	e.magnitude = amount; e.applied = amount; e.complete = true
	_effects[e.id] = e
	_note("%s props %s. It will hold without anyone spending on it." % [u.display_name, m.label])
	return true

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

func end_round() -> Array[String]:
	var events: Array[String] = []
	if resolved or failed:
		return events

	for u in _units:
		if u.etherbound != null:
			for line in u.etherbound.tick(SECONDS_PER_ROUND):
				events.append(line)

	_withdraw_dropped_effects(events)
	_advance_fronts(events)
	structure.solve()

	var over: Array[String] = structure.overloaded()
	if not over.is_empty():
		failed = true
		for label in over:
			events.append("%s gives way." % label)
	elif casualty_member != &"":
		extraction_rounds_done += 1
		if extraction_rounds_done >= extraction_rounds_required:
			resolved = true
			events.append("The casualty is clear. The path held.")
		else:
			events.append("Extraction continues. %d of %d." % [
				extraction_rounds_done, extraction_rounds_required])

	for line in events:
		_note(line)
	round_number += 1
	return events


# --- effect lifecycle ----------------------------------------------------

## Anything the body could no longer hold stops changing the world. A completed
## material change is exempt: the seam is genuinely repaired.
func _withdraw_dropped_effects(events: Array[String]) -> void:
	for id in _effects.keys():
		var e: Effect = _effects[id]
		if not e.maintained():
			continue
		var still_held: bool = false
		if e.unit.etherbound != null:
			for c in e.unit.etherbound.commitments():
				if c.id == id:
					still_held = true
		if still_held:
			continue
		match e.kind:
			"brace":
				structure.remove_external_support(e.member, e.applied)
			"lighten":
				structure.set_gravity_factor(e.members, 1.0)
				events.append("The region returns to its own weight.")
			"reshape":
				if e.applied > 0.0:
					var c := structure.connection_between(e.member, e.to_id)
					if c != null:
						c.capacity -= e.applied
				events.append("The unfinished seam relaxes back.")
		_effects.erase(id)

## A maintained front makes progress each round it survives. Capacity follows
## the progress, so a half-worked seam is genuinely half as good.
func _advance_fronts(events: Array[String]) -> void:
	for id in _effects.keys():
		var e: Effect = _effects[id]
		if e.kind != "reshape" or e.complete:
			continue
		e.rounds_done += 1
		var target: float = e.magnitude * e.progress()
		var c := structure.connection_between(e.member, e.to_id)
		if c != null:
			c.capacity += target - e.applied
		e.applied = target
		if e.rounds_done >= e.rounds_required:
			e.complete = true
			if c != null and c.kind == "corroded":
				c.kind = "repaired"
			if e.unit.etherbound != null:
				e.unit.etherbound.release(id)
			events.append("The seam is sound. It holds on its own now.")


func _note(line: String) -> void:
	_log.append("Round %d: %s" % [round_number, line])
