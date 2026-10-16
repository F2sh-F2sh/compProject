extends Node

## Input-driven regression of the new story route; real saves are disabled
## by run_tests.gd. Screenshots are visual evidence, not human playtesting.
const COTTAGE := "res://scenes/story/nan_lantern_cottage.tscn"
const APPROACH := "res://scenes/story/pilgrims_path.tscn"
const WELL := "res://scenes/story/well_descent.tscn"
var passed := 0
var failed := 0
var lvl: Node

func check(label: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("  PASS ", label)
	else:
		failed += 1
		print("  FAIL ", label)

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func open_scene(path: String) -> void:
	get_tree().paused = false
	if get_tree().current_scene:
		get_tree().current_scene.queue_free()
	await get_tree().process_frame
	lvl = load(path).instantiate()
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	await frames(65)

func wait_for(path: String) -> bool:
	for i in 240:
		if get_tree().current_scene and get_tree().current_scene.scene_file_path == path:
			lvl = get_tree().current_scene
			await frames(65)
			return true
		await frames(1)
	return false

func press(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await frames(15)

func finish_dialogue() -> void:
	for i in 20:
		if not lvl.dialogue.active:
			break
		await press("interact")

func walk_to(x: float, jumping := false) -> bool:
	var player: CharacterBody2D = lvl.player
	for i in 1200:
		var dx := x - player.position.x
		if absf(dx) < 7:
			Input.action_release("move_left")
			Input.action_release("move_right")
			Input.action_release("jump")
			await frames(12)
			return true
		Input.action_press("move_right" if dx > 0 else "move_left")
		Input.action_release("move_left" if dx > 0 else "move_right")
		if jumping and player.is_on_floor() and i % 24 == 0:
			Input.action_press("jump")
		else:
			Input.action_release("jump")
		await frames(1)
	Input.action_release("move_left")
	Input.action_release("move_right")
	Input.action_release("jump")
	print("  WALK TIMEOUT x=", player.position.x, " target=", x, " locked=", player.controls_locked, " dialogue=", lvl.dialogue.active, " velocity=", player.velocity)
	return false

func shot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("res://.godot/prologue_shots/")
	DirAccess.make_dir_recursive_absolute(directory)
	get_tree().root.get_texture().get_image().save_png(directory + name + ".png")

func run_suite(filter: String) -> void:
	get_tree().root.set_size(Vector2i(1152, 648))
	get_tree().root.get_node("Settings").reduce_motion = false
	await frames(5)
	var state := get_tree().root.get_node("GameState")
	state.clear_all()
	await open_scene(COTTAGE)
	check("Nan's conversation freezes movement", lvl.dialogue.active and lvl.player.controls_locked)
	await frames(100)
	await shot("01_nan")
	get_tree().root.set_size(Vector2i(800, 600))
	await frames(20)
	await shot("01_nan_small_window")
	var rect: Rect2 = lvl.dialogue._panel.get_global_rect()
	# canvas_items stretching keeps a logical viewport larger than the
	# physical window. Compare in canvas coordinates, as the panel does.
	var viewport_size := get_viewport().get_visible_rect().size
	check("dialogue stays inside a smaller window", rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= viewport_size.x + 1 and rect.end.y <= viewport_size.y + 1)
	get_tree().root.set_size(Vector2i(1152, 648))
	await frames(15)
	await finish_dialogue()
	check("finishing dialogue grants the lantern and restores control", state.has_flag("story.nan_lantern") and not lvl.player.controls_locked)
	check("the cottage door is reachable with the original controller", await walk_to(792))
	await press("interact")
	check("the cottage door opens the pilgrim road", await wait_for(APPROACH))
	await finish_dialogue()
	check("the winch is reachable", await walk_to(726))
	await shot("02_bridge_before")
	await press("interact")
	await frames(100)
	check("the bridge lowers and becomes solid", lvl.bridge_open and lvl._bridge_body.collision_layer == 2)
	check("crossing the bridge works without a jump", await walk_to(1140))
	await shot("03_bridge_after")
	check("the ruined stairs can be crossed with normal jumps", await walk_to(1675, true))
	await press("interact")
	check("reading the seal explains the alternate entrance", lvl.dialogue.active)
	await frames(45)
	check("Echidna lands naturally if a conversation starts during a jump", lvl.player.is_on_floor())
	await shot("04_belfry")
	await finish_dialogue()
	check("the well is unlocked by reading the door", state.has_flag("story.belfry_read") and lvl._exit.enabled)
	check("the eastern well is reachable", await walk_to(2180))
	await press("interact")
	await finish_dialogue()
	check("the well leads to a new playable passage", await wait_for(WELL))
	await finish_dialogue()
	await shot("05_well")
	check("first lamp is reachable", await walk_to(420))
	await press("interact")
	check("first lamp alone leaves the ward closed", lvl.sconces_lit == 1 and lvl._gate.collision_layer == 2)
	await open_scene(WELL)
	await finish_dialogue()
	check("Continue restores partial lamp progress and its objective", lvl.sconces_lit == 1 and lvl.objective.text.contains("1 / 2") and lvl._gate.collision_layer == 2)
	check("second lamp is reachable by the descending path", await walk_to(1050))
	await press("interact")
	check("both lamps open the ward", lvl.sconces_lit == 2 and lvl._gate.collision_layer == 0 and lvl._exit.enabled)
	await shot("06_lamps")
	check("the Undercroft entrance is reachable", await walk_to(1855))
	await press("interact")
	await shot("07_undercroft")
	await finish_dialogue()
	check("new players enter the movement-only tutorial", await wait_for("res://scenes/tutorial/tutorial_movement.tscn"))
	# Continue restores world changes, and experienced players keep their
	# tutorial completion and take the same story route into Chapter 1.
	state.set_flag("tutorial.done")
	await open_scene(WELL)
	await finish_dialogue()
	check("Continue restores the two flames and the open ward", lvl.sconces_lit == 2 and lvl._exit.enabled)
	check("Continue restores the last landing", lvl.player.position.x >= 1260)
	check("revisited entrance is reachable", await walk_to(1855))
	await press("interact")
	# Skipping must run the same transition and unlock logic as reading.
	lvl.dialogue.complete()
	check("experienced players go to Chapter 1", await wait_for("res://scenes/chapter/chapter_1.tscn"))
	await open_scene(APPROACH)
	lvl.dialogue.complete()
	check("Continue restores the lowered bridge", lvl.bridge_open and lvl._bridge_body.collision_layer == 2)
	lvl.player.teleport_to(Vector2(930, 640))
	await frames(70)
	check("a missed bridge recovers safely with no health loss", lvl.player.position.y < 550 and not lvl.player.controls_locked and lvl.player.current_health == 10)
	# Backtracking after missing a lamp needs only ordinary jumps.
	state.clear_all()
	await open_scene(WELL)
	lvl.dialogue.complete()
	check("walk down to the second landing", await walk_to(800))
	check("backtrack to the first lamp without a charged jump", await walk_to(420, true))
	# Holding Escape owns the conversation; the existing pause menu must
	# not steal it. A skipped cottage still hands over Nan's lantern.
	await open_scene(COTTAGE)
	await press("pause")
	Input.action_press("pause")
	await frames(65)
	Input.action_release("pause")
	await frames(5)
	check("holding Escape skips and grants the lantern", not lvl.dialogue.active and state.has_flag("story.nan_lantern") and not lvl.player.controls_locked)
	await open_scene(APPROACH)
	await press("ui_accept")
	check("controller confirm advances the conversation", lvl.dialogue.index == 1)
	lvl.dialogue.complete()
	await frames(10)
	await press("pause")
	check("Escape still opens the normal pause menu during play", get_tree().paused)
	await press("pause")
	check("closing pause returns to the road", not get_tree().paused and not lvl.player.controls_locked)
	# Test the original completion card's real Continue signal, not just
	# opening the new cinematic by its path.
	await open_scene("res://scenes/chapter/chapter_1.tscn")
	# Exercise the preserved legacy completion route explicitly. The main
	# journey's expanded interlude-before-card flow is covered by chapter_suite.
	lvl.next_chapter = "res://scenes/chapter/chapter_2.tscn"
	lvl.finish_chapter()
	var card := lvl.find_children("*", "ChapterComplete", true, false)
	check("the original completion card remains available", not card.is_empty())
	card[0].continue_button.pressed.emit()
	check("Chapter 1 Continue plays the bell aftermath", await wait_for("res://scenes/story/bell_aftermath.tscn"))
	await frames(30)
	await shot("08_bell_echo")
	await press("interact")
	await frames(30)
	await shot("09_lowbell_remembers")
	check("the cinematic changes to Lowbell when the chimes answer", lvl._picture == 1)
	await finish_dialogue()
	check("the bell aftermath leads to the existing Observatory", await wait_for("res://scenes/chapter/chapter_2.tscn"))
	check("the bell aftermath is remembered", state.has_flag("story.bell_echo_seen"))
	get_tree().paused = false
	print("prologue suite: passed=%d failed=%d" % [passed, failed])
