extends Node

## Tests for the rough loop after the Novices' Way: the Landing, the four wings,
## the Eye and the two endings. Rooms are solved with simulated input and the
## player's real movement, through the same screens a player uses (as in the
## rune suite). Run through tests/run_tests.gd:  -- wing [scenario]
##
## The loop is rough, so these tests check that it can be played from the Long
## Stair to the endings and that each room can be solved, not that it is tuned.

const DT := 1.0 / 60.0
const SHOTS := "user://test_shots/"
const WINGS := [Journey.KILN, Journey.CISTERN, Journey.LAMPS, Journey.GALLERIES]

var lvl: Node
var player: CharacterBody2D
var manager: RuneManager
var passed := 0
var failed := 0
var only := ""
var recoveries_since := 0


func run_suite(filter: String) -> void:
	only = filter
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS))
	await get_tree().process_frame
	var scenarios := {
		"journey": scenario_journey,
		"smoke": scenario_smoke,
		"landing": scenario_landing,
		"k1": scenario_forge_parts,
		"forge_broken": scenario_forge_broken,
		"forge_full": scenario_forge_full,
		"forge_page3": scenario_forge_page3,
		"k2": scenario_k2,
		"c1": scenario_c1,
		"c2": scenario_c2,
		"l1": scenario_l1,
		"l2": scenario_l2,
		"g1": scenario_g1,
		"g2": scenario_g2,
		"eye": scenario_eye,
		"loop": scenario_loop,
		"forge_look": scenario_forge_look,
	}
	for key in scenarios:
		if only == key or (only == "" and key != "forge_look"):
			await scenarios[key].call()
	release_all()
	get_tree().paused = false
	print("wing suite: passed=%d failed=%d" % [passed, failed])


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


## Opens a scene as a player would arrive from the Landing: everything the
## earlier parts teach, nothing else.
func load_scene(path: String, fresh := true) -> void:
	release_all()
	get_tree().paused = false
	if fresh:
		game_state().clear_all()
		Journey.skipping_to(path)
	if is_instance_valid(get_tree().current_scene):
		get_tree().current_scene.queue_free()
	await get_tree().process_frame
	lvl = load(path).instantiate()
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	await get_tree().process_frame
	await get_tree().physics_frame
	player = lvl.get_node("Player")
	manager = RuneManager.get_for(get_tree())
	recoveries_since = 0
	player.hazard_recovery.recovery_started.connect(func(): recoveries_since += 1)
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


func interact() -> void:
	await tap_action("interact")
	await frames(3)


func shot(file_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOTS + file_name + ".png"))


## Reads a tablet the way a player does.
func read_tablet(path: String) -> void:
	var t: Node = node(path)
	await walk_to(t.global_position.x - 10.0)
	await interact()


## Opens the cube's assembly screen the way a player does: walks up and uses it.
func open_cube(cube: RuneCube, from_x := NAN) -> bool:
	var stand := cube.global_position.x - 26.0 if is_nan(from_x) else from_x
	await walk_to(stand)
	await interact()
	return manager.assembly.is_open and manager.assembly.cube == cube


## Chooses fragments on an open assembly screen, in order.
func inscribe(ids: Array) -> void:
	for id in ids:
		manager.assembly.select_kind(RuneFragments.kind_of(StringName(id)))
		manager.assembly.choose(StringName(id))


## Mana is the lantern's flame: kindle at the room's flame first.
func kindle() -> void:
	Input.action_press("reload")
	await wait_until(func(): return player.current_mana >= 100, 3.0)
	Input.action_release("reload")


# ================================================================ the order

func scenario_journey() -> void:
	print("SCENARIO the order of the loop")
	var gs := game_state()
	gs.clear_all()
	check("the Observatory is followed by the dome pictures, which lead to the Landing",
		Journey.next_after(Journey.OBSERVATORY) == Journey.DOME_INTERLUDE and Journey.next_after(Journey.DOME_INTERLUDE) == Journey.LANDING)
	check("the Landing leads to the first wing", Journey.next_after(Journey.LANDING) == Journey.KILN)
	for i in 4:
		check("%s is followed by its pictures" % Journey.WINGS[i]["name"],
			Journey.next_after(Journey.WINGS[i]["scene"]) == Journey.WINGS[i]["after"])
		check("%s exists" % Journey.WINGS[i]["scene"], ResourceLoader.exists(Journey.WINGS[i]["scene"]))
		check("%s's pictures exist" % Journey.WINGS[i]["name"], ResourceLoader.exists(Journey.WINGS[i]["after"]))
	check("the Eye, its pictures and both endings exist", ResourceLoader.exists(Journey.EYE) and ResourceLoader.exists(Journey.EYE_INTERLUDE)
		and ResourceLoader.exists(Journey.STILLNESS_ENDING) and ResourceLoader.exists(Journey.SKY_ENDING))
	check("no wing is open before the Observatory is done", not Journey.wing_open(0) and not Journey.eye_open())
	gs.set_flag("ch2.complete")
	check("the first wing opens with the Observatory, the second does not", Journey.wing_open(0) and not Journey.wing_open(1))
	gs.set_flag("kiln.complete")
	check("each bell opens the next wing", Journey.wing_open(1) and not Journey.wing_open(2) and Journey.bells_rung() == 1)
	for flag in ["cistern.complete", "lamps.complete"]:
		gs.set_flag(flag)
	check("the Eye is still shut with three bells", not Journey.eye_open())
	gs.set_flag("galleries.complete")
	check("it opens with the fourth", Journey.eye_open())
	# Every word the two endings need is taught by the end of the Lampworks
	var needed := ["ice", "freeze", "self", "large", "light", "beam", "up", "long"]
	var taught := []
	for i in 3:
		taught.append_array(Journey.WINGS[i]["words"])
	check("every word of both endings is taught by the first three wings", needed.all(func(w): return taught.has(w)),
		str(needed.filter(func(w): return not taught.has(w))))
	check("the two ending sentences are valid runes", RuneBook.is_valid(RuneRecipe.from_key(EyeAltar.SKY))
		and RuneBook.is_valid(RuneRecipe.from_key(EyeAltar.STILLNESS)))
	check("and the altar tells them apart", EyeAltar.kind_of(EyeAltar.SKY) == "sky" and EyeAltar.kind_of(EyeAltar.STILLNESS) == "stillness"
		and EyeAltar.kind_of("wind/push/right/normal") == "")
	gs.clear_all()
	Journey.skipping_to(Journey.EYE)
	check("starting the Eye from the title gives every word and every bell", Journey.eye_open()
		and RuneManager.knows(&"portal", get_tree()) and RuneManager.knows(&"lift", get_tree()) and gs.has_ability("heal"))
	gs.clear_all()
	gs.all_abilities = true


# ================================================================ every scene loads

func scenario_smoke() -> void:
	print("SCENARIO each scene loads and has its pieces")
	var scenes := [Journey.LANDING] + WINGS + [Journey.EYE]
	for path in scenes:
		await load_scene(path)
		var rooms := lvl.find_children("*", "Room", true, false)
		check("%s: has rooms, a player and a rune manager" % path.get_file(), rooms.size() >= 1 and player != null and manager != null,
			"%d rooms" % rooms.size())
		check("%s: every room has a goal" % path.get_file(), rooms.all(func(r): return r.objective != ""))
		check("%s: every room has a kindle flame" % path.get_file(), _rooms_have_flames(rooms))
		check("%s: arrows show the way on" % path.get_file(), path == Journey.EYE or path == Journey.LANDING
			or get_tree().get_nodes_in_group("waymark").size() >= 4)
		for r: Room in rooms:
			await place(r.entry_spawn)
			await seconds(2.0)
			await shot("wing_%s_%s" % [path.get_file().get_basename(), r.name])
	game_state().clear_all()
	game_state().all_abilities = true


# ================================================================ the Landing

