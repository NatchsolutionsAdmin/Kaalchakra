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
##
## FRAMING (ART-DIRECTION.md §2). The review specifies where Eva sits in the
## picture, not where the camera sits:
##
##     vertical FOV      50-55 deg
##     follow distance   3.2-4.2 m outside, 2.0-2.8 m inside
##     Eva's feet        83-89% of image height
##     Eva, across       45-50% of image width
##     smoothing         0.15-0.25 s
##     look-ahead        0.4-0.8 m
##
## So the pivot height and the shoulder offset are *computed* from those
## targets rather than typed in. Change the FOV or the distance and the
## framing still holds; type a height by hand and it silently stops holding
## the first time anything else moves.
extends Node3D

@export var target: Node3D
@export var drag_sensitivity := 0.0042

@export_group("Framing", "frame_")
## Where Eva's feet land, as a fraction of image height from the top.
@export_range(0.80, 0.92) var frame_feet := 0.86
## Where Eva stands across the image. Just left of centre leaves the space
## she is walking into visible, which is the third of the review's three
## depth layers: foreground, Eva, destination.
@export_range(0.42, 0.52) var frame_across := 0.47
## Resting downward tilt. Orbiting moves away from this and back.
@export var frame_rest_pitch_deg := 15.0

@export_group("Follow", "follow_")
@export var follow_distance := 3.8
## Interiors — the trench and the chamber are both too tight for 3.8 m.
@export var follow_distance_interior := 2.4
## Time constant, seconds. Larger is heavier.
@export var follow_smoothing := 0.18
## How far ahead of herself the camera leads when she is moving.
@export var follow_look_ahead := 0.6

@export_group("Limits")
## Indoors the spring arm gets squeezed almost to nothing and the camera ends
## up inside Eva. Below this length she is hidden instead — standard practice.
@export var hide_model_below := 1.4
@export var pitch_min_deg := -62.0
@export var pitch_max_deg := 32.0

@onready var arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var _model: Node3D
var _cine: Node3D = null
var _cine_speed := 2.4
var _rest_length := 0.0
var _interior := false
var _lead := Vector3.ZERO
var _measured := 0.0


func _ready() -> void:
	top_level = true
	if target == null:
		target = get_parent() as Node3D
	# NEGATIVE is downward: the SpringArm puts the camera at local +Z, so a
	# positive X rotation drops it BELOW the pivot and it looks up. The scene
	# file had this backwards and the old 72-degree FOV was wide enough to
	# hide it.
	arm.rotation.x = deg_to_rad(-frame_rest_pitch_deg)
	_rest_length = follow_distance
	arm.spring_length = _rest_length
	global_position = _desired_position()
	_model = target.get_node_or_null("Model") as Node3D
	Dialogue.directive.connect(_on_directive)
	Dialogue.finished.connect(func(_id: String) -> void: _release())


func _physics_process(delta: float) -> void:
	if target == null:
		return

	if _cine != null and is_instance_valid(_cine):
		# While a scene is staging a shot the thumbs do not steer, and the rig
		# LEAVES Eva and goes to the marker. Turning to face something from
		# where she happens to be standing shows a wall, not the subject.
		Touch.take_look()
		_frame(_cine, delta)
		if _model:
			# A staged shot often stands exactly where the player left her,
			# and a camera inside her capsule shows the inside of a mesh —
			# which reads as "there was nothing there".
			_model.visible = global_position.distance_to(target.global_position) > 1.4
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

	_update_distance(delta)
	_update_lead(delta)

	# Exponential smoothing on a time constant: frame-rate independent, and
	# the number in the inspector is the one the review specifies.
	var weight := 1.0 - exp(-delta / maxf(0.001, follow_smoothing))
	global_position = global_position.lerp(_desired_position(), weight)

	if _model:
		_model.visible = arm.get_hit_length() > hide_model_below


# --- framing --------------------------------------------------------------

## Metres the pivot must sit above Eva's feet for those feet to land at
## `frame_feet` down the image.
##
## The pivot is always at the centre of the picture — the camera looks along
## the spring arm straight at it. So this is a small piece of trigonometry
## rather than a guess: project the feet, which are `h` below the pivot, onto
## the image plane at the resting tilt and solve for `h`.
func _pivot_height() -> float:
	var half_v := tan(deg_to_rad(_fov()) * 0.5)
	if half_v <= 0.0:
		return 1.5
	# Fraction of half-height, below centre.
	var drop := (frame_feet - 0.5) * 2.0 * half_v
	var pitch := absf(arm.rotation.x)
	var denominator := cos(pitch) - drop * sin(pitch)
	if denominator <= 0.05:
		return 1.5
	return clampf(drop * _measured_distance() / denominator, 0.4, 3.0)


