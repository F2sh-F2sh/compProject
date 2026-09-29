class_name LevelExit
extends Area2D

## Walk into this to finish the level. Shows a completion message, then loads
## next_scene_path. If no next scene is set, control is handed back instead.

@export_file("*.tscn") var next_scene_path := ""
@export var completion_text := "Tutorial Complete"
@export var trigger_size := Vector2(40, 64)
@export var fade_time := 0.8
@export var message_hold_time := 1.6

const TITLE_FONT_NAMES := ["Cinzel", "Trajan Pro", "Times New Roman", "Georgia", "Liberation Serif", "DejaVu Serif", "serif"]

var _triggered := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = trigger_size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0, -trigger_size.y / 2.0)
	add_child(collider)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player") or body.is_dead:
		return
	_triggered = true
	body.lock_controls()

	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	var fade := ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0.01, 0.005, 0.03, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)

	var font := SystemFont.new()
	font.font_names = PackedStringArray(TITLE_FONT_NAMES)
	var title := Label.new()
	title.text = completion_text
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color("c9b8f0"))
	title.modulate.a = 0.0
	layer.add_child(title)

	for node in get_tree().get_nodes_in_group("gameplay_ui"):
		node.visible = false

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, fade_time)
	tween.tween_property(title, "modulate:a", 1.0, 0.6)
	tween.tween_interval(message_hold_time)
	if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
		tween.tween_callback(func(): get_tree().change_scene_to_file(next_scene_path))
	else:
		tween.tween_property(title, "modulate:a", 0.0, 0.5)
		tween.tween_property(fade, "color:a", 0.0, fade_time)
		tween.tween_callback(func():
			for node in get_tree().get_nodes_in_group("gameplay_ui"):
				node.visible = true
			body.unlock_controls()
			layer.queue_free())
