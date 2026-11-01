## EraLighting — retints the sun and sky when the era changes.
##
## Cheap, but it is what makes the three mornings *feel* different before any
## art exists: warm gold for 1900 BCE, flat neutral for 2026, cold blue-grey
## for 2087 (CLAUDE.md §4). Final lighting is a human job (R5.4) — this is a
## placeholder that reads correctly.
extends Node3D

## NodePaths, not direct Node exports — see the note in dig_site.gd.
@export var sun_path: NodePath = NodePath("../Sun")
@export var env_path: NodePath = NodePath("../WorldEnvironment")

var sun: DirectionalLight3D
var world_env: WorldEnvironment

const SUN_ANGLE := {
	Era.Id.PAST: Vector3(-38.0, 35.0, 0.0),
	Era.Id.PRESENT: Vector3(-62.0, -15.0, 0.0),
	Era.Id.FUTURE: Vector3(-24.0, 160.0, 0.0),
}

const SUN_ENERGY := {
	Era.Id.PAST: 1.35,
	Era.Id.PRESENT: 1.6,
	Era.Id.FUTURE: 0.75,
}

const SKY_TOP := {
	Era.Id.PAST: Color(0.26, 0.38, 0.62),
	Era.Id.PRESENT: Color(0.30, 0.46, 0.72),
	Era.Id.FUTURE: Color(0.13, 0.18, 0.26),
}

const SKY_HORIZON := {
	Era.Id.PAST: Color(0.86, 0.66, 0.42),
	Era.Id.PRESENT: Color(0.74, 0.76, 0.76),
	Era.Id.FUTURE: Color(0.34, 0.42, 0.50),
}

const FOG_DENSITY := {
	Era.Id.PAST: 0.0032,
	Era.Id.PRESENT: 0.002,
	Era.Id.FUTURE: 0.0065,
}


func _ready() -> void:
	sun = get_node_or_null(sun_path) as DirectionalLight3D
	world_env = get_node_or_null(env_path) as WorldEnvironment
	if sun == null:
		push_warning("EraLighting: no DirectionalLight3D at '%s'." % sun_path)
	if world_env == null:
		push_warning("EraLighting: no WorldEnvironment at '%s'." % env_path)
	TimeShift.era_changed.connect(_on_era_changed)
	_apply(TimeShift.current_era)


func _on_era_changed(_from: Era.Id, to: Era.Id) -> void:
	_apply(to)


func _apply(era: Era.Id) -> void:
	if sun:
		sun.light_color = Era.TINT[era]
		sun.light_energy = SUN_ENERGY[era]
		sun.rotation_degrees = SUN_ANGLE[era]
	if world_env == null or world_env.environment == null:
		return
	var env := world_env.environment
	env.ambient_light_color = Era.TINT[era].darkened(0.45)
	env.fog_light_color = SKY_HORIZON[era]
	env.fog_density = FOG_DENSITY[era]
	if env.sky == null:
		return
	var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
	if sky_mat:
		sky_mat.sky_top_color = SKY_TOP[era]
		sky_mat.sky_horizon_color = SKY_HORIZON[era]
		sky_mat.ground_bottom_color = SKY_HORIZON[era].darkened(0.5)
		sky_mat.ground_horizon_color = SKY_HORIZON[era]
