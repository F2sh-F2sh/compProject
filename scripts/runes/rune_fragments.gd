class_name RuneFragments
extends RefCounted

## The rune language's vocabulary: every fragment a player can learn, keyed
## by a stable id. A complete rune has one fragment of each KIND, arranged
## as a 2x2 composite: essence (top-left), form (top-right), direction
## (bottom-left), modifier (bottom-right). Gameplay never parses the names
## or the glyphs; it only uses these ids (see RuneBook for what they do).

enum Kind { ESSENCE, FORM, DIRECTION, MODIFIER }

const KIND_NAMES := ["Essence", "Form", "Direction", "Modifier"]

## id: [kind, display name, one-line meaning]
const ALL := {
	# Essences
	&"wind": [Kind.ESSENCE, "Wind", "moving air: pushes and lifts"],
	&"fire": [Kind.ESSENCE, "Fire", "heat: ignites, burns, melts"],
	&"ice": [Kind.ESSENCE, "Ice", "cold: freezes and builds"],
	&"light": [Kind.ESSENCE, "Light", "holy light: powers crystals, stills watchers"],
	&"space": [Kind.ESSENCE, "Space", "folds distance: portals"],
	# Forms
	&"push": [Kind.FORM, "Push", "a steady current"],
	&"lift": [Kind.FORM, "Lift", "a steady updraft"],
	&"burst": [Kind.FORM, "Burst", "a single gust"],
	&"projectile": [Kind.FORM, "Projectile", "a flying bolt"],
	&"freeze": [Kind.FORM, "Freeze", "a numbing chill"],
	&"bridge": [Kind.FORM, "Bridge", "a span of solid ice"],
	&"beam": [Kind.FORM, "Beam", "a straight ray"],
	&"glow": [Kind.FORM, "Glow", "a pool of light"],
	&"portal": [Kind.FORM, "Portal", "a door to somewhere near"],
	# Directions
	&"right": [Kind.DIRECTION, "Right", "toward the right"],
	&"left": [Kind.DIRECTION, "Left", "toward the left"],
	&"up": [Kind.DIRECTION, "Up", "upward"],
	&"down": [Kind.DIRECTION, "Down", "downward"],
	&"up_right": [Kind.DIRECTION, "Up-Right", "up and to the right"],
	&"up_left": [Kind.DIRECTION, "Up-Left", "up and to the left"],
	&"down_right": [Kind.DIRECTION, "Down-Right", "down and to the right"],
	&"down_left": [Kind.DIRECTION, "Down-Left", "down and to the left"],
	&"self": [Kind.DIRECTION, "Self", "around the cube itself"],
	# Modifiers
	&"normal": [Kind.MODIFIER, "Normal", "as it is"],
	&"strong": [Kind.MODIFIER, "Strong", "twice the force"],
	&"long": [Kind.MODIFIER, "Long", "reaches much further"],
	&"large": [Kind.MODIFIER, "Large", "covers a far wider area"],
	&"persist": [Kind.MODIFIER, "Persist", "held for as long as the cube is on"],
	&"delay": [Kind.MODIFIER, "Delay", "happens two seconds later"],
	&"repeat": [Kind.MODIFIER, "Repeat", "happens again and again"],
	&"bounce": [Kind.MODIFIER, "Bounce", "reflects from mirrors"],
	&"split": [Kind.MODIFIER, "Split", "splits into three"],
	&"explode": [Kind.MODIFIER, "Explode", "bursts where it lands"],
}

## Colour per essence (always paired with its own symbol, never alone).
const ESSENCE_COLORS := {
	&"wind": Color(0.72, 0.9, 1.0),
	&"fire": Color(1.0, 0.6, 0.3),
	&"ice": Color(0.6, 0.85, 1.0),
	&"light": Color(1.0, 0.9, 0.55),
	&"space": Color(0.78, 0.6, 1.0),
}
const NEUTRAL := Color(0.8, 0.74, 0.95)

const DIRECTION_VECTORS := {
	&"right": Vector2(1, 0), &"left": Vector2(-1, 0), &"up": Vector2(0, -1), &"down": Vector2(0, 1),
	&"up_right": Vector2(1, -1), &"up_left": Vector2(-1, -1),
	&"down_right": Vector2(1, 1), &"down_left": Vector2(-1, 1),
	&"self": Vector2.ZERO,
}


static func kind_of(id: StringName) -> int:
	return ALL[id][0] if ALL.has(id) else -1


static func name_of(id: StringName) -> String:
	return ALL[id][1] if ALL.has(id) else "—"


static func meaning_of(id: StringName) -> String:
	return ALL[id][2] if ALL.has(id) else ""


