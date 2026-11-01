extends Node
func _ready() -> void:
	var size := Vector2i(2460, 1136)
	var want := OS.get_environment("SHOT_SIZE")
	if want.contains("x"):
		size = Vector2i(int(want.get_slice("x", 0)), int(want.get_slice("x", 1)))
	DisplayServer.window_set_size(size)
	var dir := OS.get_environment("SHOT_DIR")
	if dir.is_empty():
		dir = "/tmp"
	DirAccess.make_dir_recursive_absolute(dir)
	var menu: Node = load("res://scenes/Menu.tscn").instantiate()
	add_child(menu)
	for shot: Array in [["menu_title", 0], ["menu_chapters", 1], ["menu_settings", 2]]:
		menu.call("_show", shot[1])
		for _i in 20:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, shot[0]])
		print("  ", shot[0])
	get_tree().quit()
