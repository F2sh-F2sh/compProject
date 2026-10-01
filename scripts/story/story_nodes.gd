class_name StoryNodes
extends RefCounted

## The small moving parts of the storybook pictures (and the village sky).


## A field of twinkling stars, drawn with the surface pack's sparkle sprites
## (in the node's own units, so scale it like the picture). Stars can be
## unwritten: they fade once the
## Hush's circle (`hush_origin`, `hush_radius`) reaches them, or in a random
## order as `fade` rises from 0 to 1.
class Stars extends Node2D:
	var area := Rect2(-420, -320, 1992, 760)
	var count := 220
	var seed_value := 7
	var hush_origin := Vector2.ZERO
	var hush_radius := -1.0
	var fade := 0.0
	var tint := Color(0.9, 0.92, 1.0)
	var _stars: Array = []
	var _time := 0.0

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		# The pack's sparkles: mostly specks, a few small crosses, rarely a big one
		var kinds := ["spark_tiny", "spark_tiny", "spark_tiny", "spark_small", "spark_tiny", "spark_small", "spark"]
		for i in count:
			var p := Vector2(rng.randf_range(area.position.x, area.end.x), area.position.y + pow(rng.randf(), 1.5) * area.size.y)
			var kind: String = kinds[rng.randi() % kinds.size()] if rng.randf() > 0.04 else "spark"
			_stars.append({"p": p.round(), "t": SurfaceArt.tex(kind), "ph": rng.randf() * TAU,
				"sp": rng.randf_range(0.7, 2.6), "o": rng.randf(), "a": 1.0})

	func _process(delta: float) -> void:
		_time += delta
		for star in _stars:
			var gone: bool = star["o"] < fade or (hush_radius >= 0.0 and star["p"].distance_to(hush_origin) < hush_radius)
			star["a"] = move_toward(star["a"], 0.0 if gone else 1.0, delta * 1.4)
		queue_redraw()

	func _draw() -> void:
		for star in _stars:
			var a: float = star["a"]
			if a <= 0.01:
				continue
			var twinkle: float = 0.55 + 0.45 * sin(_time * star["sp"] + star["ph"])
			var t: Texture2D = star["t"]
			draw_texture(t, (star["p"] - t.get_size() / 2.0).floor(), Color(tint, a * twinkle))


## Stars that join into a constellation, line by line (`progress` 0..1), and
## the rune it spells, glowing into view as `glyph_alpha` rises.
class Constellation extends Node2D:
	var points: Array = []
	var progress := 0.0
	var glyph := &"wind"
	var glyph_center := Vector2.ZERO
	var glyph_size := 120.0
	var glyph_alpha := 0.0
	var color := Color(0.72, 0.62, 1.0)
	var _time := 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		if glyph_alpha > 0.0:
			draw_circle(glyph_center, glyph_size * 0.62, Color(color, 0.05 * glyph_alpha))
			RuneFragments.draw_glyph(self, glyph, glyph_center, glyph_size, Color(color, 0.85 * glyph_alpha), 3.0)
		var segments := points.size() - 1
		var drawn := progress * segments
		for i in segments:
			var k := clampf(drawn - i, 0.0, 1.0)
			if k <= 0.0:
				break
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			draw_line(a, a.lerp(b, k), Color(color, 0.55 * (1.0 - glyph_alpha * 0.6)), 1.5, true)
		for i in points.size():
			var lit := clampf(drawn - i + 1.0, 0.0, 1.0)
			var pulse := 0.75 + 0.25 * sin(_time * 2.0 + i)
			draw_circle(points[i], 2.5, Color(1, 1, 1, 0.5 + 0.5 * lit))
			draw_circle(points[i], 7.0 * lit, Color(color, 0.25 * lit * pulse))


## One rune glowing in the sky, with its name beneath.
class Glyph extends Node2D:
	var glyph := &"wind"
	var size := 70.0
	var color := Color(0.72, 0.62, 1.0)
	var label := ""
	var alpha := 1.0:
		set(value):
			alpha = value
			queue_redraw()

	func _draw() -> void:
		draw_circle(Vector2.ZERO, size * 0.66, Color(color, 0.07 * alpha))
		RuneFragments.draw_glyph(self, glyph, Vector2.ZERO, size, Color(color, alpha), 2.5)
		if label != "":
			var font: Font = StoryPaint.label_font()
			draw_string(font, Vector2(-80, size * 0.62 + 16), label, HORIZONTAL_ALIGNMENT_CENTER, 160, 13, Color(color, 0.8 * alpha))


