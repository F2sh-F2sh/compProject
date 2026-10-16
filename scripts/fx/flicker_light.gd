class_name FlickerLight
extends PointLight2D

## A light that breathes and flickers like a flame. Each instance gets its own
## random phase so rows of torches don't pulse in sync.

@export var base_energy := 1.1
@export_range(0.0, 1.0) var flicker_amount := 0.18
@export var flicker_speed := 1.0
## Slight size pulse, as a fraction of texture_scale.
@export_range(0.0, 0.3) var size_pulse := 0.04

var _base_scale := 1.0
var _time := 0.0
var _seed := 0.0


func _ready() -> void:
	_base_scale = texture_scale
	_seed = randf() * 100.0


func _process(delta: float) -> void:
	_time += delta * flicker_speed
	var t := _time + _seed
	# Layered sines read as organic flame movement without a noise texture
	var wave := sin(t * 7.3) * 0.5 + sin(t * 13.1) * 0.3 + sin(t * 29.7) * 0.2
	energy = base_energy * (1.0 + wave * flicker_amount)
	texture_scale = _base_scale * (1.0 + sin(t * 5.1) * size_pulse)
