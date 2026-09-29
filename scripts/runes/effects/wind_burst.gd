class_name WindBurst
extends Node2D

## A single gust (Wind Burst): one shove to every loose object and creature
## in its region when it fires, then a short visible puff. Aimed bursts use
## the same rectangle rules as a wind current; a Self burst shoves outward
## from the cube in every direction, within `reach * 0.6`.

const LIFE := 0.45

var cube: RuneCube
var direction := Vector2.ZERO
var impulse := 420.0
var reach := 256.0
var width := 96.0
var free_reach := 256.0
var _t := 0.0
## Bodies shoved and the push each got (for tests and the debug view).
var shoved := {}


func setup(owner_cube: RuneCube, spell: Dictionary) -> void:
	cube = owner_cube
	direction = (spell["direction"] as Vector2).normalized()
	impulse = spell["impulse"]
	reach = spell["reach"]
	width = spell["width"]
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_index = 3
	material = MagicLight.unshaded()
	_fire()


func _fire() -> void:
	var world := cube.get_world_2d()
	var tree := cube.get_tree()
	var centre := cube.centre()
	var o := cube.get_face_point(direction)
	if direction != Vector2.ZERO:
		free_reach = WindField.free_length(world, tree, o, direction, reach)
	for body in tree.get_nodes_in_group("wind_receiver"):
		var receiver: Node = body if body.has_method("apply_wind_impulse") else body.get_node_or_null("PlayerWind")
		if receiver == null or not body is Node2D:
			continue
		var box := RuneManager.bounds_of(body)
		var push := Vector2.ZERO
		if direction == Vector2.ZERO:
			var d := box.get_center() - centre
			if d.length() > reach * 0.6 or d.length() < 1.0:
				continue
			if not WindField.reaches(world, tree, centre, d.normalized(), 8.0, body, box):
				continue
			push = d.normalized() * impulse
		else:
			if not WindField.overlaps(o, direction, free_reach, width, box):
				continue
			if not WindField.reaches(world, tree, o, direction, width, body, box):
				continue
			push = direction * impulse
		receiver.apply_wind_impulse(push)
		shoved[body] = push
	Sfx.play("wind_gust", centre, -3.0)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= LIFE:
		queue_free()


func _draw() -> void:
	if cube == null or not is_instance_valid(cube):
		return
	var col: Color = RuneFragments.ESSENCE_COLORS[&"wind"]
	var k := _t / LIFE
	var alpha := (1.0 - k) * 0.8
	if direction == Vector2.ZERO:
		var c := cube.centre()
		for i in 3:
			draw_arc(c, reach * 0.6 * clampf(k + i * 0.12, 0.0, 1.0), 0.0, TAU, 40, Color(col, alpha * (1.0 - i * 0.25)), 1.5)
		return
	var o := cube.get_face_point(direction)
	var across := direction.orthogonal()
	# A few bright arcs rushing out along the region
	for i in 4:
		var d := free_reach * clampf(k * 1.3 - i * 0.12, 0.0, 1.0)
		var p := o + direction * d
		draw_line(p - across * width * 0.45, p + across * width * 0.45, Color(col, alpha * (1.0 - i * 0.2)), 2.0)


## One-off effects play out by themselves; switching the cube off leaves them be.
func stop() -> void:
	pass
