class_name RuneGlow
extends Node2D

## Light Glow: a pool of holy light round the cube. It is a magical aura
## (MagicLight): anything within `light_radius` that has a clear line to the
## cube counts as lit, so watchers inside it turn to stone and crystals
## inside it are powered, the same as a lit brazier's aura.

var cube: RuneCube
var light_radius := 104.0
var _light: PointLight2D
var _time := 0.0


func setup(owner_cube: RuneCube, spell: Dictionary) -> void:
	cube = owner_cube
	light_radius = spell["radius"]
	add_to_group(MagicLight.AURA_GROUP)
	top_level = true
	global_transform = Transform2D.IDENTITY
	material = MagicLight.unshaded()
	z_index = 2
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = RuneFragments.ESSENCE_COLORS[&"light"]
	_light.energy = 1.1
	_light.texture_scale = light_radius / 110.0
	_light.global_position = cube.centre()
	add_child(_light)
	Sfx.play("beam_on", cube.centre(), -5.0)


func _physics_process(_delta: float) -> void:
	for watcher in get_tree().get_nodes_in_group("gargoyle"):
		if watcher.get("is_frozen") == true and watcher.global_position.distance_to(cube.centre()) <= light_radius:
			RuneJournal.note("light")


func is_emitting() -> bool:
	return is_instance_valid(cube) and cube.is_active


func get_light_origin() -> Vector2:
	return cube.centre()


func stop() -> void:
	remove_from_group(MagicLight.AURA_GROUP)
	queue_free()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var c := cube.centre()
	var col: Color = RuneFragments.ESSENCE_COLORS[&"light"]
	draw_arc(c, light_radius, 0.0, TAU, 56, Color(col, 0.35 + 0.1 * sin(_time * 2.0)), 1.0)
	draw_circle(c, light_radius, Color(col, 0.04))
