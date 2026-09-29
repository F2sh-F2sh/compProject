class_name ChapterRoot
extends Node2D

## Root of a puzzle chapter. Tracks which Room the player is in (moving the
## camera between rooms), respawns the player at the last full checkpoint
## after a death, runs "Reset Room", and shows room titles and short messages.

## The player moved into another room.
signal room_entered(room: Room)
## Reset Room is about to put `room` back (spells should stop first).
signal room_resetting(room: Room)
## Reset Room has finished putting `room` back.
signal room_reset_done(room: Room)

## Prefix for this chapter's saved flags, e.g. "ch1".
@export var chapter_id := "ch1"
@export var chapter_title := "The Sealed Belfry"
@export var total_pages := 0
## The scene the Chapter Complete card offers to continue to ("" = none yet).
@export_file("*.tscn") var next_chapter := ""
## Every lore page in order ({id, numeral, title, text, room}), for the
## Ledger in the pause menu. Written by the chapter builder.
@export var ledger: Array[Dictionary] = []

const TITLE_FONT_NAMES := ["Cinzel", "Trajan Pro", "Times New Roman", "Georgia", "Liberation Serif", "serif"]
const BODY_FONT := preload("res://assets/Text/Orbitron-Bold.ttf")

var player: CharacterBody2D
var camera: CameraBounds
var rooms: Array[Node] = []
var current_room: Room
var is_resetting := false

## Seconds in a room without progress (or deaths there) before its hint
## stone starts calling out, when guidance is on.
const NUDGE_AFTER := 90.0
const NUDGE_DEATHS := 2

var _fade: ColorRect
var _title: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _title_tween: Tween
var _objective: ObjectivePanel
var _since_progress := 0.0
var _nudged := false
var _mood_tween: Tween


func _ready() -> void:
	add_to_group("chapter_root")
	player = get_node("Player")
	camera = player.get_node("Camera2D")
	rooms = get_tree().get_nodes_in_group("room")
	_build_ui()
	player.died.connect(func():
		GameState.add_stat(_stat("deaths"), 1)
		if current_room:
			GameState.bump(_room_key("deaths"))
		GameState.save_game())
	Settings.changed.connect(_on_settings_changed)

	var checkpoint_id := GameState.get_checkpoint_for(scene_file_path)
	if checkpoint_id != "":
		for checkpoint in get_tree().get_nodes_in_group("chapter_checkpoint"):
			if checkpoint.checkpoint_id == checkpoint_id:
				player.global_position = checkpoint.get_spawn_position()
				break
	_update_room(true)


func _physics_process(delta: float) -> void:
	_update_room(false)
	if current_room == null:
		return
	_update_steps(false)
	_since_progress += delta
	GameState.add_stat(_stat("time"), delta)
	GameState.add_stat(_stat("time." + _room_short()), delta)
	if not _nudged and Settings.guidance >= Settings.GUIDANCE_FULL and not current_room.is_cleared() \
			and (_since_progress > NUDGE_AFTER or int(GameState.session.get(_room_key("deaths"), 0)) >= NUDGE_DEATHS):
		_nudged = true
		for stone in current_room.find_children("*", "", true, false):
			if stone is HintStone:
				stone.nudge()


## Eases the post pass's colour grade toward the room's mood.
func _set_mood(room: Room, instant: bool) -> void:
	var screen := get_node_or_null("PostFX/Screen") as CanvasItem
	if screen == null or not screen.material is ShaderMaterial:
		return
	var mat := screen.material as ShaderMaterial
	if _mood_tween:
		_mood_tween.kill()
	if instant:
		mat.set_shader_parameter("highlight_tint", room.mood_highlight)
		mat.set_shader_parameter("fog_color", room.mood_fog)
		return
	var from_high: Color = mat.get_shader_parameter("highlight_tint")
	var from_fog: Color = mat.get_shader_parameter("fog_color")
	_mood_tween = create_tween()
	_mood_tween.tween_method(func(k: float):
		mat.set_shader_parameter("highlight_tint", from_high.lerp(room.mood_highlight, k))
		mat.set_shader_parameter("fog_color", from_fog.lerp(room.mood_fog, k)), 0.0, 1.0, 1.6)


