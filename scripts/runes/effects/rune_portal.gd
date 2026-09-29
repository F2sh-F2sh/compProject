class_name RunePortal
extends Node2D

## Space Portal: a doorway just beyond the cube's face, and its far side
## `range` px further in the same direction, through walls and gates. The
## player, loose objects and creatures that step into the doorway come out
## of the far side moving exactly as they were. One way only; each body has
## a short cooldown so it can't bounce back and forth. The far side is
## checked when the rune is switched on: it must be open space inside the
## room and not on a hazard, or the rune refuses to start (see problem()).

const DOOR_SIZE := Vector2(26, 44)
const COOLDOWN := 0.7

var cube: RuneCube
var direction := Vector2.RIGHT
var entrance := Vector2.ZERO
var exit_point := Vector2.ZERO
var _door: Area2D
var _cooldowns := {}
var _time := 0.0
## Bodies carried through (for tests).
var carried: Array[Node] = []


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
	if c.home_room and not c.home_room.bounds.has_point(far):
		return "The far side of the portal would open outside this room."
	var rect := Rect2(far - DOOR_SIZE / 2.0, DOOR_SIZE)
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
	_door = Area2D.new()
	_door.collision_layer = 0
	# The player and loose objects (layer 1)
	_door.collision_mask = 1
	_door.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = DOOR_SIZE
	shape.shape = rect
	_door.add_child(shape)
	add_child(_door)
	_door.global_position = entrance
	Sfx.play("portal_open", entrance, -3.0)


func stop() -> void:
	Sfx.play("portal_close", entrance, -6.0)
	queue_free()


func _physics_process(delta: float) -> void:
	_time += delta
	for body in _cooldowns.keys():
		_cooldowns[body] -= delta
		if _cooldowns[body] <= 0.0 or not is_instance_valid(body):
			_cooldowns.erase(body)
	for body in _door.get_overlapping_bodies():
		if _cooldowns.has(body) or not body is CharacterBody2D:
			continue
		if body.get("is_dead") == true or body.get("controls_locked") == true:
			continue
		_carry(body)
	queue_redraw()


func _carry(body: CharacterBody2D) -> void:
	# Same place relative to the door, same velocity
	body.global_position += exit_point - entrance
	body.reset_physics_interpolation()
	_cooldowns[body] = COOLDOWN
	carried.append(body)
	Sfx.play("portal_warp", exit_point, -2.0)
	RuneJournal.note("portal")
	ImpactFX.burst(get_parent(), exit_point, RuneFragments.ESSENCE_COLORS[&"space"], false, 10)


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
