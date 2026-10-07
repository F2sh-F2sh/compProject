extends SceneTree

## Makes the pixel sprites for the three places on the Novices' Way where
## Echidna remembers a word the Hush took (scripts/puzzle/ability_shrine.gd):
##   kept_flame  the monks' flame under glass (3 frames)   -> Fire
##   spring      a stone basin of running water (3 frames) -> Heal
##   echo_stone  a standing stone carved with sound waves (2 frames: dim,
##               remembered)                                -> Echo
## They are drawn at 1x for the dungeon (which the camera shows at 2x), in the
## packs' palette, and saved as PNG strips in res://assets/sprites/story/
## (SurfaceArt.STRIPS lists their frame counts). Re-run after editing:
##   godot --headless --path . --script res://tools/generate_shrine_sprites.gd

const OUT := "res://assets/sprites/story/"
const PREVIEW := "user://shrine_sprites_preview.png"

const PAL := {
	"o": "0b0d20", "O": "0a0614", "f": "0d0f24",
	"1": "12142e", "2": "1c2149", "3": "2d325c", "4": "3a3f72", "5": "545b86", "6": "6b73aa",
	"7": "8f99cc", "8": "c4cdef", "9": "dde4fa", "k": "7880b4", "l": "98a2d3", "n": "a9b4e0",
	"h": "221a2b", "p": "30253a", "q": "3c3044", "r": "54455c", "s": "6f6078",
	"v": "2f2756", "w": "3d3368", "x": "5e4d86", "m": "362c60",
	"t": "1a3740", "u": "27535a", "y": "3a7270", "z": "5f978f",
	"b": "2b6fd6", "c": "4aa8ff", "d": "a9d4ff",
}

var _previews: Array = []


var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	_save("kept_flame", [_kept_flame(0), _kept_flame(1), _kept_flame(2)])
	_save("spring", [_spring(0), _spring(1), _spring(2)])
	_save("echo_stone", [_echo_stone(false), _echo_stone(true)])
	_save_preview()
	print("SHRINE SPRITES DONE")
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


## Paints a small map (rows of palette letters, "." is clear) at (x, y).
func _stamp(img: Image, x: int, y: int, rows: Array) -> void:
	for r in rows.size():
		var row: String = rows[r]
		for c in row.length():
			if row[c] != ".":
				_px(img, x + c, y + r, row[c])


## A stone block with a lit left edge, a dark right edge and an outline.
func _stone(img: Image, x: int, y: int, w: int, h: int) -> void:
	_rect(img, x, y, w, h, "o")
	_rect(img, x + 1, y + 1, w - 2, h - 2, "4")
	_rect(img, x + 1, y + 1, 1, h - 2, "6")
	_rect(img, x + 1, y + 1, w - 2, 1, "6")
	_rect(img, x + w - 3, y + 2, 2, h - 3, "3")
	_rect(img, x + 1, y + h - 2, w - 2, 1, "2")


# ------------------------------------------------------------------ the Kept Flame

## The monks' flame: a small stone pedestal under a dome of glass, a blue
## flame burning inside, a flame glyph cut into the stone.
func _kept_flame(frame: int) -> Image:
	var img := _img(24, 42)
	# plinth, column, cap
	_stone(img, 2, 36, 20, 6)
	_stone(img, 7, 22, 10, 15)
	_stone(img, 4, 18, 16, 5)
	# the glyph: a flame in violet on the column
	_stamp(img, 10, 26, [
		".x.",
		"xwx",
		"xwx",
		".x.",
	])
	# the glass dome (an outline of pale glass, dark inside), a curve per row
	for y in range(3, 18):
		var t := float(y - 3) / 14.0
		var half := int(round(8.0 * sqrt(maxf(0.0, 1.0 - pow(1.0 - t, 2.0)))))
		half = maxi(half, 1)
		for x in range(12 - half, 12 + half):
			var edge := (x == 12 - half or x == 12 + half - 1)
			_px(img, x, y, "6" if edge else "1")
	_rect(img, 6, 17, 12, 1, "6")
	# a glint on the glass
	_px(img, 7, 9, "9")
	_px(img, 7, 10, "8")
	_px(img, 8, 7, "8")
	# the flame, three slightly different shapes
	var flames := [
		[
			"...c...",
			"..cdc..",
			"..cdc..",
			".bcddc.",
			".bcd9dc",
			".bcd9dc",
			"..bcdc.",
			"...bb..",
		],
		[
			"....c..",
			"...cdc.",
			"..cddc.",
			".bcddc.",
			".bcd9dc",
			".bcd9dc",
			"..bcdc.",
			"...bb..",
		],
		[
			"..c....",
			"..cdc..",
			"..cdc..",
			".bcddc.",
			"bcdd9c.",
			".bcd9dc",
			"..bcdc.",
			"...bb..",
		],
	]
	_stamp(img, 8, 9, flames[frame])
	# the flame's bowl on the cap
	_rect(img, 8, 16, 8, 1, "5")
	return img


