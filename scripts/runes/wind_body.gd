@tool
class_name WindBody
extends CharacterBody2D

## A loose object that wind can move: a wooden crate, a stone block or a
## heavy statue. It integrates its own motion from the forces it is given:
##   gravity + wind force / mass, minus drag;
##   on the ground, friction: it stays put until the sideways force beats
##   static friction (static_mu * normal force), then slides against the
##   weaker kinetic friction.
## So one normal wind (1200) moves a crate (breakaway 490) but not a stone
## block (1470); two overlapping winds (2400) move the stone block. Lifting
## reduces the normal force, and so the friction, as it should.
## The RuneManager sums every wind acting on this body each physics frame
## and hands it over through set_wind_force(); a gust arrives once through
## apply_wind_impulse(). Nothing moves the body by setting its position,
## except a room reset.
## The node's origin is the bottom-centre of the object.

signal impacted(speed: float, collider: Object)

enum Weight { CRATE, STONE, STATUE }

const PRESETS := {
	# mass, static mu, kinetic mu, drag per second
	Weight.CRATE: [1.0, 0.5, 0.35, 3.0],
	Weight.STONE: [3.0, 0.5, 0.35, 1.2],
	Weight.STATUE: [6.0, 0.5, 0.35, 1.0],
}

@export var weight: Weight = Weight.CRATE:
	set(value):
		weight = value
		_apply_preset()
		if _art:
			_art.queue_redraw()
@export var size := Vector2(40, 40):
	set(value):
		size = value
		if _art:
			_art.queue_redraw()
## Overrides (0 = use the weight class's value).
@export var mass_override := 0.0
@export var persist_id := ""

var mass := 1.0
var static_mu := 0.5
var kinetic_mu := 0.35
var drag := 3.0

## The summed wind force for this physics frame (cleared after use).
var _wind_force := Vector2.ZERO
var _impulse := Vector2.ZERO
## True while wind presses on it but can't beat friction.
var is_straining := false
var last_force := Vector2.ZERO
var _start_position := Vector2.ZERO
var _collider: CollisionShape2D
var _shake := 0.0
var _scrape := 0.0
var _art: Node2D


func _ready() -> void:
	_apply_preset()
	_collider = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size - Vector2(2, 0)
	_collider.shape = shape
	_collider.position = Vector2(0, -size.y / 2.0)
	add_child(_collider)
	# The drawing is a child, so a strain shiver never moves the real body
	_art = Node2D.new()
	_art.draw.connect(_draw_art)
	add_child(_art)
	if Engine.is_editor_hint():
		return
	collision_layer = 3
	collision_mask = 2
	floor_snap_length = 4.0
	floor_max_angle = deg_to_rad(50)
	add_to_group("wind_receiver")
	add_to_group("plate_weight")
	add_to_group("resettable")
	add_to_group("world")
	if weight != Weight.CRATE:
		add_to_group("stone_weight")
	_start_position = global_position


func _apply_preset() -> void:
	var p: Array = PRESETS[weight]
	mass = mass_override if mass_override > 0.0 else p[0]
	static_mu = p[1]
	kinetic_mu = p[2]
	drag = p[3]


## The force needed to start it sliding on flat ground.
func breakaway_force() -> float:
	return static_mu * mass * _gravity()


func _gravity() -> float:
	return get_gravity().y if is_inside_tree() else 980.0


func set_wind_force(force: Vector2) -> void:
	_wind_force = force


func apply_wind_impulse(impulse: Vector2) -> void:
	_impulse += impulse


## Its shape in the world (for wind regions and placement checks).
func get_bounds() -> Rect2:
	return Rect2(global_position - Vector2(size.x / 2.0, size.y), size)


