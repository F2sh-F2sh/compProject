@tool
class_name WatcherGargoyle
extends CharacterBody2D

## A cracked stone gargoyle that moves in darkness and turns to stone in
## magical light (beams, lit brazier auras, wisps). The rule never changes.
## - Active: patrols between patrol_min_x and patrol_max_x (it can never leave
##   that span, so it stays in its room), pursues the player it can see, and
##   attacks with a clear wind-up -> strike -> recovery. The player can pass
##   through it while it moves; only the strike hurts.
## - Frozen: cannot move or attack, is solid and weight-bearing (you can stand
##   on it; it holds pressure plates). If the player is inside it at the moment
##   it freezes, it waits until they step out before becoming solid.
## - Waking: after the light leaves it stirs for a moment and cannot attack.
## Fireballs splash harmlessly off its stone skin.

enum State { PATROL, PURSUE, WINDUP, STRIKE, RECOVER, FROZEN, WAKING }

const TEXTURE := preload("res://assets/TileSet/props/sprites/gargoyle.png")
## The crouching body, without the statue's rock pile.
const REGION := Rect2(28, 63, 72, 45)
const ART_SCALE := 0.8
const BODY_SIZE := Vector2(40, 32)

@export var patrol_min_x := 0.0
@export var patrol_max_x := 0.0
@export var walk_speed := 40.0
@export var pursue_speed := 64.0
@export var detect_range := 200.0
@export var attack_range := 40.0
@export var windup_time := 0.6
@export var strike_time := 0.25
@export var recover_time := 0.9
@export var wake_grace := 1.0
@export var unfreeze_delay := 0.35
@export var edge_pause := 0.8
@export var damage_amount := 2
@export var knockback := Vector2(190, -150)
@export var start_facing := 1

var state: State = State.PATROL
var facing := 1
var is_frozen := false

var _state_time := 0.0
var _time := 0.0
var _lit_timer := 0.0
var _beam_timer := 0.0
var _pause := 0.0
var _grace := 0.0
var _solid_pending := false
var _struck := false
var _start_position := Vector2.ZERO
var _sprite: Sprite2D
var _overlay: Node2D
var _strike_area: Area2D
var _body_sensor: Area2D


func _ready() -> void:
	facing = start_facing
	_sprite = Sprite2D.new()
	_sprite.texture = TEXTURE
	_sprite.region_enabled = true
	_sprite.region_rect = REGION
	_sprite.centered = false
	_sprite.offset = Vector2(-REGION.size.x / 2.0, -REGION.size.y)
	_sprite.scale = Vector2.ONE * ART_SCALE
	add_child(_sprite)
	_overlay = Node2D.new()
	_overlay.material = MagicLight.unshaded()
	_overlay.z_index = 1
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_update_facing()
	if Engine.is_editor_hint():
		return

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = BODY_SIZE
	shape.shape = rect
	shape.position = Vector2(0, -BODY_SIZE.y / 2.0)
	add_child(shape)
	collision_mask = 2
	_set_solid(false)
	add_to_group("gargoyle")
	add_to_group("plate_weight")
	add_to_group("resettable")
	add_to_group("world")  # fireballs splash off stone
	MagicLight.add_sensor(self, 16.0, Vector2(0, -BODY_SIZE.y / 2.0))

	_strike_area = Area2D.new()
	_strike_area.collision_layer = 0
	_strike_area.collision_mask = 2
	_strike_area.monitorable = false
	var strike_shape := CollisionShape2D.new()
	var strike_rect := RectangleShape2D.new()
	strike_rect.size = Vector2(44, 30)
	strike_shape.shape = strike_rect
	_strike_area.add_child(strike_shape)
	add_child(_strike_area)

	_body_sensor = Area2D.new()
	_body_sensor.collision_layer = 0
	_body_sensor.collision_mask = 1
	_body_sensor.monitorable = false
	var body_shape := CollisionShape2D.new()
	var body_rect := RectangleShape2D.new()
	body_rect.size = BODY_SIZE + Vector2(4, 4)
	body_shape.shape = body_rect
	body_shape.position = Vector2(0, -BODY_SIZE.y / 2.0)
	_body_sensor.add_child(body_shape)
	add_child(_body_sensor)
	_start_position = global_position


