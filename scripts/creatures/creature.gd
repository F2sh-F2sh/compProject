class_name Creature
extends CharacterBody2D

## The dungeon's roaming creatures, one script for every kind (KINDS), built
## in code from their pixel strips (tools/generate_creature_sprites.gd). Each
## level has its own (CreatureSpawner places them in the stretches between
## puzzles). Four ways of moving:
##   flyer    hovers near home, swoops at Echidna when she comes close, then
##            climbs back (bats, lampmoths)
##   drifter  floats after her slowly, on a leash round home (brine jellies,
##            hushlings: a hushling's touch drains mana instead of health)
##   crawler  walks its ledge, turning at walls and edges, and charges when
##            she is on its level (star mites, clinkers, fold mites; a fold
##            mite blinks a short way toward her)
##   hopper   hops about, and hops at her (cinderlings, frostlings)
## Each answers to the wing's own magic: a cinderling shrugs off fire, a
## frostling takes double from it, a clinker's armour cracks on the first hit.
## Every creature can be frozen (Chill), hurts on contact (DamageArea), leaves
## a mote of mana when defeated, and has its own sounds.

signal defeated

const STRIPS := "res://assets/sprites/creatures/creature_%s.png"
## Pixel art is drawn 1x and shown this many times bigger.
const DRAW_SCALE := 3.0
const DAMAGE_NUMBER := preload("res://scenes/damage_number.tscn")
const GRAVITY := 900.0

## kind: how it moves, health, speeds, sight, contact damage, and its traits.
const KINDS := {
	"bat": {"move": "flyer", "health": 8, "speed": 60.0, "rush": 170.0, "sight": 170.0, "damage": 1, "frames": 2, "puff": Color(0.55, 0.4, 0.75)},
	"moth": {"move": "flyer", "health": 10, "speed": 45.0, "rush": 120.0, "sight": 210.0, "damage": 1, "frames": 2, "puff": Color(1.0, 0.9, 0.6)},
	"jelly": {"move": "drifter", "health": 12, "speed": 22.0, "sight": 150.0, "damage": 1, "frames": 2, "puff": Color(0.5, 0.9, 0.95)},
	"hushling": {"move": "drifter", "health": 10, "speed": 32.0, "sight": 190.0, "damage": 0, "drain": 14.0, "frames": 2, "puff": Color(0.2, 0.2, 0.3)},
	"mite": {"move": "crawler", "health": 8, "speed": 40.0, "rush": 110.0, "sight": 160.0, "damage": 1, "frames": 2, "puff": Color(0.55, 0.55, 0.95)},
	"foldmite": {"move": "crawler", "health": 8, "speed": 45.0, "rush": 90.0, "sight": 170.0, "damage": 1, "blink": true, "frames": 2, "puff": Color(1.0, 0.75, 0.88)},
	"clinker": {"move": "crawler", "health": 14, "speed": 28.0, "rush": 70.0, "sight": 150.0, "damage": 1, "armoured": true, "frames": 2, "puff": Color(0.9, 0.5, 0.25)},
	"cinderling": {"move": "hopper", "health": 16, "speed": 70.0, "rush": 120.0, "sight": 180.0, "damage": 1, "fireproof": true, "frames": 2, "puff": Color(1.0, 0.55, 0.2)},
	"frostling": {"move": "hopper", "health": 14, "speed": 70.0, "rush": 120.0, "sight": 180.0, "damage": 1, "fire_weak": true, "frames": 2, "puff": Color(0.7, 0.9, 1.0)},
}

@export var kind := "bat"
## How far from where it starts it will roam.
@export var home_radius := 220.0

var health := 8
var is_dead := false
var spec: Dictionary
var sprite: AnimatedSprite2D
var home := Vector2.ZERO
var facing := 1.0
var armoured := false
var _time := 0.0
var _state := "idle"
var _state_time := 0.0
var _player: Node2D
var _hop_left := 0.0
var _blink_left := 2.5


func _ready() -> void:
	spec = KINDS.get(kind, KINDS["bat"])
	health = int(spec["health"])
	armoured = spec.get("armoured", false)
	home = global_position
	z_index = 42
	collision_layer = 1
	collision_mask = 2
	add_to_group("enemy")
	add_to_group("creature")
	_build()
	_time = randf() * 10.0


