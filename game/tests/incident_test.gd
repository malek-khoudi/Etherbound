## The slice-1 rescue, proven end to end.
## Run:  ./tools/test.sh
extends SceneTree

var _failures: int = 0

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("  PASS  ", label)
	else:
		_failures += 1
		print("  FAIL  ", label, "  ", detail)

## A gantry bay that is ALREADY failing. The corroded bracket cannot carry the
## walkway plus the crate sitting on it. Left alone, it comes down.
func _failing_bay() -> Structure:
	var s := Structure.new()
	s.add_member(&"footing", "the footing", 0.0, 10000.0, true)
	s.add_member(&"column", "the column", 200.0, 2000.0)
	s.add_member(&"beam", "the main beam", 150.0, 800.0)
	s.add_member(&"walkway", "the walkway", 100.0, 900.0)
	s.add_member(&"crate", "the feedstock crate", 300.0, 500.0)
	s.connect_members(&"column", &"footing", 3000.0, "bolted")
	s.connect_members(&"beam", &"column", 900.0, "welded")
	s.connect_members(&"walkway", &"beam", 350.0, "corroded")
	s.connect_members(&"crate", &"walkway", 600.0, "resting")
	s.solve()
	return s

func _kinetic(name: String, reserve: float) -> Unit:
	var e := Etherbound.new(Affinity.Kind.KINETIC)
	e.reserve_max = reserve
	e.reserve = reserve
	e.throughput_max = 10.0
	return Unit.new(name, e)

func _initialize() -> void:
	print("\n=== Incident mode: the rescue ===\n")
	_test_bay_is_failing_before_anyone_acts()
	_test_bracing_holds_it_up()
	_test_the_countdown_is_honest()
	_test_reserve_runs_out_and_the_walkway_falls()
	_test_the_worker_saves_it()
	_test_turn_order_cycles_into_a_round()
	print("\n=== %s ===\n" % ("ALL PASS" if _failures == 0 else "%d FAILURE(S)" % _failures))
	quit(1 if _failures > 0 else 0)


func _test_bay_is_failing_before_anyone_acts() -> void:
	print("1. The bay is already coming down")
	var s := _failing_bay()
	var bad: Array[String] = s.overloaded()
	_check("something is over capacity", bad.size() == 1, str(bad))
	_check("it is the corroded bracket", bad[0].contains("corroded"), str(bad))
	print("        overloaded: %s" % str(bad))


func _test_bracing_holds_it_up() -> void:
	print("2. A Kinetic takes the weight and it holds")
	var s := _failing_bay()
	var inc := Incident.new(s)
	var kess := _kinetic("Kess", 150.0)
	inc.add_unit(kess)
	_check("brace accepted", inc.brace(kess, &"walkway", 150.0, 10.0), inc.last_refusal())
	_check("structure now standing", s.overloaded().is_empty(), str(s.overloaded()))
	_check("Kess is at capacity", not kess.can_act())
	print("        %s" % inc.log_lines()[0])


func _test_the_countdown_is_honest() -> void:
	print("3. The projected countdown matches what actually happens")
	var s := _failing_bay()
	var inc := Incident.new(s)
	var kess := _kinetic("Kess", 150.0)
	inc.add_unit(kess)
	inc.brace(kess, &"walkway", 150.0, 10.0)

	var projected: int = inc.rounds_sustainable(kess)
	_check("projects 2 full rounds", projected == 2, "got %d" % projected)

	var survived: int = 0
	for i in 5:
		var events: Array[String] = inc.end_round()
		if events.is_empty():
			survived += 1
		else:
			break
	_check("survived exactly what was projected", survived == projected, "survived %d" % survived)


func _test_reserve_runs_out_and_the_walkway_falls() -> void:
	print("4. When the reserve is gone, the walkway comes down")
	var s := _failing_bay()
	var inc := Incident.new(s)
	var kess := _kinetic("Kess", 150.0)
	inc.add_unit(kess)
	inc.brace(kess, &"walkway", 150.0, 10.0)

	inc.end_round()
	inc.end_round()
	var events: Array[String] = inc.end_round()

	_check("two things happen at once", events.size() == 2, str(events))
	_check("the hold fails first", events[0].contains("Reserve gone"), str(events))
	_check("then the bracket gives way", events[1].contains("gives way"), str(events))
	_check("relief was withdrawn", is_equal_approx(s.external_support(&"walkway"), 0.0))
	for line in events:
		print("        %s" % line)


func _test_the_worker_saves_it() -> void:
	print("5. The worker props it, so the same failure costs nothing")
	var s := _failing_bay()
	var inc := Incident.new(s)
	var kess := _kinetic("Kess", 150.0)
	var maren := Unit.new("Maren")
	maren.directable = true
	inc.add_unit(kess)
	inc.add_unit(maren)

	inc.brace(kess, &"walkway", 150.0, 10.0)
	_check("Kess cannot do anything else", not kess.can_act())
	_check("Maren still can", maren.can_act())

	inc.end_round()
	_check("Maren props the walkway", inc.prop(maren, &"walkway", 150.0), inc.last_refusal())
	inc.end_round()
	var events: Array[String] = inc.end_round()

	_check("Kess still loses the hold", events.has("Reserve gone. Kess holding the walkway fails."), str(events))
	var fell: bool = false
	for e in events:
		if e.contains("gives way"):
			fell = true
	_check("but nothing gives way", not fell, str(events))
	_check("structure is standing", s.overloaded().is_empty(), str(s.overloaded()))
	print("        %s" % inc.log_lines()[1])


func _test_turn_order_cycles_into_a_round() -> void:
	print("6. Turns cycle, and the round ends when they wrap")
	var inc := Incident.new(_failing_bay())
	inc.add_unit(_kinetic("Kess", 500.0))
	inc.add_unit(Unit.new("Maren"))
	_check("round starts at 1", inc.round_number == 1)
	_check("Kess acts first", inc.current_unit().display_name == "Kess")
	inc.end_turn()
	_check("then Maren", inc.current_unit().display_name == "Maren")
	_check("still round 1", inc.round_number == 1)
	inc.end_turn()
	_check("back to Kess", inc.current_unit().display_name == "Kess")
	_check("now round 2", inc.round_number == 2, "got %d" % inc.round_number)
