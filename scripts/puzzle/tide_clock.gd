@tool
class_name TideClock
extends Node2D

## The Drowned Cistern's tide clock: a tall glass column the tide fills and
## empties, over and over, with a brass float riding the water. The clock
## strikes when the float is HELD at the hour mark at the top (the tide only
## touches it in passing): then it powers its circuit (the Sluice Door) and
## stays full, saved. Cold that reaches the water (an Ice Freeze rune) holds
## the tide where it is, and rising water freezes where it first meets the
## cold: to stop it at the hour the cold must lie just above the mark. Held
## anywhere else, it says how far short it is. The frame and float are pixel
## sprites (tools/generate_cistern_sprites.gd); the water is drawn.
## The node sits on the floor at the column's centre.

signal power_changed(powered: bool)

## The glass, in local space: 64 wide, from the plinth up to the capital.
const GLASS := Rect2(-32, -302, 64, 274)
## How long the float must rest at the mark for the clock to strike.
const STRIKE_HOLD := 1.5
const LINGER := 1.2
const WARN := 0.8
## Within this of the mark, the float is at the hour.
const HOUR_SLACK := 8.0

@export var persist_id := ""
## Where the water's surface is, above the floor, at the bottom and the top of the tide.
@export var low_level := 34.0
@export var high_level := 298.0
@export var rise_time := 5.0
@export var hold_top := 1.0
@export var fall_time := 4.0
@export var hold_low := 2.0
@export var phase := 0.0

## The water's surface now, above the floor.
var level := 0.0
var is_frozen := false
var struck := false
## How the last hold went: "", "short", "hour".
var last_hold := ""
var _frozen_left := 0.0
var _held_for := 0.0
var _told := false
var _t := 0.0
var _time := 0.0
var _water: Node2D
var _float: Sprite2D
var _light: PointLight2D


func _ready() -> void:
	_t = phase
	level = _level_at(_t)
	_water = Node2D.new()
	_water.name = "Water"
	_water.z_index = -2
	_water.draw.connect(_draw_water)
	add_child(_water)
	_float = SurfaceArt.sprite(self, "tide_float", Vector2(0, -level), 1.0)
	_float.name = "Float"
	_float.z_index = -1
	var frame := SurfaceArt.sprite(self, "tide_clock", Vector2.ZERO, 1.0)
	frame.name = "Frame"
	frame.z_index = -1
	if Engine.is_editor_hint():
		return
	_water.material = MagicLight.unshaded()
	add_to_group("freezable")
	add_to_group("resettable")
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = Color(0.5, 0.8, 1.0)
	_light.energy = 0.45
	_light.texture_scale = 2.2
	_light.position = Vector2(0, -160)
	_light.shadow_enabled = false
	add_child(_light)
	if persist_id != "" and GameState.has_flag(persist_id):
		struck = true
		level = high_level


func period() -> float:
	return rise_time + hold_top + fall_time + hold_low


func _level_at(t: float) -> float:
	var p := fposmod(t, period())
	if p < rise_time:
		return lerpf(low_level, high_level, _ease(p / rise_time))
	p -= rise_time
	if p < hold_top:
		return high_level
	p -= hold_top
	if p < fall_time:
		return lerpf(high_level, low_level, _ease(p / fall_time))
	return low_level


func _ease(k: float) -> float:
	return 0.5 - 0.5 * cos(clampf(k, 0.0, 1.0) * PI)


func is_powered() -> bool:
	return struck


## The float is at the hour mark.
func at_hour() -> bool:
	return level >= high_level - HOUR_SLACK


## The tide is coming up (not held, not struck).
func is_rising() -> bool:
	return not is_frozen and not struck and fposmod(_t, period()) < rise_time


## The water in the glass, world space.
func water_rect() -> Rect2:
	var bottom := global_position.y + GLASS.end.y
	var top := global_position.y - level
	return Rect2(global_position.x + GLASS.position.x, top, GLASS.size.x, maxf(bottom - top, 2.0))


## Cold from an Ice Freeze rune: if it reaches the water, the tide holds still.
func chill_from(field: Node) -> void:
	if struck:
		return
	if field.covers(water_rect()):
		if not is_frozen:
			is_frozen = true
			_held_for = 0.0
			_told = false
			Sfx.play("ice_freeze", Vector2(global_position.x, global_position.y - level), -3.0)
			ImpactFX.burst(get_parent(), Vector2(global_position.x, global_position.y - level), Color(0.75, 0.92, 1.0), true, 10)
		_frozen_left = LINGER


