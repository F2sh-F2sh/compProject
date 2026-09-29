extends Area2D

## A bottomless drop (scenes/killzone.tscn, not used by the current levels):
## the player falling in is lost. Its scene wires both signals below.


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.invulnerable_time = 0.0
		body.take_damage(body.MAX_HEALTH)


func _on_timer_timeout() -> void:
	pass
