## TimeShiftManager — the heart of the game.
##
## An "autoload" (Project Settings -> Globals): one copy of this script exists
## for the whole game, under the global name `TimeShift`. Any script can call
## TimeShift.request_shift(...) without hunting for the node.
##
## What it owns:
##   * which era is live right now
##   * the fade-to-black transition that hides the swap
##   * which eras are unlocked (story gating, R2.1)
##   * `knowledge` — the seed of PersistenceManager: things Evara has learned in
##     one era that other eras are allowed to react to (R2.2, the banyan trick)
##   * the "anchored events" refusal (R2.3) — a shift that history won't allow
##
## It deliberately does NOT know about geometry. It announces `era_changed`,
## and every EraRoot in the level listens and shows or hides itself.
extends Node

## Emitted at the midpoint of the fade, while the screen is black, so nobody
## ever sees geometry pop.
signal era_changed(from: Era.Id, to: Era.Id)
## Emitted when a shift is refused (locked era, or an anchored event).
signal shift_refused(era: Era.Id, reason: String)
signal knowledge_gained(id: String)
signal reduced_motion_changed(enabled: bool)

const FADE_TIME := 0.22

var current_era: Era.Id = Era.Id.PRESENT

## Story gating. Chapter flow will flip these on; everything is open in the prototype.
var unlocked: Dictionary = {
	Era.Id.PAST: true,
	Era.Id.PRESENT: true,
	Era.Id.FUTURE: true,
}

## Accessibility: skip the flash/fade (R6.5). Toggle with M in the prototype.
var reduced_motion := false:
	set(value):
		reduced_motion = value
		reduced_motion_changed.emit(value)

## Facts Evara carries between eras. Keys are plain strings so content can live
## in data files later, not code.
var _knowledge: Dictionary = {}

var _shifting := false
var _overlay: ColorRect


func _ready() -> void:
	# Build the fade overlay in code so it exists no matter which scene loads.
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.name = "ShiftOverlay"
	add_child(layer)

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_overlay)


func _unhandled_input(_event: InputEvent) -> void:
	for era: Era.Id in Era.ALL:
		if Input.is_action_just_pressed(Era.ACTION[era]):
			request_shift(era)
	if Input.is_action_just_pressed("toggle_reduced_motion"):
		reduced_motion = not reduced_motion


## The one way to change era. Returns true if the shift was accepted.
func request_shift(era: Era.Id) -> bool:
	if _shifting or era == current_era:
		return false
	if not unlocked.get(era, false):
		shift_refused.emit(era, "The Wheel will not turn there yet.")
		return false
	if is_anchored(era):
		# R2.3: mass-witnessed history heals around you. Not a bug — the premise.
		shift_refused.emit(era, "Anchored. History will not let you stand there.")
		return false
	_do_shift(era)
	return true


## Hook for the "anchored events" rule. Nothing is anchored in the prototype;
## chapters will override this with real conditions.
func is_anchored(_era: Era.Id) -> bool:
	return false


func _do_shift(era: Era.Id) -> void:
	_shifting = true
	var from := current_era

	if reduced_motion:
		current_era = era
		era_changed.emit(from, era)
	else:
		var tween := create_tween()
		tween.tween_property(_overlay, "color:a", 1.0, FADE_TIME)
		# The swap happens here, under full black.
		tween.tween_callback(func() -> void:
			current_era = era
			era_changed.emit(from, era))
		tween.tween_property(_overlay, "color:a", 0.0, FADE_TIME)
		await tween.finished

	_shifting = false


func is_shifting() -> bool:
	return _shifting


# --- Cross-era knowledge (seed of PersistenceManager) ---------------------

func learn(id: String) -> void:
	if _knowledge.has(id):
		return
	_knowledge[id] = true
	knowledge_gained.emit(id)


func knows(id: String) -> bool:
	return _knowledge.has(id)


## Everything SaveSystem will need from this manager later (R4.1).
func to_dict() -> Dictionary:
	return {
		"era": int(current_era),
		"unlocked": unlocked.duplicate(),
		"knowledge": _knowledge.duplicate(),
	}
