extends Node2D

## Three authored scenes between Lowbell and the existing Undercroft.
## All terrain and interactions use the original player and collision layers.
enum Stage { COTTAGE, APPROACH, WELL }
@export var stage: Stage = Stage.COTTAGE

const DIALOGUE := preload("res://scripts/story/story_dialogue.gd")
const COTTAGE := "res://scenes/story/nan_lantern_cottage.tscn"
const APPROACH := "res://scenes/story/pilgrims_path.tscn"
const WELL := "res://scenes/story/well_descent.tscn"
const TUTORIAL := "res://scenes/tutorial/tutorial_level.tscn"
const CHAPTER := "res://scenes/chapter/chapter_1.tscn"
const GOLD := Color("edbc78")
const VIOLET := Color("9989d7")
const FLOOR := 520.0
## The pilgrim road's camera rests with its centre here (the floor sits low on the
## screen, like Lowbell); its backdrop is laid out around it.
const REST_Y := 430.0

var player: CharacterBody2D
var camera: Camera2D
var dialogue: CanvasLayer
var objective: Label
var bridge_open := false
var sconces_lit := 0
var leaving := false
var _width := 960.0
var _time := 0.0
var _fade: ColorRect
var _heading: Label
var _bridge: Node2D
var _bridge_body: StaticBody2D
var _gate: StaticBody2D
var _ward_door: Sprite2D
var _exit: Interactable
var _lantern: Sprite2D
var _wisp: Sprite2D
var _sconces: Array = []
var _checkpoint := Vector2(120, FLOOR - 2)
var _safety_running := false
var _resume_when_released := false
var _cottage_framing := 1.35
var _layers: Array = []
var _winch: Sprite2D
var _bridge_rope: Line2D

func _ready() -> void:
	# The scenery, the bridge, the wisp and the cottage camera move every drawn
	# frame: drawn as they are. Echidna and her camera move in physics steps and
	# are drawn between them (set in _build_player)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_tree().paused = false
	AudioDirector.reset_combat()
	AudioDirector.duck(-5.0, 0.8)
	_width = [960.0, 2448.0, 1968.0][stage]
	var darkness := CanvasModulate.new()
	darkness.name = "Darkness"
	darkness.color = [Color("b49ca3"), Color("7e819e"), Color("6a637f")][stage]
	add_child(darkness)
	if stage == Stage.COTTAGE:
		_build_cottage()
	elif stage == Stage.APPROACH:
		_build_approach()
	else:
		_build_well()
	_build_player()
	_build_ui()
	if stage == Stage.COTTAGE:
		camera.queue_free()
		camera = Camera2D.new()
		camera.position = Vector2(480, 435)
		camera.zoom = Vector2(1.35, 1.35)
		add_child(camera)
		camera.make_current()
	var menu := PauseMenu.new()
	add_child(menu)
	var scene_path: String = [COTTAGE, APPROACH, WELL][stage]
	GameState.set_checkpoint(scene_path, GameState.get_checkpoint_for(scene_path) if GameState.get_checkpoint_for(scene_path) != "" else "prologue.%d" % stage)
	if stage == Stage.APPROACH and GameState.has_flag("story.bridge_lowered"):
		bridge_open = true
		_bridge.rotation = 0
		_bridge_body.collision_layer = 2
		objective.text = "The pilgrim road\nRead the seal on the Belfry's gate."
		if GameState.has_flag("story.belfry_read"):
			objective.text = "A way beneath the seal\nFind the old well east of the gate."
	if stage == Stage.WELL:
		for i in 2:
			if GameState.has_flag("story.lamp.%d" % i):
				_restore_sconce(i)
		_update_lamp_goal()
		if sconces_lit == 2:
			_open_ward(false)
	var fade := create_tween()
	fade.tween_property(_fade, "color:a", 0.0, 0.8)
	fade.tween_callback(_opening)
	queue_redraw()

func _exit_tree() -> void:
	AudioDirector.duck(0.0, 0.8)

