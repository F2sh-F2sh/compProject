@tool
class_name GreatKiln
extends Node2D

## The Great Kiln of the Cold Forge. It wakes only with all three of:
##   FUEL  coal in its fuel bay (the coal cart pushed in at the right side),
##   AIR   a wind current blowing into the pipe on its left side,
##   FIRE  a bursting flame (a bolt with Explode) reaching the firebox at the
##         inner end of that pipe.
## Direct shots can't reach the firebox: the pipe is the only way in, so the
## fire has to ride the air (see FireBall). A plain spark only hisses on the
## frosted coal; a burst with no coal or no air dies, and the kiln says why.
## Once it roars it stays lit (saved): it lights the hall, melts the frost,
## powers whatever its circuit drives (the Forge Door) and is a flame to
## kindle at. Three lamps on its face show FUEL, AIR and FIRE.
## The node sits on the floor surface at the kiln's bottom centre; the kiln is
## 320 px wide and 260 tall (its roof flush with a floating ledge beside it),
## its pipe (the inlet) 88 px tall on the left.

signal power_changed(powered: bool)
signal attempted(result: String)

const WIDTH := 320.0
const HEIGHT := 260.0
## The pipe through the left wall: from the outside to the firebox.
const PIPE := Rect2(-160, -142, 92, 88)
## The fuel bay at the bottom of the right side.
const BAY := Rect2(96, -64, 64, 64)
## A current counts as air once it pushes this hard into the pipe.
const AIR_FORCE := 600.0

## Saved once it roars.
@export var persist_id := ""
## Saved once its fuel is in.
@export var fuel_persist_id := ""

var fuel := false
var air := false
var roaring := false
## The same as numbers, for objective steps (1 = yes).
var fuel_state: int:
	get:
		return 1 if fuel or roaring else 0
var air_state: int:
	get:
		return 1 if air or roaring else 0
## What the last try at lighting it came to: "", "spark", "no_fuel", "no_air", "roar".
var last_attempt := ""

var _sprite: AnimatedSprite2D
var _chimney: AnimatedSprite2D
var _lamps := {}
var _light: PointLight2D
var _mouth_light: PointLight2D
var _embers: CPUParticles2D
var _smoke: CPUParticles2D
var _body: StaticBody2D
var _air_force := Vector2.ZERO
var _inlet: KilnInlet
var _roof_spot: KindleSpot
var _time := 0.0


func _ready() -> void:
	_sprite = SurfaceArt.animated(self, "great_kiln", Vector2.ZERO, 0.0, 1.0)
	_sprite.name = "Body"
	_sprite.stop()
	_chimney = SurfaceArt.animated(self, "kiln_chimney", Vector2(64, -HEIGHT + 2), 0.0, 1.0)
	_chimney.name = "Chimney"
	_chimney.stop()
	_chimney.z_index = -1
	var i := 0
	for kind in ["fuel", "air", "fire"]:
		var lamp := SurfaceArt.animated(self, "lamp_" + kind, Vector2(-30 + i * 30, -96), 0.0, 1.0)
		lamp.name = "Lamp" + kind.capitalize()
		lamp.stop()
		_lamps[kind] = lamp
		i += 1
	if Engine.is_editor_hint():
		return
	add_to_group("great_kiln")
	add_to_group("resettable")
	_build_body()
	_build_bay()
	_build_firebox()
	_roof_spot = KindleSpot.new()
	_roof_spot.name = "RoofFlame"
	_roof_spot.kiln = self
	_roof_spot.position = Vector2(0, -HEIGHT)
	add_child(_roof_spot)
	_inlet = KilnInlet.new()
	_inlet.name = "Inlet"
	_inlet.kiln = self
	_inlet.position = Vector2(PIPE.position.x - 16, PIPE.position.y + 8)
	add_child(_inlet)
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = Color(1.0, 0.62, 0.32)
	_light.energy = 0.0
	_light.texture_scale = 5.0
	_light.position = Vector2(0, -120)
	_light.shadow_enabled = false
	add_child(_light)
	_mouth_light = PointLight2D.new()
	_mouth_light.texture = LightTextures.radial(256)
	_mouth_light.color = Color(1.0, 0.55, 0.25)
	_mouth_light.energy = 0.0
	_mouth_light.texture_scale = 1.6
	_mouth_light.position = Vector2(0, -40)
	add_child(_mouth_light)
	_embers = GlowFX.embers(Color(1.0, 0.6, 0.25), 26, 90.0, 22.0, 2.0)
	_embers.position = Vector2(64, -HEIGHT - 70)
	_embers.emitting = false
	add_child(_embers)
	_smoke = GlowFX.embers(Color(0.55, 0.5, 0.6), 10, 60.0, 10.0, 2.6)
	_smoke.position = Vector2(64, -HEIGHT - 72)
	add_child(_smoke)
	if fuel_persist_id != "" and GameState.has_flag(fuel_persist_id):
		fuel = true
		_take_coal.call_deferred(true)
	if persist_id != "" and GameState.has_flag(persist_id):
		fuel = true
		_set_roaring(true, true)
	_refresh_lamps()


