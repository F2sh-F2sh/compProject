class_name RoomKit
extends RefCounted

## Builds a level's rooms while the game runs. This is a port, to run-time, of
## the helpers the story's level builders use (tools/build_chapter.gd,
## build_chapter2.gd, build_wings.gd), so a daily puzzle is made of exactly the
## same tiles, rooms, gates, circuits and rune pieces as the story's rooms.
## It is a copy on purpose: the builders write the story's saved scenes and
## must never be touched by the daily puzzle.
##
## Geometry (tiles are 64 px): floor surface y 534 (row 8); ordinary ceiling
## underside y 272; a +32 kerb (a step Echidna hops and a loose crate cannot
## climb). Rooms share their end wall column, with a doorway (rows 6-7) that a
## gate shuts.

const T := 64
const FLOOR_Y := 534
const LOW_CEIL := 4
const HIGH_CEIL := 0
const TILESET_PATH := "res://assets/TileSet/dungeon_tileset.tres"
const PUZZLE := "res://scenes/puzzle/"
const RUNES := "res://scenes/runes/"
const AMBIENT := Color(0.5, 0.48, 0.64)

const LEDGES := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
const BEAMS := [Vector2i(1, 3), Vector2i(1, 3), Vector2i(1, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3)]
const WALL_PLAIN := [Vector2i(0, 0), Vector2i(4, 4), Vector2i(0, 0), Vector2i(4, 4), Vector2i(1, 0)]
const WALL_RARE := [Vector2i(0, 1), Vector2i(2, 0), Vector2i(2, 1), Vector2i(1, 1)]
const W_TORCH := Vector2i(3, 2)
const W_VINES_TOP := Vector2i(3, 0)
const W_WINDOW_DOUBLE := Vector2i(2, 3)
const W_BANNER_FLEUR := Vector2i(1, 3)

## Where a room's decoration is drawn from (a different one each day).
var rng: DailyRng
var level: Node2D
var ts: TileSet
var background: TileMapLayer
var back_decor: TileMapLayer
var earth: TileMapLayer
var ceiling: TileMapLayer
var ground: TileMapLayer
var ground_half: TileMapLayer
## "R1", "R2"... -> the Room node.
var rooms := {}


func _init(root: Node2D, random: DailyRng) -> void:
	level = root
	rng = random
	ts = load(TILESET_PATH)
	background = _tile_layer("Background", Vector2(0, 22), Color(0.88, 0.86, 0.99), -10, false, false)
	back_decor = _tile_layer("BackDecor", Vector2(0, 22), Color(1.0, 1.0, 1.0), -9, false, false)
	earth = _tile_layer("Earth", Vector2.ZERO, Color(0.73, 0.69, 0.84))
	ceiling = _tile_layer("Ceiling", Vector2(0, -4))
	ground = _tile_layer("Ground")
	ground_half = _tile_layer("GroundHalf", Vector2(0, 32))


func _tile_layer(layer_name: String, pos := Vector2.ZERO, tint := Color.WHITE, z := 0, collide := true, occlude := true) -> TileMapLayer:
	var l := TileMapLayer.new()
	l.name = layer_name
	l.tile_set = ts
	l.position = pos
	l.modulate = tint
	l.z_index = z
	l.collision_enabled = collide
	l.occlusion_enabled = occlude
	level.add_child(l)
	return l


# ------------------------------------------------------------------ placement

static func cx(col: float) -> float:
	return col * T + T / 2.0


## Instances a saved scene (or a piece scene) under `parent` with its
## properties set before it enters the tree.
func inst(path: String, parent: Node, node_name: String, pos: Vector2, props := {}) -> Node:
	var node: Node = load(path).instantiate()
	node.name = node_name
	if node is Node2D:
		node.position = pos
	for key in props:
		node.set(key, props[key])
	parent.add_child(node)
	return node


## An untyped list as the typed Array[Node] the pieces' exports want.
static func nodes(list: Array) -> Array[Node]:
	var typed: Array[Node] = []
	for n in list:
		typed.append(n)
	return typed


