shader_type canvas_item;
render_mode unshaded;

// A shallow puddle seen from the side: a thin sheet of water over the top of
// the floor. It mirrors the (already lit) scene above its surface, wobbles
// gently, and carries rings that spread from wherever something stepped.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform vec2 rect_size = vec2(96.0, 7.0);      // local px
uniform vec2 px_uv = vec2(0.0017, 0.003);      // one local px in screen UV
uniform vec4 water_color : source_color = vec4(0.1, 0.14, 0.23, 0.92);
uniform vec4 sheen_color : source_color = vec4(0.62, 0.72, 0.9, 1.0);
uniform float reflect_strength : hint_range(0.0, 1.0) = 0.85;
uniform bool reflections = true;
uniform float time = 0.0;
// x: centre (local px from the left end), y: age (s), z: strength
uniform vec4 ripples[8];
uniform int ripple_count = 0;

const float SPEED = 55.0;     // px a ring travels per second
const float WAVELENGTH = 7.0;

void fragment() {
	vec2 p = UV * rect_size;
	float depth = p.y;
	float disp = 0.0;
	float crest = 0.0;
	for (int i = 0; i < ripple_count; i++) {
		vec4 r = ripples[i];
		float front = r.y * SPEED;
		float d = abs(p.x - r.x);
		// The ring's leading edge, with a few trailing waves behind it, fading with age
		float behind = front - d;
		float body = step(-3.0, behind) * exp(-max(behind, 0.0) / 18.0);
		float fade = r.z * exp(-r.y * 1.8);
		float wave = sin(behind * 6.2832 / WAVELENGTH) * body * fade;
		disp += wave * 2.2;
		crest += max(wave, 0.0) * fade;
	}
	// A slow shimmer even when nothing disturbs it
	disp += sin(p.x * 0.31 + time * 1.7) * 0.35 + sin(p.x * 0.11 - time * 1.1) * 0.3;

	float fall = depth / rect_size.y;
	vec3 col = water_color.rgb;
	if (reflections) {
		// A point `depth` px below the surface mirrors the point `depth` px above it
		vec2 uv = vec2(SCREEN_UV.x + disp * px_uv.x * 0.6, SCREEN_UV.y - (2.0 * depth + 1.0 + disp) * px_uv.y);
		vec3 mirrored = texture(screen_tex, uv).rgb;
		float k = reflect_strength * (1.0 - 0.35 * fall);
		// A cool, slightly lifted mirror image, so the water reads against dark stone
		col = mix(col, mirrored * vec3(0.95, 1.05, 1.2) + vec3(0.03, 0.05, 0.09), k);
	}
	// The lip of the surface, drifting glints and the crests of the rings catch the light
	float lip = smoothstep(2.2, 0.0, depth);
	float glint = pow(max(sin(p.x * 0.9 + time * 2.3) * sin(p.x * 0.37 - time * 1.1), 0.0), 8.0) * (1.0 - fall);
	col += sheen_color.rgb * (lip * 0.55 + glint * 0.5 + clamp(crest, 0.0, 1.0) * 0.8 * (1.0 - fall));
	// Soft, slightly ragged ends so it reads as water lying in a dip
	float edge = 9.0 + 3.0 * sin(p.y * 1.7 + p.x * 0.05);
	float ends = smoothstep(0.0, edge, p.x) * smoothstep(0.0, edge, rect_size.x - p.x);
	COLOR = vec4(col, water_color.a * ends);
}
