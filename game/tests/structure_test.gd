## Headless proof of the structural connection graph.
## Run:  godot --headless --path game --script res://tests/structure_test.gd
extends SceneTree

var _failures: int = 0

func _check(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("  PASS  ", label)
	else:
		_failures += 1
		print("  FAIL  ", label, "  ", detail)

## A gantry bay. The corroded bracket under the walkway is the interesting part.
##
##   crate  --resting-->  walkway  --CORRODED-->  beam  --welded-->  column  --bolted-->  footing
func _bay() -> Structure:
	var s := Structure.new()
	s.add_member(&"footing", "the footing", 0.0, 10000.0, true)
	s.add_member(&"column", "the column", 200.0, 2000.0)
	s.add_member(&"beam", "the main beam", 150.0, 800.0)
	s.add_member(&"walkway", "the walkway", 100.0, 900.0)
	s.add_member(&"crate", "the feedstock crate", 300.0, 500.0)
	s.connect_members(&"column", &"footing", 3000.0, "bolted")
	s.connect_members(&"beam", &"column", 900.0, "welded")
	s.connect_members(&"walkway", &"beam", 450.0, "corroded")
	s.connect_members(&"crate", &"walkway", 600.0, "resting")
	s.solve()
	return s

func _initialize() -> void:
	print("\n=== Structural connection graph ===\n")
	_test_load_reaches_ground()
	_test_load_splits_between_supports()
	_test_good_anchor_holds()
	_test_failure_names_the_joint_not_the_beam()
	_test_gravitic_makes_a_failing_anchor_hold()
	_test_transmutative_repair_makes_it_hold()
	_test_severing_drops_everything_above()
	_test_cycle_is_reported_as_authoring_error()
	print("\n=== %s ===\n" % ("ALL PASS" if _failures == 0 else "%d FAILURE(S)" % _failures))
	quit(1 if _failures > 0 else 0)


func _test_load_reaches_ground() -> void:
	print("1. Load propagates down to ground")
	var s := _bay()
	_check("crate carries only itself", is_equal_approx(s.member(&"crate").load, 300.0))
	_check("walkway carries crate too", is_equal_approx(s.member(&"walkway").load, 400.0),
		"got %f" % s.member(&"walkway").load)
	_check("beam carries walkway stack", is_equal_approx(s.member(&"beam").load, 550.0),
		"got %f" % s.member(&"beam").load)
	_check("footing carries everything", is_equal_approx(s.member(&"footing").load, 750.0),
		"got %f" % s.member(&"footing").load)
	_check("nothing is unsupported", s.unsupported().is_empty())


func _test_load_splits_between_supports() -> void:
	print("2. Two supports each carry half")
	var s := Structure.new()
	s.add_member(&"slab", "the slab", 0.0, 9999.0, true)
	s.add_member(&"left", "the left bracket", 0.0, 500.0)
	s.add_member(&"right", "the right bracket", 0.0, 500.0)
	s.add_member(&"plate", "the floor plate", 400.0, 900.0)
	s.connect_members(&"left", &"slab", 9999.0)
	s.connect_members(&"right", &"slab", 9999.0)
	s.connect_members(&"plate", &"left", 500.0)
	s.connect_members(&"plate", &"right", 500.0)
	s.solve()
	_check("left takes 200", is_equal_approx(s.member(&"left").load, 200.0), "got %f" % s.member(&"left").load)
	_check("right takes 200", is_equal_approx(s.member(&"right").load, 200.0))


func _test_good_anchor_holds() -> void:
	print("3. A sound anchor holds, and says how close it is")
	var s := _bay()
	var r: Dictionary = s.anchor_report(&"beam", 100.0)
	_check("holds", r["holds"], str(r))
	_check("reason names the member", r["reason"].contains("main beam"))
	_check("no failing element", r["failing_element"] == "")
	print("        \"%s\"" % r["reason"])


func _test_failure_names_the_joint_not_the_beam() -> void:
	print("4. The corroded joint fails, and the game says so by name")
	var s := _bay()
	var r: Dictionary = s.anchor_report(&"walkway", 100.0)
	_check("does not hold", not r["holds"])
	_check("blames the corroded joint", r["failing_element"].contains("corroded"), str(r))
	_check("does not blame the walkway member itself", r["failing_element"] != "the walkway", r["failing_element"])
	_check("states prior utilisation", r["reason"].contains("before you push"))
	# The bug this guards: the "before" figure was read off the post-push probe,
	# so it reported the pushed value twice and told the player the joint was
	# already failing when their own push is what broke it.
	_check("before figure is the REAL pre-push one", is_equal_approx(r["failing_utilisation_before"], 400.0 / 450.0),
		"got %f, expected %f" % [r["failing_utilisation_before"], 400.0 / 450.0])
	_check("after figure is the pushed one", is_equal_approx(r["failing_utilisation_after"], 500.0 / 450.0),
		"got %f" % r["failing_utilisation_after"])
	_check("before and after actually differ", not is_equal_approx(r["failing_utilisation_before"], r["failing_utilisation_after"]))
	_check("reason quotes 89% as the prior state, not 111%", r["reason"].contains("89% before"), r["reason"])
	print("        \"%s\"" % r["reason"])


func _test_gravitic_makes_a_failing_anchor_hold() -> void:
	print("5. Gravitic reduces the load, and the same anchor now holds")
	var s := _bay()
	_check("fails at normal gravity", not s.anchor_report(&"walkway", 100.0)["holds"])
	s.set_gravity_factor([&"crate"], 0.5)
	_check("crate mass unchanged", is_equal_approx(s.member(&"crate").mass, 300.0))
	_check("crate load halved", is_equal_approx(s.member(&"crate").load, 150.0),
		"got %f" % s.member(&"crate").load)
	var r: Dictionary = s.anchor_report(&"walkway", 100.0)
	_check("anchor now holds", r["holds"], str(r))
	print("        \"%s\"" % r["reason"])


func _test_transmutative_repair_makes_it_hold() -> void:
	print("6. Transmutative repair of the seam does the same job differently")
	var s := _bay()
	_check("fails before repair", not s.anchor_report(&"walkway", 100.0)["holds"])
	s.reinforce(&"walkway", &"beam", 300.0)
	var r: Dictionary = s.anchor_report(&"walkway", 100.0)
	_check("holds after repair", r["holds"], str(r))
	_check("joint no longer reads corroded", s.connection_between(&"walkway", &"beam").kind == "repaired")
	print("        \"%s\"" % r["reason"])


func _test_severing_drops_everything_above() -> void:
	print("7. Cutting a connection drops everything it was carrying")
	var s := _bay()
	var falling: Array[String] = s.sever(&"walkway", &"beam")
	_check("two things fall", falling.size() == 2, str(falling))
	_check("the walkway falls", falling.has("the walkway"))
	_check("the crate on it falls too", falling.has("the feedstock crate"))
	_check("the beam does not", not falling.has("the main beam"))
	print("        falling: %s" % str(falling))


func _test_cycle_is_reported_as_authoring_error() -> void:
	print("8. A cycle is an authoring bug, reported not swallowed")
	var s := Structure.new()
	s.add_member(&"a", "member A", 10.0, 100.0)
	s.add_member(&"b", "member B", 10.0, 100.0)
	s.connect_members(&"a", &"b", 100.0)
	s.connect_members(&"b", &"a", 100.0)
	_check("solve returns false", not s.solve())
	_check("error mentions the cycle", s.last_error().contains("cycle"), s.last_error())
	print("        \"%s\"" % s.last_error())
