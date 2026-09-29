shader_type canvas_item;
render_mode unshaded;

// The electric wisps from Echidna's hold-jump sheet, as their own layer. They
// glow on their own (unaffected by the dungeon's darkness) and crackle:
// brightness follows the charge, with a fast irregular flicker per stroke.

uniform float charge : hint_range(0.0, 1.0) = 1.0;
uniform float flicker_speed = 23.0;
uniform vec4 hot_color : source_color = vec4(0.82, 0.93, 1.0, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	// Neighbouring strokes flicker out of step with each other
	vec2 cell = floor(UV / TEXTURE_PIXEL_SIZE / 6.0);
	float t = floor(TIME * flicker_speed + hash(cell) * 7.0);
	float flicker = mix(0.55, 1.0, step(0.28, hash(cell + t)));
	float strength = clamp(charge, 0.0, 1.0);
	// Near full charge the strokes run hot toward white
	c.rgb = mix(c.rgb, hot_color.rgb, 0.35 * strength * strength);
	c.a *= strength * flicker;
	COLOR = c;
}
