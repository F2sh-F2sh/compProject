class_name SurfaceArt
extends RefCounted

## The surface pixel-art packs (assets/surface, assets/town), cut into named
## sprites, and the story's hand-made sprites (assets/sprites/story, made by
## tools/generate_story_sprites.gd in the packs' palette). The story pictures
## and Lowbell are built entirely from these.
##
## Sprites are placed by their feet (bottom centre). In Lowbell the packs are
## drawn at 1.5x (3 screen pixels per art pixel under the 2x camera); the
## story pictures use a 384x216 art-pixel canvas at 3x.

const SHEETS := {
	"A": preload("res://assets/town/sheetA_buildings.png"),
	"B": preload("res://assets/town/sheetB_modular.png"),
	"C": preload("res://assets/town/sheetC_silhouettes.png"),
	"P": preload("res://assets/surface/sheet2_structures_props.png"),
	"N": preload("res://assets/surface/sheet3_nature_atmosphere.png"),
}
const GROUND_SHEET := preload("res://assets/surface/sheet1_ground_tiles.png")
const BACKDROPS := {
	"sky": preload("res://assets/surface/sheet4_bg_far.png"),
	"hills": preload("res://assets/surface/sheet4_bg_mid.png"),
	"woods": preload("res://assets/surface/sheet4_bg_near.png"),
	"town": preload("res://assets/town/sheetC_town_strip_640x320.png"),
}
const STRIP_DIR := "res://assets/sprites/story/"
## The hand-made sprites and how many frames each strip holds.
const STRIPS := {
	"tam": 3, "mira": 3, "pip": 3, "edda": 3, "nan": 3, "monk": 3, "ilse": 3,
	"wren_bed": 2, "great_bell": 2, "shrine_bell": 1, "candle": 3, "chime_tube": 1, "chime_post": 1,
	"rune_cube": 1, "rune_cube_great": 1, "door_echidna": 2, "door_nan": 2,
}
## The scale everything is drawn at in Lowbell.
const LANE_SCALE := 1.5

