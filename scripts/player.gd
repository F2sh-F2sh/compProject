extends CharacterBody2D

@export var fireball_scene: PackedScene
@export var hurtbox: Hurtbox

@export_group("Jump Animation")
@export var jump_animation_name: StringName = &"jump"
@export_range(1.0, 60.0, 0.5) var jump_animation_fps: float = 12.0

# The seven frames in your new sheet, from left to right.
enum JumpFrame {
	ANTICIPATION,
	LAUNCH,
	RISING,
	APEX,
	FALLING,
	LANDING,
	RECOVERY,
}

# --- Mana ---
const MAX_MANA := 100
const FIREBALL_COST := 5
const HEAL_COST := 20
const RELOAD_TIME := 2.0

var current_mana := MAX_MANA
var is_reloading := false
var reload_progress := 0.0

# --- Movement ---
const SPEED := 130.0
const SPRINT_SPEED := 220.0
const FRICTION := 1200.0

const BASE_JUMP_VELOCITY := -350.0
const MAX_JUMP_VELOCITY := -500.0
const CHARGE_START_TIME := 1.0
const MAX_CHARGE_TIME := 2.5
const JUMP_BUFFER_DURATION := 0.15

var air_time := 0.0
var charging_jump := false
var charge_time := 0.0
var jumped := false
var jump_buffer_time := 0.0

# Negative means the landing animation is not active.
var landing_elapsed := -1.0

# --- Health & Invincibility ---
const MAX_HEALTH: int = 10
var current_health: int = MAX_HEALTH
var is_invulnerable := false
var is_dead := false

# --- Sprites ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sprite: AnimatedSprite2D = $AnimatedSprite2D2

var sprite_flash_tween: Tween


