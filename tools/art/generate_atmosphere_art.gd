extends SceneTree

## Paints the dungeon's atmosphere textures into res://assets/fx/:
##   far_fog.png        distant hall: towers lost in mist, faint lights (opaque)
##   mid_ruins.png      crumbling arcades, broken columns, chains (silhouettes)
##   front_vines.png    roots and vines hanging into the top of the frame
##   front_thorns.png   rocks, curved thorns and grass framing the bottom
##   shaft_light.png    the shape a light shaft casts (Light2D texture)
##   soft_glow.png      radial glow for halos
##   mote.png           dust / ember particle
## Every layer tiles horizontally. Drawn from noise and hand-placed shapes with
## a fixed seed, so re-running gives the same art.
##   godot --headless --path . --script res://tools/art/generate_atmosphere_art.gd

const OUT := "res://assets/fx/"

var rng := RandomNumberGenerator.new()
var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
		rng.seed = 4242
		_far_fog().save_png(ProjectSettings.globalize_path(OUT + "far_fog.png"))
		_mid_ruins().save_png(ProjectSettings.globalize_path(OUT + "mid_ruins.png"))
		_front_vines().save_png(ProjectSettings.globalize_path(OUT + "front_vines.png"))
		_front_thorns().save_png(ProjectSettings.globalize_path(OUT + "front_thorns.png"))
		_shaft_light().save_png(ProjectSettings.globalize_path(OUT + "shaft_light.png"))
		_radial(128, 2.2).save_png(ProjectSettings.globalize_path(OUT + "soft_glow.png"))
		_radial(8, 1.6).save_png(ProjectSettings.globalize_path(OUT + "mote.png"))
		print("ATMOSPHERE ART DONE")
		quit()
	return false


# ================================================================ masks

## A coverage mask (0..1 per pixel) that wraps horizontally.
class Mask:
	var w: int
	var h: int
	var v: PackedFloat32Array

	func _init(width: int, height: int) -> void:
		w = width
		h = height
		v = PackedFloat32Array()
		v.resize(w * h)

	func at(x: int, y: int) -> float:
		if y < 0 or y >= h:
			return 0.0
		return v[y * w + posmod(x, w)]

	func put(x: int, y: int, value: float) -> void:
		if y < 0 or y >= h:
			return
		var i := y * w + posmod(x, w)
		v[i] = maxf(v[i], value)

	func cut(x: int, y: int) -> void:
		if y >= 0 and y < h:
			v[y * w + posmod(x, w)] = 0.0

	## Scanline polygon fill (holes: cut=true clears instead).
	func poly(pts: PackedVector2Array, value := 1.0, cut_out := false) -> void:
		var min_y := INF
		var max_y := -INF
		for p in pts:
			min_y = minf(min_y, p.y)
			max_y = maxf(max_y, p.y)
		for y in range(int(floor(min_y)), int(ceil(max_y)) + 1):
			var fy := y + 0.5
			var xs: Array[float] = []
			for i in pts.size():
				var a := pts[i]
				var b := pts[(i + 1) % pts.size()]
				if (a.y <= fy and b.y > fy) or (b.y <= fy and a.y > fy):
					xs.append(a.x + (fy - a.y) / (b.y - a.y) * (b.x - a.x))
			xs.sort()
			for k in range(0, xs.size() - 1, 2):
				for x in range(int(round(xs[k])), int(round(xs[k + 1]))):
					if cut_out:
						cut(x, y)
					else:
						put(x, y, value)

	func disc(c: Vector2, r: float, value := 1.0) -> void:
		for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
			for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
				var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
				if d <= r:
					put(x, y, value)

	## A tapering stroke along a polyline, stamped with discs.
	func stroke(pts: PackedVector2Array, r0: float, r1: float, value := 1.0) -> void:
		var total := 0.0
		for i in pts.size() - 1:
			total += pts[i].distance_to(pts[i + 1])
		var walked := 0.0
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			var seg := a.distance_to(b)
			var steps := maxi(int(seg), 1)
			for s in steps:
				var t := float(s) / steps
				disc(a.lerp(b, t), lerpf(r0, r1, (walked + seg * t) / maxf(total, 1.0)), value)
			walked += seg

	func blur(radius: int) -> void:
		for pass_i in 2:
			var out := PackedFloat32Array()
			out.resize(w * h)
			for y in h:
				for x in w:
					var sum := 0.0
					for k in range(-radius, radius + 1):
						sum += at(x + k, y) if pass_i == 0 else at(x, clampi(y + k, 0, h - 1))
					out[y * w + x] = sum / (radius * 2 + 1)
			v = out


