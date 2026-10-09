extends CharacterBody2D

## Emitted whenever a fireball is launched, so an Echo recording can replay it.
signal fireball_cast(spawn_position: Vector2, direction: Vector2)
## Emitted when a foot plants during a walk or sprint (sound and dust follow).
signal footstep(at: Vector2)
signal died
## Emitted when she uses something (a lever, a rope), so an Echo can repeat it.
signal interaction_performed(target: Node)
## She tried a spell she has not remembered yet: "fire", "heal" or "echo".
signal ability_denied(id: String)

@export var fireball_scene: PackedScene
@export var hurtbox: Hurtbox


const MAX_MANA := 100
## Echoes can drain max mana, but never below this.
const MIN_MANA_CAP := 20
var mana_debt := 0
const FIREBALL_COST := 5
const HEAL_COST := 20
var current_mana := MAX_MANA
## Kindling the lantern at a lit flame (hold the kindle key, R) takes this long.
const RELOAD_TIME := 1.5
const KINDLE_RANGE := 70.0
var is_reloading := false
var reload_progress := 0.0
## Set by the RuneManager while runes she powers are drawing upkeep.
var reload_locked := false

const SPEED = 115.0
const SPRINT_SPEED = 220.0
const FRICTION = 1200.0

const BASE_JUMP_VELOCITY = -350.0
const MAX_JUMP_VELOCITY = -500.0

## The charged jump gathers power from the moment crouch is pressed (no wait)
## and is full after MAX_CHARGE_TIME.
const CHARGE_START_TIME = 0.0
const MAX_CHARGE_TIME = 1.5
const JUMP_BUFFER_DURATION = 0.15
## A jump pressed just after running off a ledge still counts.
const COYOTE_DURATION = 0.1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprint_dust: CPUParticles2D = $SprintDust
@onready var land_dust: CPUParticles2D = $LandDust
@onready var hazard_recovery: HazardRecovery = get_node_or_null("HazardRecovery")
# Built by tools/setup_echidna_player.gd
@onready var wisp_light: PointLight2D = get_node_or_null("WispLight")
@onready var wisp_sparks: CPUParticles2D = get_node_or_null("WispSparks")
@onready var walk_dust: CPUParticles2D = get_node_or_null("WalkDust")
@onready var contact_shadow: Sprite2D = get_node_or_null("ContactShadow")
var heal_channel: HealChannel
var _aim_marker: Node2D
var _crouch_toggled := false
var _last_denied := -1000

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
## Tests only: aim here instead of at the mouse (the OS cursor belongs to
## whoever is using the computer). null in play.
var aim_override: Variant = null
var jumped := false
var jump_buffer_time := 0.0
var coyote_time := 0.0
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
const STEP_SOUND_MIN_SPEED := 40.0
var _plants_heard := 0
var _last_step_variant := 0
var _moving_time := 0.0

func _ready() -> void:
	add_to_group("player")
	sprite_base_scale = animated_sprite.scale
	sprite_base_pos = animated_sprite.position
	var frames := animated_sprite.sprite_frames
	sprite_offset = frames.get_meta(&"sprite_offset", DEFAULT_SPRITE_OFFSET)
	footstep_frames = frames.get_meta(&"footsteps", {})
	animated_sprite.offset = sprite_offset
	animated_sprite.frame_changed.connect(_on_sprite_frame_changed)
	heal_channel = HealChannel.new()
	add_child(heal_channel)
	Crosshair.aim(true)
	# With a controller, a small chevron shows where a fireball would go
	_aim_marker = Node2D.new()
	_aim_marker.material = MagicLight.unshaded()
	_aim_marker.z_index = 5
	_aim_marker.visible = false
	_aim_marker.draw.connect(func():
		var c := Color(1.0, 0.7, 0.4, 0.85)
		_aim_marker.draw_polyline(PackedVector2Array([Vector2(-4, -5), Vector2(3, 0), Vector2(-4, 5)]), c, 1.5))
	add_child(_aim_marker)
	# While she charges a jump: a light breeze at her feet, and a small bar
	# over her head that fills and turns gold when the jump is at full power
	add_child(preload("res://scripts/fx/charge_breeze.gd").new())
	add_child(preload("res://scripts/fx/charge_bar.gd").new())
	# "[R] Kindle" over the flames that refill her mana (not wall torches)
	var kindle_prompt := KindlePrompt.new()
	kindle_prompt.name = "KindlePrompt"
	kindle_prompt.player = self
	add_child(kindle_prompt)

	if hurtbox:
		hurtbox.damage_received.connect(take_damage)

	update_health_ui.call_deferred()
	update_mana_ui.call_deferred()

