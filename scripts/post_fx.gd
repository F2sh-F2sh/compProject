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


## Applies the graphics level (Settings.GRAPHICS_TABLE): bloom and grain
## strength, whether lights cast shadows and how smooth they are, light
## shafts, and how many ambient motes drift about. Low suits weak graphics
## cards; Elite turns everything up.
func _apply_quality() -> void:
	var mat := rect.material as ShaderMaterial
	if mat == null:
		return
	var params := {"bloom_strength": "bloom", "grain": "grain"}
	for param in params:
		if not _full.has(param):
			var value = mat.get_shader_parameter(param)
			if value == null:
				# Not set on the material: the shader's own default
				value = RenderingServer.shader_get_parameter_default(mat.shader.get_rid(), param)
			if value == null:
				# The headless renderer has no compiled shader defaults.
				continue
			_full[param] = value
		mat.set_shader_parameter(param, _full[param] * float(Settings.quality(params[param])))
	var level := get_parent()
	if level == null:
		return
	var shadows: bool = Settings.quality("shadows")
	var filter: int = Settings.quality("filter")
	for light in level.find_children("*", "Light2D", true, false):
		# Remember each light as it was authored, the first time it is seen
		if not light.has_meta(&"had_shadow"):
			light.set_meta(&"had_shadow", light.shadow_enabled)
			light.set_meta(&"own_filter", light.shadow_filter)
		var authored: bool = light.get_meta(&"had_shadow")
		light.shadow_enabled = authored and shadows
		if authored:
			light.shadow_filter = light.get_meta(&"own_filter") if filter < 0 else filter
	var show_shafts: bool = Settings.quality("shafts")
	for shaft in get_tree().get_nodes_in_group("light_shaft"):
		shaft.visible = show_shafts
	var k: float = Settings.quality("particles")
	for motes in get_tree().get_nodes_in_group("ambient_particles"):
		if not motes.has_meta(&"base_amount"):
			motes.set_meta(&"base_amount", motes.amount)
		motes.amount = maxi(1, roundi(motes.get_meta(&"base_amount") * k))


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
