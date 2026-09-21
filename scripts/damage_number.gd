extends Node2D

@onready var label: Label = $Label

func setup(damage: int, critical: bool) -> void:
	if critical:
		label.text = "CRITICAL!"
		label.modulate = Color(0.554, 0.524, 0.01, 1.0)
		label.scale = Vector2(1.3, 1.3)
	else:
		label.text = str(damage)
		label.modulate = Color.WHITE
		label.scale = Vector2.ONE

	var start_pos = position
	position.y -= 10

	var tween = create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"position",
		start_pos + Vector2(0, -45),
		0.6
	)

	tween.tween_property(
		label,
		"modulate:a",
		0.0,
		0.6
	)

	await tween.finished
	queue_free()
