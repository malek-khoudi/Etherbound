## J10-01 / J10-03 regressions: physics decides the outcome, never a checklist.
## Run:  ./tools/test.sh
extends SceneTree

var _failures: int = 0

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("  PASS  ", label)
	else:
		_failures += 1
		print("  FAIL  ", label, "  ", detail)

func _bay() -> Structure:
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

func _eb(kind: Affinity.Kind, reserve: float) -> Etherbound:
	var e := Etherbound.new(kind)
	e.reserve_max = reserve
	e.reserve = reserve
	e.throughput_max = 10.0
	return e

func _incident() -> Incident:
	var inc := Incident.new(_bay())
	inc.set_objective(&"walkway", 3)
	return inc

func _initialize() -> void:
	print("\n=== J10-01/03: outcome comes from physics ===\n")
	_test_doing_nothing_fails()
	_test_gravitic_alone_succeeds()
	_test_prop_alone_endures()
	_test_exhaustion_loses_it_at_the_last_moment()
	_test_all_four_actions_do_not_instantly_win()
	_test_transmutative_front_progresses_and_persists()
	_test_dropped_front_reverts()
	print("\n=== %s ===\n" % ("ALL PASS" if _failures == 0 else "%d FAILURE(S)" % _failures))
	quit(1 if _failures > 0 else 0)


func _test_doing_nothing_fails() -> void:
	print("1. Nobody acts, so it comes down")
	var inc := _incident()
	inc.end_round()
	_check("failed", inc.outcome()["failed"])
	_check("not resolved", not inc.outcome()["resolved"])


func _test_gravitic_alone_succeeds() -> void:
	print("2. Gravitic ALONE succeeds. The old checklist failed this.")
	var inc := _incident()
	var vess := Unit.new("Vess", _eb(Affinity.Kind.GRAVITIC, 150.0))
	inc.add_unit(vess)
	_check("lighten accepted", inc.lighten(vess, [&"walkway", &"crate"], 0.55, 5.0), inc.last_refusal())
	_check("load now 220, under the 350 bracket", is_equal_approx(inc.structure.member(&"walkway").load, 220.0),
		"got %f" % inc.structure.member(&"walkway").load)
	_check("path is standing", inc.path_is_standing())
	for i in 3:
		inc.end_round()
	var o: Dictionary = inc.outcome()
	_check("resolved on physics alone", o["resolved"], str(o))
	_check("no Kinetic, no worker, no Transmutative needed", true)
	print("        \"%s\"" % o["reason"])


func _test_prop_alone_endures() -> void:
	print("3. A worker's prop alone endures indefinitely")
	var inc := _incident()
	var maren := Unit.new("Maren")
	inc.add_unit(maren)
	inc.prop(maren, &"walkway", 150.0)
	for i in 8:
		inc.end_round()
	var o: Dictionary = inc.outcome()
	_check("resolved", o["resolved"], str(o))
	_check("never failed across 8 rounds", not o["failed"])


func _test_exhaustion_loses_it_at_the_last_moment() -> void:
	print("4. Kinetic alone runs out one round short")
	var inc := _incident()
	var kess := Unit.new("Kess", _eb(Affinity.Kind.KINETIC, 150.0))
	inc.add_unit(kess)
	inc.brace(kess, &"walkway", 150.0, 10.0)
	_check("sustains 2 rounds", inc.rounds_sustainable(kess) == 2, "got %d" % inc.rounds_sustainable(kess))

	inc.end_round()
	_check("round 1 progresses", inc.extraction_rounds_done == 1)
	inc.end_round()
	_check("round 2 progresses", inc.extraction_rounds_done == 2)
	var events: Array[String] = inc.end_round()
	_check("round 3 loses it", inc.outcome()["failed"], str(events))
	_check("one round short of the objective", inc.extraction_rounds_done == 2)
	for e in events:
		print("        %s" % e)


func _test_all_four_actions_do_not_instantly_win() -> void:
	print("5. All four roles acting does NOT resolve the incident")
	var inc := _incident()
	var kess := Unit.new("Kess", _eb(Affinity.Kind.KINETIC, 500.0))
	var vess := Unit.new("Vess", _eb(Affinity.Kind.GRAVITIC, 500.0))
	var tarn := Unit.new("Tarn", _eb(Affinity.Kind.TRANSMUTATIVE, 500.0))
	var maren := Unit.new("Maren")
	for u in [kess, vess, tarn, maren]:
		inc.add_unit(u)

	inc.brace(kess, &"walkway", 100.0, 6.0)
	inc.lighten(vess, [&"crate"], 0.7, 5.0)
	inc.reshape(tarn, &"walkway", &"beam", 200.0, 2, 6.0)
	inc.prop(maren, &"walkway", 50.0)

	inc.end_round()
	var o: Dictionary = inc.outcome()
	_check("still not resolved after one round", not o["resolved"], str(o))
	_check("still not failed", not o["failed"])
	_check("extraction is what remains", o["reason"].contains("Extraction"), str(o))
	inc.end_round()
	inc.end_round()
	_check("resolves only when the WORK is done", inc.outcome()["resolved"])
	print("        \"%s\"" % o["reason"])


func _test_transmutative_front_progresses_and_persists() -> void:
	print("6. A Transmutative front is maintained, then permanent")
	var inc := _incident()
	var tarn := Unit.new("Tarn", _eb(Affinity.Kind.TRANSMUTATIVE, 500.0))
	var maren := Unit.new("Maren")
	inc.add_unit(tarn)
	inc.add_unit(maren)
	inc.prop(maren, &"walkway", 150.0)
	inc.reshape(tarn, &"walkway", &"beam", 200.0, 2, 6.0)

	var joint := inc.structure.connection_between(&"walkway", &"beam")
	_check("no capacity before the front progresses", is_equal_approx(joint.capacity, 350.0))
	inc.end_round()
	_check("half worked, half the capacity", is_equal_approx(joint.capacity, 450.0), "got %f" % joint.capacity)
	inc.end_round()
	_check("complete, full capacity", is_equal_approx(joint.capacity, 550.0), "got %f" % joint.capacity)
	_check("joint now reads repaired", joint.kind == "repaired")
	_check("Tarn is free again", tarn.etherbound.commitments().is_empty())
	_check("Tarn stopped spending", tarn.etherbound.throughput_used() == 0.0)


func _test_dropped_front_reverts() -> void:
	print("7. A front dropped early reverts. Half a repair is not a repair.")
	var inc := _incident()
	var tarn := Unit.new("Tarn", _eb(Affinity.Kind.TRANSMUTATIVE, 100.0))
	var maren := Unit.new("Maren")
	inc.add_unit(tarn)
	inc.add_unit(maren)
	inc.prop(maren, &"walkway", 150.0)
	inc.reshape(tarn, &"walkway", &"beam", 200.0, 3, 10.0)

	var joint := inc.structure.connection_between(&"walkway", &"beam")
	inc.end_round()
	_check("one third worked", is_equal_approx(joint.capacity, 350.0 + 200.0 / 3.0), "got %f" % joint.capacity)
	inc.end_round()
	_check("reserve gone, capacity reverted", is_equal_approx(joint.capacity, 350.0), "got %f" % joint.capacity)
	_check("prop still carries it", inc.path_is_standing())
