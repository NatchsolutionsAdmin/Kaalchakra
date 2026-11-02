## EraLighting — the look of each morning.
##
## No art here, and that is the point. The art review's finding was that the
## problem is *focal hierarchy*, not missing textures: everything in frame
## currently has equal emphasis. Lighting is how that gets fixed, and lighting
## is free.
##
## Every number below comes from ART-DIRECTION.md §3, which is the review's
## lighting recipe table. All three eras are mornings, per the fiction — they
## differ in what kind:
##
##   1900 BCE  07:10, sun 20 deg up, long legible shadows, dusty gold air
##   2026      11:35, sun 70 deg up, short precise shadows, bleached and flat
##   2087      08:20 overcast, no real sun, layered blue-grey, cold water light
##
## Each era also has a named failure mode, and each is actively defended
## against here rather than left to be noticed later in a screenshot:
##
##   1900 BCE  all-orange wash    -> saturation held down, cool fill kept honest
##   2026      clipped whites     -> key energy capped, contrast left near 1.0
##   2087      crushed blacks     -> ambient floor, fill ratio close to the key
##
## Final lighting is still a human job (R5.4), and these are targets that need
## on-device calibration. But they are targets, not taste.
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
		# 07:10. Grazing light, which is what makes brick courses legible and
		# throws the long shadows the gate needs to read as monumental.
		"key_elevation": 20.0,
		"key_azimuth": 34.0,
		"key_color": Color("ffd49b"),
		"key_energy": 1.45,
		"key_to_fill": 3.5,
		"fill_color": Color("8f92a2"),
		"fill_azimuth": -145.0,
		"fill_elevation": 35.0,
		"shadow_softness": 0.6,          # long & legible
		"sky_top": Color(0.24, 0.40, 0.67),
		"sky_horizon": Color(0.90, 0.72, 0.48),
		"ground_horizon": Color(0.64, 0.45, 0.31),
		"ambient": Color(0.42, 0.28, 0.20),
		"fog_color": Color("c9a877"),    # light dusty gold
		"fog_density": 0.0030,
		"sun_scatter": 0.55,
		"aerial": 0.35,
		"contrast": 1.06,
		# Held below the old 1.12. The named risk here is an orange wash, and
		# saturation is the knob that causes it.
		"saturation": 1.02,
		"brightness": 1.0,
	},
	Era.Id.PRESENT: {
		# 11:35. Near-overhead, so shadows are short and hard and the site
		# looks like what it is: a work site in the middle of the day.
		"key_elevation": 70.0,
		"key_azimuth": -22.0,
		"key_color": Color("fff4e3"),
		# Capped. The named risk is clipped whites, and a bleached scene is
		# one energy step away from a white one.
		"key_energy": 1.55,
		"key_to_fill": 2.75,
		"fill_color": Color("b8c4c8"),
		"fill_azimuth": 150.0,
		"fill_elevation": 30.0,
		"shadow_softness": 0.25,         # short & precise
		"sky_top": Color(0.33, 0.50, 0.76),
		"sky_horizon": Color(0.82, 0.84, 0.83),
		"ground_horizon": Color(0.60, 0.58, 0.54),
		"ambient": Color(0.52, 0.48, 0.42),
		"fog_color": Color(0.80, 0.82, 0.82),  # very light dust
		"fog_density": 0.0016,
		"sun_scatter": 0.18,
		"aerial": 0.20,
		"contrast": 1.0,
		"saturation": 0.90,
		"brightness": 1.0,
	},
	Era.Id.FUTURE: {
		# 08:20 overcast. There is no sun to speak of; the sky is the light.
		# The fill nearly matches the key, which is what overcast *is*.
		"key_elevation": 21.0,
		"key_azimuth": 158.0,
		"key_color": Color("cad6df"),
		"key_energy": 0.68,
		"key_to_fill": 1.5,
		"fill_color": Color("647b86"),
		"fill_azimuth": 20.0,
		"fill_elevation": 60.0,
		"shadow_softness": 1.6,          # soft & subdued
		"sky_top": Color(0.16, 0.22, 0.31),
		"sky_horizon": Color(0.44, 0.53, 0.61),
		"ground_horizon": Color(0.26, 0.33, 0.40),
		"ambient": Color(0.20, 0.26, 0.32),
		"fog_color": Color(0.34, 0.44, 0.53),  # layered blue-grey
		"fog_density": 0.0075,
		"sun_scatter": 0.10,
		"aerial": 0.55,
		"contrast": 1.02,
		# Teal is reserved for water and survival (ART-DIRECTION.md §4), so
		# 2087 is desaturated and cold rather than tinted.
		"saturation": 0.76,
		# The named risk is crushed blacks. This lifts the whole image a
		# little so the drowned city stays walkable instead of atmospheric.
		"brightness": 1.06,
	},
}

## Floor on ambient energy. 2087 is the reason this exists.
const AMBIENT_FLOOR := 0.85


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


## The review gives key-to-fill as *rendered luminance contrast*, not as two
## energy values. A pale key and a grey fill at equal energy are not equally
## bright, so the fill energy is solved for from the two colours rather than
## typed in — otherwise the ratio drifts every time a colour is nudged.
static func fill_energy_for(look: Dictionary) -> float:
	var key_lum: float = maxf(0.04, (look["key_color"] as Color).get_luminance())
	var fill_lum: float = maxf(0.04, (look["fill_color"] as Color).get_luminance())
	var ratio: float = maxf(1.0, look["key_to_fill"])
	return (look["key_energy"] * key_lum) / (ratio * fill_lum)


func _apply(era: Era.Id) -> void:
	var look: Dictionary = LOOK[era]

	if sun:
		sun.rotation_degrees = Vector3(-look["key_elevation"], look["key_azimuth"], 0.0)
		sun.light_color = look["key_color"]
		sun.light_energy = look["key_energy"]
		sun.shadow_enabled = true
		sun.shadow_blur = look["shadow_softness"]
	if fill:
		fill.rotation_degrees = Vector3(
			-look["fill_elevation"], look["fill_azimuth"], 0.0)
		fill.light_color = look["fill_color"]
		fill.light_energy = fill_energy_for(look)
		# One shadow caster only. Two directional shadows on a phone is a
		# cost with no picture to show for it.
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
	env.ambient_light_energy = AMBIENT_FLOOR
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
