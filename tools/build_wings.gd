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
		[PUZZLE + "hall_lamp.tscn", "HallLamp", Node2D, "res://scripts/puzzle/hall_lamp.gd"],
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
	var names := ["Kilnworks", "Cistern", "Lampworks", "Galleries", "The Eye"]
	for i in 5:
		inst(PUZZLE + "landing_door.tscn", room, "Door%d" % (i + 1), Vector2(cx(8 + i * 5), FLOOR_Y),
			{"index": i, "tint": DOOR_TINTS[i], "label_text": names[i]})
	guide(room, "Ring the bell in each of the four wings.", "", "", "")
	var signs := group(room, "Signs")
	add_sign(signs, "Choir", 5.6, "The Choir's last note: We sealed the Eye with four bells, so only one who has walked every wing, and learned every word, can open it. Ring the Forge Bell first: its heat runs in the pipes behind every door and thaws the next.", FLOOR_Y, 210.0)
	add_sign(signs, "Chalk", 29.5, "A chalk star, and below it: if you get lost, look up. And don't be afraid of the cold. -W", FLOOR_Y, 170.0, true)
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
## the Cistern. The Warden drowned the Tide Bell in its well and set the Great
## Sluice that drains it on a weigh pan: hold its weight still and the sluice
## opens. Here she learns PERSIST, "the word that made the silence" (the Warden
## carved it for Ilse), and uses the Hush's own word to make the bell ring.
## Reworked 2026-10-07 to be simpler and clearer (one counterweight, no timing
## at the tide's top, a free lever, no ballast or fallen span). Columns 56-119:
##   The Silence Gallery (56-74, low): a slime in a cell under a grate holds a
##     plate that opens the Silence Gate only after eight seconds; a freeze
##     lasts six. Persist on the Keeper Cube (cold that never lets go).
##   The Tide Hall (75-94): an 18-tile basin set with iron teeth, whose tide
##     (scripts/traps/tide_pool.gd) fills it, holds, empties and stays dry, over
##     and over. The Tide Lever (a mounted cube over the west doorway, fed by
##     the dungeon, worked from a lectern at either doorway) freezes the whole
##     tide: a floor of ice. Switched on while the hall is dry, the rising tide
##     freezes as it reaches the cold, level with the doorways. Its own freeze
##     lasts six seconds, too short to cross: Persist holds it while she walks
##     across, hopping the low pier for the Sluice Cube. The doorway gates are
##     open only while the floor is dry or frozen below them.
##   The Weigh House (95-108): the pan of the Great Sluice wants two weights
##     of stone: the two slimes that hop about on it, frozen by the Sluice Cube
##     set in the socket at its end (Ice, Freeze, Right, Persist: free on the
##     socket).
##     Held a moment, the sluice opens for good (saved) and the Bell Well drains
##     through the sluice gate. A lift to the High Walk.
##   The Bell Well (109-118): the Tide Bell drowned in its tank. From the end of
##     the High Walk she drops into the drained well and rings it.
## Optional: three ledger pages (a shelf in the gallery, the far pier, and the
## outflow past the sluice gate). The far pier wants the tide frozen on its way
## down, a little below the pier's top, from the high ledge over the hall
## (through the high door off the lift); a lectern on the pier brings her down.
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
	# The high door in the east wall, onto the high ledge (for the far pier)
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
		"tiles": 18, "low_level": -14.0, "high_level": 372.0, "rise_time": 6.0, "hold_high": 2.5, "fall_time": 5.0, "hold_low": 4.0,
		"recovery_checkpoints": candle_paths, "flush_with": PackedFloat32Array([float(FLOOR_Y)])})
	var floor_mark := inst(PUZZLE + "tide_mark.tscn", room, "FloorMark", Vector2(cx(o + 19), 528.0),
		{"pool": NodePath("../Tide"), "mode": 0, "visible_mark": false})
	var west_gate := gate(room, "WestTideGate", o + 19)
	var east_gate := gate(room, "EastTideGate", o + 38)
	circuit(room, "TideToWestGate", [floor_mark], [west_gate], {"channel_y": 560.0, "symbol": 1, "solved_sound": "", "show_channels": false})
	circuit(room, "TideToEastGate", [floor_mark], [east_gate], {"channel_y": 560.0, "symbol": 1, "solved_sound": "", "show_channels": false})
	# The Tide Lever: a cube on a bracket over the west doorway, fed by the
	# dungeon, its cold reaching down to just under the doorways; worked from
	# a lectern at either doorway (and the far pier's and the high ledge's)
	var lever := cube(room, "Tide Lever", cx(o + 20), "ice/freeze/down/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM}, 378.0)
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
	# The high ledge (through the high door, over the hall; for the far pier)
	# and the High Walk east over the Weigh House to the Bell Well, a gap
	# between where the lift comes up
	ledge_run(o + 37, o + 40, 2, false, true, false)
	ledge_run(o + 43, o + 53, 2, false, false, true)

	# ---------------------------------------------------- the Weigh House
	inst(TRAPS + "moving_platform.tscn", room, "WeighLift", Vector2((o + 41) * T, FLOOR_Y - 18),
		{"width_tiles": 2, "travel": Vector2(0, high_walk - FLOOR_Y), "speed": 70.0, "end_pause": 1.4})
	shrine(room, "weigh", cx(o + 43))
	# The Great Sluice's weigh pan, its socket at the west end
	var pedestal := inst(RUNES + "rune_pedestal.tscn", room, "WeighPedestal", Vector2((o + 49) * T - 60.0, FLOOR_Y))
	var pan := inst("res://scenes/pressure_plate.tscn", room, "WeighPan", Vector2((o + 49) * T + 76.0, FLOOR_Y),
		{"stone_only": true, "width": 232.0, "weight_needed": 2})
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
	circuit(room, "GreatSluice", [pan], [well, sluice_gate],
		{"latch": true, "hold_time": 2.0, "reveal_target": true, "persist_id": "cistern.r2.sluice", "channel_y": 96.0, "symbol": 2})
	cistern_page(room, 5, Vector2(cx(o + 61), 566.0), "The Warden's Ledger, v",
		"I set the Great Sluice on a weigh pan and gave it two live weights that would never keep still. Then I drowned the Tide Bell in its well, so the Hush would not hear it ring. If you are reading this, hold them still and ring it. Let it hear.")

	# ---------------------------------------------------- the goal and its steps
	guide(room, "Drain the Bell Well and ring the Tide Bell.", "II", "The Great Sluice", "The Long Stair  ·  The Drowned Cistern")
	step(room, "Persist learned", Cond.FLAG, null, {"flag": "rune.frag.persist"})
	step(room, "The slow plate held: the Silence Gate opens", Cond.OPEN, silence_gate)
	step(room, "The Sluice Cube, from the low pier", Cond.REACHED, null, {"area": Rect2((o + 25) * T, 440, 2 * T, 70)})
	step(room, "Across the Tide Hall", Cond.REACHED, null, {"area": Rect2((o + 39) * T, 480, 4 * T, 70)})
	step(room, "Both slimes frozen on the pan", Cond.POWERED, pan)
	step(room, "The Great Sluice opens: the well drains", Cond.POWERED, well)
	step(room, "Up to the High Walk", Cond.REACHED, null, {"area": Rect2((o + 37) * T, high_walk - 50.0, 17 * T, 70)})
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
		"The Tide Lever over the doorway, worked from this lectern, freezes the tide into a floor of ice: switched on while the hall is dry, the rising tide freezes level with the doorway. But its freeze lets go after six seconds.",
		"Inscribe Persist on the lever and switch it on while the hall is dry: the tide freezes level with the doorway and holds. Walk across, hop the low pier for the Sluice Cube, and go on.",
	], [lever, west_lectern, tide, west_gate, east_gate, sluice_cube])
	hint(room, Vector2(cx(o + 39), high_walk), [
		"The far pier, with its page, stands too high for ice at the doorways.",
		"From up here you can watch the tide fall. Switched on while the tide is up, the lever freezes it where it stands.",
		"Switch the lever on from this lectern as the falling tide passes a little below the pier's top, then drop onto the ice and hop up. The lectern on the pier brings you down again: switch it on while the hall is dry.",
	], [lever, high_lectern, tide])
	hint(room, Vector2(cx(o + 45) + 88.0, FLOOR_Y), [
		"The Great Sluice's pan wants two weights of stone. The two slimes hopping on it are too light alive.",
		"A frozen creature is as heavy as stone, but it thaws unless the cold persists. The socket at the end of the pan feeds any cube set in it.",
		"Set the Sluice Cube in the socket and inscribe Ice, Freeze and Persist (it already faces the pan). Switch it on: the slimes freeze as they hop into the cold and stay frozen, the pan sinks, and the Great Sluice opens for good.",
	], [pan, pedestal, weigher_a, weigher_b, sluice_gate])
	hint(room, Vector2(cx(o + 46), high_walk), [
		"The Tide Bell is drowned in its well at the end of the High Walk.",
		"The Great Sluice drains the well once its pan is weighed down.",
		"Weigh the pan with the slimes frozen on it, ride the lift up, walk to the end of the High Walk and drop into the drained well. Pull the rope.",
	], [well, sluice_gate, pan, bell, east_lectern])

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

