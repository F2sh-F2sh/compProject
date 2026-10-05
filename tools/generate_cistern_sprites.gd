extends SceneTree

## Makes the pixel sprites for the Drowned Cistern's first room (The Still Water):
##   cistern_water    a tile of black, cold water (4 frames, the surface moving)
##   fountain_nozzle  a fountain's low stone basin and bronze spout
##   tide_clock       the tide clock's frame: a stone plinth, bronze uprights with
##                    the hour mark near the top, a glass column (clear: the water
##                    inside is drawn by scripts/puzzle/tide_clock.gd) and a capital
##   tide_float       the brass float that rides the tide in the clock
##   warden_plaque    the Warden's carving: water, the cold, and the bell it rings
##   cistern_pipe     a bronze water pipe down a wall, with a valve wheel
## Drawn at 1x for the dungeon (the camera shows it at 2x), lit from the top
## left with a dark outline, in the dungeon's purples with the Cistern's own
## teal water, verdigris bronze and glass. Saved as PNG strips in
## res://assets/sprites/story/ (SurfaceArt.STRIPS lists their frame counts).
## Re-run after editing:
##   godot --headless --path . --script res://tools/generate_cistern_sprites.gd

const OUT := "res://assets/sprites/story/"
const PREVIEW := "user://cistern_sprites_preview.png"

