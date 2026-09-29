extends Node2D

## Draws only the half of each orbit that passes in front of (or behind) the wizard,
## so two instances at different z_index wrap the wind around him.
@export var front := false

const STREAKS := 6
const MOTES := 5
const TAIL_SEGMENTS := 7
const WIND_COLOR := Color(0.86, 0.95, 1.0)
const FULL_COLOR := Color(1.0, 1.0, 0.85)

var strength := 0.0
var spin := 0.0
var rise := 0.0
var burst := 0.0
var burst_strength := 0.0


func release() -> void:
	if strength > 0.05:
		burst = 1.0
		burst_strength = strength
	strength = 0.0


## Stops instantly with no burst, e.g. when the player is reset or dies.
func cancel() -> void:
	strength = 0.0
	burst = 0.0
	burst_strength = 0.0
	visible = false


func _process(delta: float) -> void:
	var s := maxf(strength, burst_strength * burst)
	spin += delta * lerpf(5.0, 13.0, s)
	rise += delta * lerpf(0.5, 1.1, s)
	burst = maxf(burst - delta / 0.3, 0.0)
	visible = strength > 0.0 or burst > 0.0
	if visible:
		queue_redraw()


func _draw() -> void:
	var s := strength
	var spread := 1.0
	var alpha := 1.0
	if strength <= 0.0:
		s = burst_strength
		spread = 1.0 + (1.0 - burst) * 1.4
		alpha = burst

	var color := WIND_COLOR.lerp(FULL_COLOR, clampf((s - 0.9) * 10.0, 0.0, 1.0))

	for i in STREAKS:
		var h := fposmod(rise + float(i) / STREAKS, 1.0)
		var fade := sin(h * PI)
		var y := lerpf(-2.0, -42.0, h)
		var rx := (11.0 + 11.0 * h + 5.0 * s) * spread
		var ry := (3.0 + 2.5 * h) * spread
		var angle := spin + float(i) * TAU / STREAKS * 1.7
		var arc := 0.14 + 0.08 * s

		for k in TAIL_SEGMENTS:
			var a0 := angle - k * arc
			var a1 := a0 - arc
			if (sin((a0 + a1) * 0.5) > 0.0) != front:
				continue
			var p0 := Vector2(cos(a0) * rx, y + sin(a0) * ry).round()
			var p1 := Vector2(cos(a1) * rx, y + sin(a1) * ry).round()
			var a := alpha * fade * (0.35 + 0.6 * s) * (1.0 - float(k) / TAIL_SEGMENTS)
			draw_line(p0, p1, Color(color, a), 1.0 if k > 2 else 2.0)

	for m in MOTES:
		var h := fposmod(rise * 1.6 + float(m) / MOTES + 0.13, 1.0)
		var a := spin * 1.4 + float(m) * 2.3
		if (sin(a) > 0.0) != front:
			continue
		var rx := (14.0 + 12.0 * h + 5.0 * s) * spread
		var p := Vector2(cos(a) * rx, lerpf(-4.0, -46.0, h) + sin(a) * 5.0).round()
		draw_rect(Rect2(p, Vector2(2, 2)), Color(color, alpha * sin(h * PI) * s))
