## KaalchakraMark — the identity, as geometry.
##
##     EIGHT POSITIONS. THREE ACCESSIBLE. FIVE ABSENT. ONE FORBIDDEN MOVEMENT.
##
## That sentence (ART-DIRECTION.md §7) is the whole brand, and this file is the
## only place it is drawn. The app icon, the title screen and the HUD dial all
## call `draw_mark()`, so they are the same object at three sizes and cannot
## drift apart the way a logo file and a UI sprite always eventually do.
##
## What the drawing says, literally:
##   - eight spoke positions, evenly spaced, always all eight present
##   - THREE of them reach the rim and carry a machined detent — the three
##     mornings the Wheel will stop at
##   - FIVE stop short of the rim. They are visible and they do not connect.
##     That is the absence the game is about, drawn rather than explained
##   - the FOURTH position is where the finale goes. It has a detent seat and
##     no detent, so the shape of what is missing is specific
##
## Drawn with _draw() rather than an image: pure geometry, crisp at any
## density, animates without a sprite sheet, costs no texture memory and
## nothing to download. On a phone that matters three times over.
class_name KaalchakraMark
extends RefCounted

const POSITIONS := 8
const STEP := TAU / float(POSITIONS)
## Index of the stop the finale turns to — the one that must resist, creak,
## and then engage (ART-DIRECTION.md §8).
const FORBIDDEN := 3


## Everything optional about one drawing of the mark.
class State:
	## Rotation of the whole wheel, radians. The review is explicit that the
	## Wheel never free-spins; this moves between detents and then stops.
	var rotation := 0.0
	## Which stop is live (0/1/2), or -1 for none — the icon and the title use
	## -1 so the mark is not pretending to be mid-game.
	var live := -1
	## 0..1, decays after a shift. A brief brightening of the rim, no more.
	var flare := 0.0
	## The finale. Gives the fourth position its detent at last.
	var fourth_engaged := false
	## Copper only, no era tints — for the app icon and anywhere the mark is
	## identity rather than instrument.
	var mono := false
	## Scales line weights. 1.0 suits roughly a 120px mark.
	var weight := 1.0
	## Drawn as a physical object in front of a scene rather than as a panel:
	## no filled face, so the picture still shows through it.
	var silhouette := false


## Draw the mark centred on `centre` with outer radius `r`.
## `ci` is any CanvasItem mid-`_draw()`.
static func draw_mark(ci: CanvasItem, centre: Vector2, r: float,
		state: State = null) -> void:
	var s := state if state != null else State.new()
	var copper := UIStyle.COPPER
	var flare: float = s.flare * s.flare
	var w: float = s.weight

	# A weathered copper reads as two tones, not one: the lit edge and the
	# oxidised body. Two arcs do what a texture would.
	var lit := copper.lerp(UIStyle.TEXT, 0.18 + 0.45 * flare)
	var body := copper.darkened(0.35)

	# Face. Near-opaque indigo, the same surface as every panel in the game —
	# except as a foreground silhouette, where a disc that size would simply
	# be a hole in the picture.
	# A silhouette still needs some body or it reads as stray arcs rather
	# than as an object standing in front of the scene.
	ci.draw_circle(centre, r, Color(UIStyle.SURFACE.r, UIStyle.SURFACE.g,
		UIStyle.SURFACE.b, 0.30 if s.silhouette else 0.78))

	# Rim: outer bright edge, inner shadowed course.
	ci.draw_arc(centre, r, 0.0, TAU, 64, lit, 2.6 * w, true)
	ci.draw_arc(centre, r - 2.6 * w, 0.0, TAU, 64, body, 1.6 * w, true)
	# Inner ring the spokes spring from.
	ci.draw_arc(centre, r * 0.78, 0.0, TAU, 56,
		Color(copper.r, copper.g, copper.b, 0.42), 1.4 * w, true)

	for i in POSITIONS:
		_draw_position(ci, centre, r, i, s, w, flare, copper, lit)

	# Hub. Tinted to the live era so the instrument reads at a glance; plain
	# copper when the mark is being identity rather than instrument.
	var hub_col := copper.lerp(UIStyle.TEXT, 0.10)
	if not s.mono and s.live >= 0:
		var t: Color = Era.TINT[s.live as Era.Id]
		hub_col = Color(t.r, t.g, t.b, 0.92)
	ci.draw_circle(centre, r * 0.155, hub_col)
	ci.draw_arc(centre, r * 0.155, 0.0, TAU, 24, lit, 1.4 * w, true)
	ci.draw_circle(centre, r * 0.055, Color(UIStyle.SURFACE.r, UIStyle.SURFACE.g,
		UIStyle.SURFACE.b, 0.9))


static func _draw_position(ci: CanvasItem, centre: Vector2, r: float, i: int,
		s: State, w: float, flare: float, copper: Color, lit: Color) -> void:
	var a: float = s.rotation + STEP * float(i) - PI * 0.5
	var dir := Vector2(cos(a), sin(a))
	var accessible: int = Era.ALL.size()          # 3
	var is_stop := i < accessible
	var is_forbidden := i == FORBIDDEN
	var live := is_stop and i == s.live

	# --- the five that stop short -------------------------------------
	if not is_stop:
		# Three quarters of the way out and no further. The gap between the
		# spoke end and the rim IS the point; it is never closed, except by
		# the finale at the fourth position.
		var faint := Color(copper.r, copper.g, copper.b, 0.30)
		ci.draw_line(centre + dir * (r * 0.20), centre + dir * (r * 0.52),
			faint, 1.3 * w, true)
		if is_forbidden:
			# The seat is machined and empty: two small marks on the rim
			# where a detent would sit, and nothing between them.
			var seat := Color(copper.r, copper.g, copper.b, 0.55)
			if s.fourth_engaged:
				_draw_detent(ci, centre + dir * (r * 0.78), 6.0 * w,
					UIStyle.OCHRE, lit, w)
				ci.draw_line(centre + dir * (r * 0.20),
					centre + dir * (r * 0.74), UIStyle.OCHRE, 2.2 * w, true)
			else:
				var n := Vector2(-dir.y, dir.x)
				for side: float in [-1.0, 1.0]:
					var at := centre + dir * (r * 0.84) + n * (5.0 * w * side)
					ci.draw_line(at - dir * (3.0 * w), at + dir * (3.0 * w),
						seat, 1.2 * w, true)
		return

	# --- the three that reach -----------------------------------------
	var col := copper
	if not s.mono:
		col = Era.TINT[i as Era.Id]
	col.a = 1.0 if live else 0.62
	ci.draw_line(centre + dir * (r * 0.16), centre + dir * (r * 0.74),
		col, (2.4 if live else 1.7) * w, true)
	_draw_detent(ci, centre + dir * (r * 0.78), (7.0 if live else 5.0) * w,
		col, lit, w)
	if live and flare > 0.001:
		ci.draw_circle(centre + dir * (r * 0.78), (10.0 + 5.0 * flare) * w,
			Color(col.r, col.g, col.b, 0.30 * flare))


## One machined stop on the rim: a filled seat with a bright lip.
static func _draw_detent(ci: CanvasItem, at: Vector2, radius: float,
		fill: Color, lip: Color, w: float) -> void:
	ci.draw_circle(at, radius, fill)
	ci.draw_arc(at, radius, 0.0, TAU, 16, lip, 1.2 * w, true)
