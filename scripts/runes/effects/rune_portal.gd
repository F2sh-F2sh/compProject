class_name RunePortal
extends Node2D

## Space Portal: a doorway just beyond the cube's face, and its far side
## `range` px further in the same direction, through walls and gates. The
## player, loose objects and creatures that step into either side come out
## of the other moving exactly as they were: it works both ways. Something
## that has just come out of a side has to step clear of it before that side
## will take it back, so nothing bounces to and fro. The far side is checked
## when the rune is switched on: it must be open space inside the room and
## not on a hazard, or the rune refuses to start (see problem()).

const DOOR_SIZE := Vector2(26, 44)
## How long a body that has just come through is held to the side it came out of.
const SETTLE := 0.3

var cube: RuneCube
var direction := Vector2.RIGHT
var entrance := Vector2.ZERO
var exit_point := Vector2.ZERO
var _door: Area2D
var _far_door: Area2D
## body -> the door it came out of (it can't use that one until it leaves it).
var _arrived := {}
var _time := 0.0
## Bodies carried through, either way (for tests).
var carried: Array[Node] = []
## Bodies carried back from the far side (for tests).
var carried_back: Array[Node] = []


static func door_centre(c: RuneCube, dir: Vector2) -> Vector2:
	return c.get_face_point(dir) + dir * (DOOR_SIZE.y / 2.0 + 2.0 if absf(dir.y) > 0.5 and absf(dir.x) < 0.5 else DOOR_SIZE.x / 2.0 + 2.0)


static func far_centre(c: RuneCube, spell: Dictionary) -> Vector2:
	var dir: Vector2 = (spell["direction"] as Vector2).normalized()
	return door_centre(c, dir) + dir * float(spell["range"])


## "" if the far side is usable, otherwise why not.
static func problem(c: RuneCube, spell: Dictionary) -> String:
	var far := far_centre(c, spell)
	var space := c.get_world_2d().direct_space_state
	var box := RectangleShape2D.new()
	box.size = DOOR_SIZE
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = box
	query.transform = Transform2D(0.0, far)
	query.collision_mask = 2
	query.exclude = RuneManager.wind_ray_exclusions(c.get_tree())
	if not space.intersect_shape(query, 1).is_empty():
		return "The far side of the portal would open inside solid stone."
	var rect := Rect2(far - DOOR_SIZE / 2.0, DOOR_SIZE)
	if c.home_room and not c.home_room.bounds.encloses(rect):
		return "The far side of the portal would open outside this room."
	for hazard in c.get_tree().get_nodes_in_group("hazard_zone"):
		if hazard.has_method("get_hazard_rect") and hazard.get_hazard_rect().intersects(rect):
			return "The far side of the portal would open over a hazard."
	return ""


func setup(owner_cube: RuneCube, spell: Dictionary) -> void:
	cube = owner_cube
	direction = (spell["direction"] as Vector2).normalized()
	entrance = door_centre(cube, direction)
	exit_point = far_centre(cube, spell)
	top_level = true
	global_transform = Transform2D.IDENTITY
	material = MagicLight.unshaded()
	z_index = 3
	_door = _make_door(entrance)
	_far_door = _make_door(exit_point)
	Sfx.play("portal_open", entrance, -3.0)


## One side of the portal: an area that notices the player and loose objects.
func _make_door(at: Vector2) -> Area2D:
	var door := Area2D.new()
	door.collision_layer = 0
	# The player and loose objects (layer 1)
	door.collision_mask = 1
	door.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = DOOR_SIZE
	shape.shape = rect
	door.add_child(shape)
	add_child(door)
	door.global_position = at
	return door


func stop() -> void:
	Sfx.play("portal_close", entrance, -6.0)
	queue_free()


func _physics_process(delta: float) -> void:
	_time += delta
	# Something that came out of a side may use it again once it has left it
	# (after a moment, so the areas have caught up with where it is now)
	for body in _arrived.keys():
		_arrived[body][1] += delta
		if not is_instance_valid(body):
			_arrived.erase(body)
		elif _arrived[body][1] > SETTLE and not _really_in(body, _arrived[body][0]):
			_arrived.erase(body)
	for pair in [[_door, _far_door], [_far_door, _door]]:
		var from: Area2D = pair[0]
		for body in from.get_overlapping_bodies():
			# (an area can still list a body for a frame after it was carried away)
			if not body is CharacterBody2D or not _really_in(body, from):
				continue
			# Just through: neither side takes it again for a moment, and the
			# side it came out of not until it has stepped clear of it
			if _arrived.has(body) and (_arrived[body][0] == from or _arrived[body][1] < SETTLE):
				continue
			if body.get("is_dead") == true or body.get("controls_locked") == true:
				continue
			_carry(body, from, pair[1])
	queue_redraw()


## Whether a body is in a side now, by where it really is.
func _really_in(body: Node2D, door: Area2D) -> bool:
	return RuneManager.bounds_of(body).intersects(Rect2(door.global_position - DOOR_SIZE / 2.0, DOOR_SIZE))


func _carry(body: CharacterBody2D, from: Area2D = null, to: Area2D = null) -> void:
	if from == null:
		from = _door
	if to == null:
		to = _far_door
	# Gates and moving bodies can block an exit after activation. Check the
	# traveller's full box at its translated position, including entry offset.
	var destination := RuneManager.bounds_of(body)
	destination.position += to.global_position - from.global_position
	if cube.home_room and not cube.home_room.bounds.encloses(destination):
		return
	var box := RectangleShape2D.new()
	box.size = destination.size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = box
	query.transform = Transform2D(0.0, destination.get_center())
	query.collision_mask = 2
	query.exclude = [body.get_rid()]
	if not body.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
		return
	for hazard in get_tree().get_nodes_in_group("hazard_zone"):
		if hazard.has_method("get_hazard_rect") and hazard.get_hazard_rect().intersects(destination):
			return
	# Same place relative to the door, same velocity
	body.global_position += to.global_position - from.global_position
	body.reset_physics_interpolation()
	_arrived[body] = [to, 0.0]
	carried.append(body)
	if from == _far_door:
		carried_back.append(body)
	Sfx.play("portal_warp", to.global_position, -2.0)
	RuneJournal.note("portal")
	ImpactFX.burst(get_parent(), to.global_position, RuneFragments.ESSENCE_COLORS[&"space"], false, 10)


func _draw() -> void:
	var col: Color = RuneFragments.ESSENCE_COLORS[&"space"]
	for p in [entrance, exit_point]:
		var r := DOOR_SIZE / 2.0
		for i in 3:
			var k := fposmod(_time * 0.8 + i / 3.0, 1.0)
			var pts := PackedVector2Array()
			for s in 25:
				var a := s / 24.0 * TAU + _time * (2.0 if p == entrance else -2.0)
				pts.append(p + Vector2(cos(a) * r.x, sin(a) * r.y) * (0.35 + 0.65 * k))
			draw_polyline(pts, Color(col, 0.7 * (1.0 - k)), 1.5)
		draw_colored_polygon(_ellipse(p, r * 0.9), Color(col, 0.12))
	# A faint thread between the two sides
	var n := int(entrance.distance_to(exit_point) / 10.0)
	for i in n:
		if i % 2 == 0:
			draw_line(entrance.lerp(exit_point, float(i) / n), entrance.lerp(exit_point, float(i + 1) / n), Color(col, 0.18), 1.0)


static func _ellipse(c: Vector2, r: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for s in 20:
		var a := s / 20.0 * TAU
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts
