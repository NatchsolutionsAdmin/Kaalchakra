## DigSite — the "act on it in another era" half of the core loop.
##
## Before Eva has learned where to dig, probing it tells her nothing. Once
## TimeShift.knows(requires_knowledge) is true, the same patch of ground becomes
## a hold-to-excavate prompt that reveals whatever `reveal` points at.
##
## This is the prototype's stand-in for the real excavation minigame (R2.4):
## same shape of interaction, a fraction of the content.
extends Interactable

@export var requires_knowledge: String = ""
@export var dig_seconds: float = 2.4
## Node switched visible when the dig succeeds (the chamber hatch).
## A NodePath rather than a direct Node reference: these scenes are written by
## hand / by tools/greybox_northgate.py, and only the Godot editor emits the
## extra metadata that lets a bare `Node3D` export resolve itself on load.
@export var reveal_path: NodePath
## Node taken AWAY when the dig succeeds — the rubble sealing a doorway. It is
## hidden and its collision switched off, so the opening becomes walkable.
@export var remove_path: NodePath
@export_multiline var line_locked: String = "Silt and salt. Nothing marks this spot."
@export_multiline var line_done: String = ""
@export var grants_knowledge: String = ""

var _dug := false


var reveal: Node3D
var remove: Node3D


func _ready() -> void:
	super._ready()
	if not reveal_path.is_empty():
		reveal = get_node_or_null(reveal_path) as Node3D
		if reveal == null:
			push_warning("DigSite %s: reveal_path '%s' resolves to nothing." % [name, reveal_path])
	if not remove_path.is_empty():
		remove = get_node_or_null(remove_path) as Node3D
		if remove == null:
			push_warning("DigSite %s: remove_path '%s' resolves to nothing." % [name, remove_path])
	if reveal:
		reveal.visible = false


## Hiding a body does not stop you walking into it, so the collision has to be
## switched off as well — on the node and anything under it.
func _open_up(node: Node) -> void:
	if node is CollisionObject3D:
		(node as CollisionObject3D).collision_layer = 0
	for child: Node in node.get_children():
		_open_up(child)


func _unlocked() -> bool:
	return requires_knowledge.is_empty() or TimeShift.knows(requires_knowledge)


func prompt_text() -> String:
	if not _unlocked():
		return "Probe the silt"
	return prompt


func hold_seconds() -> float:
	return dig_seconds if _unlocked() else 0.0


func is_available() -> bool:
	return not _dug


func _activate(by: Node3D) -> void:
	if not _unlocked():
		Interactions.say(line_locked, 5.0)
		return
	_dug = true
	if reveal:
		reveal.visible = true
	if remove:
		remove.visible = false
		_open_up(remove)
	if not grants_knowledge.is_empty():
		TimeShift.learn(grants_knowledge)
	if not line_done.is_empty():
		Interactions.say(line_done, 8.0)
	Interactions.unregister(self)
	super._activate(by)
