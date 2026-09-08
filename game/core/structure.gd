## The structural connection graph.
##
## This is what makes "the anchor failed" a fact rather than a dice roll.
##
## Members rest on other members. Load flows down those connections to ground.
## A Kinetic push needs an anchor, and the anchor is only as good as the weakest
## element between it and the ground. The player is told WHICH element that is,
## by name, before they commit. See AGENTS.md section 3 rule 5.
##
## Deliberate simplifications, recorded as adaptation not canon:
##   - Load splits equally between a member's supports, not by stiffness.
##   - The graph is a DAG. Real structures have cycles; authored levels will not.
##   - No moments, no buckling, no material fatigue curves. Capacity is a number.
## See docs/ADAPTATION.md.
class_name Structure
extends RefCounted


class Member extends RefCounted:
	var id: StringName
	var label: String
	## Structural self-weight, in the same arbitrary units as capacity.
	var mass: float
	## What this member can carry, its own mass included.
	var capacity: float
	## True for anything that reaches the ground on its own: a foundation, bedrock, a wall footing.
	var grounded: bool
	## Gravitic alters acceleration, not weight. Mass never changes; the load it
	## exerts does. 0.5 means half load, 1.5 means the region is pulling harder.
	var gravity_factor: float = 1.0
	## Solved total load carried, including everything resting on it.
	var load: float = 0.0

	func _init(p_id: StringName, p_label: String, p_mass: float, p_capacity: float, p_grounded: bool = false) -> void:
		id = p_id
		label = p_label
		mass = p_mass
		capacity = p_capacity
		grounded = p_grounded

	func effective_mass() -> float:
		return mass * gravity_factor

	func utilisation() -> float:
		if capacity <= 0.0:
			return INF
		return load / capacity


class Connection extends RefCounted:
	## The member that rests on another.
	var from_id: StringName
	## The member carrying it.
	var to_id: StringName
	var capacity: float
	## Player-facing. "bolted", "welded", "resting", "corroded", "seized".
	var kind: String
	var load: float = 0.0
	var severed: bool = false

	func _init(p_from: StringName, p_to: StringName, p_capacity: float, p_kind: String = "bolted") -> void:
		from_id = p_from
		to_id = p_to
		capacity = p_capacity
		kind = p_kind

	func label() -> String:
		return "the %s connection" % kind

	func utilisation() -> float:
		if capacity <= 0.0:
			return INF
		return load / capacity


var _members: Dictionary = {}
var _connections: Array[Connection] = []
var _last_error: String = ""


# --- authoring -----------------------------------------------------------

func add_member(id: StringName, label: String, mass: float, capacity: float, grounded: bool = false) -> Member:
	var m := Member.new(id, label, mass, capacity, grounded)
	_members[id] = m
	return m

func connect_members(from_id: StringName, to_id: StringName, capacity: float, kind: String = "bolted") -> Connection:
	var c := Connection.new(from_id, to_id, capacity, kind)
	_connections.append(c)
	return c

func member(id: StringName) -> Member:
	return _members.get(id)

func last_error() -> String:
	return _last_error


# --- topology ------------------------------------------------------------