func _build() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	var frames := SpriteFrames.new()
	var strip: Texture2D = load(STRIPS % kind)
	var n := int(spec["frames"])
	var w := strip.get_width() / n
	for i in n:
		var atlas := AtlasTexture.new()
		atlas.atlas = strip
		atlas.region = Rect2(i * w, 0, w, strip.get_height())
		frames.add_frame(&"default", atlas)
	frames.set_animation_speed(&"default", 6.0 if spec["move"] == "flyer" else 4.0)
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * DRAW_SCALE
	sprite.offset = Vector2(0, -strip.get_height() / 2.0)
	sprite.play(&"default")
	add_child(sprite)
	var size := Vector2(w, strip.get_height()) * DRAW_SCALE
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size * 0.6
	shape.shape = rect
	shape.position = Vector2(0, -size.y / 2.0)
	add_child(shape)
	var hit := DamageArea.new()
	hit.name = "DamageArea"
	hit.collision_layer = 0
	hit.collision_mask = 2
	hit.damage_amount = int(spec["damage"])
	hit.knockback = Vector2(140, -120)
	var hit_shape := CollisionShape2D.new()
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = size * 0.7
	hit_shape.shape = hit_rect
	hit_shape.position = shape.position
	hit.add_child(hit_shape)
	add_child(hit)
	if spec["damage"] == 0:
		hit.monitoring = false
	var marker := Marker2D.new()
	marker.name = "Marker2D"
	marker.position = Vector2(0, -size.y)
	add_child(marker)
	if kind in ["cinderling", "moth", "jelly"]:
		var glow := PointLight2D.new()
		glow.texture = preload("res://assets/fx/soft_glow.png")
		glow.texture_scale = 0.8
		glow.energy = 0.6
		glow.color = spec["puff"]
		glow.position = shape.position
		add_child(glow)


func _physics_process(delta: float) -> void:
	_time += delta
	_state_time += delta
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	match String(spec["move"]):
		"flyer":
			_fly(delta)
		"drifter":
			_drift(delta)
		"crawler":
			_crawl(delta)
		"hopper":
			_hop(delta)
	if absf(velocity.x) > 4.0:
		facing = signf(velocity.x)
	sprite.flip_h = facing < 0.0


## Echidna, if she is close enough to notice (and not dead).
func _target() -> Node2D:
	if _player == null or _player.get("is_dead") == true or not _player.visible:
		return null
	if _player.global_position.distance_to(global_position) > float(spec["sight"]):
		return null
	if _player.global_position.distance_to(home) > home_radius + float(spec["sight"]):
		return null
	return _player


func _fly(delta: float) -> void:
	var target := _target()
	match _state:
		"idle":
			var hover := home + Vector2(sin(_time * 0.7) * 40.0, sin(_time * 1.6) * 10.0)
			velocity = (hover - global_position).limit_length(float(spec["speed"]))
			if target and _state_time > 1.2:
				_set_state("rush")
				Sfx.play("creature_alert", global_position, -8.0, 0.1)
		"rush":
			if target == null or _state_time > 1.1:
				_set_state("climb")
			else:
				var aim := target.global_position + Vector2(0, -14)
				velocity = velocity.lerp((aim - global_position).normalized() * float(spec["rush"]), 1.0 - exp(-4.0 * delta))
		"climb":
			velocity = (home - global_position).limit_length(float(spec["speed"]) * 1.4)
			if global_position.distance_to(home) < 12.0 or _state_time > 2.5:
				_set_state("idle")
	move_and_slide()


func _drift(delta: float) -> void:
	var target := _target()
	var goal := home + Vector2(sin(_time * 0.5) * 24.0, sin(_time * 1.1) * 8.0)
	if target:
		goal = target.global_position + Vector2(0, -16)
		if goal.distance_to(home) > home_radius:
			goal = home + (goal - home).limit_length(home_radius)
	velocity = velocity.lerp((goal - global_position).limit_length(float(spec["speed"])), 1.0 - exp(-2.0 * delta))
	move_and_slide()
	# a hushling's touch takes mana, not health
	if spec.has("drain") and _player and _player.global_position.distance_to(global_position + Vector2(0, -14)) < 22.0:
		if "current_mana" in _player and _player.current_mana > 0:
			_player.current_mana = maxi(int(_player.current_mana - float(spec["drain"]) * delta * 4.0), 0)
			if _player.has_method("update_mana_ui"):
				_player.update_mana_ui()
			if int(_time * 4.0) % 4 == 0:
				Sfx.play("creature_drain", global_position, -12.0, 0.1)


func _crawl(delta: float) -> void:
	velocity.y += GRAVITY * delta
	var target := _target()
	var speed := float(spec["speed"])
	if target and absf(target.global_position.y - global_position.y) < 48.0:
		facing = signf(target.global_position.x - global_position.x)
		speed = float(spec["rush"])
		if spec.get("blink", false):
			_blink_left -= delta
			if _blink_left <= 0.0:
				_blink_left = 2.8
				_blink_toward(target)
	elif absf(global_position.x - home.x) > home_radius:
		facing = signf(home.x - global_position.x)
	velocity.x = facing * speed
	move_and_slide()
	if is_on_floor():
		# turn at walls and at the edge of the ledge
		var ahead := global_position + Vector2(facing * 14.0, 4.0)
		var query := PhysicsRayQueryParameters2D.create(ahead, ahead + Vector2(0, 24), 2)
		var floor_ahead := not get_world_2d().direct_space_state.intersect_ray(query).is_empty()
		if is_on_wall() or not floor_ahead:
			facing = -facing
			velocity.x = facing * speed


