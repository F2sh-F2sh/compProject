@tool
class_name PortcullisGate
extends Node2D

## An iron portcullis spanning floor to ceiling. set_open(true) raises it;
## set_open(false) lowers it after close_delay. It never lowers onto the player
## or an Echo standing beneath it. The node sits on the floor surface.

@export var height := 262.0:
	set(value):
		height = value
		queue_redraw()
@export var width := 24.0:
	set(value):
		width = value
		queue_redraw()
@export var open_speed := 300.0
@export var close_speed := 380.0
@export var close_delay := 0.25
## How much of the gate stays visible under the ceiling when fully open.
@export var open_visible := 22.0
@export var start_open := false

var open_amount := 0.0
## Shut for good behind her: once she has gone on into the next room the way
## back stays closed, whatever its circuit says (ChapterRoot seals it).
var sealed := false
var _want_open := false
var _close_timer := 0.0
# Until the first physics frame, commands restore saved state instantly
var _settled := false
var _body: StaticBody2D
var _shape: RectangleShape2D
var _collider: CollisionShape2D
var _sensor: Area2D


func _ready() -> void:
	open_amount = 1.0 if start_open else 0.0
	_want_open = start_open
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	_body = StaticBody2D.new()
	# Same layers as the level geometry, so the player collides with it
	_body.collision_layer = 3
	_body.collision_mask = 0
	_body.add_to_group("world")
	_shape = RectangleShape2D.new()
	_collider = CollisionShape2D.new()
	_collider.shape = _shape
	_body.add_child(_collider)
	add_child(_body)

	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = 1 | PressurePlate.ECHO_LAYER
	_sensor.monitorable = false
	var sensor_shape := RectangleShape2D.new()
	sensor_shape.size = Vector2(width + 12.0, height)
	var sensor_collider := CollisionShape2D.new()
	sensor_collider.shape = sensor_shape
	sensor_collider.position = Vector2(0, -height / 2.0)
	_sensor.add_child(sensor_collider)
	add_child(_sensor)
	_update_collision()
	_settle.call_deferred()


func _settle() -> void:
	if not is_inside_tree():
		return
	# Two frames: circuits fed by saved levers switch on during the first
	await get_tree().physics_frame
	await get_tree().physics_frame
	_settled = true


## Drops behind her and stays down (see `sealed`); instant when restoring a save.
func seal(instant := false) -> void:
	if sealed:
		return
	if instant or not _settled:
		sealed = true
		_want_open = false
		open_amount = 0.0
		_update_collision()
		queue_redraw()
		return
	set_open(false)
	sealed = true


func set_open(open: bool) -> void:
	if sealed and open:
		return
	if not _settled:
		# A gate that was already open (a saved shortcut) is simply open on load
		_want_open = open
		open_amount = 1.0 if open else 0.0
		_update_collision()
		queue_redraw()
		return
	if open != _want_open:
		Sfx.play("gate_rumble", global_position + Vector2(0, -height / 2.0), -4.0)
	_want_open = open
	if not open:
		_close_timer = close_delay


## Power-vocabulary alias: a powered gate is open.
func set_powered(powered: bool) -> void:
	set_open(powered)


func reset_state() -> void:
	_want_open = start_open and not sealed
	open_amount = 1.0 if _want_open else 0.0
	_close_timer = 0.0
	_update_collision()
	queue_redraw()


func is_fully_closed() -> bool:
	return open_amount <= 0.0


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _want_open:
		open_amount = move_toward(open_amount, 1.0, open_speed / height * delta)
	else:
		_close_timer -= delta
		if _close_timer <= 0.0 and not _something_underneath():
			var was_open := open_amount > 0.0
			open_amount = move_toward(open_amount, 0.0, close_speed / height * delta)
			if was_open and open_amount <= 0.0:
				Sfx.play("gate_slam", global_position, -3.0)
	_update_collision()
	queue_redraw()


func _something_underneath() -> bool:
	for body in _sensor.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	for area in _sensor.get_overlapping_areas():
		if area.is_in_group("echo_presser"):
			return true
	return false


func _bars_bottom() -> float:
	return lerpf(0.0, -height + open_visible, open_amount)


func _update_collision() -> void:
	var bottom := _bars_bottom()
	_shape.size = Vector2(width, maxf(bottom + height, 1.0))
	_collider.position = Vector2(0, (-height + bottom) / 2.0)


func _draw() -> void:
	var bottom := roundf(_bars_bottom())
	var top := -height
	var w := roundf(width)
	var x0 := -w / 2.0
	var iron := Color("2b2838")
	var iron_light := Color("5b5773")
	var steel := Color("8e8aa6")
	# Vertical bars
	var bx := x0 + 1.0
	while bx < x0 + w - 1.0:
		draw_rect(Rect2(bx, top, 3, bottom - top), iron)
		draw_rect(Rect2(bx, top, 1, bottom - top), iron_light)
		# Spiked tips
		draw_colored_polygon(PackedVector2Array([
			Vector2(bx - 1, bottom), Vector2(bx + 4, bottom), Vector2(bx + 1.5, bottom + 6)]), steel)
		bx += 7.0
	# Cross bars every 28 px, counted up from the bottom so they move with the gate
	var cy := bottom - 10.0
	while cy > top + 4.0:
		draw_rect(Rect2(x0 - 2.0, cy, w + 4.0, 3), iron)
		draw_rect(Rect2(x0 - 2.0, cy, w + 4.0, 1), iron_light)
		cy -= 28.0
	# Housing in the ceiling
	draw_rect(Rect2(x0 - 6.0, top, w + 12.0, 10), Color("231d38"))
	draw_rect(Rect2(x0 - 6.0, top + 9.0, w + 12.0, 1), iron_light)
