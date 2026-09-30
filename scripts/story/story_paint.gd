class_name StoryPaint
extends RefCounted

## Brushes for the storybook pictures and the village above the dungeon:
## skies, ridges, mountains, towers, robed figures, bells, houses, trees and
## glows. Everything is a polygon or a soft glow, so the story art is made in
## code like the rest of the game's effects, and each piece can be animated.

const GLOW_TEXTURE := preload("res://assets/fx/soft_glow.png")
const MOTE := preload("res://assets/fx/mote.png")
const LABEL_FONT := preload("res://assets/Text/Orbitron-Bold.ttf")


static func label_font() -> Font:
	return LABEL_FONT


static func add(parent: Node, node: Node) -> Node:
	parent.add_child(node)
	return node


static func poly(parent: Node, points: PackedVector2Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = color
	p.antialiased = true
	parent.add_child(p)
	return p


static func rect(parent: Node, r: Rect2, color: Color) -> Polygon2D:
	return poly(parent, PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), color)


## A vertical gradient filling `r`, optionally through a middle colour.
static func sky(parent: Node, r: Rect2, top: Color, bottom: Color, middle := Color(0, 0, 0, 0)) -> Polygon2D:
	var p := Polygon2D.new()
	var x0 := r.position.x
	var x1 := r.end.x
	if middle.a > 0.0:
		var ym := r.position.y + r.size.y * 0.55
		p.polygon = PackedVector2Array([Vector2(x0, r.position.y), Vector2(x1, r.position.y), Vector2(x1, ym),
			Vector2(x1, r.end.y), Vector2(x0, r.end.y), Vector2(x0, ym)])
		p.vertex_colors = PackedColorArray([top, top, middle, bottom, bottom, middle])
	else:
		p.polygon = PackedVector2Array([r.position, Vector2(x1, r.position.y), r.end, Vector2(x0, r.end.y)])
		p.vertex_colors = PackedColorArray([top, top, bottom, bottom])
	parent.add_child(p)
	return p


