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
## What this stretch of the game is called in the menus: "chapter", "level"
## (the Novices' Way: Level 1 is the tutorial, the Belfry Level 2, the
## Observatory Level 3) or "wing". The end card's heading follows it
## ("LEVEL 2 COMPLETE").
@export var unit_name := "chapter"
@export var complete_heading := "CHAPTER COMPLETE"
@export var next_label := "Continue to the next chapter"
@export var closing_line := "The next chapter is still being written."
## Rune words the end of this stretch teaches (a wing's bell), saved when it is finished.
@export var grants_words: PackedStringArray = []
@export var total_pages := 0
## The scene the Chapter Complete card offers to continue to ("" = none yet).
@export_file("*.tscn") var next_chapter := ""
## Every lore page in order ({id, numeral, title, text, room}), for the
## Ledger in the pause menu. Written by the chapter builder.
@export var ledger: Array[Dictionary] = []

const BODY_FONT := Fonts.STORY

var player: CharacterBody2D
var camera: CameraBounds
var rooms: Array[Node] = []
var current_room: Room
var is_resetting := false

## Seconds in a room without progress (or deaths there) before its hint
## stone starts calling out, when guidance is on.
const NUDGE_AFTER := 300.0
const NUDGE_DEATHS := 4

var _fade: ColorRect
var _title: Label
var _toast_panel: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _title_tween: Tween
var _objective: ObjectivePanel
## Why the current room can't be finished any more ("" while it can).
var broken_reason := ""
var _broken_panel: PanelContainer
## The banner has something to say but is waiting for a title to clear.
var _broken_waiting := false
var _broken_label: Label
var _since_progress := 0.0
var _nudged := false
var _mood_tween: Tween
## The rooms from left to right, and the furthest one she has come into since
## the level loaded: the way back into each room before it is shut behind her.
var _rooms_in_order: Array = []
var _furthest := -1
## Every gate and door between rooms (and in them), for sealing the way back.
var _gates: Array = []


func _ready() -> void:
	add_to_group("chapter_root")
	# A card still waiting for pictures that never played is stale now
	ChapterComplete.pending = {}
	player = get_node("Player")
	camera = player.get_node("Camera2D")
	rooms = get_tree().get_nodes_in_group("room")
	_build_ui()
	# off-screen targets get a pip on the screen's edge (fair aiming)
	var pips := TargetPips.new()
	pips.name = "TargetPips"
	add_child(pips)
	# the room-broken banner names the pause key for the device in use
	InputLabels.watch(self, func(): if _broken_label and broken_reason != "": _broken_label.text = broken_text(broken_reason))
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
	# (admin, for testing: start in the room chosen on the title's admin page)
	if Journey.admin_start_room != "":
		var start := get_node_or_null(Journey.admin_start_room) as Room
		Journey.admin_start_room = ""
		if start:
			player.global_position = start.entry_spawn
	_rooms_in_order = rooms.duplicate()
	_rooms_in_order.sort_custom(func(a, b): return a.bounds.position.x < b.bounds.position.x)
	for node in find_children("*", "", true, false):
		if node is PortcullisGate or node is ForgeDoor:
			_gates.append(node)
	_update_room(true)
	_set_up_ways_back()
	# (she starts at a shrine or a chosen room: drawn there, not slid there)
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	_update_room(false)
	if current_room == null:
		return
	_update_steps(false)
	_check_broken()
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
	var post := get_node_or_null("PostFX") as PostFX
	if post:
		post.set_room_ambient(room.mood_ambient, instant)
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


## The chapter's ending (the great bell has rung): saves it as complete and
## logs the run. If story pictures follow, they play straight away and the
## card with the run's numbers (Continue / Return to Title) comes after them,
## so nobody misses the story by choosing the title; otherwise the card shows
## here.
func finish_chapter() -> void:
	GameState.set_flag(chapter_id + ".complete")
	Journey.teach_words(Array(grants_words))
	var stats := {
		"time": GameState.get_stat(_stat("time")),
		"deaths": GameState.get_stat(_stat("deaths")),
		"resets": GameState.get_stat(_stat("resets")),
		"hints": GameState.get_stat(_stat("hints")),
		"pages": pages_found(),
		"total_pages": total_pages,
		"next": next_chapter,
		"heading": complete_heading,
		"next_label": next_label,
		"closing": closing_line,
	}
	GameState.log_playtest(["chapter complete", "", snappedf(stats["time"], 0.1), stats["deaths"], stats["resets"],
		stats["hints"], "%d/%d" % [stats["pages"], total_pages]])
	# Continuing later starts the chapter from its beginning
	GameState.clear_checkpoint(scene_file_path)
	GameState.save_game()
	for node in get_tree().get_nodes_in_group("gameplay_ui"):
		node.visible = false
	if is_story_scene(next_chapter):
		ChapterComplete.pending = {"name": chapter_title, "stats": stats}
		player.lock_controls()
		var tween := create_tween()
		tween.tween_property(_fade, "color:a", 1.0, 0.9)
		tween.tween_callback(func(): SceneFade.change(get_tree(), next_chapter, 0.0))
		return
	ChapterComplete.open(self, chapter_title, stats)


