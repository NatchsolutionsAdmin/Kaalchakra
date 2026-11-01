## SignMarker — one carved sign on a wall, in one era.
##
## The same sign exists three times in the world, once per morning. Touching
## it advances the decipherment chain if this is the right morning for the
## next step, and says why not if it is not. The refusal is the teaching: the
## player learns the rule by being told they are in the wrong century.
extends Interactable

@export var sign_id: String = ""


func prompt_text() -> String:
	if Decipher.is_confirmed(sign_id):
		return "Read it again"
	if not Decipher.can_advance(sign_id, era):
		return "Examine the marks"
	match Decipher.next_step(sign_id):
		Decipher.Step.LEARNED:
			return "Learn the sign"
		Decipher.Step.MATCHED:
			return "Match it to the wall"
		_:
			return "Check it against the scan"


func _activate(by: Node3D) -> void:
	if Decipher.is_confirmed(sign_id):
		var entry: Dictionary = Decipher.signs.get(sign_id, {})
		Interactions.say("%s.  %s" % [entry.get("name", sign_id), entry.get("confirm", "")], 6.0)
		return
	var line := Decipher.advance(sign_id, era)
	if line.is_empty():
		Interactions.say(Decipher.blocked_reason(sign_id, era), 5.0)
		return
	var name: String = Decipher.signs[sign_id].get("name", sign_id)
	var p := Decipher.header_progress()
	var tail := ""
	if int(Decipher.signs[sign_id].get("header", 0)) > 0 and p.y > 0:
		tail = "\n\nThe header:  %s   (%d of %d)" % [Decipher.header_text(), p.x, p.y]
	Interactions.say("%s — %s%s" % [name, line, tail], 8.0)
	super._activate(by)
