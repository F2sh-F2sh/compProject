@tool
class_name SpectralPlatform
extends Node2D

## A platform of ghostly rune-stone. In POWERED mode it is solid while a
## circuit powers it (a light bridge). In REVEALED mode it is solid only while
## magical light (a wisp or brazier aura) reaches it. When not solid it shows
## a faint marked outline, so players know something is there. It never
## materialises inside the player, and it flickers before vanishing.
## The node marks the platform's top-left corner.

enum Mode { POWERED, REVEALED }

@export var mode: Mode = Mode.POWERED
@export var size := Vector2(128, 12):
	set(value):
		size = value
		queue_redraw()
@export var start_solid := false
@export var vanish_warning := 0.35

var is_solid := false
var _powered := false
var _warning := 0.0
var _body: StaticBody2D
var _shape: CollisionShape2D
var _sensor: Area2D
var _glow: Node2D
var _time := 0.0


func _ready() -> void:
	_glow = Node2D.new()
	_glow.material = MagicLight.unshaded()
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	_body = StaticBody2D.new()
	_body.collision_layer = 3
	_body.collision_mask = 0
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = size / 2.0
	_body.add_child(_shape)
	add_child(_body)
	# Detects the player overlapping where the platform would appear
	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = 1
	_sensor.monitorable = false
	var sensor_shape := CollisionShape2D.new()
	var sensor_rect := RectangleShape2D.new()
	sensor_rect.size = size + Vector2(4, 4)
	sensor_shape.shape = sensor_rect
	sensor_shape.position = size / 2.0
	_sensor.add_child(sensor_shape)
	add_child(_sensor)
	_powered = start_solid
	_set_solid(start_solid)


func set_powered(powered: bool) -> void:
	_powered = powered


func reset_state() -> void:
	_powered = start_solid
	_warning = 0.0
	_set_solid(start_solid)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	var want := _powered
	if mode == Mode.REVEALED:
		# Its own body must not shadow the light that makes it solid
		want = MagicLight.aura_reaches(get_world_2d(), global_position + size / 2.0, [_body.get_rid()])
	if want:
		_warning = 0.0
		if not is_solid and not _player_inside():
			_set_solid(true)
			Sfx.play("receiver_on", global_position + size / 2.0, -10.0)
	elif is_solid:
		# Flicker briefly before disappearing so it never vanishes without warning
		_warning += delta
		if _warning >= vanish_warning:
			_set_solid(false)
	_glow.queue_redraw()


func _player_inside() -> bool:
	for body in _sensor.get_overlapping_bodies():
		if body.is_in_group("player") or body.is_in_group("plate_weight"):
			return true
	return false


func _set_solid(on: bool) -> void:
	is_solid = on
	_shape.set_deferred("disabled", not on)


func _draw_glow() -> void:
	var w := roundf(size.x)
	var h := roundf(size.y)
	if is_solid or Engine.is_editor_hint():
		var flicker := 1.0
		if _warning > 0.0:
			flicker = 0.35 if int(_time * 20.0) % 2 == 0 else 1.0
		var fill := Color(0.35, 0.55, 1.0, 0.45 * flicker)
		_glow.draw_rect(Rect2(0, 0, w, h), fill)
		_glow.draw_rect(Rect2(0, 0, w, 2), Color(0.75, 0.88, 1.0, 0.9 * flicker))
		# Rune-brick seams
		var x := 16.0
		while x < w:
			_glow.draw_rect(Rect2(x, 3, 1, h - 4), Color(0.7, 0.85, 1.0, 0.5 * flicker))
			x += 16.0
	else:
		# Faint dotted outline marks where the platform will appear
		var x := 0.0
		while x < w:
			_glow.draw_rect(Rect2(x, 0, 4, 1), Color(0.5, 0.65, 1.0, 0.35))
			_glow.draw_rect(Rect2(x, h - 1, 4, 1), Color(0.5, 0.65, 1.0, 0.2))
			x += 8.0
