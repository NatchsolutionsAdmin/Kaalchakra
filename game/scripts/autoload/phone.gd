## Phone — Eva calls her mother (R3.3).
##
## Autoloaded as `Phone`. It is the hint system and it is a relationship, and
## the design only works if it is both: the help you get is help *Sakshi*
## would give, in her voice, about the thing she spent thirty years being
## laughed at for. Asking for a hint should feel like phoning your mum, not
## opening a menu.
##
## Every line it can say is already written in data/signs/index.signs, by
## whoever wrote the signs. This file only decides WHICH one is useful now.
extends Node

signal call_started(contact: String)
signal line_spoken(speaker: String, text: String)
signal call_ended(contact: String)

const CONNECT_TIME := 0.9

var in_call := false
var contact := ""

var _queue: Array = []
var _asked: Dictionary = {}       # hints already given, so she does not repeat
var _connecting := 0.0


func _process(delta: float) -> void:
	if _connecting > 0.0:
		_connecting -= delta
		if _connecting <= 0.0:
			_speak_next()


func available(who: String = "sakshi") -> bool:
	return Story.has_contact(who)


func can_call(who: String = "sakshi") -> bool:
	return available(who) and not in_call and not Dialogue.is_active()


func start(who: String = "sakshi") -> bool:
	if not can_call(who):
		return false
	in_call = true
	contact = who
	_queue = _script_for(who)
	_connecting = CONNECT_TIME
	call_started.emit(who)
	return true


## Tap to move the call on; hangs up when there is nothing left to say.
func advance() -> void:
	if not in_call or _connecting > 0.0:
		return
	if _queue.is_empty():
		hang_up()
		return
	_speak_next()


func hang_up() -> void:
	if not in_call:
		return
	in_call = false
	var who := contact
	contact = ""
	_queue.clear()
	call_ended.emit(who)


func _speak_next() -> void:
	if _queue.is_empty():
		hang_up()
		return
	var line: Array = _queue.pop_front()
	line_spoken.emit(line[0], line[1])


# --- choosing what is actually useful -----------------------------------

func _script_for(who: String) -> Array:
	if who != "sakshi":
		return [["?", "No answer."]]

	# Is there a sign she could read right now, where she is standing?
	for id: String in Decipher.order:
		if not Decipher.is_confirmed(id) and Decipher.can_advance(id, TimeShift.current_era):
			return _exchange(id, "And you're in the right morning for it. Go and look.")

	# Otherwise the one furthest along, and where it has to happen.
	var best := ""
	var best_step := -1
	for id: String in Decipher.order:
		if Decipher.is_confirmed(id):
			continue
		var step: int = Decipher.step_of(id)
		if step > best_step:
			best_step = step
			best = id
	if not best.is_empty() and best_step > 0:
		return _exchange(best, "You won't do it from where you're standing. That one wants %s."
			% Era.TITLE[Decipher.era_for_next(best)])

	# Nothing learned yet — point her at the only place anyone can read.
	if not Decipher.order.is_empty():
		return _exchange(Decipher.order[0],
			"Nobody in your century can read it, beta. Go and find someone whose century could.")

	return [["EVA", "Ma?"], ["SAKSHI", "Go to bed, Eva."]]


func _exchange(sign_id: String, nudge: String) -> Array:
	var entry: Dictionary = Decipher.signs.get(sign_id, {})
	var hint: String = Decipher.hint_for(sign_id)
	# Her hints are written as "Sakshi: ..." in the sign file.
	if hint.begins_with("Sakshi:"):
		hint = hint.substr(7).strip_edges().trim_prefix("\"").trim_suffix("\"")
	var first_time := not _asked.has(sign_id)
	_asked[sign_id] = true

	var out: Array = []
	out.append(["EVA", "Ma. I'm looking at something I can't read."])
	if first_time:
		out.append(["SAKSHI", "Good. That means it's worth reading."])
	else:
		out.append(["SAKSHI", "The same one? Right."])
	out.append(["SAKSHI", hint])
	out.append(["SAKSHI", nudge])
	return out


func reset() -> void:
	hang_up()
	_asked.clear()
