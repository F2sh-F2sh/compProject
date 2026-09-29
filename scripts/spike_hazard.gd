@tool
class_name SpikeHazard
extends Area2D

## A strip of floor spikes. The node sits on the floor surface, centred on the strip.
## A non-lethal hit sends the player back to recovery_checkpoint (once reached);
## lethal hits are handled by the player's normal death sequence.

const SPIKE_TEXTURE := preload("res://assets/Spikes.png")
const SPIKE_SIZE := 32.0

@export_range(1, 32) var spike_count := 2:
	set(value):
		spike_count = value
		_rebuild()
@export var damage_amount := 2
## The safe spot the player returns to after a non-lethal hit.
@export var recovery_checkpoint: HazardCheckpoint
## Shrinks the hitbox inside the art: x from each side, y down from the spike tips.
@export var hitbox_inset := Vector2(4, 16):
	set(value):
		hitbox_inset = value
		_rebuild()
## Minimum time between hit attempts on the same hurtbox.
@export var rehit_delay := 0.25

var _sprite: Sprite2D
var _collider: CollisionShape2D
var _cooldowns := {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_rebuild()
	if not Engine.is_editor_hint():
		add_to_group("hazard_zone")


func get_width() -> float:
	return spike_count * SPIKE_SIZE


## Called by the player after a non-lethal hit.
func get_recovery_position(player: Node2D) -> Vector2:
	if recovery_checkpoint and recovery_checkpoint.is_active:
		return recovery_checkpoint.get_respawn_position()
	var recovery := player.get_node_or_null("HazardRecovery")
	if recovery:
		return recovery.get_fallback_position()
	return player.global_position


## World-space rectangle the player should never be respawned inside.
func get_hazard_rect() -> Rect2:
	var w := get_width()
	return Rect2(global_position + Vector2(-w / 2.0, -SPIKE_SIZE), Vector2(w, SPIKE_SIZE))


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	for hurtbox in _cooldowns.keys():
		_cooldowns[hurtbox] -= delta
		if _cooldowns[hurtbox] <= 0.0 or not is_instance_valid(hurtbox):
			_cooldowns.erase(hurtbox)

	if not _is_dangerous():
		return

	for area in get_overlapping_areas():
		if area is Hurtbox and not _cooldowns.has(area):
			_cooldowns[area] = rehit_delay
			area.receive_damage(damage_amount, self)


func _is_dangerous() -> bool:
	return true


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.texture = SPIKE_TEXTURE
		_sprite.centered = false
		_sprite.region_enabled = true
		_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		add_child(_sprite)
	if _collider == null:
		_collider = CollisionShape2D.new()
		_collider.shape = RectangleShape2D.new()
		add_child(_collider)

	var w := get_width()
	_sprite.region_rect = Rect2(0, 0, w, SPIKE_SIZE)
	_sprite.position = Vector2(-w / 2.0, -SPIKE_SIZE)
	_set_hitbox_height(SPIKE_SIZE - hitbox_inset.y)


func _set_hitbox_height(height: float) -> void:
	var w := get_width()
	var shape := _collider.shape as RectangleShape2D
	shape.size = Vector2(maxf(w - hitbox_inset.x * 2.0, 1.0), maxf(height, 1.0))
	_collider.position = Vector2(0, -shape.size.y / 2.0)
	_collider.set_deferred("disabled", height <= 2.0)
