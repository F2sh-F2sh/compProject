class_name DailyPiston
extends PistonTrap

var frozen_left := 0.0
var is_frozen := false

func _ready() -> void:
	super._ready()
	add_to_group("freezable")

func chill_from(field: FreezeField) -> void:
	var head := Rect2(global_position + Vector2(-head_size.x / 2, get_head_bottom() - head_size.y), head_size)
	var exclusions: Array[RID] = []
	if _head_body: exclusions.append(_head_body.get_rid())
	if field.covers(head, exclusions):
		frozen_left = 0.6
		is_frozen = true

func _physics_process(delta: float) -> void:
	frozen_left = maxf(0, frozen_left - delta)
	is_frozen = frozen_left > 0
	if not is_frozen:
		super._physics_process(delta)

func reset_state() -> void:
	frozen_left = 0
	is_frozen = false
	super.reset_state()

func is_powered() -> bool:
	return is_frozen
