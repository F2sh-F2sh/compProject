class_name SettingsPanel
extends VBoxContainer

## The settings on the title screen: volumes, graphics (Low to Elite), FPS,
## guidance, reduced motion, fullscreen, and a list of the controls (read
## from the real bindings, so it is always right).

const FONT := Fonts.STORY
const CONTROLS := [
	["Walk left", "move_left"],
	["Walk right", "move_right"],
	["Jump", "jump"],
	["Crouch (hold, then jump higher)", "crouch"],
	["Sprint (hold)", "sprint"],
	["Fireball (aim with the mouse)", "shoot"],
	["Heal (stand still)", "heal"],
	["Kindle (mana)", "reload"],
	["Record an Echo (hold: let Echoes fade)", "echo"],
	["Use / pull / ring / inscribe a cube", "interact"],
	["Pick up / place a rune cube", "rune_carry"],
	["Rune overview (switch cubes off)", "rune_overview"],
	["Pause", "pause"],
]

var _key_buttons := {}
var _waiting := ""


## A settings panel in a scroll box of the given height (for menus).
static func scrolled(height: float) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, height)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var panel := SettingsPanel.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(panel)
	return scroll


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	add_child(_slider_row("Master volume", Settings.master_volume, Settings.set_master_volume))
	add_child(_slider_row("Music volume", Settings.music_volume, Settings.set_music_volume))
	add_child(_slider_row("Ambience volume", Settings.ambient_volume, Settings.set_ambient_volume))
	add_child(_slider_row("Effects volume", Settings.sfx_volume, Settings.set_sfx_volume))
	var guidance := OptionButton.new()
	for item in ["Guidance: Full (goals, links, nudges)", "Guidance: Light (goals only)", "Guidance: Off"]:
		guidance.add_item(item)
	# Items run Full, Light, Off; the setting counts the other way
	guidance.selected = Settings.GUIDANCE_FULL - Settings.guidance
	guidance.add_theme_font_override("font", FONT)
	guidance.add_theme_font_size_override("font_size", 14)
	guidance.item_selected.connect(func(i): Sfx.play("ui_click"); Settings.set_guidance(Settings.GUIDANCE_FULL - i))
	add_child(guidance)
	add_child(_check("Reduce camera shake and flashes", Settings.reduce_motion, Settings.set_reduce_motion))
	add_child(_check("Fullscreen (F11)", Settings.fullscreen, Settings.set_fullscreen))
	var brightness := OptionButton.new()
	for level_name in Settings.BRIGHTNESS_NAMES:
		brightness.add_item("Brightness: %s" % level_name)
	brightness.selected = Settings.brightness
	brightness.add_theme_font_override("font", FONT)
	brightness.add_theme_font_size_override("font_size", 14)
	brightness.item_selected.connect(func(i): Sfx.play("ui_click"); Settings.set_brightness(i))
	add_child(brightness)
	var graphics := OptionButton.new()
	for level_name in Settings.GRAPHICS_NAMES:
		graphics.add_item("Graphics: %s" % level_name)
	graphics.selected = Settings.graphics
	graphics.add_theme_font_override("font", FONT)
	graphics.add_theme_font_size_override("font_size", 14)
	graphics.item_selected.connect(func(i): Sfx.play("ui_click"); Settings.set_graphics(i))
	add_child(graphics)
	add_child(_check("Show FPS", Settings.show_fps, Settings.set_show_fps))
	add_child(_check("Smooth motion", Settings.smooth_motion, Settings.set_smooth_motion))
	add_child(_label("Assist", 14, Color("f0d27a")))
	var damage := OptionButton.new()
	var levels := [1.0, 0.75, 0.5, 0.25]
	for level in levels:
		damage.add_item("Damage taken: %d%%" % int(level * 100.0))
	damage.selected = maxi(levels.find(Settings.assist_damage), 0)
	damage.add_theme_font_override("font", FONT)
	damage.add_theme_font_size_override("font_size", 14)
	damage.item_selected.connect(func(i): Sfx.play("ui_click"); Settings.set_assist("assist_damage", levels[i]))
	add_child(damage)
	add_child(_check("Unlimited mana", Settings.assist_infinite_mana,
		func(on): Settings.set_assist("assist_infinite_mana", on)))
	add_child(_check("Always sprint (hold sprint to walk)", Settings.assist_auto_sprint,
		func(on): Settings.set_assist("assist_auto_sprint", on)))
	add_child(_check("Crouch toggles (press once, no holding)", Settings.assist_toggle_crouch,
		func(on): Settings.set_assist("assist_toggle_crouch", on)))
	add_child(_check("Hints without waiting (the skulls speak at once)", Settings.assist_instant_hints,
		func(on): Settings.set_assist("assist_instant_hints", on)))
	var controls := Button.new()
	controls.text = "Show controls"
	controls.toggle_mode = true
	controls.add_theme_font_override("font", FONT)
	controls.add_theme_font_size_override("font_size", 14)
	add_child(controls)
	var grid := _controls_grid()
	grid.visible = false
	add_child(grid)
	controls.toggled.connect(func(on):
		Sfx.play("ui_click")
		grid.visible = on
		controls.text = "Hide controls" if on else "Show controls")


