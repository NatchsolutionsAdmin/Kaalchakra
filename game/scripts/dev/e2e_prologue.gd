## End-to-end: plays the Prologue the way a person would.
##
##   ./dev e2e
##
## The smoke test pokes systems — it sets a flag to get past a handover. This
## does not. It steers Eva with the virtual joystick, walks her to each place
## the script is waiting on, holds the action button to excavate, and only
## advances dialogue when dialogue is actually on screen.
##
## That makes it the first test that can answer "is the chapter completable by
## playing it", which no amount of unit testing can. If a doorway is too narrow,
## a step too tall, a trigger unreachable or a prompt out of range, this fails
## and the smoke test would not have noticed.
extends Node

const PROLOGUE := "res://data/dialogue/prologue_overburden.dialogue"
const WALK_TIMEOUT := 16.0
const ARRIVE := 1.6

var _main: Node
var _eva: CharacterBody3D
var _pivot: Node3D
var _fail := 0
var _shots := 0
var _dir := ""
var _started_at := 0


func _ready() -> void:
	_dir = OS.get_environment("SHOT_DIR")
	if _dir.is_empty():
		_dir = "/tmp/e2e"
	DirAccess.make_dir_recursive_absolute(_dir)
	var size := Vector2i(1230, 568)
	var want := OS.get_environment("SHOT_SIZE")
	if want.contains("x"):
		size = Vector2i(int(want.get_slice("x", 0)), int(want.get_slice("x", 1)))
	DisplayServer.window_set_size(size)

	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)
	await get_tree().physics_frame
	_eva = _main.get_node("Eva") as CharacterBody3D
	_pivot = _eva.get_node("CameraPivot") as Node3D
	_eva.global_position = Vector3(-6.0, -6.6, -6.0)
	_eva.velocity = Vector3.ZERO
	await _settle(20)

	print("\n=== E2E: playing the Prologue ===\n")
	_started_at = Time.get_ticks_msec()
	await _run()
	var secs := (Time.get_ticks_msec() - _started_at) / 1000.0

	print("")
	if _fail == 0:
		print("E2E PASSED — the Prologue is completable by playing it (%.1fs, %d shots)"
			% [secs, _shots])
	else:
		print("E2E FAILED — %d problem(s)" % _fail)
	get_tree().quit(1 if _fail > 0 else 0)


func _ok(label: String, condition: bool, detail: String = "") -> void:
	if condition:
		print("  ok    %s" % label)
	else:
		_fail += 1
		print("  FAIL  %s   %s" % [label, detail])


func _settle(frames: int) -> void:
	for _i in frames:
		await get_tree().physics_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%02d_%s.png" % [_dir, _shots, name])
	_shots += 1


## Steer with the stick, exactly as a thumb would. No teleporting.
func _walk_to(target: Vector3, label: String, done_flag: String = "") -> bool:
	var deadline := Time.get_ticks_msec() + int(WALK_TIMEOUT * 1000.0)
	var closest := INF
	var best := INF
	var stalled := 0
	var sidestep := 0
	var side := 1.0
	while Time.get_ticks_msec() < deadline:
		var flat_to := target - _eva.global_position
		flat_to.y = 0.0
		var d := flat_to.length()
		closest = minf(closest, _eva.global_position.distance_to(target))
		# Arriving is not the goal — the goal is the thing arriving CAUSES.
		# Triggers have their own radius and fire before any threshold of
		# mine, and the moment one does the scene starts talking again and
		# Eva is frozen on purpose. Walking on from there is how this test
		# wasted sixteen seconds and then blamed the game.
		if not done_flag.is_empty() and (Story.has_flag(done_flag) or TimeShift.knows(done_flag)):
			Touch.move = Vector2.ZERO
			return true
		if Dialogue.is_active():
			Touch.move = Vector2.ZERO
			return true
		if d < ARRIVE:
			Touch.move = Vector2.ZERO
			await _settle(8)
			return true

		# Point the camera at the target, then push the stick forward — the
		# same path a player's input takes. The pivot's forward is -Z rotated
		# by rotation.y, i.e. (-sin, 0, -cos); solving that for "face the
		# target" gives this, with no extra PI.
		var heading := atan2(-flat_to.x, -flat_to.z)

		# There is no navmesh, so when a wall stops progress, slide along it
		# for a moment the way a person would rather than grinding into it.
		if d < best - 0.05:
			best = d
			stalled = 0
		else:
			stalled += 1
		if stalled > 40 and sidestep <= 0:
			sidestep = 35
			side = -side
			stalled = 0
		if sidestep > 0:
			sidestep -= 1
			heading += side * 1.15

		_pivot.rotation.y = heading
		Touch.move = Vector2(0, -1)
		await get_tree().physics_frame
	Touch.move = Vector2.ZERO
	_ok("walk to %s" % label, false, "stuck %.1f m away at %v" % [closest, _eva.global_position])
	return false


