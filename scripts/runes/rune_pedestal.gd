@tool
class_name RunePedestal
extends Node2D

## A socket set into the floor, fed by the dungeon: whatever cube stands in
## it runs without costing the player any mana. A cube set down near one
## drops into it. It glows while its cube is on. The node's origin is the
## floor surface at its centre; it has no collision (cubes sit flush).

## How far from its centre a cube still drops into it.
const SNAP := 22.0

var _time := 0.0
## 1 while a cube stands in it, else 0 (for objective steps).
var occupied := 0


func _ready() -> void:
	material = MagicLight.unshaded()
	z_index = -1
	if not Engine.is_editor_hint():
		add_to_group("rune_pedestal")


## True if a cube standing at `foot` is in this socket.
func holds(foot: Vector2) -> bool:
	return absf(foot.x - global_position.x) <= 1.0 and absf(foot.y - global_position.y) <= 2.0


## Where a cube set down at `foot` should go (the socket, if close enough).
func snap(foot: Vector2) -> Vector2:
	if absf(foot.x - global_position.x) <= SNAP and absf(foot.y - global_position.y) <= 6.0:
		return global_position
	return foot


func occupant() -> Node:
	for cube in get_tree().get_nodes_in_group("rune_cube"):
		if cube.pedestal == self:
			return cube
	return null


func _process(delta: float) -> void:
	_time += delta
	if not Engine.is_editor_hint():
		occupied = 1 if occupant() != null else 0
	queue_redraw()


func _draw() -> void:
	var cube := occupant() if not Engine.is_editor_hint() else null
	var on: bool = cube != null and cube.is_active
	var pulse := 0.5 + 0.5 * sin(_time * 3.0)
	var glow := Color(0.62, 0.5, 1.0, 0.9 if on else 0.35 + 0.25 * pulse)
	# A stone collar round the socket and the dungeon's channel feeding it
	draw_rect(Rect2(-24, -3, 48, 3), Color("2c2544"))
	draw_rect(Rect2(-24, -3, 48, 1), Color("4c4468"))
	draw_rect(Rect2(-18, -2, 36, 2), glow)
	for x in [-30, 30]:
		draw_line(Vector2(x * 0.8, -1), Vector2(x * 1.6, -1), Color(glow, glow.a * 0.5), 1.0)
	if cube == null:
		# An empty socket shows a faint cube outline: "a cube goes here"
		draw_rect(Rect2(-16, -32, 32, 32), Color(glow, 0.25 * pulse), false, 1.0)
