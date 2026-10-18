class_name RuneAssembly
extends CanvasLayer

## The screen for inscribing one cube, as a carved stone wheel (after the
## dungeon kit, tools/art/generate_rune_ui_sprites.gd). The game pauses while it
## is open.
##   Left: the wheel. Its four sockets hold the sentence's words (essence at
##   the top, form right, direction below, modifier left); the sentence's
##   sigil glows in the middle in its own colours (RuneFragments.combo_glow),
##   and the stone eye over the wheel opens once the sentence is whole.
##   Middle: the fragments she knows for the chosen socket, as stone tablets.
##   Right: "Where it goes", a window onto the room framing the sentence's
##   path (AimPreview draws it in the world), and on parchment what the rune
##   will do and cost, or exactly why it can't be cast.
## Everything works with the mouse, the keyboard (arrows, Enter, Esc) or a
## controller (d-pad, A, B).
##
## A running cube can be looked at and switched off here, but its rune can
## only be changed once it is off. Words carved into the stone (locked
## sockets) never change; they carry a padlock and the word LOCKED. A banner
## always says which of these rules applies to this cube right now.

const FONT := Fonts.UI
const INK := Color("e8dcc0")
const DIM := Color("9a8f86")
const BAD := Color("ff9a8a")
const GOOD := Color("f0d27a")
const WARN := Color("ffc070")
const LOCK := Color(0.85, 0.72, 0.45)
const WHEEL := preload("res://assets/ui/rune_wheel.png")
const EYE_SHUT := preload("res://assets/ui/rune_eye_closed.png")
const EYE_OPEN := preload("res://assets/ui/rune_eye_open.png")
const WHEEL_SIZE := 320.0
## The sockets' centres on the wheel (essence, form, direction, modifier).
const SOCKETS := [Vector2(160, 84), Vector2(236, 160), Vector2(160, 236), Vector2(84, 160)]
const PREVIEW_SIZE := Vector2(300, 190)

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
var _banner: Label
var _palette_buttons: Array[Button] = []
var _wheel: Control
var _eye: TextureRect
var _sigil: Control
var _legend: Array[Label] = []
var _glows: Array[Sprite2D] = []
var _preview_view: SubViewport
var _preview_camera: Camera2D
var _aim: AimPreview
var _time := 0.0
## Why the last pick was refused ("" when it wasn't), shown until the next refresh.
var refused := ""


func _ready() -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


func open(target: RuneCube) -> void:
	if is_open or target == null:
		return
	refused = ""
	cube = target
	cube.is_selected = true
	is_open = true
	selected_kind = _first_editable_kind()
	_root.visible = true
	get_tree().paused = true
	Crosshair.arrow()
	Sfx.play("ui_open")
	_aim = AimPreview.new()
	_aim.cube = cube
	cube.get_parent().add_child(_aim)
	_preview_view.world_2d = cube.get_world_2d()
	_refresh()
	_slot_buttons[selected_kind].grab_focus()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	if is_instance_valid(cube):
		cube.is_selected = false
	if is_instance_valid(_aim):
		_aim.queue_free()
	_aim = null
	cube = null
	get_tree().paused = false
	Crosshair.restore()
	Sfx.play("ui_click")


func _first_editable_kind() -> int:
	# Start on a broken socket if there is one, else the first open one
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


func _process(delta: float) -> void:
	if not is_open:
		return
	_time += delta
	_sigil.queue_redraw()
	var look := RuneFragments.combo_glow(cube.recipe) if cube else {}
	for kind in 4:
		var g := _glows[kind]
		var on := cube != null and cube.recipe.get_slot(kind) != &""
		var target := 0.0
		if on:
			target = 0.35 + 0.15 * sin(_time * 3.0 * maxf(float(look.get("speed", 1.0)), 0.3) + kind)
		g.modulate.a = move_toward(g.modulate.a, target, delta * 2.0)


