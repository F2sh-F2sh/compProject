@tool
class_name Circuit
extends Node2D

## Connects power sources (plates, levers, switches, braziers, receivers) to
## consumers (gates, traps, bridges...). Sources expose `power_changed(bool)`
## and `is_powered()`; consumers expose `set_powered(bool)`. The circuit also
## draws a carved channel on the wall from each source to each target, which
## glows while that part is powered, so players can see what controls what.

signal power_changed(powered: bool)

enum Mode { ALL, ANY }

@export var sources: Array[Node] = []:
	set(value):
		sources = value
		queue_redraw()
@export var targets: Array[Node] = []:
	set(value):
		targets = value
		queue_redraw()
@export var mode: Mode = Mode.ALL
## Targets receive the opposite state (e.g. a lever that switches machinery OFF).
@export var invert := false
## Once satisfied, the circuit stays on until the room is reset. Plates and
## crystals are left live instead: their gate is open only while they are held.
@export var latch := false
## Sources must stay satisfied this long before the circuit switches on.
@export var hold_time := 0.0
## If set, the circuit stays on across deaths and reloads: a latched one from
## the moment it latches, a live one once the player walks on into a later
## room while it is on (a gate she has come through stays open behind her).
@export var persist_id := ""
@export var solved_sound := "puzzle_solved"
## When the circuit first switches on during play, the camera briefly looks
## at its first target (if the player is safe), e.g. a distant shortcut gate.
@export var reveal_target := false

@export_group("Channels")
@export var show_channels := true
## World height of the horizontal channel run. Zero routes directly.
@export var channel_y := 0.0:
	set(value):
		channel_y = value
		queue_redraw()
## Violet like the plate runes, so power grooves never read as light beams.
@export var channel_color := Color(0.66, 0.48, 1.0)
## Picks the rune carved at each end so linked pieces share a symbol.
@export_range(0, 3) var symbol := 0

var powered := false
var _latched := false
var _chimed := false
var _held := 0.0
var _revealed := false
var _glow: Node2D
var _time := 0.0
## 0..1: the player is near one of this circuit's pieces, so its grooves
## light up and pulse toward what it controls (with full guidance).
var preview := 0.0
var _player: Node2D

const PREVIEW_RANGE := 96.0


func _ready() -> void:
	z_index = -5
	_glow = Node2D.new()
	_glow.z_index = 0
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_glow.material = mat
	_glow.draw.connect(_draw_glow)
	add_child(_glow)
	if Engine.is_editor_hint():
		return
	add_to_group("resettable")
	for source in sources:
		if is_instance_valid(source) and source.has_signal("power_changed"):
			if not source.power_changed.is_connected(_on_source_changed):
				source.power_changed.connect(_on_source_changed)
	if persist_id != "" and GameState.has_flag(persist_id):
		_latched = true
		_chimed = true
		_revealed = true
	# Tell every target its starting state once the whole room exists
	_apply.call_deferred(_latched, true)
	if persist_id != "" and not latch:
		_watch_rooms.call_deferred()


func _watch_rooms() -> void:
	var root := get_tree().get_first_node_in_group("chapter_root")
	if root and root.has_signal("room_entered"):
		root.room_entered.connect(_on_room_entered)


func _on_room_entered(room: Node) -> void:
	if _latched or not powered:
		return
	var mine := _own_room()
	if mine and room != mine and room.bounds.position.x > mine.bounds.position.x:
		_latched = true
		GameState.set_flag(persist_id)


func _own_room() -> Node:
	var node := get_parent()
	while node and not node is Room:
		node = node.get_parent()
	return node


func is_powered() -> bool:
	return powered


func is_solved() -> bool:
	return _latched


func reset_state() -> void:
	if persist_id != "" and GameState.has_flag(persist_id):
		# Targets reset themselves too; power them again once they have
		_apply.call_deferred(true, true)
		return
	_latched = false
	_chimed = false
	_held = 0.0
	_apply(false, true)


func _on_source_changed(_p: bool) -> void:
	_glow.queue_redraw()
	queue_redraw()


func _sources_satisfied() -> bool:
	if sources.is_empty():
		return false
	var any := false
	var all := true
	for source in sources:
		var on: bool = is_instance_valid(source) and source.is_powered()
		any = any or on
		all = all and on
	return all if mode == Mode.ALL else any


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	var want := _latched or _sources_satisfied()
	if want and not _latched:
		_held += delta
		if _held < hold_time:
			want = false
	elif not want:
		_held = 0.0
	if want and latch and not _latched:
		_latched = true
		if persist_id != "":
			GameState.set_flag(persist_id)
	# A puzzle's circuit chimes the first time it comes on, not every time
	if want and not _chimed and (latch or persist_id != ""):
		_chimed = true
		if solved_sound != "":
			Sfx.play(solved_sound, global_position)
	if want != powered:
		_apply(want)
		if want and reveal_target and not _revealed and not targets.is_empty() and targets[0] is Node2D:
			_revealed = true
			var root := get_tree().get_first_node_in_group("chapter_root")
			if root:
				root.show_mechanism(targets[0].global_position + Vector2(0, -40), 1.2)
	var near := Settings.guidance >= Settings.GUIDANCE_FULL and _player_near()
	var was := preview
	preview = move_toward(preview, 1.0 if near else 0.0, delta * 4.0)
	if powered or _any_source_powered() or preview > 0.0 or was > 0.0:
		_glow.queue_redraw()


