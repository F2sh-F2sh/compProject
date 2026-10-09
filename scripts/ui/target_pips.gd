class_name TargetPips
extends CanvasLayer

## Fair aiming: every thing a rune, a beam or a bolt still has to reach in the
## room she is in (a brazier, a crystal, a lamp, brambles, a cracked wall, a
## seal) that is off the screen gets a small gold pip on the screen's edge,
## pointing at it, so no target has to be guessed at or learnt from a hint.
## Once it is lit, cleared or broken its pip goes. Hidden with the rest of the
## gameplay UI (cutscenes, the death screen) and with guidance turned off.
## ChapterRoot adds one to every chapter.

## The classes that count as targets.
const TARGETS := ["Brazier", "Burnable", "CrackedWall", "LightReceiver", "HallLamp", "GreatKiln", "ObservatorySeal",
	"RuneSeal", "FireballSwitch"]
## How far in from the screen's edge a pip sits.
const EDGE := 30.0
const GOLD := Color(0.94, 0.82, 0.48)

## Every target in the level.
var tracked: Array = []
## The targets with a pip on screen now.
var showing: Array = []
var _canvas: Control
var _time := 0.0


func _ready() -> void:
	layer = 4
	_canvas = Control.new()
	_canvas.name = "Pips"
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_to_group("gameplay_ui")
	_canvas.draw.connect(_draw_pips)
	add_child(_canvas)
	_gather.call_deferred()


func _gather() -> void:
	tracked.clear()
	for n in get_parent().find_children("*", "", true, false):
		var s: Script = n.get_script()
		if s and String(s.get_global_name()) in TARGETS:
			tracked.append(n)


static func is_done(target: Node) -> bool:
	if target.has_method("is_powered") and target.is_powered():
		return true
	return target.get("is_cleared") == true or target.get("is_broken") == true


func _process(delta: float) -> void:
	_time += delta
	showing.clear()
	var cam := get_viewport().get_camera_2d()
	var room = get_parent().get("current_room")
	if cam and room and Settings.guidance != Settings.GUIDANCE_OFF:
		var view := _view(cam).grow(-12.0)
		for t in tracked:
			if is_instance_valid(t) and t.is_inside_tree() and room.contains(t.global_position) \
					and not view.has_point(t.global_position) and not is_done(t):
				showing.append(t)
	_canvas.queue_redraw()


func _view(cam: Camera2D) -> Rect2:
	var size := get_viewport().get_visible_rect().size / cam.zoom
	return Rect2(cam.get_screen_center_position() - size / 2.0, size)


func _draw_pips() -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null or showing.is_empty():
		return
	var screen := get_viewport().get_visible_rect().size
	var centre := screen / 2.0
	var xform := get_viewport().get_canvas_transform()
	var inner := Rect2(Vector2(EDGE, EDGE + 40.0), screen - Vector2(EDGE * 2.0, EDGE * 2.0 + 80.0))
	var glow := 0.55 + 0.3 * sin(_time * 3.0)
	for t in showing:
		var at: Vector2 = xform * (t.global_position as Vector2)
		var dir := (at - centre).normalized()
		if dir == Vector2.ZERO:
			continue
		# where the line from the centre leaves the inner rectangle
		var k := INF
		if dir.x != 0.0:
			k = minf(k, ((inner.end.x if dir.x > 0.0 else inner.position.x) - centre.x) / dir.x)
		if dir.y != 0.0:
			k = minf(k, ((inner.end.y if dir.y > 0.0 else inner.position.y) - centre.y) / dir.y)
		var p := centre + dir * k
		var side := dir.orthogonal()
		var tip := p + dir * 14.0
		var col := Color(GOLD, glow)
		_canvas.draw_colored_polygon(PackedVector2Array([tip + dir * 2.0, p - dir * 5.0 + side * 12.0, p - dir * 5.0 - side * 12.0]),
			Color(0.05, 0.04, 0.06, 0.6 * glow))
		_canvas.draw_colored_polygon(PackedVector2Array([tip - dir * 1.0, p - dir * 2.0 + side * 9.0, p - dir * 2.0 - side * 9.0]), col)
		_canvas.draw_circle(p - dir * 12.0, 3.5, col)
