## Decipher — the three-era decipherment chain (R3.4), Chapter 2's spine.
##
## Autoloaded as `Decipher`. A sign is not "found", it is *built up*: learned
## fresh in 1900 BCE, recognised eroded in 2026, verified in WARDEN's scan in
## 2087. One sign, three mornings, in order. That ordering IS the chapter, so
## it is enforced here rather than left to level scripting.
##
## State is a plain dictionary of id -> step, ready for SaveSystem (R4.1).
extends Node

enum Step { UNKNOWN, LEARNED, MATCHED, CONFIRMED }

const PATH := "res://data/signs/index.signs"
## Which era each step of the chain happens in.
const ERA_FOR_STEP := {
	Step.LEARNED: Era.Id.PAST,
	Step.MATCHED: Era.Id.PRESENT,
	Step.CONFIRMED: Era.Id.FUTURE,
}

signal sign_advanced(id: String, step: Step)
signal header_readable()

var signs: Dictionary = {}
var order: Array[String] = []
var errors: Array = []

var _state: Dictionary = {}
var _header_announced := false


func _ready() -> void:
	var parsed := SignIndex.parse_file(PATH)
	signs = parsed["signs"]
	order = parsed["order"]
	errors = parsed["errors"]
	for e: String in errors:
		push_error("SignIndex: %s" % e)


func step_of(id: String) -> Step:
	return _state.get(id, Step.UNKNOWN)


func knows(id: String) -> bool:
	return step_of(id) >= Step.LEARNED


func is_confirmed(id: String) -> bool:
	return step_of(id) == Step.CONFIRMED


## The next step this sign is waiting for, and the era it has to happen in.
func next_step(id: String) -> Step:
	var s := step_of(id)
	return Step.CONFIRMED if s == Step.CONFIRMED else (s + 1) as Step


func era_for_next(id: String) -> Era.Id:
	return ERA_FOR_STEP[next_step(id)]


## Can this sign advance right now, in this era? The whole point is that it
## usually cannot — you have to go and stand in the right morning.
func can_advance(id: String, era: Era.Id) -> bool:
	if not signs.has(id) or is_confirmed(id):
		return false
	return era_for_next(id) == era


## Why not — so the game can say something better than nothing happening.
func blocked_reason(id: String, era: Era.Id) -> String:
	if not signs.has(id):
		return "That sign is not in the index."
	if is_confirmed(id):
		return "Already read, cross-checked and filed."
	var want: Era.Id = era_for_next(id)
	if want == era:
		return ""
	match next_step(id):
		Step.LEARNED:
			return "Marks, and no idea what they mean. Someone in 1900 BCE could tell her."
		Step.MATCHED:
			return "She knows what it means. She has not found it anywhere real yet — 2026 has the wall."
		_:
			return "She has it twice. One more reading would make it certain, and only WARDEN's scans go that deep."
	return ""


## Advance the chain. Returns the line Eva says, or "" if nothing happened.
func advance(id: String, era: Era.Id) -> String:
	if not can_advance(id, era):
		return ""
	var step: Step = next_step(id)
	_state[id] = step
	sign_advanced.emit(id, step)
	_check_header()
	match step:
		Step.LEARNED:
			return signs[id].get("learn", "")
		Step.MATCHED:
			return signs[id].get("match", "")
		_:
			return signs[id].get("confirm", "")


func hint_for(id: String) -> String:
	return signs.get(id, {}).get("hint", "")


# --- the header ----------------------------------------------------------

## The signs that spell the chamber's header, in order.
func header_signs() -> Array[String]:
	var found: Array[String] = []
	for id: String in order:
		if int(signs[id].get("header", 0)) > 0:
			found.append(id)
	found.sort_custom(func(a: String, b: String) -> bool:
		return int(signs[a]["header"]) < int(signs[b]["header"]))
	return found


func header_progress() -> Vector2i:
	var need := header_signs()
	var done := 0
	for id: String in need:
		if is_confirmed(id):
			done += 1
	return Vector2i(done, need.size())


## "WHAT THE WATER MUST NOT TAKE" — but only once she has earned every word.
func header_text() -> String:
	var words: Array[String] = []
	for id: String in header_signs():
		words.append(signs[id]["name"].get_slice("/", 0).strip_edges()
			if is_confirmed(id) else "·····")
	return " ".join(words)


func _check_header() -> void:
	if _header_announced:
		return
	var p := header_progress()
	if p.y > 0 and p.x == p.y:
		_header_announced = true
		header_readable.emit()


func reset() -> void:
	_state.clear()
	_header_announced = false


func to_dict() -> Dictionary:
	var out: Dictionary = {}
	for id: String in _state:
		out[id] = int(_state[id])
	return {"signs": out, "header_announced": _header_announced}


func from_dict(data: Dictionary) -> void:
	_state.clear()
	var saved: Dictionary = data.get("signs", {})
	for id: Variant in saved:
		_state[String(id)] = int(saved[id]) as Step
	_header_announced = bool(data.get("header_announced", false))
	sign_advanced.emit("", Step.UNKNOWN)
