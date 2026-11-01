## StoryTrigger — a volume that sets a story flag when Eva walks into it.
##
## This is how a paused scene knows the player has arrived somewhere and can
## start talking again. A dialogue script says
##
##     @ handover at_trench_bottom teach_dig
##
## and the trigger named `at_trench_bottom` sets that flag on entry.
##
## Era-aware in the same way interactables are: a trigger in 1900 BCE does not
## fire while you are standing in 2026.
class_name StoryTrigger
extends Area3D

const PLAYER_LAYER_MASK := 16

## The flag to set. By convention it matches this node's name.
@export var flag: String = ""
@export var once: bool = true

var era: Era.Id = Era.Id.PRESENT
var _fired := false


func _ready() -> void:
	if flag.is_empty():
		flag = name
	collision_layer = 0
	collision_mask = PLAYER_LAYER_MASK
	monitoring = true
	var root := _find_era_root()
	if root:
		era = root.era_id
	body_entered.connect(_on_body_entered)


func _find_era_root() -> EraRoot:
	var node := get_parent()
	while node != null:
		if node is EraRoot:
			return node
		node = node.get_parent()
	return null


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if once and _fired:
		return
	if era != TimeShift.current_era:
		return
	_fired = true
	Story.set_flag(flag)
