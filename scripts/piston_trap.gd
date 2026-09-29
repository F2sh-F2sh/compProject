@tool
class_name PistonTrap
extends Node2D

## A crushing piston. The node sits at the mount point; the head travels along
## the node's local +Y (straight down when unrotated — rotate the node 90
## degrees for a wall ram). It rattles and its rune turns red before each
## slam. The head is solid (it blocks the player, beams and bolts). Being
## crushed hurts and, like spikes, sends the player back to a safe point
## (recovery_checkpoint once lit, otherwise the last safe ground before the
## piston), so a running piston can't simply be walked through and healed off.
## If anything ever ends up inside the head it is pushed out to the nearest
## side, so the player can never be left embedded. Power can switch it on and
## off (running).

enum Phase { RAISED, WARNING, SLAM, LOWERED, RETRACT }

## Distance from the mount to the bottom of the head while fully raised.
@export var raised_head_bottom := 146.0:
	set(value):
		raised_head_bottom = value
		queue_redraw()
## How far the head drops. Set so the fully lowered head meets the floor.
@export var travel_distance := 112.0:
	set(value):
		travel_distance = value
		queue_redraw()
@export var head_size := Vector2(56, 40):
	set(value):
		head_size = value
		queue_redraw()
@export var slam_speed := 520.0
@export var retract_speed := 100.0
@export var raised_pause := 1.2
## Rattle before each slam so the player can read the rhythm.
@export var warning_time := 0.4
@export var lowered_pause := 0.5
## 0-1 offset into the cycle, so neighbouring pistons can be staggered.
@export_range(0.0, 1.0) var start_phase := 0.0
@export var damage_amount := 2
## Push on a hit, in the piston's own frame: x = sideways away from the head's
## centre line, y = along the travel direction.
@export var knockback := Vector2(210, 0)
@export var rehit_delay := 0.5
## A stopped piston retracts and stays raised (e.g. after a switch is hit).
@export var running := true
@export var solid_head := true
## Where a crushed player returns (if lit); otherwise the last safe ground.
@export var recovery_checkpoint: HazardCheckpoint

const TEETH_HEIGHT := 6.0
const COLOR_IRON := Color("25222f")
const COLOR_IRON_LIGHT := Color("4c4862")
const COLOR_STONE := Color("3b3358")
const COLOR_STONE_LIGHT := Color("54497a")
const COLOR_STONE_DARK := Color("241e38")
const COLOR_STEEL := Color("9a97b0")
const COLOR_BLOOD := Color("6e1422")

var phase: Phase = Phase.RAISED
var progress := 0.0  # 0 = raised, 1 = lowered
var _elapsed := 0.0
var _shake := 0.0
var _start_running := true
var _hitbox: Area2D
var _hitbox_shape: RectangleShape2D
var _shaft: Area2D
var _shaft_shape: RectangleShape2D
var _head_body: AnimatableBody2D
var _head_shape: RectangleShape2D
var _dust: CPUParticles2D
var _rune: Node2D
var _cooldowns := {}


func _ready() -> void:
	_rune = Node2D.new()
	_rune.material = MagicLight.unshaded()
	_rune.draw.connect(_draw_rune)
	add_child(_rune)
	if Engine.is_editor_hint():
		return
	_start_running = running
	add_to_group("hazard_zone")
	add_to_group("resettable")
	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = 2
	_hitbox.monitorable = false
	_hitbox_shape = RectangleShape2D.new()
	var collider := CollisionShape2D.new()
	collider.shape = _hitbox_shape
	_hitbox.add_child(collider)
	add_child(_hitbox)

	# The iron shafts are solid too, so a lowered piston can't be hopped over
	_shaft = Area2D.new()
	_shaft.collision_layer = 0
	_shaft.collision_mask = 2
	_shaft.monitorable = false
	_shaft_shape = RectangleShape2D.new()
	var shaft_collider := CollisionShape2D.new()
	shaft_collider.shape = _shaft_shape
	_shaft.add_child(shaft_collider)
	add_child(_shaft)

	if solid_head:
		_head_body = AnimatableBody2D.new()
		_head_body.sync_to_physics = false
		# Not in the "world" group: fireballs fly past the heads, so a switch
		# beyond a running gauntlet can still be shot
		_head_body.collision_layer = 3
		_head_body.collision_mask = 0
		_head_shape = RectangleShape2D.new()
		var head_collider := CollisionShape2D.new()
		head_collider.shape = _head_shape
		_head_body.add_child(head_collider)
		add_child(_head_body)

	_dust = CPUParticles2D.new()
	_dust.emitting = false
	_dust.one_shot = true
	_dust.explosiveness = 1.0
	_dust.amount = 16
	_dust.lifetime = 0.5
	_dust.direction = Vector2(1, -0.4)
	_dust.spread = 180.0
	_dust.gravity = Vector2(0, 60)
	_dust.initial_velocity_min = 30.0
	_dust.initial_velocity_max = 70.0
	_dust.damping_min = 60.0
	_dust.damping_max = 90.0
	_dust.scale_amount_min = 2.0
	_dust.scale_amount_max = 3.0
	_dust.color = Color(0.62, 0.58, 0.74, 0.8)
	_dust.position = Vector2(0, raised_head_bottom + travel_distance - 2.0)
	add_child(_dust)

	_update_motion()