func _trigger_pos(name: String) -> Vector3:
	var node := _main.get_node_or_null("NorthGate/Present/" + name) as Node3D
	return node.global_position if node else Vector3.ZERO


func _run() -> void:
	var errors := Dialogue.play_file(PROLOGUE)
	_ok("the Prologue script loads with no errors", errors.is_empty(), str(errors))

	# Evidence of the dialogue box itself, not just the world behind it.
	await _settle(20)
	await _shot("dialogue")

	var beats := 0
	var guard := 0
	while guard < 400:
		guard += 1
		if Dialogue.is_active():
			if not Dialogue.pending_choices.is_empty():
				await _settle(10)
				await _shot("choice")
				Dialogue.choose(0)
			else:
				Dialogue.advance()
			await get_tree().process_frame
			continue

		var waiting := Dialogue.waiting_for()
		if waiting.is_empty():
			break

		beats += 1
		print("\n-- beat %d: the game wants '%s' --" % [beats, waiting])
		await _shot("beat_%d_%s" % [beats, waiting])

		match waiting:
			"at_trench_top", "at_trench_bottom", "in_chamber":
				var target := _trigger_pos(waiting)
				_ok("'%s' exists in the world" % waiting, target != Vector3.ZERO)
				if not await _walk_to(target, waiting, waiting):
					return
				_ok("she reached %s on foot" % waiting, Story.has_flag(waiting),
					"arrived but the trigger did not fire")
			"chamber_opened":
				var dig := _main.get_node_or_null("NorthGate/Present/DigSite") as Interactable
				_ok("the dig site exists", dig != null)
				if dig == null:
					return
				if not await _walk_to(dig.global_position, "the sealed door"):
					return
				_ok("the game offers the dig when she is standing there",
					Interactions.focus() == dig,
					"focus is %s" % str(Interactions.focus()))
				# Hold the action button, as a thumb would.
				Touch.set_interact(true)
				await _settle(240)
				Touch.set_interact(false)
				_ok("holding the action button opens the door",
					TimeShift.knows("chamber_opened"))
			_:
				_ok("unknown handover '%s'" % waiting, false)
				return
		# Resuming after a handover is deferred (the flag usually arrives from
		# inside a physics callback), so give it a few frames before deciding
		# the scene is over.
		for _w in 6:
			await get_tree().process_frame
			if Dialogue.is_active() or Dialogue.is_waiting():
				break
		if Dialogue.is_active() or Dialogue.is_waiting():
			continue
		break

	await _shot("end")
	print("")
	_ok("the Prologue played to the end", not Dialogue.is_active() and not Dialogue.is_waiting())
	_ok("it ends in 1900 BCE", TimeShift.current_era == Era.Id.PAST,
		Era.SHORT[TimeShift.current_era])
	_ok("she saw the manifest wall", Story.has_flag("saw_the_index"))
	_ok("excavation was unlocked along the way", Story.has_skill("excavation"))
	_ok("Sakshi became callable", Story.has_contact("sakshi"))
	_ok("it took four play beats, not one wall of text", beats == 4, "%d beats" % beats)
