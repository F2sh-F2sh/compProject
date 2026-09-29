class_name FloatText
extends Node2D

## A short line of text that rises and fades in the world, e.g. "+5 MP" over a
## pickup or "Echo faded" over Echidna. Unshaded, so it reads in the dark.

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")


static func spawn(parent: Node, at: Vector2, text: String, color := Color(0.85, 0.78, 1.0), rise := 26.0,
		life := 1.2) -> FloatText:
	var ft := FloatText.new()
	parent.add_child(ft)
	ft.global_position = at
	ft._start(text, color, rise, life)
	return ft


func _start(text: String, color: Color, rise: float, life: float) -> void:
	z_index = 50
	material = MagicLight.unshaded()
	var label := Label.new()
	label.text = text
	label.use_parent_material = true
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.05, 0.9))
	label.add_theme_constant_override("outline_size", 6)
	label.scale = Vector2(0.5, 0.5)
	add_child(label)
	label.resized.connect(func(): label.position = Vector2(-label.size.x * 0.25, -label.size.y * 0.5))
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "position:y", position.y - rise, life).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, life * 0.4).set_delay(life * 0.6)
	tween.chain().tween_callback(queue_free)
