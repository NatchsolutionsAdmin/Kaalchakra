## HUD — location caption, objective, interaction prompt, banner, the index.
##
## Rebuilt against the art review (ART-DIRECTION.md §6). The old HUD's problem
## was not that it was ugly, it was that it never went away: an era label, an
## objective and two lines of keyboard hints sat permanently on top of the
## picture. The review's rule is that the HUD *announces and then leaves*.
##
## So:
##   - the location caption appears on arrival and fades after a few seconds
##   - the objective appears when it CHANGES, and otherwise on demand
##   - the controls crib is gone from play entirely (F1 brings it back at the
##     desk, which is the only place it was ever for)
##   - everything else asks `Chrome` whether it is allowed on screen
##
## Nothing here owns game state; it reads TimeShift, Story and Interactions.
extends CanvasLayer

## How long an announcement stays up before it fades out.
const CAPTION_SECONDS := 3.6
const OBJECTIVE_SECONDS := 6.0
const FADE := 0.35

var _caption: VBoxContainer
var _caption_era: Label
var _caption_place: Label
var _objective_box: PanelContainer
var _objective: Label
var _prompt: Label
var _hold_bar: ProgressBar
var _banner: PanelContainer
var _banner_label: Label
var _index_panel: PanelContainer
var _index_rows: VBoxContainer
var _index_header: Label
var _prompt_box: VBoxContainer
var _crib: Label

var _banner_timer := 0.0
var _watched: Interactable = null
var _scale := 1.0
var _last_objective := ""
var _crib_on := false


func _ready() -> void:
	layer = 10
	_build()
	TimeShift.era_changed.connect(_on_era_changed)
	TimeShift.shift_refused.connect(_on_shift_refused)
	TimeShift.knowledge_gained.connect(func(_id: String) -> void: _refresh_objective())
	Story.objective_changed.connect(func(_t: String) -> void: _refresh_objective())
	Interactions.focus_changed.connect(_on_focus_changed)
	Interactions.message.connect(_on_message)
	Decipher.sign_advanced.connect(func(_id: String, _step: int) -> void: _refresh_index())
	Decipher.header_readable.connect(_on_header_readable)
	Chrome.context_changed.connect(func(_to: int) -> void: _apply_context())
	get_viewport().size_changed.connect(_layout)
	_refresh_index()
	_refresh_objective(true)
	_apply_context()
	_layout()
	_announce_location()


func _process(delta: float) -> void:
	_index_panel.visible = Chrome.shows_journal() and Input.is_action_pressed("journal")
	if Input.is_action_just_pressed("phone"):
		if Phone.in_call:
			Phone.advance()
		else:
			Phone.start("sakshi")
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			_fade_out(_banner)


func _unhandled_key_input(event: InputEvent) -> void:
	# The controls crib is a desk-testing tool, not part of the game. The
	# review's instruction is to hide debug-style information entirely, so it
	# lives behind a key rather than on screen.
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_F1:
		_crib_on = not _crib_on
		_crib.visible = _crib_on
		_refresh_crib()


# --- construction --------------------------------------------------------

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Top-left: the location caption. Announces, then leaves.
	_caption = VBoxContainer.new()
	_caption.add_theme_constant_override("separation", UIStyle.S1)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.modulate.a = 0.0
	root.add_child(_caption)

	_caption_era = UIStyle.text("", UIStyle.Type.CHAPTER)
	_caption.add_child(_caption_era)
	_caption_place = UIStyle.text("", UIStyle.Type.LABEL, UIStyle.TEXT_DIM_A)
	_caption.add_child(_caption_place)

	# Below it: the objective, on a document surface so it reads as a note
	# rather than as floating system text.
	_objective_box = PanelContainer.new()
	_objective_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_box.add_theme_stylebox_override("panel", UIStyle.document(UIStyle.S3))
	_objective_box.modulate.a = 0.0
	root.add_child(_objective_box)

	_objective = UIStyle.text("", UIStyle.Type.BODY, UIStyle.TEXT_DIM_A)
	_objective.custom_minimum_size = Vector2(UIStyle.COLUMN, 0)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_box.add_child(_objective)

	# Bottom strip: interaction prompt + hold bar.
	_prompt_box = VBoxContainer.new()
	_prompt_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt_box.alignment = BoxContainer.ALIGNMENT_END
	_prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_box.add_theme_constant_override("separation", UIStyle.S2)
	root.add_child(_prompt_box)

	_prompt = UIStyle.text("", UIStyle.Type.MENU)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_box.add_child(_prompt)

	_hold_bar = ProgressBar.new()
	_hold_bar.custom_minimum_size = Vector2(240, 6)
	_hold_bar.add_theme_stylebox_override("background",
		UIStyle.panel(Color(0.06, 0.08, 0.11, 0.6), UIStyle.BORDER, 3, 0))
	_hold_bar.add_theme_stylebox_override("fill",
		UIStyle.panel(UIStyle.COPPER, UIStyle.OCHRE, 3, 0))
	_hold_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hold_bar.show_percentage = false
	_hold_bar.max_value = 1.0
	_hold_bar.visible = false
	_prompt_box.add_child(_hold_bar)

	# Centre, pushed down: banner for lines Eva reads.
	var banner_slot := CenterContainer.new()
	banner_slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner_slot.offset_top = 150
	banner_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner_slot)

	_banner = PanelContainer.new()
	_banner.custom_minimum_size = Vector2(UIStyle.COLUMN + 120.0, 0)
	_banner.visible = false
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_theme_stylebox_override("panel", UIStyle.document())
	banner_slot.add_child(_banner)

	_banner_label = UIStyle.text("", UIStyle.Type.DIALOGUE)
	_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_label)

	_build_index(root)

	# Bottom-left, off by default: what to press, for desk testing only.
	_crib = UIStyle.text("", UIStyle.Type.METADATA, UIStyle.DISABLED)
	_crib.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_crib.visible = false
	root.add_child(_crib)


