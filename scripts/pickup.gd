class_name Pickup
extends Area2D

## A small orb dropped by defeated creatures. It bobs in place, drifts to
## Echidna once she is close, and restores a little health ("+1 HP") when
## touched. Orbs she doesn't need (full health) stay put for later. Unclaimed
## orbs fade after a while.

const COLOR := Color(1.0, 0.45, 0.55)
const MAGNET_RANGE := 70.0
const LIFETIME := 25.0

var amount := 1
var _time := 0.0
var _player: Node2D
var _drift := Vector2.ZERO
var _collected := false


## Drops an orb at `at` with a small hop, as a child of `parent`.
static func drop(parent: Node, at: Vector2, heal := 1) -> Pickup:
	var p := Pickup.new()
	p.amount = heal
	parent.add_child(p)
	p.global_position = at
	p._drift = Vector2(randf_range(-40.0, 40.0), -90.0)
	return p


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	z_index = 4
	material = MagicLight.unshaded()
	var shape := CircleShape2D.new()
	shape.radius = 9.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	add_child(GlowFX.halo(COLOR, 16.0, 0.45, 4.0, 0.25, 0.1))
	body_entered.connect(_on_body_entered)
	add_to_group("pickup")


func _physics_process(delta: float) -> void:
	_time += delta
	if _time > LIFETIME:
		modulate.a = move_toward(modulate.a, 0.0, delta)
		if modulate.a <= 0.0:
			queue_free()
		return
	# A short hop out of the creature, then it hangs in the air
	if _drift != Vector2.ZERO:
		position += _drift * delta
		_drift = _drift.move_toward(Vector2.ZERO, 260.0 * delta)
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player and _wants(_player):
		var target := _player.global_position + Vector2(0, -18)
		if global_position.distance_to(target) < MAGNET_RANGE:
			global_position = global_position.move_toward(target, 220.0 * delta)
			if global_position.distance_to(target) < 10.0:
				_collect(_player)
	queue_redraw()


func _wants(player: Node) -> bool:
	return not player.is_dead and player.current_health < player.MAX_HEALTH


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and _wants(body):
		_collect(body)


func _collect(player: Node) -> void:
	if _collected:
		return
	_collected = true
	player.current_health = mini(player.current_health + amount, player.MAX_HEALTH)
	player.update_health_ui()
	Sfx.play("collect", global_position, -4.0)
	FloatText.spawn(get_parent(), global_position + Vector2(0, -10), "+%d HP" % amount, COLOR.lerp(Color.WHITE, 0.3))
	queue_free()


func _draw() -> void:
	var bob := sin(_time * 3.0) * 2.0
	var c := Vector2(0, bob)
	draw_circle(c, 5.0, Color(COLOR, 0.35))
	draw_circle(c, 3.0, COLOR)
	draw_circle(c + Vector2(-1, -1), 1.2, Color(1, 1, 1, 0.9))
