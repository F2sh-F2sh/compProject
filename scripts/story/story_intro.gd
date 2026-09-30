class_name StoryIntro
extends Node2D

## The story before the game: nine pixel-art pictures built from the surface
## and town packs and the story sprites (SurfaceArt), each still but for a few
## small movements (stars twinkling, a constellation drawing itself, runes
## lighting, frost creeping, the Hush draining the colour from the land, a
## bell swinging, monks leaving), with a slow push-in and a narrator's lines.
## Space, Enter or a click moves on; holding Esc skips to the village.
## When the last picture fades, Lowbell begins.

const LOWBELL := "res://scenes/story/lowbell.tscn"
const SIZE := Vector2(1152, 648)
## Painted well beyond the frame, so a wide window never sees an edge.
const WIDE := Rect2(-420, -320, 1992, 1288)
const NARRATION_FONTS := ["Palatino Linotype", "Book Antiqua", "Georgia", "Cambria", "Times New Roman", "serif"]
const HUSH_SHADER := preload("res://assets/shaders/story_hush.gdshader")
const ECHIDNA := preload("res://assets/sprites/Echidna/echidna_frames.tres")
## The pack sky's darkest blue, above the painting.
const SKY_TOP := SurfaceArt.SKY_TOP
const SKIP_HOLD := 0.9
const FADE := 0.7

var pictures: Array = []
var index := -1
var line := 0
var finished := false

var _picture: Node2D
var _camera: Camera2D
var _fade: ColorRect
var _caption: Label
## When the picture happens ("LONG AGO", "TODAY"), small above the words.
var _era: Label
var _next_hint: Label
var _skip_hint: Label
var _skip_bar: ColorRect
var _skip_time := 0.0
var _line_time := 0.0
var _line_length := 0.0
var _changing := true
var _caption_tween: Tween
## Movements a picture saves for a later line (line number -> Callable), so
## the picture acts out what the words are saying.
var _cues := {}


func _ready() -> void:
	get_tree().paused = false
	Crosshair.arrow()
	AudioDirector.fade_ambience(-40.0, 1.5)
	# Told plainly, one idea per line: what runes are, what went wrong, why
	# the bell matters, and what Echidna has to do. The small label above
	# the words says when each picture happens.
	pictures = [
		{"era": "LONG AGO", "lines": ["Long ago, monks called the Choir lived in a monastery on this mountain.",
				"They studied the stars, and found something amazing: the stars are words."],
			"build": _written_sky, "zoom": [1.14, 1.0], "from": Vector2(0, -110), "to": Vector2.ZERO, "min": [4.6, 4.6]},
		{"era": "LONG AGO", "lines": ["Put four star-words together and they make a spell, like WIND · PUSH · RIGHT · LARGE.",
				"The world does whatever the spell says. That is why the wind blows."],
			"build": _words_in_the_sky, "zoom": [1.06, 1.0], "from": Vector2(-60, 0), "to": Vector2(60, 10)},
		{"era": "LONG AGO", "lines": ["The Choir learned to carve their own four-word spells into stone cubes: rune cubes.",
				"When all four words light up, the spell comes true."],
			"build": _the_eye, "zoom": [1.0, 1.1], "from": Vector2.ZERO, "to": Vector2(0, 40), "min": [0.0, 4.8]},
		{"era": "SIXTY YEARS AGO", "lines": ["Sixty years ago, the Choir's leader, Ilse, had a daughter named Wren.",
				"Wren was very sick. She was dying, and Ilse could not bear to lose her."],
			"build": _ilse_and_wren, "zoom": [1.0, 1.08], "from": Vector2(30, 0), "to": Vector2(-30, 20)},
		{"era": "SIXTY YEARS AGO", "lines": ["So Ilse carved the most powerful spell ever written: ICE · FREEZE · SELF · PERSIST.",
				"It means “freeze this moment, and never let it end.” Time stopped around Wren, so she could not die."],
			"build": _hold_this_moment, "zoom": [1.0, 1.12], "from": Vector2.ZERO, "to": Vector2.ZERO, "min": [4.2, 5.4]},
		{"era": "SIXTY YEARS AGO", "lines": ["But the spell never stopped. Its frozen stillness began to creep out from the monastery.",
				"Wherever it reached, sound, colour and memories faded away. People called it the Hush."],
			"build": _the_hush, "zoom": [1.03, 1.0], "from": Vector2(20, 0), "to": Vector2.ZERO, "min": [5.0, 7.0]},
		{"era": "FOR SIXTY YEARS", "lines": ["Only one thing could push the Hush back: the sound of the monastery's great bell.",
				"So the monks rang it every single day, for sixty years."],
			"build": _the_bell, "zoom": [1.05, 1.0], "from": Vector2(0, -20), "to": Vector2.ZERO, "min": [5.2]},
		{"era": "NINE YEARS AGO", "lines": ["Nine years ago, the bell cracked. It could not ring any more.",
				"The last monks sealed the bell tower, the Belfry, and left the mountain for good."],
			"build": _the_crack, "zoom": [2.6, 1.0], "from": Vector2(-66, 30), "to": Vector2.ZERO, "hold": 3.4, "min": [4.5, 8.5]},
		{"era": "TODAY", "lines": ["Now nothing holds the Hush back. It has reached the village of Lowbell.",
				"The stars are going out, and people are forgetting words, even each other's names.",
				"Someone has to get into the sealed Belfry and make the bell ring again.",
				"That someone is a young witch named Echidna."],
			"build": _lowbell, "zoom": [1.0, 1.08], "from": Vector2(0, -30), "to": Vector2(-20, 30)},
	]
	_camera = Camera2D.new()
	_camera.position = SIZE / 2.0
	add_child(_camera)
	_camera.make_current()
	_build_ui()
	_show_picture(0)