# ---------------------------------------------------------------- actions

func select_kind(kind: int) -> void:
	refused = ""
	selected_kind = kind
	Sfx.play("ui_hover", null, -8.0)
	_refresh()


func choose(id: StringName) -> void:
	if cube == null:
		return
	if not cube.can_edit() or cube.is_slot_locked(selected_kind):
		Sfx.play("rune_blocked", null, -6.0)
		refused = why_not_editable(selected_kind)
		_note.text = refused
		_note.add_theme_color_override("font_color", BAD)
		return
	refused = ""
	cube.set_slot(selected_kind, id)
	Sfx.play("rune_select", null, -4.0)
	_refresh()
	# On to the next socket that still needs a fragment
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


## Why the word in socket `kind` can't be changed right now ("" if it can).
func why_not_editable(kind: int) -> String:
	if cube == null:
		return ""
	if cube.is_active:
		return "This cube is running. Switch it off first: a running cube's words can't be changed."
	if cube.is_slot_locked(kind):
		return "The %s is LOCKED: it is carved into the stone and can never be changed. Pick a part without a padlock." \
			% RuneFragments.KIND_NAMES[kind].to_lower()
	return ""


## The rule that matters for this cube right now, for the banner.
func banner_text() -> String:
	if cube == null:
		return ""
	var locked := 0
	for kind in 4:
		if cube.is_slot_locked(kind):
			locked += 1
	if cube.is_active:
		return "RUNNING  ·  Switch it off to change its words."
	if locked == 4:
		return "Every word on this cube is LOCKED (carved in). You can only switch it on and off."
	if locked > 0:
		return "Words with a padlock are LOCKED and can't be changed. The other %d can, while the cube is off." % (4 - locked)
	return "Pick a word for each socket. You can change them whenever the cube is off."


# ---------------------------------------------------------------- view

func _refresh() -> void:
	if cube == null:
		return
	var editable := cube.can_edit()
	_banner.text = banner_text()
	_banner.add_theme_color_override("font_color", WARN if cube.is_active else LOCK)
	var look := RuneFragments.combo_glow(cube.recipe)
	for kind in 4:
		var id := cube.recipe.get_slot(kind)
		var b := _slot_buttons[kind]
		b.tooltip_text = RuneFragments.meaning_of(id) if id != &"" else "Broken: choose a %s." % RuneFragments.KIND_NAMES[kind].to_lower()
		b.modulate = Color(1, 1, 1, 1) if not cube.is_slot_locked(kind) else Color(0.85, 0.8, 0.72)
		b.button_pressed = kind == selected_kind
		_slot_glyphs[kind].queue_redraw()
		_glows[kind].modulate = Color(look["color"] if kind == RuneFragments.Kind.ESSENCE else look["accent"], _glows[kind].modulate.a)
		var word := RuneFragments.name_of(id) if id != &"" else "(broken)"
		_legend[kind].text = "%s  ·  %s%s" % [RuneFragments.KIND_NAMES[kind].to_upper(), word, "  (locked)" if cube.is_slot_locked(kind) else ""]
		_legend[kind].add_theme_color_override("font_color", GOOD if kind == selected_kind else (BAD if id == &"" else INK))
	_eye.texture = EYE_OPEN if look["whole"] and RuneBook.is_valid(cube.recipe) else EYE_SHUT
	_eye.modulate = Color(look["color"].lerp(Color.WHITE, 0.4)) if _eye.texture == EYE_OPEN else Color.WHITE
	# Palette: every known fragment of the selected kind, on stone tablets
	for child in _palette.get_children():
		child.queue_free()
	_palette_buttons.clear()
	var locked := cube.is_slot_locked(selected_kind)
	_palette_title.text = "%s fragments you know" % RuneFragments.KIND_NAMES[selected_kind]
	if locked:
		_palette_title.text = "LOCKED: this %s is carved in and can't be changed." % RuneFragments.KIND_NAMES[selected_kind].to_lower()
	elif not editable:
		_palette_title.text = "Switch the cube off to change its %s." % RuneFragments.KIND_NAMES[selected_kind].to_lower()
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
	_effect.add_theme_color_override("font_color", DungeonUI.INK_DARK if d["valid"] else Color("8e2433"))
	_cost.text = d["cost"]
	_cost.visible = d["cost"] != ""
	_toggle.text = "Switch off" if cube.is_active else "Switch on"
	_toggle.disabled = not cube.is_active and not d["valid"]
	_note.text = "" if editable else "Switch the cube off to change its rune."
	_note.add_theme_color_override("font_color", DIM)
	if refused != "":
		_note.text = refused
		_note.add_theme_color_override("font_color", BAD)
	var power := "Powered by the dungeon" if cube.fed_by_dungeon() else "Draws on your mana"
	_state.text = "%s  ·  %s  ·  %s" % [cube.display_name, "ON" if cube.is_active else "off", power]
	_state.add_theme_color_override("font_color", DIM)
	_frame_preview()


