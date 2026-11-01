## TouchInput — what the player's thumbs are currently asking for.
##
## Autoloaded as `Touch`. Deliberately holds no UI: `scripts/ui/touch_controls.gd`
## draws the joystick and buttons and writes into here, and the player and camera
## read from here. That split means the controls can be redrawn, moved or
## re-skinned without touching movement code, and movement stays testable
## headlessly with no UI on screen at all.
##
## Keyboard still works everywhere alongside this, for testing at the desk.
extends Node

## -1..1 on each axis, straight from the virtual joystick.
var move := Vector2.ZERO
## True while the action button is held (the excavation hold needs this).
var interact_down := false

var _look := Vector2.ZERO
var _jump_queued := false
var _interact_queued := false


## Pixels dragged since the last read. Call once per frame — reading clears it.
func take_look() -> Vector2:
	var d := _look
	_look = Vector2.ZERO
	return d


func add_look(delta: Vector2) -> void:
	_look += delta


func queue_jump() -> void:
	_jump_queued = true


## One-shot: true on the frame the jump button went down. Reading clears it.
func consume_jump() -> bool:
	var j := _jump_queued
	_jump_queued = false
	return j


func set_interact(down: bool) -> void:
	if down and not interact_down:
		_interact_queued = true
	interact_down = down


func consume_interact() -> bool:
	var p := _interact_queued
	_interact_queued = false
	return p


func reset() -> void:
	move = Vector2.ZERO
	interact_down = false
	_look = Vector2.ZERO
	_jump_queued = false
	_interact_queued = false