func get_cycle_length() -> float:
	return raised_pause + warning_time + _slam_time() + lowered_pause + _retract_time()


## True while the head is up and walking beneath it is safe.
func is_safe_to_pass() -> bool:
	return phase == Phase.RAISED or phase == Phase.RETRACT


func is_dangerous() -> bool:
	return phase == Phase.SLAM or phase == Phase.LOWERED


func stop() -> void:
	running = false


func start() -> void:
	running = true


## Power vocabulary: a powered piston runs.
func set_powered(powered: bool) -> void:
	running = powered


func reset_state() -> void:
	running = _start_running
	_elapsed = 0.0
	_cooldowns.clear()
	_update_motion()


func get_head_bottom() -> float:
	return raised_head_bottom + travel_distance * progress


## Called by the player after a non-lethal crush.
func get_recovery_position(player: Node2D) -> Vector2:
	if recovery_checkpoint and recovery_checkpoint.is_active:
		return recovery_checkpoint.get_respawn_position()
	var recovery := player.get_node_or_null("HazardRecovery")
	if recovery:
		return recovery.get_fallback_position()
	return player.global_position


func get_knockback_velocity(player: Node2D) -> Vector2:
	var side := signf(to_local(player.global_position).x)
	if side == 0.0:
		side = -1.0
	return global_transform.basis_xform(Vector2(side * knockback.x, knockback.y))


## Footprint where the head lands, used to keep respawn points away from it.
func get_hazard_rect() -> Rect2:
	var landing := Rect2(-head_size.x / 2.0, raised_head_bottom + travel_distance - 48.0, head_size.x, 48.0)
	var corners := [landing.position, landing.end, Vector2(landing.position.x, landing.end.y), Vector2(landing.end.x, landing.position.y)]
	var r := Rect2(to_global(corners[0]), Vector2.ZERO)
	for c in corners:
		r = r.expand(to_global(c))
	return r


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_elapsed += delta
	var was_phase := phase
	if running:
		_update_motion()
	else:
		progress = move_toward(progress, 0.0, retract_speed / travel_distance * delta)
		phase = Phase.RETRACT if progress > 0.0 else Phase.RAISED
		_shake = 0.0
		_place_hitbox()
	if was_phase != Phase.WARNING and phase == Phase.WARNING:
		Sfx.play("piston_warn", _head_center(), -6.0)
	if was_phase == Phase.SLAM and phase == Phase.LOWERED:
		_dust.restart()
		Sfx.play("piston_slam", _head_center(), -3.0)
		var player := get_tree().get_first_node_in_group("player") as Node2D
		var camera := get_viewport().get_camera_2d()
		if player and camera and camera.has_method("shake") and player.global_position.distance_to(_head_center()) < 360.0:
			camera.shake(2.0, 0.15)
	for hurtbox in _cooldowns.keys():
		_cooldowns[hurtbox] -= delta
		if _cooldowns[hurtbox] <= 0.0 or not is_instance_valid(hurtbox):
			_cooldowns.erase(hurtbox)

	if is_dangerous():
		for area in _hitbox.get_overlapping_areas() + _shaft.get_overlapping_areas():
			if area is Hurtbox:
				_hurt(area)
	_eject_player()


