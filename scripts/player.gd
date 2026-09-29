extends CharacterBody2D

## Emitted whenever a fireball is launched, so an Echo recording can replay it.
signal fireball_cast(spawn_position: Vector2, direction: Vector2)
## Emitted when a foot plants during a walk or sprint (sound and dust follow).
signal footstep(at: Vector2)

@export var fireball_scene: PackedScene
@export var hurtbox: Hurtbox


const MAX_MANA := 100
## Echoes can drain max mana, but never below this.
const MIN_MANA_CAP := 20
var mana_debt := 0
const FIREBALL_COST := 5
const HEAL_COST := 20
var current_mana := MAX_MANA
const RELOAD_TIME := 2.0
var is_reloading := false
var reload_progress := 0.0

const SPEED = 115.0
const SPRINT_SPEED = 220.0
const FRICTION = 1200.0

const BASE_JUMP_VELOCITY = -350.0
const MAX_JUMP_VELOCITY = -500.0

const CHARGE_START_TIME = 1.0
const MAX_CHARGE_TIME = 2.5
const JUMP_BUFFER_DURATION = 0.15

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wind_layers: Array[Node] = [$ChargeWindBack, $ChargeWindFront]
@onready var sprint_dust: CPUParticles2D = $SprintDust
@onready var land_dust: CPUParticles2D = $LandDust
@onready var hazard_recovery: HazardRecovery = get_node_or_null("HazardRecovery")
# Built by tools/setup_echidna_player.gd
@onready var charge_wisps: AnimatedSprite2D = get_node_or_null("ChargeWisps")
@onready var wisp_light: PointLight2D = get_node_or_null("WispLight")
@onready var wisp_sparks: CPUParticles2D = get_node_or_null("WispSparks")
@onready var walk_dust: CPUParticles2D = get_node_or_null("WalkDust")
@onready var contact_shadow: Sprite2D = get_node_or_null("ContactShadow")

const HIT_INVULNERABILITY := 0.8
## How long a knockback overrides movement input.
const KNOCKBACK_CONTROL_LOCK := 0.22
const BLINK_INTERVAL_MS := 70

# Echidna's clips (assets/sprites/Echidna/echidna_frames.tres) all share one
# canvas with a bottom-centre pivot, so one offset puts her feet on the
# sprite node for every clip and switching clips never pops.
const DEFAULT_SPRITE_OFFSET := Vector2(0, -32)
const GROUND_ANIMS := [&"idle", &"run", &"sprint"]
## Short clips that must finish before anything else plays (recoveries).
const RECOVERY_ANIMS := [&"crouch", &"land", &"run_stop"]
const AFTERIMAGE_INTERVAL := 0.06
const HARD_LANDING_SPEED := 180.0

# A tap stops (via friction) faster than the stride animation can play through
# even one frame. This keeps a step finishing out after the character has
# already stopped, so a quick tap always visibly shows a footfall.
const STEP_COMMIT_DURATION := 0.15
const MIN_ANIM_SPEED_RATIO := 0.45

# --- Health & Invincibility ---
const MAX_HEALTH: int = 10
var current_health: int = MAX_HEALTH
var invulnerable_time := 0.0
var is_dead: bool = false

# --- Control lock (hazard recovery, level exit) ---
var controls_locked := false
## While frozen the player doesn't move at all, not even from gravity.
var physics_frozen := false
var knockback_time := 0.0

# --- Movement & Charging ---
var air_time := 0.0
var charging_jump := false
var charge_time := 0.0
var jumped := false
var jump_buffer_time := 0.0
var was_on_floor := true
var sprite_base_scale := Vector2.ONE
var sprite_base_pos := Vector2.ZERO
var squash_tween: Tween
var is_sprinting := false
var afterimage_timer := 0.0
var fall_speed := 0.0
var step_commit_time := 0.0
var sprite_offset := DEFAULT_SPRITE_OFFSET
# Clip frames where a foot plants, from the sprite pipeline
var footstep_frames := {}

func _ready() -> void:
	add_to_group("player")
	sprite_base_scale = animated_sprite.scale
	sprite_base_pos = animated_sprite.position
	var frames := animated_sprite.sprite_frames
	sprite_offset = frames.get_meta(&"sprite_offset", DEFAULT_SPRITE_OFFSET)
	footstep_frames = frames.get_meta(&"footsteps", {})
	animated_sprite.offset = sprite_offset
	animated_sprite.frame_changed.connect(_on_sprite_frame_changed)

	if hurtbox:
		hurtbox.damage_received.connect(take_damage)

	update_health_ui.call_deferred()
	update_mana_ui.call_deferred()