func _exit_tree() -> void:
	AudioDirector.fade_ambience(AudioDirector.AMBIENCE_DB, 1.5)


# ------------------------------------------------------------------ flow

func _show_picture(i: int) -> void:
	_changing = true
	index = i
	line = 0
	if is_instance_valid(_picture):
		_picture.queue_free()
	_picture = Node2D.new()
	_picture.name = "Picture%d" % (i + 1)
	add_child(_picture)
	move_child(_picture, 0)
	var spec: Dictionary = pictures[i]
	_cues = {}
	spec["build"].call(_picture)
	_era.text = spec.get("era", "")
	_era.modulate.a = 0.0
	# The slow push-in, over the whole time the picture is shown
	var total := 1.0
	for n in spec["lines"].size():
		total += _line_seconds(i, n) + 0.7
	var hold: float = spec.get("hold", 0.0)
	_camera.zoom = Vector2.ONE * spec["zoom"][0]
	_camera.position = SIZE / 2.0 + spec["from"]
	var ken := _picture.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ken.tween_property(_camera, "zoom", Vector2.ONE * spec["zoom"][1], maxf(total + FADE - hold, 1.0)).set_delay(hold)
	ken.tween_property(_camera, "position", SIZE / 2.0 + spec["to"], maxf(total + FADE - hold, 1.0)).set_delay(hold)
	var reveal := create_tween()
	reveal.tween_property(_fade, "color:a", 0.0, FADE + 0.3)
	reveal.tween_callback(func(): _changing = false; _show_line(0))


## How long a line stays: time to read it, and never less than the picture
## needs for its movements to play out.
func _line_seconds(picture: int, n: int) -> float:
	var text: String = pictures[picture]["lines"][n]
	var minimums: Array = pictures[picture].get("min", [])
	var at_least: float = minimums[n] if n < minimums.size() else 0.0
	return maxf(clampf(1.6 + text.length() * 0.05, 4.2, 9.0), at_least)


func _show_line(n: int) -> void:
	line = n
	var text: String = pictures[index]["lines"][n]
	_caption.text = text
	_line_time = 0.0
	_line_length = _line_seconds(index, n)
	_next_hint.modulate.a = 0.0
	if _caption_tween:
		_caption_tween.kill()
	_caption_tween = create_tween()
	_caption_tween.tween_property(_caption, "modulate:a", 1.0, 0.7)
	if n == 0:
		create_tween().tween_property(_era, "modulate:a", 1.0, 0.9)
	if _cues.has(n):
		_cues[n].call()


## Moves on: to the next line, the next picture, or the village.
func next() -> void:
	if _changing or finished:
		return
	var lines: Array = pictures[index]["lines"]
	_changing = true
	if line + 1 < lines.size():
		var t := create_tween()
		t.tween_property(_caption, "modulate:a", 0.0, 0.35)
		t.tween_callback(func(): _changing = false; _show_line(line + 1))
	elif index + 1 < pictures.size():
		var t := create_tween().set_parallel()
		t.tween_property(_caption, "modulate:a", 0.0, 0.4)
		t.tween_property(_era, "modulate:a", 0.0, 0.4)
		t.tween_property(_fade, "color:a", 1.0, FADE)
		t.chain().tween_callback(_show_picture.bind(index + 1))
	else:
		_finish()


func skip() -> void:
	_finish()


func _finish() -> void:
	if finished:
		return
	finished = true
	_changing = true
	var t := create_tween().set_parallel()
	t.tween_property(_caption, "modulate:a", 0.0, 0.4)
	t.tween_property(_era, "modulate:a", 0.0, 0.4)
	t.tween_property(_next_hint, "modulate:a", 0.0, 0.4)
	t.tween_property(_fade, "color:a", 1.0, 0.9)
	t.chain().tween_callback(func(): get_tree().change_scene_to_file(LOWBELL))


