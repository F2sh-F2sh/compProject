extends "res://tools/build_chapter.gd"

## Generates Chapter 2, "The Sealed Observatory": the rune-cube chapter.
## Reuses the Chapter 1 builder's tiles, rooms, gates, circuits and guidance
## helpers, and writes one scene per rune piece (scenes/runes) plus the level
## scenes/chapter/chapter_2.tscn.
##
##   godot --headless --path . --script res://tools/build_chapter2.gd
##
## Wind tuning the rooms rely on (scripts/runes/rune_book.gd, wind_body.gd):
##   one normal wind 1200, a strong one 2400, reach 320 px (Long 560),
##   width 96 px (Large 288); a crate needs 490 to start sliding, a stone
##   block 1470, a statue 2940. So one wind moves a crate but not a stone
##   block; two overlapping winds (or a strong one) move the stone block.

const OUT_PATH_2 := "res://scenes/chapter/chapter_2.tscn"
const RUNES := "res://scenes/runes/"
const PREFIX := "ch2"

## The watcher room keeps its dark (see MOOD_AMBIENT in build_chapter.gd).
const MOOD_AMBIENT_2 := {"R6": 0.5}
const MOODS_2 := {
	"R1": [Color(0.98, 1.03, 1.1), Color(0.25, 0.34, 0.5)],
	"R2": [Color(1.0, 1.03, 1.08), Color(0.26, 0.35, 0.48)],
	"R3": [Color(0.96, 1.04, 1.1), Color(0.24, 0.36, 0.5)],
	"R4": [Color(1.02, 1.02, 1.06), Color(0.3, 0.32, 0.46)],
	"R5": [Color(0.94, 1.04, 1.12), Color(0.22, 0.36, 0.52)],
	"R6": [Color(1.06, 1.04, 0.96), Color(0.34, 0.33, 0.4)],
	"R7": [Color(1.03, 0.99, 1.1), Color(0.33, 0.3, 0.5)],
	"R8": [Color(1.05, 1.0, 1.1), Color(0.34, 0.3, 0.52)],
}


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		rng.seed = 2207
		build_rune_components()
		ts = load(TILESET_PATH)
		build_level()
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://scenes/chapter"))
		save_scene(level, OUT_PATH_2)
		level.free()
		print("BUILD CHAPTER 2 OK")
		quit()
	return false


func build_rune_components() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RUNES))
	var table := [
		[RUNES + "rune_cube.tscn", "RuneCube", Node2D, "res://scripts/runes/rune_cube.gd"],
		[RUNES + "wind_body.tscn", "WindBody", CharacterBody2D, "res://scripts/runes/wind_body.gd"],
		[RUNES + "rune_tablet.tscn", "RuneTablet", Node2D, "res://scripts/runes/rune_tablet.gd"],
		[RUNES + "rune_lectern.tscn", "RuneLectern", Node2D, "res://scripts/runes/rune_lectern.gd"],
		[RUNES + "rune_manager.tscn", "RuneManager", Node2D, "res://scripts/runes/rune_manager.gd"],
		[RUNES + "cracked_wall.tscn", "CrackedWall", StaticBody2D, "res://scripts/runes/cracked_wall.gd"],
		[RUNES + "burnable.tscn", "Burnable", StaticBody2D, "res://scripts/runes/burnable.gd"],
		[RUNES + "rune_pedestal.tscn", "RunePedestal", Node2D, "res://scripts/runes/rune_pedestal.gd"],
		[RUNES + "observatory_seal.tscn", "ObservatorySeal", Node2D, "res://scripts/runes/observatory_seal.gd"],
	]
	for row in table:
		var node: Node = row[2].new()
		node.name = row[1]
		node.set_script(load(row[3]))
		save_scene(node, row[0])
		node.free()


