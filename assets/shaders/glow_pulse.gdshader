shader_type canvas_item;
render_mode blend_add, unshaded;

// A soft halo for magic and items: a radial glow (the texture's alpha) that
// breathes slowly and flickers a little, like a living flame or charm.
// Put it on a Sprite2D using assets/fx/soft_glow.png. Each instance can set
// its own phase so neighbouring glows don't pulse in step.

uniform vec4 glow_color : source_color = vec4(0.45, 0.65, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 2.0) = 0.5;
uniform float pulse_speed = 2.0;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.25;
uniform float flicker_amount : hint_range(0.0, 1.0) = 0.12;
uniform float phase = 0.0;

// Glows sharing one material still pulse out of step: their position in the
// world offsets the phase
varying float v_phase;

void vertex() {
	v_phase = phase + MODEL_MATRIX[3].x * 0.013 + MODEL_MATRIX[3].y * 0.007;
}

float hash(float n) {
	return fract(sin(n) * 43758.5453);
}

float flicker(float t) {
	float i = floor(t);
	float f = fract(t);
	return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

void fragment() {
	float a = texture(TEXTURE, UV).a;
	float pulse = 1.0 + pulse_amount * sin(TIME * pulse_speed + v_phase)
		+ flicker_amount * (flicker(TIME * 11.0 + v_phase * 7.0) - 0.5) * 2.0;
	COLOR = vec4(glow_color.rgb, clamp(a * intensity * max(pulse, 0.0), 0.0, 1.0));
}
