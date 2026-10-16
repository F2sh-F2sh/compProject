extends SceneTree

## Makes the small props each level scatters on its ledges and hangs from its
## ceilings (LevelTheme places them), one strip per theme and kind, 16 x 24
## art pixels a frame, shown 2x:
##   prop_<theme>_top   things that sit on a floor (feet at the frame's foot)
##   prop_<theme>_hang  things that hang from a ceiling (tops at the frame's top)
## Passage: pink flowers, a fern, moss, a mushroom / a flowering vine.
## Belfry: snow drifts, a frozen rope / icicles. Observatory: brass gears, a
## star crystal / a hanging star. Landing: frost, a candle stub / icicles.
## Kilnworks: coal, a glowing crack / a chain. Cistern: algae, a shell / drips
## of icicle. Lampworks: books, a candle stub / a cobweb. Galleries: paper
## scraps, petals / a paper chain. The Eye: frost / icicles.
##   godot --headless --path . --script res://tools/art/generate_level_props.gd

const OUT := "res://assets/sprites/props/"
const PREVIEW := "user://level_props_preview.png"
const W := 16
const H := 24

var rng := RandomNumberGenerator.new()
var _sheet: Array = []


func _init() -> void:
	rng.seed = 6061
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_strip("passage_top", [_flower("ff9ac0", "c2507a"), _fern(), _moss(), _mushroom()])
	_strip("passage_hang", [_vine(true), _vine(false)])
	_strip("belfry_top", [_drift(), _rope()])
	_strip("belfry_hang", [_icicles(3), _icicles(2)])
	_strip("observatory_top", [_gear(), _crystal("a6b4ff")])
	_strip("observatory_hang", [_star_hang()])
	_strip("landing_top", [_frost(), _candle()])
	_strip("landing_hang", [_icicles(2)])
	_strip("kiln_top", [_coal(), _crack()])
	_strip("kiln_hang", [_chain(14), _chain(20)])
	_strip("cistern_top", [_algae(), _shell()])
	_strip("cistern_hang", [_icicles(2), _drip_moss()])
	_strip("lamps_top", [_books(), _candle()])
	_strip("lamps_hang", [_cobweb()])
	_strip("galleries_top", [_paper(), _flower("ffd0e8", "b07aa8")])
	_strip("galleries_hang", [_paper_chain()])
	_strip("eye_top", [_frost(), _drift()])
	_strip("eye_hang", [_icicles(3)])
	_save_preview()
	print("LEVEL PROPS DONE")
	quit()


# ------------------------------------------------------------------ helpers

func _img() -> Image:
	return Image.create(W, H, false, Image.FORMAT_RGBA8)


func _px(img: Image, x: int, y: int, hex: String) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		img.set_pixel(x, y, Color(hex))


