class_name DungeonAtmosphere
extends Node2D

## The dungeon's depth and light, layered like a painted stage set:
##  - far: a distant hall lost in mist (Parallax2D, slowest)
##  - mid: crumbling arcades and broken columns (Parallax2D)
##  - the playfield's own brick wall, broken open in `breaches` so the far
##    layers show through, with crumbled edges and a shadowed thickness
##  - light shafts falling from those breaches, with dust in them
##  - front: roots, vines and thorns framing the top and bottom of the view
##    (Parallax2D, faster than the camera, pinned to the screen's edges)
## Add one to a level and point `wall_path` at its back-wall TileMapLayer.

const FAR := preload("res://assets/fx/far_fog.png")
const MID := preload("res://assets/fx/mid_ruins.png")
const FRONT_TOP := preload("res://assets/fx/front_vines.png")
const FRONT_BOTTOM := preload("res://assets/fx/front_thorns.png")
const WALL_ATLAS := "res://assets/tileset/walls/walls_atlas_64.png"

## The brick back-wall layer to break open.
@export var wall_path: NodePath
## Decoration layer whose cells (torches, windows) must never be broken.
@export var decor_path: NodePath
## Openings in the back wall, in that layer's cells: position = top-left
## cell, size = width x height in cells. Each gets a light shaft.
@export var breaches: Array[Rect2i] = []
## Openings with a light shaft but no hole (e.g. cracks high in a ceiling).
@export var extra_shafts: PackedVector2Array = PackedVector2Array()
## Where light shafts end: the floor surface.
@export var floor_y := 534.0
## The camera centre at which every parallax plane lines up with the world.
@export var reference_center := Vector2(2000, 400)
@export var seed := 1

@export_group("Parallax")
@export var far_scroll := Vector2(0.18, 0.85)
@export var mid_scroll := Vector2(0.45, 0.92)
@export var front_scroll := 1.3
## World y of the top of the far / mid pictures (at the reference camera).
@export var far_top := 0.0
@export var mid_top := -100.0
@export var show_front := true
@export var front_tint := Color(1, 1, 1, 0.92)

@export_group("Light")
@export var shaft_color := Color(0.68, 0.85, 0.95)
@export_range(0.0, 1.0) var shaft_intensity := 0.5
@export var shaft_angle_deg := 16.0
@export var shaft_light_energy := 0.5

var planes := {}
var shafts: Array[LightShaft] = []
var _wall: TileMapLayer
var _decor: TileMapLayer
var _holes := {}
var _edges: Node2D
var _wall_color := Color(0.2, 0.18, 0.27)


func _ready() -> void:
	_wall = get_node_or_null(wall_path) as TileMapLayer
	_decor = get_node_or_null(decor_path) as TileMapLayer
	_build_planes()
	_open_breaches()
	_place_shafts()


func _process(_delta: float) -> void:
	_align_planes()


# ---------------------------------------------------------------- parallax

func _unshaded() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return mat


func _plane(plane_name: String, texture: Texture2D, scroll: Vector2, z: int, top: float) -> Parallax2D:
	var plane := Parallax2D.new()
	# (placed from the camera every drawn frame: drawn where it is)
	plane.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	plane.name = plane_name
	plane.scroll_scale = scroll
	plane.repeat_size = Vector2(texture.get_width(), 0)
	plane.repeat_times = 3
	plane.z_index = z
	plane.z_as_relative = false
	var sprite := Sprite2D.new()
	sprite.name = "Picture"
	sprite.texture = texture
	sprite.centered = false
	sprite.position = Vector2(0, top)
	sprite.material = _unshaded()
	plane.add_child(sprite)
	add_child(plane)
	planes[plane_name] = plane
	return plane


func _build_planes() -> void:
	_plane("FarFog", FAR, far_scroll, -40, far_top)
	_plane("MidRuins", MID, mid_scroll, -30, mid_top)
	if show_front:
		var front := _plane("FrontVines", FRONT_TOP, Vector2(front_scroll, 0.0), 40, 0.0)
		var bottom := Sprite2D.new()
		bottom.name = "Thorns"
		bottom.texture = FRONT_BOTTOM
		bottom.centered = false
		bottom.material = _unshaded()
		front.add_child(bottom)
		for sprite in front.get_children():
			sprite.modulate = front_tint
	_align_planes()


## Parallax2D places a plane at (camera centre - viewport size / 2) scaled by
## (1 - scroll) plus scroll_offset. These offsets make every plane line up
## with the world at `reference_center`, and pin the front plane's pictures
## to the top and bottom edges of the view whatever the zoom.
func _align_planes() -> void:
	var viewport_size := get_viewport_rect().size
	var camera := get_viewport().get_camera_2d()
	var half_view := viewport_size / 2.0
	if camera:
		half_view = viewport_size / camera.zoom / 2.0
	for plane_name in planes:
		var plane: Parallax2D = planes[plane_name]
		var scroll := plane.scroll_scale
		var off := -(reference_center - viewport_size / 2.0) * (Vector2.ONE - scroll)
		if plane_name == "FrontVines":
			# Vertically fixed to the screen: top picture at the view's top
			# edge, thorns sitting on its bottom edge
			off.y = viewport_size.y / 2.0 - half_view.y
			var thorns: Sprite2D = plane.get_node("Thorns")
			thorns.position.y = half_view.y * 2.0 - FRONT_BOTTOM.get_height() + 12.0
		plane.scroll_offset = off


