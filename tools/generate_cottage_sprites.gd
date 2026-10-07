extends SceneTree

## Makes the pixel sprites for the inside of Nan's cottage (scripts/story/
## nan_cottage.gd), in the surface and town packs' own palette (the same one
## tools/generate_story_sprites.gd uses), as PNG strips in
## res://assets/sprites/story/ (SurfaceArt.STRIPS lists their frame counts):
##   nan_seated   Nan in her armchair: sitting, breathing, blinking (3)
##   hearth       the hearth with a low blue fire, three flames (3)
##   table        a small wooden table (1)
##   shelf_jars   a wall shelf of jars whose labels the Hush has rubbed out (1)
##   cellar_door  the cellar door: shut, then open on the stair down (2)
## All face right; the game flips them. Re-run after editing a map:
##   godot --headless --path . --script res://tools/generate_cottage_sprites.gd

const OUT := "res://assets/sprites/story/"
const PREVIEW := "user://cottage_sprites_preview.png"

const PAL := {
	"o": "0b0d20", "O": "0a0614", "f": "0d0f24",
	"1": "12142e", "2": "1c2149", "3": "2d325c", "4": "3a3f72", "5": "545b86", "6": "6b73aa",
	"7": "8f99cc", "8": "c4cdef", "9": "dde4fa", "k": "7880b4", "l": "98a2d3", "n": "a9b4e0",
	"h": "221a2b", "p": "30253a", "q": "3c3044", "r": "54455c", "s": "6f6078", "i": "433449", "j": "5b4a62",
	"v": "2f2756", "w": "3d3368", "x": "5e4d86", "m": "362c60",
	"t": "1a3740", "u": "27535a", "y": "3a7270", "z": "5f978f",
	"b": "2b6fd6", "c": "4aa8ff", "d": "a9d4ff", "g": "6e6254",
}

## Nan from the head down to the shawl (the same figure as Lowbell's Nan).
const NAN_TOP := [
	"....ooooo.......",
	"...o78887o......",
	"..o7888887o.....",
	"..o7ooooo8o.....",
	"..o7offffo7o....",
	"...oof9f9fo.....",
	"...offffffo.....",
	"...ooffffoo.....",
	"..oxxoooowxo....",
	".oxwwwxxwwwxo...",
	".oxwwwwwwwwxoo..",
	"oxwwqqqqqwwxo...",
	"oxwqqqqqqqwxo...",
]

## The lower body, seated: hands in her lap, her knees out in front.
const NAN_LAP := [
	"oxwqqqqqqqwxo....",
	"oxqqqffqqqqwxoo..",
	"oqqqqffqqqqqiiioo",
	"oqqqqqqqqqqqqqqqo",
	"oqqqqqqqqqqqqqqqo",
	".ooooooooooooooo.",
]

const FLAMES := [
	[
		"....cc....",
		"...cddc...",
		"...cddc...",
		"..bcdd9c..",
		"..bcd99dc.",
		".bccd99dcc",
		".bcd9999dc",
		".bcd9999dc",
		".bcdd99ddc",
		"..bcdddcc.",
		"..bbcccb..",
		"...bbbb...",
	],
	[
		".....c....",
		"....cdc...",
		"...cddc...",
		"..bcdd9c..",
		"..bcd99dc.",
		".bccd99dcc",
		".bcd9999dc",
		".bcd9999dc",
		".bcdd99ddc",
		"..bcdddcc.",
		"..bbcccb..",
		"...bbbb...",
	],
	[
		"...c......",
		"..cdc.....",
		"..cddc....",
		"..bcdd9c..",
		".bcd99dc..",
		".bccd99dcc",
		".bcd9999dc",
		".bcd9999dc",
		".bcdd99ddc",
		"..bcdddcc.",
		"..bbcccb..",
		"...bbbb...",
	],
]

var _previews: Array = []
var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	_save("nan_seated", _nan_frames())
	_save("hearth", [_hearth(0), _hearth(1), _hearth(2)])
	_save("table", [_table()])
	_save("shelf_jars", [_shelf()])
	_save("cellar_door", [_cellar_door(false), _cellar_door(true)])
	_save_preview()
	print("COTTAGE SPRITES DONE")
	quit()


# ------------------------------------------------------------------ helpers

func _col(ch: String) -> Color:
	return Color(PAL[ch])


func _img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


