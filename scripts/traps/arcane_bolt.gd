class_name ArcaneBolt
extends Area2D

## A slow magical bolt fired by an ArcaneBoltStatue. It damages the player's
## hurtbox and bursts on anything solid: level geometry, stone blocks, gates,
## frozen gargoyles. It fades out after max_distance.

var direction := Vector2.RIGHT
var speed := 170.0
var damage := 2
var max_distance := 900.0

var _travelled := 0.0
var _visual: Node2D
var _time := 0.0


func _ready() -> void:
	add_to_group("arcane_bolt")
	collision_layer = 0
	collision_mask = 2  # solid geometry (bodies) and the player's hurtbox (area)
	monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = 5.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	_visual = Node2D.new()
	_visual.material = MagicLight.unshaded()
	_visual.draw.connect(_draw_bolt)
	add_child(_visual)
	var light := PointLight2D.new()
	light.texture = LightTextures.radial(128)
	light.color = Color(0.75, 0.4, 1.0)
	light.energy = 0.9
	add_child(light)
	body_entered.connect(func(_b): _burst())
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is Hurtbox:
		area.receive_damage(damage, self)
		_burst()


func _physics_process(delta: float) -> void:
	_time += delta
	var step := direction * speed * delta
	position += step
	_travelled += step.length()
	if _travelled >= max_distance:
		queue_free()
	_visual.queue_redraw()


func _burst() -> void:
	Sfx.play("bolt_impact", global_position, -4.0)
	var sparks := CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 10
	sparks.lifetime = 0.35
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 30.0
	sparks.initial_velocity_max = 60.0
	sparks.color = Color(0.8, 0.55, 1.0)
	sparks.material = MagicLight.unshaded()
	sparks.global_position = global_position
	get_parent().add_child(sparks)
	sparks.emitting = true
	sparks.finished.connect(sparks.queue_free)
	queue_free()


func _draw_bolt() -> void:
	var pulse := 0.8 + 0.2 * sin(_time * 25.0)
	_visual.draw_circle(Vector2.ZERO, 7.0, Color(0.6, 0.3, 1.0, 0.3 * pulse))
	_visual.draw_circle(Vector2.ZERO, 4.0, Color(0.8, 0.55, 1.0, 0.9))
	_visual.draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1, pulse))
	# Short trail behind it
	for i in 3:
		_visual.draw_circle(-direction * (5.0 + i * 4.0), 2.5 - i * 0.6, Color(0.7, 0.45, 1.0, 0.5 - i * 0.15))


## The bolt counts as a damage source; a small push away from its path.
func get_knockback_velocity(_target: Node2D) -> Vector2:
	return direction * 140.0 + Vector2(0, -60)
