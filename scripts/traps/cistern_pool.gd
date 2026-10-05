@tool
class_name CisternPool
extends Area2D

## A pool of the Drowned Cistern's black water, too cold to swim in. For
## Echidna it works like floor spikes: a hit (1, the cold) and back to the
## candle at its edge. Anything else that falls in sinks and is lost until the
## room is reset (see WindBody.sink). Cold that reaches its surface (an Ice
## Freeze rune) freezes it, a strip at a time, into a floor of ice level with
## the banks: it holds while the cold lasts and LINGER seconds after,
## flickering for the last WARN of them, then gives way. Rune cubes can't be
## set down over it (it is a hazard zone, frozen or not).
## Pixel-art water (tools/generate_cistern_sprites.gd); the ice is drawn,
## like the Ice Bridge's.
## The node sits on the trench floor's surface, centred on the trench (a pit
## one tile deep: its rim, the floor beside it, is TILE above the node).

const TILE := 64.0
## Its surface, this far above the trench floor (12 px below the rim).
const SURFACE := 52.0
## The ice: its top level with the rim, this thick.
const ICE_THICK := 16.0
## Freezes in strips this wide.
const SEGMENT := 16.0
## How long ice holds after the cold has gone, and how long it flickers first.
const LINGER := 1.2
const WARN := 0.8

@export_range(1, 16) var tiles := 2:
	set(value):
		tiles = value
		_rebuild()
@export var damage_amount := 1
## The safe spot she returns to after falling in.
@export var recovery_checkpoint: HazardCheckpoint
@export var rehit_delay := 0.4

## Seconds of ice left on each strip, west to east (0: open water).
var frozen_left := PackedFloat32Array()
## Everything it has swallowed (for tests).
var swallowed: Array[Node] = []

var _art: Node2D
var _ice_art: Node2D
var _ice_body: StaticBody2D
var _sink: Area2D
var _cooldowns := {}
var _ice_key := ""
var _time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
	_rebuild()
	if Engine.is_editor_hint():
		return
	add_to_group("hazard_zone")
	add_to_group("resettable")
	add_to_group("freezable")
	frozen_left.resize(_segments())
	frozen_left.fill(0.0)
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
	# The ice: one shape per frozen run, rebuilt when the frozen strips change
	_ice_body = StaticBody2D.new()
	_ice_body.name = "Ice"
	_ice_body.collision_layer = 3
	_ice_body.collision_mask = 0
	_ice_body.add_to_group("world")
	_ice_body.add_to_group("ice")
	add_child(_ice_body)
	_ice_art = Node2D.new()
	_ice_art.name = "IceArt"
	_ice_art.z_index = 2
	_ice_art.material = MagicLight.unshaded()
	_ice_art.draw.connect(_draw_ice)
	add_child(_ice_art)
	var glow := PointLight2D.new()
	glow.texture = LightTextures.radial(256)
	glow.color = Color(0.45, 0.75, 0.95)
	glow.energy = 0.3
	glow.texture_scale = 0.5 + tiles * 0.3
	glow.position = Vector2(0, -SURFACE)
	glow.shadow_enabled = false
	add_child(glow)


func get_width() -> float:
	return tiles * TILE


func _segments() -> int:
	return int(get_width() / SEGMENT)


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
		var tile := SurfaceArt.animated(_art, "cistern_water", Vector2(-get_width() / 2.0 + TILE * (i + 0.5), 2.0), 4.0, 1.0)
		tile.frame = (i * 3) % 4
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	# Where it hurts: the water below its surface
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var depth := SURFACE - 6.0
	rect.size = Vector2(get_width() - 8.0, depth)
	shape.shape = rect
	shape.position = Vector2(0, -depth / 2.0)
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
	return Rect2(global_position + Vector2(-w / 2.0, -TILE), Vector2(w, TILE))


## True if the strip under world x is ice now.
func is_frozen_at(x: float) -> bool:
	var i := int(floor((x - (global_position.x - get_width() / 2.0)) / SEGMENT))
	return i >= 0 and i < frozen_left.size() and frozen_left[i] > 0.0


## How much of it is ice, 0 to 1 (for tests and steps).
func frozen_fraction() -> float:
	if frozen_left.is_empty():
		return 0.0
	var n := 0
	for v in frozen_left:
		if v > 0.0:
			n += 1
	return float(n) / frozen_left.size()