## A spell she has not remembered yet: a faint sputter (so the key is not
## silent), and a signal for any scene that wants to react to it.
func deny_ability(id: String) -> void:
	if Time.get_ticks_msec() - _last_denied > 600:
		_last_denied = Time.get_ticks_msec()
		Sfx.play("fizzle", global_position, -8.0)
		ImpactFX.burst(get_parent(), global_position + Vector2(0, -18), Color(0.5, 0.48, 0.65), false, 3)
	ability_denied.emit(id)


func shoot_fireball() -> void:
	if fireball_scene == null:
		return
	if not GameState.has_ability("fire"):
		deny_ability("fire")
		return
	if current_mana < FIREBALL_COST or is_reloading:
		# A spell with nothing behind it: a sputter, not silence
		Sfx.play("fizzle", global_position, -4.0)
		ImpactFX.burst(get_parent(), global_position + Vector2(0, -14), Color(0.55, 0.5, 0.7), false, 4)
		return

	# Spawn from the player's torso
	var origin_point = global_position + Vector2(0, -12)
	var dir := aim_direction(origin_point)

	# With the mouse it spawns at the cursor if that is close, otherwise up to
	# 50 px toward it; with a controller, just in front of her
	var spawn_distance := 24.0
	if not InputLabels.use_pad:
		spawn_distance = minf(origin_point.distance_to(_mouse_point()), 50.0)

	var spawn_position: Vector2 = _clear_spawn_point(origin_point, origin_point + dir * spawn_distance)
	spawn_fireball(spawn_position, dir)
	fireball_cast.emit(spawn_position, dir)
	Sfx.play("spell_cast", origin_point, -3.0, 0.08)
	# She turns to face the shot, with a small recoil and a flash at her hand
	if absf(dir.x) > 0.1:
		animated_sprite.flip_h = dir.x < 0.0
	squash(Vector2(1.08, 0.94))
	ImpactFX.burst(get_parent(), spawn_position, Color(1.0, 0.6, 0.3), false, 5)

	current_mana -= FIREBALL_COST
	update_mana_ui()
	flash_spell("fireball")
	if current_mana <= 0:
		hint_kindle()


## Which way a fireball from `origin` would fly: toward the mouse, or with a
## controller along the right stick (straight ahead if it's at rest), gently
## pulled toward a creature or target close to that line.
func aim_direction(origin: Vector2) -> Vector2:
	if not InputLabels.use_pad:
		return (_mouse_point() - origin).normalized()
	var stick := Vector2.ZERO
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		stick = Vector2(Input.get_joy_axis(pads[0], JOY_AXIS_RIGHT_X), Input.get_joy_axis(pads[0], JOY_AXIS_RIGHT_Y))
	var dir := stick.normalized() if stick.length() > 0.3 else Vector2(-1.0 if animated_sprite.flip_h else 1.0, 0.0)
	return _aim_assist(origin, dir)


const AIM_ASSIST_ANGLE := 0.35
const AIM_ASSIST_RANGE := 380.0


func _aim_assist(origin: Vector2, dir: Vector2) -> Vector2:
	var best := dir
	var best_angle := AIM_ASSIST_ANGLE
	for target in get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("aim_target"):
		if not target is Node2D or not target.is_visible_in_tree():
			continue
		var point: Vector2 = target.global_position + (Vector2(0, -8) if target.is_in_group("enemy") else Vector2.ZERO)
		var to := point - origin
		if to.length() > AIM_ASSIST_RANGE or to.length() < 1.0:
			continue
		var angle := absf(dir.angle_to(to))
		if angle < best_angle and MagicLight.line_is_clear(get_world_2d(), origin, point, [get_rid()]):
			best_angle = angle
			best = to.normalized()
	return best


# A fireball never starts on the far side of a floor, grate or wall (aiming
# down from a grate must not drop it into the cell below)
func _clear_spawn_point(from: Vector2, to: Vector2) -> Vector2:
	var query := PhysicsRayQueryParameters2D.create(from, to, 2, [get_rid()])
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return to
	return hit["position"] - (to - from).normalized() * 6.0


