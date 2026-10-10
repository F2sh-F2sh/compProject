extends Node2D

## The front door. A slow, moody view of the ruined belfry behind a glass title and box-art showcase; and the menu: Continue (where
## you left off), New Game (the illustrated story, then Lowbell), the Tutorial
## ("The Novices' Way": the Passage, the Belfry, the Observatory),
## Settings & Controls, and Quit. A line under the menu shows progress.

const FONT := Fonts.UI
const AERO_BUTTON := preload("res://scripts/ui/aero_menu_button.gd")
const AERO_CHROME := preload("res://scripts/ui/aero_menu_chrome.gd")
const BOX_HOME := Vector2(724, 192)
const TURNING_BOX := preload("res://scripts/ui/turning_game_box.gd")
const TUTORIAL := Journey.PASSAGE
const CHAPTER := Journey.BELFRY
const CHAPTER_2 := Journey.OBSERVATORY
const STORY := Journey.STORY

var continue_button: Button
var new_button: Button
var tutorial_button: Button
var part_1_button: Button
var part_2_button: Button
var part_3_button: Button
var landing_button: Button
var admin_button: Button
var _parts: VBoxContainer
## ADMIN (temporary, see Journey.admin_unlock): every wing's rooms and the Eye.
var _admin: VBoxContainer
var _menu: VBoxContainer
var _settings: VBoxContainer
var _progress: Label
var _new_armed := false
var _far: Sprite2D
var _mid: Sprite2D
var _time := 0.0
var _wing: TextureRect
var _starting := false
var _box_art: TextureRect
var _description: Label
var _menu_column: VBoxContainer


func _ready() -> void:
	# Animated every drawn frame (tweens, drifting pictures): drawn as it is
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_tree().paused = false
	ChapterComplete.pending = {}
	AudioDirector.reset_combat()
	AudioDirector.duck(0.0, 0.5)
	Crosshair.arrow()
	var camera := Camera2D.new()
	add_child(camera)
	_build_scenery()
	_build_art()
	_build_ui()
	_refresh()


# ------------------------------------------------------------------ scenery

func _build_scenery() -> void:
	var sky := ColorRect.new()
	sky.color = Color(0.03, 0.02, 0.05)
	sky.size = Vector2(3000, 2000)
	sky.position = Vector2(-1500, -1000)
	add_child(sky)
	_far = _backdrop("res://assets/fx/far_fog.png", Color(0.42, 0.4, 0.56, 0.8), 1.35)
	_mid = _backdrop("res://assets/fx/mid_ruins.png", Color(0.28, 0.26, 0.38), 1.2)
	var shaft := LightShaft.new()
	shaft.position = Vector2(120, -340)
	shaft.length = 620.0
	shaft.width_top = 60.0
	shaft.width_bottom = 220.0
	shaft.angle_deg = -10.0
	shaft.intensity = 0.32
	add_child(shaft)


## Keep the ruined-belfry background, faint wing and drifting snow.
func _build_art() -> void:
	var art := CanvasLayer.new()
	art.layer = 1
	add_child(art)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(root)
	# The moth's wing, vast and faint, behind where the name sits
	var wing := TextureRect.new()
	wing.texture = SurfaceArt.tex("hk_moth", 0)
	wing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	wing.size = Vector2(200, 120) * 4.6
	wing.position = Vector2(470, -150)
	wing.modulate = Color(0.55, 0.65, 0.95, 0.16)
	wing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(wing)
	_wing = wing
	# Snow, slow, over everything
	var snow := StoryPaint.snow(root, Rect2(-100, -100, 1352, 900), 80)
	snow.speed_scale = 0.35
	snow.modulate.a = 0.7


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
	if _wing:
		_wing.position.y = -150.0 + sin(_time * 0.4) * 6.0