func _build_player() -> void:
	player = preload("res://scenes/player/player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector2(332, FLOOR - 2) if stage == Stage.COTTAGE else _checkpoint
	player.collision_mask = 2
	player.z_index = 3
	camera = CameraBounds.new()
	camera.bounds = Rect2(0, REST_Y - 162.0, _width, 324) if stage == Stage.APPROACH else Rect2(0, 200, _width, 640)
	# (in the well she stands low on the screen, so it shows the way on, not the floor)
	if stage == Stage.WELL:
		camera.position = Vector2(0, -56)
	camera.base_zoom = Vector2(2, 2)
	player.add_child(camera)
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child(player)
	var aura := PointLight2D.new()
	aura.texture = LightTextures.radial(256)
	aura.position = Vector2(0, -22)
	aura.color = GOLD
	aura.energy = 0.75
	player.add_child(aura)
	_lantern = SurfaceArt.sprite(player, "desk_lantern", Vector2(19, -17), 0.65)
	_lantern.z_index = 1
	_lantern.visible = stage != Stage.COTTAGE
	player.died.connect(func(): SceneFade.restart(get_tree()))
	player.lock_controls(true)

func _solid(rect: Rect2, label: String = "Terrain", active := true) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.name = label
	body.position = rect.get_center()
	body.collision_layer = 2 if active else 0
	body.collision_mask = 0
	body.add_to_group("world")
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	return body

func _terrain(x: float, y: float, width: float, outdoor := false) -> void:
	if outdoor:
		SurfaceArt.ground(self, x, x + width, y, 1.5, 7)
	else:
		# The descending camera can see below earlier landings. Paint stone
		# through its lower bound, while keeping the authored collision depth.
		var rows := maxi(7, ceili((864.0 - y) / 24.0)) if stage == Stage.WELL else 7
		SurfaceArt.tile_block(self, Vector2(x, y), int(ceil(width / 24)), rows, ["bricks_a", "bricks_b", "bricks_roots"], 1.5, int(x + y))
	_solid(Rect2(x, y, width, 168))

func _use(at: Vector2, verb: String, callback: Callable) -> Interactable:
	var zone := Interactable.new()
	zone.position = at
	zone.verb = verb
	zone.echo_can_use = false
	zone.size = Vector2(88, 80)
	zone.interacted.connect(func(_who): callback.call())
	add_child(zone)
	return zone

func _light(at: Vector2, color: Color, energy := 0.7) -> PointLight2D:
	var light := PointLight2D.new()
	light.position = at
	light.texture = LightTextures.radial(256)
	light.color = color
	light.energy = energy
	add_child(light)
	# Keep the painted halo under the lamp's visibility, including unlit lamps.
	StoryPaint.glow(light, Vector2.ZERO, 75, Color(color, 0.35), 0.55)
	return light

func _build_cottage() -> void:
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([Vector2(0, 100), Vector2(_width, 100), Vector2(_width, 800), Vector2(0, 800)])
	background.color = Color("211c2c")
	background.z_index = -30
	add_child(background)
	_terrain(0, FLOOR, _width)
	_solid(Rect2(-30, 200, 30, 500))
	_solid(Rect2(_width, 200, 30, 500))
	var wall := SurfaceArt.tile_block(self, Vector2(66, 214), 35, 13, ["bricks_a", "bricks_b"], 1.5, 8)
	wall.modulate = Color("8e7878")
	wall.z_index = -20
	for x in [114, 258, 702, 846]:
		SurfaceArt.sprite(self, "win_arch_dark", Vector2(x, 372), 3.0)
		StoryPaint.glow(self, Vector2(x, 348), 36, Color(0.5, 0.6, 0.85, 0.25))
	SurfaceArt.sprite(self, "door_tall", Vector2(798, FLOOR), 1.5)
	SurfaceArt.sprite(self, "cart", Vector2(208, FLOOR), 1.5)
	SurfaceArt.sprite(self, "log", Vector2(574, FLOOR), 1.5)
	SurfaceArt.animated(self, "nan", Vector2(542, FLOOR), 3, 1.0, true, true)
	SurfaceArt.animated(self, "candle", Vector2(660, 445), 6, 2)
	_light(Vector2(628, 450), GOLD, 1.6)
	StoryPaint.motes(self, Rect2(500, 325, 250, 185), Color(1, 0.72, 0.42, 0.35), 22)
	_use(Vector2(798, FLOOR), "Leave for the mountain", func(): _transition(APPROACH))

## The pilgrim road at night, in the surface pack's art like Lowbell: the moon
## and stars, the monastery on its crag (the Belfry, far up the mountain), the
## bare woods, then the road itself with its old waymarks and graves, the
## ravine and the bridge the pilgrims raised behind them, the frozen outer gate,
## and the bellkeepers' well beyond it.
func _build_approach() -> void:
	var sky := _parallax("Sky", 0.0, -40)
	# (the moon sits right of centre, clear of the heading)
	SurfaceArt.backdrop(sky, "sky", Vector2(-600, REST_Y - 262), 1.5, 1280)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-600 / 1.5, (REST_Y - 162) / 1.5, 1200 / 1.5, 130 / 1.5)
	stars.count = 60
	stars.fade = 0.55
	stars.scale = Vector2(1.5, 1.5)
	sky.add_child(stars)
	for spec in [["cloud_a", Vector2(-260, REST_Y - 110)], ["cloud_c", Vector2(220, REST_Y - 92)]]:
		SurfaceArt.sprite(sky, spec[0], spec[1], 1.5).modulate.a = 0.25
	var hills := _parallax("Hills", 0.08, -36)
	SurfaceArt.backdrop(hills, "hills", Vector2(-700, REST_Y - 279), 1.0, 640 * 3)
	var woods := _parallax("Woods", 0.3, -32)
	SurfaceArt.backdrop(woods, "woods", Vector2(-900, REST_Y - 196), 1.0, 640 * 5).modulate = Color(0.8, 0.8, 0.92)
	for layer in [sky, hills, woods]:
		for child in layer.find_children("*", "CanvasItem", true, false):
			if child.material == null:
				child.use_parent_material = true

	# the road and the ravine (the ravine floor is far below, out of sight)
	_terrain(0, FLOOR, 816, true)
	_terrain(1056, FLOOR, 1392, true)
	_terrain(816, 696, 240)
	_solid(Rect2(-24, 200, 24, 700))
	_solid(Rect2(_width, 200, 24, 700))
	var tufts := StoryNodes.Tufts.new()
	tufts.x0 = 0.0
	tufts.x1 = _width / 1.5
	tufts.y = (FLOOR + 3.0) / 1.5
	tufts.skip = [Vector2(800 / 1.5, 1072 / 1.5)]
	tufts.scale = Vector2(1.5, 1.5)
	tufts.z_index = 1
	add_child(tufts)
	# roots hanging into the ravine from both lips
	for x in [804.0, 1064.0]:
		SurfaceArt.sprite(self, "vine_long", Vector2(x, FLOOR + 66), 1.5)

	# Leaving Lowbell: a signpost, a fence, the graves of old pilgrims
	SurfaceArt.sprite(self, "signpost", Vector2(150, FLOOR + 1), 1.5)
	SurfaceArt.sprite(self, "fence_broken", Vector2(60, FLOOR + 1), 1.5)
	SurfaceArt.sprite(self, "tree_big", Vector2(330, FLOOR + 2), 1.5)
	for spec in [["grave_round", 470.0], ["grave_cross", 512.0], ["grave_celtic", 560.0], ["grave_broken", 600.0]]:
		SurfaceArt.sprite(self, spec[0], Vector2(spec[1], FLOOR + 1), 1.5)
	# The pilgrims' bridge: its winch on the near lip, lit by a road lamp
	SurfaceArt.sprite(self, "lamp_post", Vector2(686, FLOOR + 1), 1.5)
	_light(Vector2(694, FLOOR - 100), GOLD, 0.8)
	_winch = SurfaceArt.sprite(self, "bridge_winch", Vector2(752, FLOOR + 1), 1.5)
	_use(Vector2(752, FLOOR), "Lower the pilgrim bridge", lower_bridge)
	_bridge = Node2D.new()
	_bridge.position = Vector2(816, FLOOR)
	_bridge.rotation = -PI / 2
	add_child(_bridge)
	SurfaceArt.tile_row(_bridge, Vector2(0, -4), ["plank_l", "plank_m", "plank_m", "plank_m", "plank_m", "plank_m", "plank_m", "plank_m", "plank_m", "plank_r"], 1.5)
	_bridge_body = _solid(Rect2(816, FLOOR, 240, 16), "PilgrimBridge", false)
	# the rope from the winch's drum to the bridge's far end
	_bridge_rope = Line2D.new()
	_bridge_rope.width = 3.0
	_bridge_rope.texture = load("res://assets/sprites/story/rope.png")
	_bridge_rope.texture_mode = Line2D.LINE_TEXTURE_TILE
	_bridge_rope.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_bridge_rope.z_index = 1
	add_child(_bridge_rope)
	_update_rope()

	# Over the bridge: a shrine-ruin with a few rocky steps to climb for fun
	for spec in [Rect2(1248, 480, 96, 40), Rect2(1344, 450, 72, 70), Rect2(1416, 480, 72, 40)]:
		SurfaceArt.ground(self, spec.position.x, spec.end.x, spec.position.y, 1.5, int(ceil(spec.size.y / 24.0)), ["grass_a", "grass_b", "grass_c"], ["dirt_stones", "dirt_a", "dirt_b"], int(spec.position.x))
		_solid(spec)
	SurfaceArt.sprite(self, "wall_broken", Vector2(1210, FLOOR + 1), 1.5)
	SurfaceArt.sprite(self, "rock_big", Vector2(1520, FLOOR + 1), 1.5)
	for x in [1120, 1980]:
		SurfaceArt.sprite(self, "pillar", Vector2(x, FLOOR + 1), 1.5)
		SurfaceArt.sprite(self, "vine", Vector2(x + 4, FLOOR - 40), 1.5)

	# The Belfry's outer gate, sealed, frost grown through it
	SurfaceArt.sprite(self, "arch", Vector2(1760, FLOOR + 1), 3.0)
	SurfaceArt.sprite(self, "door_frost", Vector2(1760, FLOOR + 1), 2.5).modulate = Color(0.78, 0.82, 0.95)
	SurfaceArt.sprite(self, "frost_a", Vector2(1712, FLOOR + 1), 1.0).modulate = Color(0.8, 0.85, 1.0, 0.85)
	SurfaceArt.sprite(self, "frost_b", Vector2(1812, FLOOR + 1), 1.0, true).modulate = Color(0.8, 0.85, 1.0, 0.85)
	_light(Vector2(1760, 434), VIOLET, 0.7)
	_gate = _solid(Rect2(1728, 390, 64, 130), "SealedBelfry")
	# The sealed entrance is in the back wall; the road continues east in
	# front of it. It blocks entry to the Belfry, not travel to the well.
	_gate.collision_layer = 0
	_use(Vector2(1688, FLOOR), "Read the sealed gate", _gate_story)

	# The bellkeepers' well, east of the gate, and an old crypt
	SurfaceArt.sprite(self, "well", Vector2(2184, FLOOR + 1), 2.0)
	SurfaceArt.sprite(self, "crypt", Vector2(2350, FLOOR + 1), 1.5)
	SurfaceArt.sprite(self, "lantern", Vector2(2120, FLOOR + 1), 1.5)
	_light(Vector2(2120, FLOOR - 36), GOLD, 0.6)
	_exit = _use(Vector2(2184, FLOOR), "Climb down the old well", _well_story)
	_exit.enabled = GameState.has_flag("story.belfry_read")
	StoryPaint.motes(self, Rect2(1990, 330, 400, 210), Color(0.64, 0.65, 0.95, 0.3), 28)


