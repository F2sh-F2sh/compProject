class_name TitleCard
extends CanvasLayer

## A centred, fading card for the structure of the game: "ACT II / The
## Flame" in the chapter, "LESSON 3 / Sprint jumps" in the tutorial. It sits
## above the play space and lets input through; a newer card replaces an
## older one.

const BODY_FONT := Fonts.STORY

static var _current: TitleCard

var _box: VBoxContainer
var _tween: Tween


## Shows a card as a child of `host` (usually the level's root node);
## returns it (it frees itself once faded out).
static func show_card(host: Node, overline: String, title: String, subtitle := "", hold := 2.6, subtitle_gap := 0, vertical_offset := 0) -> TitleCard:
	if is_instance_valid(_current):
		_current.queue_free()
	var card := TitleCard.new()
	_current = card
	host.add_child(card)
	card._build(overline, title, subtitle, subtitle_gap, vertical_offset)
	card._play(hold)
	return card


## True while a card is on screen.
static func is_showing() -> bool:
	return is_instance_valid(_current)


func _build(overline: String, title: String, subtitle: String, subtitle_gap: int = 0, vertical_offset: int = 0) -> void:
	layer = 4
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	# Reserve the top 164 pixels for the HUD and a clear reading gap.
	# Lesson headings and spell cards both use this safe position.
	var band := ColorRect.new()
	band.set_anchors_preset(Control.PRESET_TOP_WIDE)
	band.offset_top = 164 + vertical_offset
	band.offset_bottom = 316 + subtitle_gap + vertical_offset
	band.color = Color(0.02, 0.01, 0.05, 0.55)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(band)
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_box.offset_top = 172 + vertical_offset
	_box.offset_bottom = 308 + vertical_offset
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 6)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_box)
	if overline != "":
		_box.add_child(_line(overline, Fonts.UI, 16, Color("c9a24a"), 6))
	var serif: Font = Fonts.TITLE
	_box.add_child(_line(title, serif, 48, Color("f0d27a"), 0))
	if subtitle != "":
		var margin := MarginContainer.new()
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_top", subtitle_gap)
		margin.add_child(_line(subtitle, BODY_FONT, 16, Color("d9c9a8"), 0))
		_box.add_child(margin)
	root.modulate.a = 0.0


func _line(text: String, font: Font, size: int, color: Color, spacing: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	if spacing > 0 and font is FontFile:
		var variation := FontVariation.new()
		variation.base_font = font
		variation.spacing_glyph = spacing
		l.add_theme_font_override("font", variation)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _play(hold: float) -> void:
	var root: Control = get_child(0)
	_tween = create_tween()
	_tween.tween_property(root, "modulate:a", 1.0, 0.6)
	_tween.tween_interval(hold)
	_tween.tween_property(root, "modulate:a", 0.0, 0.9)
	_tween.tween_callback(queue_free)
