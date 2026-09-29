shader_type canvas_item;

// Echidna's material. The pixel art itself is never changed: this only gives
// the flat sprite a surface for the lights to fall on. Normals are derived
// from the silhouette, so the rims of her hat and cape face outward: a torch,
// a light shaft or her own lantern catches the edge facing it and leaves the
// far edge in shadow, which keeps her outline crisp against dark stone.

uniform float edge_normal_strength : hint_range(0.0, 4.0) = 1.6;
// How far in from the silhouette the rim normals reach (in texels).
uniform float edge_width : hint_range(1.0, 3.0) = 2.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * edge_width;
	float l = texture(TEXTURE, UV - vec2(px.x, 0.0)).a;
	float r = texture(TEXTURE, UV + vec2(px.x, 0.0)).a;
	float u = texture(TEXTURE, UV - vec2(0.0, px.y)).a;
	float d = texture(TEXTURE, UV + vec2(0.0, px.y)).a;
	// Points out of the silhouette: toward the side where alpha falls away
	vec2 outward = vec2(l - r, u - d);
	vec3 n = normalize(vec3(outward * edge_normal_strength, 1.0));
	NORMAL_MAP = n * 0.5 + 0.5;
	COLOR = c;
}
