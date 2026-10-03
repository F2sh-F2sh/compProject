class_name PauseMenu
extends CanvasLayer

## The Esc menu, laid out like a floating system menu: Echidna's card on the
## left, a column of round icons, and lists that cascade out to the right.
## Hovering an icon (or moving to it with the keys or a pad) rings it in
## orange with an arrow and slides its list out; hovering a row slides out
## the next list. The active row is solid orange. Crisp chimes play on hover
## and solid beeps on select.
##
##   Resume
##   Echidna   Spells, Abilities, Runes      -> the card describes each one
##   Map       Room Map, Reset Room
##   Journal   The Bellkeeper's Ledger, Rune Journal
##   Settings  Graphics, Controls, Audio, Gameplay -> every option
##   System    Restart, Return to Title, Quit Game
##
## Keys: up/down move, right or confirm goes in (or does it), left or Esc
## backs out one step; Esc on the icons closes the menu. Left/right change a
## volume. Unavailable while the death screen is up; the chapter-only parts
## hide themselves in the tutorial.

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")
const FONT_BODY := preload("res://assets/Text/Orbitron-Medium.ttf")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const FRAMES := "res://assets/sprites/Echidna/echidna_frames.tres"
const SOUNDS := "res://assets/audio/sfx/sao_%s.wav"

const ORANGE := Color("f0a21e")
const ICON_DARK := Color("3b3b40")
const ICON_RING := Color("a9a9ae")
const ROW_GREY := Color(0.32, 0.32, 0.34, 0.95)
const ROW_WHITE := Color("f5f5f5")
const TEXT_LIGHT := Color("ececec")
const TEXT_DARK := Color("252525")
const TEXT_MUTED := Color("7b7b80")
const CARD_WHITE := Color("f2f2f2")
const INFO_GREY := Color("d4d4d7")

const FRAME_SIZE := Vector2(910, 470)
const CARD_RECT := Rect2(0, 20, 330, 440)
const ICON_X := 358.0
const ICON_SIZE := 56.0
const ICON_STEP := 68.0
const SUB1_X := 440.0
const SUB1_W := 200.0
const SUB2_X := 654.0
const SUB2_W := 256.0
const SUB2_VIEW_H := 400.0
const ROW_H := 40.0
const SLOTS := 12

## The controls that can be rebound, with short names for the list.
const CONTROLS := [
	["Walk left", "move_left"], ["Walk right", "move_right"], ["Jump", "jump"],
	["Crouch / charge", "crouch"], ["Sprint", "sprint"], ["Fireball", "shoot"],
	["Heal", "heal"], ["Kindle (mana)", "reload"], ["Echo", "echo"],
	["Use / inscribe", "interact"], ["Carry a cube", "rune_carry"],
	["Rune overview", "rune_overview"], ["Pause", "pause"],
]
const GRAPHICS_INFO := [
	"For slower graphics cards: no bloom, film grain, shadows, light shafts or puddle reflections, and fewer motes.",
	"Soft bloom and hard-edged shadows, reflections in puddles, a lighter scatter of motes.",
	"The game as designed: bloom, grain, soft shadows, light shafts and reflective water.",
	"Smoother shadows from a larger shadow map, and more drifting motes.",
	"Everything at its best: the smoothest, sharpest shadows, the most motes and the most detailed water.",
]

var is_open := false
## Set while the room can't be finished: opening the menu goes straight to
## Map -> Reset Room, with the reason on the card.
static var reset_suggested := false
static var reset_reason := ""
var played := {}

var _dim: ColorRect
var _frame: Control
var _pointer: Control
var _card: PanelContainer
var _views: Array[Control] = []
var _menu_box: VBoxContainer
var _map_box: VBoxContainer
var _map_list: VBoxContainer
var _ledger_box: VBoxContainer
var _ledger_list: VBoxContainer
var _journal_box: VBoxContainer
var _journal_list: VBoxContainer
var _figure: Control
var _stats: Label
var _info_title: Label
var _info_body: Label
var _info_glyph := "person"
var _info_icon: Control
var _slot := 8

var _icons: Array[SaoIcon] = []
var _icon_by_id := {}
var _sub1_lists := {}
var _sub2_lists := {}
var _sub2_view: TextureRect
var _col := 0
var _icon_index := 0
var _row1 := -1
var _row2 := -1
var _list1: VBoxContainer
var _list2: VBoxContainer

var _resume_button: SaoIcon
var _map_button: SaoRow
var _reset_button: SaoRow
var _ledger_button: SaoRow
var _journal_button: SaoRow
var _runes_button: SaoRow
var _restart_button: SaoRow
var _restart_armed := false
var _runes_list: VBoxContainer
var _waiting_action := ""
var _value_rows: Array[SaoRow] = []

var _hover_player: AudioStreamPlayer
var _select_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _streams := {}


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_audio()
	_build()
	Settings.changed.connect(_on_settings_changed)
	_set_open(false)


func _on_settings_changed() -> void:
	if is_open:
		_refresh_values()


# ------------------------------------------------------------------ audio

## One player per kind of cue, on the SFX bus, so a hover never cuts off a
## select; open, close and back share the third.
func _build_audio() -> void:
	for kind in ["hover", "select", "open", "close", "back"]:
		var path := SOUNDS % kind
		if ResourceLoader.exists(path):
			_streams[kind] = load(path)
	_hover_player = _audio_player("HoverSound", "hover", -6.0)
	_select_player = _audio_player("SelectSound", "select", -4.0)
	_ui_player = _audio_player("MenuSound", "open", -5.0)


