extends Area2D

## A bolt of fire: Echidna's own, an Echo's, or a rune cube's (Fire
## Projectile). It flies straight, splashes on stone, hurts creatures and
## lights what burns. Fire rides the wind: a bolt that flies into a running
## current (a Wind Push or Lift) turns to travel with it, drawn to the middle
## of the current, and the moving air feeds it, so its range starts again
## (the Kilnworks' bellows work this way). Currents turn fire the way mirrors
## turn light.

@export var speed: float = 500.0
@export var max_distance: float = 400.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction: Vector2 = Vector2.ZERO
var start_position: Vector2 = Vector2.ZERO

## A critical hit: one fireball in ten, for double damage.
const CRITICAL_CHANCE := 0.1
const CRITICAL_MULTIPLIER := 2
const COLOR := Color(1.0, 0.58, 0.25)
## How fast a current draws a bolt to its middle line (px/s).
const WIND_PULL := 520.0

var _exploded := false
## The currents it is inside now (WindField -> true).
var _in_winds := {}
## The current it is riding, if any.
var riding: Node = null
## Every current it has turned into, in order (for tests).
var turns: Array = []


func _ready() -> void:
	add_to_group("fireball")
	# Enemies occupy layer 1; terrain may occupy only the solid layer 2.
	collision_mask = 3
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
	if not _exploded:
		_ride_winds(delta)
	position += direction * speed * delta

	# Out of range it sputters out with a small puff
	if global_position.distance_to(start_position) >= max_distance and not _exploded:
		_exploded = true
		ImpactFX.burst(get_parent(), global_position, COLOR, false, 5)
		queue_free()


## Turns into any current it has just flown into, and keeps to the middle of
## the one it rides.
func _ride_winds(delta: float) -> void:
	var manager := RuneManager.get_for(get_tree())
	if manager == null:
		if not _in_winds.is_empty():
			_in_winds.clear()
		return
	var now := {}
	var entered: WindField = null
	for cube in manager.cubes:
		if not cube.is_active or not is_instance_valid(cube.effect) or not cube.effect is WindField:
			continue
		var field: WindField = cube.effect
		if field.carries(global_position):
			now[field] = true
			if not _in_winds.has(field) and (entered == null or field.force > entered.force):
				entered = field
	_in_winds = now
	if entered:
		direction = entered.direction
		riding = entered
		turns.append(entered)
		# The air feeds the flame: its range starts again from here
		start_position = global_position
		Sfx.play("wind_gust", global_position, -16.0, 0.2)
	if riding and is_instance_valid(riding) and _in_winds.has(riding):
		var field: WindField = riding
		var d := global_position - field.origin()
		var lateral := d - field.direction * d.dot(field.direction)
		var length := lateral.length()
		if length > 0.5:
			global_position -= lateral / length * minf(length, WIND_PULL * delta)


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

	# A cube's own portal doorway takes fire that grazes the cube on the way in
	if body.is_in_group("rune_cube_body"):
		var cube := body.get_parent() as RuneCube
		if cube and cube.is_active and cube.effect is RunePortal and (cube.effect as RunePortal).takes_fire_at(global_position):
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


## A bolt made to burst where it lands (a rune with Explode).
func is_bursting() -> bool:
	return float(get_meta(&"explode_radius", 0.0)) > 0.0
