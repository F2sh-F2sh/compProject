extends Node

## Tests for the rune-cube system and Chapter 2 ("The Sealed Observatory").
## Rules are checked directly; every room is solved with simulated input and
## the player's real movement, through the same screens a player uses.
## Run through tests/run_tests.gd:  -- rune [scenario]

const LEVEL := "res://scenes/chapter/chapter_2.tscn"
const DT := 1.0 / 60.0
const SHOTS := "user://test_shots/"

var lvl: Node
var player: CharacterBody2D
var manager: RuneManager
var passed := 0
var failed := 0
var only := ""


func run_suite(filter: String) -> void:
	only = filter
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS))
	await get_tree().process_frame
	var scenarios := {
		"look": scenario_look,
		"recipes": scenario_recipes,
		"r1": scenario_room1,
		"r2": scenario_room2,
		"r3": scenario_room3,
		"r4": scenario_room4,
		"r5": scenario_room5,
		"r6": scenario_room6,
		"r7": scenario_room7,
		"r8": scenario_room8,
		"effects": scenario_effects,
		"carry": scenario_carry_rules,
		"mana": scenario_mana,
		"overview": scenario_overview,
		"journal": scenario_journal,
		"layout": scenario_layout,
		"full": scenario_full_run,
	}
	for key in scenarios:
		if only == key or (only == "" and key != "look"):
			await scenarios[key].call()
	release_all()
	get_tree().paused = false
	print("rune suite: passed=%d failed=%d" % [passed, failed])


# ================================================================ helpers

