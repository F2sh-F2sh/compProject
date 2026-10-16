extends SceneTree

## Makes the dungeon's roaming creatures (scripts/creatures/creature.gd), two
## frames each, drawn at 1x and shown 2x, all facing right:
##   creature_bat         a cave bat with ears and scalloped wings (the Belfry, Observatory)
##   creature_mite        a star mite: an indigo beetle with silver spots
##   creature_hushling    a scrap of the Hush: a black flame with white eyes
##   creature_cinderling  a slime of embers, a flame on its crown (Kilnworks)
##   creature_clinker     an armoured beetle with glowing seams (Kilnworks)
##   creature_frostling   a slime of ice, spikes on its back (Cistern)
##   creature_jelly       a drifting brine jelly, its bell pulsing (Cistern)
##   creature_moth        a lampmoth: four pale wings, gold eye-spots (Lampworks, Galleries)
##   creature_foldmite    a creature of folded paper that blinks (Galleries)
##   godot --headless --path . --script res://tools/art/generate_creature_sprites.gd

const OUT := "res://assets/sprites/creatures/"
const PREVIEW := "user://creature_sprites_preview.png"

var _sheet: Array = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save("mite", [_mite(0), _mite(1)])
	_save("hushling", [_hushling(0), _hushling(1)])
	_save("cinderling", [_slime(0, "ember"), _slime(1, "ember")])
	_save("clinker", [_clinker(0), _clinker(1)])
	_save("frostling", [_slime(0, "frost"), _slime(1, "frost")])
	_save("jelly", [_jelly(0), _jelly(1)])
	_save("moth", [_moth(true), _moth(false)])
	_save("foldmite", [_foldmite(0), _foldmite(1)])
	_save_preview()
	print("CREATURES DONE")
	quit()


func _px(img: Image, x: int, y: int, hex: String) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, Color(hex))