## Solid brick everywhere except the pipe on the left and the bay on the right;
## its top is a roof she can walk on.
func _build_body() -> void:
	_body = StaticBody2D.new()
	_body.name = "Brick"
	_body.collision_layer = 3
	_body.collision_mask = 0
	_body.add_to_group("world")
	add_child(_body)
	for r in [Rect2(-160, -HEIGHT, WIDTH, HEIGHT + PIPE.position.y), Rect2(-160, PIPE.end.y, PIPE.size.x, -PIPE.end.y),
			Rect2(PIPE.end.x, PIPE.position.y, BAY.position.x - PIPE.end.x, -PIPE.position.y),
			Rect2(BAY.position.x, PIPE.position.y, BAY.size.x, BAY.position.y - PIPE.position.y)]:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		shape.shape = rect
		shape.position = r.get_center()
		_body.add_child(shape)


func _build_bay() -> void:
	var bay := Area2D.new()
	bay.name = "FuelBay"
	bay.collision_layer = 0
	bay.collision_mask = 1
	bay.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = BAY.size - Vector2(8, 8)
	shape.shape = rect
	shape.position = BAY.get_center() + Vector2(-4, 0)
	bay.add_child(shape)
	add_child(bay)
	bay.body_entered.connect(func(b):
		if not fuel and b.is_in_group("coal"):
			_take_coal(false))


func _build_firebox() -> void:
	var box := Area2D.new()
	box.name = "Firebox"
	box.collision_layer = 0
	box.collision_mask = 1
	box.monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	box.add_child(shape)
	box.position = Vector2(PIPE.end.x - 14, PIPE.get_center().y)
	add_child(box)
	box.area_entered.connect(func(area):
		if area.is_in_group("fireball") and area.has_method("explode"):
			var bursting: bool = area.has_method("is_bursting") and area.is_bursting()
			area.explode()
			try_light(bursting))


## The air pipe's state (from its inlet, which takes the wind).
func set_air_force(force: Vector2) -> void:
	_air_force = force


func is_powered() -> bool:
	return roaring


## A roaring kiln is a flame she can kindle her lantern at.
func is_kindling() -> bool:
	return roaring


## A flame has reached the firebox: does the kiln catch?
func try_light(bursting: bool) -> void:
	if roaring:
		return
	var result := "roar"
	if not bursting:
		result = "spark"
	elif not fuel:
		result = "no_fuel"
	elif not air:
		result = "no_air"
	last_attempt = result
	attempted.emit(result)
	var root := get_tree().get_first_node_in_group("chapter_root") as ChapterRoot
	match result:
		"spark":
			Sfx.play("fizzle", global_position + Vector2(-90, -98), 0.0, 0.0)
			_flash_lamp("fire")
			_puff(Color(0.7, 0.7, 0.8))
			if root:
				root.show_toast("A spark only hisses on the frosted coal. The kiln needs a flame that bursts.", 4.5)
		"no_fuel":
			Sfx.play("fire_blast", global_position + Vector2(-90, -98), -4.0)
			_flash_lamp("fire")
			_flash_lamp("fuel")
			_puff(Color(1.0, 0.6, 0.3))
			if root:
				root.show_toast("The flame bursts in an empty firebox and dies: there is no coal in the kiln.", 4.5)
		"no_air":
			Sfx.play("fire_blast", global_position + Vector2(-90, -98), -4.0)
			_flash_lamp("fire")
			_flash_lamp("air")
			_puff(Color(1.0, 0.6, 0.3))
			if root:
				root.show_toast("The coal catches, then chokes. Without air in its pipe the kiln will not draw.", 4.5)
		"roar":
			_set_roaring(true, false)


func _set_roaring(on: bool, silent: bool) -> void:
	roaring = on
	_sprite.frame = 1 if on else 0
	_chimney.frame = 1 if on else 0
	_embers.emitting = on
	if on:
		_roof_spot.add_to_group("kindle_point")
	elif _roof_spot.is_in_group("kindle_point"):
		_roof_spot.remove_from_group("kindle_point")
	_refresh_lamps()
	if not on:
		_light.energy = 0.0
		_mouth_light.energy = 0.0
		power_changed.emit(false)
		return
	if persist_id != "":
		GameState.set_flag(persist_id)
	if silent:
		_light.energy = 1.2
		_mouth_light.energy = 1.6
		_warm_the_hall.call_deferred(true)
		power_changed.emit(true)
		return
	# The kiln wakes: a roar, a wave of heat and light, the hall turns warm
	Sfx.play("fire_blast", global_position + Vector2(0, -60), 2.0, 0.0)
	Sfx.play("brazier_ignite", global_position + Vector2(0, -60), 2.0, 0.0)
	Sfx.play("gate_rumble", global_position, 0.0, 0.0)
	Sfx.play("great_bell", global_position + Vector2(0, -120), -10.0, 0.0)
	ImpactFX.kick(get_tree(), 4.0, 0.5)
	for k in 5:
		ImpactFX.burst(get_parent(), global_position + Vector2(randf_range(-90, 90), -randf_range(20, 180)), Color(1.0, 0.6, 0.25), false, 18)
	var t := create_tween().set_parallel()
	t.tween_property(_light, "energy", 1.2, 1.6).from(3.0)
	t.tween_property(_mouth_light, "energy", 1.6, 0.6)
	_warm_the_hall(false)
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root:
		root.camera.focus_on(global_position + Vector2(0, -140), 2.4)
		TitleCard.show_card(root, "", "The Great Kiln roars.", "Heat runs through the iron, and the frost lets go.", 3.4)
	power_changed.emit(true)


