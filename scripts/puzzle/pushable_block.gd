@tool
class_name PushableBlock
extends CharacterBody2D

## A carved stone block the player can shove by walking into it. It is solid
## (you can stand on it), heavy enough for pressure plates, and blocks light
## beams and arcane bolts. The node origin is the bottom-centre of the block.

@export var block_size := Vector2(40, 40):
	set(value):
		block_size = value
		queue_redraw()
@export var push_speed := 70.0
@export var friction := 900.0
## Which way the room's puzzle needs it pushed (1 right, -1 left, 0 either).
## Shoved the other way up against a wall, nobody can get behind it any more:
## the room then says it can't be finished and how to reset it.
@export var needed_dir := 0
@export var required_reason := "The stone block is pushed up against the wall: nobody can get behind it to push it back."
## Once this flag is set (the room solved), where it is no longer matters.
@export var required_until_flag := ""

var _start_position := Vector2.ZERO
var _push_dir := 0.0
var _push_timer := 0.0
var _scrape_timer := 0.0
var _collider: CollisionShape2D
var _rune_glow: Node2D


func _ready() -> void:
	if _rune_glow == null:
		# The carved rune glows faintly so the block reads even in darkness
		_rune_glow = Node2D.new()
		_rune_glow.material = MagicLight.unshaded()
		_rune_glow.draw.connect(_draw_rune_glow)
		add_child(_rune_glow)
	if _collider == null:
		_collider = CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		_collider.shape = shape
		add_child(_collider)
	(_collider.shape as RectangleShape2D).size = block_size - Vector2(2, 0)
	_collider.position = Vector2(0, -block_size.y / 2.0)
	if Engine.is_editor_hint():
		return
	# Same layers as the level geometry: the player collides with it and
	# light beams and bolts are stopped by it
	collision_layer = 3
	collision_mask = 2
	floor_snap_length = 4.0
	add_to_group("plate_weight")
	add_to_group("resettable")
	add_to_group("world")
	if needed_dir != 0:
		add_to_group("puzzle_critical")
	_start_position = global_position


## Why the room can't be finished because of this block ("" if it can): it
## sits against something solid on the side she would have to push from.
func lost_reason() -> String:
	if needed_dir == 0 or not is_on_floor():
		return ""
	if required_until_flag != "" and GameState.has_flag(required_until_flag):
		return ""
	var box := RectangleShape2D.new()
	box.size = Vector2(14.0, block_size.y - 8.0)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = box
	query.transform = Transform2D(0.0, global_position + Vector2(-needed_dir * (block_size.x / 2.0 + 9.0), -block_size.y / 2.0 - 2.0))
	query.collision_mask = 2
	query.exclude = [get_rid()]
	return required_reason if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty() else ""


## Called by the player each frame they walk into the block.
func push(direction: float) -> void:
	_push_dir = signf(direction)
	_push_timer = 0.08


func reset_state() -> void:
	global_position = _start_position
	velocity = Vector2.ZERO
	_push_timer = 0.0
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if _push_timer > 0.0 and is_on_floor():
		_push_timer -= delta
		velocity.x = _push_dir * push_speed
		_scrape_timer -= delta
		if _scrape_timer <= 0.0:
			_scrape_timer = 0.28
			Sfx.play("crate_scrape", global_position, -6.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	move_and_slide()


func _draw() -> void:
	var w := roundf(block_size.x)
	var h := roundf(block_size.y)
	var x := -w / 2.0
	var y := -h
	# Stone body with chipped edges and a carved rune, in the dungeon palette
	draw_rect(Rect2(x, y, w, h), Color("1f1a33"))
	draw_rect(Rect2(x + 2, y + 2, w - 4, h - 4), Color("3b3358"))
	draw_rect(Rect2(x + 2, y + 2, w - 4, 3), Color("5a4f84"))
	draw_rect(Rect2(x + 2, y + h - 6, w - 4, 4), Color("2a2442"))
	draw_rect(Rect2(x + 2, y + 2, 3, h - 4), Color("4a4170"))
	# Mortar-like split and chips
	draw_rect(Rect2(x + 2, y + roundf(h * 0.55), w - 4, 1), Color("241e38"))
	draw_rect(Rect2(x + w - 7, y + 2, 5, 3), Color("1f1a33"))
	draw_rect(Rect2(x + 2, y + h - 5, 4, 3), Color("1f1a33"))
	if _rune_glow:
		_rune_glow.queue_redraw()


func _draw_rune_glow() -> void:
	var c := Vector2(0, -block_size.y + block_size.y * 0.35)
	var rune := Color(0.62, 0.55, 0.9, 0.55)
	_rune_glow.draw_rect(Rect2(c.x - 1, c.y - 6, 2, 12), rune)
	_rune_glow.draw_rect(Rect2(c.x - 6, c.y - 1, 12, 2), rune)
	_rune_glow.draw_rect(Rect2(c.x - 4, c.y - 4, 2, 2), rune)
	_rune_glow.draw_rect(Rect2(c.x + 2, c.y + 2, 2, 2), rune)
	# Faint outline of the block's top edge
	_rune_glow.draw_rect(Rect2(-block_size.x / 2.0 + 2.0, -block_size.y + 2.0, block_size.x - 4.0, 1), Color(0.55, 0.5, 0.8, 0.35))