func _audio_player(node_name: String, kind: String, volume: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = node_name
	p.bus = Settings.SFX_BUS
	p.volume_db = volume
	p.stream = _streams.get(kind)
	add_child(p)
	return p


func _play(kind: String) -> void:
	played[kind] = int(played.get(kind, 0)) + 1
	var p := _hover_player if kind == "hover" else (_select_player if kind == "select" else _ui_player)
	if p == _ui_player:
		p.stream = _streams.get(kind)
	if p.stream:
		p.play()


# ------------------------------------------------------------------ open / close

func _unhandled_input(event: InputEvent) -> void:
	if is_open or not event.is_action_pressed("pause", false):
		return
	# Another screen (a rune cube, a page) has the game paused and owns Esc
	if _death_screen_up() or get_tree().paused:
		return
	get_viewport().set_input_as_handled()
	_set_open(true)


func _death_screen_up() -> bool:
	var death := get_tree().get_first_node_in_group("death_screen")
	return death != null and death.visible


func _set_open(open: bool) -> void:
	var was_open := is_open
	is_open = open
	_dim.visible = open
	_frame.visible = open
	get_tree().paused = open
	_restart_armed = false
	_restart_button.text = "Restart"
	_waiting_action = ""
	_show(_menu_box)
	if open:
		Crosshair.arrow()
		_refresh_availability()
		_fill_runes()
		_refresh_values()
		_col = 0
		_row1 = -1
		_row2 = -1
		_focus_icon(_first_icon(), false, false)
		if reset_suggested and not _reset_button.disabled:
			focus_reset_room()
		_play("open")
		_animate_open()
	else:
		if was_open:
			_play("close")
		if get_tree().get_first_node_in_group("player") != null:
			Crosshair.restore()


func _animate_open() -> void:
	var tween := create_tween().set_parallel()
	_card.modulate.a = 0.0
	_card.position.x = CARD_RECT.position.x - 30.0
	tween.tween_property(_card, "modulate:a", 1.0, 0.22)
	tween.tween_property(_card, "position:x", CARD_RECT.position.x, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var n := 0
	for icon in _icons:
		if not icon.visible:
			continue
		var y := icon.position.y
		icon.modulate.a = 0.0
		icon.position.y = y - 26.0
		tween.tween_property(icon, "modulate:a", 1.0, 0.16).set_delay(n * 0.04)
		tween.tween_property(icon, "position:y", y, 0.2).set_delay(n * 0.04).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		n += 1


func _chapter_root() -> Node:
	return get_tree().get_first_node_in_group("chapter_root")


func _refresh_availability() -> void:
	var root := _chapter_root()
	var runes := get_tree().get_first_node_in_group("rune_manager") != null
	_map_button.visible = root != null
	_reset_button.disabled = root == null or root.current_room == null
	_restart_button.visible = root != null
	_ledger_button.visible = root != null and root.total_pages > 0
	_journal_button.visible = runes
	_runes_button.visible = runes
	_icon_by_id["map"].visible = root != null
	_icon_by_id["journal"].visible = _ledger_button.visible or _journal_button.visible
	var y := 0.0
	for icon in _icons:
		if icon.visible:
			icon.position = Vector2(ICON_X, 26.0 + y)
			y += ICON_STEP


# ------------------------------------------------------------------ actions

## Wipes this chapter's saved progress and starts it over. Asks for a second
## press first, since it cannot be undone.
func _on_restart() -> void:
	_play("select")
	if not _restart_armed:
		_restart_armed = true
		_restart_button.text = "Press again to confirm"
		_set_info("Restart", "Press again to erase this %s's saved progress and start it over. This cannot be undone." % _unit(), "reset", 6)
		return
	var root := _chapter_root()
	if root == null:
		return
	GameState.clear_progress(root.chapter_id)
	_set_open(false)
	get_tree().reload_current_scene()


func _on_reset() -> void:
	_play("select")
	_set_open(false)
	var root := _chapter_root()
	if root:
		root.reset_current_room()


func _on_title() -> void:
	_play("select")
	_set_open(false)
	get_tree().change_scene_to_file(TITLE_SCENE)


# ------------------------------------------------------------------ building

func _build() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.0, 0.0, 0.02, 0.62)
	add_child(_dim)

	_frame = Control.new()
	_frame.set_anchors_preset(Control.PRESET_CENTER)
	_frame.offset_left = -FRAME_SIZE.x / 2.0
	_frame.offset_right = FRAME_SIZE.x / 2.0
	_frame.offset_top = -FRAME_SIZE.y / 2.0
	_frame.offset_bottom = FRAME_SIZE.y / 2.0
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	_build_card()
	_pointer = Control.new()
	_pointer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.draw.connect(_draw_pointers)
	_frame.add_child(_pointer)

	# The second list sits in a window that fades out at its top and bottom
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.1, 0.9, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var mask := GradientTexture2D.new()
	mask.gradient = fade
	mask.fill_from = Vector2(0, 0)
	mask.fill_to = Vector2(0, 1)
	mask.width = 4
	mask.height = 64
	_sub2_view = TextureRect.new()
	_sub2_view.texture = mask
	_sub2_view.stretch_mode = TextureRect.STRETCH_SCALE
	_sub2_view.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	_sub2_view.clip_contents = true
	_sub2_view.position = Vector2(SUB2_X, (FRAME_SIZE.y - SUB2_VIEW_H) / 2.0)
	_sub2_view.size = Vector2(SUB2_W + 12.0, SUB2_VIEW_H)
	_sub2_view.mouse_filter = Control.MOUSE_FILTER_PASS
	_sub2_view.gui_input.connect(_on_sub2_wheel)
	_frame.add_child(_sub2_view)

	_resume_button = _icon("resume", "play", "Resume", [], _close_from_menu)
	_icon("echidna", "person", "Echidna", [
		_row("Spells", "flame", _spell_list()),
		_row("Abilities", "jump", _ability_list()),
		_runes_row(),
	])
	_map_button = _row("Room Map", "list", null, func(): _play("select"); _show(_map_box))
	_reset_button = _row("Reset Room", "reset", null, _on_reset)
	_icon("map", "map", "Map", [_map_button, _reset_button])
	_ledger_button = _row("The Ledger", "book", null, func(): _play("select"); _show(_ledger_box))
	_journal_button = _row("Rune Journal", "rune", null, func(): _play("select"); _show(_journal_box))
	_icon("journal", "book", "Journal", [_ledger_button, _journal_button])
	_icon("settings", "gear", "Settings", [
		_row("Graphics", "monitor", _graphics_list()),
		_row("Controls", "keys", _controls_list()),
		_row("Audio", "speaker", _audio_list()),
		_row("Gameplay", "sliders", _gameplay_list()),
	])
	_restart_button = _row("Restart", "reset", null, _on_restart)
	_icon("system", "power", "System", [
		_restart_button,
		_row("Return to Title", "door", null, _on_title),
		_row("Quit Game", "cross", null, func(): _play("select"); get_tree().quit()),
	])
	_describe_rows()


func _build_card() -> void:
	_card = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_WHITE
	style.set_corner_radius_all(2)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	_card.add_theme_stylebox_override("panel", style)
	_card.position = CARD_RECT.position
	_card.custom_minimum_size = CARD_RECT.size
	_card.size = CARD_RECT.size
	_frame.add_child(_card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_card.add_child(column)
	var name_label := _label("Echidna", 17, TEXT_DARK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(name_label)
	var rule := ColorRect.new()
	rule.color = Color(0.3, 0.3, 0.32)
	rule.custom_minimum_size = Vector2(0, 1)
	column.add_child(rule)
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(306, 386)
	column.add_child(stack)

	# Status: her figure in a ring of slots, her numbers, and a description
	_menu_box = _card_view(stack)
	_figure = Control.new()
	_figure.custom_minimum_size = Vector2(306, 226)
	_figure.draw.connect(_draw_figure)
	_menu_box.add_child(_figure)
	var frames: SpriteFrames = load(FRAMES)
	var model := AnimatedSprite2D.new()
	model.sprite_frames = frames
	model.animation = &"idle"
	model.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	model.offset = frames.get_meta(&"sprite_offset", Vector2(0, -32))
	model.scale = Vector2(2.3, 2.3)
	model.position = Vector2(153, 196)
	_figure.add_child(model)
	model.play()
	_stats = _label("", 12, TEXT_MUTED)
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu_box.add_child(_stats)
	var notch := Control.new()
	notch.custom_minimum_size = Vector2(0, 7)
	notch.draw.connect(func(): notch.draw_colored_polygon(PackedVector2Array([Vector2(18, 7), Vector2(26, 0), Vector2(34, 7)]), INFO_GREY))
	_menu_box.add_child(notch)
	var info := PanelContainer.new()
	var info_style := StyleBoxFlat.new()
	info_style.bg_color = INFO_GREY
	info_style.content_margin_left = 10
	info_style.content_margin_right = 10
	info_style.content_margin_top = 8
	info_style.content_margin_bottom = 8
	info.add_theme_stylebox_override("panel", info_style)
	info.custom_minimum_size = Vector2(306, 112)
	_menu_box.add_child(info)
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 10)
	info.add_child(info_row)
	_info_icon = Control.new()
	_info_icon.custom_minimum_size = Vector2(26, 26)
	_info_icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_info_icon.draw.connect(func():
		_info_icon.draw_circle(Vector2(13, 13), 13.0, Color(0.2, 0.2, 0.22))
		draw_glyph(_info_icon, _info_glyph, Vector2(13, 13), 7.0, Color.WHITE))
	info_row.add_child(_info_icon)
	var info_text := VBoxContainer.new()
	info_text.add_theme_constant_override("separation", 3)
	info_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(info_text)
	_info_title = _label("", 14, TEXT_DARK)
	info_text.add_child(_info_title)
	_info_body = _label("", 11, Color("3c3c40"), FONT_BODY)
	_info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info_body.custom_minimum_size = Vector2(240, 0)
	info_text.add_child(_info_body)

	# The map, the ledger and the rune journal open in the card, on a dark page
	_map_box = _card_view(stack, "CHAPTER MAP")
	_map_list = _scroll_list(_map_box, 3)
	_map_box.add_child(_label("▶ here   ✓ cleared   • visited   ◆ page   ◇ to find", 10, Color("9d93b8")))
	_ledger_box = _card_view(stack, "THE BELLKEEPER'S LEDGER")
	_ledger_list = _scroll_list(_ledger_box, 10)
	_journal_box = _card_view(stack, "RUNE JOURNAL")
	_journal_list = _scroll_list(_journal_box, 8)


func _card_view(stack: Control, title := "") -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.add_theme_constant_override("separation", 4)
	stack.add_child(box)
	_views.append(box)
	if title == "":
		return box
	var page := StyleBoxFlat.new()
	page.bg_color = Color("2b2a31")
	page.content_margin_left = 10
	page.content_margin_right = 10
	page.content_margin_top = 8
	page.content_margin_bottom = 8
	box.add_theme_constant_override("separation", 6)
	var heading := _label(title, 13, TEXT_DARK)
	box.add_child(heading)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", page)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(panel)
	var inner := VBoxContainer.new()
	panel.add_child(inner)
	box.set_meta(&"page", inner)
	return box


func _scroll_list(view: VBoxContainer, separation: int) -> VBoxContainer:
	var inner: VBoxContainer = view.get_meta(&"page")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(286, 320)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inner.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", separation)
	scroll.add_child(list)
	return list


## A main icon and the first list it slides out (empty for an action icon).
func _icon(id: String, glyph: String, title: String, rows: Array, action := Callable()) -> SaoIcon:
	var icon := SaoIcon.new(glyph)
	icon.name = "Icon" + title
	icon.set_meta(&"title", title)
	icon.set_meta(&"action", action)
	_frame.add_child(icon)
	var index := _icons.size()
	_icons.append(icon)
	_icon_by_id[id] = icon
	icon.hovered.connect(func(): _focus_icon(index, true))
	icon.chosen.connect(func(): _choose_icon(index))
	var list := VBoxContainer.new()
	list.name = "List" + title
	list.add_theme_constant_override("separation", 0)
	list.position = Vector2(SUB1_X, 0)
	list.custom_minimum_size = Vector2(SUB1_W, 0)
	list.visible = false
	_frame.add_child(list)
	for row in rows:
		_add_row(list, row, 1)
	_sub1_lists[index] = list
	return icon


## A row of the first (dark) list; `children` is its second list, if any.
func _row(label: String, glyph: String, children: VBoxContainer, action := Callable()) -> SaoRow:
	var row := SaoRow.new(label, glyph, true, SUB1_W)
	row.set_meta(&"action", action)
	if children:
		row.set_meta(&"children", children)
		children.visible = false
		_sub2_view.add_child(children)
	return row


func _add_row(list: VBoxContainer, row: SaoRow, column: int) -> void:
	list.add_child(row)
	row.hovered.connect(func():
		var i := _visible_rows(list).find(row)
		if column == 1:
			_focus_row1(i, true)
		else:
			_focus_row2(i, true))
	row.pressed.connect(func():
		var i := _visible_rows(list).find(row)
		if column == 1:
			_focus_row1(i, false)
			_choose_row1()
		else:
			_focus_row2(i, false)
			_choose_row2())


## A second (white) list: rows of [label, glyph, info title, info text, action,
## value getter, slot on the ring].
func _make_list2(rows: Array) -> VBoxContainer:
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	list.custom_minimum_size = Vector2(SUB2_W, 0)
	for spec in rows:
		var row := SaoRow.new(spec[0], spec[1], false, SUB2_W)
		row.set_meta(&"info", [spec[2], spec[3]])
		row.set_meta(&"action", spec[4] if spec.size() > 4 and spec[4] != null else Callable())
		if spec.size() > 5 and spec[5] != null:
			row.set_meta(&"value", spec[5])
			_value_rows.append(row)
		row.set_meta(&"slot", spec[6] if spec.size() > 6 else -1)
		_add_row(list, row, 2)
	return list


func _spell_list() -> VBoxContainer:
	return _make_list2([
		["Fireball", "flame", "Fireball", "Hurls a bolt of magic fire where you aim. Burns slimes, lights braziers, rings bells and wakes crystals. Costs 5 mana. (The Hush took this word; she remembers it at the Kept Flame, at the end of the Passage.)", null, func(): return "5 MP" if GameState.has_ability("fire") else "forgotten", 8],
		["Heal", "plus", "Heal", "Stand still and channel for a moment: restores 2 health. A hit breaks it. Costs 20 mana. (Another word the Hush took; the spring under the Belfry gives it back once the great bell has rung.)", null, func(): return "20 MP" if GameState.has_ability("heal") else "forgotten", 9],
		["Echo", "echo", "Echo", "Record up to 8 seconds of yourself; your Echo repeats it: holding plates, pulling levers, ringing bells. Two at once; each lowers your mana cap by 10. (Her family's own word; she remembers it at the Echo Door, early in the Passage.)", null, func(): return "8 s" if GameState.has_ability("echo") else "forgotten", 10],
	])


func _ability_list() -> VBoxContainer:
	return _make_list2([
		["Jump", "jump", "Jump", "Tap {jump} for a quick hop, even a moment after running off a ledge.", null, func(): return InputLabels.primary("jump"), 0],
		["Charged jump", "jump", "Charged jump", "Hold {crouch} to gather yourself, then press {jump}: up to twice as high.", null, func(): return InputLabels.primary("crouch"), 1],
		["Sprint", "dash", "Sprint", "Hold {sprint} to run. A sprint jump carries you across wider gaps.", null, func(): return InputLabels.primary("sprint"), 2],
		["Push", "block", "Push", "Walk into a stone block to push it along.", null, func(): return "", 3],
	])


func _runes_row() -> SaoRow:
	_runes_list = VBoxContainer.new()
	_runes_list.add_theme_constant_override("separation", 0)
	_runes_list.custom_minimum_size = Vector2(SUB2_W, 0)
	_runes_button = _row("Runes", "rune", _runes_list)
	return _runes_button


## The fragments she knows, rebuilt each time the menu opens.
func _fill_runes() -> void:
	for child in _runes_list.get_children():
		child.queue_free()
		_runes_list.remove_child(child)
	if not _runes_button.visible:
		return
	# First the rules again: the rune tour, replayed on request
	var how := SaoRow.new("How rune cubes work", "book", false, SUB2_W)
	how.value_text = "Replay"
	how.set_meta(&"info", ["How rune cubes work", InputLabels.format("Words change only while a cube is OFF. LOCKED words never change. {rune_overview} lists every rune in the room. Choose this to see the rune tour again.")])
	how.set_meta(&"action", _replay_rune_tour)
	how.set_meta(&"slot", -1)
	_add_row(_runes_list, how, 2)
	var n := 0
	for kind in 4:
		for id in RuneFragments.of_kind(kind):
			if RuneManager.knows(id, get_tree()):
				var row := SaoRow.new(RuneFragments.name_of(id), "rune", false, SUB2_W)
				row.value_text = RuneFragments.KIND_NAMES[kind]
				row.set_meta(&"info", [RuneFragments.name_of(id), RuneFragments.meaning_of(id)])
				row.set_meta(&"action", Callable())
				row.set_meta(&"slot", n % SLOTS)
				_add_row(_runes_list, row, 2)
				n += 1


## Echidna, Runes, How rune cubes work: closes the menu and plays the rune tour again.
func _replay_rune_tour() -> void:
	_set_open(false)
	UiTour.play(get_tree().current_scene, "runes", true)


func _graphics_list() -> VBoxContainer:
	var rows := []
	for i in Settings.GRAPHICS_NAMES.size():
		var level := i
		rows.append([Settings.GRAPHICS_NAMES[i], "monitor", "Graphics: %s" % Settings.GRAPHICS_NAMES[i], GRAPHICS_INFO[i],
			func(): Settings.set_graphics(level),
			func(): return "●  In use" if Settings.graphics == level else "", 4 + i])
	rows.append(["Show FPS", "dot", "Show FPS", "A small frames-per-second counter in the bottom-left corner.",
		func(): Settings.set_show_fps(not Settings.show_fps), func(): return "On" if Settings.show_fps else "Off", 9])
	rows.append(["Fullscreen", "monitor", "Fullscreen", "Fill the whole screen (also F11).",
		func(): Settings.set_fullscreen(not Settings.fullscreen), func(): return "On" if Settings.fullscreen else "Off", 10])
	rows.append(["Brightness", "sliders", "Brightness", "How bright the dungeon is. Dim is the original gloom, Normal the default, Bright lifts the shadows more.",
		func(): Settings.set_brightness((Settings.brightness + 1) % Settings.BRIGHTNESS_NAMES.size()),
		func(): return Settings.BRIGHTNESS_NAMES[Settings.brightness], -1])
	return _make_list2(rows)


func _controls_list() -> VBoxContainer:
	var rows := []
	var actions: Array = CONTROLS.map(func(c): return c[1])
	for c in CONTROLS:
		var action: String = c[1]
		rows.append([c[0], "keys", c[0], "Select, then press the new key or mouse button. Esc cancels. A key already in use swaps places with this one.",
			func(): _begin_rebind(action), func(): return "Press a key..." if _waiting_action == action else InputLabels.primary(action), -1])
	rows.append(["Reset controls", "reset", "Reset controls", "Put every key back as it was.",
		func(): _waiting_action = ""; Settings.reset_bindings(), null, -1])
	var list := _make_list2(rows)
	list.set_meta(&"actions", actions)
	return list


func _audio_list() -> VBoxContainer:
	var list := _make_list2([])
	for spec in [["Master volume", "master_volume", Settings.set_master_volume], ["Music volume", "music_volume", Settings.set_music_volume],
			["Ambience volume", "ambient_volume", Settings.set_ambient_volume], ["Effects volume", "sfx_volume", Settings.set_sfx_volume]]:
		var row := SaoRow.new("", "speaker", false, SUB2_W)
		var label := _label(spec[0], 12, TEXT_DARK)
		label.position = Vector2(44, 0)
		label.size = Vector2(130, ROW_H)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(label)
		row.labels.append(label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Settings.get(spec[1])
		slider.position = Vector2(SUB2_W - 92.0, 12.0)
		slider.size = Vector2(80, 16)
		slider.focus_mode = Control.FOCUS_NONE
		var track := StyleBoxFlat.new()
		track.bg_color = Color(0.6, 0.6, 0.64)
		track.content_margin_top = 2
		track.content_margin_bottom = 2
		var fill := StyleBoxFlat.new()
		fill.bg_color = ORANGE
		fill.content_margin_top = 2
		fill.content_margin_bottom = 2
		slider.add_theme_stylebox_override("slider", track)
		slider.add_theme_stylebox_override("grabber_area", fill)
		slider.add_theme_stylebox_override("grabber_area_highlight", fill)
		slider.value_changed.connect(spec[2])
		row.add_child(slider)
		row.set_meta(&"slider", slider)
		row.set_meta(&"setting", spec[1])
		row.set_meta(&"info", [spec[0], "Drag the bar, or use left and right."])
		row.set_meta(&"action", Callable())
		row.set_meta(&"slot", -1)
		_add_row(list, row, 2)
	return list


func _gameplay_list() -> VBoxContainer:
	var damage_levels := [1.0, 0.75, 0.5, 0.25]
	return _make_list2([
		["Guidance", "sliders", "Guidance", "Full: goals, links near switches and hints that call out when you seem stuck. Light: goals only. Off: nothing.",
			func(): Settings.set_guidance((Settings.guidance + 2) % 3),
			func(): return ["Off", "Light", "Full"][Settings.guidance], -1],
		["Reduce motion", "sliders", "Reduce motion", "Less camera shake and softer flashes.",
			func(): Settings.set_reduce_motion(not Settings.reduce_motion), func(): return "On" if Settings.reduce_motion else "Off", -1],
		["Damage taken", "plus", "Damage taken", "How much each hit hurts (never less than 1).",
			func(): Settings.set_assist("assist_damage", damage_levels[(damage_levels.find(Settings.assist_damage) + 1) % 4]),
			func(): return "%d%%" % int(Settings.assist_damage * 100.0), -1],
		["Unlimited mana", "flame", "Unlimited mana", "Spells and runes never run you dry.",
			func(): Settings.set_assist("assist_infinite_mana", not Settings.assist_infinite_mana),
			func(): return "On" if Settings.assist_infinite_mana else "Off", -1],
		["Always sprint", "dash", "Always sprint", "Run by default; hold sprint to walk.",
			func(): Settings.set_assist("assist_auto_sprint", not Settings.assist_auto_sprint),
			func(): return "On" if Settings.assist_auto_sprint else "Off", -1],
		["Crouch toggles", "jump", "Crouch toggles", "Press crouch once to gather a charged jump, instead of holding it.",
			func(): Settings.set_assist("assist_toggle_crouch", not Settings.assist_toggle_crouch),
			func(): return "On" if Settings.assist_toggle_crouch else "Off", -1],
	])


## What the card says when a first-list row is highlighted.
func _describe_rows() -> void:
	var text := {
		"Spells": "Her spells, their cost in mana and what they can do.",
		"Abilities": "How she moves.",
		"Runes": "The rune fragments she has learned.",
		"Room Map": "The acts and rooms of this %s: where you are, what's cleared, and the lore pages found." % _unit(),
		"Reset Room": "Put this room's puzzle back to its start. Health is kept.",
		"The Ledger": "The Bellkeeper's Ledger: every page you have found, to read again.",
		"Rune Journal": "Fragments you know, what you have seen runes do, and the runes you have cast.",
		"Graphics": "Quality from Low to Elite, the FPS counter and fullscreen.",
		"Controls": "Change any key.",
		"Audio": "Volumes for music, ambience and effects.",
		"Gameplay": "Guidance and assists.",
		"Restart": "Erase this %s's saved progress and start again (asks twice)." % _unit(),
		"Return to Title": "Leave for the title screen. Progress is saved at shrines.",
		"Quit Game": "Close the game.",
	}
	for index in _sub1_lists:
		for row in _sub1_lists[index].get_children():
			row.set_meta(&"info", [row.text, text.get(row.text, "")])
			row.set_meta(&"slot", -1)


# ------------------------------------------------------------------ navigation

func _first_icon() -> int:
	for i in _icons.size():
		if _icons[i].visible:
			return i
	return 0


func _visible_icons() -> Array[int]:
	var list: Array[int] = []
	for i in _icons.size():
		if _icons[i].visible:
			list.append(i)
	return list


func _visible_rows(list: VBoxContainer) -> Array:
	return list.get_children().filter(func(r): return r.visible and not r.is_queued_for_deletion())


func _focus_icon(index: int, from_mouse: bool, sound := true) -> void:
	if from_mouse and _col > 0 and index == _icon_index:
		return
	var changed := index != _icon_index or _list1 == null
	_icon_index = index
	_col = 0
	for i in _icons.size():
		_icons[i].active = i == index
	_set_list1(_sub1_lists[index])
	_row1 = -1
	_set_row_states(_list1, -1)
	_set_list2(null)
	var icon := _icons[index]
	_set_info(icon.get_meta(&"title"), "", icon.glyph, -1)
	_refresh_status()
	if changed and sound and is_open:
		_play("hover")
	_pointer.queue_redraw()


func _choose_icon(index: int) -> void:
	_focus_icon(index, false)
	_play("select")
	var action: Callable = _icons[index].get_meta(&"action")
	if action.is_valid():
		action.call()
		return
	if not _visible_rows(_list1).is_empty():
		_col = 1
		_focus_row1(0, false)


func _close_from_menu() -> void:
	_set_open(false)


func _set_list1(list: VBoxContainer) -> void:
	if _list1 == list:
		return
	if _list1:
		_list1.visible = false
	_list1 = list
	if list == null:
		return
	list.visible = not _visible_rows(list).is_empty()
	var icon := _icons[_icon_index]
	var rows := _visible_rows(list).size()
	list.position.y = clampf(icon.position.y + ICON_SIZE / 2.0 - ROW_H / 2.0, 0.0, FRAME_SIZE.y - rows * ROW_H)
	_reveal(list)


func _set_list2(list: VBoxContainer) -> void:
	if _list2 == list:
		return
	if _list2:
		_list2.visible = false
	_list2 = list
	_row2 = -1
	if list == null:
		return
	list.visible = true
	_refresh_values()
	_set_row_states(list, -1)
	_scroll_list2(-1)
	_reveal(list)


# Slides a list out from its left edge
func _reveal(list: Control) -> void:
	list.pivot_offset = Vector2(0, 0)
	list.scale = Vector2(0.4, 1.0)
	list.modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(list, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(list, "modulate:a", 1.0, 0.12)


func _set_row_states(list: VBoxContainer, index: int) -> void:
	if list == null:
		return
	var rows := _visible_rows(list)
	for i in rows.size():
		rows[i].active = i == index


func _focus_row1(index: int, from_mouse: bool) -> void:
	var rows := _visible_rows(_list1)
	if index < 0 or index >= rows.size():
		return
	var changed := index != _row1 or _col != 1
	_row1 = index
	_col = 1
	_set_row_states(_list1, index)
	var row: SaoRow = rows[index]
	var children: VBoxContainer = row.get_meta(&"children") if row.has_meta(&"children") else null
	if children:
		# The second list lines up with the row that opened it
		_sub2_view.position.y = clampf(_list1.position.y + index * ROW_H + ROW_H / 2.0 - SUB2_VIEW_H / 2.0,
			-60.0, FRAME_SIZE.y - SUB2_VIEW_H + 60.0)
	_set_list2(children)
	var info: Array = row.get_meta(&"info", [row.text, ""])
	_set_info(info[0], info[1], row.glyph, -1)
	if changed:
		_play("hover")
	_pointer.queue_redraw()


func _choose_row1() -> void:
	var rows := _visible_rows(_list1)
	if _row1 < 0 or _row1 >= rows.size():
		return
	var row: SaoRow = rows[_row1]
	if row.disabled:
		_play("back")
		return
	var action: Callable = row.get_meta(&"action", Callable())
	if action.is_valid():
		action.call()
		return
	if row.has_meta(&"children") and not _visible_rows(_list2).is_empty():
		_play("select")
		_col = 2
		_focus_row2(0, false)


func _focus_row2(index: int, from_mouse: bool) -> void:
	var rows := _visible_rows(_list2)
	if index < 0 or index >= rows.size():
		return
	var changed := index != _row2 or _col != 2
	_row2 = index
	_col = 2
	_set_row_states(_list2, index)
	var row: SaoRow = rows[index]
	var info: Array = row.get_meta(&"info", [row.text, ""])
	_set_info(info[0], info[1], row.glyph, row.get_meta(&"slot", -1))
	_scroll_list2(index)
	if changed:
		_play("hover")


func _choose_row2() -> void:
	var rows := _visible_rows(_list2)
	if _row2 < 0 or _row2 >= rows.size():
		return
	var row: SaoRow = rows[_row2]
	var action: Callable = row.get_meta(&"action", Callable())
	_play("select")
	if action.is_valid():
		action.call()
	_refresh_values()


## Keeps the active row of a long second list inside its window.
func _scroll_list2(index: int) -> void:
	if _list2 == null:
		return
	var total := _visible_rows(_list2).size() * ROW_H
	var top := (SUB2_VIEW_H - total) / 2.0
	if total > SUB2_VIEW_H - 2.0 * ROW_H:
		var at := maxf(index, 0) * ROW_H
		top = clampf(SUB2_VIEW_H / 2.0 - at - ROW_H / 2.0, SUB2_VIEW_H - total - ROW_H, ROW_H)
	# Short lists start level with the row that opened them
	if total <= SUB2_VIEW_H - 2.0 * ROW_H:
		top = SUB2_VIEW_H / 2.0 - ROW_H / 2.0
		top = minf(top, SUB2_VIEW_H - total - ROW_H * 0.5)
	_list2.position = Vector2(8, top)


func _on_sub2_wheel(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed) or _list2 == null:
		return
	var rows := _visible_rows(_list2).size()
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_focus_row2(mini(maxi(_row2, 0) + 1, rows - 1), false)
	elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_focus_row2(maxi(_row2 - 1, 0), false)


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if _waiting_action != "":
		_capture_key(event)
		return
	var handled := true
	if event.is_action_pressed("pause", false) or event.is_action_pressed("ui_cancel", false):
		_back()
	elif event.is_action_pressed("ui_up", true):
		_move(-1)
	elif event.is_action_pressed("ui_down", true):
		_move(1)
	elif event.is_action_pressed("ui_right", true):
		if not _adjust(1):
			_go_in()
	elif event.is_action_pressed("ui_left", true):
		if not _adjust(-1):
			_back()
	elif event.is_action_pressed("ui_accept", false):
		_accept()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()


func _move(step: int) -> void:
	if _col == 0:
		var icons := _visible_icons()
		var at := icons.find(_icon_index)
		_focus_icon(icons[clampi(at + step, 0, icons.size() - 1)], false)
	elif _col == 1:
		_focus_row1(clampi(_row1 + step, 0, _visible_rows(_list1).size() - 1), false)
	else:
		_focus_row2(clampi(_row2 + step, 0, _visible_rows(_list2).size() - 1), false)


func _go_in() -> void:
	if _col == 0:
		_choose_icon(_icon_index)
	elif _col == 1:
		var rows := _visible_rows(_list1)
		if _row1 >= 0 and _row1 < rows.size() and rows[_row1].has_meta(&"children"):
			_choose_row1()


func _accept() -> void:
	if _col == 0:
		_choose_icon(_icon_index)
	elif _col == 1:
		_choose_row1()
	else:
		_choose_row2()


# Left/right on a volume row change the volume instead of moving between lists
func _adjust(step: int) -> bool:
	if _col != 2 or _list2 == null:
		return false
	var rows := _visible_rows(_list2)
	if _row2 < 0 or _row2 >= rows.size() or not rows[_row2].has_meta(&"slider"):
		return false
	var slider: HSlider = rows[_row2].get_meta(&"slider")
	slider.value = clampf(slider.value + step * slider.step, 0.0, 1.0)
	_play("hover")
	return true


## One step back: out of a key being bound, the second list, a page open in
## the card, the first list; on the icons, the menu closes.
func _back() -> void:
	if _col == 2:
		_play("back")
		_col = 1
		_row2 = -1
		_set_row_states(_list2, -1)
		_focus_row1(_row1, false)
	elif _current_view() != _menu_box:
		_play("back")
		_show(_menu_box)
	elif _col == 1:
		_play("back")
		_focus_icon(_icon_index, false)
	else:
		_set_open(false)


func _current_view() -> Control:
	for view in _views:
		if view.visible:
			return view
	return _menu_box


# ------------------------------------------------------------------ rebinding

func _begin_rebind(action: String) -> void:
	_waiting_action = action
	_refresh_values()


func _capture_key(event: InputEvent) -> void:
	var usable: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed and event.button_index <= MOUSE_BUTTON_MIDDLE)
	if not usable:
		return
	get_viewport().set_input_as_handled()
	# Escape cancels (unless it's the pause key being chosen)
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE and _waiting_action != "pause":
		_play("back")
	else:
		Settings.rebind(_waiting_action, event, CONTROLS.map(func(c): return c[1]))
		_play("select")
	_waiting_action = ""
	_refresh_values()


# ------------------------------------------------------------------ card and values

func _set_info(title: String, body: String, glyph: String, slot: int) -> void:
	_info_title.text = title
	_info_body.text = InputLabels.format(body, "%s") if body != "" else _status_line()
	_info_glyph = glyph
	_info_icon.queue_redraw()
	if slot >= 0:
		_slot = slot
		_figure.queue_redraw()


func _status_line() -> String:
	var root := _chapter_root()
	if root and root.current_room:
		return "%s\n%s" % [root.chapter_title, root.current_room.title]
	return "A witch of the sealed belfry."


func _refresh_status() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		_stats.text = ""
		return
	var mana_cap: int = player.get_mana_cap() if player.has_method("get_mana_cap") else 100
	_stats.text = "HP %d / %d      MP %d / %d" % [player.current_health, player.MAX_HEALTH, player.current_mana, mana_cap]


func _refresh_values() -> void:
	for row in _value_rows:
		if is_instance_valid(row):
			var getter: Callable = row.get_meta(&"value")
			row.value_text = str(getter.call())
	for list in _sub2_view.get_children():
		for row in list.get_children():
			if row.has_meta(&"slider"):
				row.get_meta(&"slider").set_value_no_signal(Settings.get(row.get_meta(&"setting")))
	_refresh_status()


func _draw_figure() -> void:
	var c := Vector2(_figure.size.x / 2.0, 112.0)
	_figure.draw_set_transform(Vector2(c.x, 198.0), 0.0, Vector2(1.0, 0.2))
	_figure.draw_circle(Vector2.ZERO, 70.0, Color(0, 0, 0, 0.14))
	_figure.draw_set_transform(Vector2.ZERO)
	for i in SLOTS:
		var a := -PI / 2.0 + i * TAU / SLOTS
		var p := c + Vector2(cos(a) * 124.0, sin(a) * 100.0)
		if i == _slot:
			_figure.draw_circle(p, 11.0, ORANGE)
			_figure.draw_arc(p, 15.0, 0.0, TAU, 28, ORANGE, 1.5, true)
		else:
			_figure.draw_circle(p, 10.0, Color(0.24, 0.24, 0.26))
			_figure.draw_arc(p, 10.0, 0.0, TAU, 28, Color(0.64, 0.64, 0.68), 1.2, true)


# The card points at the active icon, and the icon points on to its list
func _draw_pointers() -> void:
	if _icons.is_empty() or not _icons[_icon_index].visible:
		return
	var icon := _icons[_icon_index]
	var y := icon.position.y + ICON_SIZE / 2.0
	var x := CARD_RECT.end.x
	_pointer.draw_colored_polygon(PackedVector2Array([Vector2(x, y - 10), Vector2(x + 13, y), Vector2(x, y + 10)]), CARD_WHITE)
	if _list1 and _list1.visible:
		var ax := ICON_X + ICON_SIZE + 8.0
		_pointer.draw_colored_polygon(PackedVector2Array([Vector2(ax, y - 7), Vector2(ax + 9, y), Vector2(ax, y + 7)]), ORANGE)


func _show(view: Control) -> void:
	for v in _views:
		v.visible = v == view
	if view == _map_box:
		_fill_map()
	elif view == _ledger_box:
		_fill_ledger()
	elif view == _journal_box:
		RuneJournal.fill(_journal_list, get_tree())
		# (Written for a wider page; fit it to the card)
		for label in _journal_list.find_children("*", "Label", true, false):
			if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
				label.custom_minimum_size.x = 270.0


## Kept for the tests and older callers.
func _show_map(show: bool) -> void:
	_show(_map_box if show else _menu_box)


# ------------------------------------------------------------------ map

## Lists the chapter's acts and rooms: which are cleared, visited, where you
## are, and how many of each room's lore pages you have found.
func _fill_map() -> void:
	for child in _map_list.get_children():
		child.queue_free()
	var root := _chapter_root()
	if root == null:
		return
	var rooms: Array = root.rooms.duplicate()
	rooms.sort_custom(func(a, b): return a.bounds.position.x < b.bounds.position.x)
	var chapter: String = root.chapter_id
	for room in rooms:
		if room.act != "":
			_map_list.add_child(_label("ACT %s  ·  %s" % [room.act, room.act_title], 11, Color("a99ccf")))
		var key: String = room.room_id.get_slice(".", 1)
		var seen := GameState.has_flag("%s.seen.%s" % [chapter, key])
		var cleared := GameState.has_flag("%s.clear.%s" % [chapter, key])
		var mark := "▶" if room == root.current_room else ("✓" if cleared else ("•" if seen else " "))
		var pages := ""
		for id in room.page_ids:
			pages += "◆" if GameState.has_flag(id) else ("◇" if seen else "")
		var text := " %s  %s  %s" % [mark, room.title if seen else "? ? ?", pages]
		var color := Color("e4ddf2") if room == root.current_room else (Color("b8acd8") if seen else Color("6d6488"))
		_map_list.add_child(_label(text, 12, color))
	_map_list.add_child(_label("Lore pages found: %d / %d" % [root.pages_found(), root.total_pages], 11, Color("b8acd8")))


# ------------------------------------------------------------------ ledger

## Every page in order: the found ones to re-read, the rest as a blank with
## a hint of where it lies.
func _fill_ledger() -> void:
	for child in _ledger_list.get_children():
		child.queue_free()
	var root := _chapter_root()
	if root == null:
		return
	for page in root.ledger:
		var found := GameState.has_flag(page["id"])
		var head := _label("%s   %s" % [page["numeral"], page["title"] if found else "A missing page"], 12,
			Color("e2d6fa") if found else Color("6d6488"))
		_ledger_list.add_child(head)
		var body := _label(page["text"] if found else "Somewhere in %s." % page["room"], 11,
			Color("cfc4e6") if found else Color("6d6488"), FONT_BODY)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(270, 0)
		_ledger_list.add_child(body)


func _label(text: String, size: int, color: Color, font: Font = FONT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


# ------------------------------------------------------------------ drawing

## Small white pictograms for the icons and rows, drawn at `c` about `s` px
## from the centre to the edge.
static func draw_glyph(ci: CanvasItem, id: String, c: Vector2, s: float, col: Color) -> void:
	var p := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * s
	var shade := Color(0, 0, 0, 0.5)
	match id:
		"play":
			ci.draw_colored_polygon(PackedVector2Array([p.call(-0.45, -0.62), p.call(0.68, 0.0), p.call(-0.45, 0.62)]), col)
		"person":
			ci.draw_circle(p.call(0.0, -0.42), 0.3 * s, col)
			ci.draw_colored_polygon(PackedVector2Array([p.call(-0.64, 0.74), p.call(-0.56, 0.12), p.call(-0.28, -0.06),
				p.call(0.28, -0.06), p.call(0.56, 0.12), p.call(0.64, 0.74)]), col)
		"map":
			ci.draw_circle(p.call(0.0, -0.2), 0.44 * s, col)
			ci.draw_colored_polygon(PackedVector2Array([p.call(-0.38, 0.0), p.call(0.38, 0.0), p.call(0.0, 0.8)]), col)
			ci.draw_circle(p.call(0.0, -0.2), 0.17 * s, shade)
		"book":
			ci.draw_colored_polygon(PackedVector2Array([p.call(-0.78, -0.52), p.call(-0.07, -0.38), p.call(-0.07, 0.64), p.call(-0.78, 0.5)]), col)
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.07, -0.38), p.call(0.78, -0.52), p.call(0.78, 0.5), p.call(0.07, 0.64)]), col)
		"gear":
			for i in 8:
				var d := Vector2.from_angle(i * TAU / 8.0)
				ci.draw_line(c + d * 0.4 * s, c + d * 0.8 * s, col, 0.3 * s)
			ci.draw_circle(c, 0.55 * s, col)
			ci.draw_circle(c, 0.2 * s, shade)
		"power":
			ci.draw_arc(c, 0.6 * s, deg_to_rad(-55.0), deg_to_rad(235.0), 24, col, 0.2 * s, true)
			ci.draw_line(p.call(0.0, -0.85), p.call(0.0, -0.1), col, 0.2 * s)
		"flame":
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.0, -0.85), p.call(0.4, -0.2), p.call(0.5, 0.3), p.call(0.25, 0.7),
				p.call(-0.25, 0.7), p.call(-0.5, 0.3), p.call(-0.35, -0.1), p.call(-0.1, 0.05)]), col)
		"plus":
			ci.draw_rect(Rect2(p.call(-0.2, -0.7), Vector2(0.4, 1.4) * s), col)
			ci.draw_rect(Rect2(p.call(-0.7, -0.2), Vector2(1.4, 0.4) * s), col)
		"echo":
			ci.draw_arc(p.call(-0.22, 0.0), 0.45 * s, 0.0, TAU, 20, col, 0.16 * s, true)
			ci.draw_arc(p.call(0.25, 0.0), 0.45 * s, 0.0, TAU, 20, Color(col, 0.6), 0.16 * s, true)
		"jump":
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.0, -0.8), p.call(0.6, -0.1), p.call(0.22, -0.1),
				p.call(0.22, 0.7), p.call(-0.22, 0.7), p.call(-0.22, -0.1), p.call(-0.6, -0.1)]), col)
		"dash":
			for i in 3:
				var y := -0.45 + i * 0.45
				ci.draw_line(p.call(-0.7 + i * 0.15, y), p.call(0.7, y), col, 0.17 * s)
		"block":
			ci.draw_rect(Rect2(p.call(-0.6, -0.6), Vector2(1.2, 1.2) * s), col)
			ci.draw_rect(Rect2(p.call(-0.3, -0.3), Vector2(0.6, 0.6) * s), shade)
		"rune":
			ci.draw_colored_polygon(PackedVector2Array([p.call(0.0, -0.85), p.call(0.6, 0.0), p.call(0.0, 0.85), p.call(-0.6, 0.0)]), col)
			ci.draw_line(p.call(0.0, -0.45), p.call(0.0, 0.45), shade, 0.14 * s)
		"list":
			for i in 3:
				var y := -0.5 + i * 0.5
				ci.draw_circle(p.call(-0.6, y), 0.11 * s, col)
				ci.draw_line(p.call(-0.35, y), p.call(0.7, y), col, 0.16 * s)
		"reset":
			ci.draw_arc(c, 0.55 * s, deg_to_rad(-150.0), deg_to_rad(150.0), 24, col, 0.18 * s, true)
			ci.draw_colored_polygon(PackedVector2Array([p.call(-0.78, -0.55), p.call(-0.2, -0.45), p.call(-0.6, 0.0)]), col)
		"monitor":
			ci.draw_rect(Rect2(p.call(-0.75, -0.6), Vector2(1.5, 0.95) * s), col)
			ci.draw_rect(Rect2(p.call(-0.55, -0.42), Vector2(1.1, 0.6) * s), shade)
			ci.draw_rect(Rect2(p.call(-0.12, 0.35), Vector2(0.24, 0.3) * s), col)
			ci.draw_rect(Rect2(p.call(-0.45, 0.6), Vector2(0.9, 0.16) * s), col)
		"keys":
			ci.draw_rect(Rect2(p.call(-0.8, -0.45), Vector2(1.6, 0.9) * s), col)
			for i in 3:
				ci.draw_rect(Rect2(p.call(-0.6 + i * 0.45, -0.22), Vector2(0.28, 0.2) * s), shade)
			ci.draw_rect(Rect2(p.call(-0.4, 0.12), Vector2(0.8, 0.16) * s), shade)
		"speaker":
			ci.draw_colored_polygon(PackedVector2Array([p.call(-0.75, -0.25), p.call(-0.35, -0.25), p.call(0.05, -0.65),
				p.call(0.05, 0.65), p.call(-0.35, 0.25), p.call(-0.75, 0.25)]), col)
			ci.draw_arc(p.call(0.05, 0.0), 0.45 * s, -0.9, 0.9, 10, col, 0.13 * s, true)
			ci.draw_arc(p.call(0.05, 0.0), 0.72 * s, -0.9, 0.9, 12, col, 0.13 * s, true)
		"sliders":
			for i in 3:
				var y := -0.5 + i * 0.5
				ci.draw_line(p.call(-0.75, y), p.call(0.75, y), col, 0.12 * s)
				ci.draw_circle(p.call([-0.3, 0.35, -0.05][i], y), 0.2 * s, col)
		"door":
			ci.draw_rect(Rect2(p.call(-0.55, -0.8), Vector2(0.9, 1.6) * s), col)
			ci.draw_circle(p.call(0.18, 0.05), 0.1 * s, shade)
			ci.draw_line(p.call(0.45, 0.0), p.call(0.85, 0.0), col, 0.16 * s)
		"cross":
			ci.draw_line(p.call(-0.6, -0.6), p.call(0.6, 0.6), col, 0.24 * s)
			ci.draw_line(p.call(0.6, -0.6), p.call(-0.6, 0.6), col, 0.24 * s)
		_:
			ci.draw_circle(c, 0.3 * s, col)


