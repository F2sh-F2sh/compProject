@tool
class_name TidePool
extends Node2D

## The Great Sluice's tide: a basin of the Cistern's cold water whose surface
## rises, holds, falls and drains, over and over (or stands still, for a
## well). Echidna can't swim in it: a hit (1) and back to the nearest candle
## she has lit. Anything else sinks (WindBody.sink). Cold that reaches the
## water (an Ice Freeze rune) holds the whole tide still: its surface becomes
## a floor of ice at the height it had, solid from above, while the cold lasts
## and a moment after (rising water freezes where it first meets the cold;
## water already in the cold freezes where it is). Powered by a circuit, it
## drains for good (saved). Pixel-art water across its top
## (tools/generate_cistern_sprites.gd); the depth and the ice are drawn.
## The node sits on the basin floor's surface, centred on the basin.

signal power_changed(powered: bool)

const TILE := 64.0
const ICE_THICK := 16.0
const LINGER := 1.2
const WARN := 0.8

@export_range(1, 32) var tiles := 8:
	set(value):
		tiles = value
		queue_redraw()
## Heights of the surface above the basin floor: at the bottom of the tide
## (0 or less: the basin is dry) and at the top.
@export var low_level := -14.0
@export var high_level := 372.0
@export var rise_time := 6.0
@export var hold_high := 2.5
@export var fall_time := 5.0
@export var hold_low := 7.0
@export var phase := 0.0
## A well: the water stands at high_level and never moves (until drained).
@export var still := false
@export var damage_amount := 1
## Candles she can be put back at; the nearest lit one is used.
@export var recovery_checkpoints: Array[NodePath] = []
## Saved once it has been drained.
@export var persist_id := ""
## World heights the ice settles at when it freezes within a few px of one
## (the doorway floors, so ice there is flush with them and walkable on and off).
@export var flush_with: PackedFloat32Array = []

## The surface's height above the basin floor now.
var level := 0.0
var is_frozen := false
var drained := false
## Everything it has swallowed (for tests).
var swallowed: Array[Node] = []

var _t := 0.0
var _time := 0.0
var _frozen_left := 0.0
var _art: Node2D
var _tiles_art: Node2D
var _ice_art: Node2D
var _ice_body: StaticBody2D
var _ice_shape: CollisionShape2D
var _hurt: Area2D
var _hurt_shape: RectangleShape2D
var _hurt_collider: CollisionShape2D
var _cooldowns := {}
var _drain_from := 0.0
var _none: Array[RID] = []


func _ready() -> void:
	_t = phase
	level = high_level if still else _level_at(_t)
	_art = Node2D.new()
	_art.name = "Water"
	_art.z_index = 1
	_art.draw.connect(_draw_water)
	add_child(_art)
	_tiles_art = Node2D.new()
	_tiles_art.name = "Surface"
	_tiles_art.z_index = 1
	add_child(_tiles_art)
	for i in tiles:
		var tile := SurfaceArt.animated(_tiles_art, "cistern_water", Vector2(-get_width() / 2.0 + TILE * (i + 0.5), 54.0), 4.0, 1.0)
		tile.frame = (i * 3) % 4
	# The ice goes over the surface tiles
	_ice_art = Node2D.new()
	_ice_art.name = "IceSheet"
	_ice_art.z_index = 2
	_ice_art.draw.connect(_draw_ice)
	add_child(_ice_art)
	if Engine.is_editor_hint():
		_place_surface()
		return
	add_to_group("freezable")
	add_to_group("resettable")
	add_to_group("hazard_zone")
	_hurt = Area2D.new()
	_hurt.name = "Cold"
	_hurt.collision_layer = 0
	_hurt.collision_mask = 2
	_hurt.monitorable = false
	_hurt_shape = RectangleShape2D.new()
	_hurt_collider = CollisionShape2D.new()
	_hurt_collider.shape = _hurt_shape
	_hurt.add_child(_hurt_collider)
	add_child(_hurt)
	_ice_body = StaticBody2D.new()
	_ice_body.name = "Ice"
	_ice_body.collision_layer = 3
	_ice_body.collision_mask = 0
	_ice_body.add_to_group("world")
	_ice_body.add_to_group("ice")
	add_child(_ice_body)
	_ice_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(get_width(), ICE_THICK)
	_ice_shape.shape = rect
	_ice_shape.one_way_collision = true
	_ice_shape.disabled = true
	_ice_body.add_child(_ice_shape)
	var glow := PointLight2D.new()
	glow.texture = LightTextures.radial(256)
	glow.color = Color(0.45, 0.75, 0.95)
	glow.energy = 0.35
	glow.texture_scale = 0.8 + tiles * 0.25
	glow.shadow_enabled = false
	glow.name = "Glow"
	add_child(glow)
	if persist_id != "" and GameState.has_flag(persist_id):
		drained = true
		level = low_level
	_place_surface()


