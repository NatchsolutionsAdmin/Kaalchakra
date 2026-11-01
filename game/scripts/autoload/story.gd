## Story — what the game remembers about the player's run.
##
## Autoloaded as `Story`. This is the seed of three systems in ARCHITECTURE §3.2
## that are small enough to share one file for now: ChoiceTracker (flags),
## QuestManager (the objective) and SkillManager (unlocks). If any of them grows
## teeth, split it out — but three dictionaries do not need three autoloads yet.
##
## Everything here is plain data, so SaveSystem (R4.1) can write it straight out.
extends Node

signal flag_set(name: String)
signal objective_changed(text: String)
signal skill_unlocked(name: String)
signal contact_available(name: String)

var objective: String = ""
var _flags: Dictionary = {}
var _skills: Dictionary = {}
var _contacts: Dictionary = {}


func set_flag(name: String, value: bool = true) -> void:
	if _flags.get(name, false) == value:
		return
	_flags[name] = value
	flag_set.emit(name)


func has_flag(name: String) -> bool:
	return _flags.get(name, false)


func set_objective(text: String) -> void:
	if objective == text:
		return
	objective = text
	objective_changed.emit(text)


func unlock_skill(name: String) -> void:
	if _skills.has(name):
		return
	_skills[name] = true
	skill_unlocked.emit(name)


func has_skill(name: String) -> bool:
	return _skills.has(name)


## Someone Eva can phone — the Sakshi hint system (R3.3) hangs off this.
func make_contact_available(name: String) -> void:
	if _contacts.has(name):
		return
	_contacts[name] = true
	contact_available.emit(name)


func has_contact(name: String) -> bool:
	return _contacts.has(name)


func reset() -> void:
	_flags.clear()
	_skills.clear()
	_contacts.clear()
	set_objective("")


func to_dict() -> Dictionary:
	return {
		"objective": objective,
		"flags": _flags.duplicate(),
		"skills": _skills.duplicate(),
		"contacts": _contacts.duplicate(),
	}
