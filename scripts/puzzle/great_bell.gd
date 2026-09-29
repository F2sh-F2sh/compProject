@tool
class_name GreatBell
extends Node2D

## The great bell at the top of the belfry, and the end of the chapter.
## Pulling its rope rings it three times: the music falls away, the camera
## looks up, rings of sound roll out, embers rise and the belfry slowly fills
## with light. Then the ledger's last line, and the chapter is complete.
## The node marks the bell's mount on the beam.

@export var rope_offset := Vector2(46, 94)
@export var chain_length := 94.0
@export var tolls := 3
@export var toll_gap := 2.2

var _rung := false
var _swing := 0.0
var _swing_speed := 0.0
var _waves: Array[float] = []
var _glow: Node2D
var _light: PointLight2D
var _interact: Interactable
var _time := 0.0


func _ready() -> void:
	_glow = Node2D.new()
	_glow.material = MagicLight.unshaded()
	_glow.draw.connect(_draw_glow)
	_glow.z_index = 2
	add_child(_glow)
	if Engine.is_editor_hint():
		return
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = Color(1.0, 0.82, 0.55)
	_light.energy = 0.25
	_light.texture_scale = 1.6
	_light.position = Vector2(0, 40)
	add_child(_light)
	_interact = Interactable.new()
	_interact.verb = "Ring the great bell"
	_interact.echo_can_use = false
	_interact.size = Vector2(44, 60)
	_interact.position = rope_offset + Vector2(0, 26)
	_interact.prompt_offset = Vector2(0, -76)
	add_child(_interact)
	_interact.interacted.connect(func(_p): ring())


func is_rung() -> bool:
	return _rung


## As a power source: on once the bell has rung.
func is_powered() -> bool:
	return _rung


func ring() -> void:
	if _rung:
		return
	_rung = true
	_interact.enabled = false
	var player := get_tree().get_first_node_in_group("player")
	var root := get_tree().get_first_node_in_group("chapter_root")
	if player:
		player.lock_controls()
	AudioDirector.duck(-20.0, 1.5)
	if root and root.camera:
		root.camera.focus_on(global_position + Vector2(0, 60), tolls * toll_gap + 3.0)
	for i in tolls:
		_toll(i)
		await get_tree().create_timer(toll_gap).timeout
	_fill_with_light()
	await get_tree().create_timer(1.6).timeout
	if root:
		var all_pages: bool = root.pages_found() >= root.total_pages
		TitleCard.show_card(root, "", "The great bell rings out.",
			"Every page of the ledger is yours. It has been so quiet." if all_pages else "It has been so quiet.", 3.4)
	await get_tree().create_timer(4.6).timeout
	AudioDirector.duck(0.0, 3.0)
	if root and root.has_method("finish_chapter"):
		root.finish_chapter()


func _toll(i: int) -> void:
	_swing_speed = 7.0 * (1.0 if i % 2 == 0 else -1.0)
	_waves.append(0.0)
	Sfx.play("great_bell", global_position, 0.0, 0.0)
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(2.5, 0.45)
	var tween := create_tween()
	tween.tween_property(_light, "energy", 1.6, 0.08)
	tween.tween_property(_light, "energy", 0.6, 1.4)
	var embers := GlowFX.embers(Color(1.0, 0.75, 0.4), 24, 60.0, 50.0, 2.2)
	embers.position = Vector2(0, 50)
	embers.one_shot = true
	embers.explosiveness = 0.6
	add_child(embers)
	embers.emitting = true
	embers.finished.connect(embers.queue_free)


# The dark lifts from the belfry: the room's shadow tint brightens
func _fill_with_light() -> void:
	var dark := get_tree().current_scene.get_node_or_null("Darkness") as CanvasModulate
	if dark:
		create_tween().tween_property(dark, "color", Color(0.62, 0.56, 0.66), 4.0).set_trans(Tween.TRANS_SINE)
	create_tween().tween_property(_light, "energy", 1.2, 3.0)


func _process(delta: float) -> void:
	_time += delta
	if Engine.is_editor_hint():
		return
	_swing_speed += -_swing * 18.0 * delta
	_swing_speed *= pow(0.45, delta)
	_swing += _swing_speed * delta
	for i in range(_waves.size() - 1, -1, -1):
		_waves[i] += delta
		if _waves[i] > 2.5:
			_waves.remove_at(i)
	queue_redraw()
	_glow.queue_redraw()


func _draw() -> void:
	var wood := Color("3a2a22")
	var wood_light := Color("5c4636")
	var iron := Color("2b2838")
	# Chains up to the belfry roof, and the beam it hangs from
	for x in [-44.0, 44.0]:
		var y := -10.0
		while y > -10.0 - chain_length:
			draw_rect(Rect2(x - 2.0, y - 7.0, 4, 6), Color("5b5773"), false, 1.0)
			y -= 7.0
	draw_rect(Rect2(-54, -10, 108, 12), wood)
	draw_rect(Rect2(-54, -10, 108, 2), wood_light)
	draw_rect(Rect2(-6, 2, 12, 8), iron)
	# The rope, from the headstock down to where you can reach it
	var corner := Vector2(rope_offset.x, 6)
	draw_line(Vector2(8, 6), corner, Color("7d6a55"), 2.0)
	draw_line(corner, rope_offset, Color("7d6a55"), 2.0)
	draw_rect(Rect2(rope_offset + Vector2(-3, 0), Vector2(6, 12)), Color("8f7a60"))
	# The bell swings about its headstock
	draw_set_transform_matrix(Transform2D(_swing * 0.25, Vector2(0, 10)))
	var bronze := Color("6e5634")
	var bronze_light := Color("a8864f")
	var body := PackedVector2Array([Vector2(-14, 0), Vector2(14, 0), Vector2(20, 18), Vector2(24, 40),
		Vector2(34, 54), Vector2(-34, 54), Vector2(-24, 40), Vector2(-20, 18)])
	draw_colored_polygon(body, bronze)
	draw_polyline(body + PackedVector2Array([body[0]]), Color("3f2f1c"), 1.5)
	draw_line(Vector2(-10, 4), Vector2(-18, 40), bronze_light, 2.0)
	draw_rect(Rect2(-34, 50, 68, 5), Color("5a4428"))
	draw_rect(Rect2(-26, 24, 52, 3), Color("5a4428"))
	draw_circle(Vector2(sin(_swing) * 10.0, 56), 5.0, iron)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_glow() -> void:
	# A faint rune on the bell, and rings of sound rolling out as it tolls
	var t := Transform2D(_swing * 0.25, Vector2(0, 10))
	_glow.draw_set_transform_matrix(t)
	var rune := Color(1.0, 0.85, 0.55, 0.35 + (0.5 if _rung else 0.2 * (0.5 + 0.5 * sin(_time * 2.0))))
	_glow.draw_rect(Rect2(-1, 30, 2, 12), rune)
	_glow.draw_rect(Rect2(-5, 34, 10, 2), rune)
	_glow.draw_set_transform_matrix(Transform2D.IDENTITY)
	for w in _waves:
		var r := 30.0 + w * 170.0
		_glow.draw_arc(Vector2(0, 40), r, 0.0, TAU, 64, Color(1.0, 0.85, 0.6, (1.0 - w / 2.5) * 0.55), 2.0)
