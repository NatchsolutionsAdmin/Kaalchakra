## UIStyle — the design tokens, in one place.
##
## Every number here comes from `docs/ART-DIRECTION.md`, which is the art
## review's spec written down. Nothing in this file is taste: if a colour or a
## size looks wrong, the argument belongs in that document, not in a screen.
##
## Three groups:
##   ROLES    what a colour is *for* (copper = active focus), not what it is
##   TYPE     a fixed ten-step scale; screens pick a role, never a pixel size
##   SPACE    a 4/8/16/24/32/48 rhythm, so nothing is spaced "about right"
##
## Sizes are quoted at a 1280x720 design resolution and scale from there —
## `scale_for()` does that, so a 21px dialogue line is 21px on a laptop and
## correspondingly larger on a tall phone.
class_name UIStyle
extends RefCounted

# --- colour roles (ART-DIRECTION.md §4) ----------------------------------
#
# The hexes are fixed. The *role* names are what screens should use, because
# a role survives a palette change and a colour name does not.

const SURFACE := Color("1b2433")      # primary surface: dialogue, archive
const TEXT := Color("ede7da")         # primary text
const TEXT_DIM := Color("d8cbb0")     # labels — use at 75-85% alpha
const COPPER := Color("a8703f")       # the Wheel; active focus
const OCHRE := Color("c98a3c")        # discovery emphasis
const TEAL := Color("2e7a74")         # WATER AND SURVIVAL ONLY
const DANGER := Color("b5633c")       # destructive actions

## Surface fill at the specified 90-95% opacity.
const SURFACE_90 := Color(0.106, 0.141, 0.200, 0.92)
## Thin border: secondary text at 22-30%.
const BORDER := Color(0.847, 0.796, 0.690, 0.26)
## Secondary text at 75-85%.
const TEXT_DIM_A := Color(0.847, 0.796, 0.690, 0.80)
## Unavailable state: secondary text at 35-45%.
const DISABLED := Color(0.847, 0.796, 0.690, 0.40)

# Existing names kept so screens written before the review still compile.
# They now resolve to the reviewed roles rather than their own near-misses.
const TERRACOTTA := DANGER
const DUST := TEXT_DIM
const SALT := TEXT
const DEEP_TEAL := Color("17403f")
const INDIGO := SURFACE
const INK := TEXT
const INK_DIM := TEXT_DIM_A
const PANEL := SURFACE_90
const PANEL_EDGE := BORDER
const HIGHLIGHT := OCHRE
const PRESSED_INK := SURFACE

# --- type scale (ART-DIRECTION.md §5) ------------------------------------
#
# Two faces: Marcellus for the three display roles, Manrope for everything
# read as text. Both are SIL OFL. Until the files are in `assets/fonts/` the
# engine default stands in — the sizes, weights and spacing below are already
# correct, so dropping the fonts in changes the face and nothing else.

enum Type {
	TITLE,      # Marcellus 64 / +3 letterspace
	CHAPTER,    # Marcellus 36 / +1
	PANEL_TITLE,# Marcellus 27
	DIALOGUE,   # Manrope 21 / 1.40 leading
	MENU,       # Manrope 20 / 600
	BUTTON,     # Manrope 18 / 600
	BODY,       # Manrope 18 / 1.45 leading
	EVIDENCE,   # Manrope 17
	LABEL,      # Manrope 15 / 700 / +1
	METADATA,   # Manrope 14 / 500
}

const TYPE_SIZE: Dictionary = {
	Type.TITLE: 64, Type.CHAPTER: 36, Type.PANEL_TITLE: 27,
	Type.DIALOGUE: 21, Type.MENU: 20, Type.BUTTON: 18, Type.BODY: 18,
	Type.EVIDENCE: 17, Type.LABEL: 15, Type.METADATA: 14,
}

## Extra tracking, in pixels at design scale.
const TYPE_TRACK: Dictionary = {
	Type.TITLE: 3, Type.CHAPTER: 1, Type.LABEL: 1,
}

## Line height multiplier, where the review specifies one.
const TYPE_LEADING: Dictionary = {
	Type.DIALOGUE: 1.40, Type.BODY: 1.45,
}

const DISPLAY_ROLES: Array[Type] = [Type.TITLE, Type.CHAPTER, Type.PANEL_TITLE]

# --- space and shape (ART-DIRECTION.md §5) --------------------------------

