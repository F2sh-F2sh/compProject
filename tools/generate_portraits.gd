extends SceneTree

## Makes the dialogue portraits: large busts in the game's own look (faces in
## shadow, eyes that glow), drawn at 1x (112 x 136) and shown 3x by the
## DialogueBox. Each character is one strip, a frame per expression, facing
## right (the box mirrors one for the right-hand side):
##   portrait_echidna  neutral, worried, determined, sad, surprised
##   portrait_nan      warm, lost, sad, bright
##   portrait_wren     calm, smile, pleading, scared
##   portrait_ilse     pleading, grief, peace
## Expressions are carried by the eyes (their shape, tilt, size and shine)
## and a little by the pose (a lowered hat brim, a bowed head).
##   godot --headless --path . --script res://tools/generate_portraits.gd

const OUT := "res://assets/sprites/story/"
const PREVIEW := "user://portraits_preview.png"
const W := 112
const H := 136
const FACES := {
	"echidna": ["neutral", "worried", "determined", "sad", "surprised"],
	"nan": ["warm", "lost", "sad", "bright"],
	"wren": ["calm", "smile", "pleading", "scared"],
	"ilse": ["pleading", "grief", "peace"],
}

const C := {
	"k0": "07060a", "k1": "0d0b12", "k2": "16141f",
	"rim": "9fb4e6", "rimw": "ffd9a0",
	"eye": "f6f2ff", "eye2": "d2cbe8", "shine": "ffffff", "glint": "a8d8ff", "tear": "8fd0ff",
	# Echidna: her hat and cloak (purple), the cloak's green lining, the buckle
	"h0": "2a2040", "h1": "3b2d58", "h2": "4d3b72", "h3": "64508f", "h4": "8069ad",
	"v0": "142420", "v1": "1d3530", "v2": "2a4a42",
	"y0": "9a6e1c", "y1": "d9a830", "y2": "f6d860", "y3": "fff4b8",
	# Nan: shawl, dress, silver hair, cap, spectacles
	"s0": "352a4d", "s1": "4a3b68", "s2": "5f4c84", "s3": "7a66a2",
	"d0": "2a1c16", "d1": "3e2b20", "d2": "56402e",
	"a0": "8d87a3", "a1": "b4aec8", "a2": "d8d4e6", "a3": "f4f2fa",
	"c0": "5c5578", "c1": "8c84ae", "c2": "b9b2d6",
	"r1": "8e2433", "r2": "b23a48", "r3": "e06070",
	# Wren: hair, nightdress, ribbons
	"b0": "3a2416", "b1": "553624", "b2": "744d33", "b3": "96694a",
	"n0": "7d7898", "n1": "a6a0c0", "n2": "cdc8e2", "n3": "efecf8",
	# Ilse: hood and robe, silver
	"i0": "17121f", "i1": "241c33", "i2": "34294a", "i3": "4a3c68", "i4": "62528a",
	"m0": "6e7488", "m1": "a8b0c4", "m2": "e2e8f6",
	"g1": "8f8aa0", "g2": "c4c0d4",
}

var rng := RandomNumberGenerator.new()
var _sheet: Array = []


func _init() -> void:
	rng.seed = 2601
	for who in FACES:
		var frames: Array = []
		for face in FACES[who]:
			frames.append(call("_" + who, face))
		_save("portrait_" + who, frames)
	_save_preview()
	print("PORTRAITS DONE")
	quit()


# ------------------------------------------------------------------ helpers

func _c(key: String) -> Color:
	return Color(C[key])


func _img() -> Image:
	return Image.create(W, H, false, Image.FORMAT_RGBA8)


func _px(img: Image, x: int, y: int, key: String) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		img.set_pixel(x, y, _c(key))


