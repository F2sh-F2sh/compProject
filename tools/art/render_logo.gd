extends Node

## Renders the rune-cube logo: a rounded 3D cube with the game's runes carved
## into its faces (raymarched in a shader), turned into pixel art with a
## limited palette, next to a pixel-shaded wordmark. Open
## tools/art/render_logo.tscn and press F6 (it needs a window to render).

## Written next to the project, in "For Upload/logo_v2/".
var OUT := ProjectSettings.globalize_path("res://").path_join("../For Upload/logo_v2/").simplify_path() + "/"
const ART := 150          # the cube's size in art pixels
const SS := 8             # supersampling while rendering
const SCALE := 4          # art pixel -> output pixels
## Warm greys from near-black to white, like the reference die.
const RAMP := ["0b0a0e", "18161c", "26232b", "36323a", "48434b", "5c565d", "716a70", "878085",
	"9e979a", "b5aeb0", "cbc5c5", "ddd8d6", "ece8e4", "f8f5f0", "ffffff"]
const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

const CUBE_SHADER := """
shader_type canvas_item;
uniform sampler2D g_top : filter_linear;
uniform sampler2D g_front : filter_linear;
uniform sampler2D g_right : filter_linear;
uniform sampler2D g_other : filter_linear;
uniform mat3 rot;
const float H = 1.0;
const float R = 0.24;
const float GLYPH = 0.80;

float sd_box(vec3 p) {
	vec3 q = abs(p) - vec3(H - R);
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - R;
}
vec3 normal_at(vec3 p) {
	vec2 e = vec2(0.0008, 0.0);
	return normalize(vec3(sd_box(p + e.xyy) - sd_box(p - e.xyy), sd_box(p + e.yxy) - sd_box(p - e.yxy), sd_box(p + e.yyx) - sd_box(p - e.yyx)));
}
float glyph(int face, vec2 uv) {
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) return 0.0;
	if (face == 0) return texture(g_top, uv).a;
	if (face == 1) return texture(g_front, uv).a;
	if (face == 2) return texture(g_right, uv).a;
	return texture(g_other, uv).a;
}
void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	q.y = -q.y;
	vec3 ro = vec3(0.0, 0.0, 7.0);
	vec3 rd = normalize(vec3(q * 0.27, -1.0));
	mat3 inv = transpose(rot);
	vec3 o = inv * ro;
	vec3 d = inv * rd;
	float t = 0.0;
	bool hit = false;
	for (int i = 0; i < 160; i++) {
		float h = sd_box(o + d * t);
		if (h < 0.0004) { hit = true; break; }
		t += h;
		if (t > 20.0) break;
	}
	if (!hit) { COLOR = vec4(0.0); }
	else {
		vec3 p = o + d * t;
		vec3 n = normal_at(p);
		// the face this point belongs to, and its texture axes (v points down the glyph)
		vec3 a = abs(n);
		int face = 3; vec3 U = vec3(1.0, 0.0, 0.0); vec3 V = vec3(0.0, -1.0, 0.0);
		if (a.y >= a.x && a.y >= a.z) { face = n.y > 0.0 ? 0 : 3; U = vec3(1.0, 0.0, 0.0); V = vec3(0.0, 0.0, 1.0); }
		else if (a.z >= a.x) { face = n.z > 0.0 ? 1 : 3; U = vec3(1.0, 0.0, 0.0); V = vec3(0.0, -1.0, 0.0); }
		else { face = n.x > 0.0 ? 2 : 3; U = vec3(0.0, 0.0, -1.0); V = vec3(0.0, -1.0, 0.0); }
		vec2 uv = vec2(dot(p, U), dot(p, V)) / (H * GLYPH) * 0.5 + 0.5;
		float e = 1.6 / 256.0;
		float m = glyph(face, uv);
		float du = glyph(face, uv + vec2(e, 0.0)) - glyph(face, uv - vec2(e, 0.0));
		float dv = glyph(face, uv + vec2(0.0, e)) - glyph(face, uv - vec2(0.0, e));
		vec3 nb = normalize(n + 1.6 * (du * U + dv * V));
		vec3 nc = rot * nb;
		vec3 L = normalize(vec3(-0.55, 0.78, 0.62));
		vec3 Vw = -rd;
		float diff = max(dot(nc, L), 0.0);
		float spec = pow(max(dot(nc, normalize(L + Vw)), 0.0), 28.0);
		float fres = pow(1.0 - max(dot(nc, Vw), 0.0), 3.0);
		vec3 ivory = vec3(0.95, 0.93, 0.90);
		vec3 groove = vec3(0.10, 0.09, 0.11);
		vec3 albedo = mix(ivory, groove, smoothstep(0.35, 0.75, m) * 0.92);
		float fill = max(dot(nc, normalize(vec3(0.85, 0.05, 0.5))), 0.0);
		vec3 col = albedo * (0.14 + 0.9 * diff + 0.32 * fill) + vec3(0.30) * spec * (1.0 - m) - 0.2 * fres;
		COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
	}
}
"""


