extends SceneTree

## Targeted, repeatable edits to the hand-built tutorial (its original builder
## is gone). Tile changes are made through the engine, then only the changed
## TileMapLayer data lines are swapped in the scene file, and any new nodes
## are appended, so nothing else in the file moves. Each patch checks whether
## it has already been applied.
##   godot --headless --path . --script res://tools/levels/patch_tutorial.gd

const TUTORIAL := "res://scenes/tutorial/tutorial_level.tscn"
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
	changed = _brighten() or changed
	changed = _novices_way() or changed
	changed = _trim_signs() or changed
	changed = _fire_last() or changed
	changed = _waymarks() or changed
	changed = _level_one() or changed

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
	_add_resource('[ext_resource type="Script" path="res://scripts/world/fall_catcher.gd" id="60_fallc"]')
	_text += '\n[node name="SprintGapPit" type="Area2D" parent="Hazards" unique_id=1718250931]\n' \
		+ 'position = Vector2(2048, 560)\nscript = ExtResource("60_fallc")\nsize = Vector2(128, 48)\n'
	print("sprint_gap: applied")
	return true


# Splits the tutorial into titled lessons (scripts/tutorial/lesson_zone.gd): a card on
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
	_add_resource('[ext_resource type="Script" path="res://scripts/tutorial/lesson_zone.gd" id="61_lesson"]')
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


# A brighter dungeon (the same values as the chapter builder): ambient light,
# the three tile tints, and a bigger pool of light from every wall torch.
# (Brightness then scales these at run time: see PostFX.)
const BRIGHTER := [
	['[node name="Darkness" type="CanvasModulate" parent="." unique_id=1928645671]\ncolor = Color(0.2, 0.18, 0.3, 1)',
		'[node name="Darkness" type="CanvasModulate" parent="." unique_id=1928645671]\ncolor = Color(0.5, 0.48, 0.64, 1)'],
	# (an earlier, dimmer step of this change)
	['[node name="Darkness" type="CanvasModulate" parent="." unique_id=1928645671]\ncolor = Color(0.4, 0.38, 0.52, 1)',
		'[node name="Darkness" type="CanvasModulate" parent="." unique_id=1928645671]\ncolor = Color(0.5, 0.48, 0.64, 1)'],
	['modulate = Color(0.8, 0.78, 0.9, 1)', 'modulate = Color(0.88, 0.86, 0.99, 1)'],
	['modulate = Color(0.95, 0.95, 1, 1)', 'modulate = Color(1, 1, 1, 1)'],
	['modulate = Color(0.66, 0.63, 0.76, 1)', 'modulate = Color(0.73, 0.69, 0.84, 1)'],
	['texture_scale = 1.7', 'texture_scale = 2.1'],
	# Echidna's own lantern, as in the chapters (energy 1.15, a larger pool)
	['energy = 0.95\ntexture = SubResource("GradientTexture2D_3akfc")',
		'energy = 1.15\ntexture = SubResource("GradientTexture2D_3akfc")\ntexture_scale = 1.45'],
]


func _brighten() -> bool:
	var changed := false
	for pair in BRIGHTER:
		if _text.contains(pair[0]):
			_text = _text.replace(pair[0], pair[1])
			changed = true
	print("brighten: ", "applied" if changed else "already applied")
	return changed