func shoot_fireball() -> void:
	if current_mana < FIREBALL_COST:
		return
	if is_reloading:
		return
	if fireball_scene == null:
		return

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

	var spawn_position: Vector2 = origin_point + dir * spawn_distance
	spawn_fireball(spawn_position, dir)
	fireball_cast.emit(spawn_position, dir)
	Sfx.play("spell_cast", origin_point, -3.0, 0.08)

	current_mana -= FIREBALL_COST
	update_mana_ui()
	flash_spell("fireball")
	if current_mana <= 0:
		start_reload()


## Launches a fireball without any mana cost; also used by Echo replays.
func spawn_fireball(spawn_position: Vector2, direction: Vector2) -> Node2D:
	var fireball: Node2D = fireball_scene.instantiate()
	fireball.global_position = spawn_position
	fireball.direction = direction
	get_tree().current_scene.add_child(fireball)
	return fireball


func get_mana_cap() -> int:
	return MAX_MANA - mana_debt


## Temporal debt: each living Echo lowers the mana cap.
func set_mana_debt(amount: int) -> void:
	mana_debt = clampi(amount, 0, MAX_MANA - MIN_MANA_CAP)
	current_mana = mini(current_mana, get_mana_cap())
	update_mana_ui()


func take_damage(amount: int = 1, source: Node = null) -> void:
	if is_dead or controls_locked or is_invulnerable():
		return

	current_health = clampi(current_health - amount, 0, MAX_HEALTH)
	update_health_ui()

	# Lethal damage always wins over any hazard reset or knockback
	if current_health <= 0:
		die()
		return

	_flash_hit()

	# Spikes send the player back to a safe point instead of knocking them around
	if hazard_recovery and source and source.has_method("get_recovery_position"):
		hazard_recovery.begin(source.get_recovery_position(self))
		return

	grant_invulnerability(HIT_INVULNERABILITY)
	if source and source.has_method("get_knockback_velocity"):
		var push: Vector2 = source.get_knockback_velocity(self)
		if push != Vector2.ZERO:
			apply_knockback(push)


func is_invulnerable() -> bool:
	return invulnerable_time > 0.0


func grant_invulnerability(seconds: float) -> void:
	invulnerable_time = maxf(invulnerable_time, seconds)


func apply_knockback(knock_velocity: Vector2) -> void:
	charging_jump = false
	charge_time = 0.0
	for wind in wind_layers:
		wind.cancel()
	velocity = knock_velocity
	knockback_time = KNOCKBACK_CONTROL_LOCK


func lock_controls(freeze := false) -> void:
	controls_locked = true
	physics_frozen = freeze
	_clear_motion_state()


func unlock_controls() -> void:
	controls_locked = false
	physics_frozen = false
	_clear_motion_state()


## Moves the player instantly, e.g. back to a hazard checkpoint.
func teleport_to(target: Vector2) -> void:
	global_position = target
	_clear_motion_state()
	physics_frozen = false
	reset_physics_interpolation()
	var camera := get_viewport().get_camera_2d()
	if camera:
		if camera.has_method("snap"):
			camera.snap()
		else:
			camera.reset_smoothing()
		camera.force_update_scroll()


# Drops anything that could carry over and cause an immediate second fall
func _clear_motion_state() -> void:
	velocity = Vector2.ZERO
	charging_jump = false
	charge_time = 0.0
	jump_buffer_time = 0.0
	jumped = false
	knockback_time = 0.0
	is_sprinting = false
	step_commit_time = 0.0
	afterimage_timer = 0.0
	for wind in wind_layers:
		wind.cancel()


## Walking into a pushable block while standing shoves it along.
func _push_blocks() -> void:
	if not is_on_floor():
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var body := collision.get_collider()
		if body is PushableBlock and absf(collision.get_normal().x) > 0.7:
			body.push(-collision.get_normal().x)


func _flash_hit() -> void:
	Sfx.play("player_hurt", global_position)
	var tween = create_tween()
	var flash := Color(1, 0.3, 0.3, 0.6).lerp(Color.WHITE, 1.0 - Settings.flash_strength(1.0))
	tween.tween_property(animated_sprite, "modulate", flash, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)
	tween.set_loops(4)


