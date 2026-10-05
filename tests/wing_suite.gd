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
		"heart_full": scenario_heart_full,
		"heart_broken": scenario_heart_broken,
		"c1": scenario_c1,
		"c1_full": scenario_c1_full,
		"c1_short": scenario_c1_short,
		"c1_broken": scenario_c1_broken,
		"admin": scenario_admin,
		"c2": scenario_c2,
		"c2_full": scenario_c2_full,
		"c2_pages": scenario_c2_pages,
		"c2_broken": scenario_c2_broken,
		"l1": scenario_l1,
		"l2": scenario_l2,
		"g1": scenario_g1,
		"g2": scenario_g2,
		"eye": scenario_eye,
		"loop": scenario_loop,
		"forge_look": scenario_forge_look,
		"heart_look": scenario_heart_look,
		"c1_look": scenario_c1_look,
		"c2_look": scenario_c2_look,
	}
	for key in scenarios:
		if only == key or (only == "" and not key.ends_with("_look")):
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

# ---------------------------------------------------------------- the Kiln Heart

## What she knows walking out of the Cold Forge (its five tablets).
func learn_cold_forge() -> void:
	for w in ["fire", "projectile", "burst", "explode", "up"]:
		RuneManager.learn(StringName(w))


## From the bank or a ledge west of a heat vent: walk off into its column,
## let it carry her to the top, then step off east onto the next ledge.
func ride_vent(vent_x: float, land_x: float) -> bool:
	Input.action_press("move_right")
	var went_in := await wait_until(func(): return player.global_position.x >= vent_x - 24.0, 8.0)
	Input.action_release("move_right")
	var rose := await wait_until(func(): return player.global_position.y < 268.0, 8.0)
	await seconds(0.3)
	Input.action_press("move_right")
	var landed := await wait_until(_standing_high_past.bind(land_x), 4.0)
	Input.action_release("move_right")
	await frames(8)
	return went_in and rose and landed


func _standing_high_past(x: float) -> bool:
	return player.is_on_floor() and player.global_position.y < 290.0 and player.global_position.x > x


## The bell hoist, from the tower floor up to the bell's balcony (a hop over
## the cube standing in the pedestal on the way).
func ride_bell_hoist() -> bool:
	var lift := node("R2/BellHoist") as Node2D
	if player.global_position.x < 5900.0:
		await run_to(6236.0, [player.global_position.x + 4.0], 8.0)
	await walk_to(6236.0)
	# Wait for it to arrive (not to leave): away first, then back down here
	await wait_until(func(): return lift.global_position.y < 400.0, 14.0)
	await wait_until(func(): return lift.global_position.y > 510.0, 14.0)
	await walk_to(6330.0)
	var up := await wait_until(func(): return lift.global_position.y < 196.0 and player.global_position.y < 214.0, 12.0)
	await frames(10)
	await walk_to(6440.0)
	return up and player.is_on_floor() and player.global_position.y < 214.0


## From the gallery's end (cube in hand): over the fourth vent onto the middle
## rack, off its end down to the Heart, hopping its rim, to the floor beyond.
func gallery_to_heart_floor() -> bool:
	return await run_to(5880.0, [5790.0], 12.0)