const REGIONS := {
	# Town, sheet A: whole houses
	"house_small": ["A", Rect2i(20, 64, 56, 64)],
	"house_medium": ["A", Rect2i(99, 48, 90, 80)],
	"house_big": ["A", Rect2i(210, 16, 108, 112)],
	"house_shop": ["A", Rect2i(336, 50, 112, 78)],
	"house_ruined": ["A", Rect2i(470, 50, 89, 78)],
	"house_tower": ["A", Rect2i(583, 17, 50, 111)],
	"house_tiny": ["A", Rect2i(656, 96, 32, 32)],
	# Town, sheet B: parts
	"door_small": ["B", Rect2i(16, 97, 16, 31)],
	"door_tall": ["B", Rect2i(144, 81, 16, 47)],
	"win_arch_dark": ["B", Rect2i(19, 145, 10, 15)],
	"win_arch_lit": ["B", Rect2i(51, 145, 10, 15)],
	"win_arch_bright": ["B", Rect2i(83, 145, 10, 15)],
	"win_round_dark": ["B", Rect2i(115, 146, 11, 12)],
	"win_round_lit": ["B", Rect2i(147, 146, 11, 12)],
	"win_round_bright": ["B", Rect2i(179, 146, 11, 12)],
	"win_square_lit": ["B", Rect2i(338, 145, 12, 14)],
	"awning": ["B", Rect2i(96, 244, 32, 12)],
	"slab": ["B", Rect2i(16, 248, 32, 8)],
	"bracket": ["B", Rect2i(241, 224, 9, 32)],
	"wall_lantern": ["B", Rect2i(304, 224, 16, 30)],
	"lamp_post": ["B", Rect2i(336, 180, 31, 76)],
	# Town, sheet C: silhouettes for the far distance
	"sil_big": ["C", Rect2i(18, 16, 108, 112)],
	"sil_shop": ["C", Rect2i(144, 50, 112, 78)],
	"sil_medium": ["C", Rect2i(275, 48, 90, 80)],
	"sil_ruined": ["C", Rect2i(390, 50, 89, 78)],
	"sil_tower": ["C", Rect2i(503, 17, 50, 111)],
	# Surface, structures and props
	"arch": ["P", Rect2i(13, 8, 62, 72)],
	"crypt": ["P", Rect2i(89, 27, 70, 53)],
	"ruin_house": ["P", Rect2i(168, 13, 66, 66)],
	"wall_broken": ["P", Rect2i(8, 112, 34, 31)],
	"wall_low": ["P", Rect2i(56, 118, 34, 25)],
	"pillar": ["P", Rect2i(105, 96, 16, 47)],
	"well": ["P", Rect2i(137, 104, 34, 39)],
	"cart": ["P", Rect2i(187, 123, 49, 21)],
	"log": ["P", Rect2i(248, 130, 34, 13)],
	"fence": ["P", Rect2i(8, 168, 34, 24)],
	"fence_broken": ["P", Rect2i(56, 168, 34, 24)],
	"gate": ["P", Rect2i(104, 158, 34, 34)],
	"signpost": ["P", Rect2i(152, 165, 21, 27)],
	"lantern": ["P", Rect2i(185, 158, 15, 31)],
	"grave_round": ["P", Rect2i(208, 168, 18, 24)],
	"grave_cross": ["P", Rect2i(240, 167, 18, 25)],
	"grave_celtic": ["P", Rect2i(272, 167, 18, 25)],
	"grave_broken": ["P", Rect2i(304, 174, 18, 18)],
	"barrel": ["P", Rect2i(337, 175, 14, 17)],
	"barrel_broken": ["P", Rect2i(361, 175, 14, 17)],
	"rubble": ["P", Rect2i(384, 178, 15, 14)],
	"crate": ["P", Rect2i(408, 178, 15, 14)],
	# Surface, nature and creatures
	"tree_big": ["N", Rect2i(8, 25, 84, 87)],
	"tree_small": ["N", Rect2i(105, 62, 42, 50)],
	"bush_dead": ["N", Rect2i(160, 96, 24, 16)],
	"bush": ["N", Rect2i(197, 98, 15, 14)],
	"bramble": ["N", Rect2i(225, 102, 28, 10)],
	"rock_big": ["N", Rect2i(274, 94, 28, 18)],
	"rock": ["N", Rect2i(312, 100, 19, 12)],
	"rock_small": ["N", Rect2i(345, 105, 10, 7)],
	"spire": ["N", Rect2i(368, 90, 11, 22)],
	"grass_1": ["N", Rect2i(9, 147, 13, 13)],
	"grass_2": ["N", Rect2i(35, 147, 11, 13)],
	"grass_3": ["N", Rect2i(59, 147, 13, 13)],
	"grass_4": ["N", Rect2i(80, 148, 15, 12)],
	"grass_5": ["N", Rect2i(106, 148, 13, 12)],
	"grass_6": ["N", Rect2i(130, 148, 14, 12)],
	"grass_7": ["N", Rect2i(153, 146, 12, 14)],
	"grass_8": ["N", Rect2i(180, 146, 9, 14)],
	"grass_9": ["N", Rect2i(204, 146, 11, 14)],
	"flower_small": ["N", Rect2i(226, 154, 7, 6)],
	"flowers": ["N", Rect2i(249, 153, 10, 7)],
	"flowers_big": ["N", Rect2i(272, 152, 12, 8)],
	"vine_long": ["N", Rect2i(298, 127, 10, 33)],
	"vine": ["N", Rect2i(320, 135, 11, 25)],
	"vine_short": ["N", Rect2i(345, 143, 10, 17)],
	"bat_rest": ["N", Rect2i(8, 174, 10, 10)],
	"bat_up": ["N", Rect2i(32, 175, 14, 9)],
	"bat_flat": ["N", Rect2i(56, 176, 16, 8)],
	"crow": ["N", Rect2i(80, 171, 12, 13)],
	"crow_fly_a": ["N", Rect2i(104, 174, 15, 10)],
	"crow_fly_b": ["N", Rect2i(128, 175, 15, 9)],
	"spark_tiny": ["N", Rect2i(187, 179, 2, 2)],
	"spark": ["N", Rect2i(201, 177, 5, 5)],
	"spark_small": ["N", Rect2i(218, 178, 3, 3)],
	"leaf_a": ["N", Rect2i(233, 177, 6, 5)],
	"leaf_b": ["N", Rect2i(250, 177, 4, 6)],
	"leaf_c": ["N", Rect2i(264, 179, 7, 4)],
	"cloud_a": ["N", Rect2i(8, 201, 57, 14)],
	"cloud_b": ["N", Rect2i(95, 202, 49, 13)],
	"cloud_c": ["N", Rect2i(152, 204, 48, 12)],
}

