extends SceneTree

## Pixel props for the pilgrim road and the well (scripts/story/witch_prologue.gd),
## drawn at 1x in the surface pack's palette (shown 1.5x like the lane):
##   bridge_winch   the pilgrims' bridge winch: a timber A-frame, an iron-bound
##                  drum wound with rope, a crank, on a stone footing
##   rope           a 4x4 tile of twisted rope, for Line2D ropes (tiled)
##   rope_ladder    the well's rope ladder: two ropes and wooden rungs (8x64)
##   godot --headless --path . --script res://tools/art/generate_surface_props.gd

const OUT := "res://assets/sprites/story/"

const WOOD_DARK := "3d2a22"
const WOOD := "5e4030"
const WOOD_LIGHT := "84603f"
const IRON := "3a3646"
const IRON_LIGHT := "6d6880"
const ROPE := "b49470"
const ROPE_DARK := "7c6249"
const STONE := "45405a"
const STONE_LIGHT := "68617e"
const OUTLINE := "141019"


func _init() -> void:
	_save("bridge_winch", _winch())
	_save("rope", _rope())
	_save("rope_ladder", _ladder())
	print("SURFACE PROPS DONE")
	quit()


func _px(img: Image, x: int, y: int, hex: String) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, Color(hex))


func _rect(img: Image, x: int, y: int, w: int, h: int, hex: String) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			_px(img, xx, yy, hex)


func _outline(img: Image) -> void:
	var edge: Array = []
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < img.get_width() and ny < img.get_height() and img.get_pixel(nx, ny).a > 0.0:
					edge.append(Vector2i(x, y))
					break
	for p in edge:
		_px(img, p.x, p.y, OUTLINE)


## 30 x 36: stands on its bottom row.
func _winch() -> Image:
	var img := Image.create(30, 36, false, Image.FORMAT_RGBA8)
	# stone footing
	_rect(img, 2, 31, 26, 5, STONE)
	_rect(img, 2, 31, 26, 1, STONE_LIGHT)
	for x in [8, 15, 22]:
		_px(img, x, 33, OUTLINE)
		_px(img, x, 34, OUTLINE)
	# two A-frame posts leaning together
	for i in 30:
		var t := float(i) / 29.0
		var lx := int(lerpf(5.0, 12.0, t))
		var rx := int(lerpf(24.0, 17.0, t))
		var y := 30 - i
		_px(img, lx, y, WOOD)
		_px(img, lx + 1, y, WOOD_LIGHT)
		_px(img, rx, y, WOOD)
		_px(img, rx - 1, y, WOOD_DARK)
	# crossbeam on top
	_rect(img, 10, 1, 10, 2, WOOD_LIGHT)
	_rect(img, 10, 3, 10, 1, WOOD_DARK)
	# the drum across the frame, iron-bound, wound with rope
	_rect(img, 7, 15, 16, 7, WOOD)
	_rect(img, 7, 15, 16, 1, WOOD_LIGHT)
	_rect(img, 7, 21, 16, 1, WOOD_DARK)
	for x in [7, 22]:
		_rect(img, x, 14, 1, 9, IRON)
	for x in range(9, 21):
		for y in range(16, 21):
			if (x + y) % 3 == 0:
				_px(img, x, y, ROPE)
			elif (x + y) % 3 == 1:
				_px(img, x, y, ROPE_DARK)
	# axle and crank
	_rect(img, 3, 17, 4, 3, IRON)
	_px(img, 3, 17, IRON_LIGHT)
	_rect(img, 2, 12, 2, 6, IRON)
	_rect(img, 0, 11, 4, 2, WOOD_LIGHT)
	_outline(img)
	return img


func _rope() -> Image:
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for y in 4:
		for x in 4:
			_px(img, x, y, ROPE if (x + y) % 4 < 2 else ROPE_DARK)
	return img


## 10 x 64: hangs from its top row.
func _ladder() -> Image:
	var img := Image.create(10, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		_px(img, 1, y, ROPE if y % 3 else ROPE_DARK)
		_px(img, 8, y, ROPE if (y + 1) % 3 else ROPE_DARK)
	for y in range(4, 64, 8):
		_rect(img, 1, y, 8, 2, WOOD_LIGHT)
		_rect(img, 1, y + 1, 8, 1, WOOD)
	_outline(img)
	return img


func _save(sprite_name: String, img: Image) -> void:
	img.save_png(ProjectSettings.globalize_path(OUT + sprite_name + ".png"))