func scenario_k2() -> void:
	print("SCENARIO the Kiln Heart, part by part")
	await load_scene(Journey.KILN)
	learn_cold_forge()
	await enter_room("R2")
	var heart: HeartCrucible = node("R2/Heart")
	var shutter: PortcullisGate = node("R2/Shutter")
	var lamp: Brazier = node("R2/AshLamp")
	var shutter_cube: RuneCube = cube_named("R2/ShutterCube")
	var plate: PressurePlate = node("R2/ShutterPlate")
	var hoist: Node2D = node("R2/BellHoist")
	var skips: Array = [node("R2/Skip1"), node("R2/Skip2"), node("R2/Skip3")]
	var burners: Array = [node("R2/BurnerHigh"), node("R2/BurnerMid"), node("R2/BurnerLow")]
	check("the Heart starts cold and empty", not heart.roaring and heart.fuel == 0)
	check("its pieces are pixel art, not drawn shapes", node("R2/Heart/Body") is AnimatedSprite2D
		and lvl.find_children("*", "Polygon2D", true, false).is_empty())
	check("the way back is caged: the Forge Door is sealed behind her", (node("R1/ForgeDoor") as ForgeDoor).sealed)
	check("the four heat vents are dungeon machinery, running", _vents_running())
	check("the hoist waits on the floor", absf(hoist.global_position.y - 516.0) < 1.0)
	# All three burners flaring over an empty Heart only says why it stays cold
	for b in burners:
		b.ignite()
	check("burners lit together over an empty Heart: it stays cold, and says why",
		await wait_until(func(): return heart.last_attempt == "no_coal", 1.0) and not heart.roaring)
	await seconds(0.8)
	check("each burner dies within a second", burners.all(func(b): return not b.is_lit))

	# A. The Shutter Hall: Delay
	await kindle()
	check("A the shutter is down", shutter.open_amount <= 0.0)
	await walk_to(plate.global_position.x)
	check("A standing on the plate holds it up", await wait_until(func(): return shutter.open_amount >= 1.0, 2.0))
	throw_fire(Vector2.RIGHT)
	await seconds(1.6)
	check("A her own fireball, thrown from the plate, dies short of the lamp", not lamp.is_lit)
	check("A open the Shutter Cube", await open_cube(shutter_cube))
	check("A its essence, form and direction are carved", shutter_cube.is_slot_locked(RuneFragments.Kind.ESSENCE)
		and shutter_cube.is_slot_locked(RuneFragments.Kind.FORM) and shutter_cube.is_slot_locked(RuneFragments.Kind.DIRECTION))
	manager.assembly.toggle_cube()
	await seconds(1.0)
	check("A switched on as it is, its bolt splashes on the shut shutter", not lamp.is_lit and shutter.open_amount <= 0.0)
	await read_tablet("R2/TabletDelay")
	check("A the tablet teaches Delay", RuneManager.knows(&"delay", get_tree()))
	check("A open the cube again", await open_cube(shutter_cube))
	inscribe(["delay"])
	check("A it reads fire/projectile/right/delay", shutter_cube.recipe.to_key() == "fire/projectile/right/delay", shutter_cube.recipe.to_key())
	manager.assembly.toggle_cube()
	await walk_to(plate.global_position.x)
	check("A back on the plate in time: the waiting bolt flies through and lights the lamp", await wait_until(func(): return lamp.is_lit, 4.0))
	await walk_to(plate.global_position.x - 90.0)
	await seconds(1.2)
	check("A off the plate, the lit lamp holds the shutter open, and is saved", shutter.open_amount >= 1.0 and game_state().has_flag("kiln.r2.ash"))
	await shot("heart_part_shutter")
	# The shelf over the hall: a charged jump from beside it
	await walk_to(3170.0)
	Input.action_press("crouch")
	await seconds(2.7)
	Input.action_press("move_right")
	await tap_action("jump")
	Input.action_release("crouch")
	await seconds(0.22)
	Input.action_release("move_right")
	await wait_until(func(): return player.is_on_floor(), 3.0)
	await frames(10)
	var on_shelf := absf(player.global_position.y - 436.0) < 4.0
	await walk_to(3232.0)
	check("A a charged jump reaches the shelf: ledger page iv", on_shelf and game_state().has_flag("kiln.page.4"), "at %s" % player.global_position.round())

	# B. The Slag Lake: three columns of heat (off the shelf, over the cube, through the shutter)
	check("B through the open shutter to the bank", await run_to(3700.0, [], 10.0), "at %s" % player.global_position.round())
	check("B into the first vent and up; off onto the first ledge", await ride_vent(3840.0, 3910.0), "at %s" % player.global_position.round())
	# The page low in the lake: down through the break in the ledge
	Input.action_press("move_right")
	await wait_until(func(): return player.global_position.x > 3975.0 and not player.is_on_floor(), 6.0)
	Input.action_release("move_right")
	await wait_until(func(): return player.is_on_floor(), 3.0)
	await frames(10)
	var on_low_ledge := player.is_on_floor() and absf(player.global_position.y - 500.0) < 6.0
	await walk_to(4000.0)
	check("B a drop off the ledge's end lands on the low ledge: ledger page v", on_low_ledge
		and game_state().has_flag("kiln.page.5"), "at %s" % player.global_position.round())
	check("B and the second vent carries her from there to the second ledge", await ride_vent(4160.0, 4230.0), "at %s" % player.global_position.round())
	check("B the third vent lets her off on the gallery", await ride_vent(4480.0, 4550.0), "at %s" % player.global_position.round())
	check("B no fall into the slag on the way", recoveries_since == 0, "%d" % recoveries_since)
	await shot("heart_part_gallery")

	# C. The Coal Racks: Large
	await read_tablet("R2/TabletLarge")
	check("C the gallery teaches Large", RuneManager.knows(&"large", get_tree()))
	var rack_cube: RuneCube = cube_named("R2/RackCube")
	await walk_to(rack_cube.global_position.x - 30.0)
	check("C pick up the gallery's cube", await pick_up(rack_cube))
	await walk_to(5370.0)
	check("C set it in the pedestal at the end of the gallery", await put_down("move_right") and rack_cube.pedestal == node("R2/RackPedestal"),
		"cube at %.0f, she at %.0f" % [rack_cube.global_position.x, player.global_position.x])
	await face("move_right")
	if not await open_here(rack_cube):
		check("C open it", false, "stopping here")
		return
	inscribe(["burst"])
	check("C it reads wind/burst/right/normal", rack_cube.recipe.to_key() == "wind/burst/right/normal", rack_cube.recipe.to_key())
	manager.assembly.toggle_cube()
	check("C a normal gust tips only the middle skip into the Heart", await wait_until(func(): return heart.fuel == 1, 4.0)
		and skips[1].is_consumed and not skips[0].is_consumed and not skips[2].is_consumed, "fuel %d" % heart.fuel)
	await seconds(1.0)
	check("C the top and bottom skips stay on their racks", (skips[0] as Node2D).global_position.distance_to(Vector2(5650, 146)) < 3.0
		and (skips[2] as Node2D).global_position.distance_to(Vector2(5650, 402)) < 3.0)
	check("C open it again", await open_here(rack_cube))
	inscribe(["large"])
	manager.assembly.toggle_cube()
	check("C a Large gust tips the other two in: three skips of three", await wait_until(func(): return heart.fuel == 3, 4.0),
		"fuel %d; skips at %s, %s" % [heart.fuel, (skips[0] as Node2D).global_position.round(), (skips[2] as Node2D).global_position.round()])
	check("C its three coal lamps are lit, and the skips are saved", heart.fuel_state == 1
		and ["kiln.r2.skip.1", "kiln.r2.skip.2", "kiln.r2.skip.3"].all(func(f): return game_state().has_flag(f)))
	await shot("heart_part_racks")

	# D. The Heart: Split
	await seconds(0.5)
	check("D pick the cube up from the pedestal", await pick_up(rack_cube))
	check("D over the fourth vent, along the middle rack and down to the floor past the Heart", await gallery_to_heart_floor(),
		"at %s" % player.global_position.round())
	await read_tablet("R2/TabletSplit")
	check("D the tablet teaches Split", RuneManager.knows(&"split", get_tree()))
	# One burner lit by hand flares and dies alone
	var aim: Vector2 = burners[1].global_position + Vector2(0, -30) - (player.global_position + Vector2(0, -12))
	throw_fire(aim)
	check("D one burner lit by hand: it flares and dies, the Heart stays cold",
		await wait_until(func(): return burners[1].is_lit, 2.0) and not heart.roaring)
	await walk_to(5872.0)
	check("D set the cube in the pedestal beside the Heart", await put_down("move_right") and rack_cube.pedestal == node("R2/HeartPedestal"),
		"at %.0f" % rack_cube.global_position.x)
	await face("move_right")
	check("D open it", await open_here(rack_cube))
	inscribe(["fire", "projectile", "up_right", "split"])
	check("D it reads fire/projectile/up_right/split", rack_cube.recipe.to_key() == "fire/projectile/up_right/split", rack_cube.recipe.to_key())
	manager.assembly.toggle_cube()
	check("D one bolt thrown three ways lights the three burners at once: the Heart beats", await wait_until(func(): return heart.roaring, 4.0),
		"last attempt '%s'" % heart.last_attempt)
	check("D the beat is saved", game_state().has_flag("kiln.r2.heart"))
	check("D the frost lets go of the bell", await wait_until(_heart_frost_gone, 6.0))
	check("D the beating Heart is a flame to kindle at", heart.is_in_group("kindle_point") and heart.is_kindling())
	await seconds(1.0)
	check("D its three burners burn steady now", burners.all(func(b): return b.is_lit))
	await shot("heart_part_roar")

	# E. The hoist and the Forge Bell
	check("E the hoist starts once the Heart beats", await wait_until(func(): return hoist.global_position.y < 500.0, 8.0))
	check("E ride the hoist up to the bell", await ride_bell_hoist(), "at %s" % player.global_position.round())
	await shot("heart_part_bell")
	var bell: Node2D = node("R2/GreatBell")
	await walk_to(bell.global_position.x + 40.0)
	await interact()
	check("E the Forge Bell rings and the wing is complete", await wait_until(func(): return game_state().has_flag("kiln.complete"), 25.0))
	check("E the bell taught the wing's words", RuneManager.knows(&"explode", get_tree()) and RuneManager.knows(&"large", get_tree())
		and RuneManager.knows(&"up", get_tree()))
	check("E the end card leads to the pictures", lvl.next_chapter == Journey.KILN_INTERLUDE)
	get_tree().paused = false
	game_state().clear_all()
	game_state().all_abilities = true


func _vents_running() -> bool:
	for p in ["R2/Vent1", "R2/Vent2", "R2/Vent3", "R2/Vent4"]:
		var c := cube_named(p)
		if c == null or not c.is_machinery() or not c.is_active:
			return false
	return true


func _heart_frost_gone() -> bool:
	for f in node("R2/Decor").get_children():
		if f is MeltingFrost and f.visible:
			return false
	return true


## The Kiln Heart from the door to the bell with her own feet: no teleports.
func scenario_heart_full() -> void:
	print("SCENARIO the Kiln Heart, played through with her own feet")
	await load_scene(Journey.KILN)
	learn_cold_forge()
	await enter_room("R2")
	var heart: HeartCrucible = node("R2/Heart")
	var lamp: Brazier = node("R2/AshLamp")
	var shutter_cube: RuneCube = cube_named("R2/ShutterCube")
	var plate: Node2D = node("R2/ShutterPlate")
	var rack_cube: RuneCube = cube_named("R2/RackCube")
	var frame0 := Engine.get_physics_frames()

	# 1. The Shutter Hall
	await kindle()
	await read_tablet("R2/TabletDelay")
	check("1 open the Shutter Cube", await open_cube(shutter_cube))
	inscribe(["delay"])
	manager.assembly.toggle_cube()
	await walk_to(plate.global_position.x)
	check("1 on the plate as the bolt flies: the Ash Lamp lights", await wait_until(func(): return lamp.is_lit, 4.0))

	# 2. The Slag Lake (a hop over the cube, through the open shutter)
	check("2 over the cube and through the shutter", await run_to(3700.0, [3256.0], 10.0), "at %s" % player.global_position.round())
	check("2 the first vent and the first ledge", await ride_vent(3840.0, 3910.0), "at %s" % player.global_position.round())
	check("2 the second vent and the second ledge", await ride_vent(4160.0, 4230.0), "at %s" % player.global_position.round())
	check("2 the third vent and the gallery", await ride_vent(4480.0, 4550.0), "at %s" % player.global_position.round())

	# 3. The Coal Racks
	await read_tablet("R2/TabletLarge")
	await walk_to(rack_cube.global_position.x - 30.0)
	check("3 pick up the gallery's cube", await pick_up(rack_cube))
	await walk_to(5370.0)
	check("3 set it in the pedestal at the gallery's end", await put_down("move_right") and rack_cube.pedestal != null)
	await face("move_right")
	check("3 open it", await open_here(rack_cube))
	inscribe(["burst", "large"])
	manager.assembly.toggle_cube()
	check("3 one Large gust: three skips of coal in the Heart", await wait_until(func(): return heart.fuel == 3, 5.0), "fuel %d" % heart.fuel)

	# 4. The Heart
	await seconds(0.5)
	check("4 pick the cube up again", await pick_up(rack_cube))
	check("4 down past the Heart with it", await gallery_to_heart_floor(), "at %s" % player.global_position.round())
	await read_tablet("R2/TabletSplit")
	await walk_to(5872.0)
	check("4 set it in the pedestal beside the Heart", await put_down("move_right") and rack_cube.pedestal != null)
	await face("move_right")
	check("4 open it", await open_here(rack_cube))
	inscribe(["fire", "projectile", "up_right", "split"])
	manager.assembly.toggle_cube()
	check("4 the Heart beats", await wait_until(func(): return heart.roaring, 4.0), "last attempt '%s'" % heart.last_attempt)

	# 5. The bell
	check("5 ride the hoist up", await ride_bell_hoist(), "at %s" % player.global_position.round())
	var bell: Node2D = node("R2/GreatBell")
	await walk_to(bell.global_position.x + 40.0)
	await interact()
	check("5 the Forge Bell rings: the wing is complete", await wait_until(func(): return game_state().has_flag("kiln.complete"), 25.0))
	check("5 every step of the room is done", node("R2").is_cleared())
	check("5 no fall into the slag on the whole route", recoveries_since == 0, "%d" % recoveries_since)
	print("  (the scripted route took %.0f s of game time)" % ((Engine.get_physics_frames() - frame0) / 60.0))
	get_tree().paused = false
	game_state().clear_all()
	game_state().all_abilities = true


