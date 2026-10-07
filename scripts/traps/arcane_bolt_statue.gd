@tool
class_name ArcaneBoltStatue
extends Node2D

## A carved skull set into the wall that fires arcane bolts along `fire_direction`.
## Before every shot its eyes and mouth gather light for `charge_time`, so a
## shot is never a surprise. It only fires while the player is in the same
## room (or it is on screen), never from somewhere the player can't see.
## Power switches it on and off; a lever through an inverting Circuit can
## silence it, and a stone block in the lane stops its bolts.

@export var fire_direction := Vector2.RIGHT:
	set(value):
		fire_direction = value
		queue_redraw()
@export var interval := 2.4
@export var charge_time := 0.7
@export_range(0.0, 1.0) var start_phase := 0.0
@export var bolt_speed := 170.0
@export var damage_amount := 2
@export var bolt_range := 900.0
## How far in front of the statue's centre a bolt starts. A plaque set into a wall
## uses more than the default, so its bolts begin in the open, not inside the wall.
@export var muzzle := 20.0
@export var active := true

const PLAQUE := preload("res://assets/TileSet/walls/tiles/22_plaque_skull.png")

var _timer := 0.0
var _charging := false
var _start_active := true
var _glow: Node2D
var _light: PointLight2D
var _time := 0.0


func _ready() -> void:
	_glow = Node2D.new()
	_glow.material = MagicLight.unshaded()
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	if Engine.is_editor_hint():
		return
	_start_active = active
	add_to_group("resettable")
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(128)
	_light.color = Color(0.75, 0.4, 1.0)
	_light.energy = 0.0
	add_child(_light)
	_reset_timer()


func set_powered(powered: bool) -> void:
	active = powered
	if not active:
		_charging = false


func reset_state() -> void:
	active = _start_active
	_charging = false
	_reset_timer()


func _reset_timer() -> void:
	_timer = interval * (1.0 - start_phase)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	if not active or not _player_can_see():
		_charging = false
		_light.energy = move_toward(_light.energy, 0.0, delta * 3.0)
		_glow.queue_redraw()
		return
	_timer -= delta
	if not _charging and _timer <= charge_time:
		_charging = true
		Sfx.play("bolt_charge", global_position, -6.0)
	if _charging:
		_light.energy = 1.2 * (1.0 - maxf(_timer, 0.0) / charge_time)
	if _timer <= 0.0:
		_fire()
		_timer = interval
		_charging = false
		_light.energy = 0.3
	_glow.queue_redraw()


func _fire() -> void:
	var bolt := ArcaneBolt.new()
	bolt.direction = fire_direction.normalized()
	bolt.speed = bolt_speed
	bolt.damage = damage_amount
	bolt.max_distance = bolt_range
	bolt.position = global_position + fire_direction.normalized() * muzzle
	get_parent().add_child(bolt)
	Sfx.play("bolt_fire", global_position, -4.0)


func _player_can_see() -> bool:
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root and root.current_room:
		return root.current_room.contains(global_position)
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return true
	var size := get_viewport_rect().size / camera.zoom
	return Rect2(camera.get_screen_center_position() - size / 2.0, size).has_point(global_position)


func _draw() -> void:
	draw_texture(PLAQUE, Vector2(-32, -32), Color(0.95, 0.92, 1.0))


func _draw_glow() -> void:
	var charge := 0.0
	if not Engine.is_editor_hint() and _charging:
		charge = 1.0 - clampf(_timer / charge_time, 0.0, 1.0)
	if not Engine.is_editor_hint() and not active:
		return
	var c := Color(0.8, 0.5, 1.0, 0.25 + 0.75 * charge)
	# Glowing eye sockets gather light before each shot
	_glow.draw_rect(Rect2(-7, -6, 4, 3), c)
	_glow.draw_rect(Rect2(3, -6, 4, 3), c)
	if charge > 0.0:
		var gather := 10.0 * (1.0 - charge)
		for i in 6:
			var a := _time * 6.0 + i * TAU / 6.0
			_glow.draw_rect(Rect2(fire_direction.normalized() * 16.0 + Vector2.from_angle(a) * (4.0 + gather) - Vector2(1, 1),
				Vector2(2, 2)), Color(0.85, 0.6, 1.0, charge))
