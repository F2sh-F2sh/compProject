class_name Lowbell
extends Node2D

## Lowbell at dusk: the village above the dungeon, where Echidna is met.
## The camera comes down from the silent belfry on the mountain to her door;
## she steps out, sees the wind chimes swinging without a sound, and takes the
## lane to Nan's cottage. The villagers she passes have lost words to the
## Hush. Knocking at Nan's door leads inside, to her cottage (NanCottage).
## Everything is built from the surface and town pixel-art packs (SurfaceArt),
## drawn at 1.5x; the people are the story's pixel sprites.

const FRAMES := preload("res://assets/sprites/Echidna/echidna_frames.tres")
const PUDDLE := preload("res://scenes/fx/puddle.tscn")
const WAYMARK := preload("res://scenes/puzzle/waymark.tscn")
## Chalk arrows low on the walls along the lane, pointing on to Nan's door.
const ARROWS_AT := [742.0, 962.0, 1640.0]
const SELF_PATH := "res://scenes/story/lowbell.tscn"

const FLOOR_Y := 534.0
const WIDTH := 2000.0
const BOUNDS := Rect2(0, 282, WIDTH, 324)
## Where the camera rests vertically; the backdrop is laid out around it.
const REST_Y := 444.0
const DOOR_X := 222.0
const START_X := 292.0
const STILE_X := 1030.0
const NAN_DOOR_X := 1836.0
## The packs' lamplight: a cool blue-white.
const LAMP := Color(0.7, 0.84, 1.0)
## The scale the packs are drawn at.
const S := SurfaceArt.LANE_SCALE

var player: CharacterBody2D
var camera: Camera2D
var intro_camera: Camera2D
var nan_door: Interactable
var intro_running := false
var leaving := false
var hopped := false

var _layers: Array = []
var _door_anim: AnimatedSprite2D
var _door_light: Sprite2D
var _nan_door_anim: AnimatedSprite2D
var _nan_light: Sprite2D
var _nan: AnimatedSprite2D
var _crow: AnimatedSprite2D
var _crow_flown := false
var _puppet: AnimatedSprite2D
var _thought: SpeechBubble
var _thought_target: Node2D
var _villagers: Array[Villager] = []
var _intro_tween: Tween
var _named := false
var _fade: ColorRect
var _objective: PanelContainer
var _hint: Label
var _start_x := START_X
var _walked := false
var _wind: AudioStreamPlayer


func _ready() -> void:
	# The scenery, puppets and the intro camera are tweened every drawn frame:
	# drawn as they are. Echidna and her camera move in physics steps and are
	# drawn between them (set in _build_player)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_tree().paused = false
	AudioDirector.reset_combat()
	AudioDirector.fade_ambience(-40.0, 2.0)
	var dusk := CanvasModulate.new()
	dusk.color = Color(0.58, 0.58, 0.72)
	add_child(dusk)
	_build_backdrop()
	_build_street()
	_build_ground()
	_build_people()
	_build_player()
	_build_post_and_menu()
	_build_ui()
	_start_wind()
	GameState.set_checkpoint(SELF_PATH, "lowbell.start")
	if GameState.has_flag("lowbell.intro_seen"):
		_begin_play()
	else:
		_play_intro()


func _exit_tree() -> void:
	AudioDirector.fade_ambience(AudioDirector.AMBIENCE_DB, 1.5)


# ------------------------------------------------------------------ the backdrop

## A backdrop layer that moves `scroll` as far as the camera does (0 = fixed
## to the screen, 1 = part of the world). Unshaded layers keep their own
## colours under the dusk.
func _layer(layer_name: String, scroll: float, z: int, unshaded := true) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	layer.z_index = z
	if unshaded:
		layer.material = MagicLight.unshaded()
	add_child(layer)
	_layers.append([layer, scroll])
	return layer


## Children drawn with no material of their own take the layer's.
func _share_material(layer: Node2D) -> void:
	for child in layer.find_children("*", "CanvasItem", true, false):
		if child.material == null:
			child.use_parent_material = true


