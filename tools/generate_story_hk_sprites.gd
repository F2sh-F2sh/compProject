extends SceneTree

## Makes the pixel sprites for the story reels, staged the way Hollow Knight
## stages its cutscenes (a small figure, something vast and glowing, dark
## layered rock in front):
##   hk_moth          the held moment: a great pale moth whose wings are the
##                    frozen night (3 frames: frozen, kindling, alight)
##   hk_moth_folded   the same, wings folded round itself like a cocoon
##   hk_chain_link    one iron link of the four chains
##   hk_chain_plate   a word plate on a chain (4 frames: ICE, FREEZE, SELF,
##                    PERSIST, each with its own carved mark)
##   hk_ilse_kneel    Ilse kneeling at the bed, holding on (3 frames: holding,
##                    breathing, her hand opening as she looks up)
##   hk_ornament      the small filigree over and under a lore card
##   hk_stalactites, hk_rocks, hk_crystals, hk_arch, hk_pillar, hk_grass,
##   hk_mountain (the monastery and its bell tower on the summit), hk_roofs
##   (Lowbell's roofline), hk_dome (the rim of the Eye's dome): near-black
##   silhouettes with a faint cold rim, for the near and far layers
## Drawn at 1x (the reels show them 2-6x), dark outline, lit from the top left.
##   godot --headless --path . --script res://tools/generate_story_hk_sprites.gd

const OUT := "res://assets/sprites/story/"
const PREVIEW := "user://hk_sprites_preview.png"

const C := {
	"k0": "05060c", "k1": "0b0d18", "k2": "141a2c", "k3": "1f2740", "k4": "2e3a5c", "rim": "3e4c74",
	# bone and frost
	"b0": "8c8aa4", "b1": "c4c2d6", "b2": "e8e6f2", "b3": "fbfaff",
	"f0": "1a2a4a", "f1": "2c4a78", "f2": "4f7cb0", "f3": "8fbce4", "f4": "d0ecff",
	# the frozen night on the wings
	"n0": "0e1428", "n1": "18213c", "n2": "243256",
	# warm light
	"w0": "5a2410", "w1": "a8461a", "w2": "e07a2a", "w3": "ffb456", "w4": "ffe2a4", "w5": "fff6e0",
	# Ilse's robe
	"r0": "1c1630", "r1": "2e2650", "r2": "4a3c78", "r3": "6a5aa0",
	# crystal
	"c0": "1c3450", "c1": "3a6a96", "c2": "7ab4dc", "c3": "c8eaff",
	# iron
	"i0": "16141e", "i1": "2a2836", "i2": "48465c", "i3": "6e6a8a",
	# chalk / gold for the ornament
	"g0": "8a7448", "g1": "d8bf86", "g2": "f6e8c4",
}

var _previews: Array = []
var _started := false
var rng := RandomNumberGenerator.new()


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	rng.seed = 4242
	_save("hk_moth", [_moth(0), _moth(1), _moth(2)])
	_save("hk_moth_folded", [_moth_folded()])
	_save("hk_chain_link", [_chain_link()])
	_save("hk_chain_plate", [_plate(0), _plate(1), _plate(2), _plate(3)])
	_save("hk_ilse_kneel", [_ilse_kneel(0), _ilse_kneel(1), _ilse_kneel(2)])
	_save("hk_ornament", [_ornament()])
	_save("hk_stalactites", [_stalactites()])
	_save("hk_rocks", [_rocks()])
	_save("hk_crystals", [_crystals()])
	_save("hk_arch", [_arch()])
	_save("hk_pillar", [_pillar()])
	_save("hk_grass", [_grass()])
	_save("hk_mountain", [_mountain()])
	_save("hk_roofs", [_roofs()])
	_save("hk_dome", [_dome()])
	_save_preview()
	print("HK SPRITES DONE")
	quit()


# ------------------------------------------------------------------ helpers

func _c(key: String) -> Color:
	return Color(C[key])


func _img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


func _px(img: Image, x: int, y: int, key: String) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, _c(key))


func _pxc(img: Image, x: int, y: int, col: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, col)


func _rect(img: Image, x: int, y: int, w: int, h: int, key: String) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, _c(key))