func _filled(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H and img.get_pixel(x, y).a > 0.0


func _outline(img: Image) -> void:
	var edge: Array = []
	for y in H:
		for x in W:
			if _filled(img, x, y):
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if _filled(img, x + d.x, y + d.y):
					edge.append(Vector2i(x, y))
					break
	for p in edge:
		_px(img, p.x, p.y, "0a0810")


# ------------------------------------------------------------------ tops (feet at y = H - 1)

func _flower(petal: String, dark: String) -> Image:
	var img := _img()
	for s in [[4, 6], [8, 9], [11, 5]]:
		for y in range(H - s[1], H):
			_px(img, s[0], y, "3f7a4a")
		_px(img, s[0] - 1, H - s[1] + 3, "5fa060")
		var top: int = H - s[1] - 1
		_px(img, s[0], top - 1, petal)
		_px(img, s[0] - 1, top, petal)
		_px(img, s[0] + 1, top, petal)
		_px(img, s[0], top + 1, dark)
		_px(img, s[0], top, "fff0a0")
	_outline(img)
	return img


func _fern() -> Image:
	var img := _img()
	for k in 3:
		var x0 := 4 + k * 4
		for i in 8:
			var y := H - 1 - i
			_px(img, x0 + (i / 3) * (1 if k == 2 else -1 if k == 0 else 0), y, "4c8f55")
			if i % 2 == 0:
				_px(img, x0 + 1 + (i / 3) * (1 if k == 2 else -1 if k == 0 else 0), y, "79c070")
	_outline(img)
	return img


func _moss() -> Image:
	var img := _img()
	for x in range(2, 14):
		var h := 2 + int(absf(sin(x * 1.3)) * 2.0)
		for y in range(H - h, H):
			_px(img, x, y, "5e9a58" if y == H - h else "3d6e44")
	_outline(img)
	return img


func _mushroom() -> Image:
	var img := _img()
	for y in range(H - 5, H):
		_px(img, 7, y, "e8e0d0")
		_px(img, 8, y, "c8bfae")
	for x in range(4, 12):
		_px(img, x, H - 6, "c2507a")
		if x > 4 and x < 11:
			_px(img, x, H - 7, "e06a90")
	_px(img, 6, H - 7, "ffe0ea")
	_px(img, 9, H - 6, "ffe0ea")
	_outline(img)
	return img


func _drift() -> Image:
	var img := _img()
	for x in range(1, 15):
		var h := 1 + int((1.0 - absf(x - 7.5) / 7.5) * 4.0)
		for y in range(H - h, H):
			_px(img, x, y, "f2f6ff" if y == H - h else "c8d2e8")
	_outline(img)
	return img


func _rope() -> Image:
	var img := _img()
	for a in 24:
		var p: Vector2 = Vector2(8, H - 4) + Vector2.from_angle(a * TAU / 24.0) * Vector2(5, 2.5)
		_px(img, int(p.x), int(p.y), "8a7454" if a % 3 else "c9b48a")
	for y in range(H - 3, H):
		_px(img, 8, y, "8a7454")
	_px(img, 5, H - 5, "f2f6ff")
	_px(img, 10, H - 5, "f2f6ff")
	_outline(img)
	return img


func _gear() -> Image:
	var img := _img()
	var c := Vector2(8, H - 6)
	for y in range(H - 12, H):
		for x in W:
			var d := Vector2(x + 0.5, y + 0.5) - c
			var r := d.length()
			var teeth := 4.6 + (1.2 if int(floor((atan2(d.y, d.x) + PI) / TAU * 8.0 + 0.5)) % 2 == 0 else 0.0)
			if r <= teeth and r > 1.5:
				_px(img, x, y, "d9b25a" if d.x + d.y < 0 else "9a7a34")
	_outline(img)
	return img


func _crystal(hex: String) -> Image:
	var img := _img()
	for k in 3:
		var x0 := 5 + k * 3
		var h: int = [6, 10, 7][k]
		for i in h:
			_px(img, x0, H - 1 - i, hex)
			_px(img, x0 + 1, H - 1 - i, Color(hex).darkened(0.3).to_html(false))
		_px(img, x0, H - h, "ffffff")
	_outline(img)
	return img


func _frost() -> Image:
	var img := _img()
	for k in 5:
		var x := 3 + k * 2 + rng.randi() % 2
		var h := 2 + rng.randi() % 4
		for i in h:
			_px(img, x, H - 1 - i, "dfe8ff" if i == h - 1 else "a8b8e0")
	_outline(img)
	return img


func _candle() -> Image:
	var img := _img()
	for y in range(H - 6, H):
		_px(img, 7, y, "e8e0c8")
		_px(img, 8, y, "c8bfa4")
	_px(img, 7, H - 7, "ffd070")
	_px(img, 7, H - 8, "fff4c0")
	_px(img, 8, H - 7, "ff9a40")
	_outline(img)
	return img


func _coal() -> Image:
	var img := _img()
	for x in range(2, 14):
		var h := 1 + int((1.0 - absf(x - 8.0) / 6.0) * 4.0)
		for y in range(H - h, H):
			_px(img, x, y, "2a2228" if (x + y) % 3 else "4a3a3a")
	_px(img, 7, H - 3, "ff7030")
	_px(img, 10, H - 2, "ffa040")
	_outline(img)
	return img


func _crack() -> Image:
	var img := _img()
	for x in range(1, 15):
		_px(img, x, H - 1, "1c0c09")
	for p in [[4, H - 2], [5, H - 3], [6, H - 2], [9, H - 2], [10, H - 3], [11, H - 4]]:
		_px(img, p[0], p[1], "ff8030")
	_px(img, 5, H - 4, "ffd080")
	return img


func _algae() -> Image:
	var img := _img()
	for k in 4:
		var x := 3 + k * 3
		var h := 3 + rng.randi() % 5
		for i in h:
			_px(img, x + int(sin(i * 0.9 + k) * 1.2), H - 1 - i, "3f8a78" if i % 2 else "2c6660")
	_outline(img)
	return img


func _shell() -> Image:
	var img := _img()
	for x in range(5, 12):
		var h := 1 + int((1.0 - absf(x - 8.0) / 4.0) * 3.0)
		for y in range(H - h, H):
			_px(img, x, y, "e8d8c8" if (x % 2) else "c8b0a0")
	_outline(img)
	return img


func _books() -> Image:
	var img := _img()
	var colours := ["8e2433", "3a5a8a", "6a7a3a"]
	for k in 3:
		var y := H - 2 - k * 2
		for x in range(3 + k, 13 - k):
			_px(img, x, y, colours[k])
			_px(img, x, y + 1, Color(colours[k]).darkened(0.35).to_html(false))
		_px(img, 12 - k, y, "e8dcc0")
	_outline(img)
	return img


func _paper() -> Image:
	var img := _img()
	for s in [[3, H - 2, 4, 3], [8, H - 2, 5, 2], [6, H - 4, 3, 2]]:
		for y in s[3]:
			for x in s[2]:
				_px(img, s[0] + x, s[1] - y, "f2e6d0" if (x + y) % 3 else "d8c8b0")
	_px(img, 4, H - 3, "8a7a6a")
	_outline(img)
	return img


# ------------------------------------------------------------------ hangs (tops at y = 0)

func _vine(blossom: bool) -> Image:
	var img := _img()
	var length := 18 if blossom else 14
	for y in length:
		var x := 8 + int(sin(y * 0.5) * 1.5)
		_px(img, x, y, "3f7a4a")
		if y % 4 == 1:
			_px(img, x - 1, y, "5fa060")
			_px(img, x + 1, y + 1, "79c070")
	if blossom:
		_px(img, 8, length, "ff9ac0")
		_px(img, 7, length + 1, "ff9ac0")
		_px(img, 9, length + 1, "c2507a")
	_outline(img)
	return img


func _icicles(count: int) -> Image:
	var img := _img()
	for k in count:
		var x := 3 + k * (10 / maxi(count - 1, 1))
		var h := 6 + rng.randi() % 9
		for i in h:
			var w := 1 if i > h / 2 else 2
			for dx in w:
				_px(img, x + dx, i, "dfeaff" if dx == 0 else "a8bce0")
	_outline(img)
	return img


func _star_hang() -> Image:
	var img := _img()
	for y in 12:
		_px(img, 8, y, "8a7a5a")
	for d in [Vector2i(0, -2), Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, 2), Vector2i(0, 0), Vector2i(-1, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1)]:
		_px(img, 8 + d.x, 14 + d.y, "f6dc8c" if d == Vector2i.ZERO else "d9b25a")
	_outline(img)
	return img


