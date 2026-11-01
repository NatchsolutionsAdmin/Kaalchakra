## Evara — the 3rd-person character controller.
##
## A CharacterBody3D: Godot's body type for characters you steer directly rather
## than pushing around with forces. You set `velocity`, call move_and_slide(),
## and it handles walls, slopes and stairs for you.
##
## This capsule is a stand-in. The real Evara is a commissioned model (R5.1);
## nothing here cares what she looks like.
extends CharacterBody3D

@export_group("Movement")
@export var walk_speed := 3.2
@export var run_speed := 6.4
@export var ground_accel := 9.0
@export var air_accel := 2.5
@export var turn_speed := 11.0
@export var jump_velocity := 8.5

@export_group("Ledge climb")
## Her jump clears about 1.5 m unaided, so the pull-up deliberately starts
## ABOVE that. Otherwise it hijacks every ordinary jump taken next to a step —
## and the reservoir steps are 1.4 m.
@export var mantle_max_height := 2.4
@export var mantle_min_height := 0.85
## Two phases: straight up the face, then over the lip. Moving diagonally
## through the corner in one go is what made it read as a teleport.
@export var mantle_rise_time := 0.22
@export var mantle_over_time := 0.15

@export_group("Safety net")
## Below this height she is considered fallen out of the world.
@export var fall_limit := -40.0

@onready var model: Node3D = $Model
@onready var shape: CollisionShape3D = $Shape
@onready var cam_pivot: Node3D = $CameraPivot
@onready var wall_cast: RayCast3D = $Model/WallCast
@onready var ledge_cast: RayCast3D = $Model/LedgeCast

var _spawn: Transform3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 24.0)
var _mantling := false
var _mantle_cooldown := 0.0
var _facing := 0.0


func _ready() -> void:
	add_to_group("player")
	_spawn = global_transform
	_facing = model.rotation.y
	# Layer 5 = "Player". Nothing in the world needs to collide with her except
	# the Interactable areas, which listen on exactly this layer.
	collision_layer = 16
	TimeShift.era_changed.connect(_on_era_changed)
	_apply_era(TimeShift.current_era)
	# Make the ledge casts reach exactly as far as mantle_max_height allows.
	ledge_cast.position.y = mantle_max_height + 0.35
	ledge_cast.target_position = Vector3(0.0, -(mantle_max_height + 0.3), 0.0)


func _physics_process(delta: float) -> void:
	if global_position.y < fall_limit:
		respawn()
		return
	if Input.is_action_just_pressed("respawn"):
		respawn()
		return
	if _mantling or TimeShift.is_shifting():
		return

	_handle_interaction(delta)

	var dir := _wish_direction()
	var speed := run_speed if Input.is_action_pressed("sprint") else walk_speed
	var accel := ground_accel if is_on_floor() else air_accel

	var target := dir * speed
	velocity.x = move_toward(velocity.x, target.x, accel * speed * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * speed * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

	# Jump is always just a jump. It never turns into something else.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# The pull-up is a mid-air recovery, not a ground action: you jump at a
	# ledge and, if you come up short, you catch it. Requiring her to be
	# airborne, no longer rising, and moving into the wall is what keeps it
	# from stealing jumps she never meant to turn into a climb.
	if _mantle_cooldown > 0.0:
		_mantle_cooldown -= delta
	elif not is_on_floor() and velocity.y <= 1.0 and dir.length_squared() > 0.1:
		_try_mantle(dir)

	if dir.length_squared() > 0.001:
		# -Z is "forward" in Godot, hence the negation.
		_facing = atan2(-dir.x, -dir.z)
	model.rotation.y = rotate_toward(model.rotation.y, _facing, turn_speed * delta)

	move_and_slide()


## Turns WASD into a direction in world space, relative to where the camera is
## looking — so "forward" always means "away from the camera".
func _wish_direction() -> Vector3:
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var basis := cam_pivot.global_transform.basis
	var dir := basis.x * input.x + basis.z * input.y
	dir.y = 0.0
	return dir.normalized() if dir.length_squared() > 0.0 else Vector3.ZERO


func _handle_interaction(delta: float) -> void:
	var target := Interactions.focus()
	if target == null:
		return
	if Input.is_action_just_pressed("interact"):
		target.press(self)
	elif Input.is_action_pressed("interact"):
		target.hold(self, delta)
	elif Input.is_action_just_released("interact"):
		target.release()


# --- Ledge climb ---------------------------------------------------------

func _try_mantle(dir: Vector3) -> bool:
	if not wall_cast.is_colliding() or not ledge_cast.is_colliding():
		return false

	var forward := -model.global_transform.basis.z
	# Only climb onto something she is actually heading into.
	if dir.dot(forward) < 0.5:
		return false

	var top := ledge_cast.get_collision_point()
	var rise := top.y - global_position.y
	if rise < mantle_min_height or rise > mantle_max_height:
		return false

	var landing := Vector3(top.x, top.y + 0.05, top.z) + forward * 0.5
	var apex := Vector3(global_position.x, landing.y, global_position.z)
	# Never pull her into solid geometry. Without this she can be yanked onto a
	# step further up the flight, or into a wall, which is where "it takes me
	# somewhere else" came from.
	if not _space_free(apex) or not _space_free(landing):
		return false

	_mantling = true
	velocity = Vector3.ZERO

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "global_position", apex, mantle_rise_time).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", landing, mantle_over_time).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func() -> void:
		_mantling = false
		_mantle_cooldown = 0.25)
	return true


# --- Era handling --------------------------------------------------------

func _on_era_changed(_from: Era.Id, to: Era.Id) -> void:
	_apply_era(to)
	_unstick()


## Rebuild what Evara can bump into: the shared world (layer 1) plus whichever
## era is live. The other two eras' geometry is still sitting there in the scene
## — she simply stops listening to it.
func _apply_era(era: Era.Id) -> void:
	collision_mask = 1 | int(Era.MASK[era])
	var arm := cam_pivot.get_node_or_null("SpringArm3D") as SpringArm3D
	if arm:
		arm.collision_mask = collision_mask


## Is there room for her capsule standing with her feet at `foot_pos`?
func _space_free(foot_pos: Vector3) -> bool:
	var capsule := shape.shape as CapsuleShape3D
	if capsule == null:
		return true
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = capsule
	params.collision_mask = collision_mask
	params.exclude = [get_rid()]
	params.transform = Transform3D(Basis(), foot_pos + Vector3.UP * (capsule.height * 0.5))
	return get_world_3d().direct_space_state.intersect_shape(params, 1).is_empty()


## After a shift, the era that just arrived may have a wall where Evara is
## standing. Lift her straight up until she is clear.
func _unstick() -> void:
	for _i in 30:
		if _space_free(global_position):
			return
		global_position.y += 0.3
	# Still buried after 9 metres of lifting — bail out to the spawn point.
	respawn()


func respawn() -> void:
	global_transform = _spawn
	velocity = Vector3.ZERO
	_mantling = false
	_mantle_cooldown = 0.0