## What this member rests on.
func supports_of(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for c in _connections:
		if c.from_id == id and not c.severed:
			out.append(c.to_id)
	return out

## What rests on this member.
func dependents_of(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for c in _connections:
		if c.to_id == id and not c.severed:
			out.append(c.from_id)
	return out

func connection_between(from_id: StringName, to_id: StringName) -> Connection:
	for c in _connections:
		if c.from_id == from_id and c.to_id == to_id:
			return c
	return null

## Members with no remaining path to ground. These are what falls.
func unsupported() -> Array[StringName]:
	var reaches: Dictionary = {}
	for id in _members:
		reaches[id] = _reaches_ground(id, {})
	var out: Array[StringName] = []
	for id in _members:
		if not reaches[id]:
			out.append(id)
	out.sort()
	return out

func _reaches_ground(id: StringName, seen: Dictionary) -> bool:
	var m: Member = _members.get(id)
	if m == null or seen.has(id):
		return false
	if m.grounded:
		return true
	seen[id] = true
	for s in supports_of(id):
		if _reaches_ground(s, seen):
			return true
	return false


# --- solve ---------------------------------------------------------------

## Propagate load down to ground. Returns false and sets last_error() if the
## graph has a cycle, which is an authoring bug rather than a gameplay state.
func solve() -> bool:
	_last_error = ""
	for id in _members:
		_members[id].load = _members[id].effective_mass()
	for c in _connections:
		c.load = 0.0

	# Kahn's algorithm. In-degree counts what rests ON a member, so processing
	# order runs from the top of the structure down toward the ground.
	var in_degree: Dictionary = {}
	for id in _members:
		in_degree[id] = 0
	for c in _connections:
		if not c.severed and _members.has(c.to_id):
			in_degree[c.to_id] = in_degree[c.to_id] + 1

	var queue: Array[StringName] = []
	for id in _members:
		if in_degree[id] == 0:
			queue.append(id)

	var processed: int = 0
	while not queue.is_empty():
		var id: StringName = queue.pop_front()
		processed += 1
		var carriers: Array[StringName] = supports_of(id)
		if not carriers.is_empty():
			var share: float = _members[id].load / float(carriers.size())
			for to_id in carriers:
				var c: Connection = connection_between(id, to_id)
				if c != null:
					c.load += share
				if _members.has(to_id):
					_members[to_id].load += share
					in_degree[to_id] = in_degree[to_id] - 1
					if in_degree[to_id] == 0:
						queue.append(to_id)

	if processed < _members.size():
		_last_error = "Structure has a cycle. %d of %d members resolved." % [processed, _members.size()]
		return false
	return true


# --- the player-facing question ------------------------------------------

## "If I brace against this and push with N, what breaks first?"
##
## Returns a dictionary the UI renders directly. `reason` is always populated
## and always names a specific element. Never return a bare boolean here.
func anchor_report(anchor_id: StringName, reaction: float) -> Dictionary:
	var anchor: Member = _members.get(anchor_id)
	if anchor == null:
		return {"holds": false, "reason": "There is nothing there to brace against."}

	if not _reaches_ground(anchor_id, {}):
		return {
			"holds": false,
			"reason": "%s carries no load to ground. There is nothing behind it." % anchor.label,
			"failing_element": anchor.label,
		}

	if not solve():
		return {"holds": false, "reason": _last_error}

	var before: float = anchor.utilisation()

	# Re-solve with the reaction added at the anchor and read off the first
	# element over capacity along the way down.
	var probe := _clone()
	probe._members[anchor_id].mass += reaction / maxf(probe._members[anchor_id].gravity_factor, 0.01)
	if not probe.solve():
		return {"holds": false, "reason": probe.last_error()}

	var failure: Dictionary = probe._first_overload(anchor_id)
	if failure.is_empty():
		return {
			"holds": true,
			"reason": "%s holds. Load path is at %d%% of capacity." % [
				anchor.label, int(round(probe._members[anchor_id].utilisation() * 100.0))
			],
			"utilisation_before": before,
			"utilisation_after": probe._members[anchor_id].utilisation(),
			"failing_element": "",
		}

	return {
		"holds": false,
		"reason": "%s fails, not %s. It is at %d%% before you push." % [
			failure["label"], anchor.label, int(round(failure["utilisation_before"] * 100.0))
		],
		"failing_element": failure["label"],
		"utilisation_before": before,
		"utilisation_after": failure["utilisation"],
	}

## Walk from a member down to ground, returning the first element over capacity.
## Connections are checked before the members they feed, because a joint that
## lets go is the more common and more legible failure.
func _first_overload(from_id: StringName) -> Dictionary:
	var visited: Dictionary = {}
	var stack: Array[StringName] = [from_id]
	while not stack.is_empty():
		var id: StringName = stack.pop_front()
		if visited.has(id):
			continue
		visited[id] = true
		var m: Member = _members.get(id)
		if m == null:
			continue
		if m.utilisation() > 1.0:
			return {"label": m.label, "utilisation": m.utilisation(),
				"utilisation_before": m.load / maxf(m.capacity, 0.01)}
		for to_id in supports_of(id):
			var c: Connection = connection_between(id, to_id)
			if c != null and c.utilisation() > 1.0:
				return {"label": "%s under %s" % [c.label(), m.label],
					"utilisation": c.utilisation(),
					"utilisation_before": c.load / maxf(c.capacity, 0.01)}
			stack.append(to_id)
	return {}


# --- damage --------------------------------------------------------------

## Cut a connection. Returns what is now falling, by label.
func sever(from_id: StringName, to_id: StringName) -> Array[String]:
	var c: Connection = connection_between(from_id, to_id)
	if c != null:
		c.severed = true
	solve()
	var falling: Array[String] = []
	for id in unsupported():
		falling.append(_members[id].label)
	return falling

## Transmutative repair or reinforcement of one joint.
func reinforce(from_id: StringName, to_id: StringName, added_capacity: float) -> bool:
	var c: Connection = connection_between(from_id, to_id)
	if c == null:
		return false
	c.capacity += added_capacity
	if c.kind == "corroded":
		c.kind = "repaired"
	solve()
	return true

## Gravitic. Alters acceleration over a set of members, never their mass.
func set_gravity_factor(ids: Array, factor: float) -> void:
	for id in ids:
		if _members.has(id):
			_members[id].gravity_factor = factor
	solve()


func _clone() -> Structure:
	var s := Structure.new()
	for id in _members:
		var m: Member = _members[id]
		var copy := s.add_member(m.id, m.label, m.mass, m.capacity, m.grounded)
		copy.gravity_factor = m.gravity_factor
	for c in _connections:
		var cc := s.connect_members(c.from_id, c.to_id, c.capacity, c.kind)
		cc.severed = c.severed
	return s
