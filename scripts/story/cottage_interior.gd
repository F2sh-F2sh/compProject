extends Node2D

## Plaster and timber make this a home rather than another dungeon wall.
func _draw() -> void:
	draw_rect(Rect2(0, 274, 1152, 260), Color("554452"))
	for y in range(296, 440, 18):
		for x in range(16 + (y % 5) * 8, 1140, 38):
			draw_rect(Rect2(x, y, 2, 1), Color("66545e"))
	draw_rect(Rect2(0, 448, 1152, 86), Color("322735"))
	for x in range(0, 1152, 32):
		draw_rect(Rect2(x, 451, 2, 80), Color("4e3b43"))
		draw_rect(Rect2(x + 23, 460, 1, 62), Color("281f2b"))
	draw_rect(Rect2(0, 444, 1152, 7), Color("795a4c"))
	draw_rect(Rect2(0, 526, 1152, 8), Color("654b45"))
	for x in [46, 466, 856, 1120]:
		draw_rect(Rect2(x, 274, 12, 252), Color("2a202d"))
		draw_rect(Rect2(x + 2, 276, 3, 248), Color("6b4d49"))
	draw_rect(Rect2(0, 274, 1152, 14), Color("302431"))
