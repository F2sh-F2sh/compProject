extends SceneTree

## Makes the dungeon UI kit (dark carved stone, gold filigree, crimson gems)
## and the project's Theme built from it:
##   assets/ui/panel.png          the main 9-slice panel (stone, iron frame,
##                                gold corner brackets with a crimson gem)
##   assets/ui/panel_lite.png     a plainer box for things inside a panel
##   assets/ui/crest_h.png, crest_v.png   the gold crest set at the middle of
##                                a panel's edges (DungeonUI.decorate)
##   assets/ui/button_*.png       stone plates: idle, hover, pressed,
##                                disabled, and the gold focus rim
##   assets/ui/banner.png         a crimson banner with gold edges (headings)
##   assets/ui/divider.png        a gold rule with a gem at its middle
##   assets/ui/nameplate.png      the gold plate a speaker's name sits on
##   assets/ui/slider_*.png, check_*.png, scroll_*.png, bar_frame.png,
##   assets/ui/parchment.png      the rest of the controls, and the page
##   assets/ui/arrow.png          the gold pointer beside a focused choice
##   assets/ui/dungeon_theme.tres the Theme (project setting gui/theme/custom)
## Drawn at 1x, saved at 2x (each art pixel two screen pixels at 1152x648).
##   godot --headless --path . --script res://tools/art/generate_ui_sprites.gd

const OUT := "res://assets/ui/"
const PREVIEW := "user://ui_sprites_preview.png"
const S := 2

const C := {
	"k0": "07060a",
	"s0": "100e13", "s1": "16131a", "s2": "1d1922", "s3": "292430", "s4": "38323f", "s5": "4b4454",
	"g0": "4a3a1c", "g1": "7a5f2a", "g2": "b08a3e", "g3": "d9b25a", "g4": "f6dc8c",
	"r0": "3a0d14", "r1": "6a1824", "r2": "9e2a3a", "r3": "d24a5a", "r4": "ffb0a0",
	"p0": "3b2f22", "p1": "7d6747", "p2": "b9a27a", "p3": "d8c59c", "p4": "eee0bc",
}
const FONT_UI := "res://assets/fonts/patrick_hand/PatrickHand-Regular.ttf"
const FONT_UI_BOLD := "res://assets/fonts/patrick_hand/PatrickHand-Regular.ttf"
const FONT_STORY := "res://assets/fonts/patrick_hand/PatrickHand-Regular.ttf"
const FONT_TITLE := "res://assets/fonts/im_fell_english/IMFellEnglish-Regular.ttf"
const FONT_BOOK := "res://assets/fonts/im_fell_english/IMFellEnglish-Regular.ttf"

var rng := RandomNumberGenerator.new()
var _previews: Array = []


func _init() -> void:
	rng.seed = 7341
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save("panel", _panel())
	_save("panel_lite", _panel_lite())
	_save("crest_h", _crest())
	var v := _crest()
	v.rotate_90(CLOCKWISE)
	_save("crest_v", v)
	_save("button_idle", _button(0))
	_save("button_hover", _button(1))
	_save("button_pressed", _button(2))
	_save("button_disabled", _button(3))
	_save("button_focus", _focus_rim())
	_save("banner", _banner())
	_save("divider", _divider())
	_save("rule", _rule())
	_save("rule_gem", _rule_gem())
	_save("nameplate", _nameplate())
	_save("slider_track", _track(false))
	_save("slider_fill", _track(true))
	_save("slider_grabber", _gem_knob(false))
	_save("slider_grabber_hi", _gem_knob(true))
	_save("check_off", _check(false))
	_save("check_on", _check(true))
	_save("scroll_track", _scroll_track())
	_save("scroll_grabber", _scroll_grabber(false))
	_save("scroll_grabber_hi", _scroll_grabber(true))
	_save("bar_frame", _bar_frame())
	_save("parchment", _parchment())
	_save("arrow", _arrow())
	_save_preview()
	_build_theme()
	print("UI SPRITES DONE")
	quit()


# ------------------------------------------------------------------ helpers