## Story pictures (an interlude or an ending) rather than a playable level.
static func is_story_scene(path: String) -> bool:
	return path.begins_with("res://scenes/story/") and ResourceLoader.exists(path)


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
	# Further along than ever: the cage drops behind her, so it is clear she is
	# not meant to go back
	var order := _rooms_in_order.find(room)
	if order > _furthest:
		if _furthest >= 0:
			for i in range(_furthest + 1, order + 1):
				_seal_way_back(i, instant)
		_furthest = order
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
	var seen_id := "%s.seen.%s" % [chapter_id, room.room_id.get_slice(".", 1)]
	var seen_before := GameState.has_flag(seen_id)
	GameState.set_flag(seen_id)
	if not seen_before and not room.glance_at.is_empty():
		_glance_at(room)
	var first_visit := not room.visited
	room.visited = true
	var title_delay := 0.0
	if first_visit and room.act != "":
		TitleCard.show_card(self, "ACT %s" % room.act, room.act_title, room.act_subtitle, 2.2)
		# The room's name takes the same spot once the act card has gone
		title_delay = 3.8
	if first_visit and room.title != "":
		show_room_title(room.title, title_delay)
	if first_visit and room.explainer != "" and (room.explainer != "objective" or Settings.guidance >= Settings.GUIDANCE_LIGHT):
		UiTour.play_later(self, room.explainer, title_delay + 3.6)
	if _objective:
		_objective.visible = Settings.guidance >= Settings.GUIDANCE_LIGHT
		if _objective.visible:
			_objective.show_room(room.objective, room.get_steps())
	room_entered.emit(room)


## Once the level's walls are in the physics world: gates for the open
## doorways, and (coming back in on a reload or Continue) the ways back from
## the room she starts in shut already; the rooms ahead of it stay open.
func _set_up_ways_back() -> void:
	await get_tree().physics_frame
	_add_back_gates()
	for i in range(1, _furthest + 1):
		_seal_way_back(i, true)


## Where the way from room i-1 into room i is: the wall column they share.
func _way_in_x(i: int) -> float:
	return (_rooms_in_order[i] as Room).bounds.position.x + 32.0


## The gates and doors standing in the way into room i.
func _gates_into(i: int) -> Array:
	var x := _way_in_x(i)
	return _gates.filter(func(g): return is_instance_valid(g) and absf(g.global_position.x - x) <= 40.0)


## Shuts the way from room i-1 into room i for good.
func _seal_way_back(i: int, instant: bool) -> void:
	for gate in _gates_into(i):
		gate.seal(instant)


## Where two rooms meet at an open doorway with nothing to close it, an iron
## gate (raised, open) is set in it, ready to drop behind her.
func _add_back_gates() -> void:
	var space := get_world_2d().direct_space_state
	for i in range(1, _rooms_in_order.size()):
		if not _gates_into(i).is_empty():
			continue
		var x := _way_in_x(i)
		var room := _rooms_in_order[i] as Room
		# The doorway: open air low in the wall, a floor under it, a lintel above
		var probe := PhysicsPointQueryParameters2D.new()
		probe.position = Vector2(x, 470.0)
		probe.collision_mask = 2
		if not space.intersect_point(probe, 1).is_empty():
			continue
		var down := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, 470.0), Vector2(x, room.bounds.end.y + 64.0), 2))
		var up := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(x, 470.0), Vector2(x, room.bounds.position.y - 64.0), 2))
		if down.is_empty() or up.is_empty():
			continue
		var floor_y: float = down["position"].y
		var gate := preload("res://scenes/portcullis_gate.tscn").instantiate() as PortcullisGate
		gate.name = "BackGate"
		gate.height = floor_y - float(up["position"].y)
		gate.start_open = true
		gate.position = room.to_local(Vector2(x, floor_y))
		room.add_child(gate)
		_gates.append(gate)


## The first time ever in a room that has a `glance_at`, the camera looks at
## that node for a moment (once the title cards have cleared a little).
func _glance_at(room: Room) -> void:
	var target := room.get_node_or_null(room.glance_at) as Node2D
	if target == null:
		return
	get_tree().create_timer(1.2).timeout.connect(func():
		if current_room == room and not player.is_dead and is_instance_valid(target):
			if player_is_safe(true):
				camera.focus_on(target.global_position + Vector2(0, -24), 1.8))


## When something the room's puzzle needs is gone (Room.broken_reason), a
## banner says the room can't be finished now and how to reset it, and the
## Esc menu opens straight on Reset Room until it is fixed.
func _check_broken() -> void:
	var why := ""
	if current_room and not is_resetting and not player.is_dead:
		why = current_room.broken_reason()
	if why == broken_reason:
		if _broken_waiting and not _top_busy():
			_show_broken_banner()
		return
	broken_reason = why
	PauseMenu.reset_suggested = why != ""
	PauseMenu.reset_reason = why
	if _broken_panel == null:
		return
	if why == "":
		_broken_waiting = false
		create_tween().tween_property(_broken_panel, "modulate:a", 0.0, 0.4)
		return
	_broken_label.text = broken_text(why)
	# It shares the top of the screen with the act card and the room's name:
	# it waits for them to clear rather than lie on top of them
	if _top_busy():
		_broken_waiting = true
		return
	_show_broken_banner()


