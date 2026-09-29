class_name EchoRecorder
extends Node

## Records the player's movement and spells so an Echo can replay them.
## Press the echo action to start recording and again to stop; the Echo then
## replays the recording from where it began. Every living Echo costs some
## maximum mana ("temporal debt") until it fades.

signal recording_started
signal recording_stopped
signal echoes_changed(count: int)

@export var echo_scene: PackedScene
@export var action := "echo"
@export var max_duration := 8.0
## Recordings shorter than this are discarded.
@export var min_duration := 0.25
@export var max_echoes := 2
@export var mana_debt_per_echo := 10
## When false, an Echo holds its final pose after replaying; when true it loops.
@export var loop_playback := false

var is_recording := false
var echoes: Array[Node] = []

var _frames: Array[Dictionary] = []
var _events := {}

@onready var player: CharacterBody2D = get_parent()


## Holding the echo key this long lets every Echo fade (and drops a
## recording just begun), returning the mana they hold.
const HOLD_TO_CLEAR := 0.6
## Echo tints, one per living Echo, so two of them can be told apart.
const TINTS := [Color(0.66, 0.42, 1.0), Color(0.35, 0.9, 0.85), Color(1.0, 0.78, 0.42)]

var _hold := 0.0
var _hold_used := false
var _last_tick := 0
var _told_replace := false


func _ready() -> void:
	player.fireball_cast.connect(_on_fireball_cast)
	if player.has_signal("interaction_performed"):
		player.interaction_performed.connect(_on_interaction)


func get_elapsed() -> float:
	return _frames.size() / float(Engine.physics_ticks_per_second)


func get_remaining_ratio() -> float:
	return 1.0 - clampf(get_elapsed() / max_duration, 0.0, 1.0)


func _physics_process(delta: float) -> void:
	if player.is_dead or player.controls_locked:
		if is_recording:
			cancel_recording()
			if not player.is_dead:
				_notice("Recording lost", Color(1.0, 0.55, 0.55))
		return

	if Input.is_action_just_pressed(action):
		_hold = 0.0
		_hold_used = false
		if is_recording:
			stop_recording()
		else:
			start_recording()
	elif Input.is_action_pressed(action) and not _hold_used:
		_hold += delta
		if _hold >= HOLD_TO_CLEAR:
			_hold_used = true
			if is_recording:
				cancel_recording()
			if not echoes.is_empty():
				clear_echoes()
				Sfx.play("echo_fade", player.global_position)
				_notice("Your Echoes fade", TINTS[0])

	if is_recording:
		_capture_frame()
		# A soft tick for each of the last three seconds
		var left := int(ceil(max_duration - get_elapsed()))
		if left <= 3 and left != _last_tick:
			_last_tick = left
			Sfx.play("echo_tick", null, -8.0 + (3 - left) * 2.0, 0.0)
		_update_hud()
		if get_elapsed() >= max_duration:
			stop_recording()


func start_recording() -> void:
	is_recording = true
	_last_tick = 0
	_frames.clear()
	_events.clear()
	_burst(Color(1.0, 0.3, 0.35))
	Sfx.play("echo_start", player.global_position)
	recording_started.emit()
	_update_hud()


func stop_recording() -> void:
	if not is_recording:
		return
	is_recording = false
	recording_stopped.emit()
	if get_elapsed() >= min_duration and echo_scene:
		_spawn_echo()
	_update_hud()


func cancel_recording() -> void:
	is_recording = false
	_frames.clear()
	_events.clear()
	recording_stopped.emit()
	_update_hud()


## Fades out every Echo and returns the mana they were holding.
func clear_echoes() -> void:
	for echo in echoes:
		if is_instance_valid(echo):
			echo.dissolve()
	echoes.clear()
	_refresh_debt()


func _capture_frame() -> void:
	var sprite: AnimatedSprite2D = player.animated_sprite
	_frames.append({
		"position": player.global_position,
		"animation": sprite.animation,
		"frame": sprite.frame,
		"flip_h": sprite.flip_h,
		"offset": sprite.offset,
		"sprite_position": sprite.position,
		"sprite_scale": sprite.scale,
	})


func _on_fireball_cast(spawn_position: Vector2, direction: Vector2) -> void:
	_add_event({"spawn": spawn_position, "direction": direction})


# Levers, ropes, mirror wheels: the Echo uses them again at the same moment
func _on_interaction(target: Node) -> void:
	_add_event({"interact": target})


func _add_event(event: Dictionary) -> void:
	if not is_recording:
		return
	var index := _frames.size()
	if not _events.has(index):
		_events[index] = []
	_events[index].append(event)


func _spawn_echo() -> void:
	var echo: Node2D = echo_scene.instantiate()
	player.get_parent().add_child(echo)
	echo.setup(_frames.duplicate(), _events.duplicate(true), player.animated_sprite.sprite_frames,
		player, loop_playback)
	Sfx.play("echo_spawn", echo.global_position)
	echoes.append(echo)
	while echoes.size() > max_echoes:
		var oldest: Node = echoes.pop_front()
		if is_instance_valid(oldest):
			oldest.dissolve()
			Sfx.play("echo_fade", oldest.global_position, -4.0)
			if not _told_replace:
				_told_replace = true
				_notice("Only %d Echoes at once: the oldest fades" % max_echoes, TINTS[0])
	# Each living Echo wears its own colour
	var used := echoes.filter(func(e): return is_instance_valid(e) and e != echo).map(func(e): return e.tint)
	for tint in TINTS:
		if not used.has(tint):
			echo.set_tint(tint)
			break
	_frames.clear()
	_events.clear()
	_refresh_debt()


func _refresh_debt() -> void:
	echoes = echoes.filter(func(e): return is_instance_valid(e))
	player.set_mana_debt(echoes.size() * mana_debt_per_echo)
	echoes_changed.emit(echoes.size())
	_update_hud()


func _update_hud() -> void:
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("set_echo_state"):
		hud.set_echo_state(is_recording, get_remaining_ratio(), echoes.size(), max_echoes,
			maxf(max_duration - get_elapsed(), 0.0))


func _notice(text: String, color: Color) -> void:
	FloatText.spawn(player.get_parent(), player.global_position + Vector2(0, -58), text, color, 22.0, 1.8)


func _process(_delta: float) -> void:
	if is_recording:
		_update_hud()


func _burst(color: Color) -> void:
	var ring := CPUParticles2D.new()
	ring.one_shot = true
	ring.explosiveness = 1.0
	ring.amount = 18
	ring.lifetime = 0.45
	ring.direction = Vector2.UP
	ring.spread = 180.0
	ring.gravity = Vector2.ZERO
	ring.initial_velocity_min = 50.0
	ring.initial_velocity_max = 80.0
	ring.damping_min = 80.0
	ring.damping_max = 120.0
	ring.scale_amount_min = 1.5
	ring.scale_amount_max = 2.5
	ring.color = color
	ring.position = Vector2(0, -20)
	player.add_child(ring)
	ring.emitting = true
	ring.finished.connect(ring.queue_free)