func check(label: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
		print("  PASS ", label, "  ", detail)
	else:
		failed += 1
		print("  FAIL ", label, "  ", detail)


func release_all() -> void:
	for a in ["move_left", "move_right", "jump", "crouch", "sprint", "shoot", "heal", "reload", "interact", "echo",
			"rune_carry", "rune_overview"]:
		Input.action_release(a)


func game_state() -> Node:
	return get_tree().root.get_node("GameState")


func load_level(keep_progress := false) -> void:
	release_all()
	get_tree().paused = false
	if not keep_progress:
		game_state().clear_all()
	if is_instance_valid(get_tree().current_scene):
		get_tree().current_scene.queue_free()
	await get_tree().process_frame
	lvl = load(LEVEL).instantiate()
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	await get_tree().process_frame
	await get_tree().physics_frame
	player = lvl.get_node("Player")
	manager = RuneManager.get_for(get_tree())
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


func node(path: String) -> Node:
	return lvl.get_node(path)


func place(pos: Vector2) -> void:
	player.teleport_to(pos)
	await frames(8)


func enter_room(id: String) -> void:
	await place(node(id).entry_spawn)
	await frames(10)


func walk_to(x: float, sprint := false, timeout := 12.0) -> bool:
	var dir := "move_right" if x > player.global_position.x else "move_left"
	Input.action_press(dir)
	if sprint:
		Input.action_press("sprint")
	var ok := await wait_until(func():
		return player.global_position.x >= x if dir == "move_right" else player.global_position.x <= x, timeout)
	Input.action_release(dir)
	Input.action_release("sprint")
	await frames(12)
	return ok


## Keeps moving toward x, hopping at each take-off x on the way.
func run_to(x: float, takeoffs: Array = [], timeout := 10.0) -> bool:
	var right := x > player.global_position.x
	var dir := "move_right" if right else "move_left"
	Input.action_press(dir)
	var ok := true
	for t in takeoffs:
		ok = ok and await wait_until(func(): return player.is_on_floor() and (player.global_position.x >= t if right else player.global_position.x <= t), 6.0)
		await tap_action("jump")
		ok = ok and await wait_until(func(): return not player.is_on_floor(), 0.4)
		ok = ok and await wait_until(func(): return player.is_on_floor(), 2.5)
	ok = ok and await wait_until(func(): return player.global_position.x >= x if right else player.global_position.x <= x, timeout)
	Input.action_release(dir)
	await frames(10)
	return ok


## A real input event (so screens listening for events see it too).
func tap_action(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await frames(2)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await frames(2)


func face(dir: String) -> void:
	Input.action_press(dir)
	await frames(2)
	Input.action_release(dir)
	await frames(6)


## Uses whatever is in reach (the nearest interactable) and waits a moment.
func interact() -> void:
	await tap_action("interact")
	await frames(3)


func shot(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOTS + file_name + ".png"))


## Opens the cube's assembly screen the way a player does: walks up and uses it.
func open_cube(cube: RuneCube, from_x := NAN) -> bool:
	var stand := cube.global_position.x - 26.0 if is_nan(from_x) else from_x
	await walk_to(stand)
	await interact()
	return manager.assembly.is_open and manager.assembly.cube == cube


# ================================================================ scenarios

func scenario_recipes() -> void:
	print("-- recipes: what is supported, what is refused and why")
	var ok_push := RuneRecipe.from_key("wind/push/right/normal")
	check("wind push right normal is valid", RuneBook.is_valid(ok_push))
	var broken := RuneRecipe.from_key("wind/push/-/normal")
	check("a missing quadrant is refused with its name", RuneBook.problem(broken).contains("direction"), RuneBook.problem(broken))
	var up_push := RuneRecipe.from_key("wind/push/up/normal")
	check("Push can't blow Up (reason lists the directions it can)", RuneBook.problem(up_push).contains("can't point Up")
		and RuneBook.problem(up_push).contains("Right"), RuneBook.problem(up_push))
	var bad_form := RuneRecipe.from_key("fire/lift/up/normal")
	check("Fire can't take the form Lift", RuneBook.problem(bad_form).contains("can't take the form"), RuneBook.problem(bad_form))
	var bad_mod := RuneRecipe.from_key("wind/push/right/split")
	check("Push can't be Split", RuneBook.problem(bad_mod).contains("can't be Split"), RuneBook.problem(bad_mod))
	# Every supported combination turns into a complete, described spell
	var count := 0
	var all_ok := true
	for key in RuneBook.SUPPORTED:
		var spec: Array = RuneBook.SUPPORTED[key]
		for d in spec[0]:
			for m in spec[1]:
				var r := RuneRecipe.make(StringName(key.get_slice("/", 0)), StringName(key.get_slice("/", 1)), d, m)
				var desc := RuneBook.describe(r)
				var s := RuneBook.spell(r)
				count += 1
				if not RuneBook.is_valid(r) or desc["title"] == "" or desc["cost"] == "" or s["key"] != key:
					all_ok = false
					print("    bad: ", r.to_key(), " ", desc)
	check("every supported combination is valid and described", all_ok, "%d combinations" % count)
	var strong := RuneBook.spell(RuneRecipe.from_key("wind/push/right/strong"))
	var normal := RuneBook.spell(ok_push)
	check("Strong doubles the force", is_equal_approx(strong["force"], normal["force"] * 2.0))
	check("Long adds reach, not force", RuneBook.spell(RuneRecipe.from_key("wind/push/right/long"))["reach"] > normal["reach"]
		and RuneBook.spell(RuneRecipe.from_key("wind/push/right/long"))["force"] == normal["force"])
	check("Large widens the area", RuneBook.spell(RuneRecipe.from_key("wind/push/right/large"))["width"] > normal["width"])
	check("dungeon-powered text says it costs nothing", RuneBook.describe(ok_push, true)["cost"].contains("nothing"))
	check("player-powered text states the upkeep", RuneBook.describe(ok_push)["cost"].contains("3 mana per second"),
		RuneBook.describe(ok_push)["cost"])
	var a := RuneRecipe.from_key("wind/push/left/normal")
	var b := a.copy()
	b.direction = &"right"
	check("a copied recipe is independent", a.direction == &"left")
	check("tuning: one wind beats a crate's grip, not a stone's", RuneBook.WIND_FORCE > 0.5 * 1.0 * 980.0
		and RuneBook.WIND_FORCE < 0.5 * 3.0 * 980.0 and 2.0 * RuneBook.WIND_FORCE > 0.5 * 3.0 * 980.0)


# ---------------------------------------------------------------- Room 1

func solve_r1() -> void:
	var cube: RuneCube = node("R1/BrokenCube")
	var crate: WindBody = node("R1/Crate")
	var plate = node("R1/CratePlate")
	var exit_gate = node("R1/ExitGate")
	check("R1 the cube starts broken and off", not cube.is_active and not cube.recipe.is_complete())
	check("R1 the player does not know Right yet", not RuneManager.knows(&"right", get_tree()))
	check("R1 opening the cube pauses the game", await open_cube(cube) and get_tree().paused)
	check("R1 the broken quadrant is selected first", manager.assembly.selected_kind == RuneFragments.Kind.DIRECTION)
	manager.assembly.toggle_cube()
	check("R1 a broken rune won't switch on and says why", not cube.is_active and manager.assembly._state.text.contains("direction"),
		manager.assembly._state.text)
	check("R1 Right is not on offer yet", manager.assembly._palette_buttons.all(func(bt): return not bt.text.contains("Right")))
	await tap_action("ui_cancel")
	check("R1 Esc closes the screen and resumes", not manager.assembly.is_open and not get_tree().paused)
	# Read the tablet
	await walk_to(node("R1/TabletRight").global_position.x - 10.0)
	await interact()
	check("R1 the tablet teaches Right", RuneManager.knows(&"right", get_tree()))
	check("R1 the essence quadrant is carved in (locked)", cube.is_slot_locked(RuneFragments.Kind.ESSENCE))
	check("R1 open the cube again", await open_cube(cube))
	manager.assembly.choose(&"right")
	check("R1 the rune now reads wind/push/right/normal", cube.recipe.to_key() == "wind/push/right/normal", cube.recipe.to_key())
	check("R1 the screen describes the spell and its (free) cost", manager.assembly._title.text.to_lower().contains("rightward wind")
		and manager.assembly._cost.text.contains("nothing"), manager.assembly._title.text + " / " + manager.assembly._cost.text)
	var mana_before: int = player.current_mana
	manager.assembly.toggle_cube()
	check("R1 switched on, the screen closes", cube.is_active and not manager.assembly.is_open and not get_tree().paused)
	var start_x := crate.global_position.x
	check("R1 the crate slides onto the plate", await wait_until(func(): return plate.is_pressed, 6.0),
		"crate x=%.0f (from %.0f)" % [crate.global_position.x, start_x])
	await wait_until(func(): return absf(crate.velocity.x) < 1.0, 3.0)
	check("R1 the kerb stops the crate on the plate", absf(crate.global_position.x - 812.0) < 8.0 and plate.is_pressed, "x=%.0f" % crate.global_position.x)
	check("R1 plate opens the gate", await wait_until(func(): return exit_gate.open_amount >= 1.0, 3.0))
	check("R1 a dungeon-powered cube cost no mana", player.current_mana >= mana_before)
	check("R1 room cleared", node("R1").is_cleared())
	await run_to(cx(20), [cube.global_position.x - 30.0, 760.0])
	check("R1 walked out into room 2", lvl.current_room == node("R2"), "x=%.0f" % player.global_position.x)
	check("R1 solution saved once she has gone through", game_state().has_flag("ch2.r1.solved"))


func scenario_room1() -> void:
	print("-- room 1: The Broken Inscription")
	await load_level()
	await enter_room("R1")
	await solve_r1()
	# The plate ignores the player
	await load_level()
	await place(Vector2(790, 530))
	await frames(20)
	check("R1 the crate plate ignores the player", not node("R1/CratePlate").is_pressed)


# ---------------------------------------------------------------- Room 2

func solve_r2() -> void:
	var fixed: RuneCube = node("R2/FixedCube")
	var loose: RuneCube = node("R2/LooseCube")
	var stone_block: WindBody = node("R2/Stone")
	var plate = node("R2/StonePlate")
	var exit_gate = node("R2/ExitGate")
	check("R2 open the fixed cube", await open_cube(fixed))
	manager.assembly.toggle_cube()
	check("R2 the fixed cube blows", fixed.is_active)
	var start_x := stone_block.global_position.x
	await seconds(1.5)
	check("R2 one wind can't move the stone", absf(stone_block.global_position.x - start_x) < 1.0,
		"moved %.1f" % (stone_block.global_position.x - start_x))
	check("R2 the stone strains (feedback)", stone_block.is_straining)
	check("R2 net force on the stone is one wind", manager.net_forces.get(stone_block, Vector2.ZERO).is_equal_approx(Vector2(1200, 0)),
		str(manager.net_forces.get(stone_block)))
	# Over the stone, the plate and the kerb to the far cube
	check("R2 reach the loose cube", await run_to(loose.global_position.x - 34.0, [fixed.global_position.x - 30.0, start_x - 64.0, 1880.0]),
		"x=%.0f" % player.global_position.x)
	await face("move_right")
	await tap_action("rune_carry")
	check("R2 pick up the loose cube", loose.is_carried and manager.carrier.held == loose)
	# Back over the kerb and the stone, then turn to face right
	check("R2 carry it back", await run_to(1478.0, [2000.0, start_x + 76.0]), "x=%.0f" % player.global_position.x)
	await walk_to(1490.0)
	await frames(4)
	check("R2 the ghost shows a valid spot", manager.carrier.valid, manager.carrier.reason)
	await tap_action("rune_carry")
	check("R2 set it down beside the fixed cube", not loose.is_carried and absf(loose.global_position.y - 534.0) < 2.0,
		"at %s" % loose.global_position)
	var fixed_key := fixed.recipe.to_key()
	await open_cube(loose)
	check("R2 the loose cube's screen opens", manager.assembly.is_open and manager.assembly.cube == loose,
		"cube=%s" % (manager.assembly.cube.name if manager.assembly.cube else "none"))
	manager.assembly.select_kind(RuneFragments.Kind.DIRECTION)
	manager.assembly.choose(&"right")
	check("R2 editing one cube leaves the other unchanged", fixed.recipe.to_key() == fixed_key and loose.recipe.direction == &"right")
	manager.assembly.toggle_cube()
	await frames(2)
	check("R2 two winds add up on the stone (2400, not normalised)",
		manager.net_forces.get(stone_block, Vector2.ZERO).is_equal_approx(Vector2(2400, 0)), str(manager.net_forces.get(stone_block)))
	check("R2 the stone slides onto the heavy plate", await wait_until(func(): return plate.is_pressed, 8.0),
		"x=%.0f" % stone_block.global_position.x)
	check("R2 plate opens the gate", await wait_until(func(): return exit_gate.open_amount >= 1.0, 3.0))
	await frames(30)
	await run_to(cx(41) + 20.0, [loose.global_position.x - 30.0, 1826.0], 14.0)
	check("R2 walked out into room 3", lvl.current_room == node("R3"), "x=%.0f" % player.global_position.x)
	check("R2 solution saved once she has gone through", game_state().has_flag("ch2.r2.solved"))


func scenario_room2() -> void:
	print("-- room 2: Too Heavy for One")
	await load_level()
	RuneManager.learn(&"right")
	await enter_room("R2")
	await solve_r2()


# ---------------------------------------------------------------- Room 3

func solve_r3() -> void:
	var lift: RuneCube = node("R3/PitCube")
	var lectern: Node2D = node("R3/Lectern")
	await walk_to(node("R3/TabletLift").global_position.x - 10.0)
	await interact()
	check("R3 the tablet teaches Lift", RuneManager.knows(&"lift", get_tree()))
	await walk_to(lectern.global_position.x - 8.0)
	await interact()
	check("R3 the lectern opens the pit cube's screen", manager.assembly.is_open and manager.assembly.cube == lift)
	manager.assembly.toggle_cube()
	check("R3 push-upward is refused", not lift.is_active and manager.assembly._state.text.contains("Up"), manager.assembly._state.text)
	check("R3 only the form can be changed", lift.is_slot_locked(RuneFragments.Kind.DIRECTION) and not lift.is_slot_locked(RuneFragments.Kind.FORM))
	manager.assembly.select_kind(RuneFragments.Kind.FORM)
	manager.assembly.choose(&"lift")
	manager.assembly.toggle_cube()
	check("R3 the updraft rises", lift.is_active)
	# Jump from the edge into the column, ride it up, drift onto the wall
	await walk_to(2930.0)
	Input.action_press("move_right")
	await tap_action("jump")
	var top := 999.0
	var t := 0.0
	while t < 6.0 and not (player.is_on_floor() and player.global_position.y < 300.0):
		top = minf(top, player.global_position.y)
		# Hover over the middle until high enough, then drift right
		if player.global_position.x > 3110.0 and player.global_position.y > 220.0:
			Input.action_release("move_right")
		else:
			Input.action_press("move_right")
		await get_tree().physics_frame
		t += DT
	Input.action_release("move_right")
	await frames(10)
	check("R3 the updraft carries her up over the wall", top < 240.0, "highest feet y=%.0f" % top)
	check("R3 landed on top of the wall", player.is_on_floor() and player.global_position.y < 290.0,
		"at %s" % player.global_position.round())
	check("R3 room cleared", await wait_until(func(): return node("R3").is_cleared(), 2.0))


func scenario_room3() -> void:
	print("-- room 3: Across the Teeth")
	await load_level()
	await enter_room("R3")
	await solve_r3()


# ---------------------------------------------------------------- Room 4

func solve_r4() -> void:
	var c: RuneCube = node("R4/LooseCube")
	var block: WindBody = node("R4/Stone")
	var wall: CrackedWall = node("R4/CrackedWall")
	await walk_to(node("R4/TabletStrong").global_position.x - 10.0)
	await interact()
	check("R4 the tablet teaches Strong", RuneManager.knows(&"strong", get_tree()))
	# First, the way it starts: its wind lets go of the stone before the wall
	check("R4 open the loose cube", await open_cube(c))
	check("R4 the cube says it draws on your mana", manager.assembly._cost.text.contains("mana per second"), manager.assembly._cost.text)
	manager.assembly.select_kind(RuneFragments.Kind.MODIFIER)
	manager.assembly.choose(&"strong")
	check("R4 strong costs 8 a second, stated", manager.assembly._cost.text.contains("8 mana per second"), manager.assembly._cost.text)
	await tap_action("ui_cancel")
	# Carry it right behind the stone for a full run-up
	await face("move_right")
	await tap_action("rune_carry")
	check("R4 pick up the cube", c.is_carried)
	await walk_to(block.global_position.x - 90.0)
	await tap_action("rune_carry")
	check("R4 set it down behind the stone", not c.is_carried, "at %.0f" % c.global_position.x)
	var mana_before: int = player.current_mana
	check("R4 open it again", await open_cube(c))
	manager.assembly.toggle_cube()
	check("R4 the strong wind blows", c.is_active)
	check("R4 the stone slams into the wall and breaks it", await wait_until(func(): return wall.is_broken, 5.0),
		"stone x=%.0f, last impact %.0f" % [block.global_position.x, wall.last_impact])
	check("R4 a player-powered rune spent her mana", player.current_mana < mana_before, "%d -> %d" % [mana_before, player.current_mana])
	check("R4 the broken wall is saved", game_state().has_flag("ch2.r4.wall"))
	await tap_action("rune_overview")
	manager.overview.deactivate_all()
	await tap_action("rune_overview")
	check("R4 room cleared", node("R4").is_cleared())


func scenario_room4() -> void:
	print("-- room 4: The Fractured Seal")
	await load_level()
	await enter_room("R4")
	await solve_r4()
	# A hit that isn't hard enough only thuds
	await load_level()
	var wall: CrackedWall = node("R4/CrackedWall")
	var crate := WindBody.new()
	crate.position = Vector2(1560, 534)
	wall.on_impact(crate, 600.0, 1.0)
	check("R4 a fast crate (600 x 1) doesn't break the wall", not wall.is_broken)
	wall.on_impact(crate, 300.0, 3.0)
	check("R4 a stone at 300 px/s (900) does", wall.is_broken)
	crate.free()


# ---------------------------------------------------------------- Room 5

func solve_r5() -> void:
	var c: RuneCube = node("R5/EdgeCube")
	await walk_to(node("R5/TabletBridge").global_position.x - 10.0)
	await interact()
	check("R5 the tablet teaches Bridge", RuneManager.knows(&"bridge", get_tree()))
	# The cube is set into the floor: stand on it
	await walk_to(c.global_position.x - 4.0)
	await interact()
	check("R5 standing on the edge cube opens it", manager.assembly.is_open and manager.assembly.cube == c)
	manager.assembly.choose(&"bridge")
	check("R5 the rune reads ice/bridge/right/long", c.recipe.to_key() == "ice/bridge/right/long", c.recipe.to_key())
	check("R5 a timed bridge costs 12 once", manager.assembly._cost.text.contains("12 mana to cast"), manager.assembly._cost.text)
	var mana_before: int = player.current_mana
	manager.assembly.toggle_cube()
	await frames(2)
	var bridge := c.get_node_or_null("IceBridge") as IceBridge
	check("R5 the ice bridge forms across the pit", bridge != null and bridge.length > 280.0,
		"length %.0f" % (bridge.length if bridge else 0.0))
	check("R5 it cost 12 mana, once", mana_before - player.current_mana == 12, "%d -> %d" % [mana_before, player.current_mana])
	check("R5 walk across the bridge", await walk_to(5900.0, false, 6.0), "x=%.0f y=%.0f" % [player.global_position.x, player.global_position.y])
	check("R5 no fall into the pit", recoveries_since == 0 and player.global_position.y < 540.0)
	check("R5 across the pit (step done)", await wait_until(func(): return node("R5").is_cleared(), 2.0))
	check("R5 the bridge melts after its time", await wait_until(func(): return not c.is_active and c.get_node_or_null("IceBridge") == null, 11.0))


var recoveries_since := 0


func scenario_room5() -> void:
	print("-- room 5: The Frozen Crossing")
	await load_level()
	recoveries_since = 0
	player.hazard_recovery.recovery_started.connect(func(): recoveries_since += 1)
	await enter_room("R5")
	await solve_r5()


# ---------------------------------------------------------------- Room 6

func solve_r6() -> void:
	var beam_cube: RuneCube = node("R6/CeilingCube")
	var watcher = node("R6/Watcher")
	var plate_a = node("R6/PlateA")
	var plate_b = node("R6/PlateB")
	var c: RuneCube = node("R6/LooseCube")
	var exit_gate = node("R6/ExitGate")
	RuneManager.learn(&"strong")
	await walk_to(node("R6/TabletDown").global_position.x - 10.0)
	await interact()
	check("R6 the tablet teaches Down", RuneManager.knows(&"down", get_tree()))
	await walk_to(node("R6/Lectern").global_position.x - 6.0)
	await interact()
	check("R6 the lectern opens the ceiling cube", manager.assembly.is_open and manager.assembly.cube == beam_cube)
	manager.assembly.choose(&"down")
	manager.assembly.toggle_cube()
	check("R6 the beam shines down", beam_cube.is_active and beam_cube.effect is RuneBeam)
	# Out of the watcher's sight, so it goes back to its rounds
	await walk_to(6500.0)
	check("R6 the watcher turns to stone under the beam, on plate A",
		await wait_until(func(): return watcher.is_frozen and plate_a.is_pressed, 25.0),
		"watcher x=%.0f frozen=%s" % [watcher.global_position.x, watcher.is_frozen])
	# Over the frozen watcher to the wind cube behind the stone
	check("R6 reach the loose cube", await run_to(c.global_position.x - 26.0, [watcher.global_position.x - 50.0]),
		"x=%.0f" % player.global_position.x)
	check("R6 open the loose cube", await open_cube(c))
	manager.assembly.select_kind(RuneFragments.Kind.MODIFIER)
	manager.assembly.choose(&"strong")
	manager.assembly.toggle_cube()
	check("R6 the stone slides onto plate B", await wait_until(func(): return plate_b.is_pressed, 6.0),
		"stone x=%.0f" % node("R6/Stone").global_position.x)
	check("R6 both plates held: the gate opens", await wait_until(func(): return exit_gate.open_amount >= 1.0, 4.0))


func scenario_room6() -> void:
	print("-- room 6: The Watcher's Lock")
	await load_level()
	await enter_room("R6")
	await solve_r6()


# ---------------------------------------------------------------- Room 7

func solve_r7() -> void:
	var strong_cube: RuneCube = node("R7/StrongCube")
	var normal_cube: RuneCube = node("R7/NormalCube")
	var pedestal = node("R7/Pedestal")
	var statue: WindBody = node("R7/Statue")
	var p = node("R7/StatuePlate")
	var exit_gate = node("R7/ExitGate")
	await frames(10)
	check("R7 the warding holds mana to 10", player.current_mana <= 10 and manager.mana_cap() == 10,
		"mana %d cap %d" % [player.current_mana, manager.mana_cap()])
	# From her own mana the strong rune won't even start
	check("R7 open the strong cube", await open_cube(strong_cube))
	manager.assembly.toggle_cube()
	check("R7 the strong rune can't start on 10 mana (needs 16)", not strong_cube.is_active
		and manager.assembly._state.text.contains("16"), manager.assembly._state.text)
	await tap_action("ui_cancel")
	# Into the pedestal
	await face("move_right")
	await tap_action("rune_carry")
	check("R7 pick up the strong cube", strong_cube.is_carried)
	await run_to(pedestal.global_position.x - 30.0, [normal_cube.global_position.x - 30.0])
	await frames(3)
	check("R7 the ghost snaps into the pedestal", manager.carrier.valid and manager.carrier.target.x == pedestal.global_position.x,
		"target %s, %s" % [manager.carrier.target, manager.carrier.reason])
	await tap_action("rune_carry")
	check("R7 the strong cube stands in the pedestal and is fed by it", strong_cube.pedestal == pedestal and strong_cube.fed_by_dungeon())
	# The normal cube, just behind the statue
	await walk_to(normal_cube.global_position.x + 34.0)
	await face("move_left")
	await tap_action("rune_carry")
	check("R7 pick up the normal cube", normal_cube.is_carried)
	await run_to(statue.global_position.x - 90.0, [pedestal.global_position.x - 40.0])
	await face("move_right")
	await tap_action("rune_carry")
	check("R7 set the normal cube behind the statue", not normal_cube.is_carried, "at %.0f" % normal_cube.global_position.x)
	# Strong first (free), then normal (3 a second)
	await walk_to(strong_cube.global_position.x + 26.0)
	await face("move_left")
	await interact()
	manager.assembly.toggle_cube()
	check("R7 the pedestal cube starts for free", strong_cube.is_active and manager.total_upkeep == 0.0)
	check("R7 open the normal cube", await open_cube(normal_cube, normal_cube.global_position.x - 26.0))
	manager.assembly.toggle_cube()
	await frames(2)
	check("R7 both winds blow; she pays 3 a second", normal_cube.is_active and is_equal_approx(manager.total_upkeep, 3.0), str(manager.total_upkeep))
	check("R7 the statue slides onto the plate", await wait_until(func(): return p.is_pressed, 6.0),
		"statue x=%.0f" % statue.global_position.x)
	check("R7 the gate opens", await wait_until(func(): return exit_gate.open_amount >= 1.0, 4.0))


func scenario_room7() -> void:
	print("-- room 7: The Limited Circuit")
	await load_level()
	await enter_room("R7")
	await solve_r7()


# ---------------------------------------------------------------- Room 8

func solve_r8() -> void:
	var portal: RuneCube = node("R8/PortalCube")
	var fire: RuneCube = node("R8/FireCube")
	var seal = node("R8/Seal")
	await walk_to(node("R8/TabletUpRight").global_position.x - 10.0)
	await interact()
	check("R8 the tablet teaches Up-Right", RuneManager.knows(&"up_right", get_tree()))
	# From where it starts the far side is in the air
	portal.set_slot(RuneFragments.Kind.DIRECTION, &"up_right")
	var far := RunePortal.far_centre(portal, RuneBook.spell(portal.recipe))
	check("R8 from its start the portal would open short of the balcony", far.x < 155 * 64.0, "far side %s" % far.round())
	# Over the fire cube, pick up the portal cube, carry it to the balcony wall
	await run_to(portal.global_position.x - 34.0, [fire.global_position.x - 30.0])
	await face("move_right")
	await tap_action("rune_carry")
	check("R8 pick up the portal cube", portal.is_carried)
	await walk_to(9700.0)
	await tap_action("rune_carry")
	check("R8 set it down near the wall", not portal.is_carried, "at %.0f" % portal.global_position.x)
	check("R8 open the portal cube", await open_cube(portal))
	manager.assembly.toggle_cube()
	check("R8 the portal opens", portal.is_active and portal.effect is RunePortal, manager.assembly._state.text)
	# Step back, then jump into the doorway over the cube
	await walk_to(portal.global_position.x - 60.0)
	Input.action_press("move_right")
	await tap_action("jump")
	var through := await wait_until(func(): return player.global_position.y < 300.0, 2.0)
	check("R8 the doorway carries her up and over", through, "at %s" % player.global_position.round())
	await wait_until(func(): return player.is_on_floor(), 2.0)
	Input.action_release("move_right")
	await frames(10)
	check("R8 landed on the balcony", player.is_on_floor() and player.global_position.y < 290.0, "at %s" % player.global_position.round())
	await walk_to(seal.global_position.x - 10.0)
	await interact()
	check("R8 the seal opens", seal.is_open)
	check("R8 the chapter completes", await wait_until(func(): return game_state().has_flag("ch2.complete"), 15.0))


func scenario_room8() -> void:
	print("-- room 8: The Sealed Observatory")
	await load_level()
	await enter_room("R8")
	await solve_r8()
	get_tree().paused = false


# ---------------------------------------------------------------- effects

## A cube made on the spot (for rule checks away from the rooms).
func make_cube(parent: Node, at: Vector2, recipe: String, dungeon := true) -> RuneCube:
	var c := RuneCube.new()
	c.start_recipe = recipe
	c.dungeon_powered = dungeon
	c.position = at
	parent.add_child(c)
	await frames(3)
	return c


func scenario_effects() -> void:
	print("-- effects: gust, fire, freeze, glow, lift, beam and mirror, persist bridge, portal refusal, delay, repeat")
	await load_level()
	await enter_room("R2")
	var room := node("R2")
	# Gust: one shove, then it coasts to a stop
	var crate := WindBody.new()
	crate.position = Vector2(1560, 534)
	room.add_child(crate)
	crate.global_position = Vector2(1560, 534)
	await frames(20)
	var gust := await make_cube(room, Vector2(1500, 534), "wind/burst/right/normal")
	check("gust starts", gust.activate(false) == "")
	await frames(2)
	check("a gust shoves the crate once", crate.velocity.x > 100.0, "vx=%.0f" % crate.velocity.x)
	check("the gust cube is free again after firing", not gust.is_active)
	await seconds(1.5)
	check("the crate slides to a stop", absf(crate.velocity.x) < 1.0 and crate.global_position.x > 1600.0, "x=%.0f" % crate.global_position.x)
	# Delay: nothing for two seconds, then the shove
	gust.reset_state()
	gust.start_recipe = "wind/burst/right/delay"
	gust.reset_state()
	crate.global_position = Vector2(1560, 534)
	crate.velocity = Vector2.ZERO
	await frames(5)
	gust.activate(false)
	await seconds(1.0)
	check("a delayed gust waits", absf(crate.velocity.x) < 1.0 and gust.is_active)
	await seconds(1.3)
	check("then fires", crate.global_position.x > 1600.0, "x=%.0f" % crate.global_position.x)
	# Repeat: fires again and again, charged each time
	gust.start_recipe = "wind/burst/right/repeat"
	gust.reset_state()
	gust.dungeon_powered = false
	player.current_mana = 50
	await frames(3)
	var before: int = player.current_mana
	gust.activate(false)
	await seconds(5.4)
	check("a repeating gust keeps firing and charges each time (5 a shot, no regen)", gust.is_active and before - player.current_mana == 15,
		"%d -> %d" % [before, player.current_mana])
	gust.deactivate()
	gust.queue_free()
	crate.queue_free()
	# Fire: a real fireball, Explode bursts
	var fire := await make_cube(room, Vector2(1300, 534), "fire/projectile/right/split")
	fire.activate(false)
	check("Split launches three fireballs", get_tree().get_nodes_in_group("rune_fireball").size() == 3,
		str(get_tree().get_nodes_in_group("rune_fireball").size()))
	fire.queue_free()
	# Portal that would open inside rock is refused, nothing charged
	var bad := await make_cube(room, Vector2(cx(39), 534), "space/portal/right/normal", false)
	player.current_mana = 50
	var why := bad.activate(false)
	check("a portal into solid stone is refused", why.contains("solid stone") or why.contains("outside"), why)
	check("and costs nothing", player.current_mana == 50)
	bad.queue_free()
	# Freeze: the slime in room 5 is held fast
	await enter_room("R5")
	var slime_node: CharacterBody2D = node("R5/Slime")
	var chill_cube := await make_cube(node("R5"), slime_node.global_position + Vector2(-90, 4), "ice/freeze/right/normal")
	chill_cube.activate(false)
	await frames(4)
	check("Freeze chills the slime", Chill.is_chilled(slime_node) and slime_node.is_in_group("stone_weight"))
	var x0 := slime_node.global_position.x
	await seconds(2.0)
	check("a chilled slime doesn't move", absf(slime_node.global_position.x - x0) < 1.0)
	chill_cube.deactivate()
	await seconds(1.0)
	check("it thaws when the chill ends", not Chill.is_chilled(slime_node) and not slime_node.is_in_group("stone_weight"))
	chill_cube.queue_free()
	# Glow: a pool of light turns the watcher in room 6 to stone
	await enter_room("R6")
	var watcher = node("R6/Watcher")
	var glow := await make_cube(node("R6"), watcher.global_position + Vector2(-70, 0), "light/glow/self/large")
	glow.activate(false)
	check("Glow freezes a watcher inside it", await wait_until(func(): return watcher.is_frozen, 2.0))
	glow.deactivate()
	check("and it wakes when the glow goes", await wait_until(func(): return not watcher.is_frozen, 3.0))
	glow.queue_free()
	# Lift: a crate on top of an updraft cube rises; a stone block stays
	await enter_room("R2")
	var lifter := await make_cube(node("R2"), Vector2(2144, 534), "wind/lift/up/normal")
	var light_box := WindBody.new()
	light_box.position = Vector2(2144, 502)
	node("R2").add_child(light_box)
	await frames(10)
	lifter.activate(false)
	await seconds(1.5)
	check("a normal updraft lifts a crate", light_box.global_position.y < 450.0, "y=%.0f" % light_box.global_position.y)
	lifter.deactivate()
	light_box.queue_free()
	var heavy := WindBody.new()
	heavy.weight = WindBody.Weight.STONE
	heavy.size = Vector2(40, 40)
	heavy.position = Vector2(2144, 502)
	node("R2").add_child(heavy)
	await frames(20)
	var y0 := heavy.global_position.y
	lifter.activate(false)
	await seconds(1.0)
	check("but not a stone block (1200 < its 2940 weight)", absf(heavy.global_position.y - y0) < 1.0, "moved %.1f" % (heavy.global_position.y - y0))
	lifter.deactivate()
	heavy.queue_free()
	lifter.queue_free()
	# Light Beam against a mirror: Normal stops at it, Bounce turns
	await enter_room("R3")
	var mirror: Node2D = load("res://scenes/puzzle/mirror.tscn").instantiate()
	mirror.set("facing", 3)
	mirror.set("rotatable", false)
	mirror.position = Vector2(2800, 518)
	node("R3").add_child(mirror)
	var shine := await make_cube(node("R3"), Vector2(2640, 534), "light/beam/right/normal")
	shine.activate(false)
	await frames(4)
	var beam: LightBeam = shine.effect.beam
	check("a normal beam stops at a mirror", beam.path.size() == 2 and beam.end_node == mirror, "points %d" % beam.path.size())
	shine.deactivate()
	shine.start_recipe = "light/beam/right/bounce"
	shine.reset_state()
	await frames(3)
	shine.activate(false)
	await frames(4)
	beam = shine.effect.beam
	check("a Bounce beam reflects off it", beam.path.size() >= 3, "points %d" % beam.path.size())
	shine.deactivate()
	shine.queue_free()
	mirror.queue_free()
	# Persist bridge: held past the timed bridge's ten seconds, paid by the second
	await enter_room("R5")
	var edge: RuneCube = node("R5/EdgeCube")
	edge.start_recipe = "ice/bridge/right/persist"
	edge.reset_state()
	player.current_mana = 100
	await frames(3)
	edge.activate(false)
	await seconds(10.5)
	check("a Persist bridge is still there after ten seconds", edge.is_active and edge.get_node_or_null("IceBridge") != null)
	check("and costs about 5 a second", player.current_mana <= 100 - 48 and player.current_mana >= 100 - 56, str(player.current_mana))
	edge.deactivate()
	await frames(30)
	check("switched off, it melts", edge.get_node_or_null("IceBridge") == null)
	# Fire: a real rune fireball burns the brambles; an Explode blast reaches them too
	await enter_room("R8")
	var brambles: Burnable = node("R8/Brambles")
	var torch_cube := await make_cube(node("R8"), Vector2(9760, 534), "fire/projectile/right/normal")
	torch_cube.activate(false)
	check("a rune fireball burns the brambles", await wait_until(func(): return brambles.is_cleared, 2.0))
	torch_cube.queue_free()
	brambles.reset_state()
	await frames(3)
	RuneFire.blast_at(get_tree(), lvl.get_world_2d(), brambles.global_position + Vector2(-40, -20), 56.0)
	check("an Explode blast in reach burns them too", brambles.is_cleared)


# ---------------------------------------------------------------- rules

func scenario_carry_rules() -> void:
	print("-- carrying: what can be picked up, where it can go")
	await load_level()
	RuneManager.learn(&"right")
	await enter_room("R2")
	var fixed: RuneCube = node("R2/FixedCube")
	var loose: RuneCube = node("R2/LooseCube")
	await walk_to(fixed.global_position.x - 34.0)
	await face("move_right")
	await tap_action("rune_carry")
	check("a fixed cube can't be picked up", not fixed.is_carried and manager.carrier.held == null)
	await place(Vector2(loose.global_position.x - 34.0, 530))
	await face("move_right")
	loose.activate(false)
	await tap_action("rune_carry")
	check("an active cube can't be picked up", not loose.is_carried)
	loose.deactivate()
	await tap_action("rune_carry")
	check("an inactive cube can be picked up", loose.is_carried)
	# Facing the gate wall at point-blank: no room there
	await place(Vector2(cx(40) - 36.0, 530))
	await face("move_right")
	await frames(3)
	check("no placing inside a wall (with a reason)", not manager.carrier.valid and manager.carrier.reason != "", manager.carrier.reason)
	var before := loose.global_position
	await tap_action("rune_carry")
	check("an invalid spot keeps the cube in hand", loose.is_carried and manager.carrier.held == loose)
	await place(Vector2(cx(33), 530))
	await face("move_left")
	await frames(3)
	check("open floor is a valid spot", manager.carrier.valid, manager.carrier.reason)
	await tap_action("rune_carry")
	check("placed where the ghost was", not loose.is_carried and loose.global_position.distance_to(manager.carrier.target) < 1.0
		and loose.global_position != before)
	# A reset puts every cube back
	lvl.reset_current_room()
	await seconds(1.2)
	check("reset returns the cube to its start", loose.global_position.distance_to(Vector2(cx(35), 534)) < 1.0 and not loose.is_active,
		str(loose.global_position))


func scenario_mana() -> void:
	print("-- mana: upkeep, exhaustion, regeneration, reset")
	await load_level()
	RuneManager.learn(&"right")
	await enter_room("R2")
	var loose: RuneCube = node("R2/LooseCube")
	var fixed: RuneCube = node("R2/FixedCube")
	loose.dungeon_powered = false
	player.current_mana = 60
	player.update_mana_ui()
	manager._room_start_mana = 60
	check("player-powered cube starts", loose.activate(false) == "" and loose.is_active)
	fixed.activate(false)
	var m0: int = player.current_mana
	await seconds(2.0)
	var used: int = m0 - player.current_mana
	check("upkeep drains about 3 mana a second (dungeon cube costs nothing)", used >= 5 and used <= 7, "used %d in 2 s" % used)
	check("the HUD total is the player-powered upkeep", is_equal_approx(manager.total_upkeep, 3.0), str(manager.total_upkeep))
	player.start_reload()
	check("mana can't be refilled while runes draw on it", not player.is_reloading)
	player.current_mana = 1
	await seconds(1.0)
	check("running dry shuts down the player-powered rune", not loose.is_active)
	check("the dungeon-powered rune keeps running", fixed.is_active)
	check("mana never goes below zero", player.current_mana >= 0)
	await seconds(1.0)
	check("no automatic restart after exhaustion", not loose.is_active)
	var low: int = player.current_mana
	await seconds(2.0)
	check("mana comes back once no rune draws on it", player.current_mana > low + 10, "%d -> %d" % [low, player.current_mana])
	# Not enough to start: nothing is charged
	player.current_mana = 2
	var strong_needs := RuneRecipe.from_key("wind/push/left/strong")
	loose.recipe = strong_needs
	var why := loose.activate(false)
	check("too little mana: refused with a reason, nothing charged", why.contains("Not enough mana") and player.current_mana == 2 and not loose.is_active, why)
	# Reset gives back the room's starting mana and turns runes off
	player.current_mana = 10
	lvl.reset_current_room()
	await seconds(1.2)
	check("reset restores the mana she entered with", player.current_mana >= 60, str(player.current_mana))
	check("reset switches the room's runes off", not fixed.is_active and not loose.is_active)


func scenario_overview() -> void:
	print("-- overview: remote switch-off and Deactivate All")
	await load_level()
	await enter_room("R2")
	var fixed: RuneCube = node("R2/FixedCube")
	var loose: RuneCube = node("R2/LooseCube")
	fixed.activate(false)
	loose.activate(false)
	await tap_action("rune_overview")
	check("Tab opens the rune overview and pauses", manager.overview.is_open and get_tree().paused)
	check("it lists the room's cubes", manager.overview._list.get_child_count() == 2, str(manager.overview._list.get_child_count()))
	manager.overview.deactivate_all()
	check("Deactivate All switches every rune off", not fixed.is_active and not loose.is_active)
	await tap_action("rune_overview")
	check("Tab again closes it", not manager.overview.is_open and not get_tree().paused)


func scenario_look() -> void:
	print("-- look: screenshots of the rooms and the screens")
	await load_level()
	for id in ["R1", "R2", "R3"]:
		await enter_room(id)
		await seconds(1.0)
		await shot("rune_%s" % id.to_lower())
	await enter_room("R1")
	var cube: RuneCube = node("R1/BrokenCube")
	await open_cube(cube)
	await seconds(0.3)
	await shot("rune_assembly")
	await tap_action("ui_cancel")
	RuneManager.learn(&"right")
	cube.set_slot(RuneFragments.Kind.DIRECTION, &"right")
	cube.activate(false)
	await seconds(0.6)
	await shot("rune_r1_wind")
	await enter_room("R2")
	await place(Vector2(node("R2/LooseCube").global_position.x - 34.0, 530))
	await face("move_right")
	await tap_action("rune_carry")
	await walk_to(1700.0)
	await shot("rune_carry_ghost")
	await tap_action("rune_overview")
	await seconds(0.2)
	await shot("rune_overview")
	await tap_action("rune_overview")
	for id in ["R4", "R5", "R6", "R7", "R8"]:
		await enter_room(id)
		await seconds(1.0)
		await shot("rune_%s" % id.to_lower())
	# Effects as they look in play
	await enter_room("R3")
	var lift: RuneCube = node("R3/PitCube")
	lift.set_slot(RuneFragments.Kind.FORM, &"lift")
	lift.activate(false)
	await place(Vector2(2930, 530))
	await seconds(0.8)
	await shot("rune_fx_updraft")
	await enter_room("R5")
	var edge: RuneCube = node("R5/EdgeCube")
	edge.set_slot(RuneFragments.Kind.FORM, &"bridge")
	edge.activate(false)
	await place(Vector2(5560, 530))
	await seconds(0.5)
	await shot("rune_fx_bridge")
	await enter_room("R6")
	var beam_cube: RuneCube = node("R6/CeilingCube")
	beam_cube.set_slot(RuneFragments.Kind.DIRECTION, &"down")
	beam_cube.activate(false)
	await place(Vector2(6760, 530))
	await seconds(0.5)
	await shot("rune_fx_beam")
	var chill := RuneCube.new()
	chill.start_recipe = "ice/freeze/right/large"
	chill.dungeon_powered = true
	chill.position = Vector2(6980, 534)
	node("R6").add_child(chill)
	await frames(3)
	chill.activate(false)
	await seconds(0.5)
	await shot("rune_fx_freeze")
	chill.deactivate()
	await enter_room("R8")
	var portal: RuneCube = node("R8/PortalCube")
	portal.carryable = true
	portal.global_position = Vector2(9730, 534)
	portal.set_slot(RuneFragments.Kind.DIRECTION, &"up_right")
	portal.activate(false)
	await place(Vector2(9690, 530))
	await seconds(0.6)
	await shot("rune_fx_portal")
	manager.debug_draw = true
	await enter_room("R2")
	node("R2/FixedCube").activate(false)
	await seconds(0.5)
	await shot("rune_debug_view")
	manager.debug_draw = false


static func cx(col: float) -> float:
	return col * 64.0 + 32.0


func scenario_journal() -> void:
	print("-- journal: fragments, notes and cast runes are written down")
	await load_level()
	await enter_room("R1")
	await solve_r1()
	check("the journal noted wind moving things", game_state().has_flag("rune.note.moves"))
	check("the journal logged the cast rune", game_state().has_flag("rune.cast.wind/push/right/normal"))
	var pause: PauseMenu = null
	for n in lvl.get_children():
		if n is PauseMenu:
			pause = n
	pause._set_open(true)
	check("the pause menu offers the Rune Journal here", pause._journal_button.visible)
	check("and hides the empty ledger", not pause._ledger_button.visible)
	pause._show(pause._journal_box)
	await frames(2)
	var text := ""
	for child in pause._journal_list.get_children():
		if child is Label:
			text += child.text + "\n"
	check("the journal lists fragments, notes and casts", text.contains("FRAGMENTS") and text.contains("Wind moves")
		and text.contains("Rightward wind"), text.substr(0, 200))
	pause._set_open(false)


## Every room in order, start to finish, with the player's real movement
## between rooms (each room's solution starts where the last one ended).
func scenario_full_run() -> void:
	print("-- full run: Chapter 2 from the first room to the seal")
	await load_level()
	await enter_room("R1")
	await solve_r1()
	await solve_r2()
	await solve_r3()
	# Down off the wall, through the door into room 4
	check("R3 -> R4 walked through", await walk_to(cx(59) + 10.0, false, 10.0) and lvl.current_room == node("R4"),
		"x=%.0f" % player.global_position.x)
	await solve_r4()
	# Past the stone and through the broken wall
	var r4_stone: WindBody = node("R4/Stone")
	await wait_until(func(): return absf(r4_stone.velocity.x) < 1.0, 4.0)
	var stone_x: float = r4_stone.global_position.x
	check("R4 -> R5 walked through", await run_to(cx(79) + 10.0, [node("R4/LooseCube").global_position.x - 30.0, stone_x - 64.0], 12.0)
		and lvl.current_room == node("R5"), "x=%.0f" % player.global_position.x)
	await solve_r5()
	check("R5 -> R6 walked through", await walk_to(cx(101) + 10.0, true, 12.0) and lvl.current_room == node("R6"),
		"x=%.0f" % player.global_position.x)
	await solve_r6()
	check("R6 -> R7 walked through", await run_to(cx(123) + 10.0, [node("R6/LooseCube").global_position.x - 30.0, 7440.0], 12.0) and lvl.current_room == node("R7"),
		"x=%.0f" % player.global_position.x)
	check("R6 solution saved once she has gone through (her runes there stop)", game_state().has_flag("ch2.r6.solved"))
	await solve_r7()
	check("R7 -> R8 walked through", await run_to(cx(145) + 10.0, [node("R7/NormalCube").global_position.x - 30.0, node("R7/Statue").global_position.x - 60.0], 14.0)
		and lvl.current_room == node("R8"), "x=%.0f" % player.global_position.x)
	check("R7 solution saved once she has gone through", game_state().has_flag("ch2.r7.solved"))
	await solve_r8()
	get_tree().paused = false


func scenario_layout() -> void:
	print("-- layout: every room is guided, walls make sense")
	await load_level()
	var bad := WallTileAudit.find_misplaced(lvl.get_node("BackDecor"))
	check("no floor-standing wall tile floats above the floor", bad.is_empty(), str(bad.size()))
	var rooms := get_tree().get_nodes_in_group("room")
	check("eight rooms", rooms.size() == 8, str(rooms.size()))
	for room in rooms:
		var has_hint := room.find_children("*", "", true, false).any(func(n): return n is HintStone)
		check("%s has a goal, steps and a hint stone" % room.title, room.objective != "" and not room.get_steps().is_empty() and has_hint)
	var cubes := get_tree().get_nodes_in_group("rune_cube")
	check("every cube belongs to a room", cubes.all(func(c): return c.home_room != null), str(cubes.size()))
	check("every starting rune is either broken on purpose or valid",
		cubes.all(func(c): return not c.recipe.is_complete() or RuneBook.problem(c.recipe) == "" or c.name == "PitCube"))