## Every control with its key; click a key to rebind it (then press the new
## key or mouse button). A controller works too: A jump, X heal, Y refill,
## B echo, RT fire, LT sprint, right stick aim, Start pause.
func _controls_grid() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 2)
	box.add_child(grid)
	for row in CONTROLS:
		grid.add_child(_label(row[0], 12, Color("b9ab90")))
		var key := Button.new()
		key.custom_minimum_size = Vector2(130, 24)
		key.add_theme_font_override("font", FONT)
		key.add_theme_font_size_override("font_size", 14)
		key.add_theme_color_override("font_color", Color("f0d890"))
		key.pressed.connect(_begin_rebind.bind(row[1]))
		grid.add_child(key)
		_key_buttons[row[1]] = key
	box.add_child(_label("Click a key to change it. Controller: A jump, RT fire, right stick aim, LT sprint,\nX heal, Y refill, B echo, D-pad up use, Start pause.", 11, Color("8a8092")))
	var reset := Button.new()
	reset.text = "Reset controls"
	reset.add_theme_font_override("font", FONT)
	reset.add_theme_font_size_override("font_size", 14)
	reset.pressed.connect(func():
		Sfx.play("ui_click")
		_waiting = ""
		Settings.reset_bindings()
		_refresh_keys())
	box.add_child(reset)
	_refresh_keys()
	return box


func _refresh_keys() -> void:
	for action in _key_buttons:
		_key_buttons[action].text = "Press a key..." if action == _waiting else InputLabels.primary(action)


func _begin_rebind(action: String) -> void:
	Sfx.play("ui_click")
	_waiting = action
	_refresh_keys()


func _input(event: InputEvent) -> void:
	if _waiting == "" or not is_visible_in_tree():
		return
	var usable: bool = (event is InputEventKey and event.pressed and not event.echo) \
		or (event is InputEventMouseButton and event.pressed)
	if not usable:
		return
	get_viewport().set_input_as_handled()
	# Escape cancels (unless it's the pause key being chosen)
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE and _waiting != "pause":
		_waiting = ""
	else:
		var actions: Array = CONTROLS.map(func(r): return r[1])
		Settings.rebind(_waiting, event, actions)
		_waiting = ""
		Sfx.play("ui_click")
	_refresh_keys()


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _check(text: String, value: bool, on_change: Callable) -> CheckBox:
	var box := CheckBox.new()
	box.text = text
	box.button_pressed = value
	box.add_theme_font_override("font", FONT)
	box.add_theme_font_size_override("font_size", 16)
	box.toggled.connect(func(on): Sfx.play("ui_click"); on_change.call(on))
	return box


func _slider_row(text: String, value: float, on_change: Callable) -> Control:
	var row := VBoxContainer.new()
	row.add_child(_label(text, 14, Color("e8dcc0")))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(320, 20)
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row
