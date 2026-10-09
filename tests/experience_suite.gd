extends Node

## Tests for the game around the levels: the title screen and its menu, the
## story intro, continuing a save, the Ledger and the page reader, run
## statistics, and robustness against damaged save and settings files.
## Run through tests/run_tests.gd:  -- experience [scenario]

const TITLE := "res://scenes/ui/title_screen.tscn"
const TUTORIAL := "res://scenes/tutorial_level.tscn"
const CHAPTER := "res://scenes/chapter/chapter_1.tscn"
const STORY := "res://scenes/story/story_intro.tscn"
const LOWBELL := "res://scenes/story/lowbell.tscn"
const COTTAGE := "res://scenes/story/nan_cottage.tscn"
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
		"menu": scenario_menu,
		"puddles": scenario_puddles,
		"layers": scenario_layers,
		"story": scenario_story,
		"lowbell": scenario_lowbell,
		"cottage": scenario_cottage,
		"interludes": scenario_interludes,
		"tours": scenario_tours,
		"kindle": scenario_kindle,
		"waymarks": scenario_waymarks,
		"longstair": scenario_longstair,
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
	if DisplayServer.get_name() == "headless":
		return
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
	# New Game plays the illustrated story, then Lowbell, whose lane leads to the tutorial
	lvl.new_button.pressed.emit()
	check("New Game begins with the story", await wait_for_scene(STORY))
	await seconds(2.0)
	await shot("title_intro")
	lvl.skip()
	check("the story leads out onto Lowbell's lane (Nan's cottage, then the dungeon)", await wait_for_scene(LOWBELL))
	check("Lowbell leads to Nan's cottage", lvl.next_scene() == COTTAGE)

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
	check("New Game asks again before erasing progress", scene_is(TITLE) and state().has_flag("ch1.r1.solved"))
	lvl.new_button.pressed.emit()
	await frames(5)
	check("a fresh game resets tutorial and spell progress", not state().has_flag("ch1.r1.solved")
		and not state().has_flag("tutorial.done") and not state().has_flag("ability.fire"))
	check("the story plays again", await wait_for_scene(STORY))
	lvl.skip()
	check("it leads out onto Lowbell's lane again", await wait_for_scene(LOWBELL))
	check("a new journey starts with movement lessons", Journey.after_story() == Journey.MOVEMENT)
	check("New Game still visits Nan when the tutorial is already done", lvl.next_scene() == COTTAGE)

	# Choose a Level lists the levels; Level 1 (the tutorial) always replays from the start
	await open_scene(TITLE)
	lvl.tutorial_button.pressed.emit()
	await frames(3)
	check("Choose a Level lists Level 1 (the tutorial), 2 and 3", lvl._parts.visible and not lvl._menu.visible
		and lvl.part_1_button.text.begins_with("Level 1") and lvl.part_1_button.text.contains("Passage")
		and lvl.part_2_button.text.begins_with("Level 2") and lvl.part_3_button.text.begins_with("Level 3"),
		"%s / %s / %s" % [lvl.part_1_button.text, lvl.part_2_button.text, lvl.part_3_button.text])
	lvl.part_1_button.pressed.emit()
	check("Level 1 opens the movement-only tutorial", await wait_for_scene(Journey.MOVEMENT))
	await open_scene(TITLE)
	lvl.tutorial_button.pressed.emit()
	await frames(3)
	lvl.part_3_button.pressed.emit()
	check("Level 3 opens the Observatory", await wait_for_scene("res://scenes/chapter/chapter_2.tscn"))


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
	if DisplayServer.get_name() == "headless":
		await preload("res://tests/background_aim.gd").fire(lvl.get_node("Player"), world_pos)
		return
	# A windowed run aims through the player's aim_override, not the OS cursor
	# (it belongs to whoever is using the computer); the shot itself goes through
	# the real shoot input, mana and cooldown
	var shooter: Node = lvl.get_node("Player")
	shooter.aim_override = world_pos
	Input.action_press("shoot")
	await frames(2)
	Input.action_release("shoot")
	await frames(1)
	shooter.aim_override = null


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
	check("and a fall, a chord and a heartbeat that stops", _sounds("death_fall") > 0)
	var armed := await wait_until(func(): return death.can_restart, 2.0)
	check("the retry prompt is ready within two seconds", armed)
	check("YOU DIED tolls", _sounds("death_sting") > 0)
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
	# (The other slime wanders; out of sight it can't be the nearer target)
	var other: Node2D = lvl.get_node("Enemies/Slime2")
	other.visible = false
	player.teleport_to(Vector2(slime.global_position.x - 200.0, 530))
	await seconds(0.3)
	player.animated_sprite.flip_h = false
	var origin: Vector2 = player.global_position + Vector2(0, -12)
	var dir: Vector2 = player.aim_direction(origin)
	var to_slime := (slime.global_position + Vector2(0, -8) - origin).normalized()
	other.visible = true
	InputLabels.use_pad = false
	check("controller aim leans onto a creature ahead", dir.angle_to(to_slime) < 0.05 and dir.angle_to(to_slime) > -0.05,
		"%s vs %s" % [dir, to_slime])

	# Graphics levels, Low to Elite
	if DisplayServer.get_name() == "headless":
		print("  SKIP compiled shader/graphics quality checks in headless mode")
		return
	var mat: ShaderMaterial = lvl.get_node("PostFX/Screen").material
	var lights := func(): return lvl.find_children("*", "Light2D", true, false).filter(func(l): return l.shadow_enabled)
	var shadowed: int = lights.call().size()
	var high_bloom: float = mat.get_shader_parameter("bloom_strength")
	var shafts := get_tree().get_nodes_in_group("light_shaft")
	var motes := get_tree().get_nodes_in_group("ambient_particles")
	var high_motes: int = motes[0].amount if not motes.is_empty() else 0
	settings.set_graphics(0)
	await frames(2)
	check("Low turns off bloom, grain and shadows", mat.get_shader_parameter("bloom_strength") == 0.0
		and mat.get_shader_parameter("grain") == 0.0 and lights.call().is_empty() and shadowed > 0,
		"%d shadowed lights -> %d" % [shadowed, lights.call().size()])
	check("Low hides the light shafts and thins the motes", not shafts.is_empty() and shafts.all(func(s): return not s.visible)
		and motes[0].amount < high_motes, "%d -> %d motes" % [high_motes, motes[0].amount])
	settings.set_graphics(1)
	await frames(2)
	check("Medium has softer bloom and shadows back", mat.get_shader_parameter("bloom_strength") > 0.0
		and mat.get_shader_parameter("bloom_strength") < high_bloom and lights.call().size() == shadowed)
	settings.set_graphics(4)
	await frames(2)
	check("Elite: stronger bloom, the smoothest shadows, more motes", mat.get_shader_parameter("bloom_strength") > high_bloom
		and lights.call().all(func(l): return l.shadow_filter == Light2D.SHADOW_FILTER_PCF13) and motes[0].amount > high_motes)
	settings.set_graphics(2)
	await frames(2)
	check("and High puts everything back as authored", is_equal_approx(mat.get_shader_parameter("bloom_strength"), high_bloom)
		and lights.call().size() == shadowed and shafts.all(func(s): return s.visible) and motes[0].amount == high_motes)
	# The frames-per-second readout
	settings.set_show_fps(true)
	await frames(3)
	check("Show FPS puts a live counter on screen", settings._fps_layer.visible and settings._fps_label.text.begins_with("FPS "),
		settings._fps_label.text)
	settings.set_show_fps(false)
	check("and hides it again", not settings._fps_layer.visible)


