extends SceneTree

## Generates Chapter 1, "The Sealed Belfry": one reusable scene per puzzle
## piece (scenes/puzzle, scenes/creatures, scenes/traps) and the chapter level
## scenes/chapter/chapter_1.tscn with its seven rooms.
##
##   godot --headless --path . --script res://tools/build_chapter.gd
##
## Rebuilding overwrites chapter_1.tscn, so tune rooms here (or stop using the
## builder and edit the scene by hand from then on). The work happens on the
## first frame, once the GameState/Settings/Sfx autoloads exist.
##
## Geometry reference (tiles are 64 px):
##   floor surface y 534 (row 8); ordinary ceiling underside y 272 (beam row 4);
##   tall rooms have their ceiling underside at y 16 (beam row 0).
##   Ground tile at row r: surface r*64+22. GroundHalf tile at row r: r*64+54.
##   Floating cap tile at row r: surface r*64+18.
## Player reach: tap jump ~62 px up, fully charged jump ~132 px up (measured
## by the chapter tests), walking jump ~82 px across, sprint jump ~157 px.

const TILESET_PATH := "res://assets/TileSet/dungeon_tileset.tres"
const OUT_PATH := "res://scenes/chapter/chapter_1.tscn"
const T := 64
const FLOOR_Y := 534
const LOW_CEIL := 4
const HIGH_CEIL := 0

const AMBIENT := Color(0.2, 0.18, 0.3)
const TORCH_COLOR := Color(0.42, 0.6, 1.0)
const BEAM_COLOR := Color(0.55, 0.8, 1.0)

const PUZZLE := "res://scenes/puzzle/"
const CREATURES := "res://scenes/creatures/"
const TRAPS := "res://scenes/traps/"

# Platform atlas (source 0)
const LEDGES := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
const CAP_LEFT := Vector2i(0, 1)
const CAP_MID := Vector2i(1, 1)
const CAP_RIGHT := Vector2i(2, 1)
const FLOOR_DECOR := [Vector2i(0, 4), Vector2i(2, 4), Vector2i(4, 4), Vector2i(5, 4)]
const BEAMS := [Vector2i(1, 3), Vector2i(1, 3), Vector2i(1, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3)]

# Wall atlas (source 1)
const WALL_PLAIN := [Vector2i(0, 0), Vector2i(4, 4), Vector2i(0, 0), Vector2i(4, 4), Vector2i(1, 0)]
const WALL_RARE := [Vector2i(0, 1), Vector2i(2, 0), Vector2i(2, 1), Vector2i(1, 1)]
const W_WINDOW_BARRED := Vector2i(1, 2)
const W_PILLAR := Vector2i(2, 2)
const W_TORCH := Vector2i(3, 2)
const W_CHAIN_RING := Vector2i(4, 2)
const W_BANNER_FLEUR := Vector2i(1, 3)
const W_WINDOW_DOUBLE := Vector2i(2, 3)
const W_WINDOW_MOON := Vector2i(3, 3)
const W_VINES_FULL := Vector2i(4, 3)
const W_VINES_TOP := Vector2i(3, 0)
const W_BLOOD := Vector2i(4, 0)
const W_PLAQUE_CROSS := Vector2i(3, 1)
const W_ARCHES_TOP := Vector2i(4, 1)
const W_ARCHES_BOTTOM := Vector2i(1, 4)
const W_BANNER_CROSS := Vector2i(3, 4)

var rng := RandomNumberGenerator.new()
var level: Node2D
var ts: TileSet
var background: TileMapLayer
var back_decor: TileMapLayer
var earth: TileMapLayer
var ceiling: TileMapLayer
var ground: TileMapLayer
var ground_half: TileMapLayer
var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		rng.seed = 1311
		build_components()
		ts = load(TILESET_PATH)
		build_level()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/chapter"))
		save_scene(level, OUT_PATH)
		level.free()
		print("BUILD CHAPTER OK")
		quit()
	return false


# ================================================================ components

func build_components() -> void:
	for dir in [PUZZLE, CREATURES, TRAPS]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var table := [
		[PUZZLE + "circuit.tscn", "Circuit", Node2D, "res://scripts/puzzle/circuit.gd"],
		[PUZZLE + "room.tscn", "Room", Node2D, "res://scripts/puzzle/room.gd"],
		[PUZZLE + "lever.tscn", "Lever", Node2D, "res://scripts/puzzle/lever.gd"],
		[PUZZLE + "pushable_block.tscn", "PushableBlock", CharacterBody2D, "res://scripts/puzzle/pushable_block.gd"],
		[PUZZLE + "puzzle_bell.tscn", "PuzzleBell", Node2D, "res://scripts/puzzle/puzzle_bell.gd"],
		[PUZZLE + "brazier.tscn", "Brazier", Node2D, "res://scripts/puzzle/brazier.gd"],
		[PUZZLE + "mirror.tscn", "Mirror", Node2D, "res://scripts/puzzle/mirror.gd"],
		[PUZZLE + "light_receiver.tscn", "LightReceiver", Node2D, "res://scripts/puzzle/light_receiver.gd"],
		[PUZZLE + "light_lens.tscn", "LightLens", Node2D, "res://scripts/puzzle/light_lens.gd"],
		[PUZZLE + "spectral_platform.tscn", "SpectralPlatform", Node2D, "res://scripts/puzzle/spectral_platform.gd"],
		[PUZZLE + "wisp_perch.tscn", "WispPerch", Node2D, "res://scripts/puzzle/wisp_perch.gd"],
		[PUZZLE + "rune_seal.tscn", "RuneSeal", Node2D, "res://scripts/puzzle/rune_seal.gd"],
		[PUZZLE + "hint_stone.tscn", "HintStone", Node2D, "res://scripts/puzzle/hint_stone.gd"],
		[PUZZLE + "lore_page.tscn", "LorePage", Area2D, "res://scripts/puzzle/lore_page.gd"],
		[PUZZLE + "chapter_checkpoint.tscn", "ChapterCheckpoint", Area2D, "res://scripts/puzzle/chapter_checkpoint.gd"],
		[PUZZLE + "iron_grate.tscn", "IronGrate", Node2D, "res://scripts/puzzle/iron_grate.gd"],
		[PUZZLE + "great_bell.tscn", "GreatBell", Node2D, "res://scripts/puzzle/great_bell.gd"],
		[CREATURES + "lantern_wisp.tscn", "LanternWisp", Node2D, "res://scripts/creatures/lantern_wisp.gd"],
		[CREATURES + "watcher_gargoyle.tscn", "WatcherGargoyle", CharacterBody2D, "res://scripts/creatures/watcher_gargoyle.gd"],
		[TRAPS + "arcane_bolt_statue.tscn", "ArcaneBoltStatue", Node2D, "res://scripts/traps/arcane_bolt_statue.gd"],
		[TRAPS + "crumbling_platform.tscn", "CrumblingPlatform", Node2D, "res://scripts/traps/crumbling_platform.gd"],
		[TRAPS + "magic_vent.tscn", "MagicVent", Node2D, "res://scripts/traps/magic_vent.gd"],
		[TRAPS + "moving_platform.tscn", "MovingPlatform", AnimatableBody2D, "res://scripts/traps/moving_platform.gd"],
	]
	for row in table:
		var node: Node = row[2].new()
		node.name = row[1]
		node.set_script(load(row[3]))
		save_scene(node, row[0])
		node.free()


func save_scene(node: Node, path: String) -> void:
	var packed := PackedScene.new()
	var err := packed.pack(node)
	if err != OK:
		push_error("pack failed for %s: %s" % [path, err])
		return
	err = ResourceSaver.save(packed, path)
	if err != OK:
		push_error("save failed for %s: %s" % [path, err])