func _on_settings_changed() -> void:
	if _objective == null or current_room == null:
		return
	var want := Settings.guidance >= Settings.GUIDANCE_LIGHT and current_room.objective != ""
	if want and not _objective.visible:
		_objective.show_room(current_room.objective, current_room.get_steps())
	_objective.visible = want


func _room_key(what: String) -> String:
	return "%s.%s" % [what, current_room.room_id]


func _room_short() -> String:
	return current_room.room_id.get_slice(".", 1)


func _stat(what: String) -> String:
	return "%s.stat.%s" % [chapter_id, what]


## The chapter's ending (the great bell has rung): saves it as complete,
## logs the run, and shows the Chapter Complete card.
func finish_chapter() -> void:
	GameState.set_flag(chapter_id + ".complete")
	var stats := {
		"time": GameState.get_stat(_stat("time")),
		"deaths": GameState.get_stat(_stat("deaths")),
		"resets": GameState.get_stat(_stat("resets")),
		"hints": GameState.get_stat(_stat("hints")),
		"pages": pages_found(),
		"total_pages": total_pages,
		"next": next_chapter,
	}
	GameState.log_playtest(["chapter complete", "", snappedf(stats["time"], 0.1), stats["deaths"], stats["resets"],
		stats["hints"], "%d/%d" % [stats["pages"], total_pages]])
	# Continuing later starts the chapter from its beginning
	GameState.clear_checkpoint(scene_file_path)
	GameState.save_game()
	for node in get_tree().get_nodes_in_group("gameplay_ui"):
		node.visible = false
	ChapterComplete.open(self, chapter_title, stats)


## A hint stone gave a hint (counted for the run's statistics).
func note_hint() -> void:
	GameState.add_stat(_stat("hints"), 1)
	if current_room:
		GameState.bump(_room_key("hints"))


func _log_room_clear() -> void:
	GameState.log_playtest(["room cleared", current_room.title,
		snappedf(GameState.get_stat(_stat("time." + _room_short())), 0.1),
		GameState.session.get(_room_key("deaths"), 0), GameState.session.get(_room_key("resets"), 0),
		GameState.session.get(_room_key("hints"), 0), ""])


## Checks the current room's steps; announces each one as it is done.
func _update_steps(silent: bool) -> void:
	for step in current_room.get_steps():
		if step.update(player):
			_since_progress = 0.0
			if silent:
				continue
			if _objective:
				_objective.step_done(step)
			if current_room.is_cleared() and not GameState.has_flag("%s.clear.%s" % [chapter_id, _room_short()]):
				GameState.set_flag("%s.clear.%s" % [chapter_id, _room_short()])
				_log_room_clear()
				# A short chord and a nudge of the camera: the room is done
				Sfx.play("room_clear", null, -5.0, 0.0)
				ImpactFX.kick(get_tree(), 1.0, 0.2)
			else:
				Sfx.play("receiver_on", null, -12.0)
	if _objective:
		_objective.refresh()


func _update_room(instant: bool) -> void:
	var p := player.global_position
	if current_room and current_room.contains(p):
		return
	for room in rooms:
		if room.contains(p):
			_enter(room, instant)
			return


func _enter(room: Room, instant: bool) -> void:
	current_room = room
	AudioDirector.set_combat(self, room.combat)
	if instant:
		camera.bounds = room.bounds
	else:
		camera.set_bounds_smooth(room.bounds)
	_since_progress = 0.0
	_nudged = false
	_set_mood(room, instant)
	# Run statistics are written out as each room is entered
	GameState.save_game()
	# Steps already done (saved puzzles) count at once, without fanfare
	_update_steps(true)
	GameState.set_flag("%s.seen.%s" % [chapter_id, room.room_id.get_slice(".", 1)])
	var first_visit := not room.visited
	room.visited = true
	var title_delay := 0.0
	if first_visit and room.act != "":
		TitleCard.show_card(self, "ACT %s" % room.act, room.act_title, room.act_subtitle, 2.2)
		# The room's name takes the same spot once the act card has gone
		title_delay = 3.8
	if first_visit and room.title != "":
		show_room_title(room.title, title_delay)
	if _objective:
		_objective.visible = Settings.guidance >= Settings.GUIDANCE_LIGHT
		if _objective.visible:
			_objective.show_room(room.objective, room.get_steps())
	room_entered.emit(room)


