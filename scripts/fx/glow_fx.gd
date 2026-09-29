class_name GlowFX
extends RefCounted

## Builders for the dungeon's two small light effects, so every glowing thing
## shares one look:
##  - halo(): a soft radial glow that breathes and flickers
##    (assets/shaders/glow_pulse.gdshader), for magic, flames and items
##  - embers(): sparks drifting up off a flame, additive and self-lit
## Both ignore the dungeon's darkness (they are light), and both are cheap.

const HALO_TEXTURE := preload("res://assets/fx/soft_glow.png")
const MOTE := preload("res://assets/fx/mote.png")
const PULSE := preload("res://assets/shaders/glow_pulse.gdshader")


static func halo(color: Color, radius: float, intensity := 0.5, pulse_speed := 2.0, pulse_amount := 0.2,
		flicker := 0.12) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = "Halo"
	sprite.texture = HALO_TEXTURE
	sprite.scale = Vector2.ONE * radius * 2.0 / HALO_TEXTURE.get_width()
	var mat := ShaderMaterial.new()
	mat.shader = PULSE
	mat.set_shader_parameter("glow_color", color)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("pulse_speed", pulse_speed)
	mat.set_shader_parameter("pulse_amount", pulse_amount)
	mat.set_shader_parameter("flicker_amount", flicker)
	mat.set_shader_parameter("phase", randf() * TAU)
	sprite.material = mat
	return sprite


## Sparks rising from a flame. `spread` is the half-width they start across.
static func embers(color: Color, amount := 8, rise := 28.0, spread := 5.0, lifetime := 1.3) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Embers"
	p.texture = MOTE
	p.amount = amount
	p.lifetime = lifetime
	p.preprocess = lifetime
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(spread, 2.0)
	p.direction = Vector2(0, -1)
	p.spread = 22.0
	p.gravity = Vector2(0, -rise)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 16.0
	p.damping_min = 4.0
	p.damping_max = 10.0
	p.scale_amount_min = 0.22
	p.scale_amount_max = 0.45
	p.color = color
	# Bright when born, cooling and fading as they rise; each ember a little
	# different in brightness so the stream twinkles
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.4, 1.4, 1.4, 1.0))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.35, Color(1, 1, 1, 0.9))
	p.color_ramp = ramp
	var variety := Gradient.new()
	variety.set_color(0, Color(1, 1, 1, 0.45))
	variety.set_color(1, Color(1, 1, 1, 1.0))
	p.color_initial_ramp = variety
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = additive
	return p
