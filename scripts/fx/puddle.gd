@tool
class_name Puddle
extends Node2D

## A shallow puddle on the floor. It mirrors what stands above it, and
## rings of ripples spread from every step, landing or drip. Echidna's
## footfalls in it sound wet; landing in it splashes. Water drips into it
## from the ceiling now and then. The node marks the centre of the surface;
## at play time it settles onto the floor below it, and removes itself if
## the floor there isn't flat.

const SHADER := preload("res://assets/shaders/puddle.gdshader")
const MAX_RIPPLES := 8
const RIPPLE_LIFE := 2.2

@export var width := 96.0:
	set(value):
		width = maxf(value, 24.0)
		_layout()
@export var depth := 10.0:
	set(value):
		depth = clampf(value, 3.0, 16.0)
		_layout()
@export var water_color := Color(0.1, 0.14, 0.23, 0.92)
## Water drips from the ceiling above every few seconds.
@export var drips := true
@export var drip_interval := Vector2(2.5, 6.0)

var _surface: ColorRect
var _material: ShaderMaterial
var _area: Area2D
## Each ripple: Vector4(centre x from the left end, age, strength, 0)
var _ripples: Array[Vector4] = []
var _drops: Array[Dictionary] = []
var _drip_in := 0.0
var _drip_height := 360.0
var _time := 0.0
var _step_cooldown := {}
var _player: Node2D


func _ready() -> void:
	z_index = 39
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_surface = ColorRect.new()
	_surface.name = "Surface"
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_surface.material = _material
	add_child(_surface)
	_layout()
	if Engine.is_editor_hint():
		return
	add_to_group("puddle")
	# Falling drops keep their glint in the dark
	material = MagicLight.unshaded()
	_area = Area2D.new()
	_area.monitorable = false
	_area.collision_layer = 0
	_area.collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, 18.0)
	shape.shape = rect
	shape.position = Vector2(0, -8)
	_area.add_child(shape)
	add_child(_area)
	_area.body_entered.connect(_on_body_entered)
	_drip_in = randf_range(0.5, drip_interval.y)
	_settle.call_deferred()


func _layout() -> void:
	if _surface == null:
		return
	# The top pixel sits just over the floor's edge so the surface reads as water
	_surface.position = Vector2(-width / 2.0, -1.0)
	_surface.size = Vector2(width, depth)
	_material.set_shader_parameter("rect_size", _surface.size)
	_material.set_shader_parameter("water_color", water_color)


## Finds the floor under the puddle and sits on it; gives up on uneven ground.
func _settle() -> void:
	await get_tree().physics_frame
	var space := get_world_2d().direct_space_state
	var heights := []
	for dx in [-width / 2.0 + 6.0, 0.0, width / 2.0 - 6.0]:
		var from := global_position + Vector2(dx, -24.0)
		var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0, 72.0), 2)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			queue_free()
			return
		heights.append(hit.position.y)
	if heights.max() - heights.min() > 1.5:
		queue_free()
		return
	global_position.y = heights[1]
	# How far a drip falls: up to the ceiling, or a fixed height in open halls
	var up := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -24.0), global_position + Vector2(0, -520.0), 2)
	var ceiling := space.intersect_ray(up)
	_drip_height = global_position.y - ceiling.position.y if not ceiling.is_empty() else 360.0
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player and _player.has_signal("footstep"):
		_player.footstep.connect(_on_footstep)


## Starts a ring of ripples at a world x; `strength` about 0.5 (a drip) to 1.6 (a landing).
func disturb(world_x: float, strength := 1.0) -> void:
	var local_x := world_x - global_position.x + width / 2.0
	if local_x < 0.0 or local_x > width:
		return
	var limit: int = mini(MAX_RIPPLES, int(Settings.quality("ripples")))
	while _ripples.size() >= limit:
		_ripples.pop_front()
	_ripples.append(Vector4(local_x, 0.0, strength, 0.0))


func ripple_count() -> int:
	return _ripples.size()


