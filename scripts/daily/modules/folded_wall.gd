class_name FoldedWallModule
extends DailyMechanism

func _init() -> void:
	configure("folded_wall")


func parameter_grid() -> Array:
	var out: Array = []
	for width in [2, 3, 4]:
		for lock in [0, 1]: out.append({"width": width, "lock": lock})
	return out


func base_recipe(params: Dictionary) -> String:
	return "space/-/right/-" if int(params.get("lock", 0)) == 1 else super.base_recipe(params)


func build(k: RoomKit, room: Room, x0: int, x1: int, params: Dictionary, words: PackedStringArray) -> Dictionary:
	var pieces := super.build(k, room, x0, x1, params, words)
	# The solid wall must read as foreground masonry, rather than another
	# stretch of the background. Reuse the existing dark-brick atlas face.
	var facing := TileMapLayer.new()
	facing.name = "FoldedWallFacing"
	facing.tile_set = k.ts
	facing.collision_enabled = false
	facing.occlusion_enabled = false
	facing.modulate = Color(0.43, 0.38, 0.57)
	facing.z_index = 1
	room.add_child(facing)
	for col in range(x0 + 5, x0 + 5 + int(params["width"])):
		for row in range(RoomKit.LOW_CEIL, 9):
			facing.set_cell(Vector2i(col, row), 1, Vector2i(1, 0))
	return pieces
