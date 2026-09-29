class_name Chill
extends Node2D

## Ice holding a creature still. Added to a creature (slime, gargoyle, any
## CharacterBody2D in "enemy" or "gargoyle") by an Ice Freeze rune; while it
## lasts the creature's own behaviour is paused (it only falls), it can't
## hurt anyone, it is heavy enough for stone plates, and it wears a shell of
## ice. When the time runs out everything is put back as it was.

var left := 0.0
var creature: CharacterBody2D
var _tint := Color.WHITE
var _damage_area: Area2D
var _had_stone_weight := false
var _time := 0.0


## Freezes `target` for at least `seconds` (extends a chill already on it).
static func apply(target: Node, seconds: float) -> Chill:
	if not target is CharacterBody2D or target.get("is_dead") == true:
		return null
	var chill := target.get_node_or_null("Chill") as Chill
	if chill == null:
		chill = Chill.new()
		chill.name = "Chill"
		chill.left = seconds
		target.add_child(chill)
	else:
		chill.left = maxf(chill.left, seconds)
	return chill


static func is_chilled(target: Node) -> bool:
	return target != null and target.get_node_or_null("Chill") != null


func _ready() -> void:
	creature = get_parent() as CharacterBody2D
	creature.set_physics_process(false)
	creature.velocity.x = 0.0
	_tint = creature.modulate
	creature.modulate = Color(0.62, 0.85, 1.25)
	_had_stone_weight = creature.is_in_group("stone_weight")
	creature.add_to_group("stone_weight")
	creature.add_to_group("ice_frozen")
	_damage_area = creature.get_node_or_null("DamageArea") as Area2D
	if _damage_area:
		_damage_area.set_deferred("monitoring", false)
	material = MagicLight.unshaded()
	z_index = 2
	Sfx.play("ice_freeze", creature.global_position, -4.0)
	RuneJournal.note("chill")
	# Shell drawn in world space around the creature
	top_level = true
	global_transform = Transform2D.IDENTITY


func _physics_process(delta: float) -> void:
	_time += delta
	left -= delta
	if not is_instance_valid(creature):
		return
	# Frozen solid: it only falls
	creature.velocity.x = 0.0
	if not creature.is_on_floor():
		creature.velocity.y += creature.get_gravity().y * delta
	creature.move_and_slide()
	queue_redraw()
	if left <= 0.0 or creature.get("is_dead") == true:
		thaw()


func thaw() -> void:
	if not is_instance_valid(creature):
		queue_free()
		return
	creature.set_physics_process(true)
	creature.modulate = _tint
	if not _had_stone_weight:
		creature.remove_from_group("stone_weight")
	creature.remove_from_group("ice_frozen")
	if _damage_area and creature.get("is_dead") != true:
		_damage_area.set_deferred("monitoring", true)
	ImpactFX.burst(creature.get_parent(), creature.global_position + Vector2(0, -12), Color(0.7, 0.9, 1.0), true, 8)
	Sfx.play("ice_crack", creature.global_position, -6.0)
	queue_free()


func _draw() -> void:
	if not is_instance_valid(creature):
		return
	var box := RuneManager.bounds_of(creature).grow(3.0)
	var ice := Color(0.7, 0.9, 1.0)
	# Flickers in the last second, so the thaw is never a surprise
	var a := 0.35 if left > 1.0 or int(_time * 10.0) % 2 == 0 else 0.12
	draw_rect(box, Color(ice, a * 0.5))
	draw_rect(box, Color(ice, a + 0.3), false, 1.0)
	draw_line(box.position + Vector2(3, 2), box.position + Vector2(box.size.x * 0.4, box.size.y * 0.5), Color(1, 1, 1, a), 1.0)