## Launches a fireball without any mana cost; also used by Echo replays.
func spawn_fireball(spawn_position: Vector2, direction: Vector2) -> Node2D:
	var fireball: Node2D = fireball_scene.instantiate()
	fireball.global_position = spawn_position
	fireball.direction = direction
	get_tree().current_scene.add_child(fireball)
	return fireball


func record_interaction(target: Node) -> void:
	interaction_performed.emit(target)


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

	# The damage assist softens every hit (never below 1)
	if Settings.assist_damage < 1.0:
		amount = maxi(ceili(amount * Settings.assist_damage), 1)
	current_health = clampi(current_health - amount, 0, MAX_HEALTH)
	update_health_ui()
	if heal_channel:
		heal_channel.on_hurt()

	# Lethal damage always wins over any hazard reset or knockback
	if current_health <= 0:
		Sfx.play("player_hurt", global_position)
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
	coyote_time = 0.0
	jumped = false
	knockback_time = 0.0
	is_sprinting = false
	step_commit_time = 0.0
	afterimage_timer = 0.0


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
	died.emit()
	velocity = Vector2.ZERO
	charging_jump = false
	sprint_dust.emitting = false
	if wisp_sparks:
		wisp_sparks.emitting = false
	animated_sprite.self_modulate.a = 1.0
	if hazard_recovery:
		hazard_recovery.abort()
	set_physics_process(false)
	Sfx.play("player_death", global_position)
	Sfx.play("death_fall", global_position, -2.0, 0.0)
	_dissolve()

	var death_screen = get_tree().get_first_node_in_group("death_screen")
	if death_screen == null:
		death_screen = get_tree().current_scene.get_node_or_null("DeathUI/DeathScreen")

	if death_screen:
		death_screen.show_death_screen()


# She sinks and comes apart into violet motes (it plays on while the death
# screen holds the rest of the world still)
func _dissolve() -> void:
	var motes := CPUParticles2D.new()
	motes.process_mode = Node.PROCESS_MODE_ALWAYS
	motes.one_shot = true
	motes.explosiveness = 0.35
	motes.amount = 28
	motes.lifetime = 1.3
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(9, 16)
	motes.position = Vector2(0, -18)
	motes.direction = Vector2.UP
	motes.spread = 35.0
	motes.gravity = Vector2(0, -40)
	motes.initial_velocity_min = 10.0
	motes.initial_velocity_max = 35.0
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 2.5
	motes.color = Color(0.75, 0.55, 1.0, 0.9)
	motes.material = MagicLight.unshaded()
	add_child(motes)
	motes.emitting = true
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	tween.tween_property(animated_sprite, "self_modulate:a", 0.0, 1.1).set_delay(0.15)
	tween.tween_property(animated_sprite, "scale", sprite_base_scale * Vector2(1.15, 0.55), 1.1).set_delay(0.15)


func _physics_process(delta: float) -> void:
	if invulnerable_time > 0.0:
		invulnerable_time = maxf(invulnerable_time - delta, 0.0)
	_update_invulnerability_blink()

	if controls_locked:
		_locked_physics(delta)
		return

	if Settings.assist_infinite_mana and current_mana < get_mana_cap() and not is_reloading:
		current_mana = get_mana_cap()
		update_mana_ui()
	Crosshair.aim(current_mana >= FIREBALL_COST and not is_reloading and GameState.has_ability("fire"))

	if Input.is_action_just_pressed("heal"):
		heal_player()
		
	# Kindling lasts only while the key is held and she stays at the flame
	if is_reloading and (not Input.is_action_pressed("reload") or not (Settings.assist_infinite_mana or near_kindle())):
		is_reloading = false
		reload_progress = 0.0
		update_mana_ui()

	if is_reloading:
		reload_progress += delta
		update_mana_ui()

		if reload_progress >= RELOAD_TIME:

			current_mana = get_mana_cap()
			is_reloading = false
			reload_progress = 0.0
			Sfx.play("reload_done", global_position, -5.0)

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
	elif jump_buffer_time > 0:
		jump_buffer_time -= delta


	# -------------------------
	# GRAVITY
	# -------------------------

	if not is_on_floor():
		velocity += get_gravity() * delta
		air_time += delta
		coyote_time = maxf(coyote_time - delta, 0.0)
	else:
		air_time = 0.0
		jumped = false
		coyote_time = COYOTE_DURATION


	# -------------------------
	# JUMP: instant on press; holding crouch first charges a higher one
	# -------------------------

	_update_charge(delta)
	if jump_buffer_time > 0.0 and not jumped and (is_on_floor() or coyote_time > 0.0):
		_launch_jump()


	# -------------------------
	# MOVEMENT
	# -------------------------

	var direction := Input.get_axis("move_left", "move_right")

	# Sprint while holding SHIFT (or the reverse, with the always-sprint assist)
	var current_speed = SPEED
	var sprint_held := Input.is_action_pressed("sprint") != Settings.assist_auto_sprint

	if sprint_held:
		current_speed = SPRINT_SPEED

	is_sprinting = sprint_held and direction != 0.0 and not charging_jump


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

	elif charging_jump:

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


