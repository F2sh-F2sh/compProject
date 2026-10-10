extends Control

@export var player_name := "Echidna"
@export var name_font: Font
@export var body_font: Font

const SLOPE := 0.7
const PLATE_W := 468.0
const PLATE_H := 40.0
const TAB_X := 206.0
const TAB_H := 26.0
const MANA_PLATE_W := 196.0
const MANA_PLATE_H := 24.0

const COLOR_PLATE := Color(0.086, 0.075, 0.1, 0.94)
const COLOR_BORDER := Color("c9a24a")
const COLOR_TRACK := Color("07060a")
const COLOR_TAB := Color("b08a3e")
const COLOR_TAB_TEXT := Color("1a120a")
const COLOR_GHOST := Color(1, 1, 1, 0.75)
const COLOR_HIT := Color(1.0, 0.3, 0.3)
const HP_HIGH := Color(0.8, 0.2, 0.27)
const HP_MID := Color(0.88, 0.45, 0.2)
const HP_LOW := Color(1.0, 0.28, 0.22)
const MP_HIGH := Color(0.3, 0.9, 1.0)
const MP_MID := Color(0.25, 0.6, 1.0)
const MP_LOW := Color(0.6, 0.35, 1.0)
const MP_CRITICAL := Color(1.0, 0.25, 0.75)
const MP_RESTORING := Color(0.55, 0.5, 0.7)

var hp := 10
var hp_max := 10
var hp_shown := 1.0
var hp_ghost := 1.0
var hp_ghost_delay := 0.0

var mp := 100
var mp_max := 100
var mp_shown := 1.0
var mp_ghost := 1.0
var mp_ghost_delay := 0.0
var mp_restoring := false
## Max mana currently locked away by Echoes (temporal debt).
var mp_debt := 0

var echo_recording := false
var echo_remaining := 1.0
var echo_count := 0
var echo_max := 2
## Seconds of recording left (negative when unknown).
var echo_seconds := -1.0

const COLOR_DEBT := Color(0.3, 0.08, 0.12)
const COLOR_DEBT_HATCH := Color(0.7, 0.25, 0.3, 0.8)
const COLOR_REC := Color(1.0, 0.28, 0.32)
const COLOR_ECHO := Color(0.72, 0.5, 1.0)

var hit_flash := 0.0
var heal_flash := 0.0
var shake := 0.0
var time := 0.0


