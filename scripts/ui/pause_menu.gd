class_name PauseMenu
extends CanvasLayer

## Esc menu: resume, reset the current room, volume and reduced-motion
## settings, and the count of lore pages found. Unavailable while the death
## screen is up. Works in any level; room reset needs a ChapterRoot.

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")

var is_open := false
var _panel: PanelContainer
var _dim: ColorRect
var _reset_button: Button
var _resume_button: Button
var _restart_button: Button
var _restart_armed := false
var _pages_label: Label


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_set_open(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause", false):
		if _death_screen_up():
			return
		get_viewport().set_input_as_handled()
		_set_open(not is_open)


func _death_screen_up() -> bool:
	var death := get_tree().get_first_node_in_group("death_screen")
	return death != null and death.visible


func _set_open(open: bool) -> void:
	is_open = open
	_dim.visible = open
	_panel.visible = open
	get_tree().paused = open
	_restart_armed = false
	_restart_button.text = "Restart Chapter"
	if open:
		var root := _chapter_root()
		_reset_button.disabled = root == null or root.current_room == null
		_restart_button.visible = root != null
		if root and root.total_pages > 0:
			_pages_label.text = "Lore pages found: %d / %d" % [root.pages_found(), root.total_pages]
			_pages_label.visible = true
		else:
			_pages_label.visible = false
		Sfx.play("ui_open")
		_resume_button.grab_focus()


func _chapter_root() -> Node:
	return get_tree().get_first_node_in_group("chapter_root")


## Wipes this chapter's saved progress and starts it over. Asks for a second
## press first, since it cannot be undone.
func _on_restart() -> void:
	Sfx.play("ui_click")
	if not _restart_armed:
		_restart_armed = true
		_restart_button.text = "Press again to erase chapter progress"
		return
	var root := _chapter_root()
	if root == null:
		return
	GameState.clear_progress(root.chapter_id)
	_set_open(false)
	get_tree().reload_current_scene()


func _on_reset() -> void:
	Sfx.play("ui_click")
	_set_open(false)
	var root := _chapter_root()
	if root:
		root.reset_current_room()


func _build() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.02, 0.01, 0.05, 0.65)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.1, 0.96)
	style.border_color = Color(0.5, 0.38, 0.78, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)

	var title := _label("PAUSED", 26, Color("cbbdf2"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_resume_button = _button("Resume", func(): Sfx.play("ui_click"); _set_open(false))
	box.add_child(_resume_button)
	_reset_button = _button("Reset Room", _on_reset)
	box.add_child(_reset_button)
	box.add_child(_label("Puts this room's puzzle back to its start. Health is kept.", 12, Color("9d93b8")))

	box.add_child(HSeparator.new())
	box.add_child(_slider_row("Master volume", Settings.master_volume, Settings.set_master_volume))
	box.add_child(_slider_row("Music volume", Settings.music_volume, Settings.set_music_volume))
	box.add_child(_slider_row("Ambience volume", Settings.ambient_volume, Settings.set_ambient_volume))
	box.add_child(_slider_row("Effects volume", Settings.sfx_volume, Settings.set_sfx_volume))
	var motion := CheckBox.new()
	motion.text = "Reduce camera shake and flashes"
	motion.button_pressed = Settings.reduce_motion
	motion.add_theme_font_override("font", FONT)
	motion.add_theme_font_size_override("font_size", 15)
	motion.toggled.connect(func(on): Settings.set_reduce_motion(on))
	box.add_child(motion)

	_pages_label = _label("", 14, Color("b8acd8"))
	box.add_child(_pages_label)
	box.add_child(HSeparator.new())
	_restart_button = _button("Restart Chapter", _on_restart)
	box.add_child(_restart_button)
	box.add_child(_button("Quit Game", func(): get_tree().quit()))


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 40)
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(on_press)
	return b


func _slider_row(text: String, value: float, on_change: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_child(_label(text, 14, Color("e4ddf2")))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(320, 20)
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row