func _filled(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H and img.get_pixel(x, y).a > 0.0


## Fills a polygon, shading it from four tones (dark .. light) by where each
## pixel sits: lighter toward the upper left, with a soft dither between bands.
func _shape(img: Image, pts: PackedVector2Array, tones: Array, bias := 0.0) -> void:
	var lo := pts[0]
	var hi := pts[0]
	for p in pts:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	var size := (hi - lo).max(Vector2.ONE)
	for y in range(int(lo.y), int(hi.y) + 1):
		for x in range(int(lo.x), int(hi.x) + 1):
			if not Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				continue
			var u := (x - lo.x) / size.x
			var v := (y - lo.y) / size.y
			var light := 1.0 - (u * 0.55 + v * 0.75) + bias
			var t := light * (tones.size() - 0.6)
			var k := int(floor(t))
			# dither the edge between two bands
			if fposmod(t, 1.0) > 0.78 and (x + y) % 2 == 0:
				k += 1
			_px(img, x, y, tones[clampi(k, 0, tones.size() - 1)])


func _ellipse(img: Image, c: Vector2, r: Vector2, key: String) -> void:
	for y in range(int(c.y - r.y) - 1, int(c.y + r.y) + 2):
		for x in range(int(c.x - r.x) - 1, int(c.x + r.x) + 2):
			var d := Vector2((x + 0.5 - c.x) / r.x, (y + 0.5 - c.y) / r.y)
			if d.length_squared() <= 1.0:
				_px(img, x, y, key)


func _line(img: Image, a: Vector2, b: Vector2, key: String, only_on_filled := true) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n).round()
		if not only_on_filled or _filled(img, int(p.x), int(p.y)):
			_px(img, int(p.x), int(p.y), key)


## A dark outline round everything drawn so far.
func _outline(img: Image) -> void:
	var edge: Array = []
	for y in H:
		for x in W:
			if _filled(img, x, y):
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if _filled(img, x + d.x, y + d.y) and img.get_pixel(x + d.x, y + d.y) != _c("k0"):
					edge.append(Vector2i(x, y))
					break
	for p in edge:
		# the bust is cut by the frame at the bottom: no outline there
		if p.y < H - 1:
			_px(img, p.x, p.y, "k0")


## A cool rim light down the right-hand edges, and a warm one along the top
## left (the candle side).
func _rims(img: Image) -> void:
	var cool: Array = []
	var warm: Array = []
	for y in range(1, H):
		for x in range(1, W - 1):
			if not _filled(img, x, y) or img.get_pixel(x, y) == _c("k0"):
				continue
			var right_open := not _filled(img, x + 1, y) or img.get_pixel(x + 1, y) == _c("k0")
			var top_open := not _filled(img, x, y - 1) or img.get_pixel(x, y - 1) == _c("k0")
			var left_open := not _filled(img, x - 1, y) or img.get_pixel(x - 1, y) == _c("k0")
			if right_open and y % 3 != 0:
				cool.append(Vector2i(x, y))
			elif (top_open or left_open) and x < W / 2 and y % 2 == 0:
				warm.append(Vector2i(x, y))
	for p in cool:
		img.set_pixel(p.x, p.y, img.get_pixel(p.x, p.y).lerp(_c("rim"), 0.55))
	for p in warm:
		img.set_pixel(p.x, p.y, img.get_pixel(p.x, p.y).lerp(_c("rimw"), 0.35))


## The face in shadow: a soft dark oval, a little lighter at its upper rim.
func _shadow_face(img: Image, c: Vector2, r: Vector2) -> void:
	_ellipse(img, c, r, "k1")
	_ellipse(img, c + Vector2(-1, 2), r - Vector2(3, 4), "k0")
	for x in range(int(c.x - r.x + 4), int(c.x + r.x - 4)):
		var y := int(c.y - sqrt(maxf(0.0, 1.0 - pow((x + 0.5 - c.x) / r.x, 2.0))) * r.y) + 1
		if (x % 3) != 0:
			_px(img, x, y, "k2")