func build_level() -> void:
	level = Node2D.new()
	level.name = "Chapter2"
	level.set_script(load("res://scripts/puzzle/chapter_root.gd"))
	level.set("chapter_id", PREFIX)
	level.set("chapter_title", "The Sealed Observatory")
	level.set("unit_name", "level")
	level.set("complete_heading", "LEVEL 3 COMPLETE")
	level.set("next_chapter", "res://scenes/story/interlude_dome.tscn")
	level.set("next_label", "Continue: the way down")
	level.set("total_pages", 0)

	var ambient := CanvasModulate.new()
	ambient.name = "Darkness"
	ambient.color = AMBIENT
	add_owned(level, ambient)

	background = tile_layer("Background", Vector2(0, 22), Color(0.88, 0.86, 0.99), -10, false, false)
	back_decor = tile_layer("BackDecor", Vector2(0, 22), Color(1.0, 1.0, 1.0), -9, false, false)
	earth = tile_layer("Earth", Vector2.ZERO, Color(0.73, 0.69, 0.84))
	ceiling = tile_layer("Ceiling", Vector2(0, -4))
	ground = tile_layer("Ground")
	ground_half = tile_layer("GroundHalf", Vector2(0, 32))

	room_1_broken_inscription()
	room_2_too_heavy()
	room_3_across_the_teeth()
	room_4_fractured_seal()
	room_5_frozen_crossing()
	room_6_watchers_lock()
	room_7_limited_circuit()
	room_8_sealed_observatory()
	place_atmosphere_2()
	place_player_and_ui()
	# Last, so its screens get input before the pause menu
	var manager := inst(RUNES + "rune_manager.tscn", level, "RuneManager", Vector2.ZERO)
	manager.set("starting_fragments", PackedStringArray(["wind", "push", "left", "normal"]))


func place_atmosphere_2() -> void:
	var atmos := Node2D.new()
	atmos.name = "Atmosphere"
	atmos.set_script(load("res://scripts/fx/dungeon_atmosphere.gd"))
	atmos.set("wall_path", NodePath("../Background"))
	atmos.set("decor_path", NodePath("../BackDecor"))
	var breaches: Array[Rect2i] = [
		Rect2i(4, 4, 3, 2), Rect2i(13, 4, 2, 2),           # R1
		Rect2i(23, 4, 3, 2), Rect2i(34, 4, 3, 2),          # R2
		Rect2i(42, 0, 3, 3), Rect2i(53, 0, 3, 2),          # R3 (tall)
		Rect2i(62, 4, 3, 2), Rect2i(74, 4, 2, 2),          # R4
		Rect2i(81, 4, 3, 2), Rect2i(93, 4, 3, 2),          # R5
		Rect2i(104, 4, 2, 2), Rect2i(115, 4, 3, 2),        # R6
		Rect2i(126, 4, 3, 2), Rect2i(139, 4, 2, 2),        # R7
		Rect2i(147, 0, 3, 3), Rect2i(158, 0, 4, 2),        # R8 (tall)
	]
	atmos.set("breaches", breaches)
	atmos.set("reference_center", Vector2(83 * T, 400))
	atmos.set("seed", 11)
	add_owned(level, atmos)


func make_room_2(id: String, title: String, x0: int, x1: int, ceil_row: int, entry: Vector2, deep := false) -> Node2D:
	var bounds := Rect2(x0 * T, (ceil_row - 2) * T, (x1 + 1 - x0) * T, (10 if deep else 9) * T - (ceil_row - 2) * T)
	var room := inst(PUZZLE + "room.tscn", level, id, Vector2.ZERO, {
		"room_id": PREFIX + "." + id.to_lower(),
		"title": title,
		"bounds": bounds,
		"entry_spawn": entry,
		"mood_highlight": MOODS_2[id][0],
		"mood_fog": MOODS_2[id][1],
		"mood_ambient": MOOD_AMBIENT_2.get(id, 1.0),
	})
	rooms[id] = room
	var zone := Area2D.new()
	zone.name = "Acoustics"
	zone.set_script(load("res://scripts/audio/reverb_zone.gd"))
	zone.position = bounds.position
	zone.set("size", bounds.size)
	zone.set("acoustics", 2 if ceil_row == HIGH_CEIL else 0)
	add_owned(room, zone)
	return room


# ---------------------------------------------------------------- rune pieces

## A rune cube standing on the floor (or a ledge) at world x.
func cube(parent: Node, cube_name: String, x: float, recipe: String, props := {}, surface := float(FLOOR_Y)) -> Node:
	var p := {"start_recipe": recipe, "display_name": cube_name}
	p.merge(props, true)
	return inst(RUNES + "rune_cube.tscn", parent, cube_name.to_pascal_case().replace(" ", ""), Vector2(x, surface), p)


