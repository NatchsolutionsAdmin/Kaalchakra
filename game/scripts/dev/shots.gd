## Dev-only: renders reference screenshots of the greybox in all three eras.
##   SHOT_DIR=/tmp/shots godot --path game scenes/dev/Shots.tscn
extends Node

var _dir := ""
var _main: Node
var _player: Node3D
var _pivot: Node3D
var _overview: Camera3D


func _ready() -> void:
	_dir = OS.get_environment("SHOT_DIR")
	if _dir.is_empty():
		_dir = "/tmp"
	# SHOT_SIZE=1230x568 renders at phone proportions instead of 16:9.
	var size := Vector2i(1280, 720)
	var want := OS.get_environment("SHOT_SIZE")
	if want.contains("x"):
		size = Vector2i(int(want.get_slice("x", 0)), int(want.get_slice("x", 1)))
	DisplayServer.window_set_size(size)
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)
	TimeShift.reduced_motion = true
	_player = _main.get_node("Eva")
	_pivot = _player.get_node("CameraPivot")
	_overview = Camera3D.new()
	_overview.fov = 62.0
	_main.add_child(_overview)
	await get_tree().physics_frame
	await _run()
	get_tree().quit()


func _settle(n: int = 30) -> void:
	for _i in n:
		await get_tree().physics_frame

## Shifting now takes the review's full 900 ms (ART-DIRECTION.md §8), which is
## longer than any fixed number of settle frames. Wait for the real thing.
func _shift(era: Era.Id) -> bool:
	var accepted := TimeShift.request_shift(era)
	while TimeShift.is_shifting():
		await get_tree().process_frame
	await _settle(4)
	return accepted



func _shot(name: String) -> void:
	# A shots run takes longer than the idle timeout, so without this the
	# controls fade out of half the reference frames.
	Chrome.poke()
	# Two frames: the viewport texture lags one frame behind the state change,
	# which silently swapped a pair of these the first time round.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [_dir, name])
	print("  ", name)


func _stand(pos: Vector3, yaw_deg: float) -> void:
	_player.global_position = pos
	_player.velocity = Vector3.ZERO
	await _settle(8)
	_pivot.rotation.y = deg_to_rad(yaw_deg)
	_pivot.global_position = _player.global_position + Vector3.UP * 1.45
	await _settle(25)


## Every interface layer, off. Returns what it hid so it can be put back.
func _chrome_layers() -> Array:
	var found: Array = []
	for name: String in ["HUD", "TouchControls", "DialogueUI", "PhoneUI"]:
		var node := _main.get_node_or_null(name) as CanvasLayer
		if node:
			found.append(node)
	return found


func _benchmark() -> void:
	var layers := _chrome_layers()
	for layer: CanvasLayer in layers:
		layer.visible = false

	# Two locked set-ups. The gate is the identity shot; the reservoir is the
	# one the review calls the single strongest cross-era environment.
	var setups := [
		["gate", Vector3(0, 1.2, -25.0), 0.0],
		["reservoir", Vector3(3.0, 1.2, -17.0), 180.0],
	]
	for setup: Array in setups:
		for e: Array in [[Era.Id.PAST, "1900bce"], [Era.Id.PRESENT, "2026"],
				[Era.Id.FUTURE, "2087"]]:
			await _shift(e[0])
			await _stand(setup[1], setup[2])
			await _shot("benchmark_%s_%s" % [setup[0], e[1]])

	for layer: CanvasLayer in layers:
		layer.visible = true
	await _settle(4)


