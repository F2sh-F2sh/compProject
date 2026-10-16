extends SceneTree

## Makes the rune pieces in carved stone (after the UI kit's palette):
##   assets/ui/rune_wheel.png       the inscribing wheel: a stone disc ringed by
##                                  two serpents whose heads meet at its foot,
##                                  four socket pits (essence at the top, form
##                                  right, direction below, modifier left) and
##                                  a centre socket; 160 x 160 art, saved 2x
##   assets/ui/rune_eye_closed.png, rune_eye_open.png   the stone eye over the
##                                  wheel, shut, and open when the sentence is
##                                  whole
##   assets/ui/rune_tablet.png      a small stone tablet (a fragment's button)
##   assets/sprites/story/rune_block.png   the cube as it stands in the world:
##                                  32 x 32, chiselled, four recessed sockets
##   godot --headless --path . --script res://tools/art/generate_rune_ui_sprites.gd

const UI := "res://assets/ui/"
const BLOCK := "res://assets/sprites/story/rune_block.png"
const PREVIEW := "user://rune_ui_preview.png"

const C := {
	"k0": "07060a", "k1": "0d0b10",
	"s0": "121015", "s1": "1a171f", "s2": "242029", "s3": "302b37", "s4": "403948", "s5": "564d61", "s6": "6e6479",
	"g0": "4a3a1c", "g1": "7a5f2a", "g2": "b08a3e", "g3": "d9b25a", "g4": "f6dc8c",
	"r1": "6a1824", "r2": "9e2a3a", "r3": "d24a5a",
	"e0": "e8e2d4", "e1": "b9b0a0",
}

var rng := RandomNumberGenerator.new()
var _sheet: Array = []


func _init() -> void:
	rng.seed = 909
	_save(UI + "rune_wheel.png", _wheel(), 2)
	_save(UI + "rune_eye_closed.png", _eye(false), 2)
	_save(UI + "rune_eye_open.png", _eye(true), 2)
	_save(UI + "rune_tablet.png", _tablet(), 2)
	_save(BLOCK, _block(), 1)
	_save_preview()
	print("RUNE UI DONE")
	quit()


func _c(key: String) -> Color:
	return Color(C[key])


func _px(img: Image, x: int, y: int, key: String) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, _c(key))


func _filled(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a > 0.0


## Stone lit from the upper left: a tone from the direction of the surface
## normal (here: from the centre outwards), with sparse speckle.
func _stone_tone(nx: float, ny: float, base: int) -> String:
	var lit := -(nx * 0.6 + ny * 0.8)
	var k := clampi(base + int(round(lit * 1.6)), 0, 6)
	if rng.randf() < 0.07:
		k = clampi(k + (1 if rng.randf() < 0.5 else -1), 0, 6)
	return "s%d" % k


func _outline(img: Image) -> void:
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
		_px(img, p.x, p.y, "k0")


# ------------------------------------------------------------------ the wheel

func _wheel() -> Image:
	var n := 160
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(n / 2.0, n / 2.0)
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5) - c
			var r := d.length()
			if r > 76.0:
				continue
			var nrm := d / maxf(r, 0.01)
			if r > 62.0:
				# the serpents' coils: scales along the ring
				var ang := atan2(d.y, d.x)
				var scale_k := int(floor((ang + PI) / TAU * 54.0))
				var along := fposmod((ang + PI) / TAU * 54.0, 1.0)
				var across := (r - 62.0) / 14.0
				var base := 4 if scale_k % 2 == 0 else 3
				if along < 0.12 or across < 0.08:
					_px(img, x, y, "s1")
				else:
					var t := _stone_tone(nrm.x, nrm.y, base + (1 if across < 0.45 else 0))
					_px(img, x, y, t)
			elif r > 58.0:
				_px(img, x, y, "k1")
			else:
				# the face of the disc
				_px(img, x, y, _stone_tone(d.x / 58.0 * 0.4, d.y / 58.0 * 0.4, 2))
	# carved ring and radial grooves between the sockets
	for a in 360:
		var p := c + Vector2.from_angle(deg_to_rad(a)) * 52.0
		_px(img, int(p.x), int(p.y), "s0")
		var q := c + Vector2.from_angle(deg_to_rad(a)) * 53.0
		_px(img, int(q.x), int(q.y), "s4")
	for k in 4:
		var ang := deg_to_rad(45.0 + k * 90.0)
		for t in range(16, 52):
			var p := c + Vector2.from_angle(ang) * t
			_px(img, int(p.x), int(p.y), "s0")
			_px(img, int(p.x) + 1, int(p.y), "s4")
	# the four socket pits and the centre socket
	for k in 4:
		var sc := c + Vector2.from_angle(deg_to_rad(-90.0 + k * 90.0)) * 38.0
		_pit(img, sc, 15.0)
	_pit(img, c, 12.0)
	# a gold inlay just inside the coils
	for a in 720:
		var p := c + Vector2.from_angle(deg_to_rad(a * 0.5)) * 60.0
		_px(img, int(p.x), int(p.y), "g2" if a % 12 < 8 else "g1")
	# gold studs between the sockets, on the ring
	for k in 4:
		var p := c + Vector2.from_angle(deg_to_rad(45.0 + k * 90.0)) * 56.0
		_px(img, int(p.x), int(p.y), "g3")
		_px(img, int(p.x) + 1, int(p.y), "g1")
		_px(img, int(p.x), int(p.y) + 1, "g1")
	# the two serpent heads, meeting at the foot of the wheel
	for side in [-1, 1]:
		_serpent_head(img, c + Vector2(side * 16, 69), side)
	_outline(img)
	return img