func _player_near() -> bool:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return false
	for piece in sources + targets:
		if is_instance_valid(piece) and piece is Node2D \
				and piece.global_position.distance_to(_player.global_position) < PREVIEW_RANGE:
			return true
	return false


func _apply(on: bool, force := false) -> void:
	if on == powered and not force:
		return
	powered = on
	for target in targets:
		if is_instance_valid(target) and target.has_method("set_powered"):
			target.set_powered(on != invert)
	power_changed.emit(on)
	queue_redraw()
	_glow.queue_redraw()


func _any_source_powered() -> bool:
	for source in sources:
		if is_instance_valid(source) and source.is_powered():
			return true
	return false


# ------------------------------------------------------------------ channels

func _route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := to_local(from)
	var b := to_local(to)
	if is_zero_approx(channel_y):
		return PackedVector2Array([a, Vector2(b.x, a.y), b])
	var y := to_local(Vector2(0, channel_y)).y
	return PackedVector2Array([a, Vector2(a.x, y), Vector2(b.x, y), b])


func _paths() -> Array:
	var result := []
	for source in sources:
		if not is_instance_valid(source) or not source is Node2D:
			continue
		for target in targets:
			if is_instance_valid(target) and target is Node2D:
				result.append({"source": source, "points": _route(source.global_position, target.global_position)})
	return result


func _draw() -> void:
	if not show_channels:
		return
	# The carved groove is always visible, dimly
	for path in _paths():
		var points: PackedVector2Array = path["points"]
		draw_polyline(points, Color(0.03, 0.02, 0.06, 0.85), 4.0)
		draw_polyline(points, Color(channel_color.darkened(0.55), 0.55), 1.0)
		_draw_symbol(self, points[0], Color(channel_color.darkened(0.4), 0.8))
		_draw_symbol(self, points[points.size() - 1], Color(channel_color.darkened(0.4), 0.8))


func _draw_glow() -> void:
	if not show_channels:
		return
	for path in _paths():
		var source: Node = path["source"]
		var points: PackedVector2Array = path["points"]
		var source_on: bool = not Engine.is_editor_hint() and source.is_powered()
		if not (source_on or powered):
			# A faint trace keeps every connection readable in the dark; near
			# one of its pieces it brightens and pulses toward the target
			var p := preview
			_glow.draw_polyline(points, Color(channel_color, lerpf(0.12, 0.5, p)), 1.0)
			_draw_symbol(_glow, points[0], Color(channel_color, lerpf(0.35, 0.9, p)))
			_draw_symbol(_glow, points[points.size() - 1], Color(channel_color, lerpf(0.35, 0.9, p)))
			if p > 0.0:
				_draw_pulses(points, Color(channel_color, 0.55 * p))
				var end := points[points.size() - 1]
				_glow.draw_arc(end, 9.0 + 2.0 * sin(_time * 5.0), 0.0, TAU, 20, Color(channel_color, 0.6 * p), 1.0)
			continue
		var color := channel_color if powered else Color(channel_color, 0.55)
		_glow.draw_polyline(points, Color(color, color.a * 0.35), 3.0)
		_glow.draw_polyline(points, color, 1.0)
		# Energy pulses travelling from source to target
		_draw_pulses(points, color)
		_draw_symbol(_glow, points[0], color)
		if powered:
			_draw_symbol(_glow, points[points.size() - 1], color)


func _draw_pulses(points: PackedVector2Array, color: Color) -> void:
	var total := 0.0
	for i in points.size() - 1:
		total += points[i].distance_to(points[i + 1])
	var spacing := 26.0
	var start := fmod(_time * 40.0, spacing)
	var d := start
	while d < total:
		_glow.draw_rect(Rect2(_point_along(points, d) - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 1, 1, 0.9 * color.a))
		d += spacing


func _point_along(points: PackedVector2Array, distance: float) -> Vector2:
	var left := distance
	for i in points.size() - 1:
		var seg := points[i].distance_to(points[i + 1])
		if left <= seg:
			return points[i].lerp(points[i + 1], left / maxf(seg, 0.001))
		left -= seg
	return points[points.size() - 1]


func _draw_symbol(canvas: CanvasItem, at: Vector2, color: Color) -> void:
	match symbol:
		0:  # diamond
			canvas.draw_polyline(PackedVector2Array([at + Vector2(0, -4), at + Vector2(4, 0), at + Vector2(0, 4),
				at + Vector2(-4, 0), at + Vector2(0, -4)]), color, 1.0)
		1:  # circle
			canvas.draw_arc(at, 4.0, 0.0, TAU, 12, color, 1.0)
		2:  # triangle
			canvas.draw_polyline(PackedVector2Array([at + Vector2(0, -4), at + Vector2(4, 3), at + Vector2(-4, 3),
				at + Vector2(0, -4)]), color, 1.0)
		3:  # cross
			canvas.draw_line(at + Vector2(-4, 0), at + Vector2(4, 0), color, 1.0)
			canvas.draw_line(at + Vector2(0, -4), at + Vector2(0, 4), color, 1.0)