# ------------------------------------------------------------------ the Spring

## A stone basin where a thin stream still runs: a carved spout above, the
## water in the bowl catching the light in a different place each frame.
func _spring(frame: int) -> Image:
	var img := _img(40, 30)
	# the spout: a stone post rising from the back of the basin, a pipe
	# reaching out over the water (drawn after the basin, below)
	# the basin
	_rect(img, 1, 17, 38, 13, "o")
	_rect(img, 2, 18, 36, 11, "4")
	_rect(img, 2, 18, 36, 2, "6")
	_rect(img, 3, 29, 34, 1, "o")
	_rect(img, 2, 27, 36, 2, "3")
	# brick joints
	for x in range(8, 36, 9):
		_rect(img, x, 22, 1, 7, "3")
	# the water
	_rect(img, 4, 20, 32, 5, "u")
	_rect(img, 4, 20, 32, 1, "z")
	_rect(img, 4, 21, 32, 3, "y")
	# light on the water
	for i in 4:
		var x := (4 + i * 8 + frame * 3) % 30 + 4
		_px(img, x, 21, "d")
		_px(img, x + 1, 21, "c")
		_px(img, (x + 4) % 30 + 4, 23, "c")
	# the post and its pipe
	_stone(img, 8, 0, 9, 19)
	_rect(img, 17, 6, 11, 4, "o")
	_rect(img, 17, 7, 10, 2, "5")
	_rect(img, 17, 7, 10, 1, "6")
	_rect(img, 26, 9, 3, 2, "o")
	_px(img, 27, 9, "5")
	# the stream from the pipe's lip, and the ripple where it lands
	for y in range(11, 21):
		_px(img, 27 + (1 if (y + frame) % 3 == 0 else 0), y, "d")
		_px(img, 27, y, "c")
	var ring := 1 + frame
	for dx in range(-ring - 1, ring + 2):
		_px(img, 27 + dx, 21 if abs(dx) == ring + 1 else 20, "d" if abs(dx) == ring + 1 else "c")
	# a fleck of moss
	_px(img, 3, 28, "y")
	_px(img, 4, 28, "u")
	return img


# ------------------------------------------------------------------ the Echo stone

## A tall stone with sound waves cut into it. Dim before the word returns;
## the waves glow once it has.
func _echo_stone(remembered: bool) -> Image:
	var img := _img(22, 44)
	# the slab: wider at the foot, with a rounded top
	for y in 44:
		var top := float(y) / 10.0
		var half := 9
		if y < 10:
			half = int(round(9.0 * sqrt(maxf(0.0, 1.0 - pow(1.0 - top, 2.0)))))
		var lean := 0
		for x in range(11 - half - lean, 11 + half + lean):
			var edge := x == 11 - half - lean or x == 11 + half + lean - 1 or y == 0 or y == 43
			_px(img, x, y, "o" if edge else "4")
		if half > 2:
			_px(img, 11 - half + 1, y, "6")
			_px(img, 11 + half - 2, y, "3")
			_px(img, 11 + half - 3, y, "3")
	_rect(img, 3, 40, 16, 3, "3")
	# a crack and a patch of moss
	for k in 5:
		_px(img, 14 - k % 2, 8 + k, "2")
	_px(img, 5, 41, "y")
	_px(img, 6, 41, "u")
	_px(img, 7, 42, "y")
	# the waves: three arcs opening to the right around a small dot
	var c := Vector2(8.0, 22.0)
	var wave := "c" if remembered else "x"
	var core := "d" if remembered else "w"
	for r in [4.0, 7.5, 11.0]:
		for y in range(8, 38):
			for x in range(8, 20):
				var d := Vector2(x, y).distance_to(c)
				if absf(d - r) < 0.55 and x >= 8:
					_px(img, x, y, wave)
	_rect(img, 7, 21, 2, 2, core)
	if remembered:
		_px(img, 7, 20, "d")
		_px(img, 9, 24, "c")
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
	img.fill(Color("14162e"))
	var y := pad
	for strip in _previews:
		var big: Image = strip.duplicate()
		big.resize(strip.get_width() * k, strip.get_height() * k, Image.INTERPOLATE_NEAREST)
		img.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(pad, y))
		y += big.get_height() + pad
	img.save_png(ProjectSettings.globalize_path(PREVIEW))
	print("  preview: ", ProjectSettings.globalize_path(PREVIEW))
