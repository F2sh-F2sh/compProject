@tool
class_name RuneLectern
extends Node2D

## A lectern joined by a carved groove to a cube out of reach (on a pillar
## in a pit, high on a wall). Using it opens that cube's assembly screen, as
## if she stood at the cube. The groove glows in the cube's essence colour
## while the cube is on. The node's origin is its foot.

@export var cube: RuneCube:
	set(value):
		cube = value
		queue_redraw()

var interactable: Interactable
var _time := 0.0
var _groove: Node2D


func _ready() -> void:
	_groove = Node2D.new()
	_groove.material = MagicLight.unshaded()
	_groove.z_index = -1
	_groove.draw.connect(_draw_groove)
	add_child(_groove)
	if Engine.is_editor_hint():
		return
	interactable = Interactable.new()
	interactable.verb = "Inscribe"
	interactable.size = Vector2(52, 60)
	interactable.prompt_offset = Vector2(0, -66)
	interactable.echo_can_use = false
	add_child(interactable)
	interactable.interacted.connect(func(_by):
		if cube and cube.manager and cube.manager.assembly:
			cube.manager.assembly.open(cube))


func _process(delta: float) -> void:
	_time += delta
	_groove.queue_redraw()


func _draw() -> void:
	# A slanted reading desk on a post
	draw_rect(Rect2(-3, -30, 6, 30), Color("2a2438"))
	draw_rect(Rect2(-10, -3, 20, 3), Color("241e38"))
	var desk := PackedVector2Array([Vector2(-14, -30), Vector2(14, -38), Vector2(14, -34), Vector2(-14, -26)])
	draw_colored_polygon(desk, Color("3d3556"))
	draw_polyline(desk + PackedVector2Array([desk[0]]), Color("1a1528"), 1.0)


func _draw_groove() -> void:
	if cube == null or not is_instance_valid(cube):
		return
	var on := not Engine.is_editor_hint() and cube.is_active
	var col := RuneFragments.essence_color(cube.recipe.essence) if on else Color(0.45, 0.38, 0.62)
	col.a = 0.55 + 0.3 * sin(_time * 4.0) if on else 0.4
	# Along the floor from the lectern, then up (or down) to the cube
	var a := Vector2(10, -1)
	var target := to_local(cube.global_position) + Vector2(0, -2)
	var mid := Vector2(target.x, a.y)
	_groove.draw_line(a, mid, col, 1.0)
	_groove.draw_line(mid, target, col, 1.0)
	RuneFragments.draw_glyph(_groove, cube.recipe.essence, Vector2(0, -32), 10.0, Color(col, col.a + 0.2), 1.0)