func _ready() -> void:
	add_to_group("player")

	animated_sprite.show()
	jump_sprite.hide()
	jump_sprite.pause()

	# Validate the new animation before trying to use its frames.
	if jump_sprite.sprite_frames == null:
		push_error("AnimatedSprite2D2 needs a SpriteFrames resource.")
		set_physics_process(false)
		return

	if not jump_sprite.sprite_frames.has_animation(jump_animation_name):
		push_error("AnimatedSprite2D2 needs an animation named '%s'." % jump_animation_name)
		set_physics_process(false)
		return

	if jump_sprite.sprite_frames.get_frame_count(jump_animation_name) != JumpFrame.RECOVERY + 1:
		push_error("The new jump animation must contain exactly 7 frames, in sheet order.")
		set_physics_process(false)
		return

	# Keep these settings local to this player instance.
	jump_sprite.sprite_frames = jump_sprite.sprite_frames.duplicate() as SpriteFrames
	jump_sprite.sprite_frames.set_animation_speed(jump_animation_name, jump_animation_fps)
	jump_sprite.sprite_frames.set_animation_loop(jump_animation_name, false)
	jump_sprite.animation = jump_animation_name
	jump_sprite.speed_scale = 1.0
	jump_sprite.autoplay = ""

	# Frames are advanced by the jump controller, not automatic playback.
	jump_sprite.pause()
	jump_sprite.flip_h = animated_sprite.flip_h
	jump_sprite.modulate = animated_sprite.modulate

	if hurtbox:
		hurtbox.damage_received.connect(take_damage)

	update_ui_hearts.call_deferred()
	update_mana_ui.call_deferred()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# --- Healing, mana reloading, and shooting ---
	if Input.is_action_just_pressed("heal"):
		heal_player()

	if is_reloading:
		reload_progress += delta

		if reload_progress >= RELOAD_TIME:
			current_mana = MAX_MANA
			is_reloading = false
			reload_progress = 0.0

			# Do not interrupt the damage flash / invulnerability timer.
			if not is_invulnerable:
				_flash_sprites(Color(0.7, 0.7, 0.7, 0.8), 0.15)

		update_mana_ui()

	if Input.is_action_just_pressed("reload"):
		start_reload()

	if Input.is_action_just_pressed("shoot"):
		shoot_fireball()

	var was_on_floor := is_on_floor()

	# --- Jump buffer ---
	jump_buffer_time = maxf(jump_buffer_time - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_time = JUMP_BUFFER_DURATION

	# --- Gravity ---
	if not was_on_floor:
		velocity += get_gravity() * delta
		air_time += delta

		# Walking off a ledge must not leave charging stuck on.
		charging_jump = false
		charge_time = 0.0
	else:
		air_time = 0.0
		jumped = false

	# --- Start charging ---
	if jump_buffer_time > 0.0 and was_on_floor and not charging_jump:
		charging_jump = true
		charge_time = 0.0
		jump_buffer_time = 0.0
		landing_elapsed = -1.0

	if charging_jump:
		charge_time += delta

	# Jump on release. Also handles a buffered tap released before landing.
	if charging_jump and was_on_floor and not Input.is_action_pressed("jump"):
		_release_jump()

	# --- Movement ---
	var direction := Input.get_axis("move_left", "move_right")
	var current_speed := SPEED

	if Input.is_action_pressed("sprint"):
		current_speed = SPRINT_SPEED

	# Face movement, or the mouse while idle. Keep both sprites in sync.
	if direction > 0.0:
		animated_sprite.flip_h = false
	elif direction < 0.0:
		animated_sprite.flip_h = true
	elif absf(velocity.x) < 5.0:
		animated_sprite.flip_h = get_global_mouse_position().x < global_position.x

	jump_sprite.flip_h = animated_sprite.flip_h

	if charging_jump and charge_time >= CHARGE_START_TIME:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
	elif direction != 0.0:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	move_and_slide()

	# A collision callback could have killed the player during movement.
	if is_dead:
		return

	if is_on_ceiling():
		# A ceiling hit cancels the normal launch / apex pose sequence.
		jumped = false

	# Start landing poses only after actual floor contact.
	if is_on_floor() and not was_on_floor:
		landing_elapsed = 0.0
		air_time = 0.0
		jumped = false

	_update_animation(delta)


func _release_jump() -> void:
	var jump_velocity := BASE_JUMP_VELOCITY

	if charge_time > CHARGE_START_TIME:
		var charge_percent := clampf(
			(charge_time - CHARGE_START_TIME) / (MAX_CHARGE_TIME - CHARGE_START_TIME),
			0.0,
			1.0
		)
		jump_velocity = lerpf(BASE_JUMP_VELOCITY, MAX_JUMP_VELOCITY, charge_percent)

	velocity.y = jump_velocity
	jumped = true
	charging_jump = false
	charge_time = 0.0
	air_time = 0.0
	landing_elapsed = -1.0


# --- Animation controller ---
func _update_animation(delta: float) -> void:
	if not is_on_floor():
		landing_elapsed = -1.0
		_show_jump_frame(_get_airborne_frame())
		return

	# Charging can interrupt landing immediately; movement is never locked
	# just because a landing pose is being displayed.
	if charging_jump:
		landing_elapsed = -1.0

		if charge_time >= CHARGE_START_TIME:
			# Preserve your existing charged-jump animation on the old node.
			_play_ground_animation(&"JumpCharge")
		else:
			_show_jump_frame(JumpFrame.ANTICIPATION)
		return

	if landing_elapsed >= 0.0:
		var impact_duration := _jump_frame_duration(JumpFrame.LANDING)
		var recovery_duration := _jump_frame_duration(JumpFrame.RECOVERY)

		if landing_elapsed < impact_duration:
			_show_jump_frame(JumpFrame.LANDING)
			landing_elapsed += delta
			return

		if landing_elapsed < impact_duration + recovery_duration:
			_show_jump_frame(JumpFrame.RECOVERY)
			landing_elapsed += delta
			return

		landing_elapsed = -1.0

	if absf(velocity.x) < 5.0:
		_play_ground_animation(&"idle")
	else:
		var run_speed := 1.7 if Input.is_action_pressed("sprint") else 1.0
		_play_ground_animation(&"run", run_speed)


func _get_airborne_frame() -> int:
	# Walking off an edge skips launch and goes straight to falling.
	if not jumped and velocity.y >= 0.0:
		return JumpFrame.FALLING

	# Show the launch stretch briefly, but never after upward motion stops.
	if jumped and air_time < _jump_frame_duration(JumpFrame.LAUNCH) and velocity.y < 0.0:
		return JumpFrame.LAUNCH

	# Center a short apex-pose window around zero vertical velocity.
	var apex_speed := absf(get_gravity().y) * _jump_frame_duration(JumpFrame.APEX) * 0.5

	if absf(velocity.y) <= apex_speed:
		return JumpFrame.APEX

	if velocity.y < 0.0:
		return JumpFrame.RISING

	return JumpFrame.FALLING


func _show_jump_frame(frame_index: int) -> void:
	animated_sprite.hide()
	animated_sprite.pause()

	jump_sprite.show()
	jump_sprite.pause()
	jump_sprite.frame = frame_index


func _play_ground_animation(animation_name: StringName, playback_speed: float = 1.0) -> void:
	jump_sprite.hide()
	jump_sprite.pause()

	animated_sprite.show()
	animated_sprite.speed_scale = playback_speed
	animated_sprite.play(animation_name)


func _jump_frame_duration(frame_index: int) -> float:
	var relative_duration := jump_sprite.sprite_frames.get_frame_duration(
		jump_animation_name, frame_index
	)
	return relative_duration / maxf(jump_animation_fps, 1.0)


# --- Shared visual effects: flashes affect whichever sprite is visible ---
func _set_sprite_tint(color: Color) -> void:
	animated_sprite.modulate = color
	jump_sprite.modulate = color


func _flash_sprites(color: Color, duration: float, loops: int = 1) -> Tween:
	if sprite_flash_tween != null and sprite_flash_tween.is_valid():
		sprite_flash_tween.kill()

	sprite_flash_tween = create_tween()
	sprite_flash_tween.tween_method(_set_sprite_tint, Color.WHITE, color, duration)
	sprite_flash_tween.tween_method(_set_sprite_tint, color, Color.WHITE, duration)
	sprite_flash_tween.set_loops(loops)
	return sprite_flash_tween


# --- Combat ---
func shoot_fireball() -> void:
	if is_dead or is_reloading or current_mana < FIREBALL_COST:
		return
	if fireball_scene == null:
		return

	var fireball = fireball_scene.instantiate()
	var mouse_pos := get_global_mouse_position()
	var origin_point := global_position + Vector2(0.0, -12.0)
	var dir := (mouse_pos - origin_point).normalized()
	var mouse_distance := origin_point.distance_to(mouse_pos)
	var max_spawn_distance := 50.0
	var spawn_distance := minf(mouse_distance, max_spawn_distance)

	fireball.direction = dir
	fireball.global_position = origin_point + dir * spawn_distance
	get_tree().current_scene.add_child(fireball)

	current_mana -= FIREBALL_COST
	update_mana_ui()

	if current_mana <= 0:
		start_reload()


func take_damage(amount: int = 1) -> void:
	if is_invulnerable or is_dead:
		return

	current_health = clampi(current_health - amount, 0, MAX_HEALTH)
	update_ui_hearts()

	if current_health <= 0:
		die()
		return

	# Four 0.2-second flashes = 0.8 seconds of invulnerability.
	is_invulnerable = true
	var tween := _flash_sprites(Color(1.0, 0.3, 0.3, 0.6), 0.1, 4)
	await tween.finished

	_set_sprite_tint(Color.WHITE)
	is_invulnerable = false


func heal_player() -> void:
	if is_dead or is_reloading:
		return
	if current_health >= MAX_HEALTH or current_mana < HEAL_COST:
		return

	current_mana -= HEAL_COST
	current_health = clampi(current_health + 2, 0, MAX_HEALTH)
	update_ui_hearts()
	update_mana_ui()

	if not is_invulnerable:
		_flash_sprites(Color(0.4, 0.8, 1.0, 0.8), 0.15)

	if current_mana <= 0:
		start_reload()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	animated_sprite.pause()
	jump_sprite.pause()
	set_physics_process(false)

	var death_screen = get_tree().current_scene.get_node_or_null("DeathUI/DeathScreen")
	if death_screen:
		death_screen.show_death_screen()


# --- UI & Reloading ---
func update_ui_hearts() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("set_hearts"):
		hud.set_hearts(current_health, MAX_HEALTH)


func start_reload() -> void:
	if is_dead or is_reloading or current_mana == MAX_MANA:
		return

	is_reloading = true
	reload_progress = 0.0
	update_mana_ui()


func update_mana_ui() -> void:
	var mana_ui = get_tree().get_first_node_in_group("ammo_ui")
	if mana_ui:
		var percent := 0.0
		if is_reloading:
			percent = clampf(reload_progress / RELOAD_TIME, 0.0, 1.0)

		mana_ui.update_display(current_mana, MAX_MANA, is_reloading, percent)
