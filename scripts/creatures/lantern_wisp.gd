@tool
class_name LanternWisp
extends Node2D

## A small floating light creature that rests on WispPerches. Using a perch
## calls it there: it spins up briefly, flies in a straight line, and settles.
## It never follows the player on its own. Its aura is magical light: it can
## power receivers, reveal hidden platforms and freeze gargoyles within
## light_radius (shown as a faint ring), if nothing solid is in the way.

enum State { IDLE, ANTICIPATE, TRAVEL }

@export var start_perch: WispPerch
@export var light_radius := 88.0
@export var speed := 120.0
@export var anticipation := 0.35

var state: State = State.IDLE
var current_perch: WispPerch
var target_perch: WispPerch
var _t := 0.0
var _time := 0.0
var _orb: Node2D
var _light: PointLight2D
var _trail: CPUParticles2D
var _burst: CPUParticles2D
var _rest := Vector2.ZERO


func _ready() -> void:
	_orb = Node2D.new()
	_orb.material = MagicLight.unshaded()
	_orb.z_index = 3
	_orb.draw.connect(_draw_orb)
	add_child(_orb)
	if Engine.is_editor_hint():
		return
	add_to_group(MagicLight.AURA_GROUP)
	add_to_group("resettable")
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.texture_scale = light_radius * 2.2 / 256.0
	_light.color = Color(0.6, 0.8, 1.0)
	_light.energy = 0.9
	add_child(_light)
	_trail = CPUParticles2D.new()
	_trail.amount = 16
	_trail.lifetime = 0.6
	_trail.emitting = false
	_trail.gravity = Vector2.ZERO
	_trail.initial_velocity_min = 2.0
	_trail.initial_velocity_max = 6.0
	_trail.spread = 180.0
	_trail.scale_amount_min = 1.0
	_trail.scale_amount_max = 2.0
	_trail.color = Color(0.65, 0.85, 1.0, 0.8)
	_trail.local_coords = false
	_trail.material = MagicLight.unshaded()
	add_child(_trail)
	_burst = _trail.duplicate()
	_burst.one_shot = true
	_burst.explosiveness = 1.0
	_burst.amount = 14
	_burst.initial_velocity_min = 25.0
	_burst.initial_velocity_max = 45.0
	add_child(_burst)
	if start_perch:
		_place_at(start_perch)
	_connect_perches.call_deferred()


func _connect_perches() -> void:
	for perch in get_tree().get_nodes_in_group("wisp_perch"):
		if perch.wisp == self and not perch.call_requested.is_connected(go_to):
			perch.call_requested.connect(go_to)


# --- aura interface used by MagicLight ---
func is_emitting() -> bool:
	return true


func get_light_origin() -> Vector2:
	return global_position


func go_to(perch: WispPerch) -> void:
	if state != State.IDLE or perch == current_perch:
		return
	target_perch = perch
	state = State.ANTICIPATE
	_t = 0.0
	Sfx.play("wisp_call", global_position)


func reset_state() -> void:
	state = State.IDLE
	_trail.emitting = false
	if start_perch:
		_place_at(start_perch)


func _place_at(perch: WispPerch) -> void:
	current_perch = perch
	_rest = perch.get_rest_position()
	global_position = _rest


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	match state:
		State.IDLE:
			global_position = _rest + Vector2(sin(_time * 1.3) * 2.0, sin(_time * 2.1) * 3.0)
		State.ANTICIPATE:
			_t += delta
			global_position = _rest + Vector2.from_angle(_time * 14.0) * 3.0 * (_t / anticipation)
			if _t >= anticipation:
				state = State.TRAVEL
				_trail.emitting = true
		State.TRAVEL:
			var goal := target_perch.get_rest_position()
			var step := speed * delta
			if global_position.distance_to(goal) <= step:
				_place_at(target_perch)
				state = State.IDLE
				_trail.emitting = false
				_burst.restart()
				Sfx.play("wisp_arrive", global_position)
			else:
				global_position = global_position.move_toward(goal, step)
	_orb.queue_redraw()


func _draw_orb() -> void:
	var flicker := 0.85 + 0.15 * sin(_time * 11.0)
	var glow := 1.4 if state == State.ANTICIPATE else 1.0
	_orb.draw_circle(Vector2.ZERO, 7.0 * glow, Color(0.45, 0.65, 1.0, 0.25 * flicker))
	_orb.draw_circle(Vector2.ZERO, 4.0, Color(0.7, 0.88, 1.0, 0.8 * flicker))
	_orb.draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1, flicker))
	# Faint ring shows how far its light reaches
	if not Engine.is_editor_hint() and state == State.IDLE:
		_orb.draw_arc(Vector2.ZERO, light_radius, 0.0, TAU, 48, Color(0.55, 0.75, 1.0, 0.1), 1.0)
	elif Engine.is_editor_hint():
		_orb.draw_arc(Vector2.ZERO, light_radius, 0.0, TAU, 48, Color(0.55, 0.75, 1.0, 0.4), 1.0)