func add_owned(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = level


func inst(path: String, parent: Node, node_name: String, pos: Vector2, props := {}) -> Node:
	var node: Node = load(path).instantiate()
	node.name = node_name
	if node is Node2D:
		node.position = pos
	for key in props:
		node.set(key, props[key])
	add_owned(parent, node)
	return node


func nodes(list: Array) -> Array[Node]:
	var typed: Array[Node] = []
	for n in list:
		typed.append(n)
	return typed


func light(tex_size: int, color: Color, energy: float, scale := 1.0, shadows := false) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = LightTextures.radial(tex_size)
	l.color = color
	l.energy = energy
	l.texture_scale = scale
	l.height = 40.0
	if shadows:
		l.shadow_enabled = true
		l.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		l.shadow_color = Color(0, 0, 0, 0.92)
	return l


# ================================================================ tiles

static func cx(col: float) -> float:
	return col * T + T / 2.0


func tile_layer(layer_name: String, pos := Vector2.ZERO, tint := Color.WHITE, z := 0, collide := true, occlude := true) -> TileMapLayer:
	var l := TileMapLayer.new()
	l.name = layer_name
	l.tile_set = ts
	l.position = pos
	l.modulate = tint
	l.z_index = z
	l.collision_enabled = collide
	l.occlusion_enabled = occlude
	add_owned(level, l)
	return l


func solid(x: int, y: int) -> void:
	earth.set_cell(Vector2i(x, y), 2, Vector2i(1, 0) if (x + y) % 3 else Vector2i(4, 4))


func ledge_tile() -> Vector2i:
	return LEDGES[rng.randi_range(0, LEDGES.size() - 1)]


func floor_tile(x: int, row := 8) -> void:
	ground.set_cell(Vector2i(x, row), 0, ledge_tile())


## Walls, ceiling rock, beams, floor and bedrock for one room. The two end
## columns are walls with a doorway (rows 6-7 open) unless marked outer.
func shell(x0: int, x1: int, ceil_row: int, outer_left := false, outer_right := false) -> void:
	for x in range(x0, x1 + 1):
		for y in range(ceil_row - 3, 11):
			var tile: Vector2i = WALL_PLAIN[rng.randi_range(0, WALL_PLAIN.size() - 1)]
			if rng.randf() < 0.08:
				tile = WALL_RARE[rng.randi_range(0, WALL_RARE.size() - 1)]
			if y == ceil_row - 1 and rng.randf() < 0.3:
				tile = W_VINES_TOP
			background.set_cell(Vector2i(x, y), 1, tile)
		for y in range(ceil_row - 6, ceil_row):
			solid(x, y)
		for y in range(9, 13):
			solid(x, y)
		var is_wall := x == x0 or x == x1
		if is_wall:
			var outer := (x == x0 and outer_left) or (x == x1 and outer_right)
			for y in range(ceil_row, 9 if outer else 6):
				solid(x, y)
			if not outer:
				floor_tile(x)
		else:
			ceiling.set_cell(Vector2i(x, ceil_row), 0, BEAMS[rng.randi_range(0, BEAMS.size() - 1)])
			floor_tile(x)


## Sinks floor columns by one tile (64 px): the new floor surface is y 598.
func pit(x0: int, x1: int) -> void:
	for x in range(x0, x1 + 1):
		ground.erase_cell(Vector2i(x, 8))
		earth.erase_cell(Vector2i(x, 9))
		floor_tile(x, 9)


## A cell below the floor, covered by a walkable iron grate.
func grated_cell(parent: Node, x0: int, x1: int) -> void:
	pit(x0, x1)
	inst(PUZZLE + "iron_grate.tscn", parent, "Grate", Vector2(x0 * T, FLOOR_Y), {"width": float((x1 + 1 - x0) * T)})


## A solid +96 block rising from the floor (surface y 438).
func plateau(x0: int, x1: int) -> void:
	for x in range(x0, x1 + 1):
		ground.erase_cell(Vector2i(x, 8))
		solid(x, 7)
		solid(x, 8)
		ground_half.set_cell(Vector2i(x, 6), 0, LEDGES[x % LEDGES.size()])


## A +32 kerb (surface y 502): a step the player hops, a block cannot climb.
func curb(x: int) -> void:
	ground_half.set_cell(Vector2i(x, 7), 0, LEDGES[x % LEDGES.size()])


## A floating ledge of cap tiles: surface row*64+18 on the Ground layer, or
## row*64+50 on the GroundHalf layer.
func floating_ledge(x0: int, x1: int, row: int, half := false) -> void:
	for x in range(x0, x1 + 1):
		var tile := CAP_MID
		if x0 != x1:
			tile = CAP_LEFT if x == x0 else (CAP_RIGHT if x == x1 else CAP_MID)
		(ground_half if half else ground).set_cell(Vector2i(x, row), 0, tile)


func decor(x: int, y: int, tile: Vector2i) -> void:
	back_decor.set_cell(Vector2i(x, y), 1, tile)


## A wall tile whose art stands on the ground (a pillar, the foot of an
## arcade) goes in the row whose bottom edge meets the floor (the wall layers
## sit 22 px down, so row 7 ends exactly at FLOOR_Y); `top` stacks above it.
## tools/audit_wall_tiles.gd checks every floor-standing tile rests on ground.
func decor_standing(x: int, foot: Vector2i, top := Vector2i(-1, -1)) -> void:
	decor(x, 7, foot)
	if top != Vector2i(-1, -1):
		decor(x, 6, top)


# ================================================================ level

var rooms := {}


func build_level() -> void:
	level = Node2D.new()
	level.name = "Chapter1"
	level.set_script(load("res://scripts/puzzle/chapter_root.gd"))
	level.set("chapter_id", "ch1")
	level.set("total_pages", 7)
	level.set("next_chapter", "res://scenes/chapter/chapter_2.tscn")

	var ambient := CanvasModulate.new()
	ambient.name = "Darkness"
	ambient.color = AMBIENT
	add_owned(level, ambient)

	background = tile_layer("Background", Vector2(0, 22), Color(0.8, 0.78, 0.9), -10, false, false)
	back_decor = tile_layer("BackDecor", Vector2(0, 22), Color(0.95, 0.95, 1.0), -9, false, false)
	earth = tile_layer("Earth", Vector2.ZERO, Color(0.66, 0.63, 0.76))
	ceiling = tile_layer("Ceiling", Vector2(0, -4))
	ground = tile_layer("Ground")
	ground_half = tile_layer("GroundHalf", Vector2(0, 32))

	room_1_entrance()
	room_2_bellkeeper()
	room_3_split_flame()
	room_4_watcher()
	room_5_machinery()
	room_6_lantern()
	room_7_belfry()
	room_8_choir()
	room_9_great_bell()
	ledger.sort_custom(func(a, b): return a["id"] < b["id"])
	level.set("ledger", ledger)
	place_atmosphere()
	place_player_and_ui()


# Parallax depth, broken walls and light shafts (scripts/fx/dungeon_atmosphere.gd).
# Breaches are cells of the Background layer: the upper wall of ordinary rooms
# (rows 4-5, just under the ceiling beam) and high up in the tall rooms.
func place_atmosphere() -> void:
	var atmos := Node2D.new()
	atmos.name = "Atmosphere"
	atmos.set_script(load("res://scripts/fx/dungeon_atmosphere.gd"))
	atmos.set("wall_path", NodePath("../Background"))
	atmos.set("decor_path", NodePath("../BackDecor"))
	var breaches: Array[Rect2i] = [
		Rect2i(5, 4, 3, 2), Rect2i(15, 4, 3, 2),           # R1
		Rect2i(24, 4, 3, 2), Rect2i(37, 4, 3, 2),          # R2
		Rect2i(46, 0, 4, 3), Rect2i(57, 1, 4, 3),          # R3 (tall)
		Rect2i(70, 4, 3, 2), Rect2i(81, 4, 2, 2),          # R4
		Rect2i(91, 0, 4, 3), Rect2i(103, 0, 4, 2), Rect2i(111, 1, 3, 3),  # R5 (tall)
		Rect2i(123, 4, 3, 2), Rect2i(133, 4, 3, 2),        # R6
		Rect2i(148, 0, 4, 3), Rect2i(162, 0, 4, 3),        # R7 (tall)
		Rect2i(179, 4, 3, 2), Rect2i(185, 4, 2, 2),        # R8
		Rect2i(198, 0, 4, 3), Rect2i(204, 1, 3, 2),        # R9 (tall)
	]
	atmos.set("breaches", breaches)
	atmos.set("reference_center", Vector2(87 * T, 400))
	atmos.set("seed", 7)
	add_owned(level, atmos)


## Rooms with enemies to fight (the music's combat layer rises in them).
const COMBAT_ROOMS := ["R4", "R7"]
## Each room's colour (post pass highlight tint, mist colour): cold for the
## cells, warm for the flame, amber for the works, teal by lantern light,
## violet in the belfry, gold at the great bell.
const MOODS := {
	"R1": [Color(0.98, 1.03, 1.1), Color(0.25, 0.34, 0.5)],
	"R2": [Color(1.0, 1.03, 1.08), Color(0.26, 0.35, 0.48)],
	"R3": [Color(1.08, 1.03, 0.96), Color(0.36, 0.33, 0.4)],
	"R4": [Color(0.98, 1.02, 1.1), Color(0.28, 0.34, 0.5)],
	"R5": [Color(1.1, 1.0, 0.9), Color(0.4, 0.32, 0.3)],
	"R6": [Color(0.95, 1.06, 1.06), Color(0.22, 0.38, 0.42)],
	"R7": [Color(1.03, 0.99, 1.1), Color(0.33, 0.3, 0.5)],
	"R8": [Color(1.07, 1.0, 1.04), Color(0.38, 0.3, 0.42)],
	"R9": [Color(1.1, 1.04, 0.93), Color(0.4, 0.36, 0.34)],
}


func make_room(id: String, title: String, x0: int, x1: int, ceil_row: int, entry: Vector2, deep := false) -> Node2D:
	var bounds := Rect2(x0 * T, (ceil_row - 2) * T, (x1 + 1 - x0) * T, (10 if deep else 9) * T - (ceil_row - 2) * T)
	var room := inst(PUZZLE + "room.tscn", level, id, Vector2.ZERO, {
		"room_id": "ch1." + id.to_lower(),
		"title": title,
		"bounds": bounds,
		"entry_spawn": entry,
		"combat": COMBAT_ROOMS.has(id),
		"mood_highlight": MOODS[id][0],
		"mood_fog": MOODS[id][1],
	})
	rooms[id] = room
	# The room's acoustics: tall chambers echo like caverns, the chasm like a
	# hall, the rest like stone corridors
	var acoustics := 0
	if ceil_row == HIGH_CEIL:
		acoustics = 2
	elif id == "R6":
		acoustics = 1
	var zone := Area2D.new()
	zone.name = "Acoustics"
	zone.set_script(load("res://scripts/audio/reverb_zone.gd"))
	zone.position = bounds.position
	zone.set("size", bounds.size)
	zone.set("acoustics", acoustics)
	add_owned(room, zone)
	return room


func group(parent: Node, group_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = group_name
	add_owned(parent, n)
	return n


func add_sign(parent: Node, sign_name: String, col: float, text: String, surface := float(FLOOR_Y), width := 170.0) -> void:
	inst("res://scenes/tutorial_sign.tscn", parent, sign_name, Vector2(cx(col), surface - 78.0),
		{"text": text, "width": width})


func torch(parent: Node, col: int, row := 6) -> void:
	decor(col, row, W_TORCH)
	inst("res://scenes/torch_light.tscn", parent, "Torch%d_%d" % [col, row], Vector2(cx(col), row * T + 22 + 14))


func gate(parent: Node, gate_name: String, col: int, height := 150.0, props := {}) -> Node:
	var p := {"height": height}
	p.merge(props)
	return inst("res://scenes/portcullis_gate.tscn", parent, gate_name, Vector2(cx(col), FLOOR_Y), p)


func circuit(parent: Node, circuit_name: String, sources: Array, targets: Array, props := {}) -> Node:
	var c := inst(PUZZLE + "circuit.tscn", parent, circuit_name, Vector2.ZERO, props)
	c.set("sources", nodes(sources))
	c.set("targets", nodes(targets))
	c.z_index = -5
	return c


func hint(parent: Node, pos: Vector2, lines: Array, focus: Array) -> void:
	var h := inst(PUZZLE + "hint_stone.tscn", parent, "HintStone", pos)
	h.set("hints", PackedStringArray(lines))
	h.set("focus_nodes", nodes(focus))


var ledger: Array[Dictionary] = []


func page(parent: Node, id: int, pos: Vector2, title: String, text: String) -> void:
	inst(PUZZLE + "lore_page.tscn", parent, "LorePage%d" % id, pos,
		{"page_id": "ch1.page.%d" % id, "title": title, "text": text})
	var ids: PackedStringArray = parent.get("page_ids")
	ids.append("ch1.page.%d" % id)
	parent.set("page_ids", ids)
	ledger.append({"id": "ch1.page.%d" % id, "numeral": ["i", "ii", "iii", "iv", "v", "vi", "vii"][id - 1],
		"title": title, "text": text, "room": parent.get("title")})


# ---------------------------------------------------------------- guidance
# Every room states its goal (never the solution) and has objective steps;
# the HUD shows a pip per step and names each one only once it is done.

enum Cond { POWERED, SOLVED, OPEN, RUNG, FROZEN, REACHED, FLAG, MOVED, PROPERTY }


func guide(room: Node, objective: String, act := "", act_title := "", act_subtitle := "") -> void:
	room.set("objective", objective)
	room.set("act", act)
	room.set("act_title", act_title)
	room.set("act_subtitle", act_subtitle)


func step(room: Node, label: String, cond: int, target: Node = null, props := {}) -> Node:
	var s := Node.new()
	s.set_script(load("res://scripts/puzzle/objective_step.gd"))
	s.name = "Step%d" % (room.get_children().filter(func(n): return n.get_script() == s.get_script()).size() + 1)
	add_owned(room, s)
	s.set("label", label)
	s.set("condition", cond)
	if target:
		s.set("target", target)
	for key in props:
		s.set(key, props[key])
	return s


## The room's lore page as an optional step, so players know one is there.
func page_step(room: Node, id: int) -> void:
	step(room, "Ledger page %s found" % ["i", "ii", "iii", "iv", "v", "vi", "vii"][id - 1], Cond.FLAG, null,
		{"flag": "ch1.page.%d" % id, "optional": true})


func slime(parent: Node, slime_name: String, pos: Vector2, props := {}) -> Node:
	var p := {"max_health": 12, "home_radius": 40.0, "detection_range": 200.0, "collision_mask": 2,
		"hears_bells": true, "investigate_time": 9.0, "respawn_on_room_reset": true}
	p.merge(props, true)
	var s := inst("res://scenes/slime.tscn", parent, slime_name, pos, p)
	var glow := light(128, Color(0.45, 1.0, 0.55), 0.55, 1.0)
	glow.name = "Glow"
	glow.position = Vector2(0, -10)
	add_owned(s, glow)
	return s


## A puddle on the floor centred on world x (it settles onto the floor, and
## removes itself if the ground there isn't flat).
func puddle(parent: Node, x: float, width := 80.0) -> void:
	inst("res://scenes/fx/puddle.tscn", parent, "Puddle%d" % parent.get_child_count(), Vector2(x, FLOOR_Y), {"width": width})


func prop(parent: Node, file: String, x: float, y: float, anchor_top := false, flip := false) -> Sprite2D:
	var tex: Texture2D = load("res://assets/TileSet/props/sprites/%s.png" % file)
	var s := Sprite2D.new()
	s.name = file.to_pascal_case() + str(parent.get_child_count())
	s.texture = tex
	s.centered = false
	var size := tex.get_size()
	s.offset = Vector2(-size.x / 2.0, 0.0 if anchor_top else -size.y)
	s.position = Vector2(x, y)
	s.flip_h = flip
	add_owned(parent, s)
	return s


# ---------------------------------------------------------------- Room 1
# Teaches pushing a block onto a plate; the carved groove shows which gate
# the plate powers. A +32 kerb stops the block exactly on the plate, so it
# can never be pushed past it. Optional page on a +96 ledge (charged jump).

func room_1_entrance() -> void:
	shell(0, 20, LOW_CEIL, true, false)
	plateau(1, 2)
	curb(14)
	var room := make_room("R1", "The Forgotten Entrance", 0, 20, LOW_CEIL, Vector2(380, 530))

	inst(PUZZLE + "chapter_checkpoint.tscn", room, "Shrine", Vector2(cx(5), FLOOR_Y), {"checkpoint_id": "ch1.cp.start"})
	page(room, 1, Vector2(128, 412), "The Bellkeeper's Ledger, i",
		"The belfry is sealed. The watchers turn to stone in holy light, so we keep the lamps lit and the bells quiet.")
	inst(PUZZLE + "pushable_block.tscn", room, "Block", Vector2(cx(9), FLOOR_Y))
	var plate := inst("res://scenes/pressure_plate.tscn", room, "Plate", Vector2(874, FLOOR_Y))
	var exit_gate := gate(room, "ExitGate", 20)
	circuit(room, "PlateToGate", [plate], [exit_gate],
		{"reveal_target": true, "persist_id": "ch1.r1.solved", "channel_y": 440.0, "symbol": 0})
	guide(room, "Open the gate at the far end.", "I", "The Toll", "Chapter 1  ·  The Sealed Belfry")
	step(room, "Stone on the plate: the gate opens", Cond.OPEN, exit_gate)
	page_step(room, 1)

	var signs := group(room, "Signs")
	add_sign(signs, "Welcome", 7, "Each room's goal is shown at the top right. Press {pause} for the map, settings or to reset a room.", FLOOR_Y, 200.0)
	add_sign(signs, "Push", 10.5, "Walk into a stone block to push it.")
	add_sign(signs, "Plate", 17, "A plate holds its gate open while something rests on it. Follow the groove.", FLOOR_Y, 180.0)

	var deco := group(room, "Decor")
	for c in [4, 12, 18]:
		torch(deco, c)
	decor(3, 5, W_WINDOW_DOUBLE)
	decor(8, 5, W_BANNER_FLEUR)
	decor_standing(15, W_ARCHES_BOTTOM, W_ARCHES_TOP)
	decor(19, 7, W_BLOOD)
	prop(deco, "cobweb_corner", 64 + 32, 268, true)
	prop(deco, "chain_short", cx(6), 272, true)
	prop(deco, "vine_long", cx(11), 266, true)
	prop(deco, "skull_pile", cx(4) - 20, FLOOR_Y)
	prop(deco, "rocks_a", cx(16), FLOOR_Y)
	puddle(deco, 470.0, 72.0)
	puddle(deco, cx(18), 80.0)
	prop(deco, "bat", cx(13), 266, true)


# ---------------------------------------------------------------- Room 2
# Bellbound Slime. The gate is open only while BOTH plates are held (after
# 0.5 s). Plate A lies in a sunken cell under an iron grate (the player walks
# over it; the slime cannot climb out), beneath a bell. A stone block pushed
# right stops on plate B against a +32 kerb and stays there. Ringing the bell
# (rope, or a fireball) makes the slime sit on plate A for 12 s: long enough
# to walk out through the open gate. Optional page on a +100 ledge.

func room_2_bellkeeper() -> void:
	shell(20, 44, LOW_CEIL)
	floating_ledge(38, 39, 6, true)
	curb(35)
	var room := make_room("R2", "The Bellkeeper's Cell", 20, 44, LOW_CEIL, Vector2(1400, 530), true)
	grated_cell(room, 27, 31)

	slime(room, "BellSlime", Vector2(cx(28), 596), {"warded": true, "investigate_time": 12.0})
	var plate_a := inst("res://scenes/pressure_plate.tscn", room, "PlateA", Vector2(2016, 598))
	var bell := inst(PUZZLE + "puzzle_bell.tscn", room, "Bell", Vector2(2016, 400),
		{"chain_length": 106.0, "pull_offset": Vector2(80, 74), "cooldown": 2.0})
	inst(PUZZLE + "pushable_block.tscn", room, "Block", Vector2(cx(32), FLOOR_Y))
	var plate_b := inst("res://scenes/pressure_plate.tscn", room, "PlateB", Vector2(2218, FLOOR_Y))
	var exit_gate := gate(room, "ExitGate", 44)
	circuit(room, "BothPlates", [plate_a, plate_b], [exit_gate],
		{"reveal_target": true, "hold_time": 0.5, "persist_id": "ch1.r2.solved", "channel_y": 430.0, "symbol": 1})
	guide(room, "Open the gate beyond the slime's cell.")
	step(room, "A block rests on the far plate", Cond.POWERED, plate_b)
	step(room, "The bell tolls", Cond.RUNG, bell)
	step(room, "The slime settles on its plate", Cond.POWERED, plate_a)
	step(room, "Both plates held: the gate opens", Cond.OPEN, exit_gate)
	page_step(room, 2)

	hint(room, Vector2(cx(23), FLOOR_Y), [
		"Look at the bell, the plate beneath it, the plate by the gate, and the stone block.",
		"The gate is open only while both plates are held at the same moment. A slime is heavy enough to hold one; the block can hold the other.",
		"Push the block onto the plate by the gate. Then ring the bell (pull its rope, or hit it with a fireball): the slime sits on the plate below it, and the gate stays open while it does.",
	], [bell, plate_a, plate_b])
	page(room, 2, Vector2(39 * T, 410), "The Bellkeeper's Ledger, ii",
		"The slimes of the lower cells come to the bell like hounds. We ring it at feeding time. Some say they think the bell is their mother.")

	var signs := group(room, "Signs")
	add_sign(signs, "Bells", 24.5, "Slimes follow the toll of a bell and sit where it rings.", FLOOR_Y, 180.0)
	add_sign(signs, "Ring", 34.8, "Pull a bell's rope with {interact}, or strike the bell with a fireball ({shoot}).", FLOOR_Y, 190.0)
	add_sign(signs, "TwoPlates", 40.6, "This gate wakes only while both of its plates are pressed at once.", FLOOR_Y, 180.0)

	var deco := group(room, "Decor")
	for c in [22, 29, 36, 42]:
		torch(deco, c)
	decor(25, 5, W_WINDOW_BARRED)
	decor(34, 5, W_CHAIN_RING)
	decor(41, 5, W_BANNER_CROSS)
	decor(28, 7, W_BLOOD)
	prop(deco, "chain_cage", cx(24), 272, true)
	prop(deco, "chain_short", cx(35), 272, true)
	prop(deco, "moss_drip_top", cx(30), 264, true)
	prop(deco, "skeleton", cx(42), FLOOR_Y)
	prop(deco, "rat", cx(26), FLOOR_Y)
	puddle(deco, 1584.0, 64.0)
	puddle(deco, cx(40) + 16, 80.0)


# ---------------------------------------------------------------- Room 3
# Split Flame (tall). The brazier's beam runs right at y 500 to mirror M1.
# Stage 1: turn M1 to send it up to hanging mirror M2, which starts facing
# the left crystal R1 -> spectral stairs appear (while R1 or R2 is lit). Stage 2: on the
# gallery, turn M2 until the beam reaches R2 -> the exit gate opens.
# The stairs start right of the beam column so they can never block it.

func room_3_split_flame() -> void:
	shell(44, 64, HIGH_CEIL)
	for x in range(57, 64):
		floor_tile(x, 4)
	var room := make_room("R3", "The Split Flame", 44, 64, HIGH_CEIL, Vector2(2890, 530))

	inst(PUZZLE + "chapter_checkpoint.tscn", room, "Shrine", Vector2(cx(45), FLOOR_Y), {"checkpoint_id": "ch1.cp.r3"})
	var brazier := inst(PUZZLE + "brazier.tscn", room, "Brazier", Vector2(cx(48), FLOOR_Y), {"beam_direction": Vector2.RIGHT})
	var m1 := inst(PUZZLE + "mirror.tscn", room, "MirrorLow", Vector2(cx(51), 500),
		{"facing": 1, "post_length": 34.0})
	# The upper beam runs at y 330: under the gallery slab (278-320), above
	# every stair, and low enough to be seen from the floor
	var m2 := inst(PUZZLE + "mirror.tscn", room, "MirrorHigh", Vector2(cx(51), 330),
		{"facing": 2, "hanging": true, "post_length": 314.0, "interact_offset": Vector2(404, -52)})
	var r1 := inst(PUZZLE + "light_receiver.tscn", room, "CrystalStairs", Vector2(2892, 330), {"accepts_aura": false})
	var r2 := inst(PUZZLE + "light_receiver.tscn", room, "CrystalGate", Vector2(4084, 330), {"accepts_aura": false})
	var stairs: Array = []
	for i in 5:
		stairs.append(inst(PUZZLE + "spectral_platform.tscn", room, "Stair%d" % (i + 1),
			Vector2(3328 + i * 64, 486 - i * 48), {"size": Vector2(64, 12)}))
	var exit_gate := gate(room, "ExitGate", 64)
	# The stairs stand while either crystal is lit, so once the beam moves on to
	# the gate crystal the way back up to the gallery stays
	circuit(room, "StairsCircuit", [r1, r2], stairs,
		{"mode": 1, "persist_id": "ch1.r3.stairs", "symbol": 2, "channel_y": 380.0})
	circuit(room, "GateCircuit", [r2], [exit_gate],
		{"reveal_target": true, "persist_id": "ch1.r3.solved", "symbol": 3})
	guide(room, "Wake both crystals to open the way on.", "II", "The Flame")
	step(room, "The brazier burns", Cond.POWERED, brazier)
	step(room, "The first crystal wakes: stairs rise", Cond.POWERED, r1)
	step(room, "The second crystal opens the gate", Cond.OPEN, exit_gate)
	page_step(room, 3)

	hint(room, Vector2(cx(46), FLOOR_Y), [
		"Look at the brazier, both mirrors and both crystals.",
		"Magic fire casts a beam; a mirror turns it a quarter turn off its silver face, and its dark back stops it. The low mirror feeds the high one.",
		"Light the brazier with a fireball. Turn the low mirror until the beam climbs to the high mirror: the left crystal raises stairs. Climb them and turn the high mirror until the beam reaches the right crystal.",
	], [brazier, m1, m2, r1, r2])
	page(room, 3, Vector2(cx(60), 254), "The Bellkeeper's Ledger, iii",
		"Brother Aldous split the altar flame with his silvered glass, so one fire could keep two doors. He was proud of that. The watchers were not.")

	var signs := group(room, "Signs")
	add_sign(signs, "Fire", 47, "A fireball ({shoot}) lights a brazier. Its magic fire casts a beam.", FLOOR_Y, 170.0)
	add_sign(signs, "Mirrors", 54.5, "Mirrors turn a beam off their silver face. Turn one with {interact}.", FLOOR_Y, 170.0)

	var deco := group(room, "Decor")
	for c in [46, 55, 62]:
		torch(deco, c)
	for c in [48, 58]:
		torch(deco, c, 2)
	decor(53, 1, W_WINDOW_MOON)
	decor(49, 5, W_PLAQUE_CROSS)
	decor_standing(60, W_PILLAR)
	decor(45, 2, W_BANNER_FLEUR)
	prop(deco, "chain_hook_ball", cx(47), 16, true)
	prop(deco, "vine_long", cx(56), 10, true)
	prop(deco, "cobweb_corner", cx(63) + 8, 12, true, true)
	prop(deco, "rocks_b", cx(62), FLOOR_Y)
	puddle(deco, cx(59), 96.0)


# ---------------------------------------------------------------- Room 4
# Silent Watcher. A lever opens a ceiling lens; its beam drops onto a fixed
# mirror and sweeps left across the whole hall at gargoyle height, stopping
# at a kerb. The gargoyle freezes wherever the light finds it. Only stone can
# press the heavy plate, so the player must pull the lever while the
# gargoyle is over the plate (pull again to release it and retry).
# Optional page on a ledge at +128: an easy charged jump from the frozen
# gargoyle's back (+32), or a perfectly charged jump from the floor.

func room_4_watcher() -> void:
	shell(64, 84, LOW_CEIL)
	curb(68)
	floor_tile(73, 6)
	floor_tile(74, 6)
	var room := make_room("R4", "The Silent Watcher", 64, 84, LOW_CEIL, Vector2(4180, 530))

	var lever := inst(PUZZLE + "lever.tscn", room, "Lever", Vector2(cx(67), FLOOR_Y))
	var lens := inst(PUZZLE + "light_lens.tscn", room, "Lens", Vector2(cx(79), 284), {"beam_direction": Vector2.DOWN})
	inst(PUZZLE + "mirror.tscn", room, "FixedMirror", Vector2(cx(79), 518),
		{"facing": 3, "rotatable": false, "post_length": 16.0})
	var plate := inst("res://scenes/pressure_plate.tscn", room, "HeavyPlate", Vector2(4640, FLOOR_Y),
		{"stone_only": true, "width": 48.0})
	var watcher := inst(CREATURES + "watcher_gargoyle.tscn", room, "Watcher", Vector2(4800, FLOOR_Y),
		{"patrol_min_x": 4450.0, "patrol_max_x": 4890.0, "walk_speed": 55.0, "start_facing": -1})
	var exit_gate := gate(room, "ExitGate", 84)
	circuit(room, "LeverToLens", [lever], [lens], {"channel_y": 300.0, "symbol": 1})
	circuit(room, "PlateToGate", [plate], [exit_gate],
		{"reveal_target": true, "hold_time": 0.3, "persist_id": "ch1.r4.solved", "channel_y": 440.0, "symbol": 0})
	guide(room, "Open the gate past the watcher.")
	step(room, "The lens opens", Cond.POWERED, lever)
	step(room, "The watcher turns to stone", Cond.FROZEN, watcher)
	step(room, "Stone on the heavy plate: the gate opens", Cond.OPEN, exit_gate)
	page_step(room, 4)

	hint(room, Vector2(cx(65), FLOOR_Y), [
		"Look at the lever, the lens in the ceiling, and the heavy plate.",
		"The lens lights the whole hall at once. A watcher becomes stone wherever the light touches it, and only stone can press the heavy plate.",
		"Wait by the lever and watch the gargoyle. Pull the lever just as it walks onto the heavy plate. If you miss, pull it again to release the gargoyle and wait for its next pass.",
	], [lever, lens, plate])
	page(room, 4, Vector2(4736, 382), "The Bellkeeper's Ledger, iv",
		"The watcher on the east stair has not moved in nine years. Nobody has been brave enough to put out its lamp and find out why.")

	var signs := group(room, "Signs")
	add_sign(signs, "Watchers", 66.5, "Watchers hunt in darkness. Magic light turns them to stone, and stone is heavy.", FLOOR_Y, 190.0)
	add_sign(signs, "Heavy", 71.5, "A heavy plate. Only stone can press it.", FLOOR_Y, 150.0)

	var deco := group(room, "Decor")
	for c in [65, 70, 76, 82]:
		torch(deco, c)
	decor(68, 5, W_WINDOW_DOUBLE)
	decor(80, 5, W_VINES_FULL)
	decor(74, 7, W_BLOOD)
	prop(deco, "chain_short", cx(71), 272, true)
	prop(deco, "moss_drip_top", cx(75), 264, true)
	prop(deco, "gargoyle", cx(83) - 8, FLOOR_Y)
	prop(deco, "tombstone_rubble", cx(81), FLOOR_Y)
	puddle(deco, 4520.0, 64.0)
	return


# ---------------------------------------------------------------- Room 5
# Broken Machinery (tall). A lift carries the player up to the works: a
# course at y 278 with retracting spikes (non-lethal, candle recovery), two
# solid-headed pistons, a skull plaque firing bolts down a corridor (push the
# block ahead as a shield, then use it as a step to the +64 ledge), and two
# vents. A drop leads to the end hall, where a one-way lever opens the gate
# of the tunnel under the works: a permanent shortcut back to the lift.

func room_5_machinery() -> void:
	shell(84, 116, HIGH_CEIL)
	for x in range(89, 108):
		floor_tile(x, 4)
	for x in range(108, 113):
		floor_tile(x, 3)
		solid(x, 4)
	var room := make_room("R5", "Broken Machinery", 84, 116, HIGH_CEIL, Vector2(5440, 530))
	var course := 278.0
	var step := 214.0

	inst(PUZZLE + "chapter_checkpoint.tscn", room, "Shrine", Vector2(cx(85), FLOOR_Y), {"checkpoint_id": "ch1.cp.r5"})
	inst(TRAPS + "moving_platform.tscn", room, "Lift", Vector2(87 * T, FLOOR_Y - 18),
		{"width_tiles": 2, "travel": Vector2(0, -256), "speed": 80.0, "end_pause": 1.2})
	var shortcut_gate := gate(room, "ShortcutGate", 89, FLOOR_Y - 320.0)

	var candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleCourse", Vector2(cx(90), course))
	inst("res://scenes/retracting_spikes.tscn", room, "RisingSpikes", Vector2(cx(93), course),
		{"spike_count": 3, "recovery_checkpoint": candle})
	# A crushed player restarts the pistons from here, not back past the spikes
	var candle_pistons := inst("res://scenes/hazard_checkpoint.tscn", room, "CandlePistons", Vector2(cx(95), course))
	for i in 2:
		inst("res://scenes/piston_trap.tscn", room, "Piston%d" % (i + 1), Vector2(cx(97 + i * 3), 16),
			{"raised_head_bottom": course - 112.0 - 16.0, "travel_distance": 112.0, "start_phase": [0.0, 0.45][i],
			"recovery_checkpoint": candle_pistons})
	var block := inst(PUZZLE + "pushable_block.tscn", room, "ShieldBlock", Vector2(cx(103), course))
	var statue := inst(TRAPS + "arcane_bolt_statue.tscn", room, "SkullPlaque", Vector2(108 * T - 12, course - 20),
		{"fire_direction": Vector2.LEFT, "interval": 2.2, "bolt_range": 700.0})
	for i in 2:
		inst(TRAPS + "magic_vent.tscn", room, "Vent%d" % (i + 1), Vector2(cx(109 + i * 2), step),
			{"reach": 110.0, "idle_time": 1.4, "warning_time": 0.6, "active_time": 0.9, "start_phase": [0.0, 0.5][i]})
	var lever := inst(PUZZLE + "lever.tscn", room, "ShortcutLever", Vector2(cx(114), FLOOR_Y),
		{"one_way": true, "persist_id": "ch1.r5.shortcut"})
	circuit(room, "Shortcut", [lever], [shortcut_gate],
		{"channel_y": 420.0, "symbol": 3, "reveal_target": true, "solved_sound": ""})
	guide(room, "Cross the broken works to the far hall.", "III", "The Works")
	step(room, "Up the lift into the works", Cond.REACHED, null, {"area": Rect2(89 * T, 200, 5 * T, 90)})
	step(room, "Past the pistons", Cond.REACHED, null, {"area": Rect2(102 * T, 150, 6 * T, 140)})
	step(room, "Down into the far hall", Cond.REACHED, null, {"area": Rect2(113 * T, 430, 3 * T, 110)})
	step(room, "The tunnel back is open", Cond.FLAG, null, {"flag": "ch1.r5.shortcut", "optional": true})
	page_step(room, 5)

	hint(room, Vector2(cx(101), course), [
		"Look at the stone block, the skull plaque, and the ledge above the plaque.",
		"Arcane bolts burst against stone.",
		"Push the block ahead of you all the way to the wall. It shields you from the bolts, then stand on it to hop up to the ledge.",
	], [block, statue])
	page(room, 5, Vector2(cx(91), 510), "The Bellkeeper's Ledger, v",
		"The engineers built the works above the old tunnel so the watchers could not follow them home. The tunnel door only opens from the far side.")

	var signs := group(room, "Signs")
	add_sign(signs, "Lift", 86, "The lift carries you up into the works.", FLOOR_Y, 150.0)
	# Up in the works the camera sits higher, so these signs hang lower
	add_sign(signs, "Bolts", 102.5, "Skull plaques spit bolts. Stone stops them.", course + 14.0, 150.0)
	add_sign(signs, "Vents", 110, "Vents flare before they burst.", step + 14.0, 140.0)
	add_sign(signs, "Shortcut", 115, "This lever opens the tunnel back to the lift.", FLOOR_Y, 160.0)

	var deco := group(room, "Decor")
	torch(deco, 86)
	for c in [95, 101, 107]:
		torch(deco, c)
	for c in [92, 99, 105, 111]:
		torch(deco, c, 1)
	decor(88, 2, W_WINDOW_BARRED)
	decor(96, 2, W_CHAIN_RING)
	decor(114, 5, W_PLAQUE_CROSS)
	prop(deco, "chain_short", cx(94), 16, true)
	prop(deco, "chain_cage", cx(114), 16, true)
	prop(deco, "cobweb_corner", cx(85) - 8, 12, true)
	prop(deco, "skull_pile", cx(98), 534)
	prop(deco, "rocks_a", cx(106), 534)


# ---------------------------------------------------------------- Room 6
# Lantern Crossing. Spiked chasms (64 deep, non-lethal: candle recovery).
# Beat 1: four hidden platforms, solid only in the wisp's light. Each rune
# bracket sits between two platforms and is called from the platform before
# it, so the platform you stand on stays lit while the wisp moves on.
# Beat 2: crumbling ledges from the island. Beat 3: the wisp's light on a
# crystal raises a light bridge. A one-way lever raises a walkway over every
# chasm: the return shortcut.

func room_6_lantern() -> void:
	shell(116, 144, LOW_CEIL)
	pit(121, 128)
	pit(131, 134)
	pit(137, 140)
	var room := make_room("R6", "Lantern Crossing", 116, 144, LOW_CEIL, Vector2(7560, 530), true)
	var pit_floor := 598.0
	var rest_y := 462.0

	# A shrine at the chasm's edge: a death here no longer replays the works
	inst(PUZZLE + "chapter_checkpoint.tscn", room, "Shrine", Vector2(cx(117), FLOOR_Y), {"checkpoint_id": "ch1.cp.r6"})
	var candle_entry := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleEntry", Vector2(cx(119), FLOOR_Y))
	var candle_island := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleIsland", Vector2(8352, FLOOR_Y))
	var candle_landing := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleLanding", Vector2(cx(135), FLOOR_Y))
	inst("res://scenes/spike_trap.tscn", room, "ChasmSpikes1", Vector2(8000, pit_floor),
		{"spike_count": 16, "recovery_checkpoint": candle_entry})
	inst("res://scenes/spike_trap.tscn", room, "ChasmSpikes2", Vector2(8512, pit_floor),
		{"spike_count": 8, "recovery_checkpoint": candle_island})
	inst("res://scenes/spike_trap.tscn", room, "ChasmSpikes3", Vector2(8896, pit_floor),
		{"spike_count": 8, "recovery_checkpoint": candle_landing})

	var wisp := inst(CREATURES + "lantern_wisp.tscn", room, "Wisp", Vector2(7744, rest_y),
		{"light_radius": 112.0, "speed": 130.0})
	var perch_x := [7744, 7872, 8000, 8128, 8256]
	var perches: Array = []
	for i in perch_x.size():
		var call_offset := Vector2(-44, FLOOR_Y - rest_y) if i == 0 else Vector2(-64, FLOOR_Y - rest_y)
		perches.append(inst(PUZZLE + "wisp_perch.tscn", room, "Perch%s" % "ABCDE"[i], Vector2(perch_x[i], rest_y),
			{"wisp": wisp, "interact_offset": call_offset}))
	var perch_f := inst(PUZZLE + "wisp_perch.tscn", room, "PerchF", Vector2(8704, rest_y),
		{"wisp": wisp, "interact_offset": Vector2(-24, FLOOR_Y - rest_y),
		"extra_call_offsets": PackedVector2Array([Vector2(8330 - 8704, FLOOR_Y - rest_y)])})
	wisp.set("start_perch", perches[0])
	var hidden: Array = []
	for i in 4:
		hidden.append(inst(PUZZLE + "spectral_platform.tscn", room, "HiddenPath%d" % (i + 1),
			Vector2(7776 + i * 128, FLOOR_Y), {"mode": 1, "size": Vector2(64, 12)}))

	inst(TRAPS + "crumbling_platform.tscn", room, "Crumble1", Vector2(8416, FLOOR_Y - 18))
	inst(TRAPS + "crumbling_platform.tscn", room, "Crumble2", Vector2(8544, FLOOR_Y - 18))

	var crystal := inst(PUZZLE + "light_receiver.tscn", room, "BridgeCrystal", Vector2(8740, 478))
	var bridge := inst(PUZZLE + "spectral_platform.tscn", room, "LightBridge", Vector2(8768, FLOOR_Y), {"size": Vector2(256, 12)})
	var bridge_circuit := circuit(room, "BridgeCircuit", [crystal], [bridge], {"channel_y": 500.0, "symbol": 1, "solved_sound": ""})

	var lever := inst(PUZZLE + "lever.tscn", room, "WalkwayLever", Vector2(cx(142), FLOOR_Y),
		{"one_way": true, "persist_id": "ch1.r6.walkway"})
	var walkway: Array = []
	for span in [[7744, 512], [8384, 256], [8768, 256]]:
		walkway.append(inst(PUZZLE + "spectral_platform.tscn", room, "Walkway%d" % walkway.size(),
			Vector2(span[0], 566), {"size": Vector2(span[1], 12)}))
	circuit(room, "WalkwayCircuit", [lever], walkway,
		{"channel_y": 430.0, "symbol": 2, "reveal_target": true, "solved_sound": ""})
	guide(room, "Cross the chasm by lantern light.")
	step(room, "The wisp answers your call", Cond.MOVED, wisp)
	step(room, "Across to the island", Cond.REACHED, null, {"area": Rect2(8290, 470, 120, 70)})
	step(room, "The light bridge rises", Cond.POWERED, bridge_circuit)
	step(room, "Over the last chasm", Cond.REACHED, null, {"area": Rect2(9030, 470, 180, 70)})
	step(room, "The walkway back is raised", Cond.FLAG, null, {"flag": "ch1.r6.walkway", "optional": true})
	page_step(room, 6)

	hint(room, Vector2(cx(118), FLOOR_Y), [
		"Look at the wisp, the rune brackets over the chasm, and the faint outlines between them.",
		"The outlines turn solid inside the wisp's light, and the wisp flies to whichever bracket you call it to.",
		"Stand on a lit platform and call the wisp to the next bracket ahead (the rune stone at your feet). Step forward once its light reaches the next platform.",
	], [wisp] + perches.slice(1, 3) + hidden.slice(0, 2))
	page(room, 6, Vector2(8576, 470), "The Bellkeeper's Ledger, vi",
		"The wisps were lamplighters once. They still go where they are called, and they still do not like to be hurried.")

	var signs := group(room, "Signs")
	add_sign(signs, "Wisp", 120, "Call the wisp from a rune stone with {interact}. Hidden paths turn solid in its light.", FLOOR_Y, 200.0)
	add_sign(signs, "Crumble", 130, "Cracked ledges give way. Keep moving.", FLOOR_Y, 150.0)
	add_sign(signs, "Crystal", 136, "Crystals drink the wisp's light too.", FLOOR_Y, 150.0)
	add_sign(signs, "Walkway", 142.5, "This lever raises a walkway for the way back.", FLOOR_Y, 160.0)

	var deco := group(room, "Decor")
	for c in [118, 125, 130, 136, 143]:
		torch(deco, c)
	decor(123, 5, W_WINDOW_MOON)
	decor(133, 5, W_WINDOW_DOUBLE)
	decor(139, 5, W_VINES_FULL)
	prop(deco, "chain_short", cx(122), 272, true)
	prop(deco, "vine_thin", cx(127), 266, true)
	prop(deco, "chain_hook_ball", cx(138), 272, true)
	prop(deco, "bat", cx(132), 266, true)
	prop(deco, "wisps_dark_small", cx(126), 420)
	return


# ---------------------------------------------------------------- Room 7
# The Sealed Belfry (tall). Everything together: light the belfry brazier
# (fireball) whose beam runs at y 372 into a barred window (gate G1) above a
# doorway in a stone partition. Turn the hanging mirror so the beam will
# fall on the heavy plate. Ring the bell: the slime in the grated cell sits on
# plate A, the window opens, light reaches the mirror and falls on the plate;
# the gargoyle freezes there when it walks through. The heavy plate wakes the
# rune seal (runes light in turn, the bell tolls) and the great door opens.
# The solved seal also keeps the window open, so the watcher stays stone.

func room_7_belfry() -> void:
	# (Its far wall has a doorway on to the Choir Loft)
	shell(144, 173, HIGH_CEIL)
	# A partition wall with a doorway below and a barred window above it
	# (the window is the gate G1)
	for y in range(0, 5):
		solid(154, y)
	ceiling.erase_cell(Vector2i(154, 0))
	for y in range(0, 6):
		solid(168, y)
	ceiling.erase_cell(Vector2i(168, 0))
	var room := make_room("R7", "The Sealed Belfry", 144, 173, HIGH_CEIL, Vector2(9300, 530), true)
	grated_cell(room, 147, 150)
	var beam_y := 372.0

	inst(PUZZLE + "chapter_checkpoint.tscn", room, "Shrine", Vector2(cx(145), FLOOR_Y), {"checkpoint_id": "ch1.cp.finale"})
	# Hung on a wall shelf with nothing below, so it can be shot from the floor
	var brazier := inst(PUZZLE + "brazier.tscn", room, "BelfryFlame", Vector2(145 * T + 20, 406),
		{"beam_direction": Vector2.RIGHT, "wall_side": -1, "bracket_length": 6.0})
	# The slime listens longer here: the watcher needs time to walk into the light
	slime(room, "BellSlime", Vector2(cx(148), 596), {"investigate_time": 12.0, "warded": true})
	var plate_a := inst("res://scenes/pressure_plate.tscn", room, "BellPlate", Vector2(cx(150), 598))
	var bell := inst(PUZZLE + "puzzle_bell.tscn", room, "Bell", Vector2(cx(150), 420),
		{"chain_length": 382.0, "pull_offset": Vector2(80, 54), "cooldown": 2.0})
	var bars := inst("res://scenes/portcullis_gate.tscn", room, "BarredWindow", Vector2(cx(154), 384),
		{"height": 64.0, "open_visible": 8.0, "close_delay": 0.4})
	var mirror := inst(PUZZLE + "mirror.tscn", room, "BelfryMirror", Vector2(cx(160), beam_y),
		{"facing": 0, "hanging": true, "post_length": beam_y - 16.0, "interact_offset": Vector2(9960 - cx(160), FLOOR_Y - beam_y)})
	var plate := inst("res://scenes/pressure_plate.tscn", room, "HeavyPlate", Vector2(cx(160), FLOOR_Y),
		{"stone_only": true, "width": 48.0})
	inst(CREATURES + "watcher_gargoyle.tscn", room, "Watcher", Vector2(10420, FLOOR_Y),
		{"patrol_min_x": 10096.0, "patrol_max_x": 10448.0, "walk_speed": 55.0, "start_facing": -1})
	var great_door := gate(room, "GreatDoor", 168)
	var seal := inst(PUZZLE + "rune_seal.tscn", room, "RuneSeal", Vector2(cx(168), 384))
	seal.set("targets", nodes([great_door]))
	circuit(room, "WindowCircuit", [plate_a, seal], [bars], {"mode": 1, "channel_y": 330.0, "symbol": 1, "solved_sound": ""})
	circuit(room, "SealCircuit", [plate], [seal],
		{"hold_time": 0.5, "persist_id": "ch1.r7.solved", "channel_y": 460.0, "symbol": 0, "solved_sound": ""})
	guide(room, "Break the seal on the great door.", "IV", "The Belfry")
	step(room, "The belfry flame burns", Cond.POWERED, brazier)
	step(room, "The mirror looks down on the heavy plate", Cond.PROPERTY, mirror, {"property": "facing", "value": 2})
	step(room, "The barred window opens", Cond.OPEN, bars)
	step(room, "The seal breaks", Cond.OPEN, seal)
	page_step(room, 7)

	hint(room, Vector2(cx(152), FLOOR_Y), [
		"Look at the belfry flame, the barred window high in the wall, the hanging mirror, the bell and the heavy plate.",
		"The flame's light must pass the barred window to reach the mirror. The window opens only while the plate beneath the bell is held.",
		"Light the flame with a fireball and turn the mirror until its light falls on the heavy plate. Then ring the bell: the slime holds the window open while the watcher walks into the light.",
	], [brazier, bars, mirror, bell, plate])
	page(room, 7, Vector2(cx(170), 500), "The Bellkeeper's Ledger, vii",
		"If you are reading this, the seal has answered you. Ring the great bell once for me, stranger. It has been so quiet.")

	var signs := group(room, "Signs")
	add_sign(signs, "Belfry", 153, "The seal answers only to the watcher's weight.", FLOOR_Y, 160.0)
	add_sign(signs, "MirrorControl", 156, "Turn the high mirror from here with {interact}.", FLOOR_Y, 150.0)

	var deco := group(room, "Decor")
	for c in [145, 152, 158, 165, 170]:
		torch(deco, c)
	for c in [149, 157, 163, 171]:
		torch(deco, c, 1)
	decor(160, 1, W_WINDOW_MOON)
	decor(148, 5, W_BANNER_CROSS)
	decor_standing(162, W_ARCHES_BOTTOM, W_ARCHES_TOP)
	decor(172, 5, W_BANNER_FLEUR)
	prop(deco, "chain_short", cx(156), 16, true)
	prop(deco, "cobweb_corner", cx(172) + 8, 12, true, true)
	prop(deco, "skull_pile", cx(166), FLOOR_Y)
	prop(deco, "candelabra", cx(172), FLOOR_Y)
	puddle(deco, cx(169), 80.0)
	return


# ---------------------------------------------------------------- Room 8
# The Choir Loft. Two spring levers 768 px apart; each springs back 2.5 s
# after it is pulled. The loft gate opens (and stays open) only while both
# are down at once. Sprinting from one to the other takes 3.5 s, so one witch
# can't do it: record an Echo at one lever (wait a moment, then pull), and
# while it replays, pull the other as your Echo pulls its own. Echoes can
# pull levers, ring bells and turn mirrors, just as they can hold plates.

func room_8_choir() -> void:
	shell(173, 195, LOW_CEIL)
	var room := make_room("R8", "The Choir Loft", 173, 195, LOW_CEIL, Vector2(cx(174), 530))
	var lever_a := inst(PUZZLE + "lever.tscn", room, "LeverA", Vector2(cx(176), FLOOR_Y), {"spring_time": 2.5})
	var lever_b := inst(PUZZLE + "lever.tscn", room, "LeverB", Vector2(cx(188), FLOOR_Y), {"spring_time": 2.5})
	var loft_gate := gate(room, "LoftGate", 192)
	circuit(room, "ChoirCircuit", [lever_a, lever_b], [loft_gate],
		{"latch": true, "reveal_target": true, "persist_id": "ch1.r8.solved", "channel_y": 420.0, "symbol": 2})
	guide(room, "Open the loft gate.")
	step(room, "Both levers down at once: the gate opens", Cond.OPEN, loft_gate)

	hint(room, Vector2(cx(174) + 24, FLOOR_Y), [
		"Look at the two levers and the loft gate.",
		"The gate opens only while both levers are down at the same moment, and each lever springs back. They are too far apart for one witch.",
		"Stand by one lever and record an Echo: wait a moment, pull the lever, stop recording. Then run to the other lever and pull it just as your Echo pulls its own.",
	], [lever_a, lever_b, loft_gate])

	var signs := group(room, "Signs")
	add_sign(signs, "Choir", 178.5, "Echoes do what you did: they pull levers, ring bells and turn mirrors too.", FLOOR_Y, 200.0)
	add_sign(signs, "Spring", 182.5, "These levers spring back after a moment.", FLOOR_Y, 150.0)

	var deco := group(room, "Decor")
	for c in [175, 180, 185, 190]:
		torch(deco, c)
	decor(177, 5, W_WINDOW_DOUBLE)
	decor(183, 5, W_BANNER_CROSS)
	decor(189, 5, W_WINDOW_BARRED)
	decor_standing(186, W_ARCHES_BOTTOM, W_ARCHES_TOP)
	prop(deco, "chain_short", cx(179), 272, true)
	prop(deco, "cobweb_corner", cx(194) + 8, 268, true, true)
	prop(deco, "candelabra", cx(191), FLOOR_Y)
	puddle(deco, cx(182), 128.0)


# ---------------------------------------------------------------- Room 9
# The Great Bell (tall). The bell hangs over a high balcony (y 214). Spectral
# stairs rise to it only while the plate at the foot of the tower is held, so
# an Echo must stand on the plate while Echidna climbs.

func room_9_great_bell() -> void:
	shell(195, 215, HIGH_CEIL, false, true)
	# The balcony starts right after the top stair
	for x in range(207, 215):
		floor_tile(x, 3)
	var room := make_room("R9", "The Great Bell", 195, 215, HIGH_CEIL, Vector2(cx(196), 530))
	var plate := inst("res://scenes/pressure_plate.tscn", room, "Plate", Vector2(cx(198), FLOOR_Y))
	var stairs: Array = []
	for i in 6:
		stairs.append(inst(PUZZLE + "spectral_platform.tscn", room, "Stair%d" % (i + 1),
			Vector2(201 * T + i * 64, 486 - i * 48), {"size": Vector2(64, 12)}))
	circuit(room, "StairsCircuit", [plate], stairs, {"channel_y": 510.0, "symbol": 3, "solved_sound": ""})
	# The chapter ends when its rope is pulled (the rope reaches the balcony)
	var great_bell := inst(PUZZLE + "great_bell.tscn", room, "GreatBell", Vector2(cx(211), 94))
	guide(room, "Climb to the great bell and ring it.")
	step(room, "Something holds the plate: the stairs rise", Cond.POWERED, plate)
	step(room, "Up to the great bell", Cond.REACHED, null, {"area": Rect2(208 * T, 150, 7 * T, 70)})
	step(room, "The great bell rings", Cond.POWERED, great_bell)

	hint(room, Vector2(cx(196) + 24, FLOOR_Y), [
		"Look at the plate, the faint stairs and the balcony above.",
		"The stairs stand only while the plate is held, and you can't hold it and climb at once.",
		"Record an Echo walking onto the plate and stop. When it finishes it stays there, holding the plate: climb while it does.",
	], [plate] + stairs.slice(0, 2))

	var signs := group(room, "Signs")
	add_sign(signs, "Bell", 199.5, "The great bell. Something must hold the plate while you climb.", FLOOR_Y, 180.0)

	var deco := group(room, "Decor")
	for c in [196, 200, 205]:
		torch(deco, c)
	for c in [199, 206, 212]:
		torch(deco, c, 1)
	decor(202, 1, W_WINDOW_MOON)
	decor(210, 1, W_WINDOW_MOON)
	decor(197, 5, W_BANNER_FLEUR)
	prop(deco, "chain_short", cx(211), 16, true)
	prop(deco, "chain_hook_ball", cx(203), 16, true)
	prop(deco, "skull_pile", cx(204), FLOOR_Y)
	prop(deco, "cobweb_corner", cx(214) + 8, 12, true, true)


# ================================================================ player + UI

func place_player_and_ui() -> void:
	var player := inst("res://scenes/Player.tscn", level, "Player", Vector2(380, 530),
		{"z_index": 1, "collision_mask": 2})
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.set_script(load("res://scripts/camera_bounds.gd"))
	camera.set("bounds", rooms["R1"].bounds)
	camera.set("base_zoom", Vector2(2, 2))
	camera.zoom = Vector2(2, 2)
	add_owned(player, camera)
	var aura := light(256, Color(0.78, 0.72, 1.0), 0.95, 1.0)
	aura.name = "PlayerLight"
	aura.position = Vector2(0, -20)
	add_owned(player, aura)

	var post := CanvasLayer.new()
	post.name = "PostFX"
	post.layer = 1
	post.set_script(load("res://scripts/post_fx.gd"))
	add_owned(level, post)
	var screen := ColorRect.new()
	screen.name = "Screen"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/dungeon_post.gdshader")
	mat.set_shader_parameter("fog_floor_y", float(FLOOR_Y))
	screen.material = mat
	add_owned(post, screen)

	inst("res://scenes/hud.tscn", level, "HUD", Vector2.ZERO)
	inst("res://scenes/ammo_ui.tscn", level, "AmmoUI", Vector2.ZERO)
	var death_ui := CanvasLayer.new()
	death_ui.name = "DeathUI"
	death_ui.layer = 2
	add_owned(level, death_ui)
	var death_screen: Node = load("res://scenes/death_screen.tscn").instantiate()
	add_owned(death_ui, death_screen)
	var pause := CanvasLayer.new()
	pause.name = "PauseMenu"
	pause.set_script(load("res://scripts/ui/pause_menu.gd"))
	add_owned(level, pause)
