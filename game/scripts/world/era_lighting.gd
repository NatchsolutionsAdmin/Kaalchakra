## EraLighting — the look of each morning.
##
## No art here, and that is the point: on a phone the difference between a
## greybox and something that reads as a place is lighting, silhouette and
## colour, not polygons (CLAUDE.md §9, decision #25). Each era gets a directed
## key light, a cool fill to keep shadows from going black, its own sky and fog,
## and a colour grade.
##
## All three are mornings, per the fiction — they differ in *what kind*:
##   1900 BCE  low warm sun, long shadows, dust in the air, a living city
##   2026      higher and harsher, bleached, flat, the glare of a work site
##   2087      overcast, almost no direct sun, cold and heavy with water
##
## Final lighting is still a human job (R5.4). This is a placeholder that reads.
extends Node3D

## NodePaths, not direct Node exports — see the note in dig_site.gd.
@export var sun_path: NodePath = NodePath("../Sun")
@export var fill_path: NodePath = NodePath("../Fill")
@export var env_path: NodePath = NodePath("../WorldEnvironment")

var sun: DirectionalLight3D
var fill: DirectionalLight3D
var world_env: WorldEnvironment

const LOOK: Dictionary = {
	Era.Id.PAST: {
		"ambient": Color(0.42, 0.28, 0.20),
		"sun_angle": Vector3(-17.0, 34.0, 0.0),
		"sun_color": Color(1.0, 0.83, 0.60),
		"sun_energy": 1.55,
		"fill_angle": Vector3(-35.0, -145.0, 0.0),
		"fill_color": Color(0.55, 0.62, 0.80),
		"fill_energy": 0.38,
		"sky_top": Color(0.24, 0.40, 0.67),
		"sky_horizon": Color(0.90, 0.72, 0.48),
		"ground_horizon": Color(0.64, 0.45, 0.31),
		"fog_color": Color(0.86, 0.68, 0.47),
		"fog_density": 0.0030,
		"sun_scatter": 0.55,
		"aerial": 0.35,
		"contrast": 1.07,
		"saturation": 1.12,
		"brightness": 1.0,
	},
	Era.Id.PRESENT: {
		"ambient": Color(0.52, 0.48, 0.42),
		"sun_angle": Vector3(-54.0, -22.0, 0.0),
		"sun_color": Color(1.0, 0.97, 0.92),
		"sun_energy": 1.9,
		"fill_angle": Vector3(-30.0, 150.0, 0.0),
		# Warm, not blue: this is light bounced off a salt flat, and a cool
		# fill made the dry basin look like it was full of water.
		"fill_color": Color(0.84, 0.78, 0.68),
		"fill_energy": 0.42,
		"sky_top": Color(0.33, 0.50, 0.76),
		"sky_horizon": Color(0.82, 0.84, 0.83),
		"ground_horizon": Color(0.60, 0.58, 0.54),
		"fog_color": Color(0.80, 0.82, 0.82),
		"fog_density": 0.0016,
		"sun_scatter": 0.18,
		"aerial": 0.20,
		"contrast": 1.02,
		"saturation": 0.92,
		"brightness": 1.02,
	},
	Era.Id.FUTURE: {
		"ambient": Color(0.16, 0.22, 0.28),
		"sun_angle": Vector3(-21.0, 158.0, 0.0),
		"sun_color": Color(0.74, 0.84, 0.95),
		"sun_energy": 0.72,
		"fill_angle": Vector3(-60.0, 20.0, 0.0),
		"fill_color": Color(0.46, 0.58, 0.70),
		"fill_energy": 0.85,
		# Ambient comes from the sky, so 2087 cannot be as dark as it is moody
		# or the player simply cannot see where to walk.
		"sky_top": Color(0.16, 0.22, 0.31),
		"sky_horizon": Color(0.44, 0.53, 0.61),
		"ground_horizon": Color(0.26, 0.33, 0.40),
		"fog_color": Color(0.34, 0.44, 0.53),
		"fog_density": 0.0075,
		"sun_scatter": 0.10,
		"aerial": 0.55,
		"contrast": 1.06,
		"saturation": 0.74,
		"brightness": 1.02,
	},
}


func _ready() -> void:
	sun = get_node_or_null(sun_path) as DirectionalLight3D
	fill = get_node_or_null(fill_path) as DirectionalLight3D
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
	var look: Dictionary = LOOK[era]

	if sun:
		sun.rotation_degrees = look["sun_angle"]
		sun.light_color = look["sun_color"]
		sun.light_energy = look["sun_energy"]
	if fill:
		fill.rotation_degrees = look["fill_angle"]
		fill.light_color = look["fill_color"]
		fill.light_energy = look["fill_energy"]
		fill.shadow_enabled = false

	if world_env == null or world_env.environment == null:
		return
	var env := world_env.environment
	env.fog_light_color = look["fog_color"]
	env.fog_density = look["fog_density"]
	env.fog_sun_scatter = look["sun_scatter"]
	env.fog_aerial_perspective = look["aerial"]
	# Down in the basin the only light is ambient, and pure sky ambient is
	# blue — which made a DRY reservoir read as a full one. Blend the sky with
	# a ground-bounce colour per era instead of taking it neat.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.45
	env.ambient_light_color = look["ambient"]
	env.ambient_light_energy = 1.0
	env.adjustment_enabled = true
	env.adjustment_contrast = look["contrast"]
	env.adjustment_saturation = look["saturation"]
	env.adjustment_brightness = look["brightness"]

	if env.sky == null:
		return
	var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
	if sky_mat:
		sky_mat.sky_top_color = look["sky_top"]
		sky_mat.sky_horizon_color = look["sky_horizon"]
		sky_mat.ground_horizon_color = look["ground_horizon"]
		sky_mat.ground_bottom_color = Color(look["ground_horizon"]).darkened(0.35)
