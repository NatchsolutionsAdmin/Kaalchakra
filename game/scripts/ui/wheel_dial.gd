## WheelDial — the Kaalchakra as an instrument you can touch.
##
## The drawing lives in `KaalchakraMark`, shared with the title screen and the
## app icon. This file is only the behaviour: which stop is live, how it moves
## between them, and the tap.
##
## The review is firm that the Wheel never free-spins (ART-DIRECTION.md §9).
## It moves from detent to detent, overshoots by a hair, and stops. That one
## detail is the difference between a machine and a spaceship selector.
class_name WheelDial
extends Control

signal tapped

const SPOKES := KaalchakraMark.POSITIONS

var _state := KaalchakraMark.State.new()
var _target_angle := 0.0
var _settling := false


func _ready() -> void:
	custom_minimum_size = Vector2(118, 118)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	TimeShift.era_changed.connect(_on_era_changed)
	_state.live = int(TimeShift.current_era)
	_state.rotation = _angle_for(TimeShift.current_era)
	_target_angle = _state.rotation
	set_process(true)


## Size the mark to the box it has been given.
func set_diameter(d: float) -> void:
	custom_minimum_size = Vector2(d, d)
	size = custom_minimum_size
	_state.weight = clampf(d / 120.0, 0.55, 2.0)
	queue_redraw()


func _on_era_changed(_from: Era.Id, to: Era.Id) -> void:
	_state.live = int(to)
	_target_angle = _angle_for(to)
	_state.flare = 1.0
	_settling = true


## Each stop sits on its own spoke. Turning the Wheel brings it to the top.
func _angle_for(era: Era.Id) -> float:
	return -KaalchakraMark.STEP * float(int(era))


func _process(delta: float) -> void:
	var moved := false
	var gap := angle_difference(_state.rotation, _target_angle)
	if absf(gap) > 0.0015:
		# Fast approach, then a stop — not a spin-down.
		_state.rotation = lerp_angle(_state.rotation, _target_angle,
			1.0 - exp(-16.0 * delta))
		moved = true
	elif _settling:
		_state.rotation = _target_angle
		_settling = false
		moved = true
	if _state.flare > 0.0:
		_state.flare = maxf(0.0, _state.flare - delta * 1.7)
		moved = true
	if moved:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var pressed := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if pressed:
		tapped.emit()


func _draw() -> void:
	var c := size * 0.5
	KaalchakraMark.draw_mark(self, c, minf(size.x, size.y) * 0.5 - 3.0, _state)
