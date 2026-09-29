@tool
class_name PuzzleBell
extends Node2D

## A hanging iron bell. Ring it by pulling its rope (interact) or by hitting it
## with a fireball — so no puzzle ever *needs* mana. Creatures in the
## "bell_listener" group within lure_radius go to lure_point and stay a while.
## After ringing it needs `cooldown` seconds before it can ring again; its
## rune stays dark until then.

signal rung(lure_point: Vector2)

@export var lure_radius := 520.0
@export var cooldown := 2.5
## Where lured creatures gather (world position on the floor). If left at
## zero it is the floor directly beneath the bell.
@export var lure_point := Vector2.ZERO
## Where the rope pull hangs, relative to the bell. Zero means no rope.
@export var pull_offset := Vector2(0, 150):
	set(value):
		pull_offset = value
		queue_redraw()
## Length of the chain the bell hangs from, up to the ceiling.
@export var chain_length := 0.0:
	set(value):
		chain_length = value
		queue_redraw()

var _cooldown_left := 0.0
var _swing := 0.0
var _swing_speed := 0.0
var _waves: Array[float] = []
var _glow: Node2D
var _interact: Interactable
var _time := 0.0


func _ready() -> void:
	_glow = Node2D.new()
	_glow.material = MagicLight.unshaded()
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	var catcher := Area2D.new()
	catcher.collision_layer = 0
	catcher.collision_mask = 1
	catcher.monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	catcher.add_child(collider)
	add_child(catcher)
	catcher.area_entered.connect(func(a):
		if a.is_in_group("fireball"):
			a.queue_free()
			ring())
	if pull_offset != Vector2.ZERO:
		_interact = Interactable.new()
		_interact.verb = "Ring"
		# The pull zone reaches 60 px below the rope's handle (set the handle
		# 60 px above the floor so the player can stand in it)
		_interact.size = Vector2(40, 60)
		_interact.position = pull_offset + Vector2(0, 60)
		_interact.prompt_offset = Vector2(0, -80)
		add_child(_interact)
		_interact.interacted.connect(func(_p): ring())


func get_lure_point() -> Vector2:
	if lure_point != Vector2.ZERO:
		return lure_point
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0, 600), 2)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit["position"] if not hit.is_empty() else global_position


func is_ready() -> bool:
	return _cooldown_left <= 0.0


func ring() -> void:
	if not is_ready():
		return
	_cooldown_left = cooldown
	_swing_speed = 9.0
	_waves.append(0.0)
	Sfx.play("bell", global_position)
	var point := get_lure_point()
	for listener in get_tree().get_nodes_in_group("bell_listener"):
		if listener.global_position.distance_to(point) <= lure_radius and listener.has_method("hear_bell"):
			listener.hear_bell(point)
	rung.emit(point)
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(1.5, 0.15)


func reset_state() -> void:
	_cooldown_left = 0.0
	_swing = 0.0
	_swing_speed = 0.0
	_waves.clear()


func _process(delta: float) -> void:
	_time += delta
	if Engine.is_editor_hint():
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	# Damped swing
	_swing_speed += -_swing * 60.0 * delta
	_swing_speed *= pow(0.2, delta)
	_swing += _swing_speed * delta
	for i in range(_waves.size() - 1, -1, -1):
		_waves[i] += delta
		if _waves[i] > 1.2:
			_waves.remove_at(i)
	if _interact:
		_interact.verb = "Ring" if is_ready() else "Ringing..."
	queue_redraw()
	_glow.queue_redraw()


func _draw() -> void:
	var iron := Color("2b2838")
	var iron_light := Color("5b5773")
	# Chain up to the ceiling, then the mounting bracket
	if chain_length > 0.0:
		var y := -22.0
		while y > -22.0 - chain_length:
			draw_rect(Rect2(-1.5, y - 6.0, 3, 5), iron_light, false, 1.0)
			y -= 6.0
	draw_rect(Rect2(-10, -22, 20, 4), iron)
	draw_line(Vector2(0, -18), Vector2(0, -14), iron, 2.0)
	# Rope/chain to the pull
	if pull_offset != Vector2.ZERO:
		var corner := Vector2(pull_offset.x, -20)
		draw_line(Vector2(0, -20), corner, iron_light, 1.0)
		draw_line(corner, pull_offset, Color("6b5b4a"), 1.0)
		draw_rect(Rect2(pull_offset + Vector2(-2, 0), Vector2(4, 8)), Color("7d6a55"))
	# The bell swings about its mount
	var t := Transform2D(_swing * 0.35, Vector2(0, -14))
	draw_set_transform_matrix(t)
	var body := PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(9, 12), Vector2(14, 20),
		Vector2(-14, 20), Vector2(-9, 12)])
	draw_colored_polygon(body, Color("3a3550"))
	draw_polyline(body + PackedVector2Array([body[0]]), iron_light, 1.0)
	draw_rect(Rect2(-14, 18, 28, 3), Color("4a4462"))
	draw_circle(Vector2(sin(_swing) * 4.0, 22), 3.0, iron)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_glow() -> void:
	# Rune on the bell: lit when ready to ring, dark while cooling down
	var t := Transform2D(_swing * 0.35, Vector2(0, -14))
	_glow.draw_set_transform_matrix(t)
	var ready_color := Color(0.55, 0.75, 1.0, 0.9) if is_ready() or Engine.is_editor_hint() else Color(0.35, 0.3, 0.5, 0.5)
	_glow.draw_rect(Rect2(-1, 6, 2, 8), ready_color)
	_glow.draw_rect(Rect2(-4, 9, 8, 2), ready_color)
	_glow.draw_set_transform_matrix(Transform2D.IDENTITY)
	# Expanding rings show the sound travelling
	for w in _waves:
		var r := 12.0 + w * 90.0
		_glow.draw_arc(Vector2(0, 0), r, 0.0, TAU, 40, Color(0.6, 0.8, 1.0, (1.0 - w / 1.2) * 0.5), 1.5)
