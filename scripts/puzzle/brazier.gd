@tool
class_name Brazier
extends Node2D

## An interactive iron brazier. Unlit it smoulders with a few embers and a
## rune on its bowl (decorative wall torches have neither). A fireball — or a
## circuit powering it — lights it with blue magical fire. When lit it:
## - is a powered source for circuits,
## - casts a beam if beam_direction is set,
## - bathes nearby things in magical light if light_radius > 0.
## The node sits on the floor surface.

signal power_changed(powered: bool)

@export var start_lit := false
@export var beam_direction := Vector2.ZERO
@export var light_radius := 0.0
## Lit braziers go out again after this many seconds (0 = burn forever).
@export var burn_time := 0.0
## 0 stands on the ground; -1 / 1 hangs on an iron shelf from a wall on the
## left / right, `bracket_length` px away (nothing solid under it, so
## fireballs can reach it from below).
@export_range(-1, 1) var wall_side := 0:
	set(value):
		wall_side = value
		queue_redraw()
@export var bracket_length := 24.0:
	set(value):
		bracket_length = value
		queue_redraw()

const BOWL_Y := -26.0

var is_lit := false
var _beam: LightBeam
var _halo: Sprite2D
var _embers: CPUParticles2D
var _flame: Node2D
var _light: PointLight2D
var _time := 0.0
var _burn_left := 0.0


func _ready() -> void:
	_flame = Node2D.new()
	_flame.material = MagicLight.unshaded()
	_flame.draw.connect(_draw_flame)
	add_child(_flame)
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	var catcher := Area2D.new()
	catcher.collision_layer = 0
	catcher.collision_mask = 1
	catcher.monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	catcher.add_child(collider)
	catcher.position = Vector2(0, BOWL_Y - 4.0)
	add_child(catcher)
	catcher.area_entered.connect(_on_area_entered)

	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = Color(0.45, 0.65, 1.0)
	_light.position = Vector2(0, BOWL_Y - 10.0)
	_light.shadow_enabled = true
	_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	add_child(_light)

	if beam_direction != Vector2.ZERO:
		_beam = LightBeam.new()
		_beam.direction = beam_direction
		_beam.origin_offset = Vector2(0, BOWL_Y - 8.0)
		add_child(_beam)
	# A breathing halo and rising sparks while lit
	_halo = GlowFX.halo(Color(0.45, 0.66, 1.0), 34.0, 0.55, 2.4, 0.2)
	_halo.position = Vector2(0, BOWL_Y - 10.0)
	add_child(_halo)
	_embers = GlowFX.embers(Color(0.6, 0.8, 1.0), 10, 30.0, 7.0)
	_embers.position = Vector2(0, BOWL_Y - 4.0)
	add_child(_embers)
	_set_lit(start_lit, true)


func is_powered() -> bool:
	return is_lit


## Circuits can light or douse the brazier.
func set_powered(powered: bool) -> void:
	_set_lit(powered)


func ignite() -> void:
	_set_lit(true)


# --- aura interface used by MagicLight (light_radius is the export above) ---
func is_emitting() -> bool:
	return is_lit and light_radius > 0.0


func get_light_origin() -> Vector2:
	return global_position + Vector2(0, BOWL_Y - 10.0)


func reset_state() -> void:
	_set_lit(start_lit, true)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("fireball"):
		area.queue_free()
		_set_lit(true)


func _set_lit(lit: bool, silent := false) -> void:
	if lit == is_lit and not silent:
		return
	is_lit = lit
	_burn_left = burn_time
	if lit and light_radius > 0.0:
		add_to_group(MagicLight.AURA_GROUP)
	elif is_in_group(MagicLight.AURA_GROUP):
		remove_from_group(MagicLight.AURA_GROUP)
	if _beam:
		_beam.emitting = lit
	if _halo:
		_halo.visible = lit
		_embers.emitting = lit
	if _light:
		_light.energy = 1.2 if lit else 0.15
		_light.texture_scale = 1.4 if lit else 0.3
	if not silent and lit:
		Sfx.play("brazier_ignite", global_position)
	power_changed.emit(lit)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	_flame.queue_redraw()
	if Engine.is_editor_hint():
		return
	if is_lit and burn_time > 0.0:
		_burn_left -= delta
		if _burn_left <= 0.0:
			_set_lit(false)
	if is_lit and _light:
		_light.energy = 1.2 + 0.1 * sin(_time * 9.0) + 0.05 * sin(_time * 23.0)


func _draw() -> void:
	var iron := Color("2b2838")
	var iron_light := Color("5b5773")
	if wall_side != 0:
		# Iron shelf from the wall, with a diagonal strut beneath
		var wall_x := wall_side * (bracket_length + 14.0)
		draw_rect(Rect2(minf(-14.0, wall_x), 0, absf(wall_x) + 14.0, 3), iron)
		draw_rect(Rect2(minf(-14.0, wall_x), 0, absf(wall_x) + 14.0, 1), iron_light)
		draw_line(Vector2(wall_x, 22), Vector2(0, 2), iron, 3.0)
		draw_rect(Rect2(wall_x - 2.0, -4, 4, 30), Color("231d38"))
	# Tripod legs
	draw_line(Vector2(-10, 0), Vector2(-4, -18), iron, 3.0)
	draw_line(Vector2(10, 0), Vector2(4, -18), iron, 3.0)
	draw_line(Vector2(0, 0), Vector2(0, -18), iron, 2.0)
	# Bowl
	draw_colored_polygon(PackedVector2Array([Vector2(-14, BOWL_Y), Vector2(14, BOWL_Y),
		Vector2(9, -17), Vector2(-9, -17)]), iron)
	draw_line(Vector2(-14, BOWL_Y), Vector2(14, BOWL_Y), iron_light, 2.0)
	# Rune band marks it as something you can light
	var rune := Color(0.5, 0.7, 1.0) if is_lit else Color(0.38, 0.33, 0.55)
	for x in [-8, -3, 2, 7]:
		draw_rect(Rect2(x, -22, 2, 2), rune)


func _draw_flame() -> void:
	if not is_lit:
		# Smouldering embers invite a spark
		var pulse := 0.4 + 0.3 * sin(_time * 2.5)
		for x in [-6, -1, 4]:
			_flame.draw_rect(Rect2(x, BOWL_Y - 2.0, 3, 2), Color(0.35, 0.5, 1.0, pulse))
		return
	for i in 4:
		var t := _time * 7.0 + i * 1.7
		var h := 18.0 + sin(t) * 4.0 - i * 3.5
		var w := 16.0 - i * 3.5
		var c: Color = [Color(0.2, 0.35, 0.95, 0.7), Color(0.35, 0.55, 1.0, 0.85),
			Color(0.6, 0.8, 1.0, 0.95), Color(0.92, 0.97, 1.0, 1.0)][i]
		_flame.draw_colored_polygon(PackedVector2Array([Vector2(-w / 2.0, BOWL_Y), Vector2(w / 2.0, BOWL_Y),
			Vector2(sin(t * 0.8) * 3.0, BOWL_Y - h)]), c)