# ================================================================ painting

func _image(w: int, h: int, fill := Color(0, 0, 0, 0)) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(fill)
	return img


## Paints a mask in `color`, with a lit rim where the shape's edge faces
## `light_dir` (e.g. up-left for moonlight from above).
func _paint(img: Image, m: Mask, color: Color, rim: Color, light_dir := Vector2(-0.4, -1.0), rim_px := 2) -> void:
	for y in m.h:
		for x in m.w:
			var a := m.at(x, y)
			if a <= 0.0:
				continue
			var c := color
			var lit := false
			for k in range(1, rim_px + 1):
				if m.at(x + int(round(light_dir.normalized().x * k)), y + int(round(light_dir.normalized().y * k))) <= 0.0:
					lit = true
					break
			if lit:
				c = rim
			var base := img.get_pixel(x, y)
			img.set_pixel(x, y, base.blend(Color(c, c.a * a)))


func _noise(freq: float, octaves := 4, seed_value := 0) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = seed_value if seed_value != 0 else rng.randi()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = freq
	n.fractal_octaves = octaves
	return n


func _seamless(w: int, h: int, freq: float, octaves := 4) -> Image:
	return _noise(freq, octaves).get_seamless_image(w, h, false, false, 0.15, true)


# ================================================================ far layer

func _far_fog() -> Image:
	var w := 1024
	var h := 704
	var img := _image(w, h)
	var top := Color(0.018, 0.03, 0.055)
	var mid := Color(0.075, 0.12, 0.16)
	var low := Color(0.045, 0.07, 0.1)
	for y in h:
		var k := float(y) / h
		var c := top.lerp(mid, smoothstep(0.0, 0.6, k)).lerp(low, smoothstep(0.62, 1.0, k))
		for x in w:
			img.set_pixel(x, y, c)

	# Towers and spires of a far-off hall, softened by distance
	var towers := Mask.new(w, h)
	var x := 30.0
	while x < w:
		var tw := rng.randf_range(34, 70)
		var top_y := rng.randf_range(90, 260)
		var spire := rng.randf_range(40, 110)
		towers.poly(PackedVector2Array([Vector2(x, h), Vector2(x, top_y), Vector2(x + tw * 0.5, top_y - spire),
			Vector2(x + tw, top_y), Vector2(x + tw, h)]))
		# Lit windows are cut back out and painted later
		x += tw + rng.randf_range(60, 150)
	towers.blur(2)
	_paint(img, towers, Color(0.05, 0.085, 0.12, 0.85), Color(0.09, 0.14, 0.19, 0.85), Vector2(-0.5, -1.0), 1)

	# Rolling mist, thickest in a band below the middle
	var fog := _seamless(w, h, 0.006, 5)
	var fine := _seamless(w, h, 0.02, 3)
	for y in h:
		var band := smoothstep(0.25, 0.62, float(y) / h) * (1.0 - smoothstep(0.85, 1.0, float(y) / h) * 0.4)
		for xx in w:
			var n := fog.get_pixel(xx, y).r * 0.75 + fine.get_pixel(xx, y).r * 0.25
			var a := smoothstep(0.38, 0.78, n) * band * 0.75
			img.set_pixel(xx, y, img.get_pixel(xx, y).lerp(Color(0.2, 0.3, 0.36), a))

	# Soft slanted rays from high openings
	for r in 4:
		var rx := rng.randf_range(0, w)
		var slope := rng.randf_range(0.25, 0.45)
		var width := rng.randf_range(30, 70)
		for y in h:
			var fade := (1.0 - float(y) / h) * 0.09
			for dx in range(-int(width), int(width)):
				var px := int(rx + y * slope) + dx
				var edge := 1.0 - absf(float(dx)) / width
				var c := img.get_pixel(posmod(px, w), y)
				img.set_pixel(posmod(px, w), y, c.lerp(Color(0.45, 0.62, 0.7), fade * edge * edge))

	# Distant glowing motes (lanterns, lumaflies)
	for i in 46:
		var c := Vector2(rng.randf_range(0, w), rng.randf_range(h * 0.15, h * 0.85))
		var rad := rng.randf_range(1.0, 3.2)
		var strength := rng.randf_range(0.25, 0.6)
		for yy in range(int(c.y - rad * 3), int(c.y + rad * 3) + 1):
			for xx in range(int(c.x - rad * 3), int(c.x + rad * 3) + 1):
				var d := Vector2(xx, yy).distance_to(c) / (rad * 2.2)
				if d < 1.0 and yy >= 0 and yy < h:
					var p := img.get_pixel(posmod(xx, w), yy)
					img.set_pixel(posmod(xx, w), yy, p.lerp(Color(0.6, 0.85, 0.9), strength * (1.0 - d) * (1.0 - d)))
	_grain(img, 0.018)
	return img


