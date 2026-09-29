@tool
class_name LightLens
extends Node2D

## A wall-mounted crystal lens behind an iron shutter. While powered (for
## example by a lever through a Circuit) the shutter is open and it casts a
## beam of magical light in `beam_direction`. Mount it on a wall or ceiling.

signal power_changed(powered: bool)

@export var beam_direction := Vector2.DOWN:
	set(value):
		beam_direction = value
		queue_redraw()
@export var start_on := false

var is_on := false
var _beam: LightBeam
var _glow: Node2D


func _ready() -> void:
	_glow = Node2D.new()
	_glow.material = MagicLight.unshaded()
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	_beam = LightBeam.new()
	_beam.direction = beam_direction
	_beam.origin_offset = beam_direction.normalized() * 10.0
	add_child(_beam)
	_set_on(start_on, true)


func is_powered() -> bool:
	return is_on


func set_powered(powered: bool) -> void:
	_set_on(powered)


func reset_state() -> void:
	_set_on(start_on, true)


func _set_on(on: bool, silent := false) -> void:
	if on == is_on and not silent:
		return
	is_on = on
	if _beam:
		_beam.emitting = on
	if not silent:
		Sfx.play("switch_on" if on else "power_down", global_position, -4.0)
	power_changed.emit(on)
	queue_redraw()
	_glow.queue_redraw()


func _draw() -> void:
	var d := beam_direction.normalized()
	var side := d.orthogonal()
	# Housing plate against the wall, facing the beam direction
	draw_rect(Rect2(-12, -12, 24, 24), Color("231d38"))
	draw_rect(Rect2(-12, -12, 24, 24), Color("5b5773"), false, 1.0)
	if not is_on:
		# Closed shutter blades
		for i in range(-2, 3):
			var c := d * 6.0 + side * i * 3.0
			draw_line(c - d * 4.0, c + d * 2.0, Color("4a4658"), 2.0)


func _draw_glow() -> void:
	var colour := Color(0.6, 0.85, 1.0) if is_on else Color(0.35, 0.45, 0.8, 0.45)
	_glow.draw_circle(Vector2.ZERO, 5.0, colour)
