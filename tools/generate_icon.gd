extends SceneTree

## Paints the game's icon (res://assets/icon.png): a golden bell with a ring
## of sound on a dark violet tile. Drawn in code, no third-party art.
##   godot --headless --path . --script res://tools/generate_icon.gd

const SIZE := 256


func _init() -> void:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(SIZE / 2.0, SIZE / 2.0)
	for y in SIZE:
		for x in SIZE:
			var p := Vector2(x + 0.5, y + 0.5)
			img.set_pixel(x, y, _shade(p, center))
	img.save_png(ProjectSettings.globalize_path("res://assets/icon.png"))
	print("ICON DONE")
	quit()


func _shade(p: Vector2, center: Vector2) -> Color:
	# Rounded tile
	var q := (p - center).abs() - Vector2(SIZE * 0.5 - 28.0, SIZE * 0.5 - 28.0)
	var corner := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - 26.0
	if corner > 0.0:
		return Color(0, 0, 0, 0)
	var t := p.y / SIZE
	var c := Color(0.1, 0.06, 0.2).lerp(Color(0.04, 0.02, 0.08), t)
	# A ring of sound behind the bell
	var r := p.distance_to(center + Vector2(0, 22))
	var ring := exp(-pow((r - 92.0) / 5.0, 2.0)) * 0.7
	c = c.lerp(Color(0.95, 0.8, 0.5), ring)
	# The bell: a flared shape from the crown (y 58) to the lip (y 180)
	var k := (p.y - 58.0) / (180.0 - 58.0)
	if k >= 0.0 and k <= 1.0:
		var half := lerpf(24.0, 40.0, sqrt(k)) + (22.0 * pow(k, 6.0))
		if absf(p.x - center.x) < half:
			var shine := 1.0 - absf(p.x - (center.x - half * 0.35)) / half
			c = Color(0.62, 0.45, 0.2).lerp(Color(1.0, 0.86, 0.52), clampf(shine, 0.0, 1.0))
			if k > 0.93:
				c = c.darkened(0.3)
	# The clapper
	if p.distance_to(Vector2(center.x, 190.0)) < 11.0:
		c = Color(0.3, 0.22, 0.12)
	# The crown loop
	var loop := p.distance_to(Vector2(center.x, 50.0))
	if loop < 13.0 and loop > 6.0:
		c = Color(0.78, 0.6, 0.3)
	return c