# ================================================================ mid layer

func _mid_ruins() -> Image:
	var w := 1024
	var h := 704
	var img := _image(w, h)
	var ruins := Mask.new(w, h)
	var ground := 610.0

	# Rubble ground across the whole width
	var pts := PackedVector2Array([Vector2(0, h)])
	var x := 0.0
	while x <= w:
		pts.append(Vector2(x, ground + rng.randf_range(-16, 10)))
		x += rng.randf_range(10, 28)
	pts.append(Vector2(w, pts[1].y))
	pts.append(Vector2(w, h))
	ruins.poly(pts)

	# Arcades, broken columns and wall fragments, spaced out along the width
	var cursor := 20.0
	var kinds := ["arcade", "column", "wall", "arcade", "columns", "wall", "column"]
	var k := 0
	while cursor < w - 60:
		var kind: String = kinds[k % kinds.size()]
		k += 1
		match kind:
			"arcade":
				cursor = _arcade(ruins, cursor, ground, rng.randi_range(2, 3))
			"column", "columns":
				for i in (2 if kind == "columns" else 1):
					cursor = _column(ruins, cursor, ground)
			"wall":
				cursor = _wall_fragment(ruins, cursor, ground)
		cursor += rng.randf_range(50, 120)

	# Chains hanging from far above
	for i in 5:
		var cx := rng.randf_range(0, w)
		var length := rng.randf_range(120, 300)
		var yy := 0.0
		while yy < length:
			ruins.poly(PackedVector2Array([Vector2(cx - 2, yy), Vector2(cx + 2, yy), Vector2(cx + 2, yy + 5),
				Vector2(cx - 2, yy + 5)]))
			ruins.poly(PackedVector2Array([Vector2(cx - 1, yy + 1), Vector2(cx + 1, yy + 1), Vector2(cx + 1, yy + 4),
				Vector2(cx - 1, yy + 4)]), 1.0, true)
			yy += 7.0
		ruins.disc(Vector2(cx, length + 6), 5.0)

	_paint(img, ruins, Color(0.05, 0.07, 0.108, 1.0), Color(0.15, 0.2, 0.29, 1.0), Vector2(-0.5, -1.0), 2)
	# Masonry courses and cracks drawn into the stone
	var courses := _seamless(w, h, 0.05, 2)
	for y in h:
		for xx in w:
			var c := img.get_pixel(xx, y)
			if c.a <= 0.0:
				continue
			if y % 11 == 0 and courses.get_pixel(xx, y).r > 0.35:
				img.set_pixel(xx, y, Color(c.darkened(0.25), c.a))
	# Sinking into the mist below
	for y in h:
		var mist := smoothstep(0.62, 1.0, float(y) / h)
		for xx in w:
			var c := img.get_pixel(xx, y)
			if c.a > 0.0:
				img.set_pixel(xx, y, Color(c.lerp(Color(0.1, 0.15, 0.2), mist * 0.7), c.a * (1.0 - mist * 0.45)))
	_grain(img, 0.02)
	return img