func scenario_landing() -> void:
	print("SCENARIO the Landing")
	await load_scene(Journey.LANDING, false)
	game_state().clear_all()
	game_state().all_abilities = true
	game_state().set_flag("ch2.complete")
	await load_scene(Journey.LANDING, false)
	var doors: Array = get_tree().get_nodes_in_group("landing_door")
	doors.sort_custom(func(a, b): return a.index < b.index)
	check("five doors", doors.size() == 5)
	check("only the first is open before any bell", doors[0].is_open() and not doors[1].is_open() and not doors[4].is_open())
	check("no bell-light is lit", doors.all(func(d): return not d.is_done()))
	for d in doors:
		check("door %d has a pixel-art door and bell-light" % d.index, d.get_node("Door") is AnimatedSprite2D and d.get_node("BellLight") is Sprite2D)
	# The first door is warm (the Observatory's bell thawed it); the rest are rimed
	await place(Vector2(doors[0].global_position.x + 90.0, 530))
	await seconds(1.2)
	check("the open door leads on: warm light spills from under it", doors[0].is_warm() and doors[0]._spill.modulate.a > 0.3)
	await shot("wing_landing_warm_door")
	await place(Vector2(doors[1].global_position.x + 90.0, 530))
	await seconds(1.2)
	await shot("wing_landing_sealed_door")
	# A sealed door says so and stays on the Landing
	await place(Vector2(doors[1].global_position.x - 20.0, 530))
	await frames(10)
	check("a sealed door can be used but does not open", await wait_until(func(): return doors[1].interactable.is_focused(), 2.0))
	await interact()
	check("it stays on the Landing", get_tree().current_scene == lvl)
	# Ringing a bell lights its lamp and opens the next door
	game_state().set_flag("kiln.complete")
	doors[0].refresh()
	doors[1].refresh()
	check("the first bell-light is lit and the second door opens", doors[0].is_done() and doors[1].is_open() and not doors[2].is_open())
	await place(Vector2(doors[2].global_position.x - 200.0, 530))
	await seconds(1.5)
	await shot("wing_landing_doors")
	# The first door leads to the first wing
	await place(Vector2(doors[0].global_position.x - 20.0, 530))
	await frames(10)
	await wait_until(func(): return doors[0].interactable.is_focused(), 2.0)
	await interact()
	await wait_until(func(): return get_tree().current_scene != lvl and get_tree().current_scene != null, 3.0)
	check("an open door changes scene to its wing", get_tree().current_scene != null and get_tree().current_scene.scene_file_path == Journey.KILN,
		str(get_tree().current_scene.scene_file_path if get_tree().current_scene else "none"))
	game_state().clear_all()
	game_state().all_abilities = true


# ================================================================ the wings

func scenario_k2() -> void:
	print("-- the Kilnworks, room 2: The Kiln Heart")
	await load_scene(Journey.KILN)
	await enter_room("R2")
	await solve_k2()


func solve_k2() -> void:
	var c: RuneCube = node("R2/HeartCube")
	var block = node("R2/Stone")
	var plate = node("R2/HeavyPlate")
	var gate = node("R2/HeartGate")
	var brambles = node("R2/Brambles")
	var bell = node("R2/GreatBell")
	await kindle()
	check("K2 open the heart cube", await open_cube(c))
	inscribe(["strong"])
	check("K2 it reads wind/push/right/strong", c.recipe.to_key() == "wind/push/right/strong", c.recipe.to_key())
	manager.assembly.toggle_cube()
	check("K2 the stone slides onto the plate", await wait_until(func(): return plate.is_pressed, 8.0), "stone x=%.0f" % block.global_position.x)
	check("K2 the gate opens", await wait_until(func(): return gate.open_amount >= 1.0, 3.0))
	check("K2 the brambles stand in front of the bell", not brambles.is_cleared)
	check("K2 hop the stone and walk to the bell", await run_to(brambles.global_position.x - 120.0, [c.global_position.x - 30.0, block.global_position.x - 46.0]), "x=%.0f y=%.0f" % [player.global_position.x, player.global_position.y])
	brambles.on_fire()
	check("K2 fire clears them", await wait_until(func(): return brambles.is_cleared, 2.0))
	check("K2 reach the rope", await run_to(bell.global_position.x + 40.0), "x=%.0f y=%.0f" % [player.global_position.x, player.global_position.y])
	await interact()
	check("K2 the Forge Bell rings and the wing is complete", await wait_until(func(): return game_state().has_flag("kiln.complete"), 25.0))
	check("K2 the bell taught the wing's words", RuneManager.knows(&"explode", get_tree()) and RuneManager.knows(&"large", get_tree()) and RuneManager.knows(&"up", get_tree()))
	check("K2 the end card leads to the pictures", lvl.next_chapter == Journey.KILN_INTERLUDE)
	get_tree().paused = false


func scenario_c1() -> void:
	print("-- the Cistern, room 1: The First Pool")
	await load_scene(Journey.CISTERN)
	await enter_room("R1")
	await solve_c1()


func solve_c1() -> void:
	var c: RuneCube = node("R1/PoolCube")
	var plate = node("R1/SlimePlate")
	var slime = node("R1/Slime")
	var gate = node("R1/PoolGate")
	await kindle()
	await frames(30)
	check("C1 the slime stands on the stone-only plate without pressing it", absf(slime.global_position.x - plate.global_position.x) < 70.0 and not plate.is_pressed,
		"slime x=%.0f plate x=%.0f" % [slime.global_position.x, plate.global_position.x])
	for t in ["TabletIce", "TabletFreeze", "TabletLong"]:
		await read_tablet("R1/" + t)
	check("C1 the tablets teach Ice, Freeze and Long", RuneManager.knows(&"ice", get_tree()) and RuneManager.knows(&"freeze", get_tree())
		and RuneManager.knows(&"long", get_tree()))
	check("C1 open the pool cube", await open_cube(c))
	inscribe(["ice", "freeze"])
	check("C1 a normal chill does not reach the slime", c.recipe.to_key() == "ice/freeze/right/normal")
	inscribe(["long"])
	check("C1 it reads ice/freeze/right/long", c.recipe.to_key() == "ice/freeze/right/long", c.recipe.to_key())
	manager.assembly.toggle_cube()
	check("C1 the slime freezes and holds the plate", await wait_until(func(): return plate.is_pressed, 4.0))
	check("C1 the gate opens", await wait_until(func(): return gate.open_amount >= 1.0, 3.0))
	check("C1 hop the cube and the slime and walk through before it thaws", await run_to(gate.global_position.x + 60.0, [c.global_position.x - 30.0, slime.global_position.x - 56.0], 6.0), "x=%.0f y=%.0f" % [player.global_position.x, player.global_position.y])
	check("C1 room cleared", await wait_until(func(): return node("R1").is_cleared(), 3.0))
	await run_to(1500.0, [], 5.0)
	check("C1 she walks on into the next room", lvl.current_room == node("R2"), "x=%.0f" % player.global_position.x)


func scenario_c2() -> void:
	print("-- the Cistern, room 2: The Sluice")
	await load_scene(Journey.CISTERN)
	await enter_room("R2")
	await solve_c2()