func _filled(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a > 0.0


func _ellipse(img: Image, c: Vector2, r: Vector2, hex: String) -> void:
	for y in range(int(c.y - r.y) - 1, int(c.y + r.y) + 2):
		for x in range(int(c.x - r.x) - 1, int(c.x + r.x) + 2):
			var d := Vector2((x + 0.5 - c.x) / r.x, (y + 0.5 - c.y) / r.y)
			if d.length_squared() <= 1.0:
				_px(img, x, y, hex)


func _outline(img: Image, hex := "0a0810") -> void:
	var edge: Array = []
	for y in img.get_height():
		for x in img.get_width():
			if _filled(img, x, y):
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if _filled(img, x + d.x, y + d.y):
					edge.append(Vector2i(x, y))
					break
	for p in edge:
		_px(img, p.x, p.y, hex)


# ------------------------------------------------------------------ the creatures

func _bat(up: bool) -> Image:
	var img := Image.create(20, 13, false, Image.FORMAT_RGBA8)
	# wings: a membrane with finger bones, scalloped along the bottom
	for side in [-1, 1]:
		for i in 7:
			var x: int = 10 + side * (3 + i)
			var rise := (i if i < 4 else 7 - i) if up else -int(i / 3)
			var top := 6 - rise
			var depth := 4 - i / 2 - (1 if i in [2, 5] else 0)
			for y in range(top, top + maxi(depth, 1)):
				_px(img, x, y, "4e3a62" if y > top else "6a5282")
			if i in [1, 4]:
				_px(img, x, top + 1, "2a1e36")
	_ellipse(img, Vector2(10, 7), Vector2(2.6, 3), "3a2a4a")
	_px(img, 8, 3, "3a2a4a")
	_px(img, 12, 3, "3a2a4a")
	_px(img, 8, 4, "3a2a4a")
	_px(img, 12, 4, "3a2a4a")
	_px(img, 9, 6, "ff4a5a")
	_px(img, 11, 6, "ff4a5a")
	_px(img, 10, 8, "e8dcc0")
	_outline(img)
	return img


func _mite(step: int) -> Image:
	var img := Image.create(14, 10, false, Image.FORMAT_RGBA8)
	_ellipse(img, Vector2(7, 5), Vector2(5, 3), "2c2a5a")
	_ellipse(img, Vector2(6, 4), Vector2(3, 1.5), "4a4890")
	for p in [[5, 4], [8, 5], [7, 3]]:
		_px(img, p[0], p[1], "d8dcff")
	_px(img, 11, 5, "f6f2ff")
	for k in 3:
		var x := 4 + k * 3
		_px(img, x + (step if k % 2 == 0 else 1 - step), 9, "1a1838")
		_px(img, x, 8, "1a1838")
	_outline(img)
	return img


func _hushling(flick: int) -> Image:
	var img := Image.create(14, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		var w := int(maxf(0.0, (y - 2) * 0.55)) if y < 10 else int(6 - (y - 10) * 0.8)
		var lean := int(sin(y * 0.7 + flick * 1.5) * 1.5)
		for x in range(7 - w + lean, 7 + w + lean + 1):
			_px(img, x, y, "0b0a12" if y > 4 else "1c1a2a")
	_px(img, 5, 9, "f6f2ff")
	_px(img, 8, 9, "f6f2ff")
	_px(img, 5, 10, "c8c0e0")
	_px(img, 8, 10, "c8c0e0")
	return img


func _slime(squash: int, kind: String) -> Image:
	var img := Image.create(18, 14, false, Image.FORMAT_RGBA8)
	var body := "d8642a" if kind == "ember" else "8ec8ec"
	var light := "ffb05a" if kind == "ember" else "dff2ff"
	var dark := "8a3418" if kind == "ember" else "4a7aa8"
	var r := Vector2(7 + squash, 5 - squash)
	_ellipse(img, Vector2(9, 13 - r.y), r, body)
	_ellipse(img, Vector2(7, 12 - r.y), Vector2(r.x * 0.5, r.y * 0.45), light)
	for x in range(2, 16):
		if _filled(img, x, 13):
			_px(img, x, 13, dark)
	_px(img, 7, 13 - int(r.y), "1a0c10")
	_px(img, 11, 13 - int(r.y), "1a0c10")
	if kind == "ember":
		for k in 3:
			_px(img, 8 + k, 12 - int(r.y * 2.0) - k % 2, ["ffd070", "ff8030", "ffd070"][k])
		_px(img, 9, 10 - int(r.y * 2.0), "fff0b0")
	else:
		for k in 3:
			var x := 5 + k * 4
			_px(img, x, 12 - int(r.y * 2.0), "f2faff")
			_px(img, x, 13 - int(r.y * 2.0), "b8dcf4")
	_outline(img)
	return img


func _clinker(step: int) -> Image:
	var img := Image.create(20, 12, false, Image.FORMAT_RGBA8)
	_ellipse(img, Vector2(10, 6), Vector2(8, 4), "4a4250")
	_ellipse(img, Vector2(9, 5), Vector2(6, 2), "6e6474")
	for x in [6, 10, 14]:
		for y in range(3, 9):
			if _filled(img, x, y):
				_px(img, x, y, "ff7a30")
	_px(img, 17, 6, "ffd070")
	for k in 3:
		var x := 6 + k * 4
		_px(img, x + step, 11, "2a2430")
		_px(img, x, 10, "2a2430")
	_outline(img)
	return img


func _jelly(pulse: int) -> Image:
	var img := Image.create(14, 18, false, Image.FORMAT_RGBA8)
	var r := Vector2(5 + pulse, 4 - pulse * 0.5)
	_ellipse(img, Vector2(7, 6), r, "6ad0d8")
	_ellipse(img, Vector2(6, 5), Vector2(r.x * 0.5, r.y * 0.4), "c8f4f4")
	for k in 4:
		var x := 4 + k * 2
		for y in range(9, 15 + (k % 2) * 2 - pulse):
			_px(img, x + (1 if (y + k) % 4 == 0 else 0), y, "4aa8b8" if y % 2 else "8ae0e8")
	_px(img, 5, 6, "1a3a40")
	_px(img, 9, 6, "1a3a40")
	_outline(img, "0a1a20")
	return img


func _moth(up: bool) -> Image:
	var img := Image.create(20, 16, false, Image.FORMAT_RGBA8)
	for side in [-1, 1]:
		if up:
			_ellipse(img, Vector2(10 + side * 4.5, 5), Vector2(3.6, 3.6), "e8dcb8")
			_ellipse(img, Vector2(10 + side * 3.5, 10), Vector2(2.8, 2.4), "c8b48a")
			_ellipse(img, Vector2(10 + side * 5, 5), Vector2(1.6, 1.6), "d9a830")
			_px(img, 10 + side * 5, 5, "3a2a1a")
		else:
			_ellipse(img, Vector2(10 + side * 5.5, 7), Vector2(4.4, 2.6), "e8dcb8")
			_ellipse(img, Vector2(10 + side * 3.5, 11), Vector2(2.6, 2.2), "c8b48a")
			_ellipse(img, Vector2(10 + side * 6, 7), Vector2(1.6, 1.4), "d9a830")
			_px(img, 10 + side * 6, 7, "3a2a1a")
	for y in range(4, 13):
		_px(img, 10, y, "8a7458" if y > 8 else "f6f2e8")
		_px(img, 9, y, "6a5a42" if y > 8 else "e8dcc0")
	_px(img, 8, 2, "8a7a5a")
	_px(img, 7, 1, "8a7a5a")
	_px(img, 11, 2, "8a7a5a")
	_px(img, 12, 1, "8a7a5a")
	_px(img, 9, 4, "1a1010")
	_outline(img)
	return img


func _foldmite(step: int) -> Image:
	var img := Image.create(14, 12, false, Image.FORMAT_RGBA8)
	for y in range(3, 10):
		for x in range(3, 12):
			if absf(x - 7.5) + absf(y - 6.5) <= 5.0:
				_px(img, x, y, "f2c4de" if (x + y) % 4 < 2 else "d89ac0")
	for y in range(3, 10):
		_px(img, 7 if y < 7 else 8, y, "b07aa8")
	_px(img, 10, 5, "2a1428")
	for k in 2:
		_px(img, 5 + k * 4 + step, 11, "8a5a86")
		_px(img, 5 + k * 4, 10, "8a5a86")
	_outline(img, "2a1428")
	return img


# ------------------------------------------------------------------ saving

func _save(kind: String, frames: Array) -> void:
	var w: int = frames[0].get_width()
	var h: int = frames[0].get_height()
	var strip := Image.create(w * frames.size(), h, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		strip.blit_rect(frames[i], Rect2i(0, 0, w, h), Vector2i(i * w, 0))
	strip.save_png(ProjectSettings.globalize_path(OUT + "creature_" + kind + ".png"))
	_sheet.append(strip)


func _save_preview() -> void:
	var w := 0
	var h := 0
	for s in _sheet:
		w = maxi(w, s.get_width())
		h += s.get_height() + 2
	var sheet := Image.create(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3a3442"))
	var y := 0
	for s in _sheet:
		sheet.blit_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i(0, y))
		y += s.get_height() + 2
	sheet.resize(sheet.get_width() * 6, sheet.get_height() * 6, Image.INTERPOLATE_NEAREST)
	sheet.save_png(ProjectSettings.globalize_path(PREVIEW))
