extends Control

## The original Aero composition drawn on a coarse four-pixel grid.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	for y in range(20, 180, 4):
		var t := floorf(float(y - 20) / 160.0 * 6) / 6
		draw_rect(Rect2(0, y, 1152, 4), Color("354661").lerp(Color("111a30"), t) * Color(1, 1, 1, 0.7))
	draw_rect(Rect2(0, 180, 1152, 4), Color("567f96"))
	for y in range(24, 76, 4):
		var left := floorf((684 - (y - 24) * 1.2) / 4) * 4
		draw_rect(Rect2(left, y, 1152 - left, 4), Color(0.15, 0.27, 0.38, 0.48))
	draw_rect(Rect2(684, 20, 468, 4), Color(0.77, 0.89, 0.94, 0.4))
	var c := Vector2(852, 376)
	for r in [172.0, 152.0, 120.0]:
		for y in range(-int(r), int(r), 4):
			for x in range(-int(r), int(r), 4):
				var distance := Vector2(x + 2, y + 2).length()
				if distance <= r and distance >= r - 4:
					draw_rect(Rect2(c + Vector2(x, y), Vector2(4, 4)), Color(0.31, 0.49, 0.61, 0.16))
	for i in 8:
		for step in range(156, 172, 4):
			var p := c + Vector2.from_angle(i * TAU / 8.0) * step
			p = (p / 4).floor() * 4
			draw_rect(Rect2(p, Vector2(4, 4)), Color(0.48, 0.61, 0.73, 0.22))
	for y in range(588, 636, 4):
		var t := floorf(float(y - 588) / 48 * 4) / 4
		draw_rect(Rect2(0, y, 1152, 4), Color("33465c").lerp(Color("131b2e"), t) * Color(1, 1, 1, 0.86))
	draw_rect(Rect2(0, 584, 1152, 4), Color("658da0"))
	draw_rect(Rect2(0, 636, 1152, 4), Color(0.31, 0.62, 0.68, 0.7))
