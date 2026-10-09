class_name CreatureSpawner
extends RefCounted

## Scatters each level's creatures (Creature) through its rooms when the level
## loads (LevelTheme calls populate()): on open stretches of floor, well away
## from every puzzle piece, sign, door, shrine and person (anything with an
## Area2D, every rune cube) and from each room's way in; a few per room,
## spaced out (a room's own slimes and watchers count towards both), the same
## way every time. Flyers and drifters hang in the air above their spot.
## The Passage (no rooms) keeps just its taught slimes: it is the movement
## lesson. The Landing is the safe hub between the wings: nothing roams there.
## Tests keep them away (GameState.calm_creatures) except where they test them.

## Which creatures live where (a theme missing here has none).
const KINDS_BY_THEME := {
	"belfry": ["bat", "mite"], "observatory": ["mite", "bat"],
	"kiln": ["cinderling", "clinker"], "cistern": ["frostling", "jelly"], "lamps": ["moth"],
	"galleries": ["foldmite", "moth"], "eye": ["hushling"],
}
## How near a puzzle piece (or anything a player reads or uses) a creature may start.
const KEEP_OUT := 170.0
## How near a room's way in.
const ENTRY_KEEP_OUT := 300.0
## How far apart two creatures start.
const SPACING := 400.0


static func populate(level: Node, theme: String) -> Array:
	var made: Array = []
	if GameState.calm_creatures or not KINDS_BY_THEME.has(theme):
		return made
	var ground := level.get_node_or_null("Ground") as TileMapLayer
	if ground == null:
		return made
	var kinds: Array = KINDS_BY_THEME[theme]
	# what to stay clear of
	var avoid: Array[Vector2] = []
	for node in level.find_children("*", "Area2D", true, false):
		avoid.append(node.global_position)
	for node in level.get_tree().get_nodes_in_group("rune_cube"):
		avoid.append(node.global_position)
	var residents: Array[Vector2] = []
	for node in level.get_tree().get_nodes_in_group("enemy") + level.get_tree().get_nodes_in_group("gargoyle"):
		residents.append(node.global_position)
	var floors := _floor_tops(ground)
	var holder := Node2D.new()
	holder.name = "Creatures"
	level.add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(theme + String(level.scene_file_path))
	var count := 0
	for region in _regions(level):
		var area: Rect2 = region["area"]
		var spots: Array[Vector2] = []
		for top in floors:
			if not area.has_point(top + Vector2(0, -8)):
				continue
			if top.distance_to(region["entry"]) < ENTRY_KEEP_OUT:
				continue
			if avoid.any(func(p): return p.distance_to(top) < KEEP_OUT):
				continue
			spots.append(top)
		for i in range(spots.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var swap: Vector2 = spots[i]
			spots[i] = spots[j]
			spots[j] = swap
		var limit := clampi(int(area.size.x / 900.0), 1, 4)
		var chosen: Array[Vector2] = []
		for p in residents:
			if area.has_point(p):
				chosen.append(p)
		var already := chosen.size()
		for spot in spots:
			if chosen.size() >= limit:
				break
			if chosen.any(func(p): return p.distance_to(spot) < SPACING):
				continue
			chosen.append(spot)
		for spot: Vector2 in chosen.slice(already):
			var c := Creature.new()
			c.kind = kinds[count % kinds.size()]
			var moves := String(Creature.KINDS[c.kind]["move"])
			var at: Vector2 = spot
			if moves in ["flyer", "drifter"]:
				at = spot + Vector2(0, -90)
				if ground.get_cell_source_id(ground.local_to_map(ground.to_local(at))) != -1:
					at = spot + Vector2(0, -44)
			c.position = holder.to_local(at)
			c.home_radius = 200.0
			holder.add_child(c)
			made.append(c)
			count += 1
	return made


## Every walkable floor top: a Ground cell with nothing above it.
static func _floor_tops(ground: TileMapLayer) -> Array[Vector2]:
	var tops: Array[Vector2] = []
	for cell in ground.get_used_cells():
		if ground.get_cell_source_id(cell + Vector2i(0, -1)) != -1:
			continue
		tops.append(ground.to_global(ground.map_to_local(cell)) + Vector2(0, -10))
	return tops


## The level's rooms as {area, entry}.
static func _regions(level: Node) -> Array:
	var regions: Array = []
	for room in level.find_children("*", "Room", true, false):
		regions.append({"area": room.bounds, "entry": room.entry_spawn})
	return regions
