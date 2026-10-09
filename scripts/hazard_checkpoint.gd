class_name HazardCheckpoint
extends Area2D

## A local recovery point for spike hazards. It only becomes usable once the
## player has walked through it, and only spikes that reference it use it.

signal activated

## Where the player is placed, relative to this node (which sits on the floor).
@export var respawn_offset := Vector2(0, -4)
## Tall trigger so the player can't jump over it without activating it.
@export var trigger_size := Vector2(40, 140)
@export var lit_glow_color := Color(0.4, 0.62, 1.0)
@export var lit_energy := 1.0
@export var unlit_candle_tint := Color(0.5, 0.5, 0.62)

var is_active := false

@onready var candle: Sprite2D = $Candle
@onready var flame: Sprite2D = $Flame
@onready var glow: PointLight2D = $Glow
@onready var sparks: CPUParticles2D = $Sparks

var _time := 0.0


func _ready() -> void:
	flame.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	add_to_group("kindle_point")
	monitorable = false

	var shape := RectangleShape2D.new()
	shape.size = trigger_size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0, -trigger_size.y / 2.0)
	add_child(collider)

	body_entered.connect(_on_body_entered)
	_show_state(false)


func get_respawn_position() -> Vector2:
	return global_position + respawn_offset


func activate() -> void:
	if is_active:
		return
	is_active = true
	_show_state(true)

	flame.scale = Vector2(0.2, 0.2) * candle.scale
	glow.energy = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(flame, "scale", candle.scale, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(glow, "energy", lit_energy, 0.4)
	sparks.restart()
	Sfx.play("wisp_arrive", global_position, -6.0)
	activated.emit()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		activate()


func _process(delta: float) -> void:
	if not is_active:
		return
	_time += delta
	if _time < 0.4:
		return
	# Gentle candle flicker
	var flicker := 0.9 + 0.07 * sin(_time * 11.0) + 0.03 * sin(_time * 23.0)
	glow.energy = lit_energy * flicker


func _show_state(lit: bool) -> void:
	flame.visible = lit
	glow.enabled = lit
	glow.color = lit_glow_color
	candle.modulate = Color.WHITE if lit else unlit_candle_tint


## A lit flame she can kindle her lantern at (hold the kindle key).
func is_kindling() -> bool:
	return true
