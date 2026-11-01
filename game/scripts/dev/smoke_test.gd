## Dev smoke test — drives the prototype's systems with no human in the loop.
##
## Not part of the game. Run it before committing:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
##       scenes/dev/SmokeTest.tscn
extends Node

const MAIN := "res://scenes/Main.tscn"

var _fail := 0
var _main: Node


func _ready() -> void:
	_main = load(MAIN).instantiate()
	add_child(_main)
	# Deterministic: skips the fade tween so shifts complete inside one call.
	TimeShift.reduced_motion = true
	await get_tree().physics_frame
	await _run()
	print("")
	if _fail == 0:
		print("SMOKE TEST PASSED")
	else:
		print("SMOKE TEST FAILED — %d problem(s)" % _fail)
	get_tree().quit(1 if _fail > 0 else 0)


func _ok(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_fail += 1
		print("  FAIL  %s   %s" % [label, detail])


func _settle(frames: int = 20) -> void:
	for _i in frames:
		await get_tree().physics_frame


func _era_node(name: String) -> EraRoot:
	return _main.get_node("NorthGate/" + name) as EraRoot


func _run() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	_ok("Evara is in the \"player\" group", player != null)
	if player == null:
		return

	print("\n-- starting state --")
	_ok("starts in 2026", TimeShift.current_era == Era.Id.PRESENT)
	_ok("collision mask = shared + present", player.collision_mask == (1 | 4),
		"got %d" % player.collision_mask)
	_ok("Present era is visible", _era_node("Present").visible)
	_ok("Past era is hidden", not _era_node("Past").visible)
	_ok("Future era is hidden", not _era_node("Future").visible)

	await _settle(40)
	_ok("she lands on the apron instead of falling through",
		player.global_position.y > -1.0 and player.global_position.y < 2.0,
		"y = %.2f" % player.global_position.y)
	_ok("she is still near the spawn point",
		player.global_position.distance_to(Vector3(0, 0, -26)) < 3.0,
		"at %v" % player.global_position)

	print("\n-- the dig site, before she knows anything --")
	var dig := _main.get_node("NorthGate/Present/DigSite") as Interactable
	var hatch := _main.get_node("NorthGate/Present/ChamberHatch") as Node3D
	_ok("dig site belongs to 2026", dig.era == Era.Id.PRESENT)
	_ok("nothing is known yet", not TimeShift.knows("keeper_mark"))
	_ok("so it offers only a probe, not a dig", dig.hold_seconds() == 0.0)
	_ok("prompt reads \"Probe the silt\"", dig.prompt_text() == "Probe the silt",
		dig.prompt_text())
	dig.press(player)
	_ok("probing teaches her nothing", not TimeShift.knows("chamber_opened"))
	_ok("the chamber is still sealed", not hatch.visible)

	print("\n-- shift to 1900 BCE --")
	_ok("the Wheel turns", TimeShift.request_shift(Era.Id.PAST))
	await _settle(4)
	_ok("era is PAST", TimeShift.current_era == Era.Id.PAST)
	_ok("collision mask = shared + past", player.collision_mask == (1 | 2),
		"got %d" % player.collision_mask)
	_ok("Past era is visible", _era_node("Past").visible)
	_ok("Present era is hidden", not _era_node("Present").visible)
	_ok("camera arm follows the live era",
		(player.get_node("CameraPivot/SpringArm3D") as SpringArm3D).collision_mask == (1 | 2))
	_ok("the gate rubble only exists in 2026",
		_main.get_node_or_null("NorthGate/Present/GateRubble") != null
		and _main.get_node_or_null("NorthGate/Past/GateRubble") == null)
	_ok("the reservoir only holds water in the past",
		_main.get_node_or_null("NorthGate/Past/WaterOneThird") != null
		and _main.get_node_or_null("NorthGate/Present/WaterOneThird") == null)
	_ok("the signboard has all ten signs in 1900 BCE",
		_main.get_node_or_null("NorthGate/Past/Sign9") != null
		and _main.get_node_or_null("NorthGate/Present/Sign9") == null)

	print("\n-- read the Keeper's mark --")
	var mark := _main.get_node("NorthGate/Past/KeeperMark") as Interactable
	_ok("the mark belongs to 1900 BCE", mark.era == Era.Id.PAST)
	mark.press(player)
	_ok("she now knows where the chamber is", TimeShift.knows("keeper_mark"))

	print("\n-- back to 2026 and dig --")
	_ok("the Wheel turns", TimeShift.request_shift(Era.Id.PRESENT))
	await _settle(4)
	_ok("era is PRESENT", TimeShift.current_era == Era.Id.PRESENT)
	_ok("the same patch of silt is now a dig", dig.hold_seconds() > 0.0)
	_ok("prompt reads \"Excavate\"", dig.prompt_text() == "Excavate", dig.prompt_text())
	dig.hold(player, 0.5)
	_ok("half a second of digging is not enough", not TimeShift.knows("chamber_opened"))
	dig.hold(player, 3.0)
	_ok("holding long enough opens the chamber", TimeShift.knows("chamber_opened"))
	_ok("the dig site is wired to the chamber hatch", dig.get("reveal") == hatch,
		"reveal = %s" % str(dig.get("reveal")))
	_ok("the chamber is revealed", hatch.visible)
	_ok("a finished dig stops offering itself", not dig.is_available())

	print("\n-- shift to 2087 --")
	_ok("the Wheel turns", TimeShift.request_shift(Era.Id.FUTURE))
	await _settle(4)
	_ok("collision mask = shared + future", player.collision_mask == (1 | 8),
		"got %d" % player.collision_mask)
	_ok("Future era is visible", _era_node("Future").visible)
	_ok("the site is flooded in 2087",
		_main.get_node_or_null("NorthGate/Future/FloodPlane") != null)
	var warden := _main.get_node("NorthGate/Future/WardenNode") as Interactable
	_ok("WARDEN belongs to 2087", warden.era == Era.Id.FUTURE)

	print("\n-- era lighting --")
	var lighting := _main.get_node("EraLighting")
	var sun := lighting.get("sun") as DirectionalLight3D
	var env := lighting.get("world_env") as WorldEnvironment
	_ok("lighting found the sun", sun != null)
	_ok("lighting found the environment", env != null)
	if sun != null:
		_ok("the sun is tinted for 2087", sun.light_color.is_equal_approx(Era.TINT[Era.Id.FUTURE]),
			"got %s" % sun.light_color)
		TimeShift.request_shift(Era.Id.PAST)
		await _settle(4)
		_ok("and retints for 1900 BCE", sun.light_color.is_equal_approx(Era.TINT[Era.Id.PAST]),
			"got %s" % sun.light_color)
		TimeShift.request_shift(Era.Id.FUTURE)
		await _settle(4)

	print("\n-- the rules --")
	_ok("shifting to the era you are already in is a no-op",
		not TimeShift.request_shift(Era.Id.FUTURE))
	TimeShift.unlocked[Era.Id.PAST] = false
	_ok("a locked era refuses the shift", not TimeShift.request_shift(Era.Id.PAST))
	_ok("and the era did not change", TimeShift.current_era == Era.Id.FUTURE)
	TimeShift.unlocked[Era.Id.PAST] = true

	print("\n-- the fade transition (reduced motion off) --")
	TimeShift.reduced_motion = false
	TimeShift.request_shift(Era.Id.PAST)
	_ok("a shift in progress is flagged", TimeShift.is_shifting())
	await _settle(50)
	_ok("the shift finishes", not TimeShift.is_shifting())
	_ok("and it landed in PAST", TimeShift.current_era == Era.Id.PAST)

	print("\n-- the safety net --")
	player.global_position = Vector3(0, -200, -26)
	await _settle(6)
	_ok("falling out of the world respawns her",
		player.global_position.y > -10.0, "y = %.2f" % player.global_position.y)
