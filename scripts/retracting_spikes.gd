@tool
class_name RetractingSpikes
extends SpikeHazard

## Spikes that sink into the floor and rise again on a loop. They rattle
## briefly before rising so the player can read the timing.

@export var lowered_time := 1.7
@export var warning_time := 0.45
@export var rise_time := 0.08
@export var raised_time := 1.2
@export var lower_time := 0.3
## 0-1 offset into the cycle, so neighbouring traps can be staggered.
@export_range(0.0, 1.0) var start_phase := 0.0
## The hitbox only exists once the spikes are at least this far out.
@export_range(0.0, 1.0) var danger_extension := 0.5
## Unpowered spikes stay sunk in the floor (a lever can switch them off).
@export var active := true

const WARNING_PEEK := 0.18

var extension := 1.0
var _elapsed := 0.0
var _start_active := true
var _was_warning := false


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		_start_active = active
		add_to_group("resettable")
		_update_extension()


func set_powered(powered: bool) -> void:
	active = powered


func reset_state() -> void:
	active = _start_active
	_elapsed = 0.0
	_update_extension()


func get_cycle_length() -> float:
	return lowered_time + warning_time + rise_time + raised_time + lower_time


## True while the spikes are down and it is safe to walk over them.
func is_lowered() -> bool:
	return extension <= 0.001


func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		_elapsed += delta
		_update_extension()
	super(delta)


func _is_dangerous() -> bool:
	return extension >= danger_extension


func _update_extension() -> void:
	var t := fposmod(_elapsed + start_phase * get_cycle_length(), get_cycle_length())
	var jitter := 0.0
	var warning := t >= lowered_time and t < lowered_time + warning_time
	if warning and not _was_warning and active:
		Sfx.play("piston_warn", global_position, -12.0)
	_was_warning = warning
	if not active:
		extension = move_toward(extension, 0.0, 0.1)
	elif t < lowered_time:
		extension = 0.0
	elif t < lowered_time + warning_time:
		extension = WARNING_PEEK
		jitter = 1.0 if int(t * 30.0) % 2 == 0 else -1.0
	elif t < lowered_time + warning_time + rise_time:
		extension = lerpf(WARNING_PEEK, 1.0, (t - lowered_time - warning_time) / rise_time)
	elif t < lowered_time + warning_time + rise_time + raised_time:
		extension = 1.0
	else:
		var k := (t - lowered_time - warning_time - rise_time - raised_time) / lower_time
		extension = lerpf(1.0, 0.0, clampf(k, 0.0, 1.0))
	_apply_extension(jitter)


func _rebuild() -> void:
	super()
	_apply_extension(0.0)
	queue_redraw()


func _apply_extension(jitter: float) -> void:
	if _sprite == null:
		return
	var w := get_width()
	var visible_height := roundf(SPIKE_SIZE * extension)
	_sprite.visible = visible_height >= 1.0
	# Only the tips show while the spikes are rising out of the floor
	_sprite.region_rect = Rect2(0, 0, w, maxf(visible_height, 1.0))
	_sprite.position = Vector2(-w / 2.0 + jitter, -visible_height)
	if extension >= danger_extension:
		_set_hitbox_height(visible_height - hitbox_inset.y)
	else:
		_set_hitbox_height(0.0)


func _draw() -> void:
	# Dark slots in the floor so the player can see where the spikes hide
	var w := get_width()
	for i in spike_count:
		var x := -w / 2.0 + i * SPIKE_SIZE
		draw_rect(Rect2(x + 5, -2, SPIKE_SIZE - 10, 3), Color(0.04, 0.03, 0.07, 0.9))
		draw_rect(Rect2(x + 5, -3, SPIKE_SIZE - 10, 1), Color(0.35, 0.3, 0.5, 0.6))
