@tool
class_name HintStone
extends Node2D

## A whispering skull that gives an optional three-stage hint:
## 1) says where to look, 2) describes how the objects relate and marks them
## with arrows,
## 3) explains the solution. Each "Listen" reveals the next stage, but only
## once she has spent a while in the room trying it herself: the first hint
## after about a minute, the second 2.5 minutes after that, the solution 4
## minutes after that (a gold ring fills round the skull while it listens).
## The wait counts time in the skull's room and survives deaths and resets;
## the "Hints without waiting" assist (Settings) skips it.

## Seconds in the room before each stage can be heard (counted from the start).
const UNLOCK_AT := [60.0, 210.0, 450.0]

@export var hints: PackedStringArray = PackedStringArray(["", "", ""])
## Objects highlighted by the first hint.
@export var focus_nodes: Array[Node] = []

var stage := 0
## Set when the player seems stuck: the skull's eyes flare and it calls out.
var nudging := false
var _interact: Interactable
var _eyes: Node2D
var _time := 0.0
var _call_timer := 0.0
## A nudge that came before the next stage was ready (given when it is).
var _nudge_waiting := false
## Whether she is close enough to see the listening ring.
var _near := false
var _room: Room
var _player: Node2D


func _ready() -> void:
	_eyes = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_eyes.material = mat
	_eyes.draw.connect(_draw_eyes)
	add_child(_eyes)
	if Engine.is_editor_hint():
		return
	_interact = Interactable.new()
	_interact.verb = "Listen"
	_interact.echo_can_use = false
	_interact.size = Vector2(40, 48)
	_interact.prompt_offset = Vector2(0, -44)
	add_child(_interact)
	_interact.interacted.connect(func(_p): listen())
	var up := get_parent()
	while up and not up is Room:
		up = up.get_parent()
	_room = up as Room


## Seconds she has spent in this skull's room (kept for the whole run).
var waited: float:
	get:
		return float(GameState.session.get(_wait_key(), 0.0))
	set(value):
		GameState.session[_wait_key()] = value


func _wait_key() -> String:
	return "hint_wait.%s" % String(get_path())


## Whether the next stage can be heard yet.
func is_ready() -> bool:
	return stage >= hints.size() or Settings.assist_instant_hints or waited >= UNLOCK_AT[mini(stage, UNLOCK_AT.size() - 1)]


## How far the skull is through listening for the next stage (0..1).
func listening() -> float:
	if is_ready():
		return 1.0
	var start: float = UNLOCK_AT[stage - 1] if stage > 0 else 0.0
	var end: float = UNLOCK_AT[stage]
	return clampf((waited - start) / (end - start), 0.0, 1.0)


## "Listen": the next stage if it's ready, otherwise how long it will be.
func listen() -> void:
	if is_ready():
		next_hint()
		return
	var left: float = UNLOCK_AT[stage] - waited
	Sfx.play("hint_whisper", global_position, -14.0, 0.1)
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root:
		var when := "in a moment" if left < 20.0 else "in about a minute" if left < 90.0 else "in a few minutes"
		root.show_toast("The skull is still listening to the room. Try it yourself a while;\nit will speak %s." % when, 4.0)


## Draws attention to the stone once, when the player seems stuck (or as
## soon as its next stage is ready, if it isn't yet).
func nudge() -> void:
	if nudging or stage >= hints.size():
		return
	if not is_ready():
		_nudge_waiting = true
		return
	_nudge_waiting = false
	nudging = true
	_call_timer = 0.0
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root:
		root.show_toast(InputLabels.format("Stuck? The whispering skull in this room can help. Stand by it and press {interact}.",
			"%s"), 6.0)


func next_hint() -> void:
	nudging = false
	stage = mini(stage + 1, hints.size())
	Sfx.play("hint", global_position)
	Sfx.play("hint_whisper", global_position, -4.0, 0.08)
	var root := get_tree().get_first_node_in_group("chapter_root")
	var prefix: String = ["Hint 1 of 3", "Hint 2 of 3", "Hint 3 of 3 (solution)"][clampi(stage - 1, 0, 2)]
	if root:
		root.show_toast("%s\n%s" % [prefix, InputLabels.format(hints[stage - 1])], 6.0)
		root.note_hint()
	if stage == 2:
		for node in focus_nodes:
			if is_instance_valid(node) and node is Node2D:
				_mark(node)


