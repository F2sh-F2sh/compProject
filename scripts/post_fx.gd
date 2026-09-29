class_name PostFX
extends CanvasLayer

## Drives the dungeon mood shader (assets/shaders/dungeon_post.gdshader).
## Feeds it the camera's world rectangle, so the mist stays attached to the
## world as the camera moves, and the player's position, which is where the
## lantern's pool of light is centred.

@onready var rect: ColorRect = $Screen

var _full := {}


func _ready() -> void:
	Settings.changed.connect(_apply_quality)
	_apply_quality.call_deferred()


## Low effects quality (for weaker graphics cards) turns off the bloom and
## film grain and stops lights casting shadows; High restores them.
func _apply_quality() -> void:
	var mat := rect.material as ShaderMaterial
	if mat == null:
		return
	var low := Settings.effects_low
	for param in ["bloom_strength", "grain"]:
		if not _full.has(param):
			var value = mat.get_shader_parameter(param)
			if value == null:
				# Not set on the material: the shader's own default
				value = RenderingServer.shader_get_parameter_default(mat.shader.get_rid(), param)
			_full[param] = value
		mat.set_shader_parameter(param, 0.0 if low else _full[param])
	var level := get_parent()
	if level:
		for light in level.find_children("*", "Light2D", true, false):
			if low and light.shadow_enabled:
				light.set_meta(&"had_shadow", true)
				light.shadow_enabled = false
			elif not low and light.get_meta(&"had_shadow", false):
				light.shadow_enabled = true


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	var mat := rect.material as ShaderMaterial
	if camera == null or mat == null:
		return
	var size := get_viewport().get_visible_rect().size / camera.zoom
	var origin := camera.get_screen_center_position() - size / 2.0
	mat.set_shader_parameter("world_origin", origin)
	mat.set_shader_parameter("world_size", size)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		# The lantern hangs at chest height
		var lantern := player.global_position + Vector2(0, -20)
		mat.set_shader_parameter("lantern_uv", (lantern - origin) / size)