## One eye at `c` (its centre), `w` x `h`; `tilt` raises the inner corners (+, worried, sad) or
## lowers them (-, determined); `lid` cuts the top (0..1); `smile` draws a closed,
## happy arc instead; `shine` adds the gleam.
func _eye(img: Image, c: Vector2, w: float, h: float, tilt := 0.0, lid := 0.0, smile := false, inner_right := true,
		shine := true, look := Vector2.ZERO) -> void:
	if smile:
		for i in int(w) + 1:
			var x := c.x - w / 2.0 + i
			var dy := -absf(sin((float(i) / w) * PI)) * h * 0.35
			_px(img, int(x), int(c.y + dy), "eye")
			_px(img, int(x), int(c.y + dy + 1), "eye2")
		return
	for y in range(int(c.y - h / 2.0), int(c.y + h / 2.0) + 1):
		for x in range(int(c.x - w / 2.0), int(c.x + w / 2.0) + 1):
			var d := Vector2((x + 0.5 - c.x) / (w / 2.0), (y + 0.5 - c.y) / (h / 2.0))
			if d.length_squared() > 1.0:
				continue
			# the lid: a straight cut, tilted toward the inner or outer corner
			var across := (x + 0.5 - c.x) / (w / 2.0) * (1.0 if inner_right else -1.0)
			var cut := -h / 2.0 + lid * h - tilt * across * h * 0.35
			if y + 0.5 - c.y < cut:
				continue
			_px(img, x, y, "eye2" if d.y > 0.45 else "eye")
	if shine:
		var g := c + Vector2(-w * 0.18, -h * 0.12 + lid * h * 0.4) + look
		_px(img, int(g.x), int(g.y), "shine")
		_px(img, int(g.x) + 1, int(g.y) + int(h * 0.3), "glint")


## A closed eye curving down at its ends, as in weeping (the smile's opposite).
func _shut_eye(img: Image, c: Vector2, w: float, h: float) -> void:
	for i in int(w) + 1:
		var x := c.x - w / 2.0 + i
		var dy := absf(sin((float(i) / w) * PI)) * h * 0.3
		_px(img, int(x), int(c.y + dy), "eye")
		_px(img, int(x), int(c.y + dy - 1), "eye2")


func _tear(img: Image, at: Vector2, length: int) -> void:
	for i in length:
		_px(img, int(at.x), int(at.y) + i, "tear" if i < length - 1 else "shine")


# ------------------------------------------------------------------ Echidna

