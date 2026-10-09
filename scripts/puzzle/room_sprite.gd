class_name RoomSprite
extends Node2D

## A hand-made pixel sprite (SurfaceArt) standing in a room: Ilse and Wren's
## bed in the Eye, the Smith's anvil, Wren's chalk marks... Built at run time,
## so the scene only names it. The node's origin is the sprite's foot.

@export var sprite_name := "ilse"
@export var sprite_scale := 2.0
## Plays its frames (Ilse breathes); otherwise it holds the first.
@export var play := true
@export var flip := false
## Unaffected by the dungeon's light (chalk glows faintly in the dark).
@export var unshaded := false


func _ready() -> void:
	if sprite_name in ["nan", "wren", "ilse", "tam", "mira", "pip", "edda", "monk"]:
		sprite_scale = 64.0 / SurfaceArt.size_of(sprite_name).y
	var sprite := SurfaceArt.animated(self, sprite_name, Vector2.ZERO, 3.0, sprite_scale, flip)
	sprite.name = "Sprite"
	if not play:
		sprite.stop()
	if unshaded:
		sprite.material = MagicLight.unshaded()