func _process(delta: float) -> void:
	var holding := Input.is_action_pressed("pause") or Input.is_action_pressed("ui_cancel")
	_skip_time = _skip_time + delta if holding and not finished else 0.0
	_skip_bar.size.x = 110.0 * clampf(_skip_time / SKIP_HOLD, 0.0, 1.0)
	if _skip_time >= SKIP_HOLD:
		skip()
	if _changing or finished:
		return
	_line_time += delta
	if _line_time > 1.4:
		_next_hint.modulate.a = move_toward(_next_hint.modulate.a, 0.75, delta * 2.0)
	if _line_time >= _line_length:
		next()


func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	var press: bool = event.is_action_pressed("jump") or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not press:
		return
	get_viewport().set_input_as_handled()
	# The first press finishes a line still fading in; the next moves on
	if not _changing and _caption.modulate.a < 0.95:
		if _caption_tween:
			_caption_tween.kill()
		_caption.modulate.a = 1.0
		_line_time = maxf(_line_time, 1.4)
		return
	next()


# ------------------------------------------------------------------ the page

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	# A dark band that the words sit on
	var fade_band := Gradient.new()
	fade_band.set_color(0, Color(0, 0, 0, 0))
	fade_band.set_color(1, Color(0.01, 0.005, 0.03, 0.82))
	var band_tex := GradientTexture2D.new()
	band_tex.gradient = fade_band
	band_tex.fill_from = Vector2(0, 0)
	band_tex.fill_to = Vector2(0, 1)
	band_tex.width = 4
	band_tex.height = 64
	var band := TextureRect.new()
	band.texture = band_tex
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	band.offset_top = -210
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(band)

	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(NARRATION_FONTS)
	serif.font_italic = true
	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_caption.offset_left = 120
	_caption.offset_right = -120
	_caption.offset_top = -150
	_caption.offset_bottom = -48
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_override("font", serif)
	_caption.add_theme_font_size_override("font_size", 27)
	_caption.add_theme_color_override("font_color", Color("efe6d2"))
	_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	_caption.add_theme_constant_override("outline_size", 6)
	_caption.modulate.a = 0.0
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_caption)

	var small := StoryPaint.label_font()
	_era = Label.new()
	_era.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_era.offset_top = -176
	_era.offset_bottom = -152
	_era.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var spaced := FontVariation.new()
	spaced.base_font = small
	spaced.spacing_glyph = 3
	_era.add_theme_font_override("font", spaced)
	_era.add_theme_font_size_override("font_size", 13)
	_era.add_theme_color_override("font_color", Color("d8b87a"))
	_era.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_era.add_theme_constant_override("outline_size", 4)
	_era.modulate.a = 0.0
	_era.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_era)

	_next_hint = Label.new()
	_next_hint.text = "%s  ▸" % InputLabels.primary("jump")
	_next_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_next_hint.offset_left = -170
	_next_hint.offset_right = -28
	_next_hint.offset_top = -36
	_next_hint.offset_bottom = -14
	_next_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_next_hint.add_theme_font_override("font", small)
	_next_hint.add_theme_font_size_override("font_size", 12)
	_next_hint.add_theme_color_override("font_color", Color("b3a9cf"))
	_next_hint.modulate.a = 0.0
	ui.add_child(_next_hint)

	_skip_hint = Label.new()
	_skip_hint.text = "Hold %s to skip" % InputLabels.primary("pause")
	_skip_hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_hint.offset_left = -260
	_skip_hint.offset_right = -28
	_skip_hint.offset_top = 20
	_skip_hint.offset_bottom = 40
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_hint.add_theme_font_override("font", small)
	_skip_hint.add_theme_font_size_override("font_size", 11)
	_skip_hint.add_theme_color_override("font_color", Color("7d7499"))
	ui.add_child(_skip_hint)
	_skip_bar = ColorRect.new()
	_skip_bar.color = Color("b3a9cf")
	_skip_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_bar.offset_left = -138
	_skip_bar.offset_right = -138
	_skip_bar.offset_top = 44
	_skip_bar.offset_bottom = 46
	ui.add_child(_skip_bar)

	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.01, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_fade)


# ------------------------------------------------------------------ the pictures
# Each picture is built on a canvas of art pixels drawn `scale` times over
# (3x: 384 x 216 art pixels fill the screen, like the packs' own mock-ups).
# Everything in them comes from the surface and town packs (SurfaceArt) or
# the story's pixel sprites; only light, frost, sound and runes are effects.

## A picture's canvas, `scale` screen pixels to each art pixel.
func _canvas(p: Node2D, scale := 3.0) -> Node2D:
	var c := Node2D.new()
	c.name = "Canvas"
	c.scale = Vector2(scale, scale)
	p.add_child(c)
	return c


