class_name StoryIntro
extends Node2D

## The story before the game, and the base of every story reel after it
## (StoryInterlude): eight shots staged the way Hollow Knight stages its
## cutscenes (StoryStage: depth layers drifting as the camera pushes in,
## near rock in silhouette, fog, one glowing focus, a colour grade and a
## letterbox), built from the surface and town packs and the story's pixel
## sprites (SurfaceArt). A few lines of plain words go in the bottom bar;
## some shots are silent, and lore cards put words alone on black. The
## story's four notes play where they belong (AudioDirector.play_cue).
## Space, Enter or a click moves on; holding Esc skips to the village.
## When the last picture fades, Lowbell begins.

const LOWBELL := "res://scenes/story/lowbell.tscn"
const SIZE := Vector2(1152, 648)
const NARRATION_FONTS := ["Palatino Linotype", "Book Antiqua", "Georgia", "Cambria", "Times New Roman", "serif"]
const HUSH_SHADER := preload("res://assets/shaders/story_hush.gdshader")
const ECHIDNA := preload("res://assets/sprites/Echidna/echidna_frames.tres")
## The pack sky's darkest blue, above the painting.
const SKY_TOP := SurfaceArt.SKY_TOP
const SKIP_HOLD := 0.9
const FADE := 0.7
const GRADE_SHADER := preload("res://assets/shaders/story_grade.gdshader")
## The letterbox: a black bar this tall above and below every shot.
const BAR := 74.0
## The colour grade a shot gets unless it asks for its own ("grade").
const GRADE := {"shadow": Color(0.02, 0.03, 0.07), "light": Color(1.0, 1.0, 1.0), "saturation": 0.85,
	"contrast": 1.06, "vignette": 0.6}

## Each picture is a dictionary: "lines" (the words, one at a time; "" for a
## silent beat), "build" (a Callable that stages it on a Node2D), "era" (when
## it happens, small above), "zoom" [from, to] and "from"/"to" (the camera's
## slow push), "min" (seconds each line needs at least), "hold" (seconds
## before the push starts), "grade" (overrides of GRADE), "music" (a story
## cue to start, e.g. "lullaby.wav"), and "card" (true: a lore card, the
## words centred on black between ornaments, as Hollow Knight tells its lore).
var pictures: Array = []
var index := -1
var line := 0
var finished := false

var _picture: Node2D
var _camera: Camera2D
var _fade: ColorRect
## The words now: the caption in the bottom bar, or a lore card's text.
var _caption: Label
var _bar_caption: Label
var _card_caption: Label
var _bars: Array = []
var _grade: ShaderMaterial
## The portrait of whoever is speaking (DialogueBox art), and their name.
var _speaker_art: TextureRect
var _speaker_plate: PanelContainer
var _speaker_who := ""
## When the picture happens ("LONG AGO", "TODAY"), small above the words.
var _era: Label
var _next_hint: Label
var _skip_hint: Label
var _skip_bar: ColorRect
var _skip_time := 0.0
var _line_time := 0.0
var _line_length := 0.0
var _changing := true
var _caption_tween: Tween
## Movements a picture saves for a later line (line number -> Callable), so
## the picture acts out what the words are saying.
var _cues := {}

## The card shown after the pictures, if any (for tests).
var results_card: ChapterComplete


func _ready() -> void:
	# Animated every drawn frame (tweens, drifting pictures): drawn as it is
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_tree().paused = false
	Crosshair.arrow()
	AudioDirector.fade_ambience(-40.0, 1.5)
	# Told plainly, one idea per line: what runes are, what went wrong, why
	# the bell matters, and what Echidna has to do. The small label above
	# the words says when each picture happens.
	pictures = _make_pictures()
	_camera = Camera2D.new()
	_camera.position = SIZE / 2.0
	add_child(_camera)
	_camera.make_current()
	_build_ui()
	_show_picture(0)


## The pictures and their lines. (An interlude overrides this.)
func _make_pictures() -> Array:
	var cold := {"shadow": Color(0.02, 0.03, 0.08), "saturation": 0.8, "vignette": 0.65}
	var candle := {"light": Color(1.04, 0.97, 0.9), "saturation": 0.9, "vignette": 0.62}
	return [
		{"era": "LONG AGO", "lines": ["Long ago, monks called the Choir lived on this mountain and read the night sky.",
				"They found that the stars are words. Four of them together make a spell, and the world does what it says."],
			"build": _choir_reads, "grade": cold, "zoom": [1.08, 1.0], "from": Vector2(0, -50), "to": Vector2(0, 10), "min": [4.8, 6.6]},
		{"era": "LONG AGO", "lines": ["They carved their spells into stone cubes. When all four words light up, the spell comes true."],
			"build": _choir_cube, "zoom": [1.0, 1.08], "from": Vector2(0, 10), "to": Vector2(0, 30), "min": [6.4]},
		{"era": "SIXTY YEARS AGO", "lines": ["Sixty years ago, the Choir's leader, Ilse, sat up every night with her daughter, Wren.",
				"Wren was very ill. Every night Ilse sang her the same four notes, and every night Wren asked her:",
				{"who": "wren", "face": "calm", "text": "Will you be here when I wake up?"}],
			"build": _ilse_sings, "grade": candle, "music": "lullaby.wav", "music_db": -5.0,
			"zoom": [1.0, 1.08], "from": Vector2(20, 0), "to": Vector2(-20, 10), "min": [5.0, 6.2, 4.8]},
		{"era": "SIXTY YEARS AGO", "lines": ["So that the morning would never come, Ilse wrote a sentence on the great cube: ICE · FREEZE · SELF · PERSIST.",
				"The night stopped. The snow stopped in the air. Wren did not die. But she never woke, either."],
			"build": _ilse_writes, "grade": cold, "zoom": [1.0, 1.12], "from": Vector2.ZERO, "to": Vector2.ZERO, "min": [5.6, 6.6]},
		{"era": "SIXTY YEARS AGO", "lines": ["The spell grew into something vast, and it ate the sky's words to keep that one night held.",
				"Stars went out. Names were forgotten. People called it the Hush."],
			"build": _the_moth_unfolds, "grade": cold, "zoom": [1.0, 1.06], "from": Vector2(0, 30), "to": Vector2(0, -20), "min": [6.4, 5.8]},
		{"era": "FOR SIXTY YEARS", "lines": ["Then the monks found that their great bell rang the same four notes as Ilse's song.",
				"While it rang, the spell went quiet and the Hush drew back. So they rang it every day, for sixty years."],
			"build": _the_bell_sings, "grade": cold, "music": "bell_peal.wav", "music_db": -4.0,
			"zoom": [1.05, 1.0], "from": Vector2(0, -20), "to": Vector2.ZERO, "min": [5.6, 6.6]},
		{"era": "NINE YEARS AGO", "lines": ["Nine years ago, the bell cracked. The last monks sealed the bell tower and left the mountain."],
			"build": _the_crack, "grade": cold, "zoom": [1.8, 1.0], "from": Vector2(-60, 30), "to": Vector2.ZERO, "hold": 2.4, "min": [10.0]},
		{"era": "TODAY", "lines": ["Now the Hush has reached the village of Lowbell. The stars are going out, and people are forgetting words, even each other's names.",
				"Someone has to climb to the sealed Belfry and ring the bell again. But the road up the mountain has been frozen shut for nine winters.",
				"The one to go is a young witch named Echidna. The Hush has already taken some of her spells, and her Nan has begun to forget her name."],
			"build": _lowbell_today, "grade": cold, "zoom": [1.0, 1.06], "from": Vector2(0, -20), "to": Vector2(-20, 16), "min": [6.4, 6.4, 5.6]},
	]