# ------------------------------------------------------------------ menu

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	layer.add_child(root)

	var chrome := AERO_CHROME.new()
	chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(chrome)
	var title_block := TextureRect.new()
	title_block.name = "TitleBlock"
	title_block.texture = preload("res://assets/ui/menu/aero_title.png")
	title_block.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_block.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_block.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Centre the visible logo pixels (including its transparent padding)
	# on the 485px options column and the header band at y=100.
	title_block.position = Vector2(140, 14)
	title_block.size = Vector2(320, 160)
	title_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title_block)
	var controls := _label("↑ ↓  SELECT     ENTER  CONFIRM\nMOUSE  SELECT     ESC  BACK", FONT, 20, Color("c6e1df"))
	controls.position = Vector2(688, 38)
	controls.size = Vector2(424, 60)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(controls)
	var mode := _label("BEGIN YOUR JOURNEY", FONT, 18, Color("b7c5d2"))
	mode.position = Vector2(68, 187)
	root.add_child(mode)
	_box_art = TURNING_BOX.new()
	_box_art.name = "BoxArt"
	_box_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_box_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_box_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_box_art.position = BOX_HOME
	_box_art.size = Vector2(256, 384)
	_box_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_box_art)
	_description = _label("", FONT, 22, Color("dfedf0"))
	_description.position = Vector2(68, 598)
	_description.size = Vector2(1036, 32)
	_description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_description)
	var column := VBoxContainer.new()
	_menu_column = column
	column.name = "MenuColumn"
	column.position = Vector2(60, 218)
	column.size = Vector2(485, 0)
	column.add_theme_constant_override("separation", 10)
	root.add_child(column)

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 8)
	column.add_child(_menu)
	continue_button = _button("Continue", _on_continue)
	_menu.add_child(continue_button)
	new_button = _button("New Game", _on_new_game)
	_menu.add_child(new_button)
	tutorial_button = _button("Choose a Level", _on_tutorial)
	_menu.add_child(tutorial_button)
	_menu.add_child(_button("Settings & Controls", func(): _show_settings(true)))
	_menu.add_child(_button("Quit", func(): get_tree().quit()))
	_progress = _label("", Fonts.STORY, 20, Color("d4c8b0"))
	_progress.custom_minimum_size = Vector2(485, 42)
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_menu.add_child(_progress)

	# "Choose a Level" opens the levels: Level 1 (the tutorial, the first place
	# in the dungeon), Level 2 and Level 3, all on the Novices' Way, then the
	# Long Stair
	_parts = VBoxContainer.new()
	_parts.visible = false
	_parts.add_theme_constant_override("separation", 6)
	column.add_child(_parts)
	_parts.add_child(_label("The Novices' Way", FONT, 16, Color("c9a24a")))
	part_1_button = _button("Level 1 · The Passage (tutorial)", _on_part_1)
	_parts.add_child(part_1_button)
	part_2_button = _button("Level 2 · The Belfry", func(): _jump_to(CHAPTER))
	_parts.add_child(part_2_button)
	part_3_button = _button("Level 3 · The Observatory", func(): _jump_to(CHAPTER_2))
	_parts.add_child(part_3_button)
	_parts.add_child(_label("After it", FONT, 16, Color("c9a24a")))
	landing_button = _button("The Long Stair · the four wings", func(): _jump_to(Journey.LANDING))
	_parts.add_child(landing_button)
	if Journey.admin_unlock:
		admin_button = _button("Admin: any wing, any room", func(): _show_admin(true))
		_parts.add_child(admin_button)
		_build_admin(column)
	_parts.add_child(_button("Back", func(): _show_parts(false)))
	for child in _parts.get_children():
		if child is Button:
			child.custom_minimum_size.y = 44
			child.label_size = 22

	_settings = VBoxContainer.new()
	_settings.visible = false
	_settings.add_theme_constant_override("separation", 10)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DungeonUI.panel_style())
	panel.add_child(SettingsPanel.scrolled(250.0))
	_settings.add_child(panel)
	_settings.add_child(_button("Back", func(): _show_settings(false)))
	column.add_child(_settings)

	var foot := _label("F11 fullscreen", FONT, 8, Color("6e6474"))
	foot.position = Vector2(906, 145)
	foot.size = Vector2(205, 24)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(foot)


