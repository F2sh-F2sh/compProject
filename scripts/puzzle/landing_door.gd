@tool
class_name LandingDoor
extends Node2D

## One of the five doors on the Landing at the foot of the Long Stair: four to
## the wings (each opens once the wing before it has rung its bell) and the
## last to the Eye (it opens when all four bells have rung). A bell-light over
## each door is lit once its wing's bell has rung. The node's origin is the
## door's foot. Pixel art (door_nan, shrine_bell), tinted per wing.

## 0 to 3: the wings in order; 4: the Eye.
@export_range(0, 4) var index := 0
@export var tint := Color.WHITE
@export var label_text := ""

const DOOR := "door_nan"
const BELL := "shrine_bell"
const SCALE := 3.0
const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")

var interactable: Interactable
var _door: AnimatedSprite2D
var _bell: Sprite2D
var _light: PointLight2D
var _label: Label
var _time := 0.0
## The Hush's rime over a door that is still sealed (pixel art).
var _frost: Sprite2D
## Warm light and drips under the door that is open and not yet done: the way on.
var _warmth: PointLight2D
var _drips: CPUParticles2D
## The warm glow that spills out under that door (a light alone barely shows
## on the blue stone).
var _spill: Sprite2D


func _ready() -> void:
	_door = SurfaceArt.animated(self, DOOR, Vector2.ZERO, 0.0, SCALE)
	_door.name = "Door"
	_door.stop()
	var height := SurfaceArt.size_of(DOOR).y * SCALE
	_bell = SurfaceArt.sprite(self, BELL, Vector2(0, -height - 14.0), 3.0)
	_bell.name = "BellLight"
	_frost = SurfaceArt.sprite(self, "door_frost", Vector2.ZERO, SCALE)
	_frost.name = "Frost"
	_label = Label.new()
	_label.text = label_text
	_label.add_theme_font_override("font", FONT)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.95))
	_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.05, 0.9))
	_label.add_theme_constant_override("outline_size", 4)
	# Over the bell-light (at the foot it hid in the floor's grass)
	_label.position = Vector2(-60, -height - 14.0 - SurfaceArt.size_of(BELL).y * 3.0 - 20.0)
	_label.size = Vector2(120, 16)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	if Engine.is_editor_hint():
		return
	add_to_group("landing_door")
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(128)
	_light.color = tint
	_light.energy = 0.0
	_light.texture_scale = 0.8
	_light.position = Vector2(0, -height - 14.0)
	add_child(_light)
	_warmth = PointLight2D.new()
	_warmth.texture = LightTextures.radial(256)
	_warmth.color = Color(1.0, 0.58, 0.28)
	_warmth.energy = 0.0
	_warmth.texture_scale = 1.6
	_warmth.position = Vector2(0, -height * 0.4)
	add_child(_warmth)
	_drips = GlowFX.embers(Color(1.0, 0.7, 0.4), 12, -40.0, 30.0, 1.6)
	_drips.position = Vector2(0, -height + 6)
	_drips.emitting = false
	add_child(_drips)
	_spill = Sprite2D.new()
	_spill.texture = LightTextures.radial(128)
	_spill.scale = Vector2(1.5, 0.5)
	_spill.position = Vector2(0, -6)
	_spill.z_index = 1
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_spill.material = mat
	_spill.modulate = Color(1.0, 0.55, 0.22, 0.0)
	add_child(_spill)
	interactable = Interactable.new()
	interactable.verb = "Open"
	interactable.echo_can_use = false
	interactable.size = Vector2(56, height)
	interactable.prompt_offset = Vector2(0, -height * 0.55)
	add_child(interactable)
	interactable.interacted.connect(_on_used)
	refresh()


## The scene this door leads to.
func target_scene() -> String:
	if index >= Journey.WINGS.size():
		return Journey.EYE_INTERLUDE
	return Journey.WINGS[index]["scene"]


func is_open() -> bool:
	return Journey.eye_open() if index >= Journey.WINGS.size() else Journey.wing_open(index)


## Whether this wing's bell has rung (for the Eye: the game is finished).
func is_done() -> bool:
	if index >= Journey.WINGS.size():
		return GameState.has_flag("eye.complete")
	return Journey.wing_done(index)


func refresh() -> void:
	_door.frame = 1 if is_open() else 0
	if is_done():
		_bell.modulate = tint
	else:
		_bell.modulate = Color(0.28, 0.28, 0.36)
	_frost.visible = not is_open()
	if interactable:
		interactable.verb = "Open" if is_open() else "Sealed with frost"
	if _drips:
		_drips.emitting = is_warm()


## The door that leads on: open, and its bell not rung yet. Warm air seeps
## from under it and the frost on it has melted.
func is_warm() -> bool:
	return is_open() and not is_done()


func _process(delta: float) -> void:
	_time += delta
	if _light:
		var want := 0.9 + 0.1 * sin(_time * 2.0) if is_done() else (0.6 if is_open() else 0.15)
		_light.energy = lerpf(_light.energy, want, minf(delta * 4.0, 1.0))
	if _warmth:
		var flicker := 0.2 * sin(_time * 3.1) + 0.08 * sin(_time * 11.0)
		var warm := is_warm()
		_warmth.energy = lerpf(_warmth.energy, 1.3 + flicker if warm else 0.0, minf(delta * 3.0, 1.0))
		_spill.modulate.a = lerpf(_spill.modulate.a, 0.6 + flicker * 0.5 if warm else 0.0, minf(delta * 3.0, 1.0))
		_door.modulate = _door.modulate.lerp(Color(1.18, 0.98, 0.86) if warm else Color.WHITE, minf(delta * 3.0, 1.0))


func _on_used(_by: Node) -> void:
	var root := get_tree().get_first_node_in_group("chapter_root") as ChapterRoot
	if not is_open():
		Sfx.play("rune_blocked", global_position, -4.0)
		if root:
			root.show_toast(_sealed_line(), 4.0)
		return
	Sfx.play("ui_click", global_position, -2.0)
	# (admin, for testing: with the admin switch on she may not have played the
	# wings before this one, so the door gives her their words)
	if Journey.admin_unlock:
		Journey.admin_prepare(Journey.EYE if index >= Journey.WINGS.size() else target_scene())
	opened.emit(target_scene())
	get_tree().change_scene_to_file.call_deferred(target_scene())


signal opened(scene_path: String)


func _sealed_line() -> String:
	if index >= Journey.WINGS.size():
		return "The last door is sealed. Four bells hold the Eye shut: ring them all."
	return "The Hush's frost holds this door shut. The heat of the bell before it will thaw it."