# --- light interface ---
func receive_light(_beam: Node) -> void:
	_beam_timer = 0.12


func get_knockback_velocity(target: Node2D) -> Vector2:
	var side := signf(target.global_position.x - global_position.x)
	if side == 0.0:
		side = facing
	return Vector2(side * knockback.x, knockback.y)


func reset_state() -> void:
	global_position = _start_position
	velocity = Vector2.ZERO
	facing = start_facing
	_lit_timer = 0.0
	_beam_timer = 0.0
	_pause = 0.0
	_grace = 0.0
	is_frozen = false
	_solid_pending = false
	_set_solid(false)
	_set_state(State.PATROL)
	_update_facing()
	reset_physics_interpolation()


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0
	_struck = false


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_state_time += delta
	_beam_timer -= delta
	var center := global_position + Vector2(0, -BODY_SIZE.y / 2.0)
	var lit := _beam_timer > 0.0 or MagicLight.aura_reaches(get_world_2d(), center, [get_rid()])

	if lit:
		_lit_timer = unfreeze_delay
		if state != State.FROZEN:
			_freeze()
	elif state == State.FROZEN:
		_lit_timer -= delta
		if _lit_timer <= 0.0:
			_wake()

	if _solid_pending and not _player_inside():
		_solid_pending = false
		_set_solid(true)

	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	match state:
		State.FROZEN:
			velocity.x = 0.0
		State.PATROL:
			_patrol(delta)
		State.WAKING:
			_grace -= delta
			_patrol(delta)
			if _grace <= 0.0:
				_set_state(State.PATROL)
		State.PURSUE:
			_pursue()
		State.WINDUP:
			velocity.x = 0.0
			if _state_time >= windup_time:
				_set_state(State.STRIKE)
				Sfx.play("gargoyle_attack", global_position)
		State.STRIKE:
			velocity.x = facing * 220.0 * (1.0 - _state_time / strike_time)
			_strike_area.position = Vector2(facing * 22.0, -16)
			if not _struck:
				for area in _strike_area.get_overlapping_areas():
					if area is Hurtbox:
						area.receive_damage(damage_amount, self)
						_struck = true
			if _state_time >= strike_time:
				_set_state(State.RECOVER)
		State.RECOVER:
			velocity.x = 0.0
			if _state_time >= recover_time:
				_set_state(State.PURSUE)
	move_and_slide()
	# Never leave the patrol span, whatever happens
	if patrol_max_x > patrol_min_x:
		global_position.x = clampf(global_position.x, patrol_min_x, patrol_max_x)
	_update_facing()
	_update_look()
	_overlay.queue_redraw()


func _patrol(delta: float) -> void:
	var target := _visible_player()
	if target and state == State.PATROL:
		_set_state(State.PURSUE)
		return
	if _pause > 0.0:
		_pause -= delta
		velocity.x = 0.0
		return
	velocity.x = facing * walk_speed
	if (facing > 0 and global_position.x >= patrol_max_x - 1.0) or (facing < 0 and global_position.x <= patrol_min_x + 1.0):
		facing = -facing
		_pause = edge_pause
		velocity.x = 0.0


func _pursue() -> void:
	var target := _visible_player()
	if target == null:
		_set_state(State.PATROL)
		return
	var dx := target.global_position.x - global_position.x
	facing = 1 if dx > 0.0 else -1
	if absf(dx) <= attack_range and absf(target.global_position.y - global_position.y) < 40.0:
		velocity.x = 0.0
		_set_state(State.WINDUP)
		Sfx.play("gargoyle_windup", global_position)
		return
	velocity.x = facing * pursue_speed
	# Stop at the edge of its span rather than follow the player out
	var next_x := global_position.x + velocity.x * get_physics_process_delta_time()
	if next_x <= patrol_min_x or next_x >= patrol_max_x:
		velocity.x = 0.0


func _visible_player() -> Node2D:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or player.is_dead:
		return null
	if player.global_position.x < patrol_min_x - attack_range or player.global_position.x > patrol_max_x + attack_range:
		return null
	if global_position.distance_to(player.global_position) > detect_range:
		return null
	var eye := global_position + Vector2(0, -24)
	if not MagicLight.line_is_clear(get_world_2d(), eye, player.global_position + Vector2(0, -20), [get_rid()]):
		return null
	return player


