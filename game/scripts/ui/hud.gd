## HUD — era indicator, objective, interaction prompt, the Wheel, banner text.
##
## Built in code rather than as a scene, because the real UI gets a proper
## art-directed skin later (R6.7) and this is a placeholder that should not
## pretend otherwise. Everything it shows, it reads from TimeShift and
## Interactions — the HUD never owns game state.
extends CanvasLayer

const DIM := UIStyle.INK_DIM

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
var _top_block: VBoxContainer
var _index_panel: PanelContainer
var _index_rows: VBoxContainer
var _index_header: Label
var _prompt_box: VBoxContainer


func _ready() -> void:
	layer = 10
	_build()
	TimeShift.era_changed.connect(_on_era_changed)
	TimeShift.shift_refused.connect(_on_shift_refused)
	TimeShift.knowledge_gained.connect(func(_id: String) -> void: _refresh_objective())
	TimeShift.reduced_motion_changed.connect(func(_enabled: bool) -> void: _refresh_hint())
	Story.objective_changed.connect(func(_t: String) -> void: _refresh_objective())
	Dialogue.started.connect(func(_id: String) -> void: _set_chrome(false))
	Dialogue.finished.connect(func(_id: String) -> void: _set_chrome(true))
	Interactions.focus_changed.connect(_on_focus_changed)
	Interactions.message.connect(_on_message)
	Decipher.sign_advanced.connect(func(_id: String, _step: int) -> void: _refresh_index())
	Decipher.header_readable.connect(_on_header_readable)
	get_viewport().size_changed.connect(_layout)
	_apply_era(TimeShift.current_era)
	_refresh_index()
	_refresh_objective()
	_refresh_hint()
	_on_focus_changed(null)
	_layout()


func _process(delta: float) -> void:
	_wheel.visible = Input.is_action_pressed("wheel_open")
	_index_panel.visible = Input.is_action_pressed("journal")
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
	top.add_theme_constant_override("separation", 2)
	root.add_child(top)
	_top_block = top

	_era_short = _label("", 30)
	top.add_child(_era_short)
	_era_title = _label("", 15, DIM)
	top.add_child(_era_title)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	top.add_child(gap)

	_objective = _label("", 17, UIStyle.DUST)
	_objective.custom_minimum_size = Vector2(540, 0)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	top.add_child(_objective)

	# Bottom strip: interaction prompt + hold bar.
	var prompt_box := VBoxContainer.new()
	prompt_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt_box.alignment = BoxContainer.ALIGNMENT_END
	prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_box.add_theme_constant_override("separation", 7)
	root.add_child(prompt_box)
	_prompt_box = prompt_box

	_prompt = _label("", 20)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_box.add_child(_prompt)

	_hold_bar = ProgressBar.new()
	_hold_bar.custom_minimum_size = Vector2(240, 8)
	_hold_bar.add_theme_stylebox_override("background",
		UIStyle.panel(Color(0.06, 0.05, 0.05, 0.6), Color(0.66, 0.44, 0.25, 0.35), 4, 0))
	_hold_bar.add_theme_stylebox_override("fill",
		UIStyle.panel(UIStyle.OCHRE, UIStyle.HIGHLIGHT, 4, 0))
	_hold_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hold_bar.show_percentage = false
	_hold_bar.max_value = 1.0
	_hold_bar.visible = false
	prompt_box.add_child(_hold_bar)

	# Centre, pushed down: banner for lines Eva reads.
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

	# The sign index — the journal, in its first form (R3.6). Hold I.
	var index_slot := CenterContainer.new()
	index_slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	index_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(index_slot)

	_index_panel = PanelContainer.new()
	_index_panel.visible = false
	_index_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_index_panel.add_theme_stylebox_override("panel", UIStyle.panel())
	index_slot.add_child(_index_panel)

	var index_box := VBoxContainer.new()
	index_box.add_theme_constant_override("separation", 7)
	_index_panel.add_child(index_box)
	var index_title := _label("THE INDEX", 15, DIM)
	index_box.add_child(index_title)
	_index_header = _label("", 19, UIStyle.HIGHLIGHT)
	index_box.add_child(_index_header)
	var rule := Control.new()
	rule.custom_minimum_size = Vector2(0, 8)
	index_box.add_child(rule)
	_index_rows = VBoxContainer.new()
	_index_rows.add_theme_constant_override("separation", 3)
	index_box.add_child(_index_rows)

	# Bottom-left: the controls, so Prabhjot never has to guess.
	_hint = _label("", 13, DIM)
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	root.add_child(_hint)


## Phones have notches, rounded corners and home indicators. Everything the
## player has to read gets pushed inside the safe area, and the bottom strip
## also clears the thumb controls.
func _layout() -> void:
	var inset := _safe_inset()
	var pad := 26.0
	_top_block.offset_left = inset.x + pad
	_top_block.offset_top = inset.y + pad
	# High enough to sit above the action and jump buttons.
	_prompt_box.offset_top = -(inset.w + 212.0)
	_prompt_box.offset_bottom = -(inset.w + 152.0)
	_hint.offset_left = inset.x + pad
	_hint.offset_top = -(inset.w + 58.0)
	_hint.offset_bottom = -(inset.w + 14.0)


## Unusable screen edges, in viewport pixels. Zero on a desktop window.
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


func _label(text: String, size: int, colour: Color = UIStyle.INK) -> Label:
	return UIStyle.label(text, size, colour)


func _panel_style() -> StyleBoxFlat:
	return UIStyle.panel()


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


## While a scene is playing, the HUD gets out of the way of the dialogue box.
func _set_chrome(visible_now: bool) -> void:
	_prompt_box.visible = visible_now
	_hint.visible = visible_now


## One row per sign: where it is in the chain, and where it has to go next.
func _refresh_index() -> void:
	for c: Node in _index_rows.get_children():
		c.queue_free()
	var marks := ["·", "○", "◐", "●"]
	for id: String in Decipher.order:
		var step: int = Decipher.step_of(id)
		var entry: Dictionary = Decipher.signs[id]
		var shown: String = entry["name"] if step >= Decipher.Step.LEARNED else "unread"
		var tail := ""
		if step < Decipher.Step.CONFIRMED:
			tail = "  →  %s" % Era.SHORT[Decipher.era_for_next(id)]
		var row := _label("  %s  %-22s%s" % [marks[step], shown, tail], 16,
			UIStyle.INK if step > 0 else DIM)
		_index_rows.add_child(row)
	var p := Decipher.header_progress()
	_index_header.text = "%s        %d / %d" % [Decipher.header_text(), p.x, p.y]


func _on_header_readable() -> void:
	_on_message("WHAT THE WATER MUST NOT TAKE.\n\nIt is not a prayer. It is a manifest.", 9.0)


func _refresh_objective() -> void:
	# Once the script starts setting objectives, they win over the prototype's
	# hard-coded ones.
	if not Story.objective.is_empty():
		_objective.text = Story.objective
		_on_focus_changed(_watched)
		return
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
	_hint.text = "Left thumb to walk, push it to the edge to run  ·  drag the right to look  ·  tap the dial to turn the Wheel, or swipe it\nDesk testing: WASD, Shift, Space, E, 1 / 2 / 3, hold Q  ·  M reduced motion: %s  ·  R respawn" % rm
