class_name PostFX
extends CanvasLayer

## Drives the dungeon mood shader (assets/shaders/dungeon_post.gdshader).
## Feeds it the camera's world rectangle, so the mist stays attached to the
## world as the camera moves, and the player's position, which is where the
## lantern's pool of light is centred.

@onready var rect: ColorRect = $Screen

## Whether the Brightness setting applies here. The dungeon follows it; story
## scenes (Lowbell, Nan's cottage) have their own look and turn this off.
var follows_brightness := true
var _full := {}
var _ambient: CanvasModulate
var _ambient_base := Color.WHITE
## The current room's ambient (x the level's own): watcher rooms stay dark so
## "watchers hunt in darkness" still reads in an otherwise brighter dungeon.
var _room_ambient := 1.0
var _ambient_tween: Tween


func _ready() -> void:
	preload("res://scripts/fx/world_layout.gd").settle.call_deferred(get_parent())
	# each level its own palette, mist and air (LevelTheme)
	LevelTheme.apply.call_deferred(get_parent())
	Settings.changed.connect(_on_settings_changed)
	_on_settings_changed.call_deferred()


func _on_settings_changed() -> void:
	_apply_quality()
	_apply_brightness()


## Applies the brightness level (Settings.BRIGHTNESS_TABLE): the level's
## ambient light, the lantern's gloom and reach, the vignette, and the size of
## the player's own light. Levels that never had a player light (the old
## tutorial) get the same one the chapters have.
func _apply_brightness() -> void:
	if not follows_brightness:
		return
	var level := get_parent()
	if level == null:
		return
	if _ambient == null:
		_ambient = level.get_node_or_null("Darkness") as CanvasModulate
		if _ambient:
			_ambient_base = _ambient.color
	if _ambient:
		_ambient.color = _ambient_color()
	var mat := rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("lantern_darkness", Settings.light("gloom"))
		mat.set_shader_parameter("lantern_outer", Settings.light("reach"))
		mat.set_shader_parameter("vignette", Settings.light("vignette"))
		mat.set_shader_parameter("shadow_lift", Settings.light("gamma"))
	var aura := _player_light()
	if aura:
		var authored: Vector2 = aura.get_meta(&"authored")
		aura.energy = authored.x * Settings.light("light_energy")
		aura.texture_scale = authored.y * Settings.light("light_scale")


func _ambient_color() -> Color:
	var k := Settings.light("ambient") * _room_ambient
	return Color(minf(_ambient_base.r * k, 1.0), minf(_ambient_base.g * k, 1.0), minf(_ambient_base.b * k, 1.0), 1.0)


## Eases the ambient light to a room's own level (1.0 = the level's ambient).
func set_room_ambient(scale: float, instant := false) -> void:
	if is_equal_approx(scale, _room_ambient):
		return
	if _ambient_tween:
		_ambient_tween.kill()
	if instant or _ambient == null:
		_room_ambient = scale
		if _ambient:
			_ambient.color = _ambient_color()
		return
	_ambient_tween = create_tween()
	_ambient_tween.tween_method(func(k: float):
		_room_ambient = k
		_ambient.color = _ambient_color(), _room_ambient, scale, 1.6)


func _player_light() -> PointLight2D:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return null
	var aura := player.get_node_or_null("PlayerLight") as PointLight2D
	if aura == null:
		aura = PointLight2D.new()
		aura.name = "PlayerLight"
		aura.texture = LightTextures.radial(256)
		aura.color = Color(0.78, 0.72, 1.0)
		aura.energy = 1.15
		aura.texture_scale = 1.45
		aura.height = 40.0
		aura.position = Vector2(0, -20)
		player.add_child(aura)
	if not aura.has_meta(&"authored"):
		aura.set_meta(&"authored", Vector2(aura.energy, aura.texture_scale))
	return aura


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
