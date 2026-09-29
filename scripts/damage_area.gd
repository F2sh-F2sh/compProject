class_name DamageArea
extends Area2D

@export var damage_amount: int = 1
@export var repeat_damage: bool = true
@export_range(0.1, 10.0, 0.1) var damage_interval: float = 1.0
## Push applied to whoever gets hit, away from this area. Zero means no push.
@export var knockback := Vector2.ZERO

var targets: Dictionary = {}


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func get_knockback_velocity(target: Node2D) -> Vector2:
	if knockback == Vector2.ZERO:
		return Vector2.ZERO
	var side := signf(target.global_position.x - global_position.x)
	if side == 0.0:
		side = 1.0
	return Vector2(side * knockback.x, knockback.y)


func _physics_process(delta: float) -> void:
	if not repeat_damage:
		return

	for hurtbox in targets.keys():

		if not is_instance_valid(hurtbox):
			targets.erase(hurtbox)
			continue

		targets[hurtbox] -= delta

		if targets[hurtbox] <= 0.0:
			_damage(hurtbox)
			targets[hurtbox] = damage_interval


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		_damage(area)

		if repeat_damage:
			targets[area] = damage_interval


func _on_area_exited(area: Area2D) -> void:
	targets.erase(area)


func _damage(hurtbox: Hurtbox) -> void:
	hurtbox.receive_damage(damage_amount, self)
