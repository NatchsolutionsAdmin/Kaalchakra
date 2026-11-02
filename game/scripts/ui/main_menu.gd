## MainMenu — the first thing anyone sees.
##
## The backdrop is the actual game: the north gate of Dholarath at first
## light, 1900 BCE, with a slow camera move across it. Not a painted image —
## the real location, real lighting, real shaders. It costs nothing extra
## (the level already exists), it can never go out of date as the art
## improves, and it tells the player what the game looks like before they
## press anything.
##
## Rebuilt against the art review (ART-DIRECTION.md §9), which gave this
## screen a layout rather than a mood:
##
##   title at x=88, y=150        menu at x=96, y=325      (at 1280x720)
##   the right 55-60% belongs to the gate and the Wheel, not to interface
##   an editorial vertical list — not five equally-weighted boxed buttons
##   only Continue emphasised, and only when there is a save
##   the camera drifts 0.5-1 degree over 10-15 seconds, with no obvious loop
##   the Wheel is mostly still: a tiny mechanical settle, never a spin
##
## The old version's fault, in the review's words, was "too many equally
## strong controls": five identical boxes, so the eye had nowhere to land.
extends Node3D

# `Screen` not `Panel` — Panel is a native Godot class.
enum Screen { TITLE, CHAPTERS, SETTINGS }

const LOCATION := "res://scenes/locations/NorthGate.tscn"
const GAME := "res://scenes/Main.tscn"

## Layout anchors, at the 1280x720 design resolution. Held as fractions of
## the viewport rather than as pixels, because "expand" stretch gives a
## 19.5:9 phone a much shorter viewport and absolute coordinates would walk
## the menu off the bottom of it.
const DESIGN := Vector2(1280.0, 720.0)
const TITLE_AT := Vector2(88, 150)
const MENU_AT := Vector2(96, 325)
## Interface may not cross this fraction of the width. The rest is the game.
const UI_WIDTH := 0.42
## Focus indicator: 150-200ms translation and fade.
const FOCUS_MOVE := 0.17
## Title entrance: a 600-900ms quiet reveal.
const REVEAL := 0.8

var _panels: Dictionary = {}
var _root: Control
var _cam: Camera3D
var _t := 0.0
var _chapter_rows: VBoxContainer
var _focus_bar: ColorRect
var _mark: Control
var _cam_home := Vector3.ZERO
var _cam_look := Vector3.ZERO
## Columns that must be re-placed when the screen changes shape.
var _anchored: Array[Dictionary] = []


func _ready() -> void:
	TimeShift.current_era = Era.Id.PAST
	_build_world()
	_build_ui()
	_show(Screen.TITLE)
	get_viewport().size_changed.connect(_relayout)
	_reveal()


# --- the backdrop --------------------------------------------------------

func _build_world() -> void:
	add_child(load(LOCATION).instantiate())

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	var look: Dictionary = load("res://scripts/world/era_lighting.gd").LOOK[Era.Id.PAST]
	sky_mat.sky_top_color = look["sky_top"]
	sky_mat.sky_horizon_color = look["sky_horizon"]
	sky_mat.ground_horizon_color = look["ground_horizon"]
	sky_mat.ground_bottom_color = Color(look["ground_horizon"]).darkened(0.35)
	sky_mat.sun_angle_max = 18.0
	sky.sky_material = sky_mat
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_sky_contribution = 0.45
	e.ambient_light_color = look["ambient"]
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_white = 6.0
	e.fog_enabled = true
	e.fog_light_color = look["fog_color"]
	e.fog_density = look["fog_density"]
	e.fog_sun_scatter = look["sun_scatter"]
	e.fog_aerial_perspective = look["aerial"]
	e.adjustment_enabled = true
	e.adjustment_contrast = look["contrast"]
	e.adjustment_saturation = look["saturation"]
	env.environment = e
	add_child(env)

	# The same recipe the game uses for 1900 BCE, so the menu is not a
	# separately-lit place that the first chapter then contradicts.
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-look["key_elevation"], look["key_azimuth"], 0.0)
	sun.light_color = look["key_color"]
	sun.light_energy = look["key_energy"]
	sun.shadow_enabled = true
	sun.shadow_blur = look["shadow_softness"]
	sun.directional_shadow_max_distance = 200.0
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-look["fill_elevation"], look["fill_azimuth"], 0.0)
	fill.light_color = look["fill_color"]
	fill.light_energy = load("res://scripts/world/era_lighting.gd").fill_energy_for(look)
	add_child(fill)

	# Composed so the gate sits in the right-hand 55-60% of the frame, which
	# is the half the review reserves for the game.
	_cam_home = Vector3(9.5, 6.4, -9.0)
	_cam_look = Vector3(-1.0, 3.6, -29.0)
	_cam = Camera3D.new()
	_cam.fov = 52.0
	_cam.far = 600.0
	add_child(_cam)
	# After add_child: global_position is meaningless outside the tree.
	_cam.global_position = _cam_home
	_cam.look_at(_cam_look, Vector3.UP)
	_cam.make_current()


