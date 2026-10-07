class_name ObjectivePanel
extends PanelContainer

## Top-right HUD card with the current room's goal and one pip per step:
## filled once done, hollow while still to do (a diamond for optional steps).
## When a step completes its name flashes under the pips, so players see
## their progress without being told the solution.

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")
const DONE_COLOR := Color(0.78, 0.66, 1.0)
const TODO_COLOR := Color(0.5, 0.44, 0.66)
const CLEAR_COLOR := Color(0.6, 0.95, 0.75)

var _goal: Label
var _pips: Control
var _status: Label
var _todo: Label
var _steps: Array = []
var _status_tween: Tween
var _pulse := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -292
	offset_right = -16
	offset_top = 16
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.035, 0.09, 0.78)
	style.border_color = Color(0.5, 0.38, 0.78, 0.8)
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_goal = _label(14, Color("e4ddf2"))
	_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_goal)
	_pips = Control.new()
	_pips.custom_minimum_size = Vector2(0, 12)
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pips.draw.connect(_draw_pips)
	box.add_child(_pips)
	_todo = _label(12, Color("f1d58c"))
	_todo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_todo.visible = false
	box.add_child(_todo)
	_status = _label(12, DONE_COLOR)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.modulate.a = 0.0
	box.add_child(_status)
	modulate.a = 0.0


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Shows a room's goal and steps (ObjectiveStep nodes); hides if it has none.
func show_room(goal: String, steps: Array) -> void:
	_steps = steps
	_goal.text = goal
	_status.modulate.a = 0.0
	_status.text = ""
	_status.visible = false
	visible = goal != ""
	var tween := create_tween()
	modulate.a = 0.0
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	if is_cleared():
		_show_status("Clear", CLEAR_COLOR, 0.0)
	_update_extras()
	_fit.call_deferred()


# A container only ever grows; shrink it back to its content after a change
func _fit() -> void:
	offset_bottom = offset_top


func step_done(step: Node) -> void:
	_pulse = 1.0
	_update_extras()
	if is_cleared():
		_show_status("✓ %s\nThe way on is open." % step.label, CLEAR_COLOR, 5.0)
	else:
		_show_status("✓ %s" % step.label, DONE_COLOR, 4.0)


func is_cleared() -> bool:
	var required := _steps.filter(func(s): return is_instance_valid(s) and not s.optional)
	return not required.is_empty() and required.all(func(s): return s.done)


func refresh() -> void:
	_update_extras()


func _show_status(text: String, color: Color, hold: float) -> void:
	_status.text = text
	_status.visible = true
	_status.add_theme_color_override("font_color", color)
	if _status_tween:
		_status_tween.kill()
	_status_tween = create_tween()
	_status_tween.tween_property(_status, "modulate:a", 1.0, 0.25)
	_fit.call_deferred()
	if hold > 0.0:
		_status_tween.tween_interval(hold)
		_status_tween.tween_property(_status, "modulate:a", 0.0, 0.8)
		_status_tween.tween_callback(func():
			_status.text = ""
			_status.visible = false
			_fit())


func _process(delta: float) -> void:
	if _pulse > 0.0:
		_pulse = maxf(_pulse - delta * 1.5, 0.0)
		_pips.queue_redraw()


func _draw_pips() -> void:
	var x := 6.0
	var y := 6.0
	for step in _steps:
		if not is_instance_valid(step):
			continue
		var color: Color = DONE_COLOR if step.done else TODO_COLOR
		if step.optional:
			var d := PackedVector2Array([Vector2(x, y - 5), Vector2(x + 5, y), Vector2(x, y + 5), Vector2(x - 5, y), Vector2(x, y - 5)])
			if step.done:
				_pips.draw_colored_polygon(d, color)
			else:
				_pips.draw_polyline(d, color, 1.0)
		elif step.done:
			_pips.draw_circle(Vector2(x, y), 4.5, color)
		else:
			_pips.draw_arc(Vector2(x, y), 4.0, 0.0, TAU, 16, color, 1.0)
		x += 16.0
	if _pulse > 0.0:
		_pips.draw_rect(Rect2(0, 0, x, 12), Color(DONE_COLOR, 0.12 * _pulse))


## The pips (one per step) show only with full guidance: at Light the card is
## just the goal. A step may add one line to follow until it is done (the
## belfry flame in Chapter 1 Room 7).
func _update_extras() -> void:
	_pips.visible = Settings.guidance >= Settings.GUIDANCE_FULL
	_pips.queue_redraw()
	var line := ""
	for step in _steps:
		if is_instance_valid(step) and not step.done and String(step.todo_label) != "":
			line = "▸ " + String(step.todo_label)
			break
	_todo.text = line
	_todo.visible = line != ""
	_fit.call_deferred()
