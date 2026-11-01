## LoreMarker — something Evara reads. Optionally teaches her a fact that other
## eras are allowed to react to.
##
## This is the "learn it in one era" half of the core loop (R2.2). It does not
## know the dig site exists; it just writes a string into TimeShift.knowledge.
extends Interactable

@export_multiline var line: String = ""
## A key written into TimeShift. Other eras check it with TimeShift.knows(...).
@export var grants_knowledge: String = ""
## If set, the prompt and line change once already read.
@export_multiline var line_after: String = ""
@export var once: bool = false

var _read := false


func prompt_text() -> String:
	if _read and not line_after.is_empty():
		return "Read again"
	return prompt


func is_available() -> bool:
	return not (once and _read)


func _activate(by: Node3D) -> void:
	var text := line
	if _read and not line_after.is_empty():
		text = line_after
	_read = true
	if not grants_knowledge.is_empty():
		TimeShift.learn(grants_knowledge)
	Interactions.say(text, 6.0)
	super._activate(by)
