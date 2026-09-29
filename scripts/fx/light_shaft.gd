@tool
class_name LightShaft
extends Node2D

## A beam of light falling through an opening: a soft additive beam drawn by
## assets/shaders/light_shaft.gdshader, dust motes drifting inside it, and a
## real Light2D of the same shape, so the stone and anything walking through
## (Echidna included) are lit where it lands and cast shadows below it.
## The node sits at the opening; the beam leans by `angle_deg`.

const SHADER := preload("res://assets/shaders/light_shaft.gdshader")
const LIGHT_TEXTURE := preload("res://assets/fx/shaft_light.png")
const MOTE := preload("res://assets/fx/mote.png")
const STRIPS := 16

@export var length := 320.0:
	set(value):
		length = value
		_rebuild()
@export var width_top := 44.0:
	set(value):
		width_top = value
		_rebuild()
@export var width_bottom := 110.0:
	set(value):
		width_bottom = value
		_rebuild()
## Lean from vertical; positive leans the beam to the right as it falls.
@export_range(-60.0, 60.0) var angle_deg := 16.0:
	set(value):
		angle_deg = value
		_rebuild()
@export var color := Color(0.6, 0.8, 0.92):
	set(value):
		color = value
		_rebuild()
@export_range(0.0, 1.0) var intensity := 0.22:
	set(value):
		intensity = value
		_rebuild()
@export var light_energy := 0.55
@export var dust := true

var light: PointLight2D
var motes: CPUParticles2D


func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	material = mat
	_rebuild()
	if Engine.is_editor_hint():
		return
	light = PointLight2D.new()
	light.name = "ShaftLight"
	light.texture = LIGHT_TEXTURE
	light.color = color
	light.energy = light_energy
	# Light from above the plane, so normal-mapped stone is lit face-on
	# rather than only along edges that happen to face the beam
	light.height = 80.0
	light.shadow_enabled = true
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.shadow_color = Color(0, 0, 0, 0.85)
	add_child(light)
	if dust:
		motes = CPUParticles2D.new()
		motes.name = "Dust"
		motes.texture = MOTE
		motes.amount = int(clampf(length / 12.0, 10.0, 40.0))
		motes.lifetime = 7.0
		motes.preprocess = 7.0
		motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		motes.gravity = Vector2(0, 3)
		motes.direction = Vector2(0.3, 1)
		motes.spread = 180.0
		motes.initial_velocity_min = 1.0
		motes.initial_velocity_max = 5.0
		motes.scale_amount_min = 0.25
		motes.scale_amount_max = 0.6
		motes.color = Color(0.78, 0.9, 1.0)
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 1, 1, 0))
		ramp.set_color(1, Color(1, 1, 1, 0))
		ramp.add_point(0.2, Color(1, 1, 1, 0.75))
		ramp.add_point(0.8, Color(1, 1, 1, 0.6))
		motes.color_ramp = ramp
		var additive := CanvasItemMaterial.new()
		additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		motes.material = additive
		add_child(motes)
	_rebuild()


func direction() -> Vector2:
	var a := deg_to_rad(angle_deg)
	return Vector2(sin(a), cos(a))


## World position where the beam's centre line meets its far end.
func get_end_position() -> Vector2:
	return global_position + direction() * length


## True if a world point lies inside the beam's footprint.
func contains_point(world_point: Vector2) -> bool:
	var local := world_point - global_position
	var dir := direction()
	var along := local.dot(dir)
	if along < 0.0 or along > length:
		return false
	var across := absf(local.dot(Vector2(dir.y, -dir.x)))
	return across <= lerpf(width_top, width_bottom, along / length) / 2.0


func _rebuild() -> void:
	if material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter("shaft_color", color)
		(material as ShaderMaterial).set_shader_parameter("intensity", intensity)
		(material as ShaderMaterial).set_shader_parameter("seed", fmod(absf(position.x) * 0.013, 7.0))
	var dir := direction()
	var mid_width := (width_top + width_bottom) / 2.0
	if light:
		light.color = color
		light.energy = light_energy
		# The light's texture hangs from the opening and follows the lean
		light.rotation = -deg_to_rad(angle_deg)
		light.scale = Vector2(mid_width / LIGHT_TEXTURE.get_width(), length / LIGHT_TEXTURE.get_height())
		light.offset = Vector2(0, LIGHT_TEXTURE.get_height() / 2.0)
	if motes:
		motes.position = dir * length * 0.5
		motes.rotation = -deg_to_rad(angle_deg)
		motes.emission_rect_extents = Vector2(mid_width * 0.35, length * 0.45)
	queue_redraw()


func _draw() -> void:
	var dir := direction()
	var side := Vector2(dir.y, -dir.x)
	for i in STRIPS:
		var t0 := float(i) / STRIPS
		var t1 := float(i + 1) / STRIPS
		var c0 := dir * length * t0
		var c1 := dir * length * t1
		var h0 := lerpf(width_top, width_bottom, t0) / 2.0
		var h1 := lerpf(width_top, width_bottom, t1) / 2.0
		draw_polygon(
			PackedVector2Array([c0 + side * h0, c0 - side * h0, c1 - side * h1, c1 + side * h1]),
			PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE]),
			PackedVector2Array([Vector2(0, t0), Vector2(1, t0), Vector2(1, t1), Vector2(0, t1)]))
