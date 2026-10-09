class_name NanCottage
extends Node2D

## Nan's cottage, the grandma scene (told with portraits, DialogueBox). Echidna knocks, Nan lets her in, and does
## not know her. She tries her fire spell for the fire in the hearth and it
## will not come (the Hush took the word, and Nan says why), Nan sends her to
## the old Novices' Way under the house, gives her the lantern, and she goes
## down the cellar door.
##
## Everything here is pixel art: the room from the surface and town packs
## (SurfaceArt), Nan, the hearth, the table, the jar shelf and the cellar door
## from tools/generate_cottage_sprites.gd. It is walked with the real player,
## in a room two screens wide; the story runs as one coroutine (`_story`), and
## `stage` says where it is, for the tests and the hints.
##
## What Nan says is plain on purpose: Echidna has lost her spells as well as
## Nan's memory, and the way to win them back is the monks' words in stone.

const FRAMES := preload("res://assets/sprites/Echidna/echidna_frames.tres")
const SELF_PATH := "res://scenes/story/nan_cottage.tscn"

const FLOOR_Y := 534.0
const WIDTH := 1152.0
const BOUNDS := Rect2(0, 282, WIDTH, 324)
const S := SurfaceArt.LANE_SCALE
const DOOR_X := 92.0
const SHELF_X := 445.0
const WINDOW_X := 660.0
const TABLE_X := 560.0
const NAN_X := 770.0
const HEARTH_X := 930.0
const CELLAR_X := 1068.0
const COLD := Color(0.7, 0.84, 1.0)
const TRY_FIRE_PATIENCE := 30.0

signal advanced
signal spell_tried

## Where the story is: arriving, greeting, talk, conversation, spell,
## explaining, lantern, farewell, free, leaving.
var stage := "arriving"
var player: CharacterBody2D
var camera: Camera2D
var intro_camera: Camera2D
var nan: AnimatedSprite2D
var nan_talk: Interactable
var cellar_door: Interactable
var has_lantern := false

var _speech: SpeechBubble
var _thought: SpeechBubble
## The conversation, Persona-style: portraits and a framed box (the cottage
## handles the presses).
var dialogue: DialogueBox
var _hint: Label
var _fade: ColorRect
var _puppet: AnimatedSprite2D
var _hearth: AnimatedSprite2D
var _fire_light: PointLight2D
var _lantern: Sprite2D
var _lantern_light: PointLight2D
var _door_sprite: AnimatedSprite2D
var _waiting := false
var _cooldown := 0.0
var _time := 0.0
var _fire_denied := false


func _ready() -> void:
	# The scenery, puppets and the intro camera are tweened every drawn frame:
	# drawn as they are. Echidna and her camera move in physics steps and are
	# drawn between them (set in _build_player)
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_tree().paused = false
	AudioDirector.reset_combat()
	AudioDirector.fade_ambience(-40.0, 2.0)
	var dusk := CanvasModulate.new()
	dusk.color = Color(0.76, 0.76, 0.92)
	add_child(dusk)
	_build_room()
	_build_player()
	_build_post_and_menu()
	_build_ui()
	GameState.set_checkpoint(SELF_PATH, "cottage.start")
	_story()


func _exit_tree() -> void:
	AudioDirector.fade_ambience(AudioDirector.AMBIENCE_DB, 1.5)


# ------------------------------------------------------------------ the room

