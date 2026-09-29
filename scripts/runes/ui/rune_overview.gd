class_name RuneOverview
extends CanvasLayer

## Tab (Back on a controller): every cube in this room at a glance, its rune,
## whether it is on, what it costs, with a "Switch off" per running cube and
## "Deactivate All Runes". Pauses the game while open. Cubes can be
## switched off from here (remotely) but only switched on at the cube.

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")
const INK := Color("e4ddf2")
const DIM := Color("9c92b8")

var is_open := false
var _root: Control
var _list: VBoxContainer
var _summary: Label
var _all: Button
var _done: Button


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


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
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
		row.add_child(text)
		var off := Button.new()
		off.text = "Switch off"
		off.disabled = not c.is_active
		off.custom_minimum_size = Vector2(130, 36)
		_style(off)
		off.pressed.connect(func():
			c.deactivate()
			_refresh())
		row.add_child(off)
		_list.add_child(row)
		if first == null and not off.disabled:
			first = off
	var upkeep := m.total_upkeep
	_summary.text = "Your runes cost %s mana per second.  Mana %d / %d" % [RuneBook._num(upkeep), m.mana(), m.player.get_mana_cap() if m.player else 0] \
		if upkeep > 0.0 else "None of your runes is drawing mana.  Mana %d / %d" % [m.mana(), m.player.get_mana_cap() if m.player else 0]
	_all.disabled = m.active_cubes().is_empty()
	if first:
		first.grab_focus()
	elif not _all.disabled:
		_all.grab_focus()
	else:
		_done.grab_focus()


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
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.035, 0.09, 0.97)
	box.border_color = Color(0.5, 0.38, 0.78, 0.9)
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", box)
	_root.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	var heading := _label("RUNES IN THIS ROOM", 20, Color("cbbdf2"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(heading)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	col.add_child(_list)
	_summary = _label("", 13, Color("ffd88a"))
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


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _style(b: Button) -> void:
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 14)
	var mk := func(bg: Color, border: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = bg
		s.border_color = border
		s.set_border_width_all(2)
		s.set_corner_radius_all(4)
		s.content_margin_left = 8
		s.content_margin_right = 8
		return s
	b.add_theme_stylebox_override("normal", mk.call(Color(0.1, 0.08, 0.16), Color(0.32, 0.26, 0.5)))
	b.add_theme_stylebox_override("hover", mk.call(Color(0.16, 0.12, 0.26), Color(0.6, 0.5, 0.9)))
	b.add_theme_stylebox_override("pressed", mk.call(Color(0.2, 0.15, 0.34), Color(0.85, 0.78, 1.0)))
	b.add_theme_stylebox_override("focus", mk.call(Color(0, 0, 0, 0), Color(1, 1, 1, 0.9)))
	b.add_theme_stylebox_override("disabled", mk.call(Color(0.07, 0.06, 0.1), Color(0.2, 0.18, 0.28)))