## A skip of coal that falls where it can't be tipped in: the room says so,
## and Reset Room puts it back on its rack.
func scenario_heart_broken() -> void:
	print("SCENARIO the Kiln Heart: a lost skip of coal")
	await load_scene(Journey.KILN)
	learn_cold_forge()
	await enter_room("R2")
	check("the room starts solvable", lvl.broken_reason == "" and node("R2").broken_reason() == "")
	var skip: WindBody = node("R2/Skip3")
	skip.global_position = Vector2(5560.0, 534.0)
	skip.reset_physics_interpolation()
	check("a skip come to rest on the tower floor is lost", await wait_until(func(): return lvl.broken_reason.contains("skip of coal"), 3.0),
		lvl.broken_reason)
	lvl.reset_current_room()
	await seconds(1.2)
	check("Reset Room puts it back on its rack", lvl.broken_reason == "" and skip.global_position.distance_to(Vector2(5650, 402)) < 2.0,
		"at %s" % skip.global_position.round())
	# Into the slag (pushed back west off a rack): burned, lost, back on reset
	skip.global_position = Vector2(5300.0, 560.0)
	skip.reset_physics_interpolation()
	check("a skip in the slag burns, and the room says so", await wait_until(func(): return skip.is_lost and lvl.broken_reason != "", 3.0))
	lvl.reset_current_room()
	await seconds(1.2)
	check("and Reset Room brings it back", not skip.is_lost and skip.visible and lvl.broken_reason == "")
	game_state().clear_all()
	game_state().all_abilities = true


# ---------------------------------------------------------------- the Still Water (the Cistern, room 1)

## A jump straight up with the direction held just until x reaches `to_x`
## (from a pillar to the next, or onto a step), then land.
func hop_to(to_x: float) -> bool:
	var left := to_x < player.global_position.x
	var dir := "move_left" if left else "move_right"
	await tap_action("jump")
	Input.action_press(dir)
	await wait_until(func(): return player.global_position.x <= to_x + 4.0 if left else player.global_position.x >= to_x - 4.0, 1.5)
	Input.action_release(dir)
	var landed := await wait_until(func(): return player.is_on_floor(), 2.0)
	await frames(4)
	return landed


## Up the frozen fountains, east to west, from the floor by the lectern onto
## the walkway.
func climb_fountains() -> bool:
	await walk_to(2716.0)
	var ok := true
	for i in range(4, -1, -1):
		ok = ok and await hop_to(2512.0 + 45.0 * i)
	await walk_to(2470.0)
	return ok and player.is_on_floor() and absf(player.global_position.y - 308.0) < 6.0


## From the walkway west through the Clock Gate and up the three steps to the
## clock gallery.
func walkway_to_gallery() -> bool:
	await walk_to(2070.0)
	var ok := await hop_to(2016.0)
	ok = ok and await hop_to(1952.0)
	ok = ok and await hop_to(1880.0)
	return ok and absf(player.global_position.y - 212.0) < 6.0


func _stair_of_pillars(fountains: Array) -> bool:
	for i in fountains.size():
		var top: float = fountains[i].top_y()
		if not fountains[i].is_frozen or absf(top - (306.0 + 45.0 * i)) > 9.0:
			return false
	return true


func _pillar_tops(fountains: Array) -> String:
	return str(fountains.map(func(f): return "%s%.0f" % ["*" if f.is_frozen else "", f.top_y()]))