func _c(key: String) -> Color:
	return Color(C[key])


func _img(w: int, h: int) -> Image:
	return Image.create(w, h, false, Image.FORMAT_RGBA8)


func _px(img: Image, x: int, y: int, key: String) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, _c(key))


func _rect(img: Image, x: int, y: int, w: int, h: int, key: String) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, _c(key))


## Stone: a base colour with a sparse, soft dither of the shades either side.
func _stone(img: Image, r: Rect2i, base: String, dark: String, light: String) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var n := rng.randf()
			_px(img, x, y, dark if n < 0.08 else (light if n > 0.94 else base))


## Copies `piece` onto `img` at `at`, mirrored as asked (alpha only where set).
func _stamp(img: Image, piece: Image, at: Vector2i, fx := false, fy := false) -> void:
	var w := piece.get_width()
	var h := piece.get_height()
	for y in h:
		for x in w:
			var col := piece.get_pixel(w - 1 - x if fx else x, h - 1 - y if fy else y)
			if col.a > 0.0:
				var px := at.x + x
				var py := at.y + y
				if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
					img.set_pixel(px, py, col)


## A small crimson gem, a diamond `r` pixels from its centre.
func _gem(img: Image, cx: int, cy: int, r: int) -> void:
	for y in range(-r, r + 1):
		for x in range(-r, r + 1):
			var d := absi(x) + absi(y)
			if d > r:
				continue
			var key := "r1" if d == r else ("r3" if x + y < 0 else "r2")
			_px(img, cx + x, cy + y, key)
	_px(img, cx - 1, cy - 1, "r4")


# ------------------------------------------------------------------ the panel

## The corner piece (top-left; mirrored for the others): gold brackets along
## the frame with leaf ends, a crimson gem, and small gold beads.
func _corner_piece() -> Image:
	var p := _img(14, 14)
	# the bracket: two arms along the frame, light on top/left, dark under
	for i in 10:
		_px(p, i, 1, "g3")
		_px(p, i, 2, "g1")
		_px(p, 1, i, "g3")
		_px(p, 2, i, "g1")
	_px(p, 1, 1, "g4")
	_px(p, 2, 2, "g2")
	# leaf ends of the arms
	for e in [[10, 1], [11, 2], [10, 3]]:
		_px(p, e[0], e[1], "g2")
		_px(p, e[1], e[0], "g2")
	_px(p, 9, 3, "g1")
	_px(p, 3, 9, "g1")
	# the inner curl and the gem in the crook
	for c in [[4, 7], [5, 8], [6, 8], [7, 7], [7, 6], [7, 5], [8, 4], [8, 3]]:
		_px(p, c[0], c[1], "g2")
		_px(p, c[1], c[0], "g2")
	_gem(p, 5, 5, 2)
	_px(p, 9, 9, "g3")
	_px(p, 10, 10, "g1")
	return p


func _frame(img: Image, w: int, h: int) -> void:
	# outline, iron frame (lit from the top left), and an inner dark line
	_rect(img, 0, 0, w, 1, "k0")
	_rect(img, 0, h - 1, w, 1, "k0")
	_rect(img, 0, 0, 1, h, "k0")
	_rect(img, w - 1, 0, 1, h, "k0")
	_rect(img, 1, 1, w - 2, 1, "s5")
	_rect(img, 1, 2, w - 2, 1, "s4")
	_rect(img, 1, 1, 1, h - 2, "s5")
	_rect(img, 2, 1, 1, h - 3, "s4")
	_rect(img, 1, h - 2, w - 2, 1, "s2")
	_rect(img, 2, h - 3, w - 3, 1, "s3")
	_rect(img, w - 2, 1, 1, h - 2, "s2")
	_rect(img, w - 3, 2, 1, h - 4, "s3")
	_rect(img, 3, 3, w - 6, 1, "k0")
	_rect(img, 3, h - 4, w - 6, 1, "k0")
	_rect(img, 3, 3, 1, h - 6, "k0")
	_rect(img, w - 4, 3, 1, h - 6, "k0")
	# a faint gold pinstripe inside the frame
	_rect(img, 5, 5, w - 10, 1, "g0")
	_rect(img, 5, h - 6, w - 10, 1, "g0")
	_rect(img, 5, 5, 1, h - 10, "g0")
	_rect(img, w - 6, 5, 1, h - 10, "g0")


