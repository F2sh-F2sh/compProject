shader_type canvas_item;
render_mode unshaded;

// A drifting band of fog for the story pictures: two layers of noise sliding
// past each other, thickest in the middle of the band and fading at its top
// and bottom.

uniform sampler2D noise : repeat_enable, filter_linear;
uniform vec4 tint : source_color = vec4(0.55, 0.65, 0.8, 0.5);
uniform float speed = 0.012;
uniform float stretch = 1.0;
uniform float soft_top = 0.5;
uniform float soft_bottom = 0.4;
uniform float seed = 0.0;

void fragment() {
	float a = texture(noise, vec2(UV.x * stretch + TIME * speed + seed, UV.y * 0.55 + seed * 0.37)).r;
	float b = texture(noise, vec2(UV.x * stretch * 0.6 - TIME * speed * 0.7 + 0.5, UV.y * 0.8 + 0.21)).r;
	float n = smoothstep(0.2, 0.9, a * 0.62 + b * 0.62);
	float band = smoothstep(0.0, soft_top, UV.y) * smoothstep(1.0, 1.0 - soft_bottom, UV.y)
		* smoothstep(0.0, 0.12, UV.x) * smoothstep(1.0, 0.88, UV.x);
	COLOR = vec4(tint.rgb, tint.a * band * n);
}
