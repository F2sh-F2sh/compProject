class_name UiTour
extends CanvasLayer

## A short, one-time look at one part of the screen: the game pauses, the rest
## of the view dims, a frame marks the part being explained and a card says
## what it is. Space, Enter or a click moves to the next card; Esc closes it.
## Each tour is shown once per save (flag "ui.tour.<id>").
##
## The tours: "basics" (health, the Esc menu), "fire" (mana, the spell slots),
## "echo" (the Echo tag), "objective" (the goal card) and "runes" (how rune
## cubes are edited). Rooms and shrines name the tour they play (`explainer`,
## `tour`). Tests switch it off with `UiTour.enabled = false`.

signal finished

const FONT := Fonts.STORY
const INK := Color("e8dcc0")
const DIM := Color("9a8f86")
const FRAME := Color(0.94, 0.82, 0.48)

## Off in the automated tests, which would otherwise be paused by it.
static var enabled := true
static var current: UiTour

var id := ""
var steps: Array = []
var index := -1
var is_open := false

var _was_paused := false
var _dim: Array[ColorRect] = []
var _frame: Panel
var _card: PanelContainer
var _eyebrow: Label
var _title: Label
var _text: Label
var _hint: Label
var _cooldown := 0.0
## The arrows from the card to the parts of the screen it explains.
var _arrows: Control
var _time := 0.0

const ARROW := Color(1.0, 0.82, 0.38)
const ARROW_EDGE := Color(0.08, 0.05, 0.12, 0.95)


## Plays a tour the first time only (or always with `force`). Returns it, or
## null when it is off, already seen or unknown.
static func play(host: Node, tour_id: String, force := false) -> UiTour:
	if (not enabled and not force) or is_instance_valid(current):
		return null
	var flag := "ui.tour." + tour_id
	if GameState.has_flag(flag) and not force:
		return null
	var list := steps_for(tour_id)
	if list.is_empty() or host == null or not host.is_inside_tree():
		return null
	var tour := UiTour.new()
	tour.id = tour_id
	tour.steps = list
	host.get_tree().root.add_child(tour)
	return tour


## Plays a tour once the title cards have had time to go (and only if the
## player is still around to read it).
static func play_later(host: Node, tour_id: String, seconds: float) -> void:
	if not enabled or GameState.has_flag("ui.tour." + tour_id) or host == null or not host.is_inside_tree():
		return
	var reference: WeakRef = weakref(host)
	host.get_tree().create_timer(seconds).timeout.connect(func():
		var target := reference.get_ref() as Node
		if target and target.is_inside_tree():
			var player := target.get_tree().get_first_node_in_group("player")
			if player != null and (player.get("is_dead") or player.get("controls_locked")):
				play_later(target, tour_id, 2.0)
			else:
				play(target, tour_id))


## Where things are on the screen (offsets from the top-left corner): the
## health bar and its number, the mana bar and its number. (The health bar's
## arrow comes up through the gap between the mana plate and the numbers.)
const HEALTH_BAR := Rect2(150, 22, 310, 28)
const HEALTH_NUMBER := Rect2(334, 56, 94, 22)
const MANA_BAR := Rect2(88, 56, 112, 18)
const MANA_NUMBER := Rect2(222, 56, 112, 22)