func solve_c2() -> void:
	var c: RuneCube = node("R2/SluiceCube")
	var pa = node("R2/PlateA")
	var pb = node("R2/PlateB")
	var gate = node("R2/SluiceGate")
	var bell = node("R2/GreatBell")
	await kindle()
	check("C2 open the sluice cube", await open_cube(c))
	inscribe(["ice", "freeze", "long"])
	check("C2 it reads ice/freeze/right/long", c.recipe.to_key() == "ice/freeze/right/long", c.recipe.to_key())
	manager.assembly.toggle_cube()
	check("C2 both slimes freeze on their plates", await wait_until(func(): return pa.is_pressed and pb.is_pressed, 4.0), "A x=%.0f frozen=%s pressed=%s; B x=%.0f frozen=%s pressed=%s" % [node("R2/SlimeA").global_position.x, node("R2/SlimeA").get("is_frozen"), pa.is_pressed, node("R2/SlimeB").global_position.x, node("R2/SlimeB").get("is_frozen"), pb.is_pressed])
	await shot("wing_c2_frozen")
	check("C2 the gate opens", await wait_until(func(): return gate.open_amount >= 1.0, 3.0))
	await run_to(bell.global_position.x + 40.0, [c.global_position.x - 30.0, node("R2/SlimeA").global_position.x - 56.0], 8.0)
	await interact()
	check("C2 the Tide Bell rings and the wing is complete", await wait_until(func(): return game_state().has_flag("cistern.complete"), 25.0))
	check("C2 the end card leads to the pictures", lvl.next_chapter == Journey.CISTERN_INTERLUDE)
	get_tree().paused = false


func scenario_l1() -> void:
	print("-- the Lampworks, room 1: The Dark Reading Room")
	await load_scene(Journey.LAMPS)
	await enter_room("R1")
	await solve_l1()


func solve_l1() -> void:
	var c: RuneCube = node("R1/ReadingCube")
	var crystal = node("R1/Crystal")
	await kindle()
	await read_tablet("R1/TabletLight")
	await read_tablet("R1/TabletBeam")
	check("L1 the tablets teach Light and Beam", RuneManager.knows(&"light", get_tree()) and RuneManager.knows(&"beam", get_tree()))
	check("L1 open the reading cube", await open_cube(c))
	inscribe(["light", "beam"])
	check("L1 it reads light/beam/right/normal", c.recipe.to_key() == "light/beam/right/normal", c.recipe.to_key())
	manager.assembly.toggle_cube()
	check("L1 the beam lights the crystal across the pit", await wait_until(func(): return crystal.powered, 3.0))
	var bridge := lvl.find_children("Bridge*", "SpectralPlatform", true, false)
	check("L1 a bridge of faint stone forms", await wait_until(func(): return bridge.all(func(b): return b.is_solid), 3.0))
	await shot("wing_l1_beam")
	check("L1 hop the cube and walk across", await run_to(1100.0, [c.global_position.x - 40.0]), "x=%.0f y=%.0f" % [player.global_position.x, player.global_position.y])
	check("L1 no fall into the spikes", recoveries_since == 0 and player.global_position.y < 540.0)
	check("L1 room cleared", await wait_until(func(): return node("R1").is_cleared(), 3.0))


func scenario_l2() -> void:
	print("-- the Lampworks, room 2: The Lamp Stair")
	await load_scene(Journey.LAMPS)
	await enter_room("R2")
	await solve_l2()


func solve_l2() -> void:
	var c: RuneCube = node("R2/LampCube")
	var crystal = node("R2/Crystal")
	var gate = node("R2/StairGate")
	var bell = node("R2/GreatBell")
	await kindle()
	await read_tablet("R2/TabletGlow")
	await read_tablet("R2/TabletSelf")
	check("L2 the tablets teach Glow and Self", RuneManager.knows(&"glow", get_tree()) and RuneManager.knows(&"self", get_tree()))
	# Carry the cube under the crystal
	await walk_to(c.global_position.x - 34.0)
	await face("move_right")
	await tap_action("rune_carry")
	check("L2 pick up the lamp cube", c.is_carried)
	await walk_to(crystal.global_position.x - 150.0)
	await tap_action("rune_carry")
	check("L2 set it down near the crystal", not c.is_carried, "at %.0f" % c.global_position.x)
	check("L2 open the lamp cube", await open_cube(c))
	inscribe(["light", "glow", "self", "large"])
	check("L2 it reads light/glow/self/large", c.recipe.to_key() == "light/glow/self/large", c.recipe.to_key())
	manager.assembly.toggle_cube()
	check("L2 the glow lights the crystal", await wait_until(func(): return crystal.powered, 3.0))
	await shot("wing_l2_glow")
	check("L2 the gate opens", await wait_until(func(): return gate.open_amount >= 1.0, 3.0))
	await run_to(bell.global_position.x + 40.0, [c.global_position.x - 30.0], 10.0)
	await interact()
	check("L2 the Lamp Bell rings and the wing is complete", await wait_until(func(): return game_state().has_flag("lamps.complete"), 25.0))
	check("L2 the end card leads to the pictures", lvl.next_chapter == Journey.LAMPS_INTERLUDE)
	get_tree().paused = false


func scenario_g1() -> void:
	print("-- the Galleries, room 1: The First Door")
	await load_scene(Journey.GALLERIES)
	await enter_room("R1")
	await solve_g1()


func solve_g1() -> void:
	var c: RuneCube = node("R1/DoorCube")
	await kindle()
	await read_tablet("R1/TabletSpace")
	await read_tablet("R1/TabletPortal")
	check("G1 the tablets teach Space and Portal", RuneManager.knows(&"space", get_tree()) and RuneManager.knows(&"portal", get_tree()))
	# Pick up the cube and set it down near the wall
	await walk_to(c.global_position.x - 34.0)
	await face("move_right")
	await tap_action("rune_carry")
	check("G1 pick up the door cube", c.is_carried)
	await walk_to(560.0)
	await tap_action("rune_carry")
	check("G1 set it down near the wall", not c.is_carried, "at %.0f" % c.global_position.x)
	check("G1 open the door cube", await open_cube(c))
	inscribe(["space", "portal", "up_right", "long"])
	check("G1 it reads space/portal/up_right/long", c.recipe.to_key() == "space/portal/up_right/long", c.recipe.to_key())
	manager.assembly.toggle_cube()
	check("G1 the portal opens", c.is_active and c.effect is RunePortal, manager.assembly._state.text)
	await shot("wing_g1_portal")
	check("G1 the doorway carries her up and over", await _portal_over(c), "at %s" % player.global_position.round())
	check("G1 she lands on top of the wall", player.is_on_floor() and player.global_position.y < 290.0, "at %s" % player.global_position.round())
	# It works both ways: into the far side from the wall, out of the near one
	var portal: RunePortal = c.effect
	var back_before := portal.carried_back.size()
	await walk_to(portal.exit_point.x)
	if portal.carried_back.size() == back_before:
		await tap_action("jump")
	check("G1 the far side takes her back too", await wait_until(func(): return portal.carried_back.size() > back_before, 2.0),
		"far side at %s, she is at %s" % [portal.exit_point.round(), player.global_position.round()])
	await wait_until(func(): return player.is_on_floor(), 2.0)
	await frames(10)
	check("G1 she comes out of the near side, back below the wall", player.global_position.x < 704.0 and player.global_position.y > 500.0,
		"at %s" % player.global_position.round())
	# (she lands between the cube and the wall: back over the cube, and again)
	if player.global_position.x > c.global_position.x:
		await run_to(c.global_position.x - 50.0, [player.global_position.x])
	check("G1 and over it once more", await _portal_over(c), "at %s" % player.global_position.round())
	await walk_to(1150.0, false, 8.0)
	await wait_until(func(): return player.is_on_floor(), 2.0)
	check("G1 down the other side", player.global_position.y > 500.0 and player.global_position.x > 1090.0, "at %s" % player.global_position.round())
	check("G1 room cleared", await wait_until(func(): return node("R1").is_cleared(), 4.0))


## A running jump into the portal's near side by the wall: out of the far
## side, up and over, onto the top of the wall.
func _portal_over(c: RuneCube) -> bool:
	await walk_to(c.global_position.x - 60.0)
	Input.action_press("move_right")
	await tap_action("jump")
	var through := await wait_until(func(): return player.global_position.y < 300.0, 2.0)
	await wait_until(func(): return player.is_on_floor(), 2.0)
	Input.action_release("move_right")
	await frames(10)
	return through and player.is_on_floor() and player.global_position.y < 290.0