func _ready() -> void:
	name_font = Fonts.UI_BOLD
	body_font = Fonts.UI
	custom_minimum_size = Vector2(PLATE_W, PLATE_H + TAB_H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_health(current: int, maximum: int) -> void:
	var ratio := float(current) / maxi(maximum, 1)
	if current < hp:
		hp_shown = ratio
		hp_ghost_delay = 0.4
		hit_flash = 1.0
		shake = 1.0
	elif current > hp:
		heal_flash = 1.0
	hp = current
	hp_max = maximum


func set_mana(current: int, maximum: int, restoring: bool, progress: float) -> void:
	mp_restoring = restoring
	mp_max = maximum
	if restoring:
		mp_shown = progress
		mp_ghost = progress
	elif current < mp:
		mp_shown = float(current) / maxi(maximum, 1)
		mp_ghost_delay = 0.35
	mp = current


func set_mana_debt(debt: int) -> void:
	mp_debt = debt


func set_echo_state(recording: bool, remaining: float, count: int, max_count: int, seconds_left := -1.0) -> void:
	echo_recording = recording
	echo_remaining = remaining
	echo_count = count
	echo_max = max_count
	echo_seconds = seconds_left


func _process(delta: float) -> void:
	time += delta
	hit_flash = maxf(hit_flash - delta * 3.0, 0.0)
	heal_flash = maxf(heal_flash - delta * 2.0, 0.0)
	shake = maxf(shake - delta * 4.0, 0.0)

	var hp_target := float(hp) / maxi(hp_max, 1)
	hp_shown = move_toward(hp_shown, hp_target, delta * 1.5)
	hp_ghost_delay -= delta
	if hp_ghost < hp_shown or hp_ghost_delay <= 0.0:
		hp_ghost = move_toward(hp_ghost, hp_shown, delta * (99.0 if hp_ghost < hp_shown else 0.8))

	if not mp_restoring:
		var mp_target := float(mp) / maxi(mp_max, 1)
		mp_shown = move_toward(mp_shown, mp_target, delta * 2.0)
		mp_ghost_delay -= delta
		if mp_ghost < mp_shown or mp_ghost_delay <= 0.0:
			mp_ghost = move_toward(mp_ghost, mp_shown, delta * (99.0 if mp_ghost < mp_shown else 1.2))

	queue_redraw()


func _draw() -> void:
	var jitter := Vector2(sin(time * 90.0), cos(time * 70.0)) * 3.0 * shake * (0.0 if Settings.reduce_motion else 1.0)
	draw_set_transform(jitter.round())

	var border := COLOR_BORDER.lerp(COLOR_HIT, hit_flash)

	# Mana plate and tab hang below the main plate, so draw them first
	_draw_mana_plate(border)
	_draw_tab()

	var plate := PackedVector2Array([
		Vector2(0, 0), Vector2(PLATE_W, 0),
		Vector2(_plate_edge(PLATE_H), PLATE_H), Vector2(0, PLATE_H)])
	draw_colored_polygon(plate, COLOR_PLATE)
	_outline(plate, border, 2.0)

	draw_rect(Rect2(4, 9, 4, 22), border)
	draw_line(Vector2(13, 5), Vector2(13, 35), border, 2.0)

	var name_size := 24
	var name_w := name_font.get_string_size(player_name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x
	draw_string(name_font, Vector2(22, 28), player_name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, DungeonUI.GOLD)

	_draw_health_bar(22.0 + name_w + 12.0)


func _draw_health_bar(x0: float) -> void:
	var thick_top := 7.0
	var thin_top := 19.0
	var bottom := 33.0
	var x_end_top := _plate_edge(thin_top) - 12.0
	var x_step := x0 + (x_end_top - x0) * 0.58
	var shape := PackedVector2Array([
		Vector2(x0, thick_top), Vector2(x_step, thick_top), Vector2(x_step + 12.0, thin_top),
		Vector2(x_end_top, thin_top), Vector2(_plate_edge(bottom) - 12.0, bottom), Vector2(x0, bottom)])

	draw_colored_polygon(shape, COLOR_TRACK)

	var ratio := float(hp) / maxi(hp_max, 1)
	var color := HP_HIGH if ratio > 0.5 else (HP_MID if ratio > 0.25 else HP_LOW)
	if ratio <= 0.25 and hp > 0:
		color = color.lightened(0.25 * (0.5 + 0.5 * sin(time * 8.0)))
	color = color.lerp(Color(0.85, 1.0, 0.85), heal_flash * 0.7)

	_fill_clipped(shape, x0, x_end_top, hp_ghost, COLOR_GHOST)
	var fills := _fill_clipped(shape, x0, x_end_top, hp_shown, color)

	# Top highlight strip on both the thick and thin sections
	for fill in fills:
		for band in [Rect2(x0, thick_top, x_step - x0 + 12.0, 4.0), Rect2(x_step, thin_top, x_end_top, 3.0)]:
			for part in Geometry2D.intersect_polygons(fill, _rect_poly(band)):
				draw_colored_polygon(part, Color(color.lightened(0.35), 0.9))

	_outline(shape, Color(0, 0, 0, 0.6), 1.0)


func _draw_mana_plate(border: Color) -> void:
	var top := PLATE_H - 2.0
	var bottom := PLATE_H + MANA_PLATE_H
	var plate := PackedVector2Array([
		Vector2(0, top), Vector2(MANA_PLATE_W, top),
		Vector2(MANA_PLATE_W - SLOPE * (bottom - top), bottom), Vector2(0, bottom)])
	draw_colored_polygon(plate, COLOR_PLATE)
	_outline(plate, border, 2.0)

	var bar_top := top + 5.0
	var bar_bottom := bottom - 5.0
	# (room for the word MANA at its left)
	var x0 := 12.0 + body_font.get_string_size("Mana", HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var x_end := MANA_PLATE_W - 10.0
	var bar := PackedVector2Array([
		Vector2(x0, bar_top), Vector2(x_end, bar_top),
		Vector2(x_end - SLOPE * (bar_bottom - bar_top), bar_bottom), Vector2(x0, bar_bottom)])
	draw_colored_polygon(bar, COLOR_TRACK)

	var color := MP_RESTORING
	if mp_restoring:
		color = MP_RESTORING.lightened(0.2 * (0.5 + 0.5 * sin(time * 9.0)))
	else:
		var ratio := float(mp) / maxi(mp_max, 1)
		color = MP_HIGH if ratio > 0.75 else (MP_MID if ratio > 0.5 else (MP_LOW if ratio > 0.25 else MP_CRITICAL))

	_fill_clipped(bar, x0, x_end, mp_ghost, COLOR_GHOST)
	_fill_clipped(bar, x0, x_end, mp_shown, color)
	_draw_debt(bar, x0, x_end, bar_top, bar_bottom)
	draw_string(body_font, Vector2(5, bar_bottom + 1.0), "Mana", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, border)
	_draw_echo_indicator(bottom + 4.0, border)


# Capacity held by Echoes is shown as a locked, hatched stretch at the end of the bar
func _draw_debt(bar: PackedVector2Array, x0: float, x_end: float, bar_top: float, bar_bottom: float) -> void:
	if mp_debt <= 0:
		return
	var cap_ratio := 1.0 - float(mp_debt) / maxi(mp_max, 1)
	var start_x := x0 + (x_end - x0) * cap_ratio
	var clip := _rect_poly(Rect2(start_x, bar_top - 2.0, x_end - start_x + 10.0, bar_bottom - bar_top + 4.0))
	for part in Geometry2D.intersect_polygons(bar, clip):
		draw_colored_polygon(part, COLOR_DEBT)
	var hx := start_x + 2.0
	while hx < x_end:
		var line := PackedVector2Array([Vector2(hx, bar_bottom), Vector2(hx + 4.0, bar_top)])
		var clipped := Geometry2D.clip_polyline_with_polygon(line, bar)
		for seg in clipped:
			draw_polyline(seg, COLOR_DEBT_HATCH, 1.0)
		hx += 5.0
	draw_line(Vector2(start_x, bar_top), Vector2(start_x - SLOPE * (bar_bottom - bar_top), bar_bottom),
		Color(0.85, 0.7, 1.0), 1.0)


func _draw_echo_indicator(top: float, border: Color) -> void:
	if not echo_recording and echo_count <= 0:
		return
	var w := 164.0
	var h := 24.0
	var plate := PackedVector2Array([Vector2(0, top), Vector2(w, top), Vector2(w - SLOPE * h, top + h), Vector2(0, top + h)])
	draw_colored_polygon(plate, COLOR_PLATE)
	_outline(plate, border, 1.5)
	var baseline := top + h - 4.0
	if echo_recording:
		var pulse := 0.5 + 0.5 * sin(time * 8.0)
		draw_circle(Vector2(10, top + h / 2.0), 3.5, COLOR_REC.lerp(Color.WHITE, 0.3 * pulse))
		draw_string(body_font, Vector2(18, baseline), "REC", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COLOR_REC)
		var bar := Rect2(46, top + 6.0, 48, 4)
		draw_rect(bar, COLOR_TRACK)
		# The last seconds flash white so running out is never a surprise
		var urgent := echo_seconds >= 0.0 and echo_seconds < 3.0 and sin(time * 12.0) > 0.0
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * echo_remaining, bar.size.y)),
			COLOR_REC.lerp(Color.WHITE, 0.6) if urgent else COLOR_REC)
		if echo_seconds >= 0.0:
			draw_string(body_font, Vector2(98, baseline), "%.1fs" % echo_seconds, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
				Color.WHITE if urgent else COLOR_REC)
	else:
		draw_string(body_font, Vector2(8, baseline), "ECHO", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, COLOR_ECHO)
		for i in echo_max:
			var center := Vector2(56 + i * 14, top + h / 2.0)
			var diamond := PackedVector2Array([center + Vector2(0, -4), center + Vector2(4, 0),
				center + Vector2(0, 4), center + Vector2(-4, 0)])
			if i < echo_count:
				draw_colored_polygon(diamond, COLOR_ECHO)
			else:
				_outline(diamond, COLOR_ECHO.darkened(0.3), 1.0)