func _freeze() -> void:
	_set_state(State.FROZEN)
	is_frozen = true
	velocity.x = 0.0
	Sfx.play("gargoyle_freeze", global_position)
	# Become solid only once nobody is standing inside it
	if _player_inside():
		_solid_pending = true
	else:
		_set_solid(true)


func _wake() -> void:
	is_frozen = false
	_solid_pending = false
	_set_solid(false)
	_grace = wake_grace
	_set_state(State.WAKING)
	Sfx.play("gargoyle_wake", global_position)


func _player_inside() -> bool:
	for body in _body_sensor.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


func _set_solid(solid: bool) -> void:
	# Layer 1 lets plates and fireballs sense it; layer 2 makes it solid to the
	# player and to light beams
	collision_layer = 3 if solid else 1


func _update_facing() -> void:
	if _sprite:
		_sprite.flip_h = facing < 0


func _update_look() -> void:
	var bob := 0.0
	var squash := Vector2.ONE
	var shake := 0.0
	match state:
		State.PATROL, State.PURSUE, State.WAKING:
			if absf(velocity.x) > 1.0:
				bob = -absf(sin(_time * 9.0)) * 2.0
		State.WINDUP:
			squash = Vector2(1.08, 0.9)
			shake = sin(_time * 70.0) * 1.0
		State.STRIKE:
			squash = Vector2(1.12, 0.94)
		State.RECOVER:
			squash = Vector2(1.04, 0.96)
	if state == State.WAKING:
		shake = sin(_time * 50.0) * 0.8
	_sprite.position = Vector2(shake, bob)
	_sprite.scale = Vector2.ONE * ART_SCALE * squash
	# Frozen gargoyles turn to grey stone
	_sprite.self_modulate = Color(0.6, 0.6, 0.7) if state == State.FROZEN else Color.WHITE


func _eye_position() -> Vector2:
	var local := Vector2(52 - REGION.size.x / 2.0, 14 - REGION.size.y) * ART_SCALE
	return Vector2(local.x * facing, local.y) + _sprite.position


func _draw_overlay() -> void:
	if Engine.is_editor_hint():
		_overlay.draw_line(Vector2(patrol_min_x - global_position.x, 4), Vector2(patrol_max_x - global_position.x, 4),
			Color(1, 0.4, 0.4, 0.6), 2.0)
		return
	# Faint runes on the floor mark the edges of its territory
	if patrol_max_x > patrol_min_x:
		for edge_x in [patrol_min_x, patrol_max_x]:
			var local := Vector2(edge_x - global_position.x, 0)
			_overlay.draw_rect(Rect2(local + Vector2(-1, -10), Vector2(2, 10)), Color(0.85, 0.3, 0.3, 0.45))
			_overlay.draw_rect(Rect2(local + Vector2(-4, -2), Vector2(8, 2)), Color(0.85, 0.3, 0.3, 0.45))
	var eye := _eye_position()
	match state:
		State.FROZEN:
			# Frost-blue cracks show it is locked in stone
			var c := Color(0.6, 0.8, 1.0, 0.8)
			_overlay.draw_line(Vector2(-10, -26), Vector2(-4, -18), c, 1.0)
			_overlay.draw_line(Vector2(-4, -18), Vector2(-7, -10), c, 1.0)
			_overlay.draw_line(Vector2(6, -22), Vector2(10, -14), c, 1.0)
			_overlay.draw_line(Vector2(10, -14), Vector2(6, -6), c, 1.0)
		State.WINDUP:
			var flare := 1.0 + _state_time / windup_time
			_overlay.draw_rect(Rect2(eye - Vector2(1.5, 1.5) * flare, Vector2(3, 3) * flare), Color(1.0, 0.25, 0.2))
		State.RECOVER:
			_overlay.draw_rect(Rect2(eye - Vector2(1, 1), Vector2(2, 2)), Color(0.6, 0.2, 0.2, 0.6))
		_:
			_overlay.draw_rect(Rect2(eye - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.3, 0.25, 0.9))