class Glyph extends Control:
	var id: StringName
	func _draw() -> void:
		RuneFragments.draw_glyph(self, id, Vector2(128, 128), 214.0, Color.WHITE, 17.0)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var tex := {}
	for id in ["fire", "wind", "light", "ice"]:
		tex[id] = ImageTexture.create_from_image(await render_glyph(id))
	var cube := quantize(pixelize(await render_cube(tex), ART, ART), true)
	# the wordmark, in the game's title face
	var small := style_text(await render_text("THE SEALED", Fonts.TITLE, 24))
	var big := style_text(await render_text("BELFRY", Fonts.TITLE, 50))
	var text_w := maxi(small.get_width(), big.get_width())
	var text_h := small.get_height() + 2 + big.get_height()
	var w := ART + 10 + text_w + 4
	var h := maxi(ART, text_h) + 4
	var logo := Image.create(w, h, false, Image.FORMAT_RGBA8)
	logo.blend_rect(cube, Rect2i(Vector2i.ZERO, cube.get_size()), Vector2i(0, (h - ART) / 2))
	var tx := ART + 10
	var ty := (h - text_h) / 2
	logo.blend_rect(small, Rect2i(Vector2i.ZERO, small.get_size()), Vector2i(tx + (text_w - small.get_width()) / 2, ty))
	logo.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(tx + (text_w - big.get_width()) / 2, ty + small.get_height() + 2))
	save(logo, "logo")
	# the icon: the cube alone on a square
	var icon := Image.create(ART + 8, ART + 8, false, Image.FORMAT_RGBA8)
	icon.blend_rect(cube, Rect2i(Vector2i.ZERO, cube.get_size()), Vector2i(4, 4))
	save(icon, "icon")
	print("LOGO done ", logo.get_size(), " ", icon.get_size())
	get_tree().quit()


func save(img: Image, base: String) -> void:
	var big := img.duplicate()
	big.resize(img.get_width() * SCALE, img.get_height() * SCALE, Image.INTERPOLATE_NEAREST)
	big.save_png(OUT + base + "_transparent.png")
	var black := Image.create(big.get_width(), big.get_height(), false, Image.FORMAT_RGBA8)
	black.fill(Color.BLACK)
	black.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i.ZERO)
	black.save_png(OUT + base + "_black.png")
	img.save_png(OUT + base + "_1x.png")


func render_glyph(id: String) -> Image:
	var vp := SubViewport.new()
	vp.size = Vector2i(256, 256)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var g := Glyph.new()
	g.id = StringName(id)
	g.size = Vector2(256, 256)
	vp.add_child(g)
	for i in 4:
		await get_tree().process_frame
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