func _echidna(face: String) -> Image:
	var img := _img()
	var droop := 2 if face == "sad" else 0
	# Cloak and shoulders, the green lining at the collar, a gold clasp
	_shape(img, PackedVector2Array([Vector2(4, 136), Vector2(10, 108), Vector2(22, 94), Vector2(40, 87), Vector2(76, 87),
		Vector2(94, 94), Vector2(104, 108), Vector2(110, 136)]), ["h0", "h1", "h2", "h3"], -0.05)
	_shape(img, PackedVector2Array([Vector2(46, 88), Vector2(70, 88), Vector2(58, 128)]), ["v0", "v1", "v2"], 0.1)
	for f in [[Vector2(30, 98), Vector2(20, 136)], [Vector2(40, 104), Vector2(36, 136)], [Vector2(84, 100), Vector2(92, 136)],
			[Vector2(76, 108), Vector2(78, 136)]]:
		_line(img, f[0], f[1], "h0")
		_line(img, f[0] + Vector2(1, 2), f[1] + Vector2(1, 0), "h3")
	# gold trim down the edges of the lining, and a clasp on a short chain
	_line(img, Vector2(46, 88), Vector2(58, 128), "y1")
	_line(img, Vector2(70, 88), Vector2(58, 128), "y0")
	_ellipse(img, Vector2(58, 95), Vector2(3, 3), "y1")
	_px(img, 57, 94, "y3")
	_px(img, 59, 96, "y0")
	for k in 3:
		_px(img, 52 - k * 2, 93 + k, "y0")
		_px(img, 64 + k * 2, 93 + k, "y0")
	# The face in shadow, a few dark wisps of hair at its sides
	_shadow_face(img, Vector2(58, 72 + droop), Vector2(22, 19))
	for wisp in [[Vector2(38, 62), Vector2(35, 78)], [Vector2(41, 62), Vector2(39, 74)], [Vector2(78, 62), Vector2(82, 76)]]:
		_line(img, wisp[0] + Vector2(0, droop), wisp[1] + Vector2(0, droop), "h0", false)
	# The hat: brim, cone (its tip bent back), the band and buckle
	var b := float(droop)
	_shape(img, PackedVector2Array([Vector2(26, 50 + b), Vector2(88, 50 + b), Vector2(78, 34), Vector2(68, 20), Vector2(58, 10),
		Vector2(46, 5), Vector2(30, 4), Vector2(16, 9), Vector2(10, 16), Vector2(20, 14), Vector2(32, 12), Vector2(44, 16),
		Vector2(46, 28), Vector2(36, 42)]), ["h0", "h1", "h2", "h3", "h4"], 0.05)
	_shape(img, PackedVector2Array([Vector2(2, 58 + b), Vector2(24, 48 + b), Vector2(58, 45 + b), Vector2(92, 48 + b),
		Vector2(112, 57 + b), Vector2(100, 63 + b), Vector2(58, 65 + b), Vector2(14, 63 + b)]), ["h0", "h1", "h2", "h3"], 0.12)
	for x in range(8, 106, 4):
		var y := 59 + droop + int(absf(x - 58) * 0.06)
		_px(img, x, y, "h4")
	_shape(img, PackedVector2Array([Vector2(28, 44 + b), Vector2(86, 44 + b), Vector2(87, 50 + b), Vector2(27, 50 + b)]), ["h0", "h1"], 0.0)
	_shape(img, PackedVector2Array([Vector2(52, 41 + b), Vector2(64, 41 + b), Vector2(64, 51 + b), Vector2(52, 51 + b)]), ["y0", "y1", "y2", "y3"], 0.2)
	_shape(img, PackedVector2Array([Vector2(55, 44 + b), Vector2(61, 44 + b), Vector2(61, 48 + b), Vector2(55, 48 + b)]), ["h0"], 0.0)
	# a patch stitched on the cone, and a little star charm on the brim
	_shape(img, PackedVector2Array([Vector2(64, 24), Vector2(72, 26), Vector2(70, 34), Vector2(62, 32)]), ["h2", "h3"], 0.0)
	for k in 4:
		_px(img, 63 + k * 2, 25 + k / 2, "h4")
	_line(img, Vector2(96, 60 + b), Vector2(97, 68 + b), "y0", false)
	for d in [Vector2(0, -2), Vector2(-2, 0), Vector2(2, 0), Vector2(0, 2), Vector2.ZERO, Vector2(-1, -1), Vector2(1, 1)]:
		_px(img, 97 + int(d.x), 71 + droop + int(d.y), "y2" if d != Vector2.ZERO else "y3")
	# Her eyes
	var ey := 72.0 + droop
	match face:
		"neutral":
			_eye(img, Vector2(56, ey), 7, 10)
			_eye(img, Vector2(71, ey), 7, 10)
		"worried":
			_eye(img, Vector2(56, ey + 1), 7, 10, 0.9, 0.15, false, true)
			_eye(img, Vector2(71, ey + 1), 7, 10, 0.9, 0.15, false, false)
		"determined":
			_eye(img, Vector2(56, ey + 1), 8, 9, -0.9, 0.3, false, true)
			_eye(img, Vector2(71, ey + 1), 8, 9, -0.9, 0.3, false, false)
		"sad":
			_eye(img, Vector2(56, ey + 2), 7, 9, 1.0, 0.45, false, true, true, Vector2(0, 1))
			_eye(img, Vector2(71, ey + 2), 7, 9, 1.0, 0.45, false, false, true, Vector2(0, 1))
			_tear(img, Vector2(73, ey + 6), 4)
		"surprised":
			_eye(img, Vector2(56, ey - 1), 9, 12)
			_eye(img, Vector2(71, ey - 1), 9, 12)
	_outline(img)
	_rims(img)
	return img


# ------------------------------------------------------------------ Nan

