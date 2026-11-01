## MainMenu — the first thing anyone sees.
##
## The backdrop is the actual game: the north gate of Dholarath at first
## light, 1900 BCE, with a slow camera move across it. Not a painted image —
## the real location, real lighting, real shaders. It costs nothing extra
## (the level already exists), it can never go out of date as the art
## improves, and it tells the player what the game looks like before they
## press anything.
##
## Three panels share one backdrop: title, chapters, settings.
extends Node3D

# `Screen` not `Panel` — Panel is a native Godot class.
enum Screen { TITLE, CHAPTERS, SETTINGS }

const LOCATION := "res://scenes/locations/NorthGate.tscn"
const GAME := "res://scenes/Main.tscn"

var _panels: Dictionary = {}
var _root: Control
var _cam: Camera3D
var _t := 0.0
var _chapter_rows: VBoxContainer


func _ready() -> void:
	TimeShift.current_era = Era.Id.PAST
	_build_world()
	_build_ui()
	_show(Screen.TITLE)


# --- the backdrop --------------------------------------------------------

func _build_world() -> void:
	add_child(load(LOCATION).instantiate())

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("27416b")
	sky_mat.sky_horizon_color = Color("e6b478")
	sky_mat.ground_horizon_color = Color("a4703f")
	sky_mat.ground_bottom_color = Color("4b2f20")
	sky_mat.sun_angle_max = 18.0
	sky.sky_material = sky_mat
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_sky_contribution = 0.45
	e.ambient_light_color = Color(0.42, 0.28, 0.20)
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_white = 6.0
	e.fog_enabled = true
	e.fog_light_color = Color("e6b478")
	e.fog_density = 0.0032
	e.fog_sun_scatter = 0.55
	e.fog_aerial_perspective = 0.35
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.07
	e.adjustment_saturation = 1.12
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-14, 36, 0)
	sun.light_color = Color(1.0, 0.82, 0.58)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 200.0
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35, -145, 0)
	fill.light_color = Color(0.55, 0.62, 0.80)
	fill.light_energy = 0.38
	add_child(fill)

	_cam = Camera3D.new()
	_cam.fov = 52.0
	_cam.far = 600.0
	add_child(_cam)
	_cam.make_current()


func _process(delta: float) -> void:
	# A slow drift across the gate. Deliberately gentle: the menu should feel
	# like a held shot, not a showreel.
	_t += delta * 0.045
	var a := sin(_t) * 0.55
	_cam.global_position = Vector3(8.0 + sin(_t * 0.7) * 5.0, 7.5 + sin(_t * 0.5) * 0.8,
		-13.0 + cos(a) * 6.0)
	_cam.look_at(Vector3(0.0, 4.0, -30.0), Vector3.UP)


# --- the panels ----------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_root)

	# A darkening down the left so text always has something to sit on, however
	# bright the sky behind it. A GRADIENT, not a rectangle: a hard vertical
	# edge across the middle of the screen reads as a bug.
	var grad := Gradient.new()
	grad.set_color(0, Color(0.04, 0.035, 0.035, 0.82))
	grad.set_color(1, Color(0.04, 0.035, 0.035, 0.0))
	grad.add_point(0.45, Color(0.04, 0.035, 0.035, 0.55))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 8
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	var scrim := TextureRect.new()
	scrim.texture = tex
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.offset_right = -float(360)
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(scrim)

	_panels[Screen.TITLE] = _build_title()
	_panels[Screen.CHAPTERS] = _build_chapters()
	_panels[Screen.SETTINGS] = _build_settings()
	for p: Screen in _panels:
		_root.add_child(_panels[p])


func _column() -> Control:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	col.offset_left = 78
	col.offset_top = 52
	col.add_theme_constant_override("separation", 7)
	holder.add_child(col)
	holder.set_meta("col", col)
	return holder


func _menu_button(text: String, tint: Color = UIStyle.DUST) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(410, 52)
	b.add_theme_font_size_override("font_size", 21)
	b.add_theme_color_override("font_color", tint)
	b.add_theme_color_override("font_hover_color", UIStyle.HIGHLIGHT)
	b.add_theme_color_override("font_pressed_color", UIStyle.PRESSED_INK)
	b.add_theme_color_override("font_disabled_color", Color(tint.r, tint.g, tint.b, 0.3))
	b.add_theme_stylebox_override("normal",
		UIStyle.panel(Color(0.06, 0.05, 0.05, 0.42), Color(0.66, 0.44, 0.25, 0.30), 4, 22))
	b.add_theme_stylebox_override("hover",
		UIStyle.panel(Color(0.11, 0.09, 0.08, 0.72), UIStyle.OCHRE, 4, 22))
	b.add_theme_stylebox_override("pressed",
		UIStyle.panel(UIStyle.OCHRE, UIStyle.SALT, 4, 22))
	b.add_theme_stylebox_override("disabled",
		UIStyle.panel(Color(0.05, 0.04, 0.04, 0.3), Color(0.66, 0.44, 0.25, 0.12), 4, 22))
	return b


