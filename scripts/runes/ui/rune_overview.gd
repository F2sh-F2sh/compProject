class_name RuneOverview
extends CanvasLayer

## Tab (Back on a controller): your runes. Every cube in this room at a
## glance: its rune, whether it is on, what it costs and which of its words are
## locked. A running cube can be switched off from here, from anywhere in the
## room; the cube you are standing at (or at whose lectern you stand) can be
## inscribed from here too. The rules for changing words are written at the
## top, so this screen always answers "can I edit this, and how?".
## Pauses the game while open. Cubes are only switched on at the cube.

const FONT := Fonts.UI
const INK := Color("e8dcc0")
const DIM := Color("9a8f86")
const LOCK := Color(0.78, 0.72, 0.95)
const WARN := Color("ffc070")

var is_open := false
var _root: Control
var _rules: Label
var _list: VBoxContainer
var _summary: Label
var _all: Button
var _done: Button
## cube -> its Inscribe button, for tests.
var inscribe_buttons := {}


func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func _manager() -> RuneManager:
	return get_parent() as RuneManager


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("rune_overview", false):
		var m := _manager()
		if is_open:
			get_viewport().set_input_as_handled()
			close()
		elif not get_tree().paused and m and m.player and not m.player.is_dead and not m.player.controls_locked:
			get_viewport().set_input_as_handled()
			open()
	elif is_open and (event.is_action_pressed("pause", false) or event.is_action_pressed("ui_cancel", false)):
		get_viewport().set_input_as_handled()
		close()


func open() -> void:
	is_open = true
	_root.visible = true
	get_tree().paused = true
	Crosshair.arrow()
	Sfx.play("ui_open")
	_refresh()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	get_tree().paused = false
	Crosshair.restore()
	Sfx.play("ui_click")


func deactivate_all() -> void:
	var n := _manager().deactivate_all()
	Sfx.play("rune_deactivate" if n > 0 else "ui_click")
	_refresh()


## Whether she can inscribe this cube now: standing at it, or at its lectern.
static func in_reach(cube: RuneCube) -> bool:
	if cube.interactable and cube.interactable.enabled and cube.interactable.in_reach():
		return true
	for node in cube.get_tree().get_nodes_in_group("rune_lectern"):
		if node.get("cube") == cube and node.interactable and node.interactable.in_reach():
			return true
	return false


## Opens a cube's inscribe screen from this list.
func inscribe(cube: RuneCube) -> void:
	if not in_reach(cube):
		return
	close()
	_manager().assembly.open(cube)


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	inscribe_buttons.clear()
	var m := _manager()
	var cubes := m.room_cubes()
	var first: Button = null
	if cubes.is_empty():
		_list.add_child(_label("There are no rune cubes in this room.", 14, DIM))
	for cube in cubes:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var glyph := Control.new()
		glyph.custom_minimum_size = Vector2(44, 44)
		var c: RuneCube = cube
		glyph.draw.connect(func():
			for kind in 4:
				var id := c.recipe.get_slot(kind)
				var col := RuneFragments.essence_color(id) if kind == 0 else RuneFragments.NEUTRAL
				RuneFragments.draw_glyph(glyph, id, Vector2(11 + (kind % 2) * 22, 11 + (kind / 2) * 22), 18.0, col, 1.5))
		row.add_child(glyph)
		var text := VBoxContainer.new()
		text.custom_minimum_size = Vector2(430, 0)
		var d := c.description()
		text.add_child(_label("%s  ·  %s" % [c.display_name, d["title"]], 14, INK))
		var status := "ON" if c.is_active else ("carried" if c.is_carried else "off")
		var cost := "dungeon-powered" if c.fed_by_dungeon() else ("%s mana/s" % RuneBook._num(c.upkeep()) if c.is_active and c.upkeep() > 0.0 else "your mana")
		text.add_child(_label("%s  ·  %s" % [status, cost], 12, Color("a8e0ff") if c.is_active else DIM))
		text.add_child(_label(edit_line(c), 11, WARN if c.is_active else LOCK))
		row.add_child(text)
		var edit := Button.new()
		edit.text = "Inscribe"
		edit.disabled = not in_reach(c) or c.is_carried
		edit.tooltip_text = "Stand at this cube (or its lectern) to inscribe it."
		edit.custom_minimum_size = Vector2(120, 36)
		_style(edit)
		edit.pressed.connect(inscribe.bind(c))
		row.add_child(edit)
		inscribe_buttons[c] = edit
		var off := Button.new()
		off.text = "Always on" if c.is_machinery() else "Switch off"
		off.disabled = not c.is_active or c.is_machinery()
		if c.is_machinery():
			off.tooltip_text = "Part of the dungeon's machinery: it keeps running."
		off.custom_minimum_size = Vector2(130, 36)
		_style(off)
		off.pressed.connect(func():
			c.deactivate()
			_refresh())
		row.add_child(off)
		_list.add_child(row)
		if first == null and not edit.disabled:
			first = edit
		if first == null and not off.disabled:
			first = off
	var upkeep := m.total_upkeep
	_summary.text = "Your runes cost %s mana per second.  Mana %d / %d" % [RuneBook._num(upkeep), m.mana(), m.player.get_mana_cap() if m.player else 0] \
		if upkeep > 0.0 else "None of your runes is drawing mana.  Mana %d / %d" % [m.mana(), m.player.get_mana_cap() if m.player else 0]
	_all.disabled = not m.active_cubes().any(func(c): return not c.is_machinery())
	if first:
		first.grab_focus()
	elif not _all.disabled:
		_all.grab_focus()
	else:
		_done.grab_focus()


