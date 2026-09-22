extends Area2D

@export var speed: float = 500.0
@export var max_distance: float = 400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO

# Critical hit system
var critical_chance: float = 0.01 # Starts at 1%
const CRITICAL_INCREASE: float = 0.10 # +10% when you roll 7 damage
const MAX_CRITICAL_CHANCE: float = 1.0 # Maximum 100%


func _ready() -> void:
	start_position = global_position

	if animated_sprite.sprite_frames.has_animation("FireBall"):
		animated_sprite.play("FireBall")


func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	if global_position.distance_to(start_position) >= max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	# Damage enemies
	if body.is_in_group("enemy") and body.has_method("take_damage"):

		var damage: int = randi_range(3, 7)

		# If we roll 7 damage, increase critical chance
		if damage == 7:
			critical_chance = min(
				critical_chance + CRITICAL_INCREASE,
				MAX_CRITICAL_CHANCE
			)

			print("Damage was 7! Critical chance is now ",
				critical_chance * 100, "%")
				
		if damage == 6:
			critical_chance = min(
				critical_chance + CRITICAL_INCREASE,
				MAX_CRITICAL_CHANCE
			)

			print("Damage was 6! Critical chance is now ",
				critical_chance * 100, "%")

		# Roll for critical
		var is_critical: bool = randf() < critical_chance

		if is_critical:
			damage = 15

			print("CRITICAL HIT!")

			# Reset critical chance after a critical
			critical_chance = 0.05

		body.take_damage(damage, is_critical)

		queue_free()
		return


	# Destroy on walls/floors
	if body.is_in_group("world") or body is TileMap or body is TileMapLayer:
		queue_free()