func _physics_process(delta: float) -> void:
	_time += delta
	if Engine.is_editor_hint():
		_water.queue_redraw()
		return
	if struck:
		level = move_toward(level, high_level, 60.0 * delta)
	elif is_frozen:
		_frozen_left -= delta
		_held_for += delta
		if at_hour():
			last_hold = "hour"
			if _held_for >= STRIKE_HOLD:
				_strike()
		elif _held_for >= STRIKE_HOLD and not _told:
			_told = true
			last_hold = "short"
			_say_short()
		if _frozen_left <= 0.0 and not struck:
			is_frozen = false
			Sfx.play("ice_crack", Vector2(global_position.x, global_position.y - level), -5.0)
	else:
		_t += delta
		var was_top := at_hour()
		level = _level_at(_t)
		# The float touches the mark in passing: a faint tick, nothing more
		if at_hour() and not was_top:
			Sfx.play("drip", Vector2(global_position.x, global_position.y - level), -6.0)
	_float.position = Vector2(0, -level)
	_water.queue_redraw()


func _say_short() -> void:
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root == null:
		return
	var short := high_level - level
	var how := "a hand's width" if short < 48.0 else ("a stride" if short < 120.0 else "far")
	root.show_toast("The tide is held, but %s short of the hour mark. The clock won't strike." % how, 4.0)


func _strike() -> void:
	struck = true
	is_frozen = false
	last_hold = "hour"
	if persist_id != "":
		GameState.set_flag(persist_id)
	Sfx.play("great_bell", global_position + Vector2(0, -280), -2.0, 0.0)
	ImpactFX.burst(get_parent(), global_position + Vector2(0, -level), Color(0.75, 0.92, 1.0), true, 18)
	create_tween().tween_property(_light, "energy", 0.9, 1.2).from(2.2)
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root:
		root.camera.focus_on(global_position + Vector2(0, -200), 2.2)
		TitleCard.show_card(root, "", "The tide clock strikes the hour.", "Somewhere below, the Sluice Door grinds open.", 3.2)
	power_changed.emit(true)


func reset_state() -> void:
	# A struck clock stays struck; a frozen tide lets go
	if struck:
		return
	is_frozen = false
	_frozen_left = 0.0
	_held_for = 0.0
	last_hold = ""
	_t = phase
	level = _level_at(_t)


func _draw_water() -> void:
	var lv := level if not Engine.is_editor_hint() else (low_level + high_level) * 0.5
	var bottom := GLASS.end.y
	var top := -lv
	if bottom - top < 1.0:
		return
	var x0 := GLASS.position.x
	var w := GLASS.size.x
	if is_frozen or struck:
		var a := 1.0
		if is_frozen and _frozen_left < WARN and int(_time * 9.0) % 2 == 0:
			a = 0.55
		var ice := Color(0.5, 0.74, 0.94, 0.9 * a) if is_frozen else Color(0.22, 0.5, 0.7, 0.85)
		_water.draw_rect(Rect2(x0, top, w, bottom - top), ice)
		_water.draw_rect(Rect2(x0, top, w, 3), Color(0.9, 0.98, 1.0, a))
		if is_frozen:
			var y := top + 10.0
			var k := 0
			while y < bottom - 8.0:
				_water.draw_line(Vector2(x0 + 4 + (k % 4) * 9, y), Vector2(x0 + w - 6, y + 9), Color(1, 1, 1, 0.3 * a), 1.0)
				y += 22.0
				k += 1
		return
	# Water: dark below, lighter near the top, a moving surface
	_water.draw_rect(Rect2(x0, top, w, bottom - top), Color(0.1, 0.3, 0.45, 0.85))
	_water.draw_rect(Rect2(x0, top, w, minf(24.0, bottom - top)), Color(0.18, 0.46, 0.62, 0.85))
	for i in 8:
		var sx := x0 + i * 8.0
		var wave := sin(_time * 3.0 + i * 0.9) * 1.5
		_water.draw_rect(Rect2(sx, top + wave - 1.0, 8, 2), Color(0.6, 0.88, 0.98, 0.9))
	# bubbles rising
	for i in 5:
		var by := bottom - fposmod(_time * (30.0 + i * 7.0) + i * 53.0, maxf(bottom - top - 6.0, 1.0))
		_water.draw_rect(Rect2(x0 + 8 + i * 11, by, 2, 2), Color(0.7, 0.92, 1.0, 0.6))
