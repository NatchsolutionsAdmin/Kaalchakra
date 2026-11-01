## HUD — era indicator, objective, interaction prompt, the Wheel, banner text.
##
## Built in code rather than as a scene, because the real UI gets a proper
## art-directed skin later (R6.7) and this is a placeholder that should not
## pretend otherwise. Everything it shows, it reads from TimeShift and
## Interactions — the HUD never owns game state.
extends CanvasLayer

const DIM := Color(1, 1, 1, 0.55)

var _era_short: Label
var _era_title: Label
var _objective: Label
var _prompt: Label
var _hold_bar: ProgressBar
var _banner: PanelContainer
var _banner_label: Label
var _wheel: PanelContainer
var _wheel_rows: Dictionary = {}
var _hint: Label

var _banner_timer: float = 0.0
var _watched: Interactable = null


func _ready() -> void:
	layer = 10
	_build()
	TimeShift.era_changed.connect(_on_era_changed)
	TimeShift.shift_refused.connect(_on_shift_refused)
	TimeShift.knowledge_gained.connect(func(_id: String) -> void: _refresh_objective())
	TimeShift.reduced_motion_changed.connect(func(_enabled: bool) -> void: _refresh_hint())
	Interactions.focus_changed.connect(_on_focus_changed)
	Interactions.message.connect(_on_message)
	_apply_era(TimeShift.current_era)
	_refresh_objective()
	_refresh_hint()
	_on_focus_changed(null)


func _process(delta: float) -> void:
	_wheel.visible = Input.is_action_pressed("wheel_open")
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_banner.visible = false


# --- construction --------------------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Top-left: era + objective.
	var top := VBoxContainer.new()
	top.offset_left = 28
	top.offset_top = 22
	top.add_theme_constant_override("separation", 2)
	root.add_child(top)

	_era_short = _label("", 30)
	top.add_child(_era_short)
	_era_title = _label("", 15, DIM)
	top.add_child(_era_title)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	top.add_child(gap)

	_objective = _label("", 17)
	_objective.custom_minimum_size = Vector2(540, 0)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(_objective)

	# Bottom strip: interaction prompt + hold bar.
	var prompt_box := VBoxContainer.new()
	prompt_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_box.offset_top = -124
	prompt_box.offset_bottom = -64
	prompt_box.alignment = BoxContainer.ALIGNMENT_END
	prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_box.add_theme_constant_override("separation", 7)
	root.add_child(prompt_box)

	_prompt = _label("", 20)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_box.add_child(_prompt)

	_hold_bar = ProgressBar.new()
	_hold_bar.custom_minimum_size = Vector2(240, 7)
	_hold_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hold_bar.show_percentage = false
	_hold_bar.max_value = 1.0
	_hold_bar.visible = false
	prompt_box.add_child(_hold_bar)

	# Centre, pushed down: banner for lines Evara reads.
	var banner_slot := CenterContainer.new()
	banner_slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner_slot.offset_top = 150
	banner_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner_slot)

	_banner = PanelContainer.new()
	_banner.custom_minimum_size = Vector2(700, 0)
	_banner.visible = false
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_theme_stylebox_override("panel", _panel_style())
	banner_slot.add_child(_banner)

	_banner_label = _label("", 19)
	_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)

	# Centre: the Wheel (hold Q). A real eight-spoked radial comes later (R6.3).
	var wheel_slot := CenterContainer.new()
	wheel_slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	wheel_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wheel_slot)

	_wheel = PanelContainer.new()
	_wheel.visible = false
	_wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wheel.add_theme_stylebox_override("panel", _panel_style())
	wheel_slot.add_child(_wheel)

	var wheel_box := VBoxContainer.new()
	wheel_box.add_theme_constant_override("separation", 9)
	_wheel.add_child(wheel_box)

	var wheel_title := _label("THE KAALCHAKRA", 14, DIM)
	wheel_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wheel_box.add_child(wheel_title)

	for era: Era.Id in Era.ALL:
		var row := _label("", 19)
		row.custom_minimum_size = Vector2(360, 0)
		_wheel_rows[era] = row
		wheel_box.add_child(row)

	# Bottom-left: the controls, so Prabhjot never has to guess.
	_hint = _label("", 13, DIM)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.offset_left = 28
	_hint.offset_top = -62
	_hint.offset_bottom = -18
	root.add_child(_hint)


func _label(text: String, size: int, colour: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.04, 0.05, 0.84)
	sb.border_color = Color(1, 1, 1, 0.14)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	return sb


# --- reactions -----------------------------------------------------------

func _on_era_changed(_from: Era.Id, to: Era.Id) -> void:
	_apply_era(to)


func _apply_era(era: Era.Id) -> void:
	_era_short.text = Era.SHORT[era]
	_era_short.add_theme_color_override("font_color", Era.TINT[era])
	_era_title.text = Era.TITLE[era]
	var keys := ["1", "2", "3"]
	for id: Era.Id in Era.ALL:
		var row := _wheel_rows[id] as Label
		var mark := "▶" if id == era else "   "
		row.text = "%s  [%s]  %-8s %s" % [mark, keys[int(id)], Era.SHORT[id], Era.TITLE[id]]
		row.add_theme_color_override("font_color", Era.TINT[id] if id == era else DIM)


func _on_shift_refused(_era: Era.Id, reason: String) -> void:
	_on_message(reason, 3.0)


func _on_focus_changed(target: Interactable) -> void:
	if _watched != null and is_instance_valid(_watched):
		if _watched.hold_progress.is_connected(_on_hold_progress):
			_watched.hold_progress.disconnect(_on_hold_progress)
	_watched = target
	_hold_bar.value = 0.0
	_hold_bar.visible = false
	if target == null:
		_prompt.text = ""
		return
	target.hold_progress.connect(_on_hold_progress)
	var verb := "hold [E]" if target.hold_seconds() > 0.0 else "[E]"
	_prompt.text = "%s   %s" % [verb, target.prompt_text()]


func _on_hold_progress(ratio: float) -> void:
	_hold_bar.value = ratio
	_hold_bar.visible = ratio > 0.0


func _on_message(text: String, seconds: float) -> void:
	_banner_label.text = text
	_banner.visible = true
	_banner_timer = seconds


func _refresh_objective() -> void:
	if not TimeShift.knows("keeper_mark"):
		_objective.text = "2026 has nothing left to read. Turn the Wheel back to 1900 BCE and find what the city wrote down."
	elif not TimeShift.knows("chamber_opened"):
		_objective.text = "You know where it is. Return to 2026, climb down the reservoir steps, and dig the basin floor."
	else:
		_objective.text = "WHAT THE WATER MUST NOT TAKE.   —   prototype complete."
	# The prompt text can depend on knowledge too (the dig site changes wording).
	_on_focus_changed(_watched)


func _refresh_hint() -> void:
	var rm := "on" if TimeShift.reduced_motion else "off"
	_hint.text = "WASD move  ·  Shift run  ·  Space jump / pull up a ledge  ·  E interact\n1 / 2 / 3 shift era  ·  hold Q the Wheel  ·  M reduced motion: %s  ·  R respawn  ·  Esc free the mouse" % rm