func _rect(img: Image, x: int, y: int, w: int, h: int, ch: String) -> void:
	img.fill_rect(Rect2i(x, y, w, h), _col(ch))


func _px(img: Image, x: int, y: int, ch: String) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, _col(ch))


## Paints a map (rows of palette letters, "." is clear) at (x, y).
func _stamp(img: Image, x: int, y: int, rows: Array) -> void:
	for r in rows.size():
		var row: String = rows[r]
		for c in row.length():
			if row[c] != ".":
				_px(img, x + c, y + r, row[c])


## Wood: outline, a body, a lit top edge and a shaded underside.
func _wood(img: Image, x: int, y: int, w: int, h: int) -> void:
	_rect(img, x, y, w, h, "o")
	_rect(img, x + 1, y + 1, w - 2, h - 2, "r")
	_rect(img, x + 1, y + 1, w - 2, 1, "s")
	_rect(img, x + 1, y + h - 2, w - 2, 1, "q")


# ------------------------------------------------------------------ Nan, seated

func _nan_frames() -> Array:
	var frames: Array = []
	for frame in 3:
		var top: Array = NAN_TOP.duplicate()
		if frame == 2:
			# blinking: the pale eyes shut
			for i in top.size():
				if String(top[i]).contains("f9f9f"):
					top[i] = String(top[i]).replace("9", "f")
		var img := _img(26, 31)
		_chair(img)
		var lap: Array = NAN_LAP.duplicate()
		var body: Array = top.duplicate()
		body.append_array(lap)
		if frame == 1:
			# breathing in: the head and shawl rise a pixel
			body = body.slice(1, 9) + [body[8]] + body.slice(9)
		_stamp(img, 7, 3, body)
		# her feet, resting on the floor in front of the chair
		_stamp(img, 16, 26, ["ooffo", "ooooo"])
		frames.append(img)
	return frames


## The armchair: a tall wooden back behind her, a seat, and legs.
func _chair(img: Image) -> void:
	_wood(img, 0, 6, 8, 25)
	_rect(img, 2, 7, 1, 22, "j")
	_wood(img, 0, 2, 8, 6)
	_wood(img, 0, 22, 26, 4)
	_wood(img, 0, 26, 3, 5)
	_wood(img, 23, 26, 3, 5)
	# a worn cushion
	_rect(img, 8, 20, 14, 2, "x")
	_rect(img, 8, 20, 14, 1, "w")


# ------------------------------------------------------------------ the hearth

func _hearth(frame: int) -> Image:
	var img := _img(46, 40)
	# the stone body, with brick joints
	_rect(img, 0, 6, 46, 34, "o")
	_rect(img, 1, 7, 44, 32, "4")
	for y in range(9, 39, 5):
		_rect(img, 1, y, 44, 1, "3")
		var shift := 0 if (y / 5) % 2 == 0 else 5
		for x in range(1 + shift, 45, 10):
			_rect(img, x, y + 1, 1, 4, "3")
	_rect(img, 1, 7, 44, 1, "6")
	# the mantel
	_rect(img, 0, 0, 46, 8, "o")
	_rect(img, 1, 1, 44, 6, "5")
	_rect(img, 1, 1, 44, 2, "7")
	_rect(img, 1, 6, 44, 1, "3")
	# the firebox: an arch, dark inside
	_rect(img, 11, 14, 24, 26, "o")
	_rect(img, 12, 15, 22, 25, "1")
	_rect(img, 12, 15, 1, 25, "2")
	for k in 3:
		_rect(img, 11 + k, 14 + (2 - k), 1, 1, "4")
		_rect(img, 34 - k, 14 + (2 - k), 1, 1, "4")
	# the logs and a few embers
	_rect(img, 14, 36, 18, 3, "o")
	_rect(img, 15, 36, 16, 2, "j")
	_rect(img, 15, 36, 16, 1, "r")
	_rect(img, 18, 33, 12, 3, "o")
	_rect(img, 19, 33, 10, 2, "r")
	_rect(img, 19, 33, 10, 1, "s")
	# the flame, low
	_stamp(img, 18, 21, FLAMES[frame])
	_px(img, 16 + frame * 2, 35, "c")
	_px(img, 29 - frame, 34, "d")
	return img


# ------------------------------------------------------------------ the table

