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
	DisplayServer.window_set_size(Vector2i(1280, 720))
	_main = load("res://scenes/Main.tscn").instantiate()
	add_child(_main)
	TimeShift.reduced_motion = true
	_player = _main.get_node("Evara")
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


func _shot(name: String) -> void:
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


func _run() -> void:
	var eras := [[Era.Id.PAST, "past"], [Era.Id.PRESENT, "present"], [Era.Id.FUTURE, "future"]]

	# 1. From the spawn point, looking south across the reservoir.
	for e: Array in eras:
		TimeShift.request_shift(e[0])
		await _stand(Vector3(0, 1.2, -26), 180.0)
		await _shot("spawn_%s" % e[1])

	# 2. Inside the gate, looking north at it.
	for e: Array in eras:
		TimeShift.request_shift(e[0])
		await _stand(Vector3(0, 1.2, -25), 0.0)
		await _shot("gate_%s" % e[1])

	# 3. Down on the basin floor, where the chamber is.
	for e: Array in eras:
		TimeShift.request_shift(e[0])
		await _stand(Vector3(3, -6.0, -11), 180.0)
		await _shot("basin_%s" % e[1])

	# 4. Standing in the market street, looking east.
	for e: Array in eras:
		TimeShift.request_shift(e[0])
		await _stand(Vector3(13, 1.2, -13), 270.0)
		await _shot("street_%s" % e[1])

	# 5. Overview from the south-east.
	_overview.global_position = Vector3(52, 40, 26)
	_overview.look_at(Vector3(0, -2, -18), Vector3.UP)
	_overview.make_current()
	for e: Array in eras:
		TimeShift.request_shift(e[0])
		await _settle(20)
		await _shot("overview_%s" % e[1])
