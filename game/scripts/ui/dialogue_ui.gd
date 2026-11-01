## DialogueUI — how a line of the script looks on screen.
##
## The only thing in the game that knows what dialogue looks like. It listens
## to the `Dialogue` autoload and draws; it never decides what happens next.
## Rewriting the presentation later means touching this file and nothing else.
##
## Touch rules: tap anywhere to move on, tap again while text is still typing
## to finish it instantly, and choices are full-width buttons rather than
## anything you have to aim at.
extends CanvasLayer

## Stage directions are for actors, not players. On while we are reading the
## script in-engine; off for anything a player sees.
@export var show_directions := true
@export var characters_per_second := 45.0

var _root: Control
var _tapper: Control
var _panel: PanelContainer
var _speaker: Label
var _direction: Label
var _text: Label
var _choices: VBoxContainer

var _full := ""
var _typed := 0.0
var _typing := false


func _ready() -> void:
	layer = 30
	_build()
	Dialogue.started.connect(_on_started)
	Dialogue.finished.connect(_on_finished)
	Dialogue.line_shown.connect(_on_line)
	Dialogue.choices_shown.connect(_on_choices)
	get_viewport().size_changed.connect(_layout)
	_root.visible = false
	_layout()


func _process(delta: float) -> void:
	if not _typing:
		return
	_typed += characters_per_second * delta
	if _typed >= float(_full.length()):
		_typed = float(_full.length())
		_typing = false
	_text.visible_characters = int(_typed)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Catches taps anywhere that is not a choice button.
	_tapper = Control.new()
	_tapper.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tapper.mouse_filter = Control.MOUSE_FILTER_STOP
	_tapper.gui_input.connect(_on_tap)
	_root.add_child(_tapper)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel", _panel_style())
	_root.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_panel.add_child(box)

	_speaker = _label(19, Color(0.95, 0.80, 0.45))
	box.add_child(_speaker)
	_direction = _label(15, Color(1, 1, 1, 0.45))
	box.add_child(_direction)
	_text = _label(21, Color(1, 1, 1))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_text)

	_choices = VBoxContainer.new()
	_choices.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_choices.alignment = BoxContainer.ALIGNMENT_END
	_choices.add_theme_constant_override("separation", 10)
	_choices.visible = false
	_root.add_child(_choices)


func _label(size: int, colour: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.03, 0.04, 0.9)
	sb.border_color = Color(1, 1, 1, 0.12)
	sb.border_width_top = 1
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 20
	sb.content_margin_bottom = 24
	return sb


func _choice_style(fill: Color, edge: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb


func _layout() -> void:
	var inset := _safe_inset()
	_panel.offset_left = inset.x
	_panel.offset_right = -inset.z
	_panel.offset_top = -(inset.w + 190.0)
	_panel.offset_bottom = -inset.w
	_choices.offset_left = inset.x + 40.0
	_choices.offset_right = -(inset.z + 40.0)
	_choices.offset_top = -(inset.w + 260.0)
	_choices.offset_bottom = -(inset.w + 24.0)


func _safe_inset() -> Vector4:
	var vp := get_viewport().get_visible_rect().size
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0:
		return Vector4.ZERO
	var safe := DisplayServer.get_display_safe_area()
	var k := vp / win
	return Vector4(
		maxf(0.0, safe.position.x * k.x),
		maxf(0.0, safe.position.y * k.y),
		maxf(0.0, (win.x - safe.end.x) * k.x),
		maxf(0.0, (win.y - safe.end.y) * k.y)
	)


# --- reactions -----------------------------------------------------------

func _on_started(_id: String) -> void:
	_root.visible = true
	_layout()


func _on_finished(_id: String) -> void:
	_root.visible = false
	_clear_choices()


func _on_line(speaker: String, text: String, direction: String, _id: String) -> void:
	_clear_choices()
	_tapper.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.visible = true
	_speaker.text = speaker
	_direction.text = "(%s)" % direction if (show_directions and not direction.is_empty()) else ""
	_direction.visible = not _direction.text.is_empty()
	_full = text
	_text.text = text
	_text.visible = not text.is_empty()
	_text.visible_characters = 0
	_typed = 0.0
	_typing = not text.is_empty()
	if not _typing:
		_text.visible_characters = -1


func _on_choices(options: Array) -> void:
	_clear_choices()
	# Taps must not advance while a choice is up, or the player answers by
	# accident with the same tap that finished the line.
	_tapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	_choices.visible = true
	for i in options.size():
		var option: Dictionary = options[i]
		var b := Button.new()
		b.text = option["label"]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 62)
		b.add_theme_font_size_override("font_size", 19)
		b.add_theme_color_override("font_color", Color(1, 1, 1))
		b.add_theme_color_override("font_hover_color", Color(0.98, 0.84, 0.50))
		b.add_theme_color_override("font_pressed_color", Color(0.1, 0.08, 0.05))
		for state: String in ["normal", "focus"]:
			b.add_theme_stylebox_override(state,
				_choice_style(Color(0.05, 0.05, 0.06, 0.92), Color(1, 1, 1, 0.18)))
		b.add_theme_stylebox_override("hover",
			_choice_style(Color(0.10, 0.10, 0.11, 0.95), Color(0.98, 0.84, 0.50, 0.6)))
		b.add_theme_stylebox_override("pressed",
			_choice_style(Color(0.95, 0.80, 0.42, 0.95), Color(1, 1, 1, 0.3)))
		b.pressed.connect(func() -> void: Dialogue.choose(i))
		_choices.add_child(b)


func _clear_choices() -> void:
	_choices.visible = false
	for c: Node in _choices.get_children():
		c.queue_free()


func _on_tap(event: InputEvent) -> void:
	var tapped := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if not tapped:
		return
	if _typing:
		# First tap finishes the line, second moves on. Never skip unread text.
		_typing = false
		_text.visible_characters = -1
		return
	Dialogue.advance()