func _draw_tab() -> void:
	var top := PLATE_H - 2.0
	var bottom := PLATE_H + TAB_H
	var right_top := _plate_edge(top)
	var tab := PackedVector2Array([
		Vector2(TAB_X, top), Vector2(right_top, top),
		Vector2(_plate_edge(bottom), bottom), Vector2(TAB_X + 4.0, bottom)])
	draw_colored_polygon(tab, COLOR_TAB)

	# Mana's number on the left, beside the mana bar; health's on the right,
	# under the end of the health bar
	var divider := TAB_X + 112.0
	draw_line(Vector2(divider, top + 4.0), Vector2(divider, bottom - 3.0), COLOR_TAB_TEXT, 1.0)

	var baseline := bottom - 5.0
	var mp_text := "Reloading" if mp_restoring else "Mana %d" % mp
	draw_string(body_font, Vector2(TAB_X, baseline), mp_text, HORIZONTAL_ALIGNMENT_CENTER, divider - TAB_X, 20, COLOR_TAB_TEXT)
	var hp_text := "%d / %d" % [hp, hp_max]
	draw_string(body_font, Vector2(divider + 2.0, baseline), hp_text, HORIZONTAL_ALIGNMENT_CENTER, _plate_edge(bottom) - divider - 4.0, 20, COLOR_TAB_TEXT)


func _fill_clipped(shape: PackedVector2Array, x0: float, x_max: float, ratio: float, color: Color) -> Array:
	if ratio <= 0.0:
		return []
	var clip := _rect_poly(Rect2(x0 - 1.0, -10.0, (x_max - x0) * ratio + 1.0, 100.0))
	var parts := Geometry2D.intersect_polygons(shape, clip)
	for part in parts:
		draw_colored_polygon(part, color)
	return parts


func _plate_edge(y: float) -> float:
	return PLATE_W - SLOPE * y


func _rect_poly(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


func _outline(poly: PackedVector2Array, color: Color, width: float) -> void:
	var closed := poly.duplicate()
	closed.append(poly[0])
	draw_polyline(closed, color, width)
