## PhoneUI — the call screen.
##
## Deliberately small and off to one side, not a full-screen takeover: Eva is
## standing in a trench holding a phone to her ear, not entering a menu. The
## world stays visible behind it because the thing her mother is describing is
## usually on screen.
extends CanvasLayer

var _root: Control
var _panel: PanelContainer
var _caller: Label
var _status: Label
var _line: Label
var _speaker: Label
var _overlay: ColorRect
var _chrome: Control
var _timer_label: Label
var _dots := 0.0
var _elapsed := 0.0
var _fade := 0.0


func _ready() -> void:
	layer = 25
	_build()
	Phone.call_started.connect(_on_started)
	Phone.line_spoken.connect(_on_line)
	Phone.call_ended.connect(_on_ended)
	_root.visible = false


func _process(delta: float) -> void:
	# The world treatment fades in and out rather than snapping, so picking up
	# feels like attention shifting.
	var want := 1.0 if Phone.in_call else 0.0
	if not is_equal_approx(_fade, want):
		_fade = move_toward(_fade, want, delta * 3.2)
		(_overlay.material as ShaderMaterial).set_shader_parameter("amount", _fade)
		_overlay.visible = _fade > 0.001
		if _fade <= 0.001 and not Phone.in_call:
			_root.visible = false
	if not Phone.in_call:
		return
	_elapsed += delta
	_timer_label.text = "%d:%02d" % [int(_elapsed) / 60, int(_elapsed) % 60]
	_chrome.queue_redraw()
	if _status.visible:
		_dots += delta * 2.4
		_status.text = "calling" + ".".repeat(1 + int(_dots) % 3)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.gui_input.connect(_on_tap)
	add_child(_root)

	# Full-screen treatment, behind the panel.
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color(1, 1, 1, 1)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/call_overlay.gdshader")
	mat.set_shader_parameter("amount", 0.0)
	_overlay.material = mat
	_overlay.visible = false
	_root.add_child(_overlay)

	var slot := CenterContainer.new()
	slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot.offset_top = -120.0
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(slot)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(560, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override("panel",
		UIStyle.panel(Color(0.05, 0.05, 0.06, 0.94), UIStyle.TEAL, 8, 26))
	slot.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)

	# Call chrome: avatar, name, signal bars, running timer.
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)

	_chrome = Control.new()
	_chrome.custom_minimum_size = Vector2(56, 56)
	_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chrome.draw.connect(_draw_chrome)
	head.add_child(_chrome)

	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", 0)
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(who)
	_caller = UIStyle.label("MA", 20, UIStyle.TEAL)
	who.add_child(_caller)
	_status = UIStyle.label("calling...", 14, UIStyle.INK_DIM)
	who.add_child(_status)

	_timer_label = UIStyle.label("0:00", 15, UIStyle.INK_DIM)
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(_timer_label)

	var rule := Control.new()
	rule.custom_minimum_size = Vector2(0, 6)
	box.add_child(rule)
	_speaker = UIStyle.label("", 14, UIStyle.INK_DIM)
	box.add_child(_speaker)
	_line = UIStyle.label("", 19, UIStyle.INK)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_line)


## Avatar disc and signal bars, drawn rather than imported.
func _draw_chrome() -> void:
	var c := _chrome.size * 0.5
	var r := 24.0
	_chrome.draw_circle(c, r, Color(UIStyle.TEAL, 0.22))
	_chrome.draw_arc(c, r, 0.0, TAU, 28, UIStyle.TEAL, 2.0, true)
	# A crackly line: the bars flicker between three and four.
	var bars := 3 + int(fmod(_elapsed * 1.7, 2.0))
	for i in 4:
		var h := 4.0 + i * 4.0
		var x := c.x - 12.0 + i * 8.0
		var lit := i < bars
		_chrome.draw_rect(Rect2(Vector2(x, c.y + 14.0 - h), Vector2(4.0, h)),
			UIStyle.TEAL if lit else Color(UIStyle.TEAL, 0.22))


func _on_started(_who: String) -> void:
	_root.visible = true
	_status.visible = true
	_speaker.visible = false
	_line.text = ""
	_dots = 0.0
	_elapsed = 0.0


func _on_line(speaker: String, text: String) -> void:
	_status.visible = false
	_speaker.visible = true
	_speaker.text = "Eva" if speaker == "EVA" else "Ma"
	_speaker.add_theme_color_override("font_color",
		UIStyle.INK_DIM if speaker == "EVA" else UIStyle.HIGHLIGHT)
	_line.text = text


func _on_ended(_who: String) -> void:
	# _root stays up until the treatment has faded out; _process closes it.
	_status.visible = false


func _on_tap(event: InputEvent) -> void:
	var tapped := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if tapped:
		Phone.advance()
