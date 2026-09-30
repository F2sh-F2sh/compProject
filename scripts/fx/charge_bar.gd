class_name ChargeBar
extends Node2D

## A small bar over Echidna's head while she charges a jump. It fades in as
## she settles into the charge pose, fills as the jump gathers power, and
## the moment the jump is at full power it turns gold, flashes and chimes
## once. It fades away when she leaps or stands up.

const WIDTH := 22
const HEIGHT := 3
## Above her head, clear of her hat.
const HEAD_Y := -49.0
const BACK := Color(0.05, 0.04, 0.09, 0.85)
const EDGE := Color(0.78, 0.74, 0.92, 0.75)
const FILL := Color(0.6, 0.84, 1.0)
const FULL := Color(1.0, 0.68, 0.16)

## Whether the jump is at full power (resets when a new charge begins).
var full := false
## How many times the bar has reached full (the tests count the chimes).
var times_full := 0
## The fill shown, 0-1 (it keeps its last value while fading out).
var fill := 0.0

var _player
var _start := 1.0
var _alpha := 0.0
var _flash := 0.0
var _time := 0.0


func _ready() -> void:
	_player = get_parent()
	var consts: Dictionary = _player.get_script().get_script_constant_map()
	_start = consts.get("CHARGE_START_TIME", 1.0)
	name = "ChargeBar"
	position = Vector2(-1, HEAD_Y)
	z_index = 20
	material = MagicLight.unshaded()
	visible = false


func _process(delta: float) -> void:
	var charging: bool = _player.charging_jump and not _player.is_dead
	var t: float = _player.charge_time
	# It shows a moment before the power starts, so it is there to watch fill
	var shown := charging and t >= _start - 0.3
	if charging:
		fill = _player.charge_amount()
		if fill <= 0.0:
			full = false
		elif fill >= 1.0 and not full:
			full = true
			times_full += 1
			_flash = 1.0
			Sfx.play("charge_full", global_position, -7.0, 0.0)
	# (Gone almost at once when she leaps, so it never sits on her rising hat)
	var leapt: bool = not charging and _player.velocity.y < -50.0
	_alpha = move_toward(_alpha, 1.0 if shown else 0.0, delta * (7.0 if shown else (12.0 if leapt else 5.0)))
	_flash = maxf(_flash - delta * 2.5, 0.0)
	_time += delta
	visible = _alpha > 0.0
	if visible:
		queue_redraw()


func _draw() -> void:
	var a := _alpha
	var bar := Rect2(-WIDTH * 0.5, -1, WIDTH, HEIGHT)
	draw_rect(bar.grow(1.0), Color(EDGE, EDGE.a * a))
	draw_rect(bar, Color(BACK, BACK.a * a))
	var color := FILL
	if full:
		# Gold, breathing gently, so "ready" reads at a glance
		color = FULL.lerp(Color(1.0, 0.9, 0.5), 0.2 + 0.2 * sin(_time * 9.0))
	var width := roundf(WIDTH * fill)
	if width > 0.0:
		draw_rect(Rect2(bar.position, Vector2(width, HEIGHT)), Color(color, a))
		# A lighter top edge, like light on glass
		draw_rect(Rect2(bar.position, Vector2(width, 1)), Color(color.lightened(0.35), a))
	if _flash > 0.0:
		# At full: the bar flares and a bright rim swells out and fades
		draw_rect(bar, Color(1.0, 0.97, 0.85, 0.7 * _flash * a))
		draw_rect(bar.grow(1.0 + 3.0 * (1.0 - _flash)), Color(1.0, 0.88, 0.5, 0.8 * _flash * a), false, 1.0)
