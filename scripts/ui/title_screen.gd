extends Node2D

## The front door. A slow, moody view of the ruined belfry with Echidna by a
## candle under a shaft of light; the title; and the menu: Continue (where
## you left off), New Game (the illustrated story, then Lowbell), the Tutorial,
## Settings & Controls, and Quit. A line under the menu shows progress.

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")
const TITLE_FONT_NAMES := ["Cinzel", "Trajan Pro", "Times New Roman", "Georgia", "Liberation Serif", "serif"]
const TUTORIAL := "res://scenes/tutorial_level.tscn"
const CHAPTER := "res://scenes/chapter/chapter_1.tscn"
const CHAPTER_2 := "res://scenes/chapter/chapter_2.tscn"
const STORY := "res://scenes/story/story_intro.tscn"
const FRAMES := preload("res://assets/sprites/Echidna/echidna_frames.tres")

var continue_button: Button
var new_button: Button
var tutorial_button: Button
var chapter_2_button: Button
var _menu: VBoxContainer
var _settings: VBoxContainer
var _progress: Label
var _new_armed := false
var _far: Sprite2D
var _mid: Sprite2D
var _time := 0.0
var _starting := false


func _ready() -> void:
	get_tree().paused = false
	AudioDirector.reset_combat()
	AudioDirector.duck(0.0, 0.5)
	Crosshair.arrow()
	var camera := Camera2D.new()
	add_child(camera)
	_build_scenery()
	_build_ui()
	_refresh()


# ------------------------------------------------------------------ scenery

func _build_scenery() -> void:
	var sky := ColorRect.new()
	sky.color = Color(0.03, 0.02, 0.06)
	sky.size = Vector2(3000, 2000)
	sky.position = Vector2(-1500, -1000)
	add_child(sky)
	_far = _backdrop("res://assets/fx/far_fog.png", Color(0.55, 0.55, 0.75, 0.9), 1.35)
	_mid = _backdrop("res://assets/fx/mid_ruins.png", Color(0.45, 0.42, 0.62), 1.2)
	var shaft := LightShaft.new()
	shaft.position = Vector2(-330, -340)
	shaft.length = 560.0
	shaft.width_top = 50.0
	shaft.width_bottom = 170.0
	shaft.angle_deg = 12.0
	shaft.intensity = 0.4
	add_child(shaft)
	# The floor she stands on
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([Vector2(-1500, 230), Vector2(1500, 230), Vector2(1500, 1000), Vector2(-1500, 1000)])
	ground.color = Color(0.06, 0.05, 0.1)
	add_child(ground)
	var lip := Line2D.new()
	lip.points = PackedVector2Array([Vector2(-1500, 230), Vector2(1500, 230)])
	lip.width = 3.0
	lip.default_color = Color(0.25, 0.22, 0.38)
	add_child(lip)
	var echidna := AnimatedSprite2D.new()
	echidna.sprite_frames = FRAMES
	echidna.offset = FRAMES.get_meta(&"sprite_offset", Vector2(0, -32))
	echidna.scale = Vector2(3, 3)
	echidna.position = Vector2(-300, 230)
	echidna.flip_h = true
	add_child(echidna)
	echidna.play(&"idle")
	# A candle beside her
	var candle := Node2D.new()
	candle.position = Vector2(-205, 212)
	add_child(candle)
	candle.add_child(GlowFX.halo(Color(1.0, 0.72, 0.42), 70.0, 0.5, 3.0, 0.2, 0.25))
	var embers := GlowFX.embers(Color(1.0, 0.7, 0.4), 10, 40.0, 10.0, 1.6)
	candle.add_child(embers)
	var wax := Polygon2D.new()
	wax.polygon = PackedVector2Array([Vector2(-4, 18), Vector2(4, 18), Vector2(4, 0), Vector2(-4, 0)])
	wax.color = Color(0.78, 0.72, 0.6)
	candle.add_child(wax)