const S1 := 4
const S2 := 8
const S3 := 16
const S4 := 24
const S5 := 32
const S6 := 48

## HUD edge inset, before the device's own safe area is added.
const EDGE := 32.0
const RADIUS_PANEL := 6
const RADIUS_DOCUMENT := 4
const RADIUS_CONTROL := 8
## Ideal tap target. Platform minimums (44pt iOS, 48dp Android) still apply,
## and `scale_for()` only ever grows this.
const TAP := 56.0
## Longest a column of text may get before it stops being readable.
const COLUMN := 560.0

# Kept for screens written before the review.
const RADIUS := RADIUS_PANEL
const TOUCH_MIN := 96.0

const DESIGN_SIZE := Vector2(1280.0, 720.0)


## How much to multiply design pixels by on this screen. Driven by height, so
## a wide phone does not inflate the text; clamped so a tablet does not end up
## with a HUD built for a billboard.
static func scale_for(viewport: Vector2) -> float:
	if viewport.y <= 0.0:
		return 1.0
	return clampf(viewport.y / DESIGN_SIZE.y, 0.85, 1.6)


static func size_of(role: Type, scale: float = 1.0) -> int:
	return int(round(float(TYPE_SIZE[role]) * scale))


# --- builders -------------------------------------------------------------

static func panel(fill: Color = SURFACE_90, edge: Color = BORDER,
		radius: int = RADIUS_PANEL, pad: int = S4) -> StyleBoxFlat:
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


## A document surface: squarer corners, a copper rule along the top edge.
## This is the dialogue and archive grammar from the review — a page, not a
## generic rounded card.
static func document(pad: int = S4) -> StyleBoxFlat:
	var sb := panel(SURFACE_90, BORDER, RADIUS_DOCUMENT, pad)
	sb.border_width_top = 2
	sb.border_color = Color(COPPER.r, COPPER.g, COPPER.b, 0.85)
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


## Text in one of the ten roles. Everything the role specifies — size,
## tracking, leading, weight-by-proxy — is applied here so no screen has to
## remember it.
static func text(content: String, role: Type, colour: Color = TEXT,
		scale: float = 1.0) -> Label:
	var l := Label.new()
	l.text = content
	l.add_theme_font_size_override("font_size", size_of(role, scale))
	l.add_theme_color_override("font_color", colour)
	# Tracking is not a Label property in Godot; `tracked()` does it by
	# spacing the glyphs, and the display roles are short enough for that.
	if TYPE_TRACK.has(role):
		l.text = tracked(content, int(TYPE_TRACK[role]))
	if TYPE_LEADING.has(role):
		var extra: float = (float(TYPE_LEADING[role]) - 1.0) * float(size_of(role, scale))
		l.add_theme_constant_override("line_spacing", int(round(extra)))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Letterspacing, done the only way Godot allows: by spacing the characters.
## Used for the title and for all-caps labels, where the review asks for +1 to
## +3px of tracking.
static func tracked(content: String, pixels: int = 1) -> String:
	if pixels <= 0:
		return content
	var gap := " ".repeat(maxi(1, int(round(pixels / 2.0))))
	return gap.join(content.split(""))


## Text with a shadow, because it is read over a bright desert.
## Pre-review call shape, kept so existing screens compile.
static func label(content: String, size: int, colour: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = content
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", colour)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func style_round_button(b: Button, diameter: float, tint: Color) -> void:
	b.custom_minimum_size = Vector2(diameter, diameter)
	b.size = Vector2(diameter, diameter)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", TYPE_SIZE[Type.LABEL])
	b.add_theme_color_override("font_color", tint)
	b.add_theme_color_override("font_hover_color", TEXT)
	b.add_theme_color_override("font_pressed_color", SURFACE)
	b.add_theme_color_override("font_disabled_color", Color(tint.r, tint.g, tint.b, 0.35))
	for state: String in ["normal", "focus"]:
		b.add_theme_stylebox_override(state,
			disc(diameter, Color(0.07, 0.09, 0.13, 0.52), Color(tint.r, tint.g, tint.b, 0.8)))
	b.add_theme_stylebox_override("hover",
		disc(diameter, Color(0.11, 0.14, 0.20, 0.70), tint))
	b.add_theme_stylebox_override("pressed", disc(diameter, tint, TEXT))
	b.add_theme_stylebox_override("disabled",
		disc(diameter, Color(0.06, 0.08, 0.11, 0.30), Color(tint.r, tint.g, tint.b, 0.25), 1))
