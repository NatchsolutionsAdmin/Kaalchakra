## CameraRig — the orbiting 3rd-person camera.
##
## It is a child of Evara but runs as `top_level`, meaning it ignores her
## transform and positions itself. That lets it lag a little behind her, which
## reads as weight instead of the camera being welded to her head.
##
## The SpringArm3D under it pulls the camera in when a wall gets between the
## camera and Evara.
extends Node3D

@export var target: Node3D
@export var sensitivity := 0.0024
@export var follow_speed := 14.0
@export var shoulder_height := 1.45
@export var pitch_min_deg := -62.0
@export var pitch_max_deg := 32.0

@onready var arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	top_level = true
	if target == null:
		target = get_parent() as Node3D
	global_position = _desired_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mouse"):
		var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if captured else Input.MOUSE_MODE_CAPTURED
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		rotation.y -= motion.relative.x * sensitivity
		arm.rotation.x = clampf(
			arm.rotation.x - motion.relative.y * sensitivity,
			deg_to_rad(pitch_min_deg),
			deg_to_rad(pitch_max_deg)
		)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	# Exponential smoothing: frame-rate independent, unlike a raw lerp(x, 0.2).
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(_desired_position(), weight)


func _desired_position() -> Vector3:
	return target.global_position + Vector3.UP * shoulder_height