## One line on what can be changed on this cube, and what it takes.
static func edit_line(c: RuneCube) -> String:
	var locked := PackedStringArray()
	for kind in 4:
		if c.is_slot_locked(kind):
			locked.append(RuneFragments.KIND_NAMES[kind])
	var lock_text := "Locked: %s" % ", ".join(locked) if not locked.is_empty() else "No locked words"
	if locked.size() == 4:
		return "Every word is LOCKED: it can only be switched on and off."
	if c.is_active:
		return "RUNNING: switch it off to change its words.  ·  %s" % lock_text
	if c.is_carried:
		return "Set it down to inscribe it.  ·  %s" % lock_text
	return "Can be inscribed while off.  ·  %s" % lock_text


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.05, 0.66)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", DungeonUI.panel_style())
	DungeonUI.decorate(panel)
	_root.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var heading := _label("YOUR RUNES  ·  THIS ROOM", 24, Color("f0d27a"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)
	# The rules for changing words, always in view here
	var rules_box := PanelContainer.new()
	rules_box.add_theme_stylebox_override("panel", DungeonUI.lite_style())
	col.add_child(rules_box)
	_rules = _label("", 16, Color("e8dcc0"))
	_rules.add_theme_font_override("font", Fonts.STORY)
	_rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rules.custom_minimum_size = Vector2(760, 0)
	InputLabels.watch(_rules, func(): _rules.text = rules_text())
	rules_box.add_child(_rules)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	col.add_child(_list)
	_summary = _label("", 16, Color("ffd88a"))
	_summary.add_theme_font_override("font", Fonts.STORY)
	col.add_child(_summary)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	col.add_child(buttons)
	_all = Button.new()
	_all.text = "Deactivate All Runes"
	_all.custom_minimum_size = Vector2(240, 40)
	_style(_all)
	_all.pressed.connect(deactivate_all)
	buttons.add_child(_all)
	_done = Button.new()
	_done.text = "Done"
	_done.custom_minimum_size = Vector2(120, 40)
	_style(_done)
	_done.pressed.connect(close)
	buttons.add_child(_done)


## How editing works, in three short lines (key names filled in).
static func rules_text() -> String:
	return InputLabels.format("CHANGE A CUBE'S WORDS: stand at it and press {interact}, or press Inscribe here while you stand at it.\n"
		+ "ONLY WHILE IT IS OFF: a running cube's words can't change. Switch it off here (from anywhere in the room) or at the cube.\n"
		+ "LOCKED WORDS NEVER CHANGE: a padlock means that word is carved into the stone. Only the other words can be picked.")


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", maxi(size, 18))
	l.add_theme_color_override("font_color", color)
	return l


func _style(b: Button) -> void:
	# (the project theme draws the stone plates; only the size is set here)
	b.add_theme_font_size_override("font_size", 18)
