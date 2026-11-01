## EraRoot — put this on the Past / Present / Future child of a location.
##
## A "Location" scene holds three of these. Exactly one is visible at a time;
## the other two are hidden, and their solid geometry sits on a collision layer
## the player is not currently listening to, so it may as well not exist.
##
## That is the whole trick behind the three-era switch (ARCHITECTURE §3.1).
@tool
class_name EraRoot
extends Node3D

@export var era_id: Era.Id = Era.Id.PAST:
	set(value):
		era_id = value
		update_configuration_warnings()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	TimeShift.era_changed.connect(_on_era_changed)
	_apply(TimeShift.current_era)


func _on_era_changed(_from: Era.Id, to: Era.Id) -> void:
	_apply(to)


func _apply(active: Era.Id) -> void:
	visible = (active == era_id)


func _get_configuration_warnings() -> PackedStringArray:
	if get_parent() == null:
		return []
	for sibling: Node in get_parent().get_children():
		if sibling != self and sibling is EraRoot and (sibling as EraRoot).era_id == era_id:
			return ["Two EraRoots in this location share the same era_id."]
	return []
