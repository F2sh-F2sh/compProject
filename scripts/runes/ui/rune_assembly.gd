class_name RuneAssembly
extends CanvasLayer

## The screen for inscribing one cube. The game pauses while it is open.
## Left: the cube's 2x2 rune, one button per quadrant (essence, form,
## direction, modifier). Right: the fragments the player knows for the
## selected quadrant. Below: what the rune will do and what it costs,
## written from the same numbers the game uses, or exactly why it can't be
## cast. Everything works with the mouse, the keyboard (arrows, Enter, Esc)
## or a controller (d-pad, A, B).
##
## A running cube can be looked at and switched off here, but its rune can
## only be changed once it is off.

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")
const INK := Color("e4ddf2")
const DIM := Color("9c92b8")
const BAD := Color("ff9a8a")
const GOOD := Color("a8e0ff")

var is_open := false
var cube: RuneCube
var selected_kind := 0
var _root: Control
var _slot_buttons: Array[Button] = []
var _slot_glyphs: Array[Control] = []
var _palette: GridContainer
var _palette_title: Label
var _title: Label
var _effect: Label
var _cost: Label
var _state: Label
var _toggle: Button
var _close: Button
var _note: Label
var _palette_buttons: Array[Button] = []


func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func open(target: RuneCube) -> void:
	if is_open or target == null:
		return
	cube = target
	cube.is_selected = true
	is_open = true
	selected_kind = _first_editable_kind()
	_root.visible = true
	get_tree().paused = true
	Crosshair.arrow()
	Sfx.play("ui_open")
	_refresh()
	_slot_buttons[selected_kind].grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	if is_instance_valid(cube):
		cube.is_selected = false
	cube = null
	get_tree().paused = false
	Crosshair.restore()
	Sfx.play("ui_click")


func _first_editable_kind() -> int:
	# Start on a broken quadrant if there is one, else the first open one
	for kind in 4:
		if cube.recipe.get_slot(kind) == &"" and not cube.is_slot_locked(kind):
			return kind
	for kind in 4:
		if not cube.is_slot_locked(kind):
			return kind
	return 0


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("pause", false) or event.is_action_pressed("ui_cancel", false):
		get_viewport().set_input_as_handled()
		close()


# ---------------------------------------------------------------- actions

func select_kind(kind: int) -> void:
	selected_kind = kind
	Sfx.play("ui_hover", null, -8.0)
	_refresh()


func choose(id: StringName) -> void:
	if cube == null or not cube.can_edit() or cube.is_slot_locked(selected_kind):
		Sfx.play("rune_blocked", null, -6.0)
		return
	cube.set_slot(selected_kind, id)
	Sfx.play("rune_select", null, -4.0)
	_refresh()
	# On to the next quadrant that still needs a fragment
	for step in range(1, 4):
		var kind := (selected_kind + step) % 4
		if cube.recipe.get_slot(kind) == &"" and not cube.is_slot_locked(kind):
			selected_kind = kind
			_refresh()
			_slot_buttons[kind].grab_focus()
			return
	_slot_buttons[selected_kind].grab_focus()


func toggle_cube() -> void:
	if cube == null:
		return
	var why := cube.toggle()
	if why != "":
		_state.text = why
		_state.add_theme_color_override("font_color", BAD)
		return
	_refresh()
	if cube.is_active:
		close()


# ---------------------------------------------------------------- view

func _refresh() -> void:
	if cube == null:
		return
	var editable := cube.can_edit()
	for kind in 4:
		var id := cube.recipe.get_slot(kind)
		var b := _slot_buttons[kind]
		b.tooltip_text = RuneFragments.meaning_of(id) if id != &"" else "Broken: choose a %s." % RuneFragments.KIND_NAMES[kind].to_lower()
		b.modulate = Color(1, 1, 1, 1) if not cube.is_slot_locked(kind) else Color(0.75, 0.72, 0.85)
		b.button_pressed = kind == selected_kind
		_slot_glyphs[kind].queue_redraw()
	# Palette: every known fragment of the selected kind
	for child in _palette.get_children():
		child.queue_free()
	_palette_buttons.clear()
	var locked := cube.is_slot_locked(selected_kind)
	_palette_title.text = "%s fragments you know" % RuneFragments.KIND_NAMES[selected_kind]
	if locked:
		_palette_title.text = "This %s is carved deep: it can't be changed." % RuneFragments.KIND_NAMES[selected_kind].to_lower()
	for id in RuneFragments.of_kind(selected_kind):
		if not RuneManager.knows(id, get_tree()):
			continue
		var b := _fragment_button(id)
		b.disabled = locked or not editable
		b.button_pressed = cube.recipe.get_slot(selected_kind) == id
		_palette.add_child(b)
		_palette_buttons.append(b)
	var d := cube.description()
	_title.text = d["title"]
	_effect.text = d["effect"]
	_effect.add_theme_color_override("font_color", INK if d["valid"] else BAD)
	_cost.text = d["cost"]
	_cost.visible = d["cost"] != ""
	_toggle.text = "Switch off" if cube.is_active else "Switch on"
	_toggle.disabled = not cube.is_active and not d["valid"]
	_note.text = "" if editable else "Switch the cube off to change its rune."
	var power := "Powered by the dungeon" if cube.fed_by_dungeon() else "Draws on your mana"
	_state.text = "%s  ·  %s  ·  %s" % [cube.display_name, "ON" if cube.is_active else "off", power]
	_state.add_theme_color_override("font_color", DIM)