func _process(delta: float) -> void:
	# 0.5-1 degree of apparent drift over 10-15 seconds, with no obvious loop.
	# The old menu swung the camera five metres, which read as a showreel; the
	# review asks for a held shot that is merely alive.
	#
	# Two sine waves at incommensurable rates, so the motion never repeats
	# in a way the eye can catch.
	_t += delta
	var drift := Vector3(
		sin(_t * 0.083) * 0.26 + sin(_t * 0.037) * 0.13,
		sin(_t * 0.061) * 0.07,
		cos(_t * 0.047) * 0.18)
	_cam.global_position = _cam_home + drift
	_cam.look_at(_cam_look, Vector3.UP)


# --- the panels ----------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_root)

	# A darkening down the left so text always has something to sit on,
	# however bright the sky behind it. A GRADIENT, not a rectangle: a hard
	# vertical edge across the middle of the screen reads as a bug. It stops
	# at UI_WIDTH, because past that the picture is the point.
	var grad := Gradient.new()
	grad.set_color(0, Color(UIStyle.SURFACE.r, UIStyle.SURFACE.g, UIStyle.SURFACE.b, 0.86))
	grad.set_color(1, Color(UIStyle.SURFACE.r, UIStyle.SURFACE.g, UIStyle.SURFACE.b, 0.0))
	grad.add_point(0.5, Color(UIStyle.SURFACE.r, UIStyle.SURFACE.g, UIStyle.SURFACE.b, 0.5))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 256
	tex.height = 8
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(1, 0)
	var scrim := TextureRect.new()
	scrim.texture = tex
	scrim.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	scrim.anchor_right = UI_WIDTH + 0.16
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(scrim)

	# The Wheel as a large, quiet foreground silhouette on the right — the
	# review's "physical Wheel foreground/silhouette", and the one place the
	# mark gets to be big.
	_mark = Control.new()
	_mark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mark.draw.connect(_draw_mark)
	_root.add_child(_mark)

	# One bar, moved between rows. The review asks for a focus indicator that
	# translates and fades over 150-200ms, which a per-row highlight cannot do.
	_focus_bar = ColorRect.new()
	_focus_bar.color = UIStyle.COPPER
	_focus_bar.size = Vector2(2, 30)
	_focus_bar.modulate.a = 0.0
	_focus_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_focus_bar)

	_panels[Screen.TITLE] = _build_title()
	_panels[Screen.CHAPTERS] = _build_chapters()
	_panels[Screen.SETTINGS] = _build_settings()
	for p: Screen in _panels:
		_root.add_child(_panels[p])


func _draw_mark() -> void:
	var vp := _mark.size
	var state := KaalchakraMark.State.new()
	state.mono = true
	state.weight = 2.2
	state.silhouette = true
	# Low in the right-hand third, mostly off the bottom of the frame: a
	# physical object in the foreground, not a logo pasted on the sky.
	var r := vp.y * 0.62
	# Held back so it is scenery, not a logo competing with the title.
	_mark.modulate.a = 0.62
	KaalchakraMark.draw_mark(_mark, Vector2(vp.x * 0.82, vp.y * 1.10), r, state)


# --- the editorial list ---------------------------------------------------

## A menu row: text on the backdrop, no box. Emphasis is carried by weight and
## colour, and only ever by one row at a time.
func _menu_row(text: String, emphasis: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(360, UIStyle.TAP)
	b.add_theme_font_size_override("font_size",
		UIStyle.TYPE_SIZE[UIStyle.Type.MENU] + (3 if emphasis else 0))
	b.add_theme_color_override("font_color",
		UIStyle.TEXT if emphasis else UIStyle.TEXT_DIM_A)
	b.add_theme_color_override("font_hover_color", UIStyle.OCHRE)
	b.add_theme_color_override("font_pressed_color", UIStyle.OCHRE)
	b.add_theme_color_override("font_disabled_color", UIStyle.DISABLED)
	var flat := StyleBoxEmpty.new()
	flat.content_margin_left = UIStyle.S3
	flat.content_margin_right = UIStyle.S3
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, flat)
	b.mouse_entered.connect(_focus_on.bind(b))
	return b