func _mark(node: Node2D) -> void:
	var marker := HintMarker.new()
	node.get_parent().add_child(marker)
	marker.global_position = node.global_position + Vector2(0, -44)


func _process(delta: float) -> void:
	_time += delta
	_eyes.queue_redraw()
	if Engine.is_editor_hint():
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player and (_room == null or _room.contains(_player.global_position)):
		if stage < hints.size() and not is_ready():
			waited += delta
	_near = _player != null and _player.global_position.distance_to(global_position) < 220.0
	if _nudge_waiting and is_ready():
		nudge()
	if nudging:
		_call_timer -= delta
		if _call_timer <= 0.0:
			_call_timer = 5.0
			Sfx.play("hint_whisper", global_position, -10.0, 0.1)


func _draw() -> void:
	# Stone pedestal with a skull resting on it
	draw_rect(Rect2(-9, -10, 18, 10), Color("231d38"))
	draw_rect(Rect2(-9, -10, 18, 2), Color("4a4170"))
	var bone := Color("8f86a8")
	draw_rect(Rect2(-6, -22, 12, 9), bone)
	draw_rect(Rect2(-5, -24, 10, 2), bone)
	draw_rect(Rect2(-4, -13, 8, 3), Color("766d92"))
	draw_rect(Rect2(-3, -12, 1, 2), Color("3b3358"))
	draw_rect(Rect2(0, -12, 1, 2), Color("3b3358"))
	draw_rect(Rect2(2, -12, 1, 2), Color("3b3358"))
	draw_rect(Rect2(-4, -20, 3, 3), Color("1f1a33"))
	draw_rect(Rect2(1, -20, 3, 3), Color("1f1a33"))


func _draw_eyes() -> void:
	var glow := 0.5 + 0.3 * sin(_time * 2.5)
	var color := Color(0.5, 0.75, 1.0, glow)
	_eyes.draw_rect(Rect2(-3, -19, 1, 1), color)
	_eyes.draw_rect(Rect2(2, -19, 1, 1), color)
	if _near and stage < hints.size() and not Engine.is_editor_hint():
		# The listening ring: dim stone while it waits, filling gold
		var k := listening()
		var centre := Vector2(0, -16)
		_eyes.draw_arc(centre, 15.0, 0.0, TAU, 40, Color(0.2, 0.17, 0.12, 0.55), 2.0)
		if k < 1.0:
			_eyes.draw_arc(centre, 15.0, -PI / 2.0, -PI / 2.0 + TAU * k, 40, Color(0.79, 0.64, 0.29, 0.85), 2.0)
		else:
			_eyes.draw_arc(centre, 15.0, 0.0, TAU, 40, Color(0.94, 0.82, 0.48, 0.55 + 0.35 * glow), 2.0)
	if nudging:
		# Brighter eyes and slow rings of whispering light
		_eyes.draw_rect(Rect2(-4, -20, 3, 3), Color(0.6, 0.85, 1.0, 0.5 * glow))
		_eyes.draw_rect(Rect2(1, -20, 3, 3), Color(0.6, 0.85, 1.0, 0.5 * glow))
		for i in 2:
			var k := fposmod(_time * 0.6 + i * 0.5, 1.0)
			_eyes.draw_arc(Vector2(0, -18), 8.0 + k * 34.0, 0.0, TAU, 32, Color(0.55, 0.8, 1.0, (1.0 - k) * 0.45), 1.0)


## A bobbing arrow that fades after a few seconds.
class HintMarker extends Node2D:
	var life := 5.0
	var t := 0.0

	func _ready() -> void:
		z_index = 30
		var mat := CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = mat

	func _process(delta: float) -> void:
		t += delta
		modulate.a = clampf(life - t, 0.0, 1.0)
		if t >= life:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var y := sin(t * 5.0) * 3.0
		var c := Color(0.95, 0.8, 0.4)
		draw_colored_polygon(PackedVector2Array([Vector2(-6, y - 6), Vector2(6, y - 6), Vector2(0, y + 2)]), c)
		draw_rect(Rect2(-2, y - 14, 4, 8), c)
