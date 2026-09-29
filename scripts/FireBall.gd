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
	add_to_group("fireball")
	start_position = global_position

	# The fireball lights its surroundings (and casts shadows) as it flies
	var light := PointLight2D.new()
	light.texture = LightTextures.radial(256)
	light.color = Color(1.0, 0.58, 0.25)
	light.energy = 1.2
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	add_child(light)

	# A fast-pulsing halo and a trail of embers left hanging in the air
	add_child(GlowFX.halo(Color(1.0, 0.55, 0.25), 20.0, 0.6, 9.0, 0.18, 0.25))
	var trail := GlowFX.embers(Color(1.0, 0.62, 0.3), 14, 8.0, 3.0, 0.45)
	trail.preprocess = 0.0
	trail.local_coords = false
	add_child(trail)

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
			damage *= 3

			print("CRITICAL HIT!")

			# Reset critical chance after a critical
			critical_chance = 0.05

		body.take_damage(damage, is_critical)

		queue_free()
		return


	# Destroy on walls/floors
	if body.is_in_group("world") or body is TileMap or body is TileMapLayer:
		queue_free()
