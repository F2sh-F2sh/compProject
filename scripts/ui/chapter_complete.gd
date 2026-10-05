class_name ChapterComplete
extends CanvasLayer

## The end-of-chapter card: how long the run took, deaths, room resets,
## hints heard and ledger pages found, then back to the title (or keep
## exploring the chapter, e.g. to find the pages still missing).

const TITLE_FONT_NAMES := ["Cinzel", "Trajan Pro", "Times New Roman", "Georgia", "Liberation Serif", "serif"]
const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"

## A finished chapter's card waiting for its story pictures to end:
## {name, stats}. Story pictures that find it here show the card when they
## end (see StoryIntro._finish), so it survives the change of scene. A
## chapter that starts clears it (ChapterRoot._ready).
static var pending := {}

var _root: Control
var title_button: Button
var continue_button: Button


## `stats`: {time, deaths, resets, hints, pages, total_pages}
static func open(host: Node, chapter_name: String, stats: Dictionary) -> ChapterComplete:
	var card := ChapterComplete.new()
	host.add_child(card)
	card._build(chapter_name, stats)
	return card


func _build(chapter_name: String, stats: Dictionary) -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Crosshair.arrow()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.05, 0.82)
	_root.add_child(dim)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	_root.add_child(box)
	box.add_child(_line(String(stats.get("heading", "CHAPTER COMPLETE")), FONT, 16, Color("a99ccf")))
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(TITLE_FONT_NAMES)
	box.add_child(_line(chapter_name, serif, 48, Color("e2d6fa")))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(_line("YOUR RUN", FONT, 12, Color("8f84ad")))
	var center := CenterContainer.new()
	center.add_child(grid)
	box.add_child(center)
	var seconds := int(stats.get("time", 0.0))
	var rows := [
		["Time", "%d:%02d" % [seconds / 60, seconds % 60]],
		["Deaths", str(int(stats.get("deaths", 0)))],
	]
	if stats.has("resets"):
		rows.append(["Rooms reset", str(int(stats.get("resets", 0)))])
	if stats.has("hints"):
		rows.append(["Hints heard", str(int(stats.get("hints", 0)))])
	if int(stats.get("total_pages", 0)) > 0:
		rows.append(["Ledger pages", "%d / %d" % [int(stats.get("pages", 0)), int(stats.get("total_pages", 0))]])
	for row in rows:
		grid.add_child(_line(row[0], FONT, 16, Color("b8acd8"), HORIZONTAL_ALIGNMENT_LEFT))
		grid.add_child(_line(row[1], FONT, 16, Color("f0d890"), HORIZONTAL_ALIGNMENT_RIGHT))
	var next: String = stats.get("next", "")
	if next == "":
		box.add_child(_line(String(stats.get("closing", "The next chapter is still being written.")), FONT, 13, Color("8f84ad")))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	if next != "":
		continue_button = _button(String(stats.get("next_label", "Continue to the next chapter")), func(): _to(next))
		buttons.add_child(continue_button)
	title_button = _button("Return to Title", _to_title)
	buttons.add_child(title_button)
	# (only on, or back to the title: there is no staying in a finished level)
	_root.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, 1.2)
	tween.tween_callback((continue_button if continue_button else title_button).grab_focus)


func _line(text: String, font: Font, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 40)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 17)
	b.pressed.connect(func(): Sfx.play("ui_click"); on_press.call())
	return b


func _to_title() -> void:
	_to(TITLE_SCENE)


func _to(scene: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene)


func _close() -> void:
	get_tree().paused = false
	Crosshair.restore()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.unlock_controls()
	for node in get_tree().get_nodes_in_group("gameplay_ui"):
		node.visible = true
	queue_free()