## Where the pictures lead when they are over: out onto the surface, to
## Lowbell's lane and Nan's cottage, then the pilgrim road to the abbey.
func _next_scene() -> String:
	return Journey.LOWBELL


func _exit_tree() -> void:
	AudioDirector.fade_ambience(AudioDirector.AMBIENCE_DB, 1.5)
	AudioDirector.stop_cue(2.0)


# ------------------------------------------------------------------ flow

func _show_picture(i: int) -> void:
	_hide_speaker()
	_changing = true
	index = i
	line = 0
	if is_instance_valid(_picture):
		_picture.queue_free()
	_picture = Node2D.new()
	_picture.name = "Picture%d" % (i + 1)
	add_child(_picture)
	move_child(_picture, 0)
	var spec: Dictionary = pictures[i]
	_cues = {}
	var card: bool = spec.get("card", false)
	_caption = _card_caption if card else _bar_caption
	_card_caption.modulate.a = 0.0
	_bar_caption.modulate.a = 0.0
	# The camera first, so depth layers built now start in the right place
	var zoom: Array = spec.get("zoom", [1.0, 1.0])
	var from: Vector2 = spec.get("from", Vector2.ZERO)
	var to: Vector2 = spec.get("to", Vector2.ZERO)
	_camera.zoom = Vector2.ONE * zoom[0]
	_camera.position = SIZE / 2.0 + from
	if card:
		_lore_card(_picture)
	if spec.has("build"):
		spec["build"].call(_picture)
	_era.text = spec.get("era", "")
	_era.modulate.a = 0.0
	var grade: Dictionary = GRADE.merged(spec.get("grade", {}), true)
	for key in grade:
		_grade.set_shader_parameter(key, grade[key])
	if spec.has("music"):
		AudioDirector.play_cue(spec["music"], spec.get("music_db", -4.0))
	# The slow push-in, over the whole time the picture is shown
	var total := 1.0
	for n in spec["lines"].size():
		total += _line_seconds(i, n) + 0.7
	var hold: float = spec.get("hold", 0.0)
	var ken := _picture.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ken.tween_property(_camera, "zoom", Vector2.ONE * zoom[1], maxf(total + FADE - hold, 1.0)).set_delay(hold)
	ken.tween_property(_camera, "position", SIZE / 2.0 + to, maxf(total + FADE - hold, 1.0)).set_delay(hold)
	var reveal := create_tween()
	reveal.tween_property(_fade, "color:a", 0.0, FADE + 0.3)
	reveal.tween_callback(func(): _changing = false; _show_line(0))


## How long a line stays: time to read it, and never less than the picture
## needs for its movements to play out.
func _line_seconds(picture: int, n: int) -> float:
	var text := line_text(pictures[picture]["lines"][n])
	var minimums: Array = pictures[picture].get("min", [])
	var at_least: float = minimums[n] if n < minimums.size() else 0.0
	return maxf(clampf(1.6 + text.length() * 0.05, 4.2, 9.0), at_least)


## A line's words: a plain line is its own words; a spoken one is a
## dictionary {"who", "face", "text"} and is shown in quotes, with the
## speaker's portrait cut in over the picture.
static func line_text(entry: Variant) -> String:
	if entry is Dictionary:
		return "“%s”" % entry["text"]
	return String(entry)


func _show_line(n: int) -> void:
	line = n
	var entry: Variant = pictures[index]["lines"][n]
	var text := line_text(entry)
	if entry is Dictionary and entry.has("who"):
		_show_speaker(String(entry["who"]), String(entry.get("face", "")))
	else:
		_hide_speaker()
	_caption.text = text
	_line_time = 0.0
	_line_length = _line_seconds(index, n)
	_next_hint.modulate.a = 0.0
	if _caption_tween:
		_caption_tween.kill()
	# (a silent beat has no words to show)
	if text != "":
		_caption_tween = create_tween()
		_caption_tween.tween_property(_caption, "modulate:a", 1.0, 1.1 if _caption == _card_caption else 0.7)
	if n == 0:
		create_tween().tween_property(_era, "modulate:a", 1.0, 0.9)
	if _cues.has(n):
		_cues[n].call()


## Cuts in the portrait of `who` (with `face`), on their side of the frame,
## its foot behind the bottom bar; slides in when the speaker changes.
func _show_speaker(who: String, face: String) -> void:
	if not DialogueBox.FACES.has(who):
		_hide_speaker()
		return
	var tex := DialogueBox.portrait(who, face if face != "" else String(DialogueBox.FACES[who][0]))
	var left := String(DialogueBox.SIDES.get(who, "right")) == "left"
	var view := get_viewport().get_visible_rect().size
	var art := DialogueBox.ART_SIZE * DialogueBox.SCALE
	var rest := Vector2(36.0 if left else view.x - art.x - 36.0, view.y - BAR - art.y + 96.0)
	_speaker_art.texture = tex
	_speaker_art.flip_h = not left
	(_speaker_plate.get_child(0) as Label).text = String(DialogueBox.NAMES.get(who, who.capitalize()))
	_speaker_plate.reset_size()
	_speaker_plate.position = Vector2(rest.x + (art.x - _speaker_plate.size.x) / 2.0, view.y - BAR - _speaker_plate.size.y - 6.0)
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if _speaker_who != who:
		_speaker_art.position = rest + Vector2(-70.0 if left else 70.0, 0.0)
		_speaker_art.modulate.a = 0.0
	t.tween_property(_speaker_art, "position", rest, 0.35)
	t.tween_property(_speaker_art, "modulate:a", 1.0, 0.35)
	t.tween_property(_speaker_plate, "modulate:a", 1.0, 0.35)
	_speaker_who = who


func _hide_speaker() -> void:
	if _speaker_who == "":
		return
	_speaker_who = ""
	var t := create_tween().set_parallel()
	t.tween_property(_speaker_art, "modulate:a", 0.0, 0.3)
	t.tween_property(_speaker_plate, "modulate:a", 0.0, 0.3)


## Moves on: to the next line, the next picture, or the village.
func next() -> void:
	if _changing or finished:
		return
	var lines: Array = pictures[index]["lines"]
	_changing = true
	if line + 1 < lines.size():
		var t := create_tween()
		t.tween_property(_caption, "modulate:a", 0.0, 0.35)
		t.tween_callback(func(): _changing = false; _show_line(line + 1))
	elif index + 1 < pictures.size():
		var t := create_tween().set_parallel()
		t.tween_property(_caption, "modulate:a", 0.0, 0.4)
		t.tween_property(_era, "modulate:a", 0.0, 0.4)
		t.tween_property(_fade, "color:a", 1.0, FADE)
		t.chain().tween_callback(_show_picture.bind(index + 1))
	else:
		_finish()


func skip() -> void:
	_finish()


func _finish() -> void:
	if finished:
		return
	finished = true
	_changing = true
	var t := create_tween().set_parallel()
	t.tween_property(_caption, "modulate:a", 0.0, 0.4)
	t.tween_property(_era, "modulate:a", 0.0, 0.4)
	t.tween_property(_next_hint, "modulate:a", 0.0, 0.4)
	t.tween_property(_fade, "color:a", 1.0, 0.9)
	t.chain().tween_callback(_after_pictures)


## When the pictures are over: the finished chapter's card if one is waiting
## (its Continue leads on from here), otherwise straight on.
func _after_pictures() -> void:
	if ChapterComplete.pending.is_empty():
		SceneFade.change(get_tree(), _next_scene(), 0.0)
		return
	var card: Dictionary = ChapterComplete.pending
	ChapterComplete.pending = {}
	var stats: Dictionary = card["stats"].duplicate()
	stats["next"] = _next_scene() if _next_scene() != Journey.TITLE else ""
	results_card = ChapterComplete.open(self, String(card["name"]), stats)


