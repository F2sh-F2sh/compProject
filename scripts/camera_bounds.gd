class_name CameraBounds
extends Camera2D

## Keeps the camera inside the level's (or current room's) playable area. If
## the window's shape would show more than the bounds hold, the zoom is raised
## just enough to fit. It trails its parent (the player) with a subtle damped
## follow: a little quicker sideways than up and down, leaning slightly ahead
## of her movement, and it snaps on teleports. Also offers smooth room
## transitions, screen shake that respects the reduced-motion setting, and a
## brief look at a distant point.

## The area the camera may show, in world coordinates.
@export var bounds := Rect2(0, 0, 1152, 648):
	set(value):
		bounds = value
		if is_inside_tree():
			_apply()
@export var base_zoom := Vector2(2, 2)
@export var transition_time := 0.45

@export_group("Follow")
## How quickly the camera closes the gap to its target (per second), per
## axis. Higher is tighter; around 6-8 sideways and 4-5 vertically reads as
## a soft, weighty follow without ever losing the player.
@export var follow_damping := Vector2(7.0, 4.5)
## How far ahead of the player the camera leans, in seconds of her current
## horizontal speed (so a sprint looks further ahead than a walk).
@export var look_ahead_time := 0.24
## The most it will ever lean ahead.
@export var look_ahead_max := 56.0
## A jump in the target larger than this (a teleport or respawn) snaps.
@export var snap_distance := 320.0

var _bounds_tween: Tween
var _shake_strength := 0.0
var _shake_time := 0.0
var _focus_tween: Tween
var _focus_offset := Vector2.ZERO
var _follow := Vector2.ZERO
var _lead := 0.0


func _ready() -> void:
	# The camera moves itself, trailing its parent instead of being rigidly attached
	top_level = true
	_apply()
	get_viewport().size_changed.connect(_apply)
	snap()


## Jumps straight to the target (teleports, respawns, room resets).
func snap() -> void:
	_lead = 0.0
	_follow = _target()
	global_position = _follow
	reset_smoothing()


func _target() -> Vector2:
	var parent := get_parent() as Node2D
	if parent == null:
		return global_position
	return parent.global_position + Vector2(_lead, 0)


func _update_follow(delta: float) -> void:
	var parent := get_parent() as Node2D
	if parent == null:
		return
	var moving: Variant = parent.get("velocity")
	var lead_goal := 0.0
	if moving is Vector2 and absf(moving.x) > 20.0:
		lead_goal = clampf(moving.x * look_ahead_time, -look_ahead_max, look_ahead_max)
	_lead = lerpf(_lead, lead_goal, 1.0 - exp(-2.5 * delta))
	var goal := _target()
	if _follow.distance_to(goal) > snap_distance:
		snap()
		return
	_follow.x = lerpf(_follow.x, goal.x, 1.0 - exp(-follow_damping.x * delta))
	_follow.y = lerpf(_follow.y, goal.y, 1.0 - exp(-follow_damping.y * delta))
	global_position = _follow


## Slides the limits to a new area instead of snapping.
func set_bounds_smooth(target: Rect2) -> void:
	if _bounds_tween:
		_bounds_tween.kill()
	if not is_inside_tree() or transition_time <= 0.0:
		bounds = target
		return
	# Interpolating the limits makes the clamped view slide into the new room
	var from := _current_limits()
	_bounds_tween = create_tween()
	_bounds_tween.tween_method(func(k: float):
		_set_limits(Rect2(from.position.lerp(target.position, k), from.size.lerp(target.size, k))),
		0.0, 1.0, transition_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_bounds_tween.tween_callback(func(): bounds = target)


func shake(strength: float, duration := 0.25) -> void:
	if Settings.reduce_motion:
		return
	_shake_strength = maxf(_shake_strength, strength)
	_shake_time = maxf(_shake_time, duration)


## Looks toward a world point for `hold` seconds, then eases back.
func focus_on(world_point: Vector2, hold := 1.0) -> void:
	if _focus_tween:
		_focus_tween.kill()
	var target := (world_point - global_position) * 0.85
	_focus_tween = create_tween()
	_focus_tween.tween_property(self, "_focus_offset", target, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_focus_tween.tween_interval(hold)
	_focus_tween.tween_property(self, "_focus_offset", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func cancel_focus() -> void:
	if _focus_tween:
		_focus_tween.kill()
	_focus_offset = Vector2.ZERO


func _process(delta: float) -> void:
	_update_follow(delta)
	var shake_offset := Vector2.ZERO
	if _shake_time > 0.0:
		_shake_time -= delta
		shake_offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_strength
		if _shake_time <= 0.0:
			_shake_strength = 0.0
	offset = _clamp_offset(_focus_offset + shake_offset)


# Camera2D adds `offset` after applying its limits, so keep shake and focus
# from ever showing past the edge of the bounds
func _clamp_offset(wanted: Vector2) -> Vector2:
	var half := get_viewport_rect().size / zoom / 2.0
	var lo := Vector2(limit_left, limit_top) + half
	var hi := Vector2(limit_right, limit_bottom) - half
	var centre := Vector2(
		clampf(global_position.x, lo.x, hi.x) if lo.x <= hi.x else (limit_left + limit_right) / 2.0,
		clampf(global_position.y, lo.y, hi.y) if lo.y <= hi.y else (limit_top + limit_bottom) / 2.0)
	return Vector2(
		clampf(wanted.x, minf(lo.x - centre.x, 0.0), maxf(hi.x - centre.x, 0.0)),
		clampf(wanted.y, minf(lo.y - centre.y, 0.0), maxf(hi.y - centre.y, 0.0)))


func _apply() -> void:
	_set_limits(bounds)
	var view := get_viewport_rect().size
	var fit := maxf(view.x / bounds.size.x, view.y / bounds.size.y)
	zoom = Vector2.ONE * maxf(base_zoom.x, fit)
	reset_smoothing()


func _set_limits(r: Rect2) -> void:
	limit_left = floori(r.position.x)
	limit_top = floori(r.position.y)
	limit_right = ceili(r.end.x)
	limit_bottom = ceili(r.end.y)


func _current_limits() -> Rect2:
	return Rect2(limit_left, limit_top, limit_right - limit_left, limit_bottom - limit_top)