func get_width() -> float:
	return tiles * TILE


func period() -> float:
	return rise_time + hold_high + fall_time + hold_low


func _level_at(t: float) -> float:
	var p := fposmod(t, period())
	if p < hold_low:
		return low_level
	p -= hold_low
	if p < rise_time:
		return lerpf(low_level, high_level, _ease(p / rise_time))
	p -= rise_time
	if p < hold_high:
		return high_level
	p -= hold_high
	return lerpf(high_level, low_level, _ease(p / fall_time))


func _ease(k: float) -> float:
	return 0.5 - 0.5 * cos(clampf(k, 0.0, 1.0) * PI)


## The surface in world space (y).
func surface_y() -> float:
	return global_position.y - level


## True while there is no water above `y` (world): the surface is below it.
func below(y: float) -> bool:
	return surface_y() > y


## The tide is coming in (not held, not still, not drained).
func is_rising() -> bool:
	if is_frozen or still or drained:
		return false
	var p := fposmod(_t, period())
	return p >= hold_low and p < hold_low + rise_time


## The water in world space, from the surface down to the basin floor.
func water_rect() -> Rect2:
	var h := maxf(level, 0.0)
	return Rect2(global_position.x - get_width() / 2.0, global_position.y - h, get_width(), maxf(h, 1.0))


func _rect_for(lv: float) -> Rect2:
	var h := maxf(lv, 0.0)
	return Rect2(global_position.x - get_width() / 2.0, global_position.y - h, get_width(), maxf(h, 1.0))


## Cold from an Ice Freeze rune: if it reaches the water, the tide holds still.
func chill_from(field: Node) -> void:
	if drained or level <= 0.0:
		return
	if field.covers(water_rect(), _none, 16.0):
		if not is_frozen:
			_freeze()
		_frozen_left = LINGER


func _freeze() -> void:
	for s in flush_with:
		if absf(surface_y() - s) <= 6.0:
			level = global_position.y - s
			break
	is_frozen = true
	(_ice_shape.shape as RectangleShape2D).size = Vector2(get_width(), ICE_THICK)
	_ice_shape.position = Vector2(0, -level + ICE_THICK / 2.0)
	_ice_shape.set_deferred("disabled", false)
	Sfx.play("ice_freeze", Vector2(global_position.x, surface_y()), -2.0)
	ImpactFX.burst(get_parent(), Vector2(global_position.x, surface_y()), Color(0.75, 0.92, 1.0), true, 16)


func _thaw() -> void:
	is_frozen = false
	_ice_shape.set_deferred("disabled", true)
	Sfx.play("ice_crack", Vector2(global_position.x, surface_y()), -3.0)


## A circuit drains it (the Bell Well when the Great Sluice opens): for good.
func set_powered(powered: bool) -> void:
	if not powered or drained:
		return
	drained = true
	_drain_from = level
	if is_frozen:
		_thaw()
	if persist_id != "":
		GameState.set_flag(persist_id)
	Sfx.play("gate_rumble", Vector2(global_position.x, surface_y()), 0.0)
	power_changed.emit(true)


