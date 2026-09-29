class_name RuneHud
extends CanvasLayer

## A small strip under the mana bar while any rune is running: one pip per
## running cube (in its essence's colour, with its essence symbol), the
## mana it all costs per second, and a warning when mana is running low.
## Hidden when no rune is on.

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")

var _panel: Control
var _label: Label
var _pips: Control
var _time := 0.0
var _shown := 0.0


func _ready() -> void:
	layer = 4
	_panel = Control.new()
	_panel.position = Vector2(18, 82)
	_panel.size = Vector2(380, 30)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_to_group("gameplay_ui")
	add_child(_panel)
	_pips = Control.new()
	_pips.size = Vector2(160, 26)
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pips.draw.connect(_draw_pips)
	_panel.add_child(_pips)
	_label = Label.new()
	_label.position = Vector2(0, 2)
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color("e4ddf2"))
	_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.05, 0.9))
	_label.add_theme_constant_override("outline_size", 5)
	_panel.add_child(_label)
	_panel.modulate.a = 0.0


func _manager() -> RuneManager:
	return get_parent() as RuneManager


func _process(delta: float) -> void:
	_time += delta
	var m := _manager()
	if m == null or m.player == null:
		return
	var active := m.active_cubes()
	var room: Room = m.chapter.current_room if m.chapter else null
	var limit: int = room.mana_limit if room else 0
	_shown = move_toward(_shown, 1.0 if not active.is_empty() or limit > 0 else 0.0, delta * 4.0)
	_panel.modulate.a = _shown
	if active.is_empty() and limit <= 0:
		return
	var pip_width := active.size() * 22.0
	_label.position.x = pip_width + 8.0
	var parts := PackedStringArray()
	if m.total_upkeep > 0.0:
		parts.append("-%s mana/s" % RuneBook._num(m.total_upkeep))
	else:
		if active.is_empty():
			parts.append("no runes on")
		elif active.all(func(c): return c.fed_by_dungeon()):
			parts.append("powered by the dungeon")
		else:
			parts.append("no upkeep")
	if limit > 0:
		parts.append("warded: mana held to %d" % limit)
	var low := m.total_upkeep > 0.0 and m.mana() <= RuneManager.LOW_MANA
	if low:
		parts.append("LOW MANA")
	parts.append("[%s] runes" % InputLabels.primary("rune_overview"))
	_label.text = "   ".join(parts)
	var warn := Color(1.0, 0.55, 0.45) if int(_time * 3.0) % 2 == 0 else Color(1.0, 0.8, 0.7)
	_label.add_theme_color_override("font_color", warn if low else Color("e4ddf2"))
	_pips.queue_redraw()


func _draw_pips() -> void:
	var m := _manager()
	if m == null:
		return
	var x := 11.0
	for cube in m.active_cubes():
		var col := RuneFragments.essence_color(cube.recipe.essence)
		_pips.draw_circle(Vector2(x, 12), 10.0, Color(0.05, 0.035, 0.09, 0.9))
		_pips.draw_arc(Vector2(x, 12), 10.0, 0.0, TAU, 20, Color(col, 0.9), 1.5)
		RuneFragments.draw_glyph(_pips, cube.recipe.essence, Vector2(x, 12), 13.0, col, 1.2)
		if cube.fed_by_dungeon():
			_pips.draw_rect(Rect2(x - 2, 20, 4, 3), Color(0.6, 0.5, 1.0))
		x += 22.0