func scenario_g2() -> void:
	print("-- the Galleries, room 2: The Fold Bell")
	await load_scene(Journey.GALLERIES)
	await enter_room("R2")
	await solve_g2()


func solve_g2() -> void:
	var plate = node("R2/Plate")
	var bell = node("R2/GreatBell")
	var recorder = player.get_node("EchoRecorder")
	await kindle()
	await walk_to(plate.global_position.x - 90.0)
	await tap_action("echo")
	check("G2 recording starts", recorder.is_recording)
	await walk_to(plate.global_position.x)
	await seconds(0.6)
	await tap_action("echo")
	await frames(10)
	check("G2 the Echo walks onto the plate and holds it", await wait_until(func(): return plate.is_pressed and recorder.echoes.size() == 1 and recorder.echoes[0].is_finished(), 8.0))
	check("G2 the stairs stand", await wait_until(func(): return lvl.find_children("Stair*", "SpectralPlatform", true, false).all(func(s): return s.is_solid), 3.0))
	await shot("wing_g2_stairs")
	# Up the stairs to the balcony
	var stairs := lvl.find_children("Stair*", "SpectralPlatform", true, false)
	stairs.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)
	await walk_to(stairs[0].global_position.x - 20.0)
	for s in stairs:
		Input.action_press("move_right")
		await tap_action("jump")
		await wait_until(func(): return player.is_on_floor() and player.global_position.y <= s.global_position.y + 4.0, 1.5)
	Input.action_release("move_right")
	await frames(10)
	Input.action_press("move_right")
	await tap_action("jump")
	await wait_until(func(): return player.is_on_floor(), 1.5)
	Input.action_release("move_right")
	await frames(10)
	check("G2 she reaches the balcony", player.global_position.y < 260.0, "at %s" % player.global_position.round())
	await walk_to(bell.global_position.x + 40.0, false, 8.0)
	await interact()
	check("G2 the Fold Bell rings and the wing is complete", await wait_until(func(): return game_state().has_flag("galleries.complete"), 25.0))
	check("G2 the end card leads to the pictures", lvl.next_chapter == Journey.GALLERIES_INTERLUDE)
	get_tree().paused = false


# ================================================================ the Eye

func scenario_eye() -> void:
	print("SCENARIO the Eye: the last sentence")
	await load_scene(Journey.EYE)
	await enter_room("R1")
	var great: RuneCube = node("R1/GreatCube")
	var altar: EyeAltar = node("R1/Altar")
	check("the great cube is fed by the dungeon and fixed", great.dungeon_powered and not great.carryable)
	check("Ilse and Wren's bed are pixel sprites", node("R1/Ilse/Sprite") is AnimatedSprite2D and node("R1/WrenBed/Sprite") is AnimatedSprite2D
		and lvl.find_children("*", "Polygon2D", true, false).is_empty())
	# A sentence that is neither answer is only a spell
	check("open the great cube", await open_cube(great))
	inscribe(["wind", "push", "right", "normal"])
	manager.assembly.toggle_cube()
	await frames(10)
	check("a wrong sentence does not end anything", altar.decided == "" and get_tree().current_scene == lvl)
	great.deactivate()
	await frames(5)
	# The stillness: a real ending that leads back
	await open_cube(great)
	inscribe(["ice", "freeze", "self", "large"])
	check("the cube reads ice/freeze/self/large", great.recipe.to_key() == EyeAltar.STILLNESS, great.recipe.to_key())
	await shot("wing_eye_cube")
	manager.assembly.toggle_cube()
	check("the Stillness is read", await wait_until(func(): return altar.decided == "stillness", 3.0))
	check("it leads to the Stillness pictures", await wait_until(_on_scene.bind(Journey.STILLNESS_ENDING), 6.0))
	var still: Node = get_tree().current_scene
	check("which lead back to the Eye", still._next_scene() == Journey.EYE)
	# The rewritten sky
	await load_scene(Journey.EYE)
	await enter_room("R1")
	great = node("R1/GreatCube")
	altar = node("R1/Altar")
	await open_cube(great)
	inscribe(["light", "beam", "up", "long"])
	check("the cube reads light/beam/up/long", great.recipe.to_key() == EyeAltar.SKY, great.recipe.to_key())
	manager.assembly.toggle_cube()
	check("the Rewritten Sky is read", await wait_until(func(): return altar.decided == "sky", 3.0))
	check("it leads to the final pictures", await wait_until(_on_scene.bind(Journey.SKY_ENDING), 6.0))
	var sky: Node = get_tree().current_scene
	check("which lead to the title", sky._next_scene() == Journey.TITLE)
	check("no card while the pictures play", not is_instance_valid(sky.results_card))
	sky.skip()
	check("finishing them saves the ending", await wait_until(func(): return game_state().has_flag("game.complete") and game_state().has_flag("eye.complete"), 4.0))
	var card_up := await wait_until(func(): return is_instance_valid(sky.results_card), 6.0)
	var labels: Array = sky.results_card.find_children("*", "Label", true, false).map(func(l): return l.text) if card_up else []
	check("then THE END card: the whole run's time and deaths, and thanks", card_up and labels.has("Time") and labels.has("Deaths")
		and labels.any(func(t): return t.contains("Thank you for playing")), str(labels))
	await seconds(1.0)
	await shot("wing_eye_the_end")
	if card_up:
		sky.results_card.title_button.pressed.emit()
	check("and its button goes back to the title", await wait_until(_on_scene.bind(Journey.TITLE), 6.0))
	game_state().clear_all()
	game_state().all_abilities = true


# ================================================================ the whole loop

## The pictures between the parts lead on in order, all the way round.
func scenario_loop() -> void:
	print("SCENARIO the pictures between the parts")
	# (no finished chapter's card is waiting for these pictures)
	ChapterComplete.pending = {}
	for spec in [["dome", Journey.LANDING], ["kiln", Journey.LANDING], ["cistern", Journey.LANDING], ["lamps", Journey.LANDING],
			["galleries", Journey.LANDING], ["eye", Journey.EYE], ["stillness", Journey.EYE], ["sky", Journey.TITLE]]:
		var node_: StoryInterlude = load("res://scenes/story/interlude_bell.tscn").instantiate()
		node_.kind = spec[0]
		var pictures := node_._make_pictures()
		check("%s: has pictures with words" % spec[0], pictures.size() >= 1 and pictures.all(func(p): return p["lines"].size() >= 1))
		check("%s: leads to %s" % [spec[0], spec[1].get_file()], node_._next_scene() == spec[1])
		node_.free()
	# Each picture builds without drawn shapes
	for kind in ["kiln", "cistern", "lamps", "galleries", "eye", "stillness", "sky"]:
		var path := "res://scenes/story/interlude_%s.tscn" % kind if kind in ["kiln", "cistern", "lamps", "galleries", "eye"] else "res://scenes/story/ending_%s.tscn" % kind
		game_state().clear_all()
		if is_instance_valid(get_tree().current_scene):
			get_tree().current_scene.queue_free()
		await get_tree().process_frame
		var scene: StoryInterlude = load(path).instantiate()
		get_tree().root.add_child(scene)
		get_tree().current_scene = scene
		await seconds(1.5)
		check("%s: plays, with pixel art only" % kind, scene.pictures.size() >= 1 and scene.find_children("*", "Polygon2D", true, false).is_empty())
		await shot("loop_%s" % kind)
		# every picture, then it leads on
		var guard := 0
		while not scene.finished and guard < 14:
			guard += 1
			await wait_until(func(): return not scene._changing, 4.0)
			await seconds(0.8)
			scene.next()
			await seconds(0.4)
		var want := scene._next_scene()
		check("%s: after the last picture it leads on" % kind, await wait_until(_on_scene.bind(want), 8.0))
	game_state().clear_all()
	game_state().all_abilities = true