# Crouching (holding crouch on the ground) gathers the charged jump; letting
# go of crouch or leaving the ground drops it.
func _update_charge(delta: float) -> void:
	var crouch_held := Input.is_action_pressed("crouch")
	# With the toggle assist, one press crouches and the next (or a jump) stands
	if Settings.assist_toggle_crouch:
		if Input.is_action_just_pressed("crouch"):
			_crouch_toggled = not _crouch_toggled
		if not is_on_floor():
			_crouch_toggled = false
		crouch_held = _crouch_toggled
	if charging_jump:
		if not is_on_floor() or not crouch_held:
			_cancel_charge()
			return
		charge_time += delta
	elif crouch_held and is_on_floor():
		charging_jump = true
		charge_time = 0.0


func _cancel_charge() -> void:
	charging_jump = false
	charge_time = 0.0


func _launch_jump() -> void:
	var jump_velocity := BASE_JUMP_VELOCITY
	if charging_jump and charge_time > CHARGE_START_TIME:
		var charge_percent := minf(
			(charge_time - CHARGE_START_TIME) / (MAX_CHARGE_TIME - CHARGE_START_TIME), 1.0)
		jump_velocity = lerpf(BASE_JUMP_VELOCITY, MAX_JUMP_VELOCITY, charge_percent)
	charging_jump = false
	jump_buffer_time = 0.0
	coyote_time = 0.0
	velocity.y = jump_velocity
	jumped = true
	play_anim(&"jump", true)
	squash(Vector2(0.85, 1.18))
	Sfx.play("jump", global_position, -6.0, 0.06)


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


# Footfalls happen on the frames where a foot plants. Only every second plant
# is heard (a natural walking and running cadence), never on a tap or while
# slowing, from a pool of soft variants that never repeats back to back,
# on the dry Foley bus so steps don't trail the room's echo.
func _on_sprite_frame_changed() -> void:
	var planted: Array = footstep_frames.get(animated_sprite.animation, [])
	if not planted.has(animated_sprite.frame) or not is_on_floor() or absf(velocity.x) < 5.0:
		return
	footstep.emit(global_position)
	var sprinting := animated_sprite.animation == &"sprint"
	if walk_dust and sprinting:
		walk_dust.direction.x = 1.0 if animated_sprite.flip_h else -1.0
		walk_dust.restart()
	# (A stride clip restarting counts as a plant; that isn't a real step yet)
	if absf(velocity.x) < STEP_SOUND_MIN_SPEED or _moving_time < 0.1:
		return
	_plants_heard += 1
	if _plants_heard % 2 == 0:
		return
	var on_grate := _standing_on_group(&"iron_grate")
	# each level's floor has its own steps (LevelTheme sets "footstep")
	var scene := get_tree().current_scene
	var floor_kind := "grate" if on_grate else (String(scene.get_meta(&"footstep", "stone")) if scene else "stone")
	var count: int = {"grate": 2, "stone": 4}.get(floor_kind, 3)
	var variant := randi_range(1, count)
	if variant == _last_step_variant:
		variant = variant % count + 1
	_last_step_variant = variant
	var sound := "step_%s_%d" % [floor_kind, variant]
	var volume := (-12.0 if sprinting else -15.0) + randf_range(-2.0, 2.0)
	Sfx.play(sound, global_position, volume, 0.06, true)