func _chain(length: int) -> Image:
	var img := _img()
	for y in length:
		var odd := (y / 3) % 2 == 1
		_px(img, 7 if odd else 8, y, "6e6474")
		if y % 3 == 0:
			_px(img, 8 if odd else 7, y, "9a8fa0")
	_px(img, 7, length, "4a4250")
	_px(img, 8, length + 1, "4a4250")
	_outline(img)
	return img


func _drip_moss() -> Image:
	var img := _img()
	for k in 3:
		var x := 4 + k * 4
		var h := 3 + rng.randi() % 6
		for i in h:
			_px(img, x, i, "2c6660" if i < h - 1 else "8fd4d0")
	_outline(img)
	return img


func _cobweb() -> Image:
	var img := _img()
	for a in 5:
		var dir := Vector2.from_angle(PI / 2.0 * a / 4.0)
		for t in 12:
			var p: Vector2 = dir * t
			_px(img, int(p.x) + 1, int(p.y) + 1, "c8c0d0")
	for r in [4, 8]:
		for a in 10:
			var p: Vector2 = Vector2.from_angle(PI / 2.0 * a / 9.0) * r
			_px(img, int(p.x) + 1, int(p.y) + 1, "a8a0b0")
	return img


func _paper_chain() -> Image:
	var img := _img()
	for y in 18:
		var x := 8 + (1 if (y / 3) % 2 == 0 else -1)
		_px(img, x, y, ["f2c4de", "c8e0f2", "f2e6b0"][(y / 3) % 3])
		_px(img, x + 1, y, "e0a8c8" if (y / 3) % 2 == 0 else "a8c8e0")
	_outline(img)
	return img


# ------------------------------------------------------------------ saving

func _strip(prop_name: String, frames: Array) -> void:
	var strip := Image.create(W * frames.size(), H, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		strip.blit_rect(frames[i], Rect2i(0, 0, W, H), Vector2i(i * W, 0))
	strip.save_png(ProjectSettings.globalize_path(OUT + "prop_" + prop_name + ".png"))
	_sheet.append(strip)


func _save_preview() -> void:
	var w := 0
	var h := 0
	for s in _sheet:
		w = maxi(w, s.get_width())
		h += H + 2
	var sheet := Image.create(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("2a2430"))
	var y := 0
	for s in _sheet:
		sheet.blit_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i(0, y))
		y += H + 2
	sheet.resize(sheet.get_width() * 4, sheet.get_height() * 4, Image.INTERPOLATE_NEAREST)
	sheet.save_png(ProjectSettings.globalize_path(PREVIEW))