## What each tour says. A step: "corner" ("tl", "tr", "br", "bl" or "" for no
## frame), "rect" (offset from that corner, in screen pixels), "title", "text",
## and optionally "arrows": the parts an arrow points at, each {"corner",
## "rect"}, numbered 1, 2... (the text names them by number). A framed step with
## no "arrows" gets one arrow at its frame.
static func steps_for(tour_id: String) -> Array:
	match tour_id:
		"basics":
			return [
				{"corner": "tl", "rect": Rect2(16, 16, 468, 66), "eyebrow": "THE SCREEN · 1 OF 2", "title": "Health",
					"arrows": [{"corner": "tl", "rect": HEALTH_BAR}, {"corner": "tl", "rect": HEALTH_NUMBER}],
					"text": "(1) This bar is your health. Spikes, traps and slimes take it down. (2) The same, in numbers: health left out of the most you can have. If it runs out, you wake at your last candle with it full again."},
				{"corner": "", "rect": Rect2(), "eyebrow": "THE SCREEN · 2 OF 2", "title": "The menu",
					"text": InputLabels.format("Press {pause} at any time to pause and open the menu: your spells and controls, the room map (with Reset Room), the journal, and the settings.")},
			]
		"fire":
			return [
				{"corner": "tl", "rect": Rect2(16, 52, 320, 30), "eyebrow": "THE SCREEN · MANA", "title": "Mana is your flame",
					"arrows": [{"corner": "tl", "rect": MANA_BAR}, {"corner": "tl", "rect": MANA_NUMBER}],
					"text": InputLabels.format("(1) This bar is your mana, your lantern's flame. Spells draw on it, and it does not fill by itself. (2) The same, in numbers. To restore it, hold {reload} anywhere. You can keep moving while you reload. Beaten slimes drop sparks that give some back.")},
				{"corner": "br", "rect": Rect2(-176, -104, 160, 88), "eyebrow": "THE SCREEN · SPELLS", "title": "Your spells",
					"text": "Each spell has a slot here: its key on top and its mana cost below. A slot goes dim when you don't have enough mana for it. New spells appear here as you remember them."},
			]
		"echo":
			return [
				{"corner": "tl", "rect": Rect2(16, 76, 140, 18), "eyebrow": "THE SCREEN · ECHO", "title": "The Echo tag",
					"text": InputLabels.format("When you press {echo}, a red REC tag shows how much recording time is left. Each Echo you have out is a diamond here, and it holds some of your mana until it fades.")},
			]
		"objective":
			return [
				{"corner": "tr", "rect": Rect2(-292, 16, 276, 78), "eyebrow": "THE SCREEN · THE GOAL", "title": "The goal card",
					"text": InputLabels.format("Each room names its goal here, and ticks off the steps as you do them. If you are stuck, the skull stones in a room give hints, and {pause} opens the room map and Reset Room.")},
			]
		"runes":
			return [
				{"corner": "", "rect": Rect2(), "eyebrow": "RUNE CUBES · 1 OF 5", "title": "Four words in a cube",
					"text": InputLabels.format("A rune cube holds a spell of four words: what it is made of, what it does, which way, and how. Walk up to a cube and press {interact} to inscribe it: pick a word for each part from the words you have learned, then switch it on.")},
				{"corner": "", "rect": Rect2(), "eyebrow": "RUNE CUBES · 2 OF 5", "title": "When you can change words",
					"text": "Only while the cube is OFF. A running cube's words can't be changed: switch it off first (at the cube, or from your runes list), change what you need, and switch it on again."},
				{"corner": "", "rect": Rect2(), "eyebrow": "RUNE CUBES · 3 OF 5", "title": "LOCKED words never change",
					"text": "A word with a padlock and the word LOCKED is carved into the stone: it can never be changed, on any cube. Some cubes have one or two locked words; some are locked completely and can only be switched on and off. Read a cube before you plan with it."},
				{"corner": "", "rect": Rect2(), "eyebrow": "RUNE CUBES · 4 OF 5", "title": InputLabels.format("{rune_overview}: your runes"),
					"text": InputLabels.format("Press {rune_overview} at any time to see every cube in the room: what each one does, whether it is on, what it costs and which words are locked. Switch any running cube off from there, from anywhere in the room, or press Inscribe on the cube you are standing at.")},
				{"corner": "tl", "rect": Rect2(16, 52, 320, 30), "eyebrow": "RUNE CUBES · 5 OF 5", "title": "Running runes use mana",
					"arrows": [{"corner": "tl", "rect": MANA_BAR}, {"corner": "tl", "rect": MANA_NUMBER}],
					"text": "A rune you power drains your mana (1) while it runs (2), and a rune that can't be paid for stops. Cubes fed by the dungeon (a groove under them, or standing in a pedestal) cost you nothing. When you run low, hold R to reload. Stop powering a rune first if it is drawing your mana."},
			]
	return []


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	current = self
	is_open = true
	_was_paused = get_tree().paused
	get_tree().paused = true
	Crosshair.arrow()
	_build()
	_show_step(0)