## Ground tiles: 16x16 on a 20-pixel grid (4 px margin and gaps).
const TILES := {
	"grass_a": Vector2i(0, 0), "grass_b": Vector2i(1, 0), "grass_c": Vector2i(7, 1),
	"grass_end_l": Vector2i(2, 0), "grass_end_r": Vector2i(3, 0),
	"dirt_a": Vector2i(6, 2), "dirt_b": Vector2i(7, 2), "dirt_c": Vector2i(0, 3),
	"dirt_stones": Vector2i(1, 3), "dirt_skull": Vector2i(2, 3),
	"plank_l": Vector2i(3, 3), "plank_m": Vector2i(4, 3), "plank_r": Vector2i(5, 3),
	"slab_end": Vector2i(7, 3), "slab_a": Vector2i(0, 4), "slab_b": Vector2i(1, 4),
	"bricks_grass_a": Vector2i(2, 4), "bricks_grass_b": Vector2i(3, 4),
	"bricks_top": Vector2i(4, 4), "bricks_step": Vector2i(5, 4),
	"bricks_a": Vector2i(6, 4), "bricks_b": Vector2i(7, 4),
	"bricks_roots": Vector2i(0, 5), "bricks_vines": Vector2i(1, 5),
	"brick_ledge_a": Vector2i(3, 1), "brick_ledge_b": Vector2i(4, 1),
}
## Where a grass tile's walkable surface is, below the tile's top (art px).
const GRASS_SURFACE := 4

static var _textures := {}
static var _frames := {}
static var _tile_set: TileSet


# ------------------------------------------------------------------ textures

## A named sprite's texture (a pack region, or a strip's first frame).
static func tex(sprite_name: String, frame := 0) -> Texture2D:
	var key := "%s#%d" % [sprite_name, frame]
	if _textures.has(key):
		return _textures[key]
	var atlas := AtlasTexture.new()
	if REGIONS.has(sprite_name):
		var spec: Array = REGIONS[sprite_name]
		atlas.atlas = SHEETS[spec[0]]
		atlas.region = Rect2(spec[1])
	elif STRIPS.has(sprite_name):
		var strip: Texture2D = load(STRIP_DIR + sprite_name + ".png")
		var w := strip.get_width() / int(STRIPS[sprite_name])
		atlas.atlas = strip
		atlas.region = Rect2(w * frame, 0, w, strip.get_height())
	elif TILES.has(sprite_name):
		var c: Vector2i = TILES[sprite_name]
		atlas.atlas = GROUND_SHEET
		atlas.region = Rect2(4 + c.x * 20, 4 + c.y * 20, 16, 16)
	else:
		push_error("SurfaceArt: no sprite called '%s'" % sprite_name)
		return null
	_textures[key] = atlas
	return atlas


static func size_of(sprite_name: String) -> Vector2:
	var t := tex(sprite_name)
	return t.get_size() if t else Vector2.ZERO


