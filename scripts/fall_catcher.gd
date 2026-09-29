@tool
class_name FallCatcher
extends Area2D

## A shallow pit that catches a missed jump: falling in fades the player back
## to the last safe ground before it, with no damage (the same recovery as a
## spike hit). It teaches that a jump matters without punishing a beginner,
## and the player can never be stranded in it. The node marks the top-left of
## the catch area; its size should cover the pit below the floor line.

@export var size := Vector2(128, 48):
	set(value):
		size = value
		queue_redraw()

var _shape: CollisionShape2D


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	add_to_group("hazard_zone")
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape = CollisionShape2D.new()
	_shape.shape = rect
	_shape.position = size / 2.0
	add_child(_shape)
	body_entered.connect(_on_body_entered)


## The pit's footprint, widened up to the floor line, so the ground right at
## its edges is never remembered as a safe place to return to.
func get_hazard_rect() -> Rect2:
	return Rect2(global_position - Vector2(0, 40), size + Vector2(0, 40))


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or body.is_dead:
		return
	var recovery: HazardRecovery = body.get_node_or_null("HazardRecovery")
	if recovery == null or recovery.is_active():
		return
	Sfx.play("land", body.global_position, -8.0)
	recovery.begin(recovery.get_fallback_position())


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.6, 1.0, 0.25))
