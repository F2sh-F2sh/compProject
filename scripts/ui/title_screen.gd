extends Node2D

## The front door, composed like a painted establishing shot: a night sky
## and moon over the monastery on its crag, the woods below it, and on the
## right a ruined shrine where the cracked bell hangs in lantern light, with
## Echidna small before it; snow and drifting motes over it all. The glass
## logo sits top left, the menu is plain words bottom left (no boxes), and the
## version bottom right. The menu: Continue (where you left off), New Game
## (the illustrated story, then Lowbell), Daily Puzzle (generated puzzles and
## the Endless mode), Settings & Controls, and Quit. A line under the menu shows progress.

const FONT := Fonts.UI
const MENU_FONT := Fonts.BOOK
const VERSION := "Version 1.0"
const TUTORIAL := Journey.PASSAGE
const CHAPTER := Journey.BELFRY
const CHAPTER_2 := Journey.OBSERVATORY
const STORY := Journey.STORY
## Screen size the scene is composed for (the window grows it, never shrinks).
const VIEW := Vector2(1152, 648)
const GOLD := Color("f0d27a")
const INK := Color("e8dcc0")

var continue_button: Button
var new_button: Button
var daily_button: Button
var _menu: VBoxContainer
var _settings: VBoxContainer
var _progress: Label
var _new_armed := false
var _time := 0.0
var _starting := false
## The shrine on the right: the picture's focus, which the menu leaves clear.
var _box_art: TextureRect
var _description: Label
var _menu_column: VBoxContainer
var _layers: Array = []
var _bell: AnimatedSprite2D
var _echidna: AnimatedSprite2D


func _ready() -> void:
	# Animated every drawn frame (tweens, drifting pictures): drawn as it is
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_tree().paused = false
	ChapterComplete.pending = {}
	AudioDirector.reset_combat()
	AudioDirector.duck(0.0, 0.5)
	Crosshair.arrow()
	_build_scene()
	_build_ui()
	_refresh()


# ------------------------------------------------------------------ the picture

## A layer of the picture that drifts `drift` pixels side to side, slowly.
func _layer(layer_name: String, drift: float) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	_scene_root.add_child(layer)
	_layers.append([layer, drift])
	return layer


var _scene_root: Node2D


