class_name DailyMenu
extends CanvasLayer

## The Daily Puzzle screen, opened from the title: which day it is (and
## whether it can be ranked), today's result, the streak and its calendar, the
## board (you, the friends whose result codes you pasted, and a perfect run
## for reference) and the buttons to play, practise an earlier day, or start a
## random trial. Nothing here needs the network.

signal closed

const GOLD := Color("f0d27a")
const GOLD_DIM := Color("c9a24a")
const INK := Color("e8dcc0")
const DIM := Color("8a8092")
const DIFFICULTY_NAMES := ["Gentle", "Steady", "Hard", "Grand"]

## The difficulty the random trial uses (the button cycles it).
static var trial_difficulty := 2

## The day shown: today, or an earlier one to practise.
var day := 0
var play_button: Button
var endless_buttons: Array[Button] = []
var _endless_record: Label
var back_button: Button
var friend_name: LineEdit
var friend_code: LineEdit
var _root: Control
var _panel: PanelContainer
var _body: VBoxContainer
var _status: Label
var _canvas_size := Vector2i.ZERO


static func open(host: Node) -> DailyMenu:
	var menu := DailyMenu.new()
	host.add_child(menu)
	menu._build()
	return menu


func _build() -> void:
	_canvas_size = get_tree().root.content_scale_size
	get_tree().root.content_scale_size = Vector2i.ZERO
	layer = 4
	process_mode = Node.PROCESS_MODE_ALWAYS
	DailyStore.note_today()
	DailyStore.import_friends_file()
	day = DailyStore.today()
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.01, 0.05, 0.88)
	_root.add_child(dim)
	_rebuild()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	closed.emit()
	queue_free()


func _exit_tree() -> void:
	get_tree().root.content_scale_size = _canvas_size


