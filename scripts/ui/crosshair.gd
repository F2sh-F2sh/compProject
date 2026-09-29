class_name Crosshair
extends RefCounted

## The mouse cursor while playing: a small reticle for aiming fireballs,
## bright when a fireball is ready and dim when there isn't the mana for one.
## Menus switch back to the ordinary arrow.

const SIZE := 32

static var _bright: Image
static var _dim: Image
static var _ready_state := true
static var _in_play := false


## Shows the reticle (bright if a fireball can be cast right now).
static func aim(ready: bool) -> void:
	if _in_play and ready == _ready_state:
		return
	_in_play = true
	_ready_state = ready
	if DisplayServer.get_name() == "headless":
		return
	if _bright == null:
		_bright = _draw(Color(0.9, 0.8, 1.0, 0.95))
		_dim = _draw(Color(0.55, 0.5, 0.65, 0.5))
	Input.set_custom_mouse_cursor(_bright if ready else _dim, Input.CURSOR_ARROW, Vector2(SIZE / 2.0, SIZE / 2.0))


## The plain arrow, for menus.
static func arrow() -> void:
	_in_play = false
	if DisplayServer.get_name() == "headless":
		return
	Input.set_custom_mouse_cursor(null)


## Back to the reticle after a menu closes.
static func restore() -> void:
	var was := _ready_state
	_in_play = false
	aim(was)


static func _draw(color: Color) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var c := Vector2(SIZE / 2.0 - 0.5, SIZE / 2.0 - 0.5)
	var outline := Color(0.05, 0.02, 0.1, color.a * 0.8)
	for y in SIZE:
		for x in SIZE:
			var d := Vector2(x, y).distance_to(c)
			var ring := absf(d - 8.0)
			var on_tick := (absf(x - c.x) < 0.8 and d > 10.5 and d < 14.5) or (absf(y - c.y) < 0.8 and d > 10.5 and d < 14.5)
			if ring < 0.8 or on_tick or d < 1.3:
				img.set_pixel(x, y, color)
			elif ring < 1.8 or d < 2.3:
				img.set_pixel(x, y, outline)
	return img
