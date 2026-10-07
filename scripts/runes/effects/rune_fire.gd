class_name RuneFire
extends Node2D

## Fire Projectile: launches the game's own fireball from the cube's face
## (so it lights braziers, burns vines and melts ice exactly as the player's
## does). Split fires three in a fan; Explode makes each one burst where it
## lands, reaching anything within `explode_radius` that it can see
## (creatures take damage, braziers light, fire-reactive things react).

const FIREBALL := preload("res://scenes/FireBall.tscn")
const SPEED := 420.0
const RANGE := 560.0
const FAN := 0.26

var cube: RuneCube
var bolts: Array[Node] = []


func setup(owner_cube: RuneCube, spell: Dictionary) -> void:
	cube = owner_cube
	var dir: Vector2 = (spell["direction"] as Vector2).normalized()
	var dirs := [dir] if int(spell["count"]) == 1 else [dir.rotated(-FAN), dir, dir.rotated(FAN)]
	var host := cube.get_parent()
	for d in dirs:
		var bolt := FIREBALL.instantiate()
		bolt.direction = d
		bolt.speed = SPEED
		bolt.max_distance = RANGE
		bolt.global_position = cube.get_face_point(d) + d * 14.0
		bolt.add_to_group("rune_fireball")
		host.add_child(bolt)
		bolts.append(bolt)
		var radius: float = spell["explode_radius"]
		if radius > 0.0:
			bolt.set_meta(&"explode_radius", radius)
			bolt.tree_exiting.connect(_blast.bind(bolt, radius))
	Sfx.play("spell_cast", cube.centre(), -4.0)
	RuneJournal.note("fire")


# Stays until its bolts are gone (an Explode blast needs it)
func _process(_delta: float) -> void:
	if bolts.all(func(b): return not is_instance_valid(b)):
		queue_free()


static func blast_at(tree: SceneTree, world: World2D, at: Vector2, radius: float) -> void:
	ImpactFX.burst(tree.current_scene, at, Color(1.0, 0.55, 0.25), true, 24)
	Sfx.play("fire_blast", at, -2.0)
	for node in tree.get_nodes_in_group("enemy") + tree.get_nodes_in_group("fire_reactive") + tree.get_nodes_in_group("aim_target"):
		if not node is Node2D:
			continue
		var p: Vector2 = node.global_position + Vector2(0, -12)
		if p.distance_to(at) > radius:
			continue
		var exclude: Array[RID] = []
		if node is CollisionObject2D:
			exclude.append(node.get_rid())
		if not MagicLight.line_is_clear(world, at, p, exclude):
			continue
		if node.is_in_group("enemy") and node.has_method("take_damage"):
			node.take_damage(6)
		elif node.has_method("on_fire"):
			node.on_fire()
		elif node.has_method("ignite"):
			node.ignite()


func _blast(bolt: Node2D, radius: float) -> void:
	# Only when it really burst (not when the level is being unloaded)
	if not is_instance_valid(bolt) or not bolt.is_inside_tree() or bolt.get("_exploded") != true:
		return
	blast_at(bolt.get_tree(), bolt.get_world_2d(), bolt.global_position, radius)


## One-off effects play out by themselves; switching the cube off leaves them be.
func stop() -> void:
	pass
