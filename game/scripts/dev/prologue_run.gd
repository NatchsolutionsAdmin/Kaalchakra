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
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().physics_frame
	# The Prologue opens at the top of Trench 4, not out on the apron.
	var eva := main.get_node_or_null("Eva") as Node3D
	if eva:
		# Out on the basin floor, so walking up to Trench 4 is a real walk.
		eva.global_position = Vector3(-6.0, -6.6, -6.0)
		var pivot := eva.get_node_or_null("CameraPivot") as Node3D
		if pivot:
			pivot.rotation.y = PI
			pivot.global_position = eva.global_position + Vector3.UP * 1.45
	await get_tree().physics_frame
	var errors := Dialogue.play_file(SCRIPT_PATH)
	if not errors.is_empty():
		print("\n--- problems in the script ---")
		for e: String in errors:
			print("  ", e)
	Dialogue.finished.connect(func(_id: String) -> void:
		if Dialogue.is_waiting():
			print("\n--- paused: over to you. waiting for '%s' ---"
				% Dialogue.waiting_for())
			return
		print("\n--- end of the Prologue ---")
		print("flags set: ", Story.to_dict()["flags"].keys())
		var todo := Dialogue.unhandled_directives()
		if not todo.is_empty():
			print("the script asked for, not built yet: ", ", ".join(todo))
		var absent := Audio.missing()
		if not absent.is_empty():
			print("\naudio the script asked for and we do not have (%d):" % absent.size())
			for a: String in absent:
				print("   ", a))
