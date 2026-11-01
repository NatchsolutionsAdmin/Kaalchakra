## Interactions — keeps track of what Eva could touch right now, and carries
## short bits of on-screen text.
##
## An autoload (global name `Interactions`). Each Interactable registers itself
## here when the player walks into range and unregisters on the way out. This
## node hands back the single nearest candidate, filtered to the live era, so
## the player script and the HUD never have to search the scene tree.
extends Node

signal focus_changed(interactable: Interactable)
## A line of text for the HUD banner. Dialogue proper (R3.1) replaces this later.
signal message(text: String, seconds: float)

var _candidates: Array[Interactable] = []
var _focus: Interactable = null


func _ready() -> void:
	TimeShift.era_changed.connect(_on_era_changed)


func _process(_delta: float) -> void:
	# Cheap: the candidate list is only ever a handful of nodes, and this keeps
	# the focus correct as Eva moves between two things that overlap.
	if _candidates.size() > 1:
		_refresh()


func register(node: Interactable) -> void:
	if node not in _candidates:
		_candidates.append(node)
		_refresh()


func unregister(node: Interactable) -> void:
	if _candidates.has(node):
		_candidates.erase(node)
		_refresh()


func focus() -> Interactable:
	return _focus


func say(text: String, seconds: float = 4.0) -> void:
	message.emit(text, seconds)


func _on_era_changed(_from: Era.Id, _to: Era.Id) -> void:
	_refresh()


## Nearest valid candidate wins. Valid = still alive, in the live era, and still
## offering itself (an excavated dig site drops out).
func _refresh() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var best: Interactable = null
	var best_dist := INF

	for node: Interactable in _candidates:
		if not is_instance_valid(node):
			continue
		if node.era != TimeShift.current_era:
			continue
		if not node.is_available():
			continue
		var d := 0.0
		if player != null:
			d = player.global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node

	if best != _focus:
		if _focus != null and is_instance_valid(_focus):
			_focus.release()
		_focus = best
		focus_changed.emit(_focus)