func _pit(img: Image, c: Vector2, r: float) -> void:
	for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			var d := Vector2(x + 0.5, y + 0.5) - c
			var l := d.length()
			if l > r:
				continue
			if l > r - 2.0:
				# the rim: lit on its lower right inside edge, shadowed above
				_px(img, x, y, "s5" if d.x + d.y > 0.0 else "k1")
			else:
				_px(img, x, y, "k1" if l < r - 5.0 else "s0")


func _serpent_head(img: Image, at: Vector2, side: int) -> void:
	# a wedge-shaped head with a gold eye and a forked tongue toward the middle
	for y in range(-9, 10):
		for x in range(-14, 15):
			var u := x * side
			if absf(y) > 9.0 - maxf(0.0, u - 3.0) * 0.6:
				continue
			_px(img, int(at.x) + x, int(at.y) + y, "s4" if y < 0 else "s2")
	_px(img, int(at.x) + side * 4, int(at.y) - 3, "g4")
	_px(img, int(at.x) + side * 5, int(at.y) - 3, "g3")
	_px(img, int(at.x) + side * 4, int(at.y) - 2, "g1")
	var tip := Vector2(at.x - side * 14, at.y + 1)
	_px(img, int(tip.x), int(tip.y), "r2")
	_px(img, int(tip.x) - side, int(tip.y) - 1, "r3")
	_px(img, int(tip.x) - side, int(tip.y) + 1, "r3")


# ------------------------------------------------------------------ the eye

func _eye(open: bool) -> Image:
	var w := 40
	var h := 24
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var c := Vector2(w / 2.0, h / 2.0)
	# the stone brow round it
	for y in h:
		for x in w:
			var d := Vector2((x + 0.5 - c.x) / 19.0, (y + 0.5 - c.y) / 11.0)
			if d.length_squared() <= 1.0:
				_px(img, x, y, _stone_tone(d.x * 0.6, d.y * 0.6, 3))
	for y in h:
		for x in w:
			var d := Vector2((x + 0.5 - c.x) / 14.0, (y + 0.5 - c.y) / 6.0)
			if d.length_squared() > 1.0:
				continue
			if not open:
				# a carved lid, shut: a seam across the middle
				_px(img, x, y, "k1" if absf(y + 0.5 - c.y) < 1.0 else ("s4" if y < c.y else "s3"))
				continue
			var iris := Vector2(x + 0.5 - c.x, (y + 0.5 - c.y) * 1.4).length()
			if iris < 2.0:
				_px(img, x, y, "k0")
			elif iris < 5.5:
				_px(img, x, y, "g4" if y < c.y else "g3")
			else:
				_px(img, x, y, "e0" if y < c.y else "e1")
	if open:
		_px(img, int(c.x) - 2, int(c.y) - 2, "e0")
	_outline(img)
	return img


func _tablet() -> Image:
	var w := 24
	var h := 16
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			# chamfered corners
			if (x < 2 and y < 2) or (x > w - 3 and y < 2) or (x < 2 and y > h - 3) or (x > w - 3 and y > h - 3):
				continue
			var key := "s3"
			if y <= 1 or x <= 1:
				key = "s5"
			elif y >= h - 2 or x >= w - 2:
				key = "s1"
			elif rng.randf() < 0.06:
				key = "s2"
			_px(img, x, y, key)
	_outline(img)
	return img


# ------------------------------------------------------------------ the cube in the world

func _block() -> Image:
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var key := "s3"
			if x == 0 or y == 0 or x == n - 1 or y == n - 1:
				key = "k1"
			elif y <= 2 or x <= 2:
				key = "s5" if y <= 1 or x <= 1 else "s4"
			elif y >= n - 3 or x >= n - 3:
				key = "s1" if y >= n - 2 or x >= n - 2 else "s2"
			elif rng.randf() < 0.08:
				key = "s2" if rng.randf() < 0.6 else "s4"
			_px(img, x, y, key)
	# chiselled corners
	for p in [Vector2i(0, 0), Vector2i(n - 1, 0), Vector2i(0, n - 1), Vector2i(n - 1, n - 1)]:
		img.set_pixel(p.x, p.y, Color(0, 0, 0, 0))
	# the four recessed sockets (where the words are carved)
	for o in [Vector2i(3, 3), Vector2i(17, 3), Vector2i(3, 17), Vector2i(17, 17)]:
		for y in 12:
			for x in 12:
				var key := "s1"
				if y == 0 or x == 0:
					key = "k1"
				elif y == 11 or x == 11:
					key = "s4"
				_px(img, o.x + x, o.y + y, key)
	# a crack, and a chip of moss-dark stone
	for k in 5:
		_px(img, 15 + (k % 2), 14 + k, "s1")
	return img


# ------------------------------------------------------------------ saving

func _save(path: String, img: Image, scale: int) -> void:
	var out := img.duplicate()
	if scale > 1:
		out.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	out.save_png(ProjectSettings.globalize_path(path))
	_sheet.append(out)


func _save_preview() -> void:
	var w := 0
	var h := 0
	for s in _sheet:
		w += s.get_width() + 8
		h = maxi(h, s.get_height())
	var sheet := Image.create(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("4a4258"))
	var x := 0
	for s in _sheet:
		sheet.blit_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i(x, 0))
		x += s.get_width() + 8
	sheet.save_png(ProjectSettings.globalize_path(PREVIEW))
