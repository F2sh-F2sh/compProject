@tool
class_name Mirror
extends Node2D

## A one-sided mirror on a stone post. It faces one of four diagonals; a beam
## hitting the silvered face turns 90 degrees, a beam hitting the dark back is
## blocked. Rotate it with the interact key (four clear steps, no aiming).
## The node sits at beam height; the post reaches down `post_length` to the floor.

enum Facing { NORTH_EAST, SOUTH_EAST, SOUTH_WEST, NORTH_WEST }

@export var facing: Facing = Facing.NORTH_EAST:
	set(value):
		facing = value
		_shown_angle = _facing_angle(value)
		queue_redraw()
@export var rotatable := true
@export var post_length := 36.0:
	set(value):
		post_length = value
		queue_redraw()
## Hang from a rod going up instead of standing on a post.
@export var hanging := false:
	set(value):
		hanging = value
		queue_redraw()
## Where the player rotates it from, relative to the mirror. Zero means at
## the foot of its post.
@export var interact_offset := Vector2.ZERO

var _start_facing: Facing
var _shown_angle := 0.0
var _interact: Interactable
var _face_glow: Node2D


func _ready() -> void:
	_start_facing = facing
	_shown_angle = _facing_angle(facing)
	_face_glow = Node2D.new()
	_face_glow.material = MagicLight.unshaded()
	_face_glow.draw.connect(_draw_face)
	add_child(_face_glow)
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	MagicLight.add_sensor(self, 9.0)
	if rotatable:
		_interact = Interactable.new()
		_interact.verb = "Rotate"
		_interact.size = Vector2(40, 56)
		_interact.position = interact_offset if interact_offset != Vector2.ZERO else Vector2(0, post_length)
		_interact.prompt_offset = Vector2(0, -64)
		add_child(_interact)
		_interact.interacted.connect(func(_p): rotate_step())


func face_normal() -> Vector2:
	match facing:
		Facing.NORTH_EAST: return Vector2(1, -1).normalized()
		Facing.SOUTH_EAST: return Vector2(1, 1).normalized()
		Facing.SOUTH_WEST: return Vector2(-1, 1).normalized()
		_: return Vector2(-1, -1).normalized()


## Direction a beam leaves in, or ZERO if it struck the back.
func reflect_beam(incoming: Vector2) -> Vector2:
	var n := face_normal()
	if incoming.dot(n) >= -0.01:
		return Vector2.ZERO
	var out := incoming - 2.0 * incoming.dot(n) * n
	return Vector2(roundf(out.x), roundf(out.y)).normalized()


func rotate_step() -> void:
	facing = ((facing + 1) % 4) as Facing
	Sfx.play("mirror_rotate", global_position)
	# Turned from a distant wheel: let the camera show the mirror turning
	if interact_offset.length() > 200.0:
		var root := get_tree().get_first_node_in_group("chapter_root")
		if root:
			root.show_mechanism(global_position, 0.7)
	# Animate the visible face turning; the logic changes instantly
	var from := _shown_angle - PI / 2.0
	var to := _facing_angle(facing)
	var tween := create_tween()
	tween.tween_method(func(a): _shown_angle = a; queue_redraw(); _face_glow.queue_redraw(), from, to, 0.18)


func reset_state() -> void:
	facing = _start_facing


func _facing_angle(f: Facing) -> float:
	return [-PI / 4.0, PI / 4.0, 3.0 * PI / 4.0, -3.0 * PI / 4.0][f]


func _draw() -> void:
	if hanging:
		# Iron rod up to the ceiling
		draw_rect(Rect2(-2, -post_length, 4, post_length - 8.0), Color("2b2838"))
		draw_rect(Rect2(-1, -post_length, 1, post_length - 8.0), Color("5b5773"))
		draw_rect(Rect2(-7, -post_length, 14, 4), Color("231d38"))
	else:
		# Stone post
		draw_rect(Rect2(-3, 8, 6, post_length - 8.0), Color("2b2442"))
		draw_rect(Rect2(-3, 8, 2, post_length - 8.0), Color("4a4170"))
		draw_rect(Rect2(-8, post_length - 4.0, 16, 4), Color("231d38"))
	if not Engine.is_editor_hint() and _interact and interact_offset != Vector2.ZERO:
		# A small turning-wheel at the control point, linked by a faint line
		var p := interact_offset
		draw_rect(Rect2(p + Vector2(-8, -6), Vector2(16, 6)), Color("231d38"))
		draw_circle(p + Vector2(0, -9), 4.0, Color("2b2838"))
		draw_arc(p + Vector2(0, -9), 4.0, 0.0, TAU, 12, Color("5b5773"), 1.0)
		draw_dashed_line(p + Vector2(0, -12), Vector2.ZERO, Color(0.45, 0.4, 0.6, 0.35), 1.0, 5.0)
	draw_circle(Vector2.ZERO, 11.0, Color("1f1a33"))
	draw_arc(Vector2.ZERO, 11.0, 0.0, TAU, 20, Color("5b5773"), 2.0)
	# Dark backing on the non-reflective side
	var n := Vector2.from_angle(_shown_angle)
	var along := n.orthogonal()
	var back := -n * 3.0
	draw_line(back + along * 8.0, back - along * 8.0, Color("2b2838"), 4.0)
	_face_glow.queue_redraw()


func _draw_face() -> void:
	if not Engine.is_editor_hint() and _interact and interact_offset != Vector2.ZERO:
		# The distant control wheel glows faintly so it can be found in the dark
		var p := interact_offset + Vector2(0, -9)
		_face_glow.draw_arc(p, 4.0, _shown_angle, _shown_angle + TAU * 0.75, 10, Color(0.62, 0.55, 0.95, 0.7), 1.0)
		_face_glow.draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(0.75, 0.7, 1.0, 0.8))
	var n := Vector2.from_angle(_shown_angle)
	var along := n.orthogonal()
	# Silvered face with a small notch showing which way it faces
	_face_glow.draw_line(along * 8.0, -along * 8.0, Color(0.82, 0.9, 1.0), 2.0)
	_face_glow.draw_line(n * 2.0, n * 6.0, Color(0.6, 0.78, 1.0, 0.8), 1.0)