func _build_scene() -> void:
	var scene := CanvasLayer.new()
	scene.name = "Scene"
	scene.layer = 0
	add_child(scene)
	_scene_root = Node2D.new()
	_scene_root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scene.add_child(_scene_root)
	var night := ColorRect.new()
	night.color = Color("0b0a16")
	night.size = VIEW * 2.0
	_scene_root.add_child(night)

	# The sky and the moon
	var sky := _layer("Sky", 6.0)
	_painting(sky, "sky", Vector2(-80, -40), 2.1, false)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(0, 0, VIEW.x / 2.0, 150)
	stars.count = 70
	stars.scale = Vector2(2, 2)
	sky.add_child(stars)
	# The monastery on its crag, far off between the words and the shrine
	var hills := _layer("Hills", 12.0)
	_painting(hills, "hills", Vector2(150, 40), 2.0, false).modulate = Color(0.95, 0.95, 1.1)
	# The woods, nearer and darker
	var woods := _layer("Woods", 22.0)
	_painting(woods, "woods", Vector2(-160, 150), 2.2, false).modulate = Color(0.5, 0.52, 0.7)
	# Mist lying in the valley
	_scene_root.add_child(_band(Rect2(0, 430, VIEW.x, 120), Color(0.42, 0.44, 0.62, 0.0), Color(0.42, 0.44, 0.62, 0.35)))

	# The shrine: a ruined arch, the cracked bell hanging in it, lantern light
	var shrine := _layer("Shrine", 0.0)
	var ground_y := 560.0
	var arch := SurfaceArt.sprite(shrine, "hk_arch", Vector2(900, ground_y), 2.0)
	arch.modulate = Color(0.62, 0.62, 0.8)
	for x in [722.0, 1078.0]:
		SurfaceArt.sprite(shrine, "hk_pillar", Vector2(x, ground_y + 6), 1.6).modulate = Color(0.48, 0.48, 0.66)
	StoryPaint.glow(shrine, Vector2(900, 400), 170, Color(1.0, 0.78, 0.46, 0.22), 0.9)
	_bell = SurfaceArt.animated(shrine, "great_bell", Vector2(900, 412), 1.2, 2.0)
	_bell.modulate = Color(1.0, 0.92, 0.78)
	# Kindled bowls either side of the arch, candles on the stones
	for x in [800.0, 1000.0]:
		SurfaceArt.animated(shrine, "kept_flame", Vector2(x, ground_y), 6.0, 1.0)
		StoryPaint.glow(shrine, Vector2(x, ground_y - 30), 60, Color(1.0, 0.7, 0.4, 0.3), 1.0)
	SurfaceArt.sprite(shrine, "hk_crystals", Vector2(1110, ground_y + 4), 1.4).modulate = Color(0.6, 0.75, 1.0)
	# Echidna, small before it, her lantern lit
	_echidna = AnimatedSprite2D.new()
	_echidna.sprite_frames = load("res://assets/sprites/echidna/echidna_frames.tres")
	_echidna.animation = &"idle"
	_echidna.play()
	_echidna.flip_h = false
	_echidna.scale = Vector2(1.3, 1.3)
	_echidna.offset = Vector2(0, -32)
	_echidna.position = Vector2(838, ground_y + 2)
	shrine.add_child(_echidna)
	var lantern := SurfaceArt.animated(shrine, "desk_lantern", Vector2(866, ground_y - 22), 6.0, 0.9)
	lantern.name = "Lantern"
	StoryPaint.glow(shrine, Vector2(866, ground_y - 34), 44, Color(1.0, 0.8, 0.5, 0.45), 1.0)
	# Light falling through the arch
	var shaft := LightShaft.new()
	shaft.position = Vector2(960, -40)
	shaft.length = 600.0
	shaft.width_top = 50.0
	shaft.width_bottom = 230.0
	shaft.angle_deg = 12.0
	shaft.intensity = 0.26
	_scene_root.add_child(shaft)

	# The near ground: rocks and long grass right across, dark as silhouettes
	var near := _layer("Near", 0.0)
	var ground := ColorRect.new()
	ground.color = Color("0d0b14")
	ground.position = Vector2(0, ground_y)
	ground.size = Vector2(VIEW.x * 2.0, 200)
	near.add_child(ground)
	# (low, at the edges only: they frame the shrine and never hide it)
	for spec in [[Vector2(80, ground_y + 64), 2.0], [Vector2(1240, ground_y + 58), 2.0]]:
		SurfaceArt.sprite(near, "hk_rocks", spec[0], spec[1]).modulate = Color(0.16, 0.15, 0.24)
	for x in range(0, int(VIEW.x * 2.0), 400):
		SurfaceArt.sprite(near, "hk_grass", Vector2(x + 300, VIEW.y + 14), 2.0).modulate = Color(0.12, 0.12, 0.2)
	# The left side falls into shadow, so the words read on it
	_scene_root.add_child(_band_h(Rect2(0, 0, 640, VIEW.y * 2.0), Color(0.03, 0.02, 0.06, 0.78), Color(0.03, 0.02, 0.06, 0.0)))

	# Snow over everything, and warm motes round the shrine
	var air := Control.new()
	air.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene.add_child(air)
	var snow := StoryPaint.snow(air, Rect2(-100, -100, VIEW.x + 300, VIEW.y + 200), 80)
	snow.speed_scale = 0.35
	snow.modulate.a = 0.6
	StoryPaint.motes(_scene_root, Rect2(720, 330, 380, 230), Color(1.0, 0.8, 0.5, 0.45), 26)