# ---------------------------------------------------------------- breaches

func _open_breaches() -> void:
	if _wall == null or breaches.is_empty():
		return
	_wall_color = _sample_wall_color()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	for rect in breaches:
		# An irregular hole: widest in the middle rows, ragged at the ends
		for row in rect.size.y:
			var t := (row + 0.5) / rect.size.y
			var bulge := sin(t * PI)
			var trim_left := int(round((1.0 - bulge) * rect.size.x * 0.35 + rng.randf_range(-0.4, 0.6)))
			var trim_right := int(round((1.0 - bulge) * rect.size.x * 0.35 + rng.randf_range(-0.4, 0.6)))
			for col in range(trim_left, rect.size.x - trim_right):
				var cell := rect.position + Vector2i(col, row)
				if _decor and _decor.get_cell_source_id(cell) != -1:
					continue
				_wall.erase_cell(cell)
				_holes[cell] = true
	_edges = Node2D.new()
	_edges.name = "BreachEdges"
	_edges.z_index = _wall.z_index + 2
	_edges.z_as_relative = false
	_edges.position = _wall.position
	_edges.draw.connect(_draw_edges.bind(rng.randi()))
	add_child(_edges)


## The average colour of the brick art, so crumbled edges match the wall.
func _sample_wall_color() -> Color:
	# (Through the imported texture: the source PNG isn't there in an export)
	var tex := load(WALL_ATLAS) as Texture2D
	var img := tex.get_image() if tex else null
	if img == null or img.is_empty():
		return _wall_color
	if img.is_compressed():
		img.decompress()
	var sum := Color(0, 0, 0, 0)
	var count := 0
	for y in range(0, 64, 2):
		for x in range(0, 64, 2):
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				sum += c
				count += 1
	var avg := sum / maxf(count, 1)
	return Color(avg.r, avg.g, avg.b) * _wall.modulate


## Around each hole: a dark band just inside (the wall's thickness) and
## chipped stone teeth, so the break never shows square tile edges.
func _draw_edges(edge_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = edge_seed
	var size := float(_wall.tile_set.tile_size.x)
	var shadow := Color(0.01, 0.01, 0.025, 0.72)
	var dirs := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for cell in _holes:
		var origin := Vector2(cell) * size
		for dir in dirs:
			if _holes.has(cell + dir):
				continue
			# The side of this hole cell that meets unbroken wall
			var a: Vector2
			var b: Vector2
			match dir:
				Vector2i.LEFT:
					a = origin
					b = origin + Vector2(0, size)
				Vector2i.RIGHT:
					a = origin + Vector2(size, 0)
					b = origin + Vector2(size, size)
				Vector2i.UP:
					a = origin
					b = origin + Vector2(size, 0)
				_:
					a = origin + Vector2(0, size)
					b = origin + Vector2(size, size)
			var inward := -Vector2(dir)
			_edges.draw_colored_polygon(PackedVector2Array([a, b, b + inward * 9.0, a + inward * 9.0]), shadow)
			var along := (b - a) / size
			var x := 0.0
			while x < size:
				var w := rng.randf_range(5.0, 14.0)
				var depth := rng.randf_range(3.0, 11.0)
				var p0 := a + along * x
				var p1 := a + along * minf(x + w, size)
				var tip := a + along * (x + w * rng.randf_range(0.3, 0.7)) + inward * depth
				_edges.draw_colored_polygon(PackedVector2Array([p0, p1, tip]), _wall_color)
				x += w


## World rectangles of the openings (for tests and designers).
func get_breach_rects() -> Array[Rect2]:
	var result: Array[Rect2] = []
	if _wall == null:
		return result
	var size := Vector2(_wall.tile_set.tile_size)
	for rect in breaches:
		result.append(Rect2(_wall.position + Vector2(rect.position) * size, Vector2(rect.size) * size))
	return result


func is_open(cell: Vector2i) -> bool:
	return _holes.has(cell)


# ---------------------------------------------------------------- light

func _place_shafts() -> void:
	var openings: Array[Vector2] = []
	for rect in get_breach_rects():
		openings.append(Vector2(rect.get_center().x, rect.position.y + 10.0))
	for p in extra_shafts:
		openings.append(p)
	for i in openings.size():
		var top := openings[i]
		var shaft := LightShaft.new()
		shaft.name = "Shaft%d" % i
		# Alternate the lean so neighbouring beams don't look copied
		var lean := shaft_angle_deg * (1.0 if i % 2 == 0 else -0.7)
		shaft.angle_deg = lean
		shaft.length = maxf(floor_y - top.y, 80.0) / cos(deg_to_rad(lean))
		var opening_width := 60.0
		if i < breaches.size():
			opening_width = breaches[i].size.x * 64.0 * 0.55
		shaft.width_top = opening_width
		shaft.width_bottom = opening_width * 1.9
		shaft.color = shaft_color
		shaft.intensity = shaft_intensity
		shaft.light_energy = shaft_light_energy
		shaft.position = top
		shaft.z_index = 25
		shaft.z_as_relative = false
		add_child(shaft)
		shafts.append(shaft)