func _nan(face: String) -> Image:
	var img := _img()
	# Her dress, then the knitted shawl round her shoulders, a brooch
	_shape(img, PackedVector2Array([Vector2(16, 136), Vector2(24, 104), Vector2(44, 92), Vector2(72, 92), Vector2(92, 104),
		Vector2(100, 136)]), ["d0", "d1", "d2"], 0.0)
	_shape(img, PackedVector2Array([Vector2(6, 136), Vector2(12, 106), Vector2(30, 92), Vector2(46, 88), Vector2(58, 112),
		Vector2(70, 88), Vector2(86, 92), Vector2(104, 106), Vector2(110, 136), Vector2(84, 136), Vector2(58, 120), Vector2(34, 136)]),
		["s0", "s1", "s2", "s3"], 0.0)
	for y in range(92, 136, 3):
		for x in range(8, 110, 4):
			if _filled(img, x + (y / 3) % 2 * 2, y) and img.get_pixel(x + (y / 3) % 2 * 2, y) in [_c("s1"), _c("s2")]:
				_px(img, x + (y / 3) % 2 * 2, y, "s0")
	_ellipse(img, Vector2(58, 112), Vector2(4, 4), "y1")
	_ellipse(img, Vector2(58, 112), Vector2(2, 2), "r2")
	_px(img, 57, 111, "r3")
	# tassels along the shawl's lower edge
	for k in 7:
		var tx := 38 + k * 6
		var ty := 136 - int(absf(tx - 58) * 16.0 / 22.0) - 1
		_line(img, Vector2(tx, ty), Vector2(tx, ty + 4), "s3", false)
	# Face in shadow, under her silver hair and cap
	_shadow_face(img, Vector2(58, 72), Vector2(20, 18))
	_shape(img, PackedVector2Array([Vector2(36, 70), Vector2(34, 54), Vector2(42, 44), Vector2(58, 40), Vector2(74, 44),
		Vector2(82, 54), Vector2(80, 70), Vector2(74, 60), Vector2(58, 56), Vector2(42, 60)]), ["a0", "a1", "a2", "a3"], 0.1)
	for strand in [[Vector2(44, 48), Vector2(40, 62)], [Vector2(54, 44), Vector2(48, 58)], [Vector2(66, 44), Vector2(70, 58)], [Vector2(74, 48), Vector2(78, 62)]]:
		_line(img, strand[0], strand[1], "a1")
	_ellipse(img, Vector2(58, 36), Vector2(11, 8), "a1")
	_ellipse(img, Vector2(57, 35), Vector2(8, 5), "a2")
	_px(img, 54, 32, "a3")
	# the cap's band over the hair
	_shape(img, PackedVector2Array([Vector2(36, 52), Vector2(46, 44), Vector2(70, 44), Vector2(80, 52), Vector2(78, 55), Vector2(58, 49),
		Vector2(38, 55)]), ["c0", "c1", "c2"], 0.1)
	# Her round spectacles catch the light
	var ey := 74.0
	for ex in [55.0, 69.0]:
		for a in 24:
			var p := Vector2(ex, ey) + Vector2.from_angle(a * TAU / 24.0) * Vector2(6.0, 5.0)
			_px(img, int(p.x), int(p.y), "g1")
		_px(img, int(ex) - 3, int(ey) - 4, "g2")
	_line(img, Vector2(61, 73), Vector2(63, 73), "g1", false)
	match face:
		"warm":
			_eye(img, Vector2(55, ey + 1), 6, 6, 0.0, 0.0, true)
			_eye(img, Vector2(69, ey + 1), 6, 6, 0.0, 0.0, true)
		"lost":
			_eye(img, Vector2(56, ey - 1), 4, 5, 0.0, 0.0, false, true, true, Vector2(1, -1))
			_eye(img, Vector2(70, ey), 4, 5, 0.0, 0.0, false, false, true, Vector2(1, -1))
		"sad":
			_eye(img, Vector2(55, ey + 1), 5, 6, 1.0, 0.4, false, true)
			_eye(img, Vector2(69, ey + 1), 5, 6, 1.0, 0.4, false, false)
		"bright":
			_eye(img, Vector2(55, ey), 6, 8)
			_eye(img, Vector2(69, ey), 6, 8)
			_px(img, 48, 66, "shine")
			_px(img, 78, 67, "shine")
	_outline(img)
	_rims(img)
	return img


# ------------------------------------------------------------------ Wren

