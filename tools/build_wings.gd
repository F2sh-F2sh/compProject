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
		[PUZZLE + "heart_crucible.tscn", "HeartCrucible", Node2D, "res://scripts/puzzle/heart_crucible.gd"],
		[TRAPS + "slag_pool.tscn", "SlagPool", Area2D, "res://scripts/traps/slag_pool.gd"],
		[TRAPS + "cistern_pool.tscn", "CisternPool", Area2D, "res://scripts/traps/cistern_pool.gd"],
		[PUZZLE + "fountain.tscn", "Fountain", Node2D, "res://scripts/puzzle/fountain.gd"],
		[PUZZLE + "tide_clock.tscn", "TideClock", Node2D, "res://scripts/puzzle/tide_clock.gd"],
		[TRAPS + "tide_pool.tscn", "TidePool", Node2D, "res://scripts/traps/tide_pool.gd"],
		[PUZZLE + "tide_mark.tscn", "TideMark", Node2D, "res://scripts/puzzle/tide_mark.gd"],
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
	level.set("total_pages", 6)
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
func frost(parent: Node, pos: Vector2, which := "frost_a", flip := false, flag := KILN_ROAR_FLAG) -> void:
	var n := Node2D.new()
	n.name = "Frost%d" % parent.get_child_count()
	n.position = pos
	n.set_script(load("res://scripts/fx/melting_frost.gd"))
	n.set("sprite_name", which)
	n.set("melt_flag", flag)
	n.set("flip", flip)
	add_owned(parent, n)