## Frames the "Where it goes" window on the cube and the end of its path.
func _frame_preview() -> void:
	if not is_instance_valid(_aim):
		return
	_aim.refresh()
	var lo := _aim.from.min(_aim.to) - Vector2(48, 48) - Vector2.ONE * _aim.radius
	var hi := _aim.from.max(_aim.to) + Vector2(48, 48) + Vector2.ONE * _aim.radius
	var span := (hi - lo).max(PREVIEW_SIZE * 0.5)
	var zoom := minf(PREVIEW_SIZE.x / span.x, PREVIEW_SIZE.y / span.y)
	_preview_camera.zoom = Vector2.ONE * clampf(zoom, 0.2, 2.0)
	_preview_camera.global_position = (lo + hi) / 2.0


func _fragment_button(id: StringName) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(150, 48)
	b.text = RuneFragments.name_of(id)
	b.tooltip_text = RuneFragments.meaning_of(id)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", Fonts.STORY)
	b.add_theme_font_size_override("font_size", 18)
	var tablet := DungeonUI.style("rune_tablet", 8, Vector4(48, 6, 8, 6))
	for state in ["normal", "disabled"]:
		b.add_theme_stylebox_override(state, tablet)
	for state in ["hover", "focus"]:
		b.add_theme_stylebox_override(state, DungeonUI.style("button_hover", 10, Vector4(48, 6, 8, 6)))
	b.add_theme_stylebox_override("pressed", DungeonUI.style("button_pressed", 10, Vector4(48, 6, 8, 6)))
	var glyph := Control.new()
	glyph.custom_minimum_size = Vector2(34, 34)
	glyph.position = Vector2(8, 7)
	glyph.size = Vector2(34, 34)
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kind := selected_kind
	glyph.draw.connect(func():
		var col := RuneFragments.essence_color(id) if kind == RuneFragments.Kind.ESSENCE else Color("e6c98e")
		RuneFragments.draw_glyph(glyph, id, Vector2(17, 17), 28.0, col, 2.0))
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
	dim.color = Color(0.02, 0.01, 0.03, 0.66)
	_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.add_child(panel)
	DungeonUI.decorate(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)

	var heading := DungeonUI.heading("Inscribe the Cube", 36)
	outer.add_child(heading)
	_state = _label("", 14, DIM, Fonts.STORY)
	_state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_state)
	# The rule that applies to this cube right now (running, locked words...)
	_banner = _label("", 14, LOCK, Fonts.STORY)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_banner.custom_minimum_size = Vector2(940, 0)
	outer.add_child(_banner)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	outer.add_child(row)

	# The wheel, its sockets, its eye and its sigil
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	row.add_child(left)
	_wheel = Control.new()
	_wheel.custom_minimum_size = Vector2(WHEEL_SIZE, WHEEL_SIZE + 14.0)
	_wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_wheel)
	var art := TextureRect.new()
	art.texture = WHEEL
	art.position = Vector2(0, 14)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wheel.add_child(art)
	for kind in 4:
		var g := Sprite2D.new()
		g.texture = preload("res://assets/fx/soft_glow.png")
		g.position = SOCKETS[kind] + Vector2(0, 14)
		g.scale = Vector2.ONE * 0.6
		var add := CanvasItemMaterial.new()
		add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		g.material = add
		g.modulate.a = 0.0
		_wheel.add_child(g)
		_glows.append(g)
	_sigil = Control.new()
	_sigil.position = Vector2(WHEEL_SIZE / 2.0 - 24.0, WHEEL_SIZE / 2.0 - 10.0)
	_sigil.size = Vector2(48, 48)
	_sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sigil.draw.connect(_draw_sigil)
	_wheel.add_child(_sigil)
	_eye = TextureRect.new()
	_eye.texture = EYE_SHUT
	_eye.position = Vector2(WHEEL_SIZE / 2.0 - 40.0, -8.0)
	_eye.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_wheel.add_child(_eye)
	var empty := StyleBoxEmpty.new()
	for kind in 4:
		var b := Button.new()
		b.toggle_mode = true
		b.size = Vector2(64, 64)
		b.position = SOCKETS[kind] + Vector2(-32, -32 + 14)
		b.focus_mode = Control.FOCUS_ALL
		for state in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			b.add_theme_stylebox_override(state, empty)
		b.add_theme_stylebox_override("focus", DungeonUI.style("button_focus", 10, Vector4(0, 0, 0, 0)))
		var glyph := Control.new()
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glyph.set_anchors_preset(Control.PRESET_FULL_RECT)
		var k := kind
		glyph.draw.connect(func(): _draw_slot(glyph, k))
		b.add_child(glyph)
		b.pressed.connect(select_kind.bind(kind))
		b.focus_entered.connect(func(): if selected_kind != k: select_kind(k))
		_wheel.add_child(b)
		_slot_buttons.append(b)
		_slot_glyphs.append(glyph)

	# The fragments she knows, as stone tablets
	var middle := VBoxContainer.new()
	middle.add_theme_constant_override("separation", 8)
	middle.custom_minimum_size = Vector2(310, 0)
	row.add_child(middle)
	_palette_title = _label("", 16, GOOD)
	_palette_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_palette_title.custom_minimum_size = Vector2(310, 0)
	middle.add_child(_palette_title)
	_palette = GridContainer.new()
	_palette.columns = 2
	_palette.add_theme_constant_override("h_separation", 8)
	_palette.add_theme_constant_override("v_separation", 8)
	middle.add_child(_palette)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	middle.add_child(gap)
	for kind in 4:
		var l := _label("", 16, INK, Fonts.STORY)
		l.custom_minimum_size = Vector2(310, 0)
		middle.add_child(l)
		_legend.append(l)

	# Where it goes, and what it does
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	right.custom_minimum_size = Vector2(PREVIEW_SIZE.x, 0)
	row.add_child(right)
	right.add_child(_label("WHERE IT GOES", 16, GOOD))
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", DungeonUI.style("panel_lite", 8, Vector4(4, 4, 4, 4)))
	right.add_child(frame)
	var container := SubViewportContainer.new()
	container.custom_minimum_size = PREVIEW_SIZE
	container.stretch = true
	frame.add_child(container)
	_preview_view = SubViewport.new()
	_preview_view.size = Vector2i(PREVIEW_SIZE)
	_preview_view.transparent_bg = false
	_preview_view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_preview_view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	container.add_child(_preview_view)
	_preview_camera = Camera2D.new()
	_preview_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_preview_view.add_child(_preview_camera)
	var paper := PanelContainer.new()
	paper.theme_type_variation = &"ParchmentPanel"
	paper.custom_minimum_size = Vector2(PREVIEW_SIZE.x, 0)
	right.add_child(paper)
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	paper.add_child(info)
	_title = _label("", 16, DungeonUI.INK_DARK)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_title)
	_effect = _label("", 15, DungeonUI.INK_DARK, Fonts.STORY)
	_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_effect)
	_cost = _label("", 15, Color("6a1824"), Fonts.STORY)
	_cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(_cost)
	_note = _label("", 14, DIM, Fonts.STORY)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(940, 0)

	outer.add_child(_note)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	outer.add_child(buttons)
	_toggle = Button.new()
	_toggle.custom_minimum_size = Vector2(220, 44)
	_toggle.pressed.connect(toggle_cube)
	buttons.add_child(_toggle)
	_close = Button.new()
	_close.text = "Done"
	_close.custom_minimum_size = Vector2(160, 44)
	_close.pressed.connect(close)
	buttons.add_child(_close)
	var rules := _label("", 14, Color("d9c9a8"), Fonts.STORY)
	rules.name = "Rules"
	rules.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	InputLabels.watch(rules, func(): rules.text = InputLabels.format("Words change only while the cube is OFF  ·  LOCKED words never change  ·  {rune_overview}: every rune here  ·  %s: done" % ("B" if InputLabels.use_pad else "Esc")))
	rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules.custom_minimum_size = Vector2(940, 0)
	outer.add_child(rules)