func _panel() -> Image:
	var w := 40
	var h := 40
	var img := _img(w, h)
	_stone(img, Rect2i(1, 1, w - 2, h - 2), "s1", "s0", "s2")
	_frame(img, w, h)
	var corner := _corner_piece()
	_stamp(img, corner, Vector2i(0, 0))
	_stamp(img, corner, Vector2i(w - 14, 0), true, false)
	_stamp(img, corner, Vector2i(0, h - 14), false, true)
	_stamp(img, corner, Vector2i(w - 14, h - 14), true, true)
	return img


func _panel_lite() -> Image:
	var w := 16
	var h := 16
	var img := _img(w, h)
	_stone(img, Rect2i(1, 1, w - 2, h - 2), "s0", "k0", "s1")
	_rect(img, 0, 0, w, 1, "g0")
	_rect(img, 0, h - 1, w, 1, "g0")
	_rect(img, 0, 0, 1, h, "g0")
	_rect(img, w - 1, 0, 1, h, "g0")
	_rect(img, 1, 1, w - 2, 1, "s2")
	for c in [[0, 0], [w - 1, 0], [0, h - 1], [w - 1, h - 1]]:
		_px(img, c[0], c[1], "g3")
	return img


## The crest set at the middle of a panel's top and bottom edges: a gold
## arrow-and-scroll with a crimson gem at its heart.
func _crest() -> Image:
	var img := _img(23, 9)
	for x in range(0, 23):
		var d := absi(x - 11)
		if d > 10:
			continue
		_px(img, x, 4, "g1")
		if d < 9:
			_px(img, x, 3, "g3" if d > 3 else "g2")
			_px(img, x, 5, "g1")
		if d < 6:
			_px(img, x, 2, "g2")
			_px(img, x, 6, "g0")
		if d < 3:
			_px(img, x, 1, "g3")
			_px(img, x, 7, "g1")
	for e in [[0, 3], [0, 5], [22, 3], [22, 5], [1, 2], [21, 2], [1, 6], [21, 6]]:
		_px(img, e[0], e[1], "g2")
	_gem(img, 11, 4, 3)
	return img


# ------------------------------------------------------------------ buttons

## 0 idle, 1 hover, 2 pressed, 3 disabled.
func _button(state: int) -> Image:
	var w := 24
	var h := 14
	var img := _img(w, h)
	var fill: String = ["s3", "s4", "s2", "s2"][state]
	var lit: String = ["s5", "s5", "s1", "s3"][state]
	var lit2: String = ["s4", "s4", "s2", "s2"][state]
	var dark: String = ["s2", "s2", "s3", "s1"][state]
	_stone(img, Rect2i(1, 1, w - 2, h - 2), fill, dark, lit2)
	_rect(img, 1, 1, w - 2, 1, lit)
	_rect(img, 1, 2, w - 2, 1, lit2)
	_rect(img, 1, h - 2, w - 2, 1, dark)
	_rect(img, 1, 1, 1, h - 2, lit2)
	_rect(img, w - 2, 1, 1, h - 2, dark)
	var edge := "g2" if state == 1 else ("g1" if state == 2 else "k0")
	_rect(img, 0, 0, w, 1, edge)
	_rect(img, 0, h - 1, w, 1, edge)
	_rect(img, 0, 0, 1, h, edge)
	_rect(img, w - 1, 0, 1, h, edge)
	if state == 1:
		# a crimson glow just inside the gold rim
		_rect(img, 2, h - 3, w - 4, 1, "r1")
		_rect(img, 2, 3, 1, h - 6, "r0")
		_rect(img, w - 3, 3, 1, h - 6, "r0")
	if state != 3:
		var rivet := "g4" if state == 1 else "g1"
		for c in [[2, 2], [w - 3, 2], [2, h - 3], [w - 3, h - 3]]:
			_px(img, c[0], c[1], rivet)
	return img


