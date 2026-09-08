## The physiological core. This class encodes the load-bearing canon rule.
##
## FOUR SEPARATE QUANTITIES. Never collapse them into one bar:
##   reserve       capacity. Depletes as work is done. Refills slowly with rest.
##   throughput    a RATE ceiling, whole body, shared across all six junctions.
##   mastery       control and efficiency. Does NOT raise capacity or the ceiling.
##   exhaustion    bodily cost. Accumulates independently of spent reserve.
##
## The rule that makes the slice-1 rescue work: more simultaneous tasks divide
## output. A Kinetic holding a beam at full demand has no throughput left for
## anything else, no matter how much reserve remains.
##
## See docs/CANON.md "Physiology" and AGENTS.md section 3 rule 6.
class_name Etherbound
extends RefCounted

const JUNCTION_COUNT: int = 6

var affinity: Affinity.Kind = Affinity.Kind.KINETIC

var reserve_max: float = 100.0
var reserve: float = 100.0
var throughput_max: float = 10.0
## Efficiency multiplier on reserve drain. Higher mastery does more with less.
## It must never be allowed to raise reserve_max or throughput_max.
var mastery: float = 1.0
var exhaustion: float = 0.0
var exhaustion_max: float = 100.0

## Exhaustion accrued per unit of reserve spent.
const EXHAUSTION_PER_RESERVE: float = 0.35

var _commitments: Array[Commitment] = []
## Plain-language reason the last rejected action failed. Never leave this empty
## on a refusal. See AGENTS.md section 4.
var _last_refusal: String = ""

func _init(p_affinity: Affinity.Kind = Affinity.Kind.KINETIC) -> void:
	affinity = p_affinity


# --- queries -------------------------------------------------------------

func commitments() -> Array[Commitment]:
	return _commitments.duplicate()

func junctions_used() -> int:
	var used: int = 0
	for c in _commitments:
		used += c.junctions
	return used

func junctions_free() -> int:
	return JUNCTION_COUNT - junctions_used()

## Throughput currently being delivered, summed across all commitments.
func throughput_used() -> float:
	var total: float = 0.0
	for c in _commitments:
		total += c.granted
	return total

## Unmet demand exists when the body is oversubscribed. This is the state the
## player must be able to see before they commit to one more thing.
func total_demand() -> float:
	var total: float = 0.0
	for c in _commitments:
		total += c.demand
	return total

func is_oversubscribed() -> bool:
	return total_demand() > throughput_max

## With no argument: is there ANY spare capacity at all. A body sitting exactly
## on its ceiling has none, so this is a strict comparison. With a demand: would
## that specific task fit. Junction occupancy counts either way, because a free
## junction is as necessary as free throughput.
func has_headroom(for_demand: float = 0.0, for_junctions: int = 1) -> bool:
	if reserve <= 0.0:
		return false
	if for_junctions > junctions_free():
		return false
	if for_demand <= 0.0:
		return total_demand() < throughput_max
	return total_demand() + for_demand <= throughput_max

func last_refusal() -> String:
	return _last_refusal


# --- prediction ----------------------------------------------------------

## What WOULD happen if this were committed. The UI calls this before the
## player spends anything. Returning a prediction rather than a yes/no is
## deliberate: the answer is usually "yes, but the beam starts slipping".
func preview(demand: float, junctions: int = 1) -> Dictionary:
	var projected_demand: float = total_demand() + maxf(demand, 0.0)
	var scale: float = 1.0
	if projected_demand > throughput_max and projected_demand > 0.0:
		scale = throughput_max / projected_demand

	var affected: Array[Dictionary] = []
	for c in _commitments:
		affected.append({
			"label": c.label,
			"from": c.service_ratio(),
			"to": scale,
		})

	return {
		"possible": junctions <= junctions_free() and reserve > 0.0,
		"would_divide": scale < 1.0,
		"service_ratio": scale,
		"affected": affected,
		"junctions_free_after": junctions_free() - junctions,
	}


# --- mutation ------------------------------------------------------------

## Returns true on success. On failure, last_refusal() carries player-facing text.
func commit(c: Commitment) -> bool:
	_last_refusal = ""

	if reserve <= 0.0:
		_last_refusal = "Reserve is empty. %s cannot be held." % c.label
		return false

	if c.junctions > junctions_free():
		_last_refusal = "No junction free. %d of %d already committed." % [
			junctions_used(), JUNCTION_COUNT
		]
		return false

	for existing in _commitments:
		if existing.id == c.id:
			_last_refusal = "%s is already being held." % c.label
			return false

	_commitments.append(c)
	_reallocate()
	return true

func release(id: StringName) -> bool:
	for i in _commitments.size():
		if _commitments[i].id == id:
			_commitments.remove_at(i)
			_reallocate()
			return true
	return false

func release_all(_reason: String = "") -> void:
	_commitments.clear()

## Advance by delta seconds. Drains reserve at the delivered rate, accrues
## exhaustion, and drops everything if the reserve runs out.
## Returns a list of player-facing events, empty on a quiet tick.
func tick(delta: float) -> Array[String]:
	var events: Array[String] = []
	if _commitments.is_empty():
		return events

	var delivered: float = throughput_used()
	var drain: float = delivered * delta / maxf(mastery, 0.01)

	if drain >= reserve:
		# Everything fails at once. This is intended: an Etherbound who spends
		# to zero while holding a load drops the load.
		drain = reserve
		reserve = 0.0
		exhaustion = minf(exhaustion + drain * EXHAUSTION_PER_RESERVE, exhaustion_max)
		for c in _commitments:
			events.append("Reserve gone. %s fails." % c.label)
		_commitments.clear()
		return events

	reserve -= drain
	exhaustion = minf(exhaustion + drain * EXHAUSTION_PER_RESERVE, exhaustion_max)
	return events

## Recovery is not the inverse of spending. Reserve returns; exhaustion does not,
## at least not on the same clock. See docs/CANON.md, Vital: repair is not recovery.
func rest(delta: float, reserve_rate: float = 4.0, exhaustion_rate: float = 0.6) -> void:
	if not _commitments.is_empty():
		return
	reserve = minf(reserve + reserve_rate * delta, reserve_max)
	exhaustion = maxf(exhaustion - exhaustion_rate * delta, 0.0)


# --- internals -----------------------------------------------------------

## The whole rule, in six lines. Demand above the ceiling is served
## proportionally. Nobody gets priority. Adding a task takes output from
## every task already running.
func _reallocate() -> void:
	var demand: float = total_demand()
	if demand <= 0.0:
		return
	var scale: float = 1.0
	if demand > throughput_max:
		scale = throughput_max / demand
	for c in _commitments:
		c.granted = c.demand * scale
