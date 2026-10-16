extends SceneTree

## Makes the pixel sprites for the Kilnworks (the Cold Forge and the Landing):
##   great_kiln      the Great Kiln's body, 320x260 (cold with frost, roaring)
##   kiln_chimney    its chimney stack (cold, hot)
##   lamp_fuel / lamp_air / lamp_fire   the kiln's three gauge lamps (dark, lit)
##   coal_cart       the Smith's coal tub (a wind-moved crate)
##   slag            a tile of molten slag (4 frames, bubbling)
##   slag_crust      a plug of cooled slag over a niche (a cracked wall)
##   forge_door      the iron Forge Door (frosted, warm)
##   bellows, anvil, tool_rack, coal_heap    the forge's furniture
##   smith_plaque    the Smith's carving: flame, coal and wind into the kiln
##   chalk_steps, chalk_route, chalk_star    Wren's chalk marks
##   frost_a, frost_b    the Hush's frost on a wall (it melts when the kiln roars)
##   door_frost      rime over a sealed door on the Landing
## Drawn at 1x for the dungeon (the camera shows it at 2x), lit from the top
## left with a dark outline, in the dungeon's purples with the forge's own
## soot-brown bricks, iron, fire and frost. Saved as PNG strips in
## res://assets/sprites/story/ (SurfaceArt.STRIPS lists their frame counts).
## Re-run after editing:
##   godot --headless --path . --script res://tools/art/generate_kiln_sprites.gd

const OUT := "res://assets/sprites/story/"
const PREVIEW := "user://kiln_sprites_preview.png"

const C := {
	# iron
	"i0": "0e0c16", "i1": "1c1a28", "i2": "2b2a3a", "i3": "45435a", "i4": "6e6a8c", "i5": "9a96b8",
	# sooty forge brick
	"b0": "1a0f12", "b1": "2e1a1c", "b2": "4a2a28", "b3": "6a3c32", "b4": "8a5240", "b5": "a86a4e",
	# mortar and dungeon stone
	"m0": "16121c", "m1": "241c26", "s1": "3a3346", "s2": "544a62", "s3": "6e6480", "s4": "8a80a0",
	# fire
	"f0": "5a1a10", "f1": "a8341a", "f2": "e0641e", "f3": "ff9a2e", "f4": "ffd060", "f5": "fff2b8",
	# frost
	"r0": "5f7fb8", "r1": "a6c8f0", "r2": "d8ecff", "r3": "f4fbff",
	# wood and leather
	"w0": "1e130e", "w1": "3a2418", "w2": "5a3a24", "w3": "7a5434", "w4": "9a7048",
	# coal
	"c0": "0c0b10", "c1": "1c1b24", "c2": "2e2c3a", "c3": "4a4860", "c4": "6a6884",
	# chalk
	"k0": "8890b0", "k1": "b8c0d8", "k2": "e4e8f4",
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
	rng.seed = 4071
	_save("great_kiln", [_kiln(false), _kiln(true)])
	_save("kiln_chimney", [_chimney(false), _chimney(true)])
	_save("lamp_fuel", [_lamp("fuel", false), _lamp("fuel", true)])
	_save("lamp_air", [_lamp("air", false), _lamp("air", true)])
	_save("lamp_fire", [_lamp("fire", false), _lamp("fire", true)])
	_save("coal_cart", [_coal_cart()])
	_save("slag", [_slag(0), _slag(1), _slag(2), _slag(3)])
	_save("slag_crust", [_slag_crust()])
	_save("forge_door", [_forge_door(true), _forge_door(false)])
	_save("bellows", [_bellows()])
	_save("anvil", [_anvil()])
	_save("tool_rack", [_tool_rack()])
	_save("coal_heap", [_coal_heap()])
	_save("smith_plaque", [_smith_plaque()])
	_save("chalk_steps", [_chalk_steps()])
	_save("chalk_route", [_chalk_route()])
	_save("chalk_star", [_chalk_star()])
	_save("frost_a", [_frost(64, 40, 11)])
	_save("frost_b", [_frost(48, 56, 23)])
	_save("door_frost", [_door_frost()])
	_save("heart_crucible", [_heart_crucible(false), _heart_crucible(true)])
	_save_preview()
	print("KILN SPRITES DONE")
	quit()


# ------------------------------------------------------------------ helpers

func _c(key: String) -> Color:
	return Color(C[key])


func _img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


func _rect(img: Image, x: int, y: int, w: int, h: int, key: String) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, _c(key))


func _px(img: Image, x: int, y: int, key: String) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, _c(key))


func _at(img: Image, x: int, y: int) -> Color:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		return img.get_pixel(x, y)
	return Color(0, 0, 0, 0)


## A dark outline round everything drawn so far (1 px, outside the shape).
func _outline(img: Image, key := "i0") -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := img.duplicate()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and src.get_pixel(q.x, q.y).a > 0.5:
					img.set_pixel(x, y, _c(key))
					break


## Paints a small map (rows of two-letter keys separated by spaces, ".." clear).
func _stamp(img: Image, x: int, y: int, rows: Array) -> void:
	for r in rows.size():
		var cells: PackedStringArray = (rows[r] as String).split(" ", false)
		for c in cells.size():
			if cells[c] != "..":
				_px(img, x + c, y + r, cells[c])


