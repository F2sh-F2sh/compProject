class_name WrenMeeting
extends Node2D

## Wren, Ilse's daughter: a small pixel figure (tools/art/generate_gallery_sprites.gd)
## who breathes, blinks and turns to look at Echidna. The first time Echidna
## comes close they talk, Persona-style (DialogueBox: both portraits, the
## words in a framed box); Echidna holds still while they do, each line moves
## on by itself after a while or at a press. Saved by `flag`, so it plays
## once; after that Wren says her last line in a bubble when Echidna is near.
## The node stands at Wren's feet.

@export var flag := "galleries.wren_spoke"
@export var talk_range := 96.0
## Each line is "wren: text" or "echidna: text"; a face can follow the name
## ("wren/pleading: text"; DialogueBox.FACES lists them).
@export var lines: PackedStringArray = []
@export var line_time := 3.8
@export var art_scale := 1.5
@export var facing := -1

var figure: AnimatedSprite2D
var bubble: SpeechBubble
## The conversation box (made the first time they talk).
var dialogue: DialogueBox
## Which line is showing (-1 before and after the talk).
var line_index := -1
var _player: Node2D
var _time := 0.0
var _blink := 0.0
var _next_blink := 3.0
var _line_left := 0.0
var _near := false


func _ready() -> void:
	add_to_group("wren")
	figure = SurfaceArt.animated(self, "wren", Vector2.ZERO, 0.0, art_scale)
	figure.name = "Figure"
	figure.stop()
	var height := SurfaceArt.size_of("wren").y * figure.scale.y
	bubble = SpeechBubble.new()
	bubble.position = Vector2(0, -height - 12.0)
	add_child(bubble)
	_next_blink = randf_range(1.5, 4.0)


func has_spoken() -> bool:
	return GameState.has_flag(flag)


func is_talking() -> bool:
	return line_index >= 0


func _process(delta: float) -> void:
	_time += delta
	_next_blink -= delta
	if _next_blink <= 0.0:
		_blink = 0.14
		_next_blink = randf_range(2.5, 5.5)
	_blink = maxf(_blink - delta, 0.0)
	# Frames: 0 looking, 1 glancing, 2 blinking
	figure.frame = 2 if _blink > 0.0 else (1 if fmod(_time, 3.1) > 2.2 else 0)
	figure.flip_h = facing > 0
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return
	var d := _player.global_position - global_position
	var near := _player.visible and absf(d.x) < talk_range and absf(d.y) < 70.0
	if near and absf(d.x) > 4.0:
		facing = 1 if d.x > 0.0 else -1
	if line_index >= 0:
		# the words type, then wait a while (or for a press)
		if not dialogue.is_typing:
			_line_left -= delta
		if _line_left <= 0.0:
			_show_line(line_index + 1)
		return
	if near and not _near:
		if not has_spoken() and not lines.is_empty():
			_show_line(0)
		elif not lines.is_empty():
			bubble.text = _text_of(lines[lines.size() - 1])
			bubble.show_bubble()
	elif not near and _near and bubble.is_showing():
		bubble.hide_bubble()
	_near = near


## Shows line i (or ends the talk past the last one).
func _show_line(i: int) -> void:
	if i >= lines.size():
		line_index = -1
		bubble.hide_bubble()
		if dialogue:
			dialogue.close()
		if is_instance_valid(_player) and _player.has_method("unlock_controls"):
			_player.unlock_controls()
		GameState.set_flag(flag)
		return
	if i == 0:
		if dialogue == null:
			dialogue = DialogueBox.new()
			add_child(dialogue)
			dialogue.advanced.connect(func():
				if line_index >= 0:
					_show_line(line_index + 1))
		if is_instance_valid(_player) and _player.has_method("lock_controls"):
			_player.lock_controls()
	line_index = i
	var text := _text_of(lines[i])
	_line_left = maxf(line_time - text.length() / DialogueBox.CHARS_PER_SECOND, 2.2)
	dialogue.say(_speaker_of(lines[i]), _face_of(lines[i]), text)


static func _speaker_of(line: String) -> String:
	return "echidna" if line.begins_with("echidna") else "wren"


## The face named after the speaker ("wren/pleading: ..."), or their usual one.
static func _face_of(line: String) -> String:
	var head := line.substr(0, maxi(line.find(":"), 0))
	if head.contains("/"):
		return head.get_slice("/", 1).strip_edges()
	return "neutral" if _speaker_of(line) == "echidna" else "calm"


static func _text_of(line: String) -> String:
	var i := line.find(":")
	return line.substr(i + 1).strip_edges() if i >= 0 else line
