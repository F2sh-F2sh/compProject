class_name LevelTheme
extends RefCounted

## Each level's own look (after the reference palettes: mossy teal and pink,
## cold blue stone, indigo night, ember on soot, aqua and algae, golden sepia,
## pastel pink and lavender), laid over the shared dungeon kit when a level
## loads (PostFX calls apply()):
##   - the stone recoloured by its brightness into the level's three tones
##     (assets/shaders/tile_recolor.gdshader), walls a little darker than floors
##   - the post-process mist and its shadow and highlight tints
##   - the far and middle backdrops recoloured the same way, the light shafts
##     and the torches tinted
##   - the air: what drifts in front of the camera (fireflies, falling snow,
##     star motes, rising embers, drips, gold dust, paper scraps)
## The ambient light's strength is left alone (the Brightness setting and the
## rooms' moods own it); only its colour comes from the stone and the mist.

const RECOLOR := preload("res://assets/shaders/tile_recolor.gdshader")
const MOTE := preload("res://assets/fx/mote.png")
## The tile layers that are the level's stone.
const STONE_LAYERS := ["Background", "BackDecor", "Earth", "Ground", "GroundHalf", "GroundHalfShifted", "Ceiling", "Walls"]

## id: tones (dark, mid, light), mist, shadow tint, highlight tint,
## saturation, torch colour, shaft colour, air.
const THEMES := {
	"passage": {"tones": ["0f1f1b", "3a6250", "86ae8a"], "mist": Color(0.3, 0.5, 0.42), "shadow": Color(0.86, 1.0, 0.94),
		"highlight": Color(1.05, 1.02, 0.96), "saturation": 0.98, "torch": Color(1.0, 0.76, 0.48), "shaft": Color(0.85, 1.0, 0.8), "air": "fireflies"},
	"belfry": {"tones": ["10141d", "46506a", "aab6cf"], "mist": Color(0.4, 0.48, 0.64), "shadow": Color(0.88, 0.94, 1.1),
		"highlight": Color(1.0, 1.02, 1.08), "saturation": 0.78, "torch": Color(0.8, 0.88, 1.0), "shaft": Color(0.8, 0.88, 1.0), "air": "snow"},
	"observatory": {"tones": ["0e0f22", "3c3f78", "a2a9e8"], "mist": Color(0.28, 0.28, 0.58), "shadow": Color(0.86, 0.86, 1.16),
		"highlight": Color(1.0, 1.0, 1.1), "saturation": 0.86, "torch": Color(0.82, 0.86, 1.0), "shaft": Color(0.78, 0.8, 1.0), "air": "stars"},
	"landing": {"tones": ["160f22", "564070", "bba3db"], "mist": Color(0.4, 0.32, 0.55), "shadow": Color(0.95, 0.9, 1.1),
		"highlight": Color(1.04, 1.0, 1.06), "saturation": 0.88, "torch": Color(1.0, 0.8, 0.6), "shaft": Color(0.9, 0.85, 1.0), "air": "frost"},
	"kiln": {"tones": ["1c0c09", "6b301f", "d79060"], "mist": Color(0.55, 0.28, 0.18), "shadow": Color(1.1, 0.92, 0.85),
		"highlight": Color(1.08, 1.0, 0.88), "saturation": 1.0, "torch": Color(1.0, 0.58, 0.3), "shaft": Color(1.0, 0.75, 0.5), "air": "embers"},
	"cistern": {"tones": ["0a1d22", "2c6670", "93d4d0"], "mist": Color(0.22, 0.5, 0.55), "shadow": Color(0.85, 1.05, 1.05),
		"highlight": Color(0.98, 1.04, 1.04), "saturation": 0.92, "torch": Color(0.6, 0.92, 1.0), "shaft": Color(0.7, 0.95, 1.0), "air": "drips"},
	"lamps": {"tones": ["21180b", "7a5a2d", "e6c47c"], "mist": Color(0.55, 0.44, 0.28), "shadow": Color(1.06, 0.98, 0.85),
		"highlight": Color(1.1, 1.03, 0.88), "saturation": 0.88, "torch": Color(1.0, 0.85, 0.5), "shaft": Color(1.0, 0.9, 0.6), "air": "dust"},
	"galleries": {"tones": ["211224", "8a5986", "f2c4de"], "mist": Color(0.55, 0.38, 0.55), "shadow": Color(1.06, 0.92, 1.06),
		"highlight": Color(1.06, 1.0, 1.04), "saturation": 0.95, "torch": Color(1.0, 0.76, 0.86), "shaft": Color(1.0, 0.85, 0.95), "air": "paper"},
	"eye": {"tones": ["070a14", "26304e", "8090ba"], "mist": Color(0.2, 0.25, 0.45), "shadow": Color(0.88, 0.94, 1.12),
		"highlight": Color(1.0, 1.0, 1.08), "saturation": 0.72, "torch": Color(1.0, 0.8, 0.55), "shaft": Color(0.7, 0.8, 1.0), "air": "snow_still"},
}
## id: [ambience bed (AudioDirector.set_bed), footsteps (step_<kind>_N)].
const SOUNDS := {"passage": ["", "stone"], "belfry": ["wind", "stone"], "observatory": ["stars", "stone"],
	"landing": ["hush", "stone"], "kiln": ["forge", "ash"], "cistern": ["water", "wet"], "lamps": ["lamps", "stone"],
	"galleries": ["folds", "paper"], "eye": ["eye", "stone"]}
