@tool
class_name Lever
extends Node2D

## A wall-side lever. Pull it with the interact key to toggle its power.
## States: off (handle left, dim rune), on (handle right, glowing rune) and
## locked (chained, no prompt) until a circuit unlocks it with set_powered.
## A persistent lever (persist_id) stays pulled across deaths — use it for
## shortcuts. The node sits on the floor surface.

signal power_changed(powered: bool)

@export var start_on := false
## Once pulled on, it cannot be pulled back.
@export var one_way := false
@export var locked := false:
	set(value):
		locked = value
		if _interact:
			_interact.enabled = not locked and not (one_way and is_on)
		queue_redraw()
@export var persist_id := ""
@export var rune_color := Color(0.45, 0.72, 1.0)
## A spring lever: once pulled it snaps back up after this many seconds
## (0 = an ordinary lever that stays where it is put). A shrinking ring on
## the handle shows how long it will hold.
@export var spring_time := 0.0

var is_on := false
var _spring_left := 0.0
var _angle := -0.6
var _interact: Interactable
var _light: PointLight2D
var _start_locked := false


func _ready() -> void:
	is_on = start_on
	_angle = 0.6 if is_on else -0.6
	_start_locked = locked
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(96)
	_light.color = rune_color
	_light.position = Vector2(0, -6)
	add_child(_light)
	_interact = Interactable.new()
	_interact.verb = "Pull"
	_interact.size = Vector2(40, 56)
	_interact.prompt_offset = Vector2(0, -52)
	add_child(_interact)
	_interact.interacted.connect(func(_p): toggle())
	if persist_id != "" and GameState.has_flag(persist_id):
		is_on = true
		_angle = 0.6
	locked = locked
	_refresh_light()


func is_powered() -> bool:
	return is_on


## A circuit powering the lever unlocks it.
func set_powered(powered: bool) -> void:
	locked = not powered


func toggle() -> void:
	if locked or (one_way and is_on):
		return
	# A spring lever can't be pushed back up; it returns on its own
	if spring_time > 0.0 and is_on:
		return
	is_on = not is_on
	if is_on and spring_time > 0.0:
		_spring_left = spring_time
	if is_on and persist_id != "":
		GameState.set_flag(persist_id)
	Sfx.play("lever", global_position)
	var tween := create_tween()
	tween.tween_property(self, "_angle", 0.6 if is_on else -0.6, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.18)
	_interact.enabled = not locked and not (one_way and is_on) and not (spring_time > 0.0 and is_on)
	_refresh_light()
	power_changed.emit(is_on)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or spring_time <= 0.0 or not is_on:
		return
	_spring_left -= delta
	queue_redraw()
	if _spring_left <= 0.0:
		_spring_back()


func _spring_back() -> void:
	is_on = false
	_interact.enabled = not locked
	Sfx.play("lever", global_position, -6.0, 0.1)
	var tween := create_tween()
	tween.tween_property(self, "_angle", -0.6, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_method(func(_v): queue_redraw(), 0.0, 1.0, 0.25)
	_refresh_light()
	power_changed.emit(false)


func reset_state() -> void:
	_spring_left = 0.0
	if persist_id != "" and GameState.has_flag(persist_id):
		return
	var was_on := is_on
	is_on = start_on
	_angle = 0.6 if is_on else -0.6
	locked = _start_locked
	_refresh_light()
	if was_on != is_on:
		power_changed.emit(is_on)
	queue_redraw()


func _refresh_light() -> void:
	if _light:
		_light.energy = 0.9 if is_on else (0.0 if locked else 0.2)


func _draw() -> void:
	var iron := Color("2b2838")
	var iron_light := Color("5b5773")
	# Stone base
	draw_rect(Rect2(-12, -8, 24, 8), Color("231d38"))
	draw_rect(Rect2(-12, -8, 24, 2), Color("4a4170"))
	# Handle pivots from the base
	var pivot := Vector2(0, -7)
	var tip := pivot + Vector2(sin(_angle), -cos(_angle)) * 20.0
	draw_line(pivot, tip, iron, 4.0)
	draw_line(pivot, tip, iron_light, 1.0)
	draw_circle(tip, 3.0, Color("6a5f92") if not locked else iron_light)
	draw_circle(pivot, 3.0, iron)
	# Rune on the base shows the state
	var rune := rune_color if is_on else Color(0.35, 0.3, 0.5)
	if locked:
		rune = Color(0.55, 0.18, 0.22)
	draw_rect(Rect2(-8, -4, 5, 1), rune)
	draw_rect(Rect2(3, -4, 5, 1), rune)
	draw_rect(Rect2(-1, -5, 2, 3), rune)
	if locked:
		# A chain wrapped around the handle
		for i in 4:
			draw_rect(Rect2(-6 + i * 3, -14 + i, 3, 3), iron_light, false, 1.0)
	if spring_time > 0.0:
		# A coiled spring on the base; while pulled, a ring shows the time left
		for i in 3:
			draw_arc(Vector2(-13, -3 - i * 2), 2.0, 0.0, TAU, 8, iron_light, 1.0)
		if is_on and not Engine.is_editor_hint():
			var left := clampf(_spring_left / spring_time, 0.0, 1.0)
			draw_arc(tip, 6.0, -PI / 2.0, -PI / 2.0 + TAU * left, 20, Color(rune_color, 0.9), 1.5)
