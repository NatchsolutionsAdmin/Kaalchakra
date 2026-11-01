## EvaRig — moves the blocked-out body.
##
## No animation files and no skeleton: the limbs are empty joint nodes with
## boxes hanging off them, and this rotates the joints from how fast she is
## actually moving. A walk cycle from arithmetic.
##
## It is deliberately crude, and it is temporary. When the commissioned model
## arrives (R5.1) it comes with a real skeleton and real animation, an
## AnimationTree replaces this file, and nothing else changes — her movement
## code already publishes the only thing animation needs, which is her speed.
##
## What it buys right now: she has a front, a back and a readable gait, so a
## staged camera shot has something to point at.
extends Node3D

@export var run_speed := 6.4
## Radians of leg swing at a full run.
@export var stride := 0.95
## Strides per metre travelled — what keeps the feet from skating.
@export var cycle_per_metre := 0.55
@export var bob_height := 0.045

@onready var hips: Node3D = $Hips
@onready var spine: Node3D = $Hips/Spine
@onready var head: Node3D = $Hips/Spine/Head
@onready var hip_l: Node3D = $Hips/HipL
@onready var hip_r: Node3D = $Hips/HipR
@onready var knee_l: Node3D = $Hips/HipL/KneeL
@onready var knee_r: Node3D = $Hips/HipR/KneeR
@onready var shoulder_l: Node3D = $Hips/Spine/ShoulderL
@onready var shoulder_r: Node3D = $Hips/Spine/ShoulderR
@onready var elbow_l: Node3D = $Hips/Spine/ShoulderL/ElbowL
@onready var elbow_r: Node3D = $Hips/Spine/ShoulderR/ElbowR

var _body: CharacterBody3D
var _phase := 0.0
var _breath := 0.0
var _rest_hip_y := 0.0


func _ready() -> void:
	_body = get_parent() as CharacterBody3D
	_rest_hip_y = hips.position.y


func _process(delta: float) -> void:
	if _body == null:
		return

	var speed := Vector2(_body.velocity.x, _body.velocity.z).length()
	var effort := clampf(speed / run_speed, 0.0, 1.0)
	var airborne := not _body.is_on_floor()

	# Phase advances with distance covered, not with time, so the feet keep up
	# with her whatever speed she is going.
	_phase += speed * cycle_per_metre * TAU * delta
	_breath += delta

	if airborne:
		_pose_airborne(delta)
		return

	var swing := sin(_phase)
	var amount := stride * effort

	# +X at a hip swings that leg forward; the arms run opposite, as they do.
	hip_l.rotation.x = lerp(hip_l.rotation.x, swing * amount, 0.4)
	hip_r.rotation.x = lerp(hip_r.rotation.x, -swing * amount, 0.4)
	# Knees only bend one way, and only on the trailing leg.
	knee_l.rotation.x = lerp(knee_l.rotation.x, -maxf(0.0, -swing) * amount * 1.1, 0.4)
	knee_r.rotation.x = lerp(knee_r.rotation.x, -maxf(0.0, swing) * amount * 1.1, 0.4)

	shoulder_l.rotation.x = lerp(shoulder_l.rotation.x, -swing * amount * 0.75, 0.4)
	shoulder_r.rotation.x = lerp(shoulder_r.rotation.x, swing * amount * 0.75, 0.4)
	elbow_l.rotation.x = lerp(elbow_l.rotation.x, -0.15 - absf(swing) * 0.3 * effort, 0.4)
	elbow_r.rotation.x = lerp(elbow_r.rotation.x, -0.15 - absf(swing) * 0.3 * effort, 0.4)

	# Two bobs per stride, and she leans into a run.
	hips.position.y = lerp(hips.position.y,
		_rest_hip_y - absf(sin(_phase)) * bob_height * effort, 0.4)
	spine.rotation.x = lerp(spine.rotation.x, -0.16 * effort + _idle_breath(effort), 0.3)
	head.rotation.x = lerp(head.rotation.x, 0.10 * effort, 0.3)


## Standing still is not nothing — she breathes, so a held shot is not a
## photograph.
func _idle_breath(effort: float) -> float:
	return sin(_breath * 1.6) * 0.012 * (1.0 - effort)


func _pose_airborne(delta: float) -> void:
	var k := clampf(8.0 * delta, 0.0, 1.0)
	hip_l.rotation.x = lerp(hip_l.rotation.x, 0.45, k)
	hip_r.rotation.x = lerp(hip_r.rotation.x, -0.2, k)
	knee_l.rotation.x = lerp(knee_l.rotation.x, -0.9, k)
	knee_r.rotation.x = lerp(knee_r.rotation.x, -0.35, k)
	shoulder_l.rotation.x = lerp(shoulder_l.rotation.x, -0.5, k)
	shoulder_r.rotation.x = lerp(shoulder_r.rotation.x, -0.7, k)
	elbow_l.rotation.x = lerp(elbow_l.rotation.x, -0.7, k)
	elbow_r.rotation.x = lerp(elbow_r.rotation.x, -0.9, k)
	hips.position.y = lerp(hips.position.y, _rest_hip_y - 0.02, k)
	spine.rotation.x = lerp(spine.rotation.x, -0.12, k)
