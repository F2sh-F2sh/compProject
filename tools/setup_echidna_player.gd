extends SceneTree

## Wires Echidna's sprite pipeline into scenes/Player.tscn: the sliced clips
## (tools/build_echidna_frames.gd), her lighting material, the charge glow
## and sparks, footfall dust and a contact shadow. Safe to run again; it
## replaces the nodes it owns (and removes the old ChargeWisps layer).
##
##   godot --headless --path . --script res://tools/setup_echidna_player.gd

const PLAYER := "res://scenes/Player.tscn"
const FRAMES := "res://assets/sprites/Echidna/echidna_frames.tres"
const OWNED := ["ContactShadow", "ChargeWisps", "WispLight", "WispSparks", "WalkDust"]

var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
		quit()
	return false


func _run() -> void:
	var root: Node2D = (load(PLAYER) as PackedScene).instantiate()
	for node_name in OWNED:
		var old := root.get_node_or_null(node_name)
		if old:
			root.remove_child(old)
			old.free()

	var frames: SpriteFrames = load(FRAMES)
	var offset: Vector2 = frames.get_meta(&"sprite_offset")
	var sprite: AnimatedSprite2D = root.get_node("AnimatedSprite2D")
	sprite.sprite_frames = frames
	sprite.animation = &"idle"
	sprite.autoplay = "idle"
	sprite.centered = true
	# The node sits exactly at her feet; the clips carry the pivot
	sprite.position = Vector2(-1, 0)
	sprite.offset = offset
	var lit := ShaderMaterial.new()
	lit.shader = load("res://assets/shaders/character_lit.gdshader")
	sprite.material = lit

	var shadow := Sprite2D.new()
	shadow.name = "ContactShadow"
	shadow.texture = _radial(Color(0, 0, 0, 1), Color(0, 0, 0, 0))
	shadow.position = Vector2(-1, 0)
	shadow.scale = Vector2(0.42, 0.1)
	shadow.modulate = Color(1, 1, 1, 0.5)
	shadow.z_index = -1
	_add(root, shadow, 0)

	# (The charge shows as a glow and sparks; the wisp lines were removed)
	var wisp_light := PointLight2D.new()
	wisp_light.name = "WispLight"
	wisp_light.texture = _radial(Color.WHITE, Color(1, 1, 1, 0), 128)
	wisp_light.color = Color(0.45, 0.66, 1.0)
	wisp_light.energy = 0.0
	wisp_light.texture_scale = 1.6
	wisp_light.position = Vector2(-1, -20)
	_add(root, wisp_light)

	var sparks := CPUParticles2D.new()
	sparks.name = "WispSparks"
	sparks.emitting = false
	sparks.amount = 10
	sparks.lifetime = 0.22
	sparks.position = Vector2(-1, -18)
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 15.0
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 25.0
	sparks.initial_velocity_max = 60.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 1.5
	sparks.color = Color(0.72, 0.88, 1.0)
	sparks.z_index = 2
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	sparks.material = unshaded
	_add(root, sparks)

	var sprint_dust: CPUParticles2D = root.get_node("SprintDust")
	var puff := CPUParticles2D.new()
	puff.name = "WalkDust"
	puff.emitting = false
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.amount = 5
	puff.lifetime = 0.35
	puff.position = Vector2(-1, -1)
	puff.direction = Vector2(-1, -0.35)
	puff.spread = 35.0
	puff.gravity = Vector2(0, -12)
	puff.initial_velocity_min = 12.0
	puff.initial_velocity_max = 30.0
	puff.damping_min = 40.0
	puff.damping_max = 60.0
	puff.scale_amount_min = 1.5
	puff.scale_amount_max = 2.5
	puff.color_ramp = sprint_dust.color_ramp
	_add(root, puff)

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err == OK:
		err = ResourceSaver.save(packed, PLAYER)
	print("Player scene updated: ", error_string(err))
	root.free()


func _add(root: Node, child: Node, index := -1) -> void:
	root.add_child(child)
	child.owner = root
	if index >= 0:
		root.move_child(child, index)


func _radial(inner: Color, outer: Color, size := 64) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, inner)
	gradient.set_color(1, outer)
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = size
	tex.height = size
	return tex