func _build_room() -> void:
	# The dark behind everything
	var back := ColorRect.new()
	back.name = "Dark"
	back.color = SurfaceArt.SKY_TOP
	back.position = Vector2(-300, 0)
	back.size = Vector2(WIDTH + 600, 900)
	back.z_index = -50
	add_child(back)
	var room := Node2D.new()
	room.name = "Room"
	room.z_index = -20
	add_child(room)
	# The stone wall, a little dimmer than the street's, and a floor of planks
	var wall := SurfaceArt.tile_block(room, Vector2(0, FLOOR_Y - 11.0 * 16.0 * S), 48, 11, ["bricks_a", "bricks_b"], S, 5)
	wall.name = "Wall"
	wall.modulate = Color(0.78, 0.78, 0.92)
	var planks: Array = ["plank_l"]
	for i in 46:
		planks.append("plank_m")
	planks.append("plank_r")
	var floor_row := SurfaceArt.tile_row(room, Vector2(0, FLOOR_Y - 4.0 * S), planks, S)
	floor_row.name = "Floor"
	floor_row.z_index = 1
	var under := ColorRect.new()
	under.color = SurfaceArt.SKY_TOP
	under.position = Vector2(0, FLOOR_Y + 12.0 * S)
	under.size = Vector2(WIDTH, 300)
	under.z_index = 1
	room.add_child(under)
	# Ceiling beams
	var beam_tiles: Array = []
	for i in 24:
		beam_tiles.append_array(["slab_a", "slab_b"])
	var beams := SurfaceArt.tile_row(room, Vector2(0, FLOOR_Y - 11.0 * 16.0 * S - 4.0), beam_tiles, S)
	beams.name = "Beams"
	# A soft shade from the ceiling down, so the eye goes to the fire
	var shade := Sprite2D.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.02, 0.01, 0.06, 0.8), Color(0.02, 0.01, 0.06, 0.0)])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var shade_tex := GradientTexture2D.new()
	shade_tex.gradient = gradient
	shade_tex.fill_from = Vector2(0.5, 0.0)
	shade_tex.fill_to = Vector2(0.5, 0.7)
	shade_tex.width = 8
	shade_tex.height = 64
	shade.texture = shade_tex
	shade.centered = false
	shade.position = Vector2(0, 268)
	shade.scale = Vector2(WIDTH / 8.0, 300.0 / 64.0)
	shade.z_index = -15
	add_child(shade)
	# The collision: floor and the two end walls
	var body := StaticBody2D.new()
	body.name = "Ground"
	body.collision_layer = 2
	body.collision_mask = 0
	body.add_to_group("world")
	add_child(body)
	_box(body, Rect2(-200, FLOOR_Y, WIDTH + 400, 300))
	_box(body, Rect2(-40, 0, 40, FLOOR_Y + 10))
	_box(body, Rect2(WIDTH, 0, 40, FLOOR_Y + 10))

	var props := Node2D.new()
	props.name = "Props"
	props.z_index = -10
	add_child(props)
	# The front door she came in by, and a window on the night
	SurfaceArt.sprite(props, "door_small", Vector2(DOOR_X, FLOOR_Y))
	SurfaceArt.sprite(props, "barrel", Vector2(DOOR_X + 78, FLOOR_Y))
	SurfaceArt.sprite(props, "crate", Vector2(DOOR_X + 112, FLOOR_Y))
	SurfaceArt.sprite(props, "shelf_jars", Vector2(SHELF_X, FLOOR_Y - 64))
	SurfaceArt.sprite(props, "win_arch_lit", Vector2(WINDOW_X, FLOOR_Y - 74), S * 1.4)
	SurfaceArt.sprite(props, "table", Vector2(TABLE_X, FLOOR_Y))
	_lantern = SurfaceArt.sprite(props, "lantern", Vector2(TABLE_X, FLOOR_Y - 31.0))
	_lantern.z_as_relative = false
	_lantern.z_index = 3
	_lantern_light = _light(_lantern.position + Vector2(0, -22), COLD, 0.6, 1.1)
	props.add_child(_lantern_light)
	# Herbs hung to dry from the beam, candles for warmth
	for hx in [506.0, 531.0, 556.0]:
		SurfaceArt.sprite(props, "vine_short", Vector2(hx, FLOOR_Y - 11.0 * 16.0 * S + 56.0))
	var candle_a := SurfaceArt.animated(props, "candle", Vector2(TABLE_X + 14.0, FLOOR_Y - 31.0), 6.0, S)
	candle_a.z_index = 1
	var candle_b := SurfaceArt.animated(props, "candle", Vector2(NAN_X - 62.0, FLOOR_Y), 6.0, S)
	candle_b.z_index = -2
	props.add_child(_light(candle_b.position + Vector2(0, -16), COLD, 0.45, 0.9))
	# Nan, in her armchair by the fire, facing the door
	nan = SurfaceArt.animated(props, "nan_seated", Vector2(NAN_X, FLOOR_Y), 0.0, S, true)
	nan.name = "Nan"
	nan.stop()
	nan.z_index = -1
	_hearth = SurfaceArt.animated(props, "hearth", Vector2(HEARTH_X, FLOOR_Y), 5.0, S)
	_hearth.name = "Hearth"
	_fire_light = _light(Vector2(HEARTH_X, FLOOR_Y - 34), COLD, 1.3, 3.6)
	props.add_child(_fire_light)
	_door_sprite = SurfaceArt.animated(props, "cellar_door", Vector2(CELLAR_X, FLOOR_Y), 0.0, S)
	_door_sprite.name = "CellarDoor"
	_door_sprite.stop()
	# Nan, to talk to; the cellar door, to go down (not yet)
	nan_talk = Interactable.new()
	nan_talk.name = "TalkToNan"
	nan_talk.verb = "Talk"
	nan_talk.echo_can_use = false
	nan_talk.size = Vector2(120, 60)
	nan_talk.position = Vector2(NAN_X - 10.0, FLOOR_Y)
	nan_talk.enabled = false
	add_child(nan_talk)
	cellar_door = Interactable.new()
	cellar_door.name = "CellarDoorUse"
	cellar_door.verb = "Go down"
	cellar_door.echo_can_use = false
	cellar_door.size = Vector2(56, 64)
	cellar_door.position = Vector2(CELLAR_X, FLOOR_Y)
	cellar_door.enabled = false
	add_child(cellar_door)