## Slide the copper rule to whichever row the player is on.
func _focus_on(row: Control) -> void:
	if not row.is_visible_in_tree():
		return
	var to := Vector2(row.global_position.x - 10.0,
		row.global_position.y + (row.size.y - _focus_bar.size.y) * 0.5)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_focus_bar, "position", to, FOCUS_MOVE) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_focus_bar, "modulate:a", 1.0, FOCUS_MOVE)


## Place a box at a design-resolution coordinate, and keep it there
## proportionally when the screen changes shape.
func _anchor(box: Control, at: Vector2) -> void:
	_anchored.append({"box": box, "at": at})
	_place(box, at)


func _place(box: Control, at: Vector2) -> void:
	var vp := get_viewport().get_visible_rect().size
	box.offset_left = at.x / DESIGN.x * vp.x
	box.offset_top = at.y / DESIGN.y * vp.y


func _relayout() -> void:
	for entry: Dictionary in _anchored:
		var box := entry["box"] as Control
		if is_instance_valid(box):
			_place(box, entry["at"])
	if _mark:
		_mark.queue_redraw()


func _column(at: Vector2) -> Control:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := VBoxContainer.new()
	_anchor(col, at)
	col.add_theme_constant_override("separation", UIStyle.S1)
	holder.add_child(col)
	holder.set_meta("col", col)
	return holder


func _build_title() -> Control:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# The title block, at its specified coordinates.
	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", UIStyle.S2)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(head)
	_anchor(head, TITLE_AT)
	holder.set_meta("head", head)

	head.add_child(UIStyle.text("KAALCHAKRA", UIStyle.Type.TITLE, UIStyle.TEXT))
	var sub := UIStyle.text("THE DROWNED CITY", UIStyle.Type.LABEL, UIStyle.COPPER)
	head.add_child(sub)
	head.add_child(UIStyle.text("Three mornings of the same place.",
		UIStyle.Type.BODY, UIStyle.TEXT_DIM_A))

	# The menu, at its own specified coordinates.
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	holder.add_child(col)
	_anchor(col, MENU_AT)

	var has_save := SaveGame.has_save()
	# Exactly one emphasised row, and only if it would do anything.
	var cont := _menu_row("Continue", has_save)
	cont.disabled = not has_save
	cont.pressed.connect(_continue)
	col.add_child(cont)

	var start := _menu_row("New game", not has_save)
	start.pressed.connect(func() -> void: _start(Chapters.LIST[0]))
	col.add_child(start)

	var chapters := _menu_row("Chapters")
	chapters.pressed.connect(func() -> void: _show(Screen.CHAPTERS))
	col.add_child(chapters)

	var settings := _menu_row("Settings")
	settings.pressed.connect(func() -> void: _show(Screen.SETTINGS))
	col.add_child(settings)

	var quit := _menu_row("Quit")
	quit.pressed.connect(func() -> void: get_tree().quit())
	col.add_child(quit)
	holder.set_meta("first", cont if has_save else start)
	return holder


## A 600-900ms quiet reveal: the title rises a little and fades up, then the
## menu follows. Nothing swoops.
func _reveal() -> void:
	var title: Control = _panels[Screen.TITLE]
	var head := title.get_meta("head") as Control
	head.modulate.a = 0.0
	head.position.y += 14.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(head, "modulate:a", 1.0, REVEAL) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(head, "position:y", head.position.y - 14.0, REVEAL) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	var first := title.get_meta("first") as Control
	if first and is_instance_valid(first):
		_focus_on(first)


# --- chapters: an archive ledger, not a list of buttons -------------------

