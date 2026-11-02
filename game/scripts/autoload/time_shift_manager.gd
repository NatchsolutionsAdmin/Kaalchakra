## TimeShiftManager — the heart of the game.
##
## An "autoload" (Project Settings -> Globals): one copy of this script exists
## for the whole game, under the global name `TimeShift`. Any script can call
## TimeShift.request_shift(...) without hunting for the node.
##
## What it owns:
##   * which era is live right now
##   * the era-shift transition that carries the swap
##   * which eras are unlocked (story gating, R2.1)
##   * `knowledge` — the seed of PersistenceManager: things Eva has learned in
##     one era that other eras are allowed to react to (R2.2, the banyan trick)
##   * the "anchored events" refusal (R2.3) — a shift that history won't allow
##
## It deliberately does NOT know about geometry. It announces `era_changed`,
## and every EraRoot in the level listens and shows or hides itself.
extends Node

## Emitted while the light band is crossing the screen, so the swap is
## carried by the transition rather than seen as a pop.
signal era_changed(from: Era.Id, to: Era.Id)
## Emitted when a shift is refused (locked era, or an anchored event).
signal shift_refused(era: Era.Id, reason: String)
signal knowledge_gained(id: String)
signal reduced_motion_changed(enabled: bool)

const FADE_TIME := 0.22

## "The World Remembers" (ART-DIRECTION.md §8). The review's timeline, in
## seconds, measured from the moment the Wheel is touched:
##
##   0.00 - 0.12   Eva engages the selected stop      copper click
##   0.12 - 0.30   controlled radial light band       dry mechanism resonance
##   0.30 - 0.62   era-root swap across a fixed image layered change in ambience
##   0.62 - 0.78   new light, water, material settle  destination ambience
##   0.78 - 0.90   camera and Wheel return to stillness   final mechanical stop
const SHIFT_ENGAGE := 0.12
const SHIFT_BAND_IN := 0.18      # 0.12 -> 0.30
const SHIFT_SWEEP := 0.32        # 0.30 -> 0.62
const SHIFT_SETTLE := 0.16       # 0.62 -> 0.78
const SHIFT_STILL := 0.12        # 0.78 -> 0.90

const BAND_SHADER := "res://shaders/shift_band.gdshader"

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

## Facts Eva carries between eras. Keys are plain strings so content can live
## in data files later, not code.
var _knowledge: Dictionary = {}

var _shifting := false
var _hard_cut := false
var _overlay: ColorRect
var _band: ColorRect
var _band_material: ShaderMaterial
## Where the Wheel sits on screen, in UV. The band sweeps out from it.
var band_origin := Vector2(0.9, 0.14)


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

	# A second, separate overlay for the light band, so the plain black fade
	# (used by the hard cut and by reduced motion) stays untouched.
	_band = ColorRect.new()
	_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.set_anchors_preset(Control.PRESET_FULL_RECT)
	_band.visible = false
	var shader := load(BAND_SHADER) as Shader
	if shader:
		_band_material = ShaderMaterial.new()
		_band_material.shader = shader
		_band.material = _band_material
	layer.add_child(_band)


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


## Make the NEXT shift a hard cut: no fade, one frame here and the next frame
## four thousand years away, with a single white frame to sell the hit. Used
## by the Prologue, where easing into 1900 BCE would be exactly wrong.
func arm_hard_cut() -> void:
	_hard_cut = true


## Hook for the "anchored events" rule. Nothing is anchored in the prototype;
## chapters will override this with real conditions.
func is_anchored(_era: Era.Id) -> bool:
	return false


func _do_shift(era: Era.Id) -> void:
	_shifting = true
	var from := current_era

	if _hard_cut:
		_hard_cut = false
		current_era = era
		era_changed.emit(from, era)
		if not reduced_motion:
			# Hold the white, then bleed it off. A 0.3 s fade was too polite
			# for the moment the whole Prologue exists to deliver.
			_overlay.color = Color(1, 1, 1, 1.0)
			var flash := create_tween()
			flash.tween_interval(0.14)
			flash.tween_property(_overlay, "color", Color(1, 1, 1, 0.0), 0.55)
			await flash.finished
			_overlay.color = Color(0, 0, 0, 0)
	elif reduced_motion:
		# The accessible version: a short crossfade and a cue, no sweep.
		var quiet := create_tween()
		quiet.tween_property(_overlay, "color:a", 1.0, FADE_TIME * 0.6)
		quiet.tween_callback(func() -> void:
			current_era = era
			era_changed.emit(from, era))
		quiet.tween_property(_overlay, "color:a", 0.0, FADE_TIME * 0.6)
		await quiet.finished
	else:
		await _sweep(from, era)

	_shifting = false