func scenario_c1() -> void:
	print("SCENARIO the Still Water, part by part")
	await load_scene(Journey.CISTERN)
	var pool_a: CisternPool = node("R1/Pool7")
	var pool_b: CisternPool = node("R1/Pool11")
	var brink: RuneCube = cube_named("R1/BrinkCube")
	var island: RuneCube = cube_named("R1/IslandCube")
	var plug: Burnable = node("R1/IcePlug")
	var warden: RuneCube = cube_named("R1/WardenCube")
	var clock_gate: PortcullisGate = node("R1/ClockGate")
	var plate: PressurePlate = node("R1/GatePlate")
	var keeper: Node2D = node("R1/Keeper")
	var clock: TideClock = node("R1/TideClock")
	var door: PortcullisGate = node("R1/SluiceDoor")
	var fcube: RuneCube = cube_named("R1/FountainCube")
	var fountains: Array = []
	for i in 5:
		fountains.append(node("R1/Fountain%d" % (i + 1)))
	check("its pieces are pixel art, not drawn shapes", node("R1/TideClock/Frame") is Sprite2D
		and lvl.find_children("*", "Polygon2D", true, false).is_empty())
	check("the Sluice Door is shut and the Clock Gate is down", door.open_amount <= 0.0 and clock_gate.open_amount <= 0.0)
	var lows := []
	for k in 8:
		lows.append(clock.level)
		await seconds(0.8)
	check("the tide clock runs: its tide rises and falls", lows.max() - lows.min() > 150.0, str(lows.map(func(v): return roundi(v))))
	check("and it never strikes by itself", not clock.struck and door.open_amount <= 0.0)

	# A. The first pool: Ice and Freeze
	await kindle()
	await read_tablet("R1/TabletIce")
	await read_tablet("R1/TabletFreeze")
	check("A the tablets teach Ice and Freeze", RuneManager.knows(&"ice", get_tree()) and RuneManager.knows(&"freeze", get_tree()))
	check("A open the Brink Cube", await open_cube(brink))
	check("A its direction is carved", brink.is_slot_locked(RuneFragments.Kind.DIRECTION))
	inscribe(["ice", "freeze"])
	check("A it reads ice/freeze/right/normal", brink.recipe.to_key() == "ice/freeze/right/normal", brink.recipe.to_key())
	manager.assembly.toggle_cube()
	check("A the whole first pool freezes over", await wait_until(func(): return pool_a.frozen_fraction() > 0.99, 2.0), "%.2f" % pool_a.frozen_fraction())
	await shot("still_part_first_pool")
	check("A she hops the cube and walks across on the ice to the island", await run_to(620.0, [400.0], 6.0) and recoveries_since == 0 and player.global_position.y < 540.0,
		"at %s" % player.global_position.round())
	await seconds(7.5)
	check("A the ice gives way again once the cold is gone", pool_a.frozen_fraction() == 0.0)

	# B. The second pool: Long
	await read_tablet("R1/TabletLong")
	check("B the island teaches Long", RuneManager.knows(&"long", get_tree()))
	check("B open the Island Cube", await open_cube(island))
	manager.assembly.toggle_cube()
	await frames(20)
	var short := pool_b.frozen_fraction()
	check("B a normal freeze reaches well under half the long pool", short > 0.3 and short < 0.5, "%.2f" % short)
	await seconds(7.5)
	await kindle_here()
	check("B open it again", await open_cube(island))
	inscribe(["long"])
	check("B it reads ice/freeze/right/long", island.recipe.to_key() == "ice/freeze/right/long", island.recipe.to_key())
	manager.assembly.toggle_cube()
	await frames(20)
	var long_ice := pool_b.frozen_fraction()
	check("B Long freezes all but a hop of it", long_ice > 0.75 and long_ice < 0.95, "%.2f" % long_ice)
	check("B over the cube, across the ice and a running jump off its end", await _cross_second_pool() and recoveries_since == 0,
		"at %s" % player.global_position.round())

	# C. The Ice Door
	check("C a plug of old ice fills the doorway", not plug.is_cleared)
	await walk_to(1340.0)
	throw_fire(Vector2.RIGHT)
	check("C her own fire melts it", await wait_until(func(): return plug.is_cleared, 2.0))
	await walk_to(warden.global_position.x - 30.0)
	check("C the Warden's cube behind it is hers to carry", await pick_up(warden))

	# D. The gatekeeper: a slime frozen on its plate, through the grate
	await kindle_here()
	await walk_to(2190.0)
	check("D set the cube down on the grate over the slime", await put_down("move_right") and absf(warden.global_position.y - 534.0) < 2.0,
		"at %s" % warden.global_position.round())
	await walk_to(warden.global_position.x - 26.0)
	await face("move_right")
	check("D open it", await open_here(warden))
	inscribe(["ice", "freeze", "down"])
	check("D it reads ice/freeze/down/normal", warden.recipe.to_key() == "ice/freeze/down/normal", warden.recipe.to_key())
	manager.assembly.toggle_cube()
	check("D the cold sinks through the grate: the slime freezes on its plate", await wait_until(func(): return plate.is_pressed, 3.0),
		"slime at %s" % keeper.global_position.round())
	check("D two seconds later the Clock Gate opens, for good", await wait_until(func(): return clock_gate.open_amount >= 1.0, 5.0)
		and game_state().has_flag("cistern.r1.gate"))
	warden.deactivate()
	await frames(5)
	check("D pick the cube up again", await pick_up(warden))
	await seconds(2.0)
	check("D the gate stays open after the slime thaws", clock_gate.open_amount >= 1.0 and not Chill.is_chilled(keeper))

	# E. The fountains: Down-Right
	await read_tablet("R1/TabletDownRight")
	check("E the court teaches Down-Right", RuneManager.knows(&"down_right", get_tree()))
	await walk_to(2764.0)
	await face("move_right")
	check("E the lectern opens the Fountain Cube high above", await open_here(fcube))
	inscribe(["down_right"])
	manager.assembly.toggle_cube()
	await seconds(2.5)
	check("E without Long, the cold reaches only the two tallest fountains: no way up from the floor",
		fountains.slice(0, 2).all(func(f): return f.is_frozen) and fountains.slice(2).all(func(f): return not f.is_frozen), _pillar_tops(fountains))
	await seconds(6.0)
	check("E open it again", await open_here(fcube))
	inscribe(["long"])
	check("E it reads ice/freeze/down_right/long", fcube.recipe.to_key() == "ice/freeze/down_right/long", fcube.recipe.to_key())
	manager.assembly.toggle_cube()
	check("E all five freeze", await wait_until(func(): return fountains.all(func(f): return f.is_frozen), 2.5), _pillar_tops(fountains))
	check("E into a stair, 45 px a step, the top one level with the walkway", _stair_of_pillars(fountains), _pillar_tops(fountains))
	await shot("still_part_fountains")
	check("E she climbs the stair (with the cube) onto the walkway", await climb_fountains(), "at %s" % player.global_position.round())

	# F. The tide clock
	check("F west along the walkway, through the Clock Gate and up to the clock gallery", await walkway_to_gallery(),
		"at %s" % player.global_position.round())
	check("F set the cube down on the gallery, facing the clock", await put_down("move_left"), "at %s" % warden.global_position.round())
	await walk_to(warden.global_position.x + 26.0)
	await face("move_left")
	# (the cold lasts six seconds: switch it on as the tide starts to rise)
	await wait_until(func(): return clock.is_rising() and clock.level < 120.0, 14.0)
	check("F open it", await open_here(warden))
	inscribe(["ice", "freeze", "left", "normal"])
	await kindle_here()
	manager.assembly.toggle_cube()
	check("F the tide rises into the cold and freezes at the hour", await wait_until(func(): return clock.is_frozen and clock.at_hour(), 14.0),
		"level %.0f, last hold '%s'" % [clock.level, clock.last_hold])
	check("F held there, the clock strikes", await wait_until(func(): return clock.struck, 4.0))
	check("F the Sluice Door opens", await wait_until(func(): return door.open_amount >= 1.0, 5.0))
	check("F all saved", game_state().has_flag("cistern.r1.clock") and game_state().has_flag("cistern.r1.door"))
	check("F the Hush's frost lets go", await wait_until(_still_frost_gone, 6.0))
	await seconds(1.0)
	await shot("still_part_clock")

	# G. Out through the Sluice Door: down the steps, east along the walkway,
	# off its end to the floor (the fountains are water again) and on
	check("G down the steps and east along the walkway, off its end and through the open Sluice Door",
		await walk_to(3700.0, true, 25.0) and lvl.current_room == node("R2"), "at %s" % player.global_position.round())
	check("G the room is cleared", node("R1").is_cleared())
	game_state().clear_all()
	game_state().all_abilities = true


func _still_frost_gone() -> bool:
	for f in node("R1/Decor").get_children():
		if f is MeltingFrost and f.visible:
			return false
	return true


## The wrong heights for the clock: from the walkway the tide freezes short of
## the hour, and the room says so.
func scenario_c1_short() -> void:
	print("SCENARIO the Still Water: the tide held short of the hour")
	await load_scene(Journey.CISTERN)
	var clock: TideClock = node("R1/TideClock")
	var warden: RuneCube = cube_named("R1/WardenCube")
	for w in ["ice", "freeze"]:
		RuneManager.learn(StringName(w))
	# On the gallery, but with Large: the cold is taller, its lower edge lower,
	# so the rising tide meets it a stride short of the mark
	warden.global_position = Vector2(1850.0, 210.0)
	warden.reset_physics_interpolation()
	await place(Vector2(1876.0, 206.0))
	await kindle_here()
	await face("move_left")
	RuneManager.learn(&"large")
	await wait_until(func(): return clock.is_rising() and clock.level < 120.0, 14.0)
	check("open the cube on the gallery", await open_here(warden))
	inscribe(["ice", "freeze", "left", "large"])
	manager.assembly.toggle_cube()
	check("with Large the tide freezes short of the hour", await wait_until(func(): return clock.is_frozen, 14.0) and not clock.at_hour(),
		"level %.0f" % clock.level)
	check("the room says it is short, and the clock doesn't strike", await wait_until(func(): return clock.last_hold == "short", 3.0) and not clock.struck)
	game_state().clear_all()
	game_state().all_abilities = true


## The gatekeeper killed before the gate is open: the room says it can't be
## finished; Reset Room brings it back.
func scenario_c1_broken() -> void:
	print("SCENARIO the Still Water: the gatekeeper killed")
	await load_scene(Journey.CISTERN)
	var keeper = node("R1/Keeper")
	check("the room starts solvable", lvl.broken_reason == "")
	keeper.take_damage(99)
	check("the slime that had to hold the plate is killed, and the room says so",
		await wait_until(func(): return lvl.broken_reason.contains("slime"), 4.0), lvl.broken_reason)
	lvl.reset_current_room()
	await seconds(1.5)
	check("Reset Room brings it back", lvl.broken_reason == "" and is_instance_valid(node("R1/Keeper")))
	game_state().clear_all()
	game_state().all_abilities = true


