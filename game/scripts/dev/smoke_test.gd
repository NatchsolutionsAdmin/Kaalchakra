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
	_ok("Eva is in the \"player\" group", player != null)
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

	print("\n-- she actually moves --")
	TimeShift.request_shift(Era.Id.PRESENT)
	await _settle(4)
	player.global_position = Vector3(-10, 1.0, -26)
	player.velocity = Vector3.ZERO
	await _settle(20)
	var before := player.global_position
	Input.action_press("move_forward")
	await _settle(45)
	Input.action_release("move_forward")
	var walked := before.distance_to(player.global_position)
	_ok("holding W walks her", walked > 1.5, "moved %.2f m" % walked)

	player.velocity = Vector3.ZERO
	await _settle(20)
	var standing := player.global_position.y
	Input.action_press("jump")
	await _settle(2)
	Input.action_release("jump")
	await _settle(8)
	_ok("Space gets her off the ground", player.global_position.y > standing + 0.4,
		"y %.2f -> %.2f" % [standing, player.global_position.y])
	await _settle(40)

	print("\n-- jumping next to a step stays a jump --")
	# The bug: the pull-up used to fire on any ground jump near a 1.4 m step
	# and slide her somewhere she never aimed for.
	var model := player.get("model") as Node3D
	var pivot := player.get("cam_pivot") as Node3D
	pivot.rotation.y = PI
	player.global_position = Vector3(8.5, 0.1, -22.0)
	player.velocity = Vector3.ZERO
	player.set("_facing", PI)
	model.rotation.y = PI
	await _settle(25)
	var start_at := player.global_position
	Input.action_press("jump")
	await _settle(2)
	Input.action_release("jump")
	await _settle(60)
	var drift := Vector2(player.global_position.x - start_at.x, player.global_position.z - start_at.z).length()
	_ok("a standing jump beside a ledge lands her back where she started",
		drift < 0.4 and absf(player.global_position.y - start_at.y) < 0.4,
		"drifted %.2f m, y %.2f -> %.2f" % [drift, start_at.y, player.global_position.y])

	print("\n-- the ledge climb --")
	# 1.1 m: a plain jump should carry her up, no pull-up needed.
	player.global_position = Vector3(8.5, 0.1, -23.0)
	player.velocity = Vector3.ZERO
	await _settle(20)
	Input.action_press("move_forward")
	await _settle(10)
	Input.action_press("jump")
	await _settle(3)
	Input.action_release("jump")
	await _settle(55)
	Input.action_release("move_forward")
	await _settle(20)
	_ok("she jumps the 1.1 m step unaided", player.global_position.y > 0.9,
		"y = %.2f" % player.global_position.y)

	# 1.8 m: above her jump, so this can only happen by pulling up.
	player.global_position = Vector3(8.5, 1.15, -19.6)
	player.velocity = Vector3.ZERO
	player.set("_facing", PI)
	model.rotation.y = PI
	await _settle(25)
	var below := player.global_position.y
	Input.action_press("move_forward")
	await _settle(8)
	Input.action_press("jump")
	await _settle(3)
	Input.action_release("jump")
	await _settle(70)
	Input.action_release("move_forward")
	await _settle(20)
	_ok("she pulls up onto the 1.8 m ledge she cannot jump",
		player.global_position.y > below + 1.5,
		"y %.2f -> %.2f" % [below, player.global_position.y])

	print("\n-- the reservoir steps, with thumbs --")
	# Risers are 0.58 m now, under auto_step_height, so walking up the flight
	# must need no jump at all. A phone player should never tap jump on stairs.
	pivot.rotation.y = 0.0
	player.set("_facing", 0.0)
	model.rotation.y = 0.0
	player.global_position = Vector3(0, -3.4, -17.9)
	player.velocity = Vector3.ZERO
	await _settle(30)
	var bottom := player.global_position.y
	Input.action_press("move_forward")
	await _settle(90)
	Input.action_release("move_forward")
	await _settle(20)
	var gained := player.global_position.y - bottom
	_ok("she walks up the stairs without jumping", gained > 1.0,
		"gained %.2f m (y %.2f -> %.2f)" % [gained, bottom, player.global_position.y])

	print("\n-- the virtual joystick --")
	# The joystick feeds the same path as WASD, through the Touch autoload.
	TimeShift.request_shift(Era.Id.PRESENT)
	await _settle(4)
	player.global_position = Vector3(-10, 1.0, -26)
	player.velocity = Vector3.ZERO
	await _settle(25)
	var stick_from := player.global_position
	Touch.move = Vector2(0, -1)
	await _settle(45)
	Touch.move = Vector2.ZERO
	var stick_moved := stick_from.distance_to(player.global_position)
	_ok("pushing the stick forward walks her", stick_moved > 1.5,
		"moved %.2f m" % stick_moved)

	player.velocity = Vector3.ZERO
	await _settle(25)
	var before_tap := player.global_position.y
	Touch.queue_jump()
	await _settle(10)
	_ok("the jump button gets her off the ground",
		player.global_position.y > before_tap + 0.4,
		"y %.2f -> %.2f" % [before_tap, player.global_position.y])
	await _settle(45)

	print("\n-- era lighting --")
	# This section leaves the world in FUTURE; the sections after it rely on that.
	TimeShift.request_shift(Era.Id.FUTURE)
	await _settle(4)
	var lighting := _main.get_node("EraLighting")
	var sun := lighting.get("sun") as DirectionalLight3D
	var env := lighting.get("world_env") as WorldEnvironment
	_ok("lighting found the sun", sun != null)
	_ok("lighting found the environment", env != null)
	# Era.TINT is the UI tint; the lighting has its own richer table.
	var look: Dictionary = load("res://scripts/world/era_lighting.gd").LOOK
	if sun != null:
		_ok("the sun is lit for 2087",
			sun.light_color.is_equal_approx(look[Era.Id.FUTURE]["sun_color"]),
			"got %s" % sun.light_color)
		_ok("2087 is overcast — the key light is weak",
			sun.light_energy < 1.0, "energy %.2f" % sun.light_energy)
		TimeShift.request_shift(Era.Id.PAST)
		await _settle(4)
		_ok("and relights for 1900 BCE",
			sun.light_color.is_equal_approx(look[Era.Id.PAST]["sun_color"]),
			"got %s" % sun.light_color)
		_ok("1900 BCE has a low morning sun", sun.rotation_degrees.x > -25.0,
			"pitch %.1f" % sun.rotation_degrees.x)
		TimeShift.request_shift(Era.Id.FUTURE)
		await _settle(4)
	var fill := lighting.get("fill") as DirectionalLight3D
	_ok("there is a fill light so shadows are not black", fill != null and fill.light_energy > 0.0)
	_ok("the fill casts no shadow of its own", fill != null and not fill.shadow_enabled)
	_ok("the colour grade is on", env != null and env.environment.adjustment_enabled)

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
