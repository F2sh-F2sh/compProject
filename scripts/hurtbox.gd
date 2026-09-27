class_name Hurtbox
extends Area2D

signal damage_received(amount: int)


func receive_damage(amount: int) -> void:
	if amount <= 0:
		return

	damage_received.emit(amount)
