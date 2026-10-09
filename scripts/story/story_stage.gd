class_name StoryStage
extends RefCounted

## How the story reels are staged, after Hollow Knight's cutscenes: each shot
## is a few depth layers (far haze and silhouettes, the focus, near rock in
## near-black) that drift at their own pace as the camera pushes in, with
## fog, hanging dust or rising embers, one glowing focus, and a colour grade
## and vignette over it all (StoryIntro). The great moth and its four chains
## live here too. Everything on stage is a pixel sprite (SurfaceArt); only
## light, air and fog are drawn.

const FOG_SHADER := preload("res://assets/shaders/story_fog.gdshader")
const MOTE := preload("res://assets/fx/mote.png")
## The four chains' words, in the order the plates are carved (hk_chain_plate).
const CHAIN_WORDS := ["ICE", "FREEZE", "SELF", "PERSIST"]

static var _noise: Texture2D


## A depth layer of picture `p`: what is added to it sits `depth` away
## (1 moves with the picture; less is farther and drifts less as the camera
## moves and pushes in; more is nearer and sweeps past).
static func layer(p: Node, depth: float, layer_name := "") -> Layer:
	var l := Layer.new()
	l.depth = depth
	l.name = layer_name if layer_name != "" else "Depth%d" % int(depth * 100)
	p.add_child(l)
	return l


## A canvas of art pixels on `parent`, drawn `scale` screen pixels to one.
static func canvas(parent: Node, scale := 3.0) -> Node2D:
	var c := Node2D.new()
	c.name = "Canvas"
	c.scale = Vector2(scale, scale)
	parent.add_child(c)
	return c


## A plain fill (the dark behind a cave, the black of a lore card).
static func fill(parent: Node, color: Color, rect := Rect2(-420, -320, 1992, 1288)) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.position = rect.position
	r.size = rect.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


## A vertical wash from `top` to `bottom` over `rect` (a cave's depth, a
## sky's last light).
static func wash(parent: Node, rect: Rect2, top: Color, bottom: Color) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, top)
	g.set_color(1, bottom)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 128
	var r := TextureRect.new()
	r.texture = tex
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = rect.position
	r.size = rect.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


## A band of fog drifting across `rect` (screen pixels in the picture).
static func fog(parent: Node, rect: Rect2, color: Color, speed := 0.012, seed_value := 0.0) -> ColorRect:
	var r := ColorRect.new()
	r.name = "Fog"
	r.position = rect.position
	r.size = rect.size
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = FOG_SHADER
	mat.set_shader_parameter("noise", _fog_noise())
	mat.set_shader_parameter("tint", color)
	mat.set_shader_parameter("speed", speed)
	mat.set_shader_parameter("stretch", rect.size.x / 900.0)
	mat.set_shader_parameter("seed", seed_value)
	r.material = mat
	parent.add_child(r)
	return r


static func _fog_noise() -> Texture2D:
	if _noise:
		return _noise
	var n := FastNoiseLite.new()
	n.seed = 1960
	n.frequency = 0.012
	n.fractal_octaves = 4
	_noise = ImageTexture.create_from_image(n.get_seamless_image(256, 256))
	return _noise


## A dark silhouette piece (hk_* sprites), feet at `foot` on canvas `c`,
## tinted (near pieces almost black, far ones lost in the haze).
static func piece(c: Node, sprite_name: String, foot: Vector2, tint := Color.WHITE, flip := false, flip_v := false) -> Sprite2D:
	var s := SurfaceArt.sprite(c, sprite_name, foot, 1.0, flip)
	s.modulate = tint
	s.flip_v = flip_v
	if flip_v:
		s.offset.y = 0.0
	return s