## The surface pack's night sky with its moon at `moon` (canvas art
## pixels), repeated sideways and filled above with its own darkest blue;
## and, if asked, stars.
func _night(p: Node2D, c: Node2D, moon: Vector2, star_count := 0, seed_value := 7) -> StoryNodes.Stars:
	var fill := ColorRect.new()
	fill.name = "SkyFill"
	fill.color = SKY_TOP
	fill.position = WIDE.position
	fill.size = WIDE.size
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(fill)
	p.move_child(fill, 0)
	var left := WIDE.position.x / c.scale.x - 20.0
	var x := moon.x - 450.0
	while x > left:
		x -= 640.0
	SurfaceArt.backdrop(c, "sky", Vector2(x, moon.y - 90.0), 1.0, 640.0 * 4.0)
	if star_count <= 0:
		return null
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(WIDE.position / c.scale.x, Vector2(WIDE.size.x / c.scale.x, 120.0))
	stars.count = star_count
	stars.seed_value = seed_value
	c.add_child(stars)
	return stars


## A pack sprite on the canvas (feet at `foot`, art pixels).
func _put(c: Node2D, sprite_name: String, foot: Vector2, flip := false) -> Sprite2D:
	return SurfaceArt.sprite(c, sprite_name, foot, 1.0, flip)


## A hand-made figure (standing, breathing, blinking) on the canvas.
func _figure(c: Node2D, sprite_name: String, foot: Vector2, flip := false, blink_seed := 0) -> AnimatedSprite2D:
	var a := SurfaceArt.animated(c, sprite_name, foot, 0.0, 1.0, flip)
	a.stop()
	var rng := RandomNumberGenerator.new()
	rng.seed = blink_seed + 1
	var t := create_tween().set_loops()
	t.bind_node(a)
	t.tween_interval(rng.randf_range(0.2, 1.4))
	t.tween_callback(func(): a.frame = 1)
	t.tween_interval(1.2)
	t.tween_callback(func(): a.frame = 0)
	t.tween_interval(rng.randf_range(0.8, 1.6))
	t.tween_callback(func(): a.frame = 2)
	t.tween_interval(0.14)
	t.tween_callback(func(): a.frame = 0)
	return a


## A dead tree that sways in the wind (leaning from its roots).
func _swaying(c: Node2D, sprite_name: String, foot: Vector2, amount: float, seed_value: int) -> Sprite2D:
	var tree := _put(c, sprite_name, foot)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var sway := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.bind_node(tree)
	sway.tween_interval(rng.randf() * 0.6)
	sway.tween_property(tree, "skew", -amount, 1.1 + rng.randf() * 0.4)
	sway.tween_property(tree, "skew", -amount * 0.2, 1.2 + rng.randf() * 0.4)
	return tree


## Clouds from the pack drifting slowly across.
func _clouds(c: Node2D, specs: Array, alpha := 0.3) -> void:
	for spec in specs:
		var cloud := _put(c, spec[0], spec[1])
		cloud.modulate.a = alpha
		var drift := create_tween().set_loops()
		drift.bind_node(cloud)
		drift.tween_property(cloud, "position:x", cloud.position.x + spec[2], 14.0).set_trans(Tween.TRANS_SINE)
		drift.tween_property(cloud, "position:x", cloud.position.x, 14.0).set_trans(Tween.TRANS_SINE)


## A wall of the pack's old bricks behind an interior, dimmed.
func _brick_wall(c: Node2D, shade := 0.55) -> TileMapLayer:
	var wall := SurfaceArt.tile_block(c, Vector2(-176, -128), 48, 26,
		["bricks_a", "bricks_b", "bricks_a", "bricks_b", "bricks_a", "bricks_roots", "bricks_vines"], 1.0, 23)
	wall.modulate = Color(shade, shade, shade * 1.05)
	return wall


func _written_sky(p: Node2D) -> void:
	var c := _canvas(p)
	_night(p, c, Vector2(318, 38), 110, 1)
	_clouds(c, [["cloud_a", Vector2(40, 62), 30.0], ["cloud_c", Vector2(250, 84), -24.0]], 0.22)
	# The monastery on its hill, far off
	SurfaceArt.backdrop(c, "hills", Vector2(-10 - 640, -48), 1.0, 640 * 3)
	# Nearer: the woods, and three of the Choir on a grassy rise, looking up
	SurfaceArt.backdrop(c, "woods", Vector2(-160 - 640, -70), 1.0, 640 * 3)
	SurfaceArt.ground(c, -176, 112, 142, 1.0, 6, ["grass_a", "grass_b", "grass_c"], ["dirt_a", "dirt_b", "dirt_c"], 2)
	_put(c, "grass_end_r", Vector2(120, 154))
	for spec in [[Vector2(40, 143), 0], [Vector2(60, 143), 1], [Vector2(80, 143), 2]]:
		_figure(c, "monk", spec[0], false, spec[1])
	var con := StoryNodes.Constellation.new()
	con.points = [Vector2(452, 162), Vector2(520, 104), Vector2(604, 128), Vector2(668, 70), Vector2(746, 118),
		Vector2(712, 196), Vector2(618, 210)]
	con.glyph = &"wind"
	con.glyph_center = Vector2(600, 140)
	con.glyph_size = 150.0
	p.add_child(con)
	# "...the stars are words": the constellation draws itself into a rune
	_cues[1] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(0.3)
		t.tween_property(con, "progress", 1.0, 2.6)
		t.tween_callback(Sfx.play.bind("rune_learn", null, -9.0, 0.0))
		t.tween_property(con, "glyph_alpha", 1.0, 1.4)