func _fragment_button(id: StringName) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(168, 52)
	b.text = RuneFragments.name_of(id)
	b.tooltip_text = RuneFragments.meaning_of(id)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style_button(b)
	# Room on the left for the glyph
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box: StyleBoxFlat = b.get_theme_stylebox(state).duplicate()
		box.content_margin_left = 52
		b.add_theme_stylebox_override(state, box)
	var glyph := Control.new()
	glyph.custom_minimum_size = Vector2(36, 36)
	glyph.position = Vector2(8, 8)
	glyph.size = Vector2(36, 36)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kind := selected_kind
	glyph.draw.connect(func():
		var col := RuneFragments.essence_color(id) if kind == RuneFragments.Kind.ESSENCE else RuneFragments.NEUTRAL
		RuneFragments.draw_glyph(glyph, id, Vector2(18, 18), 30.0, col, 2.0))
	b.add_child(glyph)
	b.pressed.connect(choose.bind(id))
	b.focus_entered.connect(func(): _hover_meaning(id))
	b.mouse_entered.connect(func(): _hover_meaning(id))
	return b


func _hover_meaning(id: StringName) -> void:
	_note.text = "%s: %s" % [RuneFragments.name_of(id), RuneFragments.meaning_of(id)]


# ---------------------------------------------------------------- building

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.05, 0.72)
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.add_theme_stylebox_override("panel", _box(Color(0.05, 0.035, 0.09, 0.97), Color(0.5, 0.38, 0.78, 0.9), 16))
	_root.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	panel.add_child(outer)

	var heading := _label("INSCRIBE THE CUBE", 22, Color("cbbdf2"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(heading)
	_state = _label("", 13, DIM)
	_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_state)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	outer.add_child(row)

	# The composite: four quadrant buttons in a 2x2 grid
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	row.add_child(left)
	left.add_child(_label("The rune", 14, DIM))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	left.add_child(grid)
	for kind in 4:
		var b := Button.new()
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(150, 132)
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_style_button(b)
		b.add_theme_font_size_override("font_size", 13)
		var glyph := Control.new()
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
		var k := kind
		glyph.draw.connect(func(): _draw_slot(glyph, k))
		b.add_child(glyph)
		b.pressed.connect(select_kind.bind(kind))
		b.focus_entered.connect(func(): if selected_kind != k: select_kind(k))
		grid.add_child(b)
		_slot_buttons.append(b)
		_slot_glyphs.append(glyph)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right.custom_minimum_size = Vector2(360, 0)
	row.add_child(right)
	_palette_title = _label("", 14, DIM)
	right.add_child(_palette_title)
	_palette = GridContainer.new()
	_palette.columns = 2
	_palette.add_theme_constant_override("h_separation", 6)
	_palette.add_theme_constant_override("v_separation", 6)
	right.add_child(_palette)

	# What it does, what it costs
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 4)
	info.custom_minimum_size = Vector2(700, 96)
	outer.add_child(info)
	_title = _label("", 18, GOOD)
	info.add_child(_title)
	_effect = _label("", 14, INK)
	_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_effect)
	_cost = _label("", 14, Color("ffd88a"))
	info.add_child(_cost)
	_note = _label("", 12, DIM)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_note)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	outer.add_child(buttons)
	_toggle = Button.new()
	_toggle.custom_minimum_size = Vector2(200, 40)
	_style_button(_toggle)
	_toggle.pressed.connect(toggle_cube)
	buttons.add_child(_toggle)
	_close = Button.new()
	_close.text = "Done"
	_close.custom_minimum_size = Vector2(140, 40)
	_style_button(_close)
	_close.pressed.connect(close)
	buttons.add_child(_close)
	var hint := _label("Arrows / d-pad: choose   ·   Enter / A: pick   ·   Esc / B: done", 11, DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(hint)


func _draw_slot(canvas: Control, kind: int) -> void:
	if cube == null:
		return
	var id := cube.recipe.get_slot(kind)
	var col := RuneFragments.essence_color(id) if kind == RuneFragments.Kind.ESSENCE else RuneFragments.NEUTRAL
	if id == &"":
		col = BAD
	var c := Vector2(canvas.size.x / 2.0, canvas.size.y / 2.0 - 2.0)
	RuneFragments.draw_glyph(canvas, id, c, 52.0, col, 2.5)
	var w := canvas.size.x
	canvas.draw_string(FONT, Vector2(0, 20), RuneFragments.KIND_NAMES[kind].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, w, 11, DIM)
	canvas.draw_string(FONT, Vector2(0, canvas.size.y - 10), RuneFragments.name_of(id) if id != &"" else "(broken)",
		HORIZONTAL_ALIGNMENT_CENTER, w, 14, INK if id != &"" else BAD)
	if cube.is_slot_locked(kind):
		canvas.draw_rect(Rect2(canvas.size.x - 16, 6, 10, 10), Color(0.7, 0.65, 0.85, 0.8), false, 1.5)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _box(bg: Color, border: Color, margin: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(4)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.75
	s.content_margin_bottom = margin * 0.75
	return s


func _style_button(b: Button) -> void:
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.47, 0.6))
	b.add_theme_stylebox_override("normal", _box(Color(0.1, 0.08, 0.16), Color(0.32, 0.26, 0.5), 6))
	b.add_theme_stylebox_override("hover", _box(Color(0.16, 0.12, 0.26), Color(0.6, 0.5, 0.9), 6))
	b.add_theme_stylebox_override("pressed", _box(Color(0.2, 0.15, 0.34), Color(0.85, 0.78, 1.0), 6))
	b.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), Color(1, 1, 1, 0.9), 6))
	b.add_theme_stylebox_override("disabled", _box(Color(0.07, 0.06, 0.1), Color(0.2, 0.18, 0.28), 6))