const C := {
	# iron
	"i0": "0e0c16", "i1": "1c1a28", "i2": "2b2a3a", "i3": "45435a", "i4": "6e6a8c", "i5": "9a96b8",
	# dungeon stone
	"m0": "16121c", "m1": "241c26", "s1": "3a3346", "s2": "544a62", "s3": "6e6480", "s4": "8a80a0",
	# cold water
	"a0": "050f1a", "a1": "0a1d2e", "a2": "102f44", "a3": "1a4860", "a4": "2a6c86", "a5": "52a0b8", "a6": "9edaea", "a7": "e6fbff",
	# bronze, and its verdigris
	"z0": "1e140c", "z1": "4a3218", "z2": "7a5428", "z3": "a87838", "z4": "d8aa5c", "z5": "f4d690",
	"v0": "16302c", "v1": "24504a", "v2": "3c806e", "v3": "6cb49c",
	# glass highlights
	"g0": "dff6ff",
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
	rng.seed = 5113
	_save("cistern_water", [_water(0), _water(1), _water(2), _water(3)])
	_save("fountain_nozzle", [_nozzle()])
	_save("tide_clock", [_tide_clock()])
	_save("tide_float", [_float()])
	_save("warden_plaque", [_warden_plaque()])
	_save("cistern_pipe", [_pipe()])
	_save_preview()
	print("CISTERN SPRITES DONE")
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


## A pixel with its own alpha (for glass).
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


## Stone blocks with 1 px mortar, every other row offset.
func _blocks(img: Image, x0: int, y0: int, w: int, h: int, bw: int, bh: int, seed_v: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	_rect(img, x0, y0, w, h, "m1")
	var row := 0
	var y := y0
	while y < y0 + h:
		var off := 0 if row % 2 == 0 else bw / 2
		var x := x0 - off
		while x < x0 + w:
			var bx := maxi(x, x0)
			var ex := mini(x + bw - 1, x0 + w)
			var ey := mini(y + bh - 1, y0 + h)
			if ex > bx and ey > y:
				var k: String = ["s1", "s2", "s2", "s3"][r.randi_range(0, 3)]
				_rect(img, bx, y, ex - bx, ey - y, k)
				_rect(img, bx, y, ex - bx, 1, "s4" if k != "s1" else "s3")
			x += bw
		y += bh
		row += 1


## A bronze band with a lit top edge and verdigris under it.
func _bronze_band(img: Image, x0: int, w: int, y: int, h := 4) -> void:
	_rect(img, x0, y, w, h, "z2")
	_rect(img, x0, y, w, 1, "z4")
	_rect(img, x0, y + h - 1, w, 1, "z1")
	for x in range(x0 + 2, x0 + w - 1, 5):
		_px(img, x, y + h - 1, "v2")


# ------------------------------------------------------------------ water

## One tile of the Cistern's cold water: a moving surface line with glints,
## dark below. 64x56 (its surface is the top 4 px).
func _water(frame: int) -> Image:
	var img := _img(64, 56)
	for x in 64:
		var wave := int(round(sin((x + frame * 4) / 7.0) * 1.2 + sin((x * 0.6 - frame * 3) / 5.0) * 0.6))
		var top := 2 + wave
		for y in range(top, 56):
			var d := y - top
			var k := "a5" if d == 0 else ("a4" if d < 3 else ("a3" if d < 9 else ("a2" if d < 22 else ("a1" if d < 40 else "a0"))))
			_px(img, x, y, k)
		# glints riding the crest
		if wave <= -1 and (x + frame * 5) % 11 == 0:
			_px(img, x, top, "a7")
			_px(img, x + 1, top, "a6")
	# slow ripple bands under the surface
	var r := RandomNumberGenerator.new()
	r.seed = 31
	for i in 7:
		var rx := int(fposmod(r.randi_range(0, 63) + frame * 2 * (1 if i % 2 == 0 else -1), 64))
		var ry := r.randi_range(8, 30)
		var rw := r.randi_range(6, 14)
		for x in range(rx, rx + rw):
			_px(img, x % 64, ry, "a3" if ry < 20 else "a2")
	return img


## A fountain's basin and spout: a low stone bowl with a bronze spout in the
## middle (the jet leaves its mouth 12 px above the floor). 40x14.
func _nozzle() -> Image:
	var img := _img(40, 14)
	# the bowl: a rim, curving in to its foot
	for y in range(4, 14):
		var inset := 0 if y < 8 else (y - 7)
		_rect(img, 1 + inset, y, 38 - inset * 2, 1, "s2" if y < 6 else ("s3" if y == 6 else "s1"))
	_rect(img, 1, 4, 38, 1, "s4")
	# water in the bowl
	_rect(img, 4, 5, 32, 2, "a3")
	_rect(img, 5, 5, 30, 1, "a5")
	# the spout
	_rect(img, 16, 0, 8, 6, "z2")
	_rect(img, 16, 0, 8, 1, "z4")
	_rect(img, 16, 0, 1, 6, "z3")
	_rect(img, 18, 0, 4, 1, "a6")
	_px(img, 22, 3, "v2")
	_px(img, 17, 4, "v1")
	_outline(img)
	return img


# ------------------------------------------------------------------ the tide clock

## The tide clock's frame, 112x320: a stone plinth (bottom 28 px), bronze
## uprights either side of a clear glass column 64 px wide (x 24-88, y 18-292),
## graduation ticks and the hour mark (y 26, near the top), and a capital with
## a small dial. The water and the float are drawn by the clock itself.
func _tide_clock() -> Image:
	var img := _img(112, 320)
	# plinth
	_blocks(img, 4, 292, 104, 28, 26, 9, 71)
	_rect(img, 4, 292, 104, 2, "s4")
	_bronze_band(img, 30, 52, 302, 6)
	# a wave carved on the plinth's bronze plate
	for x in range(34, 78):
		var y := 304 + int(round(sin(x / 3.0)))
		_px(img, x, y, "z5")
	# the glass column: clear, with a bright streak and a faint far edge
	for y in range(18, 292):
		_pxa(img, 28, y, "g0", 0.32)
		_pxa(img, 29, y, "g0", 0.18)
		_pxa(img, 85, y, "g0", 0.14)
		if y % 37 < 3:
			_pxa(img, 31, y, "g0", 0.22)
	# uprights
	for ux in [16, 88]:
		_rect(img, ux, 14, 8, 280, "z2")
		_rect(img, ux, 14, 1, 280, "z4")
		_rect(img, ux + 7, 14, 1, 280, "z1")
		for y in range(30, 290, 13):
			_px(img, ux + 3, y, "v2")
			_px(img, ux + 4, y + 1, "v1")
		# iron bands round them
		for y in [70, 150, 230]:
			_rect(img, ux - 2, y, 12, 5, "i2")
			_rect(img, ux - 2, y, 12, 1, "i4")
			_rect(img, ux - 2, y + 4, 12, 1, "i1")
	# graduation ticks on the inner edges, every 24 px from the bottom
	var y_tick := 286
	while y_tick > 40:
		_rect(img, 24, y_tick, 4, 1, "z4")
		_rect(img, 84, y_tick, 4, 1, "z4")
		y_tick -= 24
	# the hour mark: bright brackets jutting into the glass, and a star of bronze
	for hx in [24, 80]:
		_rect(img, hx, 25, 8, 3, "z4")
		_rect(img, hx, 25, 8, 1, "z5")
	_px(img, 8, 26, "z5")
	_px(img, 7, 26, "z4")
	_px(img, 9, 26, "z4")
	_px(img, 8, 25, "z4")
	_px(img, 8, 27, "z4")
	_px(img, 103, 26, "z5")
	_px(img, 102, 26, "z4")
	_px(img, 104, 26, "z4")
	_px(img, 103, 25, "z4")
	_px(img, 103, 27, "z4")
	# capital
	_blocks(img, 6, 0, 100, 16, 20, 8, 72)
	_rect(img, 6, 0, 100, 2, "s4")
	_rect(img, 6, 15, 100, 2, "s1")
	# its dial, a bronze ring with one hand pointing up
	for a in range(0, 360, 12):
		var ang := deg_to_rad(float(a))
		_px(img, 56 + int(round(cos(ang) * 6.0)), 8 + int(round(sin(ang) * 6.0)), "z3")
	_rect(img, 56, 3, 1, 5, "z5")
	_px(img, 56, 8, "z4")
	_outline(img)
	return img


## The brass float on the tide: a squat drum with a short mast. 20x10.
func _float() -> Image:
	var img := _img(20, 10)
	_rect(img, 1, 4, 18, 6, "z2")
	_rect(img, 1, 4, 18, 1, "z4")
	_rect(img, 1, 9, 18, 1, "z1")
	_rect(img, 2, 6, 16, 1, "z3")
	_rect(img, 9, 0, 2, 4, "z3")
	_px(img, 9, 0, "z5")
	_px(img, 4, 7, "v2")
	_outline(img)
	return img


# ------------------------------------------------------------------ the Warden's things

## The Warden's carving: three lines of water, a snowflake over them, and a
## small bell: water held still by the cold rings the hour. 56x44.
func _warden_plaque() -> Image:
	var img := _img(56, 44)
	_rect(img, 1, 1, 54, 42, "s1")
	_rect(img, 1, 1, 54, 1, "s3")
	_rect(img, 3, 3, 50, 38, "s2")
	_rect(img, 3, 3, 50, 1, "s3")
	# water
	for i in 3:
		var y0 := 30 + i * 4
		for x in range(7, 32):
			_px(img, x, y0 + int(round(sin(x / 2.5 + i))), "m1")
	# snowflake
	var cx := 19
	var cy := 15
	for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
		for k in range(-6, 7):
			_px(img, cx + d.x * k, cy + d.y * k, "m1")
	for k in [-4, 4]:
		_px(img, cx + k, cy - 1, "m1")
		_px(img, cx + k, cy + 1, "m1")
		_px(img, cx - 1, cy + k, "m1")
		_px(img, cx + 1, cy + k, "m1")
	# an arrow from the water to the bell, and the bell
	for x in range(34, 41):
		_px(img, x, 24, "m1")
	_px(img, 39, 23, "m1")
	_px(img, 39, 25, "m1")
	_stamp_bell(img, 46, 16)
	_outline(img)
	return img


func _stamp_bell(img: Image, x: int, y: int) -> void:
	for row in 12:
		var half := 2 + row / 3
		_rect(img, x - half, y + row, half * 2, 1, "m1")
	_rect(img, x - 1, y - 2, 2, 2, "m1")
	_px(img, x, y + 13, "m1")


## A bronze water pipe down the wall: flanged joints, verdigris, and a valve
## wheel halfway. 18x128.
func _pipe() -> Image:
	var img := _img(18, 128)
	_rect(img, 5, 0, 8, 128, "z2")
	_rect(img, 5, 0, 1, 128, "z4")
	_rect(img, 12, 0, 1, 128, "z1")
	for y in [10, 52, 104]:
		_rect(img, 3, y, 12, 4, "z3")
		_rect(img, 3, y, 12, 1, "z5")
		_rect(img, 3, y + 3, 12, 1, "z1")
	for i in 16:
		var y := rng.randi_range(0, 126)
		_px(img, rng.randi_range(6, 11), y, "v2" if i % 2 == 0 else "v1")
	# valve wheel
	var cx := 9
	var cy := 76
	for a in range(0, 360, 15):
		var ang := deg_to_rad(float(a))
		_px(img, cx + int(round(cos(ang) * 7.0)), cy + int(round(sin(ang) * 7.0)), "i4")
	for k in range(-6, 7):
		_px(img, cx + k, cy, "i3")
		_px(img, cx, cy + k, "i3")
	_rect(img, cx - 1, cy - 1, 3, 3, "i5")
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