## A round main-menu icon: dark with a grey ring, or solid orange with an
## outer ring while it is the active one.
class SaoIcon extends Control:
	signal hovered
	signal chosen

	var glyph := ""
	var active := false:
		set(value):
			active = value
			queue_redraw()

	func _init(icon_glyph: String) -> void:
		glyph = icon_glyph
		custom_minimum_size = Vector2(PauseMenu.ICON_SIZE, PauseMenu.ICON_SIZE)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func(): hovered.emit())

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			chosen.emit()

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x / 2.0 - 5.0
		if active:
			draw_arc(c, r + 5.0, 0.0, TAU, 48, PauseMenu.ORANGE, 2.0, true)
			draw_circle(c, r, PauseMenu.ORANGE)
		else:
			draw_circle(c, r, PauseMenu.ICON_DARK)
			draw_arc(c, r, 0.0, TAU, 48, PauseMenu.ICON_RING, 1.5, true)
		PauseMenu.draw_glyph(self, glyph, c, r * 0.55, Color.WHITE)


## A list row: dark grey (the first list) or white (the second), with a
## small round pictogram, a value on the right, and solid orange while active.
class SaoRow extends Button:
	signal hovered

	var glyph := ""
	var dark := true
	var labels: Array[Label] = []
	var value_text := "":
		set(value):
			value_text = value
			queue_redraw()
	var active := false:
		set(value):
			active = value
			_restyle()

	func _init(label_text: String, row_glyph: String, is_dark: bool, width: float) -> void:
		text = label_text
		glyph = row_glyph
		dark = is_dark
		custom_minimum_size = Vector2(width, PauseMenu.ROW_H)
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		focus_mode = Control.FOCUS_NONE
		# Clicks stay here; the mouse wheel passes on to scroll the list
		mouse_filter = Control.MOUSE_FILTER_PASS
		clip_text = true
		add_theme_font_override("font", PauseMenu.FONT)
		add_theme_font_size_override("font_size", 13 if is_dark else 12)
		mouse_entered.connect(func(): hovered.emit())
		_restyle()

	func _restyle() -> void:
		var box := StyleBoxFlat.new()
		box.bg_color = PauseMenu.ORANGE if active else (PauseMenu.ROW_GREY if dark else PauseMenu.ROW_WHITE)
		box.content_margin_left = 44
		box.content_margin_right = 12
		box.border_width_bottom = 1
		box.border_color = Color(0, 0, 0, 0.3) if dark else Color(0.8, 0.8, 0.83)
		for state in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(state, box)
		var fg := Color.WHITE if active else (PauseMenu.TEXT_LIGHT if dark else PauseMenu.TEXT_DARK)
		for key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			add_theme_color_override(key, fg)
		add_theme_color_override("font_disabled_color", Color(fg, 0.45))
		for label in labels:
			label.add_theme_color_override("font_color", fg)
		queue_redraw()

	func _draw() -> void:
		var h := size.y
		var c := Vector2(22.0, h / 2.0)
		var circle := Color.WHITE if active else (Color(0.2, 0.2, 0.22) if dark else Color(0.26, 0.26, 0.29))
		draw_circle(c, 12.0, circle)
		PauseMenu.draw_glyph(self, glyph, c, 6.5, PauseMenu.ORANGE if active else Color.WHITE)
		if value_text != "":
			var font: Font = PauseMenu.FONT
			var width := font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			var col := Color.WHITE if active else (Color(0.85, 0.85, 0.88) if dark else PauseMenu.TEXT_MUTED)
			draw_string(font, Vector2(size.x - width - 12.0, h / 2.0 + 4.0), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
		if active:
			# A notch on the left edge, pointing back at what opened this list
			draw_colored_polygon(PackedVector2Array([Vector2(0, h / 2.0 - 7.0), Vector2(-8, h / 2.0), Vector2(0, h / 2.0 + 7.0)]), PauseMenu.ORANGE)


## "chapter" or "part": what the current stretch of the game is called.
func _unit() -> String:
	var root := _chapter_root()
	return String(root.unit_name) if root else "chapter"


## Puts the selection on Map -> Reset Room (the room can't be finished, so
## that is almost certainly what she opened the menu for).
func focus_reset_room() -> void:
	var map_icon: SaoIcon = _icon_by_id.get("map")
	if map_icon == null or not map_icon.visible:
		return
	_focus_icon(_icons.find(map_icon), false, false)
	var rows := _visible_rows(_list1)
	var index := rows.find(_reset_button)
	if index < 0:
		return
	_focus_row1(index, false)
	_set_info("Reset Room", "This room can't be finished now. %s\nChoose Reset Room to put the room back as it was. Your health is kept." % reset_reason, "reset", -1)
