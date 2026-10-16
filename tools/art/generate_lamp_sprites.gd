extends SceneTree

## Makes the pixel sprites for the Lampworks' first room (The Hall of Lamps):
##   hall_lamp           a hanging brass oil lamp with a glass chimney (2 frames:
##                       dark, lit). The chain above it is drawn by the lamp.
##   great_lamp          the Great Lamp: a brass ring of five glass lamps round a
##                       crystal heart (2 frames: dark, lit)
##   bookshelf           a tall reading-hall shelf of old books
##   lamplighter_plaque  the Lamplighter's carving: a lamp, its rays, and a monk
##                       held still in them
## Drawn at 1x for the dungeon (the camera shows it at 2x), lit from the top
## left with a dark outline, in the dungeon's purples with the Lampworks' brass,
## glass and warm lamplight. Saved as PNG strips in res://assets/sprites/story/
## (SurfaceArt.STRIPS lists their frame counts). Re-run after editing:
##   godot --headless --path . --script res://tools/art/generate_lamp_sprites.gd

const OUT := "res://assets/sprites/story/"
const PREVIEW := "user://lamp_sprites_preview.png"

const C := {
	# iron
	"i0": "0e0c16", "i1": "1c1a28", "i2": "2b2a3a", "i3": "45435a", "i4": "6e6a8c", "i5": "9a96b8",
	# dungeon stone
	"m0": "16121c", "m1": "241c26", "s1": "3a3346", "s2": "544a62", "s3": "6e6480", "s4": "8a80a0",
	# brass
	"z0": "1e140c", "z1": "4a3218", "z2": "7a5428", "z3": "a87838", "z4": "d8aa5c", "z5": "f4d690",
	# glass: dark (unlit) and its highlights
	"g0": "dff6ff", "g1": "8aa4c0", "g2": "3c4a66", "g3": "222a40",
	# lamplight
	"f0": "7a2e10", "f1": "d0601c", "f2": "f4a038", "f3": "ffd77a", "f4": "fff6d8",
	# old book spines
	"b0": "3a1e22", "b1": "5a2c2c", "b2": "2c3a4e", "b3": "3e5a44", "b4": "6a5a34", "b5": "4c3462",
	# paper
	"p0": "c8b89a", "p1": "e8dcc0",
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
	rng.seed = 7071
	_save("hall_lamp", [_hall_lamp(false), _hall_lamp(true)])
	_save("great_lamp", [_great_lamp(false), _great_lamp(true)])
	_save("bookshelf", [_bookshelf()])
	_save("lamplighter_plaque", [_plaque()])
	_save_preview()
	print("LAMP SPRITES DONE")
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


## A pixel with its own alpha (for glass and glow).
func _pxa(img: Image, x: int, y: int, key: String, a: float) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, Color(_c(key), a))


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


## A brass band with a lit top edge and a dark lower edge.
func _brass_band(img: Image, x0: int, w: int, y: int, h := 3) -> void:
	_rect(img, x0, y, w, h, "z2")
	_rect(img, x0, y, w, 1, "z4")
	_rect(img, x0, y + h - 1, w, 1, "z1")


## One glass chimney with a wick: dark glass, or a flame and warm glass.
func _chimney(img: Image, x0: int, y0: int, w: int, h: int, lit: bool) -> void:
	for y in range(y0, y0 + h):
		# a gentle bulge in the middle
		var t := float(y - y0) / float(h - 1)
		var bulge := int(round(sin(t * PI) * 2.0))
		var left := x0 - bulge
		var right := x0 + w + bulge
		for x in range(left, right):
			if lit:
				var d := absf(x - (x0 + w / 2.0)) / (w / 2.0 + bulge)
				_px(img, x, y, "f3" if d < 0.35 else ("f2" if d < 0.75 else "f1"))
			else:
				_px(img, x, y, "g3" if (x - left) > 1 else "g2")
		# the glass edges catch the light
		_pxa(img, left, y, "g0", 0.55 if lit else 0.35)
	if lit:
		# the flame itself, white at its heart
		var fx := x0 + w / 2
		for k in 5:
			_px(img, fx, y0 + h - 4 - k, "f4" if k < 3 else "f3")
		_px(img, fx - 1, y0 + h - 3, "f4")
		_px(img, fx + 1, y0 + h - 3, "f3")
	else:
		# a cold wick
		_rect(img, x0 + w / 2, y0 + h - 4, 1, 3, "i4")


# ------------------------------------------------------------------ the hall lamp

## A hanging oil lamp, 24x44: a hook and cap at the top (the chain hangs from
## its top centre), a glass chimney, a brass font and a little finial below.
func _hall_lamp(lit: bool) -> Image:
	var img := _img(24, 44)
	# hook and cap
	_rect(img, 11, 0, 2, 3, "i4")
	_rect(img, 7, 3, 10, 2, "z3")
	_rect(img, 5, 5, 14, 3, "z2")
	_rect(img, 5, 5, 14, 1, "z4")
	_rect(img, 6, 7, 12, 1, "z1")
	# the chimney
	_chimney(img, 8, 8, 8, 18, lit)
	# the brass font
	_brass_band(img, 5, 14, 26, 3)
	for y in range(29, 36):
		var inset := (y - 29) / 2
		_rect(img, 4 + inset, y, 16 - inset * 2, 1, "z2" if y < 33 else "z1")
	_rect(img, 5, 29, 1, 5, "z4")
	_px(img, 9, 31, "z5")
	# finial
	_rect(img, 10, 36, 4, 3, "z3")
	_rect(img, 11, 39, 2, 4, "z2")
	_px(img, 11, 39, "z4")
	_outline(img)
	if lit:
		# a soft halo round the glass (after the outline, so it glows past it)
		for y in range(4, 30):
			for x in range(1, 23):
				if img.get_pixel(x, y).a < 0.1:
					var d := Vector2(x - 12, (y - 17) * 0.8).length()
					if d < 11.0:
						_pxa(img, x, y, "f3", 0.22 * (1.0 - d / 11.0))
	return img


