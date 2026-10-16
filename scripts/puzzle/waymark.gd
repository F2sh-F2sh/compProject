class_name Waymark
extends Node2D

## A waymark: an arrow drawn in chalk on the wall, showing which way the path
## goes on. Wren draws them for whoever comes after her (her chalk steps and
## stars are in the same chalk), so they belong to the dungeon rather than to
## the interface: no slab, no glow of their own, only the faintest light so
## they can still be read in a dark room. Pixel art
## (tools/art/generate_waymark_sprites.gd). Hidden when guidance is off.

@export_enum("right", "left", "up", "down") var direction := "right"

const SPRITE := "waymark"
const SCALE := 2.0

var _light: PointLight2D
var _time := 0.0


func _ready() -> void:
	z_index = -1
	var size := SurfaceArt.size_of(SPRITE)
	var art := Node2D.new()
	art.name = "Art"
	add_child(art)
	var chalk := SurfaceArt.animated(art, SPRITE, Vector2(0, size.y * SCALE / 2.0), 1.2, SCALE, direction == "left")
	chalk.name = "Chalk"
	art.rotation = {"right": 0.0, "left": 0.0, "up": -PI / 2.0, "down": PI / 2.0}[direction]
	if Engine.is_editor_hint():
		return
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(128)
	_light.color = Color(0.82, 0.86, 1.0)
	_light.energy = 0.16
	_light.texture_scale = 0.5
	_light.shadow_enabled = false
	add_child(_light)
	add_to_group("waymark")
	visible = Settings.guidance >= Settings.GUIDANCE_LIGHT


func _process(delta: float) -> void:
	_time += delta
	if _light:
		_light.energy = 0.14 + 0.04 * sin(_time * 1.6)