## Every room has a lit flame to kindle at inside its bounds.
func _rooms_have_flames(rooms: Array) -> bool:
	var flames := get_tree().get_nodes_in_group("kindle_point")
	for r: Room in rooms:
		var found := false
		for f in flames:
			if f is Node2D and f.has_method("is_kindling") and f.is_kindling() and r.bounds.has_point(f.global_position):
				found = true
		if not found:
			return false
	return true


func _on_scene(path: String) -> bool:
	return get_tree().current_scene != null and get_tree().current_scene.scene_file_path == path


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


# ================================================================ the Cold Forge, looked at

func scenario_forge_look() -> void:
	print("SCENARIO the Cold Forge: screenshots")
	await load_scene(Journey.KILN)
	var spots := {
		"forge_01_hearth": Vector2(300, 530), "forge_02_pit": Vector2(470, 530), "forge_03_west_floor": Vector2(1000, 530),
		"forge_04_shaft": Vector2(1180, 530), "forge_05_bench": Vector2(1100, 270), "forge_06_kiln_roof": Vector2(1560, 274),
		"forge_07_loft": Vector2(2000, 270), "forge_08_east": Vector2(2300, 530), "forge_09_door": Vector2(2700, 530),
		"forge_10_cell": Vector2(2010, 140),
	}
	for key in spots:
		await place(spots[key])
		await seconds(1.2)
		await shot(key)
	check("the forge scene loads with its kiln", lvl.get_node_or_null("R1/GreatKiln") != null)
	game_state().clear_all()
	game_state().all_abilities = true


# ================================================================ the Cold Forge

## Her own fireball, thrown from where she stands (aimed without the mouse).
func throw_fire(dir: Vector2) -> Node:
	var d := dir.normalized()
	return player.spawn_fireball(player.global_position + Vector2(0, -12) + d * 24.0, d)


## Picks up a cube standing next to her (she turns to face it first).
func pick_up(cube: RuneCube) -> bool:
	var side := -1.0 if cube.global_position.x < player.global_position.x else 1.0
	await face("move_right" if side > 0.0 else "move_left")
	await tap_action("rune_carry")
	await frames(4)
	return cube.is_carried


## Sets the carried cube down `ahead` px in front of her, facing `dir`.
func put_down(dir: String) -> bool:
	await face(dir)
	var held: RuneCube = player.get_node("RuneCarrier").held
	await tap_action("rune_carry")
	await frames(6)
	return held != null and not held.is_carried


## Opens a cube's screen from where she stands (she must be at it).
func open_here(cube: RuneCube) -> bool:
	await interact()
	return manager.assembly.is_open and manager.assembly.cube == cube


func cube_named(path: String) -> RuneCube:
	return node(path) as RuneCube


func scenario_forge_parts() -> void:
	print("SCENARIO the Cold Forge, part by part")
	await load_scene(Journey.KILN)
	var kiln: GreatKiln = node("R1/GreatKiln")
	var forge: RuneCube = cube_named("R1/ForgeCube")
	var pilot = node("R1/PilotFlame")
	var hoist = node("R1/HoistBrazier")
	var cart: WindBody = node("R1/CoalCart")
	var door: ForgeDoor = node("R1/ForgeDoor")
	check("the kiln starts cold: no coal, no air, not roaring", not kiln.fuel and not kiln.air and not kiln.roaring)
	check("the Forge Door is shut", not door.is_open)
	check("the kiln is pixel art, not drawn shapes", node("R1/GreatKiln/Body") is AnimatedSprite2D
		and lvl.find_children("*", "Polygon2D", true, false).is_empty())

	# The Cold Hearth: Fire and Projectile, two bolts across the slag
	await kindle()
	await read_tablet("R1/TabletFire")
	await read_tablet("R1/TabletProjectile")
	check("H the tablets teach Fire and Projectile", RuneManager.knows(&"fire", get_tree()) and RuneManager.knows(&"projectile", get_tree()))
	check("H the Forge Cube can be inscribed", await open_cube(forge))
	inscribe(["fire", "projectile"])
	check("H it reads fire/projectile/right/normal", forge.recipe.to_key() == "fire/projectile/right/normal", forge.recipe.to_key())
	manager.assembly.toggle_cube()
	check("H the first bolt burns the brambles", await wait_until(func(): return node("R1/Brambles").is_cleared, 4.0))
	await seconds(1.0)
	forge.activate()
	check("H the second lights the pilot flame", await wait_until(func(): return pilot.is_lit, 4.0))
	check("H a bridge forms over the slag", await wait_until(func(): return node("R1/Bridge1").is_solid, 3.0))

	# Fire rides the shaft up to the hanging brazier
	await place(Vector2(1150, 530))
	var bolt := throw_fire(Vector2.RIGHT)
	var hoist_lit := await wait_until(func(): return hoist.is_lit, 4.0)
	check("S a fireball thrown into the shaft turns upward and lights the hanging brazier", hoist_lit)
	check("S it turned into the shaft's current", hoist_lit and is_instance_valid(bolt) == false or (is_instance_valid(bolt) and bolt.turns.size() >= 1))
	check("S the bridge over the east slag rises", await wait_until(func(): return node("R1/SlagBridge1").is_solid, 3.0))
	await shot("forge_part_hoist")

	# The coal cart: pushed off the loft onto the bridge, then into the fuel bay
	await place(Vector2(2120, 270))
	await read_tablet("R1/TabletBurst")
	check("C the loft teaches Burst", RuneManager.knows(&"burst", get_tree()))
	var loft: RuneCube = cube_named("R1/LoftCube")
	await place(Vector2(loft.global_position.x + 30.0, 270))
	await face("move_left")
	check("C open the Loft Cube", await open_here(loft))
	inscribe(["left"])
	check("C it reads wind/push/left/normal", loft.recipe.to_key() == "wind/push/left/normal", loft.recipe.to_key())
	manager.assembly.toggle_cube()
	var landed := await wait_until(func(): return cart.is_on_floor() and cart.global_position.y > 520.0, 6.0)
	check("C the cart slides off the loft and lands on the bridge, unburned", landed and not cart.is_lost
		and cart.global_position.x > 1728.0 and cart.global_position.x < 1860.0, "at %s lost=%s" % [cart.global_position.round(), cart.is_lost])
	await shot("forge_part_cart_on_bridge")
	loft.deactivate()
	await frames(5)
	check("C pick up the Loft Cube", await pick_up(loft))
	await place(Vector2(1934, 530))
	check("C set it down east of the cart", await put_down("move_left"), "cube at %.0f" % loft.global_position.x)
	await face("move_right")
	await walk_to(loft.global_position.x + 26.0)
	await face("move_left")
	check("C open it again", await open_here(loft))
	manager.assembly.toggle_cube()
	check("C the cart rolls into the fuel bay and the kiln takes its coal", await wait_until(func(): return kiln.fuel, 8.0),
		"cart at %s" % cart.global_position.round())
	check("C the FUEL lamp lights", (node("R1/GreatKiln/LampFuel") as AnimatedSprite2D).frame == 1)
	loft.deactivate()
	await shot("forge_part_fuel")

	# The Smith's bench: a steady wind only leans; a strong gust breaks the slag
	var bench: RuneCube = cube_named("R1/BenchCube")
	var crust = node("R1/SlagCrust")
	await place(Vector2(1045, 270))
	await face("move_left")
	await walk_to(bench.global_position.x + 26.0)
	await face("move_left")
	check("B open the Bench Cube", await open_here(bench))
	check("B its essence and form are LOCKED", bench.is_slot_locked(RuneFragments.Kind.ESSENCE) and bench.is_slot_locked(RuneFragments.Kind.FORM))
	manager.assembly.select_kind(RuneFragments.Kind.FORM)
	manager.assembly.choose(&"burst")
	check("B choosing Burst for a locked form is refused, with the reason", bench.recipe.form == &"push"
		and manager.assembly.refused.contains("LOCKED"), manager.assembly.refused)
	inscribe(["left", "strong"])
	manager.assembly.toggle_cube()
	await seconds(2.0)
	check("B a steady Strong wind leans on the stone but can't break the slag", not crust.is_broken)
	bench.deactivate()
	await frames(5)
	# Bring the Loft Cube to the landing by the shaft and burst from there
	await place(Vector2(1200, 270))
	loft.reset_state()
	await frames(5)
	loft.global_position = Vector2(1170, 274)
	loft.reset_physics_interpolation()
	await frames(3)
	await place(Vector2(1200, 270))
	await face("move_left")
	check("B open the Loft Cube on the landing", await open_here(loft))
	inscribe(["wind", "burst", "left", "strong"])
	check("B it reads wind/burst/left/strong", loft.recipe.to_key() == "wind/burst/left/strong", loft.recipe.to_key())
	manager.assembly.toggle_cube()
	check("B the gust drives the stone through the slag plug", await wait_until(func(): return crust.is_broken, 3.0))
	await place(Vector2(884, 260))
	await read_tablet("R1/TabletExplode")
	await place(Vector2(1990, 270))
	await read_tablet("R1/TabletUp")
	check("B the alcove teaches Explode and Up", RuneManager.knows(&"explode", get_tree()) and RuneManager.knows(&"up", get_tree()))

	# Air: the Bench Cube on the perch's pedestal blows into the kiln's pipe
	bench.global_position = Vector2(1130, 434)
	bench.reset_physics_interpolation()
	bench._find_pedestal()
	await place(Vector2(1100, 430))
	await face("move_right")
	check("A the Bench Cube stands in the perch's pedestal", bench.pedestal != null)
	check("A open it on the perch", await open_here(bench))
	inscribe(["right", "normal"])
	manager.assembly.toggle_cube()
	check("A its current blows into the pipe: the AIR lamp lights", await wait_until(func(): return kiln.air, 2.0))
	check("A and it costs her nothing", bench.fed_by_dungeon())

	# The kiln's rules: a spark hisses; a burst needs coal and air
	await place(Vector2(1150, 530))
	throw_fire(Vector2.RIGHT)
	check("F her own fireball rides the shaft and the bellows into the pipe, but only hisses",
		await wait_until(func(): return kiln.last_attempt == "spark", 4.0), kiln.last_attempt)
	check("F the kiln is still cold", not kiln.roaring)

	# Fire: the Loft Cube on the floor, a bursting bolt, the route up and in
	loft.deactivate()
	loft.global_position = Vector2(1184, 534)
	loft.reset_physics_interpolation()
	await frames(3)
	await place(Vector2(1150, 530))
	await face("move_right")
	check("F open the Loft Cube on the floor below the perch", await open_here(loft))
	inscribe(["fire", "projectile", "right", "explode"])
	check("F it reads fire/projectile/right/explode", loft.recipe.to_key() == "fire/projectile/right/explode", loft.recipe.to_key())
	manager.assembly.toggle_cube()
	check("F the bolt rides the shaft, turns into the bellows and lights the kiln: it roars",
		await wait_until(func(): return kiln.roaring, 5.0), "last attempt: %s" % kiln.last_attempt)
	await seconds(1.0)
	await shot("forge_part_roar")
	check("F the roar is saved", game_state().has_flag("kiln.r1.kiln"))
	check("F the Forge Door opens", await wait_until(func(): return door.is_open and door.open_amount >= 0.99, 6.0))
	check("F the frost melts", await wait_until(func(): return lvl.find_children("Frost*", "", true, false).filter(func(f): return f is MeltingFrost).all(func(f): return not f.visible), 6.0))
	check("F the roaring kiln is a flame to kindle at (on its roof)", node("R1/GreatKiln/RoofFlame").is_in_group("kindle_point"))
	check("F the room is cleared", await wait_until(func(): return node("R1").is_cleared(), 3.0))
	game_state().clear_all()
	game_state().all_abilities = true


