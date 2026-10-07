class_name LevelExit
extends Area2D

## Walk into this to finish the level. Shows a completion message, then the
## card with the run's numbers (time, deaths) and Continue / Return to Title;
## Continue loads next_scene_path. If no next scene is set, control is handed
## back instead. While the level is played it keeps its time and deaths as
## run statistics ("<stat_prefix>.stat.time" / ".deaths").

@export_file("*.tscn") var next_scene_path := ""
@export var completion_text := "Level 1 Complete  ·  The Passage"
@export var trigger_size := Vector2(40, 64)
## Saved when the level is finished (e.g. "tutorial.done").
@export var completion_flag := ""
@export var fade_time := 0.8
@export var message_hold_time := 1.6
## Where this level's run statistics are kept.
@export var stat_prefix := "tutorial"
## The card's heading and the level's name on it.
@export var card_heading := "LEVEL 1 COMPLETE"
@export var card_title := "The Passage"
@export var card_next_label := "Continue to Level 2: The Belfry"

const TITLE_FONT_NAMES := ["Cinzel", "Trajan Pro", "Times New Roman", "Georgia", "Liberation Serif", "DejaVu Serif", "serif"]

var _triggered := false
## The card shown at the end (for tests).
var results_card: ChapterComplete


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
	_watch_player.call_deferred()


func _watch_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_signal("died"):
		player.died.connect(func(): GameState.add_stat(stat_prefix + ".stat.deaths", 1))


func _physics_process(delta: float) -> void:
	if not _triggered:
		GameState.add_stat(stat_prefix + ".stat.time", delta)


func _on_body_entered(body: Node) -> void:
	if _triggered or not body.is_in_group("player") or body.is_dead:
		return
	_triggered = true
	body.lock_controls()
	if completion_flag != "":
		GameState.set_flag(completion_flag)
	# A finished level starts from the beginning if it is played again
	var scene := get_tree().current_scene
	if scene and not scene.is_in_group("chapter_root"):
		GameState.clear_checkpoint(scene.scene_file_path)
	GameState.save_game()

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
		tween.tween_property(title, "modulate:a", 0.0, 0.4)
		tween.tween_callback(_show_card)
	else:
		tween.tween_property(title, "modulate:a", 0.0, 0.5)
		tween.tween_property(fade, "color:a", 0.0, fade_time)
		tween.tween_callback(func():
			for node in get_tree().get_nodes_in_group("gameplay_ui"):
				node.visible = true
			body.unlock_controls()
			layer.queue_free())


## The run's numbers with Continue (on to the next scene) and Return to Title.
func _show_card() -> void:
	results_card = ChapterComplete.open(self, card_title, {
		"time": GameState.get_stat(stat_prefix + ".stat.time"),
		"deaths": GameState.get_stat(stat_prefix + ".stat.deaths"),
		"next": next_scene_path,
		"heading": card_heading,
		"next_label": card_next_label,
	})
