class_name Interactable
extends Area2D

## A zone that lets the player use the object it belongs to. Shows a small
## prompt with the real key binding (e.g. "[W] Ring") only while the player is
## close, and only on the nearest usable object if several overlap.

signal interacted(player: Node)

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")

@export var verb := "Use":
	set(value):
		verb = value
		_refresh_text()
@export var action := "interact"
@export var enabled := true
@export var size := Vector2(44, 64)
@export var prompt_offset := Vector2(0, -70)

static var _focused: Interactable = null

var _player: Node2D = null
var _prompt: Node2D
var _label: Label


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0, -size.y / 2.0)
	add_child(collider)
	body_entered.connect(func(b): if b.is_in_group("player"): _player = b)
	body_exited.connect(func(b): if b == _player: _player = null)
	_build_prompt()


func is_focused() -> bool:
	return _focused == self


func _physics_process(_delta: float) -> void:
	var usable: bool = _is_usable()
	if usable:
		var mine := _player.global_position.distance_to(global_position)
		if not is_instance_valid(_focused) or not _focused._is_usable() \
				or mine < _focused._player.global_position.distance_to(_focused.global_position) - 0.5:
			_focused = self
	elif _focused == self:
		_focused = null

	var show: bool = usable and _focused == self
	_prompt.modulate.a = move_toward(_prompt.modulate.a, 1.0 if show else 0.0, 0.2)
	_prompt.visible = _prompt.modulate.a > 0.01

	if show and Input.is_action_just_pressed(action):
		interacted.emit(_player)


func _is_usable() -> bool:
	if not enabled or _player == null or not is_instance_valid(_player):
		return false
	return not _player.get("is_dead") and not _player.get("controls_locked")


func _exit_tree() -> void:
	if _focused == self:
		_focused = null


func _build_prompt() -> void:
	_prompt = Node2D.new()
	_prompt.z_index = 20
	_prompt.position = prompt_offset
	_prompt.modulate.a = 0.0
	_prompt.visible = false
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_prompt.material = mat
	add_child(_prompt)

	var panel := PanelContainer.new()
	panel.use_parent_material = true
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.035, 0.09, 0.88)
	style.border_color = Color(0.5, 0.38, 0.78, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", style)
	panel.scale = Vector2(0.5, 0.5)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_child(panel)

	_label = Label.new()
	_label.use_parent_material = true
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color("e4ddf2"))
	panel.add_child(_label)
	_refresh_text()
	panel.resized.connect(func(): panel.position = Vector2(-panel.size.x * 0.25, -panel.size.y * 0.5))


func _refresh_text() -> void:
	if _label:
		_label.text = "[%s] %s" % [InputLabels.primary(action), verb]