func _blink_toward(target: Node2D) -> void:
	var step := signf(target.global_position.x - global_position.x) * 64.0
	var to := global_position + Vector2(step, 0)
	var query := PhysicsRayQueryParameters2D.create(to + Vector2(0, -8), to + Vector2(0, 30), 2)
	if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		return
	Sfx.play("portal_warp", global_position, -14.0, 0.1)
	var t := create_tween()
	t.tween_property(sprite, "modulate:a", 0.0, 0.08)
	t.tween_callback(func(): global_position = to)
	t.tween_property(sprite, "modulate:a", 1.0, 0.12)


func _hop(delta: float) -> void:
	velocity.y += GRAVITY * delta
	var target := _target()
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		_hop_left -= delta
		if _hop_left <= 0.0:
			var dir := signf(target.global_position.x - global_position.x) if target else (
				signf(home.x - global_position.x) if absf(global_position.x - home.x) > home_radius * 0.6 else (1.0 if randf() < 0.5 else -1.0))
			velocity = Vector2(dir * float(spec["rush"] if target else spec["speed"]), -230.0 if target else -170.0)
			_hop_left = 0.7 if target else 1.4
			Sfx.play("creature_hop", global_position, -16.0, 0.15)
	move_and_slide()


func _set_state(state: String) -> void:
	_state = state
	_state_time = 0.0


## A hit from a fireball (the game's one damage source): each kind answers in
## its own way.
func take_damage(amount, critical := false) -> void:
	if is_dead:
		return
	if spec.get("fireproof", false):
		Sfx.play("fizzle", global_position, -6.0)
		_flash(Color(1.4, 1.2, 0.8))
		_number("immune", false)
		return
	if armoured:
		armoured = false
		Sfx.play("creature_crack", global_position, -4.0)
		_flash(Color(1.6, 1.0, 0.7))
		sprite.modulate = Color(1.15, 0.9, 0.85)
		_number("cracked", false)
		return
	if spec.get("fire_weak", false):
		amount *= 2
	health -= amount
	Sfx.play("creature_hurt", global_position, -4.0, 0.1)
	_number(str(amount), critical)
	_flash(Color(2.4, 2.2, 2.2))
	if _player:
		var away := signf(global_position.x - _player.global_position.x)
		velocity = Vector2((away if away != 0.0 else 1.0) * 140.0, -80.0)
	if health <= 0:
		die()


func _number(text: String, critical: bool) -> void:
	if not text.is_valid_int():
		FloatText.spawn(get_tree().current_scene, $Marker2D.global_position, text.capitalize(), Color(1.0, 0.85, 0.55))
		return
	var n := DAMAGE_NUMBER.instantiate()
	get_tree().current_scene.add_child(n)
	n.global_position = $Marker2D.global_position
	n.setup(int(text), critical)


func _flash(color: Color) -> void:
	var base := sprite.modulate
	sprite.modulate = color
	var t := create_tween()
	t.tween_property(sprite, "modulate", base, 0.15)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	remove_from_group("enemy")
	var hit := get_node_or_null("DamageArea")
	if hit:
		hit.set_deferred("monitoring", false)
	Sfx.play("creature_die", global_position, -2.0, 0.08)
	defeated.emit()
	Pickup.drop_mote(get_parent(), global_position + Vector2(0, -12), 5)
	if randf() < 0.35:
		Pickup.drop(get_parent(), global_position + Vector2(6, -12), 1)
	var puff := CPUParticles2D.new()
	puff.one_shot = true
	puff.explosiveness = 1.0
	puff.amount = 16
	puff.lifetime = 0.5
	puff.spread = 180.0
	puff.gravity = Vector2(0, 60)
	puff.initial_velocity_min = 30.0
	puff.initial_velocity_max = 70.0
	puff.scale_amount_min = 2.0
	puff.scale_amount_max = 3.0
	puff.color = spec["puff"]
	puff.position = Vector2(0, -10)
	add_child(puff)
	puff.emitting = true
	var t := create_tween().set_parallel()
	t.tween_property(sprite, "scale", Vector2(1.3, 0.2) * DRAW_SCALE, 0.25)
	t.tween_property(sprite, "modulate:a", 0.0, 0.3)
	t.chain().tween_interval(0.5)
	t.chain().tween_callback(queue_free)