func crate(parent: Node, crate_name: String, x: float, props := {}, surface := float(FLOOR_Y)) -> Node:
	return inst(RUNES + "wind_body.tscn", parent, crate_name, Vector2(x, surface), props)


func stone(parent: Node, stone_name: String, x: float, props := {}, surface := float(FLOOR_Y)) -> Node:
	var p := {"weight": 1, "size": Vector2(48, 48)}
	p.merge(props, true)
	return inst(RUNES + "wind_body.tscn", parent, stone_name, Vector2(x, surface), p)


func tablet(parent: Node, fragment: String, x: float, text: String, surface := float(FLOOR_Y)) -> Node:
	return inst(RUNES + "rune_tablet.tscn", parent, "Tablet" + fragment.to_pascal_case(), Vector2(x, surface),
		{"fragment": StringName(fragment), "text": text})


func plate(parent: Node, plate_name: String, x: float, props := {}) -> Node:
	return inst("res://scenes/pressure_plate.tscn", parent, plate_name, Vector2(x, FLOOR_Y), props)


const LOCK_ESSENCE := 1
const LOCK_FORM := 2
const LOCK_DIRECTION := 4
const LOCK_MODIFIER := 8


# ---------------------------------------------------------------- Room 1
# The Broken Inscription. A dungeon-powered cube whose Direction quadrant is
# broken. The tablet beside it teaches Right; with it the cube's wind blows
# the crate along the floor onto a plate that only loose objects press. A
# +32 kerb stops the crate on the plate.

func room_1_broken_inscription() -> void:
	shell(0, 18, LOW_CEIL, true, false)
	curb(13)
	var room := make_room_2("R1", "The Broken Inscription", 0, 18, LOW_CEIL, Vector2(cx(2), 530))
	waymarks(room, 0, 18)

	inst(PUZZLE + "chapter_checkpoint.tscn", room, "Shrine", Vector2(cx(2), FLOOR_Y), {"checkpoint_id": "ch2.cp.start"})
	var tab := tablet(room, "right", cx(4), "The wind obeys the arrow carved beside it.")
	var c := cube(room, "Broken Cube", cx(6), "wind/push/-/normal",
		{"dungeon_powered": true, "carryable": false, "locked_slots": LOCK_ESSENCE | LOCK_FORM | LOCK_MODIFIER})
	var box := crate(room, "Crate", cx(8))
	var p := plate(room, "CratePlate", 790.0, {"objects_only": true})
	var exit_gate := gate(room, "ExitGate", 18)
	circuit(room, "PlateToGate", [p], [exit_gate],
		{"reveal_target": true, "persist_id": "ch2.r1.solved", "channel_y": 440.0, "symbol": 0})
	guide(room, "Open the gate at the far end.", "I", "The Wind", "The Novices' Way  ·  Level 3  ·  The Sealed Observatory")
	room.set("explainer", "runes")
	step(room, "A new fragment learned", Cond.FLAG, null, {"flag": "rune.frag.right"})
	step(room, "The mended rune blows", Cond.POWERED, c)
	step(room, "The crate on the plate: the gate opens", Cond.OPEN, exit_gate)

	hint(room, Vector2(cx(1) + 20, FLOOR_Y), [
		"Use the cube to look at its rune. One quadrant is broken.",
		"The crate has to reach the plate, and the cube blows wind. Which way should it blow?",
		"Read the tablet to learn Right. Inscribe Right in the broken quadrant, then switch the cube on.",
	], [c, tab, box])

	var signs := group(room, "Signs")
	add_sign(signs, "Cube", 5, "Rune cubes: {interact} to read and inscribe the rune.", FLOOR_Y, 180.0)

	var deco := group(room, "Decor")
	for col in [3, 10, 16]:
		torch(deco, col)
	decor(7, 5, W_WINDOW_DOUBLE)
	decor(14, 5, W_BANNER_FLEUR)
	decor_standing(17, W_ARCHES_BOTTOM, W_ARCHES_TOP)
	prop(deco, "cobweb_corner", 64 + 32, 268, true)
	prop(deco, "chain_short", cx(9), 272, true)
	prop(deco, "rocks_a", cx(15), FLOOR_Y)
	puddle(deco, cx(16) + 16, 72.0)