func render_cube(tex: Dictionary) -> Image:
	var n := ART * SS
	var vp := SubViewport.new()
	vp.size = Vector2i(n, n)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var rect := ColorRect.new()
	rect.size = Vector2(n, n)
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = CUBE_SHADER
	# a tumble like the reference die: top, front and right faces showing
	var b := Basis(Vector3(0, 0, 1), deg_to_rad(-16)) * Basis(Vector3(1, 0, 0), deg_to_rad(34)) * Basis(Vector3(0, 1, 0), deg_to_rad(-40))
	mat.set_shader_parameter("rot", b)
	mat.set_shader_parameter("g_top", tex["fire"])
	mat.set_shader_parameter("g_front", tex["wind"])
	mat.set_shader_parameter("g_right", tex["light"])
	mat.set_shader_parameter("g_other", tex["ice"])
	rect.material = mat
	vp.add_child(rect)
	for i in 4:
		await get_tree().process_frame
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


func render_text(text: String, font: Font, px: int) -> Image:
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px * SS)
	var vp := SubViewport.new()
	vp.size = Vector2i(int(size.x) + 8 * SS, int(size.y) + 8 * SS)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", px * SS)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.position = Vector2(4 * SS, 4 * SS)
	vp.add_child(label)
	for i in 4:
		await get_tree().process_frame
	var img := vp.get_texture().get_image()
	vp.queue_free()
	img.resize(img.get_width() / SS, img.get_height() / SS, Image.INTERPOLATE_LANCZOS)
	var mask := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a >= 0.5:
				mask.set_pixel(x, y, Color.WHITE)
	return mask.get_region(mask.get_used_rect().grow(3))


func pixelize(img: Image, w: int, h: int) -> Image:
	img.resize(w, h, Image.INTERPOLATE_LANCZOS)
	return img


func ramp_color(l: float, x: int, y: int, dither: bool) -> Color:
	var steps := RAMP.size() - 1
	var d: float = (BAYER[y % 4][x % 4] / 16.0 - 0.5) * 0.6 / steps if dither else 0.0
	return Color(RAMP[clampi(int(round((l + d) * steps)), 0, steps)])


func quantize(img: Image, dither: bool) -> Image:
	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			out.set_pixel(x, y, ramp_color(c.get_luminance() / maxf(c.a, 0.001), x, y, dither))
	return out


## Bevelled like carved bone: bright along top-left edges, shaded along
## bottom-right ones, a vertical gradient, a dark outline and a drop shadow.
func style_text(mask: Image) -> Image:
	var w := mask.get_width()
	var h := mask.get_height()
	var solid := func(x: int, y: int) -> bool:
		return x >= 0 and y >= 0 and x < w and y < h and mask.get_pixel(x, y).a > 0.5
	var top := mask.get_used_rect().position.y
	var height := maxf(mask.get_used_rect().size.y, 1.0)
	var out := Image.create(w + 3, h + 3, false, Image.FORMAT_RGBA8)
	# shadow, then outline, then the letters
	for y in h:
		for x in w:
			if solid.call(x, y):
				out.set_pixel(x + 2, y + 2, Color(RAMP[1]))
	for y in range(-1, h + 1):
		for x in range(-1, w + 1):
			if not solid.call(x, y) and (solid.call(x - 1, y) or solid.call(x + 1, y) or solid.call(x, y - 1) or solid.call(x, y + 1)):
				if x >= 0 and y >= 0:
					out.set_pixel(x, y, Color(RAMP[0]))
	for y in h:
		for x in w:
			if not solid.call(x, y):
				continue
			var l := lerpf(0.98, 0.58, (y - top) / height)
			if not solid.call(x - 1, y - 1) or not solid.call(x, y - 1):
				l += 0.12
			if not solid.call(x + 1, y + 1) or not solid.call(x, y + 1):
				l -= 0.22
			out.set_pixel(x, y, ramp_color(clampf(l, 0.0, 1.0), x, y, true))
	return out
