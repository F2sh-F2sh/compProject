@tool
class_name TutorialSign
extends Node2D

## A small world marker; only the nearest sign puts its text at the screen edge.
## The plaque never sits over a platform or puzzle object.
const FONT := Fonts.STORY
const TEXT_SCALE := 1.0
@export_multiline var text := "Press {jump} to jump.":
	set(value):
		text = value
		_rebuild()
@export var width := 150.0
@export var handwritten := false
@export var key_color := Color("f2c35b")
@export var text_color := Color("f3ebd7")
@export var font_size := 22
@export var reveal_distance := 190.0
@export var fade_distance := 260.0
@export var chain_length := 18.0
@export var self_light_energy := 0.9
const SIGN_LIGHT_LAYER := 1 << 1
var _panel: PanelContainer
var _label: RichTextLabel
var _ui: CanvasLayer

func _ready() -> void:
	add_to_group("readable_sign")
	z_index = -1
	_rebuild()
	queue_redraw()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		_panel.visible = false
		return
	var nearest: Node2D
	var best := reveal_distance
	for sign_node in get_tree().get_nodes_in_group("readable_sign"):
		var distance := player.global_position.distance_to(sign_node.global_position)
		if distance < best:
			best = distance
			nearest = sign_node
	_panel.visible = nearest == self and not get_tree().paused and not player.controls_locked
	var chapter := get_tree().get_first_node_in_group("chapter_root") as ChapterRoot
	if TitleCard.is_showing() or (chapter and (chapter._top_busy() or chapter._toast_panel.modulate.a > 0.05)):
		_panel.visible = false
	_place_panel()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _panel == null:
		_ui = CanvasLayer.new()
		_ui.layer = 2
		add_child(_ui)
		_panel = PanelContainer.new()
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT
		style.border_color = DungeonUI.GOLD_DIM
		style.border_width_top = 0
		style.content_margin_left = 18
		style.content_margin_right = 18
		style.content_margin_top = 8
		style.content_margin_bottom = 10
		_panel.add_theme_stylebox_override("panel", style)
		_ui.add_child(_panel)
		_label = RichTextLabel.new()
		_label.bbcode_enabled = true
		_label.fit_content = true
		_label.scroll_active = false
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_panel.add_child(_label)
	var font: Font = Fonts.HAND if handwritten else FONT
	_label.add_theme_font_override("normal_font", font)
	_label.add_theme_font_override("bold_font", font)
	_label.add_theme_font_size_override("normal_font_size", maxi(22, font_size))
	_label.add_theme_font_size_override("bold_font_size", maxi(22, font_size))
	_label.add_theme_color_override("default_color", text_color)
	_label.add_theme_color_override("font_outline_color", Color("090812"))
	_label.add_theme_constant_override("outline_size", 6)
	_label.text = "[center]%s[/center]" % InputLabels.format(text, "[color=#%s]%%s[/color]" % key_color.to_html(false))
	_panel.visible = Engine.is_editor_hint()
	_place_panel.call_deferred()

func _place_panel() -> void:
	if _panel == null or not is_inside_tree():
		return
	var view := get_viewport().get_visible_rect().size
	var w := clampf(view.x - 384.0, 280.0, 620.0)
	_label.custom_minimum_size.x = w - 36.0
	_panel.size.x = w
	_panel.reset_size()
	_panel.position = Vector2((view.x - _panel.size.x) / 2.0, 96.0)

func _draw() -> void:
	draw_rect(Rect2(-6, -12, 12, 12), Color("473950"))
	draw_line(Vector2(-3, -8), Vector2(3, -8), DungeonUI.GOLD_DIM, 1.0)
	draw_line(Vector2(-3, -5), Vector2(3, -5), DungeonUI.GOLD_DIM, 1.0)