# ---------------------------------------------------------------- Room 2
# Too Heavy for One. A fixed cube blows right at a stone block and cannot
# shift it alone (it strains and grinds). A second cube waits past the plate,
# blowing left; carry it back, turn it to blow Right beside the first, and
# the two winds together slide the stone onto the stone-only plate.

func room_2_too_heavy() -> void:
	shell(18, 40, LOW_CEIL)
	curb(30)
	var room := make_room_2("R2", "Too Heavy for One", 18, 40, LOW_CEIL, Vector2(cx(19), 530))
	waymarks(room, 18, 40)

	var fixed := cube(room, "Fixed Cube", cx(22), "wind/push/right/normal",
		{"dungeon_powered": true, "carryable": false, "locked_slots": 15})
	var block := stone(room, "Stone", cx(25))
	var p := plate(room, "StonePlate", 1872.0, {"stone_only": true, "width": 48.0})
	var loose := cube(room, "Loose Cube", cx(35), "wind/push/left/normal", {"dungeon_powered": true})
	var exit_gate := gate(room, "ExitGate", 40)
	circuit(room, "PlateToGate", [p], [exit_gate],
		{"reveal_target": true, "persist_id": "ch2.r2.solved", "channel_y": 440.0, "symbol": 1})
	guide(room, "Move the stone block onto the heavy plate.")
	step(room, "One wind strains against the stone", Cond.POWERED, fixed)
	step(room, "The stone on the plate: the gate opens", Cond.OPEN, exit_gate)

	hint(room, Vector2(cx(20), FLOOR_Y), [
		"Switch on the fixed cube and watch the stone. It strains, but one wind isn't enough.",
		"Winds that overlap add up. There is another cube in this room.",
		"Carry the far cube ({rune_carry}) back beside the fixed one, inscribe Right, and switch both on.",
	], [fixed, block, loose])

	var signs := group(room, "Signs")
	add_sign(signs, "Carry", 33, "{rune_carry}: pick up a cube that is off, and set it down where its outline shows.", FLOOR_Y, 190.0)

	var deco := group(room, "Decor")
	for col in [21, 27, 32, 38]:
		torch(deco, col)
	decor(25, 5, W_WINDOW_BARRED)
	decor(36, 5, W_BANNER_CROSS)
	decor_standing(29, W_PILLAR)
	prop(deco, "skull_pile", cx(37), FLOOR_Y)
	puddle(deco, cx(32) + 16, 80.0)
	prop(deco, "chain_hook_ball", cx(24), 272, true)


# ---------------------------------------------------------------- Room 3
# Across the Teeth. A spiked pit, and past it a wall of stone whose top is
# far out of jumping reach. On a pillar in the pit stands a fixed cube, fed
# by the dungeon, carved "wind / push / up / large": Push can't blow up, so
# it won't start. A lectern at the pit's edge reaches it. Learn Lift from the
# tablet and the cube raises a wide updraft: float up and drift onto the wall.

