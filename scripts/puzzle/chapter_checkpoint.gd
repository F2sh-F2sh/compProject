@tool
class_name ChapterCheckpoint
extends Area2D

## A full checkpoint: a stone shrine with a soul-flame. Walking past it lights
## it and makes it the respawn point after a real death. Separate from the
## small spike-recovery candles, which only handle non-lethal spike hits.

@export var checkpoint_id := ""
## Where the player reappears, relative to the shrine (placed on safe ground).
@export var spawn_offset := Vector2(28, -4)

var is_lit := false
var _flame: Node2D
var _light: PointLight2D
var _embers: CPUParticles2D
var _time := 0.0


func _ready() -> void:
	_flame = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_flame.material = mat
	_flame.draw.connect(_draw_flame)
	add_child(_flame)
	if Engine.is_editor_hint():
		return
	add_to_group("chapter_checkpoint")
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48, 160)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0, -80)
	add_child(collider)
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = Color(0.5, 0.7, 1.0)
	_light.energy = 0.0
	_light.texture_scale = 0.9
	_light.position = Vector2(0, -40)
	add_child(_light)
	_embers = GlowFX.embers(Color(0.55, 0.75, 1.0), 7, 22.0, 3.0, 1.6)
	_embers.position = Vector2(0, -52)
	_embers.emitting = false
	add_child(_embers)
	body_entered.connect(_on_body_entered)
	if GameState.get_checkpoint_for(_scene_path()) == checkpoint_id:
		_set_lit(true)


func get_spawn_position() -> Vector2:
	return global_position + spawn_offset


# The level this shrine belongs to (current_scene isn't set yet while loading)
func _scene_path() -> String:
	if owner and owner.scene_file_path != "":
		return owner.scene_file_path
	var scene := get_tree().current_scene
	return scene.scene_file_path if scene else ""


func _on_body_entered(body: Node) -> void:
	if is_lit or not body.is_in_group("player"):
		return
	GameState.set_checkpoint(_scene_path(), checkpoint_id)
	for other in get_tree().get_nodes_in_group("chapter_checkpoint"):
		if other != self:
			other._set_lit(false)
	_set_lit(true)
	Sfx.play("checkpoint", global_position)
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root:
		root.show_toast("The shrine's flame will guide you back here.", 3.0)


func _set_lit(lit: bool) -> void:
	is_lit = lit
	if _embers:
		_embers.emitting = lit
	if _light:
		var tween := create_tween()
		tween.tween_property(_light, "energy", 1.1 if lit else 0.0, 0.5)


func _process(delta: float) -> void:
	_time += delta
	_flame.queue_redraw()
	if is_lit and _light:
		_light.energy = 1.1 + 0.08 * sin(_time * 7.0)


func _draw() -> void:
	# Pillar shrine with a stone bowl
	draw_rect(Rect2(-7, -40, 14, 40), Color("231d38"))
	draw_rect(Rect2(-5, -40, 10, 40), Color("3b3358"))
	draw_rect(Rect2(-5, -40, 2, 40), Color("4a4170"))
	draw_rect(Rect2(-12, -46, 24, 6), Color("2b2442"))
	draw_rect(Rect2(-12, -46, 24, 2), Color("5a4f84"))
	draw_rect(Rect2(-10, -3, 20, 3), Color("1f1a33"))
	# Carved rune on the pillar
	var rune := Color(0.55, 0.72, 1.0) if is_lit else Color(0.3, 0.27, 0.45)
	draw_rect(Rect2(-1, -32, 2, 12), rune)
	draw_rect(Rect2(-4, -27, 8, 2), rune)


func _draw_flame() -> void:
	if not is_lit:
		# Faint embers when unlit
		_flame.draw_rect(Rect2(-2, -49, 4, 2), Color(0.35, 0.45, 0.8, 0.6))
		return
	for i in 3:
		var t := _time * 6.0 + i * 2.1
		var h := 14.0 + sin(t) * 3.0 - i * 3.0
		var w := 8.0 - i * 2.0
		var c: Color = [Color(0.3, 0.5, 1.0, 0.8), Color(0.55, 0.75, 1.0, 0.9), Color(0.9, 0.95, 1.0, 1.0)][i]
		_flame.draw_colored_polygon(PackedVector2Array([
			Vector2(-w / 2.0, -46), Vector2(w / 2.0, -46), Vector2(sin(t * 0.7) * 2.0, -46 - h)]), c)
