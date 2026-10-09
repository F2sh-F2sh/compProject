class_name DungeonUI
extends RefCounted

## The dungeon UI kit (tools/generate_ui_sprites.gd, assets/ui/): carved dark
## stone, gold filigree and crimson gems. The Theme (assets/ui/
## dungeon_theme.tres, the project's default) styles every plain control;
## this class holds the palette and builds the pieces a theme can't: a
## heading, a gold rule with its gem, the crests on a panel's edges, a banner,
## a name plate.

const THEME := preload("res://assets/ui/dungeon_theme.tres")
const DIR := "res://assets/ui/"

## Parchment-coloured text on stone.
const INK := Color("e8dcc0")
const GOLD := Color("f0d27a")
const GOLD_DIM := Color("c9a24a")
const CRIMSON := Color("b23a48")
const CRIMSON_DARK := Color("6a1824")
const STONE := Color("1d1922")
const SHADOW := Color("07060a")
## Text that is there but not the point (hints, keys, disabled things).
const DIM := Color("8a8092")
## Ink on parchment.
const INK_DARK := Color("2a2016")
## Status colours, kept warm to sit with the gold.
const GOOD := Color("a8d8a0")
const BAD := Color("ff8a7a")
const WARN := Color("ffc070")

static var _styles := {}


## One of the kit's 9-slice textures as a style (margin in screen pixels).
static func style(sprite_name: String, margin: int, content := Vector4(-1, -1, -1, -1)) -> StyleBoxTexture:
	var key := "%s:%d:%s" % [sprite_name, margin, content]
	if _styles.has(key):
		return _styles[key]
	var sb := StyleBoxTexture.new()
	sb.texture = load(DIR + sprite_name + ".png")
	sb.set_texture_margin_all(margin)
	var c := content if content.x >= 0.0 else Vector4(margin + 6, margin, margin + 6, margin)
	sb.content_margin_left = c.x
	sb.content_margin_top = c.y
	sb.content_margin_right = c.z
	sb.content_margin_bottom = c.w
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	_styles[key] = sb
	return sb


## The main panel's style (stone, iron frame, gold corners).
static func panel_style() -> StyleBox:
	return THEME.get_stylebox("panel", "PanelContainer")


## The plainer box for things inside a panel.
static func lite_style() -> StyleBox:
	return THEME.get_stylebox("panel", "LitePanel")


static func label(text: String, font: Font, size: int, color := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", maxi(size, 18))
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A heading in the blackletter face (Title Case reads best).
static func heading(text: String, size := 36, color := GOLD) -> Label:
	var l := label(text, Fonts.TITLE, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Small gold capitals, for labels over a value or a list.
static func caps(text: String, size := 16, color := GOLD_DIM) -> Label:
	return label(text, Fonts.UI, size, color)


## Running text in the story face.
static func body(text: String, size := 16, color := INK) -> Label:
	var l := label(text, Fonts.STORY, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## A gold rule with a crimson gem at its middle.
static func divider(width := 0.0) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width > 0.0:
		row.custom_minimum_size.x = width
	for side in 3:
		if side == 1:
			var gem := TextureRect.new()
			gem.texture = load(DIR + "rule_gem.png")
			gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(gem)
			continue
		var line := TextureRect.new()
		line.texture = load(DIR + "rule.png")
		line.stretch_mode = TextureRect.STRETCH_TILE
		line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		line.custom_minimum_size = Vector2(16, 14)
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(line)
	return row


## Sets the gold crest at the middle of a panel's top and bottom edges (and
## its sides if `sides`), following the panel as it moves and resizes. (The
## crests are top-level, so a container panel doesn't lay them out.)
static func decorate(panel: Control, sides := false) -> void:
	var crests: Array = []
	for edge in (["top", "bottom", "left", "right"] if sides else ["top", "bottom"]):
		var crest := TextureRect.new()
		crest.name = "Crest" + edge.capitalize()
		crest.texture = load(DIR + ("crest_h.png" if edge in ["top", "bottom"] else "crest_v.png"))
		crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crest.top_level = true
		crest.set_meta(&"edge", edge)
		panel.add_child(crest)
		crests.append(crest)
	var place := func() -> void:
		if not panel.is_inside_tree():
			return
		var origin := panel.global_position
		var size := panel.size * panel.get_global_transform().get_scale()
		for crest in crests:
			var tex_size: Vector2 = crest.texture.get_size()
			match String(crest.get_meta(&"edge")):
				"top":
					crest.global_position = origin + Vector2((size.x - tex_size.x) / 2.0, -tex_size.y / 2.0 + 3.0)
				"bottom":
					crest.global_position = origin + Vector2((size.x - tex_size.x) / 2.0, size.y - tex_size.y / 2.0 - 3.0)
				"left":
					crest.global_position = origin + Vector2(-tex_size.x / 2.0 + 3.0, (size.y - tex_size.y) / 2.0)
				"right":
					crest.global_position = origin + Vector2(size.x - tex_size.x / 2.0 - 3.0, (size.y - tex_size.y) / 2.0)
	panel.item_rect_changed.connect(place)
	panel.ready.connect(place, CONNECT_DEFERRED)
	place.call_deferred()


## A crimson banner with gold edges and a line of capitals on it.
static func banner(text: String, size := 16) -> PanelContainer:
	var b := PanelContainer.new()
	b.theme_type_variation = &"BannerPanel"
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := caps(text, size, Color("f6e8c4"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(l)
	return b


## The gold plate a speaker's name sits on.
static func nameplate(text: String) -> PanelContainer:
	var b := PanelContainer.new()
	b.theme_type_variation = &"NamePlate"
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := caps(text, 16, INK_DARK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.add_child(l)
	return b
