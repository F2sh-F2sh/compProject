class_name RuneBeam
extends Node2D

## Light Beam: the dungeon's own LightBeam, shot from the cube's face. It
## powers crystals and stills watchers exactly like a brazier's beam. Without
## Bounce a mirror stops it; with Bounce it reflects (up to six times).

var cube: RuneCube
var beam: LightBeam


func setup(owner_cube: RuneCube, spell: Dictionary) -> void:
	cube = owner_cube
	var dir: Vector2 = (spell["direction"] as Vector2).normalized()
	beam = LightBeam.new()
	beam.name = "Beam"
	beam.direction = dir
	# Just outside the cube, so the beam never starts inside its own stone
	beam.origin_offset = cube.get_face_point(dir) - cube.global_position + dir * 2.0
	beam.max_length = spell["range"]
	beam.max_bounces = spell["bounces"]
	beam.reflects = spell["bounces"] > 0
	beam.color = RuneFragments.ESSENCE_COLORS[&"light"]
	# The beam traces from its parent's position: the cube
	cube.add_child(beam)
	Sfx.play("beam_on", cube.centre(), -5.0)


func region() -> Dictionary:
	return {}


func stop() -> void:
	if is_instance_valid(beam):
		beam.queue_free()
	queue_free()


func _physics_process(_delta: float) -> void:
	if is_instance_valid(beam) and beam.end_node and beam.end_node.is_in_group("gargoyle"):
		RuneJournal.note("light")
