class_name DialogueBox
extends CanvasLayer

## A conversation told the Persona way: the speaker's large portrait
## (tools/generate_portraits.gd, shown 3x) slides in on their side of the
## screen and whoever they are talking to dims on the other; a gold name
## plate; the words type out in a dungeon panel along the bottom, in the
## story face, with glyph gaps where a forgotten name should be (write {n}
## for n missing glyphs, as SpeechBubble does). Thoughts are shown in
## brackets, dimmer.
##
## say() shows a line and returns at once; await say_and_wait() to wait for
## the player. With `handles_input` the box takes the presses itself (the
## first finishes the typing, the next moves on); a host with its own
## press handling turns that off and calls finish_typing().

signal typed
signal advanced

const ART := "res://assets/sprites/story/portrait_%s.png"
const ART_SIZE := Vector2(112, 136)
const SCALE := 2.0
## Each portrait strip's frames, in order (as the generator draws them).
const FACES := {
	"echidna": ["neutral", "worried", "determined", "sad", "surprised"],
	"nan": ["warm", "lost", "sad", "bright"],
	"wren": ["calm", "smile", "pleading", "scared"],
	"ilse": ["pleading", "grief", "peace"],
}
const NAMES := {"echidna": "Echidna", "nan": "Nan", "wren": "Wren", "ilse": "Ilse"}
## Where each speaker stands: Echidna on the left, whoever she talks to on
## the right.
const SIDES := {"echidna": "left", "nan": "right", "wren": "right", "ilse": "right"}
const CHARS_PER_SECOND := 48.0
const BOX_H := 152.0
const FONT_SIZE := 26

var handles_input := true
## The line showing now.
var text := ""
var speaker := ""
var face := ""
var thought := false
var is_typing := false
var showing := false

var _root: Control
var _shade: TextureRect
var _portraits := {}
var _who_on := {"left": "", "right": ""}
var _box: PanelContainer
var _plate: PanelContainer
var _plate_label: Label
var _words: GapText
var _arrow: Control
var _time := 0.0
var _cooldown := 0.0
static var _textures := {}


func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	_root.visible = false


## The portrait of `who` with expression `face_name`.
static func portrait(who: String, face_name: String) -> Texture2D:
	var key := who + ":" + face_name
	if _textures.has(key):
		return _textures[key]
	if not FACES.has(who):
		return null
	var strip: Texture2D = load(ART % who)
	var at := maxi(FACES[who].find(face_name), 0)
	var atlas := AtlasTexture.new()
	atlas.atlas = strip
	atlas.region = Rect2(at * ART_SIZE.x, 0, ART_SIZE.x, ART_SIZE.y)
	_textures[key] = atlas
	return atlas


## Shows a line (and returns at once).
func say(who: String, face_name: String, line_text: String, as_thought := false) -> void:
	speaker = who
	face = face_name
	text = line_text
	thought = as_thought
	if not showing:
		_open()
	_show_portrait(who, face_name)
	_plate_label.text = NAMES.get(who, who.capitalize())
	var left := String(SIDES.get(who, "right")) == "left"
	_plate.set_anchors_preset(Control.PRESET_BOTTOM_LEFT if left else Control.PRESET_BOTTOM_RIGHT)
	_plate.grow_horizontal = Control.GROW_DIRECTION_END if left else Control.GROW_DIRECTION_BEGIN
	_plate.offset_left = 70.0 if left else -70.0
	_plate.offset_right = 70.0 if left else -70.0
	_plate.offset_top = -BOX_H - 34.0
	_plate.offset_bottom = -BOX_H - 34.0
	_words.thought = as_thought
	_words.text = "(%s)" % line_text if as_thought else line_text
	_words.shown = 0.0
	is_typing = true
	_arrow.visible = false
	_cooldown = 0.2


## Shows a line and waits for the player to move on.
func say_and_wait(who: String, face_name: String, line_text: String, as_thought := false) -> void:
	say(who, face_name, line_text, as_thought)
	await advanced


func finish_typing() -> void:
	if is_typing:
		_words.shown = float(_words.char_count())
		_done_typing()


