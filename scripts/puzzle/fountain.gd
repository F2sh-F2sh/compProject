@tool
class_name Fountain
extends Node2D

## A fountain in the Drowned Cistern: a jet of water that leaps from its
## nozzle, holds, falls back and rests, over and over. It is only water:
## nothing stands on it. Cold that reaches any part of it (an Ice Freeze rune)
## holds it still as a pillar of ice at the height it had, and a jet that rises
## into the cold freezes where it first meets it. The pillar is solid from
## above (she can jump up through it and land on top) while the cold lasts and
## LINGER seconds after, flickering for the last WARN of them; then it is water
## again and carries on from where it was. The jet is drawn (an effect); the
## basin and spout are a pixel sprite (tools/generate_cistern_sprites.gd).
## The node sits on the floor at the nozzle's centre.

const WIDTH := 28.0
const LINGER := 1.2
const WARN := 0.8
## Where the jet leaves the spout, above the floor.
const MOUTH := 12.0

## Its height at the top of a leap, above the floor.
@export var max_height := 120.0:
	set(value):
		max_height = value
		queue_redraw()
## Its height while it rests between leaps.
@export var rest_height := 14.0
@export var rest_time := 0.6
@export var rise_time := 0.35
@export var hold_time := 2.0
@export var fall_time := 0.45
## Seconds into its cycle at the start, so neighbours don't leap together.
@export var phase := 0.0

## Its height now, above the floor.
var height := 0.0
var is_frozen := false
var _frozen_left := 0.0
var _t := 0.0
var _time := 0.0
var _body: StaticBody2D
var _shape: CollisionShape2D
var _jet: Node2D
var _drops: Array[Vector3] = []


func _ready() -> void:
	_t = phase
	height = _height_at(_t)
	_jet = Node2D.new()
	_jet.name = "Jet"
	_jet.z_index = 1
	_jet.draw.connect(_draw_jet)
	add_child(_jet)
	var nozzle := SurfaceArt.sprite(self, "fountain_nozzle", Vector2.ZERO, 1.0)
	nozzle.z_index = 2
	if Engine.is_editor_hint():
		return
	_jet.material = MagicLight.unshaded()
	add_to_group("freezable")
	add_to_group("resettable")
	_body = StaticBody2D.new()
	_body.name = "Pillar"
	_body.collision_layer = 3
	_body.collision_mask = 0
	_body.add_to_group("world")
	_body.add_to_group("ice")
	add_child(_body)
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	_shape.one_way_collision = true
	_shape.disabled = true
	_body.add_child(_shape)
	var r := RandomNumberGenerator.new()
	r.seed = hash(name) + int(phase * 100.0)
	for i in 10:
		_drops.append(Vector3(r.randf(), r.randf(), r.randf()))


func period() -> float:
	return rest_time + rise_time + hold_time + fall_time


## The jet's height `t` seconds into its cycle.
func _height_at(t: float) -> float:
	var p := fposmod(t, period())
	if p < rest_time:
		return rest_height
	p -= rest_time
	if p < rise_time:
		return lerpf(rest_height, max_height, _ease(p / rise_time))
	p -= rise_time
	if p < hold_time:
		return max_height
	p -= hold_time
	return lerpf(max_height, rest_height, _ease(p / fall_time))


func _ease(k: float) -> float:
	return 0.5 - 0.5 * cos(clampf(k, 0.0, 1.0) * PI)


## The water (or ice) in world space, from the top of the jet to the spout.
func column_rect() -> Rect2:
	return _rect_for(height)


func _rect_for(h: float) -> Rect2:
	return Rect2(global_position.x - WIDTH / 2.0, global_position.y - h, WIDTH, maxf(h - MOUTH, 2.0))


## The top of the pillar, in world space (y), while it is frozen.
func top_y() -> float:
	return global_position.y - height


## Cold from an Ice Freeze rune: if it reaches the jet, the jet holds still.
func chill_from(field: Node) -> void:
	var own: Array[RID] = [_body.get_rid()]
	if field.covers(column_rect(), own):
		if not is_frozen:
			_freeze()
		_frozen_left = LINGER


func _freeze() -> void:
	is_frozen = true
	var rect := _shape.shape as RectangleShape2D
	rect.size = Vector2(WIDTH + 4.0, maxf(height - MOUTH, 4.0))
	_shape.position = Vector2(0, -height + rect.size.y / 2.0)
	_shape.set_deferred("disabled", false)
	Sfx.play("ice_freeze", global_position + Vector2(0, -height), -6.0)
	ImpactFX.burst(get_parent(), global_position + Vector2(0, -height), Color(0.75, 0.92, 1.0), true, 6)