func room_3_across_the_teeth() -> void:
	shell(40, 58, HIGH_CEIL)
	pit(46, 50)
	# The pillar in the middle of the pit
	ground.erase_cell(Vector2i(48, 9))
	floor_tile(48, 8)
	solid(48, 9)
	# The wall of stone beyond the pit, walkable on top (surface y 278)
	for x in range(51, 55):
		ground.erase_cell(Vector2i(x, 8))
		for y in range(5, 9):
			solid(x, y)
		floor_tile(x, 4)
	var room := make_room_2("R3", "Across the Teeth", 40, 58, HIGH_CEIL, Vector2(cx(41), 530))
	waymarks(room, 40, 58)
	var pit_floor := 598.0
	var candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleEdge", Vector2(cx(44), FLOOR_Y))
	inst("res://scenes/spike_trap.tscn", room, "PitSpikesL", Vector2(cx(46) + 32, pit_floor),
		{"spike_count": 4, "recovery_checkpoint": candle})
	inst("res://scenes/spike_trap.tscn", room, "PitSpikesR", Vector2(cx(49) + 32, pit_floor),
		{"spike_count": 4, "recovery_checkpoint": candle})

	var lift := cube(room, "Pit Cube", cx(48), "wind/push/up/large",
		{"dungeon_powered": true, "carryable": false, "mounted": true,
		"locked_slots": LOCK_ESSENCE | LOCK_DIRECTION | LOCK_MODIFIER})
	var lectern := inst(RUNES + "rune_lectern.tscn", room, "Lectern", Vector2(cx(45) - 8, FLOOR_Y))
	lectern.set("cube", lift)
	var tab := tablet(room, "lift", cx(42), "Air that rises carries what is light.")
	guide(room, "Get across the pit and onto the wall beyond.", "", "", "")
	step(room, "Lift learned", Cond.FLAG, null, {"flag": "rune.frag.lift"})
	step(room, "The updraft rises", Cond.POWERED, lift)
	step(room, "On top of the wall", Cond.REACHED, null, {"area": Rect2(51 * T, 200, 4 * T, 90)})

	hint(room, Vector2(cx(41) + 20, FLOOR_Y), [
		"The cube on the pillar is out of reach, but the lectern at the edge is carved to it.",
		"Its rune won't start: Push can't blow upward.",
		"Learn Lift from the tablet, inscribe it as the cube's Form, switch it on, then jump into the updraft and drift across.",
	], [lectern, lift, tab])

	var signs := group(room, "Signs")
	add_sign(signs, "Lectern", 43.5, "A lectern reaches the cube its groove leads to.", FLOOR_Y, 170.0)

	var deco := group(room, "Decor")
	for col in [41, 44]:
		torch(deco, col)
	for col in [43, 52, 56]:
		torch(deco, col, 1)
	decor(47, 1, W_WINDOW_MOON)
	decor(56, 5, W_BANNER_FLEUR)
	prop(deco, "chain_short", cx(46), 16, true)
	prop(deco, "cobweb_corner", cx(57) + 8, 12, true, true)


# ---------------------------------------------------------------- Room 4
# The Fractured Seal. A cracked wall closes the room. Only a heavy thing
# moving fast breaks it: the stone block, driven by a Strong wind (a normal
# wind can't even start it) along a run-up. This is the first cube with no
# channel under it: it runs on the player's own mana. The cube stands right
# behind the stone, so as soon as it is switched on with Strong its wind drives
# the stone the whole way into the wall: no carrying it closer first.

func room_4_fractured_seal() -> void:
	shell(58, 78, LOW_CEIL)
	var room := make_room_2("R4", "The Fractured Seal", 58, 78, LOW_CEIL, Vector2(cx(59), 530))
	waymarks(room, 58, 78)
	inst(PUZZLE + "chapter_checkpoint.tscn", room, "Shrine", Vector2(cx(60), FLOOR_Y), {"checkpoint_id": "ch2.cp.r4"})
	var tab := tablet(room, "strong", cx(61) + 16, "Twice the breath, twice the cost.")
	var c := cube(room, "Loose Cube", cx(65), "wind/push/right/normal")
	var block := stone(room, "Stone", cx(66))
	var wall := inst(RUNES + "cracked_wall.tscn", room, "CrackedWall", Vector2(cx(71), FLOOR_Y),
		{"size": Vector2(32, 262), "break_momentum": 640.0, "persist_id": "ch2.r4.wall"})
	guide(room, "Break through the cracked wall.", "II", "Stone and Frost", "The Novices' Way  ·  Level 3  ·  The Sealed Observatory")
	step(room, "Strong learned", Cond.FLAG, null, {"flag": "rune.frag.strong"})
	step(room, "The cracked wall gives way", Cond.OPEN, wall)

	hint(room, Vector2(cx(59) + 20, FLOOR_Y), [
		"The wall is cracked. Something heavy, moving fast, would break it.",
		"A normal wind can't even shift the stone. The tablet teaches Strong.",
		"Inscribe Strong on the cube and switch it on: its wind drives the stone along the floor into the wall. If the stone ever stops short, carry the cube right behind it and try again.",
	], [wall, block, c, tab])

	var signs := group(room, "Signs")
	add_sign(signs, "Mana", 63.0, "No channel under this cube: it draws on your own mana while it runs.", FLOOR_Y, 180.0)

	var deco := group(room, "Decor")
	for col in [62, 68, 74]:
		torch(deco, col)
	decor(66, 5, W_WINDOW_BARRED)
	decor(76, 5, W_BANNER_FLEUR)
	prop(deco, "rocks_a", cx(72), FLOOR_Y)
	puddle(deco, cx(68) + 16, 64.0)
	prop(deco, "chain_short", cx(65), 272, true)


