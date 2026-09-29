extends CharacterBody2D

## The slime. It hops around a limited area, chases and lunges at the player
## or an Echo, and — if `hears_bells` — hops over to a rung bell and sits
## there for `investigate_time`. It has enough weight to hold pressure plates.
## States read at a glance: "!" when alerted, sound rings while listening,
## a red squash before it lunges, a flash when hurt, a puff when defeated.

signal defeated

enum State { PATROL, ALERTED, INVESTIGATE, WINDUP, LUNGE, DEFEATED }

@export var damage_number_scene: PackedScene
@export var max_health := 30
@export var detection_range := 200.0
@export var hop_force := -250.0
@export var hop_speed := 80.0
@export var hop_cooldown := 0.8

# Aggro settings
@export var aggro_hop_speed := 140.0
@export var aggro_hop_cooldown := 0.5
## When above zero, wandering never takes the slime further than this from
## where it started, so it stays in its arena.
@export var home_radius := 0.0

@export_group("Bells")
@export var hears_bells := false
@export var investigate_time := 8.0
## While listening at a bell it ignores the player (unless hit), so bell
## puzzles stay reliable.
@export var ignore_player_while_investigating := true

@export_group("Attack")
@export var lunge_range := 60.0
@export var windup_time := 0.45
@export var lunge_speed := 190.0

@export_group("Puzzle")
## Puzzle slimes come back when their room is reset instead of being removed.
@export var respawn_on_room_reset := false
## A slime the puzzle needs alive: hits only make its ward shimmer.
@export var warded := false
## Health the slime leaves behind when defeated.
@export var drops_health := 1

var health: int
var player
var hop_timer := 0.0
var was_on_floor := true
var home_x := 0.0
var is_dead := false
var is_aggro := false
var state: State = State.PATROL

var _state_time := 0.0
var _investigate_x := 0.0
var _start_position := Vector2.ZERO
var _lunge_target: Node2D
var _emote: Node2D
var _time := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	# A slime is short: drawn above props, grates and the thorns framing the
	# bottom of the view (40) so it is never hidden behind them
	z_index = 42
	health = max_health
	home_x = global_position.x
	_start_position = global_position
	player = get_tree().get_first_node_in_group("player")
	add_to_group("plate_weight")
	if hears_bells:
		add_to_group("bell_listener")
	if respawn_on_room_reset:
		add_to_group("resettable")
	_emote = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_emote.material = mat
	_emote.z_index = 5
	_emote.draw.connect(_draw_emote)
	add_child(_emote)


## The nearest player or Echo; Echoes can distract slimes.
func _find_target() -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for node in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("echo"):
		var candidate := node as Node2D
		if candidate == null or candidate.get("is_dead") == true:
			continue
		var d := global_position.distance_to(candidate.global_position)
		if d < best_distance:
			best_distance = d
			best = candidate
	return best


## False while it is defeated or sitting at a bell, ignoring the player.
func is_threatening() -> bool:
	if is_dead:
		return false
	var listening := state == State.ALERTED or state == State.INVESTIGATE
	return not (listening and ignore_player_while_investigating)


## Called by a PuzzleBell in range.
func hear_bell(point: Vector2) -> void:
	if is_dead or not hears_bells:
		return
	_investigate_x = point.x
	_set_state(State.ALERTED)
	velocity.x = 0.0
	if is_on_floor():
		velocity.y = hop_force * 0.5
	Sfx.play("slime_alert", global_position)


func _set_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _physics_process(delta):
	_time += delta
	_state_time += delta
	if not is_on_floor():
		velocity += get_gravity() * delta
	hop_timer -= delta

	match state:
		State.PATROL:
			_patrol()
		State.ALERTED:
			if is_on_floor():
				velocity.x = 0.0
			if _state_time >= 0.5:
				_set_state(State.INVESTIGATE)
		State.INVESTIGATE:
			_investigate()
		State.WINDUP:
			velocity.x = 0.0
			if _state_time >= windup_time and is_on_floor():
				_lunge()
		State.LUNGE:
			if is_on_floor() and _state_time > 0.15:
				velocity.x = 0.0
				hop_timer = aggro_hop_cooldown
				_set_state(State.PATROL)

	move_and_slide()

	# Landing squash
	if is_on_floor() and not was_on_floor:
		_play_land_squash()
		if state != State.LUNGE and is_on_floor():
			velocity.x = 0.0
	was_on_floor = is_on_floor()
	_update_look()
	_emote.queue_redraw()