func _focus_rim() -> Image:
	var w := 24
	var h := 14
	var img := _img(w, h)
	_rect(img, 0, 0, w, 1, "g3")
	_rect(img, 0, h - 1, w, 1, "g1")
	_rect(img, 0, 0, 1, h, "g3")
	_rect(img, w - 1, 0, 1, h, "g1")
	for c in [[0, 0], [w - 1, 0], [0, h - 1], [w - 1, h - 1]]:
		_px(img, c[0], c[1], "g4")
	return img


func _banner() -> Image:
	var w := 32
	var h := 14
	var img := _img(w, h)
	for y in h:
		for x in w:
			# swallowtail ends
			var notch := absi(y - h / 2)
			if x < 4 - notch / 2 or x > w - 5 + notch / 2:
				continue
			var key := "r1"
			if y <= 1:
				key = "g2" if y == 0 else "g3"
			elif y >= h - 2:
				key = "g1" if y == h - 1 else "g0"
			elif y == 2:
				key = "r3"
			elif y == 3:
				key = "r2"
			elif y >= h - 4:
				key = "r0"
			_px(img, x, y, key)
	for y in range(2, h - 2):
		_px(img, 6, y, "g1")
		_px(img, w - 7, y, "g1")
	return img


func _divider() -> Image:
	var img := _img(64, 7)
	for x in 64:
		var d := absi(x - 32)
		_px(img, x, 3, "g1" if d > 20 else "g2")
		if d < 26:
			_px(img, x, 2, "g0" if d > 14 else "g3")
	for e in [[0, 3], [63, 3]]:
		_px(img, e[0], e[1], "g3")
	_gem(img, 32, 3, 3)
	for side in [-1, 1]:
		_px(img, 32 + side * 6, 3, "g4")
		_px(img, 32 + side * 7, 2, "g2")
		_px(img, 32 + side * 7, 4, "g2")
	return img




## A tileable gold rule (DungeonUI.divider stretches it either side of the gem).
func _rule() -> Image:
	var img := _img(8, 7)
	for x in 8:
		_px(img, x, 2, "g3")
		_px(img, x, 3, "g1")
	_px(img, 3, 3, "g2")
	return img


## The rule's middle: a crimson gem between two gold curls.
func _rule_gem() -> Image:
	var img := _img(21, 7)
	for x in 21:
		var d := absi(x - 10)
		if d > 7:
			_px(img, x, 2, "g3")
			_px(img, x, 3, "g1")
	for side in [-1, 1]:
		for c in [[6, 1], [7, 1], [8, 2], [7, 4], [6, 5], [5, 4], [5, 3]]:
			_px(img, 10 + side * c[0], c[1], "g2")
		_px(img, 10 + side * 9, 3, "g4")
	_gem(img, 10, 3, 3)
	return img
func _nameplate() -> Image:
	var w := 32
	var h := 12
	var img := _img(w, h)
	_rect(img, 2, 0, w - 4, h, "k0")
	for y in range(1, h - 1):
		for x in range(3, w - 3):
			_px(img, x, y, "g3" if y <= 2 else ("g1" if y >= h - 3 else "g2"))
	_rect(img, 4, 2, w - 8, 1, "g4")
	for side in [0, w - 1]:
		var dir := 1 if side == 0 else -1
		_gem(img, side + dir * 2, h / 2, 2)
	return img


# ------------------------------------------------------------------ small controls

func _track(filled: bool) -> Image:
	var img := _img(12, 6)
	_rect(img, 0, 0, 12, 6, "k0")
	_rect(img, 1, 1, 10, 4, "r1" if filled else "s0")
	_rect(img, 1, 1, 10, 1, "r3" if filled else "k0")
	_rect(img, 1, 4, 10, 1, "r0" if filled else "s1")
	return img