## A backdrop layer that moves `scroll` as far as the camera does (0 = fixed
## to the screen, 1 = part of the world), unshaded so it keeps its colours.
func _parallax(layer_name: String, scroll: float, z: int) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	layer.z_index = z
	layer.material = MagicLight.unshaded()
	add_child(layer)
	_layers.append([layer, scroll])
	return layer


## The rope runs from the winch's drum to the bridge's far end.
func _update_rope() -> void:
	if _bridge_rope == null or _bridge == null:
		return
	var tip := _bridge.position + Vector2(236, -2).rotated(_bridge.rotation)
	_bridge_rope.points = PackedVector2Array([Vector2(752, FLOOR - 27), tip])
func _build_well() -> void:
	# The service passage descends through three landings. Drops are safe;
	# the checkpoint advances with the player, including after a restart.
	_terrain(0, 520, 576)
	_terrain(576, 592, 600)
	_terrain(1176, 664, 792)
	# Half-height steps make both lamps reachable again after walking past
	# one; no charged jump or tutorial knowledge is needed to backtrack.
	for at in [Vector2(576, 556), Vector2(1176, 628)]:
		SurfaceArt.tile_block(self, at, 2, 2, ["bricks_step", "bricks_a"], 1.5)
		_solid(Rect2(at, Vector2(48, 48)))
	_solid(Rect2(-24, 200, 24, 700))
	_solid(Rect2(_width, 200, 24, 700))
	SurfaceArt.tile_block(self, Vector2(0, 180), 82, 29, ["bricks_a", "bricks_b", "bricks_vines"], 1.5, 13).modulate = Color("373245")
	# Back wall must stay behind the terrain and the actors.
	get_child(get_child_count() - 1).z_index = -20
	for x in range(200, 1900, 192):
		var y := 520.0 if x < 576 else (592.0 if x < 1176 else 664.0)
		SurfaceArt.sprite(self, "pillar", Vector2(x, y), 1.5).modulate = Color("756980")
		SurfaceArt.sprite(self, "vine_long", Vector2(x + 20, y - 70), 1.5)
	for i in 2:
		var at := Vector2(420, 520) if i == 0 else Vector2(1050, 592)
		SurfaceArt.sprite(self, "wall_lantern", at + Vector2(0, -34), 1.5)
		var halo := _light(at + Vector2(0, -63), GOLD, 0.0)
		halo.visible = false
		var zone := _use(at, "Share Nan's lantern flame", func(): light_sconce(i))
		_sconces.append({"light": halo, "zone": zone, "lit": false})
	SurfaceArt.sprite(self, "arch", Vector2(1700, 664), 2.0)
	_ward_door = SurfaceArt.sprite(self, "door_tall", Vector2(1700, 664), 2.0)
	_gate = _solid(Rect2(1668, 550, 64, 114), "LanternWard")
	_use(Vector2(1634, 664), "Read the lamp ward", func():
		_talk([["Inscription", "Two lamps remember the way. Carry one flame between them, and the sleepers' door will open."]]))
	_exit = _use(Vector2(1860, 664), "Enter the Undercroft", _undercroft_story)
	_exit.enabled = false
	_wisp = StoryPaint.glow(self, Vector2(275, 460), 10, Color(0.75, 0.85, 1.0), 1.2)
	_wisp.z_index = 5
	StoryPaint.motes(self, Rect2(30, 260, 1900, 420), Color(0.5, 0.6, 0.85, 0.3), 45)
	# the rope ladder she climbed down, hanging from the well-head far above
	for y in [492.0, 396.0, 300.0, 204.0]:
		SurfaceArt.sprite(self, "rope_ladder", Vector2(78, y), 1.5).z_index = -5
	_light(Vector2(80, 340), Color("aecae0"), 1.0)
	var cp: String = GameState.get_checkpoint_for(WELL)
	if cp == "prologue.well.second":
		_checkpoint = Vector2(690, 590)
	elif cp == "prologue.well.ward":
		_checkpoint = Vector2(1320, 662)

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	var root := Control.new()
	ui.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root.size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(func(): root.size = get_viewport().get_visible_rect().size)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	root.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -352
	panel.offset_right = -20
	panel.offset_top = 22
	panel.add_theme_stylebox_override("panel", DungeonUI.style("panel_lite", 8, Vector4(14, 10, 14, 10)))
	objective = Label.new()
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_font_override("font", Fonts.STORY)
	objective.add_theme_font_size_override("font_size", 16)
	objective.add_theme_color_override("font_color", DungeonUI.INK)
	panel.add_child(objective)
	objective.text = ["Nan's cottage\nSpeak with Nan.", "The pilgrim road\nLower the bridge. Find the Belfry's gate.", "The old well\nLight both passage lamps with Nan's lantern.  0 / 2"][stage]
	_heading = Label.new()
	root.add_child(_heading)
	_heading.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_heading.position = Vector2(28, 30)
	_heading.text = ["A Name to Remember", "The Pilgrim Road", "One Flame, Two Lamps"][stage]
	_heading.add_theme_font_override("font", Fonts.TITLE)
	_heading.add_theme_font_size_override("font_size", 36)
	_heading.add_theme_color_override("font_color", GOLD)
	_heading.add_theme_color_override("font_outline_color", Color("0d0b10"))
	_heading.add_theme_constant_override("outline_size", 8)
	_fade = ColorRect.new()
	root.add_child(_fade)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0.025, 0.02, 0.045, 1)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue = DIALOGUE.new()
	add_child(dialogue)
	dialogue.line_shown.connect(_cinematic_cue)
	if stage == Stage.WELL:
		_update_lamp_goal()

