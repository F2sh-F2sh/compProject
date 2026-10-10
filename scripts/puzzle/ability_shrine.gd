class_name AbilityShrine
extends Node2D

## A place on the Novices' Way where Echidna remembers a word the Hush took,
## and with it a spell: the Kept Flame (fireball), the Spring (heal) and the
## Echo stone (Echo). She has to walk up and use it (W); the first time, the
## word comes back with a flash and a card that says what it is, and the spell
## is hers for good (saved, "ability.<id>"). It glows until she has.
## Modelled on RuneTablet. The node's origin is its foot, on the floor.

signal remembered(ability: String)

## The part of the screen each spell comes with (UiTour).
const TOURS := {"fire": "fire", "echo": "echo"}

## "fire", "heal" or "echo" (GameState.ABILITIES).
@export var ability := "fire"
## A strip in assets/sprites/story (tools/generate_shrine_sprites.gd).
@export var sprite_name := "kept_flame"
## The word, as the card shows it.
@export var word := "FLAME"
@export var verb := "Read"
## What the card says under the word. {shoot}, {heal} and {echo} show the keys.
@export_multiline var story := ""
@export var glow_color := Color(0.45, 0.65, 1.0)
## Soft steam rising off it (the hot spring in the bell tower).
@export var steam := false
## How big its sprite is drawn (the hot spring is drawn at 2).
@export var sprite_scale := 1.0

var interactable: Interactable
var figure: AnimatedSprite2D
var _light: PointLight2D
var _time := 0.0


func _ready() -> void:
	add_to_group("ability_shrine")
	add_to_group("kindle_point")
	figure = SurfaceArt.animated(self, sprite_name, Vector2.ZERO, 6.0, sprite_scale)
	figure.name = "Figure"
	# The Echo stone's two frames are states (dim, remembered), not an animation
	var animated_frames: bool = int(SurfaceArt.STRIPS.get(sprite_name, 1)) > 2
	if not animated_frames:
		figure.stop()
	var height := SurfaceArt.size_of(sprite_name).y * sprite_scale
	_light = PointLight2D.new()
	_light.texture = LightTextures.radial(256)
	_light.color = glow_color
	_light.position = Vector2(0, -height * 0.55)
	_light.shadow_enabled = false
	add_child(_light)
	interactable = Interactable.new()
	interactable.verb = verb
	interactable.echo_can_use = false
	interactable.size = Vector2(64, height)
	interactable.prompt_offset = Vector2(0, -height - 14.0)
	add_child(interactable)
	interactable.interacted.connect(_on_used)
	if steam:
		var wisps := GlowFX.embers(Color(0.86, 0.93, 1.0, 0.7), 26, 22.0, 26.0, 2.8)
		wisps.name = "Steam"
		wisps.scale_amount_min = 1.0
		wisps.scale_amount_max = 2.0
		wisps.position = Vector2(8, -height * 0.55)
		add_child(wisps)
	_refresh()


func is_remembered() -> bool:
	return GameState.has_flag("ability." + ability)


func _process(delta: float) -> void:
	_time += delta
	# Unremembered, it breathes a little brighter; remembered, it settles
	var pulse := 0.5 + 0.5 * sin(_time * 2.2)
	_light.energy = 0.55 + 0.45 * pulse if not is_remembered() else 0.5
	_light.texture_scale = 1.3 + 0.25 * pulse if not is_remembered() else 1.1


func _refresh() -> void:
	if sprite_name == "echo_stone":
		figure.frame = 1 if is_remembered() else 0


func _on_used(_by: Node) -> void:
	var first := not is_remembered()
	if first:
		GameState.grant_ability(ability)
		Sfx.play("rune_learn", global_position, -3.0, 0.0)
		FloatText.spawn(get_parent(), global_position + Vector2(0, -SurfaceArt.size_of(sprite_name).y * sprite_scale - 24.0),
			"+ " + word, glow_color.lightened(0.3), 30.0, 1.8)
		_flare()
		_refresh()
		remembered.emit(ability)
	else:
		Sfx.play("ui_click", global_position, -6.0)
	var host: Node = get_tree().current_scene
	TitleCard.show_card(host, "YOU REMEMBER A WORD" if first else "THE WORD", word, InputLabels.format(story), 6.0 if first else 4.0, 20)
	if first and TOURS.has(ability):
		UiTour.play_later(self, TOURS[ability], 6.6)


## A ring of light opens out of the shrine as the word returns.
func _flare() -> void:
	var ring := _Ring.new()
	ring.color = glow_color
	ring.position = Vector2(0, -SurfaceArt.size_of(sprite_name).y * sprite_scale * 0.55)
	add_child(ring)
	var t := create_tween().set_parallel()
	t.tween_property(ring, "radius", 90.0, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(ring, "modulate:a", 0.0, 1.1)
	t.chain().tween_callback(ring.queue_free)
	ImpactFX.burst(get_parent(), global_position + Vector2(0, -SurfaceArt.size_of(sprite_name).y * sprite_scale * 0.6), glow_color, false, 12)


## The expanding ring (an effect, so it is drawn rather than a sprite).
class _Ring extends Node2D:
	var radius := 6.0:
		set(value):
			radius = value
			queue_redraw()
	var color := Color.WHITE

	func _ready() -> void:
		material = MagicLight.unshaded()
		z_index = 10

	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(color, 0.8), 2.0)
		draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 32, Color(color, 0.35), 1.0)


## The Kept Flame is a flame she can kindle at; the Spring and the stone are not.
func is_kindling() -> bool:
	return ability == "fire" and is_remembered()