func _update_invulnerability_blink() -> void:
	var blink_on := int(Time.get_ticks_msec() / BLINK_INTERVAL_MS) % 2 == 0
	animated_sprite.self_modulate.a = 0.35 if is_invulnerable() and blink_on else 1.0


func update_health_ui() -> void:
	var hud = get_tree().get_first_node_in_group("hud")

	if hud:
		hud.set_health(current_health, MAX_HEALTH)


func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	charging_jump = false
	for wind in wind_layers:
		wind.cancel()
	sprint_dust.emitting = false
	if charge_wisps:
		charge_wisps.visible = false
	if wisp_sparks:
		wisp_sparks.emitting = false
	animated_sprite.self_modulate.a = 1.0
	if hazard_recovery:
		hazard_recovery.abort()
	set_physics_process(false)

	var death_screen = get_tree().get_first_node_in_group("death_screen")
	if death_screen == null:
		death_screen = get_tree().current_scene.get_node_or_null("DeathUI/DeathScreen")

	if death_screen:
		death_screen.show_death_screen()


func _physics_process(delta: float) -> void:
	if invulnerable_time > 0.0:
		invulnerable_time = maxf(invulnerable_time - delta, 0.0)
	_update_invulnerability_blink()

	if controls_locked:
		_locked_physics(delta)
		return

	if Input.is_action_just_pressed("heal"):
		heal_player()
		
	if is_reloading:
		reload_progress += delta
		update_mana_ui()

		if reload_progress >= RELOAD_TIME:

			current_mana = get_mana_cap()
			is_reloading = false
			reload_progress = 0.0

			var tween = create_tween()

			tween.tween_property(
				animated_sprite,
				"modulate",
				Color(0.7, 0.7, 0.7, 0.8),
				0.15
			)

			tween.tween_property(
				animated_sprite,
				"modulate",
				Color.WHITE,
				0.15
			)

			update_mana_ui()
	
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


	# Walking off a ledge mid-charge would otherwise leave the charge stuck on
	if charging_jump and not is_on_floor():
		charging_jump = false

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
		play_anim(&"jump", true)
		squash(Vector2(0.85, 1.18))
		Sfx.play("jump", global_position, -6.0, 0.06)
		for wind in wind_layers:
			wind.release()


	# -------------------------
	# MOVEMENT
	# -------------------------

	var direction := Input.get_axis("move_left", "move_right")

	# Sprint while holding SHIFT
	var current_speed = SPEED

	if Input.is_action_pressed("sprint"):
		current_speed = SPRINT_SPEED

	is_sprinting = Input.is_action_pressed("sprint") and direction != 0.0


	# Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true


	# -------------------------
	# MOVEMENT / FRICTION
	# -------------------------

	if knockback_time > 0.0:
		knockback_time -= delta
		velocity.x = move_toward(velocity.x, 0, FRICTION * 0.4 * delta)

	elif charging_jump and charge_time >= CHARGE_START_TIME:

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


	fall_speed = velocity.y
	move_and_slide()
	_push_blocks()

	if is_on_floor() and not was_on_floor:
		on_landed()
	was_on_floor = is_on_floor()

	update_animation(delta)
	update_effects(delta)


func _locked_physics(delta: float) -> void:
	velocity.x = 0.0
	if physics_frozen:
		velocity = Vector2.ZERO
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
		fall_speed = velocity.y
		move_and_slide()
		if is_on_floor() and not was_on_floor:
			on_landed()
		was_on_floor = is_on_floor()
	update_animation(delta)
	update_effects(delta)


func on_landed() -> void:
	var hard := fall_speed > HARD_LANDING_SPEED
	squash(Vector2(1.25, 0.75) if hard else Vector2(1.12, 0.88))
	if hard:
		land_dust.restart()
	Sfx.play("land", global_position, 0.0 if hard else -7.0, 0.08)
	# A one-frame recovery only when stopping; if already running, the squash
	# alone keeps it fluid and control is never taken away
	if absf(velocity.x) < 5.0:
		play_anim(&"land", true)


# Footfalls: a scuff of sound and dust on the frames where a foot plants
func _on_sprite_frame_changed() -> void:
	var planted: Array = footstep_frames.get(animated_sprite.animation, [])
	if not planted.has(animated_sprite.frame) or not is_on_floor() or absf(velocity.x) < 5.0:
		return
	Sfx.play("footstep", global_position, -9.0 if animated_sprite.animation == &"run" else -6.0, 0.12)
	footstep.emit(global_position)
	if walk_dust:
		walk_dust.direction.x = 1.0 if animated_sprite.flip_h else -1.0
		walk_dust.restart()


