extends "res://tools/build_chapter2.gd"

## Generates the rough loop after the Novices' Way: the Landing (the foot of
## the Long Stair), the four wings (two rooms each, ending in a bell) and the
## Eye (the great cube and the two endings). One scene each in
## res://scenes/chapter/: landing, wing_kiln, wing_cistern, wing_lamps,
## wing_galleries, eye. Reuses the Chapter 1 and 2 builders' tiles, rooms,
## gates, circuits, cubes and guidance helpers.
##
##   godot --headless --path . --script res://tools/build_wings.gd
##
## The puzzles are rough on purpose (see docs/STORY_PLAYTHROUGH.md for where
## they are meant to go): each wing's first room teaches its element with a
## cube sentence that her own spells cannot do, the second is a short combined
## room that ends at the wing's bell.

const WING_DIR := "res://scenes/chapter/"

## Per wing: [highlight tint, mist colour].
const WING_MOODS := {
	"landing": [Color(1.0, 1.02, 1.06), Color(0.3, 0.32, 0.5)],
	"kiln": [Color(1.1, 1.0, 0.9), Color(0.4, 0.32, 0.3)],
	"cistern": [Color(0.94, 1.04, 1.12), Color(0.22, 0.36, 0.52)],
	"lamps": [Color(1.06, 1.04, 0.96), Color(0.34, 0.33, 0.4)],
	"galleries": [Color(1.03, 0.99, 1.1), Color(0.33, 0.3, 0.5)],
	"eye": [Color(1.04, 1.06, 1.12), Color(0.36, 0.4, 0.55)],
}
const DOOR_TINTS := [Color(1.0, 0.7, 0.4), Color(0.5, 0.8, 1.0), Color(1.0, 0.92, 0.55), Color(0.8, 0.65, 1.0), Color(1.0, 1.0, 1.0)]

var _prefix := ""


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		build_rune_components()
		build_wing_components()
		ts = load(TILESET_PATH)
		var specs := [
			["landing", build_landing],
			["wing_kiln", build_kiln],
			["wing_cistern", build_cistern],
			["wing_lamps", build_lamps],
			["wing_galleries", build_galleries],
			["eye", build_eye],
		]
		for spec in specs:
			rng.seed = hash(spec[0])
			rooms = {}
			ledger = []
			spec[1].call()
			save_scene(level, WING_DIR + spec[0] + ".tscn")
			level.free()
			print("BUILT ", spec[0])
		print("BUILD WINGS OK")
		quit()
	return false


func build_wing_components() -> void:
	var table := [
		[PUZZLE + "landing_door.tscn", "LandingDoor", Node2D, "res://scripts/puzzle/landing_door.gd"],
		[RUNES + "eye_altar.tscn", "EyeAltar", Node2D, "res://scripts/runes/eye_altar.gd"],
		[PUZZLE + "great_kiln.tscn", "GreatKiln", Node2D, "res://scripts/puzzle/great_kiln.gd"],
		[PUZZLE + "forge_door.tscn", "ForgeDoor", Node2D, "res://scripts/puzzle/forge_door.gd"],
		[TRAPS + "slag_pool.tscn", "SlagPool", Area2D, "res://scripts/traps/slag_pool.gd"],
	]
	for row in table:
		var node: Node = row[2].new()
		node.name = row[1]
		node.set_script(load(row[3]))
		save_scene(node, row[0])
		node.free()


# ================================================================ scene frame

## Starts a scene: the chapter root, the ambient dark and the tile layers.
func begin(node_name: String, prefix: String, title: String, next_scene: String, words: Array) -> void:
	_prefix = prefix
	level = Node2D.new()
	level.name = node_name
	level.set_script(load("res://scripts/puzzle/chapter_root.gd"))
	level.set("chapter_id", prefix)
	level.set("chapter_title", title)
	level.set("unit_name", "wing")
	level.set("complete_heading", "THE BELL HAS RUNG")
	level.set("next_chapter", next_scene)
	level.set("next_label", "Continue")
	level.set("grants_words", PackedStringArray(words))
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


## Ends a scene: light shafts and cracks in the walls, the player and screens,
## and (last, so its screens get input first) the rune manager.
func finish(runes := true) -> void:
	var atmos := Node2D.new()
	atmos.name = "Atmosphere"
	atmos.set_script(load("res://scripts/fx/dungeon_atmosphere.gd"))
	atmos.set("wall_path", NodePath("../Background"))
	atmos.set("decor_path", NodePath("../BackDecor"))
	var breaches: Array[Rect2i] = []
	for id in rooms:
		var b: Rect2 = rooms[id].bounds
		var c0 := int(b.position.x / T)
		var c1 := int((b.position.x + b.size.x) / T)
		breaches.append(Rect2i(c0 + 4, 4, 3, 2))
		breaches.append(Rect2i(c1 - 7, 4, 3, 2))
	atmos.set("breaches", breaches)
	atmos.set("reference_center", Vector2(11 * T, 400))
	atmos.set("seed", 13)
	add_owned(level, atmos)
	place_player_and_ui()
	if runes:
		var manager := inst(RUNES + "rune_manager.tscn", level, "RuneManager", Vector2.ZERO)
		manager.set("starting_fragments", PackedStringArray(["wind", "push", "left", "normal"]))