func _cinematic_cue(index: int) -> void:
	if stage != Stage.COTTAGE:
		return
	if index == 0:
		var t := create_tween().set_parallel()
		t.tween_property(camera, "position", Vector2(457, 445), 0.1 if Settings.reduce_motion else 2.4).set_trans(Tween.TRANS_SINE)
		t.tween_property(self, "_cottage_framing", 1.75, 0.1 if Settings.reduce_motion else 2.4).set_trans(Tween.TRANS_SINE)
	elif index == 8:
		_lantern.visible = true
		Sfx.play("collect", player.position, -12)
		StoryPaint.glow(player, Vector2(18, -32), 24, Color(GOLD, 0.45))

func _opening() -> void:
	if stage == Stage.COTTAGE:
		_talk([
			["Nan", "There you are, my... Oh, I know your name. I stitched it into your first cloak."],
			["Echidna", "Echidna, Nan. It's me."],
			["Nan", "Echidna. Stay a moment. Let me say it while I still can."],
			["Echidna", "The chimes outside are moving, but they don't make a sound. Is that the Hush?"],
			["Nan", "It takes the little things first. A tune. A word. Then the people those words belong to."],
			["Nan", "The monks' bell held it back. Since the bell cracked, the silence has been coming down the mountain."],
			["Echidna", "Then I'll go up there. If the bell can be made to ring, we still have a chance."],
			["Nan", "The Belfry doors are sealed. Take the pilgrim road to the old well. The bellkeepers used the passage beneath it."],
			["Nan", "Take my lantern. Share its flame with the passage lamps. The old wards remember light, even when people forget."],
			["Echidna", "I'll find the bell. And I'll come home before you have to ask my name again."],
			["Nan", "I'll keep the fire for you, Echidna."],
		], func():
			_lantern.visible = true
			GameState.set_flag("story.nan_lantern")
			Sfx.play("collect", player.position, -8)
			objective.text = "Carry Nan's lantern\nLeave through the cottage door. Follow the pilgrim road."
		)
	elif stage == Stage.APPROACH:
		_talk([["Echidna", "The old pilgrim road. Nan walked it every morning when she was a novice, up to the Choir's bell."],
			["Echidna", "No wind. No birds. Even the snow stopped halfway down. The Hush lies thicker up here."],
			["Echidna", "Keep walking. She's waiting for the sound of that bell."]])
	else:
		_talk([["Echidna", "The bellkeepers' passage. This is how they reached the tower when the snow closed the road."],
			["Echidna", "Nan's lantern is still warm in my hand. One flame can wake both lamps."]])