# ------------------------------------------------------------------ the Novices' Way
# The tutorial is "The Passage": seven phases of the monks' training path from
# Nan's cellar to the Belfry. Echidna starts without her spells; she remembers
# them at three shrines (scripts/puzzle/ability_shrine.gd): Fire at the Kept
# Flame (phase 4, before the pistons that need it), Heal at the Spring (phase 5,
# after them) and Echo at the Echo stone (phase 7, before the Echo lesson).
const PHASES := [
	# lesson node, card line, title, subtitle
	["Lesson1", "THE NOVICES' WAY · PHASE 1 · THE PILGRIM PASSAGE", "First Steps", "Walk, and sprint"],
	["Lesson2", "PHASE 1 · THE PILGRIM PASSAGE", "Jumping", "Hop up onto ledges"],
	["Lesson3", "PHASE 2 · THE BROKEN STAIR", "Sprint Jumps", "Carry your speed across wide gaps"],
	["Lesson4", "PHASE 2 · THE BROKEN STAIR", "High Jumps", "Crouch to gather power"],
	["Lesson5", "PHASE 3 · THE NOVICES' TRAPS", "Spikes", "Candles mark where you return"],
	["Lesson6", "PHASE 3 · THE NOVICES' TRAPS", "Pistons", "Learn their rhythm"],
	["Lesson7", "PHASE 4 · THE KEPT FLAME", "Fire", "The monks kept one flame alight"],
	["Lesson8", "PHASE 6 · THE CELLS", "Slimes", "Keep your distance"],
	["Lesson9", "PHASE 7 · THE ECHO DOOR", "Echoes", "Your Echo repeats what you did"],
]

const SHRINES := '''

[node name="KeptFlame" type="Node2D" parent="." unique_id=1718250952]
z_index = -1
position = Vector2(5330, 534)
script = ExtResource("62_shrine")
ability = "fire"
sprite_name = "kept_flame"
word = "FLAME"
verb = "Read"
story = "The monks kept this flame alight so the Hush could not take the word.\nPress {shoot} to throw fire (aim with the mouse). It costs mana: hold {reload} anywhere to restore it."
glow_color = Color(0.45, 0.65, 1, 1)

[node name="Spring" type="Node2D" parent="." unique_id=1718250953]
z_index = -1
position = Vector2(5890, 534)
script = ExtResource("62_shrine")
ability = "heal"
sprite_name = "spring"
word = "SPRING"
verb = "Drink"
story = "Running water is the one thing the Hush has never held still.\nStand still and press {heal} to heal. It costs mana."
glow_color = Color(0.4, 0.85, 0.95, 1)

[node name="EchoStone" type="Node2D" parent="." unique_id=1718250954]
z_index = -1
position = Vector2(6735, 534)
script = ExtResource("62_shrine")
ability = "echo"
sprite_name = "echo_stone"
word = "ECHO"
verb = "Listen"
story = "The Choir carved your family's Echo into this stone. The Hush stole your memory of it, but the stone still remembers. Listen, and the word returns.\nPress {echo} to record yourself, and again to stop. Your Echo repeats it."
glow_color = Color(0.62, 0.5, 1, 1)

[node name="Lesson10" type="Area2D" parent="Lessons" unique_id=1718250951]
position = Vector2(5800, 534)
script = ExtResource("61_lesson")
number = 10
eyebrow = "PHASE 5 · THE SPRING"
title = "Healing"
subtitle = "Running water is still alive"
width = 190.0
spawn = Vector2(20, 0)
'''


func _novices_way() -> bool:
	if _text.contains('[node name="KeptFlame"'):
		print("novices way: already applied")
		return false
	_add_resource('[ext_resource type="Script" path="res://scripts/puzzle/ability_shrine.gd" id="62_shrine"]')
	for p in PHASES:
		_set_props('name="%s" type="Area2D" parent="Lessons"' % p[0],
			{"eyebrow": '"%s"' % p[1], "title": '"%s"' % p[2], "subtitle": '"%s"' % p[3]})
	# The Fire lesson now ends where the Spring begins
	_set_props('name="Lesson7" type="Area2D" parent="Lessons"', {"width": "500.0"})
	_text += SHRINES
	# The signs around them
	_replace_text("Welcome to the dungeon.\nUse {move_left}", "Welcome to the Novices' Way.\nUse {move_left}")
	_set_props('name="Fireball" type="Node2D" parent="Signs"', {"position": "Vector2(5440, 456)", "width": "180.0"})
	_set_props('name="Echo" type="Node2D" parent="Signs"', {"position": "Vector2(6840, 456)"})
	# (Healing is taught at the Spring now)
	_remove_node('name="Heal" type="Node2D" parent="Signs"')
	print("novices way: applied")
	return true


