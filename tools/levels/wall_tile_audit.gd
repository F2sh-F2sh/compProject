class_name WallTileAudit
extends RefCounted

## Wall tiles whose art stands on the ground (a broken pillar, a wooden door,
## the foot of an arcade) must rest on a floor, not float halfway up a wall,
## and the top of an arcade must sit right above its foot. Used by
## tools/levels/audit_wall_tiles.gd and by the presentation test suite.

const WALL_SOURCE := 1
const TILE := 64.0
const PILLAR := Vector2i(2, 2)
const DOOR := Vector2i(0, 2)
const ARCH_BOTTOM := Vector2i(1, 4)
const ARCH_TOP := Vector2i(4, 1)
const FLOOR_STANDING := [PILLAR, DOOR, ARCH_BOTTOM]
## How far (px) a tile's foot may sit from the ground under it.
const TOLERANCE := 6.0


## Every misplaced tile on the layer as {cell, atlas, gap}. gap is how far the
## ground is below the tile's foot (INF: no ground; NAN: an arcade top with
## no foot under it). The layer must be in a running scene.
static func find_misplaced(layer: TileMapLayer) -> Array:
	var out := []
	var space := layer.get_world_2d().direct_space_state
	for cell in layer.get_used_cells():
		if layer.get_cell_source_id(cell) != WALL_SOURCE:
			continue
		var atlas := layer.get_cell_atlas_coords(cell)
		if atlas == ARCH_TOP:
			if layer.get_cell_atlas_coords(cell + Vector2i(0, 1)) != ARCH_BOTTOM:
				out.append({"cell": cell, "atlas": atlas, "gap": NAN})
			continue
		if not FLOOR_STANDING.has(atlas):
			continue
		var gap := ground_gap(layer, space, cell)
		if not (absf(gap) <= TOLERANCE):
			out.append({"cell": cell, "atlas": atlas, "gap": gap})
	return out


## Distance from the tile's bottom edge down to the first solid ground.
static func ground_gap(layer: TileMapLayer, space: PhysicsDirectSpaceState2D, cell: Vector2i) -> float:
	var center := layer.to_global(layer.map_to_local(cell))
	var top := center - Vector2(0, TILE / 2.0)
	var query := PhysicsRayQueryParameters2D.create(top + Vector2(0, 4), top + Vector2(0, 900), 2)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return INF
	return hit["position"].y - (top.y + TILE)
