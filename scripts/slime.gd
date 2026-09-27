extends CharacterBody2D

@export var damage_number_scene: PackedScene
@export var max_health := 30
@export var detection_range := 200.0
@export var hop_force := -250.0
@export var hop_speed := 80.0
@export var hop_cooldown := 0.8

# Aggro settings
@export var aggro_hop_speed := 140.0
@export var aggro_hop_cooldown := 0.5

var health: int
var player
var hop_timer := 0.0
var was_on_floor := true

var is_aggro := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	health = max_health
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Hop timer
	hop_timer -= delta

	# Normal hopping / aggro hopping
	if hop_timer <= 0 and is_on_floor():
		hop()

	move_and_slide()

	# Landing squash
	if is_on_floor() and not was_on_floor:
		_play_land_squash()

	was_on_floor = is_on_floor()


func hop():
	if is_aggro:
		hop_timer = aggro_hop_cooldown
	else:
		hop_timer = hop_cooldown

	# Make sure we have the player
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player:
		var direction = sign(
			player.global_position.x - global_position.x
		)

		# Aggro slime moves faster
		if is_aggro:
			velocity.x = direction * aggro_hop_speed
		else:
			var distance = global_position.distance_to(
				player.global_position
			)

			if distance <= detection_range:
				velocity.x = direction * hop_speed
			else:
				velocity.x = [-1, 1].pick_random() * hop_speed

	else:
		velocity.x = [-1, 1].pick_random() * hop_speed

	velocity.y = hop_force

	_play_hop_squash()


func _play_hop_squash():
	var tween = create_tween()

	tween.tween_property(
		sprite,
		"scale",
		Vector2(1.2, 0.7),
		0.08
	)

	tween.tween_property(
		sprite,
		"scale",
		Vector2(0.8, 1.3),
		0.12
	)

	tween.tween_property(
		sprite,
		"scale",
		Vector2(1, 1),
		0.2
	)


func _play_land_squash():
	var tween = create_tween()

	tween.tween_property(
		sprite,
		"scale",
		Vector2(1.3, 0.6),
		0.06
	)

	tween.tween_property(
		sprite,
		"scale",
		Vector2(1, 1),
		0.15
	)


func take_damage(amount, critical := false):
	# Become aggressive when hit
	is_aggro = true

	health -= amount

	# Create floating damage number
	if damage_number_scene:
		var damage_number = damage_number_scene.instantiate()

		get_tree().current_scene.add_child(damage_number)

		damage_number.global_position = $Marker2D.global_position

		damage_number.setup(amount, critical)

	# Flash red
	modulate = Color.RED

	if critical:
		print("CRITICAL HIT! Damage:", amount)
	else:
		print("Damage:", amount)

	await get_tree().create_timer(0.15).timeout

	modulate = Color.WHITE

	if health <= 0:
		die()

func die():
	queue_free()
