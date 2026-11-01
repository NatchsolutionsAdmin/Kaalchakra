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
## Tallest ledge Evara can pull herself onto.
@export var mantle_max_height := 1.7
@export var mantle_min_height := 0.35
@export var mantle_time := 0.3

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

	if Input.is_action_just_pressed("jump"):
		if not _try_mantle():
			if is_on_floor():
				velocity.y = jump_velocity

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

func _try_mantle() -> bool:
	if not wall_cast.is_colliding() or not ledge_cast.is_colliding():
		return false
	var top := ledge_cast.get_collision_point()
	var rise := top.y - global_position.y
	if rise < mantle_min_height or rise > mantle_max_height:
		return false

	_mantling = true
	velocity = Vector3.ZERO
	var forward := -model.global_transform.basis.z
	var landing := Vector3(top.x, top.y + 0.03, top.z) + forward * 0.45

	# No `await` here on purpose: this function has to return a plain bool in the
	# same frame, so the caller knows not to also fire a normal jump.
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "global_position", landing, mantle_time)
	tween.finished.connect(func() -> void: _mantling = false)
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


## After a shift, the era that just arrived may have a wall where Evara is
## standing. Lift her straight up until she is clear.
func _unstick() -> void:
	var capsule := shape.shape as CapsuleShape3D
	if capsule == null:
		return
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = capsule
	params.collision_mask = collision_mask
	params.exclude = [get_rid()]
	var space := get_world_3d().direct_space_state

	for _i in 30:
		params.transform = Transform3D(Basis(), global_position + Vector3.UP * (capsule.height * 0.5))
		if space.intersect_shape(params, 1).is_empty():
			return
		global_position.y += 0.3
	# Still buried after 9 metres of lifting — bail out to the spawn point.
	respawn()


func respawn() -> void:
	global_transform = _spawn
	velocity = Vector3.ZERO
	_mantling = false
