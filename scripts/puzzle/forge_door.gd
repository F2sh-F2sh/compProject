@tool
class_name ForgeDoor
extends Node2D

## The Forge Door: a great iron door the Smith cast to open only in heat, so
## no cold hand could reach the bell beyond. While the forge is cold it is
## rimed with the Hush's frost and shut fast. Powered (the Great Kiln roars),
## the frost melts off it and it grinds up into the wall, and it stays open
## (saved). The node sits on the floor surface, centred on the door; it is
## 64 px wide and 152 tall.

signal power_changed(powered: bool)

const SIZE := Vector2(64, 152)

## Saved once open.
@export var persist_id := ""

var is_open := false
var open_amount := 0.0
var _art: Node2D
var _sprite: AnimatedSprite2D
var _body: StaticBody2D
var _shape: CollisionShape2D


func _ready() -> void:
	_art = Node2D.new()
	_art.name = "Art"
	_art.z_index = -1
	add_child(_art)
	_sprite = SurfaceArt.animated(_art, "forge_door", Vector2.ZERO, 0.0, 1.0)
	_sprite.name = "Door"
	_sprite.stop()
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	_body = StaticBody2D.new()
	_body.collision_layer = 3
	_body.collision_mask = 0
	_body.add_to_group("world")
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	_shape.shape = rect
	_shape.position = Vector2(0, -SIZE.y / 2.0)
	_body.add_child(_shape)
	add_child(_body)
	if persist_id != "" and GameState.has_flag(persist_id):
		_open(true)


func is_powered() -> bool:
	return is_open


func set_powered(powered: bool) -> void:
	if powered and not is_open:
		_open(false)


func _open(silent: bool) -> void:
	is_open = true
	_sprite.frame = 1
	if persist_id != "":
		GameState.set_flag(persist_id)
	power_changed.emit(true)
	if silent:
		open_amount = 1.0
		_art.position.y = -SIZE.y
		_shape.set_deferred("disabled", true)
		return
	# The frost lets go first, then the door grinds up into the wall
	Sfx.play("ice_melt", global_position + Vector2(0, -SIZE.y / 2.0), 0.0, 0.0)
	for i in 4:
		ImpactFX.burst(get_parent(), global_position + Vector2(randf_range(-24, 24), -randf_range(10, SIZE.y)), Color(0.75, 0.9, 1.0), false, 8)
	var t := create_tween()
	t.tween_interval(0.8)
	t.tween_callback(func(): Sfx.play("gate_rumble", global_position + Vector2(0, -SIZE.y / 2.0), 2.0, 0.0))
	t.tween_property(self, "open_amount", 1.0, 2.4).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(_art, "position:y", -SIZE.y, 2.4).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func():
		_shape.set_deferred("disabled", true)
		Sfx.play("gate_slam", global_position + Vector2(0, -SIZE.y), -4.0))


func reset_state() -> void:
	# A door that has opened stays open
	pass
