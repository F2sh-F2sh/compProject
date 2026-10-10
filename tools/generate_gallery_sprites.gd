extends SceneTree

## Makes the pixel sprites for the Folded Galleries:
##   wren              Ilse's daughter, the girl who leaves chalk stars: a small
##                     figure in a pale nightdress, frost on her hair, chalk in
##                     her hand (3 frames: looking, glancing, blinking, like the
##                     other people's strips)
##   archivist_plaque  the Archivist's carving: a door inside a door inside a door
##   scroll_rack       a rack of the archive's star-scrolls (decoration)
##   seal_fire, seal_ice, seal_light, seal_space
##                     the four seals on Wren's door, one for each wing's magic
##                     (2 frames: dark stone, lit)
##   chalk_hands       Wren's chalk drawing of two figures holding hands
## Drawn at 1x for the dungeon (the camera shows it at 2x), lit from the top
## left with a dark outline, in the dungeon's purples. Saved as PNG strips in
## res://assets/sprites/story/ (SurfaceArt.STRIPS lists their frame counts).
##   godot --headless --path . --script res://tools/generate_gallery_sprites.gd

const OUT := "res://assets/sprites/story/"
const PREVIEW := "user://gallery_sprites_preview.png"

const C := {
	# outline and shadow
	"k0": "0d0b16", "k1": "1a1828", "k2": "26243a",
	# dungeon stone
	"s1": "3a3346", "s2": "544a62", "s3": "6e6480", "s4": "8a80a0",
	# nightdress and frost
	"w1": "8e88b0", "w2": "b8b4d8", "w3": "dcdaf2", "w4": "f4f4ff",
	"fr": "9fd8ff",
	# hair
	"h1": "4a3a2c", "h2": "6c5440",
	# wood
	"d0": "2a1a16", "d1": "4a2e22", "d2": "6a4430", "d3": "8c5c3c",
	# parchment
	"p0": "8c7a5c", "p1": "c8b89a", "p2": "e8dcc0",
	# the seals' colours (dark, mid, bright, glow)
	"fire0": "4a2418", "fire1": "c0581c", "fire2": "f4a038", "fire3": "fff0c0",
	"ice0": "1e3a4a", "ice1": "3c8aa8", "ice2": "8ad8f0", "ice3": "eaffff",
	"light0": "4a3e1c", "light1": "b89a3c", "light2": "f4dc80", "light3": "fffbe0",
	"space0": "2e1e4a", "space1": "7a4cc0", "space2": "c4a0ff", "space3": "f4ecff",
	# chalk
	"c0": "e8e8f4",
}

var _previews: Array = []
var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	_save("archivist_plaque", [_plaque()])
	_save("scroll_rack", [_scroll_rack()])
	for kind in ["fire", "ice", "light", "space"]:
		_save("seal_" + kind, [_seal(kind, false), _seal(kind, true)])
	_save("chalk_hands", [_chalk_hands()])
	_save_preview()
	print("GALLERY SPRITES DONE")
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


## A dark outline round everything drawn.
func _outline(img: Image, key := "k0") -> void:
	var w := img.get_width()
	var h := img.get_height()
	var src := img.duplicate() as Image
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x >= 0 and p.y >= 0 and p.x < w and p.y < h and src.get_pixel(p.x, p.y).a > 0.0:
					img.set_pixel(x, y, _c(key))
					break


# ------------------------------------------------------------------ Wren

## 12x19: a small girl in a nightdress, frost on her hair, a stub of chalk in
## her right hand. `frame` 0 looks ahead, 1 glances, 2 blinks.
func _wren(frame: int) -> Image:
	var img := _img(12, 19)
	# hair: a round bob with two short plaits
	_rect(img, 3, 1, 6, 1, "h1")
	_rect(img, 2, 2, 8, 4, "h1")
	_rect(img, 3, 2, 5, 1, "h2")
	_px(img, 1, 5, "h1")
	_px(img, 10, 5, "h1")
	_px(img, 1, 6, "h2")
	_px(img, 10, 6, "h2")
	# frost on the crown
	_px(img, 4, 1, "fr")
	_px(img, 7, 1, "fr")
	_px(img, 5, 2, "w4")
	# face in shadow, like everyone's
	_rect(img, 3, 4, 6, 4, "k1")
	_rect(img, 4, 8, 4, 1, "k1")
	if frame != 2:
		var ex := 4 if frame == 0 else 5
		_px(img, ex, 5, "w4")
		_px(img, ex + 3, 5, "w4")
	else:
		_px(img, 4, 6, "w2")
		_px(img, 7, 6, "w2")
	# nightdress, widening to the hem, lit from the top left
	for y in range(9, 18):
		var half := 2 + (y - 9) / 3
		_rect(img, 6 - half, y, half * 2, 1, "w2")
		_px(img, 6 - half, y, "w3")
		_px(img, 5 + half, y, "w1")
	_rect(img, 4, 9, 4, 1, "w3")
	# arms, a hand with chalk
	_px(img, 2, 11, "w2")
	_px(img, 2, 12, "w1")
	_px(img, 9, 11, "w2")
	_px(img, 9, 12, "k1")
	_px(img, 10, 12, "c0")
	# feet
	_px(img, 4, 18, "k1")
	_px(img, 7, 18, "k1")
	_outline(img)
	return img


# ------------------------------------------------------------------ the Archive

