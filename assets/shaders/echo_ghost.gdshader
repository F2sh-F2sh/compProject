shader_type canvas_item;

// Purple spectral look for Echoes: tinted, translucent, flickering, with a
// glowing outline, scanlines, and a bottom-up reveal while materialising.

uniform vec4 tint : source_color = vec4(0.66, 0.42, 1.0, 1.0);
uniform vec4 rim_color : source_color = vec4(0.85, 0.7, 1.0, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.62;
uniform float materialize : hint_range(0.0, 1.0) = 1.0;
uniform float flicker_speed = 11.0;
// Local-space vertical extent of one sprite frame (centred 64 px frames)
uniform float frame_top = -32.0;
uniform float frame_bottom = 32.0;

varying float local_y;

void vertex() {
	// Atlas UVs don't map to a single frame, so reveal by local position instead
	local_y = VERTEX.y;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float lum = dot(base.rgb, vec3(0.3, 0.59, 0.11));
	vec3 body = mix(tint.rgb * 0.55, tint.rgb * 1.5, clamp(lum * 1.8 + 0.2, 0.0, 1.0));

	// Outline: transparent pixels next to opaque ones glow
	vec2 px = TEXTURE_PIXEL_SIZE;
	float around = texture(TEXTURE, UV + vec2(px.x, 0.0)).a + texture(TEXTURE, UV - vec2(px.x, 0.0)).a
		+ texture(TEXTURE, UV + vec2(0.0, px.y)).a + texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float rim = clamp(around, 0.0, 1.0) * (1.0 - base.a);

	float flicker = 0.82 + 0.12 * sin(TIME * flicker_speed) + 0.06 * sin(TIME * 37.0);
	float scan = 0.85 + 0.15 * step(0.5, fract(SCREEN_UV.y * 160.0 - TIME * 2.0));

	// 0 at the feet, 1 at the top of the frame
	float height = clamp((frame_bottom - local_y) / (frame_bottom - frame_top), 0.0, 1.0);
	float shown = step(height, materialize + 0.001);
	float edge = smoothstep(0.08, 0.0, abs(height - materialize)) * step(0.001, 1.0 - materialize);

	vec3 color = mix(body, rim_color.rgb, rim) + rim_color.rgb * edge;
	float alpha = (base.a * opacity * scan + rim * 0.8) * flicker * shown + edge * base.a;
	COLOR = vec4(color, clamp(alpha, 0.0, 1.0));
}
