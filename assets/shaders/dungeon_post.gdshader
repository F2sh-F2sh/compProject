shader_type canvas_item;

// Full-screen mood pass for the dungeon, applied in this order:
//  1. Lantern falloff: beyond the player's lantern the gloom deepens, but
//     anything already bright (torches, light shafts, runes, glows) keeps
//     its light, so only the lantern and lit things pierce the dark.
//  2. Soft bloom: bright things bleed a gentle glow into the air.
//  3. Ground mist anchored to the world (not the screen).
//  4. Grade: cold shadows, pale cyan highlights, a touch of contrast.
//  5. Cinematic vignette and fine film grain.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 world_origin = vec2(0.0);   // world position of the screen's top-left
uniform vec2 world_size = vec2(576.0, 324.0);

group_uniforms lantern;
uniform vec2 lantern_uv = vec2(0.5, 0.6);   // the player's lantern, in screen UV
uniform float lantern_inner = 150.0;        // world px: fully lit
uniform float lantern_outer = 440.0;        // world px: full gloom
uniform float lantern_darkness : hint_range(0.0, 1.0) = 0.42;
uniform float keep_bright_from : hint_range(0.0, 1.0) = 0.08;
uniform float keep_bright_to : hint_range(0.0, 1.0) = 0.24;

group_uniforms bloom;
uniform float bloom_strength : hint_range(0.0, 2.0) = 0.55;
uniform float bloom_threshold : hint_range(0.0, 1.0) = 0.3;

group_uniforms mist;
uniform vec4 fog_color : source_color = vec4(0.27, 0.36, 0.48, 1.0);
uniform float fog_strength : hint_range(0.0, 1.0) = 0.22;
uniform float fog_floor_y = 534.0;       // mist gathers toward this height

group_uniforms grade;
uniform vec4 shadow_tint : source_color = vec4(0.9, 0.96, 1.06, 1.0);
uniform vec4 highlight_tint : source_color = vec4(1.02, 1.04, 1.06, 1.0);
uniform float contrast : hint_range(0.5, 1.5) = 1.04;
uniform float saturation : hint_range(0.0, 1.5) = 0.86;

group_uniforms frame;
uniform float vignette : hint_range(0.0, 1.0) = 0.34;
uniform float vignette_softness : hint_range(0.1, 1.0) = 0.7;
uniform float grain : hint_range(0.0, 0.2) = 0.022;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * noise(p);
		p *= 2.03;
		amp *= 0.5;
	}
	return v;
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec2 world = world_origin + SCREEN_UV * world_size;

	// 1. Lantern falloff, measured in world pixels so it is zoom-independent
	vec2 lantern_world = world_origin + lantern_uv * world_size;
	float dist = length(world - lantern_world);
	float gloom = smoothstep(lantern_inner, lantern_outer, dist) * lantern_darkness;
	float keep = smoothstep(keep_bright_from, keep_bright_to, luma(c));
	c *= 1.0 - gloom * (1.0 - keep);

	// 2. Bloom from two blurred mip levels of the screen
	vec3 blur = textureLod(screen_tex, SCREEN_UV, 2.5).rgb * 0.5 + textureLod(screen_tex, SCREEN_UV, 4.0).rgb * 0.5;
	c += max(blur - vec3(bloom_threshold), vec3(0.0)) * bloom_strength;

	// 3. Two layers of mist drifting at different speeds
	float slow = fbm(world * 0.0055 + vec2(TIME * 0.035, 0.0));
	float fast = fbm(world * 0.012 - vec2(TIME * 0.06, TIME * 0.012));
	float mist = smoothstep(0.38, 0.9, slow * 0.65 + fast * 0.45);
	float height_above_floor = fog_floor_y - world.y;
	mist *= mix(1.25, 0.35, clamp(height_above_floor / 260.0, 0.0, 1.0));
	c = mix(c, fog_color.rgb, clamp(mist * fog_strength, 0.0, 1.0));

	// 4. Grade: split toning, contrast around mid grey, gentle desaturation
	float l = luma(c);
	c *= mix(shadow_tint.rgb, highlight_tint.rgb, smoothstep(0.05, 0.5, l));
	c = (c - 0.5) * contrast + 0.5;
	c = mix(vec3(luma(c)), c, saturation);

	// 5. Cinematic vignette (wider than tall) and grain
	vec2 d = (SCREEN_UV - 0.5) * vec2(1.0, 1.25);
	c *= 1.0 - smoothstep(0.75 - vignette_softness, 0.95, length(d) * 1.35) * vignette;
	c += (hash(SCREEN_UV * 931.7 + fract(TIME) * 17.0) - 0.5) * grain;
	COLOR = vec4(max(c, vec3(0.0)), 1.0);
}
