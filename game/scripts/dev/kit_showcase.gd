## Dev-only: lays the Harappan kit out in a row and photographs it.
##
##   SHOT_DIR=/tmp/kit godot --path game scenes/dev/KitShowcase.tscn
##
## The point is the round-trip ARCHITECTURE.md §4 insists on: make a model,
## import it, confirm it works — before building a library on top of it.
extends Node3D

const KIT := "res://art/kit/"
const PIECES := [
	"wall_straight", "wall_low", "wall_corner", "doorway", "stair_flight",
	"reservoir_step", "drain_channel", "pillar_base", "tower_section",
	"platform_edge", "signboard_frame",
]


func _ready() -> void:
	var size := Vector2i(2460, 1136)
	var want := OS.get_environment("SHOT_SIZE")
	if want.contains("x"):
		size = Vector2i(int(want.get_slice("x", 0)), int(want.get_slice("x", 1)))
	DisplayServer.window_set_size(size)

	var mat: Material = load("res://materials/mat_past.tres")
	var ground := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(80, 0.4, 24)
	ground.mesh = plane
	ground.position = Vector3(14, -0.2, 0)
	ground.material_override = load("res://materials/mat_past_dark.tres")
	add_child(ground)

	var x := 0.0
	var missing: Array[String] = []
	for name: String in PIECES:
		var path := KIT + name + ".glb"
		if not ResourceLoader.exists(path):
			missing.append(name)
			continue
		var scene := load(path) as PackedScene
		var node := scene.instantiate() as Node3D
		node.position = Vector3(x, 0, 0)
		add_child(node)
		_paint(node, mat)
		var label := Label3D.new()
		label.text = name
		label.font_size = 48
		label.pixel_size = 0.004
		label.position = Vector3(x, -0.35, 1.9)
		label.modulate = Color(1, 0.92, 0.75)
		add_child(label)
		x += 4.0
	if not missing.is_empty():
		push_error("kit pieces missing: %s" % ", ".join(missing))

	_light()
	var cam := Camera3D.new()
	cam.fov = 58.0
	# Must be in the tree before look_at — it needs a global transform.
	add_child(cam)
	cam.global_position = Vector3(x * 0.5 - 2.0, 7.5, 20.0)
	cam.look_at(Vector3(x * 0.5 - 2.0, 1.0, 0), Vector3.UP)
	cam.make_current()

	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var dir := OS.get_environment("SHOT_DIR")
	if dir.is_empty():
		dir = "/tmp"
	DirAccess.make_dir_recursive_absolute(dir)
	get_viewport().get_texture().get_image().save_png(dir + "/kit.png")
	print("kit photographed: %s/kit.png   (%d pieces)" % [dir, PIECES.size() - missing.size()])
	get_tree().quit()


func _paint(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = mat
	for child: Node in node.get_children():
		_paint(child, mat)


func _light() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-34, 38, 0)
	sun.light_color = Color(1.0, 0.83, 0.60)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, -150, 0)
	fill.light_color = Color(0.45, 0.58, 0.82)
	fill.light_energy = 0.5
	add_child(fill)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.86, 0.72, 0.54)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.52, 0.52)
	e.ambient_light_energy = 0.9
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)