func _wren(face: String) -> Image:
	var img := _img()
	# A small girl, lower in the frame: her nightdress with a lace collar
	_shape(img, PackedVector2Array([Vector2(18, 136), Vector2(24, 114), Vector2(34, 104), Vector2(48, 97), Vector2(68, 97), Vector2(82, 104), Vector2(92, 114),
		Vector2(98, 136)]), ["n0", "n1", "n2", "n3"], 0.05)
	for x in range(40, 78, 4):
		_ellipse(img, Vector2(x + 2, 102), Vector2(2.5, 2.5), "n3")
		_px(img, x + 2, 104, "n1")
	for f in [[Vector2(42, 108), Vector2(36, 136)], [Vector2(74, 108), Vector2(80, 136)], [Vector2(58, 110), Vector2(58, 136)]]:
		_line(img, f[0], f[1], "n1")
	# Pigtails either side, with crimson ribbons
	for side in [-1, 1]:
		var x0: float = 58.0 + side * 24.0
		_shape(img, PackedVector2Array([Vector2(x0 - 6, 74), Vector2(x0 + 6, 74), Vector2(x0 + 6 + side * 3, 104),
			Vector2(x0 + side * 4, 112), Vector2(x0 - 6 + side * 3, 104)]), ["b0", "b1", "b2", "b3"], 0.05)
		_ellipse(img, Vector2(x0, 76), Vector2(5, 3), "r2")
		_px(img, int(x0) - 2, 75, "r3")
		_px(img, int(x0) + 3, 78, "r1")
	# Face in shadow (a child's: rounder, larger), the hair and fringe over it
	_shadow_face(img, Vector2(58, 76), Vector2(21, 20))
	_shape(img, PackedVector2Array([Vector2(34, 78), Vector2(34, 60), Vector2(42, 50), Vector2(58, 46), Vector2(74, 50),
		Vector2(82, 60), Vector2(82, 78), Vector2(78, 64), Vector2(70, 66), Vector2(62, 63), Vector2(54, 66), Vector2(46, 63),
		Vector2(38, 66)]), ["b0", "b1", "b2", "b3"], 0.05)
	for strand in [[Vector2(46, 52), Vector2(44, 64)], [Vector2(58, 48), Vector2(56, 62)], [Vector2(70, 52), Vector2(72, 64)]]:
		_line(img, strand[0], strand[1], "b0")
	# her hand at her chest, a stub of chalk in it, and a smudge on her cheek
	_ellipse(img, Vector2(84, 126), Vector2(6, 5), "k1")
	_ellipse(img, Vector2(83, 125), Vector2(4, 3), "k2")
	_line(img, Vector2(86, 118), Vector2(89, 124), "n3", false)
	_px(img, 86, 117, "shine")
	_px(img, 72, 86, "n2")
	_px(img, 74, 87, "n3")
	var ey := 78.0
	match face:
		"calm":
			_eye(img, Vector2(56, ey), 8, 11)
			_eye(img, Vector2(71, ey), 8, 11)
		"smile":
			_eye(img, Vector2(56, ey + 1), 8, 8, 0.0, 0.0, true)
			_eye(img, Vector2(71, ey + 1), 8, 8, 0.0, 0.0, true)
		"pleading":
			_eye(img, Vector2(56, ey), 9, 12, 1.0, 0.1, false, true)
			_eye(img, Vector2(71, ey), 9, 12, 1.0, 0.1, false, false)
			_px(img, 53, int(ey) + 2, "glint")
			_px(img, 68, int(ey) + 2, "glint")
			_tear(img, Vector2(52, ey + 7), 3)
		"scared":
			_eye(img, Vector2(56, ey - 1), 10, 13, 0.6, 0.0, false, true, true, Vector2(0, 1))
			_eye(img, Vector2(71, ey - 1), 10, 13, 0.6, 0.0, false, false, true, Vector2(0, 1))
	_outline(img)
	_rims(img)
	return img


# ------------------------------------------------------------------ Ilse