func _talk(pages: Array, after: Callable = Callable()) -> void:
	if dialogue.active or leaving:
		return
	# Keep gravity while talking: using a door during a jump must not leave
	# Echidna hanging in the air throughout the cinematic.
	player.lock_controls(false)
	Crosshair.arrow()
	objective.get_parent().visible = false
	_heading.visible = false
	dialogue.finished.connect(func():
		if after.is_valid():
			after.call()
		if not leaving:
			# Interactable reads just-pressed input in the physics tick. Wait
			# for release so the final dialogue press cannot reopen a door's
			# conversation or fire a spell in the same frame.
			_resume_when_released = true
			objective.get_parent().visible = true
			_heading.visible = true
			Crosshair.aim(true)
			if stage == Stage.COTTAGE:
				var t := create_tween().set_parallel()
				t.tween_property(self, "_cottage_framing", 1.35, 0.1 if Settings.reduce_motion else 1.0)
				t.tween_property(camera, "position", Vector2(480, 435), 0.1 if Settings.reduce_motion else 1.0)
	, CONNECT_ONE_SHOT)
	dialogue.begin(pages)

func lower_bridge() -> void:
	if bridge_open or leaving:
		return
	bridge_open = true
	Sfx.play("lever", Vector2(726, FLOOR), -5)
	player.lock_controls(true)
	var t := create_tween()
	t.tween_property(_bridge, "rotation", 0.0, 0.15 if Settings.reduce_motion else 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func():
		_bridge_body.collision_layer = 2
		Sfx.play("crate_thud", _bridge.position, -9)
		GameState.set_flag("story.bridge_lowered")
		objective.text = "The pilgrim road\nCross the bridge. Read the seal on the Belfry's gate."
		player.unlock_controls()
	)