func _thaw() -> void:
	is_frozen = false
	_shape.set_deferred("disabled", true)
	Sfx.play("ice_crack", global_position + Vector2(0, -height), -8.0)
	ImpactFX.burst(get_parent(), global_position + Vector2(0, -height * 0.5), Color(0.7, 0.9, 1.0), true, 8)


func _physics_process(delta: float) -> void:
	_time += delta
	if Engine.is_editor_hint():
		_jet.queue_redraw()
		return
	if is_frozen:
		_frozen_left -= delta
		if _frozen_left <= 0.0:
			_thaw()
	else:
		_t += delta
		var target := _height_at(_t)
		# Leaping up into the cold: it freezes where it first meets it (checked
		# a few px at a time, so a fast leap can't overshoot)
		if target > height + 0.5 and _caught_on_the_way(target):
			pass
		else:
			height = target
	_jet.queue_redraw()


func _caught_on_the_way(target: float) -> bool:
	var fields := get_tree().get_nodes_in_group("freeze_field")
	if fields.is_empty():
		return false
	var own: Array[RID] = [_body.get_rid()]
	var h := height
	while h < target:
		h = minf(h + 3.0, target)
		for f in fields:
			if is_instance_valid(f) and f.covers(_rect_for(h), own):
				height = h
				_freeze()
				_frozen_left = LINGER
				return true
	return false


func reset_state() -> void:
	if is_frozen:
		is_frozen = false
		_shape.set_deferred("disabled", true)
	_frozen_left = 0.0
	_t = phase
	height = _height_at(_t)


func _draw_jet() -> void:
	var h := height if not Engine.is_editor_hint() else max_height
	var top := -h
	var bottom := -MOUTH
	if bottom - top < 1.0:
		return
	var w := WIDTH
	if is_frozen:
		var a := 0.95
		if _frozen_left < WARN and int(_time * 9.0) % 2 == 0:
			a = 0.45
		_jet.draw_rect(Rect2(-w / 2.0 - 2.0, top, w + 4.0, bottom - top), Color(0.46, 0.7, 0.92, a * 0.85))
		_jet.draw_rect(Rect2(-w / 2.0 - 2.0, top, w + 4.0, 3), Color(0.9, 0.97, 1.0, a))
		_jet.draw_rect(Rect2(-w / 2.0 - 2.0, top, 2, bottom - top), Color(0.8, 0.94, 1.0, a * 0.7))
		var y := top + 8.0
		var k := 0
		while y < bottom - 6.0:
			_jet.draw_line(Vector2(-w / 2.0 + 2.0 + (k % 3) * 4.0, y), Vector2(w / 2.0 - 3.0, y + 6.0), Color(1, 1, 1, a * 0.35), 1.0)
			y += 14.0
			k += 1
		return
	# Water: a pale core, darker edges, foam at the top and spray
	_jet.draw_rect(Rect2(-w / 2.0, top + 4.0, w, bottom - top - 4.0), Color(0.3, 0.62, 0.82, 0.55))
	_jet.draw_rect(Rect2(-w / 4.0, top + 4.0, w / 2.0, bottom - top - 4.0), Color(0.72, 0.9, 1.0, 0.45))
	var stripe := fposmod(_time * 90.0, 12.0)
	var y := top + 6.0 + stripe
	while y < bottom - 2.0:
		_jet.draw_rect(Rect2(-w / 2.0 + 3.0, y, 2, 5), Color(0.9, 0.98, 1.0, 0.5))
		_jet.draw_rect(Rect2(w / 2.0 - 5.0, y + 6.0, 2, 4), Color(0.9, 0.98, 1.0, 0.4))
		y += 12.0
	_jet.draw_rect(Rect2(-w / 2.0 - 2.0, top, w + 4.0, 5), Color(0.92, 0.98, 1.0, 0.85))
	for d in _drops:
		var life := fposmod(_time * (0.9 + d.z) + d.x, 1.0)
		var dx := (d.y - 0.5) * 34.0 * life
		var dy := -10.0 * life + 30.0 * life * life
		_jet.draw_rect(Rect2(dx - 1.0, top + dy, 2, 2), Color(0.85, 0.96, 1.0, 0.8 * (1.0 - life)))
