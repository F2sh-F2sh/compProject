shader_type canvas_item;

// The Hush spreading across a picture: inside a growing circle the colour
// drains to a cold grey, with a faint pale edge where the silence advances.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec2 origin = vec2(0.6, 0.45);   // screen UV
uniform float radius = 0.0;              // in screen heights
uniform float edge = 0.14;
uniform float aspect = 1.7778;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float d = length((SCREEN_UV - origin) * vec2(aspect, 1.0));
	float inside = 1.0 - smoothstep(radius - edge, radius, d);
	float grey = dot(c, vec3(0.299, 0.587, 0.114));
	vec3 hushed = mix(vec3(grey), vec3(0.46, 0.48, 0.55) * grey * 1.3, 0.4) * 0.8;
	float rim = (1.0 - smoothstep(0.0, edge * 0.6, abs(d - radius))) * step(0.001, radius);
	COLOR = vec4(mix(c, hushed, inside) + vec3(0.1, 0.11, 0.14) * rim * 0.4, 1.0);
}
