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


## Camera targets a script names but the level does not provide. This is the
## check that stops a writer's shot silently doing nothing.
func _missing_markers(chunks: Dictionary) -> Array[String]:
	var have: Array[String] = []
	for node: Node in get_tree().get_nodes_in_group("camera_target"):
		have.append(node.name)
	var absent: Array[String] = []
	for name: String in chunks:
		for step: Dictionary in chunks[name]:
			if step["type"] != "directive" or step["name"] != "camera":
				continue
			var args: Array = step["args"]
			if args.size() < 2:
				continue
			if args[1] not in have and args[1] not in absent:
				absent.append(args[1])
	return absent


## Every bit of progress the world is capable of handing out: flags from
## trigger volumes, and knowledge from anything you can interact with.
func _producible_progress() -> Array[String]:
	var out: Array[String] = []
	_collect_progress(_main, out)
	return out


func _collect_progress(node: Node, out: Array[String]) -> void:
	if node is StoryTrigger:
		var flag: String = (node as StoryTrigger).flag
		if flag.is_empty():
			flag = node.name
		if flag not in out:
			out.append(flag)
	elif node is Interactable:
		var granted: Variant = node.get("grants_knowledge")
		if granted is String and not (granted as String).is_empty() and granted not in out:
			out.append(granted)
	for child: Node in node.get_children():
		_collect_progress(child, out)


## Walks res://scripts and loads every .gd. A script that fails to parse
## returns null here instead of silently doing nothing at runtime.
func _compile_all(dir_path: String, broken: Array[String]) -> int:
	var count := 0
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			count += _compile_all(full, broken)
		elif entry.ends_with(".gd"):
			count += 1
			if load(full) == null:
				broken.append(full)
		entry = dir.get_next()
	dir.list_dir_end()
	return count


func _count_lines(chunks: Dictionary) -> int:
	var n := 0
	for name: String in chunks:
		for step: Dictionary in chunks[name]:
			if step["type"] == "line":
				n += 1
	return n


