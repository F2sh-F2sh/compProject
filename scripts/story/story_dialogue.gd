extends CanvasLayer

## A conversation over the live scene. The host owns control locking and
## progress; completing or skipping always runs the same completion callback.
signal finished
signal line_shown(index: int)

var lines: Array = []
var index := -1
var active := false
var _speaker: Label
var _body: Label
var _counter: Label
var _portrait: TextureRect
var _next: Button
var _skip: Button
var _panel: PanelContainer
var _elapsed := 0.0
var _skip_hold := 0.0

func _ready() -> void:
	layer = 7
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	root.size = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(func(): root.size = get_viewport().get_visible_rect().size)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for top in [true, false]:
		var bar := ColorRect.new()
		root.add_child(bar)
		bar.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.offset_bottom = 24 if top else 0
		bar.offset_top = 0 if top else -24
		bar.color = Color(0.015, 0.012, 0.03, 0.85)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	root.add_child(_panel)
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_left = 32
	_panel.offset_right = -32
	_panel.offset_top = -182
	_panel.offset_bottom = -32
	var style := StyleBoxFlat.new()
	style.bg_color = Color("141121")
	style.border_color = Color("806c9b")
	style.set_border_width_all(1)
	style.border_width_top = 2
	style.set_corner_radius_all(6)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	_panel.add_child(row)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(70, 90)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_portrait)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 8)
	row.add_child(words)
	_speaker = Label.new()
	_speaker.add_theme_font_override("font", StoryPaint.label_font())
	_speaker.add_theme_font_size_override("font_size", 13)
	_speaker.add_theme_color_override("font_color", Color("e8c48b"))
	words.add_child(_speaker)
	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Cambria", "Times New Roman", "serif"])
	_body.add_theme_font_override("font", serif)
	_body.add_theme_font_size_override("font_size", 21)
	_body.add_theme_color_override("font_color", Color("eee6dc"))
	words.add_child(_body)
	var footer := HBoxContainer.new()
	words.add_child(footer)
	_counter = Label.new()
	_counter.clip_text = true
	_counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_counter.add_theme_font_size_override("font_size", 12)
	_counter.add_theme_color_override("font_color", Color("a99cb9"))
	footer.add_child(_counter)
	_skip = Button.new()
	_skip.text = "Skip conversation"
	_skip.pressed.connect(complete)
	footer.add_child(_skip)
	_next = Button.new()
	_next.pressed.connect(advance)
	footer.add_child(_next)
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	get_viewport().size_changed.connect(_adapt_layout)
	_adapt_layout()
	root.visible = false

func _adapt_layout() -> void:
	var narrow := get_viewport().get_visible_rect().size.x < 900
	_panel.offset_left = 16 if narrow else 32
	_panel.offset_right = -16 if narrow else -32
	_panel.offset_top = -202 if narrow else -182
	_body.add_theme_font_size_override("font_size", 19 if narrow else 21)
	_skip.text = "Skip" if narrow else "Skip conversation"

func begin(pages: Array) -> void:
	lines = pages
	index = -1
	active = true
	get_child(0).visible = true
	advance()

func advance() -> void:
	if not active or (index >= 0 and _elapsed < 0.18):
		return
	index += 1
	if index >= lines.size():
		complete()
		return
	_elapsed = 0.0
	var page: Array = lines[index]
	_speaker.text = String(page[0]).to_upper()
	_body.text = page[1]
	_counter.text = "%d / %d  ·  %s / %s to continue · hold %s to skip" % [index + 1, lines.size(), InputLabels.primary("interact"), InputLabels.primary("jump"), InputLabels.primary("pause")]
	_next.text = "Continue" if index < lines.size() - 1 else "Go on"
	_portrait.texture = SurfaceArt.tex("nan") if page[0] == "Nan" else preload("res://assets/sprites/Echidna/echidna_frames.tres").get_frame_texture("idle", 0)
	_portrait.visible = page[0] in ["Nan", "Echidna"] and get_viewport().get_visible_rect().size.x >= 900
	_next.grab_focus()
	line_shown.emit(index)

func complete() -> void:
	if not active:
		return
	active = false
	get_child(0).visible = false
	finished.emit()

func _process(delta: float) -> void:
	_elapsed += delta
	if not active or get_tree().paused:
		return
	_skip_hold = _skip_hold + delta if Input.is_action_pressed("pause") else 0.0
	if _skip_hold >= 0.9:
		complete()

func _input(event: InputEvent) -> void:
	if not active or get_tree().paused:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance()
