shader_type canvas_item;
render_mode blend_add, unshaded;

// A danger glint for spike art: it lights the outline of the tips (the top
// of the texture) with a slow pulse. Additive and unshaded, so it reads in
// the darkest room and stays bright through the lantern falloff. Drawn as an
// overlay copy of the spike sprite; the art itself is untouched.

uniform vec4 glint_color : source_color = vec4(1.0, 0.42, 0.3, 1.0);
uniform float intensity = 0.85;
// Fraction of the texture height (from the top) that counts as the tips.
uniform float tip_reach = 0.6;
uniform float pulse_speed = 2.2;
uniform float pulse_amount = 0.18;

varying float v_phase;

void vertex() {
	// Neighbouring strips pulse slightly out of step
	v_phase = MODEL_MATRIX[3].x * 0.011;
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	float a = texture(TEXTURE, UV).a;
	float inner = texture(TEXTURE, UV + vec2(px.x, 0.0)).a
		* texture(TEXTURE, UV - vec2(px.x, 0.0)).a
		* texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float edge = a * (1.0 - inner);
	float tips = 1.0 - smoothstep(0.0, tip_reach, UV.y);
	float g = (edge + a * tips * tips * 0.5) * tips;
	float pulse = 1.0 - pulse_amount + pulse_amount * sin(TIME * pulse_speed + v_phase);
	g *= intensity * pulse;
	COLOR = vec4(glint_color.rgb * g, g);
}