func _patrol() -> void:
	if hop_timer > 0.0 or not is_on_floor():
		return
	player = _find_target()
	if player and global_position.distance_to(player.global_position) <= lunge_range \
			and absf(player.global_position.y - global_position.y) < 40.0:
		_lunge_target = player
		_set_state(State.WINDUP)
		return
	hop()


func _investigate() -> void:
	var dx := _investigate_x - global_position.x
	if absf(dx) > 10.0:
		if hop_timer <= 0.0 and is_on_floor():
			hop_timer = 0.45
			# Aim each hop so it lands on the bell spot rather than overshooting
			var airtime := 2.0 * absf(hop_force) / get_gravity().y
			velocity.x = clampf(dx / airtime, -hop_speed * 1.4, hop_speed * 1.4)
			velocity.y = hop_force
			_play_hop_squash()
		return
	if is_on_floor():
		velocity.x = 0.0
	if not ignore_player_while_investigating:
		var target := _find_target()
		if target and global_position.distance_to(target.global_position) < lunge_range:
			_set_state(State.PATROL)
			return
	if _state_time >= investigate_time:
		hop_timer = hop_cooldown
		_set_state(State.PATROL)


func _lunge() -> void:
	var dir := 1.0
	if is_instance_valid(_lunge_target):
		dir = signf(_lunge_target.global_position.x - global_position.x)
	if dir == 0.0:
		dir = 1.0
	velocity.x = dir * lunge_speed
	velocity.y = hop_force * 0.8
	_set_state(State.LUNGE)
	_play_hop_squash()


func hop():
	if is_aggro:
		hop_timer = aggro_hop_cooldown
	else:
		hop_timer = hop_cooldown

	player = _find_target()

	if player:
		var direction = sign(
			player.global_position.x - global_position.x
		)

		# Aggro slime moves faster
		if is_aggro:
			velocity.x = direction * aggro_hop_speed
		else:
			var distance = global_position.distance_to(
				player.global_position
			)

			if distance <= detection_range:
				velocity.x = direction * hop_speed
			else:
				velocity.x = _wander_direction() * hop_speed

	else:
		velocity.x = _wander_direction() * hop_speed

	velocity.y = hop_force

	_play_hop_squash()


func _wander_direction() -> float:
	if home_radius > 0.0 and absf(global_position.x - home_x) > home_radius:
		return signf(home_x - global_position.x)
	return [-1.0, 1.0].pick_random()


func _update_look() -> void:
	# Wind-up: a red, trembling squash that telegraphs the lunge
	if state == State.WINDUP:
		sprite.self_modulate = Color(1.0, 0.55, 0.55)
		sprite.position.x = sin(_time * 60.0) * 1.0
		sprite.scale = Vector2(1.25, 0.75)
	else:
		sprite.self_modulate = Color.WHITE
		sprite.position.x = 0.0


func _play_hop_squash():
	var tween = create_tween()

	tween.tween_property(
		sprite,
		"scale",
		Vector2(1.2, 0.7),
		0.08
	)

	tween.tween_property(
		sprite,
		"scale",
		Vector2(0.8, 1.3),
		0.12
	)

	tween.tween_property(
		sprite,
		"scale",
		Vector2(1, 1),
		0.2
	)


func _play_land_squash():
	var tween = create_tween()

	tween.tween_property(
		sprite,
		"scale",
		Vector2(1.3, 0.6),
		0.06
	)

	tween.tween_property(
		sprite,
		"scale",
		Vector2(1, 1),
		0.15
	)


func take_damage(amount, critical := false):
	if is_dead:
		return
	if warded:
		_shimmer_ward()
		return
	# Become aggressive when hit, even while listening at a bell
	is_aggro = true
	if state == State.INVESTIGATE or state == State.ALERTED:
		_set_state(State.PATROL)

	health -= amount
	Sfx.play("slime_hurt", global_position)

	# Create floating damage number
	if damage_number_scene:
		var damage_number = damage_number_scene.instantiate()

		get_tree().current_scene.add_child(damage_number)

		damage_number.global_position = $Marker2D.global_position

		damage_number.setup(amount, critical)

	# A white flash and a shove away from Echidna, so every hit is felt
	modulate = Color(2.6, 2.4, 2.4)
	var hitter := get_tree().get_first_node_in_group("player") as Node2D
	if hitter and health > 0:
		var away := signf(global_position.x - hitter.global_position.x)
		velocity = Vector2((away if away != 0.0 else 1.0) * (190.0 if critical else 130.0), -90.0)
	_play_hop_squash()

	await get_tree().create_timer(0.12).timeout

	modulate = Color.WHITE

	if health <= 0:
		die()


