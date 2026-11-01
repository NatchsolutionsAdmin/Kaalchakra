## Dialogue — plays a parsed .dialogue scene.
##
## Autoloaded as `Dialogue`. It walks the steps of a chunk, stops on each
## spoken line until something calls advance(), stops on choices until
## choose() is called, and fires directives as it passes them.
##
## It draws nothing. `scripts/ui/dialogue_ui.gd` listens to the signals and is
## the only thing that knows what a line looks like on screen — so the
## presentation can be rewritten without touching the script logic, and the
## whole thing can be tested headlessly with no UI at all.
##
## Directives it handles itself (story state) are applied here. Anything
## presentational — camera, music, sfx, title cards — is re-emitted as
## `directive` for whoever owns that, and simply logged until those systems
## exist. An unknown directive is never an error: the writer is allowed to ask
## for things that are not built yet.
extends Node

signal started(scene_id: String)
signal finished(scene_id: String)
signal line_shown(speaker: String, text: String, direction: String, id: String)
signal choices_shown(options: Array)
signal directive(name: String, args: Array)

## Directives this node consumes. Everything else is passed along.
const STORY_DIRECTIVES := ["flag", "objective", "skill_unlock", "phone_available", "era"]

var scene_id := ""
var pending_choices: Array = []

var _chunks: Dictionary = {}
var _chunk := ""
var _index := 0
var _active := false
var _unhandled: Array[String] = []


func is_active() -> bool:
	return _active


## Loads and starts a scene. Returns the parse errors, so a caller (or the
## smoke test) can fail loudly on a typo instead of playing a broken scene.
func play_file(path: String, from_chunk: String = "start") -> Array:
	var parsed := DialogueParser.parse_file(path)
	var errors: Array = parsed["errors"]
	if not errors.is_empty():
		for e: String in errors:
			push_error("Dialogue: %s" % e)
	if parsed["chunks"].is_empty():
		return errors
	play(parsed["chunks"], path.get_file().get_basename(), from_chunk)
	return errors


func play(chunks: Dictionary, id: String, from_chunk: String = "start") -> void:
	if not chunks.has(from_chunk):
		push_error("Dialogue: '%s' has no chunk '%s'." % [id, from_chunk])
		return
	_chunks = chunks
	scene_id = id
	_chunk = from_chunk
	_index = 0
	_active = true
	_unhandled.clear()
	started.emit(scene_id)
	_run()


## Called by the UI when the player taps to move on.
func advance() -> void:
	if not _active or not pending_choices.is_empty():
		return
	_index += 1
	_run()


## Called by the UI when the player picks an option.
func choose(index: int) -> void:
	if not _active or index < 0 or index >= pending_choices.size():
		return
	var option: Dictionary = pending_choices[index]
	pending_choices = []
	for d: Dictionary in option["directives"]:
		_apply(d["name"], d["args"])
	_goto(option["target"])


func stop() -> void:
	if not _active:
		return
	Audio.stop_voice()
	_active = false
	pending_choices = []
	var id := scene_id
	scene_id = ""
	finished.emit(id)


## Directive names the writer used that nothing listens to yet. Useful in dev:
## it is the to-do list the script itself is asking for.
func unhandled_directives() -> Array[String]:
	return _unhandled.duplicate()


# --- the walk ------------------------------------------------------------

func _run() -> void:
	while _active:
		var steps: Array = _chunks.get(_chunk, [])
		if _index >= steps.size():
			# Falling off the end of a chunk ends the scene rather than
			# silently hanging, which is the friendlier failure for a writer.
			stop()
			return
		var step: Dictionary = steps[_index]
		match step["type"]:
			"directive":
				_apply(step["name"], step["args"])
				_index += 1
			"goto":
				_goto(step["target"])
				return
			"choices":
				var usable := _visible_options(step["options"])
				if usable.is_empty():
					_index += 1
					continue
				pending_choices = usable
				choices_shown.emit(usable)
				return
			"line":
				if not _passes(step):
					_index += 1
					continue
				# A direction-only beat like "(stops)" has no words, so it has
				# no recording and must not be counted as missing audio.
				if not String(step["text"]).is_empty():
					Audio.play_voice(scene_id, step.get("id", ""))
				line_shown.emit(step["speaker"], step["text"], step["direction"],
					step.get("id", ""))
				return
			_:
				_index += 1


func _goto(target: String) -> void:
	if target == DialogueParser.END:
		stop()
		return
	if not _chunks.has(target):
		push_error("Dialogue: '%s' jumps to missing chunk '%s'." % [scene_id, target])
		stop()
		return
	_chunk = target
	_index = 0
	_run()


func _passes(step: Dictionary) -> bool:
	var condition: String = step.get("condition", "")
	if condition.is_empty():
		return true
	var held := Story.has_flag(condition)
	return not held if step.get("negate", false) else held


func _visible_options(options: Array) -> Array:
	# Options have no conditions yet; this is where [if flag] on a choice goes.
	return options.duplicate()


func _apply(name: String, args: Array) -> void:
	match name:
		"flag":
			if args.size() >= 1:
				Story.set_flag(args[0])
		"objective":
			if args.size() >= 1:
				Story.set_objective(args[0])
		"skill_unlock":
			if args.size() >= 1:
				Story.unlock_skill(args[0])
		"phone_available":
			if args.size() >= 1:
				Story.make_contact_available(args[0])
		"music":
			if args.size() >= 1:
				Audio.play_music(args[0])
		"sfx":
			if args.size() >= 1:
				Audio.play_sfx(args[0])
		"era":
			var map := {"past": Era.Id.PAST, "present": Era.Id.PRESENT, "future": Era.Id.FUTURE}
			if args.size() >= 1 and map.has(args[0]):
				TimeShift.request_shift(map[args[0]])
		_:
			# Camera, title cards, hard cuts: not built yet. The
			# writer is allowed to ask for them; record and move on.
			if name not in _unhandled:
				_unhandled.append(name)
	directive.emit(name, args)
