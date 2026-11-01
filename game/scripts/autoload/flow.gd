## Flow — what runs next (R4.3).
##
## Autoloaded as `Flow`. Owns moving between the menu and a chapter, so no
## other script has to know how a scene is started. Everything that was
## previously "launch this scene by hand from a dev harness" goes through
## here instead.
extends Node

signal chapter_started(id: String)
signal returned_to_menu()

const MENU := "res://scenes/Menu.tscn"

var current_chapter: Dictionary = {}

var _pending: Dictionary = {}
var _load_after := false


## Fresh start of a chapter: wipe the run, load its scene, play its opening.
func start_chapter(entry: Dictionary) -> void:
	if String(entry.get("scene", "")).is_empty():
		push_warning("Flow: '%s' has no scene yet." % entry.get("id", "?"))
		return
	_pending = entry
	_load_after = false
	_go(String(entry["scene"]))


## Pick up where the player left off.
func continue_game() -> bool:
	if not SaveGame.has_save():
		return false
	# Every chapter built so far lives in the same scene; when that stops
	# being true the save will carry its chapter id and this will read it.
	var entry: Dictionary = Chapters.LIST[0]
	for c: Dictionary in Chapters.LIST:
		if Chapters.playable(c):
			entry = c
			break
	_pending = entry
	_load_after = true
	_go(String(entry["scene"]))
	return true


func to_menu() -> void:
	_pending = {}
	_load_after = false
	current_chapter = {}
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU)
	returned_to_menu.emit()


func _go(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	_setup.call_deferred()


func _setup() -> void:
	# Two frames: one for the new scene to exist, one for its _ready chain.
	await get_tree().process_frame
	await get_tree().process_frame
	if _pending.is_empty():
		return
	var entry := _pending
	_pending = {}
	current_chapter = entry

	if _load_after:
		SaveGame.load_game()
	else:
		_new_run(entry)
	chapter_started.emit(String(entry.get("id", "")))


func _new_run(entry: Dictionary) -> void:
	Story.reset()
	Decipher.reset()
	Phone.reset()
	TimeShift.reset_knowledge()
	SaveGame.clear_checkpoint()
	TimeShift.current_era = entry.get("era", Era.Id.PRESENT)
	TimeShift.era_changed.emit(TimeShift.current_era, TimeShift.current_era)

	var script_path := String(entry.get("dialogue", ""))
	if not script_path.is_empty():
		Dialogue.play_file(script_path)
