shader_type canvas_item;

// Recolours a level's stone by its brightness into the level's own palette
// (LevelTheme): dark, middle and light tones, mixed over the original by
// `amount`. The tiles keep their detail (it is their brightness that picks
// the tone) and their lighting (lights still fall on the result).

uniform vec4 dark : source_color = vec4(0.07, 0.06, 0.1, 1.0);
uniform vec4 mid : source_color = vec4(0.25, 0.22, 0.35, 1.0);
uniform vec4 light : source_color = vec4(0.6, 0.55, 0.75, 1.0);
uniform float amount = 0.85;
uniform float stretch = 1.6;

void fragment() {
	vec4 c = COLOR;
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float t = clamp(l * stretch, 0.0, 1.0);
	vec3 g = t < 0.5 ? mix(dark.rgb, mid.rgb, t * 2.0) : mix(mid.rgb, light.rgb, (t - 0.5) * 2.0);
	COLOR = vec4(mix(c.rgb, g, amount), c.a);
}