## The distance, from the surface pack's parallax paintings: the night sky
## and moon, the hills with the monastery on its crag, the woods, and the
## far rooftops of Lowbell.
func _build_backdrop() -> void:
	# (This layer is fixed to the screen: x is from the screen's middle, and
	# y from REST_Y - 162 to REST_Y + 162 is what shows)
	var sky := _layer("Sky", 0.0, -40)
	SurfaceArt.backdrop(sky, "sky", Vector2(-845, REST_Y - 250), S, 1280)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-600 / S, (REST_Y - 162) / S, 1200 / S, 130 / S)
	stars.count = 60
	stars.seed_value = 29
	stars.scale = Vector2(S, S)
	sky.add_child(stars)
	# One by one, the stars go out over Lowbell
	var fading := create_tween()
	fading.tween_property(stars, "fade", 0.8, 240.0)
	# Clouds drifting past the moon, and now and then a bat
	for spec in [["cloud_a", Vector2(-240, REST_Y - 104), 90.0], ["cloud_b", Vector2(60, REST_Y - 136), 120.0],
			["cloud_c", Vector2(260, REST_Y - 88), 75.0]]:
		var cloud := SurfaceArt.sprite(sky, spec[0], spec[1], S)
		cloud.modulate.a = 0.28
		var drift := create_tween().set_loops()
		drift.tween_property(cloud, "position:x", cloud.position.x + spec[2], 40.0).set_trans(Tween.TRANS_SINE)
		drift.tween_property(cloud, "position:x", cloud.position.x, 40.0).set_trans(Tween.TRANS_SINE)
	for k in 3:
		var bat := StoryNodes.Flyer.new()
		bat.setup(["bat_up", "bat_flat", "bat_up", "bat_rest"], 9.0)
		bat.scale = Vector2(S, S)
		bat.from = Vector2(-440 - k * 26, REST_Y - 110 + k * 12)
		bat.to = Vector2(440 - k * 26, REST_Y - 140 + k * 10)
		bat.seconds = 9.0
		bat.wait = 14.0
		bat.delay = 5.0 + k * 0.5
		sky.add_child(bat)
	_share_material(sky)

	var hills := _layer("Hills", 0.08, -36)
	# (Drawn at 1x, smaller than the lane, so they read as far away)
	SurfaceArt.backdrop(hills, "hills", Vector2(-858, 165), 1.0, 640 * 3)
	_share_material(hills)
	var woods := _layer("Woods", 0.3, -32)
	var trees := SurfaceArt.backdrop(woods, "woods", Vector2(-1000, 248), 1.0, 640 * 4)
	trees.modulate = Color(0.86, 0.86, 0.95)
	_share_material(woods)
	var rooftops := _layer("Rooftops", 0.45, -28)
	SurfaceArt.backdrop(rooftops, "town", Vector2(-800, 224), 1.0, 640 * 4)
	_share_material(rooftops)


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		var center := cam.get_screen_center_position()
		for entry in _layers:
			entry[0].position = (center - Vector2(0, REST_Y)) * (1.0 - entry[1])
	if is_instance_valid(_thought) and is_instance_valid(_thought_target):
		_thought.position = _thought_target.global_position + Vector2(0, -52)
		# A villager speaking takes the stage; her own thought gives way
		if _thought.is_showing():
			for v in _villagers:
				if v.bubble.is_showing():
					_thought.hide_bubble()
					break
	_crow_watch()
	_update_hints()


# ------------------------------------------------------------------ the lane

