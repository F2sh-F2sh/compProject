class_name EyeScene
extends Node2D

## The Eye, staged as the story's last room. The held moment hangs over the
## great cube as a vast pale moth (StoryStage.Moth), wings of frozen night,
## held to the floor round the cube by four chains whose plates read ICE,
## FREEZE, SELF and PERSIST; snow hangs in the air and does not fall; Ilse
## kneels at Wren's bed holding her hand, by the candle that must not go out.
##
## Wren comes in with Echidna (a WrenMeeting at the door, which then walks
## her to the cube); when Echidna nears the cube Ilse pleads with her, and
## Wren answers her mother. A sentence that is neither answer gets Wren's
## reply instead of a system message (EyeAltar.wrong_sentence). When the
## Rewritten Sky is read the chains break and the moth begins to fill with
## light before the pictures; when the Stillness is read, Wren is afraid.
## The camera draws back a little here, so the moth is in view.
##
## The node sits at the room's origin; `cube_x` is the great cube's x and
## `floor_y` the floor (both in the room's units).

## [speaker, face, words, a thought?]
const PLEA := [
	["ilse", "pleading", "Please. Don't. She'll wake in the morning.", false],
	["ilse", "pleading", "I'll be here when she does. I promised her.", false],
	["wren", "pleading", "It's been morning for sixty years, Mum.", false],
	["echidna", "sad", "Nan's forgetting me. If I held her still, she never would.", true],
	["wren", "calm", "That's what Mum did. Look at her.", false],
]
const WRONG := [
	"That's a spell. It isn't the one.",
	"No. That one doesn't send anything anywhere.",
	"Read what's over the door. Then read my chalk.",
]
const BACK := [
	"wren/smile: You came back.",
	"echidna/sad: I couldn't leave it like that. Not you, and not her.",
	"wren/calm: Holding on isn't the same as keeping someone. Mum never learned that.",
]

@export var cube_x := 1056.0
@export var floor_y := 534.0
@export var moth_height := 250.0
@export var zoom := 1.5

var moth: StoryStage.Moth
## The moth's cold light on the chamber (warm once it kindles).
var moth_light: PointLight2D
var chains: Array = []
var snow: CPUParticles2D
var wren: WrenMeeting
var ilse: AnimatedSprite2D
var altar: EyeAltar
## The conversation box (Persona-style portraits): the plea and Wren's replies.
var dialogue: DialogueBox
## The plea, line by line (-1 before it and after it).
var plea_index := -1
var pleaded := false
var wrong_count := 0
var _player: Node2D
var _plea_left := 0.0
var _reply_left := 0.0
var _wren_walked := false


func _ready() -> void:
	add_to_group("eye_scene")
	_stage()
	dialogue = DialogueBox.new()
	add_child(dialogue)
	dialogue.advanced.connect(_on_advanced)
	wren = get_parent().get_node_or_null("Wren") as WrenMeeting
	if wren and GameState.has_flag("eye.stillness_seen"):
		# Back from the Stillness: Wren has something else to say
		wren.flag = "eye.wren_back"
		wren.lines = PackedStringArray(BACK)
	var holder := get_parent().get_node_or_null("Ilse")
	if holder:
		ilse = holder.get_node_or_null("Sprite") as AnimatedSprite2D
		var bed_light := PointLight2D.new()
		bed_light.name = "BedLight"
		bed_light.texture = StoryPaint.GLOW_TEXTURE
		bed_light.texture_scale = 2.6
		bed_light.color = Color(1.0, 0.78, 0.5)
		bed_light.energy = 1.1
		bed_light.position = Vector2(40, -30)
		holder.add_child(bed_light)
	altar = get_parent().get_node_or_null("Altar") as EyeAltar
	if altar:
		altar.wrong_sentence.connect(_on_wrong)
		altar.sentence_read.connect(_on_read)
	_draw_back.call_deferred()


## The moth, its chains, the hanging snow, the fog over the floor and the
## candle's light, built at run time (all pixel sprites and drawn light).
func _stage() -> void:
	var unshaded := MagicLight.unshaded()
	var hang := Vector2(cube_x, floor_y - moth_height)
	moth = StoryStage.Moth.new()
	moth.name = "Moth"
	moth.art_scale = 1.6
	moth.breathe = 2.0
	moth.position = hang
	moth.z_index = -3
	moth.material = unshaded
	add_child(moth)
	_unshade(moth)
	moth_light = PointLight2D.new()
	moth_light.name = "MothLight"
	moth_light.texture = StoryPaint.GLOW_TEXTURE
	moth_light.texture_scale = 7.0
	moth_light.color = Color(0.6, 0.72, 1.0)
	moth_light.energy = 0.9
	moth_light.position = hang + Vector2(0, 40)
	add_child(moth_light)
	var tops := [Vector2(-96, 24), Vector2(-46, 64), Vector2(46, 64), Vector2(96, 24)]
	var feet := [Vector2(-112, 0), Vector2(-58, 0), Vector2(58, 0), Vector2(112, 0)]
	for i in 4:
		var chain := StoryStage.Chain.new()
		chain.name = "Chain%d" % (i + 1)
		chain.word = i
		chain.art_scale = 1.6
		chain.position = hang + tops[i]
		chain.to = Vector2(cube_x, floor_y) + feet[i] - chain.position
		chain.plate_at = 0.55
		chain.z_index = -2
		chain.material = unshaded
		add_child(chain)
		_unshade(chain)
		chains.append(chain)
	snow = StoryStage.hanging_snow(self, Rect2(cube_x - 700, floor_y - 480, 1400, 470), 140)
	snow.z_index = 2
	snow.material = unshaded
	var fog := StoryStage.fog(self, Rect2(cube_x - 900, floor_y - 120, 1800, 150), Color(0.45, 0.55, 0.78, 0.28), 0.01, 0.4)
	fog.z_index = 3


