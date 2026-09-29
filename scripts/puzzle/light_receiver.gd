@tool
class_name LightReceiver
extends Node2D

## A crystal socket that is powered while magical light reaches it: a beam
## ending on it, or (if accepts_aura) a wisp or brazier aura with a clear line
## of sight. It powers circuits like any other source.

signal power_changed(powered: bool)

@export var accepts_aura := true
## Keeps it lit briefly after the light leaves, so it never flickers.
@export var hold_time := 0.12
@export var color := Color(0.55, 0.8, 1.0)

var powered := false
var _lit_timer := 0.0
var _glow: Node2D
var _light: PointLight2D
var _time := 0.0


func _ready() -> void:
	_glow = Node2D.new()
	_glow.material = MagicLight.unshaded()
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	MagicLight.add_sensor(self, 10.0)
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(128)
	_light.color = color
	_light.energy = 0.0
	add_child(_light)


func is_powered() -> bool:
	return powered


func receive_light(_beam: Node) -> void:
	_lit_timer = hold_time


func reset_state() -> void:
	_lit_timer = 0.0
	_set_powered(false, true)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	if accepts_aura and MagicLight.aura_reaches(get_world_2d(), global_position):
		_lit_timer = hold_time
	_lit_timer -= delta
	_set_powered(_lit_timer > 0.0)
	_light.energy = lerpf(_light.energy, 1.0 if powered else 0.0, minf(delta * 10.0, 1.0))
	_glow.queue_redraw()


func _set_powered(on: bool, silent := false) -> void:
	if on == powered:
		return
	powered = on
	if not silent:
		Sfx.play("receiver_on" if on else "power_down", global_position, 0.0 if on else -8.0)
	power_changed.emit(on)
	queue_redraw()


func _draw() -> void:
	# Iron bracket around a dark crystal
	draw_rect(Rect2(-9, -9, 18, 18), Color("231d38"))
	draw_rect(Rect2(-9, -9, 18, 18), Color("5b5773"), false, 1.0)
	var crystal := PackedVector2Array([Vector2(0, -7), Vector2(5, 0), Vector2(0, 7), Vector2(-5, 0)])
	draw_colored_polygon(crystal, Color("2e3a66") if not powered else Color("3a4a80"))


func _draw_glow() -> void:
	var crystal := PackedVector2Array([Vector2(0, -7), Vector2(5, 0), Vector2(0, 7), Vector2(-5, 0)])
	if powered:
		_glow.draw_colored_polygon(crystal, Color(color.lightened(0.3), 0.95))
		# A turning ring of rune marks confirms it is receiving light
		for i in 6:
			var a := _time * 2.0 + i * TAU / 6.0
			_glow.draw_rect(Rect2(Vector2.from_angle(a) * 13.0 - Vector2(1, 1), Vector2(2, 2)), color)
	else:
		_glow.draw_polyline(PackedVector2Array([Vector2(0, -7), Vector2(5, 0), Vector2(0, 7), Vector2(-5, 0),
			Vector2(0, -7)]), Color(color, 0.35), 1.0)
