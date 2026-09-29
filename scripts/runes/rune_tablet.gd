@tool
class_name RuneTablet
extends Node2D

## A carved tablet that teaches one rune fragment. Reading it (W) adds the
## fragment to what the player can inscribe on cubes, for good (saved), and
## explains it in a line. Unread tablets glow; read ones stay legible.
## The node's origin is its foot, on the floor.

signal learned(fragment: StringName)

@export var fragment: StringName = &"right":
	set(value):
		fragment = value
		queue_redraw()
## What the carving says, shown when it is read.
@export_multiline var text := ""

var interactable: Interactable
var _time := 0.0
var _face: Node2D


func _ready() -> void:
	_face = Node2D.new()
	_face.material = MagicLight.unshaded()
	_face.draw.connect(_draw_face)
	add_child(_face)
	if Engine.is_editor_hint():
		return
	add_to_group("rune_tablet")
	interactable = Interactable.new()
	interactable.verb = "Read"
	interactable.size = Vector2(56, 64)
	interactable.prompt_offset = Vector2(0, -74)
	add_child(interactable)
	interactable.interacted.connect(_on_read)


func is_learned() -> bool:
	return GameState.has_flag("rune.frag.%s" % fragment)


func _on_read(_by: Node) -> void:
	var first := not is_learned()
	RuneManager.learn(fragment)
	var kind := RuneFragments.kind_of(fragment)
	var line := "%s fragment: %s, %s." % [RuneFragments.KIND_NAMES[kind] if kind >= 0 else "Rune",
		RuneFragments.name_of(fragment).to_upper(), RuneFragments.meaning_of(fragment)]
	if text != "":
		line = text + "\n" + line
	var chapter := get_tree().get_first_node_in_group("chapter_root") as ChapterRoot
	if chapter:
		chapter.show_toast(("You learned a new fragment. " if first else "") + line, 6.0)
	if first:
		Sfx.play("rune_learn", global_position, -3.0, 0.0)
		FloatText.spawn(get_parent(), global_position + Vector2(0, -80), "+ " + RuneFragments.name_of(fragment), RuneFragments.essence_color(fragment), 30.0, 1.8)
		learned.emit(fragment)
	_face.queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if Engine.is_editor_hint() or not is_learned():
		_face.queue_redraw()


func _draw() -> void:
	# A leaning slab on a plinth
	draw_rect(Rect2(-20, -8, 40, 8), Color("241e38"))
	draw_rect(Rect2(-20, -8, 40, 1), Color("4c4468"))
	var slab := PackedVector2Array([Vector2(-16, -8), Vector2(-14, -58), Vector2(-6, -64), Vector2(6, -64), Vector2(14, -58), Vector2(16, -8)])
	draw_colored_polygon(slab, Color("342d4a"))
	draw_polyline(slab, Color("1a1528"), 1.0)
	draw_line(Vector2(-12, -54), Vector2(12, -54), Color("463d62"), 1.0)


func _draw_face() -> void:
	var learned_now := not Engine.is_editor_hint() and is_learned()
	var kind := RuneFragments.kind_of(fragment)
	var col := RuneFragments.essence_color(fragment) if kind == RuneFragments.Kind.ESSENCE else RuneFragments.NEUTRAL
	var pulse := 0.5 + 0.5 * sin(_time * 2.5)
	col.a = 0.55 if learned_now else 0.75 + 0.25 * pulse
	RuneFragments.draw_glyph(_face, fragment, Vector2(0, -34), 20.0, col, 1.5)
	if not learned_now:
		_face.draw_arc(Vector2(0, -34), 15.0, 0.0, TAU, 20, Color(col, 0.25 * pulse), 1.0)
