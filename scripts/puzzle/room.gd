@tool
class_name Room
extends Node2D

## One puzzle room: its camera area, a title card, a safe entry point, and
## everything inside it that can be reset. Children opt into resetting by
## joining the "resettable" group and implementing reset_state(). Resetting
## returns them to their starting arrangement; doing it twice is the same as
## doing it once. Health is never restored by a reset.

@export var room_id := ""
@export var title := ""
## Camera area for this room, in world coordinates.
@export var bounds := Rect2(0, 0, 1152, 448):
	set(value):
		bounds = value
		queue_redraw()
## Where the player is placed by "Reset Room".
@export var entry_spawn := Vector2.ZERO:
	set(value):
		entry_spawn = value
		queue_redraw()
## A room with something to fight: the music leans into its combat layer
## while the player is here.
@export var combat := false

## A warding circle: while here, the player's mana can't rise above this
## (0 = no limit). Used by rune-cube rooms that are about budgeting.
@export var mana_limit := 0

@export_group("Guidance")
## Set on the first room of an act: "I", "II"... with its name.
@export var act := ""
@export var act_title := ""
@export var act_subtitle := ""
## What the player is here to do, stated as a goal, never as the solution.
@export var objective := ""
## Lore page ids found in this room (for the map).
@export var page_ids: PackedStringArray = []

@export_group("Mood")
## The room's colour: the post pass's highlight tint and mist colour ease to
## these while the player is here (cold for the cells, amber for the works...).
@export var mood_highlight := Color(1.02, 1.04, 1.06)
@export var mood_fog := Color(0.27, 0.36, 0.48)

var visited := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("room")


func contains(point: Vector2) -> bool:
	return bounds.has_point(point)


## The room's objective steps (ObjectiveStep children), in order.
func get_steps() -> Array:
	return get_children().filter(func(n): return n is ObjectiveStep)


## True once every required step has been done.
func is_cleared() -> bool:
	var required := get_steps().filter(func(s): return not s.optional)
	return not required.is_empty() and required.all(func(s): return s.done)


func reset() -> void:
	for step in get_steps():
		step.reset()
	for node in _resettables():
		node.reset_state()
	# Spells and bolts in flight would otherwise re-trigger things after a reset
	for group in ["fireball", "arcane_bolt"]:
		for projectile in get_tree().get_nodes_in_group(group):
			if bounds.has_point(projectile.global_position):
				projectile.queue_free()


func _resettables() -> Array[Node]:
	var result: Array[Node] = []
	for node in find_children("*", "", true, false):
		if node.is_in_group("resettable") and node.has_method("reset_state"):
			result.append(node)
	return result


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var local := Rect2(to_local(bounds.position), bounds.size)
	draw_rect(local, Color(0.5, 0.8, 1.0, 0.6), false, 2.0)
	draw_circle(to_local(entry_spawn), 6.0, Color(0.4, 1.0, 0.5, 0.8))