## One of the surface pack's 640x320 paintings, scaled, from `at`.
func _painting(parent: Node2D, name_: String, at: Vector2, scale_by: float, flip: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = SurfaceArt.BACKDROPS[name_]
	s.centered = false
	s.position = at
	s.scale = Vector2(scale_by, scale_by)
	s.flip_h = flip
	parent.add_child(s)
	return s


## A vertical fade from `top` to `bottom` over `rect`.
func _band(rect: Rect2, top: Color, bottom: Color) -> TextureRect:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([top, bottom])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	var t := TextureRect.new()
	t.texture = tex
	t.position = rect.position
	t.size = rect.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## A horizontal fade from `left` to `right` over `rect`.
func _band_h(rect: Rect2, left: Color, right: Color) -> TextureRect:
	var t := _band(rect, left, right)
	(t.texture as GradientTexture2D).fill_to = Vector2(1, 0)
	return t


func _process(delta: float) -> void:
	_time += delta
	# The distance breathes, very slowly
	for entry in _layers:
		entry[0].position.x = sin(_time * 0.05) * entry[1]
	if _bell:
		_bell.rotation = sin(_time * 0.6) * 0.03


# ------------------------------------------------------------------ menu

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	var title_block := TextureRect.new()
	title_block.name = "TitleBlock"
	title_block.texture = preload("res://assets/ui/menu/title_logo.png")
	title_block.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_block.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_block.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	title_block.position = Vector2(64, 40)
	title_block.size = Vector2(400, 200)
	title_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title_block)
	# The shrine, kept clear of the menu (the picture's focus)
	_box_art = TextureRect.new()
	_box_art.name = "BoxArt"
	_box_art.position = Vector2(700, 300)
	_box_art.size = Vector2(420, 270)
	_box_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_box_art)
	var version := _label(VERSION, MENU_FONT, 18, Color(INK, 0.55))

	version.position = Vector2(VIEW.x - 200, VIEW.y - 46)
	version.size = Vector2(168, 28)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(version)
	var credit := _label("Created by Ishaan Tiwari and Aarav Singh", MENU_FONT, 18, Color(INK, 0.55))
	credit.name = "Credit"
	credit.position = Vector2(VIEW.x - 432, VIEW.y - 72)
	credit.size = Vector2(400, 28)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(credit)
	_description = _label("", Fonts.BOOK_ITALIC, 18, Color(INK, 0.7))
	_description.position = Vector2(96, VIEW.y - 54)
	_description.size = Vector2(620, 28)
	_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_description)
	var column := VBoxContainer.new()
	_menu_column = column
	column.name = "MenuColumn"
	column.position = Vector2(84, 262)
	column.size = Vector2(440, 0)
	column.add_theme_constant_override("separation", 10)
	root.add_child(column)

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 2)
	column.add_child(_menu)
	continue_button = _button("Continue", _on_continue)
	_menu.add_child(continue_button)
	new_button = _button("New Game", _on_new_game)
	_menu.add_child(new_button)
	daily_button = _button("Daily Puzzle", _on_daily)
	_menu.add_child(daily_button)
	_menu.add_child(_button("Settings & Controls", func(): _show_settings(true)))
	_menu.add_child(_button("Quit", func(): AudioDirector.quit_game()))
	_progress = _label("", MENU_FONT, 18, Color(GOLD, 0.75))
	_progress.custom_minimum_size = Vector2(440, 30)
	_progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu.add_child(_progress)

	_settings = VBoxContainer.new()
	_settings.visible = false
	_settings.add_theme_constant_override("separation", 10)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DungeonUI.panel_style())
	panel.add_child(SettingsPanel.scrolled(250.0))
	_settings.add_child(panel)
	_settings.add_child(_button("Back", func(): _show_settings(false)))
	column.add_child(_settings)


func _label(text: String, font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", maxi(size, 16))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := MenuWord.new()
	b.text = text
	b.pressed.connect(func(): Sfx.play("ui_click"); on_press.call())
	b.mouse_entered.connect(func():
		if not b.disabled:
			b.grab_focus()
			_describe(b.text))
	b.focus_entered.connect(func(): _describe(b.text))
	return b


## A menu word: no box, parchment ink; the chosen word turns gold and a small
## gold diamond appears beside it (like a painted title screen's menu).
class MenuWord extends Button:
	var label_size := 32:
		set(value):
			label_size = value
			add_theme_font_size_override("font_size", value)
			custom_minimum_size.y = value + 14

	func _init() -> void:
		flat = true
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(440, label_size + 14)
		add_theme_font_override("font", MENU_FONT)
		add_theme_font_size_override("font_size", label_size)
		var empty := StyleBoxEmpty.new()
		empty.content_margin_left = 34
		for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(state, empty)
		add_theme_color_override("font_color", INK)
		add_theme_color_override("font_hover_color", GOLD)
		add_theme_color_override("font_focus_color", GOLD)
		add_theme_color_override("font_pressed_color", GOLD)
		add_theme_color_override("font_hover_pressed_color", GOLD)
		add_theme_color_override("font_disabled_color", Color(INK, 0.32))
		add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		add_theme_constant_override("outline_size", 5)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)

	func _draw() -> void:
		if not has_focus() or disabled:
			return
		var y := size.y / 2.0
		var c := Vector2(16, y)
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -7), c + Vector2(7, 0), c + Vector2(0, 7), c + Vector2(-7, 0)]), Color(0, 0, 0, 0.6))
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(5, 0), c + Vector2(0, 5), c + Vector2(-5, 0)]), GOLD)
		draw_line(Vector2(34, size.y - 6), Vector2(34 + get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, get_theme_font_size("font_size")).x, size.y - 6), Color(GOLD, 0.45), 1.0)