func _shimmer_ward() -> void:
	Sfx.play("ward_clink", global_position)
	var ring := CPUParticles2D.new()
	ring.one_shot = true
	ring.explosiveness = 1.0
	ring.amount = 14
	ring.lifetime = 0.4
	ring.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
	ring.emission_sphere_radius = 14.0
	ring.spread = 180.0
	ring.gravity = Vector2.ZERO
	ring.initial_velocity_min = 10.0
	ring.initial_velocity_max = 25.0
	ring.color = Color(0.6, 0.85, 1.0, 0.9)
	ring.material = MagicLight.unshaded()
	ring.position = Vector2(0, -8)
	add_child(ring)
	ring.emitting = true
	ring.finished.connect(ring.queue_free)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(0.7, 0.9, 1.6), 0.06)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


func die():
	if is_dead:
		return
	is_dead = true
	_set_state(State.DEFEATED)
	set_physics_process(false)
	var contact := get_node_or_null("DamageArea")
	if contact:
		contact.set_deferred("monitoring", false)
	remove_from_group("enemy")
	Sfx.play("slime_die", global_position)
	defeated.emit()
	# A defeated slime leaves a little health behind (puzzle slimes don't:
	# a room reset brings them back)
	if not respawn_on_room_reset and drops_health > 0:
		Pickup.drop(get_parent(), global_position + Vector2(0, -10), drops_health)

	var puff := CPUParticles2D.new()
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.amount = 16
	puff.lifetime = 0.5
	puff.spread = 180.0
	puff.gravity = Vector2(0, 60)
	puff.initial_velocity_min = 30.0
	puff.initial_velocity_max = 70.0
	puff.scale_amount_min = 2.0
	puff.scale_amount_max = 3.0
	puff.color = Color(0.45, 0.85, 0.5, 0.85)
	puff.position = Vector2(0, -8)
	add_child(puff)
	puff.emitting = true
	puff.finished.connect(puff.queue_free)

	var tween := create_tween().set_parallel()
	tween.tween_property(sprite, "scale", Vector2(1.6, 0.2), 0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.chain().tween_interval(0.3)
	if respawn_on_room_reset:
		# Keep the node so a room reset can bring it back
		tween.chain().tween_callback(func():
			visible = false
			collision_layer = 0
			collision_mask = 0)
	else:
		tween.chain().tween_callback(queue_free)


## Room reset: back to the starting spot, full health, calm.
func reset_state() -> void:
	global_position = _start_position
	velocity = Vector2.ZERO
	health = max_health
	is_dead = false
	is_aggro = false
	hop_timer = hop_cooldown
	_set_state(State.PATROL)
	visible = true
	collision_layer = 1
	collision_mask = 2
	sprite.scale = Vector2.ONE
	sprite.modulate.a = 1.0
	modulate = Color.WHITE
	if not is_in_group("enemy"):
		add_to_group("enemy")
	var contact := get_node_or_null("DamageArea")
	if contact:
		contact.set_deferred("monitoring", true)
	set_physics_process(true)
	reset_physics_interpolation()


func _draw_emote() -> void:
	var top := Vector2(0, -30)
	match state:
		State.ALERTED:
			# A bold "!" that pops in
			var pop := minf(_state_time / 0.12, 1.0)
			_emote.draw_rect(Rect2(top + Vector2(-1.5, -10.0 * pop), Vector2(3, 7 * pop)), Color(1.0, 0.85, 0.35))
			_emote.draw_rect(Rect2(top + Vector2(-1.5, -1), Vector2(3, 3)), Color(1.0, 0.85, 0.35))
		State.INVESTIGATE:
			# Listening: soft rings pulse from its head
			for i in 2:
				var r := fmod(_time * 1.5 + i * 0.5, 1.0)
				_emote.draw_arc(top + Vector2(0, 4), 3.0 + r * 8.0, -PI * 0.85, -PI * 0.15, 8,
					Color(0.6, 0.8, 1.0, (1.0 - r) * 0.8), 1.0)
		State.WINDUP:
			for x in [-4, 0, 4]:
				_emote.draw_line(top + Vector2(x, -6), top + Vector2(x * 1.4, -1), Color(1.0, 0.4, 0.35), 1.0)