## A heavy arcade wall: solid masonry with pointed openings and a top that
## has crumbled away unevenly.
func _arcade(m: Mask, x0: float, ground: float, arches: int) -> float:
	var pillar := rng.randf_range(22, 30)
	var span := rng.randf_range(56, 78)
	var spring := rng.randf_range(340, 420)
	var rise := span * 0.85
	var total := pillar + arches * (span + pillar)
	var top := spring - rise - rng.randf_range(50, 100)
	var pts := PackedVector2Array([Vector2(x0, ground)])
	var steps := 10
	var dip := rng.randi_range(2, steps - 2)
	for i in steps + 1:
		var t := float(i) / steps
		var y := top + rng.randf_range(-10, 12)
		if absi(i - dip) <= 1:
			y += rng.randf_range(40, 90)  # a collapsed section
		pts.append(Vector2(x0 + total * t, y))
	pts.append(Vector2(x0 + total, ground))
	m.poly(pts)
	# Cornice along the spring line
	m.poly(_rect(x0 - 5, spring - 6, total + 10, 7))
	for a in arches:
		var left := x0 + pillar + a * (span + pillar)
		var opening := PackedVector2Array([Vector2(left, ground + 2)])
		for i in 13:
			var t := i / 12.0
			# Pointed (lancet) curve: two arcs meeting at the crown
			var lift := sin(minf(t, 1.0 - t) * PI) if t != 0.5 else 1.0
			opening.append(Vector2(left + span * t, spring - rise * pow(lift, 0.75)))
		opening.append(Vector2(left + span, ground + 2))
		m.poly(opening, 1.0, true)
	return x0 + total


func _column(m: Mask, x0: float, ground: float) -> float:
	var cw := rng.randf_range(26, 38)
	var top := rng.randf_range(220, 440)
	var pts := PackedVector2Array([Vector2(x0, ground), Vector2(x0, top)])
	# Jagged break at the top
	var steps := 6
	for i in steps + 1:
		pts.append(Vector2(x0 + cw * i / steps, top + rng.randf_range(-16, 12)))
	pts.append(Vector2(x0 + cw, ground))
	m.poly(pts)
	# Plinth, and a fallen drum leaning against it
	m.poly(_rect(x0 - 7, ground - 16, cw + 14, 16))
	var dx := x0 + cw + rng.randf_range(4, 14)
	m.poly(PackedVector2Array([Vector2(dx, ground), Vector2(dx + 6, ground - cw * 0.8), Vector2(dx + cw * 0.9, ground - cw * 0.95),
		Vector2(dx + cw * 0.95, ground)]))
	return x0 + cw


func _wall_fragment(m: Mask, x0: float, ground: float) -> float:
	var ww := rng.randf_range(120, 180)
	var top := rng.randf_range(260, 360)
	var pts := PackedVector2Array([Vector2(x0, ground)])
	var steps := 8
	for i in steps + 1:
		var t := float(i) / steps
		var y := top + sin(t * PI * 1.3) * 40.0 + rng.randf_range(-18, 18)
		pts.append(Vector2(x0 + ww * t, y))
	pts.append(Vector2(x0 + ww, ground))
	m.poly(pts)
	# Lancet windows
	var windows := rng.randi_range(1, 2)
	for i in windows:
		var wx := x0 + ww * (i + 1) / (windows + 1) - 8
		var wy := top + 70.0
		var win := PackedVector2Array([Vector2(wx, wy + 70), Vector2(wx, wy + 10), Vector2(wx + 8, wy - 6),
			Vector2(wx + 16, wy + 10), Vector2(wx + 16, wy + 70)])
		m.poly(win, 1.0, true)
	return x0 + ww


func _rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])


# ================================================================ foreground