func _gate_story() -> void:
	_talk([["Echidna", "The Belfry's outer gate. The frost has grown right through the lock."],
		["Echidna", "Four hollows cut into the seal, each waiting for a word. I don't know any of them. Not yet."],
		["Inscription", "SEALED BY THE CHOIR UNTIL THE BELL IS WHOLE. Bellkeepers: take the eastern well, and keep the passage lamps burning."],
		["Echidna", "The eastern well. Nan remembered the way, even when she couldn't remember me."]], func():
		GameState.set_flag("story.belfry_read")
		_exit.enabled = true
		objective.text = "A way beneath the seal\nFind the old well east of the gate."
	)

func _well_story() -> void:
	_talk([["Echidna", "Cold air rising, and the smell of wet stone. Somewhere below is the way up to the bell."],
		["Echidna", "I'm not going down for treasure. I'm going down so Nan can say my name again."]], func(): _transition(WELL))

func light_sconce(index: int) -> void:
	if _sconces[index]["lit"] or leaving:
		return
	_restore_sconce(index)
	GameState.set_flag("story.lamp.%d" % index)
	Sfx.play("brazier_ignite", _sconces[index]["zone"].position, -10)
	_update_lamp_goal()
	if sconces_lit == 2:
		_open_ward(true)

func _restore_sconce(index: int) -> void:
	if _sconces[index]["lit"]:
		return
	_sconces[index]["lit"] = true
	_sconces[index]["zone"].enabled = false
	var lamp: PointLight2D = _sconces[index]["light"]
	lamp.visible = true
	lamp.energy = 1.1
	sconces_lit += 1