## The camera draws back so the moth over the cube is in view.
func _draw_back() -> void:
	var root := get_tree().get_first_node_in_group("chapter_root")
	var camera: Camera2D = root.get("camera") if root else null
	if camera == null or not ("base_zoom" in camera):
		return
	camera.set("base_zoom", Vector2(zoom, zoom))
	create_tween().tween_property(camera, "zoom", Vector2(zoom, zoom), 2.0).set_trans(Tween.TRANS_SINE)


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return
	# Wren, once she has had her say at the door, walks with Echidna to the cube
	if wren and not _wren_walked and wren.has_spoken() and not wren.is_talking():
		_wren_walked = true
		var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(wren, "position:x", cube_x - 150.0, absf(cube_x - 150.0 - wren.position.x) / 70.0)
	if _reply_left > 0.0:
		_reply_left -= delta
		if _reply_left <= 0.0 and plea_index < 0:
			dialogue.close()
	if plea_index >= 0:
		if not dialogue.is_typing:
			_plea_left -= delta
		if _plea_left <= 0.0:
			_say_plea(plea_index + 1)
		return
	var near_cube := absf(_player.global_position.x - global_position.x - cube_x) < 170.0
	if near_cube and not pleaded and (wren == null or not wren.is_talking()):
		pleaded = true
		_say_plea(0)


## Line i of the plea (or the end of it). Echidna holds still while it is
## said; each line moves on by itself, or at a press.
func _say_plea(i: int) -> void:
	if i >= PLEA.size():
		plea_index = -1
		dialogue.close()
		if is_instance_valid(_player) and _player.has_method("unlock_controls"):
			_player.unlock_controls()
		return
	if i == 0:
		if is_instance_valid(_player) and _player.has_method("lock_controls"):
			_player.lock_controls()
		# Draw the eye to her: the camera leans toward the bed while she speaks
		var root := get_tree().get_first_node_in_group("chapter_root")
		var camera: Node = root.get("camera") if root else null
		if camera and camera.has_method("focus_on") and ilse:
			camera.focus_on((ilse.global_position + Vector2(cube_x, floor_y) + global_position) / 2.0, PLEA.size() * 4.2 - 1.0)
	plea_index = i
	_plea_left = 2.6
	dialogue.say(PLEA[i][0], PLEA[i][1], PLEA[i][2], PLEA[i][3])
	if PLEA[i][0] == "ilse" and ilse:
		ilse.frame = 1


func _on_advanced() -> void:
	if plea_index >= 0:
		_say_plea(plea_index + 1)
	elif _reply_left > 0.0:
		_reply_left = 0.0
		dialogue.close()


## A short line from Wren that closes by itself (her replies to the cube).
func _reply(face: String, text: String) -> void:
	dialogue.say("wren", face, text)
	_reply_left = 3.6


## A sentence that is neither answer: Wren says so, in her own words.
func _on_wrong(_key: String) -> void:
	if wren == null:
		return
	if plea_index >= 0:
		plea_index = -1
		if is_instance_valid(_player) and _player.has_method("unlock_controls"):
			_player.unlock_controls()
	_reply("pleading" if wrong_count % 2 == 1 else "calm", WRONG[wrong_count % WRONG.size()])
	wrong_count += 1


## One of the two answers: the room answers before the pictures.
func _on_read(kind: String) -> void:
	plea_index = -1
	if kind == "sky":
		_reply("smile", "Thank you.")
		if ilse:
			ilse.frame = 2
		var t := create_tween()
		t.tween_property(moth, "light", 0.6, 1.2)
		create_tween().tween_property(moth_light, "color", Color(1.0, 0.82, 0.55), 2.0)
		for chain in chains:
			t.tween_callback(func() -> void:
				chain.snap()
				Sfx.play("ice_crack", chain.global_position, -4.0, 0.08))
			t.tween_interval(0.3)
	else:
		_reply("scared", "Echidna... no.")
		var t := create_tween().set_parallel()
		t.tween_property(moth, "modulate", Color(0.7, 0.8, 1.0), 1.6)
		t.tween_property(moth, "light", 0.0, 0.8)


## Lets every part of a staged piece glow in the dark of the dungeon (the
## glows have their own unshaded material already).
func _unshade(piece: Node) -> void:
	for part in piece.find_children("*", "CanvasItem", true, false):
		if part.material == null:
			part.use_parent_material = true
