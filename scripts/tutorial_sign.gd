@tool
class_name TutorialSign
extends Node2D

## A hanging plaque with tutorial text. Write {action_name} in the text to
## show whatever key that input action is currently bound to.
## The node marks the bottom-centre of the plaque.

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")
# Text is rasterised at 2x and scaled down so it stays sharp under the 2x camera
const TEXT_SCALE := 0.5

@export_multiline var text := "Press {jump} to jump.":
	set(value):
		text = value
		_rebuild()
@export var width := 150.0:
	set(value):
		width = value
		_rebuild()
@export var key_color := Color("f2c35b")
@export var text_color := Color("e4ddf2")
@export var font_size := 14
## Fully visible within this distance of the player, faded out beyond fade_distance.
@export var reveal_distance := 300.0
@export var fade_distance := 460.0
@export var chain_length := 18.0
## Lights just this plaque, so it stays readable in a dark level.
@export var self_light_energy := 0.9

## Light layer used only by signs, so their light never spills onto the level.
const SIGN_LIGHT_LAYER := 1 << 1

var _panel: PanelContainer
var _label: RichTextLabel
var _light: PointLight2D


func _ready() -> void:
	_rebuild()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var distance := player.global_position.distance_to(global_position)
	modulate.a = 1.0 - clampf((distance - reveal_distance) / (fade_distance - reveal_distance), 0.0, 1.0)


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _panel == null:
		_panel = PanelContainer.new()
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.035, 0.09, 0.86)
		style.border_color = Color(0.5, 0.38, 0.78, 0.85)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		style.shadow_color = Color(0, 0, 0, 0.45)
		style.shadow_size = 4
		_panel.add_theme_stylebox_override("panel", style)
		_panel.scale = Vector2.ONE * TEXT_SCALE
		add_child(_panel)

		_label = RichTextLabel.new()
		_label.bbcode_enabled = true
		_label.fit_content = true
		_label.scroll_active = false
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.add_theme_font_override("normal_font", FONT)
		_label.add_theme_font_override("bold_font", FONT)
		_panel.add_child(_label)

		light_mask = SIGN_LIGHT_LAYER
		_panel.light_mask = SIGN_LIGHT_LAYER
		_label.light_mask = SIGN_LIGHT_LAYER
		_light = PointLight2D.new()
		_light.texture = LightTextures.flat(64)
		_light.range_item_cull_mask = SIGN_LIGHT_LAYER
		_light.energy = self_light_energy
		add_child(_light)

	_label.add_theme_font_size_override("normal_font_size", font_size * 2)
	_label.add_theme_font_size_override("bold_font_size", font_size * 2)
	_label.add_theme_color_override("default_color", text_color)
	_label.custom_minimum_size = Vector2(width / TEXT_SCALE - 28.0, 0)
	_label.text = "[center]%s[/center]" % InputLabels.format(text, "[color=#%s]%%s[/color]" % key_color.to_html(false))

	_panel.reset_size()
	_place_panel.call_deferred()
	queue_redraw()


func _place_panel() -> void:
	if _panel == null:
		return
	_panel.reset_size()
	var size := _panel.size * TEXT_SCALE
	_panel.position = Vector2(-size.x / 2.0, -size.y)
	# Cover the plaque and its chains with the flat light
	_light.position = Vector2(0, -(size.y + chain_length) / 2.0)
	_light.texture_scale = (maxf(size.x, size.y + chain_length) + 24.0) / 64.0
	queue_redraw()


func _draw() -> void:
	if _panel == null:
		return
	# Two short chains hanging the plaque from above
	var size := _panel.size * TEXT_SCALE
	var top := -size.y
	for cx in [-size.x / 2.0 + 10.0, size.x / 2.0 - 10.0]:
		var y := top - chain_length
		while y < top:
			draw_rect(Rect2(cx - 1.0, y, 3, 3), Color("4c4862"), false, 1.0)
			y += 4.0