## The Still Water from the door to the Sluice Door with her own feet.
func scenario_c1_full() -> void:
	print("SCENARIO the Still Water, played through with her own feet")
	await load_scene(Journey.CISTERN)
	var pool_a: CisternPool = node("R1/Pool7")
	var pool_b: CisternPool = node("R1/Pool11")
	var plug: Burnable = node("R1/IcePlug")
	var warden: RuneCube = cube_named("R1/WardenCube")
	var clock_gate: PortcullisGate = node("R1/ClockGate")
	var clock: TideClock = node("R1/TideClock")
	var door: PortcullisGate = node("R1/SluiceDoor")
	var fcube: RuneCube = cube_named("R1/FountainCube")
	var frame0 := Engine.get_physics_frames()

	# 1. The first pool
	await kindle()
	await read_tablet("R1/TabletIce")
	await read_tablet("R1/TabletFreeze")
	check("1 open the Brink Cube", await open_cube(cube_named("R1/BrinkCube")))
	inscribe(["ice", "freeze"])
	manager.assembly.toggle_cube()
	await wait_until(func(): return pool_a.frozen_fraction() > 0.99, 2.0)
	check("1 across the first pool", await run_to(620.0, [400.0], 6.0))
	# 2. The second pool
	await read_tablet("R1/TabletLong")
	check("2 open the Island Cube", await open_cube(cube_named("R1/IslandCube")))
	inscribe(["long"])
	manager.assembly.toggle_cube()
	await wait_until(func(): return pool_b.frozen_fraction() > 0.75, 2.0)
	check("2 across the second pool", await _cross_second_pool())
	# 3. The Ice Door
	await walk_to(1340.0)
	throw_fire(Vector2.RIGHT)
	await wait_until(func(): return plug.is_cleared, 2.0)
	await walk_to(warden.global_position.x - 30.0)
	check("3 the plug melted, the Warden's cube in hand", plug.is_cleared and await pick_up(warden))
	await walk_to(1600.0)
	await kindle()
	# 4. The gatekeeper
	await walk_to(2190.0)
	await put_down("move_right")
	await walk_to(warden.global_position.x - 26.0)
	await face("move_right")
	check("4 open the cube on the grate", await open_here(warden))
	inscribe(["ice", "freeze", "down"])
	manager.assembly.toggle_cube()
	check("4 the Clock Gate opens for good", await wait_until(func(): return clock_gate.open_amount >= 1.0, 6.0))
	warden.deactivate()
	await frames(5)
	check("4 the cube back in hand", await pick_up(warden))
	# 5. The fountains
	await walk_to(2900.0)
	await read_tablet("R1/TabletDownRight")
	await walk_to(2764.0)
	await face("move_right")
	check("5 the lectern", await open_here(fcube))
	inscribe(["down_right", "long"])
	manager.assembly.toggle_cube()
	await seconds(0.6)
	check("5 up the frozen fountains onto the walkway", await climb_fountains(), "at %s" % player.global_position.round())
	# 6. The clock
	check("6 through the Clock Gate, up to the gallery", await walkway_to_gallery(), "at %s" % player.global_position.round())
	await put_down("move_left")
	await walk_to(warden.global_position.x + 26.0)
	await face("move_left")
	await wait_until(func(): return clock.is_rising() and clock.level < 120.0, 14.0)
	check("6 open the cube by the clock", await open_here(warden))
	inscribe(["ice", "freeze", "left"])
	manager.assembly.toggle_cube()
	check("6 the clock strikes the hour", await wait_until(func(): return clock.struck, 16.0), "level %.0f" % clock.level)
	check("6 the Sluice Door opens", await wait_until(func(): return door.open_amount >= 1.0, 5.0))
	# 7. Out: down the steps, along the walkway, down to the floor, the door
	check("7 through the Sluice Door into the next room", await walk_to(3700.0, true, 25.0) and lvl.current_room == node("R2"),
		"at %s" % player.global_position.round())
	check("7 every step of the room is done", node("R1").is_cleared())
	print("  (the scripted route took %.0f s of game time)" % ((Engine.get_physics_frames() - frame0) / 60.0))
	game_state().clear_all()
	game_state().all_abilities = true


func scenario_c1_look() -> void:
	print("SCENARIO the Still Water: screenshots")
	await load_scene(Journey.CISTERN)
	var spots := {
		"still_01_stair": Vector2(300, 530), "still_02_pool": Vector2(400, 530), "still_03_island": Vector2(640, 530),
		"still_04_bank": Vector2(1200, 530), "still_05_hall": Vector2(1560, 530), "still_06_clock": Vector2(1720, 530),
		"still_07_gallery": Vector2(1850, 206), "still_08_walk": Vector2(2260, 302), "still_09_keeper": Vector2(2150, 530),
		"still_10_court": Vector2(2620, 530), "still_11_lectern": Vector2(2800, 530), "still_12_door": Vector2(3480, 530),
	}
	for key in spots:
		await place(spots[key])
		await seconds(1.4)
		await shot(key)
	check("the Still Water loads with its clock", lvl.get_node_or_null("R1/TideClock") != null)
	game_state().clear_all()
	game_state().all_abilities = true


func scenario_c2_look() -> void:
	print("SCENARIO the Great Sluice: screenshots")
	await load_scene(Journey.CISTERN)
	await enter_room("R2")
	var tide: TidePool = node("R2/Tide")
	var earth_layer: TileMapLayer = lvl.find_child("Earth", true, false)
	for c in [Vector2i(109, 4), Vector2i(109, 6), Vector2i(115, 3), Vector2i(115, 5), Vector2i(94, 1), Vector2i(94, 3), Vector2i(81, 8)]:
		var q := PhysicsPointQueryParameters2D.new()
		q.position = Vector2(c.x * 64 + 32, c.y * 64 + 54)
		q.collision_mask = 2
		print("  cell %s source=%d solid_at_%s=%s" % [c, earth_layer.get_cell_source_id(c) if earth_layer else -9, q.position,
			not lvl.get_world_2d().direct_space_state.intersect_point(q).is_empty()])
	# (dry for the walk through the hall; then the tide at its height)
	tide.still = true
	tide.level = tide.low_level
	var spots := {
		"sluice_01_entry": Vector2(3640, 530), "sluice_02_cell": Vector2(4230, 530), "sluice_03_gate": Vector2(4560, 530),
		"sluice_04_lectern": Vector2(4720, 530), "sluice_05_pier1": Vector2(5248, 496), "sluice_06_pier2": Vector2(5568, 270),
		"sluice_07_east": Vector2(6150, 530), "sluice_08_high_door": Vector2(6110, 142), "sluice_09_weigh": Vector2(6560, 530),
		"sluice_10_shelf": Vector2(6880, 530), "sluice_11_high_walk": Vector2(6560, 142), "sluice_12_well": Vector2(7010, 142),
		"sluice_18_span_below": Vector2(6760, 530), "sluice_19_pier_lectern": Vector2(5590, 270),
	}
	for key in spots:
		await place(spots[key])
		await seconds(1.4)
		await shot(key)
	# The tide frozen just under the doorways, walked on
	tide.level = 60.0
	tide._freeze()
	tide._frozen_left = 99.0
	await place(Vector2(5000, 534))
	await seconds(1.4)
	await shot("sluice_13_ice_low")
	tide._thaw()
	tide.level = tide.high_level
	tide._freeze()
	tide._frozen_left = 99.0
	await place(Vector2(6110, 142))
	await seconds(1.4)
	await shot("sluice_14_ice_high")
	tide._thaw()
	tide.level = 300.0
	await place(Vector2(4720, 530))
	await seconds(1.4)
	await shot("sluice_15_tide_west")
	var well: TidePool = node("R2/BellWell")
	well.set_powered(true)
	node("R2/GreatSluiceGate").set_open(true)
	await seconds(3.5)
	await place(Vector2(7200, 594))
	await seconds(1.4)
	await shot("sluice_16_well_drained")
	await place(Vector2(7500, 594))
	await seconds(1.0)
	await shot("sluice_17_outflow")
	check("the Great Sluice loads with its tide", tide != null and well is TidePool)
	game_state().clear_all()
	game_state().all_abilities = true


