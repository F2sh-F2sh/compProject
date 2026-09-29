class_name PostFX
extends CanvasLayer

## Drives the dungeon mood shader (assets/shaders/dungeon_post.gdshader).
## Feeds it the camera's world rectangle, so the mist stays attached to the
## world as the camera moves, and the player's position, which is where the
## lantern's pool of light is centred.

@onready var rect: ColorRect = $Screen


func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	var mat := rect.material as ShaderMaterial
	if camera == null or mat == null:
		return
	var size := get_viewport().get_visible_rect().size / camera.zoom
	var origin := camera.get_screen_center_position() - size / 2.0
	mat.set_shader_parameter("world_origin", origin)
	mat.set_shader_parameter("world_size", size)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player:
		# The lantern hangs at chest height
		var lantern := player.global_position + Vector2(0, -20)
		mat.set_shader_parameter("lantern_uv", (lantern - origin) / size)
