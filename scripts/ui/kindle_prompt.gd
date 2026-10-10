class_name KindlePrompt
extends Node2D

## Inert compatibility node for older scenes. Mana reload has no flame prompt.
func _ready() -> void:
	queue_free()

func shown_text() -> String:
	return ""