func _run() -> void:
	var eras := [[Era.Id.PAST, "past"], [Era.Id.PRESENT, "present"], [Era.Id.FUTURE, "future"]]

	# 1. From the spawn point, looking south across the reservoir.
	for e: Array in eras:
		await _shift(e[0])
		await _stand(Vector3(0, 1.2, -26), 180.0)
		await _shot("spawn_%s" % e[1])

	# 2. Inside the gate, looking north at it.
	for e: Array in eras:
		await _shift(e[0])
		await _stand(Vector3(0, 1.2, -25), 0.0)
		await _shot("gate_%s" % e[1])

	# 3. Down on the basin floor, where the chamber is.
	for e: Array in eras:
		await _shift(e[0])
		await _stand(Vector3(3, -6.0, -11), 180.0)
		await _shot("basin_%s" % e[1])

	# 4. Standing in the market street, looking east.
	for e: Array in eras:
		await _shift(e[0])
		await _stand(Vector3(13, 1.2, -13), 270.0)
		await _shot("street_%s" % e[1])

	# 3b. Down in Trench 4, looking at the sealed doorway.
	for e: Array in eras:
		await _shift(e[0])
		await _stand(Vector3(1.2, -10.5, -12.6), 90.0)
		await _shot("trench_%s" % e[1])

	# 3c. Inside the chamber, looking at the manifest wall.
	for e: Array in eras:
		await _shift(e[0])
		if e[1] == "present":
			var sealed := _main.get_node_or_null("NorthGate/Present/SealedDoor")
			if sealed:
				sealed.visible = false
		await _stand(Vector3(-3.2, -10.5, -13.25), 90.0)
		await _shot("chamber_%s" % e[1])

	# 4b. The touch layer. State is set directly rather than by faking input —
	# these shots exist to check layout; the smoke test covers the input path.
	await _shift(Era.Id.PRESENT)
	await _stand(Vector3(3, 1.2, -24.5), 180.0)
	var touch_ui := _main.get_node("TouchControls")
	touch_ui.set("_joy_touch", 0)
	touch_ui.set("_joy_origin", Vector2(250, 470))
	touch_ui.set("_joy_point", Vector2(312, 408))
	Touch.move = Vector2(0.67, -0.67)
	touch_ui.get("_paint").queue_redraw()
	await _settle(6)
	await _shot("touch_joystick")

	touch_ui.set("_wheel_open", true)
	touch_ui.call("_refresh_wheel")
	await _settle(6)
	await _shot("touch_wheel_open")

	touch_ui.set("_wheel_open", false)
	touch_ui.call("_refresh_wheel")
	touch_ui.set("_joy_touch", -1)
	Touch.move = Vector2.ZERO
	touch_ui.get("_paint").queue_redraw()
	await _settle(6)

	# 4b2. The sign index, part-way through the chain.
	Decipher.reset()
	for id: String in ["what", "water"]:
		Decipher.advance(id, Era.Id.PAST)
		Decipher.advance(id, Era.Id.PRESENT)
		Decipher.advance(id, Era.Id.FUTURE)
	Decipher.advance("not", Era.Id.PAST)
	await _shift(Era.Id.PRESENT)
	await _stand(Vector3(-3.6, -10.5, -13.25), 90.0)
	Input.action_press("journal")
	await _settle(10)
	await _shot("sign_index")
	Input.action_release("journal")
	await _settle(6)
	Decipher.reset()

	# 4b3. On the phone to Ma.
	Story.make_contact_available("sakshi")
	Decipher.advance("water", Era.Id.PAST)
	await _shift(Era.Id.PRESENT)
	await _stand(Vector3(0.5, -10.5, -11.5), 20.0)
	Phone.start("sakshi")
	await _settle(70)
	Phone.advance()
	Phone.advance()
	await _settle(30)
	await _shot("phone_call")
	Phone.hang_up()
	Decipher.reset()
	await _settle(30)

	# 4b4. Paused.
	await _shift(Era.Id.PRESENT)
	await _stand(Vector3(0, 1.2, -24), 180.0)
	var pause_menu := _main.get_node_or_null("PauseMenu")
	if pause_menu:
		pause_menu.call("toggle")
		await _settle(8)
		await _shot("pause_menu")
		pause_menu.call("toggle")
		await _settle(6)

	# 4c. Portrait — does she have a face worth framing?
	await _shift(Era.Id.PRESENT)
	await _stand(Vector3(0, 1.2, -24), 180.0)
	_overview.global_position = _player.global_position + Vector3(0.55, 1.62, 1.25)
	_overview.look_at(_player.global_position + Vector3(0, 1.52, 0), Vector3.UP)
	_overview.fov = 42.0
	_overview.make_current()
	await _settle(14)
	await _shot("eva_portrait")
	_overview.global_position = _player.global_position + Vector3(2.1, 1.1, 2.6)
	_overview.look_at(_player.global_position + Vector3(0, 0.95, 0), Vector3.UP)
	_overview.fov = 52.0
	await _settle(14)
	await _shot("eva_full")
	_overview.fov = 62.0

	# 4d. THE BENCHMARK (ART-DIRECTION.md §1, and the review's day-one task).
	#
	# The exact same camera in all three eras, with every scrap of interface
	# switched off. Three things have to be true of this set, and they are
	# the only pass criteria that matter right now:
	#
	#   1. you can tell which era it is with no HUD
	#   2. you find the focal point within two seconds
	#   3. it is unmistakably the same place in all three
	#
	# If a change to lighting or composition cannot be defended against those
	# three questions, it is decoration.
	await _benchmark()

	# 5. Overview from the south-east.
	_overview.global_position = Vector3(52, 40, 26)
	_overview.look_at(Vector3(0, -2, -18), Vector3.UP)
	_overview.make_current()
	for e: Array in eras:
		await _shift(e[0])
		await _settle(20)
		await _shot("overview_%s" % e[1])
