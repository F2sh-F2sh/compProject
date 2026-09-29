class_name MagicLight
extends RefCounted

## The single rule for magical light, used by every puzzle piece:
## - Beams (from braziers and lenses) travel in straight lines, bounce off
##   mirrors, and stop at the first solid thing they hit.
## - Auras (lit braziers with a radius, lantern wisps) reach anything within
##   their radius that has a clear line of sight to them.
## Solid things — level geometry, stone blocks, gates, frozen gargoyles —
## block both. Receivers and gargoyles react to either. Decorative torches are
## ordinary fire and never count. Nothing here reads rendered pixel brightness.

## Physics layer of solid light blockers (shared with the level geometry).
const BLOCKER_MASK := 2
## Physics layer of light-sensitive sensors: mirrors, receivers, gargoyles.
const TARGET_LAYER := 8
const AURA_GROUP := "magic_aura"


## True if any aura reaches `point` unobstructed. `exclude` lets a solid
## target (e.g. a frozen gargoyle) ignore its own body.
static func aura_reaches(world: World2D, point: Vector2, exclude: Array[RID] = []) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	for emitter in tree.get_nodes_in_group(AURA_GROUP):
		if not emitter.is_emitting():
			continue
		var origin: Vector2 = emitter.get_light_origin()
		if origin.distance_to(point) > emitter.light_radius:
			continue
		if line_is_clear(world, origin, point, exclude):
			return true
	return false


static func line_is_clear(world: World2D, from: Vector2, to: Vector2, exclude: Array[RID] = []) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, BLOCKER_MASK, exclude)
	query.collide_with_areas = false
	return world.direct_space_state.intersect_ray(query).is_empty()


## Finds the node that handles light for a collider (the collider or its parent).
static func handler_for(collider: Object) -> Node:
	var node := collider as Node
	for i in 2:
		if node == null:
			return null
		if node.has_method("reflect_beam") or node.has_method("receive_light"):
			return node
		node = node.get_parent()
	return null


## Adds a small light-sensor area on the target layer to a node.
static func add_sensor(parent: Node, radius: float, offset := Vector2.ZERO) -> Area2D:
	var sensor := Area2D.new()
	sensor.name = "LightSensor"
	sensor.collision_layer = TARGET_LAYER
	sensor.collision_mask = 0
	sensor.monitoring = false
	sensor.monitorable = true
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collider := CollisionShape2D.new()
	collider.shape = shape
	sensor.add_child(collider)
	sensor.position = offset
	parent.add_child(sensor)
	return sensor


static func unshaded() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return mat