## A sprite standing with its feet (bottom centre) at `foot`.
static func sprite(parent: Node, sprite_name: String, foot: Vector2, scale := LANE_SCALE, flip := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = sprite_name.to_pascal_case()
	s.texture = tex(sprite_name)
	s.centered = false
	var size := s.texture.get_size()
	s.offset = Vector2(-floorf(size.x / 2.0), -size.y)
	s.position = foot
	s.scale = Vector2(scale, scale)
	s.flip_h = flip
	parent.add_child(s)
	return s


## The frames of a hand-made strip, or of a list of pack sprites (e.g. a
## bat's wingbeats), as one looping animation called "default".
static func frames(names: Variant, fps := 6.0) -> SpriteFrames:
	var key := "%s@%s" % [str(names), fps]
	if _frames.has(key):
		return _frames[key]
	var sf := SpriteFrames.new()
	sf.set_animation_speed(&"default", fps)
	if names is String:
		for i in STRIPS.get(names, 1):
			sf.add_frame(&"default", tex(names, i))
	else:
		for n in names:
			sf.add_frame(&"default", tex(n))
	_frames[key] = sf
	return sf


## An animated sprite, feet at `foot` (every frame must share a size).
static func animated(parent: Node, names: Variant, foot: Vector2, fps := 6.0, scale := LANE_SCALE, flip := false) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	a.sprite_frames = frames(names, fps)
	a.centered = false
	var size := a.sprite_frames.get_frame_texture(&"default", 0).get_size()
	a.offset = Vector2(-floorf(size.x / 2.0), -size.y)
	a.position = foot
	a.scale = Vector2(scale, scale)
	a.flip_h = flip
	parent.add_child(a)
	a.play(&"default")
	return a


# ------------------------------------------------------------------ ground

static func _tiles() -> TileSet:
	if _tile_set:
		return _tile_set
	_tile_set = TileSet.new()
	_tile_set.tile_size = Vector2i(16, 16)
	var source := TileSetAtlasSource.new()
	source.texture = GROUND_SHEET
	source.texture_region_size = Vector2i(16, 16)
	source.margins = Vector2i(4, 4)
	source.separation = Vector2i(4, 4)
	for c in TILES.values():
		if not source.has_tile(c):
			source.create_tile(c)
	_tile_set.add_source(source, 0)
	return _tile_set


## A strip of ground from x0 to x1 whose walkable surface is at `surface_y`:
## a top row of `top` tiles (picked at random) over `depth` rows of `fill`.
static func ground(parent: Node, x0: float, x1: float, surface_y: float, scale := LANE_SCALE, depth := 3,
		top: Array = ["grass_a", "grass_b", "grass_c"], fill: Array = ["dirt_a", "dirt_b", "dirt_c", "dirt_a", "dirt_stones"],
		seed_value := 1) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = "Ground"
	layer.tile_set = _tiles()
	layer.scale = Vector2(scale, scale)
	layer.position = Vector2(x0, surface_y - GRASS_SURFACE * scale)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var count := int(ceil((x1 - x0) / (16.0 * scale)))
	for i in count:
		layer.set_cell(Vector2i(i, 0), 0, TILES[top[rng.randi() % top.size()]])
		for r in depth:
			var pick: String = fill[rng.randi() % fill.size()]
			if pick == "dirt_skull" and rng.randf() > 0.3:
				pick = "dirt_a"
			layer.set_cell(Vector2i(i, r + 1), 0, TILES[pick])
	parent.add_child(layer)
	return layer


## A block of tiles filling a rectangle (a wall, a floor), in tile units
## from `at`.
static func tile_block(parent: Node, at: Vector2, cols: int, rows: int, names: Array, scale := LANE_SCALE,
		seed_value := 1) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = _tiles()
	layer.scale = Vector2(scale, scale)
	layer.position = at
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for y in rows:
		for x in cols:
			layer.set_cell(Vector2i(x, y), 0, TILES[names[rng.randi() % names.size()]])
	parent.add_child(layer)
	return layer


## A row of named tiles, left to right, from `at`.
static func tile_row(parent: Node, at: Vector2, names: Array, scale := LANE_SCALE) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.tile_set = _tiles()
	layer.scale = Vector2(scale, scale)
	layer.position = at
	for i in names.size():
		layer.set_cell(Vector2i(i, 0), 0, TILES[names[i]])
	parent.add_child(layer)
	return layer


# ------------------------------------------------------------------ distance

## One of the 640x320 parallax paintings (sky, hills, woods, town), with
## its top-left at `at`, repeated sideways to cover `width` (art pixels).
static func backdrop(parent: Node, backdrop_name: String, at: Vector2, scale: float, width := 640.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = backdrop_name.to_pascal_case()
	s.texture = BACKDROPS[backdrop_name]
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(0, 0, width, 320)
	s.position = at
	s.scale = Vector2(scale, scale)
	parent.add_child(s)
	return s


## The sky's own top colour, for filling above the painting.
const SKY_TOP := Color("0b0d20")