func _gem_knob(hi: bool) -> Image:
	var img := _img(11, 11)
	for y in range(-5, 6):
		for x in range(-5, 6):
			var d := absi(x) + absi(y)
			if d > 5:
				continue
			_px(img, 5 + x, 5 + y, "k0" if d == 5 else ("g4" if hi and x + y < -1 else ("g3" if x + y < 0 else "g1")))
	_gem(img, 5, 5, 2)
	return img


func _check(on: bool) -> Image:
	var img := _img(11, 11)
	_rect(img, 0, 0, 11, 11, "k0")
	_stone(img, Rect2i(1, 1, 9, 9), "s1", "s0", "s2")
	_rect(img, 1, 1, 9, 1, "g1")
	_rect(img, 1, 9, 9, 1, "g0")
	_rect(img, 1, 1, 1, 9, "g1")
	_rect(img, 9, 1, 1, 9, "g0")
	if on:
		_gem(img, 5, 5, 3)
	return img


func _scroll_track() -> Image:
	var img := _img(6, 12)
	_rect(img, 0, 0, 6, 12, "k0")
	_rect(img, 1, 1, 4, 10, "s0")
	return img


func _scroll_grabber(hi: bool) -> Image:
	var img := _img(6, 12)
	_rect(img, 0, 0, 6, 12, "k0")
	_rect(img, 1, 1, 4, 10, "g3" if hi else "g2")
	_rect(img, 1, 1, 1, 10, "g4" if hi else "g3")
	_rect(img, 4, 1, 1, 10, "g1")
	_px(img, 2, 5, "r2")
	_px(img, 3, 6, "r2")
	return img


func _bar_frame() -> Image:
	var w := 20
	var h := 10
	var img := _img(w, h)
	_rect(img, 0, 0, w, 1, "k0")
	_rect(img, 0, h - 1, w, 1, "k0")
	_rect(img, 0, 0, 1, h, "k0")
	_rect(img, w - 1, 0, 1, h, "k0")
	_rect(img, 1, 1, w - 2, 1, "s5")
	_rect(img, 1, h - 2, w - 2, 1, "s2")
	_rect(img, 1, 1, 1, h - 2, "s4")
	_rect(img, w - 2, 1, 1, h - 2, "s2")
	_rect(img, 2, 2, w - 4, 1, "k0")
	_rect(img, 2, h - 3, w - 4, 1, "k0")
	_rect(img, 2, 2, 1, h - 4, "k0")
	_rect(img, w - 3, 2, 1, h - 4, "k0")
	for c in [[1, 1], [w - 2, 1], [1, h - 2], [w - 2, h - 2]]:
		_px(img, c[0], c[1], "g2")
	return img


func _parchment() -> Image:
	var w := 40
	var h := 40
	var img := _img(w, h)
	for y in h:
		for x in w:
			var edge := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			# ragged edges: some edge pixels missing, then a darker border
			if edge == 0 and rng.randf() < 0.35:
				continue
			var n := rng.randf()
			var key := "p3"
			if edge <= 1:
				key = "p1"
			elif edge <= 3:
				key = "p2" if n < 0.6 else "p1"
			elif n < 0.1:
				key = "p2"
			elif n > 0.93:
				key = "p4"
			_px(img, x, y, key)
	# burnt corners
	for c in [[0, 0], [w - 1, 0], [0, h - 1], [w - 1, h - 1]]:
		for k in 3:
			_px(img, c[0] + (k if c[0] == 0 else -k), c[1], "p0")
			_px(img, c[0], c[1] + (k if c[1] == 0 else -k), "p0")
	return img


func _arrow() -> Image:
	var img := _img(6, 9)
	for y in 9:
		var reach := 4 - absi(y - 4)
		for x in range(0, reach + 1):
			_px(img, x, y, "k0" if x == reach else ("g4" if y < 4 else "g2"))
	return img


# ------------------------------------------------------------------ saving

func _save(sprite_name: String, img: Image) -> void:
	var big := img.duplicate()
	big.resize(img.get_width() * S, img.get_height() * S, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path(OUT + sprite_name + ".png"))
	_previews.append(big)


