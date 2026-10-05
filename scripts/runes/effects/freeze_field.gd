class_name FreezeField
extends Node2D

## Ice Freeze: a chill over a marked area (a rectangle along the direction,
## or a circle round the cube for Self). Every creature in it that the cold
## can reach (walls block it) is frozen solid (see Chill) while it stays
## inside and for a moment after. Water freezes too: anything in the group
## "freezable" (the Cistern's pools, fountains and tide clock) is asked each
## frame through chill_from(field), and checks its own shape with covers().
## Ice never blocks the cold. A timed rune lasts FREEZE_TIME; Persist holds
## the area as long as the cube is on.

var cube: RuneCube
var direction := Vector2.ZERO
var reach := 160.0
var width := 96.0
var free_reach := 160.0
var frozen: Array[Node] = []
var _time := 0.0
var _flakes: Array[Vector3] = []


func setup(owner_cube: RuneCube, spell: Dictionary) -> void:
	cube = owner_cube
	direction = (spell["direction"] as Vector2).normalized()
	reach = spell["reach"]
	width = spell["width"]
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_index = 3
	material = MagicLight.unshaded()
	add_to_group("freeze_field")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(cube.get_path())
	for i in 18:
		_flakes.append(Vector3(rng.randf(), rng.randf(), rng.randf()))
	Sfx.play("ice_form", cube.centre(), -4.0)


func _physics_process(delta: float) -> void:
	_time += delta
	var world := cube.get_world_2d()
	var tree := cube.get_tree()
	var o := cube.get_face_point(direction)
	if direction != Vector2.ZERO:
		free_reach = _free_length(world, o, direction, reach)
	frozen.clear()
	for creature in tree.get_nodes_in_group("enemy") + tree.get_nodes_in_group("gargoyle"):
		if not creature is CharacterBody2D or creature.get("is_dead") == true:
			continue
		var box := RuneManager.bounds_of(creature)
		var inside := false
		if direction == Vector2.ZERO:
			var d := box.get_center() - cube.centre()
			inside = d.length() <= reach and MagicLight.line_is_clear(world, cube.centre(), box.get_center(), [creature.get_rid()])
		else:
			inside = WindField.overlaps(o, direction, free_reach, width, box) \
				and WindField.reaches(world, tree, o, direction, width, creature, box)
		if inside:
			Chill.apply(creature, 0.6)
			frozen.append(creature)
	for thing in tree.get_nodes_in_group("freezable"):
		if thing.has_method("chill_from"):
			thing.chill_from(self)
	queue_redraw()


## Whether the cold reaches into `rect` (world space): it overlaps the marked
## area and a line from the cube to it is clear of walls (ice, grates, cubes
## and loose objects don't count; nor does `own`, the thing asking).
func covers(rect: Rect2, own: Array[RID] = [], step := 10.0) -> bool:
	if cube == null or not is_instance_valid(cube):
		return false
	var world := cube.get_world_2d()
	var exclude: Array[RID] = _ray_exclusions()
	exclude.append_array(own)
	if direction == Vector2.ZERO:
		var c := cube.centre()
		var nearest := Vector2(clampf(c.x, rect.position.x, rect.end.x), clampf(c.y, rect.position.y, rect.end.y))
		if nearest.distance_to(c) > reach:
			return false
		return _clear(world, c, nearest, exclude)
	var o := cube.get_face_point(direction)
	if not WindField.overlaps(o, direction, free_reach, width, rect):
		return false
	# Points of the rect (a grid: its edges and middle, every few px down and
	# across) that lie inside the area; the cold reaches it if any of them can
	# be reached in a straight line from the cube's face
	var across := direction.orthogonal()
	var xs := _steps(rect.position.x, rect.end.x, step)
	var ys := _steps(rect.position.y, rect.end.y, step)
	for y in ys:
		for x in xs:
			var p := Vector2(x, y)
			var d := p - o
			var a := d.dot(direction)
			var c := d.dot(across)
			if a < 0.0 or a > free_reach or absf(c) > width / 2.0:
				continue
			if _clear(world, o + across * c, p, exclude):
				return true
	return false


## Evenly spaced values from a to b (both included), no more than `step` apart.
static func _steps(a: float, b: float, step: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var n := maxi(int(ceil((b - a) / step)), 1)
	for i in n + 1:
		out.append(lerpf(a, b, float(i) / n))
	return out


func _ray_exclusions() -> Array[RID]:
	var out: Array[RID] = RuneManager.wind_ray_exclusions(cube.get_tree())
	for node in cube.get_tree().get_nodes_in_group("ice"):
		if node is CollisionObject2D:
			out.append(node.get_rid())
	return out


func _clear(world: World2D, from: Vector2, to: Vector2, exclude: Array[RID]) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 2, exclude)
	for i in 6:
		var hit := world.direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return true
		if hit["collider"] is Node and hit["collider"].is_in_group("wind_permeable"):
			query.exclude = query.exclude + [hit["rid"]]
			continue
		return false
	return true


## How far the cold gets before a wall (ice and grates don't stop it).
func _free_length(world: World2D, from: Vector2, dir: Vector2, length: float) -> float:
	var exclude := _ray_exclusions()
	var query := PhysicsRayQueryParameters2D.create(from, from + dir * length, 2, exclude)
	for i in 6:
		var hit := world.direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return length
		if hit["collider"] is Node and hit["collider"].is_in_group("wind_permeable"):
			query.exclude = query.exclude + [hit["rid"]]
			continue
		return from.distance_to(hit["position"])
	return length


func region() -> Dictionary:
	if direction == Vector2.ZERO:
		return {}
	return {"origin": cube.get_face_point(direction), "along": direction, "across": direction.orthogonal(), "length": free_reach, "width": width}


func _draw() -> void:
	var col: Color = RuneFragments.ESSENCE_COLORS[&"ice"]
	if direction == Vector2.ZERO:
		var c := cube.centre()
		draw_arc(c, reach, 0.0, TAU, 48, Color(col, 0.45), 1.0)
		draw_circle(c, reach, Color(col, 0.05))
		for f in _flakes:
			var a: float = f.x * TAU + _time * 0.3
			var r: float = f.y * reach
			draw_circle(c + Vector2(cos(a), sin(a)) * r, 1.2, Color(1, 1, 1, 0.5 + 0.4 * sin(_time * 3.0 + f.z * 6.0)))
		return
	var o := cube.get_face_point(direction)
	WindField.draw_dashed_rect(self, o, direction, free_reach, width, Color(col, 0.5))
	var across := direction.orthogonal()
	# Slow drifting snow inside the area
	for f in _flakes:
		var along: float = fposmod(f.x * free_reach + _time * 14.0 * (0.5 + f.z), free_reach)
		var side: float = (f.y - 0.5) * width * 0.9
		draw_circle(o + direction * along + across * side, 1.2, Color(1, 1, 1, 0.55))