func _process(delta: float) -> void:
	var holding := Input.is_action_pressed("pause") or Input.is_action_pressed("ui_cancel")
	_skip_time = _skip_time + delta if holding and not finished else 0.0
	_skip_bar.size.x = 110.0 * clampf(_skip_time / SKIP_HOLD, 0.0, 1.0)
	if _skip_time >= SKIP_HOLD:
		skip()
	if _changing or finished:
		return
	_line_time += delta
	if _line_time > 1.4:
		_next_hint.modulate.a = move_toward(_next_hint.modulate.a, 0.75, delta * 2.0)
	if _line_time >= _line_length:
		next()


func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	var press: bool = event.is_action_pressed("jump") or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not press:
		return
	get_viewport().set_input_as_handled()
	# The first press finishes a line still fading in; the next moves on
	if not _changing and _caption.text != "" and _caption.modulate.a < 0.95:
		if _caption_tween:
			_caption_tween.kill()
		_caption.modulate.a = 1.0
		_line_time = maxf(_line_time, 1.4)
		return
	next()


# ------------------------------------------------------------------ the page

func _build_ui() -> void:
	# The colour grade and vignette, over the pictures and under the words
	var graded := CanvasLayer.new()
	graded.layer = 3
	add_child(graded)
	var grade_rect := ColorRect.new()
	grade_rect.name = "Grade"
	grade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	grade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grade = ShaderMaterial.new()
	_grade.shader = GRADE_SHADER
	var view := get_viewport().get_visible_rect().size
	_grade.set_shader_parameter("aspect", view.x / maxf(view.y, 1.0))
	grade_rect.material = _grade
	graded.add_child(grade_rect)

	var ui := CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	# The letterbox: black bars that close in from the top and bottom
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.name = "BarTop" if top else "BarBottom"
		bar.color = Color(0.0, 0.0, 0.005)
		bar.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.offset_top = 0.0 if top else 0.0
		bar.offset_bottom = 0.0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(bar)
		_bars.append(bar)
		var close := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		close.tween_property(bar, "offset_bottom" if top else "offset_top", BAR if top else -BAR, 1.2)

	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(NARRATION_FONTS)
	serif.font_italic = true
	# The words of a shot, small and pale in the bottom bar
	_bar_caption = Label.new()
	_bar_caption.name = "Caption"
	_bar_caption.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bar_caption.offset_left = 170
	_bar_caption.offset_right = -170
	_bar_caption.offset_top = -BAR + 4
	_bar_caption.offset_bottom = -4
	_bar_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bar_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bar_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bar_caption.add_theme_font_override("font", serif)
	_bar_caption.add_theme_font_size_override("font_size", 21)
	_bar_caption.add_theme_color_override("font_color", Color("e6e0d2"))
	_bar_caption.add_theme_constant_override("line_spacing", -2)
	_bar_caption.modulate.a = 0.0
	_bar_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_bar_caption)
	# A lore card's words: centred on the black, between its ornaments
	var upright := SystemFont.new()
	upright.font_names = PackedStringArray(NARRATION_FONTS)
	_card_caption = Label.new()
	_card_caption.name = "CardWords"
	_card_caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card_caption.offset_left = 220
	_card_caption.offset_right = -220
	_card_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_caption.add_theme_font_override("font", upright)
	_card_caption.add_theme_font_size_override("font_size", 27)
	_card_caption.add_theme_color_override("font_color", Color("e9e4d8"))
	_card_caption.add_theme_constant_override("line_spacing", 6)
	_card_caption.modulate.a = 0.0
	_card_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_card_caption)
	_caption = _bar_caption

	var small := StoryPaint.label_font()
	# When it happens, in the top bar
	_era = Label.new()
	_era.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_era.offset_top = 0
	_era.offset_bottom = BAR
	_era.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_era.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var spaced := FontVariation.new()
	spaced.base_font = small
	spaced.spacing_glyph = 4
	_era.add_theme_font_override("font", spaced)
	_era.add_theme_font_size_override("font_size", 11)
	_era.add_theme_color_override("font_color", Color("b89e6e"))
	_era.modulate.a = 0.0
	_era.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_era)

	_next_hint = Label.new()
	_next_hint.text = "%s  ▸" % InputLabels.primary("jump")
	_next_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_next_hint.offset_left = -160
	_next_hint.offset_right = -28
	_next_hint.offset_top = -BAR / 2.0 - 11
	_next_hint.offset_bottom = -BAR / 2.0 + 11
	_next_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_next_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_next_hint.add_theme_font_override("font", small)
	_next_hint.add_theme_font_size_override("font_size", 11)
	_next_hint.add_theme_color_override("font_color", Color("8e86a8"))
	_next_hint.modulate.a = 0.0
	ui.add_child(_next_hint)

	_skip_hint = Label.new()
	_skip_hint.text = "Hold %s to skip" % InputLabels.primary("pause")
	_skip_hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_hint.offset_left = -260
	_skip_hint.offset_right = -28
	_skip_hint.offset_top = BAR / 2.0 - 12
	_skip_hint.offset_bottom = BAR / 2.0 + 6
	_skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_skip_hint.add_theme_font_override("font", small)
	_skip_hint.add_theme_font_size_override("font_size", 18)
	_skip_hint.add_theme_color_override("font_color", Color("aaa0ba"))
	ui.add_child(_skip_hint)
	_skip_bar = ColorRect.new()
	_skip_bar.color = Color("b3a9cf")
	_skip_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_skip_bar.offset_left = -138
	_skip_bar.offset_right = -138
	_skip_bar.offset_top = BAR / 2.0 + 9
	_skip_bar.offset_bottom = BAR / 2.0 + 11
	ui.add_child(_skip_bar)

	# A speaker's portrait, cut in over the picture beside the bottom bar
	_speaker_art = TextureRect.new()
	_speaker_art.name = "Speaker"
	_speaker_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_speaker_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	_speaker_art.size = DialogueBox.ART_SIZE * DialogueBox.SCALE
	_speaker_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_speaker_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker_art.modulate.a = 0.0
	ui.add_child(_speaker_art)
	_speaker_plate = DungeonUI.nameplate("")
	_speaker_plate.modulate.a = 0.0
	ui.add_child(_speaker_plate)

	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.01, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_fade)
	# (the bars and words stay above the fade, as a film's do)
	for bar in _bars:
		ui.move_child(bar, -1)
	for words in [_bar_caption, _card_caption, _era, _next_hint, _skip_hint, _skip_bar]:
		ui.move_child(words, -1)


## A lore card: black, a small ornament above the words and one below.
func _lore_card(p: Node2D) -> void:
	StoryStage.fill(p, Color(0.0, 0.0, 0.01))
	var top := SurfaceArt.sprite(p, "hk_ornament", Vector2(576, 324 - 92), 3.0)
	var bottom := SurfaceArt.sprite(p, "hk_ornament", Vector2(576, 324 + 92 + 27), 3.0)
	bottom.flip_v = true
	for o in [top, bottom]:
		o.modulate = Color(0.85, 0.8, 0.7, 0.0)
		var t := p.create_tween()
		t.tween_interval(0.4)
		t.tween_property(o, "modulate:a", 0.8, 1.4)
	StoryPaint.motes(p, Rect2(300, 200, 552, 250), Color(0.8, 0.78, 0.7, 0.25), 10)


# ------------------------------------------------------------------ the pictures
# Each picture is built on a canvas of art pixels drawn `scale` times over
# (3x: 384 x 216 art pixels fill the screen, like the packs' own mock-ups).
# Everything in them comes from the surface and town packs (SurfaceArt) or
# the story's pixel sprites; only light, frost, sound and runes are effects.

