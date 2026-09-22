extends CharacterBody2D

@export var fireball_scene: PackedScene
@export var hurtbox: Hurtbox

const MAX_AMMO := 6
const RELOAD_TIME := 2.0
var current_ammo := MAX_AMMO
var is_reloading := false
var reload_progress := 0.0

const SPEED = 130.0
const SPRINT_SPEED = 220.0
const FRICTION = 1200.0

const BASE_JUMP_VELOCITY = -350.0
const MAX_JUMP_VELOCITY = -500.0

const CHARGE_START_TIME = 1.0
const MAX_CHARGE_TIME = 2.5
const JUMP_BUFFER_DURATION = 0.15

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- Health & Invincibility ---
const MAX_HEALTH: int = 10
var current_health: int = MAX_HEALTH
var is_invulnerable: bool = false
var is_dead: bool = false

# --- Movement & Charging ---
var air_time := 0.0
var charging_jump := false
var charge_time := 0.0
var jumped := false
var jump_buffer_time := 0.0

func _ready() -> void:
	add_to_group("player")

	if hurtbox:
		hurtbox.damage_received.connect(take_damage)

	update_ui_hearts.call_deferred()

func shoot_fireball() -> void:
	if current_ammo <= 0:
		return
	if is_reloading:
		return
	if fireball_scene == null:
		return

	var fireball = fireball_scene.instantiate()
	var mouse_pos = get_global_mouse_position()

	# Spawn from the player's torso
	var origin_point = global_position + Vector2(0, -12)

	# Direction from player to mouse
	var dir = (mouse_pos - origin_point).normalized()

	# How far away the mouse is
	var mouse_distance = origin_point.distance_to(mouse_pos)

	# Maximum distance the fireball can spawn from the player
	var max_spawn_distance = 50

	# If mouse is closer than the maximum distance,
	# spawn directly at the mouse.
	# Otherwise, spawn at the maximum distance toward the mouse.
	var spawn_distance = min(mouse_distance, max_spawn_distance)

	fireball.global_position = origin_point + dir * spawn_distance
	fireball.direction = dir

	get_tree().current_scene.add_child(fireball)
	current_ammo -= 1
	update_ammo_ui()
	if current_ammo <= 0:
		start_reload()


func take_damage(amount: int = 1) -> void:
	if is_invulnerable or is_dead:
		return

	current_health = clampi(current_health - amount, 0, MAX_HEALTH)
	update_ui_hearts()

	if current_health <= 0:
		die()
		return

	# Temporary hit invulnerability (0.8s) + flash
	is_invulnerable = true

	var tween = create_tween()
	tween.tween_property(
		animated_sprite,
		"modulate",
		Color(1, 0.3, 0.3, 0.6),
		0.1
	)
	tween.tween_property(
		animated_sprite,
		"modulate",
		Color.WHITE,
		0.1
	)
	tween.set_loops(4)

	await tween.finished

	animated_sprite.modulate = Color.WHITE
	is_invulnerable = false


func update_ui_hearts() -> void:
	var hud = get_tree().get_first_node_in_group("hud")

	if hud and hud.has_method("set_hearts"):
		hud.set_hearts(current_health, MAX_HEALTH)


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)

	var death_screen = get_tree().current_scene.get_node_or_null("DeathUI/DeathScreen")

	if death_screen:
		death_screen.show_death_screen()


func _physics_process(delta: float) -> void:
	
	if is_reloading:
		reload_progress += delta

		update_ammo_ui()

	if reload_progress >= RELOAD_TIME:
		current_ammo = MAX_AMMO
		is_reloading = false
		reload_progress = 0.0

		update_ammo_ui()
	
	if Input.is_action_just_pressed("reload"):
		start_reload()

	# -------------------------
	# SHOOTING
	# -------------------------

	if Input.is_action_just_pressed("shoot"):
		shoot_fireball()


	# -------------------------
	# JUMP BUFFER
	# -------------------------

	if Input.is_action_just_pressed("jump"):
		jump_buffer_time = JUMP_BUFFER_DURATION

	if jump_buffer_time > 0:
		jump_buffer_time -= delta


	# -------------------------
	# GRAVITY
	# -------------------------

	if not is_on_floor():
		velocity += get_gravity() * delta
		air_time += delta
	else:
		air_time = 0.0
		jumped = false


	# -------------------------
	# START CHARGING
	# -------------------------

	if jump_buffer_time > 0 and is_on_floor() and not charging_jump:
		charging_jump = true
		charge_time = 0.0
		jump_buffer_time = 0.0


	if charging_jump:
		charge_time += delta


	# -------------------------
	# RELEASE JUMP
	# -------------------------

	if Input.is_action_just_released("jump") and charging_jump and is_on_floor():

		charging_jump = false

		var jump_velocity = BASE_JUMP_VELOCITY

		if charge_time > CHARGE_START_TIME:

			var charge_percent = min(
				(charge_time - CHARGE_START_TIME)
				/ (MAX_CHARGE_TIME - CHARGE_START_TIME),
				1.0
			)

			jump_velocity = lerp(
				BASE_JUMP_VELOCITY,
				MAX_JUMP_VELOCITY,
				charge_percent
			)

		velocity.y = jump_velocity
		jumped = true


	# -------------------------
	# MOVEMENT
	# -------------------------

	var direction := Input.get_axis("move_left", "move_right")

	# Sprint while holding SHIFT
	var current_speed = SPEED

	if Input.is_action_pressed("sprint"):
		current_speed = SPRINT_SPEED


	# Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
# Face mouse while idle
	elif abs(velocity.x) < 5:
		animated_sprite.flip_h = get_global_mouse_position().x < global_position.x


	# -------------------------
	# MOVEMENT / FRICTION
	# -------------------------

	if charging_jump and charge_time >= CHARGE_START_TIME:

		velocity.x = move_toward(
			velocity.x,
			0,
			FRICTION * delta
		)

	else:

		if direction:
			velocity.x = direction * current_speed
		else:
			velocity.x = move_toward(
				velocity.x,
				0,
				FRICTION * delta
			)


	move_and_slide()


	# -------------------------
	# ANIMATIONS
	# -------------------------

	if is_on_floor():

		if charging_jump and charge_time >= CHARGE_START_TIME:

			animated_sprite.speed_scale = 1.0
			animated_sprite.play("JumpCharge")

		elif abs(velocity.x) < 5:

			animated_sprite.speed_scale = 1.0
			animated_sprite.play("idle")

		else:

			animated_sprite.play("run")

			# Normal = 1.0
			# Sprint = faster animation
			if Input.is_action_pressed("sprint"):
				animated_sprite.speed_scale = 1.7
			else:
				animated_sprite.speed_scale = 1.0

	else:

		animated_sprite.speed_scale = 1.0
		animated_sprite.play("jump")

func start_reload():
	if is_reloading:
		return

	if current_ammo == MAX_AMMO:
		return

	is_reloading = true
	reload_progress = 0.0

	update_ammo_ui()

func update_ammo_ui():
	var ammo_ui = get_tree().get_first_node_in_group("ammo_ui")

	if ammo_ui:
		var percent := 0.0

		if is_reloading:
			percent = reload_progress / RELOAD_TIME

		ammo_ui.update_display(
			current_ammo,
			MAX_AMMO,
			is_reloading,
			percent
		)