func _update_lamp_goal() -> void:
	if objective:
		objective.text = "One flame, two lamps\nShare Nan's flame with both passage lamps.  %d / 2" % sconces_lit
		if sconces_lit == 2:
			objective.text = "The sleepers' door is open\nFollow the little light into the Undercroft."

func _open_ward(sound: bool) -> void:
	_gate.collision_layer = 0
	_ward_door.visible = false
	_exit.enabled = true
	if sound:
		Sfx.play("puzzle_solved", Vector2(1700, 600), -10)
		Sfx.play("gate_rumble", Vector2(1700, 600), -12)
	queue_redraw()
	_update_lamp_goal()

func _undercroft_story() -> void:
	_talk([["Echidna", "A little light... You know the way, don't you?"],
		["Echidna", "The bell is above us, but its stairs begin down here. All right. Together."],
		["The Undercroft", "Beyond the passage lie the Choir's old trials for its novices. Learn their paths, wake their mechanisms, and reach the bell before Lowbell falls silent."]], func():
		GameState.set_flag("story.undercroft_entered")
		_transition(Journey.after_story())
	)

func _transition(path: String) -> void:
	if leaving:
		return
	leaving = true
	player.lock_controls(true)
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.8)
	t.tween_callback(func(): SceneFade.change(get_tree(), path, 0.0))