## Puts the current room back to a known solvable arrangement. Health is kept.
func reset_current_room() -> void:
	if current_room == null or is_resetting or player.is_dead:
		return
	is_resetting = true
	GameState.add_stat(_stat("resets"), 1)
	GameState.bump(_room_key("resets"))
	player.lock_controls(true)
	var recorder := player.get_node_or_null("EchoRecorder")
	room_resetting.emit(current_room)
	Sfx.play("room_reset")
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.25)
	tween.tween_callback(func():
		if recorder:
			recorder.cancel_recording()
			recorder.clear_echoes()
		current_room.reset()
		player.teleport_to(current_room.entry_spawn)
		camera.cancel_focus()
		camera.bounds = current_room.bounds
		room_reset_done.emit(current_room))
	tween.tween_interval(0.15)
	tween.tween_property(_fade, "color:a", 0.0, 0.3)
	tween.tween_callback(func():
		player.unlock_controls()
		is_resetting = false)


## True if nothing dangerous is close to the player, so the camera may look away.
func player_is_safe() -> bool:
	if player.is_dead or player.controls_locked:
		return false
	for hazard in get_tree().get_nodes_in_group("hazard_zone"):
		if hazard.get_hazard_rect().grow(96.0).has_point(player.global_position):
			return false
	for enemy in get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("gargoyle"):
		if enemy is Node2D and enemy.global_position.distance_to(player.global_position) < 220.0:
			if enemy.get("is_frozen") == true:
				continue
			if enemy.has_method("is_threatening") and not enemy.is_threatening():
				continue
			return false
	return true


## Briefly shows a distant mechanism, but only when the player is out of danger.
func show_mechanism(world_point: Vector2, hold := 1.0) -> void:
	if player_is_safe():
		camera.focus_on(world_point, hold)


func pages_found() -> int:
	return GameState.count_flags(chapter_id + ".page.")


func show_room_title(text: String, delay := 0.0) -> void:
	_title.text = text
	if _title_tween:
		_title_tween.kill()
	_title_tween = create_tween()
	if delay > 0.0:
		_title.modulate.a = 0.0
		_title_tween.tween_interval(delay)
	_title_tween.tween_property(_title, "modulate:a", 1.0, 0.8)
	_title_tween.tween_interval(2.2)
	_title_tween.tween_property(_title, "modulate:a", 0.0, 1.0)


func show_toast(text: String, seconds := 5.0) -> void:
	_toast_label.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast_panel, "modulate:a", 1.0, 0.3)
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.6)


func _build_ui() -> void:
	# Fade sits under the HUD; messages sit above it
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 1
	add_child(fade_layer)
	move_child(fade_layer, 0)
	_fade = ColorRect.new()
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.color = Color(0.02, 0.01, 0.05, 0.0)
	fade_layer.add_child(_fade)

	var ui := CanvasLayer.new()
	ui.layer = 3
	add_child(ui)

	var font := SystemFont.new()
	font.font_names = PackedStringArray(TITLE_FONT_NAMES)
	_title = Label.new()
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 92
	_title.offset_bottom = 150
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", font)
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", Color("cbbdf2"))
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_title.add_theme_constant_override("outline_size", 8)
	_title.modulate.a = 0.0
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_title)

	_toast_panel = PanelContainer.new()
	_toast_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	# Along the bottom edge, below the floor the player stands on
	_toast_panel.offset_left = -300
	_toast_panel.offset_right = 300
	_toast_panel.offset_top = -74
	_toast_panel.offset_bottom = -14
	_toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast_panel.modulate.a = 0.0
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.035, 0.09, 0.9)
	style.border_color = Color(0.5, 0.38, 0.78, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_toast_panel.add_theme_stylebox_override("panel", style)
	ui.add_child(_toast_panel)
	_toast_label = Label.new()
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.custom_minimum_size = Vector2(560, 0)
	_toast_label.add_theme_font_override("font", BODY_FONT)
	_toast_label.add_theme_font_size_override("font_size", 16)
	_toast_label.add_theme_color_override("font_color", Color("e4ddf2"))
	_toast_panel.add_child(_toast_label)

	_objective = ObjectivePanel.new()
	_objective.add_to_group("gameplay_ui")
	ui.add_child(_objective)
