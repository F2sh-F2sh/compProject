extends Node2D

## Three moving tableaux bridge the original Belfry and Observatory chapters.
## The bell wins time for Lowbell; the source of the Hush remains in the Eye.
const SELF_PATH := "res://scenes/story/bell_aftermath.tscn"
const NEXT := "res://scenes/chapter/chapter_2.tscn"
const DIALOGUE := preload("res://scripts/story/story_dialogue.gd")
var dialogue: CanvasLayer
var _pictures: Array[Node2D] = []
var _camera: Camera2D
var _fade: ColorRect
var _picture := 0
var _time := 0.0
var _leaving := false
var _rings: Node2D
var _zoom_tween: Tween

func _ready() -> void:
	# Animated every drawn frame (pictures, the camera's slow zoom): drawn as it is
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_tree().paused = false
	AudioDirector.reset_combat()
	AudioDirector.duck(-8, 1.0)
	GameState.set_checkpoint(SELF_PATH, "story.bell_echo")
	_camera = Camera2D.new()
	_camera.position = Vector2(576, 324)
	add_child(_camera)
	_build_pictures()
	var ui := CanvasLayer.new()
	ui.layer = 6
	add_child(ui)
	_fade = ColorRect.new()
	_fade.color = Color(0.025, 0.02, 0.045, 1)
	ui.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue = DIALOGUE.new()
	add_child(dialogue)
	dialogue.line_shown.connect(_cue)
	dialogue.finished.connect(_finish)
	Crosshair.arrow()
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0, 1.0)
	t.tween_callback(func(): dialogue.begin([
		["The Waking Tone", "For the first time in nine years, the great bell's voice crosses the mountain."],
		["Lowbell", "Far below, a wind chime answers. A woman by her hearth remembers the name she had been trying to say."],
		["Nan", "Echidna."],
		["Echidna", "You can hear it, Nan. I hope you can hear it."],
		["Echidna", "But the stars are still going out. The bell is holding the Hush back. It hasn't stopped what makes it."],
		["The Bellkeeper's Last Note", "The tone buys us time. The Eye still holds the frozen hour. Follow the old rune passages to the observatory."],
		["Echidna", "Then that's where I go next. I'll learn the words they carved into these stones. I'll find a way to end the silence."],
	]))

func _exit_tree() -> void:
	AudioDirector.duck(0, 0.8)

func _build_pictures() -> void:
	for i in 3:
		var picture := Node2D.new()
		add_child(picture)
		_pictures.append(picture)
		picture.visible = i == 0
		SurfaceArt.backdrop(picture, "sky", Vector2(-380, -140), 3.0, 800)
		var stars := StoryNodes.Stars.new()
		stars.area = Rect2(-300, -100, 1800, 400)
		stars.count = 100
		stars.fade = 0.55 if i == 2 else 0.25
		picture.add_child(stars)
	# Belfry: the bell sways above the newly lit hall.
	var first := _pictures[0]
	SurfaceArt.tile_block(first, Vector2(-150, 420), 60, 8, ["bricks_a", "bricks_b"], 1.5)
	for x in [190, 950]:
		SurfaceArt.sprite(first, "pillar", Vector2(x, 420), 5.0)
	var bell := SurfaceArt.animated(first, "great_bell", Vector2(576, 326), 2.5, 4)
	bell.name = "RingingBell"
	_rings = Node2D.new()
	first.add_child(_rings)
	_rings.draw.connect(_draw_bell_rings)
	StoryPaint.glow(first, Vector2(576, 285), 260, Color(1, 0.74, 0.4, 0.22))
	StoryPaint.motes(first, Rect2(180, 160, 790, 260), Color(1, 0.83, 0.6, 0.5), 50)
	# Lowbell: Nan's lantern and chimes regain their warmth.
	var second := _pictures[1]
	SurfaceArt.backdrop(second, "hills", Vector2(-300, 40), 2.0, 900)
	SurfaceArt.backdrop(second, "woods", Vector2(-300, 80), 2.0, 900)
	SurfaceArt.ground(second, -100, 1400, 424, 3.0, 5)
	SurfaceArt.sprite(second, "house_big", Vector2(655, 424), 3.0)
	SurfaceArt.animated(second, "nan", Vector2(636, 424), 3, 3.0)
	SurfaceArt.sprite(second, "chime_post", Vector2(348, 424), 3.0)
	StoryPaint.glow(second, Vector2(640, 354), 120, Color(1, 0.78, 0.48, 0.45))
	# The Eye: a rune points upward through the last surviving stars.
	var third := _pictures[2]
	SurfaceArt.sprite(third, "house_tower", Vector2(880, 430), 3.4)
	SurfaceArt.sprite(third, "crypt", Vector2(680, 430), 3.5)
	SurfaceArt.tile_block(third, Vector2(-100, 430), 58, 6, ["bricks_a", "bricks_roots"], 1.5)
	var cube := StoryNodes.Cube.new()
	cube.position = Vector2(410, 330)
	cube.art_scale = 4.0
	cube.words = [&"wind", &"lift", &"up", &"normal"]
	third.add_child(cube)
	cube.lit = 4
	StoryPaint.glow(third, Vector2(410, 330), 150, Color(0.65, 0.5, 1.0, 0.3))

func _cue(index: int) -> void:
	var next_picture := 0 if index == 0 else (1 if index < 4 else 2)
	if index == 0:
		Sfx.play("great_bell", null, -14, 0)
	elif index == 1:
		Sfx.play("bell", null, -16, 0)
	if next_picture == _picture:
		return
	_picture = next_picture
	for i in 3:
		_pictures[i].visible = i == _picture
	_camera.zoom = Vector2.ONE
	if _zoom_tween:
		_zoom_tween.kill()
	if not Settings.reduce_motion:
		_zoom_tween = create_tween()
		_zoom_tween.tween_property(_camera, "zoom", Vector2(1.04, 1.04), 6.0).set_trans(Tween.TRANS_SINE)

func _process(delta: float) -> void:
	_time += delta
	if not _pictures.is_empty():
		_pictures[0].get_node("RingingBell").rotation = 0.0 if Settings.reduce_motion else sin(_time * 2.0) * 0.06
	if _rings:
		_rings.queue_redraw()

func _draw_bell_rings() -> void:
	if _picture == 0:
		for x in [544, 608]:
			for y in range(40, 228, 12):
				_rings.draw_rect(Rect2(x - 3, y, 6, 9), Color("86718e"), false, 1)
		_rings.draw_rect(Rect2(520, 228, 112, 12), Color("6a4e4d"))
		for i in 3:
			var phase := i / 3.0 if Settings.reduce_motion else fmod(_time * 0.25 + i / 3.0, 1.0)
			_rings.draw_arc(Vector2(576, 290), 90 + phase * 230, 0, TAU, 64, Color(1, 0.82, 0.55, (1 - phase) * 0.25), 2)

func _finish() -> void:
	if _leaving:
		return
	_leaving = true
	GameState.set_flag("story.bell_echo_seen")
	var t := create_tween()
	t.tween_property(_fade, "color:a", 1, 0.8)
	t.tween_callback(func(): SceneFade.change(get_tree(), NEXT, 0.0))
