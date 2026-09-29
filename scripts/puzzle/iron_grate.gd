@tool
class_name IronGrate
extends Node2D

## An iron floor grating over a sunken cell. The player walks across it and
## can see through it; creatures below cannot climb out, and fireballs
## splash on the bars, so nothing in the cell is ever hit by accident.
## The node marks the grate's top-left corner, level with the floor.

@export var width := 256.0:
	set(value):
		width = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var body := StaticBody2D.new()
	body.name = "Bars"
	body.collision_layer = 3
	body.collision_mask = 0
	body.add_to_group("world")
	body.add_to_group("iron_grate")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 6)
	shape.shape = rect
	shape.position = Vector2(width / 2.0, 3)
	body.add_child(shape)
	add_child(body)


func _draw() -> void:
	var iron := Color("2b2838")
	var iron_light := Color("5b5773")
	var steel := Color("8e8aa6")
	# Top rail with a lit edge
	draw_rect(Rect2(0, 0, width, 4), iron)
	draw_rect(Rect2(0, 0, width, 1), iron_light)
	# Cross bars below, so the cell underneath shows through
	var x := 3.0
	while x < width - 2.0:
		draw_rect(Rect2(x, 4, 3, 7), iron)
		draw_rect(Rect2(x, 4, 1, 7), iron_light)
		x += 10.0
	draw_rect(Rect2(0, 10, width, 2), iron)
	# Rivets along the rail
	x = 8.0
	while x < width:
		draw_rect(Rect2(x, 1, 2, 2), steel)
		x += 32.0
