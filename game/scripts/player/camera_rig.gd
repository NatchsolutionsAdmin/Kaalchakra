## CameraRig — the orbiting 3rd-person camera.
##
## It is a child of Evara but runs as `top_level`, meaning it ignores her
## transform and positions itself. That lets it lag a little behind her, which
## reads as weight instead of the camera being welded to her head.
##
## The SpringArm3D under it pulls the camera in when a wall gets between the
## camera and Evara.
##
## Orbiting is drag-based: a thumb anywhere on the right of the screen, fed in
## through the `Touch` autoload. The mouse is never captured — "Emulate Touch
## From Mouse" turns a mouse drag into exactly the same event, so the phone
## scheme is what gets tested at the desk too.
extends Node3D

@export var target: Node3D
@export var drag_sensitivity := 0.0042
@export var follow_speed := 14.0
@export var shoulder_height := 1.45
## Push the orbit centre sideways so Evara sits off-centre rather than dead
## in the middle. Reads better, and keeps the view ahead of her clear.
@export var shoulder_offset := 0.5
@export var pitch_min_deg := -62.0
@export var pitch_max_deg := 32.0

@onready var arm: SpringArm3D = $SpringArm3D


func _ready() -> void:
	top_level = true
	if target == null:
		target = get_parent() as Node3D
	global_position = _desired_position()


func _physics_process(delta: float) -> void:
	if target == null:
		return

	# One read per frame; reading clears the accumulated drag.
	var look := Touch.take_look()
	if look != Vector2.ZERO:
		rotation.y -= look.x * drag_sensitivity
		arm.rotation.x = clampf(
			arm.rotation.x - look.y * drag_sensitivity,
			deg_to_rad(pitch_min_deg),
			deg_to_rad(pitch_max_deg)
		)

	# Exponential smoothing: frame-rate independent, unlike a raw lerp(x, 0.2).
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(_desired_position(), weight)


func _desired_position() -> Vector3:
	return (target.global_position
		+ Vector3.UP * shoulder_height
		+ global_transform.basis.x * shoulder_offset)