func _words_in_the_sky(p: Node2D) -> void:
	var c := _canvas(p)
	_night(p, c, Vector2(40, 30), 60, 3)
	var words := [[&"wind", "WIND"], [&"push", "PUSH"], [&"right", "RIGHT"], [&"large", "LARGE"]]
	var t := p.create_tween()
	t.tween_interval(0.6)
	for i in words.size():
		var g := StoryNodes.Glyph.new()
		g.glyph = words[i][0]
		g.label = words[i][1]
		g.size = 60.0
		g.position = Vector2(366 + i * 140, 140)
		g.alpha = 0.0
		p.add_child(g)
		t.tween_property(g, "alpha", 1.0, 0.55)
	SurfaceArt.backdrop(c, "woods", Vector2(-160 - 640, -96), 1.0, 640 * 3)
	# Clouds racing, trees bending, grass and leaves blowing: the wind obeys
	for spec in [["cloud_a", Vector2(-60, 70)], ["cloud_b", Vector2(150, 50)], ["cloud_c", Vector2(330, 80)]]:
		var cloud := _put(c, spec[0], spec[1])
		cloud.modulate.a = 0.3
		var run := create_tween().set_loops()
		run.bind_node(cloud)
		run.tween_property(cloud, "position:x", cloud.position.x + 260.0, 16.0)
		run.tween_callback(func(): cloud.position.x -= 260.0)
	SurfaceArt.ground(c, -176, 560, 196, 1.0, 3, ["grass_a", "grass_b", "grass_c"], ["dirt_a", "dirt_b", "dirt_c"], 5)
	_swaying(c, "tree_big", Vector2(62, 197), 0.1, 1)
	_swaying(c, "tree_small", Vector2(322, 197), 0.12, 2)
	_swaying(c, "tree_small", Vector2(-40, 197), 0.12, 3)
	var grass := StoryNodes.Tufts.new()
	grass.x0 = -170.0
	grass.x1 = 550.0
	grass.y = 199.0
	grass.gap = Vector2(6.0, 16.0)
	grass.wind = 0.18
	c.add_child(grass)
	var leaves := StoryNodes.Leaves.new()
	leaves.area = Rect2(-170, 110, 720, 80)
	leaves.count = 14
	leaves.speed = 70.0
	c.add_child(leaves)
	var crow := StoryNodes.Flyer.new()
	crow.setup(["crow_fly_a", "crow_fly_b"], 8.0)
	crow.from = Vector2(-40, 96)
	crow.to = Vector2(430, 70)
	crow.seconds = 6.0
	crow.wait = 20.0
	crow.delay = 1.2
	c.add_child(crow)
	Sfx.play("wind_gust", null, -12.0, 0.0)


func _the_eye(p: Node2D) -> void:
	var c := _canvas(p)
	_brick_wall(c, 0.5)
	# The hall: an old arched alcove, a round window above it letting in the
	# sky's light, and a floor of worn bricks
	_put(c, "crypt", Vector2(192, 150))
	_put(c, "win_round_bright", Vector2(192, 34))
	StoryPaint.glow(c, Vector2(192, 28), 30.0, Color(0.7, 0.8, 1.0), 0.6)
	var shaft := LightShaft.new()
	shaft.position = Vector2(576, 104)
	shaft.length = 350.0
	shaft.width_top = 40.0
	shaft.width_bottom = 170.0
	shaft.color = Color(0.72, 0.8, 1.0)
	shaft.intensity = 0.3
	p.add_child(shaft)
	SurfaceArt.ground(c, -176, 560, 150, 1.0, 6, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9)
	# A stone plinth, and on it a rune cube
	_put(c, "slab", Vector2(192, 150))
	_put(c, "slab", Vector2(192, 142))
	var cube := StoryNodes.Cube.new()
	cube.sprite_name = "rune_cube"
	cube.art_scale = 3.0
	cube.position = Vector2(192, 134 - 11) * 3.0
	cube.words = [&"wind", &"push", &"up", &"strong"]
	p.add_child(cube)
	for x in [150.0, 234.0]:
		var candle := SurfaceArt.animated(c, "candle", Vector2(x, 150), 5.0, 1.0)
		candle.frame = int(x) % 3
		StoryPaint.glow(c, Vector2(x, 138), 12.0, Color(0.6, 0.8, 1.0), 0.7)
	# The Choir gathered round
	for spec in [[70.0, false], [98.0, false], [124.0, false], [260.0, true], [286.0, true], [314.0, true]]:
		_figure(c, "monk", Vector2(spec[0], 151), spec[1], int(spec[0]))
	# "When all four words light up...": one word at a time
	_cues[1] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(0.4)
		for i in 4:
			t.tween_callback(Sfx.play.bind("rune_activate", null, -11.0, 0.05))
			t.tween_property(cube, "lit", float(i + 1), 0.5)
			t.tween_interval(0.2)


