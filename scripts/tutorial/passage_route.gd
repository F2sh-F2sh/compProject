extends Node2D

## Two stages share the established Passage geometry. The movement tutorial
## ends before any spell shrine; the abbey's entry passage teaches magic.
@export var movement_only := false
const BORDER := 5300.0

func _ready() -> void:
	if not movement_only and not GameState.has_flag("story.movement_done"):
		return # Existing saves and the original complete-course test route.
	var player := get_node("Player")
	var camera := player.get_node("Camera2D") as CameraBounds
	if movement_only:
		var exit := get_node("LevelExit") as LevelExit
		exit.position = Vector2(BORDER - 100.0, 534)
		exit.next_scene_path = Journey.PASSAGE
		exit.completion_flag = "story.movement_done"
		exit.stat_prefix = "movement"
		exit.completion_text = "The pilgrim passage is behind you"
		exit.card_heading = "TUTORIAL COMPLETE"
		exit.card_title = "First Steps"
		exit.card_next_label = "Enter the abbey"
		camera.bounds = Rect2(0, 128, BORDER, 448)
	else:
		camera.bounds = Rect2(BORDER, 128, 8192 - BORDER, 448)
		if GameState.get_checkpoint_for(scene_file_path) == "":
			player.teleport_to(Vector2(BORDER + 20, 530))
	_trim(self)
	# A masonry end wall prevents walking back into the other stage.
	var wall := StaticBody2D.new()
	wall.collision_layer = 2
	wall.collision_mask = 0
	wall.add_to_group("world")
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 600)
	collider.shape = shape
	wall.position = Vector2(BORDER + 8 if movement_only else BORDER - 8, 300)
	wall.add_child(collider)
	add_child(wall)

func _trim(parent: Node) -> void:
	for child in parent.get_children():
		if child.name in ["Player", "LevelExit", "Atmosphere"] or child is CanvasLayer:
			continue
		if child is TileMapLayer:
			var map := child as TileMapLayer
			for cell in map.get_used_cells():
				var x := map.to_global(map.map_to_local(cell)).x
				if (movement_only and x >= BORDER) or (not movement_only and x < BORDER):
					map.erase_cell(cell)
			continue
		if child is Node2D and ((movement_only and child.global_position.x >= BORDER) or
				(not movement_only and child.global_position.x > 0 and child.global_position.x < BORDER)):
			child.queue_free()
			continue
		_trim(child)