## 56x44: the Archivist's carving, a door inside a door inside a door.
func _plaque() -> Image:
	var img := _img(56, 44)
	_rect(img, 1, 1, 54, 42, "s2")
	_rect(img, 1, 1, 54, 2, "s3")
	_rect(img, 1, 41, 54, 2, "s1")
	for i in 3:
		var w := 30 - i * 8
		var h := 34 - i * 9
		var x := 28 - w / 2
		var y := 40 - h
		_rect(img, x, y, w, h, "s1" if i % 2 == 0 else "k2")
		_rect(img, x + 1, y + 1, w - 2, 1, "s3")
		_rect(img, x + w / 2, y + h / 2, 1, 2, "space2")
	_px(img, 28, 14, "space3")
	_outline(img)
	return img


## 48x96: a wooden rack of rolled star-scrolls.
func _scroll_rack() -> Image:
	var img := _img(48, 96)
	_rect(img, 2, 2, 44, 94, "d1")
	_rect(img, 2, 2, 44, 2, "d3")
	_rect(img, 4, 4, 40, 90, "d0")
	for shelf in 5:
		var y := 6 + shelf * 18
		_rect(img, 4, y + 14, 40, 2, "d2")
		for k in 6:
			var x := 6 + k * 6 + (shelf % 2) * 2
			if (k + shelf) % 5 == 4:
				continue
			_rect(img, x, y + 6, 5, 8, "p1")
			_rect(img, x, y + 6, 5, 1, "p2")
			_rect(img, x + 1, y + 9, 3, 1, "p0")
	_outline(img)
	return img


## 24x24: one of the four seals on Wren's door, a disc of stone with its
## wing's colour; lit, it glows.
func _seal(kind: String, lit: bool) -> Image:
	var img := _img(24, 24)
	var dark := kind + "0"
	var mid := kind + "1"
	var bright := kind + "2"
	var glow := kind + "3"
	for y in 24:
		for x in 24:
			var d := Vector2(x - 11.5, y - 11.5).length()
			if d <= 11.0:
				_px(img, x, y, "s2" if d > 9.0 else ("s3" if x + y < 18 else "s1"))
	for y in 24:
		for x in 24:
			var d := Vector2(x - 11.5, y - 11.5).length()
			if d <= 7.0:
				_px(img, x, y, (bright if d < 4.0 else mid) if lit else dark)
	# the wing's mark in the middle
	match kind:
		"fire":
			for p in [Vector2i(11, 8), Vector2i(12, 9), Vector2i(10, 10), Vector2i(11, 10), Vector2i(12, 11), Vector2i(11, 12), Vector2i(10, 13), Vector2i(12, 13), Vector2i(11, 14)]:
				_px(img, p.x, p.y, glow if lit else mid)
		"ice":
			for i in range(8, 16):
				_px(img, 11, i, glow if lit else mid)
				_px(img, i, 11, glow if lit else mid)
			for p in [Vector2i(9, 9), Vector2i(13, 13), Vector2i(13, 9), Vector2i(9, 13)]:
				_px(img, p.x, p.y, glow if lit else mid)
		"light":
			_rect(img, 10, 10, 4, 4, glow if lit else mid)
			for p in [Vector2i(11, 7), Vector2i(11, 16), Vector2i(7, 11), Vector2i(16, 11)]:
				_px(img, p.x, p.y, glow if lit else mid)
		"space":
			for i in 5:
				_px(img, 9 + i, 9, glow if lit else mid)
				_px(img, 9 + i, 13, glow if lit else mid)
				_px(img, 9, 9 + i, glow if lit else mid)
				_px(img, 13, 9 + i, glow if lit else mid)
			_px(img, 11, 11, glow if lit else mid)
	_outline(img)
	return img


## 24x20: Wren's chalk, two figures holding hands under a star.
func _chalk_hands() -> Image:
	var img := _img(24, 20)
	for fig in [7, 16]:
		_px(img, fig, 7, "c0")
		_px(img, fig - 1, 8, "c0")
		_px(img, fig + 1, 8, "c0")
		_px(img, fig, 8, "c0")
		for y in range(9, 15):
			_px(img, fig, y, "c0")
		_px(img, fig - 1, 15, "c0")
		_px(img, fig + 1, 15, "c0")
		_px(img, fig - 2, 16, "c0")
		_px(img, fig + 2, 16, "c0")
	for x in range(8, 16):
		_px(img, x, 11, "c0")
	for p in [Vector2i(11, 1), Vector2i(12, 2), Vector2i(10, 2), Vector2i(11, 3), Vector2i(11, 2), Vector2i(13, 2), Vector2i(9, 2)]:
		_px(img, p.x, p.y, "c0")
	return img


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


## Everything side by side at 4x on stone, to look at.
func _save_preview() -> void:
	var gap := 8
	var w := gap
	var h := 0
	for p in _previews:
		w += p.get_width() * 4 + gap
		h = maxi(h, p.get_height() * 4)
	var sheet := _img(w, h + gap * 2)
	sheet.fill(_c("s1"))
	var x := gap
	for p: Image in _previews:
		var big := p.duplicate() as Image
		big.resize(p.get_width() * 4, p.get_height() * 4, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(x, gap))
		x += big.get_width() + gap
	sheet.save_png(ProjectSettings.globalize_path(PREVIEW))