func _show_broken_banner() -> void:
	_broken_waiting = false
	Sfx.play("rune_blocked", null, -2.0, 0.0)
	create_tween().tween_property(_broken_panel, "modulate:a", 1.0, 0.35)


## True while an act card or the room's name is up at the top of the screen.
func _top_busy() -> bool:
	return TitleCard.is_showing() or (_title_tween != null and _title_tween.is_valid() and _title_tween.is_running())


## The banner's words, with the player's own key for the menu.
static func broken_text(why: String) -> String:
	return InputLabels.format("THIS ROOM CAN'T BE FINISHED NOW\n%s\nReset the room: press {pause}, choose Map, then Reset Room." % why)


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
		player.teleport_to(reset_spawn(current_room))
		camera.cancel_focus()
		camera.bounds = current_room.bounds
		room_reset_done.emit(current_room)
		# (everything put back is drawn where it is now, not slid there)
		reset_physics_interpolation())
	tween.tween_interval(0.15)
	tween.tween_property(_fade, "color:a", 0.0, 0.3)
	tween.tween_callback(func():
		player.unlock_controls()
		is_resetting = false)


## Where Reset Room puts her: the room's way in, or in a long room that asks
## for it (Room.reset_at_shrine), the last shrine she lit inside it.
func reset_spawn(room: Room) -> Vector2:
	if room.reset_at_shrine:
		var id := GameState.get_checkpoint_for(scene_file_path)
		for checkpoint in get_tree().get_nodes_in_group("chapter_checkpoint"):
			if checkpoint.checkpoint_id == id and room.contains(checkpoint.global_position + Vector2(0, -8)):
				return checkpoint.get_spawn_position()
	return room.entry_spawn


## True if nothing dangerous is close to the player, so the camera may look away.
## (`ignore_warded`: caged, warded creatures do not count.)
func player_is_safe(ignore_warded := false) -> bool:
	if player.is_dead or player.controls_locked:
		return false
	for hazard in get_tree().get_nodes_in_group("hazard_zone"):
		if hazard.get_hazard_rect().grow(96.0).has_point(player.global_position):
			return false
	for enemy in get_tree().get_nodes_in_group("enemy") + get_tree().get_nodes_in_group("gargoyle"):
		if enemy is Node2D and enemy.global_position.distance_to(player.global_position) < 220.0:
			# (A warded creature in its cell can't reach anyone)
			if ignore_warded and enemy.get("warded") == true:
				continue
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

	var font: Font = Fonts.TITLE
	_title = Label.new()
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 92
	_title.offset_bottom = 150
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", font)
	_title.add_theme_font_size_override("font_size", 48)
	_title.add_theme_color_override("font_color", Color("f0d27a"))
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
	_toast_panel.add_theme_stylebox_override("panel", DungeonUI.style("panel", 24, Vector4(28, 18, 28, 18)))
	ui.add_child(_toast_panel)
	_toast_label = Label.new()
	_toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.custom_minimum_size = Vector2(560, 0)
	_toast_label.add_theme_font_override("font", BODY_FONT)
	_toast_label.add_theme_font_size_override("font_size", 16)
	_toast_label.add_theme_color_override("font_color", Color("e8dcc0"))
	_toast_panel.add_child(_toast_label)

	_objective = ObjectivePanel.new()
	_objective.add_to_group("gameplay_ui")
	ui.add_child(_objective)

	# "This room can't be finished now": top centre, clear of the HUD corners
	_broken_panel = PanelContainer.new()
	_broken_panel.name = "BrokenBanner"
	_broken_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_broken_panel.offset_left = -330
	_broken_panel.offset_right = 330
	_broken_panel.offset_top = 150
	_broken_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_broken_panel.modulate.a = 0.0
	_broken_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_broken_panel.add_theme_stylebox_override("panel", DungeonUI.style("panel", 24, Vector4(28, 18, 28, 18)))
	_broken_panel.self_modulate = Color(1.0, 0.72, 0.7)
	ui.add_child(_broken_panel)
	_broken_label = Label.new()
	_broken_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_broken_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_broken_label.custom_minimum_size = Vector2(620, 0)
	_broken_label.add_theme_font_override("font", BODY_FONT)
	_broken_label.add_theme_font_size_override("font_size", 16)
	_broken_label.add_theme_color_override("font_color", Color("ffe2dc"))
	_broken_panel.add_child(_broken_label)


func _exit_tree() -> void:
	# The Esc menu's "go to Reset Room" belongs to this level only
	PauseMenu.reset_suggested = false
	PauseMenu.reset_reason = ""
