class_name WindField
extends Node2D

## A sustained current (Wind Push or Lift) coming off a cube's face. Its
## region is a rectangle `reach` long and `width` wide along `direction`,
## cut short at the first solid wall along its centre line, so the visible
## streaks and the real effect always cover the same ground. For any object,
## contribution_for() gives this field's share of the force (direction *
## force) if the object overlaps the region and the wind can reach it
## (a wall in between blocks it; iron grates let wind through). The
## RuneManager adds up every field's share per object, once per field per
## object per physics frame. The static helpers are shared with other
## region spells (gusts, chills).

const STREAKS := 14

var direction := Vector2.RIGHT
var force := 1200.0
var reach := 320.0
var width := 96.0
## How far the current actually gets before a wall (<= reach).
var free_reach := 320.0
var cube: Node2D
var _time := 0.0
var _seeds: Array[float] = []


func setup(owner_cube: Node2D, spell: Dictionary) -> void:
	cube = owner_cube
	direction = (spell["direction"] as Vector2).normalized()
	force = spell["force"]
	reach = spell["reach"]
	width = spell["width"]
	free_reach = reach
	material = MagicLight.unshaded()
	z_index = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(owner_cube.get_path())
	for i in STREAKS * 2:
		_seeds.append(rng.randf())


## Where the current starts: the middle of the cube's face.
func origin() -> Vector2:
	return cube.get_face_point(direction)


func _physics_process(delta: float) -> void:
	_time += delta
	free_reach = free_length(get_world_2d(), get_tree(), origin(), direction, reach)
	queue_redraw()


## The region in world space as (origin, along, across, length, width).
func region() -> Dictionary:
	return {"origin": origin(), "along": direction, "across": direction.orthogonal(), "length": free_reach, "width": width}


## This field's force on `body` this frame, given its world bounds.
func contribution_for(body: Node2D, bounds: Rect2) -> Vector2:
	var o := origin()
	if not overlaps(o, direction, free_reach, width, bounds):
		return Vector2.ZERO
	if not reaches(get_world_2d(), get_tree(), o, direction, width, body, bounds):
		return Vector2.ZERO
	return direction * force


func is_obstructed() -> bool:
	return free_reach < reach * 0.4


# ---------------------------------------------------------------- geometry

## How far from `from` along `dir` before the first wall (grates, loose
## objects and cubes don't count), at most `length`.
static func free_length(world: World2D, tree: SceneTree, from: Vector2, dir: Vector2, length: float) -> float:
	var space := world.direct_space_state
	var exclude: Array[RID] = RuneManager.wind_ray_exclusions(tree)
	for i in 6:
		var query := PhysicsRayQueryParameters2D.create(from, from + dir * length, 2, exclude)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return length
		var collider = hit["collider"]
		if collider is Node and collider.is_in_group("wind_permeable"):
			exclude.append(hit["rid"])
			continue
		return from.distance_to(hit["position"])
	return length


## Does a box overlap the rectangle `length` x `width` from `o` along `dir`?
static func overlaps(o: Vector2, dir: Vector2, length: float, width: float, bounds: Rect2) -> bool:
	var across := dir.orthogonal()
	var min_a := INF
	var max_a := -INF
	var min_c := INF
	var max_c := -INF
	for corner in [bounds.position, bounds.position + Vector2(bounds.size.x, 0), bounds.end, bounds.position + Vector2(0, bounds.size.y)]:
		var d: Vector2 = corner - o
		var a := d.dot(dir)
		var c := d.dot(across)
		min_a = minf(min_a, a)
		max_a = maxf(max_a, a)
		min_c = minf(min_c, c)
		max_c = maxf(max_c, c)
	return max_a > 0.0 and min_a < length and max_c > -width / 2.0 and min_c < width / 2.0


## True if any of three lines from the face to the box is clear of walls.
static func reaches(world: World2D, tree: SceneTree, o: Vector2, dir: Vector2, width: float, body: Node2D, bounds: Rect2) -> bool:
	var space := world.direct_space_state
	var exclude: Array[RID] = RuneManager.wind_ray_exclusions(tree)
	if body is CollisionObject2D:
		exclude.append(body.get_rid())
	var across := dir.orthogonal()
	var centre := bounds.get_center()
	var spread := minf(width, absf(bounds.size.dot(across.abs()))) * 0.35
	for offset in [0.0, spread, -spread]:
		var target: Vector2 = centre + across * offset
		var query := PhysicsRayQueryParameters2D.create(o + across * clampf(offset, -width / 2.0, width / 2.0), target, 2, exclude)
		var blocked := false
		for i in 4:
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				break
			if hit["collider"] is Node and hit["collider"].is_in_group("wind_permeable"):
				query.exclude = query.exclude + [hit["rid"]]
				continue
			blocked = true
			break
		if not blocked:
			return true
	return false


## A dashed rectangle outline, for regions.
static func draw_dashed_rect(canvas: CanvasItem, o: Vector2, dir: Vector2, length: float, width: float, col: Color) -> void:
	var across := dir.orthogonal()
	var h := width / 2.0
	var corners := [o - across * h, o - across * h + dir * length, o + across * h + dir * length, o + across * h]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		var n := maxi(int(a.distance_to(b) / 8.0), 1)
		for k in n:
			if k % 2 == 0:
				canvas.draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), col, 1.0)
	canvas.draw_colored_polygon(PackedVector2Array(corners), Color(col, col.a * 0.12))


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	# Thin, cool, directional currents inside exactly the working region
	var o := to_local(origin())
	var across := direction.orthogonal()
	var col: Color = RuneFragments.ESSENCE_COLORS[&"wind"]
	var speed := 150.0 + force * 0.06
	for i in STREAKS:
		var lane: float = (_seeds[i] - 0.5) * width * 0.9
		var cycle := free_reach + 40.0
		var t := fposmod(_time * speed + _seeds[i + STREAKS] * cycle, cycle)
		var head := minf(t, free_reach)
		var tail := maxf(t - 28.0 - _seeds[i] * 16.0, 0.0)
		if head <= tail:
			continue
		var fade := 1.0 - smoothstep(free_reach * 0.8, free_reach, head)
		var a := o + direction * tail + across * lane
		var b := o + direction * head + across * lane
		draw_line(a, b, Color(col, 0.62 * fade), 1.5)
		draw_line(a + across, b - direction * 6.0 + across, Color(col, 0.2 * fade), 1.0)
	# The marked area: exactly where the wind works
	draw_dashed_rect(self, o, direction, free_reach, width, Color(col, 0.45))
