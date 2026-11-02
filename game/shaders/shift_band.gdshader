// The era shift — "The World Remembers" (ART-DIRECTION.md §8).
//
// The review's instruction was to stop flashing the screen white. A flash says
// "something happened to the picture". What should be said is "something
// happened to the PLACE, and you are still standing in it" — so the camera and
// Eva hold still and a controlled band of light crosses a fixed image while
// the world changes underneath it.
//
// The band sweeps outward from wherever the Wheel is on screen, because that
// is the thing the player just touched. Deliberately NOT a particle burst or a
// portal: this is a mechanism engaging, not magic.
//
// No screen-texture sampling and no second pass — on a tile-based mobile GPU
// the cheap version is also the one that cannot break.
shader_type canvas_item;

// 0 at the Wheel, 1 when the band has left the far corner.
uniform float progress : hint_range(0.0, 1.4) = 0.0;
// Where on screen the Wheel sits, in UV.
uniform vec2 origin = vec2(0.88, 0.14);
uniform float aspect = 1.777;
uniform vec4 band_colour : source_color = vec4(0.85, 0.62, 0.36, 1.0);
// Master fade, so the whole effect can be eased in and out.
uniform float strength : hint_range(0.0, 1.0) = 0.0;
// Width of the bright edge. Narrow reads as machined; wide reads as mist.
uniform float width : hint_range(0.01, 0.3) = 0.055;

void fragment() {
	vec2 d = (UV - origin) * vec2(aspect, 1.0);
	// Normalised so progress 1.0 clears the far corner of a 16:9 screen.
	float dist = length(d) / 2.05;

	// The leading edge: a thin bright arc.
	float edge = 1.0 - smoothstep(0.0, width, abs(dist - progress));
	// A short warm trail behind it, so the band has direction.
	float trail = (1.0 - smoothstep(progress - width * 4.0, progress, dist))
		* smoothstep(progress - width * 7.0, progress - width * 4.0, dist);

	float a = edge * 0.9 + trail * 0.28;
	COLOR = vec4(band_colour.rgb, clamp(a, 0.0, 1.0) * strength);
}
