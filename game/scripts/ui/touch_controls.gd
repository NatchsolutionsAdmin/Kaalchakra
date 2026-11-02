## TouchControls — the on-screen thumb controls.
##
## Left half of the screen is a *floating* joystick: it appears wherever your
## left thumb lands, rather than at a fixed spot you have to find. Right half
## is drag-to-orbit. Buttons sit bottom-right, with the Wheel dial top-right.
##
## Buttons are ordinary Control nodes, so they swallow their own touches before
## anything reaches `_unhandled_input` below — that is what keeps a thumb on the
## jump button from also spinning the camera.
##
## Everything here only writes into the `Touch` autoload. Movement code never
## looks at this file.
extends CanvasLayer

const JOY_RADIUS := 92.0       # how far the knob can travel
const JOY_DEADZONE := 0.12
const KNOB_RADIUS := 42.0
const ACTION_SIZE := 128.0     # all well above the ~44pt minimum tap target
const JUMP_SIZE := 108.0
const PHONE_SIZE := 92.0
const WHEEL_SIZE := 118.0
const ERA_SIZE := 92.0
const SWIPE_STEP := 70.0       # px of horizontal drag on the dial = one era

var _root: Control
var _paint: Control
var _action: Button
var _jump: Button
var _phone: Button
var _dial: WheelDial
var _era_buttons: Dictionary = {}

var _joy_touch := -1
var _look_touch := -1
var _joy_origin := Vector2.ZERO
var _joy_point := Vector2.ZERO
var _wheel_open := false
var _wheel_swipe := 0.0
## Opening the window emits a stray touch on the Mac (mouse-to-touch emulation
## fires as the window takes focus), which flashed the joystick ring for a
## frame. Ignore anything in the first moment.
var _settle_in := 0.25


func _ready() -> void:
	layer = 20
	_build()
	get_viewport().size_changed.connect(_layout)
	Interactions.focus_changed.connect(_on_focus_changed)
	Story.contact_available.connect(func(_who: String) -> void: _refresh_phone())
	# Who is allowed on screen is Chrome's decision, not four separate
	# signal handlers' (ART-DIRECTION.md §6).
	Chrome.context_changed.connect(func(_to: int) -> void: _apply_context())
	Chrome.idle_changed.connect(func(_idle: bool) -> void: _apply_idle())
	TimeShift.era_changed.connect(func(_f: Era.Id, _t: Era.Id) -> void: _refresh_wheel())
	_on_focus_changed(null)
	_refresh_wheel()
	_refresh_phone()
	_layout()
	_apply_context()
	_apply_idle()


# --- construction --------------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# The joystick is drawn, not built from nodes, so it can follow the thumb.
	_paint = Control.new()
	_paint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_paint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_paint.draw.connect(_draw_joystick)
	_root.add_child(_paint)

	_action = _round_button("", ACTION_SIZE, UIStyle.HIGHLIGHT)
	_action.button_down.connect(func() -> void: Touch.set_interact(true))
	_action.button_up.connect(func() -> void: Touch.set_interact(false))
	_root.add_child(_action)

	_phone = _round_button("MA", PHONE_SIZE, UIStyle.TEAL)
	_phone.pressed.connect(func() -> void: Phone.start("sakshi"))
	_phone.visible = false
	_root.add_child(_phone)

	_jump = _round_button("JUMP", JUMP_SIZE, UIStyle.DUST)
	_jump.button_down.connect(func() -> void: Touch.queue_jump())
	_root.add_child(_jump)

	# The Wheel is drawn, not a button with a label on it.
	_dial = WheelDial.new()
	_dial.tapped.connect(_toggle_wheel)
	_dial.gui_input.connect(_on_wheel_gui_input)
	_root.add_child(_dial)

	for era: Era.Id in Era.ALL:
		var b := _round_button(Era.SHORT[era], ERA_SIZE, Era.TINT[era])
		b.visible = false
		b.pressed.connect(_pick_era.bind(era))
		_era_buttons[era] = b
		_root.add_child(b)


func _round_button(text: String, diameter: float, tint: Color) -> Button:
	var b := Button.new()
	b.text = text
	UIStyle.style_round_button(b, diameter, tint)
	return b


# --- layout (safe areas: notches, rounded corners, home indicator) --------

## How much of each edge is unusable on this device, in viewport pixels.
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


func _layout() -> void:
	var vp := get_viewport().get_visible_rect().size
	var inset := _safe_inset()
	var pad := 26.0
	var left_pad := inset.x + pad
	var right := vp.x - inset.z - pad
	var bottom := vp.y - inset.w - pad
	var top := inset.y + pad

	_action.position = Vector2(right - ACTION_SIZE, bottom - ACTION_SIZE)
	_jump.position = Vector2(right - ACTION_SIZE - JUMP_SIZE - 22.0,
		bottom - JUMP_SIZE - (ACTION_SIZE - JUMP_SIZE) * 0.5)
	_dial.position = Vector2(right - WHEEL_SIZE, top)
	# The era-shift band sweeps out from the Wheel, so the Wheel has to tell
	# the shift where it is. In UV, because the shader works in UV.
	var dial_centre := _dial.position + Vector2(WHEEL_SIZE, WHEEL_SIZE) * 0.5
	TimeShift.band_origin = dial_centre / vp
	_phone.position = Vector2(left_pad, bottom - PHONE_SIZE)

	# The three era buttons fan down-and-left of the dial, inside the screen,
	# where a right thumb can sweep them without covering the view.
	# Screen angles: y grows downward, so 90..180 degrees is "below and left".
	var centre := _dial.position + Vector2(WHEEL_SIZE, WHEEL_SIZE) * 0.5
	var radius := WHEEL_SIZE + 62.0
	var angles := [176.0, 143.0, 110.0]
	for era: Era.Id in Era.ALL:
		var a := deg_to_rad(angles[int(era)])
		var c := centre + Vector2(cos(a), sin(a)) * radius
		(_era_buttons[era] as Button).position = c - Vector2(ERA_SIZE, ERA_SIZE) * 0.5
	_paint.queue_redraw()


