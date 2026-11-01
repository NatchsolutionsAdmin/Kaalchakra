## Dev-only: turns a .dialogue script into a recording sheet.
##
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path game \
##       scenes/dev/VOManifest.tscn
##
## Writes a CSV next to the script: one row per spoken line, with the exact
## filename that line's audio must have. Open it in Numbers or Excel — it is
## the script you hand a voice actor, and the checklist for what you get back.
##
## Re-run it whenever the writing changes. Diff the two CSVs and you know
## precisely which lines need re-recording.
extends Node

const SCRIPTS := ["res://data/dialogue/prologue_overburden.dialogue"]


func _ready() -> void:
	for path: String in SCRIPTS:
		_write_manifest(path)
	get_tree().quit()


func _write_manifest(path: String) -> void:
	var scene_id := path.get_file().get_basename()
	var parsed := DialogueParser.parse_file(path)
	if not parsed["errors"].is_empty():
		print("problems in %s:" % scene_id)
		for e: String in parsed["errors"]:
			print("   ", e)

	var out_path := path.get_base_dir() + "/" + scene_id + ".recording.csv"
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f == null:
		push_error("Could not write %s" % out_path)
		return

	f.store_csv_line(["audio_file", "speaker", "direction", "line", "chunk"])
	var rows := 0
	var speakers: Dictionary = {}
	# Chunk order, so the sheet reads in the order it is performed.
	for chunk: String in parsed["order"]:
		for step: Dictionary in parsed["chunks"][chunk]:
			if step["type"] != "line":
				continue
			var text: String = step["text"]
			if text.is_empty():
				continue  # a silent beat needs no recording
			f.store_csv_line([
				"%s/%s.ogg" % [scene_id, step["id"]],
				step["speaker"],
				step["direction"],
				text,
				chunk,
			])
			rows += 1
			speakers[step["speaker"]] = int(speakers.get(step["speaker"], 0)) + 1
	f.close()

	print("%s — %d lines to record" % [scene_id, rows])
	for who: String in speakers:
		print("   %-9s %d" % [who, speakers[who]])
	print("   written to ", ProjectSettings.globalize_path(out_path))
