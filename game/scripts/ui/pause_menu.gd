## PauseMenu — Escape, or the pause button.
##
## Pauses the tree, so nothing moves behind it, and offers the two things a
## player actually wants mid-session: get back in, or get out safely. Quitting
## saves first — on a phone, leaving is the normal way a session ends, not an
## accident.
extends CanvasLayer

var _root: Control
var _open := false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	# Never over a conversation: pausing mid-line loses the player's place.
	if not _open and Dialogue.is_active():
		return
	_open = not _open
	_root.visible = _open
	get_tree().paused = _open


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.03, 0.04, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var slot := CenterContainer.new()
	slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(slot)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.panel(PANEL_BG, UIStyle.PANEL_EDGE, 6, 30))
	slot.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	col.add_child(UIStyle.label("PAUSED", 15, UIStyle.INK_DIM))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	col.add_child(gap)

	col.add_child(_button("Resume", UIStyle.HIGHLIGHT, func() -> void: toggle()))
	col.add_child(_button("Save now", UIStyle.DUST, func() -> void:
		SaveGame.save_now("manual")))
	col.add_child(_button("Quit to menu", UIStyle.INK_DIM, func() -> void:
		SaveGame.save_now("quit to menu")
		_open = false
		_root.visible = false
		Flow.to_menu()))


const PANEL_BG := Color(0.06, 0.05, 0.05, 0.95)


func _button(text: String, tint: Color, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(320, 54)
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_color_override("font_color", tint)
	b.add_theme_color_override("font_hover_color", UIStyle.HIGHLIGHT)
	b.add_theme_color_override("font_pressed_color", UIStyle.PRESSED_INK)
	b.add_theme_stylebox_override("normal",
		UIStyle.panel(Color(0.08, 0.07, 0.07, 0.8), Color(0.66, 0.44, 0.25, 0.3), 4, 20))
	b.add_theme_stylebox_override("hover",
		UIStyle.panel(Color(0.13, 0.11, 0.10, 0.9), UIStyle.OCHRE, 4, 20))
	b.add_theme_stylebox_override("pressed", UIStyle.panel(UIStyle.OCHRE, UIStyle.SALT, 4, 20))
	b.pressed.connect(on_press)
	return b