## A picture's canvas, `scale` screen pixels to each art pixel.
func _canvas(p: Node2D, scale := 3.0) -> Node2D:
	var c := Node2D.new()
	c.name = "Canvas"
	c.scale = Vector2(scale, scale)
	p.add_child(c)
	return c


## A pack sprite on the canvas (feet at `foot`, art pixels).
func _put(c: Node2D, sprite_name: String, foot: Vector2, flip := false) -> Sprite2D:
	return SurfaceArt.sprite(c, sprite_name, foot, 1.0, flip)


## A hand-made figure (standing, breathing, blinking) on the canvas.
func _figure(c: Node2D, sprite_name: String, foot: Vector2, flip := false, blink_seed := 0) -> AnimatedSprite2D:
	var a := SurfaceArt.animated(c, sprite_name, foot, 0.0, 1.0, flip)
	a.stop()
	var rng := RandomNumberGenerator.new()
	rng.seed = blink_seed + 1
	var t := create_tween().set_loops()
	t.bind_node(a)
	t.tween_interval(rng.randf_range(0.2, 1.4))
	t.tween_callback(func(): a.frame = 1)
	t.tween_interval(1.2)
	t.tween_callback(func(): a.frame = 0)
	t.tween_interval(rng.randf_range(0.8, 1.6))
	t.tween_callback(func(): a.frame = 2)
	t.tween_interval(0.14)
	t.tween_callback(func(): a.frame = 0)
	return a


## A dead tree that sways in the wind (leaning from its roots).
func _swaying(c: Node2D, sprite_name: String, foot: Vector2, amount: float, seed_value: int) -> Sprite2D:
	var tree := _put(c, sprite_name, foot)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var sway := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.bind_node(tree)
	sway.tween_interval(rng.randf() * 0.6)
	sway.tween_property(tree, "skew", -amount, 1.1 + rng.randf() * 0.4)
	sway.tween_property(tree, "skew", -amount * 0.2, 1.2 + rng.randf() * 0.4)
	return tree


## A wall of the pack's old bricks behind an interior, dimmed.
func _brick_wall(c: Node2D, shade := 0.55) -> TileMapLayer:
	var wall := SurfaceArt.tile_block(c, Vector2(-176, -128), 48, 26,
		["bricks_a", "bricks_b", "bricks_a", "bricks_b", "bricks_a", "bricks_roots", "bricks_vines"], 1.0, 23)
	wall.modulate = Color(shade, shade, shade * 1.05)
	return wall


## The bell frame: two old pillars and a beam of planks, with the great
## bell hanging from its middle; returns the bell (it swings from its top).
func _bell_frame(c: Node2D, x: float, ground_y: float) -> Node2D:
	_put(c, "pillar", Vector2(x - 34, ground_y))
	_put(c, "pillar", Vector2(x + 34, ground_y))
	SurfaceArt.tile_row(c, Vector2(x - 40, ground_y - 50), ["plank_l", "plank_m", "plank_m", "plank_m", "plank_r"], 1.0)
	var hang := Node2D.new()
	hang.name = "Bell"
	hang.position = Vector2(x, ground_y - 44)
	c.add_child(hang)
	var bell := AnimatedSprite2D.new()
	bell.sprite_frames = SurfaceArt.frames("great_bell", 0.0)
	bell.centered = false
	bell.offset = Vector2(-13, 0)
	hang.add_child(bell)
	return hang



## The Choir on a ridge of the mountain under the stars; on the second line
## the stars join into a word.
func _choir_reads(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.15, "Sky")
	StoryStage.fill(far, SKY_TOP)
	StoryStage.wash(far, Rect2(-420, 240, 1992, 720), Color(0.04, 0.05, 0.12, 0.0), Color("26315c"))
	var sc := StoryStage.canvas(far, 2.0)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-220, -170, 1000, 290)
	stars.count = 190
	stars.seed_value = 1
	sc.add_child(stars)
	var con := StoryNodes.Constellation.new()
	con.points = [Vector2(452, 162), Vector2(520, 104), Vector2(604, 128), Vector2(668, 70), Vector2(746, 118),
		Vector2(712, 196), Vector2(618, 210)]
	con.glyph = &"wind"
	con.glyph_center = Vector2(600, 140)
	con.glyph_size = 150.0
	far.add_child(con)
	# The mountain behind them, and the monastery on its summit
	var peaks := StoryStage.layer(p, 0.45, "Peaks")
	var pc := StoryStage.canvas(peaks, 2.5)
	StoryStage.piece(pc, "hk_mountain", Vector2(330, 215), Color(0.2, 0.23, 0.36))
	StoryPaint.glow(pc, Vector2(330, 75), 8.0, Color(1.0, 0.8, 0.5), 0.5)
	StoryStage.fog(p, Rect2(-300, 470, 1750, 140), Color(0.5, 0.58, 0.8, 0.22), 0.008, 0.2)
	# The ledge the Choir stand on, in silhouette
	var c := StoryStage.canvas(p, 3.0)
	var ledge := SurfaceArt.ground(c, -176, 150, 172, 1.0, 6, ["grass_a", "grass_b", "grass_c"], ["dirt_a", "dirt_b", "dirt_c"], 2)
	ledge.modulate = Color(0.13, 0.13, 0.19)
	_put(c, "grass_end_r", Vector2(158, 188)).modulate = Color(0.13, 0.13, 0.19)
	for spec in [[Vector2(52, 173), 0], [Vector2(72, 173), 1], [Vector2(92, 173), 2]]:
		var monk := _figure(c, "monk", spec[0], false, spec[1])
		monk.modulate = Color(0.16, 0.16, 0.24)
	# "...the stars are words": the stars join into a rune
	_cues[1] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(0.3)
		t.tween_property(con, "progress", 1.0, 2.6)
		t.tween_callback(Sfx.play.bind("rune_learn", null, -9.0, 0.0))
		t.tween_property(con, "glyph_alpha", 1.0, 1.4)


