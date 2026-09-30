class_name Villager
extends Node2D

## A villager of Lowbell: a pixel-art figure (tools/generate_story_sprites.gd)
## with Echidna's kind of face, dark with two pale eyes, who breathes,
## blinks, and turns to look at her when she comes close, then says their
## line. The Hush has taken some of their words: write those as {n} in `line`
## (n glyphs are shown instead). The node stands at the figure's feet.

@export_multiline var line := ""
## Which sprite strip in assets/sprites/story (tam, mira, pip, edda, nan).
@export var sprite_name := "tam"
@export var facing := -1
@export var talk_range := 70.0
@export var art_scale := SurfaceArt.LANE_SCALE

var bubble: SpeechBubble
var heard := false
var figure: AnimatedSprite2D
var _player: Node2D
var _time := 0.0
var _blink := 0.0
var _next_blink := 3.0
var _near := false


func _ready() -> void:
	add_to_group("villager")
	figure = SurfaceArt.animated(self, sprite_name, Vector2.ZERO, 0.0, art_scale)
	figure.name = "Figure"
	figure.stop()
	var height := SurfaceArt.size_of(sprite_name).y * art_scale
	bubble = SpeechBubble.new()
	bubble.text = line
	bubble.position = Vector2(0, -height - 12.0)
	add_child(bubble)
	_time = randf() * 3.0
	_next_blink = randf_range(1.5, 4.0)


func _process(delta: float) -> void:
	_time += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.14
		_next_blink = randf_range(2.5, 5.5)
	_blink = maxf(_blink - delta, 0.0)
	# Frames: 0 standing, 1 breathing in, 2 blinking
	figure.frame = 2 if _blink > 0.0 else (1 if fmod(_time, 2.4) > 1.3 else 0)
	figure.flip_h = facing < 0
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	var near := false
	if is_instance_valid(_player) and _player.visible:
		var d := _player.global_position - global_position
		near = absf(d.x) < talk_range and absf(d.y) < 60.0
		if near and absf(d.x) > 4.0:
			facing = 1 if d.x > 0.0 else -1
	if near != _near:
		_near = near
		if near:
			heard = true
			bubble.show_bubble()
		else:
			bubble.hide_bubble()