## A rune cube seen head-on: the carved stone (a pixel sprite from the story
## sprites, drawn `art_scale` times over) with four sockets (essence, action,
## direction, modifier) whose runes light up one by one as `lit` rises from
## 0 to 4. The runes are the game's own glyphs.
class Cube extends Node2D:
	var sprite_name := "rune_cube"
	var art_scale := 3.0
	var words: Array = [&"wind", &"push", &"up", &"strong"]
	var color := Color(0.62, 0.48, 1.0)
	var show_names := false
	var lit := 0.0:
		set(value):
			lit = value
			_update_glows()
			queue_redraw()
	var _glows: Array = []
	var _texture: Texture2D

	func _ready() -> void:
		_texture = SurfaceArt.tex(sprite_name)
		for i in 4:
			var g := StoryPaint.glow(self, _center(i), _texture.get_width() * art_scale * 0.42, color, 0.8)
			g.modulate.a = 0.0
			_glows.append(g)
		_update_glows()

	## The size of a socket, in art pixels (as tools/generate_story_sprites.gd
	## _cube() carves them).
	func _cell() -> int:
		var w := _texture.get_width()
		return (w - 2 - 3 * _gap()) / 2

	func _gap() -> int:
		return 2 if _texture.get_width() < 30 else 3

	func _center(i: int) -> Vector2:
		var w := _texture.get_width()
		var offset := (1 + _gap() + _cell() / 2.0) - w / 2.0
		var step := float(_cell() + _gap())
		return Vector2(offset + (i % 2) * step, offset + (i / 2) * step) * art_scale

	func _update_glows() -> void:
		for i in _glows.size():
			_glows[i].modulate.a = clampf(lit - i, 0.0, 1.0) * 0.55

	func _draw() -> void:
		var tsize := _texture.get_size() * art_scale
		draw_texture_rect(_texture, Rect2(-tsize / 2.0, tsize), false)
		var cell := _cell() * art_scale
		for i in 4:
			var c := _center(i)
			var on := clampf(lit - i, 0.0, 1.0)
			if on > 0.0:
				# The socket fills with the rune's light
				draw_rect(Rect2(c - Vector2(cell, cell) / 2.0, Vector2(cell, cell)), Color(color.darkened(0.55), 0.8 * on))
			var glyph_color := Color(0.36, 0.38, 0.55).lerp(color.lightened(0.45), on)
			RuneFragments.draw_glyph(self, words[i], c, cell * 0.72, glyph_color, maxf(art_scale * 0.55, 1.5))
			if show_names and on > 0.0:
				var font: Font = StoryPaint.label_font()
				var fs := int(maxf(cell * 0.16, 11.0))
				draw_string(font, c + Vector2(-cell, cell * 0.5 + fs + 4.0), RuneFragments.name_of(words[i]).to_upper(),
					HORIZONTAL_ALIGNMENT_CENTER, cell * 2.0, fs, Color(1, 1, 1, 0.9 * on))


## Frost creeping out from the centre: branching crystals revealed as
## `radius` grows.
class Frost extends Node2D:
	var reach := 1100.0
	var color := Color(0.78, 0.94, 1.0)
	var radius := 0.0:
		set(value):
			radius = value
			queue_redraw()
	var _segments: Array = []

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 41
		for b in 34:
			var angle := b * TAU / 34.0 + rng.randf_range(-0.08, 0.08)
			var p := Vector2.from_angle(angle) * rng.randf_range(20.0, 60.0)
			while p.length() < reach:
				angle += rng.randf_range(-0.22, 0.22)
				var q := p + Vector2.from_angle(angle) * rng.randf_range(14.0, 24.0)
				_segments.append([p, q, q.length(), 1.6])
				if rng.randf() < 0.3:
					var side := angle + (0.8 if rng.randf() < 0.5 else -0.8)
					var t := q
					for k in 3:
						var u := t + Vector2.from_angle(side + rng.randf_range(-0.2, 0.2)) * rng.randf_range(8.0, 13.0)
						_segments.append([t, u, u.length(), 1.0])
						t = u
				p = q

	func _draw() -> void:
		if radius <= 0.0:
			return
		draw_circle(Vector2.ZERO, radius, Color(color, 0.05))
		for s in _segments:
			var d: float = s[2]
			if d > radius:
				continue
			var a := clampf((radius - d) / 80.0, 0.0, 1.0)
			draw_line(s[0], s[1], Color(color, 0.75 * a), s[3], true)


