class_name Waymark
extends Node2D

## A Choir waymark: a small carved slab with a softly glowing arrow, set in the
## wall to show which way the path goes on. The monks cut them for novices
## (the Novices' Way is the path they walked), so they belong to the dungeon
## rather than to the interface. Pixel art (tools/generate_waymark_sprites.gd),
## a dim blue light, and a slow breath. Hidden when guidance is off.

@export_enum("right", "left", "up", "down") var direction := "right"

const SPRITE := "waymark"
const SCALE := 2.0

var _light: PointLight2D
var _time := 0.0


func _ready() -> void:
	z_index = -1
	modulate = Color(0.82, 0.86, 0.95)
	var size := SurfaceArt.size_of(SPRITE)
	var art := Node2D.new()
	art.name = "Art"
	add_child(art)
	var slab := SurfaceArt.animated(art, SPRITE, Vector2(0, size.y * SCALE / 2.0), 1.6, SCALE, direction == "left")
	slab.name = "Slab"
	art.rotation = {"right": 0.0, "left": 0.0, "up": -PI / 2.0, "down": PI / 2.0}[direction]
	if Engine.is_editor_hint():
		return
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(128)
	_light.color = Color(0.45, 0.65, 1.0)
	_light.energy = 0.35
	_light.texture_scale = 0.6
	_light.shadow_enabled = false
	add_child(_light)
	add_to_group("waymark")
	visible = Settings.guidance >= Settings.GUIDANCE_LIGHT


func _process(delta: float) -> void:
	_time += delta
	if _light:
		_light.energy = 0.3 + 0.12 * sin(_time * 2.0)
