class_name TideMark
extends Node2D

## A mark on the wall of a TidePool, read by circuits as a power source:
##   BELOW   on while the water is below the mark (the tide gates at the
##           Tide Hall's doorways stand open while the floor is dry);
##   HELD    on while the tide is held still (frozen) with its surface at or
##           above the mark, within `slack` (the Great Sluice's tide lock).
## The node's y is the mark; it draws a small carved notch there.

signal power_changed(powered: bool)

enum Mode { BELOW, HELD }

@export var pool: NodePath
@export var mode: Mode = Mode.BELOW
@export var slack := 8.0
## Draw the carved notch (off for marks that are only logic).
@export var visible_mark := true

var _pool: TidePool
var _on := false


func _ready() -> void:
	_pool = get_node_or_null(pool) as TidePool
	_on = _compute()
	queue_redraw()


func is_powered() -> bool:
	return _on


func _compute() -> bool:
	if _pool == null:
		return false
	match mode:
		Mode.BELOW:
			return _pool.drained or _pool.below(global_position.y)
		Mode.HELD:
			return _pool.is_frozen and _pool.surface_y() <= global_position.y + slack
	return false


func _physics_process(_delta: float) -> void:
	var on := _compute()
	if on != _on:
		_on = on
		power_changed.emit(on)
		queue_redraw()


func _draw() -> void:
	if not visible_mark:
		return
	# A carved line with a wave over it: brass-bright while the mark is met
	var col := Color(0.95, 0.82, 0.45) if _on else Color(0.62, 0.55, 0.42)
	draw_rect(Rect2(-15, -1, 30, 3), col)
	draw_rect(Rect2(-2, -7, 4, 14), col)
	for i in 3:
		draw_rect(Rect2(-12 + i * 9, -11 + (i % 2) * 2, 6, 2), col)