## A course of bricks: brick w x h with 1 px mortar, offset every other row.
func _bricks(img: Image, x0: int, y0: int, w: int, h: int, bw: int, bh: int, keys: Array, mortar: String, seed_v: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	_rect(img, x0, y0, w, h, mortar)
	var row := 0
	var y := y0
	while y < y0 + h:
		var off := 0 if row % 2 == 0 else bw / 2
		var x := x0 - off
		while x < x0 + w:
			var bx := maxi(x, x0)
			var ex := mini(x + bw - 1, x0 + w)
			var by := y
			var ey := mini(y + bh - 1, y0 + h)
			if ex > bx and ey > by:
				var k: String = keys[r.randi_range(0, keys.size() - 1)]
				_rect(img, bx, by, ex - bx, ey - by, k)
				# a lit top edge and a darker bottom edge on each brick
				var light: String = keys[mini(keys.find(k) + 1, keys.size() - 1)]
				_rect(img, bx, by, ex - bx, 1, light)
				if r.randf() < 0.25:
					_px(img, bx + r.randi_range(1, maxi(ex - bx - 2, 1)), by + r.randi_range(1, maxi(ey - by - 1, 1)), mortar)
			x += bw
		y += bh
		row += 1


## A row of rivets along a band.
func _rivets(img: Image, x0: int, x1: int, y: int, step: int) -> void:
	var x := x0
	while x <= x1:
		_px(img, x, y, "i5")
		_px(img, x + 1, y, "i4")
		_px(img, x, y + 1, "i3")
		_px(img, x + 1, y + 1, "i1")
		x += step


## An iron band across: dark under, light on top, with rivets.
func _band(img: Image, x0: int, w: int, y: int, h := 4) -> void:
	_rect(img, x0, y, w, h, "i2")
	_rect(img, x0, y, w, 1, "i4")
	_rect(img, x0, y + h - 1, w, 1, "i1")
	_rivets(img, x0 + 4, x0 + w - 6, y + 1, 12)


## An arched opening: dark inside, framed by stone voussoirs.
func _arch(img: Image, x0: int, y0: int, w: int, h: int, inside: String) -> void:
	var r := w / 2.0
	var cx := x0 + w / 2.0
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			var dy := float(y - (y0 + r))
			var inside_arch := y >= y0 + r or (pow(x + 0.5 - cx, 2) + pow(dy, 2) <= r * r)
			if inside_arch:
				_px(img, x, y, inside)
	# stone ring around the arch
	for a in range(0, 181, 3):
		var ang := deg_to_rad(180.0 + a)
		for k in [r + 1.0, r + 2.0, r + 3.0]:
			var px := int(round(cx - 0.5 + cos(ang) * k))
			var py := int(round(y0 + r + sin(ang) * k))
			_px(img, px, py, "s2" if k < r + 2.5 else "s1")
	_rect(img, x0 - 3, y0 + int(r), 3, h - int(r), "s2")
	_rect(img, x0 + w, y0 + int(r), 3, h - int(r), "s1")


# ------------------------------------------------------------------ the Great Kiln

## The kiln, 320x260: the body below under a roof slab 4 px thicker, so its
## walkable top is flush with a floating ledge beside it (ledges stand at
## row * 64 + 18, which is 260 above the floor).
func _kiln(hot: bool) -> Image:
	var body := _kiln_body(hot)
	var w := body.get_width()
	var img := _img(w, body.get_height() + 4)
	img.blit_rect(body, Rect2i(0, 0, w, body.get_height()), Vector2i(0, 4))
	_rect(img, 0, 0, w, 6, "s2")
	_rect(img, 0, 0, w, 2, "s4")
	for x in range(17, w, 22):
		_px(img, x, 3, "s1")
	_outline_box(img)
	return img


## The kiln's body, 320x256. Left: the air pipe's mouth (the inlet, y 114-202).
## Right, at the bottom: the fuel bay (x 256-320, y 192-256). Front: the fire
## mouth behind its grate. Three lamp sockets above the mouth (the lamps are
## their own sprites). Cold: frost on the lip and openings, dark inside. Hot:
## the mortar glows near the fire, the mouth and pipe burn.
func _kiln_body(hot: bool) -> Image:
	var w := 320
	var h := 256
	var img := _img(w, h)
	# The brick body
	_bricks(img, 0, 8, w, 236, 16, 8, ["b1", "b2", "b3", "b2", "b3"], "m0", 91)
	# Stone pilasters at the corners and a stone base course
	for px0 in [0, w - 18]:
		_bricks(img, px0, 8, 18, 236, 18, 12, ["s1", "s2", "s1"], "m0", 17 + px0)
		_rect(img, px0, 8, 1, 236, "s3" if px0 == 0 else "m0")
	_bricks(img, 0, 240, w, 16, 24, 8, ["s1", "s2"], "m0", 33)
	_rect(img, 0, 240, w, 1, "s3")
	# The roof lip: a slab with a lit top (the walkable top of the kiln)
	_rect(img, 0, 0, w, 9, "s2")
	_rect(img, 0, 0, w, 2, "s4")
	_rect(img, 0, 7, w, 2, "m1")
	for x in range(6, w, 22):
		_px(img, x, 4, "s1")
		_px(img, x + 1, 5, "s1")
	# Iron bands
	_band(img, 18, w - 36, 54, 5)
	_band(img, 18, w - 36, 132, 5)
	# The fire mouth: an arch with a grate
	_arch(img, 112, 172, 96, 68, "i0")
	if hot:
		# Fire behind the bars: white-hot at the bottom, orange above
		for y in range(178, 240):
			for x in range(116, 204):
				if _at(img, x, y) == _c("i0"):
					var t := float(y - 178) / 62.0
					var k := "f2" if t < 0.35 else ("f3" if t < 0.7 else ("f4" if t < 0.9 else "f5"))
					if rng.randf() < 0.18:
						k = "f3" if k == "f2" else "f4"
					_px(img, x, y, k)
	else:
		# A cold, dark firebox with grey ash on its floor
		_rect(img, 118, 232, 84, 8, "c1")
		for x in range(120, 200, 3):
			_px(img, x, 231, "c2")
	for x in range(118, 204, 8):
		_rect(img, x, 180, 3, 60, "i2")
		_rect(img, x, 180, 1, 60, "i4")
	_rect(img, 112, 236, 96, 4, "i2")
	_rect(img, 112, 236, 96, 1, "i4")
	# The air pipe's mouth on the left (the inlet): an iron collar round a dark tunnel
	_rect(img, 0, 114, 30, 88, "i0")
	for y in range(110, 206):
		for x in range(0, 34):
			var on_ring := (y < 114 or y >= 202 or x >= 30) and x < 34 and y >= 110 and y < 206
			if on_ring:
				_px(img, x, y, "i3" if (y < 112 or x == 30) else "i2")
	_rect(img, 0, 110, 34, 1, "i4")
	_rivets(img, 2, 30, 111, 7)
	_rivets(img, 2, 30, 203, 7)
	if hot:
		for y in range(118, 198):
			for x in range(0, 30):
				var t := float(x) / 30.0
				_px(img, x, y, "f1" if t < 0.4 else ("f2" if t < 0.75 else "f3"))
	# The fuel bay on the right, at the bottom: an iron-framed arch
	_arch(img, 262, 196, 54, 44, "i0")
	if hot:
		_rect(img, 266, 226, 46, 14, "f1")
		for x in range(266, 312, 4):
			_px(img, x + 1, 225, "f3")
			_px(img, x, 227, "f4")
	_rect(img, 258, 236, 62, 4, "i2")
	_rect(img, 258, 236, 62, 1, "i4")
	# Three lamp sockets above the mouth
	for lx in [130, 160, 190]:
		for y in range(146, 160):
			for x in range(lx - 7, lx + 7):
				var d := Vector2(x + 0.5 - lx, y + 0.5 - 153).length()
				if d <= 7.0:
					_px(img, x, y, "i2" if d > 5.5 else "i0")
		_px(img, lx - 4, 147, "i4")
	# Soot streaks over the mouth and the pipe
	for i in 40:
		var sx := rng.randi_range(116, 204)
		var sy := rng.randi_range(150, 172)
		_px(img, sx, sy, "b0")
	if hot:
		# Mortar near the fire glows
		for y in range(60, 236):
			for x in range(20, 300):
				if _at(img, x, y) == _c("m0"):
					var d := Vector2(x - 160, (y - 210) * 1.3).length()
					if d < 70:
						_px(img, x, y, "f1" if d > 40 else "f2")
	else:
		# The Hush's frost: crusted on the lip, icicles, rime round the openings
		for x in range(0, w):
			if rng.randf() < 0.55:
				_px(img, x, 9, "r1")
			if rng.randf() < 0.25:
				_px(img, x, 10, "r0")
		for x in range(4, w - 4, 9):
			var n := rng.randi_range(2, 7)
			for k in n:
				_px(img, x, 9 + k, "r2" if k < n - 1 else "r1")
		for i in 160:
			var a := rng.randf() * TAU
			var rr := rng.randf_range(40.0, 52.0)
			_px(img, int(160 + cos(a) * rr), int(206 + sin(a) * rr * 0.75), "r1" if rng.randf() < 0.7 else "r2")
		for i in 90:
			var y := rng.randi_range(104, 210)
			_px(img, rng.randi_range(30, 40), y, "r1" if rng.randf() < 0.6 else "r0")
		for px0 in [0, w - 18]:
			for i in 60:
				_px(img, px0 + rng.randi_range(0, 17), rng.randi_range(10, 240), "r0" if rng.randf() < 0.6 else "r1")
	_outline_box(img)
	return img


## A crisp 1 px dark border round the whole kiln.
func _outline_box(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	_rect(img, 0, 0, w, 1, "i0")
	_rect(img, 0, h - 1, w, 1, "i0")
	_rect(img, 0, 0, 1, 110, "i0")
	_rect(img, 0, 206, 1, h - 206, "i0")
	_rect(img, w - 1, 0, 1, h, "i0")


func _chimney(hot: bool) -> Image:
	var img := _img(56, 80)
	_bricks(img, 6, 12, 44, 68, 12, 6, ["b1", "b2", "b3"], "m0", 51)
	_rect(img, 6, 12, 1, 68, "s3")
	_rect(img, 49, 12, 1, 68, "m0")
	# Iron cap with a lip
	_rect(img, 2, 4, 52, 9, "i2")
	_rect(img, 2, 4, 52, 1, "i4")
	_rect(img, 2, 12, 52, 1, "i1")
	_rivets(img, 6, 48, 7, 8)
	_rect(img, 14, 0, 28, 5, "i0")
	if hot:
		_rect(img, 16, 0, 24, 3, "f3")
		_rect(img, 18, 0, 20, 1, "f5")
		for y in range(20, 78):
			for x in range(8, 48):
				if _at(img, x, y) == _c("m0") and y > 40:
					_px(img, x, y, "f1")
	else:
		for x in range(2, 54):
			if rng.randf() < 0.6:
				_px(img, x, 13, "r1")
		for x in range(4, 52, 7):
			for k in rng.randi_range(2, 6):
				_px(img, x, 13 + k, "r2")
	_outline(img)
	return img


## A gauge lamp: an iron rim round a glass with its sign (coal, wind, flame).
func _lamp(kind: String, lit: bool) -> Image:
	var img := _img(14, 14)
	for y in 14:
		for x in 14:
			var d := Vector2(x + 0.5 - 7, y + 0.5 - 7).length()
			if d <= 6.6:
				_px(img, x, y, "i3" if d > 5.2 else ("f0" if lit else "i1"))
	var ink := "f5" if lit else "i3"
	var mid := "f4" if lit else "i2"
	match kind:
		"fuel":
			_stamp(img, 3, 5, [
				".. AA AA .. .. .. ..".replace("AA", mid),
				"AA BB BB AA .. AA ..".replace("AA", mid).replace("BB", ink),
				"AA BB AA AA AA BB AA".replace("AA", mid).replace("BB", ink),
				".. AA AA BB BB AA ..".replace("AA", mid).replace("BB", ink),
			])
		"air":
			_stamp(img, 3, 4, [
				"BB BB BB BB .. .. ..".replace("BB", ink),
				".. .. .. .. BB .. ..".replace("BB", ink),
				".. BB BB BB BB BB ..".replace("BB", ink),
				".. .. .. .. .. .. BB".replace("BB", ink),
				"BB BB BB BB BB BB ..".replace("BB", ink),
			])
		"fire":
			_stamp(img, 4, 3, [
				".. .. BB .. ..".replace("BB", ink),
				".. .. BB BB ..".replace("BB", ink),
				".. BB AA BB ..".replace("AA", mid).replace("BB", ink),
				"BB BB AA AA BB".replace("AA", mid).replace("BB", ink),
				"BB AA AA AA BB".replace("AA", mid).replace("BB", ink),
				".. BB BB BB ..".replace("BB", ink),
			])
	_outline(img)
	return img


# ------------------------------------------------------------------ the coal cart

## A wooden tub bound in iron, on two small wheels, heaped with coal. 40x40.
func _coal_cart() -> Image:
	var img := _img(40, 40)
	# coal heap above the rim
	for y in range(4, 14):
		for x in range(4, 36):
			var hump := 14 - int(3.0 * sin((x - 4) / 32.0 * PI) + 2.0 * sin((x - 4) / 7.0))
			if y >= hump - 6:
				_px(img, x, y, ["c1", "c2", "c1", "c3"][rng.randi_range(0, 3)])
	for i in 18:
		_px(img, rng.randi_range(6, 33), rng.randi_range(6, 12), "c4")
	# the tub: planks
	_rect(img, 3, 13, 34, 20, "w2")
	for x in range(3, 37, 6):
		_rect(img, x, 13, 1, 20, "w1")
		_rect(img, x + 1, 13, 1, 20, "w3")
	_rect(img, 3, 13, 34, 1, "w4")
	# iron bands
	for y in [15, 27]:
		_rect(img, 2, y, 36, 3, "i2")
		_rect(img, 2, y, 36, 1, "i4")
		_rivets(img, 4, 34, y + 1, 9)
	# wheels
	for wx in [10, 30]:
		for y in range(31, 40):
			for x in range(wx - 5, wx + 5):
				var d := Vector2(x + 0.5 - wx, y + 0.5 - 35).length()
				if d <= 4.6:
					_px(img, x, y, "i3" if d > 3.0 else ("i1" if d > 1.2 else "i4"))
	_outline(img)
	return img


# ------------------------------------------------------------------ slag

## One tile of molten slag: a glowing surface with drifting black crust and
## a bubble that swells and pops over four frames. 64x24.
func _slag(frame: int) -> Image:
	var img := _img(64, 24)
	var r := RandomNumberGenerator.new()
	r.seed = 77
	for y in 24:
		for x in 64:
			var wave := sin((x + frame * 4) / 6.0) * 1.5 + sin((x * 0.7 - frame * 3) / 4.0)
			var t := (y - 3 - wave) / 21.0
			var k := "f4" if t < 0.12 else ("f3" if t < 0.35 else ("f2" if t < 0.65 else "f1"))
			if y < 2 + wave:
				continue
			_px(img, x, y, k)
	# crust plates drifting along
	for i in 6:
		var cx := int(fposmod(r.randi_range(0, 63) + frame * 3, 64))
		var cw := r.randi_range(5, 11)
		var cy := r.randi_range(5, 16)
		for x in range(cx, cx + cw):
			var xx := x % 64
			_px(img, xx, cy, "b0")
			_px(img, xx, cy + 1, "f0")
			if r.randf() < 0.5:
				_px(img, xx, cy - 1, "b0")
	# a bubble
	var bx := 20 + frame * 9
	var size: int = [1, 2, 3, 0][frame]
	if size > 0:
		for y in range(-size, size + 1):
			for x in range(-size, size + 1):
				if Vector2(x, y).length() <= size:
					_px(img, bx + x, 6 + y, "f5" if Vector2(x, y).length() < size - 0.8 else "f4")
	else:
		_px(img, bx - 2, 4, "f5")
		_px(img, bx + 2, 3, "f5")
		_px(img, bx, 2, "f4")
	return img


## A plug of cooled slag: black and glassy, faceted, with dim red cracks. 24x82.
func _slag_crust() -> Image:
	var img := _img(24, 82)
	for y in 82:
		for x in 24:
			var edge := 2 + int(1.5 * sin(y / 5.0)) + (1 if y % 9 == 0 else 0)
			if x >= edge and x < 24 - edge + (1 if y % 7 == 0 else 0):
				var k := "c1" if (x + y / 3) % 7 < 4 else "c2"
				if x < edge + 2:
					k = "c3"
				_px(img, x, y, k)
	# facets
	for i in 14:
		var fy := rng.randi_range(4, 76)
		var fx := rng.randi_range(5, 16)
		for k in rng.randi_range(3, 6):
			_px(img, fx + k, fy + k / 2, "c4")
	# the crack, glowing dully
	var x := 12
	for y in range(3, 80):
		_px(img, x, y, "f0")
		if y % 3 == 0:
			_px(img, x + 1, y, "f1")
		if y % 5 == 0:
			x += rng.randi_range(-2, 2)
			x = clampi(x, 6, 17)
	# rime at its edges: it is cold slag
	for i in 26:
		_px(img, rng.randi_range(2, 5), rng.randi_range(0, 81), "r0")
	_outline(img)
	return img


# ------------------------------------------------------------------ the Forge Door

## The great iron door to the bell beyond: riveted plates, two bands and the
## Smith's sign (an anvil under a flame). Frosted: rimed white with icicles.
## Warm: dark iron with a dull glow at its seams. 64x152.
func _forge_door(frosted: bool) -> Image:
	var img := _img(64, 152)
	_rect(img, 2, 0, 60, 152, "i2")
	# plates
	for py in [0, 50, 100]:
		_rect(img, 2, py, 60, 1, "i4")
		_rect(img, 2, py + 49, 60, 1, "i1")
		_rect(img, 31, py, 2, 50, "i1")
		_rect(img, 33, py, 1, 50, "i3")
		_rivets(img, 5, 57, py + 3, 8)
		_rivets(img, 5, 57, py + 45, 8)
	_rect(img, 2, 0, 1, 152, "i4")
	_rect(img, 61, 0, 1, 152, "i1")
	# bands
	for by in [38, 112]:
		_band(img, 0, 64, by, 6)
	# the sign: an anvil under a flame
	_stamp(img, 22, 60, _tr([
		".. .. .. .. .. .. .. .. ff .. .. .. .. .. .. .. .. ..",
		".. .. .. .. .. .. .. ff gg ff .. .. .. .. .. .. .. ..",
		".. .. .. .. .. .. .. ff gg gg ff .. .. .. .. .. .. ..",
		".. .. .. .. .. .. ff gg hh gg ff .. .. .. .. .. .. ..",
		".. .. .. .. .. .. ff gg hh gg ff .. .. .. .. .. .. ..",
		".. .. .. .. .. .. .. ff ff ff .. .. .. .. .. .. .. ..",
		".. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. .. ..",
		".. aa aa aa aa aa aa aa aa aa aa aa aa aa aa .. .. ..",
		".. .. aa bb bb bb bb bb bb bb bb bb bb aa aa aa .. ..",
		".. .. .. .. aa bb bb bb bb bb bb aa .. .. .. .. .. ..",
		".. .. .. .. .. aa bb bb bb bb aa .. .. .. .. .. .. ..",
		".. .. .. .. aa aa aa aa aa aa aa aa .. .. .. .. .. ..",
	], {"ff": "i4" if frosted else "f1", "gg": "i3" if frosted else "f2", "hh": "i4" if frosted else "f3", "aa": "i4", "bb": "i3"}))
	if frosted:
		# rime over everything, thick at the top and the seams, icicles at the bands
		for i in 700:
			var x := rng.randi_range(2, 61)
			var y := rng.randi_range(0, 151)
			var near_seam := y % 50 < 4 or y % 50 > 46 or absi(x - 32) < 3 or y < 10
			if rng.randf() < (0.8 if near_seam else 0.18):
				_px(img, x, y, "r1" if rng.randf() < 0.6 else ("r2" if rng.randf() < 0.7 else "r3"))
		for by in [44, 118]:
			for x in range(3, 61, 5):
				var n := rng.randi_range(2, 7)
				for k in n:
					_px(img, x, by + k, "r2" if k < n - 1 else "r1")
	else:
		for y in 152:
			if y % 50 < 2 or y % 50 > 47:
				for x in range(3, 61):
					if rng.randf() < 0.3:
						_px(img, x, y, "f1")
	_outline(img)
	return img


# ------------------------------------------------------------------ furniture

func _bellows() -> Image:
	var img := _img(64, 36)
	# lower board and upper board, leather folds between, nozzle to the right
	_rect(img, 4, 26, 46, 5, "w2")
	_rect(img, 4, 26, 46, 1, "w4")
	_rect(img, 4, 8, 44, 5, "w2")
	_rect(img, 4, 8, 44, 1, "w4")
	for i in 4:
		var y := 13 + i * 3
		var inset := 3 + (i % 2) * 2
		_rect(img, 6 + inset, y, 38 - inset * 2, 3, "w1" if i % 2 == 0 else "w0")
		_rect(img, 6 + inset, y, 38 - inset * 2, 1, "w3")
	_rect(img, 48, 16, 12, 6, "i2")
	_rect(img, 48, 16, 12, 1, "i4")
	_rect(img, 58, 17, 4, 4, "i1")
	# handles
	_rect(img, 0, 9, 6, 2, "w3")
	_rect(img, 0, 27, 6, 2, "w3")
	_rivets(img, 8, 44, 9, 9)
	_outline(img)
	return img


func _anvil() -> Image:
	var img := _img(40, 24)
	_stamp(img, 2, 2, [
		"i3 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i4 i3 .. .. .. ..",
		".. i2 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i2 ..",
		".. .. .. i2 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i2 i2 i2 i2 i2 .. .. .. ..",
		".. .. .. .. .. i2 i2 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i3 i2 i2 .. .. .. .. .. .. .. .. .. .. ..",
	])
	_rect(img, 12, 6, 14, 8, "i2")
	_rect(img, 12, 6, 1, 8, "i3")
	_rect(img, 8, 14, 22, 3, "i2")
	_rect(img, 8, 14, 22, 1, "i3")
	_rect(img, 6, 17, 26, 5, "w2")
	_rect(img, 6, 17, 26, 1, "w4")
	_px(img, 22, 2, "k2")
	_px(img, 23, 3, "k1")
	_outline(img)
	return img


func _tool_rack() -> Image:
	var img := _img(40, 44)
	_rect(img, 2, 4, 36, 4, "w2")
	_rect(img, 2, 4, 36, 1, "w4")
	for i in 4:
		var x := 6 + i * 9
		_rect(img, x, 8, 2, 26, "i3")
		_rect(img, x, 8, 1, 26, "i4")
		if i % 2 == 0:
			_rect(img, x - 2, 32, 6, 5, "i2")
			_rect(img, x - 2, 32, 6, 1, "i4")
		else:
			_rect(img, x - 1, 32, 1, 8, "i3")
			_rect(img, x + 2, 32, 1, 8, "i3")
	_outline(img)
	return img


func _coal_heap() -> Image:
	var img := _img(48, 18)
	for y in 18:
		for x in 48:
			var top := 17 - int(12.0 * sin(x / 47.0 * PI))
			if y >= top:
				_px(img, x, y, ["c1", "c2", "c1", "c0"][rng.randi_range(0, 3)])
	for i in 20:
		var x := rng.randi_range(4, 44)
		_px(img, x, 17 - int(12.0 * sin(x / 47.0 * PI)) + 1, "c4")
	_outline(img)
	return img


## The Smith's carving: a flame, coal and a breath of wind, each with an arrow
## into a little kiln. 72x44.
func _smith_plaque() -> Image:
	var img := _img(72, 44)
	_rect(img, 1, 1, 70, 42, "s1")
	_rect(img, 1, 1, 70, 1, "s3")
	_rect(img, 1, 1, 1, 42, "s2")
	_rect(img, 70, 1, 1, 42, "m0")
	_rect(img, 1, 42, 70, 1, "m0")
	var cut := "m0"
	var hi := "s4"
	# flame (top left)
	_stamp(img, 6, 4, _tr([
		".. .. hh .. ..", ".. .. hh cc ..", ".. hh cc cc ..", "hh cc cc cc hh", "hh cc .. cc hh", ".. hh cc hh ..",
	], {"hh": hi, "cc": cut}))
	# coal (middle left)
	_stamp(img, 5, 17, _tr([
		".. cc cc .. .. ..", "cc hh hh cc cc ..", "cc hh cc hh hh cc", ".. cc cc cc cc ..",
	], {"hh": hi, "cc": cut}))
	# wind (bottom left)
	_stamp(img, 5, 29, _tr([
		"cc cc cc cc .. .. ..", ".. .. .. .. cc .. ..", ".. cc cc cc cc cc ..", ".. .. .. .. .. .. cc", "cc cc cc cc cc cc ..",
	], {"cc": cut}))
	# three arrows to the kiln
	for y in [8, 19, 31]:
		_rect(img, 16, y, 24, 1, cut)
		_rect(img, 16, y + 1, 24, 1, hi)
		_px(img, 38, y - 1, cut)
		_px(img, 38, y + 1, cut)
		_px(img, 37, y - 2, cut)
		_px(img, 37, y + 2, cut)
	# the kiln: a box with an arch and a chimney
	_rect(img, 44, 10, 22, 26, cut)
	_rect(img, 45, 11, 20, 24, "s2")
	_rect(img, 51, 24, 8, 11, cut)
	_rect(img, 58, 4, 4, 7, cut)
	_rect(img, 45, 11, 20, 1, hi)
	_outline(img)
	return img


# ------------------------------------------------------------------ chalk and frost

func _chalk_steps() -> Image:
	var img := _img(48, 6)
	for i in 4:
		var x := 2 + i * 12
		var y := 0 if i % 2 == 0 else 3
		_rect(img, x, y, 4, 2, "k1")
		_px(img, x + 4, y, "k0")
		_px(img, x + 1, y + 2, "k0")
	return img


## Wren's drawing: a flame, an arrow right, up, and right again, into a kiln.
func _chalk_route() -> Image:
	var img := _img(56, 40)
	var k := "k2"
	# flame
	_stamp(img, 1, 26, [".. k1 ..", "k1 k2 k1", "k1 k2 k1", ".. k1 .."])
	# right
	_rect(img, 6, 28, 14, 1, k)
	_px(img, 18, 27, k)
	_px(img, 18, 29, k)
	# up
	_rect(img, 20, 10, 1, 19, k)
	_px(img, 19, 12, k)
	_px(img, 21, 12, k)
	# right again
	_rect(img, 21, 10, 18, 1, k)
	_px(img, 37, 9, k)
	_px(img, 37, 11, k)
	# kiln
	_rect(img, 40, 4, 14, 1, k)
	_rect(img, 40, 4, 1, 16, k)
	_rect(img, 53, 4, 1, 16, k)
	_rect(img, 40, 19, 14, 1, k)
	_rect(img, 44, 14, 6, 1, "k1")
	_rect(img, 49, 0, 2, 4, "k1")
	# a little star: Wren's mark
	_stamp(img, 26, 30, [".. k1 ..", "k1 k2 k1", ".. k1 .."])
	return img


func _chalk_star() -> Image:
	var img := _img(12, 12)
	_stamp(img, 1, 1, [
		".. .. .. .. k2 .. .. .. .. ..",
		".. .. .. .. k2 .. .. .. .. ..",
		".. .. .. k1 k2 k1 .. .. .. ..",
		"k2 k2 k1 k2 k2 k2 k1 k2 k2 ..",
		".. .. k1 k2 k2 k2 k1 .. .. ..",
		".. .. .. k2 .. k2 .. .. .. ..",
		".. .. k1 .. .. .. k1 .. .. ..",
		".. .. k2 .. .. .. k2 .. .. ..",
	])
	return img


## Frost crystals spreading over a wall: dense at the centre, feathered out.
func _frost(w: int, h: int, seed_v: int) -> Image:
	var img := _img(w, h)
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var centre := Vector2(w / 2.0, h / 2.0)
	for i in w * h:
		var p := Vector2(r.randf_range(0, w), r.randf_range(0, h))
		var d := ((p - centre) / centre).length()
		if d < 1.0 and r.randf() < pow(1.0 - d, 1.6) * 0.55:
			var k := "r0" if d > 0.7 else ("r1" if d > 0.35 else "r2")
			_px(img, int(p.x), int(p.y), k)
	# feathered branches
	for b in 7:
		var a := r.randf() * TAU
		var p := centre
		for s in r.randi_range(8, 18):
			p += Vector2(cos(a), sin(a)) * 1.3
			a += r.randf_range(-0.4, 0.4)
			_px(img, int(p.x), int(p.y), "r2")
			if s % 3 == 0:
				_px(img, int(p.x + sin(a) * 2), int(p.y - cos(a) * 2), "r1")
	return img


## Rime over a sealed door on the Landing (the same size as its door frame).
## Rime over a sealed door: a crust that hugs the arched frame and feathers
## inward, icicles from the lintel, and fern-like crystals reaching in from
## the sides. The middle stays mostly clear, so the door shows through.
func _door_frost() -> Image:
	var img := _img(32, 33)
	var x0 := 3
	var x1 := 28
	var y1 := 32
	# The crust
	for y in range(0, y1 + 1):
		for x in range(x0, x1 + 1):
			var top := _frost_top(x)
			if y < top:
				continue
			var d := minf(minf(float(x - x0), float(x1 - x)), float(y - top))
			# (thinner toward the floor, where the cold has less hold)
			d += float(y) / 16.0
			var p := 0.95 if d < 1.5 else (0.55 if d < 3.0 else (0.18 if d < 4.5 else 0.0))
			if rng.randf() < p:
				_px(img, x, y, "r2" if d < 1.0 else "r1")
	# Fern-like fronds reaching in from the sides: a thin stem, a spur on
	# one side every third step, a bright tip
	for i in 5:
		var left := i % 2 == 0
		var x := x0 + 2 if left else x1 - 2
		var y := rng.randi_range(7, 25)
		var step := Vector2i(1 if left else -1, -1 if rng.randf() < 0.5 else 1)
		var length := rng.randi_range(4, 7)
		for k in length:
			x += step.x
			y += step.y
			if y < _frost_top(x) + 1 or y > y1:
				break
			_px(img, x, y, "r1")
			if k % 3 == 2:
				_px(img, x, y - step.y, "r0")
		_px(img, x, y, "r3")
	# Icicles from the lintel
	for x in range(6, 27, 3):
		var top := _frost_top(x) + 2
		var n := rng.randi_range(2, 5)
		for k in n:
			_px(img, x, top + k, "r2" if k < n - 1 else "r3")
	# A few glints in the crust
	for i in 10:
		var gx := rng.randi_range(x0, x1)
		var gy := rng.randi_range(_frost_top(gx), _frost_top(gx) + 3)
		_px(img, gx, gy, "r3")
	return img


## The Kiln Heart, 128x88: the Smith's great iron crucible, a heap of coal
## mounded in its mouth, a thick riveted rim, a tapering bowl with two bands,
## three lamp sockets (the lamps are their own sprites) and three stubby feet.
## Cold: dark coal under rime, frost on the rim. Hot: the coal glows through
## its cracks, the rim's lip burns orange and the bowl's foot warms.
func _heart_crucible(hot: bool) -> Image:
	var w := 128
	var h := 88
	var img := _img(w, h)
	# The bowl, tapering toward its feet
	for y in range(18, 81):
		var half := 62.0 - (y - 18) * 0.3
		for x in range(int(64 - half), int(64 + half)):
			var t := (x - (64 - half)) / (2.0 * half)
			_px(img, x, y, "i3" if t < 0.18 else ("i2" if t < 0.72 else "i1"))
	_band(img, 4, 120, 32, 5)
	_band(img, 10, 108, 64, 5)
	# Three lamp sockets on its face (the coal lamps sit in them)
	for lx in [36, 64, 92]:
		for y in range(35, 50):
			for x in range(lx - 8, lx + 8):
				var d := Vector2(x + 0.5 - lx, y + 0.5 - 42).length()
				if d <= 8.0:
					_px(img, x, y, "i1" if d > 6.5 else "i0")
		_px(img, lx - 5, 36, "i4")
	# The Smith's flame struck into the bowl, low between the bands
	_stamp(img, 60, 52, [
		".. .. i4 .. .. ..",
		".. i4 i3 i4 .. ..",
		".. i4 i3 i3 i4 ..",
		"i4 i3 i1 i3 i4 ..",
		".. i4 i3 i4 .. ..",
	])
	# Feet
	for fx in [18, 57, 96]:
		_rect(img, fx, 80, 14, 8, "i1")
		_rect(img, fx, 80, 14, 1, "i3")
	# The rim: a thick iron lip across the whole width
	_rect(img, 0, 8, w, 11, "i2")
	_rect(img, 0, 8, w, 2, "i4")
	_rect(img, 0, 17, w, 2, "i1")
	_rivets(img, 6, w - 8, 12, 10)
	# The coal heaped in its mouth
	for x in range(8, w - 8):
		var top := 2 + int(pow(absf(x - 64.0) / 56.0, 2.0) * 6.0)
		for y in range(top, 9):
			var k := "c1" if rng.randf() < 0.45 else ("c2" if rng.randf() < 0.7 else "c3")
			_px(img, x, y, k)
		if rng.randf() < 0.3:
			_px(img, x, top, "c4")
	if hot:
		# Glowing cracks through the coal, a burning lip, a warm foot
		for i in 70:
			var x := rng.randi_range(10, w - 11)
			var y := rng.randi_range(3, 8)
			if _at(img, x, y).a > 0.5:
				_px(img, x, y, "f3" if rng.randf() < 0.6 else "f4")
		for x in range(0, w):
			if rng.randf() < 0.7:
				_px(img, x, 8, "f2")
		for y in range(60, 81):
			for x in range(0, w):
				if _at(img, x, y) == _c("i2") and rng.randf() < 0.12:
					_px(img, x, y, "f0")
	else:
		# The Hush's rime on the coal and the rim
		for x in range(8, w - 8):
			if rng.randf() < 0.5:
				var top := 2 + int(pow(absf(x - 64.0) / 56.0, 2.0) * 6.0)
				_px(img, x, top, "r1" if rng.randf() < 0.7 else "r2")
		for x in range(0, w):
			if rng.randf() < 0.45:
				_px(img, x, 19, "r1")
			if rng.randf() < 0.2:
				var n := rng.randi_range(1, 4)
				for k in n:
					_px(img, x, 19 + k, "r2" if k < n - 1 else "r1")
	_outline(img)
	return img


## The top of the door's arch at column x: high in the middle, low at the sides.
func _frost_top(x: int) -> int:
	return 1 + int(round(5.0 * pow((x - 15.5) / 12.5, 2.0)))


# ------------------------------------------------------------------ saving

func _save(sprite_name: String, frames: Array) -> void:
	var w := 0
	var h := 0
	for f in frames:
		w = maxi(w, f.get_width())
		h = maxi(h, f.get_height())
	var strip := Image.create(w * frames.size(), h, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		var f: Image = frames[i]
		strip.blit_rect(f, Rect2i(Vector2i.ZERO, f.get_size()), Vector2i(i * w + (w - f.get_width()) / 2, h - f.get_height()))
	strip.save_png(ProjectSettings.globalize_path(OUT + sprite_name + ".png"))
	_previews.append(strip)
	print("  %s: %d frame(s) of %dx%d" % [sprite_name, frames.size(), w, h])


func _save_preview() -> void:
	var k := 2
	var pad := 10
	var width := 0
	var height := pad
	for strip in _previews:
		width = maxi(width, strip.get_width() * k + pad * 2)
		height += strip.get_height() * k + pad
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color("1c1a2e"))
	var y := pad
	for strip in _previews:
		var big: Image = strip.duplicate()
		big.resize(strip.get_width() * k, strip.get_height() * k, Image.INTERPOLATE_NEAREST)
		img.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(pad, y))
		y += big.get_height() + pad
	img.save_png(ProjectSettings.globalize_path(PREVIEW))
	print("  preview: ", ProjectSettings.globalize_path(PREVIEW))


## Replaces placeholder keys in a map's rows.
func _tr(rows: Array, pairs: Dictionary) -> Array:
	var out := []
	for row in rows:
		var s: String = row
		for k in pairs:
			s = s.replace(k, pairs[k])
		out.append(s)
	return out
