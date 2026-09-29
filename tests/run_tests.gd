extends SceneTree

## Automated gameplay tests. Run from the project folder:
##   godot --path . --fixed-fps 60 --script res://tests/run_tests.gd -- [suite] [scenario]
## suite: "tutorial", "chapter" or "all" (default). scenario: optional filter.
## Suites are loaded only after the engine (and its autoloads) has started, so
## they may use every game class. The exit code is non-zero if anything fails.

var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var suite_name: String = args[0] if args.size() > 0 else "all"
	var scenario: String = args[1] if args.size() > 1 else ""
	# Tests must never read or overwrite a player's real save file
	var game_state := root.get_node("GameState")
	game_state.persist_to_disk = false
	game_state.clear_all()
	# Tests check audio state, not sound; keep the speakers quiet while they run
	AudioServer.set_bus_mute(0, true)

	var names: Array = ["tutorial", "chapter", "presentation"] if suite_name == "all" else [suite_name]
	var passed := 0
	var failed := 0
	for n in names:
		var path := "res://tests/%s_suite.gd" % n
		if not ResourceLoader.exists(path):
			continue
		var suite: Node = load(path).new()
		suite.process_mode = Node.PROCESS_MODE_ALWAYS
		root.add_child(suite)
		await suite.run_suite(scenario)
		passed += suite.passed
		failed += suite.failed
		suite.queue_free()
	print("RESULT passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
