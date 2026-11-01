// One water shader, three settings: a managed reservoir in 1900 BCE, nothing
// in 2026, and a dead lid over everything in 2087 (ART-BIBLE.md §9).
//
// No textures and no screen-space refraction — both are expensive on mobile.
// Movement comes from two scrolling noise fields, depth comes from a fresnel
// term, and that is enough for water seen from a 3rd-person camera.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, diffuse_lambert;

uniform vec3 shallow_color : source_color = vec3(0.30, 0.62, 0.60);
uniform vec3 deep_color : source_color = vec3(0.06, 0.20, 0.24);
uniform float opacity : hint_range(0.0, 1.0) = 0.72;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.06;
// 0 = mirror-still (the past), 1 = restless. The drowned future sits near 0.15:
// dead water, not calm water.
uniform float motion : hint_range(0.0, 2.0) = 0.35;
uniform float wave_scale = 1.6;
uniform float wave_height = 0.02;
uniform float sparkle : hint_range(0.0, 1.0) = 0.35;

varying vec3 world_pos;

float hash13(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash13(i), hash13(i + vec3(1, 0, 0)), f.x),
	               mix(hash13(i + vec3(0, 1, 0)), hash13(i + vec3(1, 1, 0)), f.x), f.y),
	           mix(mix(hash13(i + vec3(0, 0, 1)), hash13(i + vec3(1, 0, 1)), f.x),
	               mix(hash13(i + vec3(0, 1, 1)), hash13(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * 0.25 * motion;
	float h = vnoise(vec3(world_pos.x * wave_scale, t, world_pos.z * wave_scale));
	VERTEX.y += (h - 0.5) * wave_height * motion;
}

void fragment() {
	float t = TIME * 0.18 * motion;
	float a = vnoise(vec3(world_pos.x * wave_scale, t, world_pos.z * wave_scale));
	float b = vnoise(vec3(world_pos.z * wave_scale * 1.7 - t, 3.3, world_pos.x * wave_scale * 1.7));
	float ripple = (a + b) * 0.5;

	// Steeper viewing angle sees deeper water.
	float fres = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.2);
	vec3 col = mix(deep_color, shallow_color, fres * 0.75 + ripple * 0.25);

	// A little specular break-up, so still water is not a flat plate.
	float glint = smoothstep(0.72, 0.95, ripple) * sparkle;
	col += glint * 0.25;

	ALBEDO = col;
	ALPHA = clamp(opacity + fres * 0.18, 0.0, 1.0);
	ROUGHNESS = roughness_value + ripple * 0.06 * motion;
	METALLIC = 0.12;
	SPECULAR = 0.5;
	NORMAL_MAP = vec3(0.5 + (a - 0.5) * motion, 0.5 + (b - 0.5) * motion, 1.0);
	NORMAL_MAP_DEPTH = 0.6 * motion;
}