# ---------------------------------------------------------------- Room 5
# The Frozen Crossing. A spiked pit too wide to jump. A cube is set into its
# near edge, its top flush with the floor, carved "ice / ? / right / long":
# learn Bridge and it throws a bridge of ice across for ten seconds (it costs
# mana once, when cast). A slime keeps the far side.

func room_5_frozen_crossing() -> void:
	shell(78, 100, LOW_CEIL)
	pit(86, 90)
	var room := make_room_2("R5", "The Frozen Crossing", 78, 100, LOW_CEIL, Vector2(cx(79), 530), true)
	waymarks(room, 78, 100)
	var candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleEdge", Vector2(cx(84), FLOOR_Y))
	inst("res://scenes/spike_trap.tscn", room, "PitSpikes", Vector2(5680, 598.0),
		{"spike_count": 9, "recovery_checkpoint": candle})
	var tab := tablet(room, "bridge", cx(81), "Cold that holds its shape can be walked on.")
	var c := cube(room, "Edge Cube", 5520.0, "ice/-/right/long",
		{"mounted": true, "carryable": false, "locked_slots": LOCK_ESSENCE | LOCK_DIRECTION | LOCK_MODIFIER}, 566.0)
	slime(room, "Slime", Vector2(cx(95), 530), {"hears_bells": false, "home_radius": 90.0, "max_health": 10})
	guide(room, "Cross the pit.")
	step(room, "Bridge learned", Cond.FLAG, null, {"flag": "rune.frag.bridge"})
	step(room, "The ice bridge forms", Cond.POWERED, c)
	step(room, "Across the pit", Cond.REACHED, null, {"area": Rect2(91 * T, 470, 9 * T, 70)})

	hint(room, Vector2(cx(79) + 20, FLOOR_Y), [
		"Too wide to jump. Look at the edge of the pit: a cube is set into the floor.",
		"Its rune has no form. The tablet teaches Bridge.",
		"Stand on the cube, inscribe Bridge, switch it on, and cross before the ice melts (ten seconds; it flickers near the end).",
	], [c, tab])

	var signs := group(room, "Signs")

	var deco := group(room, "Decor")
	for col in [80, 85, 92, 97]:
		torch(deco, col)
	decor(88, 5, W_WINDOW_MOON)
	decor(96, 5, W_BANNER_CROSS)
	prop(deco, "moss_drip_top", cx(88), 264, true)
	prop(deco, "skull_pile", cx(98), FLOOR_Y)
	puddle(deco, cx(96), 80.0)


# ---------------------------------------------------------------- Room 6
# The Watcher's Lock. Two heavy plates must be held at once. A cube hangs
# from the ceiling over plate A, carved "light / beam / ? / normal"; learn
# Down and its beam turns the patrolling watcher to stone the moment it
# walks under it, onto the plate. Plate B wants the stone block, which needs
# a Strong wind (or two). The gate is open while both are held (after 0.5 s).