## The level's shadows turn from cold to warm as the kiln burns.
func _warm_the_hall(instant: bool) -> void:
	var scene: Node = owner if owner else get_tree().current_scene
	var dark := scene.get_node_or_null("Darkness") as CanvasModulate if scene else null
	if dark == null:
		return
	var warm := Color(0.74, 0.6, 0.56)
	if instant:
		dark.color = warm
	else:
		create_tween().tween_property(dark, "color", warm, 3.0).set_trans(Tween.TRANS_SINE)


func _take_coal(silent: bool) -> void:
	fuel = true
	if fuel_persist_id != "":
		GameState.set_flag(fuel_persist_id)
	var cart := get_tree().get_first_node_in_group("coal")
	if cart and cart.has_method("consume"):
		cart.consume(silent)
	_refresh_lamps()
	if not silent:
		Sfx.play("crumble_fall", global_position + BAY.get_center(), 0.0, 0.0)
		Sfx.play("receiver_on", global_position + BAY.get_center(), -4.0, 0.0)
		ImpactFX.burst(get_parent(), global_position + BAY.get_center(), Color(0.3, 0.3, 0.4), true, 16)
		var root := get_tree().get_first_node_in_group("chapter_root")
		if root:
			root.show_toast("The coal tumbles into the kiln. One lamp lit: FUEL.", 3.5)


func _refresh_lamps() -> void:
	if _lamps.is_empty():
		return
	(_lamps["fuel"] as AnimatedSprite2D).frame = 1 if fuel or roaring else 0
	(_lamps["air"] as AnimatedSprite2D).frame = 1 if air or roaring else 0
	(_lamps["fire"] as AnimatedSprite2D).frame = 1 if roaring else 0


func _flash_lamp(kind: String) -> void:
	var lamp: AnimatedSprite2D = _lamps[kind]
	var t := create_tween()
	for k in 3:
		t.tween_callback(func(): lamp.frame = 1)
		t.tween_interval(0.12)
		t.tween_callback(func(): lamp.frame = 0)
		t.tween_interval(0.12)
	t.tween_callback(_refresh_lamps)


func _puff(color: Color) -> void:
	ImpactFX.burst(get_parent(), global_position + Vector2(PIPE.position.x + 8, PIPE.get_center().y), color, false, 12)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	var was := air
	air = _air_force.x >= AIR_FORCE
	_air_force = Vector2.ZERO
	if air != was:
		_refresh_lamps()
		if air and not roaring:
			Sfx.play("wind_gust", global_position + Vector2(PIPE.position.x, PIPE.get_center().y), -6.0)
	if roaring:
		_mouth_light.energy = 1.6 + 0.2 * sin(_time * 9.0) + 0.1 * sin(_time * 23.0)
	elif air:
		# Air through a cold kiln: the ash stirs
		_mouth_light.energy = 0.15 + 0.05 * sin(_time * 6.0)


func reset_state() -> void:
	last_attempt = ""
	if roaring:
		return
	air = false
	if fuel_persist_id != "" and GameState.has_flag(fuel_persist_id):
		return
	fuel = false
	_refresh_lamps()


## The kiln's air pipe as wind sees it: a small box at the pipe's mouth that
## takes the summed force of every current reaching it (see RuneManager).
class KilnInlet extends Node2D:
	var kiln: GreatKiln
	const SIZE := Vector2(16, 72)

	func _ready() -> void:
		add_to_group("wind_receiver")

	func get_bounds() -> Rect2:
		return Rect2(global_position, SIZE)

	func set_wind_force(force: Vector2) -> void:
		if kiln:
			kiln.set_air_force(force)

	func apply_wind_impulse(_impulse: Vector2) -> void:
		pass


## Where she kindles at a roaring kiln: on its roof, over the fire.
class KindleSpot extends Node2D:
	var kiln: GreatKiln

	func is_kindling() -> bool:
		return kiln != null and kiln.roaring
