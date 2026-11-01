## Dev-only: loads the world and plays the Prologue script straight away, so
## the writing can be read in the game rather than in a text editor.
##
##   /Applications/Godot.app/Contents/MacOS/Godot --path game \
##       scenes/dev/Prologue.tscn
##
## Tap anywhere to move on. Tap while the text is still typing to finish the
## line instantly. Choices are the buttons.
extends Node

const SCRIPT_PATH := "res://data/dialogue/prologue_overburden.dialogue"


func _ready() -> void:
	add_child(load("res://scenes/Main.tscn").instantiate())
	await get_tree().process_frame
	var errors := Dialogue.play_file(SCRIPT_PATH)
	if not errors.is_empty():
		print("\n--- problems in the script ---")
		for e: String in errors:
			print("  ", e)
	Dialogue.finished.connect(func(_id: String) -> void:
		print("\n--- end of the Prologue ---")
		print("flags set: ", Story.to_dict()["flags"].keys())
		var todo := Dialogue.unhandled_directives()
		if not todo.is_empty():
			print("the script asked for, not built yet: ", ", ".join(todo)))