## Thumbs off the controls while someone is speaking — otherwise the tap that
## advances a line also spins the camera.
## The call button is the only sign the player gets that Sakshi exists, so it
## appears the moment she becomes reachable and not before.
func _refresh_phone() -> void:
	_phone.visible = Phone.available("sakshi")


## Thumbs off the controls while someone is speaking — otherwise the tap that
## advances a line also spins the camera.
func _apply_context() -> void:
	var allowed := Chrome.shows_action()
	_root.visible = allowed
	if not allowed:
		_clear_joy()
		_look_touch = -1
		Touch.reset()
		if _wheel_open:
			_wheel_open = false
			_refresh_wheel()
	_dial.visible = Chrome.shows_wheel()


## After a few seconds of stillness the controls get out of the picture. They
## come straight back on the next touch, so nothing is ever unreachable — the
## left half of the screen still drives the joystick while it is invisible.
func _apply_idle() -> void:
	var to: float = 0.0 if Chrome.idle else 1.0
	for node: Control in [_jump, _phone]:
		create_tween().tween_property(node, "modulate:a", to, 0.45)
	# The dial stays legible: it is the one control that is also information.
	create_tween().tween_property(_dial, "modulate:a",
		0.55 if Chrome.idle else 1.0, 0.45)
	if Chrome.idle:
		_clear_joy()


# --- the floating joystick ----------------------------------------------

func _draw_joystick() -> void:
	if _joy_touch == -1:
		return
	var c := UIStyle.COPPER
	_paint.draw_circle(_joy_origin, JOY_RADIUS, Color(0.07, 0.06, 0.06, 0.26))
	_paint.draw_arc(_joy_origin, JOY_RADIUS, 0.0, TAU, 48, Color(c.r, c.g, c.b, 0.45), 2.0, true)
	_paint.draw_circle(_joy_point, KNOB_RADIUS, Color(c.r, c.g, c.b, 0.34))
	_paint.draw_arc(_joy_point, KNOB_RADIUS, 0.0, TAU, 32, UIStyle.OCHRE, 2.0, true)


func _set_joy(point: Vector2) -> void:
	var offset := point - _joy_origin
	if offset.length() > JOY_RADIUS:
		offset = offset.normalized() * JOY_RADIUS
	_joy_point = _joy_origin + offset
	var v := offset / JOY_RADIUS
	Touch.move = Vector2.ZERO if v.length() < JOY_DEADZONE else v
	_paint.queue_redraw()


func _clear_joy() -> void:
	_joy_touch = -1
	Touch.move = Vector2.ZERO
	_paint.queue_redraw()


# Runs only for touches no Control claimed, so buttons always win.
func _process(delta: float) -> void:
	if _settle_in > 0.0:
		_settle_in -= delta


func _unhandled_input(event: InputEvent) -> void:
	if _settle_in > 0.0:
		return
	var half := get_viewport().get_visible_rect().size.x * 0.5

	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if t.position.x < half and _joy_touch == -1:
				_joy_touch = t.index
				_joy_origin = t.position
				_set_joy(t.position)
			elif _look_touch == -1:
				_look_touch = t.index
		else:
			if t.index == _joy_touch:
				_clear_joy()
			elif t.index == _look_touch:
				_look_touch = -1

	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_touch:
			_set_joy(d.position)
		elif d.index == _look_touch:
			Touch.add_look(d.relative)


# --- the Wheel dial ------------------------------------------------------

func _toggle_wheel() -> void:
	_wheel_open = not _wheel_open
	_refresh_wheel()


func _pick_era(era: Era.Id) -> void:
	TimeShift.request_shift(era)
	_wheel_open = false
	_refresh_wheel()


## Swiping across the dial steps through the eras without opening it.
func _on_wheel_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		_wheel_swipe += (event as InputEventScreenDrag).relative.x
		if absf(_wheel_swipe) >= SWIPE_STEP:
			var step := 1 if _wheel_swipe > 0.0 else -1
			_wheel_swipe = 0.0
			var next := (int(TimeShift.current_era) + step + Era.ALL.size()) % Era.ALL.size()
			TimeShift.request_shift(next as Era.Id)
	elif event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed:
		_wheel_swipe = 0.0


func _refresh_wheel() -> void:
	var era := TimeShift.current_era
	for id: Era.Id in Era.ALL:
		var b := _era_buttons[id] as Button
		b.visible = _wheel_open
		b.disabled = (id == era)


# --- the contextual action button ---------------------------------------

func _on_focus_changed(target: Interactable) -> void:
	if target == null:
		_action.visible = false
		Touch.set_interact(false)
		return
	_action.visible = true
	_action.text = _verb(target.prompt_text())


## The button is round and small, so it gets a one-word verb; the full prompt
## stays in the HUD line above it.
func _verb(prompt: String) -> String:
	var first := prompt.strip_edges().split(" ")[0]
	return first.to_upper()
