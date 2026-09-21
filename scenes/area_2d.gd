extends Area2D

@export var speed := 500.0
@export var max_distance := 400.0

@onready var animated_sprite = $AnimatedSprite2D

var direction := Vector2.ZERO
var start_position := Vector2.ZERO

func _ready():
	start_position = global_position
	animated_sprite.play("FireBall")
	

func _physics_process(delta):
	position += direction * speed * delta

	if global_position.distance_to(start_position) >= max_distance:
		queue_free()

func _on_body_entered(body):
	print("Hit:", body.name)

	# Damage enemy here if needed

	#queue_free()