func _exit_tree() -> void:
	if current == self:
		current = null


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	for i in 4:
		var d := ColorRect.new()
		d.color = Color(0.02, 0.01, 0.05, 0.62)
		d.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(d)
		_dim.append(d)
	_frame = Panel.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.add_theme_stylebox_override("panel", DungeonUI.style("button_focus", 10, Vector4(0, 0, 0, 0)))
	root.add_child(_frame)
	_card = PanelContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_theme_stylebox_override("panel", DungeonUI.panel_style())
	_card.custom_minimum_size = Vector2(470, 0)
	root.add_child(_card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_card.add_child(box)
	_eyebrow = DungeonUI.caps("", 16, DIM)
	_title = DungeonUI.heading("", 36)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text = _label(16, INK)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(400, 0)
	_hint = _label(14, DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for l in [_eyebrow, _title, _text, _hint]:
		box.add_child(l)
	_arrows = Control.new()
	_arrows.set_anchors_preset(Control.PRESET_FULL_RECT)
	_arrows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrows.draw.connect(_draw_arrows)
	root.add_child(_arrows)


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## The frame's rectangle on screen for a step (empty if it has none).
func target_rect(step: Dictionary) -> Rect2:
	return _on_screen(step.get("corner", ""), step.get("rect", Rect2()))


## What a step's arrows point at, on screen, in their numbered order.
func arrow_targets(step: Dictionary) -> Array:
	var out := []
	for a in step.get("arrows", []):
		out.append(_on_screen(a["corner"], a["rect"]))
	if out.is_empty() and target_rect(step).size != Vector2.ZERO:
		out.append(target_rect(step))
	return out


func _on_screen(corner: String, r: Rect2) -> Rect2:
	if corner == "":
		return Rect2()
	var view := get_viewport().get_visible_rect().size
	var origin := Vector2(view.x if corner in ["tr", "br"] else 0.0, view.y if corner in ["bl", "br"] else 0.0)
	return Rect2(origin + r.position, r.size)


## Arrows from the card to each part it explains (numbered when there are
## several), drawn on top of the dimmed screen. They bob gently toward it.
func _draw_arrows() -> void:
	if index < 0 or index >= steps.size() or _card.modulate.a <= 0.0:
		return
	var targets := arrow_targets(steps[index])
	var card := Rect2(_card.position, _card.size)
	var bob := 3.0 * sin(_time * 5.0)
	var last_tail_x := -INF
	for i in targets.size():
		var t: Rect2 = targets[i]
		var above := t.get_center().y < card.position.y
		var tail_x := clampf(t.get_center().x, card.position.x + 24.0, card.end.x - 24.0)
		# (tails at least a badge apart)
		tail_x = maxf(tail_x, last_tail_x + 34.0)
		last_tail_x = tail_x
		var tail := Vector2(tail_x, card.position.y - 12.0 if above else card.end.y + 12.0)
		var tip := Vector2(t.get_center().x, t.end.y + 4.0 if above else t.position.y - 4.0)
		var dir := (tip - tail).normalized()
		tip += dir * bob
		var side := dir.orthogonal()
		var base := tip - dir * 13.0
		var start := tail + dir * 11.0
		var alpha := _card.modulate.a
		_arrows.draw_line(start, base, Color(ARROW_EDGE, alpha), 7.0)
		_arrows.draw_line(start, base, Color(ARROW, alpha), 3.0)
		_arrows.draw_colored_polygon(PackedVector2Array([tip + dir * 3.0, base + side * 10.0 - dir * 2.0, base - side * 10.0 - dir * 2.0]),
			Color(ARROW_EDGE, alpha))
		_arrows.draw_colored_polygon(PackedVector2Array([tip, base + side * 7.0, base - side * 7.0]), Color(ARROW, alpha))
		if targets.size() > 1:
			_arrows.draw_circle(tail, 11.0, Color(ARROW_EDGE, alpha))
			_arrows.draw_circle(tail, 9.0, Color(ARROW, alpha))
			_arrows.draw_string(FONT, tail + Vector2(-4.0, 5.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(ARROW_EDGE, alpha))


func _show_step(i: int) -> void:
	index = i
	_cooldown = 0.35
	var step: Dictionary = steps[i]
	_eyebrow.text = step.get("eyebrow", "")
	_title.text = step["title"]
	_text.text = step["text"]
	_hint.text = "%s  ·  Esc: close" % ("Space / click: next" if i + 1 < steps.size() else "Space / click: done")
	Sfx.play("ui_click", null, -8.0)
	_layout()
	_card.modulate.a = 0.0
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(_card, "modulate:a", 1.0, 0.25)


func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var hole := target_rect(steps[index])
	_frame.visible = hole.size != Vector2.ZERO
	if not _frame.visible:
		# No part of the screen: one dim over everything
		_dim[0].position = Vector2.ZERO
		_dim[0].size = view
		for i in range(1, 4):
			_dim[i].size = Vector2.ZERO
	else:
		hole = hole.grow(5.0)
		_frame.position = hole.position
		_frame.size = hole.size
		_dim[0].position = Vector2.ZERO
		_dim[0].size = Vector2(view.x, maxf(hole.position.y, 0.0))
		_dim[1].position = Vector2(0, hole.end.y)
		_dim[1].size = Vector2(view.x, maxf(view.y - hole.end.y, 0.0))
		_dim[2].position = Vector2(0, hole.position.y)
		_dim[2].size = Vector2(maxf(hole.position.x, 0.0), hole.size.y)
		_dim[3].position = Vector2(hole.end.x, hole.position.y)
		_dim[3].size = Vector2(maxf(view.x - hole.end.x, 0.0), hole.size.y)
	await get_tree().process_frame
	var card_size := _card.get_combined_minimum_size()
	_card.size = card_size
	var pos := Vector2((view.x - card_size.x) / 2.0, (view.y - card_size.y) / 2.0)
	if hole.size != Vector2.ZERO:
		# Beside the highlighted part, on the side with room (further off when
		# arrows point from it, so they read as arrows)
		var gap := 56.0 if not arrow_targets(steps[index]).is_empty() else 18.0
		var centre := hole.get_center()
		pos.x = clampf(centre.x - card_size.x / 2.0, 16.0, view.x - card_size.x - 16.0)
		pos.y = hole.end.y + gap if centre.y < view.y / 2.0 else hole.position.y - card_size.y - gap
	_card.position = pos
	_arrows.queue_redraw()


func _process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_time += delta
	if _arrows:
		_arrows.queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("pause", false) or event.is_action_pressed("ui_cancel", false):
		get_viewport().set_input_as_handled()
		close()
		return
	var press: bool = event.is_action_pressed("jump", false) or event.is_action_pressed("interact", false) \
		or event.is_action_pressed("ui_accept", false) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if press:
		get_viewport().set_input_as_handled()
		next()


func next() -> void:
	if not is_open or _cooldown > 0.0:
		return
	if index + 1 < steps.size():
		_show_step(index + 1)
	else:
		close()


func close() -> void:
	if not is_open:
		return
	is_open = false
	GameState.set_flag("ui.tour." + id)
	get_tree().paused = _was_paused
	finished.emit()
	queue_free()
