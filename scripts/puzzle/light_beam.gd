class_name LightBeam
extends Node2D

## A straight beam of magical light. Each physics frame it traces its path:
## it reflects off mirrors (up to max_bounces, so it can never loop forever),
## powers receivers and freezes gargoyles it reaches, and stops at the first
## solid blocker. The drawn line is exactly the traced path.

@export var direction := Vector2.RIGHT
## Where the beam starts, relative to the node that owns it.
@export var origin_offset := Vector2.ZERO
@export var emitting := true
@export var max_length := 1600.0
@export var max_bounces := 8
@export var color := Color(0.55, 0.8, 1.0)

var path := PackedVector2Array()
## What the beam ended on this frame (a receiver, gargoyle, blocker or null).
var end_node: Node = null

var _core: Line2D
var _halo: Line2D
var _end_light: PointLight2D
var _start_light: PointLight2D
var _sparks: CPUParticles2D


func _ready() -> void:
	# The beam draws in world coordinates, independent of its parent's transform
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_index = 2
	_halo = _line(8.0, Color(color, 0.28))
	_core = _line(2.0, Color(color.lightened(0.5), 0.95))
	_start_light = _light(0.9)
	_end_light = _light(1.1)
	_sparks = CPUParticles2D.new()
	_sparks.amount = 10
	_sparks.lifetime = 0.35
	_sparks.spread = 180.0
	_sparks.gravity = Vector2.ZERO
	_sparks.initial_velocity_min = 15.0
	_sparks.initial_velocity_max = 35.0
	_sparks.scale_amount_min = 1.0
	_sparks.scale_amount_max = 2.0
	_sparks.color = color.lightened(0.4)
	_sparks.material = MagicLight.unshaded()
	add_child(_sparks)


func _line(width: float, c: Color) -> Line2D:
	var line := Line2D.new()
	line.width = width
	line.default_color = c
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.material = MagicLight.unshaded()
	add_child(line)
	return line


func _light(energy: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = LightTextures.radial(128)
	l.color = color
	l.energy = energy
	add_child(l)
	return l


func _physics_process(_delta: float) -> void:
	if not emitting or not get_parent().is_inside_tree():
		_set_visible(false)
		path = PackedVector2Array()
		end_node = null
		return
	_trace()
	_set_visible(true)
	_core.points = path
	_halo.points = path
	_start_light.global_position = path[0]
	_end_light.global_position = path[path.size() - 1]
	_sparks.global_position = path[path.size() - 1]
	_sparks.emitting = end_node != null


func _set_visible(on: bool) -> void:
	_core.visible = on
	_halo.visible = on
	_start_light.enabled = on
	_end_light.enabled = on
	if not on:
		_sparks.emitting = false


func _trace() -> void:
	var space: PhysicsDirectSpaceState2D = (get_parent() as Node2D).get_world_2d().direct_space_state
	var origin: Vector2 = get_parent().global_position + origin_offset
	var dir := direction.normalized()
	var remaining := max_length
	path = PackedVector2Array([origin])
	end_node = null
	var exclude: Array[RID] = []
	for bounce in max_bounces + 1:
		var hit := _cast(space, origin, dir, remaining, exclude)
		if hit.is_empty():
			path.append(origin + dir * remaining)
			return
		var point: Vector2 = hit["position"]
		var handler := MagicLight.handler_for(hit["collider"])
		if handler and handler.has_method("reflect_beam"):
			# Bounce from the mirror's centre so the path stays on the grid
			var centre: Vector2 = handler.global_position
			path.append(centre)
			var bounced: Vector2 = handler.reflect_beam(dir)
			if bounced == Vector2.ZERO:
				end_node = handler
				return
			remaining -= origin.distance_to(centre)
			origin = centre
			dir = bounced
			exclude = [hit["rid"]]
			continue
		path.append(point)
		end_node = handler if handler else hit["collider"]
		if handler and handler.has_method("receive_light"):
			handler.receive_light(self)
		return


# Nearest of: a solid blocker, or a light-sensitive sensor
func _cast(space: PhysicsDirectSpaceState2D, from: Vector2, dir: Vector2, length: float, exclude: Array[RID]) -> Dictionary:
	var to := from + dir * length
	var solid := PhysicsRayQueryParameters2D.create(from, to, MagicLight.BLOCKER_MASK, exclude)
	solid.collide_with_areas = false
	var sensor := PhysicsRayQueryParameters2D.create(from, to, MagicLight.TARGET_LAYER, exclude)
	sensor.collide_with_bodies = false
	sensor.collide_with_areas = true
	var a := space.intersect_ray(solid)
	var b := space.intersect_ray(sensor)
	if a.is_empty():
		return b
	if b.is_empty():
		return a
	return a if from.distance_to(a["position"]) <= from.distance_to(b["position"]) else b
