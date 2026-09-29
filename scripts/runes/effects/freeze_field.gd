class_name FreezeField
extends Node2D

## Ice Freeze: a chill over a marked area (a rectangle along the direction,
## or a circle round the cube for Self). Every creature in it that the cold
## can reach (walls block it) is frozen solid (see Chill) while it stays
## inside and for a moment after. A timed rune lasts FREEZE_TIME; Persist
## holds the area as long as the cube is on.

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
		free_reach = WindField.free_length(world, tree, o, direction, reach)
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
	queue_redraw()


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