func _backdrop(path: String, tint: Color, scale_by: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = load(path)
	sprite.modulate = tint
	sprite.scale = Vector2.ONE * scale_by
	add_child(sprite)
	return sprite


func _process(delta: float) -> void:
	_time += delta
	# A slow drift, as if the fog were breathing
	_far.position = Vector2(sin(_time * 0.05) * 30.0, -40.0 + sin(_time * 0.08) * 6.0)
	_mid.position = Vector2(sin(_time * 0.05) * 60.0, 10.0)


# ------------------------------------------------------------------ menu

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.offset_right = -90
	column.add_theme_constant_override("separation", 12)
	root.add_child(column)

	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(TITLE_FONT_NAMES)
	column.add_child(_label("The Sealed Belfry", serif, 58, Color("e2d6fa")))
	column.add_child(_label("A witch, a belfry, and a bell that has not rung in nine years.", FONT, 13, Color("a99ccf")))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	column.add_child(spacer)

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 8)
	column.add_child(_menu)
	continue_button = _button("Continue", _on_continue)
	_menu.add_child(continue_button)
	new_button = _button("New Game", _on_new_game)
	_menu.add_child(new_button)
	tutorial_button = _button("Tutorial", _on_tutorial)
	_menu.add_child(tutorial_button)
	chapter_2_button = _button("Chapter 2: The Sealed Observatory", func(): _start(CHAPTER_2))
	_menu.add_child(chapter_2_button)
	_menu.add_child(_button("Settings & Controls", func(): _show_settings(true)))
	_menu.add_child(_button("Quit", func(): get_tree().quit()))
	_progress = _label("", FONT, 13, Color("b8acd8"))
	_menu.add_child(_progress)

	_settings = VBoxContainer.new()
	_settings.visible = false
	_settings.add_theme_constant_override("separation", 10)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.1, 0.92)
	style.border_color = Color(0.5, 0.38, 0.78, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	for side in ["left", "right", "top", "bottom"]:
		style.set("content_margin_" + side, 18)
	panel.add_theme_stylebox_override("panel", style)
	panel.add_child(SettingsPanel.scrolled(400.0))
	_settings.add_child(panel)
	_settings.add_child(_button("Back", func(): _show_settings(false)))
	column.add_child(_settings)

	var foot := _label("F11 fullscreen", FONT, 11, Color("6d6488"))
	foot.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	foot.offset_left = 18
	foot.offset_top = -30
	root.add_child(foot)


func _label(text: String, font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 40)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(func(): Sfx.play("ui_click"); on_press.call())
	return b


func _show_settings(show: bool) -> void:
	_menu.visible = not show
	_settings.visible = show
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
	if GameState.has_flag("ch2.complete"):
		_progress.text = "Chapters 1 and 2 complete  ·  ledger pages %d / 7" % pages
	elif GameState.has_flag("ch1.complete"):
		_progress.text = "Chapter 1 complete  ·  ledger pages %d / 7" % pages
	elif rooms > 0 or pages > 0:
		_progress.text = "Chapter 1: %d of 9 rooms  ·  ledger pages %d / 7" % [rooms, pages]
	elif GameState.has_flag("tutorial.done"):
		_progress.text = "Tutorial complete"
	else:
		_progress.text = ""
	(continue_button if has_save else new_button).grab_focus()


## Where "Continue" goes: the level of your latest shrine or lesson, or the
## chapter once the tutorial is done; "" if there's nothing to continue.
func _continue_target() -> String:
	var scene := GameState.checkpoint_scene
	if scene != "" and ResourceLoader.exists(scene):
		return scene
	# Chapter 1 finished: on to Chapter 2
	if GameState.has_flag("ch1.complete") and not GameState.has_flag("ch2.complete"):
		return CHAPTER_2
	if GameState.has_flag("tutorial.done"):
		return CHAPTER
	return ""


func _on_continue() -> void:
	var target := _continue_target()
	if target != "":
		_start(target)


## Starts over (chapter progress is wiped; a finished tutorial stays
## finished). Asks for a second press if there is progress to lose.
func _on_new_game() -> void:
	var has_progress := GameState.checkpoint_scene != "" or GameState.count_flags("ch1.") > 0
	if has_progress and not _new_armed:
		_new_armed = true
		new_button.text = "Press again: start over"
		return
	var tutorial_done := GameState.has_flag("tutorial.done")
	GameState.clear_all()
	if tutorial_done:
		GameState.set_flag("tutorial.done")
	# The story, then Lowbell; the village leads on to the tutorial (or the
	# chapter, once the tutorial is done)
	_start(STORY)


func _on_tutorial() -> void:
	GameState.clear_checkpoint(TUTORIAL)
	_start(TUTORIAL)


func _start(path: String) -> void:
	if _starting:
		return
	_starting = true
	get_tree().change_scene_to_file(path)