func room_6_watchers_lock() -> void:
	shell(100, 122, LOW_CEIL)
	curb(118)
	var room := make_room_2("R6", "The Watcher's Lock", 100, 122, LOW_CEIL, Vector2(cx(101), 530))
	waymarks(room, 100, 122)
	inst(PUZZLE + "chapter_checkpoint.tscn", room, "Shrine", Vector2(cx(101) + 24, FLOOR_Y), {"checkpoint_id": "ch2.cp.r6"})
	var tab := tablet(room, "down", cx(103) + 24, "What falls from above finds what walks below.")
	var beam_cube := cube(room, "Ceiling Cube", 6912.0, "light/beam/-/normal",
		{"dungeon_powered": true, "mounted": true, "carryable": false,
		"locked_slots": LOCK_ESSENCE | LOCK_FORM | LOCK_MODIFIER}, 304.0)
	var lectern := inst(RUNES + "rune_lectern.tscn", room, "Lectern", Vector2(cx(102) + 16, FLOOR_Y))
	lectern.set("cube", beam_cube)
	var plate_a := plate(room, "PlateA", 6912.0, {"stone_only": true, "width": 48.0})
	var watcher := inst(CREATURES + "watcher_gargoyle.tscn", room, "Watcher", Vector2(7060, FLOOR_Y),
		{"patrol_min_x": 6800.0, "patrol_max_x": 7090.0, "walk_speed": 50.0, "start_facing": -1})
	var c := cube(room, "Loose Cube", cx(111), "wind/push/right/normal")
	var block := stone(room, "Stone", cx(113))
	var plate_b := plate(room, "PlateB", 7536.0, {"stone_only": true, "width": 48.0})
	var exit_gate := gate(room, "ExitGate", 122)
	circuit(room, "PlatesToGate", [plate_a, plate_b], [exit_gate],
		{"hold_time": 0.5, "reveal_target": true, "persist_id": "ch2.r6.solved", "channel_y": 440.0, "symbol": 2})
	guide(room, "Hold both heavy plates at once.", "III", "Light and Space", "The Novices' Way  ·  Level 3  ·  The Sealed Observatory")
	step(room, "Down learned", Cond.FLAG, null, {"flag": "rune.frag.down"})
	step(room, "The watcher turns to stone on the plate", Cond.POWERED, plate_a)
	step(room, "Both plates held: the gate opens", Cond.OPEN, exit_gate)

	hint(room, Vector2(cx(101) - 8, FLOOR_Y), [
		"Two heavy plates, and only stone presses them. The watcher is stone when light touches it.",
		"The cube in the ceiling holds a beam of light with no direction. The tablet teaches Down.",
		"Inscribe Down at the lectern: the watcher freezes on plate A as it walks under the beam. Then drive the stone onto plate B with a Strong wind.",
	], [beam_cube, plate_a, watcher, block, c, tab])

	var signs := group(room, "Signs")

	var deco := group(room, "Decor")
	for col in [102, 109, 115, 120]:
		torch(deco, col)
	decor(106, 5, W_WINDOW_DOUBLE)
	decor(117, 5, W_VINES_FULL)
	prop(deco, "gargoyle", cx(121) - 8, FLOOR_Y)
	prop(deco, "chain_hook_ball", cx(112), 272, true)


# ---------------------------------------------------------------- Room 7
# The Limited Circuit. A warding circle holds the player's mana to 10 here.
# The statue needs a Strong wind and a normal one together (3600 against its
# 2940 grip), but the strong rune needs 16 mana in hand to start (two seconds
# of its upkeep), more than she can hold here. A pedestal
# behind the statue feeds whatever cube stands in it; put the expensive
# rune there, and the normal one costs her 3 a second.