## When the coal cart burns, the room says it can't be finished, and how to
## reset it; the menu opens on Reset Room; a reset brings the cart back.
func scenario_forge_broken() -> void:
	print("SCENARIO the Cold Forge: a lost coal cart")
	await load_scene(Journey.KILN)
	var cart: WindBody = node("R1/CoalCart")
	var loft: RuneCube = cube_named("R1/LoftCube")
	check("the room starts solvable", lvl.broken_reason == "" and node("R1").broken_reason() == "")
	# The bridge over the slag isn't up: push the cart off anyway
	await place(Vector2(loft.global_position.x + 30.0, 270))
	await face("move_left")
	await open_here(loft)
	inscribe(["left"])
	manager.assembly.toggle_cube()
	check("the cart falls into the slag and burns", await wait_until(func(): return cart.is_lost, 6.0))
	loft.deactivate()
	check("the room says it can't be finished now", await wait_until(func(): return lvl.broken_reason != "", 2.0), lvl.broken_reason)
	var banner: Control = lvl.find_child("BrokenBanner", true, false)
	check("the Esc menu is told to open on Reset Room at once", PauseMenu.reset_suggested)
	# (the act card and the room's name are still up here: the banner waits for them)
	await seconds(0.6)
	check("while the room's title is on screen the banner waits", lvl._top_busy() and banner != null and banner.modulate.a < 0.1)
	var shown := await wait_until(func(): return banner.modulate.a > 0.9, 12.0)
	check("then it shows why and how to reset, with the top of the screen clear", shown and not lvl._top_busy()
		and lvl._broken_label.text.contains("burned") and lvl._broken_label.text.contains("Reset Room"), lvl._broken_label.text)
	await shot("forge_broken_banner")
	var menu: PauseMenu = lvl.get_node("PauseMenu")
	await tap_action("pause")
	await frames(10)
	check("Esc opens the menu straight on Map, Reset Room", menu.is_open and menu._list1 != null
		and menu._visible_rows(menu._list1).find(menu._reset_button) == menu._row1, "row %d" % menu._row1)
	await shot("forge_broken_menu")
	menu._choose_row1()
	await seconds(1.2)
	check("Reset Room brings the cart back to the loft", not cart.is_lost and cart.visible
		and absf(cart.global_position.x - 1898.0) < 4.0, "at %s" % cart.global_position.round())
	check("and the banner goes away", await wait_until(func(): return lvl.broken_reason == "", 2.0))
	check("and the menu no longer jumps to Reset Room", not PauseMenu.reset_suggested)
	# (no wind can take the bench stone off the bench before it breaks the plug,
	# but if it ever came to rest anywhere else the room would say so too)
	var stone: WindBody = node("R1/BenchStone")
	stone.global_position = Vector2(1120.0, 420.0)
	stone.reset_physics_interpolation()
	check("a stone off the Smith's bench is lost too", await wait_until(func(): return lvl.broken_reason.contains("Smith's bench"), 3.0),
		lvl.broken_reason)
	lvl.reset_current_room()
	await seconds(1.2)
	check("and Reset Room puts it back", lvl.broken_reason == "" and absf(stone.global_position.x - 944.0) < 2.0, "x=%.0f" % stone.global_position.x)
	game_state().clear_all()
	game_state().all_abilities = true


# ---------------------------------------------------------------- moving through the Cold Forge

## From the west floor into the bellows shaft: it lifts her to the top, then
## she steps off to the west (the landing by the bench) or the east (the ledge
## over the slag, by the kiln's roof).
func ride_shaft(exit_dir: String) -> bool:
	if player.global_position.x < 1232.0:
		# From the west floor: a hop at the notch's edge clears a cube standing
		# there (out from under the perch, which would bump her head)
		Input.action_press("move_right")
		await wait_until(func(): return player.global_position.x >= 1158.0, 6.0)
		await tap_action("jump")
		await wait_until(func(): return player.global_position.x >= 1262.0, 6.0)
		Input.action_release("move_right")
	elif player.global_position.x > 1328.0:
		Input.action_press("move_left")
		await wait_until(func(): return player.global_position.x <= 1300.0, 6.0)
		Input.action_release("move_left")
	var rose := await wait_until(func(): return player.global_position.y < 268.0, 8.0)
	await seconds(0.3)
	Input.action_press(exit_dir)
	var landed := await wait_until(_stepped_off.bind(exit_dir), 4.0)
	Input.action_release(exit_dir)
	await frames(8)
	return rose and landed