func _ilse(face: String) -> Image:
	var img := _img()
	var bow := 3 if face == "grief" else 0
	# Her robe, the Choir's silver star on it, a pendant on a chain
	_shape(img, PackedVector2Array([Vector2(2, 136), Vector2(8, 106), Vector2(24, 92), Vector2(42, 86), Vector2(74, 86),
		Vector2(92, 92), Vector2(108, 106), Vector2(112, 136)]), ["i0", "i1", "i2", "i3"], 0.0)
	for f in [[Vector2(26, 100), Vector2(14, 136)], [Vector2(40, 98), Vector2(34, 136)], [Vector2(88, 100), Vector2(98, 136)]]:
		_line(img, f[0], f[1], "i0")
	for i in 8:
		var a := i * TAU / 8.0
		_line(img, Vector2(36, 120), Vector2(36, 120) + Vector2.from_angle(a) * (5.0 if i % 2 == 0 else 3.0), "m1")
	_px(img, 36, 120, "m2")
	_line(img, Vector2(48, 90), Vector2(58, 104), "m0", false)
	_line(img, Vector2(68, 90), Vector2(58, 104), "m0", false)
	_ellipse(img, Vector2(58, 106), Vector2(3, 3), "m1")
	_px(img, 57, 105, "m2")
	# The hood, deep, with grey hair showing at its edge; the face in shadow
	var hb := float(bow)
	_shape(img, PackedVector2Array([Vector2(16, 100), Vector2(20, 64 + hb), Vector2(30, 42 + hb), Vector2(46, 30 + hb),
		Vector2(66, 28 + hb), Vector2(84, 36 + hb), Vector2(96, 56 + hb), Vector2(100, 96), Vector2(86, 88), Vector2(80, 70 + hb),
		Vector2(36, 70 + hb), Vector2(30, 90)]), ["i0", "i1", "i2", "i3", "i4"], 0.05)
	_shadow_face(img, Vector2(58, 72 + bow), Vector2(21, 18))
	_shape(img, PackedVector2Array([Vector2(36, 62 + hb), Vector2(44, 52 + hb), Vector2(60, 50 + hb), Vector2(76, 54 + hb),
		Vector2(80, 62 + hb), Vector2(70, 58 + hb), Vector2(58, 56 + hb), Vector2(46, 58 + hb)]), ["a0", "a1", "a2"], 0.0)
	_line(img, Vector2(36, 62 + hb), Vector2(32, 80 + hb), "a1")
	_line(img, Vector2(80, 62 + hb), Vector2(84, 78 + hb), "a0")
	var ey := 74.0 + bow
	match face:
		"pleading":
			_eye(img, Vector2(56, ey), 7, 9, 1.0, 0.25, false, true)
			_eye(img, Vector2(70, ey), 7, 9, 1.0, 0.25, false, false)
			_tear(img, Vector2(53, ey + 5), 4)
		"grief":
			_shut_eye(img, Vector2(56, ey + 1), 7, 7)
			_shut_eye(img, Vector2(70, ey + 1), 7, 7)
			_tear(img, Vector2(70, ey + 3), 6)
			_tear(img, Vector2(55, ey + 3), 5)
		"peace":
			_eye(img, Vector2(56, ey + 1), 7, 6, 0.0, 0.0, true)
			_eye(img, Vector2(70, ey + 1), 7, 6, 0.0, 0.0, true)
	_outline(img)
	_rims(img)
	return img


# ------------------------------------------------------------------ saving

func _save(sprite_name: String, frames: Array) -> void:
	var strip := Image.create(W * frames.size(), H, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		strip.blit_rect(frames[i], Rect2i(0, 0, W, H), Vector2i(i * W, 0))
	strip.save_png(ProjectSettings.globalize_path(OUT + sprite_name + ".png"))
	_sheet.append(strip)


func _save_preview() -> void:
	var w := 0
	var h := 0
	for s in _sheet:
		w = maxi(w, s.get_width())
		h += s.get_height() + 4
	var sheet := Image.create(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("3a3442"))
	var y := 0
	for s in _sheet:
		sheet.blit_rect(s, Rect2i(Vector2i.ZERO, s.get_size()), Vector2i(0, y))
		y += s.get_height() + 4
	sheet.resize(sheet.get_width() * 2, sheet.get_height() * 2, Image.INTERPOLATE_NEAREST)
	sheet.save_png(ProjectSettings.globalize_path(PREVIEW))
