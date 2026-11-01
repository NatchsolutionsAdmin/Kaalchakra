## Settings — options that outlive a run.
##
## Autoloaded as `Options`. Kept out of the save file on purpose: a player's
## volume and accessibility choices belong to the player, not to a
## playthrough, and must survive starting a new game.
extends Node

const PATH := "user://settings.cfg"

signal changed()

var music := 0.8
var sfx := 0.9
var voice := 1.0
var reduced_motion := false
var large_text := false


func _ready() -> void:
	load_settings()
	apply()


func apply() -> void:
	_set_bus("Music", music)
	_set_bus("SFX", sfx)
	_set_bus("Voice", voice)
	TimeShift.reduced_motion = reduced_motion
	changed.emit()


func _set_bus(name: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(name)
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, value <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "voice", voice)
	cfg.set_value("access", "reduced_motion", reduced_motion)
	cfg.set_value("access", "large_text", large_text)
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	music = float(cfg.get_value("audio", "music", music))
	sfx = float(cfg.get_value("audio", "sfx", sfx))
	voice = float(cfg.get_value("audio", "voice", voice))
	reduced_motion = bool(cfg.get_value("access", "reduced_motion", reduced_motion))
	large_text = bool(cfg.get_value("access", "large_text", large_text))