## A level's chapter id (ChapterRoot.chapter_id) to its theme.
const BY_CHAPTER := {"ch1": "belfry", "ch2": "observatory", "landing": "landing", "kiln": "kiln", "cistern": "cistern",
	"lamps": "lamps", "galleries": "galleries", "eye": "eye"}


## The theme a level wears ("" for a scene that isn't a dungeon level).
static func id_for(level: Node) -> String:
	if level == null:
		return ""
	if level.scene_file_path.ends_with("tutorial_level.tscn") or level.scene_file_path.ends_with("tutorial_movement.tscn"):
		return "passage"
	if "chapter_id" in level:
		return String(BY_CHAPTER.get(String(level.get("chapter_id")), ""))
	return ""


## Dresses `level` in its theme (nothing happens for a scene without one).
static func apply(level: Node) -> String:
	var id := id_for(level)
	if id == "" or not THEMES.has(id):
		return ""
	var t: Dictionary = THEMES[id]
	level.set_meta(&"level_theme", id)
	level.set_meta(&"footstep", SOUNDS[id][1])
	AudioDirector.set_bed(SOUNDS[id][0])
	for layer_name in STONE_LAYERS:
		var layer := level.get_node_or_null(layer_name) as CanvasItem
		if layer:
			var back: bool = layer_name in ["Background", "BackDecor"]
			layer.material = recolor_material(t, 0.8 if back else 0.72, 1.45 if back else 1.7)
	var post := level.get_node_or_null("PostFX/Screen") as ColorRect
	if post and post.material is ShaderMaterial:
		var mat := post.material as ShaderMaterial
		mat.set_shader_parameter("fog_color", t["mist"])
		mat.set_shader_parameter("shadow_tint", t["shadow"])
		mat.set_shader_parameter("highlight_tint", t["highlight"])
		mat.set_shader_parameter("saturation", t["saturation"])
	# each room keeps its own mood, leaning toward the level's (rooms set the
	# mist and highlight again as she walks between them)
	for room in level.find_children("*", "Room", true, false):
		room.mood_fog = room.mood_fog.lerp(t["mist"], 0.75)
		room.mood_highlight = room.mood_highlight.lerp(t["highlight"], 0.6)
	if post and post.material is ShaderMaterial:
		var current := level.get("current_room") as Room if "current_room" in level else null
		if current:
			(post.material as ShaderMaterial).set_shader_parameter("fog_color", current.mood_fog)
			(post.material as ShaderMaterial).set_shader_parameter("highlight_tint", current.mood_highlight)
	for atmosphere in level.find_children("*", "DungeonAtmosphere", true, false):
		_dress_atmosphere.call_deferred(atmosphere, t)
	for light in level.find_children("*", "PointLight2D", true, false):
		if light.name.begins_with("TorchLight") or light.scene_file_path.ends_with("torch_light.tscn"):
			_tint_torch(light, t["torch"])
	# Exit stone and its magic light belong to the surrounding level palette.
	for exit in level.find_children("*", "LevelExit", true, false):
		var door := exit.get_node_or_null("Door") as Sprite2D
		if door:
			door.material = recolor_material(t, 0.72, 1.7)
		var glow := exit.get_node_or_null("Glow") as PointLight2D
		if glow:
			glow.color = t["shaft"]
		var wisps := exit.get_node_or_null("Wisps") as CPUParticles2D
		if wisps:
			wisps.color = Color(t["shaft"], wisps.color.a)
	_add_air(level, String(t["air"]))
	_scatter_props(level, id)
	CreatureSpawner.populate(level, id)
	return id


