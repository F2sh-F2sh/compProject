@tool
class_name HeartCrucible
extends Node2D

## The Kiln Heart: the Smith's great crucible, sunk in the floor of the Forge
## Bell's tower. It beats with coal and fire together:
##   COAL     three skips of coal tipped into its mouth from the racks above
##            (it counts them: three lamps on its rim);
##   BURNERS  its three burners hanging in the tower lit at the same moment
##            (each flares and dies within a second, so only fire that reaches
##            all three together will do).
## Then it roars: the tower warms, the frost lets go of the Forge Bell, its
## burners burn steady, and it powers whatever its circuit drives (the bell
## hoist). It says why when the
## burners flare together over an empty crucible. Saved once it beats; each
## skip it has taken stays taken (WindBody.persist_id). Its coal is solid
## underfoot. Pixel art (tools/generate_kiln_sprites.gd).
## The node sits on the pit floor, centred on the crucible (128 px wide).

signal power_changed(powered: bool)

const WIDTH := 128.0
const HEIGHT := 88.0
const FUEL_NEEDED := 3
## Its mouth, where the coal falls in (local).
const MOUTH := Rect2(-56, -104, 112, 48)

## Saved once it beats.
@export var persist_id := ""
## The three burners (braziers that flare and die) that must burn together.
@export var burners: Array[NodePath] = []
## Its skips' saved ids (WindBody.persist_id): the coal it holds after a reload.
@export var coal_ids: PackedStringArray = []

var fuel := 0
var roaring := false
## The same as numbers, for objective steps (1 = all its coal is in).
var fuel_state: int:
	get:
		return 1 if fuel >= FUEL_NEEDED or roaring else 0
## What the last time all three burners flared together came to: "", "no_coal", "roar".
var last_attempt := ""

var _sprite: AnimatedSprite2D
var _lamps: Array[AnimatedSprite2D] = []
var _light: PointLight2D
var _embers: CPUParticles2D
var _burners: Array = []
var _all_lit_before := false
var _single_note_at := -100000
var _time := 0.0


func _ready() -> void:
	_sprite = SurfaceArt.animated(self, "heart_crucible", Vector2.ZERO, 0.0, 1.0)
	_sprite.name = "Body"
	_sprite.stop()
	for i in FUEL_NEEDED:
		var lamp := SurfaceArt.animated(self, "lamp_fuel", Vector2(-28 + i * 28, -46), 0.0, 1.0)
		lamp.name = "Coal%d" % (i + 1)
		lamp.stop()
		_lamps.append(lamp)
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	_build_body()
	_build_mouth()
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = Color(1.0, 0.6, 0.3)
	_light.energy = 0.0
	_light.texture_scale = 4.0
	_light.position = Vector2(0, -90)
	_light.shadow_enabled = false
	add_child(_light)
	_embers = GlowFX.embers(Color(1.0, 0.62, 0.26), 30, 110.0, 50.0, 2.4)
	_embers.position = Vector2(0, -90)
	_embers.emitting = false
	add_child(_embers)
	for path in burners:
		var b := get_node_or_null(path)
		if b:
			_burners.append(b)
	for id in coal_ids:
		if GameState.has_flag(id):
			fuel += 1
	if persist_id != "" and GameState.has_flag(persist_id):
		fuel = FUEL_NEEDED
		_set_roaring(true, true)
	_refresh_lamps()


## Solid iron sides and a bed of coal at the floor's level she can walk on.
func _build_body() -> void:
	var body := StaticBody2D.new()
	body.name = "Iron"
	body.collision_layer = 3
	body.collision_mask = 0
	body.add_to_group("world")
	add_child(body)
	for r in [Rect2(-WIDTH / 2.0, -64, WIDTH, 64), Rect2(-WIDTH / 2.0, -HEIGHT, 10, 24), Rect2(WIDTH / 2.0 - 10, -HEIGHT, 10, 24)]:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		shape.shape = rect
		shape.position = r.get_center()
		body.add_child(shape)


func _build_mouth() -> void:
	var mouth := Area2D.new()
	mouth.name = "Mouth"
	mouth.collision_layer = 0
	mouth.collision_mask = 1
	mouth.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = MOUTH.size
	shape.shape = rect
	shape.position = MOUTH.get_center()
	mouth.add_child(shape)
	add_child(mouth)
	mouth.body_entered.connect(_on_mouth_entered)


func is_powered() -> bool:
	return roaring


