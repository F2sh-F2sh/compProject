class_name KindleFlame
extends Node2D

## A flame by a room's entrance where Echidna can kindle her lantern (hold the
## kindle key) to fill her mana, so running dry never means walking back
## through earlier rooms. It is the Kept Flame's pixel-art pedestal with a
## blue light and a few embers. Always lit; it is not a checkpoint.

const SPRITE := "kept_flame"

var _light: PointLight2D
var _time := 0.0


func _ready() -> void:
	# Hidden: mana is restored by holding R anywhere. The node is still placed
	# in the generated level scenes.
	visible = false
	z_index = -1
	var figure := SurfaceArt.animated(self, SPRITE, Vector2.ZERO, 6.0, 1.0)
	figure.name = "Figure"
	if Engine.is_editor_hint():
		return
	add_to_group("kindle_point")
	var height := SurfaceArt.size_of(SPRITE).y
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = Color(0.45, 0.65, 1.0)
	_light.energy = 0.7
	_light.texture_scale = 1.1
	_light.shadow_enabled = false
	_light.position = Vector2(0, -height * 0.6)
	add_child(_light)
	var embers := GlowFX.embers(Color(0.55, 0.75, 1.0), 6, 20.0, 3.0, 1.6)
	embers.position = Vector2(0, -height * 0.8)
	add_child(embers)


func _process(delta: float) -> void:
	_time += delta
	if _light:
		_light.energy = 0.7 + 0.08 * sin(_time * 7.0)


## A lit flame she can kindle her lantern at (hold the kindle key).
func is_kindling() -> bool:
	return true
