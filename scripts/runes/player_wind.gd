class_name PlayerWind
extends Node

## How wind moves Echidna. Added to the player by the RuneManager, so the
## player controller itself is unchanged. It runs after her own movement
## each physics frame:
##   sideways: she drifts with the current (a normal wind carries her at a
##   third of walking speed; walking against it is slower, against a strong
##   wind noticeably so);
##   upward: an updraft pushes against gravity, so a normal current floats
##   her up slowly and a strong one lifts her quickly, both with a capped
##   rising speed; at the top of the column she settles and bobs.

## Drift speed per unit of force (1200 -> 36 px/s) and how fast it builds.
const DRIFT_PER_FORCE := 0.03
const DRIFT_RATE := 5.0
## Upward acceleration per unit of force, and the fastest rise.
const LIFT_PER_FORCE := 1.0
const MAX_RISE := 190.0

var force := Vector2.ZERO
var drift := 0.0
var _player: CharacterBody2D


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	_player.add_to_group("wind_receiver")
	# After the player's own physics
	process_physics_priority = 10


## Called by the RuneManager with the sum of every wind on her this frame.
func set_wind_force(total: Vector2) -> void:
	force = total


## A gust: a shove sideways (drifting off quickly) and a real kick upward.
func apply_wind_impulse(impulse: Vector2) -> void:
	drift += impulse.x * 0.5
	_player.velocity.y += impulse.y * 0.8


func _physics_process(delta: float) -> void:
	var f := force
	force = Vector2.ZERO
	if _player.is_dead or _player.controls_locked:
		drift = 0.0
		return
	drift = lerpf(drift, f.x * DRIFT_PER_FORCE, 1.0 - exp(-DRIFT_RATE * delta))
	if absf(drift) > 0.5:
		_player.move_and_collide(Vector2(drift * delta, 0.0))
	if f.y < 0.0:
		RuneJournal.note("lift")
		_player.velocity.y = maxf(_player.velocity.y + f.y * LIFT_PER_FORCE * delta, -MAX_RISE)
	elif f.y > 0.0:
		_player.velocity.y += f.y * LIFT_PER_FORCE * 0.5 * delta