## (Re)builds the card for `day`.
func _rebuild() -> void:
	if is_instance_valid(_panel):
		_panel.queue_free()
	var compact := get_viewport().get_visible_rect().size.x < 900
	var card := PanelContainer.new()
	_panel = card
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.custom_minimum_size = Vector2(880, 0) if not compact else Vector2.ZERO
	_root.add_child(card)
	DungeonUI.decorate(card)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 8)
	if compact:
		card.set_anchors_preset(Control.PRESET_FULL_RECT)
		card.offset_left = 16
		card.offset_right = -16
		card.offset_top = 16
		card.offset_bottom = -16
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus = true
		card.add_child(scroll)
		_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(_body)
	else:
		card.add_child(_body)

	var today := DailyStore.today()
	var clock := DailyStore.clock_status()
	var ranked_today := clock == "ok" and day == today
	var difficulty := DailyGenerator.difficulty_for_day(day)
	var result := DailyStore.result_for(day)

	_body.add_child(_label("Daily Puzzle", Fonts.TITLE, 32 if compact else 46, GOLD, HORIZONTAL_ALIGNMENT_CENTER))
	var date_row := HBoxContainer.new()
	date_row.alignment = BoxContainer.ALIGNMENT_CENTER
	date_row.add_theme_constant_override("separation", 14)
	_body.add_child(date_row)
	var prev := _small_button("<", func(): _go_day(day - 1))
	prev.disabled = day <= 0
	date_row.add_child(prev)
	date_row.add_child(_label("%s  ·  %s" % [DailyRng.label_of(day), DIFFICULTY_NAMES[difficulty - 1]], Fonts.UI, 16, INK))
	var next := _small_button(">", func(): _go_day(day + 1))
	next.disabled = day >= today
	date_row.add_child(next)
	_body.add_child(DungeonUI.divider(520.0))

	var columns: BoxContainer = VBoxContainer.new() if compact else HBoxContainer.new()
	columns.add_theme_constant_override("separation", 36)
	_body.add_child(columns)

	# ---- left: status, streak, buttons
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(400, 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	columns.add_child(left)
	if clock == "too_early":
		_status = _label("This device's clock looks wrong (it is earlier than this game). Practice is open; the daily needs the right date.", Fonts.STORY, 16, Color("b23a48"))
		_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left.add_child(_status)
	elif clock == "rewound":
		_status = _label("The clock has gone backwards, so today can't be ranked. Practice is open.", Fonts.STORY, 16, Color("b23a48"))
		_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		left.add_child(_status)
	if not result.is_empty():
		var seconds := int(round(float(result["time"])))
		left.add_child(_label("Solved: %d points, %d:%02d" % [int(result["score"]), seconds / 60, seconds % 60], Fonts.STORY, 16, GOLD))
		var stars := DailyComplete.StarRow.new()
		stars.count = int(result["stars"])
		stars.custom_minimum_size = Vector2(150, 36)
		left.add_child(stars)
	else:
		var text := "Not played yet." if day == today else "Not played that day."
		left.add_child(_label(text, Fonts.STORY, 16, DIM))
	var streak := DailyStore.current_streak()
	left.add_child(_label("Streak: %d day%s   (best %d)" % [streak, "" if streak == 1 else "s", DailyStore.best_streak], Fonts.STORY, 16, GOLD_DIM))
	var strip := StreakStrip.new()
	strip.today = today
	strip.custom_minimum_size = Vector2(380, 26)
	left.add_child(strip)
	if DailyStore.mend_ready():
		left.add_child(_label("A missed day will be forgiven once this week.", Fonts.STORY, 14, DIM))

	var label_text := "Play today's puzzle"
	if day != today:
		label_text = "Practise this day"
	elif not result.is_empty():
		label_text = "Practise today's puzzle"
	elif not ranked_today:
		label_text = "Practise today's puzzle"
	play_button = _button(label_text, func(): _play(ranked_today and result.is_empty()))
	left.add_child(play_button)
	left.add_child(_label("ENDLESS", Fonts.UI, 16, DIM))
	var endless_row := HBoxContainer.new()
	endless_row.add_theme_constant_override("separation", 6)
	left.add_child(endless_row)
	endless_buttons.clear()
	for i in 4:
		var start: int = i + 1
		var button := _small_button(DIFFICULTY_NAMES[i], func(): _endless(start))
		button.custom_minimum_size = Vector2(96, 36)
		endless_row.add_child(button)
		endless_buttons.append(button)
		button.focus_entered.connect(func(): _show_endless_record(start))
		button.mouse_entered.connect(func(): _show_endless_record(start))
	_endless_record = _label("No Endless run yet.", Fonts.STORY, 14, DIM)
	left.add_child(_endless_record)
	var overall := 2
	var most_rooms := -1
	var best_score := -1
	for start in range(1,5):
		var best := DailyStore.endless_best_for(start)
		if int(best.get("rooms", -1)) > most_rooms or (int(best.get("rooms", -1)) == most_rooms and int(best.get("score", -1)) > best_score):
			overall = start
			most_rooms = int(best.get("rooms", -1))
			best_score = int(best.get("score", -1))
	_show_endless_record(overall)

	# ---- right: the board
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(400, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	columns.add_child(right)
	right.add_child(_label("THE BOARD, %s" % DailyRng.label_of(day), Fonts.UI, 16, DIM))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 3)
	right.add_child(grid)
	var rows := DailyStore.board_for(day)
	for row in rows:
		var c: Color = GOLD if row["you"] else INK
		var seconds := int(round(float(row["time"])))
		grid.add_child(_label(String(row["name"]), Fonts.STORY, 16, c, HORIZONTAL_ALIGNMENT_LEFT))
		grid.add_child(_label("%d" % int(row["score"]), Fonts.STORY, 16, c, HORIZONTAL_ALIGNMENT_RIGHT))
		grid.add_child(_label("%d:%02d" % [seconds / 60, seconds % 60], Fonts.STORY, 16, DIM, HORIZONTAL_ALIGNMENT_RIGHT))
	grid.add_child(_label("A perfect run", Fonts.STORY, 16, GOLD_DIM, HORIZONTAL_ALIGNMENT_LEFT))
	grid.add_child(_label("1000", Fonts.STORY, 16, GOLD_DIM, HORIZONTAL_ALIGNMENT_RIGHT))
	grid.add_child(_label("", Fonts.STORY, 16, DIM))
	if rows.is_empty():
		right.add_child(_label("Solve it, then paste friends' codes to compare.", Fonts.STORY, 14, DIM))
	if Settings.handheld:
		right.add_child(_label("To add friends, put lines of \"Name CODE\" in friends.txt in the game's save folder.", Fonts.STORY, 14, DIM))
	else:
		right.add_child(_label("Add a friend's result", Fonts.UI, 16, DIM))
		var entry := HBoxContainer.new()
		entry.add_theme_constant_override("separation", 6)
		right.add_child(entry)
		friend_name = LineEdit.new()
		friend_name.placeholder_text = "Name"
		friend_name.custom_minimum_size = Vector2(110, 32)
		friend_name.max_length = DailyStore.MAX_NAME
		entry.add_child(friend_name)
		friend_code = LineEdit.new()
		friend_code.placeholder_text = "SB1-..."
		friend_code.custom_minimum_size = Vector2(190, 32)
		entry.add_child(friend_code)
		entry.add_child(_small_button("Add", _add_friend))

	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	_body.add_child(foot)
	back_button = _button("Back", _close)
	foot.add_child(back_button)
	for i in endless_buttons.size():
		var button := endless_buttons[i]
		button.focus_neighbor_top = button.get_path_to(play_button)
		button.focus_neighbor_bottom = button.get_path_to(back_button)
		if i > 0:
			button.focus_neighbor_left = button.get_path_to(endless_buttons[i - 1])
		if i < 3:
			button.focus_neighbor_right = button.get_path_to(endless_buttons[i + 1])
	play_button.focus_neighbor_bottom = play_button.get_path_to(endless_buttons[0])
	back_button.focus_neighbor_top = back_button.get_path_to(endless_buttons[0])
	play_button.grab_focus.call_deferred()


func _label(text: String, font: Font, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(300, 40)
	b.add_theme_font_override("font", Fonts.UI)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(func(): Sfx.play("ui_click"); on_press.call())
	return b


func _small_button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(40, 32)
	b.add_theme_font_override("font", Fonts.UI)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(func(): Sfx.play("ui_click"); on_press.call())
	return b


func _go_day(new_day: int) -> void:
	day = clampi(new_day, 0, DailyStore.today())
	_rebuild()


## Starts the puzzle of the shown day: ranked if it is today, the clock is
## right and it hasn't been solved yet; otherwise practice.
func _play(ranked: bool) -> void:
	var difficulty := DailyGenerator.difficulty_for_day(day)
	DailyRun.start("daily" if ranked else "practice", DailyGenerator.seed_for_day(day), day, difficulty,
		DailyGenerator.tier_for_difficulty(difficulty))
	SceneFade.change(get_tree(), DailyRun.SCENE)


func _trial() -> void:
	var seed_value := DailyRng.mix(Time.get_ticks_usec())
	DailyRun.start("trial", seed_value, 0, trial_difficulty, DailyGenerator.tier_for_difficulty(trial_difficulty))
	SceneFade.change(get_tree(), DailyRun.SCENE)


func _add_friend() -> void:
	var problem := DailyStore.add_friend(friend_name.text, friend_code.text)
	if problem != "":
		friend_code.text = ""
		friend_code.placeholder_text = problem
		return
	# Show the friend's day, so the new row is visible
	var added := DailyScore.decode(friend_code.text)
	if not added.is_empty():
		day = clampi(int(added["day"]), 0, DailyStore.today())
	_rebuild()


## The last two weeks as a row of squares: gold = solved, dark = not, ringed
## = today.
class StreakStrip extends Control:
	var today := 0

	func _draw() -> void:
		for i in 14:
			var d := today - 13 + i
			var rect := Rect2(i * 27.0, 3.0, 22.0, 20.0)
			var solved := DailyStore.has_ranked(d)
			draw_rect(rect, Color("f0d27a") if solved else Color("2a2630"))
			draw_rect(rect, Color("c9a24a") if solved else Color("4a4250"), false, 1.0)
			if d == today:
				draw_rect(rect.grow(2.0), Color("e8dcc0"), false, 1.5)


func _endless(start: int) -> void:
	DailyRun.start_endless(start, DailyRng.mix(Time.get_ticks_usec()))
	SceneFade.change(get_tree(), DailyRun.SCENE)


func _show_endless_record(start: int) -> void:
	var best := DailyStore.endless_best_for(start)
	_endless_record.text = "No Endless run yet." if best.is_empty() else "Best: %s, %d rooms, %d points" % [DIFFICULTY_NAMES[start - 1], int(best["rooms"]), int(best["score"])]
