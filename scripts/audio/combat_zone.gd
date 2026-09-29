@tool
class_name CombatZone
extends Area2D

## While the player is inside, the music leans into its combat layer
## (AudioDirector.set_combat). Use it where a fight happens outside a
## chapter Room marked `combat`. The node sits at the zone's top-left corner.

@export var size := Vector2(512, 448):
	set(value):
		size = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = size / 2.0
	add_child(collider)
	body_entered.connect(func(b): if b.is_in_group("player"): AudioDirector.set_combat(self, true))
	body_exited.connect(func(b): if b.is_in_group("player"): AudioDirector.set_combat(self, false))


func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		AudioDirector.set_combat(self, false)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.35, 0.3, 0.08))
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.35, 0.3, 0.6), false, 1.0)
