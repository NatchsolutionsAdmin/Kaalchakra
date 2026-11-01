## AudioManager — music, sound effects and voice.
##
## Autoloaded as `Audio`. Nothing calls this directly from a scene; the
## dialogue script's `@ music` and `@ sfx` directives land here, and a line's
## voice clip plays automatically from the line's id.
##
## Files are looked up by name, not wired up by hand, so adding sound means
## dropping a file in the right folder with the right name — no code, no Godot:
##
##   audio/music/<cue>.ogg       @ music bansuri_sparse  ->  bansuri_sparse.ogg
##   audio/sfx/<cue>.ogg         @ sfx phone_dial        ->  phone_dial.ogg
##   audio/voice/<scene>/<id>.ogg                        ->  start_03.ogg
##
## A cue with no file is NOT an error — most of them have no file yet. Each
## missing one is recorded once so `missing()` can print the shopping list.
extends Node

const MUSIC_DIR := "res://audio/music/"
const SFX_DIR := "res://audio/sfx/"
const VOICE_DIR := "res://audio/voice/"
const EXTENSIONS := [".ogg", ".wav", ".mp3"]
## Cue names that mean "stop", not "play a file called this".
const STOP_CUES := ["silence", "drop_out", "stop", "none", "off"]

const FADE := 0.8

var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_on_a := true
var _voice: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _missing: Array[String] = []
var _current_music := ""


func _ready() -> void:
	_music_a = _make_player("Music")
	_music_b = _make_player("Music")
	_voice = _make_player("Voice")
	# A small pool, so overlapping effects do not cut each other off.
	for _i in 6:
		_sfx.append(_make_player("SFX"))


func _make_player(bus: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus if AudioServer.get_bus_index(bus) != -1 else "Master"
	add_child(p)
	return p


# --- music ---------------------------------------------------------------

func play_music(cue: String) -> bool:
	if cue in STOP_CUES:
		stop_music()
		return true
	if cue == _current_music:
		return true
	var stream := _load(MUSIC_DIR, cue)
	if stream == null:
		return false
	_current_music = cue
	var incoming := _music_b if _music_on_a else _music_a
	var outgoing := _music_a if _music_on_a else _music_b
	_music_on_a = not _music_on_a

	incoming.stream = stream
	incoming.volume_db = -40.0
	incoming.play()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(incoming, "volume_db", 0.0, FADE)
	if outgoing.playing:
		tween.tween_property(outgoing, "volume_db", -40.0, FADE)
		tween.chain().tween_callback(outgoing.stop)
	return true


func stop_music() -> void:
	_current_music = ""
	for p: AudioStreamPlayer in [_music_a, _music_b]:
		if p.playing:
			var tween := create_tween()
			tween.tween_property(p, "volume_db", -40.0, FADE)
			tween.tween_callback(p.stop)


# --- effects and voice ---------------------------------------------------

func play_sfx(cue: String) -> bool:
	var stream := _load(SFX_DIR, cue)
	if stream == null:
		return false
	var p := _sfx[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx.size()
	p.stream = stream
	p.volume_db = 0.0
	p.play()
	return true


## One clip per spoken line. Silent (and harmless) until the file exists.
func play_voice(scene_id: String, line_id: String) -> bool:
	var stream := _load(VOICE_DIR + scene_id + "/", line_id)
	if stream == null:
		return false
	_voice.stop()
	_voice.stream = stream
	_voice.play()
	return true


func stop_voice() -> void:
	_voice.stop()


func is_voice_playing() -> bool:
	return _voice.playing


# --- lookup --------------------------------------------------------------

func _load(dir: String, cue: String) -> AudioStream:
	if cue.is_empty():
		return null
	for ext: String in EXTENSIONS:
		var path := dir + cue + ext
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	var want := dir + cue
	if want not in _missing:
		_missing.append(want)
	return null


## Every cue the game asked for and could not find — the shopping list.
func missing() -> Array[String]:
	return _missing.duplicate()


func clear_missing() -> void:
	_missing.clear()
