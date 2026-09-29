@tool
class_name Burnable
extends StaticBody2D

## Something fire removes: a curtain of dry brambles (burns away) or a block
## of old ice (melts). It blocks the way (and light and wind) until a
## fireball touches it or a fire blast reaches it; then it goes, and comes
## back only on Reset Room. The node's origin is the bottom-centre.

enum Kind { BRAMBLES, ICE }

signal cleared

@export var kind: Kind = Kind.BRAMBLES:
	set(value):
		kind = value
		queue_redraw()
@export var size := Vector2(32, 96):
	set(value):
		size = value
		queue_redraw()

var is_cleared := false
## Same as is_cleared (what objective steps ask).
var is_open := false
var _shape: CollisionShape2D
var _sensor: Area2D
var _fade := 1.0


func _ready() -> void:
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = Vector2(0, -size.y / 2.0)
	add_child(_shape)
	if Engine.is_editor_hint():
		return
	collision_layer = 3
	collision_mask = 0
	add_to_group("world")
	add_to_group("resettable")
	add_to_group("fire_reactive")
	# Fireballs are areas: a sensor a little larger than the body catches them
	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = 0xFFFF
	_sensor.monitorable = false
	var sense := CollisionShape2D.new()
	var srect := RectangleShape2D.new()
	srect.size = size + Vector2(6, 6)
	sense.shape = srect
	sense.position = _shape.position
	_sensor.add_child(sense)
	add_child(_sensor)
	_sensor.area_entered.connect(func(area):
		if area.is_in_group("fireball"):
			if area.has_method("explode"):
				area.explode(true)
			on_fire())


func on_fire() -> void:
	if is_cleared:
		return
	is_cleared = true
	is_open = true
	_shape.set_deferred("disabled", true)
	var at := global_position + Vector2(0, -size.y / 2.0)
	if kind == Kind.BRAMBLES:
		Sfx.play("brambles_burn", at, -2.0)
		ImpactFX.burst(get_parent(), at, Color(1.0, 0.55, 0.25), false, 18)
	else:
		Sfx.play("ice_melt", at, -2.0)
		ImpactFX.burst(get_parent(), at, Color(0.7, 0.9, 1.0), false, 14)
	var tween := create_tween()
	tween.tween_property(self, "_fade", 0.0, 0.6)
	tween.parallel().tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.6)
	cleared.emit()


func reset_state() -> void:
	is_cleared = false
	is_open = false
	_fade = 1.0
	_shape.set_deferred("disabled", false)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if _fade <= 0.01:
		return
	if kind == Kind.BRAMBLES:
		var dark := Color(0.2, 0.14, 0.1, _fade)
		var light := Color(0.45, 0.32, 0.2, _fade)
		for i in 7:
			var x := -w / 2.0 + (i + 0.5) * w / 7.0
			var pts := PackedVector2Array()
			for k in 9:
				var t := k / 8.0
				pts.append(Vector2(x + sin(t * 9.0 + i * 1.7) * 5.0, -t * h))
			draw_polyline(pts, dark, 3.0)
			draw_polyline(pts, light, 1.0)
		for i in 10:
			var p := Vector2(-w / 2.0 + fposmod(i * 13.7, w), -fposmod(i * 29.3, h))
			draw_line(p, p + Vector2(4, -3), light, 1.0)
	else:
		draw_rect(Rect2(-w / 2.0, -h, w, h), Color(0.45, 0.68, 0.9, 0.75 * _fade))
		draw_rect(Rect2(-w / 2.0, -h, w, 3), Color(0.85, 0.95, 1.0, 0.9 * _fade))
		draw_line(Vector2(-w / 4.0, -h + 6), Vector2(-w / 8.0, -h * 0.4), Color(1, 1, 1, 0.5 * _fade), 1.0)
