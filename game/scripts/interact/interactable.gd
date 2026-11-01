## Interactable — base class for anything Eva can press E on.
##
## It is an Area3D: an invisible volume that reports when a body enters it.
## This one only listens for the player (collision layer 5), registers itself
## with the `Interactions` autoload while she is inside, and unregisters on exit.
##
## Supports both a tap (hold_time = 0) and a hold (hold_time > 0, used by the
## excavation site). Subclasses override prompt_text() / is_available() /
## _activate() rather than touching any of the plumbing below.
class_name Interactable
extends Area3D

signal used(by: Node3D)
signal hold_progress(ratio: float)

const PLAYER_LAYER_MASK := 16  # physics layer 5 — see Project Settings -> Layer Names

@export var prompt: String = "Examine"
## Seconds the player must hold E. 0 = instant.
@export var hold_time: float = 0.0

## Which era this belongs to. Auto-filled from the owning EraRoot in _ready(),
## so it can never drift out of sync with where the node actually sits.
var era: Era.Id = Era.Id.PRESENT

var _held := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = PLAYER_LAYER_MASK
	monitoring = true
	var found := _find_era_root()
	if found:
		era = found.era_id
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _find_era_root() -> EraRoot:
	var node := get_parent()
	while node != null:
		if node is EraRoot:
			return node
		node = node.get_parent()
	return null


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		Interactions.register(self)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		release()
		Interactions.unregister(self)


# --- API the player script calls ----------------------------------------

## Shown in the HUD prompt. Override to make it react to story state.
func prompt_text() -> String:
	return prompt


## Seconds of hold required right now. Override for conditional holds.
func hold_seconds() -> float:
	return hold_time


## False = do not offer this at all any more (e.g. already excavated).
func is_available() -> bool:
	return true


func press(by: Node3D) -> void:
	if hold_seconds() <= 0.0:
		_activate(by)


func hold(by: Node3D, delta: float) -> void:
	var need := hold_seconds()
	if need <= 0.0:
		return
	_held += delta
	hold_progress.emit(clampf(_held / need, 0.0, 1.0))
	if _held >= need:
		release()
		_activate(by)


func release() -> void:
	if _held != 0.0:
		_held = 0.0
		hold_progress.emit(0.0)


func _activate(by: Node3D) -> void:
	used.emit(by)