func _table() -> Image:
	var img := _img(34, 22)
	_wood(img, 0, 0, 34, 5)
	_rect(img, 1, 1, 32, 1, "s")
	_wood(img, 3, 5, 4, 17)
	_wood(img, 27, 5, 4, 17)
	_rect(img, 7, 7, 20, 2, "o")
	_rect(img, 7, 7, 20, 1, "q")
	return img


# ------------------------------------------------------------------ the jar shelf

func _shelf() -> Image:
	var img := _img(36, 28)
	# two shelves on brackets
	_wood(img, 0, 12, 36, 3)
	_wood(img, 0, 26, 36, 2)
	_rect(img, 3, 15, 2, 4, "o")
	_rect(img, 31, 15, 2, 4, "o")
	# jars on both shelves: teal, violet, and a pale one. Their labels are blank:
	# the Hush has taken the words.
	var jars := [
		[3, 3, 7, 9, "y", "z"], [12, 5, 6, 7, "x", "k"], [20, 2, 8, 10, "u", "z"], [29, 4, 5, 8, "w", "l"],
		[2, 17, 8, 9, "x", "k"], [12, 19, 6, 7, "y", "z"], [20, 16, 7, 10, "w", "l"], [29, 18, 5, 8, "u", "z"],
	]
	for j in jars:
		var x: int = j[0]
		var y: int = j[1]
		var w: int = j[2]
		var h: int = j[3]
		_rect(img, x, y, w, h, "o")
		_rect(img, x + 1, y + 1, w - 2, h - 2, j[4])
		_rect(img, x + 1, y + 1, 1, h - 2, j[5])
		_rect(img, x + 1, y - 1, w - 2, 1, "o")
		_rect(img, x + 1, y, w - 2, 1, "s")
		# the rubbed-out label
		if h >= 8:
			_rect(img, x + 2, y + h / 2, w - 4, 2, "n")
	return img


# ------------------------------------------------------------------ the cellar door

func _cellar_door(open: bool) -> Image:
	var img := _img(22, 34)
	# the stone arch round it
	_rect(img, 0, 6, 22, 28, "o")
	_rect(img, 1, 7, 20, 27, "4")
	_rect(img, 1, 7, 2, 27, "6")
	_rect(img, 19, 8, 2, 26, "3")
	for k in 6:
		_rect(img, k, 6 - k, 22 - 2 * k, 1, "o")
		_rect(img, k + 1, 7 - k, 20 - 2 * k, 1, "5" if k < 5 else "4")
	# the doorway
	_rect(img, 4, 11, 14, 23, "o")
	if not open:
		_rect(img, 5, 12, 12, 22, "r")
		for x in [8, 11, 14]:
			_rect(img, x, 12, 1, 22, "q")
		_rect(img, 5, 12, 12, 1, "s")
		# iron straps and a ring
		_rect(img, 5, 16, 12, 2, "o")
		_rect(img, 5, 27, 12, 2, "o")
		_rect(img, 5, 16, 12, 1, "5")
		_rect(img, 5, 27, 12, 1, "5")
		_px(img, 14, 22, "o")
		_px(img, 15, 22, "5")
		_px(img, 14, 23, "5")
		_px(img, 15, 23, "o")
	else:
		# open on the dark of the stair: a few steps going down, a pale glimmer
		_rect(img, 5, 12, 12, 22, "f")
		for k in 4:
			_rect(img, 5 + k, 24 + k * 2, 12 - k, 2, "2" if k % 2 == 0 else "1")
			_rect(img, 5 + k, 24 + k * 2, 12 - k, 1, "3")
		_rect(img, 5, 12, 3, 22, "h")
		_rect(img, 5, 12, 1, 22, "r")
		_px(img, 14, 17, "5")
		_px(img, 15, 18, "3")
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
	var k := 8
	var pad := 12
	var width := 0
	var height := pad
	for strip in _previews:
		width = maxi(width, strip.get_width() * k + pad * 2)
		height += strip.get_height() * k + pad
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color("3b3a55"))
	var y := pad
	for strip in _previews:
		var big: Image = strip.duplicate()
		big.resize(strip.get_width() * k, strip.get_height() * k, Image.INTERPOLATE_NEAREST)
		img.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(pad, y))
		y += big.get_height() + pad
	img.save_png(ProjectSettings.globalize_path(PREVIEW))
	print("  preview: ", ProjectSettings.globalize_path(PREVIEW))
