@tool
class_name LessonZone
extends Area2D

## One lesson of the tutorial (a stretch of the Novices' Way). Walking into it the first time shows its card
## ("PHASE 2 . THE BROKEN STAIR / Sprint Jumps") and saves it as the respawn point, so a
## death restarts the current lesson instead of the whole tutorial. The node
## marks the lesson's left edge on the floor; `spawn` is where to respawn,
## relative to it.

## The lesson's id (saved as its respawn point); not what the card says.
@export var number := 1
## The small line above the title, e.g. "PHASE 4 . THE KEPT FLAME". Empty = "LESSON n".
@export var eyebrow := ""
@export var title := ""
@export var subtitle := ""
@export var height := 520.0
@export var width := 256.0
@export var spawn := Vector2(48, 0)
## A UiTour to play a few seconds after the card, the first time (UiTour.steps_for).
@export var tour := ""

var _shown := false


func get_id() -> String:
	return "lesson.%d" % number


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, height)
	var shape := CollisionShape2D.new()
	shape.shape = rect
	shape.position = Vector2(width / 2.0, -height / 2.0)
	add_child(shape)
	body_entered.connect(_on_body_entered)
	add_to_group("lesson_zone")
	if GameState.get_checkpoint_for(_scene_path()) == get_id():
		# Respawning into this lesson: no card, and start at its beginning
		_shown = true
		_respawn_here.call_deferred()


# The level this lesson belongs to (its owner is the level's root node, even
# while the level is still being added to the tree)
func _scene_path() -> String:
	return owner.scene_file_path if owner else ""


func get_spawn_position() -> Vector2:
	return global_position + spawn


func _respawn_here() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.has_method("teleport_to"):
		player.teleport_to(get_spawn_position())


func _on_body_entered(body: Node) -> void:
	if _shown or not body.is_in_group("player"):
		return
	_shown = true
	GameState.set_checkpoint(_scene_path(), get_id())
	TitleCard.show_card(owner if owner else get_parent(), eyebrow if eyebrow != "" else "LESSON %d" % number, title, subtitle, 2.2)
	if tour != "":
		UiTour.play_later(self, tour, 3.6)