## The sign index. The review asks for it to be elevated from a list into the
## primary archaeological mechanic, and to compare one observation across
## three columns: intact, eroded, archive scan. So the three columns ARE the
## three eras, and a row is one sign's progress through all three mornings.
func _build_index(root: Control) -> void:
	var index_slot := CenterContainer.new()
	index_slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	index_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(index_slot)

	_index_panel = PanelContainer.new()
	_index_panel.visible = false
	_index_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_index_panel.add_theme_stylebox_override("panel", UIStyle.document(UIStyle.S4))
	index_slot.add_child(_index_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UIStyle.S2)
	_index_panel.add_child(box)

	box.add_child(UIStyle.text("THE INDEX", UIStyle.Type.LABEL, UIStyle.TEXT_DIM_A))
	_index_header = UIStyle.text("", UIStyle.Type.PANEL_TITLE, UIStyle.OCHRE)
	box.add_child(_index_header)

	var rule := Control.new()
	rule.custom_minimum_size = Vector2(0, UIStyle.S2)
	box.add_child(rule)

	box.add_child(_index_row("SIGN", "INTACT", "ERODED", "ARCHIVE",
		UIStyle.Type.LABEL, UIStyle.TEXT_DIM_A))
	box.add_child(_index_row("", "1900 BCE", "2026", "2087",
		UIStyle.Type.METADATA, UIStyle.DISABLED))

	var rule2 := Control.new()
	rule2.custom_minimum_size = Vector2(0, UIStyle.S2)
	box.add_child(rule2)

	_index_rows = VBoxContainer.new()
	_index_rows.add_theme_constant_override("separation", UIStyle.S1)
	box.add_child(_index_rows)


## One row of the index: a name and three era cells.
func _index_row(name_text: String, a: String, b: String, c: String,
		role: UIStyle.Type, colour: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UIStyle.S3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var who := UIStyle.text(name_text, role, colour, _scale)
	who.custom_minimum_size = Vector2(230, 0)
	row.add_child(who)
	for i: int in 3:
		var cell := UIStyle.text([a, b, c][i], role, colour, _scale)
		cell.custom_minimum_size = Vector2(96, 0)
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(cell)
	return row


# --- layout --------------------------------------------------------------

## Phones have notches, rounded corners and home indicators. The review puts
## the HUD edge at 32px *plus* whatever the device itself steals.
func _layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	_scale = UIStyle.scale_for(vp)
	var inset := _safe_inset()
	var pad := UIStyle.EDGE * _scale

	_caption.offset_left = inset.x + pad
	_caption.offset_top = inset.y + pad
	_objective_box.offset_left = inset.x + pad
	_objective_box.offset_top = inset.y + pad + 86.0 * _scale

	# High enough to sit above the thumb controls.
	_prompt_box.offset_top = -(inset.w + 212.0 * _scale)
	_prompt_box.offset_bottom = -(inset.w + 150.0 * _scale)
	_crib.offset_left = inset.x + pad
	_crib.offset_top = -(inset.w + 58.0)
	_crib.offset_bottom = -(inset.w + 14.0)


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


# --- showing and hiding ---------------------------------------------------

func _fade_in(node: CanvasItem) -> void:
	node.visible = true
	create_tween().tween_property(node, "modulate:a", 1.0, FADE)


func _fade_out(node: CanvasItem) -> void:
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 0.0, FADE)
	tween.tween_callback(func() -> void: node.visible = false)