## Where the Hall of Lamps' parts begin (columns): the Mirror Gallery, the
## Watchers' Walk, the Watch Lamp's chamber, the Dark Stacks, the Great Lamp,
## and its end (the Lamp Door, where the Lamp Stair begins).
const HALL_GALLERY := 16
const HALL_WALK := 33
const HALL_WATCH := 50
const HALL_STACKS := 59
const HALL_GREAT := 81
const HALL_END := 96


func build_lamps() -> void:
	begin("Lamps", "lamps", "The Lampworks", Journey.LAMPS_INTERLUDE, Journey.WINGS[2]["words"])
	level.set("total_pages", 3)
	lamps_hall()
	lamps_stair(HALL_END - 22)
	ledger.sort_custom(func(a, b): return a["id"] < b["id"])
	level.set("ledger", ledger)
	finish()


## One of the Lamplighter's ledger pages (the Hall of Lamps has three).
func lamps_page(parent: Node, id: int, pos: Vector2, title: String, text: String) -> void:
	inst(PUZZLE + "lore_page.tscn", parent, "LorePage%d" % id, pos,
		{"page_id": "lamps.page.%d" % id, "title": title, "text": text})
	var ids: PackedStringArray = parent.get("page_ids")
	ids.append("lamps.page.%d" % id)
	parent.set("page_ids", ids)
	ledger.append({"id": "lamps.page.%d" % id, "numeral": ["i", "ii", "iii"][id - 1],
		"title": title, "text": text, "room": parent.get("title")})


## A hanging lamp of the hall (scripts/puzzle/hall_lamp.gd), dark until a
## circuit powers it. `at` is where its chain meets it.
func hall_lamp(room: Node, lamp_name: String, at: Vector2, chain: float, sprite := "hall_lamp") -> Node:
	return inst(PUZZLE + "hall_lamp.tscn", room, lamp_name, at, {"sprite_name": sprite, "chain_length": chain})


## The camera glances at `look` the first time ever she walks past x.
func lamps_reveal(room: Node, reveal_name: String, x: float, look: Vector2, flag: String) -> void:
	var reveal := Area2D.new()
	reveal.name = reveal_name
	reveal.set_script(load("res://scripts/puzzle/reveal_trigger.gd"))
	reveal.position = Vector2(x, FLOOR_Y)
	reveal.set("look_at", look)
	reveal.set("flag", flag)
	add_owned(room, reveal)


