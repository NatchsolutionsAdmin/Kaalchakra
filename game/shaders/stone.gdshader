// Harappan masonry without a single texture.
//
// Everything here is arithmetic on world position, which means: no UV
// unwrapping, no texture memory, no download size, and it works on greybox
// boxes and on finished models alike. On a phone that matters — texture
// bandwidth is usually the first thing to run out.
//
// It draws brick courses on the real 1:2:4 module from ART-BIBLE.md §8, fades
// them out with distance so they never shimmer, bleaches upward-facing
// surfaces the way sun does, darkens undersides, and can stain a waterline at
// any height — which is how 2026 shows where the reservoir used to reach.
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

uniform vec3 base_color : source_color = vec3(0.72, 0.45, 0.30);
uniform vec3 sun_bleach : source_color = vec3(0.86, 0.73, 0.55);
uniform vec3 ground_shade : source_color = vec3(0.34, 0.22, 0.16);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.95;

// Brick courses. 0.2 m is two brick heights — one course reads better at
// playing distance than the true 0.1 m, which turns to mush.
uniform float course_height = 0.2;
uniform float course_length = 0.4;
uniform float mortar_depth : hint_range(0.0, 1.0) = 0.22;
uniform float mortar_fade_start = 12.0;
uniform float mortar_fade_end = 32.0;

uniform float patch_scale = 0.11;
uniform float patch_strength : hint_range(0.0, 1.0) = 0.16;

// Waterline stain. Off by default; the reservoir and 2087 switch it on.
uniform bool waterline_enabled = false;
uniform float waterline_height = 0.0;
uniform float waterline_width = 0.35;
uniform vec3 waterline_color : source_color = vec3(0.30, 0.34, 0.30);

varying vec3 world_pos;
varying vec3 world_normal;

float hash13(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash13(i);
	float n100 = hash13(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash13(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash13(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash13(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash13(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash13(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash13(i + vec3(1.0, 1.0, 1.0));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
	           mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(world_normal);
	vec3 col = base_color;

	// Large patchy variation, so no two walls are the same flat colour.
	float patch = vnoise(world_pos * patch_scale);
	col = mix(col, col * (0.78 + 0.44 * patch), patch_strength * 2.0);

	// Sun bleaches what faces up; undersides go into shade. One line each,
	// and together they do more than any texture would.
	float up = clamp(n.y, 0.0, 1.0);
	float down = clamp(-n.y, 0.0, 1.0);
	col = mix(col, sun_bleach, up * 0.18);
	col = mix(col, ground_shade, down * 0.35);

	// Brick courses, only on near-vertical faces. Alternate rows shift by half
	// a brick, which is what makes it read as bonded masonry rather than tile.
	float verticality = 1.0 - up - down;
	float row = world_pos.y / course_height;
	float course = fract(row);
	// Pick the horizontal axis the face RUNS ALONG, which is the one its
	// normal does not point down. Having these the wrong way round made every
	// wall look like timber siding instead of bonded brick.
	float along = mix(world_pos.x, world_pos.z, step(abs(n.z), abs(n.x)));
	float stagger = mod(floor(row), 2.0) * 0.5;
	float joint = fract(along / course_length + stagger);

	// Softer than before: hard thin lines read as corduroy at this scale.
	float line_h = smoothstep(0.0, 0.10, course) * smoothstep(0.0, 0.10, 1.0 - course);
	float line_v = smoothstep(0.0, 0.07, joint) * smoothstep(0.0, 0.07, 1.0 - joint);
	float mortar = (1.0 - line_h * line_v) * verticality;

	// Fade the courses out with distance. Thin lines at range alias badly and
	// that reads as the "pixelation" we already fixed once.
	float dist = length(VERTEX);
	mortar *= 1.0 - smoothstep(mortar_fade_start, mortar_fade_end, dist);
	col *= 1.0 - mortar * mortar_depth;

	// Where water used to stand, or still does.
	if (waterline_enabled) {
		float d = abs(world_pos.y - waterline_height);
		float stain = 1.0 - smoothstep(0.0, waterline_width, d);
		stain *= 0.55 + 0.45 * vnoise(world_pos * 1.7);
		col = mix(col, waterline_color, stain * 0.5 * verticality);
		// Everything below the old line is darker — it stayed wet longer.
		col *= 1.0 - clamp((waterline_height - world_pos.y) * 0.06, 0.0, 0.16);
	}

	// Ground and other up-facing surfaces get no courses, so without this they
	// are a single flat colour over enormous areas. Fine grain at close range,
	// faded out before it can shimmer.
	float grain = vnoise(world_pos * 2.3);
	float grain_fade = 1.0 - smoothstep(8.0, 26.0, dist);
	col *= 1.0 - up * grain_fade * (0.10 * (1.0 - grain));
	col = mix(col, col * (0.92 + 0.16 * vnoise(world_pos * 0.45)), up * 0.5);

	ALBEDO = col;
	ROUGHNESS = roughness_value;
	SPECULAR = 0.08;
}
