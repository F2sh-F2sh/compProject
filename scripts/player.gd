extends CharacterBody2D

@export var fireball_scene: PackedScene

const SPEED = 130.0

const FRICTION = 1200.0

const BASE_JUMP_VELOCITY = -350.0
const MAX_JUMP_VELOCITY = -500.0

const CHARGE_START_TIME = 1.0
const MAX_CHARGE_TIME = 2.5

const JUMP_BUFFER_DURATION = 0.15

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var air_time := 0.0
var charging_jump := false
var charge_time := 0.0
var jumped := false

var jump_buffer_time := 0.0

func shoot_fireball():
	var fireball = fireball_scene.instantiate()

	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()

	fireball.global_position = global_position + dir * 40
	fireball.direction = dir

	get_tree().current_scene.add_child(fireball)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		shoot_fireball()
	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_time = JUMP_BUFFER_DURATION

	if jump_buffer_time > 0:
		jump_buffer_time -= delta

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		air_time += delta
	else:
		air_time = 0.0
		jumped = false

	# Start charging from buffered jump
	if jump_buffer_time > 0 and is_on_floor() and not charging_jump:
		charging_jump = true
		charge_time = 0.0
		jump_buffer_time = 0.0

	# Charge timer
	if charging_jump:
		charge_time += delta

	# Release jump
	if Input.is_action_just_released("jump") and charging_jump and is_on_floor():
		charging_jump = false

		var jump_velocity = BASE_JUMP_VELOCITY

		if charge_time > CHARGE_START_TIME:
			var charge_percent = min(
				(charge_time - CHARGE_START_TIME) /
				(MAX_CHARGE_TIME - CHARGE_START_TIME),
				1.0
			)

			jump_velocity = lerp(
				BASE_JUMP_VELOCITY,
				MAX_JUMP_VELOCITY,
				charge_percent
			)

		velocity.y = jump_velocity
		jumped = true

	# Movement input
	var direction := Input.get_axis("move_left", "move_right")

	# Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Horizontal movement
	if charging_jump and charge_time >= CHARGE_START_TIME:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	else:
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	move_and_slide()

	# Animations
	if is_on_floor():
		if charging_jump and charge_time >= CHARGE_START_TIME:
			animated_sprite.speed_scale = 1.0
			animated_sprite.play("JumpCharge")

		elif abs(velocity.x) < 5:
			animated_sprite.speed_scale = 1.0
			animated_sprite.play("idle")

		else:
			animated_sprite.speed_scale = max(abs(velocity.x) / SPEED * 1.2, 0.8)
			animated_sprite.play("run")

	else:
		animated_sprite.speed_scale = 1.0
		animated_sprite.play("jump")