## THE HALL OF LAMPS. The reading halls where the Choir read the sky by
## lamplight. The Lamplighter put the lamps out the night Ilse went down to the
## Eye, and the monks who walk the dark now are the Watchers: light does not
## hurt them, it holds them still. Each part teaches one thing about light and
## ends with a lamp lit, which opens the way on (the three hall lamps also show
## over the Lamp Door). No timing anywhere: every light stays on while its cube
## or its fire does. Reset Room brings her back to the last shrine she lit.
##   The Reading Room (cols 0-16, low): Light and Beam on the Reading Cube
##     cross a spiked pit to a crystal; a bridge of light forms.
##   The Mirror Gallery (16-33): the Gallery Cube's beam (Light, Beam, Right,
##     carved) stops at the first mirror until it learns Bounce; then three
##     mirrors, turned from wheels on the floor, carry it up, across and down
##     onto the Gallery Lamp's crystal (680 px of beam: under a plain 900).
##   The Watchers' Walk (33-50): Glow and Self. A Watcher patrols over a heavy
##     plate. The Watch Cube glowing in the plate's socket holds it there as
##     stone (it stops at the edge of the light: a Large glow stops it short of
##     the plate), and the Monks' Gate opens.
##   The Watch Lamp (50-59): the second Watcher paces under a dark brazier
##     beside a ledge too high to jump to. Her fire lights the brazier, its
##     light holds the monk, and from his back a charged jump reaches the ledge
##     with the Watch Cube, which glows in the socket by the lamp's crystal.
##     (The cube can't do both: it can't be carried while it shines.)
##   The Dark Stacks (59-81): a walkway over a spiked chasm that is there only
##     in light. Fire lights the brazier at the near edge (the first stretch);
##     the Watch Cube glowing in the socket on the stone pillar in the middle
##     lights the stones round it; from there her fire reaches the Stacks Lamp
##     over the far stretch. Plain, a running jump crosses the dark between;
##     Large leaves only a hop. Without the cube's light it is too far.
##   The Great Lamp (81-96): the Door Cube's beam, its direction free, reaches
##     the Great Lamp's crystal only Up-Left. The Lamp Door opens.
## Optional: three ledger pages (a shelf in the Reading Room, a ledge over the
## Gallery Cube, a stone above the walkway that only a Large glow shows).
func lamps_hall() -> void:
	var g := HALL_GALLERY
	var w := HALL_WALK
	var m := HALL_WATCH
	var d := HALL_STACKS
	var e := HALL_GREAT
	shell(0, g, LOW_CEIL, true, false)
	shell(g, w, HIGH_CEIL, false, false)
	shell(w, m, HIGH_CEIL, false, false)
	shell(m, d, HIGH_CEIL, false, false)
	shell(d, e, HIGH_CEIL, false, false)
	shell(e, HALL_END, HIGH_CEIL, false, false)
	var room := mk_room("R1", "The Hall of Lamps", 0, HALL_END, HIGH_CEIL, Vector2(cx(1), 530), true)
	room.set("mood_ambient", 0.85)
	room.set("reset_at_shrine", true)
	var deco := group(room, "Decor")

	# ---------------------------------------------------- the Reading Room: Light, Beam
	shrine(room, "hall", cx(2))
	var tab_light := tablet(room, "light", cx(4), "Holy light, and what it wakes.")
	var tab_beam := tablet(room, "beam", cx(5) + 20, "A straight ray, to a far place.")
	var reading := cube(room, "Reading Cube", cx(7), "wind/push/right/normal",
		{"carryable": false, "locked_slots": LOCK_DIRECTION | LOCK_MODIFIER})
	spiked_pit(room, 8, 12, 6)
	var reading_crystal := inst(PUZZLE + "light_receiver.tscn", room, "ReadingCrystal", Vector2(cx(14), FLOOR_Y - 16.0), {"accepts_aura": false})
	spectral_bridge(room, 8, 12, reading_crystal, "lamps.r1.bridge", 1)
	# Page i on a shelf by the doorway (a charged jump)
	ledge_run(15, 15, 6, true)
	lamps_page(room, 1, Vector2(cx(15), 404.0), "The Lamplighter's Ledger, i",
		"Every star the Choir ever named was written down in this hall, under these lamps. I kept them burning forty years. A reader should never have to stop because the light went out.")

	# ---------------------------------------------------- the Mirror Gallery: Bounce
	var tab_bounce := tablet(room, "bounce", cx(g + 1) + 16, "Light that turns at every mirror.")
	# Its beam is on from the start: a plain beam stops at the first mirror
	var gallery_cube := cube(room, "Gallery Cube", cx(g + 3), "light/beam/right/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "start_active": true,
		"locked_slots": LOCK_ESSENCE | LOCK_FORM | LOCK_DIRECTION})
	# Right, up, right, down: each mirror starts turned wrong (two, one and
	# three turns), the high two turned from wheels on the floor
	var mirror_low := inst(PUZZLE + "mirror.tscn", room, "MirrorLow", Vector2(cx(g + 4), FLOOR_Y - 16.0),
		{"facing": 1, "post_length": 16.0})
	var mirror_high := inst(PUZZLE + "mirror.tscn", room, "MirrorHigh", Vector2(cx(g + 4), 380.0),
		{"facing": 0, "hanging": true, "post_length": 364.0, "interact_offset": Vector2(64, FLOOR_Y - 380.0)})
	var mirror_far := inst(PUZZLE + "mirror.tscn", room, "MirrorFar", Vector2(cx(g + 10), 380.0),
		{"facing": 3, "hanging": true, "post_length": 364.0, "interact_offset": Vector2(-64, FLOOR_Y - 380.0)})
	var gallery_crystal := inst(PUZZLE + "light_receiver.tscn", room, "GalleryCrystal", Vector2(cx(g + 10), 500.0), {"accepts_aura": false})
	var gallery_lamp := hall_lamp(room, "GalleryLamp", Vector2(cx(g + 13), 340.0), 324.0)
	var gallery_gate := gate(room, "GalleryGate", w)
	circuit(room, "GalleryLampCircuit", [gallery_crystal], [gallery_lamp, gallery_gate],
		{"latch": true, "reveal_target": true, "persist_id": "lamps.r1.gallery", "channel_y": 460.0, "symbol": 2})
	# Page ii on a ledge over the Gallery Cube's west side (a charged jump from its top)
	ledge_run(g + 2, g + 2, 6)
	lamps_page(room, 2, Vector2(cx(g + 2), 372.0), "The Lamplighter's Ledger, ii",
		"Ilse asked me to put out the lamps of the east halls the night she went down to the Eye. I did not ask her why. The dark is where the Watchers walk now, and I have stopped going east.")
	lamps_reveal(room, "GalleryReveal", cx(g + 1), Vector2(cx(g + 7), 330.0), "lamps.r1.gallery_seen")

	# ---------------------------------------------------- the Watchers' Walk: Glow, Self
	shrine(room, "walk", cx(w + 1))
	var tab_glow := tablet(room, "glow", cx(w + 2) + 24, "A pool of light, carried.")
	var tab_self := tablet(room, "self", cx(w + 3) + 24, "It shines on all sides.")
	var watch_cube := cube(room, "Watch Cube", cx(w + 4) + 24, "wind/push/right/normal")
	var monk_a := inst(CREATURES + "watcher_gargoyle.tscn", room, "WatcherA", Vector2((w + 14) * T, FLOOR_Y),
		{"patrol_min_x": float((w + 7) * T), "patrol_max_x": float((w + 16) * T), "walk_speed": 40.0, "start_facing": -1})
	var monk_plate := plate(room, "MonkPlate", cx(w + 11), {"stone_only": true, "width": 224.0})
	var plate_socket := inst(RUNES + "rune_pedestal.tscn", room, "PlateSocket", Vector2(cx(w + 11), FLOOR_Y))
	var monks_gate := gate(room, "MonksGate", m)
	circuit(room, "MonkPlateCircuit", [monk_plate], [monks_gate],
		{"latch": true, "hold_time": 0.5, "reveal_target": true, "persist_id": "lamps.r1.monks", "channel_y": 440.0, "symbol": 0})
	deco_sprite(deco, "lamplighter_plaque", Vector2(cx(w + 6), 452.0), false, -2)

	# ---------------------------------------------------- the Watch Lamp: fire holds a monk
	var monk_b := inst(CREATURES + "watcher_gargoyle.tscn", room, "WatcherB", Vector2(m * T + 210.0, FLOOR_Y),
		{"patrol_min_x": m * T + 192.0, "patrol_max_x": m * T + 232.0, "walk_speed": 30.0, "start_facing": 1})
	var monk_brazier := inst(PUZZLE + "brazier.tscn", room, "MonkBrazier", Vector2(m * T + 160.0, 446.0),
		{"hang_length": 410.0, "light_radius": 150.0})
	ledge_run(m + 4, m + 7, 6)
	var lamp_socket := inst(RUNES + "rune_pedestal.tscn", room, "LampSocket", Vector2(cx(m + 5), 402.0))
	var watch_crystal := inst(PUZZLE + "light_receiver.tscn", room, "WatchCrystal", Vector2(cx(m + 6) + 16.0, 370.0))
	var watch_lamp := hall_lamp(room, "WatchLamp", Vector2(cx(m + 6) + 16.0, 300.0), 284.0)
	var walk_gate := gate(room, "WalkGate", d)
	circuit(room, "WatchLampCircuit", [watch_crystal], [watch_lamp, walk_gate],
		{"latch": true, "reveal_target": true, "persist_id": "lamps.r1.watch", "channel_y": 300.0, "symbol": 1})

	# ---------------------------------------------------- the Dark Stacks: light shows the way
	# The chasm (cols p0-p1) runs under a low vault of the stacks (its underside
	# at 400): no jump carries more than ~165 px under it, so the dark between
	# the lights can't be jumped. Lit by the brazier: p0..p0+3; the cube on the
	# pillar (p0+4): one stone each side, or two with Large; the Stacks Lamp:
	# p0+8..p1. Dark between, plain: 128 px (a running jump), Large: 64 (a hop),
	# without the cube: 192 (too far). The stones let light through, so a lit
	# stone never shades the next one.
	var p0 := d + 6
	var p1 := d + 17
	var pillar := p0 + 4
	shrine(room, "stacks", cx(d + 1))
	var stacks_candle := inst("res://scenes/hazard_checkpoint.tscn", room, "CandleStacks", Vector2(cx(d + 4), FLOOR_Y))
	# Hung high over the edge, so its light clears the stones it lights
	var near_brazier := inst(PUZZLE + "brazier.tscn", room, "StacksBrazier", Vector2(cx(d + 5), 446.0),
		{"hang_length": 404.0, "light_radius": 300.0})
	pit(p0, p1)
	for x in range(p0, p1 + 1):
		ceiling.erase_cell(Vector2i(x, HIGH_CEIL))
		for y in range(HIGH_CEIL, 6):
			solid(x, y)
		ceiling.set_cell(Vector2i(x, 6), 0, BEAMS[x % BEAMS.size()])
	# A stone pillar in the middle, level with the walkway, a socket on its top
	ground.erase_cell(Vector2i(pillar, 9))
	floor_tile(pillar, 8)
	solid(pillar, 9)
	var chasm_socket := inst(RUNES + "rune_pedestal.tscn", room, "ChasmSocket", Vector2(cx(pillar), FLOOR_Y))
	inst("res://scenes/spike_trap.tscn", room, "StacksSpikesWest", Vector2(p0 * T + 128.0, 598.0),
		{"spike_count": 8, "damage_amount": 1, "recovery_checkpoint": stacks_candle})
	inst("res://scenes/spike_trap.tscn", room, "StacksSpikesEast", Vector2((pillar + 1) * T + 224.0, 598.0),
		{"spike_count": 14, "damage_amount": 1, "recovery_checkpoint": stacks_candle})
	# The walkway: stones there only while light reaches them
	for col in range(p0, p1 + 1):
		if col != pillar:
			inst(PUZZLE + "spectral_platform.tscn", room, "Walk%d" % col, Vector2(col * T, FLOOR_Y),
				{"mode": 1, "size": Vector2(64, 12), "casts_shadow": false})
	# Page iii on a stone over the walkway that only a Large glow reaches (a
	# charged jump from the stone before it)
	inst(PUZZLE + "spectral_platform.tscn", room, "PageStone", Vector2((pillar + 2) * T - 20.0, 470.0),
		{"mode": 1, "size": Vector2(64, 12), "casts_shadow": false})
	lamps_page(room, 3, Vector2((pillar + 2) * T + 12.0, 446.0), "The Lamplighter's Ledger, iii",
		"The Watchers are not stone. They are us. Light does not hurt them: it holds them still, the way we used to hold still to hear the bell. If you find Brother Aldous walking in the dark, tell him I kept his lamp.")
	# The Stacks Lamp: a brazier hung from the vault over the far stretch
	var stacks_lamp := inst(PUZZLE + "brazier.tscn", room, "StacksLamp", Vector2((p0 + 10) * T, 446.0),
		{"hang_length": 20.0, "light_radius": 175.0})
	var stacks_gate := gate(room, "StacksGate", e)
	circuit(room, "StacksLampCircuit", [stacks_lamp], [stacks_gate],
		{"latch": true, "reveal_target": true, "persist_id": "lamps.r1.stacks", "channel_y": 440.0, "symbol": 3})
	lamps_reveal(room, "StacksReveal", cx(d + 2), Vector2(cx(pillar), 440.0), "lamps.r1.stacks_seen")

	# ---------------------------------------------------- the Great Lamp: Up-Left
	shrine(room, "door", cx(e + 1))
	var tab_up_left := tablet(room, "up_left", cx(e + 2) + 16, "Up, and back the way you came.")
	var door_cube := cube(room, "Door Cube", cx(e + 9), "light/beam/up/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM})
	# Its up-left corner is 16 px up and left of its centre; the diagonal from
	# there meets the lamp's crystal 122 px up (low enough to be seen from the floor)
	var great_x := cx(e + 9) - 16.0 - 122.0
	var great_lamp := hall_lamp(room, "GreatLamp", Vector2(great_x, 338.0), 322.0, "great_lamp")
	var great_crystal := inst(PUZZLE + "light_receiver.tscn", room, "GreatCrystal", Vector2(great_x, 380.0), {"accepts_aura": false})
	var lamp_door := gate(room, "LampDoor", HALL_END)
	circuit(room, "GreatLampCircuit", [great_crystal], [great_lamp, lamp_door],
		{"latch": true, "reveal_target": true, "persist_id": "lamps.r1.solved", "channel_y": 96.0, "symbol": 2})
	# The three hall lamps over the Lamp Door, one for each lamp lit
	var board: Array = []
	for i in 3:
		board.append(hall_lamp(room, "BoardLamp%d" % (i + 1), Vector2(cx(e + 12) - 48.0 + i * 48.0, 330.0), 314.0))
	for spec in [["GalleryBoard", gallery_crystal, board[0], "lamps.r1.board1"], ["WatchBoard", watch_crystal, board[1], "lamps.r1.board2"],
			["StacksBoard", stacks_lamp, board[2], "lamps.r1.board3"]]:
		circuit(room, spec[0], [spec[1]], [spec[2]], {"latch": true, "persist_id": spec[3], "show_channels": false, "solved_sound": ""})
	lamps_reveal(room, "GreatReveal", cx(e + 2), Vector2(great_x, 330.0), "lamps.r1.great_seen")

	# ---------------------------------------------------- the goal and its steps
	guide(room, "Light the Great Lamp.", "I", "The Hall of Lamps", "The Long Stair  ·  The Lampworks")
	step(room, "Light learned", Cond.FLAG, null, {"flag": "rune.frag.light"})
	step(room, "A bridge of light over the pit", Cond.POWERED, reading_crystal)
	step(room, "Bounce learned", Cond.FLAG, null, {"flag": "rune.frag.bounce"})
	step(room, "The Gallery Lamp burns", Cond.POWERED, gallery_lamp)
	step(room, "Glow learned", Cond.FLAG, null, {"flag": "rune.frag.glow"})
	step(room, "A Watcher held on the plate: the Monks' Gate opens", Cond.OPEN, monks_gate)
	step(room, "The Watch Lamp burns", Cond.POWERED, watch_lamp)
	step(room, "The Stacks Lamp burns", Cond.POWERED, stacks_lamp)
	step(room, "Up-Left learned", Cond.FLAG, null, {"flag": "rune.frag.up_left"})
	step(room, "The Great Lamp burns: the Lamp Door opens", Cond.POWERED, great_lamp)
	for i in 3:
		step(room, "Ledger page %s found" % ["i", "ii", "iii"][i], Cond.FLAG, null,
			{"flag": "lamps.page.%d" % (i + 1), "optional": true})

	hint(room, Vector2(cx(1) + 24, FLOOR_Y), [
		"A crystal waits across the pit, and a cube stands at its edge.",
		"Crystals wake to holy light: a beam that ends on one powers it.",
		"Read both tablets, inscribe Light and Beam on the cube and switch it on: the beam crosses the pit, lights the crystal, and a bridge of light forms.",
	], [reading, reading_crystal, tab_light, tab_beam])
	hint(room, Vector2(cx(g + 7), FLOOR_Y), [
		"The Gallery Lamp's crystal is past the mirrors. A plain beam stops at the first mirror it meets.",
		"Bounce: light that turns at every mirror. A mirror turns light off its bright face only; each one turns from the wheel on the floor below it.",
		"Switch the Gallery Cube off, inscribe Bounce and switch it on. Turn the first mirror to send the beam up, the high one to send it right, and the far one to send it down onto the crystal.",
	], [gallery_cube, mirror_low, mirror_high, mirror_far, gallery_crystal, tab_bounce])
	hint(room, Vector2(cx(w + 5) + 16, FLOOR_Y), [
		"The Watchers were monks of the Choir. Light doesn't hurt them: it holds them still, as heavy as stone.",
		"A glow lights a circle round its cube. Glow can only shine on all sides: Self. A Watcher stops where the light begins.",
		"Write Light, Glow and Self on the Watch Cube, set it in the socket on the plate and switch it on. The Watcher stops on the plate as stone. (Large stops it before the plate.)",
	], [watch_cube, monk_a, monk_plate, plate_socket, tab_glow, tab_self])
	hint(room, Vector2(cx(m + 1), FLOOR_Y), [
		"The Watch Lamp's crystal is up on the ledge, too high to jump to from the floor.",
		"The brazier over the pacing Watcher is dark. Fire lights it, and its light would hold him still: something to stand on.",
		"Throw fire at the brazier. Carry the Watch Cube onto the Watcher's back, make a charged jump to the ledge, set the cube in the socket and make it glow.",
	], [monk_b, monk_brazier, lamp_socket, watch_crystal])
	hint(room, Vector2(cx(d + 2), FLOOR_Y), [
		"The walkway over the chasm is there only where light reaches it.",
		"Fire lights the brazier over the edge. The socket on the pillar takes a cube, and from the stones past it your fire reaches the lamp over the far side.",
		"Light the brazier and carry the Watch Cube out to the pillar. Set it in the socket glowing (Light, Glow, Self: Large lights more of the way), walk on to the last lit stone and throw fire at the Stacks Lamp.",
	], [near_brazier, chasm_socket, stacks_lamp])
	hint(room, Vector2(cx(e + 4), FLOOR_Y), [
		"The Great Lamp hangs high over the hall. The Door Cube's beam can go any way.",
		"Straight up misses it, and so does straight across.",
		"Read the tablet: Up-Left. Write it on the Door Cube and switch it on.",
	], [door_cube, great_lamp, tab_up_left])

	# ---------------------------------------------------- dressing
	for c in [1, 6, 13]:
		torch(deco, c)
	for c in [g + 6, g + 15, w + 8, w + 14, m + 2, d + 2, p1 + 2, e + 6, e + 13]:
		torch(deco, c, 2)
	for x in [cx(1) - 8, cx(12) + 16, cx(g + 11) + 16, cx(g + 14) + 8, cx(w + 9), cx(e + 6), cx(e + 7) + 16]:
		deco_sprite(deco, "bookshelf", Vector2(x, FLOOR_Y), false, -2)
	decor(g + 9, 1, W_WINDOW_MOON)
	decor(w + 10, 1, W_WINDOW_BARRED)
	decor(d + 3, 1, W_WINDOW_MOON)
	decor(e + 5, 1, W_BANNER_FLEUR)
	# Wren's chalk star on the wall by the chasm: she has been this way
	deco_sprite(deco, "chalk_star", Vector2(cx(d + 4) + 16, 430.0), false, -1, true)
	deco_sprite(deco, "chalk_steps", Vector2(cx(w + 2), FLOOR_Y), false, -1, true)
	waymark(room, cx(13), "right")
	waymark(room, cx(w - 2), "right")
	waymark(room, cx(m - 2), "right")
	waymark(room, cx(m + 8), "down", 360.0)
	waymark(room, cx(e - 2), "right")
	waymark(room, cx(HALL_END - 2), "right")
	prop(deco, "cobweb_corner", cx(HALL_END - 1) + 8, 12.0, true, true)


## The Lamp Stair (`o` columns east of where it was first built, after the
## Hall of Lamps). A crystal on the wall opens the gate while light touches
## it. A glow cube lights it from afar only with Large; carry the cube to a
## spot where it can reach. The Lamp Bell is behind the gate.
func lamps_stair(o: int) -> void:
	shell(o + 22, o + 46, LOW_CEIL, false, true)
	var room := mk_room("R2", "The Lamp Stair", o + 22, o + 46, LOW_CEIL, Vector2(cx(o + 23), 530))
	waymarks(room, o + 22, o + 46, false)
	shrine(room, "stair", cx(o + 24))
	tablet(room, "glow", cx(o + 27) + 16, "A pool of light, carried.")
	tablet(room, "self", cx(o + 29), "It shines on all sides.")
	var c := cube(room, "Lamp Cube", cx(o + 31), "wind/push/right/normal")
	var crystal := inst(PUZZLE + "light_receiver.tscn", room, "Crystal", Vector2(cx(o + 38), FLOOR_Y - 120.0))
	var exit_gate := gate(room, "StairGate", o + 41)
	circuit(room, "CrystalToGate", [crystal], [exit_gate],
		{"reveal_target": true, "persist_id": "lamps.r2.solved", "channel_y": 440.0, "symbol": 3})
	var bell := wing_bell(room, cx(o + 43), "The Lamp Bell rings out.", "Every lamp in the works flickers, and burns on.")
	guide(room, "Ring the Lamp Bell.")
	step(room, "Glow learned", Cond.FLAG, null, {"flag": "rune.frag.glow"})
	step(room, "The crystal is lit: the gate opens", Cond.OPEN, exit_gate)
	step(room, "The Lamp Bell rings", Cond.POWERED, bell)
	hint(room, Vector2(cx(o + 24) + 28, FLOOR_Y), [
		"A crystal high on the wall holds the gate. Light that reaches it wakes it.",
		"A glow lights a circle around its cube. A Large one is wider. The cube can be carried.",
		"Inscribe Light, Glow, Self and Large, carry the cube under the crystal, set it down and switch it on.",
	], [c, crystal])
	dress(room, o + 22, o + 46, [o + 25, o + 33, o + 36, o + 44])


# ================================================================ the Folded Galleries (space)

## Where the Folded Archive's parts begin (columns): the Tall Stacks, the
## Sealed Reading Room, the Pillar, the Hearth, and its end (the Archive Door,
## where the second room begins).
const ARCHIVE_STACKS := 13
const ARCHIVE_READING := 27
const ARCHIVE_PILLAR := 43
const ARCHIVE_HEARTH := 57
const ARCHIVE_END := 70


func build_galleries() -> void:
	begin("Galleries", "galleries", "The Folded Galleries", Journey.GALLERIES_INTERLUDE, Journey.WINGS[3]["words"])
	level.set("total_pages", 5)
	galleries_archive()
	galleries_wren()
	ledger.sort_custom(func(a, b): return a["id"] < b["id"])
	level.set("ledger", ledger)
	finish()


## One of the Archivist's ledger pages.
func galleries_page(parent: Node, id: int, pos: Vector2, title: String, text: String) -> void:
	inst(PUZZLE + "lore_page.tscn", parent, "LorePage%d" % id, pos,
		{"page_id": "galleries.page.%d" % id, "title": title, "text": text})
	var ids: PackedStringArray = parent.get("page_ids")
	ids.append("galleries.page.%d" % id)
	parent.set("page_ids", ids)
	ledger.append({"id": "galleries.page.%d" % id, "numeral": ["i", "ii", "iii", "iv", "v", "vi"][id - 1],
		"title": title, "text": text, "room": parent.get("title")})


## A sealed pocket in the air, cols c0..c1 inside, walls on cols c0-1 and c1+1
## from the roof (row `roof`, solid) down to the floor row `floor_row` (cap
## tiles, surface floor_row*64+18, or +50 if `half`). Nothing gets in or out
## but by a portal.
func sealed_pocket(c0: int, c1: int, roof: int, floor_row: int, half := false) -> void:
	for x in range(c0 - 1, c1 + 2):
		for y in range(HIGH_CEIL, roof + 1):
			ceiling.erase_cell(Vector2i(x, y))
			solid(x, y)
	for x in [c0 - 1, c1 + 1]:
		for y in range(roof + 1, floor_row + 1):
			solid(x, y)
	ledge_run(c0, c1, floor_row, half, false, false)


## THE FOLDED ARCHIVE. The Choir's archive of the sky, folded away by the
## Archivist so the Hush could not find it: shelves hung in rooms nobody can
## walk to, doors that open into walls. Space and Portal: a portal is a doorway
## by the cube and its far side `range` px on (Long: further), through stone and
## shut gates; whatever goes in one side comes out the other moving as it was,
## and that includes fire. Columns 0-70, five parts:
##   The Sealed Door (0-13, low): the Archive's door is frozen shut. The Door
##     Cube beside it (Space and Portal to write; Right is carved) opens a
##     doorway through the door and the rock behind it.
##   The Tall Stacks (13-27): the Stacks Lever is on a shelf 196 px up. The
##     Archive Cube in the socket under it, Portal Up: a doorway in the air over
##     the shelf; jump into the one above the cube. The lever opens the way on.
##   The Sealed Reading Room (27-43): the Reading Gate is held open only while
##     the plate in a sealed pocket overhead is pressed, and the only way into
##     the pocket is the Archive Cube's doorway up. She can't be on the plate
##     and at the gate at once: an Echo recorded jumping in through the portal
##     follows the same path (through the rock, even with the portal gone) and
##     stays on the plate. Once she is through, the gate stays open.
##   The Pillar (43-57): a pillar of rock from floor to roof. The Pillar Cube's
##     doorway Right comes out inside a hollow in the pillar, on the plate that
##     holds the Pillar Gate beyond it; Long takes it all the way through. An
##     Echo recorded hopping in (Right) still goes into the hollow once the cube
##     says Long, and holds the gate while she goes through. Once she is
##     through, the gate stays open.
##   The Hearth (57-70): the Archive Door opens when the brazier in a sealed
##     hearth up in the wall burns. The Hearth Cube, on a ledge, worked from a
##     lectern: its doorway Right opens in the air, its far side inside the
##     hearth. Fire thrown straight up through the doorway comes out in the
##     hearth still flying up, into the brazier.
## Optional: three ledger pages (a shelf behind the sealed door, a shelf high
## over the stacks (Long, up), the pillar's hollow).
func galleries_archive() -> void:
	var b := ARCHIVE_STACKS
	var r := ARCHIVE_READING
	var p := ARCHIVE_PILLAR
	var h := ARCHIVE_HEARTH
	shell(0, b, LOW_CEIL, true, false)
	shell(b, r, HIGH_CEIL, false, false)
	shell(r, p, HIGH_CEIL, false, false)
	shell(p, h, HIGH_CEIL, false, false)
	shell(h, ARCHIVE_END, HIGH_CEIL, false, false)
	var room := mk_room("R1", "The Folded Archive", 0, ARCHIVE_END, HIGH_CEIL, Vector2(cx(1), 530), true)
	room.set("mood_ambient", 0.9)
	room.set("reset_at_shrine", true)
	var deco := group(room, "Decor")

	# ---------------------------------------------------- the Sealed Door: Space, Portal
	shrine(room, "archive", cx(2))
	var tab_space := tablet(room, "space", cx(4), "Distance is only a habit.")
	var tab_portal := tablet(room, "portal", cx(5) + 16, "A door to somewhere near.")
	# On a low plinth, so its doorway stands on the floor beyond the wall
	var door_cube := cube(room, "Door Cube", cx(7), "wind/push/right/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_DIRECTION | LOCK_MODIFIER}, FLOOR_Y - 8.0)
	# The Archive's own door, frozen shut, and two tiles of rock behind it
	ceiling.erase_cell(Vector2i(9, LOW_CEIL))
	for y in [LOW_CEIL, LOW_CEIL + 1]:
		solid(9, y)
	gate(room, "SealedDoor", 9)
	ceiling.erase_cell(Vector2i(10, LOW_CEIL))
	ground.erase_cell(Vector2i(10, 8))
	for y in range(LOW_CEIL, 9):
		solid(10, y)
	deco_sprite(deco, "door_frost", Vector2(cx(9), FLOOR_Y), false, 1)
	# Page i on a shelf over the far doorway, behind the door (a charged jump from the east)
	ledge_run(11, 11, 6, true)
	galleries_page(room, 1, Vector2(cx(11), 404.0), "The Archivist's Ledger, i",
		"I folded the archive the night the bell cracked. Every star the Choir ever wrote down is still here, in rooms you cannot walk to. The Hush listens for doors. It has never learned to listen for distance.")

	# ---------------------------------------------------- the Tall Stacks: a door in the air
	var archive_cube := cube(room, "Archive Cube", cx(b + 2), "wind/push/right/normal")
	var lift_socket := inst(RUNES + "rune_pedestal.tscn", room, "LiftSocket", Vector2(cx(b + 7), FLOOR_Y))
	# The shelf over the socket (196 px up): the doorway Up opens above it
	ledge_run(b + 6, b + 12, 5, false, false, true)
	var stacks_lever := inst(PUZZLE + "lever.tscn", room, "StacksLever", Vector2(cx(b + 11), 338.0),
		{"one_way": true, "persist_id": "galleries.r1.stacks"})
	var stacks_gate := gate(room, "StacksGate", r)
	circuit(room, "StacksCircuit", [stacks_lever], [stacks_gate],
		{"latch": true, "reveal_target": true, "persist_id": "galleries.r1.stacks_gate", "channel_y": 300.0, "symbol": 1})
	# Page ii on a shelf high over the stacks: the doorway Up and Long
	ledge_run(b + 7, b + 8, 2, false, false, true)
	galleries_page(room, 2, Vector2(cx(b + 8), 116.0), "The Archivist's Ledger, ii",
		"Wren used to sit on the top shelf of the stacks, where no ladder reaches, and read the star-books upside down. She found the way up before I did. She said a door does not care which way is down.")
	deco_sprite(deco, "chalk_route", Vector2(cx(b + 6), FLOOR_Y), false, -1, true)
	lamps_reveal(room, "StacksReveal", cx(b + 2), Vector2(cx(b + 11), 300.0), "galleries.r1.stacks_seen")

	# ---------------------------------------------------- the Sealed Reading Room: an Echo through a door
	shrine(room, "reading", cx(r + 1))
	var reading_socket := inst(RUNES + "rune_pedestal.tscn", room, "ReadingSocket", Vector2(cx(r + 6), FLOOR_Y))
	# The pocket overhead, sealed all round: its floor 196 px up
	sealed_pocket(r + 6, r + 7, 2, 5)
	var pocket_plate := plate(room, "PocketPlate", cx(r + 6) + 32.0, {"width": 96.0})
	pocket_plate.position.y = 338.0
	var reading_gate := gate(room, "ReadingGate", p)
	# Past the gate a threshold she can't miss: once she is through, it stays open
	var threshold := plate(room, "Threshold", cx(p + 1), {"width": 112.0})
	var through := circuit(room, "ThroughReading", [threshold], [],
		{"latch": true, "persist_id": "galleries.r1.reading", "show_channels": false, "solved_sound": ""})
	circuit(room, "ReadingCircuit", [pocket_plate, through], [reading_gate],
		{"mode": 1, "reveal_target": true, "channel_y": 420.0, "symbol": 2})
	deco_sprite(deco, "archivist_plaque", Vector2(cx(r + 3), 470.0), false, -2)
	lamps_reveal(room, "PocketReveal", cx(r + 3), Vector2(cx(r + 6) + 32.0, 290.0), "galleries.r1.pocket_seen")

	# ---------------------------------------------------- the Pillar: how far
	shrine(room, "pillar", cx(p + 2))
	var pillar_cube := cube(room, "Pillar Cube", cx(p + 5), "space/portal/up/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM}, FLOOR_Y - 8.0)
	# The pillar: rock from floor to roof, three tiles thick, a hollow inside
	for x in range(p + 8, p + 11):
		ceiling.erase_cell(Vector2i(x, HIGH_CEIL))
		ground.erase_cell(Vector2i(x, 8))
		for y in range(HIGH_CEIL, 9):
			if x == p + 9 and y in [6, 7, 8]:
				continue
			solid(x, y)
	floor_tile(p + 9, 8)
	galleries_page(room, 3, Vector2(cx(p + 9), 500.0), "The Archivist's Ledger, iii",
		"This hollow is the smallest room in the archive, and the one I am proudest of. Ilse came here to ask me to fold the Eye. I told her a fold is not a lock. You can always find the door if you know how far to walk.")
	# The gate past the pillar is held by a plate in the hollow: an Echo
	# recorded going in (Right) still goes in once the cube says Long
	var hollow_plate := plate(room, "HollowPlate", cx(p + 9), {"width": 56.0})
	var pillar_gate := gate(room, "PillarGate", h)
	var pillar_threshold := plate(room, "PillarThreshold", cx(h + 1), {"width": 112.0})
	var through_pillar := circuit(room, "ThroughPillar", [pillar_threshold], [],
		{"latch": true, "persist_id": "galleries.r1.pillar", "show_channels": false, "solved_sound": ""})
	circuit(room, "PillarCircuit", [hollow_plate, through_pillar], [pillar_gate],
		{"mode": 1, "reveal_target": true, "channel_y": 96.0, "symbol": 0})

	# ---------------------------------------------------- the Hearth: fire through a door
	shrine(room, "hearth", cx(h + 1))
	# The Hearth Cube on a ledge 132 px up (out of reach); its doorway Right opens in the air
	ledge_run(h + 4, h + 4, 6, false, false, false)
	# (overhanging its ledge a little, so fire thrown up into its doorway clears the stone)
	var hearth_cube := cube(room, "Hearth Cube", cx(h + 4) + 24.0, "space/portal/up/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM}, 402.0)
	var hearth_lectern := inst(RUNES + "rune_lectern.tscn", room, "HearthLectern", Vector2(cx(h + 3), FLOOR_Y), {"cube": hearth_cube})
	# The hearth: a sealed pocket in the wall, its brazier hung from the roof
	sealed_pocket(h + 8, h + 9, 2, 6, true)
	var hearth := inst(PUZZLE + "brazier.tscn", room, "HearthBrazier", Vector2(cx(h + 4) + 24.0 + 31.0 + 224.0, 316.0),
		{"hang_length": 98.0, "light_radius": 0.0})
	var archive_door := gate(room, "ArchiveDoor", ARCHIVE_END)
	circuit(room, "HearthCircuit", [hearth], [archive_door],
		{"latch": true, "reveal_target": true, "persist_id": "galleries.r1.solved", "channel_y": 96.0, "symbol": 3})
	deco_sprite(deco, "chalk_star", Vector2(cx(h + 5), 470.0), false, -1, true)
	lamps_reveal(room, "HearthReveal", cx(h + 3), Vector2(cx(h + 4) + 279.0, 340.0), "galleries.r1.hearth_seen")

	# ---------------------------------------------------- the goal and its steps
	guide(room, "Find the way through the Folded Archive.", "I", "The Folded Archive", "The Long Stair  ·  The Folded Galleries")
	step(room, "Space learned", Cond.FLAG, null, {"flag": "rune.frag.space"})
	step(room, "Through the sealed door", Cond.REACHED, null, {"area": Rect2(11 * T, 470, 2 * T, 70)})
	step(room, "Up the stacks: the Stacks Gate opens", Cond.OPEN, stacks_gate)
	step(room, "Something holds the pocket's plate", Cond.POWERED, pocket_plate)
	step(room, "Through the Reading Gate", Cond.FLAG, null, {"flag": "galleries.r1.reading"})
	step(room, "Through the pillar", Cond.REACHED, null, {"area": Rect2((p + 11) * T, 470, 3 * T, 70)})
	step(room, "Through the Pillar Gate", Cond.FLAG, null, {"flag": "galleries.r1.pillar"})
	step(room, "Fire in the hearth: the Archive Door opens", Cond.POWERED, hearth)
	for i in 3:
		step(room, "Ledger page %s found" % ["i", "ii", "iii"][i], Cond.FLAG, null,
			{"flag": "galleries.page.%d" % (i + 1), "optional": true})

	hint(room, Vector2(cx(1) + 24, FLOOR_Y), [
		"The Archive's door is frozen shut, and there is rock behind it. The cube beside it is the Archivist's.",
		"A portal is a doorway by the cube, and another one further on, through stone and shut doors. Walk into one, come out of the other.",
		"Read both tablets, write Space and Portal on the Door Cube and switch it on. Hop over the cube into its doorway.",
	], [door_cube, tab_space, tab_portal])
	hint(room, Vector2(cx(b + 4), FLOOR_Y), [
		"The lever is on a shelf far too high to jump to. There is a socket on the floor beneath it.",
		"A portal Up opens its far side in the air above the cube: over the shelf.",
		"Write Space, Portal, Up on the Archive Cube, set it in the socket and switch it on. Jump into the doorway over the cube.",
	], [archive_cube, lift_socket, stacks_lever])
	hint(room, Vector2(cx(r + 4), FLOOR_Y), [
		"The gate is open only while the plate in the sealed pocket overhead is pressed.",
		"You can't stand on the plate and walk through the gate. An Echo follows the path you recorded, even through a door that has gone.",
		"With the Archive Cube's doorway Up under the pocket: record an Echo jumping in and onto the plate. It will stay there. Then walk through the gate.",
	], [reading_socket, pocket_plate, reading_gate])
	hint(room, Vector2(cx(p + 4), FLOOR_Y), [
		"Rock from the floor to the roof. The Pillar Cube can open a door through it. The gate past the pillar is held by a plate.",
		"A plain doorway comes out 224 px on, inside the pillar, by the plate. Long goes all the way through. An Echo goes where you went, even after the cube has changed.",
		"Write Right and record an Echo hopping into the doorway onto the hollow's plate. Come back out, change the cube to Long and go through: the Echo holds the gate open.",
	], [pillar_cube, hollow_plate, pillar_gate])
	hint(room, Vector2(cx(h + 6), FLOOR_Y), [
		"The brazier that opens the Archive Door is shut in a hearth up in the wall.",
		"Fire flies through a doorway too, and keeps going the way it was thrown.",
		"At the lectern, write Right on the Hearth Cube and switch it on. Stand under its doorway and throw fire straight up.",
	], [hearth_cube, hearth_lectern, hearth])

	# ---------------------------------------------------- dressing
	for c in [1, 6, 12]:
		torch(deco, c)
	for c in [b + 3, b + 10, r + 3, r + 11, p + 2, p + 13, h + 6, h + 11]:
		torch(deco, c, 2)
	for x in [cx(b + 2) + 40, cx(b + 4) + 16, cx(r + 10), cx(r + 12) + 8, cx(p + 12) + 16, cx(h + 11)]:
		deco_sprite(deco, "scroll_rack", Vector2(x, FLOOR_Y), false, -2)
	for x in [cx(r + 13), cx(h + 12) + 8]:
		deco_sprite(deco, "bookshelf", Vector2(x, FLOOR_Y), false, -2)
	decor(b + 5, 1, W_WINDOW_MOON)
	decor(r + 9, 1, W_WINDOW_BARRED)
	decor(p + 6, 1, W_WINDOW_MOON)
	decor(h + 5, 1, W_BANNER_FLEUR)
	waymark(room, cx(11) + 20, "right")
	waymark(room, cx(r - 2), "right")
	waymark(room, cx(p - 2), "right")
	waymark(room, cx(h - 2), "right")
	waymark(room, cx(ARCHIVE_END - 2), "right")
	prop(deco, "cobweb_corner", cx(ARCHIVE_END - 1) + 8, 12.0, true, true)


## Where Wren's Test's parts begin (columns): the Ember Lift, the Frozen
## Fountains, the Two Hearths, the Last Crystal, Wren's Door, and its end.
const WREN_EMBER := 70
const WREN_FROST := 84
const WREN_HEARTHS := 100
const WREN_CRYSTAL := 116
const WREN_DOOR := 128
const WREN_END := 134


## A hearth: a sealed pocket in the wall (its floor 100 px up) with a brazier
## hung from its roof, and a cube on a ledge 132 px up to the west whose
## doorway Right opens in the air, its far side inside the pocket (fire thrown
## straight up through the doorway comes out in the hearth, into the brazier).
## The ledge is column `ledge`; the pocket is the two columns from ledge+4.
func galleries_hearth(room: Node, cube_name: String, brazier_name: String, ledge: int, props: Dictionary, brazier_props: Dictionary) -> Array:
	ledge_run(ledge, ledge, 6, false, false, false)
	# (overhanging its ledge a little, so fire thrown up into its doorway clears the stone)
	var c := cube(room, cube_name, cx(ledge) + 24.0, props.get("recipe", "space/portal/right/normal"), props, 402.0)
	sealed_pocket(ledge + 4, ledge + 5, 2, 6, true)
	var b := inst(PUZZLE + "brazier.tscn", room, brazier_name, Vector2(cx(ledge) + 24.0 + 31.0 + 224.0, 316.0),
		{"hang_length": 98.0, "light_radius": 0.0}.merged(brazier_props, true))
	return [c, b]


## WREN'S TEST. Behind the archive Wren left a test for whoever came after
## her, in chalk on four cubes of her own: half a sentence on each, for
## Echidna to finish. Each lights one of the four seals on Wren's door (fire,
## ice, space, light), and behind the door Wren is waiting. Columns 70-134:
##   Again (70-84): the way on is a ledge 324 px up; the Ember Lift rises only
##     while the brazier in a chimney over the Ember Lock burns, and it burns
##     two seconds. Wren wrote Fire, Projectile, Up: Repeat keeps it burning
##     (a bolt every 1.6 s), so the lift carries her all the way.
##   Aslant (84-100): from a balcony, down to five leaping fountains. Wren's
##     Frost Lock, hung high over them, has Ice, Freeze and Long: Down-Left
##     lays the cold aslant across all five jets, a stair of ice (for a few
##     breaths) up to the walkway and the second seal.
##   Two Hearths (100-116): two braziers in two hearths, each reached by fire
##     thrown up through a cube's doorway (as in the archive), 416 px apart;
##     the seal wants both burning at once, and each burns two seconds. An
##     Echo throws at one while she throws at the other.
##   The Last Crystal (116-128): Wren's Lens Lock (Light, Beam, Right) and
##     three mirrors to the crystal; the last mirror's wheel is in a sealed
##     pocket over it, reached by the Pocket Cube's doorway Up.
##   Wren's Door (128-134): with all four seals lit it opens. Wren speaks, and
##     the Fold Bell is hers to ring.
## Optional: two more ledger pages (on top of the Frost Lock, in the pocket).
func galleries_wren() -> void:
	var e := WREN_EMBER
	var f := WREN_FROST
	var t := WREN_HEARTHS
	var l := WREN_CRYSTAL
	var d := WREN_DOOR
	shell(e, f, HIGH_CEIL, false, false)
	shell(f, t, HIGH_CEIL, false, false)
	shell(t, l, HIGH_CEIL, false, false)
	shell(l, d, HIGH_CEIL, false, false)
	shell(d, WREN_END, HIGH_CEIL, false, true)
	var room := mk_room("R2", "Wren's Test", e, WREN_END, HIGH_CEIL, Vector2(cx(e + 1), 530), true)
	room.set("mood_ambient", 0.9)
	room.set("reset_at_shrine", true)
	var deco := group(room, "Decor")
	var chalk := group(room, "Chalk")

	# The four seals over Wren's door, dark until each lock is done
	var seals := {}
	var kinds := ["fire", "ice", "space", "light"]
	for i in 4:
		seals[kinds[i]] = inst(PUZZLE + "hall_lamp.tscn", room, "Seal" + kinds[i].capitalize(),
			Vector2(cx(d) - 72.0 + i * 48.0, 356.0), {"sprite_name": "seal_" + kinds[i], "chain_length": 0.0, "light_energy": 0.55,
			"light_color": {"fire": Color(1.0, 0.6, 0.3), "ice": Color(0.55, 0.85, 1.0), "space": Color(0.75, 0.55, 1.0), "light": Color(1.0, 0.9, 0.55)}[kinds[i]]})

	# ---------------------------------------------------- Again: Repeat
	shrine(room, "wren", cx(e + 1))
	var tab_repeat := tablet(room, "repeat", cx(e + 3) + 16, "Again, while it lasts.")
	var ember_lock := cube(room, "Ember Lock", cx(e + 6), "fire/projectile/up/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM | LOCK_DIRECTION})
	# The chimney over the lock: its brazier is out of reach of anyone's fire
	# but a bolt flown straight up from under it
	for x in range(e + 5, e + 8):
		for y in range(HIGH_CEIL, 3):
			ceiling.erase_cell(Vector2i(x, y))
			solid(x, y)
	for x in [e + 5, e + 7]:
		for y in range(3, 7):
			solid(x, y)
	var ember := inst(PUZZLE + "brazier.tscn", room, "EmberBrazier", Vector2(cx(e + 6), 300.0),
		{"hang_length": 82.0, "light_radius": 0.0, "burn_time": 2.0})
	var lift := inst(TRAPS + "moving_platform.tscn", room, "EmberLift", Vector2((e + 9) * T, FLOOR_Y - 18.0),
		{"width_tiles": 2, "travel": Vector2(0, -324), "speed": 60.0, "end_pause": 1.0, "requires_power": true})
	circuit(room, "EmberCircuit", [ember], [lift], {"channel_y": 140.0, "symbol": 0, "solved_sound": ""})
	# The ledge the lift rises to, and the high doorway east
	ledge_run(e + 11, f, 3, false, false, false)
	for y in [2, 3]:
		earth.erase_cell(Vector2i(f, y))
	for y in [6, 7, 8]:
		solid(f, y)
	ground.erase_cell(Vector2i(f, 8))
	var ember_plate := plate(room, "EmberPlate", cx(e + 12), {"width": 96.0})
	ember_plate.position.y = 210.0
	circuit(room, "FireSeal", [ember_plate], [seals["fire"]],
		{"latch": true, "persist_id": "galleries.r2.fire", "show_channels": false})
	deco_sprite(chalk, "chalk_star", Vector2(cx(e + 6) - 22.0, 470.0), false, -1, true)

	# ---------------------------------------------------- Aslant: Down-Left
	# The balcony she comes out on; the tablet on it
	ledge_run(f + 1, f + 3, 3, false, false, true)
	var tab_dl := tablet(room, "down_left", cx(f + 2), "Back the way the rain came.", 210.0)
	# Five fountains (the Cistern's, mirrored): frozen aslant from the Frost
	# Lock over them, each where its leap first meets the cold, a stair of
	# pillars 45 px a step up to the walkway at 306 (east)
	var top_x := float(cx(f + 9) + 16)
	var fountains := []
	for i in 5:
		var top_y := 306.0 + 45.0 * i
		fountains.append(inst(PUZZLE + "fountain.tscn", room, "Fountain%d" % (i + 1), Vector2(top_x - 45.0 * i, FLOOR_Y), {
			"max_height": FLOOR_Y - top_y + 6.0, "rest_height": 14.0, "rest_time": 0.5 + 0.1 * (i % 3),
			"rise_time": 0.45, "hold_time": 1.8 + 0.25 * ((i + 1) % 3), "fall_time": 0.45, "phase": 0.7 * i}))
	var frost_lock := cube(room, "Frost Lock", top_x - 5.0, "ice/freeze/down/long",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM | LOCK_MODIFIER}, 245.0)
	var frost_lectern := inst(RUNES + "rune_lectern.tscn", room, "FrostLectern", Vector2(top_x - 272.0, FLOOR_Y), {"cube": frost_lock})
	# The walkway east of the stair (she drops off its east end to the gate), the seal's plate on it
	ledge_run(f + 10, t - 2, 4, true, false, true)
	var frost_plate := plate(room, "FrostPlate", cx(f + 12), {"width": 96.0})
	frost_plate.position.y = 306.0
	var frost_gate := gate(room, "FrostGate", t)
	circuit(room, "IceSeal", [frost_plate], [seals["ice"], frost_gate],
		{"latch": true, "reveal_target": false, "persist_id": "galleries.r2.ice", "show_channels": false})
	galleries_page(room, 4, Vector2(top_x - 5.0, 196.0), "The Archivist's Ledger, iv",
		"Wren made a game of my locks. She would write half a sentence on a cube and leave it for the novices, and laugh when they stood in front of it for an hour. Finish what I started, she wrote on the wall. Every one of them did.")
	deco_sprite(chalk, "chalk_steps", Vector2(top_x - 230.0, FLOOR_Y), false, -1, true)

	# ---------------------------------------------------- Two Hearths: two places at once
	shrine(room, "hearths", cx(t + 1))
	var hearth_a := galleries_hearth(room, "West Hearth Cube", "WestHearth", t + 2,
		{"dungeon_powered": true, "carryable": false, "mounted": true, "start_active": true, "locked_slots": 15}, {"burn_time": 2.0})
	var hearth_b := galleries_hearth(room, "East Hearth Cube", "EastHearth", t + 9,
		{"dungeon_powered": true, "carryable": false, "mounted": true, "start_active": true, "locked_slots": 15}, {"burn_time": 2.0})
	var hearths_gate := gate(room, "HearthsGate", l)
	circuit(room, "SpaceSeal", [hearth_a[1], hearth_b[1]], [seals["space"], hearths_gate],
		{"latch": true, "reveal_target": true, "persist_id": "galleries.r2.space", "channel_y": 96.0, "symbol": 2})
	deco_sprite(chalk, "chalk_hands", Vector2(cx(t + 6), 460.0), false, -1, true)

	# ---------------------------------------------------- The Last Crystal
	shrine(room, "crystal", cx(l + 1))
	var lens_lock := cube(room, "Lens Lock", cx(l + 3), "light/beam/right/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": LOCK_ESSENCE | LOCK_FORM | LOCK_DIRECTION})
	# Right, up, right, down: the low and high mirrors turned from the floor,
	# the last from its wheel in the sealed pocket over it
	var m_low := inst(PUZZLE + "mirror.tscn", room, "LensMirrorLow", Vector2(cx(l + 4), FLOOR_Y - 16.0), {"facing": 1, "post_length": 16.0})
	var m_high := inst(PUZZLE + "mirror.tscn", room, "LensMirrorHigh", Vector2(cx(l + 4), 420.0),
		{"facing": 0, "hanging": true, "post_length": 404.0, "interact_offset": Vector2(64, FLOOR_Y - 420.0)})
	var m_far := inst(PUZZLE + "mirror.tscn", room, "LensMirrorFar", Vector2(cx(l + 9), 420.0),
		{"facing": 3, "hanging": true, "post_length": 36.0, "interact_offset": Vector2(0, 338.0 - 420.0)})
	var crystal := inst(PUZZLE + "light_receiver.tscn", room, "LastCrystal", Vector2(cx(l + 9), 500.0), {"accepts_aura": false})
	sealed_pocket(l + 7, l + 9, 2, 5)
	var pocket_cube := cube(room, "Pocket Cube", cx(l + 7), "space/portal/up/normal",
		{"dungeon_powered": true, "carryable": false, "mounted": true, "locked_slots": 15})
	var wrens_door := gate(room, "WrensDoor", d)
	circuit(room, "LightSeal", [crystal], [seals["light"]],
		{"latch": true, "persist_id": "galleries.r2.light", "show_channels": false})
	circuit(room, "WrensDoorCircuit", [seals["fire"], seals["ice"], seals["space"], seals["light"]], [wrens_door],
		{"latch": true, "reveal_target": true, "persist_id": "galleries.r2.door", "show_channels": false})
	galleries_page(room, 5, Vector2(cx(l + 8), 300.0), "The Archivist's Ledger, v",
		"Ilse has not come down from the Eye in a year. I take her bread to the door and it is still there in the morning. Wren comes instead. She is not cold, and she is not warm. She asks me to read her the stars, and she always asks for the one with no name.")

	# ---------------------------------------------------- Wren's Door
	var wren := Node2D.new()
	wren.name = "Wren"
	wren.set_script(load("res://scripts/story/wren_meeting.gd"))
	wren.position = Vector2(cx(d + 2), FLOOR_Y)
	wren.set("lines", PackedStringArray([
		"wren/calm: You came all this way. Mum said nobody would.",
		"echidna/surprised: The chalk stars. It was you, all along.",
		"wren/smile: I left them so you wouldn't get lost. The Galleries fold if you let them.",
		"wren/pleading: Mum won't let go. Please.",
		"echidna/worried: Let go of what?",
		"wren/calm: Me. She holds the moment so I can't leave it. It has been sixty years, and it is still the same night.",
		"wren/pleading: I want it to end. I just don't want Mum to be alone.",
		"wren/calm: Ring the bell. Then come to the Eye. I'll be there.",
	]))
	add_owned(room, wren)
	var bell := wing_bell(room, cx(d + 4), "The Fold Bell rings out.", "The rooms inside rooms fall quiet. Somewhere below, a door unfolds.")

	# ---------------------------------------------------- the goal and its steps
	guide(room, "Light the four seals on Wren's door.", "II", "Wren's Test", "The Long Stair  ·  The Folded Galleries")
	step(room, "Repeat learned", Cond.FLAG, null, {"flag": "rune.frag.repeat"})
	step(room, "Up the Ember Lift: the seal of fire", Cond.POWERED, seals["fire"])
	step(room, "Down-Left learned", Cond.FLAG, null, {"flag": "rune.frag.down_left"})
	step(room, "Up the frozen fountains: the seal of ice", Cond.POWERED, seals["ice"])
	step(room, "Two hearths at once: the seal of space", Cond.POWERED, seals["space"])
	step(room, "The crystal lit: the seal of light", Cond.POWERED, seals["light"])
	step(room, "Wren's door opens", Cond.OPEN, wrens_door)
	step(room, "Wren speaks", Cond.FLAG, null, {"flag": "galleries.wren_spoke"})
	step(room, "The Fold Bell rings", Cond.POWERED, bell)
	for i in [4, 5]:
		step(room, "Ledger page %s found" % ["iv", "v"][i - 4], Cond.FLAG, null,
			{"flag": "galleries.page.%d" % i, "optional": true})

	hint(room, Vector2(cx(e + 4) + 16, FLOOR_Y), [
		"The way on is up the lift's shaft. The lift moves only while the brazier in the chimney over Wren's lock burns, and it burns two seconds.",
		"Repeat: it happens again and again while the cube is on.",
		"Read the tablet and finish Wren's sentence on the Ember Lock with Repeat. Ride the lift up.",
	], [ember_lock, ember, lift, tab_repeat])
	hint(room, Vector2(top_x - 320.0, FLOOR_Y), [
		"Five fountains leap and fall. Wren's Frost Lock hangs over them; its lectern is here.",
		"Frozen, a fountain is a pillar. Cold laid aslant meets each jet at a different height.",
		"At the lectern, finish the Frost Lock with Down-Left and switch it on, then climb the frozen jets to the walkway. Quickly: it holds a few breaths.",
	], [frost_lock, frost_lectern, tab_dl] + fountains)
	hint(room, Vector2(cx(t + 5), FLOOR_Y), [
		"Two hearths, each with a doorway under it. The seal wants both fires burning at once.",
		"Each burns two seconds, and they are too far apart to light one and run to the other. An Echo throws the fire you threw.",
		"Record an Echo throwing fire up through one doorway (wait a little first). Then go to the other and throw when your Echo does.",
	], [hearth_a[0], hearth_b[0], hearth_a[1], hearth_b[1]])
	hint(room, Vector2(cx(l + 5) + 32, FLOOR_Y), [
		"Wren's Lens Lock, three mirrors and a crystal. The last mirror's wheel is shut in the pocket over it.",
		"A plain beam stops at the first mirror. The Pocket Cube's doorway goes up into the pocket.",
		"Write Bounce on the Lens Lock. Turn the low mirror to send the beam up, the high one to send it right; go up through the Pocket Cube's doorway and turn the last to send it down.",
	], [lens_lock, m_low, m_high, m_far, pocket_cube, crystal])

	# ---------------------------------------------------- dressing
	for c in [e + 2, e + 9, f + 6, f + 12, t + 4, t + 13, l + 2, l + 11, d + 3]:
		torch(deco, c, 2)
	for x in [cx(e + 3) + 40, cx(f + 5), cx(t + 7) + 16, cx(l + 11) + 16]:
		deco_sprite(deco, "scroll_rack", Vector2(x, FLOOR_Y), false, -2)
	decor(e + 3, 1, W_WINDOW_MOON)
	decor(f + 7, 1, W_WINDOW_BARRED)
	decor(t + 6, 1, W_WINDOW_MOON)
	decor(d + 3, 1, W_WINDOW_MOON)
	for x in [cx(d + 1), cx(d + 3) + 20]:
		deco_sprite(chalk, "chalk_star", Vector2(x, 440.0), false, -1, true)
	waymark(room, cx(e + 4), "right")
	waymark(room, cx(f + 2), "down", 160.0)
	waymark(room, cx(t - 2), "right")
	waymark(room, cx(l - 2), "right")
	waymark(room, cx(d - 2), "right")
	prop(deco, "cobweb_corner", cx(WREN_END - 1) + 8, 12.0, true, true)


# ================================================================ the Eye

## The Eye: one tall, dark chamber under the monastery, the story's last
## room. The held moment hangs over the great cube as a vast moth held by
## four chains (EyeScene stages it), Ilse kneels at Wren's bed holding her
## hand, and Wren comes in with Echidna. Over the door: what cannot be kept
## can be sent. Wren's chalk on the plinth draws the other sentence. The hint
## stone points at those clues and names the two sentences only at its end.
## Whatever sentence is switched on the cube is read by
## scripts/runes/eye_altar.gd.
func build_eye() -> void:
	begin("Eye", "eye", "The Eye", "", [])
	shell(0, 30, HIGH_CEIL, true, true)
	var room := mk_room("R1", "The Eye", 0, 30, HIGH_CEIL, Vector2(cx(2), 530))
	shrine(room, "start", cx(2))
	var great := cube(room, "Great Cube", cx(16), "light/glow/self/normal",
		{"dungeon_powered": true, "carryable": false})

	var altar := inst(RUNES + "eye_altar.tscn", room, "Altar", Vector2(cx(16), FLOOR_Y))
	altar.set("cube_path", NodePath("../GreatCube"))
	# Wren's bed, the candle that must not go out, and Ilse kneeling at the
	# head of the bed, holding her daughter's hand
	var bed_x := cx(19)
	var wren_bed := room_sprite(room, "wren_bed", bed_x, 2.0, true)
	var ilse := room_sprite(room, "hk_ilse_kneel", bed_x - 38.0 - 22.0, 2.0, false)
	ilse.name = "Ilse"
	var crate := room_sprite(room, "crate", bed_x + 58.0, 2.0, false)
	crate.name = "Crate"
	var candle := room_sprite(room, "candle", bed_x + 58.0, 2.0, true)
	candle.name = "Candle"
	candle.position.y = FLOOR_Y - 27.0
	candle.set("unshaded", true)
	inst("res://scenes/torch_light.tscn", room, "CandleLight", Vector2(bed_x + 58.0, FLOOR_Y - 50.0))
	# Wren, at the door
	var wren := Node2D.new()
	wren.name = "Wren"
	wren.set_script(load("res://scripts/story/wren_meeting.gd"))
	wren.position = Vector2(cx(7), FLOOR_Y)
	wren.set("flag", "eye.wren_spoke")
	wren.set("lines", PackedStringArray([
		"wren/calm: This is my room. It's still the same night.",
		"echidna/worried: Is your mum here?",
		"wren/calm: By my bed. She's been holding my hand for sixty years.",
		"wren/smile: The words are on the big cube. I drew them for you, on the stone.",
		"wren/smile: Don't be scared. I'm not.",
	]))
	add_owned(room, wren)
	# The moth, its chains, the snow that does not fall
	var scene := Node2D.new()
	scene.name = "EyeScene"
	scene.set_script(load("res://scripts/story/eye_scene.gd"))
	scene.set("cube_x", cx(16))
	scene.set("floor_y", float(FLOOR_Y))
	add_owned(room, scene)
	# The clues: the words over the door, and Wren's chalk on the plinth
	var chalk := room_sprite(room, "chalk_star", cx(15) - 4.0, 1.0, false)
	chalk.name = "Chalk"
	chalk.position.y = FLOOR_Y - 6.0
	chalk.set("unshaded", true)
	var signs := group(room, "Signs")
	add_sign(signs, "Mural", 5.0, "Carved over the door: WHAT CANNOT BE KEPT CAN BE SENT.", FLOOR_Y, 190.0)
	add_sign(signs, "WrensChalk", 12.0, "Wren's chalk, low on the plinth: a star, and from it one line drawn straight up, on and on, off the top of the stone.", FLOOR_Y, 210.0, true)
	room.set("mood_ambient", 0.55)
	guide(room, "Write the last sentence on the great cube.", "", "", "")
	step(room, "A sentence on the great cube", Cond.POWERED, great)
	hint(room, Vector2(cx(9), FLOOR_Y), [
		"Two things in this room were written for you: the words over the door, and Wren's chalk on the plinth.",
		"The door says the moment is to be sent, not kept. Wren's chalk is a sentence: a star, a line from it, straight up, on and on.",
		"Light, Beam, Up, Long sends the held moment away. (Ice, Freeze, Self, Large keeps it, for ever.)",
	], [chalk, great, ilse])
	# Dark but for the door's torch, the candle and the moth's own cold light
	torch(group(room, "Decor"), 3)
	prop(room.get_node("Decor"), "skull_pile", cx(28), FLOOR_Y)
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