# ---------------------------------------------------------------- the Great Sluice (the Cistern, room 2)

## The Cistern's second room as a player reaches it: the first room's words
## known, standing in its doorway.
func _c2_arrive() -> void:
	await load_scene(Journey.CISTERN)
	for w in ["ice", "freeze", "long", "down_right"]:
		RuneManager.learn(StringName(w))
	await enter_room("R2")


func _on_ledge(y: float) -> bool:
	return player.is_on_floor() and absf(player.global_position.y - y) < 6.0


## The Silence Gallery: Persist on the Keeper Cube holds the slime on the slow
## plate until the Silence Gate opens. With `wrong`, first the cube as written
## (a six-second freeze) is shown to be too short.
func _c2_silence(wrong: bool) -> void:
	var keeper_cube: RuneCube = cube_named("R2/KeeperCube")
	var plate: PressurePlate = node("R2/CellPlate")
	var gate: PortcullisGate = node("R2/SilenceGate")
	await walk_to(3808.0)
	await kindle()
	await read_tablet("R2/TabletPersist")
	check("A the tablet teaches Persist", RuneManager.knows(&"persist", get_tree()))
	check("A open the Keeper Cube on the grate", await open_cube(keeper_cube))
	check("A only its last word can change", keeper_cube.is_slot_locked(RuneFragments.Kind.DIRECTION)
		and not keeper_cube.is_slot_locked(RuneFragments.Kind.MODIFIER))
	if wrong:
		manager.assembly.toggle_cube()
		check("A as written, the cold sinks through the grate and the slime freezes on the plate",
			await wait_until(func(): return plate.is_pressed, 3.0))
		var opened := await wait_until(func(): return gate.open_amount > 0.05, 9.0)
		check("A but the freeze lets go before the slow plate opens the gate", not opened and not plate.is_pressed)
		check("A open it again", await open_here(keeper_cube))
	inscribe(["persist"])
	check("A it reads ice/freeze/down/persist", keeper_cube.recipe.to_key() == "ice/freeze/down/persist", keeper_cube.recipe.to_key())
	manager.assembly.toggle_cube()
	check("A held by Persist, after eight seconds the Silence Gate opens, for good",
		await wait_until(func(): return gate.open_amount >= 1.0, 14.0) and game_state().has_flag("cistern.r2.silence"))
	keeper_cube.deactivate()
	await seconds(1.5)
	check("A the gate stays open after the slime thaws", gate.open_amount >= 1.0 and not Chill.is_chilled(node("R2/Keeper")))


## The Tide Hall: Persist on the Tide Lever (from the west lectern) as the
## tide comes in; across the ice, the Sluice Cube from the low pier, on to the
## east floor.
func _c2_cross() -> void:
	var tide: TidePool = node("R2/Tide")
	var lever: RuneCube = cube_named("R2/TideLever")
	var sluice: RuneCube = cube_named("R2/SluiceCube")
	var west_gate: PortcullisGate = node("R2/WestTideGate")
	var east_gate: PortcullisGate = node("R2/EastTideGate")
	# (over the Keeper Cube on the grate, through the Silence Gate)
	check("B over the Keeper Cube and through the Silence Gate to the west lectern",
		await run_to(4748.0, [player.global_position.x], 10.0), "at %s" % player.global_position.round())
	await face("move_right")
	check("B the west lectern works the Tide Lever", await open_here(lever))
	inscribe(["persist"])
	check("B it reads ice/freeze/down/persist", lever.recipe.to_key() == "ice/freeze/down/persist", lever.recipe.to_key())
	manager.assembly.close()
	await frames(4)
	# (the game waits while the screen is open: switch it on as the tide starts in)
	await wait_until(func(): return tide.is_rising() and tide.level < 0.0, 25.0)
	check("B open the lever again as the tide comes in", await open_here(lever))
	manager.assembly.toggle_cube()
	check("B the rising tide freezes level with the doorway", await wait_until(func(): return tide.is_frozen, 4.0)
		and absf(tide.surface_y() - 534.0) < 1.0, "surface %.0f" % tide.surface_y())
	check("B and the doorway gates stay open over the ice", await wait_until(func(): return west_gate.open_amount >= 1.0 and east_gate.open_amount >= 1.0, 3.0))
	await shot("sluice_part_ice")
	await walk_to(5160.0)
	check("B across the ice to the low pier, and up onto it", await hop_to(5205.0) and _on_ledge(502.0) and recoveries_since == 0,
		"at %s" % player.global_position.round())
	check("B the Sluice Cube is hers to carry", await pick_up(sluice))
	check("B over the ice and through the east doorway", await walk_to(6110.0, false, 14.0) and _on_ledge(534.0) and recoveries_since == 0,
		"at %s" % player.global_position.round())
	check("B the cube came too, and the lever held the whole way", sluice.is_carried and lever.is_active and tide.is_frozen,
		"mana %.0f" % player.current_mana)
	lever.deactivate()
	await seconds(2.0)
	check("B switched off, the ice lets go", not tide.is_frozen)


## The Weigh House: the Sluice Cube in the socket under the shelf (Ice,
## Freeze, Right, Persist) freezes the slimes hopping on the pan; a Strong wind
## from the Drover Cube shoves the Ballast off its shelf, and the kerb stops it
## on the pan.
func _c2_weigh(wrong: bool) -> void:
	var sluice: RuneCube = cube_named("R2/SluiceCube")
	var drover: RuneCube = cube_named("R2/DroverCube")
	var pan: PressurePlate = node("R2/WeighPan")
	var ballast: WindBody = node("R2/Ballast")
	var carrier: Node = player.get_node("RuneCarrier")
	await walk_to(6432.0)
	await kindle()
	check("C under the shelf to the pan's socket", await walk_to(6612.0), "at %s" % player.global_position.round())
	var placed := await put_down("move_right")
	check("C set the Sluice Cube in the socket", placed and sluice.fed_by_dungeon(),
		"at %s (%s)" % [sluice.global_position.round(), carrier.get("reason")])
	await walk_to(sluice.global_position.x - 26.0)
	await face("move_right")
	check("C open it", await open_here(sluice))
	inscribe(["ice", "freeze", "persist"])
	check("C it reads ice/freeze/right/persist", sluice.recipe.to_key() == "ice/freeze/right/persist", sluice.recipe.to_key())
	manager.assembly.toggle_cube()
	check("C on, fed by the socket", sluice.is_active and sluice.fed_by_dungeon())
	check("C the slimes freeze as they hop into the cold: two weights", await wait_until(func(): return pan.weight() >= 2, 20.0),
		"weight %d, slimes at %.0f %.0f" % [pan.weight(), node("R2/WeigherA").global_position.x, node("R2/WeigherB").global_position.x])
	await walk_to(6476.0)
	await face("move_right")
	var start := ballast.global_position
	check("C the lectern by the flame works the Drover Cube", await open_here(drover))
	if wrong:
		manager.assembly.toggle_cube()
		await seconds(2.0)
		check("C a steady wind can't shift the stone", ballast.global_position.distance_to(start) < 4.0)
		drover.deactivate()
		await frames(4)
		check("C open it again", await open_here(drover))
	inscribe(["strong"])
	check("C it reads wind/push/right/strong", drover.recipe.to_key() == "wind/push/right/strong", drover.recipe.to_key())
	manager.assembly.toggle_cube()
	check("C the Strong wind shoves the Ballast off its shelf, and the kerb stops it on the pan: three weights",
		await wait_until(func(): return pan.is_powered(), 6.0), "weight %d, stone at %s" % [pan.weight(), ballast.global_position.round()])
	drover.deactivate()
	await seconds(1.5)
	check("C the pan stays down", pan.is_powered() and not ballast.is_lost and lvl.broken_reason == "",
		"stone at %s" % ballast.global_position.round())
	await shot("sluice_part_pan")