## Every fragment of a kind, in a stable order.
static func of_kind(kind: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in ALL:
		if ALL[id][0] == kind:
			out.append(id)
	return out


## Unit vector for a direction fragment (zero for Self).
static func direction_vector(id: StringName) -> Vector2:
	return DIRECTION_VECTORS.get(id, Vector2.ZERO).normalized()


static func essence_color(id: StringName) -> Color:
	return ESSENCE_COLORS.get(id, NEUTRAL)


## Draws a fragment's glyph centred at `c` in a cell of `size` px, with
## simple strokes that stay readable at 8 px and at 48 px.
static func draw_glyph(canvas: CanvasItem, id: StringName, c: Vector2, size: float, color: Color, width := 1.0) -> void:
	var s := size * 0.5
	match id:
		&"wind":
			for i in 3:
				var y := c.y + (i - 1) * s * 0.55
				var pts := PackedVector2Array()
				for k in 7:
					var t := k / 6.0
					pts.append(Vector2(c.x - s * 0.8 + t * s * 1.6, y + sin(t * TAU + i) * s * 0.18))
				canvas.draw_polyline(pts, color, width)
		&"fire":
			var flame := PackedVector2Array([c + Vector2(0, -s * 0.9), c + Vector2(s * 0.5, -s * 0.1), c + Vector2(s * 0.45, s * 0.45),
				c + Vector2(0, s * 0.8), c + Vector2(-s * 0.45, s * 0.45), c + Vector2(-s * 0.5, -s * 0.1), c + Vector2(0, -s * 0.9)])
			canvas.draw_polyline(flame, color, width)
			canvas.draw_line(c + Vector2(0, s * 0.1), c + Vector2(0, s * 0.5), color, width)
		&"ice":
			for i in 3:
				var a := i * PI / 3.0
				canvas.draw_line(c - Vector2(cos(a), sin(a)) * s * 0.8, c + Vector2(cos(a), sin(a)) * s * 0.8, color, width)
		&"light":
			canvas.draw_arc(c, s * 0.35, 0.0, TAU, 12, color, width)
			for i in 8:
				var a := i * PI / 4.0
				canvas.draw_line(c + Vector2(cos(a), sin(a)) * s * 0.55, c + Vector2(cos(a), sin(a)) * s * 0.85, color, width)
		&"space":
			canvas.draw_arc(c, s * 0.8, 0.0, TAU, 16, color, width)
			canvas.draw_arc(c, s * 0.4, PI * 0.5, PI * 2.2, 10, color, width)
			canvas.draw_circle(c, maxf(width, 1.0), color)
		&"push":
			for i in 2:
				var x := c.x - s * 0.5 + i * s * 0.55
				canvas.draw_polyline(PackedVector2Array([Vector2(x, c.y - s * 0.6), Vector2(x + s * 0.45, c.y), Vector2(x, c.y + s * 0.6)]), color, width)
		&"lift":
			canvas.draw_line(c + Vector2(-s * 0.7, s * 0.75), c + Vector2(s * 0.7, s * 0.75), color, width)
			canvas.draw_line(c + Vector2(0, s * 0.5), c + Vector2(0, -s * 0.8), color, width)
			canvas.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.45, -s * 0.35), c + Vector2(0, -s * 0.8), c + Vector2(s * 0.45, -s * 0.35)]), color, width)
		&"burst":
			for i in 8:
				var a := i * PI / 4.0
				canvas.draw_line(c + Vector2(cos(a), sin(a)) * s * 0.25, c + Vector2(cos(a), sin(a)) * s * (0.85 if i % 2 == 0 else 0.6), color, width)
		&"projectile":
			canvas.draw_circle(c + Vector2(s * 0.35, 0), s * 0.28, color)
			canvas.draw_line(c + Vector2(-s * 0.8, 0), c + Vector2(s * 0.1, 0), color, width)
			canvas.draw_line(c + Vector2(-s * 0.6, -s * 0.3), c + Vector2(0, -s * 0.12), color, width)
			canvas.draw_line(c + Vector2(-s * 0.6, s * 0.3), c + Vector2(0, s * 0.12), color, width)
		&"freeze":
			var hexagon := PackedVector2Array()
			for i in 7:
				var a := i * PI / 3.0 + PI / 6.0
				hexagon.append(c + Vector2(cos(a), sin(a)) * s * 0.75)
			canvas.draw_polyline(hexagon, color, width)
			canvas.draw_circle(c, maxf(width, 1.0) * 1.2, color)
		&"bridge":
			canvas.draw_line(c + Vector2(-s * 0.85, -s * 0.15), c + Vector2(s * 0.85, -s * 0.15), color, width * 2.0)
			canvas.draw_line(c + Vector2(-s * 0.6, -s * 0.15), c + Vector2(-s * 0.6, s * 0.7), color, width)
			canvas.draw_line(c + Vector2(s * 0.6, -s * 0.15), c + Vector2(s * 0.6, s * 0.7), color, width)
		&"beam":
			canvas.draw_circle(c + Vector2(-s * 0.65, 0), s * 0.22, color)
			canvas.draw_line(c + Vector2(-s * 0.4, 0), c + Vector2(s * 0.85, 0), color, width)
			canvas.draw_line(c + Vector2(-s * 0.2, -s * 0.3), c + Vector2(s * 0.85, -s * 0.3), color, maxf(width * 0.5, 1.0))
		&"glow":
			canvas.draw_circle(c, s * 0.3, color)
			canvas.draw_arc(c, s * 0.7, 0.0, TAU, 16, color, width)
		&"portal":
			canvas.draw_arc(c + Vector2(-s * 0.35, 0), s * 0.4, 0.0, TAU, 12, color, width)
			canvas.draw_arc(c + Vector2(s * 0.35, 0), s * 0.4, 0.0, TAU, 12, color, width)
		&"self":
			canvas.draw_arc(c, s * 0.7, 0.0, TAU, 16, color, width)
			canvas.draw_circle(c, s * 0.18, color)
		&"normal":
			canvas.draw_circle(c, s * 0.2, color)
		&"strong":
			canvas.draw_line(c + Vector2(-s * 0.3, -s * 0.7), c + Vector2(-s * 0.3, s * 0.7), color, width * 2.0)
			canvas.draw_line(c + Vector2(s * 0.3, -s * 0.7), c + Vector2(s * 0.3, s * 0.7), color, width * 2.0)
		&"long":
			canvas.draw_line(c + Vector2(-s * 0.85, 0), c + Vector2(s * 0.85, 0), color, width)
			canvas.draw_line(c + Vector2(-s * 0.85, -s * 0.35), c + Vector2(-s * 0.85, s * 0.35), color, width)
			canvas.draw_line(c + Vector2(s * 0.85, -s * 0.35), c + Vector2(s * 0.85, s * 0.35), color, width)
		&"large":
			canvas.draw_rect(Rect2(c - Vector2(s, s) * 0.7, Vector2(s, s) * 1.4), color, false, width)
			canvas.draw_rect(Rect2(c - Vector2(s, s) * 0.3, Vector2(s, s) * 0.6), color, false, width)
		&"persist":
			var loop := PackedVector2Array()
			for k in 25:
				var t := k / 24.0 * TAU
				loop.append(c + Vector2(sin(t) * s * 0.8, sin(t * 2.0) * s * 0.35))
			canvas.draw_polyline(loop, color, width)
		&"delay":
			canvas.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.5, -s * 0.75), c + Vector2(s * 0.5, -s * 0.75),
				c + Vector2(-s * 0.5, s * 0.75), c + Vector2(s * 0.5, s * 0.75), c + Vector2(-s * 0.5, -s * 0.75)]), color, width)
		&"repeat":
			canvas.draw_arc(c, s * 0.6, 0.3, TAU - 0.6, 14, color, width)
			var tip := c + Vector2(cos(-0.3), sin(-0.3)) * s * 0.6
			canvas.draw_line(tip, tip + Vector2(-s * 0.3, -s * 0.1), color, width)
			canvas.draw_line(tip, tip + Vector2(0, -s * 0.35), color, width)
		&"bounce":
			canvas.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.85, s * 0.5), c + Vector2(-s * 0.3, -s * 0.5),
				c + Vector2(s * 0.25, s * 0.5), c + Vector2(s * 0.85, -s * 0.5)]), color, width)
		&"split":
			canvas.draw_line(c + Vector2(-s * 0.8, 0), c + Vector2(0, 0), color, width)
			canvas.draw_line(c, c + Vector2(s * 0.8, -s * 0.6), color, width)
			canvas.draw_line(c, c + Vector2(s * 0.8, 0), color, width)
			canvas.draw_line(c, c + Vector2(s * 0.8, s * 0.6), color, width)
		&"explode":
			for i in 5:
				var a := i * TAU / 5.0 - PI / 2.0
				canvas.draw_line(c, c + Vector2(cos(a), sin(a)) * s * 0.85, color, width)
			canvas.draw_circle(c, s * 0.2, color)
		_:
			var d := direction_vector(id)
			if d != Vector2.ZERO:
				var tip := c + d * s * 0.8
				canvas.draw_line(c - d * s * 0.7, tip, color, width)
				var side := d.orthogonal()
				canvas.draw_line(tip, tip - d * s * 0.45 + side * s * 0.35, color, width)
				canvas.draw_line(tip, tip - d * s * 0.45 - side * s * 0.35, color, width)
			else:
				# An empty (broken) quadrant: a small crack
				canvas.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.4, -s * 0.5), c + Vector2(0, -s * 0.1),
					c + Vector2(-s * 0.15, s * 0.2), c + Vector2(s * 0.3, s * 0.55)]), Color(color, 0.5), width)
