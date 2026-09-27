extends CanvasLayer

@export var heart_scene: PackedScene
@export var health_per_heart: int = 2

@onready var hearts_container: HBoxContainer = $HUDRoot/Hearts

var hearts: Array[Node] = []


func set_hearts(current_health: int, max_health: int) -> void:
	current_health = clampi(current_health, 0, max_health)

	var heart_count := ceili(float(max_health) / health_per_heart)

	if hearts.size() != heart_count:
		create_hearts(heart_count)

	for i in range(heart_count):
		var health_in_this_heart := clampi(
			current_health - (i * health_per_heart),
			0,
			health_per_heart
		)

		hearts[i].set_health_amount(
			health_in_this_heart,
			health_per_heart
		)


func create_hearts(count: int) -> void:
	for heart in hearts:
		heart.queue_free()

	hearts.clear()

	for i in range(count):
		var heart = heart_scene.instantiate()
		hearts_container.add_child(heart)
		hearts.append(heart)