func _standing_on_group(group_name: StringName) -> bool:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider() as Node
		if collision.get_normal().y < -0.7 and collider and collider.is_in_group(group_name):
			return true
	return false


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

	if charging_jump:
		# The charge sheet is her crouch
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
	_update_charge_glow()
	_update_contact_shadow()
	if _aim_marker:
		_aim_marker.visible = InputLabels.use_pad and not is_dead and not controls_locked
		if _aim_marker.visible:
			var dir := aim_direction(global_position + Vector2(0, -12))
			_aim_marker.position = Vector2(0, -12) + dir * 30.0
			_aim_marker.rotation = dir.angle()

	# The first real step after starting to move is always heard
	if absf(velocity.x) < 5.0 or not is_on_floor():
		_plants_heard = 0
		_moving_time = 0.0
	else:
		_moving_time += delta

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


# A soft glow gathers around her as the charge builds (no lines or streaks),
# and a few sparks show it is full.
func _update_charge_glow() -> void:
	var active := animated_sprite.animation == &"JumpCharge" and charging_jump \
		and charge_time >= CHARGE_START_TIME and not is_dead
	var amount := 0.35 + 0.65 * charge_amount() if active else 0.0
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

## Whether she stands at a lit flame that can refill her (a shrine, a lit
## brazier, a candle, the Kept Flame): nodes in the group "kindle_point" with
## is_kindling().
func near_kindle() -> bool:
	for point in get_tree().get_nodes_in_group("kindle_point"):
		if point is Node2D and point.has_method("is_kindling") and point.is_kindling() \
				and absf(point.global_position.x - global_position.x) < KINDLE_RANGE \
				and absf(point.global_position.y - global_position.y) < 90.0:
			return true
	return false


## The nearest lit flame she can kindle at, within `max_dist` (null if none).
func nearest_kindle(max_dist := INF) -> Node2D:
	var best: Node2D = null
	var best_d := max_dist
	for point in get_tree().get_nodes_in_group("kindle_point"):
		if point is Node2D and point.has_method("is_kindling") and point.is_kindling():
			var d := (point as Node2D).global_position.distance_to(global_position)
			if d < best_d:
				best_d = d
				best = point
	return best


var _last_kindle_hint := -10000


## Tells her which flames refill her mana and which way the nearest one is
## (not more than once in a while).
func hint_kindle() -> void:
	if Settings.assist_infinite_mana or Time.get_ticks_msec() - _last_kindle_hint < 4000:
		return
	_last_kindle_hint = Time.get_ticks_msec()
	var text := "No flame to kindle at here.\nHold %s beside a flame bowl, a shrine, a candle\nor a lit brazier. Wall torches won't do." % InputLabels.primary("reload")
	var nearest := nearest_kindle()
	if nearest:
		text += "\nThe nearest is to your %s." % ("right" if nearest.global_position.x > global_position.x else "left")
	FloatText.spawn(get_parent(), global_position + Vector2(0, -60), text, Color(0.72, 0.9, 1.0), 20.0, 3.6)


func start_reload():
	if is_reloading:
		return
	# Runes she is powering draw on this same mana; no refilling under them
	if reload_locked:
		Sfx.play("fizzle", global_position, -8.0)
		FloatText.spawn(get_parent(), global_position + Vector2(0, -52), "Runes are drawing your mana", Color(0.72, 0.9, 1.0))
		return

	if current_mana >= get_mana_cap():
		return
	# Mana is the lantern's flame: it only comes back at a lit flame
	if not Settings.assist_infinite_mana and not near_kindle():
		hint_kindle()
		return

	is_reloading = true
	reload_progress = 0.0
	Sfx.play("reload_start", global_position, -6.0)

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


## Healing is channelled (see scripts/player/heal_channel.gd); the mana and
## health change only when the channel completes, in complete_heal().
func heal_player():
	if not GameState.has_ability("heal"):
		deny_ability("heal")
		return
	if heal_channel:
		heal_channel.try_start()
	else:
		complete_heal()


func complete_heal():

	if is_reloading:
		return

	if current_health >= MAX_HEALTH:
		return

	if current_mana < HEAL_COST:
		return

	Sfx.play("heal_done", global_position, -3.0)
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
		hint_kindle()




## Where the mouse aims, in the world (or the tests' aim_override).
func _mouse_point() -> Vector2:
	return aim_override if aim_override is Vector2 else get_global_mouse_position()