## One of the Smith's ledger pages (the Kilnworks has six, three a room).
func kiln_page(parent: Node, id: int, pos: Vector2, title: String, text: String) -> void:
	inst(PUZZLE + "lore_page.tscn", parent, "LorePage%d" % id, pos,
		{"page_id": "kiln.page.%d" % id, "title": title, "text": text})
	var ids: PackedStringArray = parent.get("page_ids")
	ids.append("kiln.page.%d" % id)
	parent.set("page_ids", ids)
	ledger.append({"id": "kiln.page.%d" % id, "numeral": ["i", "ii", "iii", "iv", "v", "vi"][id - 1],
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


## THE KILN HEART. The Great Kiln's heat runs on into the Smith's last forge:
## a long hall over a lake of slag, ending in the tower where the Forge Bell
## hangs frozen. The Heart (the Smith's crucible, sunk in the tower floor;
## scripts/puzzle/heart_crucible.gd) wakes it: three skips of coal tipped into
## it and its three burners lit at the same moment. Five parts, three of them
## a new word:
##   the Shutter Hall (cols 45-52)  DELAY: the shutter stands open only while
##     someone is on its plate, and the lamp beyond it is out of reach of her
##     own fire. The cube by the shutter throws further, but she can't be at the
##     cube and on the plate at once: a bolt that waits two seconds can.
##   the Slag Lake (cols 59-74)  three heat vents (dungeon machinery, always on)
##     and the ledges between them: up a column, off onto the next ledge.
##   the Coal Racks (the gallery, cols 71-87)  LARGE: from the pedestal at the
##     end of the gallery one wide gust tips the skips off all three iron racks
##     (wind blows through iron bars) into the Heart; a normal one reaches one.
##   the Heart (cols 89-97)  SPLIT: from the pedestal beside it, one bolt thrown
##     three ways up and to the right lights the three burners hanging over it
##     at once (each dies within half a second, so one at a time won't do).
##   the bell (cols 98-101)  the Heart's roar thaws the bell and drives the
##     hoist, the only way up to it.
## Optional: three ledger pages (a shelf over the hall, a ledge low in the lake
## beside the second vent, a ledge beside the hoist halfway up).
func kiln_heart() -> void:
	shell(44, 102, HIGH_CEIL, false, true)
	# The Shutter Hall is a low antechamber; its east wall comes down to the
	# shutter's doorway (col 52)
	for x in range(45, 53):
		ceiling.erase_cell(Vector2i(x, 0))
		for y in range(0, 4 if x < 52 else 6):
			solid(x, y)
		if x < 52:
			ceiling.set_cell(Vector2i(x, 4), 0, BEAMS[rng.randi_range(0, BEAMS.size() - 1)])
	var room := mk_room("R2", "The Kiln Heart", 44, 102, HIGH_CEIL, Vector2(cx(45), 530), true)
	var deco := group(room, "Decor")
	var machinery := {"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": 15, "start_active": true}

	# ---------------------------------------------------- the Shutter Hall (Delay)
	shrine(room, "heart", cx(45))
	kindle_flame(room, cx(46))
	var tab_delay := tablet(room, "delay", 3096.0, "A flame that waits, then flies.")
	var shutter_plate := plate(room, "ShutterPlate", 3176.0, {"width": 56.0})
	var shutter_cube := cube(room, "Shutter Cube", cx(51), "fire/projectile/right/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM | LOCK_DIRECTION})
	var shutter := gate(room, "Shutter", 52)
	# Beyond the shutter: the cube's bolt reaches it; her own fire, thrown from
	# the plate, dies a stride short
	var ash_lamp := inst(PUZZLE + "brazier.tscn", room, "AshLamp", Vector2(cx(58), FLOOR_Y), {"persist_id": "kiln.r2.ash"})
	circuit(room, "ShutterCircuit", [shutter_plate, ash_lamp], [shutter],
		{"mode": 1, "channel_y": 470.0, "symbol": 0, "solved_sound": ""})
	room.set("glance_at", NodePath("AshLamp"))
	# The Smith's notes on a shelf over the hall (a charged jump)
	ledge_run(50, 50, 6, true)
	kiln_page(room, 4, Vector2(cx(50), 404.0), "The Smith's Ledger, iv",
		"The Kiln Heart takes the Great Kiln's heat up the tower and wakes the Forge Bell with it. Three skips of coal and three burners lit together, or it lies cold. When the Hush came I let it go cold, and the bell froze in its tower.")

	# ---------------------------------------------------- the Slag Lake (three heat vents)
	# Each vent is a column of heat (a mounted dungeon cube, always on) rising
	# out of the slag; the next ledge starts a hand's width from its edge (and
	# is square there), so she rides up and steps off. A fall in the slag puts
	# her back at the last candle she touched.
	var bank_candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleBank", Vector2(cx(56), FLOOR_Y))
	var candle_a := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleLedgeA", Vector2(cx(61), 274.0))
	var candle_b := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleLedgeB", Vector2(cx(67), 274.0))
	var candle_g := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleGallery", Vector2(cx(72), 274.0))
	slag_pool(room, 59, 62, bank_candle)
	slag_pool(room, 63, 67, candle_a)
	slag_pool(room, 68, 74, candle_b)
	slag_pool(room, 75, 84, candle_g)
	# The first ledge is broken in the middle (a hop across, or a drop to the
	# ledge low in the lake below it)
	ledge_run(61, 61, 4)
	ledge_run(63, 63, 4)
	ledge_run(66, 68, 4, false, false, false)
	var vents := []
	for x in [60 * T, 65 * T, 70 * T]:
		vents.append(cube(room, "Vent %d" % (vents.size() + 1), x, "wind/lift/up/normal", machinery, 598.0))
	# The ledge low in the lake, under the break: walk off its end into the
	# second vent
	ledge_run(62, 63, 7, true)
	kiln_page(room, 5, Vector2(cx(62), 468.0), "The Smith's Ledger, v",
		"My apprentice crossed the lake on the heat. Up the column, off at the top, never look down. He fell twice and the slag spat him back both times. He did not fall a third time.")

	# ---------------------------------------------------- the gallery and the Coal Racks (Large)
	# The far gallery, on over the end of the lake to the tower
	ledge_run(71, 84, 4, false, false, false)
	inst(PUZZLE + "kindle_flame.tscn", room, "KindleGallery", Vector2(cx(73) + 16, 274.0))
	inst(PUZZLE + "chapter_checkpoint.tscn", room, "ShrineGallery", Vector2(cx(74) + 24, 274.0), {"checkpoint_id": "kiln.cp.gallery"})
	var reveal := Area2D.new()
	reveal.name = "HeartReveal"
	reveal.set_script(load("res://scripts/puzzle/reveal_trigger.gd"))
	reveal.position = Vector2(cx(71) + 16, 274.0)
	reveal.set("look_at", Vector2(5760.0, 330.0))
	reveal.set("flag", "kiln.r2.revealed")
	add_owned(room, reveal)
	var tab_large := tablet(room, "large", cx(77), "A wide breath fills the whole forge.", 274.0)
	var rack_cube := cube(room, "Rack Cube", cx(79), "wind/push/right/normal", {}, 274.0)
	# The pedestal at the very end of the gallery, so a gust from it starts clear of the ledge
	var rack_pedestal := inst(RUNES + "rune_pedestal.tscn", room, "RackPedestal", Vector2(85 * T - 16, 274.0))
	# The fourth vent, beside the gallery's end: the way back up from the tower floor
	pit(85, 85)
	vents.append(cube(room, "Vent 4", cx(85), "wind/lift/up/normal", machinery, 598.0))
	# Three iron racks over the Heart's west rim, one above another, a skip of
	# coal near the end of each: from the pedestal a normal gust (96 px tall)
	# reaches the middle one, a Large one (288 px) all three
	var skips := []
	for i in 3:
		var surface: float = [146.0, 274.0, 402.0][i]
		inst(PUZZLE + "iron_grate.tscn", room, "Rack%d" % (i + 1), Vector2(5536.0, surface), {"width": 144.0})
		skips.append(inst(RUNES + "wind_body.tscn", room, "Skip%d" % (i + 1), Vector2(5650.0, surface), {
			"size": Vector2(40, 40), "sprite_name": "coal_cart", "extra_groups": PackedStringArray(["coal"]),
			"persist_id": "kiln.r2.skip.%d" % (i + 1), "required": true, "required_until_flag": "kiln.r2.heart",
			"required_reason": "A skip of coal fell where it can't be tipped into the Heart.",
			"required_area": Rect2(5530.0, 90.0, 160.0, 320.0)}))

	# ---------------------------------------------------- the Heart (Split)
	pit(89, 90)
	var burner_paths: Array[NodePath] = [NodePath("../BurnerHigh"), NodePath("../BurnerMid"), NodePath("../BurnerLow")]
	var heart := inst(PUZZLE + "heart_crucible.tscn", room, "Heart", Vector2(90 * T, 598.0), {
		"persist_id": "kiln.r2.heart", "burners": burner_paths,
		"coal_ids": PackedStringArray(["kiln.r2.skip.1", "kiln.r2.skip.2", "kiln.r2.skip.3"])})
	# Its three burners hang beside it on chains from the roof, along the fan of
	# a split bolt thrown up and to the right from the pedestal by it: each 200
	# px along its line (all three catch in the same instant), low enough to be
	# seen from the pedestal
	var burners := []
	for spec in [["BurnerHigh", Vector2(6043, 347)], ["BurnerMid", Vector2(6087, 381)], ["BurnerLow", Vector2(6121, 425)]]:
		var pos: Vector2 = spec[1]
		burners.append(inst(PUZZLE + "brazier.tscn", room, spec[0], pos, {"hang_length": pos.y - 42.0, "burn_time": 0.5}))
	var tab_split := tablet(room, "split", 5848.0, "One flame, thrown three ways.")
	var heart_pedestal := inst(RUNES + "rune_pedestal.tscn", room, "HeartPedestal", Vector2(cx(92), FLOOR_Y))
	# Down on the tower floor for the first time: a look at the burners
	var burner_look := Area2D.new()
	burner_look.name = "BurnerReveal"
	burner_look.set_script(load("res://scripts/puzzle/reveal_trigger.gd"))
	burner_look.position = Vector2(cx(91), FLOOR_Y)
	burner_look.set("look_at", Vector2(6080.0, 390.0))
	burner_look.set("flag", "kiln.r2.burners_seen")
	add_owned(room, burner_look)

	# ---------------------------------------------------- the bell
	# The hoist is the only way up to it: it waits on the floor until the Heart beats
	var hoist := inst(TRAPS + "moving_platform.tscn", room, "BellHoist", Vector2(98 * T, FLOOR_Y - 18),
		{"width_tiles": 2, "travel": Vector2(0, -324), "speed": 70.0, "end_pause": 1.4, "requires_power": true})
	circuit(room, "HeartToHoist", [heart], [hoist],
		{"latch": true, "hold_time": 2.6, "reveal_target": true, "persist_id": "kiln.r2.hoist", "channel_y": 470.0, "symbol": 2})
	ledge_run(100, 101, 3, false, false, false)
	var bell := inst(PUZZLE + "great_bell.tscn", room, "GreatBell", Vector2(cx(100), 90.0),
		{"announce": "The Forge Bell rings out.", "announce_sub": "Heat runs through the cold stone, and the furnaces stir.", "tolls": 2})
	# A ledge beside the hoist, halfway up: step off on the way past
	ledge_run(100, 100, 5)
	kiln_page(room, 6, Vector2(cx(100), 306.0), "The Smith's Ledger, vi",
		"The girl asked to ring the Forge Bell. I let her, once. She laughed at the noise and drew a star on the hoist. If someone finds this: the bell is still yours to ring. Make it loud.")

	# ---------------------------------------------------- the goal and its steps
	guide(room, "Wake the Kiln Heart and ring the Forge Bell.", "II", "The Kiln Heart", "The Long Stair  ·  The Kilnworks")
	step(room, "Delay learned", Cond.FLAG, null, {"flag": "rune.frag.delay"})
	step(room, "The Ash Lamp burns: the shutter stays open", Cond.POWERED, ash_lamp)
	step(room, "Across the slag lake", Cond.REACHED, null, {"area": Rect2(71 * T, 220, 6 * T, 70)})
	step(room, "Large learned", Cond.FLAG, null, {"flag": "rune.frag.large"})
	step(room, "Three skips of coal in the Heart", Cond.PROPERTY, heart, {"property": "fuel_state", "value": 1})
	step(room, "Split learned", Cond.FLAG, null, {"flag": "rune.frag.split"})
	step(room, "The Kiln Heart beats", Cond.POWERED, heart)
	step(room, "Up to the Forge Bell", Cond.REACHED, null, {"area": Rect2(100 * T, 150, 2 * T, 70)})
	step(room, "The Forge Bell rings", Cond.POWERED, bell)
	for i in 3:
		step(room, "Ledger page %s found" % ["iv", "v", "vi"][i], Cond.FLAG, null,
			{"flag": "kiln.page.%d" % (i + 4), "optional": true})

	hint(room, Vector2(cx(47), FLOOR_Y), [
		"The lamp beyond the shutter is out of reach of your own fire. The cube by the shutter throws further.",
		"The shutter stays up only while someone stands on the plate, and you can't be at the cube and on the plate at once.",
		"Read the Delay tablet. Inscribe Delay on the cube and switch it on, then run back onto the plate: two seconds later its bolt flies through the open shutter and lights the lamp.",
	], [shutter_cube, shutter_plate, shutter, ash_lamp, tab_delay])
	hint(room, Vector2(cx(54) - 8, FLOOR_Y), [
		"Three columns of heat rise out of the slag.",
		"Ride a column to its top and step off onto the ledge beside it. If you fall, the slag throws you back to the last candle you touched.",
		"Walk off the bank into the first column, rise, and step right onto the ledge. Hop the break in it (or drop through onto the low ledge) and walk off the far end into the next column. The third lets you off on the gallery.",
	], vents.slice(0, 3))
	hint(room, Vector2(cx(81), 274.0), [
		"Three skips of coal sit on three iron racks over the Heart. It needs all three.",
		"A gust from the pedestal at the end of the gallery strikes only what is level with it. The racks are iron bars: wind blows straight through them.",
		"Set the gallery's cube in the pedestal and inscribe Wind, Burst, Right, Large: one wide gust tips all three skips into the Heart.",
	], [rack_cube, rack_pedestal, tab_large] + skips)
	hint(room, Vector2(cx(94) - 8, FLOOR_Y), [
		"Three burners hang beside the Heart. Each flares and dies in half a breath. The Heart beats only when all three burn at once, and only with all its coal in.",
		"One flame thrown three ways reaches three places at once. From the pedestal beside the Heart, the burners fan out up and to the right.",
		"Bring a cube to the pedestal beside the Heart and inscribe Fire, Projectile, Up-Right, Split.",
	], [heart, heart_pedestal, tab_split] + burners)

	# ---------------------------------------------------- dressing: light, the Smith's things, Wren, the frost
	for c in [47, 49]:
		torch(deco, c)
	for c in [55, 60, 64, 69, 73, 78, 83, 87, 93, 96]:
		torch(deco, c, 2)
	decor(48, 5, W_BANNER_FLEUR)
	decor(78, 1, W_WINDOW_BARRED)
	decor(95, 1, W_WINDOW_MOON)
	deco_sprite(deco, "smith_plaque", Vector2(cx(54), 420.0))
	deco_sprite(deco, "chalk_steps", Vector2(3560.0, FLOOR_Y), false, -1, true)
	deco_sprite(deco, "tool_rack", Vector2(cx(80), 230.0))
	deco_sprite(deco, "coal_heap", Vector2(cx(82) + 20, 274.0), true, -1)
	deco_sprite(deco, "anvil", Vector2(cx(95) + 8, FLOOR_Y), false, 1)
	deco_sprite(deco, "bellows", Vector2(cx(96), FLOOR_Y), true, 1)
	deco_sprite(deco, "chalk_star", Vector2(cx(98) + 32, 440.0), false, -1, true)
	for spec in [[Vector2(cx(97), 120), "frost_a", false], [Vector2(cx(101) - 10, 300), "frost_b", true], [Vector2(cx(93), 70), "frost_b", false],
			[Vector2(cx(88), 200), "frost_a", false], [Vector2(cx(99), 40), "frost_a", true], [Vector2(cx(91), 430), "frost_b", false]]:
		frost(deco, spec[0], spec[1], spec[2], "kiln.r2.heart")
	waymark(room, cx(49), "right")
	waymark(room, cx(54), "right")
	for x in [60 * T, 65 * T, 70 * T]:
		waymark(room, x, "up", 470.0)
	waymark(room, cx(62) + 40, "right", 210.0)
	waymark(room, cx(67) + 40, "right", 210.0)
	waymark(room, cx(76), "right", 210.0)
	waymark(room, 5712.0, "down", 210.0)
	waymark(room, cx(94), "right")
	waymark(room, cx(98) + 32, "up", 300.0)
	prop(deco, "cobweb_corner", cx(101) + 8, 12.0, true, true)

# ================================================================ the Drowned Cistern (ice)

func build_cistern() -> void:
	begin("Cistern", "cistern", "The Drowned Cistern", Journey.CISTERN_INTERLUDE, Journey.WINGS[1]["words"])
	level.set("total_pages", 6)
	cistern_still_water()
	cistern_great_sluice()
	ledger.sort_custom(func(a, b): return a["id"] < b["id"])
	level.set("ledger", ledger)
	finish()


## A pool of the Cistern's cold water filling a trench over columns c0..c1.
func cistern_pool(room: Node, c0: int, c1: int, candle: Node) -> Node:
	pit(c0, c1)
	var centre := (c0 * T + (c1 + 1) * T) / 2.0
	return inst(TRAPS + "cistern_pool.tscn", room, "Pool%d" % c0, Vector2(centre, 598.0),
		{"tiles": c1 - c0 + 1, "recovery_checkpoint": candle})


## One of the Warden of Waters' ledger pages (the Cistern's first room has three).
func cistern_page(parent: Node, id: int, pos: Vector2, title: String, text: String) -> void:
	inst(PUZZLE + "lore_page.tscn", parent, "LorePage%d" % id, pos,
		{"page_id": "cistern.page.%d" % id, "title": title, "text": text})
	var ids: PackedStringArray = parent.get("page_ids")
	ids.append("cistern.page.%d" % id)
	parent.set("page_ids", ids)
	ledger.append({"id": "cistern.page.%d" % id, "numeral": ["i", "ii", "iii", "iv", "v", "vi"][id - 1],
		"title": title, "text": text, "room": parent.get("title")})


## THE STILL WATER. The Warden of Waters' clock hall, flooded and stopped.
## Everything here is about freezing things, and each kind of thing frozen is
## useful in its own way (scripts/runes/effects/freeze_field.gd asks anything
## "freezable"; rising water freezes where it first meets the cold):
##   The Cold Stair (cols 0-21, low): two pools of black water too cold to swim.
##     ICE and FREEZE on the Brink Cube freeze the first pool's surface into a
##     floor for a few breaths (water held still is a floor). On the island,
##     LONG on the Island Cube freezes all but a hop of the long second pool.
##   The Ice Door (col 22): a plug of old ice fills the doorway to the hall.
##     Her own fire melts it (ice gives way to fire); the Warden's cube, free,
##     waits behind it.
##   The Gatekeeper (col 34, under the walkway): a slime shut in a cell under
##     an iron grate sits on a plate that wants stone. Frozen, a creature is as
##     heavy as stone, and cold sinks through iron bars: the cube set on the
##     grate, Freeze Down, two seconds on the plate, and the Clock Gate up on
##     the walkway is open for good.
##   The Fountain Court (cols 39-42): five fountains leap and fall. Frozen, a
##     fountain is a pillar, and a jet leaping into the cold freezes where it
##     meets it. The Fountain Cube hangs high above them, worked from a lectern:
##     DOWN-RIGHT with Long lays its cold aslant across all five, freezing them
##     into a stair up to the walkway (be quick: it holds a few breaths).
##   The Tide Clock (cols 26-27): a glass column the tide fills and empties.
##     It strikes when its float is HELD at the hour mark; its strike opens the
##     Sluice Door (col 56). The cold must lie just above the mark: the Warden's
##     cube on the clock gallery, the step level with the clock's top, facing it
##     (anywhere lower, the tide freezes short of the hour, and the room says so).
## Optional: three ledger pages (a shelf over the island, the top of the
## Fountain Cube, the clock gallery's corner).
func cistern_still_water() -> void:
	shell(0, 22, LOW_CEIL, true, false)
	shell(22, 56, HIGH_CEIL, false, false)
	var room := mk_room("R1", "The Still Water", 0, 56, HIGH_CEIL, Vector2(cx(2), 530), true)
	var deco := group(room, "Decor")
	var cold := "cistern.r1.clock"

	# ---------------------------------------------------- the Cold Stair: Ice, Freeze, Long
	shrine(room, "start", cx(2))
	kindle_flame(room, cx(3))
	var tab_ice := tablet(room, "ice", cx(4), "Cold that holds its shape.")
	var tab_freeze := tablet(room, "freeze", cx(5) + 8, "What reaches the cold is held still.")
	var stair_candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleStair", Vector2(396.0, FLOOR_Y))
	var brink := cube(room, "Brink Cube", 432.0, "wind/push/right/normal", {"carryable": false, "locked_slots": LOCK_DIRECTION})
	var pool_a := cistern_pool(room, 7, 8, stair_candle)
	var island_candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleIsland", Vector2(600.0, FLOOR_Y))
	var tab_long := tablet(room, "long", 644.0, "Cold reaches further than it seems.")
	var island := cube(room, "Island Cube", 688.0, "ice/freeze/right/normal",
		{"carryable": false, "locked_slots": LOCK_ESSENCE | LOCK_FORM | LOCK_DIRECTION})
	var pool_b := cistern_pool(room, 11, 16, island_candle)
	# The Warden's notes on a shelf over the island (a charged jump)
	ledge_run(9, 9, 6, true)
	cistern_page(room, 1, Vector2(cx(9), 404.0), "The Warden's Ledger, i",
		"The Cistern measured the sky by its water: the tide filled the clock, the clock struck, and the Choir wrote down the hour. The night the Hush came every clock in the Cistern stopped at the same minute, and the water stood still.")
	inst("res://scenes/hazard_checkpoint.tscn", room, "CandleBank", Vector2(1120.0, FLOOR_Y))

	# ---------------------------------------------------- the Ice Door
	var plug := inst(RUNES + "burnable.tscn", room, "IcePlug", Vector2(cx(22), FLOOR_Y), {"kind": 1, "size": Vector2(48, 150)})
	var warden := cube(room, "Warden Cube", 1512.0, "wind/push/right/normal")

	# ---------------------------------------------------- the Clock Hall
	shrine(room, "hall", cx(24))
	kindle_flame(room, 1616.0)
	var clock := inst(PUZZLE + "tide_clock.tscn", room, "TideClock", Vector2(1728.0, FLOOR_Y), {"persist_id": cold})
	var reveal := Area2D.new()
	reveal.name = "ClockReveal"
	reveal.set_script(load("res://scripts/puzzle/reveal_trigger.gd"))
	reveal.position = Vector2(cx(23) + 24, FLOOR_Y)
	reveal.set("look_at", Vector2(1728.0, 340.0))
	reveal.set("flag", "cistern.r1.revealed")
	add_owned(room, reveal)
	# The clock gallery (level with the clock's top), the stair down to the walkway
	ledge_run(28, 29, 3, false, false, true)
	ledge_run(30, 30, 3, true)
	ledge_run(31, 31, 4)
	ledge_run(32, 38, 4, true, false, false)
	cistern_page(room, 3, Vector2(1890.0, 176.0), "The Warden's Ledger, iii",
		"To stop the clock you need only stop the water. To stop it at the hour, the cold must lie above the mark, no lower: the tide freezes where it first touches the cold. I taught every novice that, and it was still the Hush that did it best.")
	# The Clock Gate on the walkway: rock down from the roof to just over it
	for y in range(0, 3):
		solid(34, y)
	ceiling.erase_cell(Vector2i(34, 0))
	var clock_gate := inst("res://scenes/portcullis_gate.tscn", room, "ClockGate", Vector2(cx(34), 306.0), {"height": 114.0})
	# The gatekeeper: a slime shut in a cell under a grate, sitting on a plate
	# that wants stone (cold sinks through iron bars)
	grated_cell(room, 34, 34)
	var gate_plate := inst("res://scenes/pressure_plate.tscn", room, "GatePlate", Vector2(cx(34), 598.0), {"stone_only": true, "width": 56.0})
	var keeper := slime(room, "Keeper", Vector2(cx(34), 594), {"hears_bells": false, "home_radius": 1.0, "detection_range": 0.0,
		"max_health": 10, "required": true, "required_until_flag": "cistern.r1.gate",
		"required_reason": "The slime that had to hold the plate has been killed, and only something as heavy as stone can press it."})
	circuit(room, "KeeperToGate", [gate_plate], [clock_gate],
		{"latch": true, "hold_time": 2.0, "reveal_target": true, "persist_id": "cistern.r1.gate", "channel_y": 420.0, "symbol": 1})

	# ---------------------------------------------------- the Fountain Court: Down-Right
	# Five fountains, 45 px apart; frozen by cold laid aslant (Down-Right) from
	# the Fountain Cube, each where its leap first meets the cold's lower edge:
	# a stair of pillars 45 px a step, the top one level with the walkway (306).
	# (The cube's corner sits where that edge passes through the jets' tops,
	# and the lowest is still inside a Long reach; a normal one reaches three.)
	var fountains := []
	for i in 5:
		var top_y := 306.0 + 45.0 * i
		fountains.append(inst(PUZZLE + "fountain.tscn", room, "Fountain%d" % (i + 1), Vector2(2512.0 + 45.0 * i, FLOOR_Y), {
			"max_height": FLOOR_Y - top_y + 6.0, "rest_height": 14.0, "rest_time": 0.5 + 0.1 * (i % 3),
			"rise_time": 0.45, "hold_time": 1.8 + 0.25 * ((i + 1) % 3), "fall_time": 0.45, "phase": 0.7 * i}))
	var fountain_cube := cube(room, "Fountain Cube", 2517.0, "ice/freeze/down/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM}, 245.0)
	var lectern := inst(RUNES + "rune_lectern.tscn", room, "FountainLectern", Vector2(2784.0, FLOOR_Y), {"cube": fountain_cube})
	var tab_dr := tablet(room, "down_right", 2856.0, "Cold falls aslant, like rain on a wind.")
	cistern_page(room, 2, Vector2(2517.0, 196.0), "The Warden's Ledger, ii",
		"The fountains were the novices' stair. We froze them every morning, all at once, aslant, and climbed to the clock before they let go. Wren ran up them laughing and never once looked down.")

	# ---------------------------------------------------- the way on: the Sluice Door
	shrine(room, "east", cx(47))
	kindle_flame(room, cx(48))
	var door := gate(room, "SluiceDoor", 56)
	circuit(room, "ClockToDoor", [clock], [door],
		{"latch": true, "reveal_target": true, "persist_id": "cistern.r1.door", "channel_y": 96.0, "symbol": 2})

	# ---------------------------------------------------- the goal and its steps
	guide(room, "Open the Sluice Door.", "I", "The Still Water", "The Long Stair  ·  The Drowned Cistern")
	step(room, "Freeze learned", Cond.FLAG, null, {"flag": "rune.frag.freeze"})
	step(room, "Across the first pool", Cond.REACHED, null, {"area": Rect2(576, 480, 128, 70)})
	step(room, "Long learned", Cond.FLAG, null, {"flag": "rune.frag.long"})
	step(room, "Across the second pool", Cond.REACHED, null, {"area": Rect2(1088, 480, 320, 70)})
	step(room, "The old ice melts", Cond.OPEN, plug)
	step(room, "A frozen slime holds the plate: the Clock Gate opens", Cond.OPEN, clock_gate)
	step(room, "Down-Right learned", Cond.FLAG, null, {"flag": "rune.frag.down_right"})
	step(room, "Up the frozen fountains to the walkway", Cond.REACHED, null, {"area": Rect2(2048, 262, 448, 60)})
	step(room, "The tide held at the hour: the clock strikes", Cond.POWERED, clock)
	step(room, "The Sluice Door opens", Cond.OPEN, door)
	for i in 3:
		step(room, "Ledger page %s found" % ["i", "ii", "iii"][i], Cond.FLAG, null,
			{"flag": "cistern.page.%d" % (i + 1), "optional": true})

	hint(room, Vector2(cx(1), FLOOR_Y), [
		"The water is far too cold to swim. The cube at its edge can hold it still.",
		"Read the tablets: Ice and Freeze. Cold that reaches the water turns its top to ice for a few breaths, solid enough to walk on.",
		"Inscribe Ice and Freeze on the Brink Cube, switch it on and cross before the ice gives way. On the island, Long carries the cold nearly twice as far: run along the ice and jump the last stretch.",
	], [brink, island, pool_a, pool_b, tab_ice, tab_freeze, tab_long])
	hint(room, Vector2(1200.0, FLOOR_Y), [
		"A plug of old ice fills the doorway to the hall.",
		"Ice holds against cold. It doesn't hold against fire.",
		"Throw a fireball at the ice. The cube behind it is yours to carry.",
	], [plug, warden])
	hint(room, Vector2(2120.0, FLOOR_Y), [
		"The gate up on the walkway opens while the plate in the cell under this grate is held down by something heavy. The slime shut in with it isn't heavy enough.",
		"What the cold holds still is as heavy as stone. And cold sinks through iron bars.",
		"Set your cube down on the grate, right over the slime, inscribe Ice, Freeze, Down and switch it on. Two seconds on the plate and the gate stays open.",
	], [gate_plate, keeper, clock_gate])
	hint(room, Vector2(2928.0, FLOOR_Y), [
		"The fountains leap and fall. Frozen, a fountain is a pillar you can stand on.",
		"A jet that leaps into the cold freezes where it first meets it. The cube high above the fountains is worked from the lectern; its cold can only fall from up there. Which way, to touch every fountain at a different height?",
		"At the lectern: Down-Right and Long. The cold falls aslant across all five and freezes them into a stair up to the walkway. Climb quickly; it holds a few breaths.",
	], [fountain_cube, lectern, tab_dr] + fountains)
	hint(room, Vector2(1640.0, FLOOR_Y), [
		"The Sluice Door opens when the tide clock strikes. It strikes only when its float is held still at the hour mark at the top.",
		"Rising water freezes where it first touches the cold. Cold across the column stops the tide short of the mark; cold just above the mark stops it at the hour.",
		"Carry the cube up to the clock gallery, the step level with the top of the clock, set it down facing the clock and inscribe Ice, Freeze, Left. The cold lasts a few breaths: switch it on as the tide starts to rise.",
	], [clock, door])

	# ---------------------------------------------------- dressing: light, the Warden's things, Wren, the Hush's frost
	for c in [1, 6, 12, 18]:
		torch(deco, c)
	for c in [24, 30, 37, 44, 50, 54]:
		torch(deco, c, 2)
	torch(deco, 52)
	decor(10, 5, W_BANNER_FLEUR)
	decor(20, 5, W_WINDOW_BARRED)
	decor(32, 1, W_WINDOW_MOON)
	decor(46, 2, W_WINDOW_BARRED)
	deco_sprite(deco, "warden_plaque", Vector2(cx(19), 470.0))
	for x in [cx(29), cx(45) + 16, cx(53)]:
		deco_sprite(deco, "cistern_pipe", Vector2(x, FLOOR_Y), false, -2)
	deco_sprite(deco, "chalk_steps", Vector2(620.0, FLOOR_Y), false, -1, true)
	deco_sprite(deco, "chalk_steps", Vector2(2740.0, FLOOR_Y), true, -1, true)
	deco_sprite(deco, "chalk_star", Vector2(1846.0, 160.0), false, -1, true)
	for spec in [[Vector2(1580, 300), "frost_a", false], [Vector2(1880, 110), "frost_b", true], [Vector2(2300, 150), "frost_a", true],
			[Vector2(2700, 260), "frost_b", false], [Vector2(3200, 330), "frost_a", false], [Vector2(3480, 180), "frost_b", true]]:
		frost(deco, spec[0], spec[1], spec[2], cold)
	waymark(room, cx(5) + 40, "right")
	waymark(room, cx(10), "right")
	waymark(room, cx(20) + 32, "right")
	waymark(room, cx(36), "right")
	waymark(room, 2696.0, "up", 420.0)
	waymark(room, 2420.0, "left", 240.0)
	waymark(room, 1960.0, "up", 180.0)
	waymark(room, cx(51), "right")
	prop(deco, "cobweb_corner", cx(55) + 8, 12.0, true, true)


## THE GREAT SLUICE. The Warden's sluice works, which fed every water clock in
## the Cistern. The Warden drowned the Tide Bell in its well and balanced the
## Great Sluice that drains it on two counterweights: a weight of three held
## still on a pan, and the tide held at its high mark. Here she learns PERSIST,
## "the word that made the silence" (the Warden carved it for Ilse), and uses
## the Hush's own word to make the bell ring. Columns 56-119:
##   The Silence Gallery (56-74, low): a slime in a cell under a grate holds a
##     plate that opens the Silence Gate only after eight seconds; a freeze
##     lasts six. Persist on the Keeper Cube (cold that never lets go).
##   The Tide Hall (75-94): an 18-tile basin set with iron teeth, whose tide
##     (scripts/traps/tide_pool.gd) fills it, holds, empties and stays dry, over
##     and over. The Tide Lever (a mounted cube over the west doorway, its cold
##     reaching down to just under the doorways, worked from a lectern at
##     either doorway or on the high ledge, paid for with her mana) freezes the
##     whole tide: a floor of ice. Switched on while the hall is dry, the
##     rising tide freezes as it reaches the cold, just under the doorways;
##     switched on while the tide is up, it freezes where it stands. Its own
##     freeze lasts six seconds, too short to cross: Persist holds it while she
##     walks across, hopping the low pier for the Sluice Cube. The doorway
##     gates are open only while the floor is dry or frozen below them. The
##     high mark wants the tide frozen at its very top (from the high ledge,
##     where she can see it); the far pier (a page) wants it frozen on its way
##     down, a little below the pier's top.
##   The Weigh House (95-108): a pan that wants three weights of stone at once:
##     the Ballast, pushed off its shelf by the Drover Cube (it needs a Strong
##     wind; a kerb by the Bell Well's wall stops it on the pan), and the two
##     slimes that hop about on the pan, frozen as they stray into the cold of
##     the Sluice Cube set in the socket under the shelf (Ice, Freeze, Right,
##     Persist: free on the socket, and held, or they thaw). A lift to the High
##     Walk and the high ledge.
##   The Bell Well (109-118): the Tide Bell drowned in its tank. The Great
##     Sluice opens (two breaths of both counterweights, then for good, saved)
##     with the pan weighed and the tide held at its high mark; the well drains
##     through the sluice gate. The High Walk's span over the pan has fallen:
##     with the sluice open the pan's work is done, so the Sluice Cube comes out
##     of its socket and, set at the edge, bridges the gap (Ice, Bridge, Right).
##     She drops into the well from the far end and rings the bell.
## Optional: three ledger pages (a shelf in the gallery, the far pier, and the
## outflow past the sluice gate).
func cistern_great_sluice() -> void:
	var o := 56
	shell(o, o + 19, LOW_CEIL, false, false)
	shell(o + 19, o + 38, HIGH_CEIL, false, false)
	shell(o + 38, o + 63, HIGH_CEIL, false, true)
	var room := mk_room("R2", "The Great Sluice", o, o + 63, HIGH_CEIL, Vector2(cx(o + 1), 530), true)
	var deco := group(room, "Decor")
	var drained := "cistern.r2.well"
	# The high ledge and the High Walk (cap tiles in row 2)
	var high_walk := 146.0

	# ---------------------------------------------------- the Silence Gallery: Persist
	shrine(room, "sluice", cx(o + 2))
	kindle_flame(room, cx(o + 3))
	var tab_persist := tablet(room, "persist", cx(o + 5), "The cold that never lets go.")
	ledge_run(o + 6, o + 6, 6, true)
	cistern_page(room, 4, Vector2(cx(o + 6), 404.0), "The Warden's Ledger, iv",
		"Ilse came to me the winter before the Hush and asked for the word that holds water still for ever. I carved PERSIST for her on the sluice, the way I carve all the words. I did not ask what she meant to hold still. I have asked every day since.")
	grated_cell(room, o + 10, o + 10)
	var cell_plate := inst("res://scenes/pressure_plate.tscn", room, "CellPlate", Vector2(cx(o + 10), 598.0), {"stone_only": true, "width": 56.0})
	var keeper := slime(room, "Keeper", Vector2(cx(o + 10), 594), {"hears_bells": false, "home_radius": 1.0, "detection_range": 0.0,
		"max_health": 10, "required": true, "required_until_flag": "cistern.r2.silence",
		"required_reason": "The slime that had to hold the slow plate has been killed, and only something as heavy as stone can press it."})
	var keeper_cube := cube(room, "Keeper Cube", cx(o + 10), "ice/freeze/down/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM | LOCK_DIRECTION})
	var silence_gate := gate(room, "SilenceGate", o + 15)
	circuit(room, "SlowPlate", [cell_plate], [silence_gate],
		{"latch": true, "hold_time": 8.0, "reveal_target": true, "persist_id": "cistern.r2.silence", "channel_y": 420.0, "symbol": 0})
	var west_candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleWest", Vector2(cx(o + 17), FLOOR_Y))

	# ---------------------------------------------------- the Tide Hall
	pit(o + 20, o + 37)
	# The low pier (a hop up from ice at the doorways) holds the Sluice Cube;
	# the far pier floats high (a page), above anything frozen low
	for x in [o + 25, o + 26]:
		solid(x, 8)
		solid(x, 9)
		ground_half.set_cell(Vector2i(x, 7), 0, LEDGES[x % LEDGES.size()])
	ledge_run(o + 30, o + 31, 4)
	# The high door in the east wall, onto the high ledge (the high mark is
	# carved on the wall under it)
	for y in [0, 1, 2]:
		earth.erase_cell(Vector2i(o + 38, y))
	var east_candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleEast", Vector2(cx(o + 40), FLOOR_Y))
	inst("res://scenes/hazard_checkpoint.tscn", room, "CandleHigh", Vector2(cx(o + 44), high_walk))
	var candle_paths: Array[NodePath] = [NodePath("../CandleWest"), NodePath("../CandleEast"), NodePath("../CandleHigh")]
	# The basin's iron teeth: no crossing the dry floor
	inst("res://scenes/spike_trap.tscn", room, "TeethWest", Vector2((o + 20) * T + 160.0, 598.0),
		{"spike_count": 10, "damage_amount": 1, "recovery_checkpoint": west_candle})
	inst("res://scenes/spike_trap.tscn", room, "TeethEast", Vector2((o + 27) * T + 352.0, 598.0),
		{"spike_count": 22, "damage_amount": 1, "recovery_checkpoint": east_candle})
	var tide := inst(TRAPS + "tide_pool.tscn", room, "Tide", Vector2((o + 29) * T, 598.0), {
		"tiles": 18, "low_level": -14.0, "high_level": 372.0, "rise_time": 6.0, "hold_high": 2.5, "fall_time": 5.0, "hold_low": 7.0,
		"recovery_checkpoints": candle_paths, "flush_with": PackedFloat32Array([float(FLOOR_Y)])})
	var floor_mark := inst(PUZZLE + "tide_mark.tscn", room, "FloorMark", Vector2(cx(o + 19), 528.0),
		{"pool": NodePath("../Tide"), "mode": 0, "visible_mark": false})
	var high_mark := inst(PUZZLE + "tide_mark.tscn", room, "HighMark", Vector2((o + 38) * T - 4.0, 244.0),
		{"pool": NodePath("../Tide"), "mode": 1, "slack": 8.0})
	var west_gate := gate(room, "WestTideGate", o + 19)
	var east_gate := gate(room, "EastTideGate", o + 38)
	circuit(room, "TideToWestGate", [floor_mark], [west_gate], {"channel_y": 560.0, "symbol": 1, "solved_sound": "", "show_channels": false})
	circuit(room, "TideToEastGate", [floor_mark], [east_gate], {"channel_y": 560.0, "symbol": 1, "solved_sound": "", "show_channels": false})
	# The Tide Lever: a cube on a bracket over the west doorway, its cold
	# reaching down to just under the doorways; worked from three lecterns
	# (her mana pays for it)
	var lever := cube(room, "Tide Lever", cx(o + 20), "ice/freeze/down/normal",
		{"carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM}, 378.0)
	var west_lectern := inst(RUNES + "rune_lectern.tscn", room, "WestLectern", Vector2(cx(o + 18), FLOOR_Y), {"cube": lever})
	var east_lectern := inst(RUNES + "rune_lectern.tscn", room, "EastLectern", Vector2(cx(o + 39), FLOOR_Y), {"cube": lever})
	var high_lectern := inst(RUNES + "rune_lectern.tscn", room, "HighLectern", Vector2(cx(o + 40), high_walk), {"cube": lever})
	var sluice_cube := cube(room, "Sluice Cube", (o + 26) * T, "wind/push/right/normal", {}, 502.0)
	cistern_page(room, 6, Vector2((o + 31) * T + 32.0, 248.0), "The Warden's Ledger, vi",
		"The girl drew a star on the far pier at low tide and dared me to freeze the sea so she could reach it. I did. She stood on the ice and laughed and said the water was holding its breath.")
	# The Warden's own lectern on the far pier: the way back down (the next
	# tide frozen level with the doorways)
	inst(RUNES + "rune_lectern.tscn", room, "PierLectern", Vector2((o + 30) * T + 20.0, 274.0), {"cube": lever})
	var reveal := Area2D.new()
	reveal.name = "TideReveal"
	reveal.set_script(load("res://scripts/puzzle/reveal_trigger.gd"))
	reveal.position = Vector2(cx(o + 17), FLOOR_Y)
	reveal.set("look_at", Vector2((o + 29) * T, 400.0))
	reveal.set("flag", "cistern.r2.revealed")
	add_owned(room, reveal)
	# The high ledge (through the high door, over the hall) and the High Walk
	# east over the Weigh House to the Bell Well, a gap between where the lift
	# comes up; the Walk's span over the pan has fallen (three tiles: an ice
	# bridge from the edge crosses it, a jump doesn't)
	ledge_run(o + 37, o + 40, 2, false, true, false)
	ledge_run(o + 43, o + 47, 2, false, false, true)
	ledge_run(o + 51, o + 53, 2)

	# ---------------------------------------------------- the Weigh House
	inst(TRAPS + "moving_platform.tscn", room, "WeighLift", Vector2((o + 41) * T, FLOOR_Y - 18),
		{"width_tiles": 2, "travel": Vector2(0, high_walk - FLOOR_Y), "speed": 70.0, "end_pause": 1.4})
	shrine(room, "weigh", cx(o + 43))
	kindle_flame(room, cx(o + 44))
	# The Ballast's shelf with its Drover at the far end; under it the pan's
	# socket, and the pan running east to a kerb by the Bell Well's wall (which
	# stops a stone shoved along it, so it comes to rest on the pan)
	var drover_lectern := inst(RUNES + "rune_lectern.tscn", room, "DroverLectern", Vector2(cx(o + 45), FLOOR_Y))
	ledge_run(o + 46, o + 48, 6)
	var drover := cube(room, "Drover Cube", (o + 46) * T + 32.0, "wind/push/right/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM | LOCK_DIRECTION}, 402.0)
	drover_lectern.set("cube", drover)
	var ballast := stone(room, "Ballast", (o + 49) * T - 28.0, {"required": true, "required_until_flag": "cistern.r2.sluice",
		"required_reason": "The ballast stone fell where it can't be put on the pan.",
		"required_area": Rect2(6500.0, 380.0, 476.0, 170.0)}, 402.0)
	var pedestal := inst(RUNES + "rune_pedestal.tscn", room, "WeighPedestal", Vector2((o + 49) * T - 60.0, FLOOR_Y))
	var pan := inst("res://scenes/pressure_plate.tscn", room, "WeighPan", Vector2((o + 49) * T + 76.0, FLOOR_Y),
		{"stone_only": true, "width": 232.0, "weight_needed": 3})
	ground_half.set_cell(Vector2i(o + 52, 7), 0, LEDGES[(o + 52) % LEDGES.size()])
	# The Warden's two live weights, hopping about on the pan: too light alive
	var needed := {"hears_bells": false, "detection_range": 0.0, "home_radius": 50.0, "max_health": 10, "required": true,
		"required_until_flag": "cistern.r2.sluice",
		"required_reason": "A slime the pan needed has been killed, and only creatures held still by the cold can make up its weight."}
	var weigher_a := slime(room, "WeigherA", Vector2((o + 49) * T + 60.0, 530), needed)
	var weigher_b := slime(room, "WeigherB", Vector2((o + 49) * T + 120.0, 530), needed)

	# ---------------------------------------------------- the Bell Well and the Great Sluice
	# The tank: a wall each side, its floor a pit at 598; the sluice gate at the
	# foot of its east wall lets the water out into the outflow
	for y in range(3, 9):
		solid(o + 53, y)
	pit(o + 54, o + 62)
	for y in range(3, 7):
		solid(o + 59, y)
	var well := inst(TRAPS + "tide_pool.tscn", room, "BellWell", Vector2((o + 54) * T + 160.0, 598.0), {
		"tiles": 5, "still": true, "high_level": 298.0, "low_level": -14.0, "persist_id": drained,
		"recovery_checkpoints": candle_paths})
	var sluice_gate := inst("res://scenes/portcullis_gate.tscn", room, "GreatSluiceGate", Vector2(cx(o + 59), 598.0), {"height": 150.0})
	var bell := inst(PUZZLE + "great_bell.tscn", room, "GreatBell", Vector2(cx(o + 56) - 46.0, 478.0),
		{"announce": "The Tide Bell rings out.", "announce_sub": "Water runs again through every channel, and the Cistern breathes.",
		"tolls": 2, "chain_length": 462.0})
	circuit(room, "GreatSluice", [pan, high_mark], [well, sluice_gate],
		{"latch": true, "hold_time": 2.0, "reveal_target": true, "persist_id": "cistern.r2.sluice", "channel_y": 96.0, "symbol": 2})
	cistern_page(room, 5, Vector2(cx(o + 61), 566.0), "The Warden's Ledger, v",
		"I balanced the Great Sluice on two counterweights: a weight of three held still on the pan, and the tide held at its height. Then I drowned the Tide Bell in its well, so the Hush would not hear it ring. If you are reading this, ring it. Let it hear.")

	# ---------------------------------------------------- the goal and its steps
	guide(room, "Drain the Bell Well and ring the Tide Bell.", "II", "The Great Sluice", "The Long Stair  ·  The Drowned Cistern")
	step(room, "Persist learned", Cond.FLAG, null, {"flag": "rune.frag.persist"})
	step(room, "The slow plate held: the Silence Gate opens", Cond.OPEN, silence_gate)
	step(room, "The Sluice Cube, from the low pier", Cond.REACHED, null, {"area": Rect2((o + 25) * T, 440, 2 * T, 70)})
	step(room, "Across the Tide Hall", Cond.REACHED, null, {"area": Rect2((o + 39) * T, 480, 4 * T, 70)})
	step(room, "Three weights on the pan", Cond.POWERED, pan)
	step(room, "Up to the High Walk", Cond.REACHED, null, {"area": Rect2((o + 37) * T, high_walk - 50.0, 17 * T, 70)})
	step(room, "The tide held at its high mark", Cond.POWERED, high_mark)
	step(room, "The Great Sluice opens: the well drains", Cond.POWERED, well)
	step(room, "Over the fallen span", Cond.REACHED, null, {"area": Rect2((o + 51) * T, high_walk - 50.0, 3 * T, 70)})
	step(room, "The Tide Bell rings", Cond.POWERED, bell)
	for i in 3:
		step(room, "Ledger page %s found" % ["iv", "v", "vi"][i], Cond.FLAG, null,
			{"flag": "cistern.page.%d" % (i + 4), "optional": true})

	hint(room, Vector2(cx(o + 8), FLOOR_Y), [
		"The plate in the cell opens the gate, but only once it has been held down a long while. A freeze lets go too soon.",
		"Read the tablet by the door. Persist: cold that never lets go, for as long as its cube is on.",
		"Inscribe Persist on the cube over the grate and switch it on. Wait: the slime stays frozen, and after a few breaths the gate grinds open for good.",
	], [keeper_cube, keeper, cell_plate, silence_gate, tab_persist])
	hint(room, Vector2(cx(o + 16), FLOOR_Y), [
		"The tide fills the hall and empties it, over and over, and the floor under it is iron teeth. While the water is up, the doorway gates stay shut.",
		"The Tide Lever over the doorway, worked from this lectern, freezes the tide into a floor of ice. Switched on while the hall is dry, the rising tide freezes as it reaches the cold, just under the doorway. But its freeze lets go after six seconds.",
		"Inscribe Persist on the lever and switch it on while the hall is dry: the rising tide freezes just under the doorway and holds while your mana lasts. Walk across, hop the low pier for the Sluice Cube, and go on. Switch it off from your runes (Tab) once you're over.",
	], [lever, west_lectern, tide, west_gate, east_gate, sluice_cube])
	hint(room, Vector2(cx(o + 39), high_walk), [
		"Every ledge in the hall wants the tide frozen at its own height.",
		"From up here you can watch the tide stand at its top, beside the high mark on the wall. Switched on while the tide is up, the lever freezes it where it stands.",
		"Switch the lever on from this lectern while the tide stands at its very top: it freezes at the high mark. The far pier wants it frozen on its way down, a little below the pier's top.",
	], [lever, high_lectern, tide, high_mark])
	hint(room, Vector2(cx(o + 45) + 88.0, FLOOR_Y), [
		"The pan wants three weights of stone at once. The stone on the shelf and the two slimes make three.",
		"A steady wind can't shift the stone: it takes a Strong one. A frozen slime is as heavy as stone, but it thaws unless the cold persists.",
		"Strong on the Drover Cube (its lectern is by the flame) pushes the stone off its shelf; the kerb stops it on the pan. Set the Sluice Cube in the socket under the shelf with Ice, Freeze, Persist (it already faces the pan): the slimes freeze as they hop into its cold, and stay frozen.",
	], [pan, ballast, drover, drover_lectern, pedestal, weigher_a, weigher_b])
	hint(room, Vector2(cx(o + 46), high_walk), [
		"The Tide Bell is drowned in its well, past the fallen span. The Great Sluice drains it, but only while both its counterweights hold: the pan weighed, and the tide held still at its high mark.",
		"Hold the pan first, with the slimes frozen on it; then the tide at its very top, from the high ledge. Once the sluice opens it stays open, and the pan's work is done.",
		"With the pan held, freeze the tide at its top with the Tide Lever and Persist: two breaths of both, and the sluice opens for good. Then switch the Sluice Cube off, take it from its socket, set it at the edge of the fallen span and write Ice, Bridge, Right.",
	], [well, sluice_gate, pan, high_mark, bell, east_lectern])

	# ---------------------------------------------------- dressing
	for c in [1, 7, 13]:
		torch(deco, o + c)
	for c in [21, 27, 34, 55, 61]:
		torch(deco, o + c, 2)
	for c in [44, 50]:
		torch(deco, o + c, 1)
	decor(o + 4, 5, W_BANNER_FLEUR)
	decor(o + 29, 1, W_WINDOW_MOON)
	decor(o + 49, 1, W_WINDOW_BARRED)
	deco_sprite(deco, "warden_plaque", Vector2(cx(o + 12), 470.0))
	for p in [Vector2(cx(o + 14), FLOOR_Y), Vector2(cx(o + 47), FLOOR_Y), Vector2(cx(o + 62), 598.0)]:
		deco_sprite(deco, "cistern_pipe", p, false, -2)
	deco_sprite(deco, "chalk_star", Vector2((o + 30) * T + 32.0, 230.0), false, -1, true)
	deco_sprite(deco, "chalk_steps", Vector2(cx(o + 9), FLOOR_Y), false, -1, true)
	for spec in [[Vector2(cx(o + 42), 60), "frost_a", false], [Vector2(cx(o + 47), 250), "frost_b", true], [Vector2(cx(o + 55), 90), "frost_a", true],
			[Vector2(cx(o + 58), 200), "frost_b", false], [Vector2(cx(o + 62), 330), "frost_a", false]]:
		frost(deco, spec[0], spec[1], spec[2], drained)
	waymark(room, cx(o + 6) + 32, "right")
	waymark(room, cx(o + 13), "right")
	waymark(room, cx(o + 40), "right")
	waymark(room, cx(o + 43), "up", 420.0)
	waymark(room, cx(o + 46), "right", high_walk - 60.0)
	waymark(room, cx(o + 54), "down", 200.0)
	prop(deco, "cobweb_corner", cx(o + 62) + 8, 12.0, true, true)


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