func _filled(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and img.get_pixel(x, y).a > 0.0


## Fills a polygon (points in image pixels) with `paint(x, y) -> Color`.
func _poly(img: Image, pts: PackedVector2Array, paint: Callable) -> void:
	var lo := pts[0]
	var hi := pts[0]
	for p in pts:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	for y in range(int(lo.y), int(hi.y) + 1):
		for x in range(int(lo.x), int(hi.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				var col: Color = paint.call(x, y)
				if col.a > 0.0:
					_pxc(img, x, y, col)


func _ellipse(img: Image, c: Vector2, r: Vector2, key: String) -> void:
	for y in range(int(c.y - r.y) - 1, int(c.y + r.y) + 2):
		for x in range(int(c.x - r.x) - 1, int(c.x + r.x) + 2):
			var d := Vector2((x + 0.5 - c.x) / r.x, (y + 0.5 - c.y) / r.y)
			if d.length_squared() <= 1.0:
				_px(img, x, y, key)


func _line(img: Image, a: Vector2, b: Vector2, key: String, only_on_filled := false) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		if only_on_filled and not _filled(img, int(p.x), int(p.y)):
			continue
		_px(img, int(p.x), int(p.y), key)


## A dark outline round everything drawn.
func _outline(img: Image, key := "k0") -> void:
	var src := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height() and src.get_pixel(p.x, p.y).a > 0.0:
					img.set_pixel(x, y, _c(key))
					break


## A thin cold rim on the top and left edges of a silhouette.
func _rim(img: Image, key := "rim") -> void:
	var src := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a == 0.0:
				continue
			var up := y == 0 or src.get_pixel(x, y - 1).a == 0.0
			var left := x == 0 or src.get_pixel(x - 1, y).a == 0.0
			if up or (left and (x + y) % 2 == 0):
				img.set_pixel(x, y, _c(key))


# ------------------------------------------------------------------ the moth

## 200x120. `stage` 0: frozen (wings of night, frost veins, stars caught in
## them); 1: kindling (light rising from the body along the veins); 2: alight.
func _moth(stage: int) -> Image:
	var img := _img(200, 120)
	var cx := 100.0
	var body_top := Vector2(cx, 44)
	for side in [-1.0, 1.0]:
		# Forewing and hindwing, one side
		var fore := PackedVector2Array([Vector2(cx + side * 4, 42), Vector2(cx + side * 30, 22), Vector2(cx + side * 70, 10),
			Vector2(cx + side * 96, 18), Vector2(cx + side * 90, 36), Vector2(cx + side * 70, 58), Vector2(cx + side * 34, 66), Vector2(cx + side * 6, 60)])
		var hind := PackedVector2Array([Vector2(cx + side * 6, 60), Vector2(cx + side * 40, 66), Vector2(cx + side * 62, 80),
			Vector2(cx + side * 58, 100), Vector2(cx + side * 40, 112), Vector2(cx + side * 20, 104), Vector2(cx + side * 6, 84)])
		for wing in [fore, hind]:
			_poly(img, wing, func(x: int, y: int) -> Color:
				var d := Vector2(x, y).distance_to(body_top) / 100.0
				return _wing_colour(stage, d, x, y))
		# Veins from the body out to the margin
		for tip in [Vector2(cx + side * 92, 20), Vector2(cx + side * 80, 40), Vector2(cx + side * 60, 58), Vector2(cx + side * 56, 94), Vector2(cx + side * 36, 108), Vector2(cx + side * 62, 14)]:
			var a := Vector2(cx + side * 6, 52)
			var mid := a.lerp(tip, 0.5) + Vector2(0, -6 if tip.y < 50 else 6)
			for seg in [[a, mid], [mid, tip]]:
				_line(img, seg[0], seg[1], _vein_key(stage, seg[0] == a), true)
		# The moon on each forewing
		_ring(img, Vector2(cx + side * 58, 32), 7.0, "f3" if stage == 0 else ("w3" if stage == 2 else "f2"))
	# The margin of the wings, a lighter band
	_wing_margin(img, stage)
	# Body: a segmented abdomen and a furred thorax
	for y in range(46, 106):
		var t := (y - 46) / 60.0
		var half := int(lerpf(8.0, 2.0, t * t))
		for x in range(int(cx) - half, int(cx) + half + 1):
			var key := "b1" if x < cx else "b0"
			if (y - 46) % 7 == 0:
				key = "b0"
			if stage == 2 and absf(x - cx) < half - 1:
				key = "w4" if (y - 46) % 7 != 0 else "w3"
			_px(img, x, y, key)
	_ellipse(img, Vector2(cx, 48), Vector2(10, 8), "b2")
	# Head: a white mask with two hollow eyes
	_ellipse(img, Vector2(cx, 30), Vector2(12, 11), "b2")
	_ellipse(img, Vector2(cx - 1, 28), Vector2(10, 8), "b3")
	_ellipse(img, Vector2(cx - 5, 31), Vector2(3.4, 4.6), "k0")
	_ellipse(img, Vector2(cx + 5, 31), Vector2(3.4, 4.6), "k0")
	# Feathered antennae
	for side in [-1.0, 1.0]:
		var a := Vector2(cx + side * 5, 20)
		var b := Vector2(cx + side * 24, 3)
		_line(img, a, b, "b1")
		for k in range(1, 6):
			var p := a.lerp(b, k / 6.0)
			_line(img, p, p + Vector2(side * -3, -3), "b0")
			_line(img, p, p + Vector2(side * 3, 1), "b0")
	_outline(img)
	return img


func _wing_colour(stage: int, d: float, x: int, y: int) -> Color:
	var night := _c("n1").lerp(_c("n2"), clampf(1.0 - d, 0.0, 1.0))
	if (x * 7 + y * 13) % 53 == 0:
		night = _c("f4")
	elif (x * 5 + y * 11) % 37 == 0:
		night = _c("f2")
	match stage:
		0:
			return night
		1:
			var warm := clampf(1.0 - d * 1.6, 0.0, 1.0)
			return night.lerp(_c("w2"), warm * 0.85)
		_:
			var glow := _c("w4").lerp(_c("w2"), clampf(d * 1.1, 0.0, 1.0))
			if (x * 7 + y * 13) % 53 == 0:
				glow = _c("w5")
			return glow


func _vein_key(stage: int, near: bool) -> String:
	match stage:
		0:
			return "f3"
		1:
			return "w3" if near else "f3"
	return "w5"


func _ring(img: Image, c: Vector2, r: float, key: String) -> void:
	for a in 48:
		var p := c + Vector2.from_angle(a / 48.0 * TAU) * r
		if _filled(img, int(p.x), int(p.y)):
			_px(img, int(p.x), int(p.y), key)


func _wing_margin(img: Image, stage: int) -> void:
	var src := img.duplicate() as Image
	var key := "f1" if stage == 0 else ("w1" if stage == 1 else "w3")
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a == 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x < 0 or p.y < 0 or p.x >= img.get_width() or p.y >= img.get_height() or src.get_pixel(p.x, p.y).a == 0.0:
					img.set_pixel(x, y, _c(key))
					break


## 90x120: wings folded round the body like a cocoon.
func _moth_folded() -> Image:
	var img := _img(90, 120)
	var cx := 45.0
	for side in [-1.0, 1.0]:
		var wing := PackedVector2Array([Vector2(cx, 26), Vector2(cx + side * 22, 30), Vector2(cx + side * 40, 60),
			Vector2(cx + side * 36, 98), Vector2(cx + side * 18, 116), Vector2(cx, 112)])
		_poly(img, wing, func(x: int, y: int) -> Color:
			var d := absf(x - cx) / 40.0
			var col := _c("n2").lerp(_c("n1"), d)
			if (x * 7 + y * 13) % 41 == 0:
				col = _c("f4")
			return col)
		for k in 4:
			_line(img, Vector2(cx + side * 2, 34 + k * 18), Vector2(cx + side * (30 - k * 3), 54 + k * 16), "f2", true)
	_line(img, Vector2(cx, 28), Vector2(cx, 112), "f1")
	_ellipse(img, Vector2(cx, 18), Vector2(10, 9), "b2")
	_ellipse(img, Vector2(cx - 4, 19), Vector2(2.6, 3.6), "k0")
	_ellipse(img, Vector2(cx + 4, 19), Vector2(2.6, 3.6), "k0")
	for side in [-1.0, 1.0]:
		_line(img, Vector2(cx + side * 4, 10), Vector2(cx + side * 16, 1), "b1")
	_outline(img)
	return img


# ------------------------------------------------------------------ chains

func _chain_link() -> Image:
	var img := _img(8, 12)
	for y in 12:
		for x in 8:
			var d := Vector2((x + 0.5 - 4.0) / 4.0, (y + 0.5 - 6.0) / 6.0).length()
			if d <= 1.0 and d >= 0.55:
				_px(img, x, y, "i3" if x < 4 and y < 6 else ("i2" if x < 5 else "i1"))
	return img


## 22x18: an iron plate with the word's mark carved and frost in the cuts.
func _plate(word: int) -> Image:
	var img := _img(22, 18)
	_rect(img, 1, 1, 20, 16, "i2")
	_rect(img, 1, 1, 20, 1, "i3")
	_rect(img, 1, 16, 20, 1, "i1")
	_rect(img, 3, 3, 16, 12, "i1")
	var marks := [
		[Vector2(11, 4), Vector2(11, 13), Vector2(7, 6), Vector2(15, 11), Vector2(15, 6), Vector2(7, 11)],   # ICE: a snowflake
		[Vector2(5, 9), Vector2(17, 9), Vector2(8, 5), Vector2(14, 13), Vector2(14, 5), Vector2(8, 13)],      # FREEZE: crossed bars
		[Vector2(11, 4), Vector2(11, 13), Vector2(7, 9), Vector2(15, 9)],                                    # SELF: a cross in a ring
		[Vector2(6, 5), Vector2(16, 5), Vector2(16, 5), Vector2(16, 13), Vector2(16, 13), Vector2(6, 13), Vector2(6, 13), Vector2(6, 5)],  # PERSIST: a closed square
	]
	var m: Array = marks[word]
	for i in range(0, m.size(), 2):
		_line(img, m[i], m[i + 1], "f3")
	if word == 2:
		_ring(img, Vector2(11, 9), 4.0, "f3")
	_outline(img)
	return img


# ------------------------------------------------------------------ Ilse

## 24x22: kneeling, her robe pooled, reaching right to hold a hand on the bed.
## `frame` 0 holding, 1 breathing, 2 her hand opening, looking up.
func _ilse_kneel(frame: int) -> Image:
	var img := _img(24, 22)
	var bob := 1 if frame == 1 else 0
	# Robe pooled on the floor
	_poly(img, PackedVector2Array([Vector2(2, 21), Vector2(4, 12 + bob), Vector2(9, 8 + bob), Vector2(14, 10 + bob), Vector2(16, 21)]),
		func(x: int, y: int) -> Color: return _c("r2") if x < 9 else _c("r1"))
	_line(img, Vector2(5, 20), Vector2(14, 20), "r0")
	# Hood and the frost band across her eyes
	var head := Vector2(10, 7 + bob) if frame != 2 else Vector2(10, 5)
	_ellipse(img, head, Vector2(4.2, 4.2), "r1")
	_ellipse(img, head + Vector2(0.5, 0.5), Vector2(3, 3), "k1")
	_line(img, head + Vector2(-3, -1), head + Vector2(3, -1), "f3")
	_px(img, int(head.x) - 1, int(head.y) + 1, "b3")
	_px(img, int(head.x) + 1, int(head.y) + 1, "b3")
	# The arm, reaching to the bed (the hand closed, or open)
	var shoulder := Vector2(13, 12 + bob)
	var hand := Vector2(21, 13) if frame != 2 else Vector2(20, 10)
	_line(img, shoulder, hand, "r2")
	_line(img, shoulder + Vector2(0, 1), hand + Vector2(0, 1), "r1")
	if frame == 2:
		_px(img, int(hand.x) + 1, int(hand.y) - 1, "b2")
		_px(img, int(hand.x) + 2, int(hand.y), "b2")
		_px(img, int(hand.x) + 1, int(hand.y) + 1, "b2")
	else:
		_px(img, int(hand.x) + 1, int(hand.y), "b2")
		_px(img, int(hand.x) + 1, int(hand.y) + 1, "b1")
	# The pendant
	_px(img, 9, 13 + bob, "f3")
	_outline(img)
	return img


# ------------------------------------------------------------------ the lore card

## 120x9: a thin filigree line with a diamond and two curls.
func _ornament() -> Image:
	var img := _img(120, 9)
	for x in range(8, 112):
		var fade := 1.0 - absf(x - 60.0) / 52.0
		if fade > 0.08:
			_pxc(img, x, 4, _c("g1").lerp(_c("g0"), 1.0 - fade))
	for k in 4:
		_px(img, 60 - k, 4 - k, "g2")
		_px(img, 60 + k, 4 - k, "g2")
		_px(img, 60 - k, 4 + k, "g2")
		_px(img, 60 + k, 4 + k, "g2")
	_px(img, 60, 4, "g2")
	for side in [-1, 1]:
		for k in 5:
			var a := k / 5.0 * PI
			_px(img, 60 + side * (14 + int(cos(a) * 3)), 4 + int(sin(a) * 3), "g1")
		_px(img, 60 + side * 50, 4, "g1")
		_px(img, 60 + side * 52, 3, "g0")
	return img


# ------------------------------------------------------------------ silhouettes

func _sil(x: int, y: int) -> Color:
	return _c("k1") if (x * 3 + y) % 11 else _c("k2")


## 200x70: stalactites hanging from a ceiling band.
func _stalactites() -> Image:
	var img := _img(200, 70)
	_rect(img, 0, 0, 200, 10, "k1")
	var x := 0
	while x < 200:
		var w := rng.randi_range(8, 22)
		var h := rng.randi_range(18, 68)
		_poly(img, PackedVector2Array([Vector2(x, 9), Vector2(x + w, 9), Vector2(x + w * 0.55, h)]), _sil)
		x += w - rng.randi_range(0, 4)
	_rim(img)
	return img


## 200x56: a broken ground of rocks, for the near layer.
func _rocks() -> Image:
	var img := _img(200, 56)
	var x := -6
	while x < 206:
		var w := rng.randi_range(18, 40)
		var h := rng.randi_range(16, 52)
		var pts := PackedVector2Array([Vector2(x, 56), Vector2(x + w * 0.1, 56 - h * 0.7), Vector2(x + w * 0.4, 56 - h),
			Vector2(x + w * 0.8, 56 - h * 0.8), Vector2(x + w, 56)])
		_poly(img, pts, _sil)
		x += w - rng.randi_range(4, 10)
	_rim(img)
	return img


## 70x60: a cluster of crystals, glinting a cold blue.
func _crystals() -> Image:
	var img := _img(70, 60)
	var specs := [[22, 60, 8, 50, -0.25], [34, 60, 10, 58, 0.0], [46, 60, 8, 44, 0.3], [14, 60, 6, 30, -0.5], [56, 60, 7, 30, 0.55]]
	for s in specs:
		var base := Vector2(s[0], s[1])
		var dir := Vector2(sin(s[4]), -cos(s[4]))
		var tip := base + dir * float(s[3])
		var side := Vector2(-dir.y, dir.x) * float(s[2]) * 0.5
		var pts := PackedVector2Array([base - side, base - side + dir * s[3] * 0.8, tip, base + side + dir * s[3] * 0.8, base + side])
		_poly(img, pts, func(x: int, y: int) -> Color:
			var on_left := (Vector2(x, y) - base).dot(side) < 0.0
			return _c("c1") if on_left else _c("c0"))
		_line(img, base + dir * 2.0, tip, "c2")
	_outline(img)
	return img


## 140x120: a broken stone arch.
func _arch() -> Image:
	var img := _img(140, 120)
	for leg in [[6, 26], [110, 130]]:
		_rect(img, leg[0], 40, leg[1] - leg[0], 80, "k1")
	_ring_fill(img, Vector2(70, 46), Vector2(64, 46), Vector2(44, 28), func(t: float) -> bool: return t < 2.15 or t > 2.45)
	# a fallen block
	_rect(img, 84, 104, 20, 16, "k2")
	_rim(img)
	return img


## 34x120: a pillar broken off at the top.
func _pillar() -> Image:
	var img := _img(34, 120)
	_rect(img, 6, 22, 22, 98, "k1")
	_rect(img, 2, 112, 30, 8, "k2")
	_poly(img, PackedVector2Array([Vector2(6, 22), Vector2(12, 12), Vector2(17, 18), Vector2(23, 6), Vector2(28, 22)]), _sil)
	for y in range(30, 110, 10):
		_rect(img, 10, y, 1, 6, "k2")
	_rim(img)
	return img


## 200x26: tall grass and weeds, for the nearest layer.
func _grass() -> Image:
	var img := _img(200, 26)
	_rect(img, 0, 22, 200, 4, "k0")
	for x in range(0, 200, 2):
		var h := rng.randi_range(6, 24)
		var lean := rng.randf_range(-3.0, 3.0)
		_line(img, Vector2(x, 25), Vector2(x + lean, 25 - h), "k0")
	return img


## 320x150: the mountain, the monastery on its summit and the bell tower.
func _mountain() -> Image:
	var img := _img(320, 150)
	_poly(img, PackedVector2Array([Vector2(0, 150), Vector2(40, 120), Vector2(90, 96), Vector2(130, 70), Vector2(160, 56),
		Vector2(196, 64), Vector2(230, 86), Vector2(280, 112), Vector2(320, 130), Vector2(320, 150)]),
		func(x: int, y: int) -> Color: return _c("k3") if (x * 7 + y * 13) % 29 == 0 else _c("k2"))
	# The monastery: halls, roofs, the bell tower with its open belfry
	_rect(img, 132, 40, 56, 22, "k1")
	_poly(img, PackedVector2Array([Vector2(130, 40), Vector2(160, 28), Vector2(190, 40)]), _sil)
	_rect(img, 150, 8, 14, 34, "k1")
	_poly(img, PackedVector2Array([Vector2(148, 8), Vector2(157, -2), Vector2(166, 8)]), _sil)
	_rect(img, 153, 14, 8, 8, "k3")
	_rect(img, 118, 48, 14, 14, "k1")
	_rect(img, 188, 46, 12, 16, "k1")
	_rim(img)
	return img


## 320x64: Lowbell's roofline: roofs, chimneys, the chime post.
func _roofs() -> Image:
	var img := _img(320, 64)
	var x := 0
	while x < 320:
		var w := rng.randi_range(30, 56)
		var h := rng.randi_range(22, 40)
		_rect(img, x, 64 - h, w, h, "k1")
		_poly(img, PackedVector2Array([Vector2(x - 3, 64 - h), Vector2(x + w * 0.5, 64 - h - rng.randi_range(10, 18)), Vector2(x + w + 3, 64 - h)]), _sil)
		if rng.randf() < 0.6:
			_rect(img, x + int(w * 0.7), 64 - h - 14, 5, 12, "k1")
		x += w + rng.randi_range(2, 10)
	_rect(img, 210, 18, 2, 46, "k1")
	_rect(img, 204, 18, 14, 2, "k1")
	_rim(img)
	return img


## 320x130: the rim of the Eye's dome, a great arc of stone with ribs.
func _dome() -> Image:
	var img := _img(320, 130)
	_ring_fill(img, Vector2(160, 130), Vector2(160, 129), Vector2(146, 114), func(_t: float) -> bool: return true)
	# Ribs reaching in from the rim
	for k in 9:
		var t := (k + 0.5) / 9.0 * PI
		for w in [-1, 0, 1]:
			_line(img, Vector2(160 + w, 130) + Vector2(-cos(t) * 146, -sin(t) * 114),
				Vector2(160 + w, 130) + Vector2(-cos(t) * 122, -sin(t) * 94), "k1")
	_rim(img)
	return img


## Fills the band between two half-ellipses (centre `c`, outer and inner
## radii) above the centre, where `keep(angle)` (0 at the left, PI at the
## right) says so.
func _ring_fill(img: Image, c: Vector2, outer: Vector2, inner: Vector2, keep: Callable) -> void:
	for y in range(int(c.y - outer.y) - 1, int(c.y) + 1):
		for x in range(int(c.x - outer.x) - 1, int(c.x + outer.x) + 2):
			var p := Vector2(x + 0.5, y + 0.5) - c
			if p.y > 0.0:
				continue
			var o := (p.x / outer.x) * (p.x / outer.x) + (p.y / outer.y) * (p.y / outer.y)
			var i := (p.x / inner.x) * (p.x / inner.x) + (p.y / inner.y) * (p.y / inner.y)
			if o <= 1.0 and i >= 1.0 and keep.call(PI - atan2(-p.y, p.x)):
				_pxc(img, x, y, _sil(x, y))


# ------------------------------------------------------------------ saving

func _save(sprite_name: String, frames: Array) -> void:
	var w: int = frames[0].get_width()
	var h: int = frames[0].get_height()
	var strip := _img(w * frames.size(), h)
	for i in frames.size():
		strip.blit_rect(frames[i], Rect2i(0, 0, w, h), Vector2i(i * w, 0))
	var err := strip.save_png(ProjectSettings.globalize_path(OUT + sprite_name + ".png"))
	if err != OK:
		push_error("could not save %s: %d" % [sprite_name, err])
	_previews.append(strip)


## Everything stacked at 2x on a dusk blue, to look at.
func _save_preview() -> void:
	var gap := 8
	var w := 0
	var h := gap
	for p in _previews:
		w = maxi(w, p.get_width() * 2 + gap * 2)
		h += p.get_height() * 2 + gap
	var sheet := _img(w, h)
	sheet.fill(Color("3a4566"))
	var y := gap
	for p: Image in _previews:
		var big := p.duplicate() as Image
		big.resize(p.get_width() * 2, p.get_height() * 2, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(gap, y))
		y += big.get_height() + gap
	sheet.save_png(ProjectSettings.globalize_path(PREVIEW))
