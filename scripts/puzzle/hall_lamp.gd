@tool
class_name HallLamp
extends Node2D

## A hanging lamp of the Lampworks (pixel art: tools/generate_lamp_sprites.gd),
## dark until a circuit powers it, then lit with a warm glow and light. It is a
## circuit target (set_powered) and reads as powered while lit, so a room's
## steps can follow it. Purely a sign of progress: it lights nothing else.
## The node is where its chain meets the lamp; the chain is drawn up from it.

@export var sprite_name := "hall_lamp":
	set(value):
		sprite_name = value
		_rebuild()
@export var chain_length := 48.0:
	set(value):
		chain_length = value
		queue_redraw()
@export var light_energy := 1.1
@export var light_color := Color(1.0, 0.8, 0.48)

var lit := false
var _sprite: Sprite2D
var _light: PointLight2D


func _ready() -> void:
	_rebuild()
	if Engine.is_editor_hint():
		return
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = light_color
	_light.energy = 0.0
	_light.texture_scale = 1.0 + SurfaceArt.size_of(sprite_name).x / 48.0
	_light.position = Vector2(0, SurfaceArt.size_of(sprite_name).y * 0.45)
	_light.shadow_enabled = false
	add_child(_light)


func _rebuild() -> void:
	if not is_inside_tree():
		return
	if _sprite:
		_sprite.queue_free()
	var size := SurfaceArt.size_of(sprite_name)
	_sprite = SurfaceArt.sprite(self, sprite_name, Vector2(0, size.y), 1.0)
	_sprite.texture = SurfaceArt.tex(sprite_name, 1 if lit else 0)
	queue_redraw()


func set_powered(on: bool) -> void:
	if on == lit:
		return
	lit = on
	if _sprite:
		_sprite.texture = SurfaceArt.tex(sprite_name, 1 if lit else 0)
	if _light:
		var t := create_tween()
		t.tween_property(_light, "energy", light_energy if lit else 0.0, 0.6 if lit else 0.3)
	if lit and not Engine.is_editor_hint():
		Sfx.play("brazier_ignite", global_position, -3.0)
		ImpactFX.burst(get_parent(), global_position + Vector2(0, SurfaceArt.size_of(sprite_name).y * 0.45),
			Color(1.0, 0.82, 0.5), true, 10)


func is_powered() -> bool:
	return lit


func _draw() -> void:
	# The chain up to its hook
	var iron := Color("45435a")
	var iron_light := Color("6e6a8c")
	var y := 0.0
	while y > -chain_length:
		draw_rect(Rect2(-2, y - 6, 4, 5), iron)
		draw_rect(Rect2(-1, y - 6, 1, 5), iron_light)
		y -= 7.0
