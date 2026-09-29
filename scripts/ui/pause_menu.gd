class_name PauseMenu
extends CanvasLayer

## Esc menu. Main view: resume, the chapter map, the Bellkeeper's Ledger
## (collected lore pages, to re-read), settings, reset the current room,
## restart the chapter, return to the title, quit. Unavailable while the
## death screen is up. Works in any level; the chapter-only parts hide
## themselves elsewhere.

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"

var is_open := false
var _panel: PanelContainer
var _dim: ColorRect
var _reset_button: Button
var _resume_button: Button
var _restart_button: Button
var _restart_armed := false
var _pages_label: Label
var _menu_box: VBoxContainer
var _map_box: VBoxContainer
var _map_list: VBoxContainer
var _map_button: Button
var _ledger_box: VBoxContainer
var _ledger_list: VBoxContainer
var _ledger_button: Button
var _journal_box: VBoxContainer
var _journal_list: VBoxContainer
var _journal_button: Button
var _settings_box: VBoxContainer
var _views: Array[Control] = []


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_set_open(false)


func _unhandled_input(event: InputEvent) -> void:
	# A controller's B backs out of the menu (Escape is already "pause")
	if is_open and event is InputEventJoypadButton and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		Sfx.play("ui_click")
		if not _menu_box.visible:
			_show(_menu_box)
		else:
			_set_open(false)
		return
	if event.is_action_pressed("pause", false):
		# Another screen (a rune cube, a page) has the game paused and owns Esc
		if _death_screen_up() or (get_tree().paused and not is_open):
			return
		get_viewport().set_input_as_handled()
		# Esc backs out of a sub-view first
		if is_open and not _menu_box.visible:
			Sfx.play("ui_click")
			_show(_menu_box)
			return
		_set_open(not is_open)


func _death_screen_up() -> bool:
	var death := get_tree().get_first_node_in_group("death_screen")
	return death != null and death.visible


func _set_open(open: bool) -> void:
	is_open = open
	_dim.visible = open
	_panel.visible = open
	get_tree().paused = open
	_restart_armed = false
	_restart_button.text = "Restart Chapter"
	_show(_menu_box)
	if open:
		Crosshair.arrow()
	elif get_tree().get_first_node_in_group("player") != null:
		Crosshair.restore()
	if open:
		var root := _chapter_root()
		_reset_button.disabled = root == null or root.current_room == null
		_restart_button.visible = root != null
		_map_button.visible = root != null
		_ledger_button.visible = root != null and root.total_pages > 0
		_journal_button.visible = get_tree().get_first_node_in_group("rune_manager") != null
		if root and root.total_pages > 0:
			_pages_label.text = "Lore pages found: %d / %d" % [root.pages_found(), root.total_pages]
			_pages_label.visible = true
		else:
			_pages_label.visible = false
		Sfx.play("ui_open")
		_resume_button.grab_focus()


func _chapter_root() -> Node:
	return get_tree().get_first_node_in_group("chapter_root")


## Wipes this chapter's saved progress and starts it over. Asks for a second
## press first, since it cannot be undone.
func _on_restart() -> void:
	Sfx.play("ui_click")
	if not _restart_armed:
		_restart_armed = true
		_restart_button.text = "Press again to erase chapter progress"
		return
	var root := _chapter_root()
	if root == null:
		return
	GameState.clear_progress(root.chapter_id)
	_set_open(false)
	get_tree().reload_current_scene()


func _on_reset() -> void:
	Sfx.play("ui_click")
	_set_open(false)
	var root := _chapter_root()
	if root:
		root.reset_current_room()


func _on_title() -> void:
	Sfx.play("ui_click")
	_set_open(false)
	get_tree().change_scene_to_file(TITLE_SCENE)


