class_name RevealTrigger
extends Area2D

## The first time ever she walks through it, the camera looks at something
## (the Great Kiln as she steps into the Kiln Hall), so the goal is seen
## before it is read about. Saved by `flag`, so it happens once.

@export var size := Vector2(64, 140)
@export var look_at := Vector2.ZERO
@export var hold := 2.2
@export var flag := ""


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = Vector2(0, -size.y / 2.0)
	add_child(shape)
	body_entered.connect(func(b):
		if not b.is_in_group("player") or (flag != "" and GameState.has_flag(flag)):
			return
		if flag != "":
			GameState.set_flag(flag)
		var root := get_tree().get_first_node_in_group("chapter_root") as ChapterRoot
		if root and root.player_is_safe():
			root.camera.focus_on(look_at, hold))
