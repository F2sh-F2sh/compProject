@tool
class_name MovingPlatform
extends AnimatableBody2D

## A stone ledge that glides between its start position and `travel`, pausing
## at each end. It carries the player and never deals damage (crushing is the
## PistonTrap's job). If `requires_power` is set it only moves while powered.
## The node marks the platform's top-left corner.

const TILE := preload("res://assets/tileset/platforms/tiles/08_cap_mid.png")
const TILE_TOP := 18.0

@export var width_tiles := 2:
	set(value):
		width_tiles = maxi(value, 1)
		queue_redraw()
@export var travel := Vector2(192, 0):
	set(value):
		travel = value
		queue_redraw()
@export var speed := 60.0
@export var end_pause := 0.8
@export var requires_power := false

var _start := Vector2.ZERO
var _t := 0.0
var _dir := 1.0
var _pause := 0.0
var _powered := false
var _safe_fraction := 1.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	sync_to_physics = false
	collision_layer = 3
	collision_mask = 0
	add_to_group("resettable")
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width_tiles * 64.0, 14.0)
	shape.shape = rect
	shape.position = Vector2(width_tiles * 32.0, TILE_TOP + 7.0)
	shape.one_way_collision = true
	add_child(shape)
	_start = global_position
	_check_clearance.call_deferred()


func _check_clearance() -> void:
	await get_tree().physics_frame
	if not is_inside_tree() or travel.is_zero_approx():
		return
	_safe_fraction = 1.0
	# Sweep the complete visible slab against masonry. Its bottom must
	# stop before the floor, even though the ride collider is thinner.
	var slab := RectangleShape2D.new()
	slab.size = Vector2(width_tiles * 64.0 - 4.0, 25.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = slab
	query.transform = Transform2D(0, _start + Vector2(width_tiles * 32.0, TILE_TOP + 12.5))
	query.motion = travel
	query.collision_mask = 2
	query.exclude = [get_rid()]
	var result := get_world_2d().direct_space_state.cast_motion(query)
	if result.size() == 2 and result[0] < 1.0:
		_safe_fraction = maxf(0.0, result[0] - 3.0 / maxf(travel.length(), 1.0))


func set_powered(powered: bool) -> void:
	_powered = powered


func reset_state() -> void:
	_t = 0.0
	_dir = 1.0
	_pause = 0.0
	global_position = _start


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if requires_power and not _powered:
		return
	if _pause > 0.0:
		_pause -= delta
		return
	var length := maxf(travel.length() * _safe_fraction, 1.0)
	_t = clampf(_t + _dir * speed * delta / length, 0.0, 1.0)
	if _t <= 0.0 or _t >= 1.0:
		_dir = -_dir
		_pause = end_pause
	# Ease in and out at the ends so riding it feels steady
	var eased := 0.5 - 0.5 * cos(_t * PI)
	global_position = _start + travel * eased * _safe_fraction


func _draw() -> void:
	for i in width_tiles:
		draw_texture_rect_region(TILE, Rect2(i * 64.0, TILE_TOP, 64, 22), Rect2(0, TILE_TOP, 64, 22))
	# Iron runners under the slab show it is a mechanism
	draw_rect(Rect2(6, TILE_TOP + 22.0, width_tiles * 64.0 - 12.0, 3), Color("2b2838"))
	if Engine.is_editor_hint():
		draw_dashed_line(Vector2(width_tiles * 32.0, TILE_TOP), Vector2(width_tiles * 32.0, TILE_TOP) + travel,
			Color(0.5, 0.9, 1.0, 0.6), 1.0, 4.0)