func _hurt(hurtbox: Hurtbox) -> void:
	if _cooldowns.has(hurtbox):
		return
	_cooldowns[hurtbox] = rehit_delay
	hurtbox.receive_damage(damage_amount, self)


# If the player ever ends up inside the solid head, move them out to the
# nearest side. Being caught by a falling head always hurts.
func _eject_player() -> void:
	if not solid_head:
		return
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null or player.is_dead:
		return
	var body_bottom := get_head_bottom() - TEETH_HEIGHT
	var top := get_head_bottom() - head_size.y
	# The player's capsule (5 px radius, 32 px tall) in the piston's frame
	var p := to_local(player.global_position + Vector2(0, -18))
	var half_w := (head_size.x - 2.0) / 2.0 + 5.0
	if absf(p.x) < half_w - 1.0 and p.y + 16.0 > top + 1.0 and p.y - 16.0 < body_bottom - 1.0:
		var side := signf(p.x) if p.x != 0.0 else -1.0
		player.global_position = to_global(Vector2(side * (half_w + 2.0), p.y)) + Vector2(0, 18)
		player.velocity = Vector2.ZERO
		var hurtbox = player.get("hurtbox")
		if is_dangerous() and hurtbox is Hurtbox:
			_hurt(hurtbox)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_redraw()
		_rune.queue_redraw()


func _head_center() -> Vector2:
	return to_global(Vector2(0, get_head_bottom() - head_size.y / 2.0))


func _slam_time() -> float:
	return travel_distance / maxf(slam_speed, 1.0)


func _retract_time() -> float:
	return travel_distance / maxf(retract_speed, 1.0)


func _update_motion() -> void:
	var t := fposmod(_elapsed + start_phase * get_cycle_length(), get_cycle_length())
	_shake = 0.0
	if t < raised_pause:
		phase = Phase.RAISED
		progress = 0.0
	elif t < raised_pause + warning_time:
		phase = Phase.WARNING
		progress = 0.0
		_shake = 1.0 if int(t * 28.0) % 2 == 0 else -1.0
	elif t < raised_pause + warning_time + _slam_time():
		phase = Phase.SLAM
		var k := (t - raised_pause - warning_time) / _slam_time()
		progress = k * k  # accelerates into the floor
	elif t < raised_pause + warning_time + _slam_time() + lowered_pause:
		phase = Phase.LOWERED
		progress = 1.0
	else:
		phase = Phase.RETRACT
		var k := (t - raised_pause - warning_time - _slam_time() - lowered_pause) / _retract_time()
		progress = 1.0 - clampf(k, 0.0, 1.0)

	_place_hitbox()


# The hitbox and solid body follow exactly the same head position that gets drawn
func _place_hitbox() -> void:
	var bottom := get_head_bottom()
	# With a solid head the hitbox reaches just past its sides, so pressing
	# against a slammed-down head hurts instead of being a safe place to wait
	_hitbox_shape.size = Vector2(head_size.x + (4.0 if solid_head else -6.0), head_size.y)
	_hitbox.position = Vector2(0, bottom - head_size.y / 2.0)
	var head_top := bottom - head_size.y
	_shaft_shape.size = Vector2(20, maxf(head_top - 8.0, 1.0))
	_shaft.position = Vector2(0, 8.0 + _shaft_shape.size.y / 2.0)
	if _head_body:
		var body_h := head_size.y - TEETH_HEIGHT
		_head_shape.size = Vector2(head_size.x - 2.0, body_h)
		_head_body.position = Vector2(0, head_top + body_h / 2.0)


