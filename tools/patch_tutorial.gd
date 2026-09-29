extends SceneTree

## Targeted, repeatable edits to the hand-built tutorial (its original builder
## is gone). Tile changes are made through the engine, then only the changed
## TileMapLayer data lines are swapped in the scene file, and any new nodes
## are appended, so nothing else in the file moves. Each patch checks whether
## it has already been applied.
##   godot --headless --path . --script res://tools/patch_tutorial.gd

const TUTORIAL := "res://scenes/tutorial_level.tscn"
const LAYERS := ["Ground", "GroundHalf", "GroundHalfShifted", "Earth"]

var _started := false
var _text := ""


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	root.get_node("GameState").persist_to_disk = false
	_text = FileAccess.get_file_as_string(TUTORIAL)
	var scene: Node = load(TUTORIAL).instantiate()
	root.add_child(scene)
	await physics_frame
	var before := {}
	for layer_name in LAYERS:
		before[layer_name] = Marshalls.raw_to_base64((scene.get_node(layer_name) as TileMapLayer).tile_map_data)

	var changed := _sprint_gap(scene)
	changed = _lessons() or changed

	if changed:
		for layer_name in LAYERS:
			var after := Marshalls.raw_to_base64((scene.get_node(layer_name) as TileMapLayer).tile_map_data)
			if after == before[layer_name]:
				continue
			var old_line := 'tile_map_data = PackedByteArray("%s")' % before[layer_name]
			if _text.count(old_line) != 1:
				print("ABORTED: %s tile data not found exactly once" % layer_name)
				quit(1)
				return
			_text = _text.replace(old_line, 'tile_map_data = PackedByteArray("%s")' % after)
		var file := FileAccess.open(TUTORIAL, FileAccess.WRITE)
		file.store_string(_text)
		file.close()
		print("tutorial patched")
	print("PATCH DONE")
	quit()


# The "sprint jump" gap used to sit 32 px above the floor: a short jump just
# dropped you onto the floor and you hopped up the other side, so sprinting
# was never needed. Now the gap is 128 px wide (a walking jump, even a charged
# one, falls short; a sprint jump clears it easily) over a shallow pit whose
# FallCatcher fades you back to the ledge with no damage.
#   ledge before: GroundHalf cols 28-31 (x 1792-2048, top y 502), unchanged
#   pit: cols 32-33 (x 2048-2176), floor sunk to y 598
#   ledge after: moved from the shifted layer (x 2144-2272) to cols 34-35
#   (x 2176-2304)
func _sprint_gap(scene: Node) -> bool:
	var ground: TileMapLayer = scene.get_node("Ground")
	var half: TileMapLayer = scene.get_node("GroundHalf")
	var shifted: TileMapLayer = scene.get_node("GroundHalfShifted")
	var earth: TileMapLayer = scene.get_node("Earth")
	if half.get_cell_source_id(Vector2i(34, 7)) != -1:
		print("sprint_gap: already applied")
		return false
	for x in [32, 33]:
		var floor_atlas := ground.get_cell_atlas_coords(Vector2i(x, 8))
		ground.erase_cell(Vector2i(x, 8))
		earth.erase_cell(Vector2i(x, 9))
		ground.set_cell(Vector2i(x, 9), 0, floor_atlas)
	var ledge := [shifted.get_cell_atlas_coords(Vector2i(33, 7)), shifted.get_cell_atlas_coords(Vector2i(34, 7))]
	shifted.erase_cell(Vector2i(33, 7))
	shifted.erase_cell(Vector2i(34, 7))
	half.set_cell(Vector2i(34, 7), 0, ledge[0])
	half.set_cell(Vector2i(35, 7), 0, ledge[1])
	_add_resource('[ext_resource type="Script" path="res://scripts/fall_catcher.gd" id="60_fallc"]')
	_text += '\n[node name="SprintGapPit" type="Area2D" parent="Hazards" unique_id=1718250931]\n' \
		+ 'position = Vector2(2048, 560)\nscript = ExtResource("60_fallc")\nsize = Vector2(128, 48)\n'
	print("sprint_gap: applied")
	return true


# Splits the tutorial into titled lessons (scripts/lesson_zone.gd): a card on
# entering each, and a death restarts the current lesson instead of the whole
# tutorial. The exit marks the tutorial as done.
const LESSONS := [
	# [left edge x, width, respawn x (relative), title, subtitle]
	[0, 1100, 224, "First Steps", "Walk, and sprint"],
	[1100, 660, 40, "Jumping", "Hop up onto ledges"],
	[1760, 540, 20, "Sprint Jumps", "Carry your speed across wide gaps"],
	[2300, 440, 20, "High Jumps", "Crouch to gather power"],
	[2740, 1020, 20, "Spikes", "Candles mark where you return"],
	[3760, 1540, 20, "Pistons", "Learn their rhythm"],
	[5300, 690, 20, "Fire", "Aim with the mouse"],
	[5990, 710, 10, "Slimes", "Keep your distance"],
	[6700, 1492, 20, "Echoes", "Your Echo repeats what you did"],
]


func _lessons() -> bool:
	if _text.contains('[node name="Lessons"'):
		print("lessons: already applied")
		return false
	_add_resource('[ext_resource type="Script" path="res://scripts/lesson_zone.gd" id="61_lesson"]')
	_text += '\n[node name="Lessons" type="Node2D" parent="." unique_id=1718250940]\n'
	for i in LESSONS.size():
		var l: Array = LESSONS[i]
		_text += '\n[node name="Lesson%d" type="Area2D" parent="Lessons" unique_id=%d]\n' % [i + 1, 1718250941 + i] \
			+ 'position = Vector2(%d, 534)\nscript = ExtResource("61_lesson")\nnumber = %d\n' % [l[0], i + 1] \
			+ 'title = "%s"\nsubtitle = "%s"\nwidth = %d.0\nspawn = Vector2(%d, 0)\n' % [l[3], l[4], l[1], l[2]]
	var exit_line := 'next_scene_path = "res://scenes/chapter/chapter_1.tscn"\n'
	if _text.count(exit_line) == 1:
		_text = _text.replace(exit_line, exit_line + 'completion_flag = "tutorial.done"\n')
	print("lessons: applied")
	return true


func _add_resource(line: String) -> void:
	if _text.contains(line):
		return
	var last := _text.rfind("[ext_resource ")
	var end := _text.find("\n", last)
	_text = _text.insert(end + 1, line + "\n")