## Cold from an Ice Freeze rune: every strip of surface it reaches freezes (or
## stays frozen) for LINGER more seconds.
func chill_from(field: Node) -> void:
	var left := global_position.x - get_width() / 2.0
	var top := global_position.y - SURFACE - 4.0
	var newly := false
	for i in frozen_left.size():
		if field.covers(Rect2(left + i * SEGMENT, top, SEGMENT, 10.0)):
			if frozen_left[i] <= 0.0:
				newly = true
			frozen_left[i] = LINGER
	if newly:
		Sfx.play("ice_form", global_position + Vector2(0, -SURFACE), -4.0)
		RuneJournal.note("chill")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	var key := ""
	var thawed := false
	for i in frozen_left.size():
		if frozen_left[i] > 0.0:
			frozen_left[i] = maxf(frozen_left[i] - delta, 0.0)
			if frozen_left[i] <= 0.0:
				thawed = true
		key += "1" if frozen_left[i] > 0.0 else "0"
	if thawed:
		Sfx.play("ice_crack", global_position + Vector2(0, -SURFACE), -6.0)
	if key != _ice_key:
		_ice_key = key
		_rebuild_ice()
	_ice_art.queue_redraw()
	for hurtbox in _cooldowns.keys():
		_cooldowns[hurtbox] -= delta
		if _cooldowns[hurtbox] <= 0.0 or not is_instance_valid(hurtbox):
			_cooldowns.erase(hurtbox)
	for area in get_overlapping_areas():
		if area is Hurtbox and not _cooldowns.has(area):
			_cooldowns[area] = rehit_delay
			Sfx.play("puddle_splash", area.global_position, -2.0, 0.1)
			ImpactFX.burst(get_parent(), Vector2(area.global_position.x, global_position.y - SURFACE), Color(0.6, 0.85, 1.0), false, 10)
			area.receive_damage(damage_amount, self)
	# Loose objects that have dropped in sink (checked against where they
	# really are: a reset may have just put one back somewhere else)
	for body in _sink.get_overlapping_bodies():
		if not swallowed.has(body) and _really_in(body):
			if body.has_method("sink"):
				swallowed.append(body)
				body.sink(self)
			elif body.has_method("burn"):
				swallowed.append(body)
				body.burn(self)


func _sink_rect() -> Rect2:
	var w := get_width() - 8.0
	return Rect2(global_position + Vector2(-w / 2.0, -20.0), Vector2(w, 20.0))


func _really_in(body: Node) -> bool:
	if body.has_method("get_bounds"):
		return (body.get_bounds() as Rect2).intersects(_sink_rect())
	return body is Node2D and _sink_rect().grow(16.0).has_point((body as Node2D).global_position)


## One collision shape per run of frozen strips, its top level with the rim.
func _rebuild_ice() -> void:
	for child in _ice_body.get_children():
		_ice_body.remove_child(child)
		child.queue_free()
	var left := -get_width() / 2.0
	var i := 0
	while i < frozen_left.size():
		if frozen_left[i] <= 0.0:
			i += 1
			continue
		var j := i
		while j < frozen_left.size() and frozen_left[j] > 0.0:
			j += 1
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2((j - i) * SEGMENT, ICE_THICK)
		shape.shape = rect
		shape.position = Vector2(left + (i + j) * SEGMENT / 2.0, -TILE + ICE_THICK / 2.0)
		shape.one_way_collision = true
		_ice_body.add_child(shape)
		i = j


func reset_state() -> void:
	swallowed.clear()
	frozen_left.fill(0.0)


func _draw_ice() -> void:
	var left := -get_width() / 2.0
	var ice := Color(0.7, 0.9, 1.0)
	for i in frozen_left.size():
		var t := frozen_left[i]
		if t <= 0.0:
			continue
		var a := 0.9
		if t < WARN and int(_time * 9.0) % 2 == 0:
			a = 0.4
		var x := left + i * SEGMENT
		var top := -TILE
		_ice_art.draw_rect(Rect2(x, top, SEGMENT, ICE_THICK + 4.0), Color(0.42, 0.66, 0.88, a * 0.85))
		_ice_art.draw_rect(Rect2(x, top, SEGMENT, 2), Color(ice, a))
		_ice_art.draw_rect(Rect2(x, top + ICE_THICK + 2.0, SEGMENT, 2), Color(0.85, 0.95, 1.0, a * 0.5))
		# facets, a different slant on each strip
		var k := (i * 7) % 5
		_ice_art.draw_line(Vector2(x + 2 + k, top + 4), Vector2(x + 8 + k, top + 11), Color(1, 1, 1, a * 0.45), 1.0)
		if i % 3 == 0:
			_ice_art.draw_line(Vector2(x + 12, top + 5), Vector2(x + 9, top + 14), Color(1, 1, 1, a * 0.3), 1.0)
