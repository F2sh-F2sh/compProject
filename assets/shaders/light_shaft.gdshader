shader_type canvas_item;
render_mode blend_add, unshaded;

// A soft, angled beam of light falling through a broken wall or ceiling.
// Drawn by LightShaft as a strip of quads with UV.x across the beam (0..1)
// and UV.y along it (0 at the opening, 1 at the floor). Slow drifting
// streaks and a faint breathing make it read as light through moving dust.

uniform vec4 shaft_color : source_color = vec4(0.6, 0.8, 0.92, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.22;
// Fraction of the half-width that fades softly at each edge.
uniform float softness : hint_range(0.05, 1.0) = 0.7;
uniform float streak_scale = 7.0;
uniform float drift_speed = 0.035;
uniform float breathe : hint_range(0.0, 0.5) = 0.12;
uniform float seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	float across = abs(UV.x * 2.0 - 1.0);
	float edge = 1.0 - smoothstep(1.0 - softness, 1.0, across);
	float along = UV.y;
	// Bright just under the opening, dissolving toward the floor
	float fade = smoothstep(0.0, 0.05, along) * (1.0 - 0.5 * along) * (1.0 - smoothstep(0.82, 1.0, along));
	// Long streaks that drift sideways, like dust currents in the beam
	float streaks = 0.55 + 0.45 * noise(vec2(UV.x * streak_scale + TIME * drift_speed + seed, along * 1.6 - TIME * 0.015));
	float pulse = 1.0 + breathe * sin(TIME * 0.6 + seed * 3.1);
	float a = intensity * edge * fade * streaks * pulse;
	COLOR = vec4(shaft_color.rgb, clamp(a, 0.0, 1.0));
}
