@tool
class_name SlagPool
extends Area2D

## A trench of molten slag in the Kilnworks: pixel art that bubbles, a warm
## glow and rising embers. For Echidna it works like floor spikes: a hit (2)
## and back to the candle at its edge. Anything else that falls in is lost: a
## wind-moved object (the coal cart, a crate, a stone) burns or sinks (see
## WindBody.burn), and a room that needed it says it must be reset. Rune
## cubes can't be set down over it (it is a hazard zone).
## The node sits on the trench floor's surface, centred on the trench.

const TILE := 64.0
const DEPTH := 30.0

@export_range(1, 16) var tiles := 2:
	set(value):
		tiles = value
		_rebuild()
@export var damage_amount := 2
## The safe spot she returns to after a non-lethal hit.
@export var recovery_checkpoint: HazardCheckpoint
@export var rehit_delay := 0.25

var _art: Node2D
var _cooldowns := {}
var _sink: Area2D
## Everything it has swallowed (for tests).
var swallowed: Array[Node] = []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_rebuild()
	if Engine.is_editor_hint():
		return
	add_to_group("hazard_zone")
	add_to_group("resettable")
	# Loose objects (layer 1) that drop in
	_sink = Area2D.new()
	_sink.name = "Sink"
	_sink.collision_layer = 0
	_sink.collision_mask = 1
	_sink.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(get_width() - 8.0, 20.0)
	shape.shape = rect
	shape.position = Vector2(0, -10)
	_sink.add_child(shape)
	add_child(_sink)
	var glow := PointLight2D.new()
	glow.texture = LightTextures.radial(256)
	glow.color = Color(1.0, 0.5, 0.2)
	glow.energy = 0.9
	glow.texture_scale = 0.6 + tiles * 0.35
	glow.position = Vector2(0, -20)
	glow.shadow_enabled = false
	add_child(glow)
	var embers := GlowFX.embers(Color(1.0, 0.55, 0.22), 6 + tiles * 3, 70.0, get_width() * 0.45, 1.8)
	embers.position = Vector2(0, -8)
	add_child(embers)


func get_width() -> float:
	return tiles * TILE


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _art:
		_art.queue_free()
	_art = Node2D.new()
	_art.name = "Art"
	_art.z_index = 1
	add_child(_art)
	for i in tiles:
		var tile := SurfaceArt.animated(_art, "slag", Vector2(-get_width() / 2.0 + TILE * (i + 0.5), 4.0), 5.0, 1.0)
		tile.frame = i % 4
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		tile.material = mat
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(get_width() - 8.0, DEPTH)
	shape.shape = rect
	shape.position = Vector2(0, -DEPTH / 2.0)
	add_child(shape)


## Called by the player after a non-lethal hit.
func get_recovery_position(player: Node2D) -> Vector2:
	if recovery_checkpoint and recovery_checkpoint.is_active:
		return recovery_checkpoint.get_respawn_position()
	var recovery := player.get_node_or_null("HazardRecovery")
	if recovery:
		return recovery.get_fallback_position()
	return player.global_position


## World-space rectangle nothing should be respawned or set down inside.
func get_hazard_rect() -> Rect2:
	var w := get_width()
	return Rect2(global_position + Vector2(-w / 2.0, -64.0), Vector2(w, 64.0))


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for hurtbox in _cooldowns.keys():
		_cooldowns[hurtbox] -= delta
		if _cooldowns[hurtbox] <= 0.0 or not is_instance_valid(hurtbox):
			_cooldowns.erase(hurtbox)
	for area in get_overlapping_areas():
		if area is Hurtbox and not _cooldowns.has(area):
			_cooldowns[area] = rehit_delay
			area.receive_damage(damage_amount, self)
	# Loose objects that have dropped in burn (checked against where they
	# really are: the frame after a reset puts one back somewhere else, the
	# sink can still report it at the spot it was taken from)
	for body in _sink.get_overlapping_bodies():
		if body.has_method("burn") and not swallowed.has(body) and _really_in(body):
			swallowed.append(body)
			body.burn(self)


## The sink in the world: the bottom 20 px of the trench.
func _sink_rect() -> Rect2:
	var w := get_width() - 8.0
	return Rect2(global_position + Vector2(-w / 2.0, -20.0), Vector2(w, 20.0))


func _really_in(body: Node) -> bool:
	if body.has_method("get_bounds"):
		return (body.get_bounds() as Rect2).intersects(_sink_rect())
	return body is Node2D and _sink_rect().grow(16.0).has_point((body as Node2D).global_position)


func reset_state() -> void:
	swallowed.clear()
