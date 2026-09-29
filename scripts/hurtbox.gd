class_name Hurtbox
extends Area2D

<<<<<<< HEAD
## source is the hazard that dealt the hit. The receiver can ask it for
## extra behaviour, e.g. get_recovery_position() or get_knockback_velocity().
signal damage_received(amount: int, source: Node)


func receive_damage(amount: int, source: Node = null) -> void:
	if amount <= 0:
		return

	damage_received.emit(amount, source)
=======
signal damage_received(amount: int)


func receive_damage(amount: int) -> void:
	if amount <= 0:
		return

	damage_received.emit(amount)
>>>>>>> ca7ff5e18fa8e215148f3f169007eba690423f12
