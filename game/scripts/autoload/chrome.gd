## Chrome — what the interface should be showing, right now.
##
## The art review's complaint about the HUD was not that it was ugly. It was
## that it was *always all there*: objective text, control hints and an era
## label sat on top of the picture whether or not they were any use, and the
## picture is the thing the player came for.
##
## So the review gives a context matrix (ART-DIRECTION.md §6), and this file
## is that table, written once:
##
##   Element    Explore             Puzzle              Dialogue
##   Wheel      small               visible if allowed  hidden
##   Joystick   touch / idle fade   hidden              hidden
##   Action     near interactable   puzzle contextual   hidden
##   Location   on entry            usually hidden      hidden
##   Journal    secondary access    available           usually hidden
##
## It lives here rather than in the HUD because the HUD and the thumb controls
## are separate CanvasLayers, and two screens each deciding for themselves
## when to hide is how you end up with a joystick floating over a cutscene.
extends Node

enum Context { EXPLORE, PUZZLE, DIALOGUE }

signal context_changed(to: Context)
## Fires when the player stops touching the screen for a while, and again when
## they touch it. Driving the fade from a signal keeps the timer in one place.
signal idle_changed(idle: bool)

## How long a thumb has to be still before the controls get out of the way.
const IDLE_AFTER := 4.0

var context: Context = Context.EXPLORE:
	set(value):
		if value == context:
			return
		context = value
		context_changed.emit(context)

var idle := false:
	set(value):
		if value == idle:
			return
		idle = value
		idle_changed.emit(idle)

var _since_input := 0.0
var _in_puzzle := false
## Mirrored from the signals rather than read off Dialogue, whose `_active`
## is private and should stay that way.
var _talking := false
var _on_call := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Dialogue.started.connect(func(_id: String) -> void: _set_talking(true))
	Dialogue.finished.connect(func(_id: String) -> void: _set_talking(false))
	Phone.call_started.connect(func(_who: String) -> void: _set_on_call(true))
	Phone.call_ended.connect(func(_who: String) -> void: _set_on_call(false))


func _set_talking(value: bool) -> void:
	_talking = value
	_refresh()


func _set_on_call(value: bool) -> void:
	_on_call = value
	_refresh()


## Puzzle controllers call this when they take over the screen.
func set_puzzle(active: bool) -> void:
	_in_puzzle = active
	_refresh()


func _refresh() -> void:
	if _talking or _on_call:
		context = Context.DIALOGUE
	elif _in_puzzle:
		context = Context.PUZZLE
	else:
		context = Context.EXPLORE


## Any touch, drag, key or click counts as the player being present.
func poke() -> void:
	_since_input = 0.0
	idle = false


func _process(delta: float) -> void:
	_since_input += delta
	if _since_input >= IDLE_AFTER:
		idle = true


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag \
			or event is InputEventMouseButton or event is InputEventKey \
			or event is InputEventJoypadButton:
		poke()


# --- the matrix, read-only ------------------------------------------------
#
# One function per row. Screens ask these questions; they never test the
# context themselves, so the table above stays the only copy.

## The Wheel is small while exploring, full-size while a puzzle allows it,
## and gone while anyone is talking.
func shows_wheel() -> bool:
	return context != Context.DIALOGUE


## Hidden outright in a puzzle or a conversation; in exploration it is there
## while a thumb is down and fades out when the player stops.
func shows_joystick() -> bool:
	return context == Context.EXPLORE and not idle


## Visibility still depends on there being something to act on — this only
## says whether the button is allowed on screen at all.
func shows_action() -> bool:
	return context != Context.DIALOGUE


## The location caption announces a place on arrival and then leaves.
func shows_location() -> bool:
	return context == Context.EXPLORE


## Reachable while exploring, properly available during a puzzle, and out of
## the way while someone is speaking.
func shows_journal() -> bool:
	return context != Context.DIALOGUE