func _save_preview() -> void:
	var w := 0
	var h := 0
	for p in _previews:
		w = maxi(w, p.get_width())
		h += p.get_height() + 6
	var sheet := _img(w * 2 + 8, h)
	sheet.fill(Color("3a3442"))
	var y := 0
	for p in _previews:
		sheet.blit_rect(p, Rect2i(Vector2i.ZERO, p.get_size()), Vector2i(4, y))
		y += p.get_height() + 6
	sheet.save_png(ProjectSettings.globalize_path(PREVIEW))


# ------------------------------------------------------------------ the theme

## A 9-slice style from one of the kit's textures; margins in art pixels.
func _box(sprite_name: String, margin: int, content: Vector4 = Vector4(-1, -1, -1, -1), tile := true) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(OUT + sprite_name + ".png")
	sb.set_texture_margin_all(margin * S)
	var c := content if content.x >= 0.0 else Vector4(margin * S + 4, margin * S, margin * S + 4, margin * S)
	sb.content_margin_left = c.x
	sb.content_margin_top = c.y
	sb.content_margin_right = c.z
	sb.content_margin_bottom = c.w
	if tile:
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	return sb


func _build_theme() -> void:
	# (the textures must be imported first: run with --import before this)
	if not ResourceLoader.exists(OUT + "panel.png"):
		print("UI THEME SKIPPED: import the textures first")
		return
	var ink := Color("e8dcc0")
	var gold := Color("f0d27a")
	var gold_dim := Color("c9a24a")
	var dim := Color("7d7286")
	var t := Theme.new()
	t.default_font = load(FONT_STORY)
	t.default_font_size = 20
	t.set_color("font_color", "Label", ink)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.0))
	var panel := _box("panel", 12, Vector4(28, 24, 28, 24))
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	# Buttons: stone plates, gold rim when hovered or focused
	var button_content := Vector4(16, 8, 16, 8)
	t.set_stylebox("normal", "Button", _box("button_idle", 5, button_content))
	t.set_stylebox("hover", "Button", _box("button_hover", 5, button_content))
	t.set_stylebox("pressed", "Button", _box("button_pressed", 5, button_content))
	t.set_stylebox("disabled", "Button", _box("button_disabled", 5, button_content))
	t.set_stylebox("focus", "Button", _box("button_focus", 5, button_content, false))
	t.set_stylebox("hover_pressed", "Button", _box("button_pressed", 5, button_content))
	t.set_font("font", "Button", load(FONT_UI))
	t.set_font_size("font_size", "Button", 20)
	t.set_color("font_color", "Button", ink)
	t.set_color("font_hover_color", "Button", gold)
	t.set_color("font_focus_color", "Button", gold)
	t.set_color("font_pressed_color", "Button", gold_dim)
	t.set_color("font_hover_pressed_color", "Button", gold)
	t.set_color("font_disabled_color", "Button", dim)
	for type in ["OptionButton", "MenuButton"]:
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			t.set_stylebox(st, type, t.get_stylebox(st, "Button"))
		t.set_font("font", type, load(FONT_UI))
		t.set_font_size("font_size", type, 20)
		t.set_color("font_color", type, ink)
		t.set_color("font_hover_color", type, gold)
		t.set_color("font_focus_color", type, gold)
	var lite := _box("panel_lite", 4, Vector4(10, 8, 10, 8))
	t.set_stylebox("panel", "PopupMenu", lite)
	t.set_stylebox("hover", "PopupMenu", _box("button_hover", 5, Vector4(8, 4, 8, 4)))
	t.set_color("font_color", "PopupMenu", ink)
	t.set_color("font_hover_color", "PopupMenu", gold)
	t.set_stylebox("panel", "TooltipPanel", lite)
	t.set_color("font_color", "TooltipLabel", ink)
	t.set_stylebox("normal", "LineEdit", lite)
	t.set_stylebox("focus", "LineEdit", _box("button_focus", 5, Vector4(8, 4, 8, 4), false))
	# Sliders, check boxes, scroll bars
	t.set_stylebox("slider", "HSlider", _box("slider_track", 3, Vector4(0, 4, 0, 4)))
	t.set_stylebox("grabber_area", "HSlider", _box("slider_fill", 3, Vector4(0, 4, 0, 4)))
	t.set_stylebox("grabber_area_highlight", "HSlider", _box("slider_fill", 3, Vector4(0, 4, 0, 4)))
	t.set_icon("grabber", "HSlider", load(OUT + "slider_grabber.png"))
	t.set_icon("grabber_highlight", "HSlider", load(OUT + "slider_grabber_hi.png"))
	for type in ["CheckBox", "CheckButton"]:
		t.set_icon("checked", type, load(OUT + "check_on.png"))
		t.set_icon("unchecked", type, load(OUT + "check_off.png"))
		t.set_icon("checked_disabled", type, load(OUT + "check_on.png"))
		t.set_icon("unchecked_disabled", type, load(OUT + "check_off.png"))
		t.set_stylebox("normal", type, StyleBoxEmpty.new())
		t.set_stylebox("hover", type, StyleBoxEmpty.new())
		t.set_stylebox("pressed", type, StyleBoxEmpty.new())
		t.set_stylebox("focus", type, _box("button_focus", 5, Vector4(4, 2, 4, 2), false))
		t.set_font("font", type, load(FONT_STORY))
		t.set_color("font_color", type, ink)
		t.set_color("font_hover_color", type, gold)
		t.set_color("font_focus_color", type, gold)
		t.set_color("font_pressed_color", type, gold)
	for type in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", type, _box("scroll_track", 2, Vector4(0, 0, 0, 0)))
		t.set_stylebox("grabber", type, _box("scroll_grabber", 3, Vector4(0, 0, 0, 0)))
		t.set_stylebox("grabber_highlight", type, _box("scroll_grabber_hi", 3, Vector4(0, 0, 0, 0)))
		t.set_stylebox("grabber_pressed", type, _box("scroll_grabber_hi", 3, Vector4(0, 0, 0, 0)))
	t.set_stylebox("background", "ProgressBar", _box("bar_frame", 4, Vector4(6, 6, 6, 6)))
	t.set_stylebox("fill", "ProgressBar", _box("slider_fill", 3, Vector4(0, 0, 0, 0)))
	# Variations: headings, small capitals, book text, plain and paper boxes
	t.set_type_variation("HeaderLabel", "Label")
	t.set_font("font", "HeaderLabel", load(FONT_TITLE))
	t.set_font_size("font_size", "HeaderLabel", 36)
	t.set_color("font_color", "HeaderLabel", gold)
	t.set_type_variation("CapsLabel", "Label")
	t.set_font("font", "CapsLabel", load(FONT_UI))
	t.set_font_size("font_size", "CapsLabel", 16)
	t.set_color("font_color", "CapsLabel", gold_dim)
	t.set_type_variation("BookLabel", "Label")
	t.set_font("font", "BookLabel", load(FONT_BOOK))
	t.set_font_size("font_size", "BookLabel", 22)
	t.set_color("font_color", "BookLabel", Color("2a2016"))
	t.set_type_variation("LitePanel", "PanelContainer")
	t.set_stylebox("panel", "LitePanel", lite)
	t.set_type_variation("ParchmentPanel", "PanelContainer")
	t.set_stylebox("panel", "ParchmentPanel", _box("parchment", 12, Vector4(30, 26, 30, 26)))
	t.set_type_variation("BannerPanel", "PanelContainer")
	t.set_stylebox("panel", "BannerPanel", _box("banner", 7, Vector4(26, 6, 26, 8), false))
	t.set_type_variation("NamePlate", "PanelContainer")
	t.set_stylebox("panel", "NamePlate", _box("nameplate", 5, Vector4(18, 4, 18, 6), false))
	var err := ResourceSaver.save(t, OUT + "dungeon_theme.tres")
	print("  theme saved: ", err == OK)