func group(parent: Node, group_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = group_name
	parent.add_child(n)
	return n


# ------------------------------------------------------------------ tiles

func solid(x: int, y: int) -> void:
	earth.set_cell(Vector2i(x, y), 2, Vector2i(1, 0) if (x + y) % 3 else Vector2i(4, 4))


func ledge_tile() -> Vector2i:
	return LEDGES[rng.int_range(0, LEDGES.size() - 1)]


func floor_tile(x: int, row := 8) -> void:
	ground.set_cell(Vector2i(x, row), 0, ledge_tile())


## Walls, ceiling rock, beams, floor and bedrock for one room. The two end
## columns are walls with a doorway (rows 6-7 open) unless marked outer.
func shell(x0: int, x1: int, ceil_row: int, outer_left := false, outer_right := false) -> void:
	for x in range(x0, x1 + 1):
		for y in range(ceil_row - 3, 11):
			var tile: Vector2i = WALL_PLAIN[rng.int_range(0, WALL_PLAIN.size() - 1)]
			if rng.chance(0.08):
				tile = WALL_RARE[rng.int_range(0, WALL_RARE.size() - 1)]
			if y == ceil_row - 1 and rng.chance(0.3):
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
			ceiling.set_cell(Vector2i(x, ceil_row), 0, BEAMS[rng.int_range(0, BEAMS.size() - 1)])
			floor_tile(x)


## A +32 kerb (surface y 502): a step the player hops, a block cannot climb.
func curb(x: int) -> void:
	ground_half.set_cell(Vector2i(x, 7), 0, LEDGES[x % LEDGES.size()])


func decor(x: int, y: int, tile: Vector2i) -> void:
	back_decor.set_cell(Vector2i(x, y), 1, tile)


func torch(parent: Node, col: int, row := 6) -> void:
	decor(col, row, W_TORCH)
	inst("res://scenes/torch_light.tscn", parent, "Torch%d_%d" % [col, row], Vector2(cx(col), row * T + 22 + 14))


# ------------------------------------------------------------------ rooms

## A room of columns x0..x1 whose camera area is the room (its entry spawn is
## where Reset Room and a respawn put the player).
func make_room(id: String, title: String, x0: int, x1: int, ceil_row: int, entry: Vector2, mood: int, index: int) -> Room:
	var bounds := Rect2(x0 * T, (ceil_row - 2) * T, (x1 + 1 - x0) * T, 9 * T - (ceil_row - 2) * T)
	var moods := [
		[Color(0.98, 1.03, 1.1), Color(0.25, 0.34, 0.5)],
		[Color(1.0, 1.03, 1.08), Color(0.26, 0.35, 0.48)],
		[Color(0.96, 1.04, 1.1), Color(0.24, 0.36, 0.5)],
		[Color(1.02, 1.02, 1.06), Color(0.3, 0.32, 0.46)],
	]
	var m: Array = moods[mood % moods.size()]
	var room := inst(PUZZLE + "room.tscn", level, id, Vector2.ZERO, {
		"room_id": "daily." + id.to_lower(),
		"title": title,
		"bounds": bounds,
		"entry_spawn": entry,
		"mood_highlight": m[0],
		"mood_fog": m[1],
		"mood_ambient": 1.0,
	}) as Room
	rooms[id] = room
	var zone := Area2D.new()
	zone.name = "Acoustics"
	zone.set_script(load("res://scripts/audio/reverb_zone.gd"))
	zone.position = bounds.position
	zone.set("size", bounds.size)
	zone.set("acoustics", 0)
	room.add_child(zone)
	return room


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


## The room's goal (never the solution), shown in the objective panel.
func guide(room: Node, objective: String) -> void:
	room.set("objective", objective)


## One step of a room's goal, ticked off when its condition holds.
func step(room: Node, label: String, cond: int, target: Node = null, props := {}) -> Node:
	var s := Node.new()
	s.set_script(load("res://scripts/puzzle/objective_step.gd"))
	var count := room.get_children().filter(func(n): return n.get_script() == s.get_script()).size()
	s.name = "Step%d" % (count + 1)
	room.add_child(s)
	s.set("label", label)
	s.set("condition", cond)
	if target:
		s.set("target", target)
	for key in props:
		s.set(key, props[key])
	return s


## The Choir's chalk arrows: soon after the way in, and just before the way out.
func waymarks(room: Node, x0: int, x1: int) -> void:
	inst(PUZZLE + "waymark.tscn", room, "Waymark1", Vector2(x0 * T + 7.5 * T, FLOOR_Y - 76), {"direction": "right"})
	inst(PUZZLE + "waymark.tscn", room, "Waymark2", Vector2(x1 * T - 1.6 * T, FLOOR_Y - 76), {"direction": "right"})


# ------------------------------------------------------------------ rune pieces

const LOCK_ESSENCE := 1
const LOCK_FORM := 2
const LOCK_DIRECTION := 4
const LOCK_MODIFIER := 8


## A rune cube standing on the floor at world x.
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


func plate(parent: Node, plate_name: String, x: float, props := {}) -> Node:
	return inst("res://scenes/pressure_plate.tscn", parent, plate_name, Vector2(x, FLOOR_Y), props)