## Rings of sound spreading from a point (call ring() for each toll).
class Rings extends Node2D:
	var speed := 260.0
	var life := 2.6
	var color := Color(1.0, 0.86, 0.6)
	var _rings: Array = []

	func ring() -> void:
		_rings.append(0.0)

	func _process(delta: float) -> void:
		for i in range(_rings.size() - 1, -1, -1):
			_rings[i] += delta
			if _rings[i] > life:
				_rings.remove_at(i)
		queue_redraw()

	func _draw() -> void:
		for age in _rings:
			var a: float = 1.0 - age / life
			for k in 3:
				var r: float = age * speed - k * 18.0
				if r > 4.0:
					draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Color(color, 0.35 * a * (1.0 - k * 0.3)), 2.0, true)


## A bat or a crow crossing the sky: it flaps (the pack's wing frames) along
## a gently bobbing line from `from` to `to`, waits, and crosses again.
class Flyer extends AnimatedSprite2D:
	var from := Vector2.ZERO
	var to := Vector2(400, 0)
	var seconds := 8.0
	var wait := 6.0
	var bob := 5.0
	var delay := 0.0
	var _t := 0.0

	func setup(frame_names: Array, fps: float) -> void:
		sprite_frames = SurfaceArt.frames(frame_names, fps)
		play(&"default")

	func _process(delta: float) -> void:
		if delay > 0.0:
			delay -= delta
			visible = false
			return
		visible = true
		_t += delta / seconds
		position = (from.lerp(to, _t) + Vector2(0, sin(_t * TAU * 3.0) * bob)).round()
		if _t >= 1.0:
			_t = 0.0
			delay = wait


## Leaves blown across by the wind: the pack's leaf sprites tumbling from
## left to right through `area` (in this node's units), wrapping round.
class Leaves extends Node2D:
	var area := Rect2(0, 0, 400, 80)
	var count := 6
	var speed := 50.0
	var seed_value := 3
	var _leaves: Array = []
	var _time := 0.0

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for i in count:
			var s := Sprite2D.new()
			s.texture = SurfaceArt.tex(["leaf_a", "leaf_b", "leaf_c"][i % 3])
			add_child(s)
			_leaves.append({"s": s, "x": rng.randf_range(area.position.x, area.end.x),
				"y": rng.randf_range(area.position.y, area.end.y), "v": speed * rng.randf_range(0.7, 1.4),
				"ph": rng.randf() * TAU, "spin": rng.randf_range(2.0, 5.0)})

	func _process(delta: float) -> void:
		_time += delta
		for leaf in _leaves:
			leaf["x"] += leaf["v"] * delta
			if leaf["x"] > area.end.x:
				leaf["x"] = area.position.x
			var s: Sprite2D = leaf["s"]
			s.position = Vector2(leaf["x"], leaf["y"] + sin(_time * 2.2 + leaf["ph"]) * 5.0).round()
			s.rotation = _time * leaf["spin"] + leaf["ph"]


## Tufts of the pack's grass along a line (feet at `y`), each swaying a
## little in its own time; `wind` leans them all.
class Tufts extends Node2D:
	var x0 := 0.0
	var x1 := 400.0
	var y := 0.0
	var gap := Vector2(10.0, 26.0)
	var flowers := 0.15
	var wind := 0.0
	var seed_value := 5
	var skip: Array = []
	var _tufts: Array = []
	var _time := 0.0

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var x := x0
		while x < x1:
			var blocked := false
			for r in skip:
				if x > r.x and x < r.y:
					blocked = true
			if not blocked:
				var kind := "grass_%d" % (rng.randi() % 9 + 1)
				if rng.randf() < flowers:
					kind = ["flower_small", "flowers", "flowers_big"][rng.randi() % 3]
				var s := Sprite2D.new()
				s.texture = SurfaceArt.tex(kind)
				s.centered = false
				s.offset = Vector2(-floorf(s.texture.get_width() / 2.0), -s.texture.get_height())
				s.position = Vector2(round(x), y)
				s.flip_h = rng.randf() < 0.5
				add_child(s)
				_tufts.append([s, rng.randf() * TAU, rng.randf_range(1.2, 2.2)])
			x += rng.randf_range(gap.x, gap.y)

	func _process(delta: float) -> void:
		_time += delta
		for t in _tufts:
			t[0].skew = (sin(_time * t[2] + t[1]) * 0.08 + wind) * -1.0