func _covers(world_x: float) -> bool:
	return absf(world_x - global_position.x) <= width / 2.0


func _on_footstep(at: Vector2) -> void:
	if _covers(at.x) and absf(at.y - global_position.y) < 10.0:
		disturb(at.x, 1.0)
		Sfx.play("puddle_step", at, -9.0, 0.08)


func _on_body_entered(body: Node) -> void:
	var fall: float = body.velocity.y if "velocity" in body else 0.0
	if fall > 140.0 and _covers(body.global_position.x):
		disturb(body.global_position.x, 1.6)
		Sfx.play("puddle_splash", body.global_position, -3.0, 0.06)
		_spray(body.global_position.x)


# A few droplets thrown up by a landing
func _spray(world_x: float) -> void:
	var spray := CPUParticles2D.new()
	spray.one_shot = true
	spray.explosiveness = 0.9
	spray.amount = maxi(4, roundi(10 * float(Settings.quality("particles"))))
	spray.lifetime = 0.5
	spray.direction = Vector2.UP
	spray.spread = 55.0
	spray.initial_velocity_min = 60.0
	spray.initial_velocity_max = 130.0
	spray.gravity = Vector2(0, 420)
	spray.scale_amount_min = 1.0
	spray.scale_amount_max = 1.8
	spray.color = Color(0.7, 0.8, 0.95, 0.85)
	spray.material = MagicLight.unshaded()
	spray.position = Vector2(world_x - global_position.x, -2.0)
	add_child(spray)
	spray.emitting = true
	spray.finished.connect(spray.queue_free)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	# Anything else wading through (a slime, a pushed block) leaves rings too
	if _area:
		for body in _area.get_overlapping_bodies():
			if body == _player or not "velocity" in body or absf(body.velocity.x) < 25.0:
				continue
			var t: float = _step_cooldown.get(body, 0.0) - delta
			if t <= 0.0:
				t = 0.25
				disturb(body.global_position.x, 0.8)
			_step_cooldown[body] = t
	_update_drips(delta)
	for i in range(_ripples.size() - 1, -1, -1):
		var r := _ripples[i]
		r.y += delta
		if r.y > RIPPLE_LIFE:
			_ripples.remove_at(i)
		else:
			_ripples[i] = r
	var packed := PackedVector4Array()
	packed.resize(MAX_RIPPLES)
	for i in _ripples.size():
		packed[i] = _ripples[i]
	_material.set_shader_parameter("ripples", packed)
	_material.set_shader_parameter("ripple_count", _ripples.size())
	_material.set_shader_parameter("time", _time)
	_material.set_shader_parameter("reflections", Settings.quality("reflections"))
	var scale_px := get_global_transform_with_canvas().get_scale()
	_material.set_shader_parameter("px_uv", scale_px / get_viewport_rect().size)


func _update_drips(delta: float) -> void:
	if drips and float(Settings.quality("particles")) >= 0.5:
		_drip_in -= delta
		if _drip_in <= 0.0:
			_drip_in = randf_range(drip_interval.x, drip_interval.y)
			_drops.append({"x": randf_range(-width / 2.0 + 10.0, width / 2.0 - 10.0), "y": -_drip_height, "v": 0.0})
	if _drops.is_empty():
		return
	for i in range(_drops.size() - 1, -1, -1):
		var drop: Dictionary = _drops[i]
		drop["v"] += 900.0 * delta
		drop["y"] += drop["v"] * delta
		if drop["y"] >= 0.0:
			disturb(global_position.x + drop["x"], 0.55)
			Sfx.play("drip", global_position + Vector2(drop["x"], 0.0), -14.0, 0.15)
			_drops.remove_at(i)
	queue_redraw()


func _draw() -> void:
	for drop in _drops:
		var len := clampf(drop["v"] / 120.0, 2.0, 6.0)
		draw_rect(Rect2(drop["x"] - 0.5, drop["y"] - len, 1.0, len), Color(0.72, 0.82, 0.98, 0.7))