## Up the lift to the high ledge, and the tide frozen at its top from the high
## lectern: with the pan held, the Great Sluice opens and the well drains.
func _c2_high_mark() -> void:
	var tide: TidePool = node("R2/Tide")
	var lever: RuneCube = cube_named("R2/TideLever")
	var lift: Node2D = node("R2/WeighLift")
	var mark: TideMark = node("R2/HighMark")
	var well: TidePool = node("R2/BellWell")
	await walk_to(6150.0)
	await wait_until(func(): return lift.global_position.y < 300.0, 15.0)
	await walk_to(6272.0)
	await wait_until(func(): return lift.global_position.y >= 515.0, 15.0)
	check("C up the lift", await wait_until(func(): return lift.global_position.y <= 129.0, 15.0) and _on_ledge(146.0),
		"at %s" % player.global_position.round())
	check("C west off the lift onto the high ledge", await walk_to(6150.0, true) and _on_ledge(146.0), "at %s" % player.global_position.round())
	await walk_to(6154.0)
	await face("move_right")
	await wait_until(func(): return tide.level >= tide.high_level - 0.5 and not tide.is_frozen, 25.0)
	check("D the high lectern works the lever too", await open_here(lever))
	manager.assembly.toggle_cube()
	check("D switched on while the tide stands at its top, it freezes there: the high mark", await wait_until(func(): return mark.is_powered(), 2.0),
		"surface %.0f" % tide.surface_y())
	check("D with the pan held as well, the Great Sluice opens for good", await wait_until(func(): return game_state().has_flag("cistern.r2.sluice"), 5.0))
	check("D the Bell Well drains", await wait_until(func(): return well.level <= 0.0, 8.0) and node("R2/GreatSluiceGate").open_amount >= 1.0)
	await shot("sluice_part_sluice")
	lever.deactivate()


## With the sluice open: down from the high ledge, the Sluice Cube out of its
## socket, up the lift, an ice bridge over the High Walk's fallen span; then
## down into the drained well, out through the sluice gate for the last page,
## and the bell.
func _c2_bell() -> void:
	var lift: Node2D = node("R2/WeighLift")
	var sluice: RuneCube = cube_named("R2/SluiceCube")
	var pan: PressurePlate = node("R2/WeighPan")
	# Off the high ledge onto the lift at the bottom, and back to the socket
	await wait_until(func(): return lift.global_position.y >= 515.0, 15.0)
	await walk_to(6300.0)
	check("E down from the high ledge", await wait_until(func(): return _on_ledge(534.0), 4.0), "at %s" % player.global_position.round())
	await walk_to(6634.0)
	await face("move_right")
	check("E open the Sluice Cube in its socket and switch it off", await open_here(sluice))
	manager.assembly.toggle_cube()
	manager.assembly.close()
	await frames(4)
	check("E the Sluice Cube back out of its socket (the sluice stays open)", await pick_up(sluice)
		and game_state().has_flag("cistern.r2.sluice"))
	await seconds(2.0)
	check("E the slimes thaw, and the pan lets go", not pan.is_powered())
	# Back up the lift with it
	await wait_until(func(): return lift.global_position.y < 300.0, 15.0)
	await walk_to(6272.0)
	await wait_until(func(): return lift.global_position.y >= 515.0, 15.0)
	check("E up the lift with the cube", await wait_until(func(): return lift.global_position.y <= 129.0, 15.0) and _on_ledge(146.0),
		"at %s" % player.global_position.round())
	check("E east along the High Walk to the fallen span", await walk_to(6594.0) and _on_ledge(146.0),
		"at %s" % player.global_position.round())
	check("E set the cube at its edge", await put_down("move_right"), "(%s)" % player.get_node("RuneCarrier").get("reason"))
	await walk_to(sluice.global_position.x - 26.0)
	await face("move_right")
	check("E open it", await open_here(sluice))
	inscribe(["bridge", "normal"])
	check("E it reads ice/bridge/right/normal", sluice.recipe.to_key() == "ice/bridge/right/normal", sluice.recipe.to_key())
	manager.assembly.toggle_cube()
	check("E a bridge of ice reaches over the span", await wait_until(func(): return sluice.is_active, 1.0))
	await shot("sluice_part_bridge")
	check("E over the cube and across the bridge", await run_to(7000.0, [player.global_position.x], 10.0) and _on_ledge(146.0)
		and recoveries_since == 0, "at %s" % player.global_position.round())
	check("E off its end into the drained well", await walk_to(7150.0, false, 6.0) and _on_ledge(598.0) and recoveries_since == 0,
		"at %s" % player.global_position.round())
	check("E out through the sluice gate: the Warden's page", await walk_to(7520.0, false, 6.0)
		and await wait_until(func(): return game_state().has_flag("cistern.page.5"), 2.0))
	await walk_to(7200.0)
	await interact()
	check("E the Tide Bell rings and the wing is complete", await wait_until(func(): return game_state().has_flag("cistern.complete"), 25.0))
	check("E the end card leads to the pictures", lvl.next_chapter == Journey.CISTERN_INTERLUDE)
	get_tree().paused = false


func scenario_c2() -> void:
	print("SCENARIO the Great Sluice, part by part")
	await _c2_arrive()
	check("its pieces are pixel art, not drawn shapes", lvl.find_children("*", "Polygon2D", true, false).is_empty())
	var tide: TidePool = node("R2/Tide")
	var lows := []
	for k in 10:
		lows.append(tide.level)
		await seconds(2.2)
	check("the tide fills the hall and empties it", lows.max() > 360.0 and lows.min() <= 0.0, str(lows.map(func(v): return roundi(v))))
	check("the Bell Well is full and the Great Sluice shut", node("R2/BellWell").level > 290.0 and node("R2/GreatSluiceGate").open_amount <= 0.0)
	await _c2_silence(true)
	await _c2_cross()
	await _c2_weigh(true)
	await _c2_high_mark()
	await _c2_bell()
	game_state().clear_all()
	game_state().all_abilities = true


## The Great Sluice from its door to the bell with her own feet, no detours.
func scenario_c2_full() -> void:
	print("SCENARIO the Great Sluice, played through with her own feet")
	await _c2_arrive()
	var frame0 := Engine.get_physics_frames()
	await _c2_silence(false)
	await _c2_cross()
	await _c2_weigh(false)
	await _c2_high_mark()
	await _c2_bell()
	check("every step of the room is done", node("R2").is_cleared())
	print("  (the scripted route took %.0f s of game time)" % ((Engine.get_physics_frames() - frame0) / 60.0))
	game_state().clear_all()
	game_state().all_abilities = true


## A charged jump straight up from where she stands, drifting toward `to_x`
## once she is in the air.
func charged_hop_to(to_x: float) -> bool:
	var dir := "move_left" if to_x < player.global_position.x else "move_right"
	Input.action_press("crouch")
	await seconds(2.7)
	await tap_action("jump")
	Input.action_release("crouch")
	await wait_until(func(): return not player.is_on_floor(), 0.6)
	var start_y := player.global_position.y
	await wait_until(func(): return player.global_position.y < start_y - 108.0 or player.velocity.y >= 0.0, 1.5)
	Input.action_press(dir)
	await wait_until(func(): return player.global_position.x <= to_x + 4.0 if dir == "move_left" else player.global_position.x >= to_x - 4.0, 1.5)
	Input.action_release(dir)
	var landed := await wait_until(func(): return player.is_on_floor(), 3.0)
	await frames(6)
	return landed


