@tool
class_name CrackedWall
extends StaticBody2D

## A cracked stretch of wall that a heavy enough impact knocks down: an
## object that hits it with momentum (speed x mass) of at least
## `break_momentum` breaks it for good; a weaker hit just thuds and shows a
## puff of dust. With the default 660 a stone block (mass 3) must arrive at
## 220 px/s or more (a strong wind's run-up does it, a normal push can't even
## start it), and a crate never can. The node's origin is the bottom-centre.

signal broken

@export var size := Vector2(32, 128):
	set(value):
		size = value
		queue_redraw()
@export var break_momentum := 660.0
## Saved once broken (a solved room stays solved).
@export var persist_id := ""
## A pixel sprite (SurfaceArt) to show instead of the drawn bricks, e.g. the
## Kilnworks' plug of cold slag. Its feet sit at the wall's origin.
@export var sprite_name := ""

var is_broken := false
## Same as is_broken (what objective steps and gates ask).
var is_open := false
var last_impact := 0.0
var _shape: CollisionShape2D
var _thud_cooldown := 0.0


func _ready() -> void:
	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = Vector2(0, -size.y / 2.0)
	add_child(_shape)
	if sprite_name != "":
		var sprite := SurfaceArt.sprite(self, sprite_name, Vector2.ZERO, 1.0)
		sprite.name = "Sprite"
	if Engine.is_editor_hint():
		return
	collision_layer = 3
	collision_mask = 0
	add_to_group("world")
	add_to_group("resettable")
	add_to_group("cracked_wall")
	if persist_id != "" and GameState.has_flag(persist_id):
		_break(true)


## Called by a WindBody that runs into it.
func on_impact(body: Node, speed: float, mass: float) -> void:
	if is_broken:
		return
	last_impact = speed * mass
	if last_impact >= break_momentum:
		_break(false)
	elif _thud_cooldown <= 0.0 and speed > 60.0:
		_thud_cooldown = 0.4
		Sfx.play("crate_thud", global_position + Vector2(0, -size.y / 2.0), -4.0)
		ImpactFX.burst(get_parent(), (body as Node2D).global_position + Vector2(0, -20), Color(0.6, 0.55, 0.7), true, 5)


func _break(silent: bool) -> void:
	is_broken = true
	is_open = true
	_shape.set_deferred("disabled", true)
	visible = false
	if persist_id != "":
		GameState.set_flag(persist_id)
	if not silent:
		Sfx.play("wall_break", global_position + Vector2(0, -size.y / 2.0), 0.0, 0.0)
		RuneJournal.note("impact")
		for i in 4:
			ImpactFX.burst(get_parent(), global_position + Vector2(0, -size.y * (i + 0.5) / 4.0), Color(0.5, 0.45, 0.62), true, 12)
		ImpactFX.kick(get_tree(), 2.5, 0.2)
		broken.emit()


func reset_state() -> void:
	if persist_id != "" and GameState.has_flag(persist_id):
		return
	is_broken = false
	is_open = false
	visible = true
	_shape.set_deferred("disabled", false)


func _physics_process(delta: float) -> void:
	_thud_cooldown -= delta


func _draw() -> void:
	if sprite_name != "":
		return
	var w := size.x
	var h := size.y
	var r := Rect2(-w / 2.0, -h, w, h)
	draw_rect(r, Color("2c2540"))
	for row in int(h / 16.0):
		var y := -h + row * 16.0
		draw_line(Vector2(-w / 2.0, y), Vector2(w / 2.0, y), Color("1c1729"), 1.0)
		var off := 0.0 if row % 2 == 0 else w / 2.0
		draw_line(Vector2(-w / 2.0 + off, y), Vector2(-w / 2.0 + off, y + 16), Color("1c1729"), 1.0)
	# The crack: a bright jagged seam, so it reads as breakable
	var crack := PackedVector2Array([Vector2(-2, -h + 4), Vector2(4, -h * 0.75), Vector2(-4, -h * 0.55),
		Vector2(5, -h * 0.35), Vector2(-3, -h * 0.15), Vector2(2, -4)])
	draw_polyline(crack, Color("0e0b16"), 3.0)
	draw_polyline(crack, Color(0.72, 0.62, 0.95, 0.55), 1.0)