## A room of this scene.
func mk_room(id: String, title: String, x0: int, x1: int, ceil_row: int, entry: Vector2, deep := false) -> Node2D:
	var bounds := Rect2(x0 * T, (ceil_row - 2) * T, (x1 + 1 - x0) * T, (10 if deep else 9) * T - (ceil_row - 2) * T)
	var mood: Array = WING_MOODS[_prefix]
	var room := inst(PUZZLE + "room.tscn", level, id, Vector2.ZERO, {
		"room_id": _prefix + "." + id.to_lower(),
		"title": title,
		"bounds": bounds,
		"entry_spawn": entry,
		"mood_highlight": mood[0],
		"mood_fog": mood[1],
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


## The room's checkpoint shrine.
func shrine(room: Node, id: String, x: float) -> Node:
	return inst(PUZZLE + "chapter_checkpoint.tscn", room, "Shrine", Vector2(x, FLOOR_Y), {"checkpoint_id": "%s.cp.%s" % [_prefix, id]})


## Torches and a window or two, so a room is not bare.
func dress(room: Node, x0: int, x1: int, torch_cols: Array) -> void:
	var deco := group(room, "Decor")
	for col in torch_cols:
		torch(deco, col)
	decor(x0 + 6, 5, W_WINDOW_BARRED)
	decor(x1 - 5, 5, W_BANNER_FLEUR)
	prop(deco, "skull_pile", cx(x1 - 2), FLOOR_Y)


## A wall of stone with a walkable top (surface y 278), cols a to b.
func stone_wall(a: int, b: int) -> void:
	for x in range(a, b + 1):
		ground.erase_cell(Vector2i(x, 8))
		for y in range(5, 9):
			solid(x, y)
		floor_tile(x, 4)


## The pit with its spikes and a candle at its edge (as in Chapter 2's Frozen Crossing).
func spiked_pit(room: Node, c0: int, c1: int, candle_col: int) -> void:
	pit(c0, c1)
	var candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleEdge", Vector2(cx(candle_col), FLOOR_Y))
	var centre := (c0 * T + (c1 + 1) * T) / 2.0 + 16.0
	inst("res://scenes/spike_trap.tscn", room, "PitSpikes", Vector2(centre, 598.0),
		{"spike_count": 9, "recovery_checkpoint": candle})


## A bridge of faint platforms over a pit, solid while the circuit is on.
func spectral_bridge(room: Node, c0: int, c1: int, source: Node, persist_id: String, symbol: int) -> Array:
	var platforms: Array = []
	for i in range(c0, c1 + 1):
		platforms.append(inst(PUZZLE + "spectral_platform.tscn", room, "Bridge%d" % (i - c0 + 1),
			Vector2(i * T, FLOOR_Y), {"size": Vector2(64, 12)}))
	circuit(room, "ToBridge", [source], platforms,
		{"latch": true, "reveal_target": true, "persist_id": persist_id, "channel_y": 440.0, "symbol": symbol})
	return platforms


## One bell, ending the wing: it names itself when rung.
func wing_bell(room: Node, x: float, bell_name: String, line: String) -> Node:
	return inst(PUZZLE + "great_bell.tscn", room, "GreatBell", Vector2(x, FLOOR_Y - 120.0),
		{"announce": bell_name, "announce_sub": line, "tolls": 2})


# ================================================================ the Landing

func build_landing() -> void:
	begin("Landing", "landing", "The Long Stair", "", [])
	shell(0, 31, LOW_CEIL, true, true)
	var room := mk_room("R1", "The Landing", 0, 31, LOW_CEIL, Vector2(cx(2), 530))
	shrine(room, "start", cx(2))
	kindle_flame(room, cx(4))
	var names := ["Kilnworks", "Cistern", "Lampworks", "Galleries", "The Eye"]
	for i in 5:
		inst(PUZZLE + "landing_door.tscn", room, "Door%d" % (i + 1), Vector2(cx(8 + i * 5), FLOOR_Y),
			{"index": i, "tint": DOOR_TINTS[i], "label_text": names[i]})
	guide(room, "Ring the bell in each of the four wings.", "", "", "")
	var signs := group(room, "Signs")
	add_sign(signs, "Choir", 5.6, "The Choir's last note: Four bells hold the Eye shut. Ring the Forge Bell first: its heat runs in the pipes behind every door and thaws the next.", FLOOR_Y, 210.0)
	add_sign(signs, "Chalk", 29.5, "A chalk star, and below it: don't be afraid of the cold. -W", FLOOR_Y, 170.0)
	room.set("glance_at", NodePath("Door1"))
	var chalk := group(room, "Chalk")
	for x in [cx(5) + 20, cx(6) + 20, cx(7) - 10]:
		deco_sprite(chalk, "chalk_steps", Vector2(x, FLOOR_Y), false, -1, true)
	dress(room, 0, 31, [3, 12, 22, 28])
	finish()


# ================================================================ the Kilnworks (fire)

## The Kilnworks' shadows are cold until the Great Kiln roars (it warms them).
const KILN_COLD := Color(0.44, 0.45, 0.62)
const KILN_ROAR_FLAG := "kiln.r1.kiln"


func build_kiln() -> void:
	begin("Kiln", "kiln", "The Kilnworks", Journey.KILN_INTERLUDE, Journey.WINGS[0]["words"])
	level.set("total_pages", 3)
	(level.get_node("Darkness") as CanvasModulate).color = KILN_COLD
	kiln_cold_forge()
	kiln_heart()
	ledger.sort_custom(func(a, b): return a["id"] < b["id"])
	level.set("ledger", ledger)
	finish()


## A run of floating ledge tiles; square ends where it meets a wall or another
## surface, rounded where it stops in the air.
func ledge_run(x0: int, x1: int, row: int, half := false, round_left := true, round_right := true) -> void:
	for x in range(x0, x1 + 1):
		var tile := CAP_MID
		if x0 != x1 and x == x0 and round_left:
			tile = CAP_LEFT
		elif x0 != x1 and x == x1 and round_right:
			tile = CAP_RIGHT
		(ground_half if half else ground).set_cell(Vector2i(x, row), 0, tile)


## A trench of molten slag over columns c0..c1 (one tile deep).
func slag_pool(room: Node, c0: int, c1: int, candle: Node) -> Node:
	pit(c0, c1)
	var centre := (c0 * T + (c1 + 1) * T) / 2.0
	return inst(TRAPS + "slag_pool.tscn", room, "Slag%d" % c0, Vector2(centre, 598.0),
		{"tiles": c1 - c0 + 1, "recovery_checkpoint": candle})


## A pixel sprite standing in the room (its foot at `pos`).
func deco_sprite(parent: Node, sprite_name: String, pos: Vector2, flip := false, z := -1, unshaded := false) -> Node:
	var n := Node2D.new()
	n.name = sprite_name.to_pascal_case() + str(parent.get_child_count())
	n.position = pos
	n.z_index = z
	n.set_script(load("res://scripts/puzzle/room_sprite.gd"))
	n.set("sprite_name", sprite_name)
	n.set("sprite_scale", 1.0)
	n.set("play", false)
	n.set("flip", flip)
	n.set("unshaded", unshaded)
	add_owned(parent, n)
	return n


## A patch of the Hush's frost on the wall that melts when the kiln roars.
func frost(parent: Node, pos: Vector2, which := "frost_a", flip := false) -> void:
	var n := Node2D.new()
	n.name = "Frost%d" % parent.get_child_count()
	n.position = pos
	n.set_script(load("res://scripts/fx/melting_frost.gd"))
	n.set("sprite_name", which)
	n.set("melt_flag", KILN_ROAR_FLAG)
	n.set("flip", flip)
	add_owned(parent, n)


## One of the Smith's ledger pages (the Kilnworks has three).
func kiln_page(parent: Node, id: int, pos: Vector2, title: String, text: String) -> void:
	inst(PUZZLE + "lore_page.tscn", parent, "LorePage%d" % id, pos,
		{"page_id": "kiln.page.%d" % id, "title": title, "text": text})
	var ids: PackedStringArray = parent.get("page_ids")
	ids.append("kiln.page.%d" % id)
	parent.set("page_ids", ids)
	ledger.append({"id": "kiln.page.%d" % id, "numeral": ["i", "ii", "iii"][id - 1],
		"title": title, "text": text, "room": parent.get("title")})


## THE COLD FORGE. The Smith's hall: a long room with a low entrance and a
## tall hall, the Great Kiln in the middle. The kiln wakes with coal, air and a
## bursting flame together (scripts/puzzle/great_kiln.gd); its heat opens the
## Forge Door to the rest of the wing. Fire rides wind: a bolt that flies into
## a current turns to follow it (FireBall), and that is how fire gets into the
## kiln, whose only way in is the pipe on its left side.
##
##   The Cold Hearth (cols 0-12): Fire and Projectile; the Forge Cube throws a
##     bolt further than she can, at brambles and then the pilot flame across
##     the slag: a bridge.
##   The Bellows Shaft (cols 19-20): a current of air rising out of a notch
##     (always on). It lifts her to the gallery, and any fire thrown into it:
##     up to the hanging brazier, which raises the bridge over the east slag.
##   The Smith's Bench (gallery, cols 13-16): the Explode tablet sealed behind
##     a plug of cold slag, a stone pressed against it and a cube whose words
##     are carved "wind, push". A steady wind only leans; a Strong Burst from a
##     cube with a free form (the loft's) drives the stone through.
##   The Coal Loft (cols 29-33): the coal cart behind brambles, the Burst
##     tablet and the Loft Cube. Push the cart west off the loft (onto the
##     bridge, or it burns in the slag), then push it into the kiln's fuel bay.
##   The Bellows Perch (col 17, under the gap in the gallery): the only place
##     a current blows into the kiln's pipe. A pedestal makes it free.
##   The ignition: the Bench Cube on the perch (Push Right) for air; the Loft
##     Cube on the floor below (Fire, Projectile, Right, Explode). Its bolt flies
##     into the shaft, rises, turns into the perch's current and rides it into
##     the pipe: the kiln roars and the Forge Door opens.
##   Optional: three ledger pages, the last in a cell above the loft that only
##     a Lift (fire riding it to burn the mat, then her riding it) reaches.
func kiln_cold_forge() -> void:
	shell(0, 12, LOW_CEIL, true, false)
	shell(12, 44, HIGH_CEIL, false, false)
	var room := mk_room("R1", "The Cold Forge", 0, 44, HIGH_CEIL, Vector2(cx(2), 530), true)
	var deco := group(room, "Decor")
	var signs := group(room, "Signs")

	# ---------------------------------------------------- the Cold Hearth
	shrine(room, "start", cx(2))
	kindle_flame(room, cx(3) + 8)
	var tab_fire := tablet(room, "fire", cx(4) + 8, "Heat remembers what was struck.")
	var tab_proj := tablet(room, "projectile", cx(5) + 16, "A bolt goes where it is thrown, further than a hand can.")
	var hearth_candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleHearth", Vector2(cx(6) + 8, FLOOR_Y))
	var forge_cube := cube(room, "Forge Cube", cx(7), "wind/push/right/normal",
		{"carryable": false, "locked_slots": LOCK_DIRECTION})
	slag_pool(room, 8, 12, hearth_candle)
	var brambles := inst(RUNES + "burnable.tscn", room, "Brambles", Vector2(880.0, FLOOR_Y), {"size": Vector2(32, 128)})
	var pilot := inst(PUZZLE + "brazier.tscn", room, "PilotFlame", Vector2(960.0, FLOOR_Y))
	spectral_bridge(room, 8, 12, pilot, "kiln.r1.bridge", 0)
	kiln_page(room, 1, Vector2(cx(1) + 8, 462.0), "The Smith's Ledger, i",
		"The Hush came down the flues before it came through the doors. We let the Great Kiln go cold so the frost would have nothing to hold on to. Whoever wakes it: fire, coal and air, all three at once, or it will not draw.")
	add_sign(signs, "Smith", 1.6, "The Smith's hall. Fire, coal and air: all three at once, or the Great Kiln will not draw.", FLOOR_Y, 190.0)
	for x in [250.0, 410.0]:
		deco_sprite(deco, "chalk_steps", Vector2(x, FLOOR_Y), false, -1, true)
	var reveal := Area2D.new()
	reveal.name = "KilnReveal"
	reveal.set_script(load("res://scripts/puzzle/reveal_trigger.gd"))
	reveal.position = Vector2(cx(13), FLOOR_Y)
	reveal.set("look_at", Vector2(1568.0, 380.0))
	reveal.set("flag", "kiln.r1.revealed")
	add_owned(room, reveal)

	# ---------------------------------------------------- the west end of the Kiln Hall
	# The Smith's gallery: the bench (cols 13-16), a gap over the perch (17), a
	# landing by the shaft (18), the shaft's opening (19-20), and a ledge over
	# the west slag (21) that meets the kiln's roof
	ledge_run(13, 16, 4, false, false, true)
	ledge_run(18, 18, 4)
	ledge_run(21, 21, 4)
	# The bench's alcove: a roof of rock down from the ceiling over col 13
	for x in [13]:
		for y in range(0, 3):
			solid(x, y)
	var crust := inst(RUNES + "cracked_wall.tscn", room, "SlagCrust", Vector2(908.0, 274.0),
		{"size": Vector2(24, 82), "break_momentum": 800.0, "persist_id": "kiln.r1.crust", "sprite_name": "slag_crust"})
	# (blown off the bench before it breaks the plug, nothing can lift it back)
	var bench_stone := stone(room, "BenchStone", 944.0, {"required": true, "required_until_flag": "kiln.r1.crust",
		"required_reason": "The stone fell off the Smith's bench, and nothing can lift it back up there.",
		"required_area": Rect2(820, 200, 270, 90)}, 274.0)
	var bench_cube := cube(room, "Bench Cube", 1004.0, "wind/push/right/normal",
		{"locked_slots": LOCK_ESSENCE | LOCK_FORM}, 274.0)
	var tab_explode := tablet(room, "explode", 862.0, "Flame that bursts reaches what a spark cannot.", 274.0)

	kiln_page(room, 2, Vector2(862.0, 214.0), "The Smith's Ledger, ii",
		"Air carries flame. My bellows could send a spark up the shaft and into the kiln's pipe without anyone going near it. The coal is damp with frost now; a spark will only hiss on it. It wants a flame that bursts.")
	# The perch under the gap: the only spot whose current blows into the pipe
	ledge_run(17, 17, 6, true)
	var pedestal := inst(RUNES + "rune_pedestal.tscn", room, "PerchPedestal", Vector2(1130.0, 434.0))
	# The bellows shaft: an updraft out of a notch in the floor, always on
	pit(19, 20)
	var shaft := cube(room, "Bellows Shaft", 1280.0, "wind/lift/up/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": 15, "start_active": true}, 598.0)
	var hoist := inst(PUZZLE + "brazier.tscn", room, "HoistBrazier", Vector2(1280.0, 176.0), {"hang_length": 176.0})
	var west_candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleWest", Vector2(1120.0, FLOOR_Y))
	slag_pool(room, 21, 21, west_candle)

	# ---------------------------------------------------- the Great Kiln
	var kiln := inst(PUZZLE + "great_kiln.tscn", room, "GreatKiln", Vector2(1568.0, FLOOR_Y),
		{"persist_id": KILN_ROAR_FLAG, "fuel_persist_id": "kiln.r1.fuel"})

	# ---------------------------------------------------- the east end: slag, the coal loft, the door
	var east_candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleEast", Vector2(cx(30) + 8, FLOOR_Y))
	slag_pool(room, 27, 28, east_candle)
	var slag_bridge: Array = []
	for i in range(27, 29):
		slag_bridge.append(inst(PUZZLE + "spectral_platform.tscn", room, "SlagBridge%d" % (i - 26),
			Vector2(i * T, FLOOR_Y), {"size": Vector2(64, 12)}))
	circuit(room, "HoistToSlagBridge", [hoist], slag_bridge,
		{"latch": true, "reveal_target": true, "persist_id": "kiln.r1.slagbridge", "channel_y": 36.0, "symbol": 1})
	# Flat at its east end, where the lift docks (a rounded cap there catches her)
	ledge_run(28, 33, 4, false, true, false)
	var cart := inst(RUNES + "wind_body.tscn", room, "CoalCart", Vector2(1898.0, 274.0), {
		"size": Vector2(40, 40), "sprite_name": "coal_cart", "extra_groups": PackedStringArray(["coal"]),
		"required": true, "required_reason": "The coal cart fell into the slag and burned.",
		"required_until_flag": "kiln.r1.fuel"})
	var loft_cube := cube(room, "Loft Cube", 2060.0, "wind/push/right/normal", {}, 274.0)
	tablet(room, "burst", 2136.0, "A breeze only leans. A gust strikes.", 274.0)
	tablet(room, "up", 2004.0, "Heat rises, and so does what it carries.", 274.0)
	inst(TRAPS + "moving_platform.tscn", room, "LoftHoist", Vector2(34 * T, FLOOR_Y - 18),
		{"width_tiles": 2, "travel": Vector2(0, -260), "speed": 70.0, "end_pause": 1.2})
	# The page cell above the loft: a floor with a hole matted with brambles
	ledge_run(31, 31, 2)
	ledge_run(33, 33, 2)
	for y in range(0, 3):
		solid(30, y)
		solid(34, y)
	inst(RUNES + "burnable.tscn", room, "CellMat", Vector2(2080.0, 192.0), {"size": Vector2(64, 16)})
	kiln_page(room, 3, Vector2(2010.0, 112.0), "The Smith's Ledger, iii",
		"The Prior's girl came through the hall again. She drew a star on my anvil in chalk and asked why fire is afraid of the cold. I told her it isn't. It is the cold that runs from the fire. She liked that.")
	kindle_flame(room, cx(37))
	shrine(room, "east", cx(39))
	var door := inst(PUZZLE + "forge_door.tscn", room, "ForgeDoor", Vector2(cx(44), FLOOR_Y), {"persist_id": "kiln.r1.door"})
	circuit(room, "KilnToDoor", [kiln], [door],
		{"latch": true, "hold_time": 2.9, "reveal_target": true, "persist_id": "kiln.r1.doorway", "channel_y": 300.0, "symbol": 3})

	# ---------------------------------------------------- the goal and its steps
	guide(room, "Relight the Great Kiln.", "I", "The Cold Forge", "The Long Stair  ·  The Kilnworks")
	step(room, "The pilot flame burns: a bridge forms", Cond.POWERED, pilot)
	step(room, "Fire rides the shaft: a bridge rises over the slag", Cond.POWERED, hoist)
	step(room, "Burst learned", Cond.FLAG, null, {"flag": "rune.frag.burst"})
	step(room, "Explode learned", Cond.FLAG, null, {"flag": "rune.frag.explode"})
	step(room, "Coal in the kiln", Cond.PROPERTY, kiln, {"property": "fuel_state", "value": 1})
	step(room, "Air in the kiln's pipe", Cond.PROPERTY, kiln, {"property": "air_state", "value": 1})
	step(room, "The Great Kiln roars", Cond.POWERED, kiln)
	step(room, "The Forge Door opens", Cond.OPEN, door)
	for i in 3:
		step(room, "Ledger page %s found" % ["i", "ii", "iii"][i], Cond.FLAG, null,
			{"flag": "kiln.page.%d" % (i + 1), "optional": true})

	hint(room, Vector2(cx(1) + 8, FLOOR_Y), [
		"The brazier across the slag is too far for your own fire. The cube at the edge throws further.",
		"Dry brambles stand in front of the brazier. A bolt stops at the first thing it hits, and burns brambles away.",
		"Read both tablets, inscribe Fire and Projectile on the Forge Cube and switch it on: once for the brambles, once more for the brazier.",
	], [forge_cube, brambles, pilot, tab_fire, tab_proj])
	hint(room, Vector2(1010.0, FLOOR_Y), [
		"Air rises out of the bellows shaft, and a brazier hangs dark above it. The groove from it runs all the way to the slag beyond the kiln.",
		"Air carries flame: fire that flies into a current turns and goes with it. The shaft carries you, too.",
		"Throw a fireball into the shaft: it rises and lights the hanging brazier, which raises the bridge over the slag past the kiln. Ride the shaft up to reach the gallery and the kiln's roof.",
	], [shaft, hoist, slag_bridge[0]])
	hint(room, Vector2(1196.0, 274.0), [
		"The Explode tablet is sealed behind a plug of cold slag. The stone in front of it is pressed right up against the plug.",
		"A steady wind only leans on the stone: it has no room to gather speed. A single gust strikes all at once. The Bench Cube's first two words are carved: Wind, Push.",
		"Carry the cube from the coal loft (its words are all free) up the shaft to this landing. Set it down here, inscribe Wind, Burst, Left, Strong and switch it on: the gust crosses the gap and strikes the stone.",
	], [crust, bench_stone, bench_cube, tab_explode])
	hint(room, Vector2(1966.0, 274.0), [
		"The kiln burns coal, and the coal cart is up here. Below the loft's west edge is slag.",
		"Anything that falls into the slag burns. The bridge over it rises only when the brazier above the bellows shaft is lit.",
		"Light the hanging brazier first (fire up the shaft). Then push the cart west off the loft with Wind, Push, Left so it lands on the bridge, carry the cube down and push the cart into the kiln's fuel bay.",
	], [cart, loft_cube, slag_bridge[0]])
	hint(room, Vector2(904.0, FLOOR_Y), [
		"Three lamps on the kiln: coal, air, fire. A grate guards its mouth; the only way in is the pipe on its left side.",
		"The pipe needs a current blowing into it at its own height: only the perch with the pedestal is that high. And a spark only hisses on the cold coal: it wants a flame that bursts.",
		"Put the Bench Cube on the perch's pedestal: Wind, Push, Right. Put the loft's cube on the floor below, between the perch and the shaft: Fire, Projectile, Right, Explode. Its bolt rides the shaft up, turns into the perch's current and flies into the pipe.",
	], [kiln, pedestal, shaft])

	# ---------------------------------------------------- dressing: light, the Smith's things, Wren, the frost
	for c in [1, 6, 10]:
		torch(deco, c)
	for c in [15, 23, 27, 31, 36, 41]:
		torch(deco, c, 1)
	for c in [38, 42]:
		torch(deco, c)
	decor(16, 5, W_BANNER_FLEUR)
	decor(39, 5, W_WINDOW_BARRED)
	decor(42, 2, W_WINDOW_MOON)
	deco_sprite(deco, "smith_plaque", Vector2(1010.0, 438.0))
	deco_sprite(deco, "bellows", Vector2(1020.0, FLOOR_Y), false, 1)
	deco_sprite(deco, "chalk_route", Vector2(1184.0, 500.0), false, -1, true)
	deco_sprite(deco, "chalk_steps", Vector2(1080.0, FLOOR_Y), false, -1, true)
	deco_sprite(deco, "chalk_star", Vector2(cx(43) + 16, 420.0), false, -1, true)
	deco_sprite(deco, "anvil", Vector2(2448.0, FLOOR_Y), false, 1)
	deco_sprite(deco, "tool_rack", Vector2(2500.0, 470.0))
	deco_sprite(deco, "coal_heap", Vector2(2330.0, FLOOR_Y), false, 1)
	deco_sprite(deco, "coal_heap", Vector2(2108.0, 274.0), true, -1)
	for spec in [[Vector2(900, 150), "frost_a", false], [Vector2(1150, 330), "frost_b", true], [Vector2(1420, 150), "frost_a", true],
			[Vector2(1700, 120), "frost_b", false], [Vector2(1990, 420), "frost_a", false], [Vector2(2280, 170), "frost_b", true],
			[Vector2(2600, 360), "frost_a", false], [Vector2(2760, 180), "frost_b", false], [Vector2(300, 400), "frost_a", true],
			[Vector2(640, 380), "frost_b", false]]:
		frost(deco, spec[0], spec[1], spec[2])
	waymark(room, cx(5), "right")
	waymark(room, 1200.0, "up", 420.0)
	waymark(room, 1376.0, "right", 198.0)
	waymark(room, 2280.0, "down", 198.0)
	waymark(room, cx(41), "right")
	prop(deco, "chain_short", 1180.0, 16.0, true)
	prop(deco, "cobweb_corner", cx(43) + 8, 12.0, true, true)


## The Kiln Heart. A stone block on a heavy plate opens the gate (a Strong
## wind drives it; a kerb stops it on the plate), brambles hide the bell
## behind it, and the Forge Bell ends the wing.
func kiln_heart() -> void:
	var o := 22
	shell(22 + o, 46 + o, LOW_CEIL, false, true)
	curb(40 + o)
	var room := mk_room("R2", "The Kiln Heart", 22 + o, 46 + o, LOW_CEIL, Vector2(cx(23 + o), 530))
	waymarks(room, 22 + o, 46 + o, false)
	shrine(room, "heart", cx(24 + o))
	kindle_flame(room, cx(26 + o))
	tablet(room, "up", cx(27 + o) + 16, "Heat rises, and so does what it moves.")
	tablet(room, "large", cx(29 + o), "A wide hearth warms a wide room.")
	var c := cube(room, "Heart Cube", cx(33 + o), "wind/push/right/normal")
	var block := stone(room, "Stone", cx(35 + o))
	var p := plate(room, "HeavyPlate", 2544.0 + o * T, {"stone_only": true, "width": 48.0})
	var exit_gate := gate(room, "HeartGate", 41 + o)
	circuit(room, "PlateToGate", [p], [exit_gate],
		{"reveal_target": true, "persist_id": "kiln.r2.solved", "channel_y": 440.0, "symbol": 1})
	var brambles := inst(RUNES + "burnable.tscn", room, "Brambles", Vector2(cx(42 + o), FLOOR_Y), {"size": Vector2(32, 128)})
	var bell := wing_bell(room, cx(43 + o), "The Forge Bell rings out.", "Heat runs through the cold stone, and the furnaces stir.")
	guide(room, "Ring the Forge Bell.")
	step(room, "The stone on the plate: the gate opens", Cond.OPEN, exit_gate)
	step(room, "The brambles burn", Cond.OPEN, brambles)
	step(room, "The Forge Bell rings", Cond.POWERED, bell)
	hint(room, Vector2(cx(24 + o) + 28, FLOOR_Y), [
		"A stone block, a heavy plate and a cube. The brambles around the bell are dry.",
		"A normal wind cannot shift the stone. You learned Strong in the Observatory.",
		"Inscribe Strong on the loose cube beside the stone and switch it on: the stone slides onto the plate. Then burn the brambles with your own fireball and ring the bell.",
	], [c, block, p, brambles])
	dress(room, 22 + o, 46 + o, [25 + o, 31 + o, 38 + o, 44 + o])

# ================================================================ the Drowned Cistern (ice)

func build_cistern() -> void:
	begin("Cistern", "cistern", "The Drowned Cistern", Journey.CISTERN_INTERLUDE, Journey.WINGS[1]["words"])
	cistern_first_pool()
	cistern_sluice()
	finish()


## A slime that cannot be bothered to move stands on a heavy plate. Only
## stone presses it: but a frozen slime is stone. Her cube reaches it only
## with Long (the slime is 240 px away; a normal chill reaches 160).
func cistern_first_pool() -> void:
	shell(0, 22, LOW_CEIL, true, false)
	var room := mk_room("R1", "The First Pool", 0, 22, LOW_CEIL, Vector2(cx(2), 530))
	waymarks(room, 0, 22)
	shrine(room, "start", cx(2))
	kindle_flame(room, cx(4))
	var t1 := tablet(room, "ice", cx(5), "Cold that holds its shape.")
	var t2 := tablet(room, "freeze", cx(6) + 16, "What is held still is heavy.")
	var t3 := tablet(room, "long", cx(7) + 32, "Cold reaches further than it seems.")
	var c := cube(room, "Pool Cube", cx(10), "wind/push/right/normal", {"carryable": false, "locked_slots": LOCK_DIRECTION})
	var p := plate(room, "SlimePlate", cx(14), {"stone_only": true, "width": 56.0})
	var s := slime(room, "Slime", Vector2(cx(14), 530), {"hears_bells": false, "home_radius": 1.0, "detection_range": 0.0, "max_health": 10,
		"required": true, "required_reason": "The slime that had to hold the plate has been killed, and only a frozen creature can press it.", "required_until_flag": "cistern.r1.solved"})
	var exit_gate := gate(room, "PoolGate", 19)
	circuit(room, "PlateToGate", [p], [exit_gate],
		{"reveal_target": true, "persist_id": "cistern.r1.solved", "channel_y": 440.0, "symbol": 0})
	guide(room, "Open the gate.", "I", "The First Pool", "The Long Stair  ·  The Drowned Cistern")
	step(room, "Freeze learned", Cond.FLAG, null, {"flag": "rune.frag.freeze"})
	step(room, "The frozen slime holds the plate: the gate opens", Cond.OPEN, exit_gate)
	hint(room, Vector2(cx(3) + 20, FLOOR_Y), [
		"The plate wants stone, and the slime on it is not stone. Yet.",
		"A frozen creature is as heavy as stone. The cube's chill is too short to reach the slime.",
		"Read the tablets, inscribe Ice, Freeze and Long on the cube and switch it on, then walk through the gate before the slime thaws.",
	], [c, p, s, t1, t2, t3])
	dress(room, 0, 22, [3, 8, 13, 20])


## The Sluice. Two slimes, two heavy plates, one cube: the second slime is as
## far from the cube as a Long chill reaches. The Cistern's bell is behind
## the gate.
func cistern_sluice() -> void:
	shell(22, 46, LOW_CEIL, false, true)
	var room := mk_room("R2", "The Sluice", 22, 46, LOW_CEIL, Vector2(cx(23), 530))
	waymarks(room, 22, 46, false)
	shrine(room, "sluice", cx(24))
	kindle_flame(room, cx(26))
	tablet(room, "persist", cx(28), "The word that made the silence.")
	var c := cube(room, "Sluice Cube", cx(33), "wind/push/right/normal", {"carryable": false, "locked_slots": LOCK_DIRECTION})
	var pa := plate(room, "PlateA", 2350.0, {"stone_only": true, "width": 64.0})
	var pb := plate(room, "PlateB", 2420.0, {"stone_only": true, "width": 64.0})
	var needed := {"required": true, "required_reason": "A slime that had to hold a plate has been killed, and only frozen creatures can press them.", "required_until_flag": "cistern.r2.solved"}
	var sa := slime(room, "SlimeA", Vector2(2350.0, 530), {"hears_bells": false, "home_radius": 1.0, "detection_range": 0.0, "max_health": 10}.merged(needed))
	var sb := slime(room, "SlimeB", Vector2(2420.0, 530), {"hears_bells": false, "home_radius": 1.0, "detection_range": 0.0, "max_health": 10}.merged(needed))
	var exit_gate := gate(room, "SluiceGate", 41)
	circuit(room, "PlatesToGate", [pa, pb], [exit_gate],
		{"hold_time": 0.5, "reveal_target": true, "persist_id": "cistern.r2.solved", "channel_y": 440.0, "symbol": 2})
	var bell := wing_bell(room, cx(43), "The Tide Bell rings out.", "Water runs again through every channel.")
	guide(room, "Ring the Tide Bell.")
	step(room, "Both slimes frozen on their plates: the gate opens", Cond.OPEN, exit_gate)
	step(room, "The Tide Bell rings", Cond.POWERED, bell)
	hint(room, Vector2(cx(24) + 28, FLOOR_Y), [
		"Two plates, two slimes, one cube. The gate wants both held at once.",
		"A cold that reaches further is Long. Both slimes are inside one Long chill, but only just.",
		"Inscribe Ice, Freeze and Long on the cube, switch it on and go through the gate before the cold lets go (six seconds).",
	], [c, pa, pb, sa, sb])
	dress(room, 22, 46, [25, 30, 38, 44])


# ================================================================ the Lampworks (light)

func build_lamps() -> void:
	begin("Lamps", "lamps", "The Lampworks", Journey.LAMPS_INTERLUDE, Journey.WINGS[2]["words"])
	lamps_reading_room()
	lamps_stair()
	finish()


## The Dark Reading Room. A beam crosses a spiked pit and lights a crystal
## on the far side, which raises a bridge of faint stone.
func lamps_reading_room() -> void:
	shell(0, 22, LOW_CEIL, true, false)
	var room := mk_room("R1", "The Dark Reading Room", 0, 22, LOW_CEIL, Vector2(cx(2), 530))
	waymarks(room, 0, 22)
	shrine(room, "start", cx(2))
	kindle_flame(room, cx(4))
	spiked_pit(room, 10, 14, 7)
	var t1 := tablet(room, "light", cx(5), "Holy light, and what it wakes.")
	var t2 := tablet(room, "beam", cx(6) + 16, "A straight ray, to a far place.")
	var c := cube(room, "Reading Cube", cx(9), "wind/push/right/normal",
		{"carryable": false, "locked_slots": LOCK_DIRECTION | LOCK_MODIFIER})
	var crystal := inst(PUZZLE + "light_receiver.tscn", room, "Crystal", Vector2(cx(17), FLOOR_Y - 16.0))
	spectral_bridge(room, 10, 14, crystal, "lamps.r1.bridge", 1)
	guide(room, "Cross the pit.", "I", "The Dark Reading Room", "The Long Stair  ·  The Lampworks")
	step(room, "Light learned", Cond.FLAG, null, {"flag": "rune.frag.beam"})
	step(room, "The crystal is lit: a bridge forms", Cond.POWERED, crystal)
	step(room, "Across the pit", Cond.REACHED, null, {"area": Rect2(15 * T, 470, 8 * T, 70)})
	hint(room, Vector2(cx(3) + 20, FLOOR_Y), [
		"A crystal waits across the pit, and a cube stands at the edge.",
		"Crystals wake to holy light: a beam that ends on one powers it.",
		"Read both tablets, inscribe Light and Beam on the cube and switch it on: the beam crosses the pit and lights the crystal.",
	], [c, crystal, t1, t2])
	dress(room, 0, 22, [3, 8, 13, 19])


## The Lamp Stair. A crystal on the wall opens the gate while light touches
## it. A glow cube lights it from afar only with Large; carry the cube to a
## spot where it can reach. The Lamp Bell is behind the gate.
func lamps_stair() -> void:
	shell(22, 46, LOW_CEIL, false, true)
	var room := mk_room("R2", "The Lamp Stair", 22, 46, LOW_CEIL, Vector2(cx(23), 530))
	waymarks(room, 22, 46, false)
	shrine(room, "stair", cx(24))
	kindle_flame(room, cx(26))
	tablet(room, "glow", cx(27) + 16, "A pool of light, carried.")
	tablet(room, "self", cx(29), "It shines on all sides.")
	var c := cube(room, "Lamp Cube", cx(31), "wind/push/right/normal")
	var crystal := inst(PUZZLE + "light_receiver.tscn", room, "Crystal", Vector2(cx(38), FLOOR_Y - 120.0))
	var exit_gate := gate(room, "StairGate", 41)
	circuit(room, "CrystalToGate", [crystal], [exit_gate],
		{"reveal_target": true, "persist_id": "lamps.r2.solved", "channel_y": 440.0, "symbol": 3})
	var bell := wing_bell(room, cx(43), "The Lamp Bell rings out.", "Every lamp in the works flickers, and burns on.")
	guide(room, "Ring the Lamp Bell.")
	step(room, "Glow learned", Cond.FLAG, null, {"flag": "rune.frag.glow"})
	step(room, "The crystal is lit: the gate opens", Cond.OPEN, exit_gate)
	step(room, "The Lamp Bell rings", Cond.POWERED, bell)
	hint(room, Vector2(cx(24) + 28, FLOOR_Y), [
		"A crystal high on the wall holds the gate. Light that reaches it wakes it.",
		"A glow lights a circle around its cube. A Large one is wider. The cube can be carried.",
		"Inscribe Light, Glow, Self and Large, carry the cube under the crystal, set it down and switch it on.",
	], [c, crystal])
	dress(room, 22, 46, [25, 33, 36, 44])


# ================================================================ the Folded Galleries (space)

func build_galleries() -> void:
	begin("Galleries", "galleries", "The Folded Galleries", Journey.GALLERIES_INTERLUDE, Journey.WINGS[3]["words"])
	galleries_first_door()
	galleries_fold_bell()
	finish()


## The First Door. A wall of stone with a walkable top: a portal cube, carried
## to the wall, doors her up and over it (Space, Portal, Up-Right and Long).
func galleries_first_door() -> void:
	shell(0, 22, HIGH_CEIL, true, false)
	stone_wall(11, 15)
	var room := mk_room("R1", "The First Door", 0, 22, HIGH_CEIL, Vector2(cx(2), 530))
	waymarks(room, 0, 22)
	shrine(room, "start", cx(2))
	kindle_flame(room, cx(5))
	var t1 := tablet(room, "space", cx(3), "Distance is only a habit.")
	var t2 := tablet(room, "portal", cx(4), "A door to somewhere near.")
	var c := cube(room, "Door Cube", cx(6), "wind/push/right/normal")
	guide(room, "Get over the wall.", "I", "The First Door", "The Long Stair  ·  The Folded Galleries")
	step(room, "Space learned", Cond.FLAG, null, {"flag": "rune.frag.portal"})
	step(room, "Onto the wall", Cond.REACHED, null, {"area": Rect2(11 * T, 180, 5 * T, 110)})
	step(room, "Down the other side", Cond.REACHED, null, {"area": Rect2(17 * T, 470, 5 * T, 70)})
	hint(room, Vector2(cx(3) + 20, FLOOR_Y), [
		"The wall is far too high to jump. The cube can fold space.",
		"A portal opens up and to the right of the cube. From where it starts, that is the empty air in front of the wall.",
		"Inscribe Space, Portal, Up-Right and Long, carry the cube close to the wall, switch it on and jump into the doorway.",
	], [c, t1, t2])
	var deco := group(room, "Decor")
	for col in [3, 8, 18, 21]:
		torch(deco, col)
	for col in [5, 14, 19]:
		torch(deco, col, 1)
	decor(8, 1, W_WINDOW_MOON)
	decor(18, 5, W_BANNER_FLEUR)
	prop(deco, "skull_pile", cx(20), FLOOR_Y)


## The Fold Bell. A plate holds faint stairs up to a balcony: she cannot hold
## the plate and climb, but her Echo can. The Fold Bell hangs on the balcony.
func galleries_fold_bell() -> void:
	shell(22, 42, HIGH_CEIL, false, true)
	for x in range(34, 42):
		floor_tile(x, 3)
	var room := mk_room("R2", "The Fold Bell", 22, 42, HIGH_CEIL, Vector2(cx(23), 530))
	waymarks(room, 22, 42, false)
	kindle_flame(room, cx(24))
	var plate_node := inst("res://scenes/pressure_plate.tscn", room, "Plate", Vector2(cx(25), FLOOR_Y))
	var stairs: Array = []
	for i in 6:
		stairs.append(inst(PUZZLE + "spectral_platform.tscn", room, "Stair%d" % (i + 1),
			Vector2(28 * T + i * 64, 486 - i * 48), {"size": Vector2(64, 12)}))
	circuit(room, "StairsCircuit", [plate_node], stairs, {"channel_y": 510.0, "symbol": 3, "solved_sound": ""})
	var bell := inst(PUZZLE + "great_bell.tscn", room, "GreatBell", Vector2(cx(38), 94),
		{"announce": "The Fold Bell rings out.", "announce_sub": "The rooms inside rooms fall quiet.", "tolls": 2})
	guide(room, "Climb to the Fold Bell and ring it.")
	step(room, "Something holds the plate: the stairs rise", Cond.POWERED, plate_node)
	step(room, "Up to the Fold Bell", Cond.REACHED, null, {"area": Rect2(35 * T, 150, 7 * T, 70)})
	step(room, "The Fold Bell rings", Cond.POWERED, bell)
	hint(room, Vector2(cx(23) + 24, FLOOR_Y), [
		"Look at the plate, the faint stairs and the balcony above.",
		"The stairs stand only while the plate is held, and you cannot hold it and climb at once.",
		"Record an Echo walking onto the plate and stop. When it finishes it stays there, holding the plate: climb while it does.",
	], [plate_node] + stairs.slice(0, 2))
	var deco := group(room, "Decor")
	for col in [23, 27, 32]:
		torch(deco, col)
	for col in [26, 33, 39]:
		torch(deco, col, 1)
	decor(29, 1, W_WINDOW_MOON)
	decor(37, 1, W_WINDOW_MOON)
	prop(deco, "skull_pile", cx(31), FLOOR_Y)


# ================================================================ the Eye

## The Eye. Ilse stands frozen beside Wren's bed; between them the great cube
## reads Ice, Freeze, Self, Persist. Whatever sentence is switched on it is
## read (scripts/runes/eye_altar.gd).
func build_eye() -> void:
	begin("Eye", "eye", "The Eye", "", [])
	shell(0, 26, HIGH_CEIL, true, true)
	var room := mk_room("R1", "The Eye", 0, 26, HIGH_CEIL, Vector2(cx(2), 530))
	shrine(room, "start", cx(2))
	kindle_flame(room, cx(4))
	var great := cube(room, "Great Cube", cx(15), "light/glow/self/normal",
		{"dungeon_powered": true, "carryable": false})

	var altar := inst(RUNES + "eye_altar.tscn", room, "Altar", Vector2(cx(15), FLOOR_Y))
	altar.set("cube_path", NodePath("../GreatCube"))
	var ilse := room_sprite(room, "ilse", cx(20), 2.0, true)
	var wren := room_sprite(room, "wren_bed", cx(23), 2.0, false)
	guide(room, "Write the last sentence on the great cube.", "", "", "")
	step(room, "A sentence on the great cube", Cond.POWERED, great)
	hint(room, Vector2(cx(6), FLOOR_Y), [
		"The great cube is fed by the dungeon, and answers to whatever you write on it.",
		"The held moment can be kept, or it can be sent away. There are only two sentences it answers to.",
		"Everything you need has been learned. Light, Beam, Up, Long sends it away; Ice, Freeze, Self, Large keeps it.",
	], [great, ilse, wren])
	var signs := group(room, "Signs")
	add_sign(signs, "Mural", 9.0, "The mural: what can't be kept can be sent.", FLOOR_Y, 170.0)
	add_sign(signs, "Plea", 18.0, "Ilse: please. Don't let go of her.", FLOOR_Y, 150.0)
	dress(room, 0, 26, [3, 8, 12, 24])
	finish()


## A hand-made sprite placed in a room (Ilse, Wren's bed). A strip with
## several frames animates; a single frame stands still.
func room_sprite(room: Node, sprite_name: String, x: float, scale: float, animated: bool) -> Node:
	var holder := Node2D.new()
	holder.name = sprite_name.to_pascal_case()
	holder.position = Vector2(x, FLOOR_Y)
	holder.z_index = -1
	add_owned(room, holder)
	var script := load("res://scripts/puzzle/room_sprite.gd")
	holder.set_script(script)
	holder.set("sprite_name", sprite_name)
	holder.set("sprite_scale", scale)
	holder.set("play", animated)
	return holder