func _ilse_and_wren(p: Node2D) -> void:
	# A closer picture: 5x
	var c := _canvas(p, 5.0)
	_brick_wall(c, 0.42)
	# Moonlight through the window
	_put(c, "win_arch_bright", Vector2(142, 40))
	StoryPaint.glow(c, Vector2(142, 32), 16.0, Color(0.7, 0.82, 1.0), 0.6)
	var shaft := LightShaft.new()
	shaft.position = Vector2(142 * 5, 38 * 5)
	shaft.length = 260.0
	shaft.width_top = 40.0
	shaft.width_bottom = 150.0
	shaft.angle_deg = -14.0
	shaft.color = Color(0.72, 0.8, 1.0)
	shaft.intensity = 0.28
	p.add_child(shaft)
	SurfaceArt.ground(c, -40, 280, 88, 1.0, 8, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 13)
	# Wren asleep, breathing slowly; a candle on the crate beside her
	var bed := SurfaceArt.animated(c, "wren_bed", Vector2(150, 89), 0.9, 1.0)
	bed.play(&"default")
	_put(c, "crate", Vector2(118, 89))
	var candle := SurfaceArt.animated(c, "candle", Vector2(118, 75), 5.0, 1.0)
	candle.play(&"default")
	StoryPaint.glow(c, Vector2(118, 64), 30.0, Color(0.62, 0.8, 1.0), 0.8)
	# Ilse, watching over her
	_figure(c, "ilse", Vector2(88, 89), false, 4)
	StoryPaint.motes(c, Rect2(60, 0, 140, 80), Color(0.8, 0.85, 1.0, 0.4), 14)


