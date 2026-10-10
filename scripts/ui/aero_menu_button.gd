extends Button

## Menu-only pixel glass tabs: stepped shading, hard edges and pixel text.
var glass: Control
var menu_font := Fonts.UI
var label_size := 24

func _ready() -> void:
	add_theme_font_override("font", menu_font)
	add_theme_font_size_override("font_size", label_size)
	add_theme_color_override("font_color", Color("e5edf2"))
	add_theme_color_override("font_hover_color", Color("f0ffff"))
	add_theme_color_override("font_focus_color", Color("f0ffff"))
	add_theme_color_override("font_pressed_color", Color("f0ffff"))
	add_theme_color_override("font_disabled_color", Color("737f93"))
	add_theme_color_override("font_outline_color", Color("0a111f"))
	add_theme_constant_override("outline_size", 3)
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var empty := StyleBoxEmpty.new()
		empty.content_margin_left = 36
		empty.content_margin_right = 22
		add_theme_stylebox_override(state, empty)
	glass = Control.new()
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.show_behind_parent = true
	glass.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glass.draw.connect(_draw_glass)
	add_child(glass)
	for signal_name in ["mouse_entered", "mouse_exited", "focus_entered", "focus_exited", "button_down", "button_up", "resized"]:
		connect(signal_name, func(): glass.queue_redraw())

func _draw_glass() -> void:
	var w := floorf(size.x / 4) * 4
	var h := floorf(size.y / 4) * 4
	var lit := not disabled and (has_focus() or is_hovered())
	var top := Color("48536f") if not lit else Color("6c9fa9")
	var bottom := Color("17243e") if not lit else Color("1a5968")
	if disabled:
		top = Color("2b3247")
		bottom = Color("111a2b")
	for y in range(0, int(h), 4):
		var t := float(y) / maxf(1, h - 4)
		var left := 12 - floorf(t * 3) * 4
		var right := w - 4 - floorf(t * 2) * 4
		glass.draw_rect(Rect2(left + 4, y + 4, right - left, 4), Color("090d1d"))
		glass.draw_rect(Rect2(left, y, right - left, 4), Color("0a1428"))
		if y < 4 or y >= h - 4:
			glass.draw_rect(Rect2(left + 4, y, right - left - 8, 4), Color("85b7bc") if lit else Color("536681"))
		else:
			var shade := floorf(t * 5) / 5
			var c := top.lerp(bottom, shade)
			if y == 4: c = c.lightened(0.16)
			if y == int(h) - 8 and lit: c = Color("438f97")
			glass.draw_rect(Rect2(left + 4, y, right - left - 8, 4), c)
	if lit:
		var mid := floorf(h / 8) * 4
		glass.draw_rect(Rect2(20, mid - 4, 4, 12), Color("e5d09b"))
		glass.draw_rect(Rect2(24, mid, 4, 4), Color("e5d09b"))