func is_powered() -> bool:
	return drained


func _physics_process(delta: float) -> void:
	_time += delta
	if Engine.is_editor_hint():
		_place_surface()
		return
	if drained:
		level = move_toward(level, low_level, maxf(_drain_from, 60.0) / 3.0 * delta)
	elif is_frozen:
		_frozen_left -= delta
		if _frozen_left <= 0.0:
			_thaw()
	elif not still:
		_t += delta
		var target := _level_at(_t)
		# Rising into the cold: it freezes where it first meets it
		if target > level + 0.25 and _caught_on_the_way(target):
			pass
		else:
			level = target
	_place_surface()
	_hurt_water(delta)
	_sink_objects()


func _caught_on_the_way(target: float) -> bool:
	var fields := get_tree().get_nodes_in_group("freeze_field")
	if fields.is_empty() or level < 0.0 and target <= 0.0:
		return false
	var lv := level
	while lv < target:
		lv = minf(lv + 3.0, target)
		if lv <= 0.0:
			continue
		for f in fields:
			if is_instance_valid(f) and f.covers(_rect_for(lv), _none, 16.0):
				level = lv
				_freeze()
				_frozen_left = LINGER
				return true
	return false


## The surface tiles and the cold area follow the level.
func _place_surface() -> void:
	if _tiles_art:
		_tiles_art.position = Vector2(0, -level)
		_tiles_art.visible = level > 0.0
		# Frozen water stops moving and goes pale
		var still_water := is_frozen and not Engine.is_editor_hint()
		_tiles_art.modulate = Color(0.78, 0.9, 1.0) if still_water else Color.WHITE
		for tile in _tiles_art.get_children():
			if tile is AnimatedSprite2D:
				tile.speed_scale = 0.0 if still_water else 1.0
	if _ice_art:
		_ice_art.queue_redraw()
	if _hurt_shape:
		var depth := maxf(level - 6.0, 0.0)
		_hurt_shape.size = Vector2(get_width() - 8.0, maxf(depth, 1.0))
		_hurt_collider.position = Vector2(0, -depth / 2.0)
		if _hurt_collider.disabled != (depth <= 0.0):
			_hurt_collider.set_deferred("disabled", depth <= 0.0)
	if _art:
		_art.queue_redraw()


func _hurt_water(delta: float) -> void:
	for hurtbox in _cooldowns.keys():
		_cooldowns[hurtbox] -= delta
		if _cooldowns[hurtbox] <= 0.0 or not is_instance_valid(hurtbox):
			_cooldowns.erase(hurtbox)
	if level <= 6.0:
		return
	for area in _hurt.get_overlapping_areas():
		if area is Hurtbox and not _cooldowns.has(area) and _really_under(area):
			_cooldowns[area] = 0.4
			Sfx.play("puddle_splash", area.global_position, -2.0, 0.1)
			ImpactFX.burst(get_parent(), Vector2(area.global_position.x, surface_y()), Color(0.6, 0.85, 1.0), false, 10)
			area.receive_damage(damage_amount, self)


# (an area's overlap list can lag a frame behind a teleport: check where it
# is; the hurtbox sits at her feet. Standing on the ice is not being in it.)
func _really_under(area: Area2D) -> bool:
	var feet := area.global_position.y
	var x := area.global_position.x
	var half := get_width() / 2.0 - 4.0
	return absf(x - global_position.x) <= half and feet > surface_y() + 8.0 and feet <= global_position.y + 6.0


func _sink_objects() -> void:
	if level <= 8.0:
		return
	var rect := water_rect().grow_individual(-4.0, -6.0, -4.0, 0.0)
	for body in get_tree().get_nodes_in_group("wind_receiver"):
		if body is WindBody and not swallowed.has(body) and not body.is_lost and not body.is_consumed:
			var b: Rect2 = body.get_bounds()
			if rect.intersects(b) and b.get_center().y > surface_y() + 4.0:
				swallowed.append(body)
				body.sink(self)