func _build_chapters() -> Control:
	var holder := _column(Vector2(TITLE_AT.x, 96))
	var col: VBoxContainer = holder.get_meta("col")
	col.add_child(UIStyle.text("CHAPTERS", UIStyle.Type.LABEL, UIStyle.TEXT_DIM_A))
	col.add_child(UIStyle.text("Five hours, in short mornings.",
		UIStyle.Type.BODY, UIStyle.TEXT_DIM_A))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, UIStyle.S4)
	col.add_child(gap)

	# Seven chapters plus their lines do not fit a phone in landscape, so the
	# list scrolls rather than running off the bottom of the screen.
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(700, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# No visible scrollbar. On a phone you drag the list; a grey rail down the
	# middle of the title art is just damage.
	var blank := StyleBoxEmpty.new()
	for part: String in ["scroll", "grabber", "grabber_highlight", "grabber_pressed"]:
		scroll.get_v_scroll_bar().add_theme_stylebox_override(part, blank)
	col.add_child(scroll)
	_chapter_rows = VBoxContainer.new()
	_chapter_rows.add_theme_constant_override("separation", UIStyle.S2)
	_chapter_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_chapter_rows)

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, UIStyle.S3)
	col.add_child(gap2)
	var back := _menu_row("Back")
	back.pressed.connect(func() -> void: _show(Screen.TITLE))
	col.add_child(back)
	return holder


func _fill_chapters() -> void:
	for c: Node in _chapter_rows.get_children():
		c.queue_free()
	for entry: Dictionary in Chapters.LIST:
		var playable: bool = Chapters.playable(entry)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UIStyle.S3)
		_chapter_rows.add_child(row)

		# A pip in the era's own colour, so the running order reads as a
		# pattern of mornings before you read a single word.
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(3, 34)
		pip.color = Era.TINT[entry["era"]] if playable else UIStyle.DISABLED
		row.add_child(pip)

		var b := _menu_row("%s   %s" % [entry["no"], entry["title"]])
		b.custom_minimum_size = Vector2(440, 34)
		b.add_theme_font_size_override("font_size",
			UIStyle.TYPE_SIZE[UIStyle.Type.PANEL_TITLE] - 4)
		b.disabled = not playable
		if playable:
			b.pressed.connect(_start.bind(entry))
		row.add_child(b)

		var mins := UIStyle.text("%d min" % int(entry["mins"]),
			UIStyle.Type.METADATA, UIStyle.DISABLED)
		mins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(mins)

		# The ledger's annotation line, indented under its entry.
		var line := UIStyle.text("      " + String(entry["line"]),
			UIStyle.Type.METADATA, UIStyle.TEXT_DIM_A)
		line.custom_minimum_size = Vector2(620, 0)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_chapter_rows.add_child(line)

		var rule := ColorRect.new()
		rule.color = UIStyle.BORDER
		rule.custom_minimum_size = Vector2(620, 1)
		_chapter_rows.add_child(rule)


# --- settings -------------------------------------------------------------

func _build_settings() -> Control:
	var holder := _column(Vector2(TITLE_AT.x, 130))
	var col: VBoxContainer = holder.get_meta("col")
	col.add_child(UIStyle.text("SETTINGS", UIStyle.Type.LABEL, UIStyle.TEXT_DIM_A))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, UIStyle.S4)
	col.add_child(gap)

	col.add_child(_slider("Music", Options.music,
		func(v: float) -> void: Options.music = v))
	col.add_child(_slider("Sound", Options.sfx,
		func(v: float) -> void: Options.sfx = v))
	col.add_child(_slider("Voice", Options.voice,
		func(v: float) -> void: Options.voice = v))

	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, UIStyle.S3)
	col.add_child(gap2)
	col.add_child(_toggle("Reduced motion", Options.reduced_motion,
		func(on: bool) -> void: Options.reduced_motion = on))
	col.add_child(_toggle("Larger text", Options.large_text,
		func(on: bool) -> void: Options.large_text = on))

	var gap3 := Control.new()
	gap3.custom_minimum_size = Vector2(0, UIStyle.S4)
	col.add_child(gap3)
	var back := _menu_row("Back")
	back.pressed.connect(func() -> void:
		Options.save_settings()
		_show(Screen.TITLE))
	col.add_child(back)
	return holder


func _slider(label: String, value: float, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.S4)
	var l := UIStyle.text(label, UIStyle.Type.MENU, UIStyle.TEXT_DIM_A)
	l.custom_minimum_size = Vector2(140, UIStyle.TAP)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	var s := HSlider.new()
	s.custom_minimum_size = Vector2(280, UIStyle.TAP)
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
	var b := _menu_row("%s   %s" % [label, "ON" if value else "OFF"])
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
	_focus_bar.modulate.a = 0.0
	if panel == Screen.CHAPTERS:
		_fill_chapters()


func _continue() -> void:
	Flow.continue_game()


func _start(entry: Dictionary) -> void:
	Flow.start_chapter(entry)
