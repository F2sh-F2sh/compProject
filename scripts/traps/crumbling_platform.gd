@tool
class_name CrumblingPlatform
extends Node2D

## A weathered ledge that cracks as soon as the player stands on it, holds for
## `warning_time`, then crumbles away. After `respawn_delay` it reforms — but
## only once the space is clear, so it can never appear inside the player.
## Resetting the room restores it immediately. The node marks the top-left.

enum State { SOLID, CRACKING, FALLEN }

const TILE := preload("res://assets/tileset/platforms/tiles/08_cap_mid.png")
const TILE_TOP := 18.0

@export var width_tiles := 1:
	set(value):
		width_tiles = maxi(value, 1)
		queue_redraw()
@export var warning_time := 0.7
@export var respawn_delay := 2.5

var state: State = State.SOLID
var _timer := 0.0
var _body: StaticBody2D
var _shape: CollisionShape2D
var _sensor: Area2D
var _clear_sensor: Area2D
var _time := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	var w := width_tiles * 64.0
	_body = StaticBody2D.new()
	_body.collision_layer = 3
	_body.collision_mask = 0
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, 64.0 - TILE_TOP)
	_shape.shape = rect
	_shape.position = Vector2(w / 2.0, TILE_TOP + rect.size.y / 2.0)
	_body.add_child(_shape)
	add_child(_body)
	# Standing on top starts the crumble
	_sensor = _area(Vector2(w - 4.0, 8.0), Vector2(w / 2.0, TILE_TOP - 4.0))
	# The whole platform volume must be empty before it reforms
	_clear_sensor = _area(Vector2(w, 64.0 - TILE_TOP + 8.0), Vector2(w / 2.0, TILE_TOP + (64.0 - TILE_TOP) / 2.0 - 4.0))


func _area(size: Vector2, pos: Vector2) -> Area2D:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = pos
	area.add_child(shape)
	add_child(area)
	return area


func reset_state() -> void:
	state = State.SOLID
	_timer = 0.0
	_shape.set_deferred("disabled", false)
	modulate.a = 1.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	match state:
		State.SOLID:
			if _player_on(_sensor):
				state = State.CRACKING
				_timer = warning_time
				Sfx.play("crumble_crack", global_position + Vector2(32, 18))
		State.CRACKING:
			_timer -= delta
			if _timer <= 0.0:
				state = State.FALLEN
				_timer = respawn_delay
				_shape.set_deferred("disabled", true)
				_spawn_rubble()
				Sfx.play("crumble_fall", global_position + Vector2(32, 18))
		State.FALLEN:
			_timer -= delta
			if _timer <= 0.0 and not _player_on(_clear_sensor):
				state = State.SOLID
				_shape.set_deferred("disabled", false)
				modulate.a = 0.0
				create_tween().tween_property(self, "modulate:a", 1.0, 0.3)
	queue_redraw()


func _player_on(area: Area2D) -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player") or body.is_in_group("plate_weight"):
			return true
	return false


func _spawn_rubble() -> void:
	var rubble := CPUParticles2D.new()
	rubble.one_shot = true
	rubble.explosiveness = 0.9
	rubble.amount = 18
	rubble.lifetime = 0.8
	rubble.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rubble.emission_rect_extents = Vector2(width_tiles * 32.0, 6)
	rubble.direction = Vector2.DOWN
	rubble.spread = 25.0
	rubble.gravity = Vector2(0, 500)
	rubble.initial_velocity_min = 10.0
	rubble.initial_velocity_max = 40.0
	rubble.scale_amount_min = 2.0
	rubble.scale_amount_max = 4.0
	rubble.color = Color(0.3, 0.27, 0.42)
	rubble.position = Vector2(width_tiles * 32.0, TILE_TOP + 10.0)
	add_child(rubble)
	rubble.emitting = true
	rubble.finished.connect(rubble.queue_free)


func _draw() -> void:
	if not Engine.is_editor_hint() and state == State.FALLEN:
		# Broken stubs remain on the wall so the gap reads as a crumbled ledge
		draw_rect(Rect2(0, TILE_TOP, 5, 8), Color("2a2442"))
		draw_rect(Rect2(width_tiles * 64.0 - 5.0, TILE_TOP, 5, 8), Color("2a2442"))
		return
	var shake := 0.0
	var cracks := 0.0
	if not Engine.is_editor_hint() and state == State.CRACKING:
		cracks = 1.0 - _timer / warning_time
		shake = sin(_time * 70.0) * cracks * 1.5
	for i in width_tiles:
		draw_texture(TILE, Vector2(i * 64.0 + shake, 0), Color(0.92, 0.9, 1.0))
		# Cracks widen as it gives way
		if cracks > 0.0:
			var x := i * 64.0 + 20.0 + shake
			var c := Color(0.08, 0.05, 0.12)
			draw_line(Vector2(x, TILE_TOP), Vector2(x + 6, TILE_TOP + 10.0 * cracks + 4), c, 1.0)
			draw_line(Vector2(x + 6, TILE_TOP + 10.0 * cracks + 4), Vector2(x + 2, TILE_TOP + 22.0 * cracks + 6), c, 1.0)
			if cracks > 0.5:
				draw_line(Vector2(x + 24, TILE_TOP), Vector2(x + 18, TILE_TOP + 16.0 * cracks), c, 1.0)
	# Small rune scratched on top marks it as unstable before it is ever touched
	draw_rect(Rect2(width_tiles * 32.0 - 3.0 + shake, TILE_TOP + 4.0, 6, 1), Color(0.5, 0.35, 0.55))
