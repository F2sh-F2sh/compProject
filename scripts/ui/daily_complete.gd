class_name DailyComplete
extends CanvasLayer

## The card after a daily (or practice, or trial) puzzle: stars, the score and
## what was taken off it, the ways the rooms could have been solved and the
## ones she found, the streak, and a short code to share the result.
## It pauses the game like the story's end card (ChapterComplete).

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const FONT := Fonts.STORY
const GOLD := Color("f0d27a")
const GOLD_DIM := Color("c9a24a")
const INK := Color("e8dcc0")
const DIM := Color("8a8092")

var _root: Control
var again_button: Button
var title_button: Button
var copy_button: Button
var code_field: LineEdit
## What it was opened with (the tests read it).
var data := {}


## `data`: {result, scored, info, ways: [String], code, mode, kit_tier}
static func open(host: Node, card_data: Dictionary) -> DailyComplete:
	var card := DailyComplete.new()
	card.data = card_data
	host.add_child(card)
	card._build()
	return card


func _build() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Crosshair.arrow()
	var result: Dictionary = data["result"]
	var scored: Dictionary = data["scored"]
	var info: Dictionary = data.get("info", {})
	var mode := String(data.get("mode", "daily"))

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.05, 0.84)
	_root.add_child(dim)
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	var height := get_viewport().get_visible_rect().size.y - 40
	card.offset_left = -300
	card.offset_right = 300
	card.offset_top = -height / 2
	card.offset_bottom = height / 2
	_root.add_child(card)
	DungeonUI.decorate(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 7)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	card.add_child(scroll)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	var heading: String = {"daily": "TODAY'S PUZZLE SOLVED", "practice": "PRACTICE RUN", "trial": "TRIAL SOLVED"}.get(mode, "PUZZLE SOLVED")
	box.add_child(_line(heading, Fonts.UI, 16, GOLD_DIM))
	var subtitle := "Trial seed %d" % int(data.get("seed", 0)) if mode == "trial" else DailyRng.label_of(int(result["day"]))
	box.add_child(_line("%s  ·  %s" % [subtitle, _difficulty_name(int(result["difficulty"]))], Fonts.TITLE, 34, GOLD))
	box.add_child(DungeonUI.divider(420.0))

	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 24)
	box.add_child(top)
	var stars := StarRow.new()
	stars.count = int(scored["stars"])
	stars.custom_minimum_size = Vector2(150, 40)
	top.add_child(stars)
	top.add_child(_line("%d" % int(scored["score"]), Fonts.TITLE, 54, INK))
	top.add_child(_line("of 1000", FONT, 16, DIM))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 3)
	var center := CenterContainer.new()
	center.add_child(grid)
	box.add_child(center)
	var seconds := int(round(float(result["time"])))
	var parts: Dictionary = scored["parts"]
	var rows := [
		["Time", "%d:%02d" % [seconds / 60, seconds % 60], int(parts["time"])],
		["Deaths", str(int(result["deaths"])), int(parts["deaths"])],
		["Rooms reset", str(int(result["resets"])), int(parts["resets"])],
		["Hints heard", str(int(result["hints"])), int(parts["hints"])],
		["Runes cast", str(int(result["casts"])), int(parts["casts"])],
	]
	for row in rows:
		grid.add_child(_line(row[0], FONT, 16, Color("b9ab90"), HORIZONTAL_ALIGNMENT_LEFT))
		grid.add_child(_line(row[1], FONT, 16, Color("f0d890"), HORIZONTAL_ALIGNMENT_RIGHT))
		grid.add_child(_line("-%d" % row[2] if row[2] > 0 else "", FONT, 16, Color("b23a48"), HORIZONTAL_ALIGNMENT_RIGHT))

	box.add_child(_line("THE WAYS THROUGH", Fonts.UI, 16, DIM))
	for line in data.get("ways", []):
		var way := _line(String(line), FONT, 16, INK)
		way.custom_minimum_size.x = 540
		way.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(way)

	var streak_text := ""
	if mode == "daily" and bool(info.get("ranked", false)):
		streak_text = "Streak: %d day%s  (best %d)" % [int(info["streak"]), "" if int(info["streak"]) == 1 else "s", DailyStore.best_streak]
		if bool(info.get("mended", false)):
			streak_text += "  ·  a missed day was mended"
	elif mode == "daily":
		streak_text = "Already ranked today: this run is practice."
	elif mode == "practice":
		streak_text = "Practice: the ranked result stands."
	if streak_text != "":
		box.add_child(_line(streak_text, FONT, 16, GOLD_DIM))

	var code_row := HBoxContainer.new()
	code_row.alignment = BoxContainer.ALIGNMENT_CENTER
	code_row.add_theme_constant_override("separation", 10)
	box.add_child(code_row)
	code_field = LineEdit.new()
	code_field.text = String(data["code"])
	code_field.editable = false
	code_field.custom_minimum_size = Vector2(400, 34)
	code_field.add_theme_font_override("font", Fonts.UI)
	code_field.add_theme_font_size_override("font_size", 16)
	code_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_row.add_child(code_field)
	copy_button = _button("Copy", _copy, 90)
	code_row.add_child(copy_button)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	again_button = _button("Try it again" if mode != "trial" else "Another trial", _again, 210)
	buttons.add_child(again_button)
	title_button = _button("Return to Title", func(): _to(TITLE_SCENE), 210)
	buttons.add_child(title_button)

	_root.modulate.a = 0.0
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_root, "modulate:a", 1.0, 0.8)
	tween.tween_callback(title_button.grab_focus)


func _line(text: String, font: Font, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, on_press: Callable, width := 200) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 38)
	b.add_theme_font_override("font", Fonts.UI)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(func(): Sfx.play("ui_click"); on_press.call())
	return b


static func _difficulty_name(difficulty: int) -> String:
	return ["Gentle", "Steady", "Hard", "Grand"][clampi(difficulty, 1, 4) - 1]


func _copy() -> void:
	var result: Dictionary = data["result"]
	DisplayServer.clipboard_set(DailyScore.share_text(result, String(data["code"])))
	copy_button.text = "Copied"


## Another go at the same puzzle (practice), or a fresh random trial.
func _again() -> void:
	var result: Dictionary = data["result"]
	if String(data.get("mode", "daily")) == "trial":
		var seed_value := DailyRng.mix(Time.get_ticks_usec())
		DailyRun.start("trial", seed_value, 0, int(result["difficulty"]), int(result["tier"]))
	else:
		DailyRun.start("practice", DailyGenerator.seed_for_day(int(result["day"])), int(result["day"]),
			int(result["difficulty"]), int(result["tier"]))
	_to(DailyRun.SCENE)


func _to(scene: String) -> void:
	if get_parent() is DailyRoot: get_parent()._transitioning = true
	get_tree().paused = false
	SceneFade.change(get_tree(), scene)


## Three stars in a row, the earned ones gold and the rest dark.
class StarRow extends Control:
	var count := 1

	func _draw() -> void:
		for i in 3:
			var c := Vector2(20.0 + i * 50.0, size.y / 2.0)
			var pts := PackedVector2Array()
			for k in 10:
				var a := -PI / 2.0 + k * PI / 5.0
				var r := 18.0 if k % 2 == 0 else 8.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			var earned := i < count
			draw_colored_polygon(pts, Color("f0d27a") if earned else Color("2a2630"))
			var outline := pts.duplicate()
			outline.append(pts[0])
			draw_polyline(outline, Color("c9a24a") if earned else Color("4a4250"), 1.5)