func update_animation(delta: float) -> void:
	var current := animated_sprite.animation
	var desired: StringName

	if not is_on_floor():
		if velocity.y < -60.0:
			desired = &"jump"
		elif velocity.y < 60.0:
			desired = &"apex"
		else:
			desired = &"fall"
		# Let the rise pose finish before the apex so short hops don't skip it
		if current == &"jump" and desired == &"apex" and animated_sprite.is_playing():
			return
		play_anim(desired)
		return

	var moving := absf(velocity.x) >= 5.0
	if moving:
		step_commit_time = STEP_COMMIT_DURATION
	elif step_commit_time > 0.0:
		step_commit_time = maxf(step_commit_time - delta, 0.0)

	if charging_jump and charge_time >= CHARGE_START_TIME:
		desired = &"JumpCharge"
	elif not moving and step_commit_time <= 0.0:
		# Out of a stride, a quick recovery pose settles her before idling
		desired = &"run_stop" if (current == &"run" or current == &"sprint") else &"idle"
		if current == &"run_stop":
			desired = &"run_stop" if animated_sprite.is_playing() else &"idle"
	elif not moving:
		# Tail end of a tap: let whichever stride was already playing finish out
		desired = current if (current == &"run" or current == &"sprint") else &"run"
	elif is_sprinting:
		desired = &"sprint"
	else:
		desired = &"run"

	# Recoveries are short bridges: into the charge pose, out of a landing or a
	# stop. Moving again cuts a landing or stop short, so control never lags.
	if RECOVERY_ANIMS.has(current) and animated_sprite.is_playing():
		if current == &"crouch" or not moving:
			return
	if desired == &"JumpCharge" and current != &"JumpCharge" and current != &"crouch":
		play_anim(&"crouch", true)
		return

	# Keep the stride in step when switching between run and sprint
	if (current == &"run" and desired == &"sprint") or (current == &"sprint" and desired == &"run"):
		var progress := float(animated_sprite.frame) / animated_sprite.sprite_frames.get_frame_count(current)
		play_anim(desired)
		animated_sprite.frame = int(progress * animated_sprite.sprite_frames.get_frame_count(desired))
		match_stride_to_speed()
		return

	play_anim(desired)
	match_stride_to_speed()


# Both cycles are authored to cover about the same ground per loop at their
# base speed, so scaling by velocity keeps the feet from sliding.
func match_stride_to_speed() -> void:
	var anim := animated_sprite.animation
	if anim == &"run":
		var ref_speed := maxf(absf(velocity.x), SPEED * MIN_ANIM_SPEED_RATIO)
		animated_sprite.speed_scale = clampf(ref_speed / SPEED, 0.3, 2.0)
	elif anim == &"sprint":
		var ref_speed := maxf(absf(velocity.x), SPRINT_SPEED * MIN_ANIM_SPEED_RATIO)
		animated_sprite.speed_scale = clampf(ref_speed / SPRINT_SPEED, 0.3, 2.0)


func play_anim(anim: StringName, restart := false) -> void:
	if animated_sprite.animation == anim and not restart:
		if not animated_sprite.is_playing() and animated_sprite.sprite_frames.get_animation_loop(anim):
			animated_sprite.play(anim)
		return
	animated_sprite.speed_scale = 1.0
	animated_sprite.play(anim)
	animated_sprite.frame = 0
	animated_sprite.offset = sprite_offset


func update_effects(delta: float) -> void:
	var wind_strength := 0.0
	if charging_jump:
		if charge_time >= CHARGE_START_TIME:
			var charge_percent := minf(
				(charge_time - CHARGE_START_TIME) / (MAX_CHARGE_TIME - CHARGE_START_TIME), 1.0)
			wind_strength = 0.35 + 0.65 * charge_percent
		else:
			# A faint stir while holding, so the build-up starts before the pose changes
			wind_strength = clampf((charge_time - 0.4) / (CHARGE_START_TIME - 0.4), 0.0, 1.0) * 0.35
	for wind in wind_layers:
		if charging_jump:
			wind.strength = wind_strength
		elif wind.strength > 0.0:
			wind.release()
	_update_charge_wisps()
	_update_contact_shadow()

	var sprinting_on_ground := is_sprinting and is_on_floor()
	sprint_dust.emitting = sprinting_on_ground
	sprint_dust.direction.x = 1.0 if animated_sprite.flip_h else -1.0

	if is_sprinting and absf(velocity.x) > SPEED:
		afterimage_timer -= delta
		if afterimage_timer <= 0.0:
			afterimage_timer = AFTERIMAGE_INTERVAL
			spawn_afterimage()
	else:
		afterimage_timer = 0.0