## Small props on the tops of ledges and hanging under the ceilings
## (tools/generate_level_props.gd), placed the same way every time.
static func _scatter_props(level: Node, id: String) -> void:
	var holder := Node2D.new()
	holder.name = "ThemeProps"
	holder.z_index = -1
	level.add_child(holder)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	for spec in [["Ground", "top", 0.2], ["Ceiling", "hang", 0.16]]:
		var layer := level.get_node_or_null(spec[0]) as TileMapLayer
		var path := "res://assets/sprites/props/prop_%s_%s.png" % [id, spec[1]]
		if layer == null or not ResourceLoader.exists(path):
			continue
		var strip: Texture2D = load(path)
		var frames := strip.get_width() / 16
		var placed := 0
		for cell in layer.get_used_cells():
			var open := cell + (Vector2i(0, -1) if spec[1] == "top" else Vector2i(0, 1))
			if layer.get_cell_source_id(open) != -1 or rng.randf() > float(spec[2]):
				continue
			var at := layer.to_global(layer.map_to_local(cell)) + Vector2(rng.randf_range(-22.0, 22.0), -10.0 if spec[1] == "top" else 30.0)
			var s := Sprite2D.new()
			var atlas := AtlasTexture.new()
			atlas.atlas = strip
			atlas.region = Rect2((rng.randi() % frames) * 16, 0, 16, 24)
			s.texture = atlas
			s.centered = false
			s.offset = Vector2(-8, -24) if spec[1] == "top" else Vector2(-8, 0)
			s.scale = Vector2(2, 2)
			s.flip_h = rng.randf() < 0.5
			s.position = holder.to_local(at)
			holder.add_child(s)
			placed += 1
			if placed >= 140:
				break


## A torch's light, its halo and its embers in the level's own flame colour.
static func _tint_torch(light: PointLight2D, flame: Color) -> void:
	light.color = light.color.lerp(flame, 0.8)
	for child in light.get_children():
		if child is CanvasItem and child.material is ShaderMaterial:
			var mat: ShaderMaterial = child.material.duplicate()
			mat.set_shader_parameter("glow_color", flame)
			child.material = mat
		if child is CPUParticles2D:
			child.color = Color(flame.lightened(0.2), child.color.a)


