class_name SpeechBubble
extends Node2D

## A small speech bubble over a villager, or a thought over Echidna. Words the
## Hush has taken are written {n} in the text: they show as n faint rune
## glyphs in a little box, where the word should have been. Drawn at twice
## the size and scaled down, so the words stay sharp under the 2x camera.

const FONT := Fonts.STORY
const FONT_SIZE := 20
const MAX_WIDTH := 340.0
const PAD := Vector2(16, 12)
const GLYPH := 18.0
const LINE_HEIGHT := 26.0

var text := "":
	set(value):
		text = value
		_layout()
		queue_redraw()
## A thought: a softer bubble with little round puffs instead of a tail.
var thought := false:
	set(value):
		thought = value
		queue_redraw()

var _lines: Array = []
var _box := Vector2.ZERO
var _tween: Tween


func _ready() -> void:
	scale = Vector2(0.5, 0.5)
	material = MagicLight.unshaded()
	z_index = 40
	z_as_relative = false
	modulate.a = 0.0
	_layout()


func show_bubble(seconds := 0.25) -> void:
	_fade_to(1.0, seconds)


func hide_bubble(seconds := 0.35) -> void:
	_fade_to(0.0, seconds)


func is_showing() -> bool:
	return modulate.a > 0.5


## The number of glyphs drawn for missing words.
func gap_count() -> int:
	var n := 0
	for words in _lines:
		for item in words:
			if item["gap"] > 0:
				n += item["gap"]
	return n


func _fade_to(alpha: float, seconds: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, seconds)


func _layout() -> void:
	_lines.clear()
	var space := FONT.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var gap_pattern := RegEx.create_from_string("^\\{(\\d+)\\}(.*)$")
	var current: Array = []
	var width := 0.0
	var widest := 0.0
	for token in text.split(" ", false):
		var item := {"word": token, "gap": 0, "tail": ""}
		var m := gap_pattern.search(token)
		if m:
			item["gap"] = int(m.get_string(1))
			item["tail"] = m.get_string(2)
			item["w"] = item["gap"] * GLYPH + 10.0 + FONT.get_string_size(item["tail"], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		else:
			item["w"] = FONT.get_string_size(token, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var needed: float = item["w"] + (space if not current.is_empty() else 0.0)
		if not current.is_empty() and width + needed > MAX_WIDTH:
			_lines.append(current)
			widest = maxf(widest, width)
			current = []
			width = 0.0
			needed = item["w"]
		current.append(item)
		width += needed
	if not current.is_empty():
		_lines.append(current)
		widest = maxf(widest, width)
	_box = Vector2(widest + PAD.x * 2.0, _lines.size() * LINE_HEIGHT + PAD.y * 2.0)


func _draw() -> void:
	if _lines.is_empty():
		return
	var rect := Rect2(-_box.x / 2.0, -_box.y - 16.0, _box.x, _box.y)
	var style: StyleBox = DungeonUI.THEME.get_stylebox("panel", "ParchmentPanel") if thought else DungeonUI.style("panel_lite", 8)
	var fill := Color("d8c59c") if thought else Color("16131a")
	draw_style_box(style, rect)
	if thought:
		draw_circle(Vector2(-6, -9), 5.0, fill)
		draw_circle(Vector2(-12, 2), 3.0, fill)
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(-8, -18), Vector2(8, -18), Vector2(0, -4)]), fill)
		draw_polyline(PackedVector2Array([Vector2(-8, -17), Vector2(0, -4), Vector2(8, -17)]), Color("7a5f2a"), 2.0)
	var ink := Color("2a2016") if thought else Color("e8dcc0")
	var faded := Color(0.62, 0.42, 0.32, 0.85) if thought else Color(0.86, 0.7, 0.42, 0.85)
	var space := FONT.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	for row in _lines.size():
		var words: Array = _lines[row]
		var line_width := 0.0
		for k in words.size():
			line_width += words[k]["w"] + (space if k > 0 else 0.0)
		var x := -line_width / 2.0
		var baseline := rect.position.y + PAD.y + row * LINE_HEIGHT + FONT_SIZE * 0.95
		for item in words:
			if item["gap"] > 0:
				var n: int = item["gap"]
				var box := Rect2(x, baseline - FONT_SIZE * 0.85, n * GLYPH + 8.0, FONT_SIZE * 1.05)
				draw_rect(box, Color(0.42, 0.1, 0.14, 0.3))
				for g in n:
					var ids := RuneFragments.ALL.keys()
					var id: StringName = ids[absi(hash(text) + g * 7 + row * 13) % ids.size()]
					RuneFragments.draw_glyph(self, id, Vector2(x + 4.0 + GLYPH * (g + 0.5), box.get_center().y), GLYPH * 0.72, faded, 1.5)
				draw_string(FONT, Vector2(x + n * GLYPH + 10.0, baseline), item["tail"], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, ink)
			else:
				draw_string(FONT, Vector2(x, baseline), item["word"], HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, ink)
			x += item["w"] + space