## The lane, from the town pack's houses and the surface pack's props.
func _build_street() -> void:
	var street := Node2D.new()
	street.name = "Street"
	street.z_index = -5
	add_child(street)
	SurfaceArt.sprite(street, "tree_small", Vector2(34, FLOOR_Y + 2))
	# Echidna's house, and her door
	_house(street, "house_medium", DOOR_X, [Vector2(22, 56)])
	_door_anim = _opening_door(street, "door_echidna", DOOR_X, "house_medium", Vector2(39, 49))
	_door_light = StoryPaint.glow(street, Vector2(DOOR_X, FLOOR_Y - 20), 40.0, LAMP, 0.8)
	_door_light.modulate.a = 0.0
	# The wind chimes on their post, swinging without a sound
	_chimes(street, 348.0)
	_lamp(street, 486.0)
	# The bakery
	_house(street, "house_shop", 706.0, [Vector2(61, 66)])
	SurfaceArt.sprite(street, "barrel", Vector2(800, FLOOR_Y + 1))
	SurfaceArt.sprite(street, "barrel", Vector2(822, FLOOR_Y + 1))
	SurfaceArt.sprite(street, "crate", Vector2(842, FLOOR_Y + 1))
	# A house gone quiet: no lights at all
	_house(street, "house_ruined", 928.0, [])
	# The well, with a crow on its roof, and the signpost for the mountain
	SurfaceArt.sprite(street, "signpost", Vector2(1118, FLOOR_Y + 1))
	SurfaceArt.sprite(street, "well", Vector2(1190, FLOOR_Y + 1))
	_crow = SurfaceArt.animated(street, ["crow"], Vector2(1190, FLOOR_Y - 56), 1.0)
	_crow.name = "Crow"
	# The square: a little shrine bell under an old arch, silent too
	SurfaceArt.sprite(street, "arch", Vector2(1276, FLOOR_Y + 1))
	var hang := Node2D.new()
	hang.name = "ShrineBell"
	hang.position = Vector2(1276, FLOOR_Y - 69)
	street.add_child(hang)
	SurfaceArt.sprite(hang, "shrine_bell", Vector2(0, 14 * S))
	var sway := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.tween_property(hang, "rotation", 0.06, 2.1)
	sway.tween_property(hang, "rotation", -0.06, 2.1)
	_lamp(street, 1466.0)
	SurfaceArt.sprite(street, "cart", Vector2(1522, FLOOR_Y + 1))
	_house(street, "house_tower", 1600.0, [Vector2(26, 31), Vector2(25, 71)])
	_lamp(street, 1690.0)
	# Nan's cottage, the biggest on the lane
	_house(street, "house_big", NAN_DOOR_X + 1.5, [Vector2(54, 44), Vector2(27, 88)])
	_nan_door_anim = _opening_door(street, "door_nan", NAN_DOOR_X + 1.5, "house_big", Vector2(45, 76))
	_nan_light = StoryPaint.glow(street, Vector2(NAN_DOOR_X, FLOOR_Y - 22), 46.0, LAMP, 0.9)
	_nan_light.modulate.a = 0.0
	_nan = SurfaceArt.animated(street, "nan", Vector2(NAN_DOOR_X, FLOOR_Y - 1), 0.0)
	_nan.name = "Nan"
	_nan.flip_h = true
	_nan.stop()
	_nan.visible = false
	SurfaceArt.sprite(street, "tree_big", Vector2(1968, FLOOR_Y + 2))
	SurfaceArt.sprite(street, "fence", Vector2(1934, FLOOR_Y + 1))
	SurfaceArt.sprite(street, "fence_broken", Vector2(1985, FLOOR_Y + 1))
	# Chalk arrows on the walls: the way to Nan's
	for x in ARROWS_AT:
		var mark: Node2D = WAYMARK.instantiate()
		mark.position = Vector2(x, FLOOR_Y - 44)
		add_child(mark)
	# Puddles in the lane
	for spec in [[562.0, 60.0], [1350.0, 84.0]]:
		var puddle: Node2D = PUDDLE.instantiate()
		puddle.position = Vector2(spec[0], FLOOR_Y)
		puddle.set("width", spec[1])
		add_child(puddle)
	# Leaves blowing along the lane
	var leaves := StoryNodes.Leaves.new()
	leaves.name = "Leaves"
	leaves.area = Rect2(-40 / S, (FLOOR_Y - 90) / S, (WIDTH + 80) / S, 70 / S)
	leaves.count = 14
	leaves.speed = 34.0
	leaves.scale = Vector2(S, S)
	leaves.z_index = 2
	add_child(leaves)


## A house from the town pack, standing on the lane at `x` (its middle);
## `lit` lists its lit windows (art pixels from its top-left), which glow.
func _house(parent: Node, house: String, x: float, lit: Array) -> Sprite2D:
	var s := SurfaceArt.sprite(parent, house, Vector2(x, FLOOR_Y + 2))
	var top_left := s.position + s.offset * S
	for w in lit:
		var at: Vector2 = top_left + w * S
		StoryPaint.glow(parent, at, 18.0, LAMP, 0.55)
		_light(at, LAMP, 0.35, 0.7)
	return s


## A house's door that can swing open (frames cut from the house itself by
## tools/generate_story_sprites.gd); hidden while shut.
func _opening_door(parent: Node, frames_name: String, x: float, house: String, door_at: Vector2) -> AnimatedSprite2D:
	var size := SurfaceArt.size_of(house)
	var top_left := Vector2(x - floorf(size.x / 2.0) * S, FLOOR_Y + 2 - size.y * S)
	var door := AnimatedSprite2D.new()
	door.name = frames_name.to_pascal_case()
	door.sprite_frames = SurfaceArt.frames(frames_name, 0.0)
	door.centered = false
	door.position = top_left + door_at * S
	door.scale = Vector2(S, S)
	door.visible = false
	parent.add_child(door)
	return door


