class_name KindlePrompt
extends Node2D

## Over a flame Echidna can kindle her lantern at (a flame bowl, a shrine, a
## candle, a lit brazier; never a wall torch): "[R] Kindle" while her mana is
## not full and she is close enough, a faint "[R]" from a little further off,
## so it is clear which flames refill her mana. Added to the player.

const FONT := Fonts.UI
## How far off the faint cue shows.
const CUE_RANGE := 220.0
## How high over the flame's foot it floats.
const LIFT := 96.0

var player: Node2D
var _label: Label
var _target: Node2D
var _close := false
var _pad := false


func _ready() -> void:
	top_level = true
	z_index = 20
	modulate.a = 0.0
	visible = false
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = mat
	var panel := PanelContainer.new()
	panel.use_parent_material = true
	panel.add_theme_stylebox_override("panel", DungeonUI.style("panel_lite", 8, Vector4(12, 5, 12, 5)))
	panel.scale = Vector2(0.5, 0.5)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	_label = Label.new()
	_label.use_parent_material = true
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", DungeonUI.GOLD)
	panel.add_child(_label)
	panel.resized.connect(func(): panel.position = Vector2(-panel.size.x * 0.25, -panel.size.y * 0.5))
	_refresh()


## The text it shows now ("" when hidden).
func shown_text() -> String:
	return _label.text if visible and modulate.a > 0.3 else ""


func _physics_process(_delta: float) -> void:
	var want := 0.0
	var close := false
	if is_instance_valid(player) and _wanted():
		var t: Node2D = player.nearest_kindle(CUE_RANGE)
		if t:
			_target = t
			close = player.near_kindle()
			want = 1.0 if close else 0.45
	if is_instance_valid(_target):
		global_position = _target.global_position + Vector2(0, -LIFT)
	if close != _close or InputLabels.use_pad != _pad:
		_close = close
		_pad = InputLabels.use_pad
		_refresh()
	modulate.a = move_toward(modulate.a, want, 0.12)
	visible = modulate.a > 0.01


func _wanted() -> bool:
	if Settings.assist_infinite_mana or Settings.guidance < Settings.GUIDANCE_LIGHT:
		return false
	if player.is_dead or player.controls_locked or player.is_reloading:
		return false
	return player.current_mana < player.get_mana_cap()


func _refresh() -> void:
	var key := InputLabels.primary("reload")
	_label.text = "[%s] Kindle" % key if _close else "[%s]" % key
