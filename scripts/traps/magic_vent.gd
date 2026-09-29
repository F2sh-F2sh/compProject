@tool
class_name MagicVent
extends Node2D

## A grated vent that periodically releases a thin stream of cold blue magic
## along its local -Y (straight up when unrotated; rotate for wall vents).
## Phases: idle -> warning (sparks and a faint outline of the full danger
## area, harmless) -> active (damaging stream) -> idle. Power can disable it.

enum Phase { IDLE, WARNING, ACTIVE }

@export var reach := 120.0:
	set(value):
		reach = value
		queue_redraw()
@export var stream_width := 20.0:
	set(value):
		stream_width = value
		queue_redraw()
@export var idle_time := 1.8
@export var warning_time := 0.6
@export var active_time := 1.0
@export_range(0.0, 1.0) var start_phase := 0.0
@export var damage_amount := 2
@export var rehit_delay := 0.6
@export var active := true

var phase: Phase = Phase.IDLE
var _elapsed := 0.0
var _start_active := true
var _hitbox: Area2D
var _stream: CPUParticles2D
var _glow: Node2D
var _cooldowns := {}
var _time := 0.0


func _ready() -> void:
	_glow = Node2D.new()
	_glow.material = MagicLight.unshaded()
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	if Engine.is_editor_hint():
		return
	_start_active = active
	add_to_group("resettable")
	add_to_group("hazard_zone")
	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2
	_hitbox.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(stream_width - 4.0, reach)
	shape.shape = rect
	shape.position = Vector2(0, -reach / 2.0)
	_hitbox.add_child(shape)
	add_child(_hitbox)
	_stream = CPUParticles2D.new()
	_stream.emitting = false
	_stream.amount = 40
	_stream.lifetime = reach / 220.0
	_stream.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_stream.emission_rect_extents = Vector2(stream_width * 0.3, 2)
	_stream.direction = Vector2.UP
	_stream.spread = 4.0
	_stream.gravity = Vector2.ZERO
	_stream.initial_velocity_min = 200.0
	_stream.initial_velocity_max = 240.0
	_stream.scale_amount_min = 1.5
	_stream.scale_amount_max = 3.0
	_stream.color = Color(0.6, 0.85, 1.0, 0.7)
	_stream.material = MagicLight.unshaded()
	add_child(_stream)


func get_cycle_length() -> float:
	return idle_time + warning_time + active_time


func set_powered(powered: bool) -> void:
	active = powered


func reset_state() -> void:
	active = _start_active
	_elapsed = 0.0
	_cooldowns.clear()


func is_dangerous() -> bool:
	return phase == Phase.ACTIVE


func get_hazard_rect() -> Rect2:
	var a := to_global(Vector2(-stream_width / 2.0, -reach))
	var b := to_global(Vector2(stream_width / 2.0, 0))
	return Rect2(a, Vector2.ZERO).expand(b)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_elapsed += delta
	var before := phase
	if not active:
		phase = Phase.IDLE
	else:
		var t := fposmod(_elapsed + start_phase * get_cycle_length(), get_cycle_length())
		if t < idle_time:
			phase = Phase.IDLE
		elif t < idle_time + warning_time:
			phase = Phase.WARNING
		else:
			phase = Phase.ACTIVE
	if phase != before:
		if phase == Phase.WARNING:
			Sfx.play("vent_warn", global_position, -6.0)
		elif phase == Phase.ACTIVE:
			Sfx.play("vent_burst", global_position, -4.0)
	_stream.emitting = phase == Phase.ACTIVE
	_glow.queue_redraw()

	for hurtbox in _cooldowns.keys():
		_cooldowns[hurtbox] -= delta
		if _cooldowns[hurtbox] <= 0.0 or not is_instance_valid(hurtbox):
			_cooldowns.erase(hurtbox)
	if phase != Phase.ACTIVE:
		return
	for area in _hitbox.get_overlapping_areas():
		if area is Hurtbox and not _cooldowns.has(area):
			_cooldowns[area] = rehit_delay
			area.receive_damage(damage_amount, self)


func get_knockback_velocity(_target: Node2D) -> Vector2:
	return global_transform.basis_xform(Vector2(0, -160))


func _draw() -> void:
	# Iron grate set into the floor
	draw_rect(Rect2(-stream_width / 2.0 - 4.0, -4, stream_width + 8.0, 4), Color("231d38"))
	var x := -stream_width / 2.0
	while x < stream_width / 2.0:
		draw_rect(Rect2(x, -4, 2, 4), Color("4c4862"))
		x += 5.0


func _draw_glow() -> void:
	var w := stream_width
	if Engine.is_editor_hint():
		_glow.draw_rect(Rect2(-w / 2.0, -reach, w, reach), Color(0.6, 0.8, 1.0, 0.2), false, 1.0)
		return
	match phase:
		Phase.WARNING:
			# Show the whole danger area faintly, plus sparks at the grate
			var blink := 0.35 if int(_time * 8.0) % 2 == 0 else 0.2
			_glow.draw_rect(Rect2(-w / 2.0, -reach, w, reach), Color(0.6, 0.85, 1.0, 0.08), true)
			_glow.draw_rect(Rect2(-w / 2.0, -reach, w, reach), Color(0.6, 0.85, 1.0, blink), false, 1.0)
			for i in 3:
				_glow.draw_rect(Rect2(-w / 2.0 + 3.0 + i * (w - 6.0) / 2.0, -4 - fmod(_time * 30.0 + i * 5.0, 10.0), 2, 2),
					Color(0.8, 0.9, 1.0, 0.9))
		Phase.ACTIVE:
			_glow.draw_rect(Rect2(-w / 2.0 + 3.0, -reach, w - 6.0, reach), Color(0.55, 0.8, 1.0, 0.18))
			_glow.draw_rect(Rect2(-1, -reach, 2, reach), Color(0.85, 0.95, 1.0, 0.5))
		_:
			if active:
				_glow.draw_rect(Rect2(-w / 2.0, -2, w, 1), Color(0.5, 0.7, 1.0, 0.35))
