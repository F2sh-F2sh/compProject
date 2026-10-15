class_name EndlessCard
extends CanvasLayer

var kind := "over"
var keep_button: Button
var leave_button: Button
var again_button: Button
var title_button: Button
var copy_button: Button
var result: Dictionary = {}
var code := ""

static func open(host: Node, card_kind: String) -> EndlessCard:
	var card := EndlessCard.new()
	card.kind = card_kind
	host.add_child(card)
	card._build()
	return card

func _build() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Crosshair.arrow()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.05, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var height := minf(480.0, get_viewport().get_visible_rect().size.y - 40.0)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -height / 2
	panel.offset_bottom = height / 2
	root.add_child(panel)
	DungeonUI.decorate(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(box)
	box.add_child(_line("A REST ON THE STAIR" if kind == "rest" else "THE CLIMB ENDS", 16, DailyComplete.GOLD_DIM))
	box.add_child(_line("Endless: %s → %s" % [DailyDifficulty.name_of(DailyRun.endless_start), DailyDifficulty.name_of(DailyRun.level())], 24, DailyComplete.GOLD))
	box.add_child(DungeonUI.divider(480))
	box.add_child(_line("Rooms climbed   %d" % DailyRun.run_rooms))
	box.add_child(_line("Score   %d" % DailyRun.run_score))
	box.add_child(_line("Hints heard   %d" % DailyRun.run_hints))
	if kind == "rest":
		box.add_child(_line("Lives %d (one back)" % DailyRun.lives, 16, DailyComplete.GOLD))
	else:
		var best := DailyStore.endless_best_for(DailyRun.endless_start)
		box.add_child(_line("Best from %s: %d rooms%s" % [DailyDifficulty.name_of(DailyRun.endless_start), int(best.get("rooms", 0)), " (new best!)" if DailyRun.new_best else ""]))
	var last := _line("Last room: " + DailyRun.last_ways)
	last.custom_minimum_size.x = 560
	last.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(last)
	result = {"endless": true, "version": DailyGenerator.GEN_VERSION, "day": DailyRun.run_rooms,
		"score": int(float(DailyRun.run_score) / maxi(1, DailyRun.run_rooms)), "time": DailyRun.run_time,
		"difficulty": DailyRun.endless_start, "tier": int(round((DailyRun.level() - DailyRun.endless_start) * 4.0)),
		"hints": DailyRun.run_hints, "assist": DailyRoot.assist_mask()}
	code = DailyScore.encode(result)
	if kind == "over":
		var share := HBoxContainer.new()
		share.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(share)
		share.add_child(_line(code, 14))
		copy_button = _button("Copy", func():
			DisplayServer.clipboard_set(DailyScore.share_text(result, code))
			copy_button.text = "Copied")
		share.add_child(copy_button)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)
	if kind == "rest":
		keep_button = _button("Keep climbing", func():
			DailyRun.prepare_endless_room()
			_to(DailyRun.SCENE))
		leave_button = _button("Leave", func(): _to(DailyComplete.TITLE_SCENE))
		buttons.add_child(keep_button)
		buttons.add_child(leave_button)
	else:
		again_button = _button("Climb again", func():
			DailyRun.start_endless(DailyRun.endless_start, DailyRng.mix(Time.get_ticks_usec()))
			_to(DailyRun.SCENE))
		title_button = _button("Return to Title", func(): _to(DailyComplete.TITLE_SCENE))
		buttons.add_child(again_button)
		buttons.add_child(title_button)
	root.modulate.a = 0
	var fade := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade.tween_property(root, "modulate:a", 1.0, 0.8)
	fade.tween_callback(keep_button.grab_focus if kind == "rest" else title_button.grab_focus)

func _line(text: String, font_size := 16, color := DailyComplete.INK) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", Fonts.UI if font_size > 16 else Fonts.STORY)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 38)
	button.add_theme_font_override("font", Fonts.UI)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(func(): Sfx.play("ui_click"); action.call())
	return button

func _to(scene: String) -> void:
	if get_parent() is DailyRoot: get_parent()._transitioning = true
	get_tree().paused = false
	SceneFade.change(get_tree(), scene)