## How many glyph gaps (forgotten words) the line has.
func gap_count() -> int:
	return _words.gap_count()


func close() -> void:
	if not showing:
		return
	showing = false
	is_typing = false
	var t := create_tween().set_parallel()
	t.tween_property(_root, "modulate:a", 0.0, 0.25)
	for side in _portraits:
		t.tween_property(_portraits[side], "position:x", _rest_x(side) + (-80.0 if side == "left" else 80.0), 0.25)
	t.chain().tween_callback(func():
		if not showing:
			_root.visible = false
			_who_on = {"left": "", "right": ""})


func _open() -> void:
	showing = true
	_root.visible = true
	_root.modulate.a = 0.0
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.2)
	for side in _portraits:
		_portraits[side].modulate.a = 0.0


func _show_portrait(who: String, face_name: String) -> void:
	var side := String(SIDES.get(who, "right"))
	var other := "right" if side == "left" else "left"
	var p: TextureRect = _portraits[side]
	var tex := portrait(who, face_name)
	var arriving: bool = _who_on[side] != who
	p.texture = tex
	p.flip_h = side == "right"
	_who_on[side] = who
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if arriving:
		p.position.x = _rest_x(side) + (-60.0 if side == "left" else 60.0)
		p.modulate = Color(1, 1, 1, 0)
	t.tween_property(p, "position:x", _rest_x(side), 0.25)
	t.tween_property(p, "modulate", Color.WHITE, 0.2)
	t.tween_property(p, "scale", Vector2.ONE, 0.2)
	# the listener steps back into the dark
	var q: TextureRect = _portraits[other]
	if _who_on[other] != "":
		t.tween_property(q, "modulate", Color(0.42, 0.4, 0.5, 1.0), 0.2)
		t.tween_property(q, "scale", Vector2.ONE * 0.96, 0.2)


func _rest_x(side: String) -> float:
	var view := get_viewport().get_visible_rect().size
	var w := ART_SIZE.x * SCALE
	return 36.0 if side == "left" else view.x - w - 36.0


func _done_typing() -> void:
	is_typing = false
	_arrow.visible = true
	typed.emit()


func _process(delta: float) -> void:
	if not showing:
		return
	_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	if is_typing:
		var before := int(_words.shown)
		_words.shown = minf(_words.shown + delta * CHARS_PER_SECOND, float(_words.char_count()))
		if int(_words.shown) / 3 != before / 3:
			Sfx.play("echo_tick", null, -24.0, 0.15)
		if _words.shown >= _words.char_count():
			_done_typing()
	_arrow.offset_top = -56.0 + sin(_time * 5.0) * 2.0
	_arrow.offset_bottom = _arrow.offset_top + 18.0
	for side in _portraits:
		var p: TextureRect = _portraits[side]
		if _who_on[side] == speaker and p.texture:
			# a slow breath
			p.position.y = _portrait_y() + sin(_time * 1.6) * 1.5


func _portrait_y() -> float:
	var view := get_viewport().get_visible_rect().size
	return view.y - BOX_H - 18.0 + 64.0 - ART_SIZE.y * SCALE


