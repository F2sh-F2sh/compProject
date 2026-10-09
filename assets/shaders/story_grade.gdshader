shader_type canvas_item;

// The story pictures' colour grade: the colours eased back, the shadows
// pulled toward a deep cold blue and the lights toward one accent, and the
// edges of the frame sinking into the dark (a vignette).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec4 shadow : source_color = vec4(0.02, 0.03, 0.07, 1.0);
uniform vec4 light : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float saturation = 0.85;
uniform float contrast = 1.08;
uniform float vignette = 0.6;
uniform float aspect = 1.7778;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c = clamp((c - 0.5) * contrast + 0.5, 0.0, 1.0);
	c = mix(shadow.rgb + c * (vec3(1.0) - shadow.rgb), c * light.rgb, smoothstep(0.0, 0.75, l));
	vec2 d = (SCREEN_UV - 0.5) * vec2(aspect, 1.0);
	float v = smoothstep(0.42, 1.1, length(d));
	c *= 1.0 - v * vignette;
	COLOR = vec4(c, 1.0);
}
