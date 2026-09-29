@tool
class_name PressurePlate
extends Area2D

## A floor plate held down by anything with weight: the player, an Echo,
## a pushable block, or creatures in the "plate_weight" group (slimes,
## gargoyles). Momentary by default; a latched plate stays down once pressed
## until the room is reset. A heavy plate (`stone_only`) is marked with a
## carved block and only sinks under stone: pushable blocks and gargoyles
## that have turned to stone. It is a power source (`power_changed`,
## `is_powered`) and can also drive `targets` directly via set_open().
## The node sits on the floor surface, centred on the plate.

signal pressed_changed(is_pressed: bool)
signal power_changed(powered: bool)

const ECHO_LAYER := 4

@export var width := 44.0:
	set(value):
		width = value
		queue_redraw()
@export var targets: Array[Node] = []
@export var latched := false
@export var stone_only := false:
	set(value):
		stone_only = value
		queue_redraw()
## Only loose objects (crates, stone blocks) and creatures press it; the
## player and her Echoes are too light. Marked with a small crate at each end.
@export var objects_only := false:
	set(value):
		objects_only = value
		queue_redraw()
@export var light_color := Color(0.62, 0.45, 1.0)

var is_pressed := false
var _occupants := {}
var _light: PointLight2D
var _time := 0.0


func _ready() -> void:
	collision_layer = 0
	# Player, blocks and creatures are on layer 1; Echo pressers on layer 3
	collision_mask = 1 | ECHO_LAYER
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width - 8.0, 14.0)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0, -7)
	add_child(collider)

	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(128)
	_light.color = light_color
	_light.energy = 0.0
	_light.position = Vector2(0, -6)
	add_child(_light)

	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	body_entered.connect(func(b): _set_occupant(b, _has_weight(b), true))
	body_exited.connect(func(b): _set_occupant(b, true, false))
	area_entered.connect(func(a): _set_occupant(a, a.is_in_group("echo_presser"), true))
	area_exited.connect(func(a): _set_occupant(a, true, false))


func is_powered() -> bool:
	return is_pressed


func reset_state() -> void:
	# Re-derive from whatever is actually standing on the plate now
	_occupants.clear()
	for body in get_overlapping_bodies():
		if _has_weight(body):
			_occupants[body] = true
	for area in get_overlapping_areas():
		if area.is_in_group("echo_presser"):
			_occupants[area] = true
	_set_pressed(_any_pressing(), true)


func _has_weight(body: Node) -> bool:
	return body.is_in_group("player") or body.is_in_group("plate_weight")


func _set_occupant(node: Node, counts: bool, entered: bool) -> void:
	if entered and counts:
		_occupants[node] = true
	elif not entered:
		_occupants.erase(node)
	_refresh()


func _refresh() -> void:
	for node in _occupants.keys():
		if not is_instance_valid(node) or not _still_counts(node):
			_occupants.erase(node)
	var pressed := _any_pressing()
	if latched and is_pressed:
		pressed = true
	_set_pressed(pressed)


# Echoes that fade and creatures that are defeated stop pressing the plate
func _still_counts(node: Node) -> bool:
	if node is Area2D:
		return node.monitorable
	if node.get("is_dead") == true or node.get("is_defeated") == true:
		return false
	return true


# Occupants are tracked either way; a heavy plate only sinks under stone
func _any_pressing() -> bool:
	for node in _occupants:
		if objects_only and (node is Area2D or node.is_in_group("player")):
			continue
		if not stone_only or node is PushableBlock or node.is_in_group("stone_weight") or node.get("is_frozen") == true:
			return true
	return false


func _set_pressed(pressed: bool, silent := false) -> void:
	if pressed == is_pressed:
		return
	is_pressed = pressed
	for target in targets:
		if is_instance_valid(target) and target.has_method("set_open"):
			target.set_open(pressed)
	pressed_changed.emit(pressed)
	power_changed.emit(pressed)
	if not silent:
		Sfx.play("plate_down" if pressed else "plate_up", global_position)
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	if not _occupants.is_empty():
		_refresh()
	var target_energy := 1.1 + 0.15 * sin(_time * 5.0) if is_pressed else 0.25 + 0.1 * sin(_time * 2.0)
	_light.energy = lerpf(_light.energy, target_energy, minf(delta * 8.0, 1.0))


func _draw() -> void:
	var w := roundf(width)
	var sink := 2.0 if is_pressed else 0.0
	# Stone socket
	draw_rect(Rect2(-w / 2.0 - 3.0, -5, w + 6.0, 5), Color("231d38"))
	draw_rect(Rect2(-w / 2.0 - 3.0, -5, w + 6.0, 1), Color("4c4468"))
	# Plate
	draw_rect(Rect2(-w / 2.0, -7 + sink, w, 5), Color("3b3358"))
	draw_rect(Rect2(-w / 2.0, -7 + sink, w, 1), Color("6a5f92"))
	# Rune: lit when pressed; a latched plate shows a lock bar too
	var rune := Color(0.85, 0.72, 1.0) if is_pressed else Color(0.4, 0.34, 0.55)
	var cy := -5.0 + sink
	for x in [-10, -4, 2, 8]:
		draw_rect(Rect2(x, cy, 3, 1), rune)
	draw_rect(Rect2(-1, cy - 1, 2, 3), rune)
	if latched:
		draw_rect(Rect2(-w / 2.0 + 2.0, cy + 1.0, 4, 1), rune)
		draw_rect(Rect2(w / 2.0 - 6.0, cy + 1.0, 4, 1), rune)
	if objects_only and not stone_only:
		# A little carved crate on both ends: "a crate goes here"
		for sx in [-w / 2.0 - 3.0, w / 2.0 - 3.0]:
			draw_rect(Rect2(sx, -12, 6, 7), Color("3a2a24"))
			draw_rect(Rect2(sx + 1, -11, 4, 5), Color("5a3f33"))
			draw_line(Vector2(sx + 1, -11), Vector2(sx + 5, -6), rune, 1.0)
	if stone_only:
		# Carved stone-block marks on both ends of the socket
		for sx in [-w / 2.0 - 3.0, w / 2.0 - 3.0]:
			draw_rect(Rect2(sx, -12, 6, 7), Color("2b2442"))
			draw_rect(Rect2(sx + 1, -11, 4, 1), rune)
			draw_rect(Rect2(sx + 1, -8, 4, 1), rune)
