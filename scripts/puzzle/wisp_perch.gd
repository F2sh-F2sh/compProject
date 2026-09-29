@tool
class_name WispPerch
extends Node2D

## A rune bracket where a Lantern Wisp can rest. Use it (interact) to call the
## wisp over. The prompt sits at `interact_offset`, on the floor below.

signal call_requested(perch: WispPerch)

@export var wisp: Node
@export var interact_offset := Vector2(0, 60):
	set(value):
		interact_offset = value
		queue_redraw()
## Extra places the wisp can be called from (relative offsets), e.g. from the
## far side of a bridge so the player can never be stranded.
@export var extra_call_offsets := PackedVector2Array()

var _interact: Interactable
var _call_spots: Array[Interactable] = []
var _glow: Node2D
var _time := 0.0


func _ready() -> void:
	_glow = Node2D.new()
	_glow.material = MagicLight.unshaded()
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	if Engine.is_editor_hint():
		return
	add_to_group("wisp_perch")
	var offsets := PackedVector2Array([interact_offset]) + extra_call_offsets
	for offset in offsets:
		var spot := Interactable.new()
		spot.verb = "Call Wisp"
		spot.size = Vector2(44, 64)
		spot.position = offset
		spot.prompt_offset = Vector2(0, -70)
		add_child(spot)
		spot.interacted.connect(func(_p): call_requested.emit(self))
		if _interact == null:
			_interact = spot
		_call_spots.append(spot)


func get_rest_position() -> Vector2:
	return global_position


func is_occupied() -> bool:
	return is_instance_valid(wisp) and wisp.current_perch == self and wisp.state == 0


func _process(delta: float) -> void:
	_time += delta
	_glow.queue_redraw()


func _draw() -> void:
	# Iron bracket arm and ring
	draw_line(Vector2(0, 10), Vector2(0, 16), Color("2b2838"), 3.0)
	draw_rect(Rect2(-6, 16, 12, 4), Color("231d38"))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 20, Color("2b2838"), 3.0)
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 20, Color("5b5773"), 1.0)
	if Engine.is_editor_hint():
		draw_dashed_line(Vector2.ZERO, interact_offset, Color(0.5, 0.8, 1.0, 0.5), 1.0, 4.0)
		for offset in extra_call_offsets:
			draw_dashed_line(Vector2.ZERO, offset, Color(0.5, 0.8, 1.0, 0.3), 1.0, 4.0)


func _draw_glow() -> void:
	var occupied := not Engine.is_editor_hint() and is_occupied()
	var c := Color(0.6, 0.85, 1.0, 0.9) if occupied else Color(0.45, 0.55, 0.9, 0.35 + 0.15 * sin(_time * 2.0))
	for i in 4:
		var a := i * TAU / 4.0 + PI / 4.0
		_glow.draw_rect(Rect2(Vector2.from_angle(a) * 10.0 - Vector2(1, 1), Vector2(2, 2)), c)
	# A matching rune stone marks each place the wisp can be called from
	if not Engine.is_editor_hint():
		for spot in _call_spots:
			var p := spot.position
			_glow.draw_rect(Rect2(p + Vector2(-6, -3), Vector2(12, 3)), Color(0.25, 0.22, 0.38))
			_glow.draw_rect(Rect2(p + Vector2(-2, -3), Vector2(4, 1)), c)
