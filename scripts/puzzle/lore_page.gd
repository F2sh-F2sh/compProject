@tool
class_name LorePage
extends Area2D

## An optional collectible scrap of lore. Collected pages are remembered by
## id, so they never reappear or count twice after a death or reload.

@export var page_id := ""
@export var title := "A Torn Page"
@export_multiline var text := ""

var _time := 0.0
var _collected := false
var _glow: Node2D


func _ready() -> void:
	_glow = Node2D.new()
	_glow.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_glow.material = mat
	_glow.draw.connect(_draw_page)
	add_child(_glow)
	if Engine.is_editor_hint():
		return
	if GameState.has_flag(page_id):
		queue_free()
		return
	add_to_group("lore_page")
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	var light := PointLight2D.new()
	light.texture = LightTextures.radial(128)
	light.color = Color(0.85, 0.8, 1.0)
	light.energy = 0.6
	add_child(light)
	# A slow, breathing halo marks it as something worth picking up
	_glow.add_child(GlowFX.halo(Color(0.72, 0.62, 1.0), 18.0, 0.4, 2.2, 0.3, 0.05))
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_glow.position.y = sin(_time * 2.2) * 3.0
	_glow.queue_redraw()


func _on_body_entered(body: Node) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	GameState.set_flag(page_id)
	Sfx.play("collect", global_position)
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root and PageReader.enabled:
		PageReader.open(root, title, text, root.pages_found(), root.total_pages)
	elif root:
		root.show_toast("%s\n\n%s" % [title, text], 7.0)
	var tween := create_tween().set_parallel()
	tween.tween_property(_glow, "position:y", -30.0, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.chain().tween_callback(queue_free)


func _draw_page() -> void:
	# A small curled parchment with faint writing, glowing softly
	var pulse := 0.6 + 0.4 * sin(_time * 3.0)
	_glow.draw_circle(Vector2.ZERO, 11.0, Color(0.55, 0.5, 1.0, 0.12 * pulse))
	_glow.draw_rect(Rect2(-6, -8, 12, 15), Color("d9cfee"))
	_glow.draw_rect(Rect2(-6, -8, 12, 2), Color("b9accf"))
	_glow.draw_rect(Rect2(4, 5, 2, 2), Color("9e90b8"))
	for i in 4:
		_glow.draw_rect(Rect2(-4, -4 + i * 3, 7 - (i % 2) * 2, 1), Color("6f6488"))
