class_name PageReader
extends CanvasLayer

## A found lore page, shown on a sheet of parchment while the game waits.
## Closed with interact, jump, pause or a click (after a short moment, so a
## held key doesn't skip it). Pages can be re-read in the pause menu's
## Ledger.

const TITLE_FONT_NAMES := ["Cinzel", "Trajan Pro", "Times New Roman", "Georgia", "Liberation Serif", "serif"]
const BODY_FONT := preload("res://assets/Text/Orbitron-Bold.ttf")
const CLOSE_ACTIONS := ["interact", "jump", "pause", "shoot"]

## The test suites turn this off so a page never stops a scripted run.
static var enabled := true

var _ready_to_close := 0.5
var _root: Control


static func open(host: Node, title: String, text: String, found: int, total: int) -> PageReader:
	var reader := PageReader.new()
	host.add_child(reader)
	reader._build(title, text, found, total)
	return reader


func _build(title: String, text: String, found: int, total: int) -> void:
	layer = 7
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.05, 0.7)
	_root.add_child(dim)
	var sheet := PanelContainer.new()
	sheet.set_anchors_preset(Control.PRESET_CENTER)
	sheet.grow_horizontal = Control.GROW_DIRECTION_BOTH
	sheet.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color("d9cfb8")
	style.border_color = Color("6b5b44")
	style.set_border_width_all(3)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 12
	for side in ["left", "right"]:
		style.set("content_margin_" + side, 34)
	style.content_margin_top = 26
	style.content_margin_bottom = 22
	sheet.add_theme_stylebox_override("panel", style)
	_root.add_child(sheet)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	sheet.add_child(box)
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(TITLE_FONT_NAMES)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", serif)
	heading.add_theme_font_size_override("font_size", 30)
	heading.add_theme_color_override("font_color", Color("3a2c1e"))
	box.add_child(heading)
	var body := Label.new()
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(460, 0)
	body.add_theme_font_override("font", serif)
	body.add_theme_font_size_override("font_size", 21)
	body.add_theme_color_override("font_color", Color("2b2118"))
	box.add_child(body)
	var foot := Label.new()
	foot.text = "Page %d of %d   ·   %s to continue" % [found, total, InputLabels.primary("interact")]
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_override("font", BODY_FONT)
	foot.add_theme_font_size_override("font_size", 13)
	foot.add_theme_color_override("font_color", Color("6b5b44"))
	box.add_child(foot)
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.25)


func _process(delta: float) -> void:
	_ready_to_close = maxf(_ready_to_close - delta, 0.0)


func _input(event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	if _ready_to_close > 0.0 or not event.is_pressed() or event.is_echo():
		return
	var close := event is InputEventMouseButton
	for action in CLOSE_ACTIONS:
		close = close or event.is_action_pressed(action)
	if close:
		_close()


func _close() -> void:
	set_process_input(false)
	get_tree().paused = false
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
