class_name AimPreview
extends Node2D

## Where a sentence will go, shown in the room while its cube is being
## inscribed: a dotted path from the face it leaves by, in its direction, to
## the first wall it meets (or as far as it reaches), with a ring where it
## stops; for Self, a ring round the cube as wide as its reach. So aiming is
## never a blind guess, even at a target off the edge of the screen (the rune
## screen's "Where it goes" window frames this whole path).

## The light-blocking and solid layer the beam and the portal test against.
const SOLID_MASK := 2

var cube: RuneCube
## The path's ends, in the world (for the framing window).
var from := Vector2.ZERO
var to := Vector2.ZERO
var radius := 0.0
var color := Color(1.0, 0.85, 0.5)
var _time := 0.0


func _ready() -> void:
	z_index = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat


## Works out the path for the cube's sentence as it stands now.
func refresh() -> void:
	if not is_instance_valid(cube):
		return
	var r := cube.recipe
	var look := RuneFragments.combo_glow(r)
	color = look["accent"]
	var s := RuneBook.spell(r)
	var dir: Vector2 = s.get("direction", Vector2.ZERO)
	var reach: float = s.get("range", s.get("reach", s.get("span", 0.0)))
	if s["key"] == "fire/projectile":
		reach = 900.0
	if r.direction == &"" or r.form == &"":
		from = cube.centre()
		to = from
		radius = 0.0
	elif dir == Vector2.ZERO:
		from = cube.centre()
		to = from
		radius = maxf(float(s.get("radius", s.get("width", 48.0))), 32.0)
	else:
		radius = 0.0
		dir = dir.normalized()
		from = cube.get_face_point(dir)
		var end := from + dir * maxf(reach, 120.0)
		var query := PhysicsRayQueryParameters2D.create(from, end, SOLID_MASK)
		if cube.body:
			query.exclude = [cube.body.get_rid()]
		var hit := cube.get_world_2d().direct_space_state.intersect_ray(query)
		to = hit["position"] if not hit.is_empty() else end
	global_position = Vector2.ZERO
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if not is_instance_valid(cube):
		return
	if radius > 0.0:
		var n := 40
		for i in n:
			if (i + int(_time * 6.0)) % 2 == 0:
				var a := i * TAU / n
				draw_arc(from, radius, a, a + TAU / n * 0.6, 4, Color(color, 0.85), 2.0)
		return
	var length := from.distance_to(to)
	if length < 4.0:
		return
	var dir := (to - from) / length
	var step := 10.0
	var offset := fposmod(_time * 30.0, step)
	var d := offset
	while d < length:
		draw_circle(from + dir * d, 2.0, Color(color, 0.9))
		d += step
	# where it stops: a ring and a small cross
	draw_arc(to, 9.0 + sin(_time * 4.0) * 1.5, 0.0, TAU, 24, Color(color, 0.95), 2.0)
	draw_line(to + Vector2(-4, 0), to + Vector2(4, 0), Color(color, 0.9), 1.0)
	draw_line(to + Vector2(0, -4), to + Vector2(0, 4), Color(color, 0.9), 1.0)