## Plays a scene to the end with no human: takes `pick` at every branch, and
## at every handover stands in for the player doing whatever it waits on.
func _walk_dialogue(pick: int, limit: int = 600) -> Dictionary:
	var lines := 0
	var choices := 0
	var handovers := 0
	for _guard in limit:
		if Dialogue.is_active():
			if not Dialogue.pending_choices.is_empty():
				Dialogue.choose(mini(pick, Dialogue.pending_choices.size() - 1))
				choices += 1
			else:
				Dialogue.advance()
				lines += 1
			continue
		var flag := Dialogue.waiting_for()
		if flag.is_empty():
			break
		Story.set_flag(flag)
		handovers += 1
		await get_tree().process_frame
		await get_tree().process_frame
	return {"lines": lines, "choices": choices, "handovers": handovers}


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
	var door := _main.get_node("NorthGate/Present/SealedDoor") as StaticBody3D
	_ok("dig site belongs to 2026", dig.era == Era.Id.PRESENT)
	_ok("nothing is known yet", not TimeShift.knows("keeper_mark"))
	_ok("so it offers only a probe, not a dig", dig.hold_seconds() == 0.0)
	_ok("prompt reads \"Probe the silt\"", dig.prompt_text() == "Probe the silt",
		dig.prompt_text())
	dig.press(player)
	_ok("probing teaches her nothing", not TimeShift.knows("chamber_opened"))
	_ok("the chamber is still sealed", door.visible and door.collision_layer != 0)

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
	_ok("the dig site is wired to the sealed door", dig.get("remove") == door,
		"remove = %s" % str(dig.get("remove")))
	_ok("the door is gone once dug", not door.visible)
	_ok("and the doorway is actually walkable, not just invisible",
		door.collision_layer == 0, "layer still %d" % door.collision_layer)
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

	print("\n-- running without a run button --")
	# A phone has no Shift. The stick is analogue instead: nudge it and she
	# walks, push it to the edge and she runs.
	# Out on open ground facing south: at a run she covers over five metres in
	# the measuring window, and the city walls would otherwise stop her short
	# and make a run look like a walk.
	pivot.rotation.y = PI
	player.set("_facing", PI)
	model.rotation.y = PI
	var paces: Array[float] = []
	for push: float in [0.45, 1.0]:
		player.global_position = Vector3(34, 1.0, -14)
		player.velocity = Vector3.ZERO
		Touch.move = Vector2.ZERO
		await _settle(25)
		var from := player.global_position
		Touch.move = Vector2(0, -push)
		await _settle(50)
		paces.append(from.distance_to(player.global_position))
		Touch.move = Vector2.ZERO
		await _settle(10)
	_ok("a gentle push walks her", paces[0] > 1.0, "%.2f m" % paces[0])
	_ok("pushing it to the edge runs her", paces[1] > paces[0] * 1.4,
		"%.2f m walking vs %.2f m running" % [paces[0], paces[1]])

	player.global_position = Vector3(-10, 1.0, -26)
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
	TimeShift.reduced_motion = true

	print("\n-- the chamber, in three eras --")
	for probe: Array in [
		["Past", "TabletStack", "1900 BCE: in use, and empty — the Keeper is not born yet"],
		["Present", "TheWheel", "2026: the skeleton, hands cupped around the Wheel"],
		["Future", "ChamberSilt", "2087: silted and drowned"],
	]:
		_ok("  %s" % probe[2],
			_main.get_node_or_null("NorthGate/%s/%s" % [probe[0], probe[1]]) != null)
	_ok("the manifest wall is in all three eras",
		_main.get_node_or_null("NorthGate/Past/ManifestSign00") != null
		and _main.get_node_or_null("NorthGate/Present/ManifestSign00") != null
		and _main.get_node_or_null("NorthGate/Future/ManifestSign00") != null)
	_ok("only 2026 has a door bricked across it",
		_main.get_node_or_null("NorthGate/Past/SealedDoor") == null
		and _main.get_node_or_null("NorthGate/Future/SealedDoor") == null)

	print("\n-- the sign index --")
	_ok("the sign file parses with no errors", Decipher.errors.is_empty(),
		"\n        " + "\n        ".join(Decipher.errors))
	_ok("there are signs in it", Decipher.order.size() >= 4,
		"%d signs" % Decipher.order.size())
	var incomplete: Array[String] = []
	for id: String in Decipher.order:
		for need: String in ["learn", "match", "confirm"]:
			if String(Decipher.signs[id].get(need, "")).is_empty():
				incomplete.append("%s/%s" % [id, need])
	_ok("every sign is written for all three eras", incomplete.is_empty(),
		", ".join(incomplete))
	_ok("the header has words in it", Decipher.header_signs().size() >= 2,
		"%d" % Decipher.header_signs().size())

	print("\n-- a sign can only be read in the right morning --")
	Decipher.reset()
	var sign_id: String = Decipher.header_signs()[0]
	_ok("it starts unknown", Decipher.step_of(sign_id) == Decipher.Step.UNKNOWN)
	_ok("it cannot be learned in 2026", Decipher.advance(sign_id, Era.Id.PRESENT).is_empty())
	_ok("nor in 2087", Decipher.advance(sign_id, Era.Id.FUTURE).is_empty())
	_ok("and the game says why, rather than nothing happening",
		not Decipher.blocked_reason(sign_id, Era.Id.PRESENT).is_empty())
	_ok("learning it works in 1900 BCE",
		not Decipher.advance(sign_id, Era.Id.PAST).is_empty())
	_ok("now it cannot be learned twice", Decipher.advance(sign_id, Era.Id.PAST).is_empty())
	_ok("matching needs 2026", Decipher.advance(sign_id, Era.Id.FUTURE).is_empty()
		and not Decipher.advance(sign_id, Era.Id.PRESENT).is_empty())
	_ok("confirming needs 2087", Decipher.advance(sign_id, Era.Id.PAST).is_empty()
		and not Decipher.advance(sign_id, Era.Id.FUTURE).is_empty())
	_ok("and then it is done", Decipher.is_confirmed(sign_id))

	print("\n-- the header --")
	_ok("it is masked while words are missing", Decipher.header_text().contains("·"),
		Decipher.header_text())
	var announced := [false]
	Decipher.header_readable.connect(func() -> void: announced[0] = true, CONNECT_ONE_SHOT)
	for id: String in Decipher.header_signs():
		for era_step: Array in [[Era.Id.PAST], [Era.Id.PRESENT], [Era.Id.FUTURE]]:
			Decipher.advance(id, era_step[0])
	_ok("every header sign confirmed", Decipher.header_progress().x == Decipher.header_progress().y,
		"%d/%d" % [Decipher.header_progress().x, Decipher.header_progress().y])
	_ok("it reads WHAT THE WATER MUST NOT TAKE",
		Decipher.header_text() == "WHAT WATER MUST NOT TAKE", Decipher.header_text())
	_ok("and the game announces it once", announced[0])
	Decipher.reset()

	print("\n-- the same wall in three eras --")
	for era_name: String in ["Past", "Present", "Future"]:
		var found := 0
		for id: String in Decipher.order:
			if _main.get_node_or_null("NorthGate/%s/Sign_%s" % [era_name, id]) != null:
				found += 1
		_ok("  %s carries all %d signs" % [era_name, Decipher.order.size()],
			found == Decipher.order.size(), "%d found" % found)

	print("\n-- calling Ma --")
	Decipher.reset()
	Phone.reset()
	Story.reset()
	_ok("she cannot call before Sakshi is reachable", not Phone.can_call("sakshi"))
	Story.make_contact_available("sakshi")
	_ok("and can once she is", Phone.can_call("sakshi"))

	# Collect what is actually said.
	var said: Array[String] = []
	var heard := func(_who: String, text: String) -> void: said.append(text)
	Phone.line_spoken.connect(heard)

	TimeShift.request_shift(Era.Id.PRESENT)
	await _settle(4)
	_ok("the call connects", Phone.start("sakshi"))
	_ok("she cannot ring twice at once", not Phone.start("sakshi"))
	await _settle(80)
	for _i in 6:
		Phone.advance()
		await get_tree().process_frame
	_ok("Ma says something", said.size() >= 3, "%d lines" % said.size())
	_ok("and the call ends on its own", not Phone.in_call)

	# Nothing learned yet, so she should be sent to the only century that can
	# read it rather than given a sign-specific nudge about 2026.
	_ok("with nothing learned she is sent to 1900 BCE",
		"".join(said).to_lower().contains("century"), "\n        " + "\n        ".join(said))

	# Now learn one, and the advice should change to the era it needs next.
	said.clear()
	var learn_me: String = Decipher.order[0]
	Decipher.advance(learn_me, Era.Id.PAST)
	TimeShift.request_shift(Era.Id.FUTURE)
	await _settle(4)
	Phone.start("sakshi")
	await _settle(80)
	for _i in 6:
		Phone.advance()
		await get_tree().process_frame
	_ok("once a sign is learned she names the morning it needs",
		"".join(said).contains(Era.TITLE[Era.Id.PRESENT]),
		"\n        " + "\n        ".join(said))

	# Standing in the right era, she should say so instead.
	said.clear()
	TimeShift.request_shift(Era.Id.PRESENT)
	await _settle(4)
	Phone.start("sakshi")
	await _settle(80)
	for _i in 6:
		Phone.advance()
		await get_tree().process_frame
	_ok("standing in the right morning, she says so",
		"".join(said).to_lower().contains("right morning"),
		"\n        " + "\n        ".join(said))
	_ok("and she notices being asked twice",
		"".join(said).to_lower().contains("the same one"),
		"\n        " + "\n        ".join(said))

	Phone.line_spoken.disconnect(heard)
	Phone.reset()
	Decipher.reset()
	Story.reset()

	print("\n-- the Prologue script --")
	const PROLOGUE := "res://data/dialogue/prologue_overburden.dialogue"
	var parsed := DialogueParser.parse_file(PROLOGUE)
	var parse_errors: Array = parsed["errors"]
	_ok("the Prologue parses with no errors", parse_errors.is_empty(),
		"\n        " + "\n        ".join(parse_errors))
	_ok("it has a start chunk", parsed["chunks"].has("start"))
	print("        %d chunks, %d lines"
		% [parsed["chunks"].size(), _count_lines(parsed["chunks"])])

	# Walk it twice, down both sides of the first branch, and check the flags
	# the script promises actually land.
	var played: Dictionary = {}
	for path: Array in [[0, "invited Ishita down"], [2, "sent her away"]]:
		Story.reset()
		TimeShift.request_shift(Era.Id.PRESENT)
		await _settle(4)
		Dialogue.play_file(PROLOGUE)
		played = await _walk_dialogue(path[0])
		_ok("plays to the end — %s" % path[1],
			not Dialogue.is_active() and not Dialogue.is_waiting(),
			"stalled after %d lines" % played["lines"])
		_ok("  reached the chamber", Story.has_flag("saw_the_index"))
		_ok("  excavation was unlocked", Story.has_skill("excavation"))
		_ok("  Sakshi became callable", Story.has_contact("sakshi"))
		_ok("  it ends in 1900 BCE", TimeShift.current_era == Era.Id.PAST,
			"ended in %s" % Era.SHORT[TimeShift.current_era])
		print("        %d lines, %d choices, %d handovers"
			% [played["lines"], played["choices"], played["handovers"]])

	# Ishita only speaks at the door if she was invited down.
	Story.reset()
	Story.set_flag("ishita_present_at_discovery")
	Dialogue.play_file(PROLOGUE, "the_lintel")
	var with_her := await _walk_dialogue(0)
	Story.reset()
	Dialogue.play_file(PROLOGUE, "the_lintel")
	var without_her := await _walk_dialogue(0)
	_ok("Ishita's lines appear only when she came down",
		with_her["lines"] > without_her["lines"],
		"%d vs %d lines" % [with_her["lines"], without_her["lines"]])

	# Capture this before the audio tests below clear the list.
	var wanted_audio: Array = Audio.missing()

	print("\n-- audio --")
	for bus: String in ["Music", "SFX", "Voice"]:
		_ok("there is a %s bus" % bus, AudioServer.get_bus_index(bus) != -1)
	Audio.clear_missing()
	_ok("a cue with no file is silent, not a crash", not Audio.play_music("nothing_here"))
	_ok("and it is recorded as missing", Audio.missing().size() == 1, str(Audio.missing()))
	_ok("\"silence\" stops the music rather than looking for a file",
		Audio.play_music("silence"))
	_ok("a line with no recording is silent, not a crash",
		not Audio.play_voice("prologue_overburden", "no_such_line_99"))
	# True only while the local placeholder audio exists; it is git-ignored, so
	# a fresh clone will not have it and this is reported, not failed.
	if Audio.play_voice("prologue_overburden", "start_01"):
		print("  ok    scratch voice is installed locally and plays")
		Audio.stop_voice()
	else:
		print("  --    no local scratch voice (run tools/scratch_vo.py to hear the script)")

	print("\n-- voice-line ids --")
	var ids: Dictionary = {}
	var blank := 0
	for chunk: String in parsed["chunks"]:
		for step: Dictionary in parsed["chunks"][chunk]:
			if step["type"] != "line":
				continue
			var id: String = step.get("id", "")
			if id.is_empty():
				blank += 1
			ids[id] = int(ids.get(id, 0)) + 1
	var duped := 0
	for id: String in ids:
		if ids[id] > 1:
			duped += 1
	_ok("every line has an id", blank == 0, "%d without one" % blank)
	_ok("and no two lines share one", duped == 0, "%d collisions" % duped)

	var wrapped := DialogueParser.parse("::a\nEVA: one line that is\n    wrapped in the editor\n-> END\n")
	var wrapped_steps: Array = wrapped["chunks"]["a"]
	_ok("a wrapped line is one beat, not two",
		wrapped_steps.size() == 2 and wrapped_steps[0]["text"] == "one line that is wrapped in the editor",
		str(wrapped_steps[0].get("text", "")))

	print("\n-- every pause can actually be ended --")
	# The Prologue sat forever on "Clear the doorway" because the dig granted
	# TimeShift knowledge while the handover listened for a Story flag. The
	# scene simply never resumed. Nothing in the suite noticed, because the
	# walker set the flags itself. This is that check.
	var producible := _producible_progress()
	var orphans: Array[String] = []
	for chunk_name: String in parsed["chunks"]:
		for step: Dictionary in parsed["chunks"][chunk_name]:
			if step["type"] != "directive" or step["name"] != "handover":
				continue
			var flag: String = step["args"][0]
			if flag not in producible and flag not in orphans:
				orphans.append(flag)
	_ok("nothing in the script waits on something the world cannot give it",
		orphans.is_empty(), "nothing produces: %s" % ", ".join(orphans))
	print("        the world can produce: %s" % ", ".join(producible))

	print("\n-- progress from a puzzle resumes the scene too --")
	# The actual bug: the dig announces itself through TimeShift.knowledge,
	# the handover was listening to Story.flags, and the Prologue hung on
	# "Clear the doorway" for ever. A structural check could not see it;
	# only driving the real signal can.
	Story.reset()
	TimeShift.reset_knowledge()
	TimeShift.request_shift(Era.Id.PRESENT)
	await _settle(4)
	Dialogue.play_file(PROLOGUE)
	var safety := 0
	while safety < 300:
		safety += 1
		if Dialogue.is_active():
			if not Dialogue.pending_choices.is_empty():
				Dialogue.choose(0)
			else:
				Dialogue.advance()
			continue
		if Dialogue.waiting_for() == "chamber_opened":
			break
		if Dialogue.waiting_for().is_empty():
			break
		Story.set_flag(Dialogue.waiting_for())
		await get_tree().process_frame
		await get_tree().process_frame
	_ok("the scene reaches the sealed door and waits there",
		Dialogue.waiting_for() == "chamber_opened", Dialogue.waiting_for())
	_ok("  and the doorway is diggable by then — the script unlocked it",
		TimeShift.knows("keeper_mark"))
	TimeShift.learn("chamber_opened")
	await get_tree().process_frame
	await get_tree().process_frame
	_ok("  opening the door starts the scene again", Dialogue.is_active(),
		"still waiting on '%s'" % Dialogue.waiting_for())
	Dialogue.stop()
	Story.reset()

	print("\n-- the scene breathes --")
	Story.reset()
	TimeShift.request_shift(Era.Id.PRESENT)
	await _settle(4)
	Dialogue.play_file(PROLOGUE)
	var talked := 0
	for _i in 40:
		if not Dialogue.is_active():
			break
		Dialogue.advance()
		talked += 1
	_ok("the opening stops and hands control back instead of talking at you",
		not Dialogue.is_active() and Dialogue.is_waiting(),
		"still talking after %d lines" % talked)
	_ok("  and it is waiting on the player reaching the trench",
		Dialogue.waiting_for() == "at_trench_top", Dialogue.waiting_for())
	var resumed := await _walk_dialogue(0)
	_ok("  walking there starts it again, four more times before the end",
		resumed["handovers"] >= 3, "%d handovers" % resumed["handovers"])
	Story.reset()

	print("\n-- staging --")
	_ok("every camera target the Prologue names exists",
		_missing_markers(parsed["chunks"]).is_empty(),
		"missing: %s" % ", ".join(_missing_markers(parsed["chunks"])))
	Story.reset()
	# Deliberately with fades ON, because the point of a hard cut is that it
	# ignores them.
	TimeShift.reduced_motion = false
	TimeShift.request_shift(Era.Id.PRESENT)
	await _settle(45)
	TimeShift.arm_hard_cut()
	TimeShift.request_shift(Era.Id.PAST)
	_ok("a hard cut changes era on the very same frame — no fade to sit through",
		TimeShift.current_era == Era.Id.PAST,
		"era=%s" % Era.SHORT[TimeShift.current_era])
	# The flash holds then bleeds off over ~0.7 s, so give it longer than that.
	await _settle(70)
	_ok("and the white frame is gone a moment later", not TimeShift.is_shifting())
	TimeShift.reduced_motion = true

	var todo := Dialogue.unhandled_directives()
	print("        script asks for, not built yet: %s" % ", ".join(todo))
	print("        audio files the script wants and we do not have: %d" % wanted_audio.size())
	for a: String in wanted_audio.slice(0, 6):
		print("          ", a)
	if wanted_audio.size() > 6:
		print("           ... and %d more" % (wanted_audio.size() - 6))

	# A typo must produce a readable complaint, not a crash.
	var bad_jump := DialogueParser.parse("::a\nEVA: hi\n-> nowhere\n")
	_ok("a jump to a missing chunk is reported", bad_jump["errors"].size() == 1,
		str(bad_jump["errors"]))

	Story.reset()

	print("\n-- saving and loading --")
	SaveGame.autosave = false
	SaveGame.delete_save()
	Story.reset()
	Decipher.reset()
	TimeShift.reset_knowledge()
	TimeShift.request_shift(Era.Id.PRESENT)
	await _settle(4)

	# Build up a run worth losing.
	Story.set_flag("ishita_present_at_discovery")
	Story.set_objective("Clear the doorway")
	Story.unlock_skill("excavation")
	Story.make_contact_available("sakshi")
	TimeShift.learn("keeper_mark")
	Decipher.advance("water", Era.Id.PAST)
	Decipher.advance("water", Era.Id.PRESENT)
	player.global_position = Vector3(2.0, -10.5, -12.0)
	await _settle(10)
	var saved_at := player.global_position

	_ok("it writes a save", SaveGame.save_now("test"))
	_ok("and the file is there", SaveGame.has_save())

	# Wreck everything.
	Story.reset()
	Decipher.reset()
	TimeShift.reset_knowledge()
	TimeShift.request_shift(Era.Id.FUTURE)
	await _settle(4)
	player.global_position = Vector3(-30, 2, -40)
	await _settle(6)
	_ok("the run is genuinely gone before loading",
		not Story.has_flag("ishita_present_at_discovery")
		and Decipher.step_of("water") == Decipher.Step.UNKNOWN)

	_ok("it loads", SaveGame.load_game())
	await _settle(6)
	_ok("  flags come back", Story.has_flag("ishita_present_at_discovery"))
	_ok("  the objective comes back", Story.objective == "Clear the doorway")
	_ok("  skills come back", Story.has_skill("excavation"))
	_ok("  Sakshi is reachable again", Story.has_contact("sakshi"))
	_ok("  knowledge comes back", TimeShift.knows("keeper_mark"))
	_ok("  half-deciphered signs keep their place",
		Decipher.step_of("water") == Decipher.Step.MATCHED,
		"step %d" % Decipher.step_of("water"))
	_ok("  the era comes back", TimeShift.current_era == Era.Id.PRESENT,
		Era.SHORT[TimeShift.current_era])
	_ok("  and she is standing where she was",
		player.global_position.distance_to(saved_at) < 1.2,
		"%v vs %v" % [player.global_position, saved_at])
	_ok("  with no transition played on load", not TimeShift.is_shifting())

	print("\n-- checkpoints --")
	SaveGame.clear_checkpoint()
	_ok("there is none to begin with", not SaveGame.has_checkpoint())
	player.global_position = Vector3(1.0, -10.5, -11.0)
	await _settle(8)
	var safe := player.global_position
	SaveGame.set_checkpoint("trench floor")
	_ok("one can be set", SaveGame.has_checkpoint())
	player.global_position = Vector3(0, -300, 0)
	Story.set_flag("drowned")
	await _settle(4)
	_ok("restoring is instant and in memory", SaveGame.restore_checkpoint())
	await _settle(6)
	_ok("  she is back on her feet where it was safe",
		player.global_position.distance_to(safe) < 1.2, "%v" % player.global_position)
	_ok("  and what happened after the checkpoint did not", not Story.has_flag("drowned"))

	SaveGame.delete_save()
	_ok("a save can be deleted", not SaveGame.has_save())
	SaveGame.clear_checkpoint()
	Story.reset()
	Decipher.reset()
	SaveGame.autosave = true

	print("\n-- every script in the project compiles --")
	# Eva's rig script had a parse error and the whole suite still passed,
	# because a script that fails to load just leaves its node un-scripted and
	# nothing complained. Load every one of them and find out.
	var broken: Array[String] = []
	var checked := _compile_all("res://scripts", broken)
	_ok("all %d scripts load" % checked, broken.is_empty(),
		"\n        broken: " + "\n        broken: ".join(broken))

	print("\n-- the safety net --")
	player.global_position = Vector3(0, -200, -26)
	await _settle(6)
	_ok("falling out of the world respawns her",
		player.global_position.y > -10.0, "y = %.2f" % player.global_position.y)