## A running jump: hold the direction (and sprint), jump at `takeoff`, land.
func leap(dir: String, takeoff: float, to_x: float, timeout := 6.0, sprint := true) -> bool:
	var right := dir == "move_right"
	Input.action_press(dir)
	if sprint:
		Input.action_press("sprint")
	var ok := await wait_until(func(): return player.global_position.x >= takeoff if right else player.global_position.x <= takeoff, timeout)
	await tap_action("jump")
	ok = ok and await wait_until(func(): return not player.is_on_floor(), 0.5)
	ok = ok and await wait_until(func(): return player.is_on_floor(), 2.5)
	ok = ok and await wait_until(func(): return player.global_position.x >= to_x if right else player.global_position.x <= to_x, timeout)
	Input.action_release(dir)
	Input.action_release("sprint")
	await frames(8)
	return ok


## A charged jump (crouch held, then jump) toward `dir`.
func charged_jump(dir: String) -> bool:
	Input.action_press("crouch")
	await seconds(2.7)
	Input.action_press(dir)
	await tap_action("jump")
	Input.action_release("crouch")
	await wait_until(func(): return not player.is_on_floor(), 0.6)
	var landed := await wait_until(func(): return player.is_on_floor(), 3.0)
	Input.action_release(dir)
	await frames(8)
	return landed


func _hoist_platform() -> Node2D:
	return node("R1/LoftHoist") as Node2D


## The coal loft's lift, down to the east floor (she starts on the loft).
func lift_down() -> bool:
	var lift := _hoist_platform()
	await walk_to(2150.0)
	# Wait for it to arrive (not to leave): away first, then back up here
	await wait_until(func(): return lift.global_position.y > 400.0, 12.0)
	await wait_until(func(): return lift.global_position.y < 260.0, 12.0)
	await walk_to(2240.0)
	var down := await wait_until(func(): return lift.global_position.y > 510.0, 10.0)
	await frames(10)
	await walk_to(2120.0)
	return down and player.global_position.y > 520.0


## The lift up to the loft (she starts on the east floor).
func lift_up() -> bool:
	var lift := _hoist_platform()
	await walk_to(2120.0)
	await wait_until(func(): return lift.global_position.y < 400.0, 12.0)
	await wait_until(func(): return lift.global_position.y > 510.0, 12.0)
	await walk_to(2240.0)
	var up := await wait_until(func(): return lift.global_position.y < 260.0 and player.global_position.y < 282.0, 10.0)
	await frames(10)
	await walk_to(2150.0)
	return up and player.global_position.y < 282.0


## From the kiln's roof (or the ledge west of it) across the gap to the loft.
func roof_to_loft() -> bool:
	return await leap("move_right", 1712.0, 1830.0)


## From the loft back across the gap to the kiln's roof.
func loft_to_roof() -> bool:
	await walk_to(1840.0)
	return await leap("move_left", 1822.0, 1700.0)