## A dark hall of the Choir: a rune cube on its plinth, the monks round it
## in silhouette, a shaft of cold light; its four words light, and the air
## moves.
func _choir_cube(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.4, "Far")
	StoryStage.fill(far, Color("05060c"))
	StoryStage.wash(far, Rect2(-420, -320, 1992, 900), Color("151b33"), Color(0.02, 0.03, 0.06, 0.0))
	var fc := StoryStage.canvas(far, 3.0)
	StoryStage.piece(fc, "hk_arch", Vector2(72, 176), Color(0.28, 0.3, 0.42))
	StoryStage.piece(fc, "hk_arch", Vector2(312, 178), Color(0.28, 0.3, 0.42), true)
	var shaft := StoryStage.Beam.new()
	shaft.up = false
	shaft.position = Vector2(576, -40)
	shaft.length = 620.0
	shaft.width_near = 110.0
	shaft.width_far = 320.0
	shaft.color = Color(0.7, 0.8, 1.0)
	shaft.intensity = 0.28
	p.add_child(shaft)
	var c := StoryStage.canvas(p, 3.0)
	var floor_tiles := SurfaceArt.ground(c, -176, 560, 170, 1.0, 6, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9)
	floor_tiles.modulate = Color(0.32, 0.34, 0.48)
	for k in 2:
		_put(c, "slab", Vector2(192, 170 - k * 8)).modulate = Color(0.5, 0.52, 0.66)
	var cube := StoryNodes.Cube.new()
	cube.sprite_name = "rune_cube"
	cube.art_scale = 4.0
	cube.position = Vector2(576, 154 * 3.0 - 44.0)
	cube.words = [&"wind", &"push", &"up", &"strong"]
	p.add_child(cube)
	for x in [156.0, 228.0]:
		var flame := SurfaceArt.animated(c, "candle", Vector2(x, 170), 5.0, 1.0)
		flame.frame = int(x) % 3
		StoryPaint.glow(c, Vector2(x, 158), 14.0, Color(0.6, 0.8, 1.0), 0.7)
	for spec in [[100.0, false], [126.0, false], [258.0, true], [284.0, true]]:
		var monk := _figure(c, "monk", Vector2(spec[0], 171), spec[1], int(spec[0]))
		monk.modulate = Color(0.2, 0.19, 0.3)
	var gust := StoryStage.embers(p, Rect2(440, 300, 272, 160), Color(0.75, 0.68, 1.0, 0.9), 30, 90.0)
	gust.emitting = false
	var near := StoryStage.layer(p, 1.4, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_pillar", Vector2(4, 214), Color(0.4, 0.4, 0.5))
	StoryStage.piece(nc, "hk_pillar", Vector2(382, 212), Color(0.4, 0.4, 0.5), true)
	# "When all four words light up...": one at a time, and the wind rises
	_cues[0] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(0.6)
		for i in 4:
			t.tween_callback(Sfx.play.bind("rune_activate", null, -11.0, 0.05))
			t.tween_property(cube, "lit", float(i + 1), 0.5)
			t.tween_interval(0.2)
		t.tween_callback(func() -> void:
			gust.emitting = true
			Sfx.play("wind_gust", null, -10.0, 0.0))


## Wren's bedside, sixty years ago: Ilse kneeling, holding her daughter's
## hand, the candle lit, moonlight from a high window; on the second line the
## four notes of her song rise from her, one by one.
func _ilse_sings(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.4, "Far")
	StoryStage.fill(far, Color("0a0810"))
	StoryStage.wash(far, Rect2(-420, -320, 1992, 900), Color("201a2c"), Color(0.03, 0.03, 0.05, 0.0))
	var fc := StoryStage.canvas(far, 4.0)
	StoryStage.piece(fc, "hk_arch", Vector2(150, 146), Color(0.3, 0.27, 0.34))
	_put(fc, "win_arch_bright", Vector2(70, 60)).modulate = Color(0.75, 0.82, 1.0)
	StoryPaint.glow(fc, Vector2(70, 50), 18.0, Color(0.6, 0.75, 1.0), 0.5)
	var moon := StoryStage.Beam.new()
	moon.up = false
	moon.position = Vector2(280, 200)
	moon.rotation = -0.45
	moon.length = 520.0
	moon.width_near = 50.0
	moon.width_far = 200.0
	moon.color = Color(0.7, 0.8, 1.0)
	moon.intensity = 0.22
	p.add_child(moon)
	var c := StoryStage.canvas(p, 5.0)
	var floor_tiles := SurfaceArt.ground(c, -60, 300, 104, 1.0, 5, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 13)
	floor_tiles.modulate = Color(0.42, 0.38, 0.45)
	SurfaceArt.animated(c, "wren_bed", Vector2(133, 104), 0.9, 1.0).modulate = Color(0.95, 0.9, 0.9)
	_put(c, "crate", Vector2(184, 104)).modulate = Color(0.75, 0.7, 0.72)
	SurfaceArt.animated(c, "candle", Vector2(184, 90), 5.0, 1.0)
	StoryPaint.glow(c, Vector2(184, 80), 26.0, Color(1.0, 0.72, 0.4), 0.9)
	var ilse := SurfaceArt.animated(c, "hk_ilse_kneel", Vector2(100, 104), 0.0, 1.0)
	ilse.stop()
	var near := StoryStage.layer(p, 1.4, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_pillar", Vector2(380, 214), Color(0.32, 0.3, 0.36), true)
	var notes: Array = []
	for i in 4:
		var note := StoryPaint.glow(c, Vector2(104, 80), 4.0, Color(1.0, 0.86, 0.6), 1.2)
		note.modulate.a = 0.0
		notes.append(note)
	_cues[1] = func() -> void:
		var t := p.create_tween()
		t.tween_callback(func(): ilse.frame = 1)
		for i in 4:
			var note: Sprite2D = notes[i]
			t.tween_callback(func() -> void:
				note.modulate.a = 1.0
				var rise := p.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
				rise.tween_property(note, "position", Vector2(98 + i * 10, 44 - (i % 2) * 6), 2.4)
				rise.tween_property(note, "modulate:a", 0.0, 2.8).set_delay(0.6))
			t.tween_interval(0.9)
		t.tween_callback(func(): ilse.frame = 0)


## The great cube, and Ilse small before it: the four words of the spell
## light, and on the second line the frost takes the room and the snow stops.
func _ilse_writes(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.4, "Far")
	StoryStage.fill(far, Color("04060c"))
	StoryStage.wash(far, Rect2(-420, -320, 1992, 900), Color("0e1830"), Color(0.02, 0.03, 0.06, 0.0))
	var fc := StoryStage.canvas(far, 3.0)
	StoryStage.piece(fc, "hk_stalactites", Vector2(60, 50), Color(0.32, 0.36, 0.5))
	StoryStage.piece(fc, "hk_stalactites", Vector2(330, 46), Color(0.32, 0.36, 0.5), true)
	var snow := StoryPaint.snow(p, Rect2(-420, -340, 1992, 1100), 170)
	var c := StoryStage.canvas(p, 3.0)
	var floor_tiles := SurfaceArt.ground(c, -176, 560, 170, 1.0, 6, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9)
	floor_tiles.modulate = Color(0.3, 0.33, 0.46)
	for spec in [Vector2(176, 170), Vector2(208, 170), Vector2(176, 162), Vector2(208, 162)]:
		_put(c, "slab", spec).modulate = Color(0.5, 0.54, 0.7)
	var cube := StoryNodes.Cube.new()
	cube.sprite_name = "rune_cube_great"
	cube.art_scale = 4.0
	cube.position = Vector2(576, 154 * 3.0 - 68.0)
	cube.words = [&"ice", &"freeze", &"self", &"persist"]
	cube.color = Color(0.62, 0.9, 1.0)
	cube.show_names = true
	p.add_child(cube)
	var ilse := _figure(c, "ilse", Vector2(120, 171), false, 4)
	ilse.modulate = Color(0.3, 0.32, 0.42)
	var frost := StoryNodes.Frost.new()
	frost.position = cube.position
	p.add_child(frost)
	var flash := StoryPaint.glow(p, cube.position, 440, Color(0.7, 0.9, 1.0), 0.6)
	flash.modulate.a = 0.0
	var near := StoryStage.layer(p, 1.4, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_rocks", Vector2(20, 238), Color(0.3, 0.3, 0.4))
	StoryStage.piece(nc, "hk_rocks", Vector2(372, 240), Color(0.3, 0.3, 0.4), true)
	_cues[0] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(0.8)
		for i in 4:
			t.tween_callback(Sfx.play.bind("ice_form", null, -10.0, 0.05))
			t.tween_property(cube, "lit", float(i + 1), 0.6)
	# "The night stopped...": the frost takes the room and the snow hangs still
	_cues[1] = func() -> void:
		var freeze := p.create_tween()
		freeze.tween_interval(0.3)
		freeze.tween_callback(Sfx.play.bind("ice_freeze", null, -4.0, 0.0))
		freeze.set_parallel()
		freeze.tween_property(frost, "radius", 1100.0, 3.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		freeze.tween_property(snow, "speed_scale", 0.0, 2.6)
		freeze.tween_property(flash, "modulate:a", 0.45, 1.5)


## The mountain at night: the Hush spreads as the stars go out.
func _the_moth_unfolds(p: Node2D) -> void:
	var sky := _mountain_night(p, false, false)
	var stars: StoryNodes.Stars = sky["stars"]
	# The Hush reads as a spreading absence of stars, rather than a giant insect.
	var t := p.create_tween().set_parallel()
	t.tween_property(stars, "fade", 0.15, 9.0).set_delay(1.0)
	t.tween_callback(Sfx.play.bind("power_down", null, -12.0, 0.0)).set_delay(1.0)

func _the_bell_sings(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.2, "Sky")
	StoryStage.fill(far, SKY_TOP)
	StoryStage.wash(far, Rect2(-420, 200, 1992, 760), Color(0.04, 0.05, 0.12, 0.0), Color("2a3560"))
	var sc := StoryStage.canvas(far, 2.0)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-220, -170, 1000, 260)
	stars.count = 120
	stars.seed_value = 5
	sc.add_child(stars)
	var c := StoryStage.canvas(p, 5.0)
	var ledge := SurfaceArt.ground(c, -90, 330, 96, 1.0, 8, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 51)
	ledge.modulate = Color(0.34, 0.35, 0.48)
	var bell := _bell_frame(c, 115.0, 96.0)
	bell.modulate = Color(0.75, 0.75, 0.86)
	# The Hush: grey fog closing in from both sides, pushed back with each note
	var fogs: Array = []
	for side in [-1, 1]:
		var fog := StoryStage.fog(p, Rect2(576 + side * 360 - 420, 120, 840, 420), Color(0.55, 0.57, 0.66, 0.55), 0.006, 0.5 + side * 0.2)
		fogs.append([fog, side])
	var rings := StoryNodes.Rings.new()
	rings.color = Color(0.85, 0.9, 1.0)
	rings.position = Vector2(115, 60) * 5.0
	p.add_child(rings)
	var near := StoryStage.layer(p, 1.35, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_rocks", Vector2(20, 240), Color(0.2, 0.2, 0.28))
	StoryStage.piece(nc, "hk_rocks", Vector2(372, 242), Color(0.2, 0.2, 0.28), true)
	bell.rotation = -0.26
	var swing := p.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing.tween_property(bell, "rotation", 0.26, 1.6)
	swing.tween_property(bell, "rotation", -0.26, 1.6)
	# In time with the peal's notes (tools/generate_story_music.gd)
	var t := p.create_tween()
	t.tween_interval(0.3)
	for k in 5:
		t.tween_callback(func() -> void:
			rings.ring()
			for entry in fogs:
				var fog: ColorRect = entry[0]
				var push := p.create_tween().set_trans(Tween.TRANS_SINE)
				push.tween_property(fog, "position:x", fog.position.x + entry[1] * 60.0, 1.0).set_ease(Tween.EASE_OUT))
		t.tween_interval(1.6 if k < 3 else 2.1)


## Nine years ago: the bell cracks, the Belfry is sealed, and the last monks
## go down the mountain with their lanterns.
func _the_crack(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.2, "Sky")
	StoryStage.fill(far, SKY_TOP)
	StoryStage.wash(far, Rect2(-420, 200, 1992, 760), Color(0.04, 0.05, 0.12, 0.0), Color("26305a"))
	var sc := StoryStage.canvas(far, 2.0)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-220, -170, 1000, 240)
	stars.count = 90
	stars.seed_value = 19
	sc.add_child(stars)
	var hills := StoryStage.layer(p, 0.5, "Hills")
	var hc := StoryStage.canvas(hills, 3.0)
	StoryStage.piece(hc, "hk_rocks", Vector2(240, 214), Color(0.26, 0.28, 0.4))
	StoryStage.piece(hc, "hk_rocks", Vector2(420, 210), Color(0.26, 0.28, 0.4), true)
	var c := StoryStage.canvas(p, 3.0)
	# The high ledge with the belfry and its sealed door, and the lower lane
	# the monks go down
	SurfaceArt.ground(c, -176, 232, 150, 1.0, 5, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b", "bricks_roots"], 71).modulate = Color(0.4, 0.42, 0.55)
	SurfaceArt.ground(c, 232, 560, 196, 1.0, 2, ["grass_a", "grass_b", "grass_c"], ["dirt_a", "dirt_b"], 72).modulate = Color(0.4, 0.42, 0.55)
	_put(c, "crypt", Vector2(62, 150)).modulate = Color(0.5, 0.52, 0.66)
	var bell_hang := _bell_frame(c, 170.0, 150.0)
	bell_hang.modulate = Color(0.6, 0.62, 0.74)
	var bell: AnimatedSprite2D = bell_hang.get_child(0)
	var seal := StoryNodes.Glyph.new()
	seal.glyph = &"persist"
	seal.size = 26.0
	seal.color = Color(0.7, 0.55, 1.0)
	seal.position = Vector2(62, 136) * 3.0
	seal.alpha = 0.0
	p.add_child(seal)
	# The last monks, lanterns lit, going down and away
	var monks: Array = []
	for j in 4:
		var monk := _figure(c, "monk", Vector2(120 + j * 18, 151), false, j)
		monk.modulate = Color(0.32, 0.32, 0.44, 0.0)
		var lamp := StoryPaint.glow(monk, Vector2(12, -12), 10.0, Color(1.0, 0.8, 0.5), 1.0)
		lamp.modulate.a = 1.0
		monks.append(monk)
	var walk := func(k: float) -> void:
		for j in monks.size():
			var d := clampf(k - j * 0.1, 0.0, 1.0)
			var monk: AnimatedSprite2D = monks[j]
			# Along the ledge, down to the lane, and off to the right
			var pos := Vector2(lerpf(120.0, 470.0, d), 151.0)
			if pos.x > 232.0:
				pos.y = lerpf(151.0, 197.0, clampf((pos.x - 232.0) / 24.0, 0.0, 1.0))
			pos.y -= absf(sin(d * 60.0)) * 1.0
			monk.position = pos.round()
			monk.modulate.a = clampf(d * 14.0, 0.0, 1.0) * clampf((1.0 - d) * 5.0, 0.0, 1.0)
	walk.call(0.0)
	var near := StoryStage.layer(p, 1.3, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	for x in [-100.0, 100.0, 300.0, 500.0]:
		StoryStage.piece(nc, "hk_grass", Vector2(x, 238), Color(0.2, 0.2, 0.28))
	# The bell cracks; the tower is sealed; the monks go
	_cues[0] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(0.4)
		t.tween_callback(Sfx.play.bind("crumble_crack", null, -3.0, 0.0))
		t.tween_callback(func(): bell.frame = 1)
		t.tween_property(bell_hang, "modulate", Color(0.5, 0.48, 0.5), 0.6)
		t.tween_interval(1.4)
		t.tween_callback(Sfx.play.bind("gate_slam", null, -10.0, 0.0))
		t.tween_property(seal, "alpha", 1.0, 0.6)
		t.tween_method(walk, 0.0, 1.3, 7.0)


## Lowbell today, grey with the Hush and its stars going out; on the third
## line Echidna steps into the lane.
func _lowbell_today(p: Node2D) -> void:
	var town := _lowbell_wide(p, false, false)
	var stars: StoryNodes.Stars = town["stars"]
	var fading := p.create_tween()
	fading.tween_interval(1.5)
	fading.tween_property(stars, "fade", 0.9, 14.0)
	var c: Node2D = town["layers"][3]
	var echidna := _echidna(c, Vector2(282, 211), 0.541)
	echidna.modulate.a = 0.0
	for l in town["layers"]:
		l.modulate = Color(0.7, 0.72, 0.8)
	_cues[2] = func() -> void:
		var appear := p.create_tween()
		appear.tween_interval(0.3)
		appear.tween_property(echidna, "modulate:a", 1.0, 1.2)


# ------------------------------------------------------------------ staging shared by the reels

## The Eye: a dark domed chamber deep under the monastery. The held moment
## hangs in it as a great moth (`moth_light` 0 frozen .. 2 alight), held by
## four chains to the plinth of the great cube; snow hangs still in the air;
## Ilse kneels at Wren's bed holding her hand; Echidna (`with_echidna`) stands
## small before the cube. `folded`: the moth wrapped round itself, as it is
## before the end. Returns the parts the shots move.
func _eye_room(p: Node2D, moth_light := 0.0, words: Array = [&"light", &"beam", &"up", &"long"], folded := false,
		with_echidna := true) -> Dictionary:
	# Far: the dark of the chamber, its dome, and the lens at the top
	var far := StoryStage.layer(p, 0.35, "Far")
	StoryStage.fill(far, Color("04060c"))
	StoryStage.wash(far, Rect2(-420, -320, 1992, 860), Color("0c1428"), Color(0.02, 0.03, 0.06, 0.0))
	var fc := StoryStage.canvas(far, 3.0)
	StoryStage.piece(fc, "hk_dome", Vector2(192, 152), Color(0.42, 0.48, 0.66))
	StoryPaint.glow(far, Vector2(576, 64), 70.0, Color(0.55, 0.7, 1.0), 0.6)
	# Middle distance: stalactites and cold crystals
	var mid := StoryStage.layer(p, 0.65, "Mid")
	var mc := StoryStage.canvas(mid, 3.0)
	StoryStage.piece(mc, "hk_stalactites", Vector2(40, 52), Color(0.42, 0.46, 0.6))
	StoryStage.piece(mc, "hk_stalactites", Vector2(344, 48), Color(0.42, 0.46, 0.6), true)
	for spec in [[Vector2(18, 176), false], [Vector2(368, 178), true]]:
		StoryStage.piece(mc, "hk_crystals", spec[0], Color(0.75, 0.85, 1.0), spec[1])
		StoryPaint.glow(mc, spec[0] - Vector2(0, 26), 34.0, Color(0.45, 0.65, 1.0), 0.5)
	# The focus
	var c := StoryStage.canvas(p, 3.0)
	var floor_tiles := SurfaceArt.ground(c, -176, 560, 170, 1.0, 6, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9)
	floor_tiles.modulate = Color(0.3, 0.33, 0.45)
	var moth := StoryStage.Moth.new()
	moth.art_scale = 2.6
	moth.position = Vector2(576, 214)
	moth.light = moth_light
	moth.folded = folded
	if folded:
		moth.position.y = 244.0
	p.add_child(moth)
	var chains: Array = []
	var tops := [Vector2(-40, 30), Vector2(-24, 120), Vector2(24, 120), Vector2(40, 30)] if folded \
		else [Vector2(-150, 36), Vector2(-74, 100), Vector2(74, 100), Vector2(150, 36)]
	var feet := [Vector2(404, 508), Vector2(478, 508), Vector2(674, 508), Vector2(748, 508)]
	for i in 4:
		var chain := StoryStage.Chain.new()
		chain.word = i
		chain.art_scale = 2.6
		chain.position = moth.position + tops[i]
		chain.to = feet[i] - chain.position
		chain.plate_at = 0.5
		p.add_child(chain)
		chains.append(chain)
	for k in 2:
		var slab := _put(c, "slab", Vector2(192, 170 - k * 8))
		slab.modulate = Color(0.5, 0.52, 0.65)
	var cube := StoryNodes.Cube.new()
	cube.sprite_name = "rune_cube_great"
	cube.art_scale = 3.0
	cube.position = Vector2(576, 154 * 3.0 - 51.0)
	cube.words = words
	cube.color = Color(1.0, 0.82, 0.5) if words[0] == &"light" else Color(0.62, 0.9, 1.0)
	cube.show_names = true
	p.add_child(cube)
	# Wren's bed, the candle that must not go out, and Ilse kneeling, holding on
	var bed := SurfaceArt.animated(c, "wren_bed", Vector2(302, 170), 0.9, 1.0)
	bed.modulate = Color(0.78, 0.82, 0.95)
	_put(c, "crate", Vector2(352, 170)).modulate = Color(0.6, 0.62, 0.75)
	var candle := SurfaceArt.animated(c, "candle", Vector2(352, 156), 5.0, 1.0)
	var candle_glow := StoryPaint.glow(c, Vector2(352, 146), 26.0, Color(1.0, 0.75, 0.45), 0.8)
	var ilse := SurfaceArt.animated(c, "hk_ilse_kneel", Vector2(258, 170), 0.0, 1.0)
	ilse.stop()
	ilse.frame = 0
	var echidna: AnimatedSprite2D = _echidna(p, Vector2(318, 510), 1.4) if with_echidna else null
	# Air: fog over the floor and snow that does not fall
	StoryStage.fog(p, Rect2(-300, 400, 1750, 190), Color(0.45, 0.55, 0.78, 0.32), 0.01, 0.3)
	var snow := StoryStage.hanging_snow(p, Rect2(-120, -20, 1392, 620), 120)
	# Near: black rock and broken pillars at the edges of the frame
	var near := StoryStage.layer(p, 1.4, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_rocks", Vector2(10, 236), Color(0.45, 0.45, 0.55))
	StoryStage.piece(nc, "hk_rocks", Vector2(380, 238), Color(0.45, 0.45, 0.55), true)
	StoryStage.piece(nc, "hk_pillar", Vector2(-6, 214), Color(0.5, 0.5, 0.6))
	StoryStage.piece(nc, "hk_pillar", Vector2(392, 212), Color(0.5, 0.5, 0.6), true)
	return {"moth": moth, "chains": chains, "cube": cube, "bed": bed, "candle": candle, "candle_glow": candle_glow,
		"ilse": ilse, "echidna": echidna, "snow": snow}


## Echidna (her own sprite frames), feet at `foot` in the parent's units.
func _echidna(parent: Node, foot: Vector2, size := 1.4, flip := false, animation := &"idle") -> AnimatedSprite2D:
	var e := AnimatedSprite2D.new()
	e.name = "Echidna"
	e.sprite_frames = ECHIDNA
	e.offset = ECHIDNA.get_meta(&"sprite_offset", Vector2(0, -32))
	e.scale = Vector2(size, size)
	e.position = foot
	e.flip_h = flip
	parent.add_child(e)
	e.play(animation)
	return e


## Night over the mountain: stars far off, the monastery and its bell tower on
## the summit, the dark gap where four stars went out (`dead`) and the pair
## of new stars (`pair`, lit) with a faint line between them, fog at the
## mountain's foot and grass black in front. Without `pair_shown`, just
## the night (no gap, no pair).
func _mountain_night(p: Node2D, snowing := false, pair_shown := true) -> Dictionary:
	var far := StoryStage.layer(p, 0.15, "Sky")
	StoryStage.fill(far, SKY_TOP)
	StoryStage.wash(far, Rect2(-420, 180, 1992, 780), Color(0.04, 0.05, 0.12, 0.0), Color("2c3a6a"))
	var sc := StoryStage.canvas(far, 2.0)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-220, -170, 1000, 230)
	stars.count = 150
	stars.seed_value = 61
	sc.add_child(stars)
	var dead: Array = []
	for at in [Vector2(530, 150), Vector2(560, 196), Vector2(604, 168), Vector2(640, 210)]:
		var d := SurfaceArt.sprite(far, "spark_small", at + Vector2(0, 3), 2.0)
		d.modulate = Color(0.5, 0.5, 0.64, 0.9)
		dead.append(d)
	var pair: Array = []
	for at in [Vector2(552, 172), Vector2(612, 184)]:
		var holder := Node2D.new()
		holder.position = at
		far.add_child(holder)
		var star := SurfaceArt.sprite(holder, "spark", Vector2(0, 7), 2.6)
		star.modulate = Color(1.0, 0.97, 0.88)
		StoryPaint.glow(holder, Vector2.ZERO, 26.0, Color(1.0, 0.9, 0.7), 0.9)
		var twinkle := holder.create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		twinkle.tween_property(star, "modulate:a", 0.7, 1.3 + pair.size() * 0.4)
		twinkle.tween_property(star, "modulate:a", 1.0, 1.3 + pair.size() * 0.4)
		pair.append(holder)
	var line := StoryNodes.Constellation.new()
	line.points = [Vector2(552, 172), Vector2(612, 184)]
	line.color = Color(1.0, 0.9, 0.7)
	line.glyph_alpha = 0.0
	line.progress = 1.0
	far.add_child(line)
	var hill := StoryStage.layer(p, 0.55, "Mountain")
	var hc := StoryStage.canvas(hill, 3.0)
	StoryStage.piece(hc, "hk_mountain", Vector2(192, 222), Color(0.3, 0.32, 0.44))
	StoryPaint.glow(hc, Vector2(192, 92), 10.0, Color(1.0, 0.8, 0.5), 0.5)
	StoryStage.fog(p, Rect2(-300, 420, 1750, 200), Color(0.5, 0.58, 0.8, 0.35), 0.008, 0.1)
	var near := StoryStage.layer(p, 1.3, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	for x in [-100.0, 100.0, 300.0, 500.0]:
		StoryStage.piece(nc, "hk_grass", Vector2(x, 224), Color(0.35, 0.36, 0.45))
	var snow: CPUParticles2D = null
	if snowing:
		snow = StoryPaint.snow(p, Rect2(-300, -340, 1752, 1100), 140)
	if not pair_shown:
		for piece in dead + pair + [line]:
			piece.visible = false
	return {"dead": dead, "pair": pair, "line": line, "snow": snow, "stars": stars}


## Lowbell seen wide at night: sky and stars, the hills, the town behind, the
## lane's houses with their windows lit, the wind chimes (swinging, or held
## still), black grass in front. With `pair`, the two new stars are up.
func _lowbell_wide(p: Node2D, swing: bool, pair: bool) -> Dictionary:
	var far := StoryStage.layer(p, 0.2, "Sky")
	StoryStage.fill(far, SKY_TOP)
	var fc := StoryStage.canvas(far, 2.0)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-220, -170, 1000, 180)
	stars.count = 110
	stars.seed_value = 29
	fc.add_child(stars)
	if pair:
		for at in [Vector2(250, 76), Vector2(266, 79)]:
			SurfaceArt.sprite(fc, "spark", at, 1.6).modulate = Color(1.0, 0.95, 0.85)
			StoryPaint.glow(fc, at - Vector2(0, 3), 7.0, Color(1.0, 0.9, 0.7), 0.7)
	var hills := StoryStage.layer(p, 0.5, "Hills")
	var hc := StoryStage.canvas(hills, 2.0)
	hc.position.y = 60.0
	SurfaceArt.backdrop(hc, "hills", Vector2(-40 - 640, -90), 1.0, 640 * 3)
	var town := StoryStage.layer(p, 0.75, "Town")
	var tc := StoryStage.canvas(town, 2.0)
	tc.position.y = 60.0
	var roofs := SurfaceArt.backdrop(tc, "town", Vector2(-220 - 640, -100), 1.0, 640 * 3)
	roofs.modulate = Color(0.9, 0.9, 1.0)
	var c := StoryStage.canvas(p, 2.0)
	c.position.y = 60.0
	SurfaceArt.ground(c, -230, 800, 210, 1.0, 8, ["grass_a", "grass_b", "grass_c"], ["dirt_a", "dirt_b", "dirt_c"], 61)
	for spec in [["house_small", 34.0, [Vector2(38, 46)]], ["house_medium", 120.0, [Vector2(22, 56)]],
			["house_shop", 236.0, [Vector2(61, 66)]], ["house_big", 368.0, [Vector2(54, 44), Vector2(27, 88)]],
			["house_tower", 470.0, [Vector2(26, 31)]]]:
		var house := _put(c, spec[0], Vector2(spec[1], 212))
		var top_left := house.position + house.offset
		for w in spec[2]:
			StoryPaint.glow(c, top_left + w, 10.0, Color(1.0, 0.8, 0.5), 0.8)
	_put(c, "chime_post", Vector2(303, 211))
	for i in 5:
		var tube := _swaying(c, "chime_tube", Vector2(291 + i * 5.0, 196), 0.18, 40 + i) if swing \
			else _put(c, "chime_tube", Vector2(291 + i * 5.0, 196))
		if not swing:
			tube.skew = -0.12 + i * 0.03
		tube.z_index = 1
	var near := StoryStage.layer(p, 1.3, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	for x in [-100.0, 100.0, 300.0, 500.0]:
		StoryStage.piece(nc, "hk_grass", Vector2(x, 196), Color(0.3, 0.32, 0.4))
	return {"layers": [far, hills, town, c], "stars": stars}


## Nan's cottage door at night: the roofs of Lowbell behind, Nan in her chair
## and Echidna beside her. With `pair`, the two new stars are up.
func _porch(p: Node2D, pair: bool) -> Dictionary:
	var far := StoryStage.layer(p, 0.2, "Sky")
	StoryStage.fill(far, SKY_TOP)
	StoryStage.wash(far, Rect2(-420, 160, 1992, 600), Color(0.04, 0.05, 0.12, 0.0), Color("1c2242"))
	var fc := StoryStage.canvas(far, 2.0)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-220, -170, 1000, 170)
	stars.count = 90
	stars.seed_value = 3
	fc.add_child(stars)
	if pair:
		for at in [Vector2(380, 90), Vector2(398, 94)]:
			SurfaceArt.sprite(fc, "spark", at, 1.6).modulate = Color(1.0, 0.95, 0.85)
			StoryPaint.glow(fc, at - Vector2(0, 3), 8.0, Color(1.0, 0.9, 0.7), 0.8)
	var town := StoryStage.layer(p, 0.6, "Roofs")
	var tc := StoryStage.canvas(town, 3.0)
	StoryStage.piece(tc, "hk_roofs", Vector2(80, 168), Color(0.4, 0.42, 0.56))
	StoryStage.piece(tc, "hk_roofs", Vector2(380, 166), Color(0.4, 0.42, 0.56), true)
	var c := StoryStage.canvas(p, 4.0)
	SurfaceArt.ground(c, -110, 400, 132, 1.0, 5, ["grass_a", "grass_b", "grass_c"], ["dirt_a", "dirt_b", "dirt_c"], 7)
	var house := _put(c, "house_small", Vector2(186, 133))
	var top_left := house.position + house.offset
	StoryPaint.glow(c, top_left + Vector2(38, 46), 9.0, Color(1.0, 0.74, 0.42), 0.7)
	var nan := SurfaceArt.animated(c, "nan_seated", Vector2(118, 133), 0.0, 1.0)
	nan.stop()
	nan.frame = 2
	var echidna := _echidna(c, Vector2(144, 133), 0.541, true)
	var warm := StoryPaint.glow(c, Vector2(130, 112), 40.0, Color(1.0, 0.8, 0.55), 0.35)
	var near := StoryStage.layer(p, 1.35, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_grass", Vector2(40, 226), Color(0.28, 0.3, 0.38))
	StoryStage.piece(nc, "hk_grass", Vector2(340, 226), Color(0.28, 0.3, 0.38), true)
	return {"nan": nan, "echidna": echidna, "stars": stars, "warm": warm}