func _draw() -> void:
	var bottom := roundf(get_head_bottom() if not Engine.is_editor_hint() else raised_head_bottom)
	var w := roundf(head_size.x)
	var h := roundf(head_size.y)
	var body_h := h - TEETH_HEIGHT
	var top := bottom - h
	var x := -w / 2.0 + _shake

	if Engine.is_editor_hint():
		# Show where the head will land
		var floor_y := raised_head_bottom + travel_distance
		draw_rect(Rect2(-w / 2.0, floor_y - h, w, h), Color(1, 0.3, 0.3, 0.25), false, 1.0)

	# Mount bracket
	draw_rect(Rect2(-18, 0, 36, 8), COLOR_IRON)
	draw_rect(Rect2(-18, 6, 36, 2), COLOR_IRON_LIGHT)
	for rx in [-14, 12]:
		draw_rect(Rect2(rx, 2, 2, 2), COLOR_STEEL)

	# Twin shafts down to the head
	for sx in [-8, 4]:
		draw_rect(Rect2(sx + _shake, 8, 4, top - 8), COLOR_IRON)
		draw_rect(Rect2(sx + _shake + 1, 8, 1, top - 8), COLOR_IRON_LIGHT)
		var y := 14.0
		while y < top - 4:
			draw_rect(Rect2(sx + _shake - 1, y, 6, 2), COLOR_IRON_LIGHT)
			y += 14.0

	# Stone head with iron bands
	draw_rect(Rect2(x, top, w, body_h), COLOR_STONE_DARK)
	draw_rect(Rect2(x + 2, top + 2, w - 4, body_h - 4), COLOR_STONE)
	draw_rect(Rect2(x + 2, top + 2, w - 4, 3), COLOR_STONE_LIGHT)
	var mid := top + roundf(body_h / 2.0)
	draw_rect(Rect2(x + 2, mid, w - 4, 1), COLOR_STONE_DARK)
	draw_rect(Rect2(x + roundf(w / 3.0), top + 5, 1, mid - top - 5), COLOR_STONE_DARK)
	draw_rect(Rect2(x + roundf(w * 2.0 / 3.0), mid + 1, 1, top + body_h - mid - 4), COLOR_STONE_DARK)
	draw_rect(Rect2(x, top, w, 4), COLOR_IRON)
	draw_rect(Rect2(x, top + body_h - 5, w, 5), COLOR_IRON)
	draw_rect(Rect2(x, top + body_h - 5, w, 1), COLOR_IRON_LIGHT)
	for rx in range(4, int(w) - 2, 12):
		draw_rect(Rect2(x + rx, top + 1, 2, 2), COLOR_STEEL)

	# Crushing teeth
	var tooth_w := 8.0
	var tx := x + 2.0
	while tx + tooth_w <= x + w - 1.0:
		var base_y := top + body_h
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx, base_y), Vector2(tx + tooth_w, base_y),
			Vector2(tx + tooth_w / 2.0, base_y + TEETH_HEIGHT)]), COLOR_STEEL)
		draw_rect(Rect2(tx + tooth_w / 2.0 - 1.0, base_y + TEETH_HEIGHT - 2.0, 2, 2), COLOR_BLOOD)
		tx += tooth_w


# A rune on the mount: blue at rest, red while it is about to slam or down,
# dark when the piston has been switched off
func _draw_rune() -> void:
	var c := Color(0.45, 0.65, 1.0, 0.8)
	if not Engine.is_editor_hint():
		if not running:
			c = Color(0.3, 0.3, 0.4, 0.6)
		elif phase == Phase.WARNING or phase == Phase.SLAM or phase == Phase.LOWERED:
			c = Color(1.0, 0.3, 0.25, 0.95)
	_rune.draw_rect(Rect2(-3, 2, 6, 3), c)
	# A glint along the crushing teeth so the danger edge reads in the dark;
	# it flares while the piston is about to slam or is down
	if Engine.is_editor_hint() or not running:
		return
	var bottom := roundf(get_head_bottom())
	var w := roundf(head_size.x)
	var x := -w / 2.0 + _shake
	var danger := phase == Phase.WARNING or phase == Phase.SLAM or phase == Phase.LOWERED
	var glint := Color(1.0, 0.34, 0.28, 0.95 if danger else 0.45)
	var tooth_w := 8.0
	var tx := x + 2.0
	while tx + tooth_w <= x + w - 1.0:
		var tip := Vector2(tx + tooth_w / 2.0, bottom)
		_rune.draw_line(Vector2(tx, bottom - TEETH_HEIGHT), tip, glint, 1.0)
		_rune.draw_line(tip, Vector2(tx + tooth_w, bottom - TEETH_HEIGHT), glint, 1.0)
		tx += tooth_w
