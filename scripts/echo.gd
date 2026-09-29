class_name Echo
extends Node2D

## A ghost that replays a recording of the player. It is purely position
## driven, so it follows the recording exactly and can never drift. It can
## hold pressure plates (via its Presser area) and re-cast recorded fireballs,
## but hazards and enemies cannot hurt it.

@export var materialize_time := 0.45
@export var dissolve_time := 0.5

var frames: Array[Dictionary] = []
var events := {}
var loop := false
var index := 0
var caster: Node

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var glow: PointLight2D = $Glow
@onready var motes: CPUParticles2D = $Motes
@onready var presser: Area2D = $Presser

var _material: ShaderMaterial
var _dissolving := false


func _ready() -> void:
	add_to_group("echo")
	presser.add_to_group("echo_presser")


func setup(recorded_frames: Array[Dictionary], recorded_events: Dictionary, sprite_frames: SpriteFrames,
		owner_player: Node, loop_playback: bool) -> void:
	frames = recorded_frames
	events = recorded_events
	caster = owner_player
	loop = loop_playback
	sprite.sprite_frames = sprite_frames
	sprite.speed_scale = 0.0
	# Each Echo gets its own material so reveal/dissolve don't affect others
	_material = (sprite.material as ShaderMaterial).duplicate()
	sprite.material = _material
	_apply(0)

	_material.set_shader_parameter("materialize", 0.0)
	var energy := glow.energy
	glow.energy = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_method(func(v): _material.set_shader_parameter("materialize", v), 0.0, 1.0, materialize_time)
	tween.tween_property(glow, "energy", energy, materialize_time)
	motes.emitting = true


func is_finished() -> bool:
	return index >= frames.size() - 1 and not loop


func dissolve() -> void:
	if _dissolving:
		return
	_dissolving = true
	presser.set_deferred("monitorable", false)
	var tween := create_tween().set_parallel()
	tween.tween_method(func(v): _material.set_shader_parameter("materialize", v), 1.0, 0.0, dissolve_time)
	tween.tween_property(glow, "energy", 0.0, dissolve_time)
	tween.chain().tween_callback(queue_free)


func _physics_process(_delta: float) -> void:
	if frames.is_empty() or _dissolving:
		return
	if index < frames.size() - 1:
		index += 1
		_apply(index)
		_fire_events(index)
	elif loop:
		index = 0
		_apply(0)


func _apply(i: int) -> void:
	var f: Dictionary = frames[i]
	global_position = f["position"]
	if sprite.animation != f["animation"]:
		sprite.animation = f["animation"]
	sprite.frame = f["frame"]
	sprite.flip_h = f["flip_h"]
	sprite.offset = f["offset"]
	sprite.position = f["sprite_position"]
	sprite.scale = f["sprite_scale"]


func _fire_events(i: int) -> void:
	if not events.has(i) or not is_instance_valid(caster):
		return
	for event in events[i]:
		caster.spawn_fireball(event["spawn"], event["direction"])
