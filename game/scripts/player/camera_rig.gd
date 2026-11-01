## CameraRig — the orbiting 3rd-person camera.
##
## It is a child of Eva but runs as `top_level`, meaning it ignores her
## transform and positions itself. That lets it lag a little behind her, which
## reads as weight instead of the camera being welded to her head.
##
## The SpringArm3D under it pulls the camera in when a wall gets between the
## camera and Eva.
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
## Push the orbit centre sideways so Eva sits off-centre rather than dead
## in the middle. Reads better, and keeps the view ahead of her clear.
@export var shoulder_offset := 0.5
## Indoors the spring arm gets squeezed almost to nothing and the camera ends
## up inside Eva. Below this length she is hidden instead — standard practice,
## and the trench and chamber are both too tight to avoid it.
@export var hide_model_below := 1.6
@export var pitch_min_deg := -62.0
@export var pitch_max_deg := 32.0

@onready var arm: SpringArm3D = $SpringArm3D

var _model: Node3D
var _cine: Node3D = null
var _rest_length := 0.0


func _ready() -> void:
	top_level = true
	if target == null:
		target = get_parent() as Node3D
	global_position = _desired_position()
	_model = target.get_node_or_null("Model") as Node3D
	_rest_length = arm.spring_length
	Dialogue.directive.connect(_on_directive)
	Dialogue.finished.connect(func(_id: String) -> void: _release())


func _physics_process(delta: float) -> void:
	if target == null:
		return

	if _cine != null and is_instance_valid(_cine):
		# While a scene is staging a shot, the thumbs do not steer the camera.
		Touch.take_look()
		_aim_at(_cine, delta)
	# One read per frame; reading clears the accumulated drag.
	var look := Touch.take_look()
	if _cine == null and look != Vector2.ZERO:
		rotation.y -= look.x * drag_sensitivity
		arm.rotation.x = clampf(
			arm.rotation.x - look.y * drag_sensitivity,
			deg_to_rad(pitch_min_deg),
			deg_to_rad(pitch_max_deg)
		)

	# Exponential smoothing: frame-rate independent, unlike a raw lerp(x, 0.2).
	var weight := 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(_desired_position(), weight)

	if _model:
		_model.visible = arm.get_hit_length() > hide_model_below


# --- staging a shot from the dialogue script -----------------------------
#
#   @ camera push_in sealed_door
#   @ camera look_at wheel
#   @ camera slow_reveal chamber
#   @ camera whip_around
#   @ camera release
#
# Targets are Marker3D nodes in the "camera_target" group, named exactly as
# the writer types them, so a script never contains a coordinate.

func _on_directive(name: String, args: Array) -> void:
	if name != "camera" or args.is_empty():
		return
	var move: String = args[0]
	var target_name: String = args[1] if args.size() > 1 else ""

	match move:
		"release":
			_release()
			return
		"whip_around":
			# For the hard cut: throw the view round, no target needed.
			var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			tween.tween_property(self, "rotation:y", rotation.y + PI, 0.28)
			return

	var target := _find_target(target_name)
	if target == null:
		push_warning("camera %s: no marker named '%s'." % [move, target_name])
		return
	_cine = target
	var length := _rest_length
	match move:
		"push_in":
			length = 1.9
		"slow_reveal":
			length = 3.4
	create_tween().tween_property(arm, "spring_length", length, 1.1)


func _find_target(target_name: String) -> Node3D:
	for node: Node in get_tree().get_nodes_in_group("camera_target"):
		if node.name == target_name:
			return node as Node3D
	return null


## Turn the rig until the camera is looking at `node`. The camera hangs off the
## arm along the rig's +Z and looks back through it, so pointing the rig at the
## target is the same as pointing the camera at it.
func _aim_at(node: Node3D, delta: float) -> void:
	var to := node.global_position - global_position
	if to.length_squared() < 0.01:
		return
	to = to.normalized()
	var want_yaw := atan2(-to.x, -to.z)
	var want_pitch := clampf(asin(to.y), deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	var weight := 1.0 - exp(-4.0 * delta)
	rotation.y = lerp_angle(rotation.y, want_yaw, weight)
	arm.rotation.x = lerp_angle(arm.rotation.x, want_pitch, weight)


func _release() -> void:
	if _cine == null:
		return
	_cine = null
	create_tween().tween_property(arm, "spring_length", _rest_length, 0.6)


func _desired_position() -> Vector3:
	return (target.global_position
		+ Vector3.UP * shoulder_height
		+ global_transform.basis.x * shoulder_offset)