func room_7_limited_circuit() -> void:
	shell(122, 144, LOW_CEIL)
	curb(137)
	var room := make_room_2("R7", "The Limited Circuit", 122, 144, LOW_CEIL, Vector2(cx(123), 530))
	waymarks(room, 122, 144)
	room.set("mana_limit", 10)
	var strong_cube := cube(room, "Strong Cube", cx(124), "wind/push/right/strong", {"locked_slots": 15})
	var normal_cube := cube(room, "Normal Cube", cx(126), "wind/push/right/normal", {"locked_slots": 15})
	var pedestal := inst(RUNES + "rune_pedestal.tscn", room, "Pedestal", Vector2(cx(129), FLOOR_Y))
	var statue := stone(room, "Statue", cx(132), {"weight": 2, "size": Vector2(52, 48)})
	var p := plate(room, "StatuePlate", 8724.0, {"stone_only": true, "width": 60.0})
	var exit_gate := gate(room, "ExitGate", 144)
	circuit(room, "PlateToGate", [p], [exit_gate],
		{"reveal_target": true, "persist_id": "ch2.r7.solved", "channel_y": 440.0, "symbol": 3})
	guide(room, "Move the statue onto the heavy plate.")
	step(room, "A cube stands in the pedestal", Cond.PROPERTY, pedestal, {"property": "occupied", "value": 1})
	step(room, "The statue on the plate: the gate opens", Cond.OPEN, exit_gate)

	hint(room, Vector2(cx(123) + 20, FLOOR_Y), [
		"The statue needs both winds at once, and the warding here holds your mana to 10.",
		"The strong rune needs 16 mana in hand to start, and the warding holds you to 10. The pedestal pays for whatever stands in it.",
		"Put the Strong cube in the pedestal behind the statue, the Normal cube just behind the statue, and switch both on.",
	], [pedestal, strong_cube, normal_cube, statue])

	var signs := group(room, "Signs")
	add_sign(signs, "Ward", 123.5, "A warding circle: here your mana can't rise above 10.", FLOOR_Y, 170.0)
	add_sign(signs, "Pedestal", 128, "A pedestal pays for the cube standing in it.", FLOOR_Y, 160.0)

	var deco := group(room, "Decor")
	for col in [125, 131, 137, 142]:
		torch(deco, col)
	decor(128, 5, W_PLAQUE_CROSS)
	decor(140, 5, W_WINDOW_BARRED)
	prop(deco, "tombstone_rubble", cx(141), FLOOR_Y)
	puddle(deco, cx(139) + 16, 64.0)


# ---------------------------------------------------------------- Room 8
# The Sealed Observatory (finale). The seal waits on a balcony of stone far
# out of reach. A portal cube, carved "space / portal / ? / long": learn
# Up-Right and its doorway (just off the cube's upper-right corner) opens
# 253 px up and 253 px right. From where the cube starts, the far side opens
# in empty air; carried close to the balcony wall, it opens onto the
# balcony.

func room_8_sealed_observatory() -> void:
	shell(144, 166, HIGH_CEIL, false, true)
	for x in range(155, 166):
		ground.erase_cell(Vector2i(x, 8))
		for y in range(5, 9):
			solid(x, y)
		floor_tile(x, 4)
	var room := make_room_2("R8", "The Sealed Observatory", 144, 166, HIGH_CEIL, Vector2(cx(145), 530))
	waymarks(room, 144, 166, false)
	inst(PUZZLE + "chapter_checkpoint.tscn", room, "Shrine", Vector2(cx(146), FLOOR_Y), {"checkpoint_id": "ch2.cp.r8"})
	var tab := tablet(room, "up_right", cx(147) + 16, "Space folds where the arrow points.")
	var portal := cube(room, "Portal Cube", cx(149), "space/portal/-/long",
		{"locked_slots": LOCK_ESSENCE | LOCK_FORM | LOCK_MODIFIER})
	var seal := inst(RUNES + "observatory_seal.tscn", room, "Seal", Vector2(cx(160), 278.0))
	guide(room, "Reach the seal on the balcony.")
	step(room, "Up-Right learned", Cond.FLAG, null, {"flag": "rune.frag.up_right"})
	step(room, "Onto the balcony", Cond.REACHED, null, {"area": Rect2(155 * T, 180, 11 * T, 110)})
	step(room, "The seal opens", Cond.POWERED, seal)

	hint(room, Vector2(cx(145) + 20, FLOOR_Y), [
		"The balcony is far out of reach. The cube near the entrance holds a portal with no direction.",
		"The tablet teaches Up-Right. The portal's doorway is just off the cube's upper-right corner; its far side is up and to the right.",
		"From where it starts, the far side opens in the air. Carry the cube close to the balcony wall, then switch it on and jump into the doorway.",
	], [portal, tab, seal])

	var signs := group(room, "Signs")

	var deco := group(room, "Decor")
	for col in [146, 150]:
		torch(deco, col)
	for col in [148, 157, 163]:
		torch(deco, col, 1)
	decor(152, 1, W_WINDOW_MOON)
	decor(161, 1, W_WINDOW_MOON)
	prop(deco, "cobweb_corner", cx(165) + 8, 12, true, true)
	prop(deco, "chain_short", cx(158), 16, true)
	puddle(deco, cx(151), 64.0)