## The band crossing a held image. Eva and the camera are untouched for the
## whole 900 ms — that is the entire point, and it is why this is a shader on
## an overlay rather than anything that moves the world.
func _sweep(from: Era.Id, era: Era.Id) -> void:
	if _band_material == null:
		# No shader: fall back to the plain fade rather than skipping the
		# swap, which would strand the player in the wrong era.
		current_era = era
		era_changed.emit(from, era)
		return

	var vp := Vector2(get_viewport().get_visible_rect().size)
	_band_material.set_shader_parameter("aspect", vp.x / maxf(1.0, vp.y))
	_band_material.set_shader_parameter("origin", band_origin)
	_band_material.set_shader_parameter("progress", 0.0)
	_band_material.set_shader_parameter("strength", 0.0)
	_band.visible = true

	Audio.play_sfx("wheel_engage")
	var tween := create_tween()
	tween.set_parallel(false)
	# 0.00 - 0.12  the detent takes.
	tween.tween_interval(SHIFT_ENGAGE)
	# 0.12 - 0.30  the band appears and starts out.
	tween.tween_callback(func() -> void: Audio.play_sfx("wheel_resonance"))
	tween.tween_method(_set_band.bind(0.0, 0.30), 0.0, 1.0, SHIFT_BAND_IN)
	# 0.30 - 0.62  the world changes under it.
	tween.tween_callback(func() -> void:
		current_era = era
		era_changed.emit(from, era))
	tween.tween_method(_set_band.bind(0.30, 0.92), 0.0, 1.0, SHIFT_SWEEP)
	# 0.62 - 0.78  light, water and material settle as the band clears.
	tween.tween_method(_set_band.bind(0.92, 1.25), 0.0, 1.0, SHIFT_SETTLE)
	# 0.78 - 0.90  back to stillness.
	tween.tween_callback(func() -> void: Audio.play_sfx("wheel_stop"))
	tween.tween_interval(SHIFT_STILL)
	await tween.finished

	_band.visible = false


## One step of the sweep. `t` runs 0..1 within the stage; the band's own
## position runs from `a` to `b`, and its strength eases in at the start and
## out at the very end so it never pops on or off.
func _set_band(t: float, a: float, b: float) -> void:
	var p := lerpf(a, b, t)
	_band_material.set_shader_parameter("progress", p)
	# Full strength across the middle; off at both ends.
	var strength := clampf(p / 0.12, 0.0, 1.0) * clampf((1.25 - p) / 0.22, 0.0, 1.0)
	_band_material.set_shader_parameter("strength", strength)


func is_shifting() -> bool:
	return _shifting


# --- Cross-era knowledge (seed of PersistenceManager) ---------------------

func learn(id: String) -> void:
	if _knowledge.has(id):
		return
	_knowledge[id] = true
	knowledge_gained.emit(id)


## Wipe what Eva has learned. Needed for starting a new game, and for tests
## that have to re-run a discovery.
func reset_knowledge() -> void:
	_knowledge.clear()


func knows(id: String) -> bool:
	return _knowledge.has(id)


func to_dict() -> Dictionary:
	var unlocked_out: Dictionary = {}
	for era: Era.Id in Era.ALL:
		unlocked_out[str(int(era))] = bool(unlocked.get(era, true))
	return {
		"era": int(current_era),
		"unlocked": unlocked_out,
		"knowledge": _knowledge.keys(),
	}


func from_dict(data: Dictionary) -> void:
	_knowledge.clear()
	for id: Variant in data.get("knowledge", []):
		_knowledge[String(id)] = true
	for key: Variant in data.get("unlocked", {}):
		unlocked[int(String(key)) as Era.Id] = bool(data["unlocked"][key])
	# Set the era directly: a restore should not play a transition.
	var from := current_era
	current_era = int(data.get("era", int(Era.Id.PRESENT))) as Era.Id
	_hard_cut = false
	_shifting = false
	era_changed.emit(from, current_era)
