extends Area2D

@export var speed: float = 500.0
@export var max_distance: float = 400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO

## A critical hit: one fireball in ten, for double damage.
const CRITICAL_CHANCE := 0.1
const CRITICAL_MULTIPLIER := 2
const COLOR := Color(1.0, 0.58, 0.25)

var _exploded := false


func _ready() -> void:
	add_to_group("fireball")
	start_position = global_position

	# The fireball lights its surroundings (and casts shadows) as it flies
	var light := PointLight2D.new()
	light.texture = LightTextures.radial(256)
	light.color = COLOR
	light.energy = 1.2
	light.shadow_enabled = Settings.quality("shadows")
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	add_child(light)

	# A fast-pulsing halo and a trail of embers left hanging in the air
	add_child(GlowFX.halo(Color(1.0, 0.55, 0.25), 20.0, 0.6, 9.0, 0.18, 0.25))
	var trail := GlowFX.embers(Color(1.0, 0.62, 0.3), 14, 8.0, 3.0, 0.45)
	trail.preprocess = 0.0
	trail.local_coords = false
	add_child(trail)

	if animated_sprite.sprite_frames.has_animation("FireBall"):
		animated_sprite.play("FireBall")


func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	# Out of range it sputters out with a small puff
	if global_position.distance_to(start_position) >= max_distance and not _exploded:
		_exploded = true
		ImpactFX.burst(get_parent(), global_position, COLOR, false, 5)
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _exploded:
		return
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		var damage: int = randi_range(3, 7)
		var is_critical: bool = randf() < CRITICAL_CHANCE
		if is_critical:
			damage *= CRITICAL_MULTIPLIER
		body.take_damage(damage, is_critical)
		# A hit lands: a heartbeat of stillness and a kick of the camera
		ImpactFX.hit_stop(get_tree(), 0.07 if is_critical else 0.045)
		ImpactFX.kick(get_tree(), 2.2 if is_critical else 1.3, 0.12)
		explode(false, true)
		return

	# Splash on walls, floors and anything else solid
	if body.is_in_group("world") or body is TileMap or body is TileMapLayer:
		explode(true)


## Bursts where it is (also called by braziers, bells and rune switches
## when a fireball strikes them).
func explode(on_stone := false, on_creature := false) -> void:
	if _exploded:
		return
	_exploded = true
	ImpactFX.burst(get_parent(), global_position, COLOR, on_stone, 16 if on_creature else 11)
	Sfx.play("fireball_hit", global_position, 0.0 if on_creature else -5.0, 0.12)
	queue_free()