func _process(delta: float) -> void:
	_time += delta
	# the distance drifts slower than the road (see _parallax)
	var view := get_viewport().get_camera_2d()
	if view and not _layers.is_empty():
		var centre := view.get_screen_center_position()
		for entry in _layers:
			entry[0].position = (centre - Vector2(0, REST_Y)) * (1.0 - entry[1])
	if _bridge_rope:
		_update_rope()
	if stage == Stage.COTTAGE:
		var viewport_size := get_viewport().get_visible_rect().size
		var available := Vector2(2.0 * minf(camera.position.x, _width - camera.position.x), 2.0 * minf(camera.position.y - 100.0, 800.0 - camera.position.y))
		var zoom := maxf(_cottage_framing, maxf(viewport_size.x / available.x, viewport_size.y / available.y))
		camera.zoom = Vector2.ONE * zoom
	if not is_instance_valid(player):
		return
	if _lantern:
		_lantern.position.x = -19 if player.animated_sprite.flip_h else 19
	if _resume_when_released and not dialogue.active and not leaving and not Input.is_action_pressed("interact") and not Input.is_action_pressed("jump") and not Input.is_action_pressed("ui_accept") and not Input.is_action_pressed("shoot"):
		_resume_when_released = false
		player.unlock_controls()
	if _wisp:
		var target := player.position + Vector2(58, -64 + sin(_time * 2.0) * 7)
		_wisp.position = _wisp.position.lerp(target, 1.0 - exp(-delta * 2.5))
	if stage == Stage.APPROACH and player.position.y > 620 and not _safety_running:
		_recover()
	if stage == Stage.WELL and not dialogue.active and not leaving:
		if player.position.x > 1260 and _checkpoint.x < 1260:
			_checkpoint = Vector2(1320, 662)
			GameState.set_checkpoint(WELL, "prologue.well.ward")
		elif player.position.x > 650 and _checkpoint.x < 650:
			_checkpoint = Vector2(690, 590)
			GameState.set_checkpoint(WELL, "prologue.well.second")
	if stage == Stage.APPROACH and player.position.x > 1860 and not GameState.has_flag("story.belfry_read") and not dialogue.active:
		_gate_story()
	queue_redraw()

func _recover() -> void:
	_safety_running = true
	player.lock_controls(true)
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.25)
	t.tween_callback(func():
		player.teleport_to(Vector2(736, FLOOR - 2))
		camera.snap()
	)
	t.tween_property(_fade, "color:a", 0.0, 0.35)
	t.tween_callback(func():
		player.unlock_controls()
		_safety_running = false
	)

func _draw() -> void:
	if stage == Stage.COTTAGE:
		# Hearth, mantel, rug and ceiling timbers behind the reused sprites.
		draw_rect(Rect2(588, 386, 96, 134), Color("302332"))
		draw_rect(Rect2(600, 435, 72, 80), Color("130f1d"))
		draw_rect(Rect2(574, 382, 124, 12), Color("725044"))
		draw_rect(Rect2(276, 517, 292, 3), Color("b57961"))
		for x in [80, 440, 880]:
			draw_rect(Rect2(x, 205, 12, 315), Color("41303c"))
		draw_rect(Rect2(80, 211, 812, 14), Color("594039"))
		# Pantry shelves, a handwoven runner, and a portrait Nan still keeps.
		for y in [408, 448]:
			draw_rect(Rect2(134, y, 130, 7), Color("705344"))
			for k in 5:
				draw_rect(Rect2(146 + k * 22, y - 22, 13, 22), Color("b8a390") if k % 2 == 0 else Color("655870"))
		draw_rect(Rect2(284, 513, 278, 5), Color("a87866"))
		for x in range(290, 557, 12):
			draw_line(Vector2(x, 514), Vector2(x + 6, 517), Color("d3b283"), 1)
		draw_rect(Rect2(483, 300, 38, 46), Color("b18c62"), false, 3)
		draw_circle(Vector2(502, 317), 7, Color("a193a0"))
		draw_rect(Rect2(493, 326, 18, 15), Color("584a69"))
		for i in 6:
			var p := Vector2(614 + i * 9, 508)
			var tip := p + Vector2(sin(_time * 3 + i) * 4, -22 - sin(_time * 4 + i) * 8)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-5, 0), tip, p + Vector2(5, 0)]), Color("e68b43"))
			draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 0), p.lerp(tip, 0.7), p + Vector2(3, 0)]), GOLD)
	elif stage == Stage.APPROACH:
		# The seal's word-hollow glows faintly on the frozen gate
		RuneFragments.draw_glyph(self, &"space", Vector2(1760, 404), 30, Color(VIOLET, 0.5 + sin(_time) * 0.12), 2)
	else:
		# Water glints beneath the landings
		for x in range(620, 1960, 40):
			draw_line(Vector2(x, 785), Vector2(x + 22, 785), Color(0.4, 0.5, 0.7, 0.2 + sin(_time + x) * 0.08), 1)
		if sconces_lit < 2:
			for i in 2:
				RuneFragments.draw_glyph(self, &"light", Vector2(1683 + i * 34, 604), 24, GOLD if _sconces.size() > i and _sconces[i]["lit"] else Color("635975"), 2)
 
