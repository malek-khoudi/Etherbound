## Headless proof of the reserve/throughput rule.
## Run:  godot --headless --path game --script res://tests/reserve_test.gd
extends SceneTree

var _failures: int = 0

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("  PASS  ", label)
	else:
		_failures += 1
		print("  FAIL  ", label, "  ", detail)

func _initialize() -> void:
	print("\n=== Etherbound reserve / throughput ===\n")

	_test_single_commitment()
	_test_division()
	_test_third_task_steals_from_the_first_two()
	_test_junction_limit()
	_test_reserve_exhaustion_drops_the_load()
	_test_ordinary_unit_acts_when_party_is_capped()
	_test_mastery_is_efficiency_not_capacity()

	print("\n=== %s ===\n" % ("ALL PASS" if _failures == 0 else "%d FAILURE(S)" % _failures))
	quit(1 if _failures > 0 else 0)


func _test_single_commitment() -> void:
	print("1. One task under the ceiling is fully served")
	var e := Etherbound.new(Affinity.Kind.KINETIC)
	e.throughput_max = 10.0
	e.commit(Commitment.new(&"beam", "Holding the gantry beam", 6.0))
	_check("served at 100%", is_equal_approx(e.commitments()[0].service_ratio(), 1.0))
	_check("not oversubscribed", not e.is_oversubscribed())
	_check("headroom for 4 more", e.has_headroom(4.0))
	_check("no headroom for 5 more", not e.has_headroom(5.0))


func _test_division() -> void:
	print("2. Two tasks over the ceiling divide output")
	var e := Etherbound.new(Affinity.Kind.KINETIC)
	e.throughput_max = 10.0
	e.commit(Commitment.new(&"beam", "Holding the gantry beam", 8.0))
	e.commit(Commitment.new(&"door", "Forcing the shutter", 8.0))
	var ratio: float = e.commitments()[0].service_ratio()
	_check("both served at 62.5%", is_equal_approx(ratio, 10.0 / 16.0), "got %f" % ratio)
	_check("delivered equals the ceiling", is_equal_approx(e.throughput_used(), 10.0))
	_check("oversubscribed flag set", e.is_oversubscribed())


func _test_third_task_steals_from_the_first_two() -> void:
	print("3. A third task takes output from the two already running")
	var e := Etherbound.new(Affinity.Kind.KINETIC)
	e.throughput_max = 12.0
	e.commit(Commitment.new(&"beam", "Holding the gantry beam", 6.0))
	e.commit(Commitment.new(&"brace", "Bracing the walkway", 6.0))
	var before: float = e.commitments()[0].service_ratio()

	var pre: Dictionary = e.preview(6.0)
	_check("preview warns output would divide", pre["would_divide"])
	_check("preview says 66% service", is_equal_approx(pre["service_ratio"], 12.0 / 18.0))

	e.commit(Commitment.new(&"pull", "Pulling the worker clear", 6.0))
	var after: float = e.commitments()[0].service_ratio()
	_check("beam was fully served before", is_equal_approx(before, 1.0))
	_check("beam now slipping to 66%", is_equal_approx(after, 12.0 / 18.0), "got %f" % after)
	_check("preview matched reality", is_equal_approx(after, pre["service_ratio"]))


func _test_junction_limit() -> void:
	print("4. Six junctions is a hard ceiling, refusal is readable")
	var e := Etherbound.new(Affinity.Kind.GRAVITIC)
	e.throughput_max = 100.0
	for i in 6:
		e.commit(Commitment.new(StringName("t%d" % i), "Task %d" % i, 1.0))
	_check("six junctions used", e.junctions_used() == 6)
	var ok: bool = e.commit(Commitment.new(&"seventh", "One more thing", 1.0))
	_check("seventh refused", not ok)
	_check("refusal text is specific", e.last_refusal().contains("junction"), e.last_refusal())
	print("        refusal: \"%s\"" % e.last_refusal())


func _test_reserve_exhaustion_drops_the_load() -> void:
	print("5. Spending to zero while holding a load drops the load")
	var e := Etherbound.new(Affinity.Kind.KINETIC)
	e.reserve = 10.0
	e.reserve_max = 100.0
	e.throughput_max = 10.0
	e.commit(Commitment.new(&"beam", "Holding the gantry beam", 10.0))

	var events: Array[String] = e.tick(0.5)
	_check("survives half a second", events.is_empty())
	_check("reserve halved", is_equal_approx(e.reserve, 5.0), "got %f" % e.reserve)
	_check("exhaustion accrued", e.exhaustion > 0.0)

	events = e.tick(1.0)
	_check("beam fails", events.size() == 1)
	_check("failure names the act", events[0].contains("gantry beam"), str(events))
	_check("commitments cleared", e.commitments().is_empty())
	_check("reserve at zero", is_equal_approx(e.reserve, 0.0))
	print("        event: \"%s\"" % events[0])


func _test_ordinary_unit_acts_when_party_is_capped() -> void:
	print("6. Ordinary units act when every Etherbound is at capacity")
	var party: Array[Unit] = []

	for spec in [
		[&"Kinetic", Affinity.Kind.KINETIC],
		[&"Gravitic", Affinity.Kind.GRAVITIC],
		[&"Transmutative", Affinity.Kind.TRANSMUTATIVE],
	]:
		var e := Etherbound.new(spec[1])
		e.throughput_max = 10.0
		e.commit(Commitment.new(&"held", "Holding", 10.0))
		party.append(Unit.new(str(spec[0]), e))

	var worker := Unit.new("Site worker")
	worker.directable = true

	var any_etherbound_free: bool = false
	for u in party:
		if u.can_act():
			any_etherbound_free = true

	_check("no Etherbound can act", not any_etherbound_free)
	_check("the worker can", worker.can_act())
	_check("worker is not Etherbound", not worker.is_etherbound())
	print("        %s" % worker.status_line())


func _test_mastery_is_efficiency_not_capacity() -> void:
	print("7. Mastery lowers drain. It never raises the ceiling or capacity")
	var novice := Etherbound.new(Affinity.Kind.TRANSMUTATIVE)
	var adept := Etherbound.new(Affinity.Kind.TRANSMUTATIVE)
	adept.mastery = 2.0

	for e in [novice, adept]:
		e.throughput_max = 10.0
		e.commit(Commitment.new(&"front", "Maintaining the front", 10.0))
		e.tick(1.0)

	_check("adept spent half as much", is_equal_approx(adept.reserve, 95.0) and is_equal_approx(novice.reserve, 90.0),
		"novice %f adept %f" % [novice.reserve, adept.reserve])
	_check("same throughput ceiling", is_equal_approx(novice.throughput_max, adept.throughput_max))
	_check("same reserve capacity", is_equal_approx(novice.reserve_max, adept.reserve_max))
