class_name Interactable
extends Area2D

## A zone that lets the player use the object it belongs to. Shows a small
## prompt with the real key binding (e.g. "[W] Ring") only while the player is
## close, and only on the nearest usable object if several overlap.

signal interacted(player: Node)

const FONT := Fonts.UI

@export var verb := "Use":
	set(value):
		verb = value
		_refresh_text()
@export var action := "interact"
@export var enabled := true
@export var size := Vector2(44, 64)
@export var prompt_offset := Vector2(0, -70)
## Whether an Echo replaying a recorded use can use it too.
@export var echo_can_use := true
## When several are in reach, the higher one is used (a rune cube over a hint
## stone beside it), then the nearest.
@export var use_priority := 0

static var _focused: Interactable = null

const CUE_RANGE := 170.0
const CUE_ALPHA := 0.45

var _player: Node2D = null
var _nearby: Node2D = null
var _compact := false
var _pad_mode := false
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


## True while the player is close enough to use it.
func in_reach() -> bool:
	return _is_usable()


func _physics_process(_delta: float) -> void:
	var usable: bool = _is_usable()
	if usable:
		var mine := _player.global_position.distance_to(global_position)
		if not is_instance_valid(_focused) or not _focused._is_usable() or use_priority > _focused.use_priority \
				or (use_priority == _focused.use_priority \
				and mine < _focused._player.global_position.distance_to(_focused.global_position) - 0.5):
			_focused = self
	elif _focused == self:
		_focused = null

	var show: bool = usable and _focused == self
	# From a little further away a faint key cue says "you can use this"
	var cue := not show and _in_cue_range()
	var compact := not show
	if compact != _compact or InputLabels.use_pad != _pad_mode:
		_compact = compact
		_pad_mode = InputLabels.use_pad
		_refresh_text()
	_prompt.modulate.a = move_toward(_prompt.modulate.a, 1.0 if show else (CUE_ALPHA if cue else 0.0), 0.2)
	_prompt.visible = _prompt.modulate.a > 0.01

	if show and Input.is_action_just_pressed(action):
		interacted.emit(_player)
		# So an Echo being recorded can repeat it
		if _player and _player.has_method("record_interaction"):
			_player.record_interaction(self)


## Uses it on someone else's behalf (an Echo replaying a recorded use).
## Returns false if it can't be used right now.
func trigger(actor: Node) -> bool:
	if not enabled or not echo_can_use:
		return false
	interacted.emit(actor)
	return true


func _in_cue_range() -> bool:
	if not enabled or Settings.guidance < Settings.GUIDANCE_FULL:
		return false
	if not is_instance_valid(_nearby):
		_nearby = get_tree().get_first_node_in_group("player") as Node2D
		if _nearby == null:
			return false
	if _nearby.get("is_dead") or _nearby.get("controls_locked"):
		return false
	return _nearby.global_position.distance_to(global_position) < CUE_RANGE


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
	panel.add_theme_stylebox_override("panel", DungeonUI.style("panel_lite", 8, Vector4(12, 5, 12, 5)))
	panel.scale = Vector2(0.5, 0.5)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_child(panel)

	_label = Label.new()
	_label.use_parent_material = true
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color("e8dcc0"))
	panel.add_child(_label)
	InputLabels.watch(self, _refresh_text)
	panel.resized.connect(func(): panel.position = Vector2(-panel.size.x * 0.25, -panel.size.y * 0.5))


func _refresh_text() -> void:
	if _label:
		var key := InputLabels.primary(action)
		_label.text = "[%s]" % key if _compact else "[%s] %s" % [key, verb]
		# fit the plate to the new key name (shorter on a keyboard than a pad)
		if _label.get_parent() is Control:
			(_label.get_parent() as Control).reset_size()