## 0 when not in the charge pose, then 0-1 over the charge.
func charge_amount() -> float:
	if not charging_jump or charge_time < CHARGE_START_TIME:
		return 0.0
	return minf((charge_time - CHARGE_START_TIME) / (MAX_CHARGE_TIME - CHARGE_START_TIME), 1.0)


# The electric wisps of the hold-jump art ride on the charge pose, frame for
# frame, and brighten (with their light and sparks) as the charge builds.
func _update_charge_wisps() -> void:
	if charge_wisps == null:
		return
	var active := animated_sprite.animation == &"JumpCharge" and charging_jump and not is_dead
	charge_wisps.visible = active
	if active:
		charge_wisps.frame = animated_sprite.frame
		charge_wisps.flip_h = animated_sprite.flip_h
		charge_wisps.position = animated_sprite.position
		charge_wisps.scale = animated_sprite.scale
		charge_wisps.offset = animated_sprite.offset
	var amount := 0.35 + 0.65 * charge_amount() if active else 0.0
	(charge_wisps.material as ShaderMaterial).set_shader_parameter("charge", amount)
	if wisp_light:
		wisp_light.energy = move_toward(wisp_light.energy, amount * 1.1, 0.12)
	if wisp_sparks:
		wisp_sparks.emitting = active and charge_amount() >= 1.0


# A soft shadow under her feet, fading as she leaves the ground
func _update_contact_shadow() -> void:
	if contact_shadow == null:
		return
	var grounded := 1.0 if is_on_floor() else clampf(1.0 - air_time * 4.0, 0.0, 1.0)
	contact_shadow.modulate.a = move_toward(contact_shadow.modulate.a, 0.5 * grounded, 0.1)


func spawn_afterimage() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = animated_sprite.sprite_frames.get_frame_texture(
		animated_sprite.animation, animated_sprite.frame)
	ghost.flip_h = animated_sprite.flip_h
	ghost.offset = animated_sprite.offset
	ghost.modulate = Color(0.65, 0.45, 1.0, 0.45)
	ghost.z_index = -1
	get_parent().add_child(ghost)
	ghost.global_scale = animated_sprite.global_scale
	ghost.global_position = animated_sprite.global_position
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ghost.queue_free)


func squash(amount: Vector2) -> void:
	if squash_tween:
		squash_tween.kill()
	_apply_squash(amount)
	squash_tween = create_tween()
	squash_tween.tween_method(_apply_squash, amount, Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# The sprite node sits at her feet (bottom-centre pivot), so scaling it
# squashes around the feet and she never hovers or sinks
func _apply_squash(amount: Vector2) -> void:
	animated_sprite.scale = sprite_base_scale * amount
	animated_sprite.position = sprite_base_pos

func start_reload():
	if is_reloading:
		return

	if current_mana >= get_mana_cap():
		return

	is_reloading = true
	reload_progress = 0.0

	update_mana_ui()

func update_mana_ui():
	var percent := 0.0
	if is_reloading:
		percent = reload_progress / RELOAD_TIME

	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.set_mana(current_mana, MAX_MANA, is_reloading, percent)
		if hud.has_method("set_mana_debt"):
			hud.set_mana_debt(mana_debt)

	var mana_ui = get_tree().get_first_node_in_group("ammo_ui")
	if mana_ui:
		mana_ui.update_display(current_mana, is_reloading)

func flash_spell(spell: String) -> void:
	var mana_ui = get_tree().get_first_node_in_group("ammo_ui")
	if mana_ui:
		mana_ui.flash_spell(spell)


func heal_player():

	if is_reloading:
		return

	if current_health >= MAX_HEALTH:
		return

	if current_mana < HEAL_COST:
		return

	current_mana -= HEAL_COST

	current_health = clampi(
		current_health + 2,
		0,
		MAX_HEALTH
	)

	update_health_ui()
	update_mana_ui()
	flash_spell("heal")

	var tween = create_tween()

	tween.tween_property(
		animated_sprite,
		"modulate",
		Color(0.4, 0.8, 1.0, 0.8),
		0.15
	)

	tween.tween_property(
		animated_sprite,
		"modulate",
		Color.WHITE,
		0.15
	)

	if current_mana <= 0:
		start_reload()
