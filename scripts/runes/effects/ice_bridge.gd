class_name IceBridge
extends StaticBody2D

## Ice Bridge: a span of solid ice growing sideways from the top edge of the
## cube's face, level with the cube's top (a cube set into the edge of a pit,
## flush with the floor, makes a bridge that continues the floor across it).
## It stops at the first wall. It is one-way from below, so it can never
## trap anyone who is under it as it forms. A timed bridge flickers for its
## last two seconds, then melts: its collision goes first, cleanly, and the
## ice fades after.

const THICKNESS := 14.0
const WARN_TIME := 2.0

var cube: RuneCube
var direction := 1.0
var span := 224.0
var length := 224.0
var duration := 0.0
var _left := 0.0
var _time := 0.0
var _shape: CollisionShape2D
var _melting := false


func setup(owner_cube: RuneCube, spell: Dictionary) -> void:
	cube = owner_cube
	direction = signf((spell["direction"] as Vector2).x)
	span = spell["span"]
	duration = spell["duration"] if spell["kind"] == RuneBook.Kind.TIMED else 0.0
	_left = duration
	top_level = true
	collision_layer = 3
	collision_mask = 0
	add_to_group("world")
	add_to_group("ice_bridge")
	var start := start_point(cube, direction)
	length = measure(cube, direction, span)
	global_position = start
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(length, THICKNESS)
	_shape.shape = rect
	_shape.position = Vector2(direction * length / 2.0, THICKNESS / 2.0)
	_shape.one_way_collision = true
	add_child(_shape)
	var art := Node2D.new()
	art.material = MagicLight.unshaded()
	art.draw.connect(_draw_ice.bind(art))
	art.name = "Art"
	add_child(art)
	z_index = 1
	Sfx.play("ice_form", start, -2.0)
	RuneJournal.note("bridge")


## The bridge's top starts at the top corner of the cube's face.
static func start_point(c: RuneCube, dir_x: float) -> Vector2:
	return c.global_position + Vector2(dir_x * RuneCube.SIZE / 2.0, -RuneCube.SIZE)


## How long it can grow before a wall stops it.
static func measure(c: RuneCube, dir_x: float, max_span: float) -> float:
	var from := start_point(c, dir_x) + Vector2(0, THICKNESS / 2.0)
	var dir := Vector2(dir_x, 0)
	return maxf(WindField.free_length(c.get_world_2d(), c.get_tree(), from, dir, max_span), 8.0)


func stop() -> void:
	if _melting:
		return
	_melting = true
	# Collision goes at once; the ice fades after
	_shape.set_deferred("disabled", true)
	Sfx.play("ice_crack", global_position + Vector2(direction * length / 2.0, 0), -3.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	_time += delta
	if duration > 0.0 and not _melting:
		_left -= delta
	get_node("Art").queue_redraw()


func _draw_ice(art: Node2D) -> void:
	var ice := Color(0.7, 0.9, 1.0)
	var a := 0.85
	if duration > 0.0 and _left < WARN_TIME and int(_time * 8.0) % 2 == 0:
		a = 0.4
	var x0 := 0.0 if direction > 0.0 else -length
	art.draw_rect(Rect2(x0, 0, length, THICKNESS), Color(0.45, 0.7, 0.95, a * 0.7))
	art.draw_rect(Rect2(x0, 0, length, 2), Color(ice, a))
	# Frost facets underneath
	var n := int(length / 16.0)
	for i in n:
		var x := x0 + i * 16.0 + 8.0
		art.draw_line(Vector2(x - 6, THICKNESS), Vector2(x, THICKNESS + 5), Color(ice, a * 0.6), 1.0)
		art.draw_line(Vector2(x, THICKNESS + 5), Vector2(x + 6, THICKNESS), Color(ice, a * 0.6), 1.0)