## Embers or sparks of light rising through `area`.
static func embers(parent: Node, area: Rect2, color: Color, amount := 26, rise := 18.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Embers"
	p.texture = MOTE
	p.amount = amount
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.position = area.get_center()
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = area.size / 2.0
	p.direction = Vector2(0, -1)
	p.spread = 25.0
	p.gravity = Vector2(0, -2)
	p.initial_velocity_min = rise * 0.5
	p.initial_velocity_max = rise
	p.scale_amount_min = 0.15
	p.scale_amount_max = 0.45
	var fade := Gradient.new()
	fade.set_color(0, Color(color, 0.0))
	fade.add_point(0.2, color)
	fade.set_color(fade.get_point_count() - 1, Color(color, 0.0))
	p.color_ramp = fade
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat
	parent.add_child(p)
	return p


## Snow hanging still in the air (the held moment): a field of flakes that
## never fall, each glinting slowly. Set `fall` above 0 and they come down.
static func hanging_snow(parent: Node, area: Rect2, amount := 90) -> CPUParticles2D:
	var s := StoryPaint.snow(parent, area, amount)
	s.name = "HangingSnow"
	s.speed_scale = 0.0
	return s


# ------------------------------------------------------------------ depth

class Layer extends Node2D:
	## 1: with the picture; under 1: farther; over 1: nearer.
	var depth := 1.0
	## The camera's resting point (the middle of the picture).
	var rest := Vector2(576, 324)

	func _ready() -> void:
		physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		process_priority = 100
		follow()

	func _process(_delta: float) -> void:
		follow()

	## Places the layer for where the camera is now: as it moves and zooms,
	## a far layer moves and grows less, a near one more.
	func follow() -> void:
		var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
		if cam == null:
			return
		var c := cam.global_position
		var z := cam.zoom.x
		var s := (1.0 + (z - 1.0) * depth) / z
		scale = Vector2(s, s)
		position = c - (rest + (c - rest) * depth) * s


# ------------------------------------------------------------------ light

## A beam of light rising (or falling) from a point: a soft additive column,
## widest and faintest at its far end. `reach` 0..1 draws it out.
class Beam extends Node2D:
	var length := 600.0
	var width_near := 40.0
	var width_far := 120.0
	var color := Color(1.0, 0.85, 0.55)
	var intensity := 0.6
	var up := true
	var reach := 1.0:
		set(value):
			reach = value
			queue_redraw()

	func _ready() -> void:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		material = mat

	func _draw() -> void:
		if reach <= 0.0:
			return
		var dir := -1.0 if up else 1.0
		var strips := 24
		var shown := length * reach
		for i in strips:
			var t0 := float(i) / strips
			var t1 := float(i + 1) / strips
			var w0 := lerpf(width_near, width_far, t0) / 2.0
			var w1 := lerpf(width_near, width_far, t1) / 2.0
			var a := intensity * pow(1.0 - t0, 1.3)
			for k in 3:
				# three nested columns: a soft wide one, a brighter core
				var f: float = [1.0, 0.6, 0.25][k]
				var ak: float = a * [0.35, 0.4, 0.6][k]
				var pts := PackedVector2Array([Vector2(-w0 * f, dir * shown * t0), Vector2(w0 * f, dir * shown * t0),
					Vector2(w1 * f, dir * shown * t1), Vector2(-w1 * f, dir * shown * t1)])
				draw_colored_polygon(pts, Color(color, ak))


# ------------------------------------------------------------------ the moth

## The held moment: a great pale moth whose wings are the frozen night.
## `light` 0..2 fills it, frozen to kindling to alight (the three frames of
## hk_moth, crossfaded); it breathes, a slow rise and fall, and its glow
## turns from cold to warm as it fills. `folded` shows it wrapped round
## itself instead.
class Moth extends Node2D:
	var art_scale := 3.0
	var folded := false
	var breathe := 3.0
	var light := 0.0:
		set(value):
			light = value
			_update()
	var _frames: Array = []
	var _glow: Sprite2D
	var _halo: Sprite2D
	var _time := 0.0

	func _ready() -> void:
		var body_y := -6.0 * art_scale
		_halo = StoryPaint.glow(self, Vector2(0, body_y), 150.0 * art_scale, Color(0.5, 0.62, 0.95), 0.25)
		_glow = StoryPaint.glow(self, Vector2(0, body_y), 70.0 * art_scale, Color(0.6, 0.75, 1.0), 0.5)
		var count := 1 if folded else 3
		for i in count:
			var s := Sprite2D.new()
			s.name = "Frame%d" % i
			s.texture = SurfaceArt.tex("hk_moth_folded" if folded else "hk_moth", i)
			s.scale = Vector2(art_scale, art_scale)
			add_child(s)
			_frames.append(s)
		_update()

	func _process(delta: float) -> void:
		_time += delta
		var b := sin(_time * 0.8)
		for s in _frames:
			s.position.y = roundf(b * breathe)
		_glow.modulate.a = 0.85 + 0.15 * sin(_time * 0.8 + 0.6)

	func _update() -> void:
		if _frames.is_empty():
			return
		for i in range(1, _frames.size()):
			_frames[i].modulate.a = clampf(light - (i - 1), 0.0, 1.0)
		var warm := clampf(light / 2.0, 0.0, 1.0)
		var cold := Color(0.6, 0.75, 1.0)
		var gold := Color(1.0, 0.78, 0.45)
		var c := cold.lerp(gold, warm)
		var e := lerpf(0.5, 1.3, warm)
		_glow.modulate = Color(c.r * e, c.g * e, c.b * e, _glow.modulate.a)
		var h := lerpf(0.25, 0.7, warm)
		_halo.modulate = Color(c.r * h, c.g * h, c.b * h, 1.0)


## One of the four chains that hold the moth: iron links (hk_chain_link)
## from this node to `to`, with its word plate (hk_chain_plate, `word` 0..3)
## partway along. snap() breaks it at the plate: the plate bursts into
## light, the upper half fades up into the moth, the lower half falls.
class Chain extends Node2D:
	var to := Vector2(0, 300)
	var word := 0
	var art_scale := 3.0
	var plate_at := 0.6
	var broken := false
	var upper: Links
	var lower: Links
	var plate: Sprite2D

	func _ready() -> void:
		var mid := to * plate_at
		upper = Links.new()
		upper.b = mid
		upper.art_scale = art_scale
		add_child(upper)
		lower = Links.new()
		lower.a = mid
		lower.b = to
		lower.art_scale = art_scale
		add_child(lower)
		plate = Sprite2D.new()
		plate.name = "Plate"
		plate.texture = SurfaceArt.tex("hk_chain_plate", word)
		plate.scale = Vector2(art_scale, art_scale)
		plate.position = mid
		add_child(plate)

	## Breaks the chain at its plate; returns how long it takes to clear.
	func snap() -> float:
		if broken:
			return 0.0
		broken = true
		var mid := to * plate_at
		var flash := StoryPaint.glow(self, mid, 40.0 * art_scale, Color(1.0, 0.86, 0.6), 1.2)
		var burst := CPUParticles2D.new()
		burst.texture = MOTE
		burst.amount = 26
		burst.lifetime = 1.6
		burst.one_shot = true
		burst.explosiveness = 1.0
		burst.position = mid
		burst.direction = Vector2(0, -1)
		burst.spread = 180.0
		burst.gravity = Vector2(0, 60)
		burst.initial_velocity_min = 60.0
		burst.initial_velocity_max = 170.0
		burst.scale_amount_min = 0.2
		burst.scale_amount_max = 0.6
		burst.color = Color(1.0, 0.88, 0.62)
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		burst.material = mat
		add_child(burst)
		burst.emitting = true
		var t := create_tween().set_parallel()
		t.tween_property(plate, "modulate", Color(2.0, 1.8, 1.4, 0.0), 0.5)
		t.tween_property(plate, "scale", plate.scale * 1.5, 0.5)
		t.tween_property(flash, "modulate:a", 0.0, 1.2).set_delay(0.15)
		# the lower half drops and swings away; the upper half draws up and goes
		t.tween_property(lower, "position", Vector2(to.x * 0.08, 140.0), 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(lower, "rotation", 0.12 * signf(to.x if to.x != 0.0 else 1.0), 1.4)
		t.tween_property(lower, "modulate:a", 0.0, 0.9).set_delay(0.6)
		t.tween_property(upper, "position", -mid * 0.25, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(upper, "modulate", Color(1.6, 1.3, 0.9, 0.0), 1.6)
		return 1.6


## A run of chain links from `a` to `b`.
class Links extends Node2D:
	var a := Vector2.ZERO
	var b := Vector2(0, 100)
	var art_scale := 3.0

	func _draw() -> void:
		var t := SurfaceArt.tex("hk_chain_link")
		var step := t.get_height() * art_scale * 0.75
		var d := b - a
		var n := maxi(int(d.length() / step), 1)
		var angle := d.angle() - PI / 2.0
		for i in n + 1:
			var p := a.lerp(b, float(i) / n)
			draw_set_transform(p.round(), angle, Vector2(art_scale, art_scale))
			draw_texture(t, -t.get_size() / 2.0, Color.WHITE if i % 2 == 0 else Color(0.72, 0.72, 0.8))
		draw_set_transform(Vector2.ZERO)