## The optional pages: iv on the gallery's high shelf (a charged jump), vi on
## the far pier (the tide frozen on its way down, from the high ledge).
func scenario_c2_pages() -> void:
	print("SCENARIO the Great Sluice: the optional pages")
	await _c2_arrive()
	await walk_to(3940.0)
	check("iv a charged jump up onto the gallery's high shelf", await charged_hop_to(4000.0) and _on_ledge(434.0),
		"at %s" % player.global_position.round())
	check("iv the Warden's page iv", await wait_until(func(): return game_state().has_flag("cistern.page.4"), 2.0))
	# The far pier: from the high ledge (as after the crossing), the lever on
	# Persist, switched on as the falling tide passes just under the pier's top
	var tide: TidePool = node("R2/Tide")
	var lever: RuneCube = cube_named("R2/TideLever")
	RuneManager.learn(&"persist")
	await place(Vector2(6154.0, 142.0))
	await kindle_here()
	await face("move_right")
	check("vi the high lectern", await open_here(lever))
	inscribe(["persist"])
	manager.assembly.close()
	await frames(4)
	await wait_until(func(): return tide.level >= tide.high_level - 0.5, 25.0)
	await wait_until(func(): return not tide.is_rising() and tide.surface_y() >= 292.0, 10.0)
	check("vi switched on as the falling tide passes under the far pier", await open_here(lever))
	manager.assembly.toggle_cube()
	check("vi it freezes there, a hop under the pier's top", await wait_until(func(): return tide.is_frozen, 1.0)
		and tide.surface_y() > 274.0 and tide.surface_y() < 330.0, "surface %.0f" % tide.surface_y())
	await shot("sluice_part_far_pier")
	check("vi off the high ledge onto the ice", await walk_to(5900.0, false, 6.0) and _on_ledge(tide.surface_y()) and recoveries_since == 0,
		"at %s" % player.global_position.round())
	await walk_to(5660.0)
	check("vi up onto the far pier", await hop_to(5600.0) and _on_ledge(274.0), "at %s" % player.global_position.round())
	check("vi the Warden's page vi", await wait_until(func(): return game_state().has_flag("cistern.page.6"), 2.0))
	lever.deactivate()
	await seconds(3.0)
	check("vi let go, the tide falls away under the pier and leaves her on it", _on_ledge(274.0) and recoveries_since == 0,
		"at %s" % player.global_position.round())
	# The Warden's lectern on the pier brings her down: the next tide frozen
	# level with the doorways, and off the pier onto it
	await walk_to(5546.0)
	await face("move_left")
	await wait_until(func(): return tide.is_rising() and tide.level < 0.0, 25.0)
	check("vi the Warden's lectern on the pier works the lever too", await open_here(lever))
	manager.assembly.toggle_cube()
	check("vi the rising tide freezes level with the doorways below her", await wait_until(func(): return tide.is_frozen, 4.0)
		and absf(tide.surface_y() - 534.0) < 1.0, "surface %.0f" % tide.surface_y())
	check("vi off the pier onto the ice and out through the east doorway", await walk_to(6110.0, false, 12.0) and _on_ledge(534.0)
		and recoveries_since == 0, "at %s" % player.global_position.round())
	lever.deactivate()
	game_state().clear_all()
	game_state().all_abilities = true


## The creatures the room needs, killed: the room says so, and Reset Room
## brings them back.
func scenario_c2_broken() -> void:
	print("SCENARIO the Great Sluice: what it needs, lost")
	await _c2_arrive()
	check("the room starts solvable", lvl.broken_reason == "")
	node("R2/Keeper").take_damage(99)
	check("the slime under the grate killed: the room says it can't be finished",
		await wait_until(func(): return lvl.broken_reason.contains("slow plate"), 4.0), lvl.broken_reason)
	lvl.reset_current_room()
	await seconds(1.5)
	check("Reset Room brings it back", lvl.broken_reason == "" and is_instance_valid(node("R2/Keeper")))
	node("R2/WeigherB").take_damage(99)
	check("a slime of the pan killed: the room says so", await wait_until(func(): return lvl.broken_reason.contains("pan needed"), 4.0),
		lvl.broken_reason)
	lvl.reset_current_room()
	await seconds(1.5)
	check("Reset Room brings it back too", lvl.broken_reason == "" and is_instance_valid(node("R2/WeigherB")))
	# Once the Great Sluice is open the slimes are no longer needed
	game_state().set_flag("cistern.r2.silence")
	game_state().set_flag("cistern.r2.sluice")
	node("R2/WeigherA").take_damage(99)
	await seconds(1.5)
	check("after the sluice opens, killing them breaks nothing", lvl.broken_reason == "", lvl.broken_reason)
	game_state().clear_all()
	game_state().all_abilities = true


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


func scenario_heart_look() -> void:
	print("SCENARIO the Kiln Heart: screenshots")
	await load_scene(Journey.KILN)
	await enter_room("R2")
	var spots := {
		"heart_01_hall": Vector2(3000, 530), "heart_02_shutter": Vector2(3250, 530), "heart_03_bank": Vector2(3600, 530),
		"heart_04_lake": Vector2(3950, 270), "heart_05_ledge_b": Vector2(4300, 270), "heart_06_low_ledge": Vector2(4000, 494),
		"heart_07_gallery": Vector2(4800, 270), "heart_08_racks": Vector2(5300, 270), "heart_09_heart": Vector2(5880, 530),
		"heart_10_hoist": Vector2(6200, 530), "heart_11_balcony": Vector2(6470, 206),
	}
	for key in spots:
		await place(spots[key])
		await seconds(1.2)
		await shot(key)
	check("the Kiln Heart loads with its crucible", lvl.get_node_or_null("R2/Heart") != null)
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
	# (the Cold Forge's frost: the Kiln Heart's melts when the Heart beats)
	check("F the frost melts", await wait_until(func(): return node("R1").find_children("Frost*", "", true, false).filter(func(f): return f is MeltingFrost).all(func(f): return not f.visible), 6.0))
	check("F the Kiln Heart's frost waits for the Heart", node("R2").find_children("Frost*", "", true, false).filter(func(f): return f is MeltingFrost).any(func(f): return f.visible))
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


## From the island cube: a run-up, a hop over it onto the ice, then a running
## jump off the end of the ice onto the far bank.
func _cross_second_pool() -> bool:
	await walk_to(636.0)
	var on_ice := await run_to(760.0, [648.0], 6.0)
	return on_ice and await leap("move_right", 990.0, 1150.0, 6.0, true)


## The admin switch (Journey.admin_unlock, off for every other test): every
## level open with nothing finished, and the title's admin page starting a
## wing's second room directly.
func scenario_admin() -> void:
	print("SCENARIO admin: every level open, for testing by hand")
	Journey.admin_unlock = true
	game_state().clear_all()
	game_state().all_abilities = true
	check("with nothing finished, every wing and the Eye are open", _all_wings_open() and Journey.eye_open())
	await load_scene(Journey.LANDING, false)
	var doors: Array = get_tree().get_nodes_in_group("landing_door")
	check("every door on the Long Stair is open", doors.size() == 5 and doors.all(func(d): return d.is_open()))
	# The title's admin page
	if is_instance_valid(get_tree().current_scene):
		get_tree().current_scene.queue_free()
	await get_tree().process_frame
	var title: Node = load(Journey.TITLE).instantiate()
	get_tree().root.add_child(title)
	get_tree().current_scene = title
	await frames(10)
	check("Choose a Level has the admin page", title.admin_button != null and title._admin != null)
	title._show_parts(true)
	title._show_admin(true)
	await frames(4)
	await shot("admin_title_page")
	var heart_button := _button_titled(title._admin, "Kilnworks · The Kiln Heart")
	check("it lists the Kiln Heart", heart_button != null)
	if heart_button:
		heart_button.pressed.emit()
	check("which starts the Kilnworks", await wait_until(_on_scene.bind(Journey.KILN), 6.0))
	await frames(20)
	lvl = get_tree().current_scene
	player = lvl.get_node("Player")
	check("in the Kiln Heart, with the Cold Forge unsolved", lvl.current_room == lvl.get_node("R2") and not game_state().has_flag("kiln.r1.kiln"),
		"at %s" % player.global_position.round())
	check("knowing the Kilnworks' words", RuneManager.knows(&"fire", get_tree()) and RuneManager.knows(&"burst", get_tree()))
	Journey.admin_unlock = false
	check("switched off, the doors are locked again", not Journey.wing_open(1) and not Journey.eye_open())
	game_state().clear_all()
	game_state().all_abilities = true


func _all_wings_open() -> bool:
	for i in Journey.WINGS.size():
		if not Journey.wing_open(i):
			return false
	return true


func _button_titled(parent: Node, text: String) -> Button:
	for b in parent.find_children("*", "Button", true, false):
		if (b as Button).text == text:
			return b
	return null