## A soft additive glow: light, not paint.
static func glow(parent: Node, at: Vector2, radius: float, color: Color, energy := 1.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = GLOW_TEXTURE
	s.position = at
	s.scale = Vector2.ONE * radius * 2.0 / GLOW_TEXTURE.get_width()
	s.modulate = Color(color.r * energy, color.g * energy, color.b * energy, color.a)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	s.material = mat
	parent.add_child(s)
	return s


## A line of hills from x0 to x1: its top rolls around `y`, up to `height`
## higher, and it is filled down to `bottom`.
static func ridge(parent: Node, x0: float, x1: float, y: float, height: float, bottom: float, color: Color,
		seed_value: int, step := 16.0) -> Polygon2D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var f := [rng.randf_range(0.004, 0.007), rng.randf_range(0.011, 0.017), rng.randf_range(0.03, 0.05)]
	var ph := [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
	var pts := PackedVector2Array()
	var x := x0
	while x <= x1 + step:
		var h := 0.5 * sin(x * f[0] + ph[0]) + 0.3 * sin(x * f[1] + ph[1]) + 0.2 * sin(x * f[2] + ph[2])
		pts.append(Vector2(minf(x, x1), y - height * (0.5 + 0.5 * h) + rng.randf_range(-1.5, 1.5)))
		x += step
	pts.append(Vector2(x1, bottom))
	pts.append(Vector2(x0, bottom))
	return poly(parent, pts, color)


## A craggy mountain rising to a peak at `peak`, its flanks reaching
## `half_width`: steep near the top, easing out at the foot, with rocky
## edges and a shoulder on one side.
static func mountain(parent: Node, peak: Vector2, half_width: float, bottom: float, color: Color, seed_value: int) -> Polygon2D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var ph := [rng.randf() * TAU, rng.randf() * TAU]
	var shoulder := 0.28 if rng.randf() < 0.5 else 0.72
	var pts := PackedVector2Array()
	var n := 48
	var rise := bottom - peak.y
	for i in n + 1:
		var t := float(i) / n
		var x := peak.x - half_width + t * half_width * 2.0
		var k := 1.0 - absf(t - 0.5) * 2.0
		var y := bottom - rise * pow(k, 1.45)
		var rough := sin(k * PI)
		y += (sin(t * 23.0 + ph[0]) * 0.55 + sin(t * 61.0 + ph[1]) * 0.3) * 16.0 * rough
		y += rng.randf_range(-3.0, 3.0) * rough
		y -= rise * 0.14 * exp(-pow((t - shoulder) / 0.07, 2.0))
		if i == n / 2:
			y = peak.y
		pts.append(Vector2(x, y))
	pts.append(Vector2(peak.x + half_width, bottom + 400.0))
	pts.append(Vector2(peak.x - half_width, bottom + 400.0))
	return poly(parent, pts, color)


## A tower standing on `base`: a body `w` wide and `h` tall, with a spire,
## a dome, a belfry arch or a battlemented top.
static func tower(parent: Node, base: Vector2, w: float, h: float, color: Color, roof := "spire", roof_h := 0.0) -> Node2D:
	var node := Node2D.new()
	node.position = base
	parent.add_child(node)
	rect(node, Rect2(-w / 2.0, -h, w, h), color)
	match roof:
		"spire":
			var rh := roof_h if roof_h > 0.0 else w * 1.6
			poly(node, PackedVector2Array([Vector2(-w / 2.0 - 3.0, -h), Vector2(w / 2.0 + 3.0, -h), Vector2(0, -h - rh)]), color)
		"dome":
			var pts := PackedVector2Array()
			var r := w / 2.0 + 2.0
			for i in 17:
				var a := PI + PI * i / 16.0
				pts.append(Vector2(cos(a) * r, -h + sin(a) * r * 0.9))
			poly(node, pts, color)
			poly(node, PackedVector2Array([Vector2(-1.5, -h - r * 0.9), Vector2(1.5, -h - r * 0.9), Vector2(0, -h - r * 0.9 - 10.0)]), color)
		"belfry":
			rect(node, Rect2(-w / 2.0 - 3.0, -h - 4.0, w + 6.0, 4.0), color)
			poly(node, PackedVector2Array([Vector2(-w / 2.0 - 3.0, -h - 4.0), Vector2(w / 2.0 + 3.0, -h - 4.0), Vector2(0, -h - 4.0 - w * 0.9)]), color)
		"crenel":
			for i in 3:
				rect(node, Rect2(-w / 2.0 + i * w / 2.5, -h - 5.0, w / 5.0, 5.0), color)
	return node


## A small window of light, with its glow.
static func window(parent: Node, at: Vector2, size: Vector2, color: Color, glow_radius := 0.0) -> Polygon2D:
	var p := rect(parent, Rect2(at - size / 2.0, size), color)
	if glow_radius > 0.0:
		glow(parent, at, glow_radius, color, 0.55)
	return p


## A figure in a hooded robe standing with its feet at `feet`, facing +x (or
## -x with facing -1). `rim` lights one edge from the side `rim_dir` (+1 the
## light is to the right, -1 to the left). With `eyes`, two pale eyes shine
## from the dark of the hood, as Echidna's do.
static func robed_figure(parent: Node, feet: Vector2, h: float, color: Color, facing := 1, eyes := false,
		hem_width := 0.0, rim := Color(0, 0, 0, 0), rim_dir := 0.0) -> Node2D:
	var node := Node2D.new()
	node.position = feet
	node.scale.x = facing
	parent.add_child(node)
	var w := hem_width if hem_width > 0.0 else h * 0.44
	var body := PackedVector2Array([
		Vector2(-w * 0.52, -h * 0.02), Vector2(-w * 0.44, -h * 0.4), Vector2(-w * 0.36, -h * 0.66),
		Vector2(-w * 0.3, -h * 0.84), Vector2(-w * 0.2, -h * 0.96), Vector2(-w * 0.02, -h),
		Vector2(w * 0.16, -h * 0.97), Vector2(w * 0.3, -h * 0.87), Vector2(w * 0.37, -h * 0.76),
		Vector2(w * 0.31, -h * 0.72), Vector2(w * 0.4, -h * 0.64), Vector2(w * 0.46, -h * 0.36),
		Vector2(w * 0.55, -h * 0.02), Vector2(w * 0.5, 0), Vector2(-w * 0.5, 0)])
	if rim.a > 0.0 and rim_dir != 0.0:
		var shifted := PackedVector2Array()
		var shift := Vector2(rim_dir * facing * maxf(h * 0.018, 1.5), -maxf(h * 0.008, 1.0))
		for p in body:
			shifted.append(p + shift)
		poly(node, shifted, rim)
	poly(node, body, color)
	# The shadow of the face inside the hood
	poly(node, PackedVector2Array([Vector2(w * 0.1, -h * 0.9), Vector2(w * 0.28, -h * 0.86), Vector2(w * 0.3, -h * 0.76),
		Vector2(w * 0.14, -h * 0.74)]), color.darkened(0.5))
	if eyes:
		var e := Color(0.93, 0.93, 1.0)
		var s := maxf(h * 0.022, 1.0)
		rect(node, Rect2(Vector2(w * 0.15, -h * 0.84), Vector2(s, s * 1.6)), e)
		rect(node, Rect2(Vector2(w * 0.24, -h * 0.84), Vector2(s, s * 1.6)), e)
	return node


## A bell outline, hanging from (0, 0) and `size` tall.
static func bell_points(size: float) -> PackedVector2Array:
	var half := [Vector2(0.1, 0.0), Vector2(0.12, 0.07), Vector2(0.27, 0.13), Vector2(0.34, 0.26), Vector2(0.36, 0.48),
		Vector2(0.39, 0.66), Vector2(0.46, 0.82), Vector2(0.55, 0.93), Vector2(0.56, 1.0)]
	var pts := PackedVector2Array()
	for p in half:
		pts.append(Vector2(p.x, p.y) * size)
	for i in range(half.size() - 1, -1, -1):
		pts.append(Vector2(-half[i].x, half[i].y) * size)
	return pts


## A bell that can swing: the returned node's origin is where it hangs.
static func bell(parent: Node, hang: Vector2, size: float, color: Color, rim := Color(0, 0, 0, 0)) -> Node2D:
	var node := Node2D.new()
	node.position = hang
	parent.add_child(node)
	poly(node, bell_points(size), color)
	if rim.a > 0.0:
		var lip := Line2D.new()
		lip.points = PackedVector2Array([Vector2(-0.55, 0.96) * size, Vector2(0.55, 0.96) * size])
		lip.width = maxf(size * 0.03, 1.5)
		lip.default_color = rim
		node.add_child(lip)
		var shoulder := Line2D.new()
		shoulder.points = PackedVector2Array([Vector2(-0.3, 0.2) * size, Vector2(-0.34, 0.45) * size])
		shoulder.width = maxf(size * 0.025, 1.0)
		shoulder.default_color = Color(rim, rim.a * 0.6)
		node.add_child(shoulder)
	return node


## A steep-roofed village house with its feet on `base` (bottom centre).
## `windows` are positions relative to `base`; `lit` sets which glow.
static func house(parent: Node, base: Vector2, w: float, h: float, wall: Color, roof: Color, windows := [],
		lit := [], chimney := true) -> Node2D:
	var node := Node2D.new()
	node.position = base
	parent.add_child(node)
	rect(node, Rect2(-w / 2.0, -h, w, h), wall)
	# Timber frame
	var beam := wall.darkened(0.35)
	rect(node, Rect2(-w / 2.0, -h, w, 3.0), beam)
	rect(node, Rect2(-w / 2.0, -h * 0.52, w, 2.0), beam)
	rect(node, Rect2(-w / 2.0, -h, 3.0, h), beam)
	rect(node, Rect2(w / 2.0 - 3.0, -h, 3.0, h), beam)
	var roof_h := w * 0.62
	poly(node, PackedVector2Array([Vector2(-w / 2.0 - 8.0, -h + 2.0), Vector2(w / 2.0 + 8.0, -h + 2.0),
		Vector2(w * 0.08, -h - roof_h), Vector2(-w * 0.08, -h - roof_h)]), roof)
	if chimney:
		rect(node, Rect2(w * 0.18, -h - roof_h * 0.85, 9.0, roof_h * 0.55), roof.darkened(0.2))
	for i in windows.size():
		var on: bool = lit.has(i)
		var c := Color(1.0, 0.72, 0.38) if on else wall.darkened(0.55)
		window(node, windows[i], Vector2(9, 11), c, 30.0 if on else 0.0)
	return node


## A dark fir: stacked triangles.
static func fir(parent: Node, base: Vector2, h: float, color: Color) -> Node2D:
	var node := Node2D.new()
	node.position = base
	parent.add_child(node)
	rect(node, Rect2(-2.0, -h * 0.18, 4.0, h * 0.18), color)
	for i in 3:
		var y0 := -h * (0.15 + i * 0.27)
		var w := h * (0.34 - i * 0.08)
		poly(node, PackedVector2Array([Vector2(-w, y0), Vector2(w, y0), Vector2(0, y0 - h * 0.42)]), color)
	return node


## Slow motes drifting in `area`.
static func motes(parent: Node, area: Rect2, color: Color, amount := 30) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = MOTE
	p.amount = amount
	p.lifetime = 8.0
	p.preprocess = 8.0
	p.position = area.get_center()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area.size / 2.0
	p.gravity = Vector2(0, 2)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 8.0
	p.spread = 180.0
	p.scale_amount_min = 0.2
	p.scale_amount_max = 0.5
	p.color = color
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	parent.add_child(p)
	return p


## Snow falling across `area` (set speed_scale to 0 and it hangs in the air).
static func snow(parent: Node, area: Rect2, amount := 90) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = MOTE
	p.amount = amount
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.position = area.get_center()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area.size / 2.0
	p.direction = Vector2(0.15, 1.0)
	p.spread = 12.0
	p.gravity = Vector2(0, 0)
	p.initial_velocity_min = 22.0
	p.initial_velocity_max = 40.0
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.6
	p.color = Color(0.92, 0.96, 1.0, 0.85)
	parent.add_child(p)
	return p


## A little monastery on a summit: towers, a belfry and the observatory's
## dome, with a few lit windows.
static func monastery(parent: Node, summit: Vector2, s: float, color: Color, lit := true) -> Node2D:
	var node := Node2D.new()
	node.position = summit
	node.scale = Vector2(s, s)
	parent.add_child(node)
	# The crag it is built on, so it never seems to float over a sharp peak
	poly(node, PackedVector2Array([Vector2(-78, 2), Vector2(78, 2), Vector2(62, 22), Vector2(40, 34), Vector2(14, 58),
		Vector2(-12, 60), Vector2(-38, 38), Vector2(-64, 20)]), color)
	rect(node, Rect2(-70, -26, 140, 30), color)
	tower(node, Vector2(-52, -24), 20, 42, color, "spire", 30)
	tower(node, Vector2(-18, -24), 26, 70, color, "belfry")
	tower(node, Vector2(30, -24), 54, 30, color, "dome")
	tower(node, Vector2(62, -24), 14, 26, color, "spire", 18)
	if lit:
		var warm := Color(1.0, 0.74, 0.4)
		for p in [Vector2(-52, -46), Vector2(-18, -60), Vector2(18, -34), Vector2(40, -34), Vector2(-40, -12)]:
			window(node, p, Vector2(4, 5), warm, 10.0)
	return node