func _draw_slot(canvas: Control, kind: int) -> void:
	if cube == null:
		return
	var id := cube.recipe.get_slot(kind)
	var look := RuneFragments.combo_glow(cube.recipe)
	var col: Color = look["color"] if kind == RuneFragments.Kind.ESSENCE else look["accent"]
	if id == &"":
		col = BAD
	var c := canvas.size / 2.0
	RuneFragments.draw_glyph(canvas, id, c, 34.0, col, 2.5)
	if cube.is_slot_locked(kind):
		# a small padlock: carved in, can't change
		var p := Vector2(canvas.size.x - 16, 2)
		canvas.draw_arc(p + Vector2(5, 6), 3.5, PI, TAU, 10, LOCK, 2.0)
		canvas.draw_rect(Rect2(p + Vector2(0, 6), Vector2(10, 8)), LOCK)
		canvas.draw_rect(Rect2(p + Vector2(4, 9), Vector2(2, 3)), Color(0.1, 0.08, 0.1))
	elif cube.is_active:
		canvas.draw_circle(Vector2(canvas.size.x - 8, 8), 3.0, WARN)


## The sentence's sigil at the wheel's heart: its four glyphs in a diamond,
## glowing at the sentence's own pace; a red stutter while it is broken.
func _draw_sigil() -> void:
	if cube == null:
		return
	var look := RuneFragments.combo_glow(cube.recipe)
	var c := _sigil.size / 2.0
	var pulse := 0.6 + 0.4 * sin(_time * 3.0 * maxf(float(look["speed"]), 0.3))
	if look["flicker"]:
		pulse = 0.35 if int(_time * 6.0) % 3 == 0 else 0.7
	var col: Color = look["color"] if look["whole"] else Color(0.8, 0.3, 0.3)
	_sigil.draw_circle(c, 22.0 * float(look["size"]) * 0.8, Color(col.darkened(0.5), 0.35 * pulse))
	var offsets := [Vector2(0, -11), Vector2(11, 0), Vector2(0, 11), Vector2(-11, 0)]
	for kind in 4:
		var id := cube.recipe.get_slot(kind)
		if id != &"":
			RuneFragments.draw_glyph(_sigil, id, c + offsets[kind], 10.0, Color(col.lerp(look["accent"], 0.4), pulse), 1.5)


func _label(text: String, size: int, color: Color, font: Font = FONT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", maxi(size, 18))
	l.add_theme_color_override("font_color", color)
	return l