## Show something for a while, then let it go.
func _flash(node: CanvasItem, seconds: float) -> void:
	node.visible = true
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1.0, FADE)
	tween.tween_interval(seconds)
	tween.tween_property(node, "modulate:a", 0.0, FADE)
	tween.tween_callback(func() -> void: node.visible = false)


func _apply_context() -> void:
	var talking := not Chrome.shows_action()
	_prompt_box.visible = not talking
	if talking:
		_index_panel.visible = false


# --- reactions -----------------------------------------------------------

func _on_era_changed(_from: Era.Id, _to: Era.Id) -> void:
	_announce_location()


## "PAST / 1900 BCE · Dholarath", for a few seconds, on arrival.
func _announce_location() -> void:
	if not Chrome.shows_location():
		return
	var era := TimeShift.current_era
	_caption_era.text = UIStyle.tracked(Era.SHORT[era], 1)
	_caption_era.add_theme_color_override("font_color", Era.TINT[era])
	_caption_place.text = UIStyle.tracked(Era.TITLE[era].to_upper(), 1)
	_flash(_caption, CAPTION_SECONDS)


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
	var verb := "hold" if target.hold_seconds() > 0.0 else ""
	_prompt.text = "%s %s" % [verb, target.prompt_text()] if verb else target.prompt_text()


func _on_hold_progress(ratio: float) -> void:
	_hold_bar.value = ratio
	_hold_bar.visible = ratio > 0.0


func _on_message(text: String, seconds: float) -> void:
	_banner_label.text = text
	_banner.modulate.a = 0.0
	_fade_in(_banner)
	_banner_timer = seconds


## One row per sign, three cells: where it has been read, and where it has
## still to be read. A filled cell is a morning this sign has survived into.
func _refresh_index() -> void:
	for c: Node in _index_rows.get_children():
		c.queue_free()
	for id: String in Decipher.order:
		var step: int = Decipher.step_of(id)
		var entry: Dictionary = Decipher.signs[id]
		var shown: String = entry["name"] if step >= Decipher.Step.LEARNED else "—"
		var next_era := Decipher.era_for_next(id) if step < Decipher.Step.CONFIRMED else -1
		var cells: Array[String] = []
		for i: int in 3:
			if step > i:
				cells.append("●")
			elif int(next_era) == i:
				cells.append("○")
			else:
				cells.append("·")
		var row := _index_row(shown, cells[0], cells[1], cells[2],
			UIStyle.Type.EVIDENCE,
			UIStyle.TEXT if step > 0 else UIStyle.DISABLED)
		# The cell she can act on next is the only coloured thing in the row.
		if next_era >= 0:
			var cell := row.get_child(1 + int(next_era)) as Label
			cell.add_theme_color_override("font_color", UIStyle.OCHRE)
		_index_rows.add_child(row)
	var p := Decipher.header_progress()
	_index_header.text = "%s        %d / %d" % [Decipher.header_text(), p.x, p.y]


func _on_header_readable() -> void:
	_on_message("WHAT THE WATER MUST NOT TAKE.\n\nIt is not a prayer. It is a manifest.", 9.0)


## The objective is shown when it changes, and then gets out of the way.
func _refresh_objective(silent: bool = false) -> void:
	var text := Story.objective
	if text.is_empty():
		# Prototype fallbacks, until the script sets objectives everywhere.
		if not TimeShift.knows("keeper_mark"):
			text = "2026 has nothing left to read. Turn the Wheel back to 1900 BCE and find what the city wrote down."
		elif not TimeShift.knows("chamber_opened"):
			text = "You know where it is. Return to 2026, climb down the reservoir steps, and dig the basin floor."
		else:
			text = "WHAT THE WATER MUST NOT TAKE.   —   prototype complete."
	var changed := text != _last_objective
	_last_objective = text
	_objective.text = text
	if changed and not silent:
		_flash(_objective_box, OBJECTIVE_SECONDS)
	# The prompt wording can depend on knowledge too.
	_on_focus_changed(_watched)


func _refresh_crib() -> void:
	if not _crib_on:
		return
	var rm := "on" if TimeShift.reduced_motion else "off"
	_crib.text = "F1 hides this  ·  WASD, Shift, Space, E, 1 / 2 / 3, hold Q  ·  I index  ·  C phone  ·  M reduced motion: %s  ·  R respawn" % rm