func _build_title() -> Control:
	var holder := _column()
	var col: VBoxContainer = holder.get_meta("col")

	var dial := WheelDial.new()
	dial.custom_minimum_size = Vector2(76, 76)
	dial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(dial)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 8)
	col.add_child(gap)

	var title := UIStyle.label("KAALCHAKRA", 54, UIStyle.SALT)
	col.add_child(title)
	var sub := UIStyle.label("THE DROWNED CITY", 20, UIStyle.OCHRE)
	col.add_child(sub)
	var tag := UIStyle.label("Three mornings of the same place.", 16, UIStyle.INK_DIM)
	col.add_child(tag)

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 22)
	col.add_child(gap2)

	var cont := _menu_button("Continue", UIStyle.HIGHLIGHT)
	cont.disabled = not SaveGame.has_save()
	cont.pressed.connect(_continue)
	col.add_child(cont)

	var start := _menu_button("New game")
	start.pressed.connect(func() -> void: _start(Chapters.LIST[0]))
	col.add_child(start)

	var chapters := _menu_button("Chapters")
	chapters.pressed.connect(func() -> void: _show(Screen.CHAPTERS))
	col.add_child(chapters)

	var settings := _menu_button("Settings")
	settings.pressed.connect(func() -> void: _show(Screen.SETTINGS))
	col.add_child(settings)

	var quit := _menu_button("Quit", UIStyle.INK_DIM)
	quit.pressed.connect(func() -> void: get_tree().quit())
	col.add_child(quit)
	return holder


func _build_chapters() -> Control:
	var holder := _column()
	var col: VBoxContainer = holder.get_meta("col")
	col.add_child(UIStyle.label("CHAPTERS", 15, UIStyle.INK_DIM))
	col.add_child(UIStyle.label("Five hours, in short mornings.", 17, UIStyle.DUST))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 18)
	col.add_child(gap)

	# Seven chapters plus their lines do not fit a phone in landscape, so the
	# list scrolls rather than running off the bottom of the screen.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_chapter_rows = VBoxContainer.new()
	_chapter_rows.add_theme_constant_override("separation", 5)
	_chapter_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_chapter_rows)

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 10)
	col.add_child(gap2)
	var back := _menu_button("Back", UIStyle.INK_DIM)
	back.pressed.connect(func() -> void: _show(Screen.TITLE))
	col.add_child(back)
	return holder


func _fill_chapters() -> void:
	for c: Node in _chapter_rows.get_children():
		c.queue_free()
	for entry: Dictionary in Chapters.LIST:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		_chapter_rows.add_child(row)

		# A pip in the era's own colour, so the running order reads as a
		# pattern of mornings before you read a single word.
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(5, 44)
		pip.color = Era.TINT[entry["era"]]
		row.add_child(pip)

		var playable: bool = Chapters.playable(entry)
		var b := _menu_button("%s   %s" % [entry["no"], entry["title"]],
			UIStyle.DUST if playable else UIStyle.INK_DIM)
		b.custom_minimum_size = Vector2(470, 44)
		b.disabled = not playable
		if playable:
			b.pressed.connect(_start.bind(entry))
		row.add_child(b)

		var mins := UIStyle.label("%d min" % int(entry["mins"]), 14, UIStyle.INK_DIM)
		mins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(mins)

		var line := UIStyle.label("        " + String(entry["line"]), 13, UIStyle.INK_DIM)
		line.custom_minimum_size = Vector2(600, 0)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_chapter_rows.add_child(line)


func _build_settings() -> Control:
	var holder := _column()
	var col: VBoxContainer = holder.get_meta("col")
	col.add_child(UIStyle.label("SETTINGS", 15, UIStyle.INK_DIM))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	col.add_child(gap)

	col.add_child(_slider("Music", Options.music,
		func(v: float) -> void: Options.music = v))
	col.add_child(_slider("Sound", Options.sfx,
		func(v: float) -> void: Options.sfx = v))
	col.add_child(_slider("Voice", Options.voice,
		func(v: float) -> void: Options.voice = v))

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 12)
	col.add_child(gap2)
	col.add_child(_toggle("Reduced motion", Options.reduced_motion,
		func(on: bool) -> void: Options.reduced_motion = on))
	col.add_child(_toggle("Larger text", Options.large_text,
		func(on: bool) -> void: Options.large_text = on))

	var gap3 := Control.new()
	gap3.custom_minimum_size = Vector2(0, 20)
	col.add_child(gap3)
	var back := _menu_button("Back", UIStyle.INK_DIM)
	back.pressed.connect(func() -> void:
		Options.save_settings()
		_show(Screen.TITLE))
	col.add_child(back)
	return holder


func _slider(label: String, value: float, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var l := UIStyle.label(label, 18, UIStyle.DUST)
	l.custom_minimum_size = Vector2(150, 44)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	var s := HSlider.new()
	s.custom_minimum_size = Vector2(300, 44)
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(func(v: float) -> void:
		on_change.call(v)
		Options.apply())
	row.add_child(s)
	return row


func _toggle(label: String, value: bool, on_change: Callable) -> Button:
	var b := _menu_button("%s   %s" % [label, "ON" if value else "OFF"])
	b.pressed.connect(func() -> void:
		value = not value
		on_change.call(value)
		Options.apply()
		Options.save_settings()
		b.text = "%s   %s" % [label, "ON" if value else "OFF"])
	return b


# --- flow ----------------------------------------------------------------

func _show(panel: Screen) -> void:
	for p: Screen in _panels:
		(_panels[p] as Control).visible = (p == panel)
	if panel == Screen.CHAPTERS:
		_fill_chapters()


func _continue() -> void:
	Flow.continue_game()


func _start(entry: Dictionary) -> void:
	Flow.start_chapter(entry)