func _build() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.02, 0.01, 0.05, 0.65)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.1, 0.96)
	style.border_color = Color(0.5, 0.38, 0.78, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var stack := VBoxContainer.new()
	_panel.add_child(stack)

	# Main view
	_menu_box = _view(stack, "PAUSED")
	_resume_button = _button("Resume", func(): Sfx.play("ui_click"); _set_open(false))
	_menu_box.add_child(_resume_button)
	_map_button = _button("Chapter Map", func(): Sfx.play("ui_click"); _show(_map_box))
	_menu_box.add_child(_map_button)
	_ledger_button = _button("The Bellkeeper's Ledger", func(): Sfx.play("ui_click"); _show(_ledger_box))
	_menu_box.add_child(_ledger_button)
	_journal_button = _button("Rune Journal", func(): Sfx.play("ui_click"); _show(_journal_box))
	_menu_box.add_child(_journal_button)
	_menu_box.add_child(_button("Settings & Controls", func(): Sfx.play("ui_click"); _show(_settings_box)))
	_reset_button = _button("Reset Room", _on_reset)
	_menu_box.add_child(_reset_button)
	_menu_box.add_child(_label("Puts this room's puzzle back to its start. Health is kept.", 12, Color("9d93b8")))
	_pages_label = _label("", 14, Color("b8acd8"))
	_menu_box.add_child(_pages_label)
	_menu_box.add_child(HSeparator.new())
	_restart_button = _button("Restart Chapter", _on_restart)
	_menu_box.add_child(_restart_button)
	_menu_box.add_child(_button("Return to Title", _on_title))
	_menu_box.add_child(_button("Quit Game", func(): get_tree().quit()))

	# Map view
	_map_box = _view(stack, "CHAPTER MAP")
	_map_list = VBoxContainer.new()
	_map_list.add_theme_constant_override("separation", 3)
	_map_box.add_child(_map_list)
	_map_box.add_child(_label("▶ you are here    ✓ cleared    • visited    ◆ page found    ◇ page to find", 11, Color("9d93b8")))
	_map_box.add_child(_back_button())

	# Ledger view
	_ledger_box = _view(stack, "THE BELLKEEPER'S LEDGER")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_ledger_box.add_child(scroll)
	_ledger_list = VBoxContainer.new()
	_ledger_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ledger_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_ledger_list)
	_ledger_box.add_child(_back_button())

	# Rune journal view (levels with rune cubes)
	_journal_box = _view(stack, "RUNE JOURNAL")
	var journal_scroll := ScrollContainer.new()
	journal_scroll.custom_minimum_size = Vector2(560, 380)
	journal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_journal_box.add_child(journal_scroll)
	_journal_list = VBoxContainer.new()
	_journal_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_list.add_theme_constant_override("separation", 8)
	journal_scroll.add_child(_journal_list)
	_journal_box.add_child(_back_button())

	# Settings view
	_settings_box = _view(stack, "SETTINGS")
	_settings_box.add_child(SettingsPanel.scrolled(420.0))
	_settings_box.add_child(_back_button())


func _view(stack: VBoxContainer, title_text: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	stack.add_child(box)
	_views.append(box)
	var title := _label(title_text, 24, Color("cbbdf2"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	return box


func _back_button() -> Button:
	return _button("Back", func(): Sfx.play("ui_click"); _show(_menu_box))


func _show(view: Control) -> void:
	for v in _views:
		v.visible = v == view
	# The panel shrinks back to the view's size
	_panel.reset_size()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	if view == _map_box:
		_fill_map()
	elif view == _ledger_box:
		_fill_ledger()
	elif view == _journal_box:
		RuneJournal.fill(_journal_list, get_tree())
	if not is_open:
		return
	if view == _menu_box:
		_resume_button.grab_focus()
	else:
		var back: Button = view.get_child(view.get_child_count() - 1)
		back.grab_focus()


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
			_map_list.add_child(_label("ACT %s  ·  %s" % [room.act, room.act_title], 13, Color("a99ccf")))
		var key: String = room.room_id.get_slice(".", 1)
		var seen := GameState.has_flag("%s.seen.%s" % [chapter, key])
		var cleared := GameState.has_flag("%s.clear.%s" % [chapter, key])
		var mark := "▶" if room == root.current_room else ("✓" if cleared else ("•" if seen else " "))
		var pages := ""
		for id in room.page_ids:
			pages += "◆" if GameState.has_flag(id) else ("◇" if seen else "")
		var text := "  %s  %s   %s" % [mark, room.title if seen else "? ? ?", pages]
		var color := Color("e4ddf2") if room == root.current_room else (Color("b8acd8") if seen else Color("6d6488"))
		_map_list.add_child(_label(text, 15, color))
	_map_list.add_child(_label("Lore pages found: %d / %d" % [root.pages_found(), root.total_pages], 13, Color("b8acd8")))


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
		var head := _label("%s   %s" % [page["numeral"], page["title"] if found else "A missing page"], 15,
			Color("e2d6fa") if found else Color("6d6488"))
		_ledger_list.add_child(head)
		var body := _label(page["text"] if found else "Somewhere in %s." % page["room"], 13,
			Color("cfc4e6") if found else Color("6d6488"))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(520, 0)
		_ledger_list.add_child(body)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 38)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(on_press)
	return b
