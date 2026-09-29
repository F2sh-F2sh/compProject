@tool
class_name RuneSeal
extends Node2D

## The carved seal over a great door. When powered it wakes one rune at a
## time, tolls the bell, and only then powers its own targets (the door), so
## a finale reads as a ceremony rather than a switch. A seal that is already
## solved when the level loads opens instantly and silently.
## The node sits at the centre of the arch, above the door.

## Emitted once the seal has fully opened (or closed again), so circuits can
## use a solved seal as a source.
signal power_changed(powered: bool)

@export var targets: Array[Node] = []
@export var rune_count := 5:
	set(value):
		rune_count = maxi(value, 1)
		queue_redraw()
@export var arch_radius := 44.0:
	set(value):
		arch_radius = value
		queue_redraw()
@export var step_time := 0.35

var lit_runes := 0
var is_open := false
var _settled := false
var _sequence: Tween
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
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = Color(0.55, 0.75, 1.0)
	_light.energy = 0.0
	add_child(_light)
	_settle.call_deferred()


func _settle() -> void:
	# Anything powering the seal during loading restores a solved state
	await get_tree().physics_frame
	await get_tree().physics_frame
	_settled = true


func set_powered(powered: bool) -> void:
	if not powered:
		if _sequence:
			_sequence.kill()
		_set_open(false)
		lit_runes = 0
		return
	if is_open or (_sequence and _sequence.is_running()):
		return
	if not _settled:
		lit_runes = rune_count
		_set_open(true)
		return
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root:
		root.show_mechanism(global_position + Vector2(0, 40), step_time * rune_count + 1.2)
	_sequence = create_tween()
	for i in rune_count:
		_sequence.tween_callback(func():
			lit_runes = i + 1
			Sfx.play("receiver_on", global_position, -4.0, 0.0))
		_sequence.tween_interval(step_time)
	_sequence.tween_callback(func():
		Sfx.play("bell", global_position, 2.0, 0.0)
		var camera := get_viewport().get_camera_2d()
		if camera and camera.has_method("shake"):
			camera.shake(2.5, 0.3)
		_set_open(true))


func is_powered() -> bool:
	return is_open


func reset_state() -> void:
	# Only an unsolved seal is ever reset; its circuit decides that
	pass


func _set_open(open: bool) -> void:
	var changed := open != is_open
	is_open = open
	for target in targets:
		if is_instance_valid(target) and target.has_method("set_powered"):
			target.set_powered(open)
	if changed:
		power_changed.emit(open)


func _process(delta: float) -> void:
	_time += delta
	if Engine.is_editor_hint():
		return
	var want := 0.4 + 0.9 * float(lit_runes) / rune_count
	_light.energy = lerpf(_light.energy, want if lit_runes > 0 else 0.0, minf(delta * 4.0, 1.0))
	_glow.queue_redraw()


func _rune_position(i: int) -> Vector2:
	var a := PI + PI * (i + 0.5) / rune_count
	return Vector2.from_angle(a) * arch_radius


func _draw() -> void:
	# Stone arch band the runes are cut into
	draw_arc(Vector2.ZERO, arch_radius, PI, TAU, 32, Color("231d38"), 12.0)
	draw_arc(Vector2.ZERO, arch_radius + 6.0, PI, TAU, 32, Color("4a4170"), 1.0)
	draw_arc(Vector2.ZERO, arch_radius - 6.0, PI, TAU, 32, Color("2b2442"), 1.0)
	# Keystone
	draw_rect(Rect2(-7, -arch_radius - 9.0, 14, 16), Color("2b2442"))
	draw_rect(Rect2(-7, -arch_radius - 9.0, 14, 2), Color("5a4f84"))


func _draw_glow() -> void:
	var editor := Engine.is_editor_hint()
	for i in rune_count:
		var p := _rune_position(i)
		var on := editor or i < lit_runes
		var c := Color(0.75, 0.9, 1.0, 0.95) if on else Color(0.35, 0.3, 0.52, 0.7)
		# Each rune is a different small glyph
		match i % 3:
			0:
				_glow.draw_rect(Rect2(p + Vector2(-1, -4), Vector2(2, 8)), c)
				_glow.draw_rect(Rect2(p + Vector2(-3, -1), Vector2(6, 2)), c)
			1:
				_glow.draw_arc(p, 3.0, 0.0, TAU, 10, c, 1.0)
				_glow.draw_rect(Rect2(p + Vector2(-1, -1), Vector2(2, 2)), c)
			2:
				_glow.draw_polyline(PackedVector2Array([p + Vector2(-3, 3), p + Vector2(0, -4), p + Vector2(3, 3),
					p + Vector2(-3, 3)]), c, 1.0)
	if lit_runes >= rune_count and not editor:
		var pulse := 0.5 + 0.5 * sin(_time * 3.0)
		_glow.draw_rect(Rect2(-2, -arch_radius - 5.0, 4, 8), Color(0.85, 0.95, 1.0, 0.6 + 0.4 * pulse))
