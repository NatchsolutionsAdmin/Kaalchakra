// What the screen does while Eva is on the phone.
//
// She is standing in a trench with a phone against her ear, so the world goes
// quiet rather than away: desaturated, dimmed at the edges, with a slow drift
// of line noise over it. The thing her mother is describing is usually still
// on screen, so it must stay readable — this is attention moving, not a menu
// opening.
//
// One full-screen pass, and only while a call is up.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 1.0;
uniform float desaturate : hint_range(0.0, 1.0) = 0.55;
uniform float dim : hint_range(0.0, 1.0) = 0.28;
uniform float vignette_start : hint_range(0.0, 1.5) = 0.42;
uniform float vignette_end : hint_range(0.0, 1.5) = 1.05;
uniform vec3 tint : source_color = vec3(0.16, 0.42, 0.42);
uniform float noise_strength : hint_range(0.0, 0.3) = 0.055;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec3 col = texture(screen_tex, SCREEN_UV).rgb;

	float grey = dot(col, vec3(0.299, 0.587, 0.114));
	vec3 treated = mix(col, vec3(grey), desaturate);
	treated = mix(treated, treated * tint * 2.2, 0.18);
	treated *= 1.0 - dim;

	// Edges fall away, so the eye lands on the panel in the middle.
	float d = distance(SCREEN_UV, vec2(0.5)) * 1.42;
	float v = 1.0 - smoothstep(vignette_start, vignette_end, d);
	treated *= mix(0.45, 1.0, v);

	// A bad line, drifting. Horizontal because that is what interference on
	// a phone screen looks like.
	float band = hash12(vec2(floor(SCREEN_UV.y * 220.0), floor(TIME * 9.0)));
	treated += (band - 0.5) * noise_strength;

	COLOR = vec4(mix(col, treated, amount), 1.0);
}
