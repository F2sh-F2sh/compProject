@tool
extends TileMapLayer

## Floating Kilnworks shelves can be jumped through from below, like the
## hoists alongside them. Floors, ceiling beams and masonry remain solid.
## Use a private TileSet so other chapters keep their collision rules.
func _ready() -> void:
	tile_set = tile_set.duplicate(true)
	var platforms := tile_set.get_source(0) as TileSetAtlasSource
	for i in platforms.get_tiles_count():
		var coords := platforms.get_tile_id(i)
		if coords.y != 1:
			continue
		var data := platforms.get_tile_data(coords, 0)
		for polygon in data.get_collision_polygons_count(0):
			data.set_collision_polygon_one_way(0, polygon, true)
			data.set_collision_polygon_one_way_margin(0, polygon, 4.0)