func _light(at: Vector2, color: Color, energy: float, reach: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = LightTextures.radial(256)
	light.color = color
	light.energy = energy
	light.texture_scale = reach
	light.position = at
	add_child(light)
	return light


## One of the town pack's lamp posts, its two lanterns lit.
func _lamp(parent: Node, x: float) -> void:
	var post := SurfaceArt.sprite(parent, "lamp_post", Vector2(x, FLOOR_Y + 1))
	var top_left := post.position + post.offset * S
	for lantern in [Vector2(4.5, 26.5), Vector2(26.5, 26.5)]:
		StoryPaint.glow(parent, top_left + lantern * S, 22.0, LAMP, 0.6)
	_light(top_left + Vector2(15.5, 28) * S, LAMP, 0.55, 1.2)


func _chimes(parent: Node, x: float) -> void:
	var post := SurfaceArt.sprite(parent, "chime_post", Vector2(x, FLOOR_Y + 1))
	var top_left := post.position + post.offset * S
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 5:
		# Each tube swings from the top of its string
		var tube := Node2D.new()
		tube.name = "Chime%d" % k
		tube.add_to_group("wind_chime")
		tube.position = top_left + Vector2(10.5 + k * 4.0, 6.0 + (k % 3)) * S
		parent.add_child(tube)
		var piece := Sprite2D.new()
		piece.texture = SurfaceArt.tex("chime_tube")
		piece.centered = false
		piece.offset = Vector2(-1.5, 0)
		piece.scale = Vector2(S, S)
		tube.add_child(piece)
		var swing := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		swing.tween_interval(rng.randf() * 0.6)
		swing.tween_property(tube, "rotation", 0.14, 1.3 + rng.randf() * 0.5)
		swing.tween_property(tube, "rotation", -0.1, 1.3 + rng.randf() * 0.5)


## The crow on the well takes off when Echidna comes near.
func _crow_watch() -> void:
	if not is_instance_valid(_crow) or _crow_flown or not is_instance_valid(player) or not player.visible:
		return
	if absf(player.global_position.x - _crow.global_position.x) > 90.0:
		return
	_crow_flown = true
	_crow.sprite_frames = SurfaceArt.frames(["crow_fly_a", "crow_fly_b"], 10.0)
	_crow.play(&"default")
	var away := create_tween().set_parallel()
	away.tween_property(_crow, "position", _crow.position + Vector2(260, -220), 2.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	away.tween_property(_crow, "modulate:a", 0.0, 2.4).set_delay(0.8)


# ------------------------------------------------------------------ the ground

func _build_ground() -> void:
	var body := StaticBody2D.new()
	body.name = "Ground"
	body.collision_layer = 2
	body.collision_mask = 0
	body.add_to_group("world")
	add_child(body)
	_box(body, Rect2(-200, FLOOR_Y, WIDTH + 400, 300))
	_box(body, Rect2(-40, 0, 40, FLOOR_Y + 10))
	_box(body, Rect2(WIDTH, 0, 40, FLOOR_Y + 10))
	# The fallen log across the lane (the "stile" she hops)
	_box(body, Rect2(STILE_X - 24, FLOOR_Y - 19, 48, 19))

	var ground := Node2D.new()
	ground.name = "Earth"
	ground.z_index = -4
	add_child(ground)
	# Grass and earth all along the lane (mostly plain earth; now and then a
	# buried stone)
	var earth := ["dirt_a", "dirt_b", "dirt_c", "dirt_a", "dirt_b", "dirt_c", "dirt_a", "dirt_b", "dirt_c", "dirt_stones"]
	var soil := SurfaceArt.ground(ground, -300.0, WIDTH + 300.0, FLOOR_Y, S, 4, ["grass_a", "grass_b", "grass_c"], earth, 17)
	# ...and a single old skull, deep down, for anyone who looks
	soil.set_cell(Vector2i(46, 3), 0, SurfaceArt.TILES["dirt_skull"])
	SurfaceArt.sprite(ground, "log", Vector2(STILE_X, FLOOR_Y + 2))
	# Tufts of grass and a few flowers along the verge, clear of the doors
	var tufts := StoryNodes.Tufts.new()
	tufts.name = "Tufts"
	tufts.x0 = -20.0 / S
	tufts.x1 = (WIDTH + 20.0) / S
	tufts.y = (FLOOR_Y + 3.0) / S
	tufts.skip = [Vector2((DOOR_X - 24) / S, (DOOR_X + 24) / S), Vector2((NAN_DOOR_X - 26) / S, (NAN_DOOR_X + 26) / S),
		Vector2((STILE_X - 30) / S, (STILE_X + 30) / S)]
	tufts.scale = Vector2(S, S)
	tufts.z_index = 1
	ground.add_child(tufts)


func _box(body: StaticBody2D, r: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = r.size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = r.get_center()
	body.add_child(collider)


# ------------------------------------------------------------------ people

func _build_people() -> void:
	var people := Node2D.new()
	people.name = "People"
	add_child(people)
	_villager(people, "Tam", "tam", 412.0, "Listen. The chimes used to {4} every evening. Now I can't even remember the word.")
	_villager(people, "Mira", "mira", 664.0, "Have you seen my... my {6}? Round. Wooden. For the dough. I had it this morning.")
	_villager(people, "Pip", "pip", 1084.0, "Nan says there used to be {5} up there. Lots and lots. Like spilled sugar.")
	_villager(people, "Edda", "edda", 1410.0, "The road up the mountain's been frozen shut for nine winters. Ever since the bell went {5}.")


func _villager(parent: Node, villager_name: String, sprite: String, x: float, line: String) -> Villager:
	var v := Villager.new()
	v.name = villager_name
	v.line = line
	v.sprite_name = sprite
	v.position = Vector2(x, FLOOR_Y + 1)
	parent.add_child(v)
	_villagers.append(v)
	return v


# ------------------------------------------------------------------ Echidna

func _build_player() -> void:
	player = load("res://scenes/Player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector2(START_X, FLOOR_Y - 2)
	player.z_index = 1
	player.collision_mask = 2
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.set_script(load("res://scripts/camera_bounds.gd"))
	camera.set("bounds", BOUNDS)
	camera.set("base_zoom", Vector2(2, 2))
	camera.zoom = Vector2(2, 2)
	player.add_child(camera)
	var aura := PointLight2D.new()
	aura.name = "PlayerLight"
	aura.texture = LightTextures.radial(256)
	aura.color = Color(0.8, 0.76, 1.0)
	aura.energy = 0.55
	aura.position = Vector2(0, -20)
	player.add_child(aura)
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child(player)
	intro_camera = Camera2D.new()
	intro_camera.name = "IntroCamera"
	intro_camera.zoom = Vector2(2, 2)
	add_child(intro_camera)
	_thought = SpeechBubble.new()
	_thought.thought = true
	add_child(_thought)


func _build_post_and_menu() -> void:
	var post := CanvasLayer.new()
	post.name = "PostFX"
	post.layer = 1
	post.set_script(load("res://scripts/post_fx.gd"))
	post.set("follows_brightness", false)
	var screen := ColorRect.new()
	screen.name = "Screen"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/dungeon_post.gdshader")
	# Out under the sky: little lantern gloom, a grey mist, and the colour
	# already draining out of everything (the Hush)
	mat.set_shader_parameter("fog_floor_y", FLOOR_Y)
	mat.set_shader_parameter("lantern_outer", 440.0)
	mat.set_shader_parameter("lantern_darkness", 0.14)
	mat.set_shader_parameter("fog_strength", 0.14)
	mat.set_shader_parameter("fog_color", Color(0.46, 0.47, 0.56))
	mat.set_shader_parameter("saturation", 0.6)
	mat.set_shader_parameter("vignette", 0.36)
	screen.material = mat
	post.add_child(screen)
	add_child(post)
	var pause := CanvasLayer.new()
	pause.name = "PauseMenu"
	pause.set_script(load("res://scripts/ui/pause_menu.gd"))
	add_child(pause)


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	var font := StoryPaint.label_font()
	_objective = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.1, 0.82)
	style.border_color = Color(0.5, 0.4, 0.75, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_objective.add_theme_stylebox_override("panel", style)
	_objective.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_objective.offset_left = -300
	_objective.offset_right = -18
	_objective.offset_top = 18
	_objective.modulate.a = 0.0
	ui.add_child(_objective)
	var goal := Label.new()
	goal.text = "Go to Grandma Nan's cottage, at the end of the lane. She will know what to do."
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal.add_theme_font_override("font", font)
	goal.add_theme_font_size_override("font_size", 13)
	goal.add_theme_color_override("font_color", Color("e4ddf2"))
	_objective.add_child(goal)

	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_left = -260
	_hint.offset_right = 260
	_hint.offset_top = -70
	_hint.offset_bottom = -44
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_override("font", font)
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", Color("e4ddf2"))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hint.add_theme_constant_override("outline_size", 5)
	_hint.modulate.a = 0.0
	ui.add_child(_hint)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0.01, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_fade)



func _start_wind() -> void:
	var stream := load("res://assets/audio/sfx/wind_loop.wav") as AudioStreamWAV
	if stream == null:
		return
	stream = stream.duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2
	_wind = AudioStreamPlayer.new()
	_wind.name = "Wind"
	_wind.stream = stream
	_wind.bus = Settings.AMBIENT_BUS
	_wind.volume_db = -22.0
	add_child(_wind)
	_wind.play()


# ------------------------------------------------------------------ the opening

## The camera comes down from the mountain; her door opens; she steps out,
## notices the silent chimes, and her name comes up. Any press skips ahead.
func _play_intro() -> void:
	intro_running = true
	player.visible = false
	player.lock_controls(true)
	intro_camera.position = Vector2(DOOR_X + 150, REST_Y - 300)
	intro_camera.make_current()
	_puppet = AnimatedSprite2D.new()
	_puppet.name = "EchidnaIntro"
	_puppet.sprite_frames = FRAMES
	_puppet.offset = FRAMES.get_meta(&"sprite_offset", Vector2(0, -32))
	_puppet.scale = Vector2(0.812, 0.812)
	_puppet.material = player.get_node("AnimatedSprite2D").material
	_puppet.position = Vector2(DOOR_X, FLOOR_Y)
	_puppet.z_index = 1
	_puppet.visible = false
	add_child(_puppet)
	_puppet.play(&"idle")
	var t := create_tween()
	_intro_tween = t
	t.tween_property(_fade, "color:a", 0.0, 1.6)
	t.parallel().tween_property(intro_camera, "position", Vector2(DOOR_X + 116, REST_Y), 4.6) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(_open_door)
	t.tween_interval(0.55)
	t.tween_callback(func(): _puppet.visible = true; _puppet.speed_scale = 0.7; _puppet.play(&"run"))
	t.tween_property(_puppet, "position:x", START_X, 0.95)
	t.tween_callback(func(): _puppet.speed_scale = 1.0; _puppet.play(&"idle"))
	t.tween_interval(0.55)
	t.tween_callback(func(): _puppet.flip_h = true)
	t.tween_interval(0.7)
	t.tween_callback(func(): _puppet.flip_h = false; _say("The Hush is here. Even the chimes have gone quiet...", _puppet))
	t.tween_interval(2.8)
	t.tween_callback(func(): _thought.hide_bubble(); _show_name(); _close_door())
	t.tween_interval(3.0)
	t.tween_callback(_begin_play)


func _open_door() -> void:
	Sfx.play("door_creak", Vector2(DOOR_X, FLOOR_Y - 20), -6.0, 0.05)
	_swing(_door_anim, true)
	create_tween().tween_property(_door_light, "modulate:a", 1.0, 0.5)


func _close_door() -> void:
	_swing(_door_anim, false)
	create_tween().tween_property(_door_light, "modulate:a", 0.0, 0.6)


## A door swinging open (ajar, then open) or shut again (ajar, then gone).
func _swing(door: AnimatedSprite2D, opening: bool) -> void:
	if not is_instance_valid(door):
		return
	var t := create_tween()
	t.tween_callback(func(): door.visible = true; door.frame = 0)
	t.tween_interval(0.16)
	t.tween_callback(func(): door.visible = opening; door.frame = 1)


func _show_name() -> void:
	if _named:
		return
	_named = true
	TitleCard.show_card(self, "A WITCH OF LOWBELL", "Echidna", "", 2.4)


## A short thought over someone's head.
func _say(text: String, over: Node2D, seconds := 2.8) -> void:
	_thought.text = text
	_thought_target = over
	_thought.position = over.global_position + Vector2(0, -52)
	_thought.show_bubble()
	get_tree().create_timer(seconds).timeout.connect(func():
		if _thought.text == text:
			_thought.hide_bubble())


## Hands Echidna to the player, where the opening left her.
func _begin_play() -> void:
	var from_intro := intro_running
	intro_running = false
	if _intro_tween:
		_intro_tween.kill()
	var at := Vector2(START_X, FLOOR_Y - 2)
	var face_left := false
	if is_instance_valid(_puppet):
		at = Vector2(_puppet.position.x, FLOOR_Y - 2)
		face_left = _puppet.flip_h
		_puppet.queue_free()
	if from_intro:
		_show_name()
		_close_door()
	player.teleport_to(at)
	player.animated_sprite.flip_h = face_left
	player.visible = true
	# (A moment later, so the press that skipped the opening isn't also a jump)
	get_tree().create_timer(0.15).timeout.connect(func():
		if not leaving:
			player.unlock_controls())
	camera.make_current()
	camera.call("snap")
	_fade.color.a = 0.0
	_start_x = at.x
	GameState.set_flag("lowbell.intro_seen")
	GameState.save_game()
	var show := create_tween()
	show.tween_interval(0.6)
	show.tween_property(_objective, "modulate:a", 1.0, 0.6)
	get_tree().create_timer(1.4).timeout.connect(func():
		if not leaving:
			_say("Nan will know what's happening.", player, 3.0))
	nan_door = Interactable.new()
	nan_door.name = "NanDoor"
	nan_door.verb = "Knock"
	nan_door.echo_can_use = false
	nan_door.size = Vector2(44, 64)
	nan_door.position = Vector2(NAN_DOOR_X, FLOOR_Y)
	add_child(nan_door)
	nan_door.interacted.connect(func(_who): knock())


func _update_hints() -> void:
	if intro_running or leaving or not player.visible:
		_hint.modulate.a = move_toward(_hint.modulate.a, 0.0, 0.05)
		return
	var x := player.global_position.x
	if not _walked and absf(x - _start_x) > 50.0:
		_walked = true
	if x > STILE_X + 20.0:
		hopped = true
	var text := ""
	if not _walked:
		text = "%s / %s  walk" % [InputLabels.primary("move_left"), InputLabels.primary("move_right")]
	elif not hopped and x > STILE_X - 130.0 and x < STILE_X:
		text = "%s  jump" % InputLabels.primary("jump")
	if text != "":
		_hint.text = text
	_hint.modulate.a = move_toward(_hint.modulate.a, 0.9 if text != "" else 0.0, 0.05)


# ------------------------------------------------------------------ leaving

func next_scene() -> String:
	return Journey.COTTAGE


## Knocking at Nan's door: she answers, and the story moves on.
func knock() -> void:
	if leaving:
		return
	leaving = true
	nan_door.enabled = false
	player.lock_controls(false)
	_thought.hide_bubble()
	var t := create_tween()
	t.tween_property(_objective, "modulate:a", 0.0, 0.4)
	for i in 3:
		t.tween_callback(Sfx.play.bind("knock", Vector2(NAN_DOOR_X, FLOOR_Y - 20), -2.0, 0.08))
		t.tween_interval(0.34)
	t.tween_interval(0.8)
	t.tween_callback(Sfx.play.bind("door_creak", Vector2(NAN_DOOR_X, FLOOR_Y - 20), -5.0, 0.05))
	t.tween_callback(_swing.bind(_nan_door_anim, true))
	t.tween_property(_nan_light, "modulate:a", 1.0, 0.5)
	# Nan in the doorway, her lantern lit
	t.tween_callback(func(): _nan.visible = true; _nan.frame = 0)
	t.tween_interval(1.4)
	t.tween_property(_fade, "color:a", 1.0, 1.2)
	t.tween_callback(_leave)


func _leave() -> void:
	SceneFade.change(get_tree(), next_scene(), 0.0)


func _unhandled_input(event: InputEvent) -> void:
	var press: bool = event.is_action_pressed("jump") or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")
	if not press:
		return
	if intro_running:
		get_viewport().set_input_as_handled()
		_begin_play()
	elif leaving and _fade.color.a >= 0.99:
		get_viewport().set_input_as_handled()
		_leave()


static func _circle(c: Vector2, r: float, n := 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n:
		pts.append(c + Vector2.from_angle(TAU * k / n) * r)
	return pts
