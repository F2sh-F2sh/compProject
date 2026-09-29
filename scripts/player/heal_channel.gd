class_name HealChannel
extends Node2D

## Healing is a short channel, not an instant top-up. Echidna stands still
## while a ring of water-light fills above her; only when it completes is the
## mana spent and the health restored. Moving, jumping, casting or being hurt
## breaks it (nothing is spent), and it can't begin for a moment after a hit,
## so a hazard can't be walked through and healed off on the spot.

const CHANNEL_TIME := 1.2
## Seconds after taking damage before a heal can begin.
const HIT_LOCKOUT := 3.0
const RING_COLOR := Color(0.45, 0.82, 1.0)
const CHARGE_SOUND := preload("res://assets/audio/sfx/heal_charge.wav")

var is_channeling := false
## 0..1 while channeling.
var progress := 0.0

var _since_hit := 99.0
var _was_channeling := false
var _refused := 0.0
var _sparkles: CPUParticles2D
var _voice: AudioStreamPlayer2D

@onready var player: CharacterBody2D = get_parent()


func _ready() -> void:
	name = "HealChannel"
	z_index = 5
	material = MagicLight.unshaded()
	position = Vector2(0, -20)
	_sparkles = CPUParticles2D.new()
	_sparkles.emitting = false
	_sparkles.amount = 14
	_sparkles.lifetime = 0.7
	_sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_sparkles.emission_rect_extents = Vector2(10, 14)
	_sparkles.direction = Vector2.UP
	_sparkles.spread = 25.0
	_sparkles.gravity = Vector2(0, -30)
	_sparkles.initial_velocity_min = 8.0
	_sparkles.initial_velocity_max = 22.0
	_sparkles.scale_amount_min = 1.0
	_sparkles.scale_amount_max = 2.0
	_sparkles.color = Color(RING_COLOR, 0.85)
	_sparkles.use_parent_material = true
	add_child(_sparkles)
	_voice = AudioStreamPlayer2D.new()
	_voice.stream = CHARGE_SOUND
	_voice.bus = Settings.SFX_BUS
	_voice.volume_db = -6.0
	add_child(_voice)


## Starts healing if she can; otherwise a short refusal cue. Returns true if
## the channel began.
func try_start() -> bool:
	if is_channeling:
		return false
	if player.current_health >= player.MAX_HEALTH:
		return false
	var blocked: bool = player.is_reloading or player.current_mana < player.HEAL_COST \
		or _since_hit < HIT_LOCKOUT or not player.is_on_floor() \
		or absf(Input.get_axis("move_left", "move_right")) > 0.0
	if blocked:
		_refuse()
		return false
	is_channeling = true
	progress = 0.0
	_sparkles.emitting = true
	_voice.play()
	return true


## Breaks the channel without spending anything.
func cancel() -> void:
	if not is_channeling:
		return
	is_channeling = false
	progress = 0.0
	_sparkles.emitting = false
	_voice.stop()
	Sfx.play("heal_cancel", player.global_position, -4.0)
	queue_redraw()


## Called by the player whenever damage lands.
func on_hurt() -> void:
	_since_hit = 0.0
	cancel()


func _physics_process(delta: float) -> void:
	_since_hit += delta
	_refused = maxf(_refused - delta, 0.0)
	if is_channeling:
		var broken: bool = player.is_dead or player.controls_locked or not player.is_on_floor() \
			or absf(Input.get_axis("move_left", "move_right")) > 0.0 \
			or Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("shoot") \
			or player.charging_jump
		if broken:
			cancel()
		else:
			progress = minf(progress + delta / CHANNEL_TIME, 1.0)
			if progress >= 1.0:
				_finish()
	if is_channeling or _refused > 0.0:
		queue_redraw()
	if is_channeling != _was_channeling:
		_was_channeling = is_channeling
		if not is_channeling:
			_show_slot(0.0)
	if is_channeling:
		_show_slot(progress)


func _show_slot(p: float) -> void:
	var slots := get_tree().get_first_node_in_group("ammo_ui")
	if slots and slots.has_method("set_heal_progress"):
		slots.set_heal_progress(p)


func _finish() -> void:
	is_channeling = false
	progress = 0.0
	_sparkles.emitting = false
	player.complete_heal()
	var burst := CPUParticles2D.new()
	burst.one_shot = true
	burst.explosiveness = 0.9
	burst.amount = 18
	burst.lifetime = 0.6
	burst.spread = 180.0
	burst.gravity = Vector2(0, -20)
	burst.initial_velocity_min = 20.0
	burst.initial_velocity_max = 45.0
	burst.scale_amount_min = 1.0
	burst.scale_amount_max = 2.5
	burst.color = Color(RING_COLOR, 0.9)
	burst.use_parent_material = true
	add_child(burst)
	burst.emitting = true
	burst.finished.connect(burst.queue_free)
	queue_redraw()


func _refuse() -> void:
	_refused = 0.35
	Sfx.play("heal_cancel", player.global_position, -8.0)
	queue_redraw()


func _draw() -> void:
	# Above the brim of her hat
	var center := Vector2(0, -44)
	if is_channeling:
		var p := progress
		draw_arc(center, 11.0, 0.0, TAU, 32, Color(RING_COLOR, 0.18), 2.0)
		draw_arc(center, 11.0, -PI / 2.0, -PI / 2.0 + TAU * p, 32, Color(RING_COLOR, 0.9), 2.0)
		draw_circle(center, 3.0 + 2.0 * p, Color(RING_COLOR, 0.25 + 0.5 * p))
	elif _refused > 0.0:
		draw_arc(center, 11.0, 0.0, TAU, 32, Color(0.6, 0.6, 0.7, _refused * 1.6), 2.0)
