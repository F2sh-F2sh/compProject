extends SceneTree

## Automated gameplay tests. Run from the project folder:
##   godot --path . --fixed-fps 60 --script res://tests/run_tests.gd -- [suite] [scenario]
## suite: tutorial, chapter, presentation, experience, rune, wing, prologue, adversarial or all
## (default). scenario: optional filter.
## Suites are loaded only after the engine (and its autoloads) has started, so
## they may use every game class. The exit code is non-zero if anything fails.

var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("BACKGROUND: no desktop input or screenshots; targeted projectile helpers bypass mouse aiming, cost and cooldown.")
	var args := OS.get_cmdline_user_args()
	var suite_name: String = args[0] if args.size() > 0 else "all"
	var scenario: String = args[1] if args.size() > 1 else ""
	# Keep the authored viewport used by the existing story regressions.
	# Daily acceptance also exercises the actual handheld window size.
	root.size = DisplayServer.window_get_size() if suite_name == "daily" and DisplayServer.get_name() != "headless" else Vector2i(1152, 648)
	# Tests must never read or overwrite a player's real save file
	var game_state := root.get_node("GameState")
	game_state.persist_to_disk = false
	# Echidna has to earn her spells in the game; the tests use them from the start
	game_state.all_abilities = true
	# The roaming creatures stay away from the puzzle routes (their own scenarios bring them back)
	game_state.calm_creatures = true
	# (loaded at run time: UiTour needs the autoloads, which are not up while this script compiles)
	var ui_tour: GDScript = load("res://scripts/ui/ui_tour.gd")
	ui_tour.set("enabled", false)
	# The admin switch (every level open, for testing by hand) is off: the tests
	# check the real locks
	var journey: GDScript = load("res://scripts/story/journey.gd")
	journey.set("admin_unlock", false)
	game_state.clear_all()
	var settings := root.get_node("Settings")
	settings.persist_to_disk = false
	# (loaded at run time for the same reason: it reaches the autoloads)
	var daily_store: GDScript = load("res://scripts/daily/daily_store.gd")
	daily_store.set("persist", false)
	load("res://scripts/daily/daily_calibration.gd").set("persist", false)
	# hint skulls answer at once (one wing scenario checks the wait)
	settings.assist_instant_hints = true
	# The player's own settings file must not change what the tests see
	settings.guidance = settings.GUIDANCE_FULL
	settings.brightness = settings.Brightness.NORMAL
	settings.reduce_motion = false
	# Tests press the default keys, whatever the player has rebound
	settings.bindings.clear()
	InputMap.load_from_project_settings()
	settings.set_graphics(2)  # High
	settings.show_fps = false
	# Smooth motion (physics interpolation) is on, as it is by default
	settings.set_smooth_motion(true)
	settings.assist_damage = 1.0
	settings.assist_infinite_mana = false
	settings.assist_auto_sprint = false
	settings.assist_toggle_crouch = false
	# A found page would stop a scripted run to be read; tests use the toast
	PageReader.enabled = false
	if settings.fullscreen:
		settings.fullscreen = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# Tests check audio state, not sound; keep the speakers quiet while they run
	AudioServer.set_bus_mute(0, true)

	var names: Array = ["tutorial", "chapter", "presentation", "experience", "rune", "wing", "prologue", "adversarial", "polish", "daily"] if suite_name == "all" else [suite_name]
	var passed := 0
	var failed := 0
	for n in names:
		var path := "res://tests/%s_suite.gd" % n
		if not ResourceLoader.exists(path):
			push_error("Unknown test suite: " + str(n))
			failed += 1
			continue
		var suite_script: Script = load(path)
		if suite_script == null or not suite_script.can_instantiate():
			push_error("Cannot load test suite: " + str(n))
			failed += 1
			continue
		var suite: Node = suite_script.new()
		suite.process_mode = Node.PROCESS_MODE_ALWAYS
		root.add_child(suite)
		await suite.run_suite(scenario)
		if "completed" in suite and not suite.completed:
			print("  FAIL suite aborted before completion: ", n)
			failed += 1
		passed += suite.passed
		failed += suite.failed
		suite.queue_free()
	print("RESULT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