## Called by the player after a hit: the nearest lit candle of its own.
func get_recovery_position(player: Node2D) -> Vector2:
	var best: Node2D = null
	var best_d := INF
	for path in recovery_checkpoints:
		var c := get_node_or_null(path) as HazardCheckpoint
		if c and c.is_active:
			var d := c.global_position.distance_to(player.global_position)
			if d < best_d:
				best_d = d
				best = c
	if best:
		return (best as HazardCheckpoint).get_respawn_position()
	var recovery := player.get_node_or_null("HazardRecovery")
	if recovery:
		return recovery.get_fallback_position()
	return player.global_position


## World-space rectangle nothing should be set down or respawned inside.
func get_hazard_rect() -> Rect2:
	var top := global_position.y - maxf(high_level, 0.0) - 8.0
	return Rect2(global_position.x - get_width() / 2.0, top, get_width(), global_position.y - top)


func reset_state() -> void:
	swallowed.clear()
	if drained:
		return
	if is_frozen:
		_thaw()
	_frozen_left = 0.0
	_t = phase
	level = high_level if still else _level_at(_t)
	_place_surface()


func _draw_water() -> void:
	var lv := level
	if Engine.is_editor_hint():
		lv = high_level if still else (low_level + high_level) * 0.6
	if lv <= 0.0:
		return
	var w := get_width()
	var x0 := -w / 2.0
	var top := -lv
	# The body below the surface tiles (the tiles cover its top 56 px): deep
	# teal you can just see the walls through, darker the deeper it goes, with
	# slow bands of light drifting across it
	var deep_top := top + 50.0
	if deep_top < 0.0:
		var y := deep_top
		while y < 0.0:
			var h := minf(16.0, -y)
			var k := clampf((y - deep_top) / 260.0, 0.0, 1.0)
			_art.draw_rect(Rect2(x0, y, w, h), Color(0.05, 0.22, 0.3, 0.62).lerp(Color(0.02, 0.07, 0.12, 0.9), k))
			y += 16.0
		for i in 5:
			var by := deep_top + 14.0 + i * 37.0
			if by > -6.0:
				break
			var drift := fposmod(_time * (9.0 + i * 3.0) + i * 97.0, 140.0)
			var x := x0 - 140.0 + drift
			while x < x0 + w:
				var a := maxf(x, x0)
				var b := minf(x + 46.0 + i * 6.0, x0 + w)
				if b > a:
					_art.draw_rect(Rect2(a, by, b - a, 2), Color(0.45, 0.8, 0.95, 0.09))
				x += 140.0


## The ice sheet over the surface tiles while the tide is held: a pale slab
## with a bright rim and cracks, flickering in its last moment.
func _draw_ice() -> void:
	if not is_frozen or level <= 0.0:
		return
	var w := get_width()
	var x0 := -w / 2.0
	var top := -level
	var a := 1.0
	if _frozen_left < WARN and int(_time * 9.0) % 2 == 0:
		a = 0.5
	_ice_art.draw_rect(Rect2(x0, top, w, minf(level, ICE_THICK)), Color(0.62, 0.82, 0.96, 0.82 * a))
	_ice_art.draw_rect(Rect2(x0, top, w, 3), Color(0.92, 0.98, 1.0, a))
	_ice_art.draw_rect(Rect2(x0, top + ICE_THICK, w, 2), Color(0.4, 0.62, 0.82, 0.6 * a))
	var x := x0 + 10.0
	var k := 0
	while x < x0 + w - 12.0:
		_ice_art.draw_line(Vector2(x, top + 4), Vector2(x + 7 + (k % 2) * 4, top + 13), Color(1, 1, 1, 0.45 * a), 1.0)
		x += 37.0 + (k % 3) * 9.0
		k += 1
