extends Node

## Tests for the game around the levels: the title screen and its menu, the
## story intro, continuing a save, the Ledger and the page reader, run
## statistics, and robustness against damaged save and settings files.
## Run through tests/run_tests.gd:  -- experience [scenario]

const TITLE := "res://scenes/ui/title_screen.tscn"
const TUTORIAL := "res://scenes/tutorial_level.tscn"
const CHAPTER := "res://scenes/chapter/chapter_1.tscn"
const SHOTS := "user://test_shots/"
const DT := 1.0 / 60.0

var lvl: Node
var passed := 0
var failed := 0


func run_suite(filter: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS))
	await get_tree().process_frame
	var scenarios := {
		"title": scenario_title,
		"continue": scenario_continue,
		"ledger": scenario_ledger,
		"reader": scenario_reader,
		"stats": scenario_stats,
		"feedback": scenario_feedback,
		"controls": scenario_controls,
		"damaged": scenario_damaged_files,
	}
	for key in scenarios:
		if filter == key or filter == "":
			await scenarios[key].call()
	get_tree().paused = false
	print("experience suite: passed=%d failed=%d" % [passed, failed])


# ================================================================ helpers

func check(label: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
		print("  PASS ", label, "  ", detail)
	else:
		failed += 1
		print("  FAIL ", label, "  ", detail)


func state() -> Node:
	return get_tree().root.get_node("GameState")


func open_scene(path: String) -> void:
	get_tree().paused = false
	if is_instance_valid(get_tree().current_scene):
		get_tree().current_scene.queue_free()
	await get_tree().process_frame
	lvl = load(path).instantiate()
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	await frames(10)


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func seconds(s: float) -> void:
	await frames(int(s * 60.0))


func wait_until(cond: Callable, timeout_s: float) -> bool:
	var t := 0.0
	while not cond.call():
		await get_tree().physics_frame
		t += DT
		if t > timeout_s:
			return false
	return true


func scene_is(path: String) -> bool:
	return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == path


## Waits for a scene change to `path` and adopts the new scene.
func wait_for_scene(path: String, timeout := 8.0) -> bool:
	var ok := await wait_until(func(): return scene_is(path), timeout)
	if ok:
		lvl = get_tree().current_scene
		await frames(10)
	return ok


func press_key(key: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = key
	ev.physical_keycode = key
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(2)
	var up := ev.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await frames(2)


func press_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(2)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await frames(2)


func shot(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOTS + file_name + ".png"))


# ================================================================ title

func scenario_title() -> void:
	print("SCENARIO title screen, new game and intro")
	state().clear_all()
	await open_scene(TITLE)
	await seconds(1.0)
	await shot("title_screen")
	check("the title screen is the game's first scene", ProjectSettings.get_setting("application/run/main_scene") == TITLE)
	check("with no save, Continue is disabled", lvl.continue_button.disabled)
	check("the game has its real name", ProjectSettings.get_setting("application/config/name") == "The Sealed Belfry")
	# New Game plays the story intro, which any key skips, then the tutorial
	lvl.new_button.pressed.emit()
	await seconds(1.4)
	check("New Game begins with the story intro", lvl._intro != null and scene_is(TITLE))
	await shot("title_intro")
	await press_key(KEY_SPACE)
	check("a key skips the intro into the tutorial", await wait_for_scene(TUTORIAL))

	# After the tutorial, Continue and New Game go straight to the chapter
	state().clear_all()
	state().set_flag("tutorial.done")
	await open_scene(TITLE)
	check("after the tutorial, Continue is available", not lvl.continue_button.disabled)
	lvl.continue_button.pressed.emit()
	check("Continue after the tutorial opens the chapter", await wait_for_scene(CHAPTER))

	# Starting over asks twice when there is progress to lose
	state().set_flag("ch1.r1.solved")
	state().set_flag("ch1.page.1")
	await open_scene(TITLE)
	check("the menu shows the chapter's progress", lvl._progress.text.contains("pages 1 / 7"), lvl._progress.text)
	lvl.new_button.pressed.emit()
	await frames(5)
	check("New Game asks again before erasing progress", scene_is(TITLE) and lvl._intro == null
		and state().has_flag("ch1.r1.solved"))
	lvl.new_button.pressed.emit()
	await frames(5)
	check("the second press starts over but keeps the finished tutorial", not state().has_flag("ch1.r1.solved")
		and state().has_flag("tutorial.done"))
	await press_key(KEY_SPACE)
	check("a new game after the tutorial begins in the chapter", await wait_for_scene(CHAPTER))

	# The Tutorial entry always replays it from the start
	await open_scene(TITLE)
	lvl.tutorial_button.pressed.emit()
	check("the Tutorial entry opens the tutorial", await wait_for_scene(TUTORIAL))


func scenario_continue() -> void:
	print("SCENARIO continue from the last shrine")
	state().clear_all()
	state().set_flag("tutorial.done")
	state().set_checkpoint(CHAPTER, "ch1.cp.r3")
	await open_scene(TITLE)
	lvl.continue_button.pressed.emit()
	check("Continue opens the level of the last shrine", await wait_for_scene(CHAPTER))
	var shrine: Node2D = null
	for cp in get_tree().get_nodes_in_group("chapter_checkpoint"):
		if cp.checkpoint_id == "ch1.cp.r3":
			shrine = cp
	var player: Node2D = lvl.get_node("Player")
	check("and puts Echidna at that shrine", shrine != null and player.global_position.distance_to(shrine.get_spawn_position()) < 16.0,
		"player %s" % player.global_position.round())
	# The pause menu can take you back to the title
	var menu = lvl.get_node("PauseMenu")
	menu._set_open(true)
	menu._on_title()
	check("Return to Title from the pause menu", await wait_for_scene(TITLE))
	check("the title isn't left paused", not get_tree().paused)


# ================================================================ ledger and pages

func scenario_ledger() -> void:
	print("SCENARIO the Bellkeeper's Ledger")
	state().clear_all()
	state().set_flag("ch1.page.3")
	await open_scene(CHAPTER)
	check("the chapter carries all seven pages for the Ledger", lvl.ledger.size() == 7)
	var menu = lvl.get_node("PauseMenu")
	menu._set_open(true)
	menu._show(menu._ledger_box)
	await frames(3)
	await shot("ledger")
	var texts: Array = menu._ledger_list.get_children().map(func(l): return l.text)
	menu._set_open(false)
	var page3: Dictionary = lvl.ledger[2]
	check("a found page can be re-read in the Ledger", texts.has(page3["text"]), str(texts.slice(4, 6)))
	check("a missing page says only where it lies", texts.has("Somewhere in The Forgotten Entrance."))
	check("missing pages keep their words hidden", not texts.has(lvl.ledger[0]["text"]))


func scenario_reader() -> void:
	print("SCENARIO the page reader")
	state().clear_all()
	await open_scene(CHAPTER)
	PageReader.enabled = true
	var page: Node2D = lvl.get_node("R1/LorePage1")
	var player = lvl.get_node("Player")
	player.teleport_to(page.global_position + Vector2(0, 14))
	var opened := await wait_until(func(): return _reader() != null, 2.0)
	check("finding a page opens it to read, and the game waits", opened and get_tree().paused)
	await seconds(0.3)
	await shot("page_reader")
	await press_action("interact")
	check("the reader ignores a key pressed straight away", _reader() != null)
	await seconds(0.4)
	await press_action("interact")
	await seconds(0.4)
	check("the interact key closes it and the game resumes", _reader() == null and not get_tree().paused)
	check("the page is kept", state().has_flag("ch1.page.1"))
	PageReader.enabled = false


func _reader() -> Node:
	for child in lvl.get_children():
		if child is PageReader:
			return child
	return null


# ================================================================ statistics

func scenario_stats() -> void:
	print("SCENARIO run statistics")
	state().clear_all()
	await open_scene(CHAPTER)
	await seconds(1.0)
	check("time in the chapter is counted", state().get_stat("ch1.stat.time") > 0.5 and state().get_stat("ch1.stat.time.r1") > 0.5,
		"%.2f s" % state().get_stat("ch1.stat.time"))
	lvl.reset_current_room()
	await seconds(1.0)
	check("room resets are counted", state().get_stat("ch1.stat.resets") == 1.0)
	var player = lvl.get_node("Player")
	player.teleport_to(lvl.get_node("R2").entry_spawn)
	await seconds(0.5)
	lvl.get_node("R2/HintStone").next_hint()
	check("hints heard are counted", state().get_stat("ch1.stat.hints") == 1.0)
	player.take_damage(99)
	await frames(5)
	check("deaths are counted", state().get_stat("ch1.stat.deaths") == 1.0)
	get_tree().paused = false
	state().clear_progress("ch1")
	check("restarting the chapter clears its statistics", state().get_stat("ch1.stat.deaths") == 0.0)


# ================================================================ feedback

func _sounds(name: String) -> int:
	return int(get_tree().root.get_node("Sfx").played.get(name, 0))


func aim_and_shoot(world_pos: Vector2) -> void:
	var screen_pos: Vector2 = lvl.get_viewport().get_canvas_transform() * world_pos
	get_tree().root.warp_mouse(screen_pos)
	await frames(2)
	Input.action_press("shoot")
	await frames(2)
	Input.action_release("shoot")
	await frames(1)


func _particles_in(node: Node) -> int:
	return node.get_children().filter(func(n): return n is CPUParticles2D).size()


func scenario_feedback() -> void:
	print("SCENARIO hit feedback, fizzles, low health, death, moods")
	state().clear_all()
	await open_scene(TUTORIAL)
	var player = lvl.get_node("Player")
	player.teleport_to(Vector2(700, 530))
	await seconds(0.5)
	# A fireball bursts into sparks on a wall, and the sparks clean themselves up
	var hits := _sounds("fireball_hit")
	# (Straight down at the floor beside her: well within a fireball's range)
	await aim_and_shoot(Vector2(760, 560))
	var burst := await wait_until(func(): return _sounds("fireball_hit") > hits, 2.0)
	check("a fireball bursts with a sound where it strikes a wall", burst)
	var sparks := _particles_in(lvl)
	check("the burst leaves sparks behind", sparks > 0, "%d emitters" % sparks)
	await seconds(1.5)
	check("and the sparks clean themselves up", _particles_in(lvl) < sparks, "%d left" % _particles_in(lvl))
	# With no mana a cast sputters instead of doing nothing
	player.current_mana = 0
	var fizzles := _sounds("fizzle")
	await aim_and_shoot(Vector2(900, 480))
	check("casting with no mana sputters", _sounds("fizzle") > fizzles)
	player.current_mana = 100
	# A hit on a creature: a heartbeat of hit-stop, then time runs normally
	var slime = lvl.get_node("Enemies/Slime1")
	player.teleport_to(Vector2(slime.global_position.x - 150.0, 530))
	await seconds(0.3)
	var hp: int = slime.health
	var slowed := false
	for i in 4:
		if slime.health < hp:
			break
		await aim_and_shoot(slime.global_position + Vector2(0, -6))
		for f in 30:
			await get_tree().physics_frame
			slowed = slowed or Engine.time_scale < 1.0
			if slime.health < hp:
				break
	check("a fireball hit on a slime lands with a hit-stop", slowed)
	var numbers := lvl.find_children("*", "Label", true, false).filter(func(l):
		return l.text.trim_suffix("!").is_valid_int() and int(l.text.trim_suffix("!")) == hp - slime.health)
	check("the damage number shows the damage dealt", not numbers.is_empty(), "hp %d -> %d" % [hp, slime.health])
	await seconds(0.5)
	check("and time runs normally again", Engine.time_scale == 1.0)
	# Low health: red edges and a heartbeat
	var hud = lvl.get_node("HUD")
	player.current_health = 3
	player.update_health_ui()
	var beats := _sounds("heartbeat")
	await seconds(1.2)
	check("at low health the screen's edges glow red", hud._vignette.visible)
	check("and a heartbeat plays", _sounds("heartbeat") > beats)
	player.current_health = 10
	player.update_health_ui()
	await frames(3)
	check("the warning clears at full health", not hud._vignette.visible)
	# Death: a sound, a dissolve, and the retry prompt in about a second and a half
	var death = lvl.get_node("DeathUI/DeathScreen")
	var deaths := _sounds("player_death")
	player.invulnerable_time = 0.0
	player.take_damage(99)
	check("dying has its own sound", _sounds("player_death") > deaths)
	var armed := await wait_until(func(): return death.can_restart, 2.0)
	check("the retry prompt is ready within two seconds", armed)
	check("Echidna fades as she falls", player.animated_sprite.self_modulate.a < 0.5)
	get_tree().paused = false
	# Each room has its own colour
	state().clear_all()
	await open_scene(CHAPTER)
	var mat: ShaderMaterial = lvl.get_node("PostFX/Screen").material
	var r1: Color = mat.get_shader_parameter("highlight_tint")
	lvl.get_node("Player").teleport_to(lvl.get_node("R5").entry_spawn)
	await seconds(2.0)
	var r5: Color = mat.get_shader_parameter("highlight_tint")
	check("each room has its own colour (the works glow amber)", r5.r > r1.r and r5.b < r1.b, "%s -> %s" % [r1, r5])


# ================================================================ controls and comfort

func _key_event(key: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	ev.pressed = true
	return ev


func scenario_controls() -> void:
	print("SCENARIO controller, rebinding, assists and effects quality")
	var settings := get_tree().root.get_node("Settings")
	var actions := ["move_left", "move_right", "jump", "crouch", "sprint", "shoot", "heal", "reload", "echo", "interact", "pause"]
	var unbound := actions.filter(func(a): return not InputMap.action_get_events(a).any(func(e):
		return e is InputEventJoypadButton or e is InputEventJoypadMotion))
	check("every action can be played on a controller", unbound.is_empty(), str(unbound))
	InputLabels.use_pad = true
	var pad_jump := InputLabels.primary("jump")
	var pad_fire := InputLabels.primary("shoot")
	InputLabels.use_pad = false
	check("prompts name controller buttons while one is in use", pad_jump == "A" and pad_fire == "RT", "%s / %s" % [pad_jump, pad_fire])
	check("and keys again at the keyboard", InputLabels.primary("jump") == "Space")

	# Rebinding: a new key, a swap on conflict, and a reset
	settings.rebind("jump", _key_event(KEY_K), actions)
	check("jump can be rebound", InputLabels.primary("jump") == "K")
	settings.rebind("jump", _key_event(KEY_E), actions)
	check("taking another action's key swaps them, so neither is lost",
		InputLabels.primary("jump") == "E" and InputLabels.primary("echo") == "K")
	check("a rebound key keeps its controller button", InputMap.action_get_events("jump").any(func(e): return e is InputEventJoypadButton))
	settings.reset_bindings()
	check("Reset controls restores the defaults", InputLabels.primary("jump") == "Space" and InputLabels.primary("echo") == "E")

	# Assists
	state().clear_all()
	await open_scene(TUTORIAL)
	var player = lvl.get_node("Player")
	player.teleport_to(Vector2(700, 530))
	await seconds(0.3)
	settings.assist_damage = 0.5
	player.take_damage(2)
	check("the damage assist halves a hit", player.current_health == 9, "hp=%d" % player.current_health)
	settings.assist_damage = 1.0
	player.invulnerable_time = 0.0
	settings.assist_auto_sprint = true
	Input.action_press("move_right")
	await seconds(0.3)
	var speed: float = player.velocity.x
	Input.action_release("move_right")
	settings.assist_auto_sprint = false
	check("with always-sprint she runs at sprint speed", speed > 200.0, "%.0f px/s" % speed)
	await seconds(0.3)
	settings.assist_toggle_crouch = true
	Input.action_press("crouch")
	await frames(3)
	Input.action_release("crouch")
	await seconds(0.3)
	var crouching: bool = player.charging_jump
	Input.action_press("crouch")
	await frames(3)
	Input.action_release("crouch")
	await frames(3)
	settings.assist_toggle_crouch = false
	check("with the toggle, one press crouches and the next stands", crouching and not player.charging_jump)
	settings.assist_infinite_mana = true
	player.current_mana = 20
	await frames(3)
	check("unlimited mana keeps her full", player.current_mana == player.get_mana_cap())
	settings.assist_infinite_mana = false

	# Controller aim: straight ahead, drawn toward a creature near that line
	InputLabels.use_pad = true
	var slime: Node2D = lvl.get_node("Enemies/Slime1")
	player.teleport_to(Vector2(slime.global_position.x - 200.0, 530))
	await seconds(0.3)
	player.animated_sprite.flip_h = false
	var origin: Vector2 = player.global_position + Vector2(0, -12)
	var dir: Vector2 = player.aim_direction(origin)
	var to_slime := (slime.global_position + Vector2(0, -8) - origin).normalized()
	InputLabels.use_pad = false
	check("controller aim leans onto a creature ahead", dir.angle_to(to_slime) < 0.05 and dir.angle_to(to_slime) > -0.05,
		"%s vs %s" % [dir, to_slime])

	# Lighter effects: no bloom or grain, and lights stop casting shadows
	var mat: ShaderMaterial = lvl.get_node("PostFX/Screen").material
	var shadowed := lvl.find_children("*", "Light2D", true, false).filter(func(l): return l.shadow_enabled).size()
	settings.effects_low = true
	settings.changed.emit()
	await frames(2)
	var still := lvl.find_children("*", "Light2D", true, false).filter(func(l): return l.shadow_enabled).size()
	check("lighter effects turn off bloom, grain and shadows", mat.get_shader_parameter("bloom_strength") == 0.0
		and still == 0 and shadowed > 0, "%d shadowed lights -> %d" % [shadowed, still])
	settings.effects_low = false
	settings.changed.emit()
	await frames(2)
	check("and full effects bring them back", mat.get_shader_parameter("bloom_strength") > 0.0
		and lvl.find_children("*", "Light2D", true, false).filter(func(l): return l.shadow_enabled).size() == shadowed)


# ================================================================ damaged files

func scenario_damaged_files() -> void:
	print("SCENARIO damaged save and settings files")
	var path := "user://test_damaged_save.cfg"
	var file := ConfigFile.new()
	file.set_value("progress", "flags", "not a dictionary")
	file.set_value("progress", "checkpoint_scene", 42)
	file.set_value("progress", "checkpoints", [1, 2, 3])
	file.save(path)
	state().load_game(path)
	check("a damaged save loads as empty progress instead of crashing", state().flags is Dictionary
		and state().flags.is_empty() and state().checkpoint_scene == "" and state().checkpoints is Dictionary)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var settings := get_tree().root.get_node("Settings")
	check("a damaged setting falls back to its default", settings._number("loud", 0.7) == 0.7
		and settings._number(5.0, 0.7) == 2.0)
