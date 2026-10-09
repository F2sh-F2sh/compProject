class_name ChargeBreeze
extends Node2D

## A light breeze gathering at Echidna's feet while she charges a jump: a
## few specks of air drift in toward her and a little dust stirs along the
## ground, growing as the charge builds and warming to gold at full power.
## Only soft dots, never streaks or lines. When she leaps, the dust puffs out
## from where she stood.

const MOTES := 12
const PUFFS := 8
const AIR := Color(0.84, 0.93, 1.0)
const GOLD := Color(1.0, 0.86, 0.55)
const DUST := Color(0.7, 0.68, 0.78)
## Around her middle, where the air gathers.
const CENTER := Vector2(0, -14)

## 0 when still, rising to 1 at full charge.
var strength := 0.0

var _player
var _start := 1.0
var _time := 0.0
var _full := 0.0
## The take-off puff, 1 when she leaps and fading; drawn where she stood.
var _scatter := 0.0
var _scatter_strength := 0.0
var _launch_at := Vector2.ZERO


func _ready() -> void:
	_player = get_parent()
	var consts: Dictionary = _player.get_script().get_script_constant_map()
	_start = consts.get("CHARGE_START_TIME", 1.0)
	name = "ChargeBreeze"
	# Behind her, so the specks pass round rather than over her
	z_index = -1
	material = MagicLight.unshaded()
	visible = false


func _process(delta: float) -> void:
	var charging: bool = _player.charging_jump and not _player.is_dead
	var t: float = _player.charge_time
	if charging:
		# A faint stir as she crouches, then the real gathering with the power
		var settle := clampf((t - _start * 0.5) / (_start * 0.5), 0.0, 1.0) if _start > 0.0 else 1.0
		var target: float = 0.2 * settle + 0.8 * _player.charge_amount()
		strength = move_toward(strength, target, delta * 3.0)
	elif strength > 0.0:
		if _player.velocity.y < -50.0 and not _player.is_dead:
			# She leapt: the gathered air puffs out from under her
			_scatter = 1.0
			_scatter_strength = strength
			_launch_at = global_position
			strength = 0.0
		else:
			strength = move_toward(strength, 0.0, delta * 4.0)
	var full: bool = charging and _player.charge_amount() >= 1.0
	_full = move_toward(_full, 1.0 if full else 0.0, delta * 3.0)
	_scatter = maxf(_scatter - delta / 0.45, 0.0)
	_time += delta * (0.7 + 0.8 * strength)
	visible = strength > 0.0 or _scatter > 0.0
	if visible:
		queue_redraw()


func _draw() -> void:
	var s := strength
	if s > 0.0:
		var air := AIR.lerp(GOLD, _full)
		# Specks of air spiralling in toward her
		for i in MOTES:
			var k := fposmod(_time * 0.9 + float(i) / MOTES + 0.37 * i, 1.0)
			var r := lerpf(30.0, 8.0, k) * (0.8 + 0.2 * s)
			var turn := 1.0 if i % 2 == 0 else -1.0
			var angle := float(i) * 2.4 + turn * k * 2.2
			var p := CENTER + Vector2(cos(angle) * r, sin(angle) * r * 0.45 - k * 4.0)
			var a := sin(k * PI) * (0.35 + 0.5 * s)
			var size := 2.0 if i % 2 == 0 else 1.0
			draw_rect(Rect2(p.round(), Vector2(size, size)), Color(air, a))
		# Dust stirred along the ground at her feet
		for j in PUFFS:
			var side := -1.0 if j % 2 == 0 else 1.0
			var k := fposmod(_time * 1.3 + j * 0.37, 1.0)
			var p := Vector2(side * (6.0 + 20.0 * k), -2.0 - 4.0 * sin(k * PI))
			var a := sin(k * PI) * (1.0 - k) * 1.4 * s
			var size := 2.0 + roundf(k)
			draw_rect(Rect2(p.round(), Vector2(size, size - 1.0)), Color(DUST, a))
	if _scatter > 0.0:
		# The take-off puff, left behind on the ground as she rises
		var origin := to_local(_launch_at)
		var spread := 1.0 - _scatter
		for j in 8:
			var side := -1.0 if j % 2 == 0 else 1.0
			var x := side * (4.0 + (10.0 + j * 3.0) * spread)
			var p := origin + Vector2(x, -1.0 - (j % 3) * 2.0 * spread)
			draw_rect(Rect2(p.round(), Vector2(2, 2)), Color(DUST, 0.6 * _scatter * (0.4 + 0.6 * _scatter_strength)))