## Metres to push the orbit centre sideways so Eva appears at `frame_across`.
func _shoulder_offset() -> float:
	var vp := get_viewport().get_visible_rect().size
	var aspect := vp.x / maxf(1.0, vp.y)
	var half_h := tan(deg_to_rad(_fov()) * 0.5) * aspect
	# Positive pushes the camera right, which moves Eva left in frame.
	return (0.5 - frame_across) * 2.0 * half_h * _measured_distance()


func _fov() -> float:
	return camera.fov if camera else 52.0


## What the arm is being asked for.
func _distance() -> float:
	return follow_distance_interior if _interior else follow_distance


## What the camera actually got. A wall behind her squeezes the spring arm,
## and if the framing maths keeps using the requested distance her feet slide
## out of the bottom of the picture exactly when the shot is tightest.
func _measured_distance() -> float:
	var hit := arm.get_hit_length()
	if hit > 0.3:
		_measured = lerpf(_measured, hit, 0.25) if _measured > 0.3 else hit
	else:
		_measured = _distance()
	return _measured


## Inside or outside, decided by whether there is a ceiling overhead. The
## spring arm's mask is kept era-correct by `eva.gd`, so this asks the same
## question the camera collision does.
func _update_distance(delta: float) -> void:
	var space := get_world_3d().direct_space_state
	var from := target.global_position + Vector3.UP * 1.8
	var params := PhysicsRayQueryParameters3D.create(from, from + Vector3.UP * 2.6)
	params.collision_mask = arm.collision_mask
	params.exclude = [target]
	var hit := not space.intersect_ray(params).is_empty()
	if hit != _interior:
		_interior = hit
	# Ease between the two distances so stepping under a lintel is not a cut.
	arm.spring_length = lerpf(arm.spring_length, _distance(),
		1.0 - exp(-delta / 0.35))
	_rest_length = _distance()


## Lead the camera in the direction she is travelling, so the destination
## stays in frame rather than arriving at the edge.
func _update_lead(delta: float) -> void:
	var want := Vector3.ZERO
	var body := target as CharacterBody3D
	if body:
		var flat := Vector3(body.velocity.x, 0.0, body.velocity.z)
		if flat.length() > 0.4:
			want = flat.normalized() * follow_look_ahead
	_lead = _lead.lerp(want, 1.0 - exp(-delta / 0.45))


func _desired_position() -> Vector3:
	return (target.global_position
		+ Vector3.UP * _pivot_height()
		+ global_transform.basis.x * _shoulder_offset()
		+ _lead)


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

	var marker := _find_target(target_name)
	if marker == null:
		push_warning("camera %s: no marker named '%s'." % [move, target_name])
		return
	_cine = marker
	# Markers ARE camera set-ups: position and facing both come from the
	# marker, so the writer names a shot and never touches a transform.
	_cine_speed = {"cut_to": 50.0, "push_in": 1.6, "look_at": 3.0,
		"slow_reveal": 0.9, "move_to": 2.2}.get(move, 2.2)
	create_tween().tween_property(arm, "spring_length", 0.0, 0.35)


func _find_target(target_name: String) -> Node3D:
	for node: Node in get_tree().get_nodes_in_group("camera_target"):
		if node.name == target_name:
			return node as Node3D
	return null


## Move the rig onto the marker and adopt its facing. With the spring arm
## collapsed the camera sits exactly where the rig is, so the marker's
## transform is literally the shot.
func _frame(node: Node3D, delta: float) -> void:
	var weight := clampf(1.0 - exp(-_cine_speed * delta), 0.0, 1.0)
	global_position = global_position.lerp(node.global_position, weight)
	var want := node.global_rotation
	rotation.y = lerp_angle(rotation.y, want.y, weight)
	arm.rotation.x = lerp_angle(arm.rotation.x, want.x, weight)


func _release() -> void:
	if _cine == null:
		return
	_cine = null
	# No tween back: `_update_distance` eases the arm to the right length on
	# its own, and two things writing one property is how cameras get stuck.