## Sets (or adds) single-line properties on the node whose header contains
## `header` (e.g. 'name="Lesson7" type="Area2D" parent="Lessons"').
func _set_props(header: String, props: Dictionary) -> void:
	var start := _text.find("[node " + header)
	if start == -1:
		print("novices way: no node ", header)
		return
	var end := _text.find("\n[", start + 1)
	if end == -1:
		end = _text.length()
	var block := _text.substr(start, end - start)
	for key in props:
		var rx := RegEx.create_from_string("(?m)^%s = .*$" % key)
		if rx.search(block):
			block = rx.sub(block, "%s = %s" % [key, props[key]])
		else:
			block = block.rstrip("\n") + "\n%s = %s" % [key, props[key]]
	_text = _text.substr(0, start) + block.rstrip("
") + "
" + _text.substr(end)


func _remove_node(header: String) -> void:
	var start := _text.find("[node " + header)
	if start == -1:
		return
	var end := _text.find("\n[", start + 1)
	if end == -1:
		end = _text.length()
	_text = _text.substr(0, start).rstrip("\n") + "\n" + _text.substr(end)


func _replace_text(old: String, new: String) -> void:
	if _text.count(old) != 1:
		print("novices way: expected one '%s', found %d" % [old.replace("\n", " / "), _text.count(old)])
		return
	_text = _text.replace(old, new)


# The shrines' cards now say what each spell does, so the signs next to them
# shrink or go (fewer hints): the pistons sign, the Echo sign and the slimes.
func _trim_signs() -> bool:
	if not _text.contains("Aim with the mouse and press {shoot}"):
		print("trim signs: already applied")
		return false
	_replace_text("These pistons never stop.\nAim with the mouse and press {shoot} to hit the rune switch beyond them.",
		"These pistons never stop.\nPress {shoot} to hit the rune switch beyond them.")
	_remove_node('name="Echo" type="Node2D" parent="Signs"')
	_replace_text("Slimes! Keep your distance and burn them with fireballs ({shoot}).", "Slimes! Keep your distance.")
	print("trim signs: applied")
	return true


# ------------------------------------------------------------------ fire comes last
# The Passage now ends with the fire lessons: the Echo Door moves to where the
# Kept Flame was (x 5300), and the Kept Flame, the pistons that need fire and
# the slimes move 1300 px on (to x 6600). The Spring is gone from the Passage
# (Heal now comes back at the end of the Belfry). Phases: 4 The Echo Door,
# 5 The Kept Flame, 6 The Cells.
func _fire_last() -> bool:
	if not _text.contains('[node name="Spring"'):
		print("fire last: already applied")
		return false
	var fire := {
		'name="KeptFlame" type="Node2D" parent="."': 5330, 'name="Fireball" type="Node2D" parent="Signs"': 5440,
		'name="GauntletPiston1" type="Node2D" parent="Gauntlet"': 5536, 'name="GauntletPiston2" type="Node2D" parent="Gauntlet"': 5600,
		'name="GauntletPiston3" type="Node2D" parent="Gauntlet"': 5664, 'name="Slimes" type="Node2D" parent="Signs"': 6080,
	}
	for header in fire:
		_shift(header, 1300)
	_shift('name="RuneSwitch" type="Area2D" parent="Gauntlet"', 1300)
	_shift('name="Slime1" type="CharacterBody2D" parent="Enemies"', 1300)
	_shift('name="Slime2" type="CharacterBody2D" parent="Enemies"', 1300)
	_shift('name="SlimeArenaCombat" type="Area2D" parent="."', 1300)
	for header in ['name="EchoStone" type="Node2D" parent="."', 'name="Gate" type="Node2D" parent="EchoLab"',
			'name="Plate" type="Area2D" parent="EchoLab"', 'name="Plate" type="Node2D" parent="Signs"',
			'name="Debt" type="Node2D" parent="Signs"']:
		_shift(header, -1400)
	_shift('name="PuddleArena" parent="Puddles"', 1300)
	_shift('name="PuddleLab" parent="Puddles"', -1400)
	_set_props('name="WellDone" type="Node2D" parent="Signs"', {"position": "Vector2(7960, 456)"})
	_set_props('name="LevelExit" type="Area2D" parent="."', {"position": "Vector2(8060, 534)"})
	# the lesson zones
	_set_props('name="Lesson9" type="Area2D" parent="Lessons"', {"position": "Vector2(5300, 534)", "width": "1300.0",
		"eyebrow": '"PHASE 4 · THE ECHO DOOR"'})
	_set_props('name="Lesson7" type="Area2D" parent="Lessons"', {"position": "Vector2(6600, 534)", "width": "690.0",
		"eyebrow": '"PHASE 5 · THE KEPT FLAME"'})
	_set_props('name="Lesson8" type="Area2D" parent="Lessons"', {"position": "Vector2(7290, 534)", "width": "800.0",
		"eyebrow": '"PHASE 6 · THE CELLS"'})
	_remove_node('name="Lesson10" type="Area2D" parent="Lessons"')
	_set_props('name="Lesson1" type="Area2D" parent="Lessons"', {"tour": '"basics"'})
	_remove_node('name="Spring" type="Node2D" parent="."')
	print("fire last: applied")
	return true


## Moves a node's position by dx (x only).
func _shift(header: String, dx: float) -> void:
	var start := _text.find("[node " + header)
	if start == -1:
		print("fire last: no node ", header)
		return
	var end := _text.find("\n[", start + 1)
	var block := _text.substr(start, end - start)
	var rx := RegEx.create_from_string("(?m)^position = Vector2[(]([-0-9.]+), ([-0-9.]+)[)]$")
	var m := rx.search(block)
	if m == null:
		print("fire last: no position on ", header)
		return
	var shifted := "position = Vector2(%d, %s)" % [int(float(m.get_string(1)) + dx), m.get_string(2)]
	block = block.replace(m.get_string(), shifted)
	_text = _text.substr(0, start) + block + _text.substr(end)


# ------------------------------------------------------------------ waymarks
# The Choir's glowing arrows along the Passage (scripts/puzzle/waymark.gd).
const WAYMARKS_AT := [600, 1500, 2150, 2650, 3300, 4150, 4750, 5200, 6350, 7050, 7750]


func _waymarks() -> bool:
	if _text.contains('[node name="Waymarks"'):
		print("waymarks: already applied")
		return false
	_add_resource('[ext_resource type="PackedScene" path="res://scenes/puzzle/waymark.tscn" id="63_waymark"]')
	_text += '\n[node name="Waymarks" type="Node2D" parent="."]\n'
	for i in WAYMARKS_AT.size():
		_text += '\n[node name="Waymark%d" parent="Waymarks" instance=ExtResource("63_waymark")]\nposition = Vector2(%d, 458)\n' % [i + 1, WAYMARKS_AT[i]]
	print("waymarks: applied")
	return true


# The tutorial is Level 1: the first place she comes to in the dungeon, down
# Nan's cellar door. Its first card and its welcome sign say so.
func _level_one() -> bool:
	if _text.contains("LEVEL 1 · THE PASSAGE"):
		print("level one: already applied")
		return false
	_set_props('name="Lesson1" type="Area2D" parent="Lessons"', {"eyebrow": '"LEVEL 1 · THE PASSAGE · THE PILGRIM PASSAGE"'})
	_replace_text("Welcome to the Novices' Way.\nUse {move_left}", "Level 1: the Passage.\nUse {move_left}")
	print("level one: applied")
	return true
