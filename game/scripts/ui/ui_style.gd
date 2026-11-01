## UIStyle — one place for what the interface is made of.
##
## Colours come straight from ART-BIBLE.md §3, so the UI and the world share a
## palette rather than drifting apart. Nothing here draws; it hands out colours
## and styleboxes so every panel and button in the game matches without each
## one re-inventing it.
class_name UIStyle
extends RefCounted

# ART-BIBLE.md §3
const TERRACOTTA := Color("b5633c")
const OCHRE := Color("c98a3c")
const DUST := Color("d8cbb0")
const SALT := Color("ede7da")
const TEAL := Color("2e7a74")
const DEEP_TEAL := Color("17403f")
const COPPER := Color("a8703f")
const INDIGO := Color("1b2433")

# Roles
const INK := Color("ede7da")                     # body text
const INK_DIM := Color(0.85, 0.82, 0.74, 0.62)   # secondary text
const PANEL := Color(0.08, 0.07, 0.07, 0.88)
const PANEL_EDGE := Color(0.66, 0.44, 0.25, 0.55)
const HIGHLIGHT := Color("e3a85a")
const PRESSED_INK := Color("1b1410")

const RADIUS := 5
const TOUCH_MIN := 96.0   # well over the 44 pt minimum (CLAUDE.md §9)


static func panel(fill: Color = PANEL, edge: Color = PANEL_EDGE,
		radius: int = RADIUS, pad: int = 20) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 8
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = int(pad * 0.75)
	sb.content_margin_bottom = int(pad * 0.85)
	return sb


## A round button face — the thumb controls are all discs.
static func disc(diameter: float, fill: Color, edge: Color, width: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(int(diameter * 0.5))
	sb.corner_detail = 12
	return sb


## Text with a shadow, because it is read over a bright desert.
static func label(text: String, size: int, colour: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func style_round_button(b: Button, diameter: float, tint: Color) -> void:
	b.custom_minimum_size = Vector2(diameter, diameter)
	b.size = Vector2(diameter, diameter)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", tint)
	b.add_theme_color_override("font_hover_color", SALT)
	b.add_theme_color_override("font_pressed_color", PRESSED_INK)
	b.add_theme_color_override("font_disabled_color", Color(tint.r, tint.g, tint.b, 0.35))
	for state: String in ["normal", "focus"]:
		b.add_theme_stylebox_override(state,
			disc(diameter, Color(0.07, 0.06, 0.06, 0.52), Color(tint.r, tint.g, tint.b, 0.8)))
	b.add_theme_stylebox_override("hover",
		disc(diameter, Color(0.12, 0.10, 0.09, 0.70), tint))
	b.add_theme_stylebox_override("pressed", disc(diameter, tint, SALT))
	b.add_theme_stylebox_override("disabled",
		disc(diameter, Color(0.06, 0.05, 0.05, 0.30), Color(tint.r, tint.g, tint.b, 0.25), 1))