# ------------------------------------------------------------------ the Great Lamp

## The Great Lamp, 72x64: a crystal heart hanging in a brass ring of five glass
## lamps. Its chain hangs from its top centre; the crystal is at about (36, 40).
func _great_lamp(lit: bool) -> Image:
	var img := _img(72, 64)
	# the crown and the hanger
	_rect(img, 35, 0, 2, 6, "i4")
	_rect(img, 30, 6, 12, 3, "z3")
	_rect(img, 30, 6, 12, 1, "z5")
	# three rods down to the ring
	for k in 14:
		_px(img, 33 - k, 9 + k, "z2")
		_px(img, 38 + k, 9 + k, "z2")
		_px(img, 36, 9 + k, "z2")
	# the ring
	_brass_band(img, 4, 64, 23, 4)
	for x in range(6, 66, 6):
		_px(img, x, 24, "z5")
	# five lamps on the ring
	for i in 5:
		var lx := 6 + i * 14
		_rect(img, lx, 20, 6, 3, "z2")
		_rect(img, lx, 20, 6, 1, "z4")
		_chimney(img, lx + 1, 10, 4, 10, lit)
	# the crystal heart, hanging under the ring
	_rect(img, 35, 27, 2, 6, "i4")
	var cx := 36
	var cy := 42
	for row in range(-9, 10):
		var half := 6 - absi(row) * 6 / 9
		for x in range(cx - half, cx + half + 1):
			var key := "g1"
			if lit:
				key = "f4" if absi(x - cx) + absi(row) < 4 else ("f3" if absi(x - cx) + absi(row) < 7 else "f2")
			elif x < cx:
				key = "g2"
			_px(img, x, cy + row, key)
	_px(img, cx - 2, cy - 5, "g0")
	_px(img, cx - 3, cy - 4, "g0")
	# a drip of brass beneath
	_rect(img, 35, 52, 2, 4, "z3")
	_px(img, 35, 56, "z4")
	_outline(img)
	if lit:
		for y in 64:
			for x in 72:
				if img.get_pixel(x, y).a < 0.1:
					var d := Vector2(x - cx, (y - cy) * 0.9).length()
					if d < 22.0:
						_pxa(img, x, y, "f3", 0.18 * (1.0 - d / 22.0))
	return img


# ------------------------------------------------------------------ the reading hall

## A tall shelf of old books, 48x112: a dark frame, five shelves, books leaning
## and standing in the reading halls' faded colours, a scroll or two.
func _bookshelf() -> Image:
	var img := _img(48, 112)
	_rect(img, 0, 0, 48, 112, "m1")
	_rect(img, 0, 0, 48, 2, "s2")
	_rect(img, 0, 0, 2, 112, "s1")
	_rect(img, 46, 0, 2, 112, "m0")
	var spines := ["b0", "b1", "b2", "b3", "b4", "b5"]
	for shelf in 5:
		var floor_y := 22 + shelf * 21
		# the board
		_rect(img, 2, floor_y, 44, 2, "z1")
		_rect(img, 2, floor_y, 44, 1, "z2")
		# books standing on it
		var x := 3
		while x < 44:
			var w := rng.randi_range(2, 4)
			var h := rng.randi_range(11, 17)
			if x + w > 45:
				break
			if rng.randf() < 0.12:
				# a scroll lying on its side
				_rect(img, x, floor_y - 4, mini(8, 45 - x), 4, "p0")
				_rect(img, x, floor_y - 4, mini(8, 45 - x), 1, "p1")
				x += 9
				continue
			var key: String = spines[rng.randi_range(0, spines.size() - 1)]
			_rect(img, x, floor_y - h, w, h, key)
			_rect(img, x, floor_y - h, 1, h, "s3")
			# a gilt band on some spines
			if rng.randf() < 0.5:
				_rect(img, x, floor_y - h + 3, w, 1, "z3")
			x += w + (1 if rng.randf() < 0.3 else 0)
	_outline(img)
	return img


## The Lamplighter's carving, 56x44: a lamp with rays falling on a small
## kneeling monk, held still in its light.
func _plaque() -> Image:
	var img := _img(56, 44)
	_rect(img, 1, 1, 54, 42, "s1")
	_rect(img, 1, 1, 54, 1, "s3")
	_rect(img, 3, 3, 50, 38, "s2")
	_rect(img, 3, 3, 50, 1, "s3")
	# the lamp, top left
	_rect(img, 12, 6, 6, 2, "m1")
	_rect(img, 13, 8, 4, 7, "m1")
	_rect(img, 11, 15, 8, 2, "m1")
	# its rays, falling down to the right
	for k in 3:
		var sx := 18 + k * 2
		var sy := 13 + k * 2
		for t in range(0, 18):
			_px(img, sx + t, sy + t * 0.8 + k, "s3")
	# the monk, kneeling, bottom right
	_rect(img, 38, 26, 5, 5, "m1")
	_rect(img, 36, 31, 9, 6, "m1")
	_rect(img, 34, 37, 13, 2, "m1")
	# a stillness mark over it: three short bars
	for k in 3:
		_rect(img, 35 + k * 4, 22, 2, 1, "m1")
	_outline(img)
	return img


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
	var k := 3
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