func _front_vines() -> Image:
	var w := 1024
	var h := 180
	var img := _image(w, h)
	var m := Mask.new(w, h)
	# Moss and root mass along the top edge
	var pts := PackedVector2Array([Vector2(0, 0)])
	var x := 0.0
	while x <= w:
		pts.append(Vector2(x, rng.randf_range(4, 18)))
		x += rng.randf_range(6, 16)
	pts.append(Vector2(w, 0))
	m.poly(pts)
	for i in 26:
		var vx := rng.randf_range(0, w)
		var length := rng.randf_range(35, h - 8)
		if rng.randf() < 0.5:
			length *= 0.55
		var sway := rng.randf_range(-18, 18)
		var line := PackedVector2Array()
		for s in 13:
			var t := s / 12.0
			line.append(Vector2(vx + sin(t * PI * 0.9) * sway + sin(t * 9.0 + i) * 1.5, t * length))
		m.stroke(line, rng.randf_range(2.2, 4.0), 0.8)
		# Leaves along the vine
		for leaf in int(length / 14):
			var t := rng.randf_range(0.15, 1.0)
			var p := line[int(t * 12)]
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			m.poly(PackedVector2Array([p, p + Vector2(side * 5, 2), p + Vector2(side * 8, 6), p + Vector2(side * 3, 5)]))
	_paint(img, m, Color(0.012, 0.016, 0.03, 1.0), Color(0.06, 0.085, 0.12, 1.0), Vector2(1.0, 0.2), 1)
	return img


func _front_thorns() -> Image:
	var w := 1024
	var h := 150
	var img := _image(w, h)
	var m := Mask.new(w, h)
	# Rock line along the bottom
	var pts := PackedVector2Array([Vector2(0, h)])
	var x := 0.0
	while x <= w:
		pts.append(Vector2(x, h - rng.randf_range(14, 40)))
		x += rng.randf_range(14, 40)
	pts.append(Vector2(w, pts[1].y))
	pts.append(Vector2(w, h))
	m.poly(pts)
	# Curved thorns rising out of the rocks, leaning like hooked horns
	for i in 16:
		var bx := rng.randf_range(0, w)
		var tall := rng.randf_range(50, 90) if rng.randf() < 0.3 else rng.randf_range(20, 45)
		var lean := rng.randf_range(0.25, 0.6) * (1.0 if rng.randf() < 0.5 else -1.0)
		var base := rng.randf_range(7, 13)
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for s in 11:
			var t := s / 10.0
			var curve := Vector2(sin(t * t * 1.4) * lean * tall, -t * tall)
			var half := base * (1.0 - t)
			outer.append(Vector2(bx, h - 20) + curve + Vector2(-half, 0))
			inner.append(Vector2(bx, h - 20) + curve + Vector2(half, 0))
		inner.reverse()
		m.poly(outer + inner)
	# Grass tufts
	for i in 40:
		var gx := rng.randf_range(0, w)
		for blade in 4:
			var tip := Vector2(gx + rng.randf_range(-8, 8), h - rng.randf_range(34, 58))
			m.stroke(PackedVector2Array([Vector2(gx + blade * 2 - 3, h - 26), tip]), 1.4, 0.4)
	_paint(img, m, Color(0.01, 0.013, 0.025, 1.0), Color(0.055, 0.08, 0.11, 1.0), Vector2(-0.4, -1.0), 1)
	return img


# ================================================================ light textures

## The footprint of a light shaft: bright under the opening, soft edges,
## fading out toward the floor.
func _shaft_light() -> Image:
	var w := 128
	var h := 512
	var img := _image(w, h)
	for y in h:
		var along := float(y) / h
		var fade := (1.0 - 0.55 * along) * smoothstep(0.0, 0.06, along) * (1.0 - smoothstep(0.8, 1.0, along))
		for x in w:
			var across := absf(float(x) / (w - 1) * 2.0 - 1.0)
			var edge := 1.0 - smoothstep(0.45, 1.0, across)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(fade * edge, 0.0, 1.0)))
	return img


func _radial(size: int, falloff: float) -> Image:
	var img := _image(size, size)
	var c := Vector2(size, size) / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c) / (size / 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(pow(maxf(1.0 - d, 0.0), falloff), 0.0, 1.0)))
	return img


func _grain(img: Image, amount: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var g := rng.randf_range(-amount, amount)
			img.set_pixel(x, y, Color(c.r + g, c.g + g, c.b + g, c.a))