func _label(text: String, font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", maxi(size, 18))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 4)
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := AERO_BUTTON.new()
	b.text = text
	b.custom_minimum_size = Vector2(485, 52)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(func(): Sfx.play("ui_click"); on_press.call())
	b.mouse_entered.connect(func():
		if not b.disabled:
			b.grab_focus()
			_describe(b.text))
	b.focus_entered.connect(func(): _describe(b.text))
	return b


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


func _on_tutorial() -> void:
	_show_parts(true)


func _show_parts(show: bool) -> void:
	_describe("Choose a Level" if show else "New Game")
	_menu.visible = not show
	_parts.visible = show
	_menu_column.call_deferred("reset_size")
	if show:
		part_1_button.grab_focus()
	else:
		tutorial_button.grab_focus()


## Part 1 always replays from its start.
func _on_part_1() -> void:
	GameState.clear_progress("ability.")
	GameState.clear_progress("tutorial.")
	GameState.set_flag("story.movement_done", false)
	GameState.clear_checkpoint(TUTORIAL)
	GameState.clear_checkpoint(Journey.MOVEMENT)
	_start(Journey.MOVEMENT)


## Starting a later part straight from the list: Echidna has the spells she
## would have remembered on the way there.
func _jump_to(path: String) -> void:
	Journey.skipping_to(path)
	_start(path)


# ------------------------------------------------------------------ admin (temporary)

## The admin page: every room of the four wings, and the Eye, each started
## directly with the spells and words of everything before it.
const ADMIN_ROOMS := [
	["Kilnworks · The Cold Forge", Journey.KILN, "R1"], ["Kilnworks · The Kiln Heart", Journey.KILN, "R2"],
	["Cistern · The Still Water", Journey.CISTERN, "R1"], ["Cistern · The Great Sluice", Journey.CISTERN, "R2"],
	["Lampworks · The Reading Room", Journey.LAMPS, "R1"], ["Lampworks · The Lamp Stair", Journey.LAMPS, "R2"],
	["Galleries · The First Door", Journey.GALLERIES, "R1"], ["Galleries · The Fold Bell", Journey.GALLERIES, "R2"],
	["The Eye", Journey.EYE, "R1"],
]


func _build_admin(column: VBoxContainer) -> void:
	_admin = VBoxContainer.new()
	_admin.visible = false
	_admin.add_theme_constant_override("separation", 8)
	column.add_child(_admin)
	_admin.add_child(_label("Admin: start any room (nothing before it needs finishing)", FONT, 13, Color("ffd88a")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	_admin.add_child(grid)
	for spec in ADMIN_ROOMS:
		var b := _button(spec[0], _admin_jump.bind(spec[1], spec[2]))
		b.custom_minimum_size = Vector2(296, 36)
		b.label_size = 17
		grid.add_child(b)
	_admin.add_child(_button("Back", func(): _show_admin(false)))


func _show_admin(show: bool) -> void:
	_box_art.visible = not show
	_menu_column.size.x = 600 if show else 485
	_parts.visible = not show
	_admin.visible = show
	if show:
		((_admin.get_child(1) as GridContainer).get_child(0) as Button).grab_focus()
	elif admin_button:
		admin_button.grab_focus()


func _admin_jump(path: String, room: String) -> void:
	Journey.admin_prepare(path, room)
	Journey.admin_start_room = room
	_start(path)


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
		"Choose a Level": _description.text = "Revisit a lesson or enter the chapters you have discovered."
		"Settings & Controls": _description.text = "Adjust sound, display, controls and accessibility."
		"Quit": _description.text = "Leave the belfry. Your saved journey will be waiting."
		"Back": _description.text = "Return to the previous menu."
		_: _description.text = option


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _settings.visible:
			_show_settings(false)
		elif _admin and _admin.visible:
			_show_admin(false)
		elif _parts.visible:
			_show_parts(false)
		else:
			return
		get_viewport().set_input_as_handled()