func reset_state() -> void:
	global_position = _start_position
	velocity = Vector2.ZERO
	_wind_force = Vector2.ZERO
	_impulse = Vector2.ZERO
	is_straining = false
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var force := _wind_force
	last_force = force
	_wind_force = Vector2.ZERO
	var g := _gravity()
	if _impulse != Vector2.ZERO:
		velocity += _impulse / mass
		_impulse = Vector2.ZERO

	velocity.y += (g + force.y / mass) * delta
	velocity.y -= velocity.y * drag * 0.5 * delta

	is_straining = false
	if is_on_floor():
		# Lift takes weight off the floor, and with it some friction
		var normal := maxf(mass * g + force.y, 0.0)
		if absf(velocity.x) < 1.0:
			if absf(force.x) > static_mu * normal:
				velocity.x += (force.x - signf(force.x) * kinetic_mu * normal) / mass * delta
			else:
				velocity.x = 0.0
				is_straining = absf(force.x) > 0.2 * static_mu * normal
		else:
			var slowed := velocity.x + (force.x / mass - signf(velocity.x) * kinetic_mu * normal / mass) * delta
			slowed -= velocity.x * drag * delta
			# Friction stops it; it never pushes it back the other way
			velocity.x = 0.0 if signf(slowed) != signf(velocity.x) and absf(force.x) <= kinetic_mu * normal else slowed
	else:
		velocity.x += (force.x / mass - velocity.x * drag) * delta

	var before := velocity
	move_and_slide()
	_report_impacts(before)
	_update_feedback(delta)


# A hard enough collision is an impact (a cracked wall asks how hard)
func _report_impacts(before: Vector2) -> void:
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var speed := -before.dot(hit.get_normal())
		if speed > 20.0:
			var other := hit.get_collider()
			impacted.emit(speed, other)
			if other and other.has_method("on_impact"):
				other.on_impact(self, speed, mass)
			elif other and other.get_parent() and other.get_parent().has_method("on_impact"):
				other.get_parent().on_impact(self, speed, mass)


func _update_feedback(delta: float) -> void:
	# Straining: a shiver of the art and a grinding scrape, never real motion
	_shake = move_toward(_shake, 1.0 if is_straining else 0.0, delta * 6.0)
	_art.position = Vector2(sin(Time.get_ticks_msec() * 0.09) * 0.8 * _shake, 0.0)
	_scrape -= delta
	var sliding := is_on_floor() and absf(velocity.x) > 12.0
	if sliding and last_force != Vector2.ZERO:
		RuneJournal.note("moves")
	if is_straining:
		RuneJournal.note("strain")
	if (is_straining or sliding) and _scrape <= 0.0:
		_scrape = 0.32 if sliding else 0.6
		Sfx.play("crate_scrape", global_position, -9.0 if is_straining else -6.0, 0.15)


func _draw_art() -> void:
	var w := roundf(size.x)
	var h := roundf(size.y)
	var x := -w / 2.0
	var y := -h
	match weight:
		Weight.CRATE:
			# Wooden crate: planks and a cross brace, warm brown under the purple light
			_art.draw_rect(Rect2(x, y, w, h), Color("2a1d1a"))
			_art.draw_rect(Rect2(x + 2, y + 2, w - 4, h - 4), Color("5a3f33"))
			for i in 3:
				_art.draw_rect(Rect2(x + 2, y + 2 + i * roundf((h - 4) / 3.0), w - 4, 1), Color("3a2a24"))
			_art.draw_line(Vector2(x + 4, y + 4), Vector2(x + w - 4, y + h - 4), Color("7a5a48"), 2.0)
			_art.draw_rect(Rect2(x + 2, y + 2, w - 4, 2), Color("8a6a54"))
		Weight.STONE, Weight.STATUE:
			var body := Color("3b3358") if weight == Weight.STONE else Color("4a4466")
			_art.draw_rect(Rect2(x, y, w, h), Color("1f1a33"))
			_art.draw_rect(Rect2(x + 2, y + 2, w - 4, h - 4), body)
			_art.draw_rect(Rect2(x + 2, y + 2, w - 4, 3), body.lightened(0.25))
			_art.draw_rect(Rect2(x + 2, y + roundf(h * 0.55), w - 4, 1), Color("241e38"))
			# Carved weight marks: one bar per ton of stubbornness
			var bars := 2 if weight == Weight.STONE else 3
			for i in bars:
				_art.draw_rect(Rect2(x + w / 2.0 - bars * 3.0 + i * 6.0, y + h * 0.3, 3, h * 0.18), Color("241e38"))


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if _art:
			_art.queue_redraw()
