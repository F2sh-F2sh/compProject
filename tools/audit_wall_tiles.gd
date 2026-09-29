extends SceneTree

## Reports floor-standing wall tiles (pillars, doors, arcades) that don't rest
## on the ground in the tutorial and the chapter. With "fix", misplaced tiles
## in the hand-built tutorial are moved down onto the floor and its scene file
## is patched in place (only the BackDecor tile data line changes). The
## chapter is generated: fix it in tools/build_chapter.gd instead.
##   godot --headless --path . --script res://tools/audit_wall_tiles.gd -- [fix]

const TUTORIAL := "res://scenes/tutorial_level.tscn"
const SCENES := [TUTORIAL, "res://scenes/chapter/chapter_1.tscn", "res://scenes/chapter/chapter_2.tscn"]

var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	var fix := OS.get_cmdline_user_args().has("fix")
	root.get_node("GameState").persist_to_disk = false
	var total := 0
	for path in SCENES:
		var scene: Node = load(path).instantiate()
		root.add_child(scene)
		for i in 3:
			await physics_frame
		var layer: TileMapLayer = scene.get_node("BackDecor")
		var bad := WallTileAudit.find_misplaced(layer)
		print("%s: %d misplaced" % [path, bad.size()])
		for b in bad:
			print("  cell %s atlas %s gap %s" % [b.cell, b.atlas, b.gap])
		total += bad.size()
		if fix and path == TUTORIAL and not bad.is_empty():
			_fix(layer, bad)
		scene.queue_free()
		await process_frame
	print("AUDIT DONE misplaced=%d" % total)
	quit()


func _fix(layer: TileMapLayer, bad: Array) -> void:
	var before := Marshalls.raw_to_base64(layer.tile_map_data)
	for b in bad:
		if b.atlas == WallTileAudit.ARCH_TOP or is_inf(b.gap):
			continue
		var rows := roundi(b.gap / WallTileAudit.TILE)
		if absf(b.gap - rows * WallTileAudit.TILE) > WallTileAudit.TOLERANCE or rows == 0:
			# Ground that isn't on the tile grid (a +96 plateau): stand it on
			# the nearest stretch of floor it can rest on instead
			var spot := _nearest_resting_cell(layer, b.cell)
			if spot == b.cell:
				print("  can't fix %s (gap %.0f)" % [b.cell, b.gap])
				continue
			_move_to(layer, b.cell, spot)
			continue
		_move(layer, b.cell, rows)
		# An arcade's top travels with its foot
		var above: Vector2i = b.cell + Vector2i(0, -1)
		if layer.get_cell_atlas_coords(above) == WallTileAudit.ARCH_TOP:
			_move(layer, above, rows)
	var after := Marshalls.raw_to_base64(layer.tile_map_data)
	var text := FileAccess.get_file_as_string(TUTORIAL)
	var old_line := 'tile_map_data = PackedByteArray("%s")' % before
	if text.count(old_line) != 1:
		print("  FIX ABORTED: BackDecor tile data not found exactly once in the scene file")
		return
	text = text.replace(old_line, 'tile_map_data = PackedByteArray("%s")' % after)
	var file := FileAccess.open(TUTORIAL, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("  tutorial patched")


func _nearest_resting_cell(layer: TileMapLayer, cell: Vector2i) -> Vector2i:
	var space := layer.get_world_2d().direct_space_state
	for dx in [1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, -6]:
		for dy in range(-1, 4):
			var target: Vector2i = cell + Vector2i(dx, dy)
			if layer.get_cell_source_id(target) != -1:
				continue
			if absf(WallTileAudit.ground_gap(layer, space, target)) <= WallTileAudit.TOLERANCE:
				return target
	return cell


# Moves a wall tile down by `rows`; the plain brick it covered stays behind
# on the Background layer, so nothing else changes.
func _move(layer: TileMapLayer, cell: Vector2i, rows: int) -> void:
	_move_to(layer, cell, cell + Vector2i(0, rows))


func _move_to(layer: TileMapLayer, cell: Vector2i, target: Vector2i) -> void:
	var atlas := layer.get_cell_atlas_coords(cell)
	var source := layer.get_cell_source_id(cell)
	var alt := layer.get_cell_alternative_tile(cell)
	layer.erase_cell(cell)
	layer.set_cell(target, source, atlas, alt)
	print("  moved %s -> %s" % [cell, target])
