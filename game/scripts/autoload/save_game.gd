## SaveGame — saving, loading, checkpoints and the phone's lifecycle (R4.1,
## R4.2, CLAUDE.md §9).
##
## Autoloaded as `SaveGame`. Two different jobs that share one snapshot:
##
##   * SAVE is for leaving. A call comes in, the player swaps apps, the phone
##     dies — the game must come back exactly where it was. Written to disk,
##     automatically, often.
##   * CHECKPOINT is for failing. The trench collapses, Eva drowns, a watchman
##     sees her — and she is back on her feet in under a minute (R2.8). Kept
##     in memory, because it has to be instant and must not survive a quit.
##
## It does not know what any system contains. Each one hands over a plain
## dictionary and takes one back, so adding a system later means adding two
## lines here and nothing else.
extends Node

const PATH := "user://save_01.json"
const VERSION := 1
## Longest gap between a change happening and it being on disk.
const AUTOSAVE_EVERY := 6.0

signal saved(reason: String)
signal loaded()
signal checkpoint_set(name: String)
signal checkpoint_restored(name: String)

var autosave := true

var _dirty := false
var _since_save := 0.0
var _checkpoint: Dictionary = {}
var _checkpoint_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.objective_changed.connect(func(_t: String) -> void: mark_dirty())
	Story.flag_set.connect(func(_n: String) -> void: mark_dirty())
	Story.skill_unlocked.connect(func(_n: String) -> void: mark_dirty())
	TimeShift.era_changed.connect(func(_f: Era.Id, _t: Era.Id) -> void: mark_dirty())
	TimeShift.knowledge_gained.connect(func(_id: String) -> void: mark_dirty())
	Decipher.sign_advanced.connect(func(_id: String, _s: int) -> void: mark_dirty())


func _process(delta: float) -> void:
	if not autosave or not _dirty:
		return
	_since_save += delta
	if _since_save >= AUTOSAVE_EVERY:
		save_now("autosave")


## The phone is going away. This is the one that actually matters on mobile:
## there may be no later.
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			if autosave and _dirty:
				save_now("leaving")


func mark_dirty() -> void:
	_dirty = true


# --- the snapshot --------------------------------------------------------

func snapshot() -> Dictionary:
	var data := {
		"version": VERSION,
		"time_shift": TimeShift.to_dict(),
		"story": Story.to_dict(),
		"decipher": Decipher.to_dict(),
		"dialogue": Dialogue.state(),
	}
	var eva := _player()
	if eva:
		var p: Vector3 = eva.global_position
		data["player"] = {"x": p.x, "y": p.y, "z": p.z, "facing": eva.get("_facing")}
	return data


func restore(data: Dictionary) -> void:
	if int(data.get("version", 0)) != VERSION:
		push_warning("SaveGame: save is version %s, this build is %d. Ignoring."
			% [data.get("version", "?"), VERSION])
		return
	TimeShift.from_dict(data.get("time_shift", {}))
	Story.from_dict(data.get("story", {}))
	Decipher.from_dict(data.get("decipher", {}))
	var eva := _player()
	if eva and data.has("player"):
		var p: Dictionary = data["player"]
		eva.global_position = Vector3(p.get("x", 0.0), p.get("y", 0.0), p.get("z", 0.0))
		eva.set("velocity", Vector3.ZERO)
		eva.set("_facing", float(p.get("facing", 0.0)))
	# Dialogue last: restoring it can start a scene, which wants the world
	# already in the right state.
	Dialogue.restore(data.get("dialogue", {}))
	_dirty = false
	_since_save = 0.0
	loaded.emit()


# --- disk ----------------------------------------------------------------

func save_now(reason: String = "manual") -> bool:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveGame: cannot write %s" % PATH)
		return false
	f.store_string(JSON.stringify(snapshot(), "\t"))
	f.close()
	_dirty = false
	_since_save = 0.0
	saved.emit(reason)
	return true


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func load_game() -> bool:
	if not has_save():
		return false
	var text := FileAccess.open(PATH, FileAccess.READ).get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveGame: %s is not readable." % PATH)
		return false
	restore(parsed)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


# --- checkpoints ---------------------------------------------------------

## Mark a place worth coming back to. Call it when the player reaches safety,
## not when they reach danger.
func set_checkpoint(name: String = "") -> void:
	_checkpoint = snapshot()
	_checkpoint_name = name
	checkpoint_set.emit(name)


func has_checkpoint() -> bool:
	return not _checkpoint.is_empty()


## Failure/retry. In memory, so it is instant — the design budget is back on
## your feet inside thirty to sixty seconds (R2.8), and loading a file is not
## how you hit that.
func restore_checkpoint() -> bool:
	if _checkpoint.is_empty():
		return false
	restore(_checkpoint.duplicate(true))
	checkpoint_restored.emit(_checkpoint_name)
	return true


func clear_checkpoint() -> void:
	_checkpoint.clear()
	_checkpoint_name = ""


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D