func _hold_this_moment(p: Node2D) -> void:
	var c := _canvas(p, 3.0)
	_night(p, c, Vector2(-300, 40))
	c.modulate = Color(0.7, 0.8, 1.0)
	var snow := StoryPaint.snow(p, Rect2(-420, -340, 1992, 1100), 170)
	var cube := StoryNodes.Cube.new()
	cube.sprite_name = "rune_cube_great"
	cube.art_scale = 6.0
	cube.position = Vector2(576, 312)
	cube.words = [&"ice", &"freeze", &"self", &"persist"]
	cube.color = Color(0.62, 0.9, 1.0)
	cube.show_names = true
	p.add_child(cube)
	var frost := StoryNodes.Frost.new()
	frost.position = cube.position
	p.add_child(frost)
	var flash := StoryPaint.glow(p, cube.position, 440, Color(0.7, 0.9, 1.0), 0.6)
	flash.modulate.a = 0.0
	var t := p.create_tween()
	t.tween_interval(0.8)
	for i in 4:
		t.tween_callback(Sfx.play.bind("ice_form", null, -10.0, 0.05))
		t.tween_property(cube, "lit", float(i + 1), 0.6)
	# "...time stopped": the frost takes the room and the snow hangs still
	_cues[1] = func() -> void:
		var freeze := p.create_tween()
		freeze.tween_interval(0.3)
		freeze.tween_callback(Sfx.play.bind("ice_freeze", null, -4.0, 0.0))
		freeze.set_parallel()
		freeze.tween_property(frost, "radius", 1100.0, 3.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		freeze.tween_property(snow, "speed_scale", 0.0, 2.6)
		freeze.tween_property(flash, "modulate:a", 0.45, 1.5)
		freeze.tween_property(p, "modulate", Color(0.86, 0.97, 1.12), 3.0)


func _the_hush(p: Node2D) -> void:
	# A wide view: 2x
	var c := _canvas(p, 2.0)
	var stars := _night(p, c, Vector2(120, 44), 150, 12)
	stars.area = Rect2(-220, -170, 1000, 190)
	# The monastery on its hill; the village below, still lit for now
	SurfaceArt.backdrop(c, "hills", Vector2(250 - 640, -64), 1.0, 640 * 3)
	SurfaceArt.backdrop(c, "woods", Vector2(-220 - 640, -40), 1.0, 640 * 3)
	SurfaceArt.ground(c, -230, 800, 214, 1.0, 8, ["grass_a", "grass_b", "grass_c"], ["dirt_a", "dirt_b", "dirt_c"], 21)
	var village_lights: Array = []
	for spec in [["house_small", 40.0, [Vector2(38, 46)]], ["house_medium", 118.0, [Vector2(22, 56)]],
			["house_tiny", 180.0, []], ["house_shop", 250.0, [Vector2(61, 66)]], ["house_small", 330.0, [Vector2(38, 46)]]]:
		var house := _put(c, spec[0], Vector2(spec[1], 215))
		var top_left := house.position + house.offset
		for w in spec[2]:
			village_lights.append(StoryPaint.glow(c, top_left + w, 12.0, Color(0.7, 0.84, 1.0), 0.8))
	var summit := c.position + Vector2(250 + 182, -64 + 150) * c.scale
	# The Hush: colour and stars drain away in a circle growing from the monastery
	var layer := CanvasLayer.new()
	layer.layer = 1
	p.add_child(layer)
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = HUSH_SHADER
	veil.material = mat
	layer.add_child(veil)
	var spread := func(r: float) -> void:
		var view := get_viewport().get_visible_rect().size
		var on_screen := get_viewport().get_canvas_transform() * summit
		mat.set_shader_parameter("origin", on_screen / view)
		mat.set_shader_parameter("aspect", view.x / view.y)
		mat.set_shader_parameter("radius", r)
		var world_r := r * view.y / _camera.zoom.y
		stars.hush_origin = (summit - c.position) / c.scale
		stars.hush_radius = world_r / c.scale.x
		for light in village_lights:
			if is_instance_valid(light) and light.global_position.distance_to(summit) < world_r:
				light.modulate.a = move_toward(light.modulate.a, 0.0, 0.04)
	spread.call(0.0)
	var t := p.create_tween()
	t.tween_interval(1.0)
	t.tween_callback(Sfx.play.bind("power_down", null, -10.0, 0.0))
	t.tween_method(spread, 0.0, 2.4, 10.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


## The bell frame: two old pillars and a beam of planks, with the great
## bell hanging from its middle; returns the bell (it swings from its top).
func _bell_frame(c: Node2D, x: float, ground_y: float) -> Node2D:
	_put(c, "pillar", Vector2(x - 34, ground_y))
	_put(c, "pillar", Vector2(x + 34, ground_y))
	SurfaceArt.tile_row(c, Vector2(x - 40, ground_y - 50), ["plank_l", "plank_m", "plank_m", "plank_m", "plank_r"], 1.0)
	var hang := Node2D.new()
	hang.name = "Bell"
	hang.position = Vector2(x, ground_y - 44)
	c.add_child(hang)
	var bell := AnimatedSprite2D.new()
	bell.sprite_frames = SurfaceArt.frames("great_bell", 0.0)
	bell.centered = false
	bell.offset = Vector2(-13, 0)
	hang.add_child(bell)
	return hang


func _the_bell(p: Node2D) -> void:
	# Close in on the belfry: 5x
	var c := _canvas(p, 5.0)
	_night(p, c, Vector2(-14, 22), 50, 5)
	SurfaceArt.ground(c, -90, 330, 88, 1.0, 8, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 51)
	var bell := _bell_frame(c, 115.0, 88.0)
	# Grey Hush at the edges (the pack's clouds, drained), pushed back with every toll
	var fog: Array = []
	for side in [-1, 1]:
		for k in 2:
			var cloud := _put(c, ["cloud_a", "cloud_b"][k], Vector2(115 + side * (122 + k * 20), 70 - k * 30))
			cloud.modulate = Color(0.62, 0.64, 0.72, 0.75)
			cloud.scale = Vector2(1.6, 1.6)
			fog.append([cloud, side])
	var rings := StoryNodes.Rings.new()
	rings.color = Color(0.8, 0.88, 1.0)
	rings.position = Vector2(115, 56) * 5.0
	p.add_child(rings)
	var state := {"tolls": 0}
	var toll := func() -> void:
		rings.ring()
		if state["tolls"] < 3:
			Sfx.play("great_bell", null, -9.0, 0.0)
		state["tolls"] += 1
		for entry in fog:
			var cloud: Sprite2D = entry[0]
			var out: float = entry[1] * 16.0
			var push := p.create_tween().set_trans(Tween.TRANS_SINE)
			push.tween_property(cloud, "position:x", cloud.position.x + out, 0.9).set_ease(Tween.EASE_OUT)
			push.tween_property(cloud, "position:x", cloud.position.x + out * 0.3, 1.8).set_ease(Tween.EASE_IN_OUT)
	bell.rotation = -0.3
	var swing := p.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing.tween_property(bell, "rotation", 0.3, 1.35)
	swing.tween_callback(toll)
	swing.tween_property(bell, "rotation", -0.3, 1.35)
	swing.tween_callback(toll)


func _the_crack(p: Node2D) -> void:
	var c := _canvas(p)
	_night(p, c, Vector2(330, 34), 70, 19)
	SurfaceArt.backdrop(c, "hills", Vector2(120 - 640, -40), 1.0, 640 * 3)
	# The high ledge with the belfry and its sealed door, and the lower lane
	# the monks go down
	SurfaceArt.ground(c, -176, 232, 150, 1.0, 5, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b", "bricks_roots"], 71)
	SurfaceArt.ground(c, 232, 560, 196, 1.0, 2, ["grass_a", "grass_b", "grass_c"], ["dirt_a", "dirt_b"], 72)
	_put(c, "crypt", Vector2(62, 150))
	var bell_hang := _bell_frame(c, 170.0, 150.0)
	var bell: AnimatedSprite2D = bell_hang.get_child(0)
	var seal := StoryNodes.Glyph.new()
	seal.glyph = &"persist"
	seal.size = 26.0
	seal.color = Color(0.7, 0.55, 1.0)
	seal.position = Vector2(62, 136) * 3.0
	seal.alpha = 0.0
	p.add_child(seal)
	# The last monks, lanterns lit, going down and away
	var monks: Array = []
	for j in 4:
		var monk := _figure(c, "monk", Vector2(120 + j * 18, 151), false, j)
		monk.modulate.a = 0.0
		var lamp := StoryPaint.glow(monk, Vector2(12, -12), 10.0, Color(0.7, 0.84, 1.0), 1.0)
		lamp.modulate.a = 1.0
		monks.append(monk)
	var walk := func(k: float) -> void:
		for j in monks.size():
			var d := clampf(k - j * 0.1, 0.0, 1.0)
			var monk: AnimatedSprite2D = monks[j]
			# Along the ledge, down to the lane, and off to the right
			var pos := Vector2(lerpf(120.0, 470.0, d), 151.0)
			if pos.x > 232.0:
				pos.y = lerpf(151.0, 197.0, clampf((pos.x - 232.0) / 24.0, 0.0, 1.0))
			pos.y -= absf(sin(d * 60.0)) * 1.0
			monk.position = pos.round()
			monk.modulate.a = clampf(d * 14.0, 0.0, 1.0) * clampf((1.0 - d) * 5.0, 0.0, 1.0)
	walk.call(0.0)
	var t := p.create_tween()
	t.tween_interval(0.9)
	t.tween_callback(Sfx.play.bind("crumble_crack", null, -3.0, 0.0))
	t.tween_callback(func(): bell.frame = 1)
	t.tween_property(bell_hang, "modulate", Color(0.8, 0.78, 0.78), 0.6)
	t.tween_interval(0.9)
	t.tween_callback(Sfx.play.bind("gate_slam", null, -10.0, 0.0))
	t.tween_property(seal, "alpha", 1.0, 0.6)
	t.tween_method(walk, 0.0, 1.3, 9.0)


func _lowbell(p: Node2D) -> void:
	# The village today, wide: 2x
	var c := _canvas(p, 2.0)
	var stars := _night(p, c, Vector2(470, 48), 90, 29)
	stars.area = Rect2(-220, -170, 1000, 180)
	var fading := p.create_tween()
	fading.tween_interval(1.5)
	fading.tween_property(stars, "fade", 0.9, 12.0)
	SurfaceArt.backdrop(c, "hills", Vector2(-40 - 640, -90), 1.0, 640 * 3)
	var roofs := SurfaceArt.backdrop(c, "town", Vector2(-220 - 640, -100), 1.0, 640 * 3)
	roofs.modulate = Color(0.9, 0.9, 1.0)
	SurfaceArt.ground(c, -230, 800, 210, 1.0, 8, ["grass_a", "grass_b", "grass_c"], ["dirt_a", "dirt_b", "dirt_c"], 61)
	for spec in [["house_small", 34.0, [Vector2(38, 46)]], ["house_medium", 120.0, [Vector2(22, 56)]],
			["house_shop", 236.0, [Vector2(61, 66)]], ["house_big", 368.0, [Vector2(54, 44), Vector2(27, 88)]],
			["house_tower", 470.0, [Vector2(26, 31)]], ["house_tiny", 530.0, []]]:
		var house := _put(c, spec[0], Vector2(spec[1], 212))
		var top_left := house.position + house.offset
		for w in spec[2]:
			StoryPaint.glow(c, top_left + w, 10.0, Color(0.7, 0.84, 1.0), 0.6)
	for x in [176.0, 300.0]:
		_put(c, "lamp_post", Vector2(x, 211))
	var grass := StoryNodes.Tufts.new()
	grass.x0 = -220.0
	grass.x1 = 790.0
	grass.y = 213.0
	c.add_child(grass)
	# "That someone is a young witch named Echidna."
	var echidna := AnimatedSprite2D.new()
	echidna.name = "Echidna"
	echidna.sprite_frames = ECHIDNA
	echidna.offset = ECHIDNA.get_meta(&"sprite_offset", Vector2(0, -32))
	echidna.scale = Vector2.ONE * (0.812 / SurfaceArt.LANE_SCALE)
	echidna.position = Vector2(300 - 18, 211)
	echidna.modulate.a = 0.0
	c.add_child(echidna)
	echidna.play(&"idle")
	_cues[3] = func() -> void:
		var appear := p.create_tween()
		appear.tween_interval(0.3)
		appear.tween_property(echidna, "modulate:a", 1.0, 1.2)