func _light(at: Vector2, color: Color, energy: float, scale: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = LightTextures.radial(256)
	l.color = color
	l.energy = energy
	l.texture_scale = scale
	l.position = at
	return l


func _box(body: StaticBody2D, r: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = r.size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = r.get_center()
	body.add_child(collider)


# ------------------------------------------------------------------ Echidna and the UI

func _build_player() -> void:
	player = load("res://scenes/Player.tscn").instantiate()
	player.name = "Player"
	player.position = Vector2(DOOR_X + 60.0, FLOOR_Y - 2)
	player.z_index = 1
	player.collision_mask = 2
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.set_script(load("res://scripts/camera_bounds.gd"))
	camera.set("bounds", BOUNDS)
	camera.set("base_zoom", Vector2(2, 2))
	camera.zoom = Vector2(2, 2)
	player.add_child(camera)
	var aura := _light(Vector2(0, -20), Color(0.8, 0.76, 1.0), 0.45, 1.0)
	aura.name = "PlayerLight"
	player.add_child(aura)
	player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child(player)
	player.ability_denied.connect(_on_ability_denied)
	intro_camera = Camera2D.new()
	intro_camera.name = "IntroCamera"
	intro_camera.zoom = Vector2(2, 2)
	intro_camera.position = Vector2(640, 444)
	add_child(intro_camera)
	_speech = SpeechBubble.new()
	add_child(_speech)
	_thought = SpeechBubble.new()
	_thought.thought = true
	dialogue = DialogueBox.new()
	dialogue.handles_input = false
	add_child(dialogue)
	add_child(_thought)


func _build_post_and_menu() -> void:
	var post := CanvasLayer.new()
	post.name = "PostFX"
	post.layer = 1
	post.set_script(load("res://scripts/post_fx.gd"))
	post.set("follows_brightness", false)
	var screen := ColorRect.new()
	screen.name = "Screen"
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/dungeon_post.gdshader")
	# Indoors by a low fire: a soft gloom, little mist, and the colour already
	# draining out of everything but the hearth
	mat.set_shader_parameter("fog_floor_y", FLOOR_Y)
	mat.set_shader_parameter("lantern_outer", 440.0)
	mat.set_shader_parameter("lantern_darkness", 0.12)
	mat.set_shader_parameter("fog_strength", 0.06)
	mat.set_shader_parameter("fog_color", Color(0.4, 0.42, 0.55))
	mat.set_shader_parameter("saturation", 0.62)
	mat.set_shader_parameter("vignette", 0.4)
	screen.material = mat
	post.add_child(screen)
	add_child(post)
	var pause := CanvasLayer.new()
	pause.name = "PauseMenu"
	pause.set_script(load("res://scripts/ui/pause_menu.gd"))
	add_child(pause)


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	ui.layer = 5
	add_child(ui)
	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_left = -300
	_hint.offset_right = 300
	_hint.offset_top = -70
	_hint.offset_bottom = -44
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_override("font", StoryPaint.label_font())
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", Color("e4ddf2"))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hint.add_theme_constant_override("outline_size", 5)
	_hint.modulate.a = 0.0
	ui.add_child(_hint)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0.01, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_fade)


# ------------------------------------------------------------------ the story

func _story() -> void:
	player.visible = false
	player.lock_controls(true)
	intro_camera.make_current()
	_start_puppet()
	var t := create_tween()
	t.tween_property(_fade, "color:a", 0.0, 1.4)
	await t.finished
	Sfx.play("door_creak", Vector2(DOOR_X, FLOOR_Y - 20), -8.0, 0.05)
	# Nan is humming by the fire, as she always does: four notes, the bell's
	# old tune (the lullaby Ilse sang; see docs/STORY_PLAYTHROUGH.md)
	AudioDirector.play_cue("lullaby.wav", -12.0)
	_speech.text = "Mm, mm-mm, mm..."
	_speech.position = nan.global_position + Vector2(0, -(40.0 * S + 8.0))
	_speech.show_bubble()
	# She steps in out of the cold and stops a little short of the fire
	_puppet.visible = true
	_puppet.speed_scale = 0.7
	_puppet.play(&"run")
	var walk := create_tween()
	walk.tween_property(_puppet, "position:x", 640.0, 3.2)
	await walk.finished
	_puppet.speed_scale = 1.0
	_puppet.play(&"idle")
	_hand_to_player()

	_speech.hide_bubble(0.3)
	AudioDirector.stop_cue(2.5)
	stage = "greeting"
	await _say(nan, "Oh, a visitor! Come in, dear. Come in. Mind the step.", false, "warm")
	await _say(player, "She's humming the bell's old tune again. But she doesn't know me.", true, "sad")
	stage = "talk"
	_set_hint("%s  talk to Nan" % InputLabels.primary("interact"))
	dialogue.close()
	player.unlock_controls()
	nan_talk.enabled = true
	await nan_talk.interacted
	nan_talk.enabled = false
	player.lock_controls(false)
	_set_hint("")

	stage = "conversation"
	await _say(player, "Nan, it's me.", false, "worried")
	await _say(nan, "Of course it is. Of course. You're my... you're {4}...", false, "lost")
	await _say(nan, "It was right here, on the tip of my tongue. I'm sorry, love.", false, "sad")
	if not GameState.has_ability("fire"):
		await _fire_beat()
	stage = "explaining"
	await _say(nan, "The Hush takes names first, then the little spells, then everything else.", false, "sad")
	await _say(nan, "But words don't die, love. The Choir carved theirs in stone, up in the mountain. Stone remembers.", false, "warm")
	await _say(nan, "Find the old words, and yours will come home.", false, "bright")
	await _say(nan, "And the bell. The big bell kept the Hush away for sixty years. It rang the tune I'm always humming.", false, "warm")
	await _say(player, "Then I'll ring it again. But the road up the mountain has been frozen shut for nine winters.", false, "determined")
	await _say(nan, "Not the road, love. This cottage was the Choir's gatehouse, and I was their last novice, when I was your age.", false, "bright")
	await _say(nan, "The Novices' Way starts right under our feet, in the cellar, and climbs up through the inside of the mountain.", false, "warm")
	stage = "lantern"
	await _say(nan, "Take my lantern. It's the only thing in this house that still burns properly.", false, "warm")
	await _give_lantern()
	await _say(player, "I'll bring your words back. And I'll tell you my name as many times as it takes.", false, "determined")
	stage = "farewell"
	await _say(nan, "That's kind. Go on, then. And mind the step.", false, "warm")
	stage = "free"
	dialogue.close()
	player.unlock_controls()
	cellar_door.enabled = true
	cellar_door.interacted.connect(func(_who): _go_down(), CONNECT_ONE_SHOT)
	_set_hint("%s  go down the cellar door" % InputLabels.primary("interact"))


## Echidna tries to light the fire for Nan and the spell will not come.
func _fire_beat() -> void:
	stage = "spell"
	await _say(nan, "The fire's nearly out. Would you, dear? You always lit it with a flick of your finger.", false, "warm")
	_fire_denied = false
	dialogue.close()
	player.unlock_controls()
	_set_hint("%s  try your fire spell" % InputLabels.primary("shoot"))
	var waited := 0.0
	while not _fire_denied and waited < TRY_FIRE_PATIENCE:
		await get_tree().process_frame
		waited += get_process_delta_time()
	player.lock_controls(false)
	_set_hint("")
	await get_tree().create_timer(0.5).timeout
	await _say(player, "I did this yesterday. The word is gone.", true, "worried")


func _on_ability_denied(id: String) -> void:
	if id == "fire":
		_fire_denied = true
		spell_tried.emit()


## Nan lifts the lantern off the table and it comes to Echidna, whose own
## light grows to match.
func _give_lantern() -> void:
	var from := _lantern.global_position
	var to := player.global_position + Vector2(0, -34)
	var t := create_tween()
	t.tween_property(_lantern, "global_position", from + Vector2(0, -24), 0.4)
	t.tween_property(_lantern, "global_position", to, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	has_lantern = true
	Sfx.play("brazier_ignite", player.global_position, -6.0)
	var aura: PointLight2D = player.get_node("PlayerLight")
	var glow := create_tween().set_parallel()
	glow.tween_property(aura, "energy", 0.95, 1.0)
	glow.tween_property(_lantern, "modulate:a", 0.0, 1.0)
	glow.tween_property(_lantern_light, "energy", 0.0, 1.0)
	await glow.finished


## The cellar door opens on the stair, and the screen goes dark.
func _go_down() -> void:
	if stage == "leaving":
		return
	stage = "leaving"
	player.lock_controls(false)
	cellar_door.enabled = false
	_set_hint("")
	Sfx.play("door_creak", Vector2(CELLAR_X, FLOOR_Y - 20), -4.0, 0.05)
	_door_sprite.frame = 1
	GameState.set_flag("cottage.done")
	var t := create_tween()
	t.tween_interval(0.8)
	t.tween_property(_fade, "color:a", 1.0, 1.4)
	t.tween_interval(0.4)
	t.tween_callback(func(): SceneFade.change(get_tree(), next_scene(), 0.0))


func next_scene() -> String:
	return Journey.after_story()


# ------------------------------------------------------------------ talking

## A bubble over `who` (Nan, or Echidna's own thought); waits for a press.
func _say(who: Node2D, text: String, thought := false, face := "") -> void:
	var id := "nan" if who == nan else "echidna"
	var f := face
	if f == "":
		f = "warm" if id == "nan" else ("worried" if thought else "neutral")
	dialogue.say(id, f, text, thought)
	await _wait_press()


func _wait_press() -> void:
	# the first press only finishes the typing (see _physics_process)
	if dialogue.is_typing:
		await dialogue.typed
	_cooldown = 0.35
	_set_hint("%s  ▸" % InputLabels.primary("interact"))
	_waiting = true
	await advanced
	_waiting = false
	_set_hint("")


func _set_hint(text: String) -> void:
	if text != "":
		_hint.text = text
	create_tween().tween_property(_hint, "modulate:a", 0.9 if text != "" else 0.0, 0.25)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if dialogue and dialogue.is_typing and _pressed():
		dialogue.finish_typing()
		_cooldown = 0.2
	elif _waiting and _cooldown <= 0.0 and _pressed():
		_waiting = false
		advanced.emit()


func _pressed() -> bool:
	return Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("jump") \
		or Input.is_action_just_pressed("ui_accept")


func _process(delta: float) -> void:
	_time += delta
	# Breath and blink for Nan; the fire flickers
	var breathing := fmod(_time, 2.6) > 1.4
	var blinking := fmod(_time + 0.9, 4.1) < 0.14
	nan.frame = 2 if blinking else (1 if breathing else 0)
	_fire_light.energy = 1.25 + 0.14 * sin(_time * 7.0) + 0.07 * sin(_time * 17.0)


# ------------------------------------------------------------------ the entrance

func _start_puppet() -> void:
	_puppet = AnimatedSprite2D.new()
	_puppet.name = "EchidnaEntering"
	_puppet.sprite_frames = FRAMES
	_puppet.offset = FRAMES.get_meta(&"sprite_offset", Vector2(0, -32))
	_puppet.scale = Vector2(0.812, 0.812)
	_puppet.material = player.get_node("AnimatedSprite2D").material
	_puppet.position = Vector2(DOOR_X, FLOOR_Y)
	_puppet.z_index = 1
	_puppet.visible = false
	add_child(_puppet)
	_puppet.play(&"idle")


## Hands Echidna to the player where the walk-in left her.
func _hand_to_player() -> void:
	var at := Vector2(_puppet.position.x, FLOOR_Y - 2)
	_puppet.queue_free()
	player.teleport_to(at)
	player.animated_sprite.flip_h = false
	player.visible = true
	camera.make_current()
	camera.call("snap")
