extends Node2D

## A number that pops up where a creature is hit and floats away. A critical
## hit shows its (doubled) number larger, in orange, with a "!". Unshaded and
## outlined, so it reads in the darkest room.

@onready var label: Label = $Label


func setup(damage: int, critical: bool) -> void:
	# (tweened every drawn frame: drawn where it is, not between physics steps)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	z_index = 50
	material = MagicLight.unshaded()
	label.use_parent_material = true
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.08, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	if critical:
		label.text = "%d!" % damage
		label.modulate = Color(1.0, 0.62, 0.25)
		label.scale = Vector2(1.4, 1.4)
	else:
		label.text = str(damage)
		label.modulate = Color(1.0, 0.95, 0.9)
		label.scale = Vector2.ONE

	var start_pos = position
	position.y -= 10
	position.x += randf_range(-6.0, 6.0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", start_pos + Vector2(randf_range(-10.0, 10.0), -45), 0.7) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.35).set_delay(0.35)

	await tween.finished
	queue_free()