func _unhandled_input(event: InputEvent) -> void:
	if not handles_input or not showing or _cooldown > 0.0:
		return
	var press: bool = event.is_action_pressed("interact") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not press:
		return
	get_viewport().set_input_as_handled()
	if is_typing:
		finish_typing()
	else:
		_cooldown = 0.15
		advanced.emit()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	# a darkening toward the bottom, so the words and faces stand out
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0.01, 0.005, 0.02, 0.7))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	_shade = TextureRect.new()
	_shade.texture = gt
	_shade.stretch_mode = TextureRect.STRETCH_SCALE
	_shade.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_shade.offset_top = -BOX_H - 260.0
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_shade)
	for side in ["left", "right"]:
		var p := TextureRect.new()
		p.name = "Portrait" + side.capitalize()
		p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		p.size = ART_SIZE * SCALE
		p.pivot_offset = Vector2(ART_SIZE.x * SCALE / 2.0, ART_SIZE.y * SCALE)
		p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.position = Vector2(0, 0)
		_root.add_child(p)
		_portraits[side] = p
	_box = PanelContainer.new()
	_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_left = 28
	_box.offset_right = -28
	_box.offset_top = -BOX_H - 18.0
	_box.offset_bottom = -18
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_box)
	DungeonUI.decorate(_box)
	_words = GapText.new()
	_words.font_size = FONT_SIZE
	_box.add_child(_words)
	_plate = DungeonUI.nameplate("")
	_plate_label = _plate.get_child(0)
	_root.add_child(_plate)
	# a small gold triangle, bobbing, when the line is done
	_arrow = Control.new()
	_arrow.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_arrow.offset_left = -68
	_arrow.offset_right = -52
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.draw.connect(func():
		_arrow.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(16, 0), Vector2(8, 10)]), DungeonUI.SHADOW)
		_arrow.draw_colored_polygon(PackedVector2Array([Vector2(2, 1), Vector2(14, 1), Vector2(8, 8)]), DungeonUI.GOLD))
	_root.add_child(_arrow)
	get_viewport().size_changed.connect(_place)
	_place()


func _place() -> void:
	for side in _portraits:
		var p: TextureRect = _portraits[side]
		p.position = Vector2(_rest_x(side), _portrait_y())


## Words laid out and typed out, with glyph gaps for {n} (forgotten words).
class GapText extends Control:
	var font_size := 22
	var thought := false
	var shown := 0.0:
		set(value):
			shown = value
			queue_redraw()
	var text := "":
		set(value):
			text = value
			_tokens = _tokenise(value)
			queue_redraw()
	var _tokens: Array = []
	const GLYPH := 20.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL

	func gap_count() -> int:
		var n := 0
		for t in _tokens:
			n += 1 if t["gap"] > 0 else 0
		return n

	func char_count() -> int:
		var n := 0
		for t in _tokens:
			n += t["gap"] if t["gap"] > 0 else t["word"].length() + 1
		return n

	func _tokenise(s: String) -> Array:
		var out: Array = []
		for word in s.split(" ", false):
			var gap := 0
			var tail := ""
			var at := word.find("{")
			var close := word.find("}")
			if at >= 0 and close > at:
				gap = int(word.substr(at + 1, close - at - 1))
				tail = word.substr(close + 1)
				if at > 0:
					out.append({"word": word.substr(0, at), "gap": 0, "tail": ""})
			out.append({"word": word if gap == 0 else "", "gap": gap, "tail": tail})
		return out

	func _draw() -> void:
		var font: Font = Fonts.STORY
		var ink := Color("b9ab90") if thought else DungeonUI.INK
		var space := font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var line_h := font_size * 1.35
		var x := 0.0
		var y := font_size * 1.0
		var budget := shown
		for t in _tokens:
			var w: float = (t["gap"] * GLYPH + 8.0 + font.get_string_size(t["tail"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) \
				if t["gap"] > 0 else font.get_string_size(t["word"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			if x > 0.0 and x + w > size.x:
				x = 0.0
				y += line_h
			if budget <= 0.0:
				return
			if t["gap"] > 0:
				var n: int = t["gap"]
				var box := Rect2(x, y - font_size * 0.85, n * GLYPH + 6.0, font_size * 1.05)
				draw_rect(box, Color(0.42, 0.1, 0.14, 0.35))
				var ids := RuneFragments.ALL.keys()
				for g in mini(n, int(budget)):
					var id: StringName = ids[absi(hash(text) + g * 7) % ids.size()]
					RuneFragments.draw_glyph(self, id, Vector2(x + 3.0 + GLYPH * (g + 0.5), box.get_center().y), GLYPH * 0.7,
						Color(0.86, 0.7, 0.42, 0.85), 1.5)
				budget -= n
				if budget > 0.0:
					var tail: String = t["tail"].substr(0, int(budget))
					draw_string(font, Vector2(x + n * GLYPH + 8.0, y), tail, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
					budget -= t["tail"].length()
			else:
				var word: String = t["word"]
				draw_string(font, Vector2(x, y), word.substr(0, int(budget)), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
				budget -= word.length() + 1
			x += w + space
