@tool
class_name ReverbZone
extends Area2D

## A region of the dungeon with its own acoustics. Any positional sound that
## starts inside it (footfalls, spells, gates, creatures) plays through one
## of the reverb buses set up by Settings, so it echoes like the space it
## is in. Uses Godot's Area2D audio bus override: Sfx's players listen for
## areas on AUDIO_LAYER only, so zones never interfere with gameplay.
## The node sits at the zone's top-left corner.

enum Acoustics { CORRIDOR, HALL, CAVERN }

## Physics layer 6, used only by audio zones.
const AUDIO_LAYER := 1 << 5
const BUSES := ["ReverbCorridor", "ReverbHall", "ReverbCavern"]

@export var acoustics: Acoustics = Acoustics.CORRIDOR:
	set(value):
		acoustics = value
		queue_redraw()
@export var size := Vector2(1024, 448):
	set(value):
		size = value
		queue_redraw()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	collision_layer = AUDIO_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	audio_bus_override = true
	audio_bus_name = BUSES[acoustics]
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = size / 2.0
	add_child(collider)


func _draw() -> void:
	if Engine.is_editor_hint():
		var c: Color = [Color(0.4, 0.8, 1.0), Color(0.6, 0.6, 1.0), Color(0.8, 0.5, 1.0)][acoustics]
		draw_rect(Rect2(Vector2.ZERO, size), Color(c, 0.08))
		draw_rect(Rect2(Vector2.ZERO, size), Color(c, 0.5), false, 1.0)
