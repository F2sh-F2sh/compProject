class_name MeltingFrost
extends Node2D

## A patch of the Hush's frost on a wall (pixel art). It melts away (and drips)
## once `melt_flag` is set, e.g. when the Great Kiln roars; if the flag is
## already set when the level loads, it is simply gone.

@export var sprite_name := "frost_a"
@export var melt_flag := ""
@export var flip := false

var melted := false
var _sprite: Sprite2D


func _ready() -> void:
	z_index = -2
	_sprite = SurfaceArt.sprite(self, sprite_name, Vector2.ZERO, 1.0, flip)
	_sprite.centered = true
	_sprite.offset = Vector2.ZERO
	if melt_flag != "" and GameState.has_flag(melt_flag):
		melted = true
		visible = false


func _process(_delta: float) -> void:
	if melted or melt_flag == "" or not GameState.has_flag(melt_flag):
		return
	melted = true
	# Not all at once: a little later the further it is from the heat
	var t := create_tween()
	t.tween_interval(randf_range(0.4, 2.2))
	t.tween_callback(func():
		Sfx.play("drip", global_position, -10.0, 0.2)
		ImpactFX.burst(get_parent(), global_position, Color(0.7, 0.85, 1.0), false, 6))
	t.tween_property(self, "modulate:a", 0.0, 1.6)
	t.tween_callback(func(): visible = false)
