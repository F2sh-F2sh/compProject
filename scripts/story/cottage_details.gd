extends Node2D
var tabletop := -30.0

## Small household objects drawn in the same pixel grid as the furniture.
func _draw() -> void:
	# An embroidered rug belongs to the background floor, below the actors.
	draw_rect(Rect2(460, -4, 370, 4), Color("533149"))
	for x in range(465, 830, 12):
		draw_rect(Rect2(x, -4, 4, 1), Color("b29a70"))
	# Cupboard with distinct legs; its feet exactly meet the floor.
	draw_rect(Rect2(328, -55, 46, 50), Color("211a26"))
	draw_rect(Rect2(330, -53, 42, 46), Color("544050"))
	for x in [332, 353]:
		draw_rect(Rect2(x, -50, 17, 39), Color("392b3a"))
		draw_rect(Rect2(x + 12, -33, 2, 3), Color("bf9b54"))
	for x in [331, 369]:
		draw_rect(Rect2(x, -6, 3, 6), Color("544050"))
	# Folded quilt on the cupboard and a little family picture above it.
	draw_rect(Rect2(334, -60, 28, 5), Color("817295"))
	for x in range(334, 362, 6):
		draw_rect(Rect2(x, -59, 2, 3), Color("b6a3bb"))
	draw_rect(Rect2(337, -120, 30, 36), Color("927246"))
	draw_rect(Rect2(340, -117, 24, 30), Color("262b3d"))
	draw_rect(Rect2(345, -108, 5, 6), Color("b1a8c5"))
	draw_rect(Rect2(354, -108, 5, 6), Color("d2bd94"))
	draw_rect(Rect2(343, -101, 9, 12), Color("79638b"))
	draw_rect(Rect2(352, -101, 9, 12), Color("54766c"))
	# A mug and saucer beside the lantern, with space between both flames.
	draw_rect(Rect2(558, tabletop - 2, 10, 2), Color("ad9dbb"))
	draw_rect(Rect2(560, tabletop - 10, 6, 8), Color("c4b4c7"))
	draw_rect(Rect2(566, tabletop - 8, 3, 4), Color("a99ab3"), false, 1)
