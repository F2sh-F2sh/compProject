class_name StoryPaint
extends RefCounted

## Light and air for the story pictures and the village above the dungeon:
## soft glows, drifting motes and falling snow, and the label font. The
## things in the pictures (people, houses, bells, trees, the sky) are pixel
## art from the surface and town packs and the story sprites (SurfaceArt).

const GLOW_TEXTURE := preload("res://assets/fx/soft_glow.png")
const MOTE := preload("res://assets/fx/mote.png")
const LABEL_FONT := Fonts.UI


static func label_font() -> Font:
	return LABEL_FONT


## A soft additive glow: light, not paint.
static func glow(parent: Node, at: Vector2, radius: float, color: Color, energy := 1.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = GLOW_TEXTURE
	s.position = at
	s.scale = Vector2.ONE * radius * 2.0 / GLOW_TEXTURE.get_width()
	s.modulate = Color(color.r * energy, color.g * energy, color.b * energy, color.a)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	s.material = mat
	parent.add_child(s)
	return s


## Slow motes drifting in `area`.
static func motes(parent: Node, area: Rect2, color: Color, amount := 30) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = MOTE
	p.amount = amount
	p.lifetime = 8.0
	p.preprocess = 8.0
	p.position = area.get_center()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area.size / 2.0
	p.gravity = Vector2(0, 2)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 8.0
	p.spread = 180.0
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.5
	p.color = color
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	parent.add_child(p)
	return p


## Snow falling across `area` (set speed_scale to 0 and it hangs in the air).
static func snow(parent: Node, area: Rect2, amount := 90) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = MOTE
	p.amount = amount
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.position = area.get_center()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area.size / 2.0
	p.direction = Vector2(0.15, 1.0)
	p.spread = 12.0
	p.gravity = Vector2(0, 0)
	p.initial_velocity_min = 22.0
	p.initial_velocity_max = 40.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.6
	p.color = Color(0.92, 0.96, 1.0, 0.85)
	parent.add_child(p)
	return p