static func recolor_material(t: Dictionary, amount: float, stretch: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = RECOLOR
	mat.set_shader_parameter("dark", Color(t["tones"][0]))
	mat.set_shader_parameter("mid", Color(t["tones"][1]))
	mat.set_shader_parameter("light", Color(t["tones"][2]))
	mat.set_shader_parameter("amount", amount)
	mat.set_shader_parameter("stretch", stretch)
	return mat


static func _dress_atmosphere(atmosphere: Node, t: Dictionary) -> void:
	if not is_instance_valid(atmosphere):
		return
	for sprite in atmosphere.find_children("*", "Sprite2D", true, false):
		if sprite.material == null:
			sprite.material = recolor_material(t, 0.7, 1.4)
	for shaft in atmosphere.find_children("*", "LightShaft", true, false):
		shaft.color = t["shaft"]


## What drifts in the air in front of the camera: a field of motes that
## follows the view.
static func _add_air(level: Node, kind: String) -> void:
	var p := CPUParticles2D.new()
	p.name = "ThemeAir"
	p.texture = MOTE
	p.z_index = 35
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(340, 200)
	p.local_coords = false
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	p.material = add
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 0.12
	p.scale_amount_max = 0.3
	match kind:
		"fireflies":
			p.amount = 26
			p.lifetime = 7.0
			p.color = Color(0.85, 1.0, 0.55, 0.85)
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 12.0
			p.spread = 180.0
			p.direction = Vector2(0, -1)
		"snow":
			p.amount = 60
			p.lifetime = 9.0
			p.color = Color(0.9, 0.95, 1.0, 0.7)
			p.direction = Vector2(0.15, 1.0)
			p.spread = 10.0
			p.initial_velocity_min = 14.0
			p.initial_velocity_max = 26.0
			p.material = null
		"snow_still":
			p.amount = 50
			p.lifetime = 12.0
			p.color = Color(0.85, 0.92, 1.0, 0.6)
			p.direction = Vector2(0, 1)
			p.initial_velocity_min = 0.5
			p.initial_velocity_max = 1.5
			p.material = null
		"stars":
			p.amount = 30
			p.lifetime = 6.0
			p.color = Color(0.8, 0.85, 1.0, 0.9)
			p.initial_velocity_min = 1.0
			p.initial_velocity_max = 4.0
			p.spread = 180.0
		"frost":
			p.amount = 24
			p.lifetime = 8.0
			p.color = Color(0.85, 0.85, 1.0, 0.6)
			p.direction = Vector2(0.3, 1.0)
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 9.0
		"embers":
			p.amount = 34
			p.lifetime = 5.0
			p.color = Color(1.0, 0.6, 0.25, 0.9)
			p.direction = Vector2(0.1, -1.0)
			p.spread = 20.0
			p.initial_velocity_min = 14.0
			p.initial_velocity_max = 30.0
		"drips":
			p.amount = 20
			p.lifetime = 4.0
			p.color = Color(0.6, 0.92, 1.0, 0.6)
			p.direction = Vector2(0, 1)
			p.spread = 2.0
			p.initial_velocity_min = 60.0
			p.initial_velocity_max = 90.0
			p.gravity = Vector2(0, 80)
			p.material = null
		"dust":
			p.amount = 40
			p.lifetime = 9.0
			p.color = Color(1.0, 0.86, 0.55, 0.6)
			p.initial_velocity_min = 2.0
			p.initial_velocity_max = 6.0
			p.spread = 180.0
		"paper":
			p.amount = 18
			p.lifetime = 10.0
			p.color = Color(1.0, 0.82, 0.92, 0.75)
			p.direction = Vector2(0.4, 1.0)
			p.initial_velocity_min = 8.0
			p.initial_velocity_max = 16.0
			p.angular_velocity_min = -90.0
			p.angular_velocity_max = 90.0
			p.scale_amount_min = 0.25
			p.scale_amount_max = 0.45
			p.material = null
	var follower := AirFollower.new()
	follower.name = "ThemeAirFollower"
	level.add_child(follower)
	follower.add_child(p)


## Keeps the air's emitter on the camera.
class AirFollower extends Node2D:
	func _process(_delta: float) -> void:
		var cam := get_viewport().get_camera_2d()
		if cam:
			global_position = cam.get_screen_center_position()