# ================================================================ damaged files

func scenario_damaged_files() -> void:
	print("SCENARIO damaged save and settings files")
	var path := "res://.godot/test_damaged_save.cfg"
	var file := ConfigFile.new()
	file.set_value("progress", "flags", "not a dictionary")
	file.set_value("progress", "checkpoint_scene", 42)
	file.set_value("progress", "checkpoints", [1, 2, 3])
	check("damaged-save fixture was written", file.save(path) == OK)
	state().load_game(path)
	check("a damaged save loads as empty progress instead of crashing", state().flags is Dictionary
		and state().flags.is_empty() and state().checkpoint_scene == "" and state().checkpoints is Dictionary)
	# Leave this isolated fixture for inspection; never touch the real save.
	var settings := get_tree().root.get_node("Settings")
	check("a damaged setting falls back to its default", settings._number("loud", 0.7) == 0.7
		and settings._number(5.0, 0.7) == 2.0)


# ================================================================ the cascading menu

func _settings() -> Node:
	return get_tree().root.get_node("Settings")


func _mouse_to(at: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = at
	ev.global_position = at
	Input.parse_input_event(ev)
	await frames(3)


func _click(at: Vector2) -> void:
	await _mouse_to(at)
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.position = at
		ev.global_position = at
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await frames(2)


func scenario_menu() -> void:
	print("SCENARIO the cascading menu")
	state().clear_all()
	await open_scene(CHAPTER)
	var menu = lvl.get_node("PauseMenu")
	await press_action("pause")
	check("Esc opens the menu and pauses", menu.is_open and get_tree().paused)
	check("it opens with a chime", int(menu.played.get("open", 0)) >= 1)
	check("six round icons, the first ringed in orange", menu._icons.size() == 6 and menu._icons[0].active)
	await seconds(0.5)
	await shot("menu_open")
	# Down to Settings: each move rings the next icon, with a chime
	var hovers: int = menu.played.get("hover", 0)
	for i in 4:
		await press_action("ui_down")
	check("moving down rings each icon in turn", menu._icons[4].active and not menu._icons[0].active, "icon %d" % menu._icon_index)
	check("a chime on each hover", int(menu.played.get("hover", 0)) >= hovers + 4)
	check("its list slides out beside it", menu._list1 != null and menu._list1.visible and menu._visible_rows(menu._list1).size() == 4)
	var selects: int = menu.played.get("select", 0)
	await press_action("ui_right")
	check("right goes into the list, with a beep", menu._col == 1 and menu._row1 == 0 and int(menu.played.get("select", 0)) == selects + 1)
	check("the active row is solid orange", menu._visible_rows(menu._list1)[0].active)
	check("Graphics cascades out its own list: five levels, three switches and Brightness", menu._list2 != null and menu._list2.visible
		and menu._visible_rows(menu._list2).size() == 9)
	await press_action("ui_right")
	for i in 4:
		await press_action("ui_down")
	check("the card describes the highlighted level", menu._info_title.text == "Graphics: Elite", menu._info_title.text)
	await seconds(0.3)
	await shot("menu_graphics")
	await press_action("ui_accept")
	check("choosing Elite sets it", _settings().graphics == 4)
	check("and marks it in use", menu._visible_rows(menu._list2)[4].value_text.contains("In use"))
	await press_action("ui_down")
	await press_action("ui_accept")
	check("Show FPS switches the counter on from the menu", _settings().show_fps and _settings()._fps_layer.visible)
	await press_action("ui_accept")
	check("and off again", not _settings().show_fps)
	_settings().set_graphics(2)
	await press_action("ui_cancel")
	check("Esc backs out one list", menu._col == 1 and menu.is_open)
	# Controls: rebind Jump to J from the menu, then put it back
	await press_action("ui_down")
	check("Controls is next", menu._visible_rows(menu._list1)[1].active)
	await press_action("ui_right")
	await press_action("ui_down")
	await press_action("ui_down")
	await press_action("ui_accept")
	check("choosing a control waits for a key", menu._waiting_action == "jump"
		and menu._visible_rows(menu._list2)[2].value_text == "Press a key...")
	await press_key(KEY_J)
	check("the next key becomes Jump", InputLabels.primary("jump") == "J", InputLabels.primary("jump"))
	check("and the list shows it", menu._visible_rows(menu._list2)[2].value_text == "J")
	_settings().reset_bindings()
	await press_action("ui_cancel")
	# Audio: left and right change a volume
	_settings().set_music_volume(0.5)
	await press_action("ui_down")
	await press_action("ui_right")
	await press_action("ui_down")
	var music: float = _settings().music_volume
	await press_action("ui_left")
	check("left turns the music down", _settings().music_volume < music, "%.2f -> %.2f" % [music, _settings().music_volume])
	await press_action("ui_right")
	check("right turns it back up", is_equal_approx(_settings().music_volume, music))
	await press_action("ui_cancel")
	await press_action("ui_cancel")
	check("back on the icons, the lists folded away", menu._col == 0 and menu._list2 == null)
	# The map opens in the card
	await press_action("ui_up")
	await press_action("ui_up")
	await press_action("ui_right")
	await press_action("ui_accept")
	check("Chapter Map opens in the card", menu._map_box.visible and menu._map_list.get_child_count() > 0)
	await shot("menu_map")
	await press_action("ui_cancel")
	check("Esc closes the page first", menu._menu_box.visible and menu.is_open)
	await press_action("ui_cancel")
	await press_action("ui_cancel")
	check("Esc on the icons closes the menu", not menu.is_open and not get_tree().paused)
	check("with its own sound", int(menu.played.get("close", 0)) >= 1)

	# With the mouse: hover opens, click chooses
	await press_action("pause")
	await seconds(0.4)
	var icon = menu._icons[1]
	await _mouse_to(icon.get_global_rect().get_center())
	check("hovering an icon rings it and slides its list out", icon.active and menu._list1.visible)
	await seconds(0.3)
	var spells = menu._visible_rows(menu._list1)[0]
	await _mouse_to(spells.get_global_rect().get_center())
	check("hovering a row lights it and cascades the next list", spells.active and menu._list2 != null and menu._list2.visible)
	await seconds(0.3)
	var fireball = menu._visible_rows(menu._list2)[0]
	await _mouse_to(fireball.get_global_rect().get_center())
	check("hovering a spell describes it on the card", menu._info_title.text == "Fireball" and fireball.active, menu._info_title.text)
	await shot("menu_spells")
	await _click(menu._icons[0].get_global_rect().get_center())
	check("clicking Resume closes the menu", not menu.is_open and not get_tree().paused)

	# The tutorial has no chapter: its map and journal stay hidden
	await open_scene(TUTORIAL)
	menu = lvl.get_node("PauseMenu")
	menu._set_open(true)
	check("the tutorial menu hides the chapter-only icons", not menu._icon_by_id["map"].visible
		and not menu._icon_by_id["journal"].visible and menu._icon_by_id["settings"].visible)
	menu._set_open(false)


# ================================================================ puddles

func scenario_puddles() -> void:
	print("SCENARIO puddles")
	state().clear_all()
	await open_scene(CHAPTER)
	await frames(10)
	var puddles := get_tree().get_nodes_in_group("puddle")
	check("the chapter's puddles settle onto flat floor", puddles.size() >= 6, "%d puddles" % puddles.size())
	var p: Node2D = null
	for each in puddles:
		if p == null or absf(each.global_position.x - 470.0) < absf(p.global_position.x - 470.0):
			p = each
	check("a puddle lies on the floor's surface", p != null and absf(p.global_position.y - 534.0) <= 1.0,
		"y=%.1f" % p.global_position.y)
	var player: Node2D = lvl.get_node("Player")
	player.teleport_to(Vector2(p.global_position.x - 90.0, 530.0))
	await frames(20)
	var wet := _sounds("puddle_step")
	Input.action_press("move_right")
	await wait_until(func(): return player.global_position.x > p.global_position.x + 30.0, 4.0)
	Input.action_release("move_right")
	check("walking through leaves rings of ripples", p.ripple_count() > 0, "%d" % p.ripple_count())
	check("footfalls in it sound wet", _sounds("puddle_step") > wet)
	await seconds(2.5)
	player.teleport_to(Vector2(p.global_position.x, 430.0))
	var splashes := _sounds("puddle_splash")
	await wait_until(func(): return not player.is_on_floor(), 0.5)
	await wait_until(func(): return player.is_on_floor(), 2.0)
	await frames(2)
	check("landing in it splashes", _sounds("puddle_splash") > splashes and p.ripple_count() > 0)
	await seconds(0.25)
	await shot("puddle_splash")
	_settings().set_graphics(0)
	await frames(2)
	check("Low graphics drop the reflection", p._material.get_shader_parameter("reflections") == false)
	_settings().set_graphics(2)
	await frames(2)
	check("High mirrors the scene above it", p._material.get_shader_parameter("reflections") == true)
	var drips := _sounds("drip")
	p.drip_interval = Vector2(0.2, 0.3)
	p._drip_in = 0.05
	check("water drips into it from above", await wait_until(func(): return _sounds("drip") > drips, 4.0))
	player.teleport_to(Vector2(p.global_position.x - 14.0, 530.0))
	await seconds(1.0)
	await shot("puddle_reflection")
	# In the tutorial too
	await open_scene(TUTORIAL)
	await frames(10)
	check("the tutorial has its puddles", get_tree().get_nodes_in_group("puddle").size() >= 2,
		"%d" % get_tree().get_nodes_in_group("puddle").size())


# ================================================================ the story and Lowbell

func _walk_to(player: Node2D, x: float, timeout := 10.0) -> bool:
	var dir := "move_right" if x > player.global_position.x else "move_left"
	Input.action_press(dir)
	var ok := await wait_until(func(): return player.global_position.x >= x if dir == "move_right" else player.global_position.x <= x, timeout)
	Input.action_release(dir)
	await frames(10)
	return ok


func scenario_story() -> void:
	print("SCENARIO the story before the game")
	state().clear_all()
	await open_scene(TITLE)
	lvl.new_button.pressed.emit()
	check("New Game opens the illustrated story", await wait_for_scene(STORY))
	var first_words := func(): return lvl.index == 0 and lvl._caption.modulate.a > 0.9
	check("it opens on the first picture, with its words", await wait_until(first_words, 4.0))
	check("each picture is drawn, not a blank page", lvl._picture != null
		and lvl._picture.find_children("*", "", true, false).size() > 10)
	# Its people and things are pixel art from the packs, not drawn shapes
	var shapes: Array = lvl._picture.find_children("*", "Polygon2D", true, false)
	var sprites: Array = lvl._picture.find_children("*", "Sprite2D", true, false) \
		+ lvl._picture.find_children("*", "AnimatedSprite2D", true, false)
	check("the picture is made of pixel-art sprites, with no drawn shapes", shapes.is_empty() and sprites.size() > 5,
		"%d shapes, %d sprites" % [shapes.size(), sprites.size()])
	# Pressing on moves through every picture (a press on a line still
	# fading in just shows it), and the last one leads to the village
	var seen := {}
	var guard := 0
	while not lvl.finished and guard < 90:
		seen[lvl.index] = true
		await press_action("jump")
		await seconds(0.8)
		guard += 1
	check("all eight pictures can be paged through", seen.size() == 8, str(seen.keys()))
	check("and the last leads out onto Lowbell's lane", await wait_for_scene(LOWBELL, 5.0))
	# Holding Esc skips straight there
	state().clear_all()
	await open_scene(STORY)
	await seconds(1.5)
	Input.action_press("pause")
	await seconds(1.3)
	Input.action_release("pause")
	check("holding Esc skips the story", await wait_for_scene(LOWBELL, 4.0))


func scenario_lowbell() -> void:
	print("SCENARIO Lowbell: meeting Echidna")
	state().clear_all()
	await open_scene(LOWBELL)
	var player: CharacterBody2D = lvl.player
	check("the opening starts in the sky, before Echidna appears", lvl.intro_running and not player.visible
		and player.controls_locked)
	check("entering Lowbell saves it for Continue", state().checkpoint_scene == LOWBELL)
	await seconds(1.5)
	await shot("lowbell_opening")
	var handed_over := func(): return not lvl.intro_running and player.visible and not player.controls_locked
	check("she steps out and is handed over", await wait_until(handed_over, 20.0))
	check("her name comes up", lvl._named)
	check("the goal is shown", await wait_until(func(): return lvl._objective.modulate.a > 0.9, 3.0))
	check("the wind chimes swing, silent", get_tree().get_nodes_in_group("wind_chime").size() == 5)
	check("the lane has its puddles", get_tree().get_nodes_in_group("puddle").size() == 2)
	# The village is the surface and town packs' pixel art, not drawn shapes
	var shapes: Array = []
	var puddles := get_tree().get_nodes_in_group("puddle")
	for s in lvl.find_children("*", "Polygon2D", true, false):
		var in_puddle := false
		for p in puddles:
			if p.is_ancestor_of(s):
				in_puddle = true
		if not in_puddle:
			shapes.append(s)
	check("Lowbell is built from pixel-art sprites, with no drawn shapes", shapes.is_empty()
		and lvl.find_children("*", "Sprite2D", true, false).size() > 20, "%d shapes" % shapes.size())
	var look: ShaderMaterial = lvl.get_node("PostFX/Screen").material
	var lift = look.get_shader_parameter("shadow_lift")
	check("Lowbell keeps its own look: the Brightness setting does not touch it",
		is_equal_approx(float(look.get_shader_parameter("lantern_darkness")), 0.14) and (lift == null or is_equal_approx(float(lift), 1.0)))
	check("the villagers are pixel sprites", lvl.get_node("People/Mira").figure is AnimatedSprite2D)
	await shot("lowbell_start")
	# The villagers have lost words to the Hush
	var mira = lvl.get_node("People/Mira")
	await _walk_to(player, mira.global_position.x + 16.0)
	check("a villager speaks when she comes close", await wait_until(func(): return mira.bubble.is_showing(), 2.0))
	check("a word the Hush has taken shows as runes", mira.bubble.gap_count() == 6, str(mira.bubble.gap_count()))
	await shot("lowbell_villager")
	# The stile across the lane needs a hop
	await _walk_to(player, lvl.STILE_X - 60.0)
	Input.action_press("move_right")
	await seconds(1.2)
	check("the stile stops her walking", player.global_position.x < lvl.STILE_X - 10.0, "x=%.0f" % player.global_position.x)
	await press_action("jump")
	await seconds(0.8)
	Input.action_release("move_right")
	check("a hop clears it", player.global_position.x > lvl.STILE_X + 10.0, "x=%.0f" % player.global_position.x)
	await _walk_to(player, 1200.0)
	check("the crow on the well flies off as she passes", lvl._crow_flown)
	# Knocking at Nan's door leads on
	await _walk_to(player, lvl.NAN_DOOR_X - 6.0, 14.0)
	check("Nan's door can be knocked on", await wait_until(func(): return lvl.nan_door.is_focused(), 2.0))
	await press_action("interact")
	check("knocking starts the way on", lvl.leaving)
	var nan_answers := func(): return lvl._nan.visible and lvl._nan_door_anim.visible
	check("Nan opens her door, lantern in hand", await wait_until(nan_answers, 4.0))
	check("which leads into her cottage", await wait_for_scene(COTTAGE, 40.0))
	# Coming back (Continue), the opening doesn't play again
	await open_scene(LOWBELL)
	await frames(5)
	check("a second visit skips the opening", not lvl.intro_running and lvl.player.visible)


# ================================================================ Nan's cottage

## Taps interact once a line is showing (the story waits for a press).
func _cottage_next(timeout := 15.0) -> bool:
	var ok := await wait_until(func(): return lvl._waiting, timeout)
	await frames(24)
	Input.action_press("interact")
	await frames(2)
	Input.action_release("interact")
	await frames(2)
	return ok


func scenario_cottage() -> void:
	print("SCENARIO Nan's cottage: the grandma scene")
	state().clear_all()
	state().all_abilities = false
	await open_scene(COTTAGE)
	var player: CharacterBody2D = lvl.player
	check("the cottage is built from sprites, with no drawn shapes", lvl.find_children("*", "Polygon2D", true, false).is_empty())
	check("it saves itself for Continue", state().checkpoint_scene == COTTAGE)
	check("she has not got her fire spell yet", not state().has_ability("fire"))
	check("Nan greets her", await wait_until(func(): return lvl.stage == "greeting", 10.0))
	check("and Nan is in her chair by the fire", lvl.nan.position.x > 700.0 and lvl.nan.flip_h)
	await _cottage_next()
	check("Echidna thinks: she does not know me", lvl.dialogue.thought and lvl.dialogue.text.contains("know me"))
	await _cottage_next()
	check("then she is free to walk to Nan", await wait_until(func(): return lvl.stage == "talk", 5.0)
		and lvl.nan_talk.enabled and not player.controls_locked)
	# Walk to Nan and talk
	Input.action_press("move_right")
	await wait_until(func(): return player.global_position.x > 710.0, 8.0)
	Input.action_release("move_right")
	await frames(20)
	check("Nan can be talked to", await wait_until(func(): return lvl.nan_talk.is_focused(), 2.0))
	await press_action("interact")
	check("talking starts the conversation", await wait_until(func(): return lvl.stage == "conversation", 2.0))
	await _cottage_next()
	check("Nan cannot say her name: the words are glyph gaps", lvl.dialogue.gap_count() > 0, "%d gaps" % lvl.dialogue.gap_count())
	await seconds(1.2)
	await shot("cottage_dialogue")
	await _cottage_next()
	await _cottage_next()
	# The fire spell will not come
	check("Nan asks for her fire", await wait_until(func(): return lvl.stage == "spell", 5.0))
	await _cottage_next()
	check("she is asked to try it", await wait_until(func(): return lvl._hint.text.contains("fire spell"), 3.0))
	var denied := []
	player.ability_denied.connect(func(id): denied.append(id))
	var fireballs := get_tree().get_nodes_in_group("fireball").size()
	Input.action_press("shoot")
	await frames(3)
	Input.action_release("shoot")
	await frames(10)
	check("trying it only sputters: no fireball, the game is told", denied == ["fire"]
		and get_tree().get_nodes_in_group("fireball").size() == fireballs, str(denied))
	await frames(40)
	check("she thinks: the word is gone", lvl.dialogue.text.contains("word is gone"))
	await _cottage_next()
	check("Nan explains the Hush", await wait_until(func(): return lvl.stage == "explaining", 4.0))
	for i in 7:
		await _cottage_next()
	check("then Nan gives her the lantern", await wait_until(func(): return lvl.stage == "lantern", 4.0))
	await _cottage_next()
	check("it comes to Echidna and her own light grows", await wait_until(func(): return lvl.has_lantern and player.get_node("PlayerLight").energy > 0.8, 8.0))
	await _cottage_next()
	await _cottage_next()
	check("Nan sends her on, and the cellar door is free", await wait_until(func(): return lvl.stage == "free", 4.0)
		and lvl.cellar_door.enabled)
	await shot("cottage_free")
	# Down the cellar door: on to the Passage
	player.teleport_to(Vector2(lvl.CELLAR_X, 530))
	await frames(10)
	check("the cellar door can be used", await wait_until(func(): return lvl.cellar_door.is_focused(), 2.0))
	await press_action("interact")
	check("going down marks the scene done", lvl.stage == "leaving" and state().has_flag("cottage.done"))
	check("and leads outside to the pilgrim road", await wait_for_scene("res://scenes/story/pilgrims_path.tscn", 10.0))
	# Anyone who already has her spells skips the fire beat, and goes on to the Belfry
	state().clear_all()
	state().set_flag("tutorial.done")
	state().grant_ability("fire")
	state().grant_ability("echo")
	state().all_abilities = false
	check("a finished tutorial leads on to the Belfry", Journey.after_story() == CHAPTER)
	await open_scene(COTTAGE)
	check("she already has her spells", state().has_ability("fire"))
	await wait_until(func(): return lvl.stage == "greeting", 10.0)
	await _cottage_next()
	await _cottage_next()
	await wait_until(func(): return lvl.stage == "talk", 5.0)
	lvl.player.teleport_to(Vector2(720, 530))
	await frames(20)
	await press_action("interact")
	await wait_until(func(): return lvl.stage == "conversation", 2.0)
	await _cottage_next()
	await _cottage_next()
	await _cottage_next()
	check("the fire beat is skipped for her", await wait_until(func(): return lvl.stage == "explaining", 5.0))
	state().all_abilities = true


# ================================================================ story interludes

func scenario_interludes() -> void:
	print("SCENARIO the story pictures after the bell and the dome")
	var chapter_1: Node = load(CHAPTER).instantiate()
	check("the Belfry's end card leads to the bell pictures", chapter_1.next_chapter == Journey.BELL_INTERLUDE)
	chapter_1.free()
	var chapter_2: Node = load("res://scenes/chapter/chapter_2.tscn").instantiate()
	check("and the Observatory's to the dome pictures", chapter_2.next_chapter == Journey.DOME_INTERLUDE)
	chapter_2.free()
	for kind in ["bell", "dome"]:
		var path := Journey.BELL_INTERLUDE if kind == "bell" else Journey.DOME_INTERLUDE
		# (no finished chapter's card is waiting for these pictures)
		ChapterComplete.pending = {}
		await open_scene(path)
		var count := 4 if kind == "bell" else 3
		state().all_abilities = false
		state().clear_all()
		state().grant_ability("fire")
		check("%s: %d pictures of pixel-art sprites, no drawn shapes" % [kind, count],
			lvl.pictures.size() == count and lvl.find_children("*", "Polygon2D", true, false).is_empty()
			and lvl.find_children("*", "Sprite2D", true, false).size() >= 1, "%d pictures, %d polygons, %d sprites" % [lvl.pictures.size(), lvl.find_children("*", "Polygon2D", true, false).size(), lvl.find_children("*", "Sprite2D", true, false).size()])
		if kind == "bell":
			check("the bell's pictures no longer show the Spring (it is drunk in the bell tower now)",
				not lvl.pictures.any(_is_spring_picture))
		await seconds(1.5)
		await shot("interlude_" + kind)
		var guard := 0
		while not lvl.finished and guard < 12:
			guard += 1
			await wait_until(func(): return not lvl._changing, 4.0)
			await seconds(1.0)
			if lvl.line == 0 or lvl.line == 1:
				await shot("interlude_%s_%d_%d" % [kind, lvl.index, lvl.line])
			lvl.next()
			await seconds(0.5)
		var want := Journey.OBSERVATORY if kind == "bell" else Journey.LANDING
		check("%s: after the last picture it leads on" % kind, await wait_for_scene(want, 8.0))
		if kind == "bell":
			check("anyone who walked past the hot spring still has heal after the bell", state().has_flag("ability.heal"))
	state().all_abilities = true



func _is_spring_picture(picture: Dictionary) -> bool:
	return String(picture.get("era", "")) == "THE SPRING"


# ================================================================ UI tours and kindle flames

func scenario_tours() -> void:
	print("SCENARIO the UI tours")
	UiTour.enabled = true
	state().clear_all()
	state().all_abilities = true
	check("the fire and Echo shrines name their tours", AbilityShrine.TOURS == {"fire": "fire", "echo": "echo"})
	for id in ["basics", "fire", "echo", "objective", "runes"]:
		var steps := UiTour.steps_for(id)
		check("tour '%s' has steps with a title and text" % id, not steps.is_empty()
			and steps.all(func(s): return s["title"] != "" and s["text"] != ""))
	check("an unknown tour has no steps", UiTour.steps_for("nothing").is_empty())

	# Part 1: health and the menu, a few seconds after the first card
	await open_scene(TUTORIAL)
	check("the first lesson names the 'basics' tour", lvl.get_node("Lessons/Lesson1").tour == "basics")
	check("the tour waits for the card to clear", UiTour.current == null)
	check("and then opens", await wait_until(func(): return UiTour.current != null, 6.0))
	var tour: UiTour = UiTour.current
	await seconds(0.6)
	check("the game is paused while it is read", get_tree().paused and tour.id == "basics")
	var rect := tour.target_rect(tour.steps[0])
	var view := get_viewport().get_visible_rect().size
	check("the first card frames the health bar, on screen", tour._frame.visible and Rect2(Vector2.ZERO, view).encloses(rect)
		and rect.position.y < 40.0 and tour._title.text == "Health", str(rect))
	check("the card sits clear of the framed part", not tour._card.get_global_rect().intersects(rect.grow(2.0)))
	await shot("tour_basics_1")
	await press_action("jump")
	check("a press moves to the menu card", tour.index == 1 and tour._title.text == "The menu" and not tour._frame.visible
		and tour._text.text.contains("Esc"), tour._text.text)
	await seconds(0.6)
	await shot("tour_basics_2")
	await press_action("jump")
	await frames(4)
	check("the last press closes it and the game goes on", not is_instance_valid(tour) or tour.is_queued_for_deletion())
	check("unpaused, and it is not shown again", not get_tree().paused and state().has_flag("ui.tour.basics")
		and UiTour.play(lvl, "basics") == null)

	# Esc closes it at once
	state().clear_all()
	var again := UiTour.play(lvl, "fire")
	await seconds(0.6)
	check("the fire tour frames the mana bar, then the spell slots", again.target_rect(again.steps[0]).position.x < 40.0
		and again.target_rect(again.steps[1]).end.x > view.x - 20.0)
	await shot("tour_fire_1")
	await press_action("pause")
	await frames(4)
	check("Esc closes a tour and marks it seen", not get_tree().paused and state().has_flag("ui.tour.fire"))

	# Part 3: how rune cubes are edited, when the Observatory begins
	state().clear_all()
	state().all_abilities = true
	await open_scene("res://scenes/chapter/chapter_2.tscn")
	check("Part 3's first room names the rune tour", lvl.get_node("R1").explainer == "runes")
	check("and it opens after the act card", await wait_until(func(): return UiTour.current != null, 14.0))
	tour = UiTour.current
	await seconds(0.6)
	var all_text := ""
	for s in tour.steps:
		all_text += s["title"] + " " + s["text"] + " "
	check("it says LOCKED words never change, and how they look", all_text.contains("LOCKED words never change") and all_text.contains("padlock"))
	check("it says words change only while the cube is off", all_text.contains("When you can change words")
		and all_text.contains("Only while the cube is OFF") and all_text.contains("switch it off first"))
	check("it names the Tab key for the runes list", all_text.contains("Tab: your runes") and all_text.contains("Press Tab"), all_text)
	check("it says runes use mana", all_text.contains("mana"))
	await shot("tour_runes_1")
	for i in 4:
		await press_action("jump")
		await seconds(0.5)
		await shot("tour_runes_%d" % (i + 2))
	await press_action("jump")
	await frames(4)
	check("a five-card tour ends and sets its flag", state().has_flag("ui.tour.runes") and not get_tree().paused)

	# Come in any other way (here: straight into the Kilnworks), and the first
	# cube she reaches plays it
	state().clear_all()
	state().all_abilities = true
	await open_scene(Journey.KILN)
	await seconds(1.0)
	check("no rune tour before she reaches a cube", UiTour.current == null)
	var cube: RuneCube = lvl.get_node("R1/ForgeCube")
	var her: Node2D = lvl.get_node("Player")
	her.global_position = cube.global_position + Vector2(-30.0, -2.0)
	her.reset_physics_interpolation()
	check("reaching a cube plays the rune tour", await wait_until(func(): return UiTour.current != null and UiTour.current.id == "runes", 6.0))
	await press_action("pause")
	await frames(4)
	check("seen once, it is marked and the game goes on", state().has_flag("ui.tour.runes") and not get_tree().paused)
	her.global_position = cube.global_position + Vector2(-140.0, -2.0)
	await frames(10)
	her.global_position = cube.global_position + Vector2(-30.0, -2.0)
	await seconds(1.5)
	check("and never again", UiTour.current == null)
	# ...unless she asks: Esc, Echidna, Runes, How rune cubes work
	var menu: PauseMenu = lvl.get_node("PauseMenu")
	menu._set_open(true)
	await frames(4)
	var how: Node = menu._runes_list.get_child(0) if menu._runes_list.get_child_count() > 0 else null
	check("the menu's Runes list starts with How rune cubes work", how != null and how.text == "How rune cubes work")
	if how:
		(how.get_meta(&"action") as Callable).call()
	check("choosing it closes the menu and plays the tour again", not menu.is_open
		and await wait_until(func(): return UiTour.current != null and UiTour.current.id == "runes", 2.0))
	await shot("tour_runes_replay")
	await press_action("pause")
	await frames(4)
	check("and the game goes on after it", not get_tree().paused and UiTour.current == null)

	# Part 2: the goal card
	state().clear_all()
	state().all_abilities = true
	await open_scene(CHAPTER)
	check("Part 2's first room names the goal-card tour", lvl.get_node("R1").explainer == "objective")
	check("and it opens", await wait_until(func(): return UiTour.current != null, 14.0))
	tour = UiTour.current
	await seconds(0.6)
	rect = tour.target_rect(tour.steps[0])
	check("it frames the card in the top right", rect.end.x <= view.x and rect.position.x > view.x - 320.0 and rect.position.y < 40.0, str(rect))
	await shot("tour_objective")
	await press_action("pause")
	await frames(4)
	UiTour.enabled = false
	state().clear_all()
	state().all_abilities = true


func scenario_kindle() -> void:
	print("SCENARIO a flame to kindle at in every room")
	UiTour.enabled = false
	for path in [CHAPTER, "res://scenes/chapter/chapter_2.tscn"]:
		state().clear_all()
		state().all_abilities = true
		await open_scene(path)
		await frames(5)
		var flames := get_tree().get_nodes_in_group("kindle_point")
		var rooms := lvl.find_children("*", "Room", true, false)
		check("%s: has rooms and kindle points" % path.get_file(), not rooms.is_empty() and not flames.is_empty())
		for room: Room in rooms:
			var near := flames.filter(func(f): return f is Node2D and f.has_method("is_kindling") and f.is_kindling() and room.bounds.has_point(f.global_position))
			check("%s %s has a flame to kindle at" % [path.get_file(), room.title], not near.is_empty())
		var sample: KindleFlame = lvl.find_children("KindleFlame", "", true, false)[0]
		check("a room flame is a pixel sprite that kindles", sample.is_kindling() and sample.get_node("Figure") is AnimatedSprite2D
			and sample.find_children("*", "Polygon2D", true, false).is_empty())
		# A look at each added flame, from where the player arrives
		var player: Node2D = lvl.get("player")
		for flame: KindleFlame in lvl.find_children("KindleFlame", "", true, false):
			if player != null:
				player.teleport_to(flame.global_position + Vector2(70, -4))
				await seconds(3.0)
				await shot("kindle_%s_%s" % [path.get_file().get_basename(), flame.get_parent().name])
	state().clear_all()
	state().all_abilities = true


# ================================================================ waymarks

func scenario_waymarks() -> void:
	print("SCENARIO the Choir's waymarks")
	UiTour.enabled = false
	var settings := get_tree().root.get_node("Settings")
	var shown := {}
	for path in [TUTORIAL, CHAPTER, "res://scenes/chapter/chapter_2.tscn"]:
		state().clear_all()
		state().all_abilities = true
		await open_scene(path)
		await frames(5)
		var marks := get_tree().get_nodes_in_group("waymark")
		var name_of: String = path.get_file().get_basename()
		check("%s has waymarks" % name_of, marks.size() >= 8, str(marks.size()))
		check("%s: every waymark is a pixel sprite pointing a known way" % name_of, _marks_ok(marks))
		var tiles: Array = []
		var player: Node2D = lvl.get("player")
		if DisplayServer.get_name() == "headless":
			print("  SKIP waymark screenshot sheets in headless mode: ", name_of)
		for m: Waymark in marks:
			if player != null and DisplayServer.get_name() != "headless":
				player.teleport_to(Vector2(m.global_position.x - 140.0, 530.0))
				await seconds(2.2)
				await get_tree().process_frame
				var img := get_tree().root.get_texture().get_image()
				img.resize(384, 216, Image.INTERPOLATE_BILINEAR)
				tiles.append(img)
		for page in ceili(tiles.size() / 12.0):
			var sheet := Image.create(1152, 864, false, Image.FORMAT_RGB8)
			for i in range(page * 12, mini(tiles.size(), page * 12 + 12)):
				var k := i - page * 12
				sheet.blit_rect(tiles[i], Rect2i(0, 0, 384, 216), Vector2i((k % 3) * 384, (k / 3) * 216))
			sheet.save_png(ProjectSettings.globalize_path(SHOTS + "waymarks_%s_%d.png" % [name_of, page]))
		# hidden with guidance off
		settings.guidance = Settings.GUIDANCE_OFF
		await open_scene(path)
		await frames(3)
		check("%s: waymarks are hidden when guidance is off" % name_of, get_tree().get_nodes_in_group("waymark").all(func(m): return not m.visible))
		settings.guidance = Settings.GUIDANCE_FULL
	state().clear_all()
	state().all_abilities = true


# ================================================================ the title and the Long Stair

func scenario_longstair() -> void:
	print("SCENARIO the title screen and the Long Stair")
	var gs := state()
	gs.clear_all()
	await open_scene(TITLE)
	check("the parts list has an entry for the Long Stair", lvl.landing_button != null)
	gs.set_flag("tutorial.done")
	gs.set_flag("ch1.complete")
	gs.set_flag("ch2.complete")
	await open_scene(TITLE)
	check("once the Observatory is done, Continue leads to the Landing", lvl._continue_target() == Journey.LANDING)
	check("and the line under the menu counts the bells", lvl._progress.text.contains("0 of 4 bells"), lvl._progress.text)
	gs.set_flag("kiln.complete")
	await open_scene(TITLE)
	check("a bell is counted", lvl._progress.text.contains("1 of 4 bells"), lvl._progress.text)
	for f in ["cistern.complete", "lamps.complete", "galleries.complete"]:
		gs.set_flag(f)
	await open_scene(TITLE)
	check("with four the Eye is open", lvl._progress.text.contains("Eye is open"), lvl._progress.text)
	gs.set_flag("game.complete")
	await open_scene(TITLE)
	check("and a finished game says so", lvl._progress.text.contains("complete"), lvl._progress.text)
	lvl.landing_button.pressed.emit()
	check("the list's Long Stair entry opens the Landing", await wait_for_scene(Journey.LANDING))
	gs.clear_all()
	gs.all_abilities = true

# ================================================================ draw order

func scenario_layers() -> void:
	print("SCENARIO what draws over what")
	await open_scene(CHAPTER)
	var slime: Node2D = lvl.get_node("R2/BellSlime")
	var front := lvl.find_children("FrontVines", "", true, false)
	var front_z: int = front[0].z_index if not front.is_empty() else 40
	check("slimes draw above props, grates and the thorn frame", slime.z_index > front_z, "%d vs %d" % [slime.z_index, front_z])
	var signs := lvl.find_children("*", "Node2D", true, false).filter(func(n): return n is TutorialSign)
	check("sign text uses a screen layer and leaves the playfield clear", not signs.is_empty() and signs.all(func(s): return s._ui.layer == 2 and s.z_index < front_z))
	var number: Node2D = load("res://scenes/damage_number.tscn").instantiate()
	lvl.add_child(number)
	number.setup(3, false)
	await frames(1)
	check("damage numbers still show over a slime", number.z_index > slime.z_index)
	number.queue_free()
	var card := TitleCard.show_card(lvl, "ACT I", "The Toll", "Chapter 1", 0.5)
	await frames(2)
	var height := get_tree().root.get_visible_rect().size.y
	check("act and lesson cards sit high, clear of the hanging signs", card._box.get_global_rect().end.y < height * 0.4,
		"card ends at %.0f of %.0f" % [card._box.get_global_rect().end.y, height])


func _marks_ok(marks: Array) -> bool:
	for m in marks:
		if not (m.get_node("Art/Chalk") is AnimatedSprite2D) or not (m.direction in ["right", "left", "up", "down"]):
			return false
		if not m.find_children("*", "Polygon2D", true, false).is_empty():
			return false
	return true