func scenario_forge_full() -> void:
	print("SCENARIO the Cold Forge, played through with her own feet")
	await load_scene(Journey.KILN)
	var kiln: GreatKiln = node("R1/GreatKiln")
	var forge: RuneCube = cube_named("R1/ForgeCube")
	var loft: RuneCube = cube_named("R1/LoftCube")
	var bench: RuneCube = cube_named("R1/BenchCube")
	var cart: WindBody = node("R1/CoalCart")
	var door: ForgeDoor = node("R1/ForgeDoor")
	var frame0 := Engine.get_physics_frames()

	# 1. The Cold Hearth
	await read_tablet("R1/TabletFire")
	await read_tablet("R1/TabletProjectile")
	check("1 open the Forge Cube", await open_cube(forge))
	inscribe(["fire", "projectile"])
	manager.assembly.toggle_cube()
	await wait_until(func(): return node("R1/Brambles").is_cleared, 4.0)
	await seconds(1.0)
	check("1 open it again", await open_cube(forge))
	manager.assembly.toggle_cube()
	check("1 the pilot flame is lit and the bridge forms", await wait_until(func(): return node("R1/Bridge5").is_solid, 5.0))
	check("1 hop the cube and cross the bridge into the hall", await run_to(1150.0, [forge.global_position.x - 40.0], 12.0),
		"x=%.0f y=%.0f" % [player.global_position.x, player.global_position.y])

	# 2. Fire up the shaft lights the hanging brazier
	throw_fire(Vector2.RIGHT)
	check("2 a fireball thrown into the shaft lights the hanging brazier", await wait_until(func(): return node("R1/HoistBrazier").is_lit, 4.0))
	check("2 the bridge over the east slag rises", await wait_until(func(): return node("R1/SlagBridge2").is_solid, 4.0))

	# 3. Up the shaft, over the kiln, across the gap to the coal loft
	check("3 the shaft lifts her; she steps off east by the kiln", await ride_shaft("move_right"), "at %s" % player.global_position.round())
	await walk_to(1640.0)
	check("3 she walks the kiln's roof", player.is_on_floor() and player.global_position.y < 285.0, "at %s" % player.global_position.round())
	check("3 a running jump crosses the gap to the coal loft", await roof_to_loft(), "at %s" % player.global_position.round())

	# 4. The loft: hop the cart, Burst, and the cart off the edge onto the bridge
	check("4 hop over the coal cart", await run_to(1994.0, [player.global_position.x]), "at %s" % player.global_position.round())
	await read_tablet("R1/TabletUp")
	check("4 hop over the Loft Cube", await run_to(2126.0, [2008.0]), "at %s" % player.global_position.round())
	await read_tablet("R1/TabletBurst")
	check("4 Up and Burst learned", RuneManager.knows(&"up", get_tree()) and RuneManager.knows(&"burst", get_tree()))
	check("4 open the Loft Cube", await open_cube(loft, loft.global_position.x + 30.0))
	inscribe(["left"])
	manager.assembly.toggle_cube()
	check("4 the cart lands on the bridge over the slag", await wait_until(func(): return cart.is_on_floor() and cart.global_position.y > 520.0, 6.0)
		and not cart.is_lost, "at %s" % cart.global_position.round())
	loft.deactivate()
	await frames(5)

	# 5. Down the lift with the cube; push the cart into the fuel bay
	await walk_to(loft.global_position.x + 34.0)
	check("5 pick up the Loft Cube", await pick_up(loft))
	check("5 ride the lift down to the east floor", await lift_down(), "at %s" % player.global_position.round())
	await walk_to(1934.0)
	check("5 set the cube down east of the cart", await put_down("move_left"), "at %.0f" % loft.global_position.x)
	await walk_to(loft.global_position.x + 26.0)
	await face("move_left")
	check("5 open it", await open_here(loft))
	manager.assembly.toggle_cube()
	check("5 the cart rolls into the fuel bay: FUEL", await wait_until(func(): return kiln.fuel, 8.0))
	loft.deactivate()
	await frames(5)

	# 6. Back up with the cube, over to the bench, and a Strong Burst
	await walk_to(loft.global_position.x + 34.0)
	check("6 pick up the Loft Cube again", await pick_up(loft))
	check("6 ride the lift up to the loft", await lift_up(), "at %s" % player.global_position.round())
	check("6 jump back to the kiln's roof", await loft_to_roof(), "at %s" % player.global_position.round())
	await walk_to(1360.0)
	check("6 into the shaft from the east and off to the west landing", await ride_shaft("move_left"), "at %s" % player.global_position.round())
	await walk_to(1200.0)
	check("6 set the Loft Cube down on the landing", await put_down("move_left"), "at %.0f" % loft.global_position.x)
	await walk_to(loft.global_position.x + 26.0)
	await face("move_left")
	check("6 open it", await open_here(loft))
	inscribe(["burst", "strong"])
	check("6 it reads wind/burst/left/strong", loft.recipe.to_key() == "wind/burst/left/strong", loft.recipe.to_key())
	manager.assembly.toggle_cube()
	check("6 the gust drives the stone through the slag plug", await wait_until(func(): return node("R1/SlagCrust").is_broken, 3.0))

	# 7. The Loft Cube down through the gap to the floor below the perch (it
	#    will throw the fire later); back up the shaft, over the gap to the
	#    bench, and over the stone into the alcove: Explode and the second page
	check("7 pick the Loft Cube up again", await pick_up(loft))
	Input.action_press("move_left")
	await wait_until(func(): return not player.is_on_floor(), 2.0)
	Input.action_release("move_left")
	await wait_until(func(): return player.is_on_floor(), 2.0)
	check("7 down through the gap onto the perch", absf(player.global_position.y - 436.0) < 6.0, "at %s" % player.global_position.round())
	Input.action_press("move_right")
	await wait_until(func(): return player.global_position.y > 520.0, 3.0)
	Input.action_release("move_right")
	await frames(10)
	await walk_to(1150.0)
	check("7 set the Loft Cube on the floor between the perch and the shaft", await put_down("move_right"), "at %.0f" % loft.global_position.x)
	check("7 hop it into the shaft and step off at the west landing", await ride_shaft("move_left"), "at %s" % player.global_position.round())
	check("7 jump the gap onto the bench", await leap("move_left", 1162.0, 1070.0, 6.0, false), "at %s" % player.global_position.round())
	var stone: Node2D = node("R1/BenchStone")
	check("7 over the Bench Cube and the stone into the alcove", await run_to(880.0, [1050.0, stone.global_position.x + 46.0]),
		"at %s" % player.global_position.round())
	await read_tablet("R1/TabletExplode")
	check("7 Explode learned", RuneManager.knows(&"explode", get_tree()))
	await tap_action("jump")
	await seconds(0.8)
	check("7 the second ledger page", await wait_until(func(): return game_state().has_flag("kiln.page.2"), 1.5))

	# 8. Air: back over the stone, the Bench Cube down onto the perch's pedestal
	await run_to(975.0, [905.0], 6.0)
	await wait_until(func(): return player.is_on_floor(), 1.5)
	check("8 back over the stone", player.global_position.y > 270.0 and player.global_position.x > 968.0,
		"at %s" % player.global_position.round())
	check("8 pick up the Bench Cube", await pick_up(bench))
	Input.action_press("move_right")
	await wait_until(func(): return not player.is_on_floor(), 3.0)
	Input.action_release("move_right")
	await wait_until(func(): return player.is_on_floor(), 2.0)
	check("8 drop through the gap onto the perch", absf(player.global_position.y - 436.0) < 6.0, "at %s" % player.global_position.round())
	# (she lands at the perch's west end: right where the cube reaches the pedestal)
	check("8 set it in the pedestal", await put_down("move_right") and bench.pedestal != null, "at %.0f" % bench.global_position.x)
	await face("move_right")
	check("8 open it on the perch", await open_here(bench))
	inscribe(["right", "normal"])
	manager.assembly.toggle_cube()
	check("8 AIR: its current blows into the kiln's pipe", await wait_until(func(): return kiln.air, 2.0))

	# 9. Fire: down to the Loft Cube waiting on the floor, a bursting bolt
	Input.action_press("move_left")
	await wait_until(func(): return not player.is_on_floor(), 2.0)
	Input.action_release("move_left")
	await wait_until(func(): return player.is_on_floor(), 2.0)
	check("9 down from the perch to the floor", player.global_position.y > 520.0, "at %s" % player.global_position.round())
	await walk_to(1150.0)
	await face("move_right")
	check("9 open the Loft Cube", await open_here(loft))
	inscribe(["fire", "projectile", "right", "explode"])
	manager.assembly.toggle_cube()
	check("9 the bursting bolt rides the shaft and the bellows into the kiln: it roars", await wait_until(func(): return kiln.roaring, 6.0),
		"last attempt %s" % kiln.last_attempt)
	check("9 the Forge Door opens (after the kiln's moment)", await wait_until(func(): return door.is_open and door.open_amount >= 0.99, 9.0))

	# 10. Out through the Forge Door
	check("10 up the shaft, east over the kiln", await ride_shaft("move_right"), "at %s" % player.global_position.round())
	check("10 across to the loft", await roof_to_loft(), "at %s" % player.global_position.round())
	check("10 down the lift", await lift_down(), "at %s" % player.global_position.round())
	check("10 through the open Forge Door into the Kiln Heart", await walk_to(2960.0, true, 12.0) and lvl.current_room == node("R2"),
		"at %s" % player.global_position.round())
	check("10 the Cold Forge is cleared", node("R1").is_cleared())
	# (game time, at 60 physics frames a second: the route alone, by someone who
	# already knows the answer; a first-time player reads, tries and fails too)
	print("  (the scripted route took %.0f s of game time)" % ((Engine.get_physics_frames() - frame0) / 60.0))
	game_state().clear_all()
	game_state().all_abilities = true


## The third ledger page, in the cell over the coal loft: a bolt straight up
## from the Loft Cube burns the bramble mat over the hole in the cell's floor,
## then an updraft from the same cube carries her up through it.
func scenario_forge_page3() -> void:
	print("SCENARIO the Cold Forge: the third ledger page")
	await load_scene(Journey.KILN)
	# (what she knows by now: Up from the loft's tablet, Lift from the Observatory)
	for w in ["fire", "projectile", "up", "lift"]:
		RuneManager.learn(StringName(w))
	var loft: RuneCube = cube_named("R1/LoftCube")
	var mat: Burnable = node("R1/CellMat")
	await place(Vector2(2000, 270))
	await kindle_here()
	await walk_to(loft.global_position.x - 26.0)
	await face("move_right")
	check("P open the Loft Cube where it stands, under the hole", await open_here(loft))
	inscribe(["fire", "projectile", "up", "normal"])
	manager.assembly.toggle_cube()
	check("P a bolt straight up burns the bramble mat over the hole", await wait_until(func(): return mat.is_cleared, 4.0))
	await seconds(0.6)
	check("P open it again", await open_here(loft))
	inscribe(["wind", "lift", "up", "normal"])
	manager.assembly.toggle_cube()
	check("P the updraft runs up through the hole", loft.is_active)
	await run_to(loft.global_position.x, [player.global_position.x], 3.0)
	check("P standing on the cube, the updraft carries her up into the cell",
		await wait_until(func(): return player.global_position.y < 150.0, 6.0), "at %s" % player.global_position.round())
	Input.action_press("move_left")
	var landed := await wait_until(_in_the_cell, 4.0)
	Input.action_release("move_left")
	check("P she steps off onto the cell's floor", landed, "at %s" % player.global_position.round())
	await shot("forge_page3_cell")
	await walk_to(2010.0)
	check("P the third ledger page", await wait_until(func(): return game_state().has_flag("kiln.page.3"), 2.0))
	game_state().clear_all()
	game_state().all_abilities = true


func _in_the_cell() -> bool:
	return player.is_on_floor() and player.global_position.y < 150.0 and player.global_position.x < 2045.0


## Mana for a test that starts away from a flame.
func kindle_here() -> void:
	player.current_mana = 100


## Off the top of the shaft and standing on the ledge on that side.
func _stepped_off(exit_dir: String) -> bool:
	if not player.is_on_floor() or player.global_position.y >= 290.0:
		return false
	return player.global_position.x < 1225.0 if exit_dir == "move_left" else player.global_position.x > 1335.0