## A beating Heart is a flame she can kindle her lantern at.
func is_kindling() -> bool:
	return roaring


func _on_mouth_entered(body: Node) -> void:
	if roaring or not body.is_in_group("coal") or not body.has_method("consume") or body.get("is_consumed") == true:
		return
	body.consume(false)
	fuel = mini(fuel + 1, FUEL_NEEDED)
	_refresh_lamps()
	Sfx.play("crumble_fall", global_position + Vector2(0, -70), 0.0, 0.0)
	Sfx.play("receiver_on", global_position + Vector2(0, -70), -4.0, 0.0)
	ImpactFX.burst(get_parent(), global_position + Vector2(0, -70), Color(0.3, 0.3, 0.4), true, 14)
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root:
		root.show_toast("Coal tumbles into the Heart: %d of %d." % [fuel, FUEL_NEEDED] if fuel < FUEL_NEEDED
			else "The Heart is full of coal. Now its three burners, all at once.", 3.5)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	if roaring:
		_light.energy = 1.5 + 0.2 * sin(_time * 7.0) + 0.1 * sin(_time * 19.0)
		return
	var lit := 0
	for b in _burners:
		if is_instance_valid(b) and b.is_lit:
			lit += 1
	var all_lit := not _burners.is_empty() and lit == _burners.size()
	if all_lit and not _all_lit_before:
		_burners_flared_together()
	elif lit > 0 and not all_lit and Time.get_ticks_msec() - _single_note_at > 9000:
		_single_note_at = Time.get_ticks_msec()
		var root := get_tree().get_first_node_in_group("chapter_root")
		if root:
			root.show_toast("A burner flares and dies. The Heart wants all three burning at the same moment.", 4.0)
	_all_lit_before = all_lit


func _burners_flared_together() -> void:
	if fuel < FUEL_NEEDED:
		last_attempt = "no_coal"
		Sfx.play("fire_blast", global_position + Vector2(0, -70), -4.0)
		ImpactFX.burst(get_parent(), global_position + Vector2(0, -80), Color(1.0, 0.6, 0.3), false, 12)
		var root := get_tree().get_first_node_in_group("chapter_root")
		if root:
			root.show_toast("All three burners flare at once, but the Heart is cold: it has %d of its %d skips of coal." % [fuel, FUEL_NEEDED], 4.5)
		return
	last_attempt = "roar"
	_set_roaring(true, false)


func _set_roaring(on: bool, silent: bool) -> void:
	roaring = on
	_sprite.frame = 1 if on else 0
	_embers.emitting = on
	_refresh_lamps()
	if not on:
		_light.energy = 0.0
		if is_in_group("kindle_point"):
			remove_from_group("kindle_point")
		power_changed.emit(false)
		return
	add_to_group("kindle_point")
	if persist_id != "":
		GameState.set_flag(persist_id)
	# Its burners burn steady now (and after a reset or a reload)
	for b in _burners:
		if is_instance_valid(b):
			b.burn_time = 0.0
			b.start_lit = true
			b.reset_state()
	if silent:
		_light.energy = 1.5
		power_changed.emit(true)
		return
	# The Heart beats: a roar, heat climbing the tower, the frost letting go
	Sfx.play("fire_blast", global_position + Vector2(0, -60), 2.0, 0.0)
	Sfx.play("brazier_ignite", global_position + Vector2(0, -60), 2.0, 0.0)
	Sfx.play("gate_rumble", global_position, 0.0, 0.0)
	ImpactFX.kick(get_tree(), 4.0, 0.5)
	for k in 6:
		ImpactFX.burst(get_parent(), global_position + Vector2(randf_range(-60, 60), -randf_range(40, 200)), Color(1.0, 0.6, 0.25), false, 18)
	create_tween().tween_property(_light, "energy", 1.5, 1.6).from(3.5)
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root:
		root.camera.focus_on(global_position + Vector2(0, -160), 2.4)
		TitleCard.show_card(root, "", "The Kiln Heart beats.", "Heat climbs the tower, and the frost lets go of the Forge Bell.", 3.4)
	power_changed.emit(true)


func _refresh_lamps() -> void:
	for i in _lamps.size():
		_lamps[i].frame = 1 if roaring or fuel > i else 0


func reset_state() -> void:
	# The coal it has taken stays taken (each skip is saved), and a beating
	# Heart keeps beating
	last_attempt = ""
	_all_lit_before = false
