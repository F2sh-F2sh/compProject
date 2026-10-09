extends Node2D

## The front door. A slow, moody view of the ruined belfry with Echidna by a
## candle under a shaft of light; the title; and the menu: Continue (where
## you left off), New Game (the illustrated story, then Lowbell), the Tutorial
## ("The Novices' Way": the Passage, the Belfry, the Observatory),
## Settings & Controls, and Quit. A line under the menu shows progress.

const FONT := Fonts.UI
const TUTORIAL := Journey.PASSAGE
const CHAPTER := Journey.BELFRY
const CHAPTER_2 := Journey.OBSERVATORY
const STORY := Journey.STORY
const FRAMES := preload("res://assets/sprites/Echidna/echidna_frames.tres")

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
var _portrait: TextureRect
var _portrait_y := 0.0
var _starting := false


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


## The title's art, laid out like a film poster: a tall crimson banner with
## Echidna's portrait large before it, the held moment's frozen wing faint
## behind the name, slow snow over everything.
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
	# The banner: crimson, edged in gold, a faint lattice in it
	var banner := Control.new()
	banner.position = Vector2(70, 0)
	banner.size = Vector2(300, 648)
	banner.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	banner.offset_left = 70
	banner.offset_right = 370
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.draw.connect(func():
		var s := banner.size
		banner.draw_rect(Rect2(Vector2.ZERO, s), Color("4a0f19"))
		for y in range(0, int(s.y), 28):
			for x in range(0, int(s.x) + 28, 28):
				var c := Vector2(x + (14 if (y / 28) % 2 == 1 else 0), y)
				if c.x < 18.0 or c.x > s.x - 18.0:
					continue
				banner.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0)]),
					Color("5e1622"))
		banner.draw_rect(Rect2(0, 0, 4, s.y), DungeonUI.GOLD_DIM)
		banner.draw_rect(Rect2(s.x - 4, 0, 4, s.y), DungeonUI.GOLD_DIM)
		banner.draw_rect(Rect2(8, 0, 2, s.y), Color("7a5f2a"))
		banner.draw_rect(Rect2(s.x - 10, 0, 2, s.y), Color("7a5f2a"))
		# a swallowtail at the foot
		banner.draw_colored_polygon(PackedVector2Array([Vector2(0, s.y - 40), Vector2(s.x / 2.0, s.y - 4), Vector2(s.x, s.y - 40),
			Vector2(s.x, s.y), Vector2(0, s.y)]), Color(0.02, 0.01, 0.03)))
	root.add_child(banner)
	# Down the banner's edge, small capitals, like a poster's side line
	var side := DungeonUI.caps("A WITCH  ·  A HELD NIGHT  ·  A BELL THAT WILL NOT RING", 16, Color("e6b45c"))
	side.rotation = -PI / 2.0
	side.position = Vector2(340, 560)
	root.add_child(side)
	# Light behind her, and Echidna herself, large, before the banner
	var halo := TextureRect.new()
	halo.texture = preload("res://assets/fx/soft_glow.png")
	halo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	halo.size = Vector2(560, 560)
	halo.position = Vector2(-20, 70)
	halo.modulate = Color(1.0, 0.75, 0.5, 0.35)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	halo.material = add
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(halo)
	_portrait = TextureRect.new()
	_portrait.texture = DialogueBox.portrait("echidna", "neutral")
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.size = DialogueBox.ART_SIZE * 4.0
	_portrait.position = Vector2(0, 648 - DialogueBox.ART_SIZE.y * 4.0 + 64.0)
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_portrait)
	_portrait_y = _portrait.position.y
	# Layered stone cards behind the menu, set at slight angles
	for spec in [[Vector2(700, 196), Vector2(400, 400), -0.05], [Vector2(716, 214), Vector2(380, 380), 0.03]]:
		var card := Panel.new()
		card.position = spec[0]
		card.size = spec[1]
		card.rotation = spec[2]
		card.modulate = Color(1, 1, 1, 0.55)
		card.add_theme_stylebox_override("panel", DungeonUI.lite_style())
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(card)
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
	if _portrait:
		_portrait.position.y = _portrait_y + roundf(sin(_time * 1.3) * 2.0)
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

	# The name, huge, across the top right, with a crimson shadow
	var title_block := VBoxContainer.new()
	title_block.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	title_block.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	title_block.offset_right = -56
	title_block.offset_top = 22
	title_block.add_theme_constant_override("separation", 0)
	title_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title_block)
	for words in ["The Sealed", "Belfry"]:
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(520, 86)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_block.add_child(holder)
		var shadow := _label(words, Fonts.TITLE, 84, Color("7a1f2b"))
		shadow.position = Vector2(5, 5)
		shadow.size = holder.custom_minimum_size
		shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		holder.add_child(shadow)
		var big := _label(words, Fonts.TITLE, 84, Color("f0d27a"))
		big.size = holder.custom_minimum_size
		big.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		holder.add_child(big)
	title_block.add_child(DungeonUI.divider(520.0))
	var tagline := _label("A witch, a frozen night, and a bell that has not rung in nine years.", Fonts.BOOK_ITALIC, 20, Color("d9c9a8"))
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_block.add_child(tagline)

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.offset_right = -100
	column.offset_top = 250
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
	_progress = _label("", Fonts.STORY, 16, Color("b9ab90"))
	_menu.add_child(_progress)

	# "Choose a Level" opens the levels: Level 1 (the tutorial, the first place
	# in the dungeon), Level 2 and Level 3, all on the Novices' Way, then the
	# Long Stair
	_parts = VBoxContainer.new()
	_parts.visible = false
	_parts.add_theme_constant_override("separation", 8)
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

	_settings = VBoxContainer.new()
	_settings.visible = false
	_settings.add_theme_constant_override("separation", 10)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", DungeonUI.panel_style())
	panel.add_child(SettingsPanel.scrolled(400.0))
	_settings.add_child(panel)
	_settings.add_child(_button("Back", func(): _show_settings(false)))
	column.add_child(_settings)

	var foot := _label("F11 fullscreen", FONT, 8, Color("6e6474"))
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
	b.custom_minimum_size = Vector2(340, 46)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 16)
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
	_show_parts(true)


func _show_parts(show: bool) -> void:
	_menu.visible = not show
	_parts.visible = show
	if show:
		part_1_button.grab_focus()
	else:
		tutorial_button.grab_focus()


## Part 1 always replays from its start.
func _on_part_1() -> void:
	GameState.clear_checkpoint(TUTORIAL)
	_start(TUTORIAL)


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
		b.custom_minimum_size = Vector2(290, 36)
		b.add_theme_font_size_override("font_size", 14)
		grid.add_child(b)
	_admin.add_child(_button("Back", func(): _show_admin(false)))


func _show_admin(show: bool) -> void:
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
