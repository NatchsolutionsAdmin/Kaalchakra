## WheelDial — the Kaalchakra itself, drawn rather than textured.
##
## An eight-spoked copper disc, which is what the story bible describes, with
## three of the eight spokes marked as the three mornings it stops at. It turns
## to bring the live era to the top, and flares when it lands.
##
## Drawn with _draw() instead of an image for three reasons: it is pure
## geometry, it stays crisp on any phone at any density, and it can animate
## without a sprite sheet. No texture memory, nothing to download.
##
## The eighth spoke is the point of the finale — she turns it one notch past
## its stop — so the spokes are drawn, not implied.
class_name WheelDial
extends Control

const SPOKES := 8

signal tapped

var _angle := 0.0          # current rotation, radians
var _target_angle := 0.0
var _flare := 0.0          # 0..1, brief glow after a shift
var _era := Era.Id.PRESENT


func _ready() -> void:
	custom_minimum_size = Vector2(118, 118)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	TimeShift.era_changed.connect(_on_era_changed)
	_era = TimeShift.current_era
	_angle = _angle_for(_era)
	_target_angle = _angle
	set_process(true)


func _on_era_changed(_from: Era.Id, to: Era.Id) -> void:
	_era = to
	_target_angle = _angle_for(to)
	_flare = 1.0


## Each era sits on its own spoke. Turning the wheel brings it to the top.
func _angle_for(era: Era.Id) -> float:
	return -TAU / float(SPOKES) * float(int(era))


func _process(delta: float) -> void:
	var moved := false
	if absf(angle_difference(_angle, _target_angle)) > 0.002:
		_angle = lerp_angle(_angle, _target_angle, 1.0 - exp(-11.0 * delta))
		moved = true
	if _flare > 0.0:
		_flare = maxf(0.0, _flare - delta * 1.6)
		moved = true
	if moved:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var pressed := (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
	if pressed:
		tapped.emit()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 3.0
	var tint: Color = Era.TINT[_era]
	var copper := UIStyle.COPPER
	var flare := _flare * _flare

	# Face and rim.
	draw_circle(c, r, Color(0.07, 0.06, 0.06, 0.55))
	# Weathered copper, brighter the moment it turns.
	var rim := copper.lerp(UIStyle.SALT, 0.15 + 0.5 * flare)
	draw_arc(c, r, 0.0, TAU, 48, rim, 3.0, true)
	draw_arc(c, r * 0.80, 0.0, TAU, 40, Color(copper.r, copper.g, copper.b, 0.45), 1.5, true)

	# Eight spokes. Three of them are the mornings; the rest are the ones the
	# game never shows you.
	for i in SPOKES:
		var a := _angle + TAU / float(SPOKES) * float(i) - PI * 0.5
		var dir := Vector2(cos(a), sin(a))
		var is_stop := i < Era.ALL.size()
		var live := is_stop and i == int(_era)
		var col := copper
		if is_stop:
			col = Era.TINT[i as Era.Id]
			col.a = 1.0 if live else 0.5
		else:
			col = Color(copper.r, copper.g, copper.b, 0.32)
		draw_line(c + dir * (r * 0.18), c + dir * (r * 0.78), col, 2.0 if live else 1.5, true)
		if is_stop:
			var stop_r := 7.0 if live else 4.0
			draw_circle(c + dir * (r * 0.80), stop_r, col)
			if live:
				draw_circle(c + dir * (r * 0.80), stop_r + 3.0 + 4.0 * flare,
					Color(col.r, col.g, col.b, 0.25 + 0.4 * flare))

	# Hub, tinted to the live era so the dial reads at a glance.
	draw_circle(c, r * 0.17, Color(tint.r, tint.g, tint.b, 0.85))
	draw_arc(c, r * 0.17, 0.0, TAU, 20, rim, 1.5, true)