func _show_settings(show: bool) -> void:
	_describe("Settings & Controls" if show else "New Game")
	_menu.visible = not show
	_settings.visible = show
	_menu_column.call_deferred("reset_size")
	if show:
		(_settings.get_child(1) as Button).grab_focus()
	else:
		_refresh()


## What there is to continue, and the line of progress under the menu.
func _refresh() -> void:
	var has_save := _continue_target() != ""
	continue_button.disabled = not has_save
	var rooms := GameState.count_flags("ch1.clear.")
	var pages := GameState.count_flags("ch1.page.")
	if GameState.has_flag("game.complete"):
		_progress.text = "The game is complete  ·  the sky was rewritten"
	elif GameState.has_flag("ch2.complete"):
		_progress.text = "The Long Stair: %d of 4 bells rung" % Journey.bells_rung()
		if Journey.eye_open():
			_progress.text = "The Long Stair: all four bells rung; the Eye is open"
	elif GameState.has_flag("ch1.complete"):
		_progress.text = "Level 2 done  ·  ledger pages %d / 7" % pages
	elif rooms > 0 or pages > 0:
		_progress.text = "Level 2: %d of 9 rooms  ·  ledger pages %d / 7" % [rooms, pages]
	elif GameState.has_flag("tutorial.done"):
		_progress.text = "Level 1 done"
	else:
		_progress.text = ""
	(continue_button if has_save else new_button).grab_focus()


## Where "Continue" goes: the level of your latest shrine or lesson, or the
## chapter once the tutorial is done; "" if there's nothing to continue.
func _continue_target() -> String:
	var scene := GameState.checkpoint_scene
	if scene != "" and ResourceLoader.exists(scene):
		return scene
	# The Novices' Way done: the Long Stair (its Landing)
	if GameState.has_flag("ch2.complete"):
		return Journey.LANDING
	# Chapter 1 finished: on to Chapter 2
	if GameState.has_flag("ch1.complete") and not GameState.has_flag("ch2.complete"):
		if not GameState.has_flag("story.bell_echo_seen"):
			return Journey.BELL_INTERLUDE
		return CHAPTER_2
	if GameState.has_flag("tutorial.done"):
		return CHAPTER
	if GameState.has_flag("story.movement_done"):
		return TUTORIAL
	return ""


func _on_continue() -> void:
	var target := _continue_target()
	if target != "":
		_start(target)


## Starts over with cleared story, chapter, tutorial and spell progress.
## Asks for a second press if there is progress to lose.
func _on_new_game() -> void:
	var has_progress := GameState.checkpoint_scene != "" or GameState.count_flags("ch1.") > 0
	if has_progress and not _new_armed:
		_new_armed = true
		new_button.text = "Press again: start over"
		return
	GameState.clear_all()
	# The story, then Lowbell; the village leads on to the tutorial (or the
	# chapter, once the tutorial is done)
	_start(STORY)


func _start(path: String) -> void:
	if _starting:
		return
	_starting = true
	SceneFade.change(get_tree(), path)


func _describe(option: String) -> void:
	if not _description: return
	match option:
		"Continue": _description.text = "Return to your last shrine and continue Echidna's journey."
		"New Game", "Press again: start over": _description.text = "A frozen night. A silent bell. Begin Echidna's story."
		"Daily Puzzle": _description.text = "A new puzzle every day, the same for everyone. How many ways can you find?"
		"Settings & Controls": _description.text = "Adjust sound, display, controls and accessibility."
		"Quit": _description.text = "Leave the belfry. Your saved journey will be waiting."
		"Back": _description.text = "Return to the previous menu."
		_: _description.text = option


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _settings.visible:
			_show_settings(false)
		else:
			return
		get_viewport().set_input_as_handled()


## The Daily Puzzle screen (a new puzzle every day, a streak, a board).
func _on_daily() -> void:
	# The title's own words are hidden meanwhile, so arrow keys and a pad
	# can't wander from the Daily Puzzle screen onto them.
	_menu_column.visible = false
	var menu := DailyMenu.open(self)
	menu.closed.connect(func():
		_menu_column.visible = true
		daily_button.grab_focus())
