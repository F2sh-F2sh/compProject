class_name HazardRecovery
extends Node

## Handles the short non-lethal reset after a spike hit: fade out, move the
## player to a safe point, fade in, then hand control back. Lives as a child
## of the Player.

signal recovery_started
signal recovery_finished

@export var fade_out_time := 0.18
@export var hold_time := 0.12
@export var fade_in_time := 0.28
## Extra pause after the fade before input returns.
@export var control_restore_delay := 0.05
## Invulnerability that continues after control is restored.
@export var post_recovery_invulnerability := 1.0
@export var fade_color := Color(0.02, 0.01, 0.05)
## Ground within this distance of a hazard is not remembered as safe.
@export var safe_hazard_margin := 28.0

var last_safe_position := Vector2.ZERO
var has_safe_position := false

var _active := false
var _tween: Tween
var _overlay: ColorRect

@onready var player: CharacterBody2D = get_parent()


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color(fade_color, 0.0)
	layer.add_child(_overlay)


func is_active() -> bool:
	return _active


func begin(target: Vector2) -> void:
	if _active or player.is_dead:
		return
	_active = true
	player.lock_controls(true)
	player.grant_invulnerability(fade_out_time + hold_time + fade_in_time
		+ control_restore_delay + post_recovery_invulnerability)
	recovery_started.emit()

	_tween = create_tween()
	_tween.tween_property(_overlay, "color:a", 1.0, fade_out_time)
	_tween.tween_callback(player.teleport_to.bind(target))
	_tween.tween_interval(hold_time)
	_tween.tween_property(_overlay, "color:a", 0.0, fade_in_time)
	_tween.tween_interval(control_restore_delay)
	_tween.tween_callback(_finish)


func abort() -> void:
	if _tween:
		_tween.kill()
	_overlay.color.a = 0.0
	_active = false


func get_fallback_position() -> Vector2:
	return last_safe_position if has_safe_position else player.global_position


func _finish() -> void:
	_active = false
	player.unlock_controls()
	recovery_finished.emit()


func _physics_process(_delta: float) -> void:
	if _active or player.is_dead or player.controls_locked:
		return
	if player.is_on_floor() and not _near_hazard(player.global_position):
		last_safe_position = player.global_position
		has_safe_position = true


func _near_hazard(pos: Vector2) -> bool:
	for hazard in get_tree().get_nodes_in_group("hazard_zone"):
		if hazard.get_hazard_rect().grow(safe_hazard_margin).has_point(pos):
			return true
	return false
