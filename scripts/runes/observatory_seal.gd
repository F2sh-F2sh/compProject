@tool
class_name ObservatorySeal
extends Node2D

## The great rune on the observatory wall that ends Chapter 2. Using it
## lights its five essence glyphs one after another (wind, fire, ice, light,
## space), then the whole seal, and the chapter is complete. The node's
## origin is the floor at its foot; the seal hangs above it.

signal opened

const ORDER := [&"wind", &"fire", &"ice", &"light", &"space"]
const RADIUS := 44.0

var is_open := false
var _lit := 0
var _time := 0.0
var _interact: Interactable
var _light: PointLight2D
var _face: Node2D


func _ready() -> void:
	_face = Node2D.new()
	_face.material = MagicLight.unshaded()
	_face.draw.connect(_draw_face)
	add_child(_face)
	if Engine.is_editor_hint():
		return
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = Color(0.8, 0.7, 1.0)
	_light.energy = 0.3
	_light.position = Vector2(0, -90)
	add_child(_light)
	_interact = Interactable.new()
	_interact.verb = "Open the seal"
	_interact.size = Vector2(72, 64)
	_interact.prompt_offset = Vector2(0, -150)
	_interact.echo_can_use = false
	add_child(_interact)
	_interact.interacted.connect(func(_by): open())


func is_powered() -> bool:
	return is_open


func open() -> void:
	if is_open:
		return
	is_open = true
	_interact.enabled = false
	var player := get_tree().get_first_node_in_group("player")
	var root := get_tree().get_first_node_in_group("chapter_root")
	if player:
		player.lock_controls()
	var manager := RuneManager.get_for(get_tree())
	if manager:
		manager.deactivate_all("reset")
	AudioDirector.duck(-18.0, 1.2)
	if root and root.camera:
		root.camera.focus_on(global_position + Vector2(0, -90), 9.0)
	for i in ORDER.size():
		_lit = i + 1
		Sfx.play("rune_activate", global_position + Vector2(0, -90), 0.0, 0.0)
		var tween := create_tween()
		tween.tween_property(_light, "energy", 0.6 + i * 0.25, 0.2)
		await get_tree().create_timer(0.7).timeout
	Sfx.play("portal_open", global_position + Vector2(0, -90), 2.0, 0.0)
	ImpactFX.kick(get_tree(), 3.0, 0.3)
	var t2 := create_tween()
	t2.tween_property(_light, "energy", 2.4, 0.6)
	opened.emit()
	await get_tree().create_timer(1.4).timeout
	if root:
		TitleCard.show_card(root, "", "The observatory opens.", "Above it, for the first time in years, the stars.", 3.4)
	await get_tree().create_timer(4.4).timeout
	AudioDirector.duck(0.0, 3.0)
	if root and root.has_method("finish_chapter"):
		root.finish_chapter()


func _process(delta: float) -> void:
	_time += delta
	_face.queue_redraw()


func _draw() -> void:
	# A stone disc set into the wall on a short plinth
	var c := Vector2(0, -90)
	draw_rect(Rect2(-10, -40, 20, 40), Color("2a2438"))
	draw_circle(c, RADIUS + 6, Color("1c1729"))
	draw_circle(c, RADIUS + 4, Color("3a3350"))
	draw_circle(c, RADIUS - 2, Color("241f33"))


func _draw_face() -> void:
	var c := Vector2(0, -90)
	var pulse := 0.5 + 0.5 * sin(_time * 2.0)
	var ring := Color(0.8, 0.7, 1.0, 0.9 if is_open and _lit >= ORDER.size() else 0.3 + 0.2 * pulse)
	_face.draw_arc(c, RADIUS, 0.0, TAU, 48, ring, 1.5)
	for i in ORDER.size():
		var a := -PI / 2.0 + i * TAU / ORDER.size()
		var p := c + Vector2(cos(a), sin(a)) * (RADIUS - 14.0)
		var col := RuneFragments.essence_color(ORDER[i])
		col.a = 1.0 if i < _lit else 0.35
		RuneFragments.draw_glyph(_face, ORDER[i], p, 16.0, col, 1.5)
	if is_open and _lit >= ORDER.size():
		_face.draw_circle(c, 8.0 + pulse * 3.0, Color(1, 0.95, 1.0, 0.8))
