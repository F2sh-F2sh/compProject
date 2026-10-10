extends Node

## Gameplay tests for Chapter 1 ("The Sealed Belfry"). Every room is solved
## with simulated input and the player's real movement; the "full" scenario
## plays the whole chapter start to finish in one go. Shared systems (reset,
## saving, checkpoints, the light rule, hazards) are checked along the way.
## Run through tests/run_tests.gd:  -- chapter [scenario]

const LEVEL := "res://scenes/chapter/chapter_1.tscn"
const DT := 1.0 / 60.0
const SHOTS := "user://test_shots/"
const FLOOR := 530.0
# Numeric enum values, so this file doesn't depend on class load order
const PISTON_RAISED := 0
const VENT_IDLE := 0
const WISP_IDLE := 0
const MIRROR_NE := 0
const MIRROR_SE := 1
const MIRROR_SW := 2
const MIRROR_NW := 3

var lvl: Node
var player: CharacterBody2D
var passed := 0
var failed := 0
var only := ""
var monitor_camera := false
## How room 9 ended: the Part Complete card (shown on the bell's pictures),
## and whether she was alive when the level made way for them.
var results_card: ChapterComplete
var ended_alive := true
var ended_hp := 0
var camera_worst := 0.0
var camera_worst_at := ""
var _cam_settle := 0
var recoveries := 0


func run_suite(filter: String) -> void:
	only = filter
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SHOTS))
	await get_tree().process_frame
	var scenarios := {
		"look": scenario_look,
		"r1": scenario_room1,
		"r2": scenario_room2,
		"r3": scenario_room3,
		"r4": scenario_room4,
		"r5": scenario_room5,
		"r6": scenario_room6,
		"r7": scenario_room7,
		"r8": scenario_room8,
		"r9": scenario_room9,
		"save": scenario_save_and_checkpoints,
		"reset": scenario_reset_rules,
		"stuck": scenario_stuck_block,
		"ways": scenario_ways_back,
		"hazards": scenario_hazard_rules,
		"guide": scenario_guidance,
		"flame": scenario_flame,
		"full": scenario_full_run,
	}
	for key in scenarios:
		if only == key or (only == "" and key != "look"):
			await scenarios[key].call()
	release_all()
	get_tree().paused = false
	print("chapter suite: passed=%d failed=%d" % [passed, failed])


# ================================================================ helpers

func check(label: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
		print("  PASS ", label, "  ", detail)
	else:
		failed += 1
		print("  FAIL ", label, "  ", detail)


func release_all() -> void:
	for a in ["move_left", "move_right", "jump", "crouch", "sprint", "shoot", "heal", "reload", "interact", "echo"]:
		Input.action_release(a)


func game_state() -> Node:
	return get_tree().root.get_node("GameState")


func sfx() -> Node:
	return get_tree().root.get_node("Sfx")


func _count_sounds(prefix: String) -> int:
	var n := 0
	for key in sfx().played:
		if String(key).begins_with(prefix):
			n += int(sfx().played[key])
	return n


## Loads the chapter. Progress is wiped unless keep_progress is set.
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
	_adopt_scene()
	await frames(10)


func _adopt_scene() -> void:
	lvl = get_tree().current_scene
	player = lvl.get_node("Player")
	recoveries = 0
	player.hazard_recovery.recovery_started.connect(func(): recoveries += 1)


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


## Enters a room at its reset spawn, as if just arriving.
func enter_room(id: String) -> void:
	await place(node(id).entry_spawn)
	await frames(10)


## Walks (or sprints) to x and stops there.
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


func tap_action(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)


func interact() -> void:
	await tap_action("interact")


## One tapped jump while holding a direction; waits for the landing.
func hop(dir: String) -> void:
	Input.action_press(dir)
	await tap_action("jump")
	await wait_until(func(): return not player.is_on_floor(), 0.4)
	await wait_until(func(): return player.is_on_floor(), 2.5)
	Input.action_release(dir)
	await frames(6)


## Keeps running right and jumps at each take-off x, landing between jumps.
func run_across(takeoffs: Array, sprint := false) -> bool:
	Input.action_press("move_right")
	if sprint:
		Input.action_press("sprint")
	var ok := true
	for x in takeoffs:
		ok = ok and await wait_until(func(): return player.is_on_floor() and player.global_position.x >= x, 6.0)
		await tap_action("jump")
		ok = ok and await wait_until(func(): return not player.is_on_floor(), 0.4)
		ok = ok and await wait_until(func(): return player.is_on_floor(), 2.5)
	Input.action_release("move_right")
	Input.action_release("sprint")
	await frames(8)
	return ok


## Crouches to charge the big jump, then jumps, drifting in `dir` once airborne.
func charged_jump(dir := "", hold := 2.6) -> float:
	var start_y := player.global_position.y
	Input.action_press("crouch")
	await seconds(hold)
	if dir != "":
		Input.action_press(dir)
	await tap_action("jump")
	Input.action_release("crouch")
	var best := start_y
	var t := 0.0
	await wait_until(func(): return not player.is_on_floor(), 0.3)
	while not player.is_on_floor() and t < 3.0:
		best = minf(best, player.global_position.y)
		await get_tree().physics_frame
		t += DT
	if dir != "":
		Input.action_release(dir)
	await frames(6)
	return start_y - best


func aim_and_shoot(world_pos: Vector2) -> void:
	if DisplayServer.get_name() == "headless":
		await preload("res://tests/background_aim.gd").fire(player, world_pos)
		return
	# A windowed run aims through the player's aim_override, not the OS cursor
	# (it belongs to whoever is using the computer); the shot itself goes through
	# the real shoot input, mana and cooldown
	var shooter: Node = player
	shooter.aim_override = world_pos
	await tap_action("shoot")
	shooter.aim_override = null


func shot(file_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().root.get_texture().get_image().save_png(ProjectSettings.globalize_path(SHOTS + file_name + ".png"))


func current_room_id() -> String:
	var room = lvl.current_room
	return room.room_id if room else ""


func cam_rect() -> Rect2:
	var cam: Camera2D = player.get_node("Camera2D")
	var size := get_tree().root.get_visible_rect().size / cam.zoom
	var center := cam.get_screen_center_position()
	return Rect2(center - size / 2.0, size)


func _physics_process(_delta: float) -> void:
	if not monitor_camera or not is_instance_valid(lvl) or not is_instance_valid(player) or not player.is_inside_tree():
		return
	var room = lvl.get("current_room")
	if room == null or lvl.is_resetting:
		return
	# Judge the camera only once it has settled into the room
	var cam = player.get_node("Camera2D")
	if cam._bounds_tween and cam._bounds_tween.is_running():
		_cam_settle = 0
		return
	# (with smooth motion the slide's last step is drawn a step later)
	_cam_settle += 1
	if _cam_settle < 3:
		return
	var r := cam_rect()
	var b: Rect2 = room.bounds
	var over := maxf(maxf(b.position.x - r.position.x, r.end.x - b.end.x),
		maxf(b.position.y - r.position.y, r.end.y - b.end.y))
	if over > camera_worst:
		camera_worst = over
		camera_worst_at = "%s player=%s view=%s" % [room.room_id, player.global_position.round(), r]


func wait_phase_start(trap, target: int) -> void:
	await wait_until(func(): return trap.phase != target, 6.0)
	await wait_until(func(): return trap.phase == target, 6.0)


# ================================================================ room solutions
# Each starts where the player enters the room and ends in the next room.

func solve_r1() -> void:
	var block: Node2D = node("R1/Block")
	var plate = node("R1/Plate")
	var exit_gate = node("R1/ExitGate")
	check("R1 gate starts closed", exit_gate.is_fully_closed())
	await walk_to(540)
	var start_x := block.global_position.x
	Input.action_press("move_right")
	await wait_until(func(): return plate.is_pressed, 12.0)
	await seconds(1.0)
	Input.action_release("move_right")
	await frames(20)
	check("R1 walking into the block pushes it", block.global_position.x > start_x + 200.0, "x=%.0f" % block.global_position.x)
	check("R1 the kerb stops the block on the plate", plate.is_pressed and absf(block.global_position.x - 876.0) < 6.0,
		"block x=%.0f" % block.global_position.x)
	check("R1 plate opens the gate", await wait_until(func(): return exit_gate.open_amount >= 1.0, 3.0))
	check("R1 not saved while she is still in the room", not game_state().has_flag("ch1.r1.solved"))
	await run_across([0.0])
	check("R1 walked out into room 2", await walk_to(1450.0), "x=%.0f" % player.global_position.x)
	check("R1 solution saved once she has gone through", game_state().has_flag("ch1.r1.solved"))


## Pushes the block onto plate B and rings the bell by its rope.
func r2_block_and_bell() -> void:
	var slime = node("R2/BellSlime")
	var plate_b = node("R2/PlateB")
	var block: Node2D = node("R2/Block")
	var bell = node("R2/Bell")
	var exit_gate = node("R2/ExitGate")
	check("R2 the grate carries the player over the cell", await walk_to(2030.0) and player.global_position.y < 540.0,
		"y=%.0f" % player.global_position.y)
	Input.action_press("move_right")
	await wait_until(func(): return plate_b.is_pressed, 8.0)
	await seconds(0.8)
	Input.action_release("move_right")
	await frames(20)
	check("R2 the kerb stops the block on plate B", plate_b.is_pressed and absf(block.global_position.x - 2220.0) < 6.0,
		"block x=%.0f" % block.global_position.x)
	await walk_to(2096.0)
	await seconds(1.0)
	check("R2 one plate alone keeps the gate shut", exit_gate.is_fully_closed())
	await interact()
	check("R2 rope rings the bell", not bell.is_ready())
	check("R2 slime heard the bell", slime.state == 1 or slime.state == 2, "state=%d" % slime.state)


func solve_r2() -> void:
	var plate_a = node("R2/PlateA")
	var block: Node2D = node("R2/Block")
	var exit_gate = node("R2/ExitGate")
	await r2_block_and_bell()
	check("R2 slime hops onto plate A and holds it", await wait_until(func(): return plate_a.is_pressed, 8.0),
		"slime x=%.0f" % node("R2/BellSlime").global_position.x)
	check("R2 both plates open the gate", await wait_until(func(): return exit_gate.open_amount >= 1.0, 4.0))
	# Over the block (resting against the kerb) and out while the slime listens
	await run_across([block.global_position.x - 44.0], true)
	check("R2 walked out into room 3", await walk_to(2950.0, true), "x=%.0f" % player.global_position.x)
	check("R2 solution saved once she has gone through", game_state().has_flag("ch1.r2.solved"))


func solve_r3() -> void:
	var brazier = node("R3/Brazier")
	var m1 = node("R3/MirrorLow")
	var m2 = node("R3/MirrorHigh")
	var r1 = node("R3/CrystalStairs")
	var r2 = node("R3/CrystalGate")
	var exit_gate = node("R3/ExitGate")
	await walk_to(3010)
	await aim_and_shoot(brazier.global_position + Vector2(0, -32))
	check("R3 fireball lights the brazier", await wait_until(func(): return brazier.is_lit, 2.0))
	await frames(4)
	var beam = brazier._beam
	check("R3 mirror's dark back stops the beam", beam.end_node == m1 and not r1.is_powered(),
		"end=%s" % [beam.end_node])
	await walk_to(m1.global_position.x)
	while m1.facing != MIRROR_NW:
		await interact()
		await frames(6)
	check("R3 low mirror sends the beam up to the high mirror", await wait_until(func(): return r1.is_powered(), 1.0))
	check("R3 left crystal raises the stairs", await wait_until(func(): return node("R3/Stair5").is_solid, 1.0))
	await shot("r3_stairs")
	var climbed := await run_across([3290.0, 3368.0, 3432.0, 3496.0, 3560.0, 3624.0])
	check("R3 stairs can be climbed to the gallery", climbed and player.global_position.y < 285.0,
		"pos=%s" % player.global_position.round())
	await walk_to(3700)
	var turns := 0
	while m2.facing != MIRROR_SE and turns < 4:
		await interact()
		await frames(6)
		turns += 1
	check("R3 high mirror turned from the gallery wheel", m2.facing == MIRROR_SE, "facing=%d" % m2.facing)
	check("R3 right crystal lit", await wait_until(func(): return r2.is_powered(), 1.0))
	check("R3 exit gate opens", await wait_until(func(): return exit_gate.open_amount >= 1.0, 3.0))
	# The light has to stay on the crystal: turned away, the gate shuts again
	await interact()
	await frames(6)
	check("R3 turning the beam off the crystal closes the gate", not r2.is_powered()
		and await wait_until(func(): return exit_gate.is_fully_closed(), 4.0), "facing=%d" % m2.facing)
	turns = 0
	while m2.facing != MIRROR_SE and turns < 4:
		await interact()
		await frames(6)
		turns += 1
	check("R3 turned back onto it, the gate opens again", await wait_until(func(): return exit_gate.open_amount >= 1.0, 3.0))
	check("R3 stairs stay after the beam moves on", node("R3/Stair1").is_solid)
	await shot("r3_solved")
	# Down the stairs and out under the gallery
	await walk_to(3250)
	check("R3 walked out into room 4", await walk_to(4200.0, true))


func solve_r4() -> void:
	var lever = node("R4/Lever")
	var gargoyle = node("R4/Watcher")
	var plate = node("R4/HeavyPlate")
	var exit_gate = node("R4/ExitGate")
	await walk_to(lever.global_position.x)
	check("R4 the watcher ignores the player at the lever", gargoyle.state == 0, "state=%d" % gargoyle.state)
	var over := await wait_until(func(): return absf(gargoyle.global_position.x - plate.global_position.x) < 10.0, 25.0)
	await interact()
	check("R4 lever pulled with the watcher over the plate", over and lever.is_on)
	check("R4 light turns the watcher to stone", await wait_until(func(): return gargoyle.is_frozen, 1.0))
	check("R4 stone watcher presses the heavy plate", await wait_until(func(): return plate.is_pressed, 1.0))
	check("R4 exit gate opens", await wait_until(func(): return exit_gate.open_amount >= 1.0, 3.0))
	await shot("r4_solved")
	await walk_to(4330)
	await run_across([4336.0])
	await walk_to(gargoyle.global_position.x - 40.0)
	await run_across([gargoyle.global_position.x - 34.0])
	check("R4 walked out into room 5", await walk_to(5480.0, true), "x=%.0f" % player.global_position.x)


func solve_r5() -> void:
	var lift: Node2D = node("R5/Lift")
	var spikes = node("R5/RisingSpikes")
	var p1 = node("R5/Piston1")
	var p2 = node("R5/Piston2")
	var block: Node2D = node("R5/ShieldBlock")
	var vent2 = node("R5/Vent2")
	var lever = node("R5/ShortcutLever")
	var shortcut = node("R5/ShortcutGate")
	var start_health: int = player.current_health
	await walk_to(5540)
	await wait_until(func(): return lift.global_position.y >= 515.0, 10.0)
	await walk_to(5632)
	check("R5 the lift carries the player up", await wait_until(func(): return player.global_position.y < 290.0, 8.0),
		"y=%.0f" % player.global_position.y)
	await wait_until(func(): return lift.global_position.y <= 261.0, 3.0)
	await walk_to(5900)
	await wait_until(func():
		var t: float = fposmod(spikes._elapsed + spikes.start_phase * spikes.get_cycle_length(), spikes.get_cycle_length())
		return spikes.is_lowered() and t < 0.25, 8.0)
	await walk_to(6100, true)
	await wait_phase_start(p1, PISTON_RAISED)
	await walk_to(6330, true)
	await wait_phase_start(p2, PISTON_RAISED)
	await walk_to(6560, true)
	check("R5 spikes and pistons crossed without harm", player.current_health == start_health and recoveries == 0,
		"hp=%d resets=%d" % [player.current_health, recoveries])
	# Push the block to the wall as a shield against the bolts
	Input.action_press("move_right")
	await wait_until(func(): return block.global_position.x >= 6888.0, 10.0)
	await seconds(0.3)
	Input.action_release("move_right")
	await frames(10)
	check("R5 block pushed up against the plaque", block.global_position.x >= 6888.0, "x=%.0f" % block.global_position.x)
	check("R5 the block shielded the player from bolts", player.current_health == start_health,
		"hp=%d" % player.current_health)
	# The plaque is set into the step's wall: the block can only meet it, never overlap it
	var plaque: Node2D = node("R5/SkullPlaque")
	var wall_face := 108.0 * 64.0
	var block_right: float = block.global_position.x + block.block_size.x / 2.0
	check("R5 the plaque is set into the wall, so the block cannot be pushed into it",
		plaque.global_position.x - 32.0 >= wall_face - 0.5 and block_right <= plaque.global_position.x - 32.0 + 1.0,
		"plaque left edge %.0f, wall %.0f, block right edge %.0f" % [plaque.global_position.x - 32.0, wall_face, block_right])
	check("R5 its bolts start outside the wall, in the open",
		plaque.global_position.x - plaque.muzzle < wall_face, "starts at x=%.0f" % (plaque.global_position.x - plaque.muzzle))
	await run_across([0.0, 0.0])
	check("R5 block used as a step to the ledge", player.global_position.y < 220.0, "y=%.0f" % player.global_position.y)
	await walk_to(6940)
	await wait_phase_start(vent2, VENT_IDLE)
	await walk_to(7200, true)
	check("R5 vents crossed between bursts", player.current_health == start_health, "hp=%d" % player.current_health)
	await walk_to(7300)
	check("R5 dropped into the end hall", await wait_until(func(): return player.is_on_floor() and player.global_position.y > 520.0, 2.0))
	await walk_to(lever.global_position.x)
	await interact()
	check("R5 shortcut lever pulled and saved", lever.is_on and game_state().has_flag("ch1.r5.shortcut"))
	check("R5 the tunnel gate opens", await wait_until(func(): return shortcut.open_amount >= 1.0, 3.0))
	check("R5 walked out into room 6", await walk_to(7520.0, true))


func solve_r6() -> void:
	var wisp = node("R6/Wisp")
	var hidden := [node("R6/HiddenPath1"), node("R6/HiddenPath2"), node("R6/HiddenPath3"), node("R6/HiddenPath4")]
	var perches := [node("R6/PerchB"), node("R6/PerchC"), node("R6/PerchD"), node("R6/PerchE")]
	var perch_f = node("R6/PerchF")
	var bridge = node("R6/LightBridge")
	var lever = node("R6/WalkwayLever")
	await walk_to(7650)
	check("R6 first hidden platform lit by the wisp", hidden[0].is_solid)
	check("R6 far hidden platforms stay unsolid in the dark", not hidden[2].is_solid and not hidden[3].is_solid)
	await walk_to(7700)
	await run_across([7738.0])
	check("R6 landed on the first hidden platform", player.global_position.y < 540.0 and player.global_position.x > 7776.0,
		"pos=%s" % player.global_position.round())
	for i in 4:
		var x0: float = hidden[i].global_position.x
		await walk_to(x0 + 30.0)
		await interact()
		var arrived := await wait_until(func(): return wisp.state == WISP_IDLE and wisp.current_perch == perches[i], 4.0)
		var next_solid := true
		if i < 3:
			next_solid = await wait_until(func(): return hidden[i + 1].is_solid, 1.0)
		check("R6 wisp called to bracket %d lights the way ahead" % (i + 2), arrived and next_solid and hidden[i].is_solid)
		await run_across([x0 + 58.0])
	check("R6 reached the island", player.global_position.x > 8256.0 and player.global_position.y < 540.0,
		"pos=%s" % player.global_position.round())
	await walk_to(8330)
	await interact()
	check("R6 wisp called across to the far crystal", await wait_until(func(): return wisp.current_perch == perch_f and wisp.state == WISP_IDLE, 6.0))
	check("R6 crystal raises the light bridge", await wait_until(func(): return bridge.is_solid, 1.0))
	await walk_to(8350)
	var crossed := await run_across([8378.0, 8474.0, 8602.0])
	check("R6 crossed the crumbling ledges", crossed and player.global_position.x > 8640.0 and player.global_position.y < 540.0,
		"pos=%s" % player.global_position.round())
	check("R6 crossed the light bridge", await walk_to(9080.0) and player.global_position.y < 540.0)
	await walk_to(lever.global_position.x)
	await interact()
	check("R6 walkway lever saved", game_state().has_flag("ch1.r6.walkway"))
	check("R6 the return walkway appears", await wait_until(func(): return node("R6/Walkway0").is_solid, 1.0))
	check("R6 walked out into room 7", await walk_to(9320.0, true))


func solve_r7() -> void:
	var brazier = node("R7/BelfryFlame")
	var bars = node("R7/BarredWindow")
	var mirror = node("R7/BelfryMirror")
	var gargoyle = node("R7/Watcher")
	var plate = node("R7/HeavyPlate")
	var seal = node("R7/RuneSeal")
	var door = node("R7/GreatDoor")
	await walk_to(9330)
	await aim_and_shoot(brazier.global_position + Vector2(0, -32))
	check("R7 fireball lights the belfry flame", await wait_until(func(): return brazier.is_lit, 2.0))
	await frames(4)
	check("R7 the closed window blocks the beam", brazier._beam.end_node == bars or brazier._beam.path[brazier._beam.path.size() - 1].x < 9900.0)
	await walk_to(9960)
	var turns := 0
	while mirror.facing != MIRROR_SW and turns < 4:
		await interact()
		await frames(6)
		turns += 1
	check("R7 mirror turned toward the heavy plate", mirror.facing == MIRROR_SW)
	await walk_to(9712)
	await interact()
	check("R7 bell rung", not node("R7/Bell").is_ready())
	check("R7 slime holds the window open", await wait_until(func(): return bars.open_amount >= 1.0, 8.0))
	check("R7 watcher turns to stone on the heavy plate", await wait_until(func(): return gargoyle.is_frozen and plate.is_pressed, 14.0),
		"watcher x=%.0f" % gargoyle.global_position.x)
	check("R7 the seal wakes rune by rune", await wait_until(func(): return seal.lit_runes > 0 and not seal.is_open, 2.0))
	check("R7 the seal opens the great door", await wait_until(func(): return seal.is_open and door.open_amount >= 1.0, 6.0))
	await shot("r7_solved")
	await seconds(12.0)
	check("R7 the window stays open after the slime leaves", bars.open_amount >= 1.0 and gargoyle.is_frozen)
	await walk_to(gargoyle.global_position.x - 40.0)
	await run_across([gargoyle.global_position.x - 34.0])
	check("R7 through the great door into the choir loft", await walk_to(11180.0), "x=%.0f" % player.global_position.x)
	check("R7 seal saved once she has gone through", game_state().has_flag("ch1.r7.solved"))


func solve_r8() -> void:
	var lever_a = node("R8/LeverA")
	var lever_b = node("R8/LeverB")
	var loft_gate = node("R8/LoftGate")
	var recorder = player.get_node("EchoRecorder")
	await walk_to(lever_a.global_position.x)
	# Record: wait a moment, pull lever A, stop. The Echo replays from here.
	await tap_action("echo")
	await seconds(2.4)
	await interact()
	await frames(6)
	await tap_action("echo")
	check("R8 an Echo is recorded at the first lever", recorder.echoes.size() >= 1)
	await walk_to(lever_b.global_position.x, true)
	check("R8 the Echo pulls the first lever", await wait_until(func(): return lever_a.is_on, 3.0))
	await interact()
	check("R8 both levers down at once open the loft gate", await wait_until(func(): return loft_gate.open_amount >= 1.0, 4.0))
	check("R8 solution saved", game_state().has_flag("ch1.r8.solved"))
	await shot("r8_solved")
	check("R8 walked out into the great bell tower", await walk_to(12560.0, true), "x=%.0f" % player.global_position.x)


func solve_r9() -> void:
	var plate = node("R9/Plate")
	var recorder = player.get_node("EchoRecorder")
	recorder.clear_echoes()
	await frames(10)
	# The hot spring at the foot of the stair gives back the word SPRING (heal)
	var spring: Node2D = node("R9/HotSpring")
	await walk_to(spring.global_position.x - 6.0)
	await interact()
	check("R9 drinking from the hot spring gives back SPRING (heal)", await wait_until(func(): return game_state().has_flag("ability.heal"), 3.0))
	await shot("r9_hot_spring")
	await walk_to(plate.global_position.x - 70.0)
	# Record walking onto the plate; the finished Echo keeps standing on it
	await tap_action("echo")
	await walk_to(plate.global_position.x)
	await seconds(0.3)
	await tap_action("echo")
	check("R9 the Echo holds the plate and the stairs rise",
		await wait_until(func(): return plate.is_pressed and node("R9/Stair6").is_solid, 4.0))
	await walk_to(12780.0)
	var climbed := await run_across([12826.0, 12904.0, 12968.0, 13032.0, 13096.0, 13160.0, 13224.0])
	check("R9 the stairs carry you up to the balcony", climbed and player.global_position.y < 220.0,
		"pos=%s" % player.global_position.round())
	await shot("r9_balcony")
	var bell = node("R9/GreatBell")
	await walk_to(bell.global_position.x + bell.rope_offset.x)
	await interact()
	check("R9 pulling the rope rings the great bell", bell.is_rung() and player.controls_locked)
	# (the level is freed once the pictures start)
	ended_alive = not player.is_dead
	ended_hp = player.current_health
	results_card = null
	await seconds(3.0)
	await shot("r9_bell")
	# The bell's pictures come straight after it; the Part Complete card follows them
	var into_pictures := await wait_until(func(): return get_tree().current_scene is StoryInterlude, 20.0)
	check("R9 the bell leads straight into its pictures", into_pictures and game_state().has_flag("ch1.complete"),
		str(get_tree().current_scene.scene_file_path if get_tree().current_scene else "none"))
	var story := get_tree().current_scene as StoryIntro
	if story == null:
		return
	await seconds(1.0)
	await shot("r9_pictures")
	check("R9 no card yet while the pictures play", not is_instance_valid(story.results_card))
	story.skip()
	var card_up := await wait_until(func(): return is_instance_valid(story.results_card), 6.0)
	check("R9 after the pictures, the Part Complete card", card_up)
	if card_up:
		results_card = story.results_card
	await seconds(1.6)
	await shot("chapter_complete")


# ================================================================ scenarios

func scenario_look() -> void:
	print("SCENARIO look (screenshots of every room)")
	await load_level()
	var spots := {
		"r1_start": Vector2(380, FLOOR), "r1_plate": Vector2(760, FLOOR),
		"r2_entry": Vector2(1500, FLOOR), "r2_pit": Vector2(2100, FLOOR), "r2_gate": Vector2(2600, FLOOR),
		"r3_floor": Vector2(3150, FLOOR), "r3_gallery": Vector2(3800, 274),
		"r4_lever": Vector2(4300, FLOOR), "r4_zone": Vector2(4700, FLOOR),
		"r5_start": Vector2(5500, FLOOR), "r5_course": Vector2(6100, 274), "r5_bolts": Vector2(6700, 274),
		"r5_step": Vector2(7050, 210), "r5_end": Vector2(7300, FLOOR),
		"r6_entry": Vector2(7640, FLOOR), "r6_island": Vector2(8320, FLOOR), "r6_landing": Vector2(8700, FLOOR),
		"r7_entry": Vector2(9340, FLOOR), "r7_mirror": Vector2(9960, FLOOR), "r7_zone": Vector2(10300, FLOOR),
		"r7_exit": Vector2(10900, FLOOR),
	}
	for key in spots:
		await place(spots[key])
		await seconds(0.8)
		await shot("chapter_" + key)
	# A hint and the pause menu
	await place(Vector2(node("R3/HintStone").global_position.x, FLOOR))
	await interact()
	await seconds(0.6)
	await shot("chapter_hint")
	var menu = node("PauseMenu")
	menu._set_open(true)
	await get_tree().process_frame
	await shot("chapter_pause")
	menu._set_open(false)
	check("screenshots taken", true)


func scenario_room1() -> void:
	print("SCENARIO room 1: push the block onto the plate")
	await load_level()
	check("starts in room 1", current_room_id() == "ch1.r1", current_room_id())
	monitor_camera = true
	camera_worst = 0.0
	await solve_r1()
	check("camera moved to room 2", current_room_id() == "ch1.r2", current_room_id())
	await seconds(0.8)
	monitor_camera = false
	check("camera stayed inside room bounds", camera_worst <= 0.5, "worst=%.2f %s" % [camera_worst, camera_worst_at])

	# Optional page on the +96 ledge needs a charged jump
	await place(Vector2(215, FLOOR))
	await hop("move_left")
	check("a tapped jump cannot reach the page ledge", player.global_position.y > 500.0, "y=%.0f" % player.global_position.y)
	await place(Vector2(215, FLOOR))
	var rise := await charged_jump("move_left")
	await frames(30)
	check("charged jump reaches the page ledge", player.global_position.y < 440.0,
		"rise=%.0f y=%.0f" % [rise, player.global_position.y])
	check("page collected", game_state().has_flag("ch1.page.1"))


func scenario_room2() -> void:
	print("SCENARIO room 2: bell, slime and two plates")
	await load_level()
	await enter_room("R2")
	var plate_a = node("R2/PlateA")
	var exit_gate = node("R2/ExitGate")
	await place(Vector2(node("R2/PlateB").global_position.x, FLOOR))
	await seconds(1.5)
	check("one plate alone does not open the gate", exit_gate.is_fully_closed())
	check("slime stays off plate A on its own", not plate_a.is_pressed)
	# The gate is open only while both plates are held: when the slime is done
	# listening it closes again (she hasn't gone through yet)
	await enter_room("R2")
	await r2_block_and_bell()
	check("the gate opens while the slime sits", await wait_until(func(): return exit_gate.open_amount >= 1.0, 10.0))
	check("slime leaves plate A after listening", await wait_until(func(): return not plate_a.is_pressed, 16.0))
	check("then the gate closes again", await wait_until(func(): return exit_gate.is_fully_closed(), 5.0))
	check("and the room isn't saved as solved", not game_state().has_flag("ch1.r2.solved"))

	await load_level()
	plate_a = node("R2/PlateA")
	exit_gate = node("R2/ExitGate")
	await enter_room("R2")
	await solve_r2()
	await seconds(12.0)
	check("slime leaves plate A after she has gone through", not plate_a.is_pressed)
	# (the way back is caged once she is in the next room, whatever its plates say)
	check("a gate she has come through drops shut behind her and stays shut", exit_gate.sealed and exit_gate.is_fully_closed(),
		"open %.2f" % exit_gate.open_amount)

	# Alternative: a fireball from plate B rings the bell
	await load_level()
	var bell = node("R2/Bell")
	exit_gate = node("R2/ExitGate")
	await place(Vector2(node("R2/PlateB").global_position.x, FLOOR))
	# (Let the camera finish sliding into the room, or the aim drifts)
	await seconds(1.2)
	await aim_and_shoot(bell.global_position + Vector2(0, -2))
	check("a fireball from plate B rings the bell", await wait_until(func(): return not bell.is_ready(), 2.0))
	check("fireball ring also opens the gate", await wait_until(func(): return exit_gate.open_amount >= 1.0, 8.0))

	# Optional page on the +100 ledge by plate B
	await place(Vector2(38 * 64 - 20, FLOOR))
	await charged_jump("move_right")
	await frames(20)
	check("room 2 page reachable with a charged jump", game_state().has_flag("ch1.page.2"),
		"pos=%s" % player.global_position.round())

	# The caged slime can't be killed by accident: fireballs splash on the
	# grate, even aimed straight down from on top of it, and it is warded
	await load_level()
	var caged = node("R2/BellSlime")
	await enter_room("R2")
	await place(Vector2(caged.global_position.x, FLOOR))
	var steps_before: int = _count_sounds("step_grate_")
	await walk_to(caged.global_position.x + 70.0)
	check("walking the grate sounds like iron, not stone", _count_sounds("step_grate_") > steps_before)
	await place(Vector2(caged.global_position.x + 30.0, FLOOR))
	for i in 3:
		await aim_and_shoot(caged.global_position + Vector2(0, -6))
		await seconds(0.5)
	check("fireballs aimed through the grate never reach the caged slime",
		caged.health == caged.max_health and not caged.is_dead, "hp=%d" % caged.health)
	check("fireballs never start below the grate",
		get_tree().get_nodes_in_group("fireball").all(func(f): return f.global_position.y < FLOOR))
	var clinks: int = int(sfx().played.get("ward_clink", 0))
	caged.take_damage(50)
	check("a stray hit only makes the ward shimmer", caged.health == caged.max_health
		and int(sfx().played.get("ward_clink", 0)) == clinks + 1)

	# A killed slime comes back when the room is reset; health is kept
	await load_level()
	var slime = node("R2/BellSlime")
	await enter_room("R2")
	slime.die()
	await seconds(1.2)
	check("killed slime is gone", slime.is_dead and not slime.visible)
	var hp: int = player.current_health - 3
	player.current_health = hp
	lvl.reset_current_room()
	await seconds(1.2)
	check("room reset revives the slime", not slime.is_dead and slime.visible)
	check("room reset does not heal", player.current_health == hp, "hp=%d" % player.current_health)
	check("room reset returns the player to the entry", player.global_position.distance_to(node("R2").entry_spawn) < 8.0)
	await solve_r2()


func scenario_room3() -> void:
	print("SCENARIO room 3: split flame")
	await load_level()
	await enter_room("R3")
	# Mana is the lantern's flame: it comes back only at a lit flame (hold R)
	var shrine: Node2D = null
	for cp in get_tree().get_nodes_in_group("chapter_checkpoint"):
		if cp.checkpoint_id == "ch1.cp.r3":
			shrine = cp
	player.current_mana = 0
	await place(Vector2(shrine.global_position.x + 400.0, FLOOR))
	Input.action_press("reload")
	await seconds(2.2)
	Input.action_release("reload")
	check("holding R restores mana away from flames", player.current_mana == 100 and not player.is_reloading,
		"mana=%d" % player.current_mana)
	await place(Vector2(shrine.global_position.x, FLOOR))
	Input.action_press("reload")
	await wait_until(func(): return player.current_mana >= 100, 3.0)
	Input.action_release("reload")
	check("holding R refills mana", player.current_mana == 100, "mana=%d reloading=%s dist=%.0f" % [player.current_mana, player.is_reloading, shrine.global_position.distance_to(player.global_position)])
	player.current_mana = 40
	await place(Vector2(shrine.global_position.x, FLOOR))
	Input.action_press("reload")
	await seconds(0.5)
	Input.action_release("reload")
	await seconds(1.5)
	check("letting go early gets nothing (it must be held)", player.current_mana == 40, "mana=%d" % player.current_mana)
	player.current_mana = 100
	await enter_room("R3")
	await solve_r3()


func scenario_room4() -> void:
	print("SCENARIO room 4: silent watcher")
	await load_level()
	await enter_room("R4")
	var lever = node("R4/Lever")
	var gargoyle = node("R4/Watcher")
	var plate = node("R4/HeavyPlate")
	var exit_gate = node("R4/ExitGate")
	await walk_to(lever.global_position.x)
	await seconds(4.0)
	check("torchlight never freezes the watcher", not gargoyle.is_frozen)
	# Wrong moment: freeze it away from the plate
	await wait_until(func(): return absf(gargoyle.global_position.x - plate.global_position.x) > 120.0, 20.0)
	await interact()
	check("lens freezes the watcher wherever it is", await wait_until(func(): return gargoyle.is_frozen, 1.0))
	await seconds(1.0)
	check("frozen away from the plate: gate stays shut", not plate.is_pressed and exit_gate.is_fully_closed())
	await interact()
	check("closing the lens wakes the watcher", await wait_until(func(): return not gargoyle.is_frozen, 1.5))
	# The player (or an Echo) is too light for the heavy plate
	await place(Vector2(plate.global_position.x, FLOOR))
	await frames(6)
	check("the player cannot press the heavy plate", not plate.is_pressed)
	var hp: int = player.current_health
	var struck := await wait_until(func(): return player.current_health < hp, 6.0)
	check("an active watcher's strike hurts", struck, "hp=%d" % player.current_health)
	check("watcher strike is not a spike recovery", recoveries == 0)
	await load_level()
	await enter_room("R4")
	await solve_r4()

	# Optional page: from the frozen watcher's back to the high ledge
	await load_level()
	await enter_room("R4")
	gargoyle = node("R4/Watcher")
	plate = node("R4/HeavyPlate")
	await walk_to(node("R4/Lever").global_position.x)
	await wait_until(func(): return absf(gargoyle.global_position.x - plate.global_position.x) < 10.0, 25.0)
	await interact()
	await wait_until(func(): return gargoyle.is_frozen, 1.0)
	await place(Vector2(gargoyle.global_position.x, 490))
	await frames(10)
	check("the frozen watcher can be stood on", player.is_on_floor() and player.global_position.y < 505.0,
		"y=%.0f" % player.global_position.y)
	await charged_jump("move_right")
	await frames(20)
	check("room 4 page reached from the watcher's back", game_state().has_flag("ch1.page.4"),
		"pos=%s" % player.global_position.round())


func scenario_room5() -> void:
	print("SCENARIO room 5: broken machinery")
	await load_level()
	await enter_room("R5")
	await solve_r5()
	# The shortcut survives a reload
	await load_level(true)
	check("shortcut gate stays open after reloading", node("R5/ShortcutGate").open_amount >= 1.0)
	await place(Vector2(5600, FLOOR))
	check("the tunnel leads straight to the end hall", await walk_to(7300.0, true), "x=%.0f" % player.global_position.x)
	check("tunnel page collected on the way", game_state().has_flag("ch1.page.5"))


func scenario_room6() -> void:
	print("SCENARIO room 6: lantern crossing")
	await load_level()
	await enter_room("R6")
	# Falling in is not fatal: the entry candle catches you
	var hp: int = player.current_health
	await walk_to(7650)
	await place(Vector2(8000, 560))
	check("chasm spikes send the player back to the entry candle",
		await wait_until(func(): return recoveries > 0 and not player.hazard_recovery.is_active(), 3.0)
		and player.global_position.x < 7744.0, "pos=%s" % player.global_position.round())
	check("chasm hit is not a death", not player.is_dead and player.current_health == hp - 2, "hp=%d" % player.current_health)
	await load_level()
	await enter_room("R6")
	await solve_r6()


func scenario_room7() -> void:
	print("SCENARIO room 7: the sealed belfry")
	await load_level()
	await enter_room("R7")
	await solve_r7()


func scenario_room8() -> void:
	print("SCENARIO room 8: the choir loft (Echo pulls a lever)")
	await load_level()
	await enter_room("R8")
	var lever_a = node("R8/LeverA")
	var lever_b = node("R8/LeverB")
	# Alone it can't be done: the first lever springs back before you arrive
	await walk_to(lever_a.global_position.x)
	await interact()
	check("R8 a spring lever goes down when pulled", lever_a.is_on)
	await walk_to(lever_b.global_position.x, true)
	await interact()
	await frames(10)
	check("R8 alone, the first lever has sprung back before you reach the second", not lever_a.is_on
		and node("R8/LoftGate").open_amount < 0.1)
	await wait_until(func(): return not lever_b.is_on, 3.0)
	await enter_room("R8")
	await solve_r8()


func scenario_room9() -> void:
	print("SCENARIO room 9: the great bell (Echo holds the plate)")
	await load_level()
	await enter_room("R9")
	var plate = node("R9/Plate")
	# Standing on the plate yourself raises the stairs, but only while you stay
	await walk_to(plate.global_position.x)
	await frames(10)
	check("R9 the plate raises the stairs", node("R9/Stair1").is_solid)
	await walk_to(plate.global_position.x + 120.0)
	check("R9 stepping off lowers them again", await wait_until(func(): return not node("R9/Stair1").is_solid, 2.0))
	await enter_room("R9")
	await solve_r9()
	if results_card:
		results_card.title_button.pressed.emit()
	var changed := await wait_until(_on_title_screen, 5.0)
	check("the card's Title button returns to the title screen", changed,
		str(get_tree().current_scene.scene_file_path if get_tree().current_scene else "none"))
	check("the game is not left paused", not get_tree().paused)


func _on_title_screen() -> bool:
	return get_tree().current_scene != null and get_tree().current_scene.scene_file_path.ends_with("title_screen.tscn")


func scenario_save_and_checkpoints() -> void:
	print("SCENARIO saving, checkpoints and death")
	await load_level()
	await solve_r1()
	await place(Vector2(128, 430))
	await frames(10)
	check("page 1 collected", game_state().has_flag("ch1.page.1"))
	await place(Vector2(2900, FLOOR))
	await walk_to(2990)
	check("walking past the room 3 shrine saves it", game_state().get_checkpoint_for(LEVEL) == "ch1.cp.r3",
		game_state().get_checkpoint_for(LEVEL))
	# A real death: the death screen, then restart at the last shrine
	player.take_damage(99, null)
	check("lethal damage kills", await wait_until(func(): return player.is_dead, 2.0))
	var death = node("DeathUI/DeathScreen")
	await seconds(1.0)
	check("death screen shown", death.visible and get_tree().current_scene == lvl)
	check("death screen ignores presses before its prompt", not death.can_restart)
	await wait_until(func(): return death.can_restart, 5.0)
	var old_id := lvl.get_instance_id()
	var press := InputEventAction.new()
	press.action = "jump"
	press.pressed = true
	Input.parse_input_event(press)
	var restarted := await wait_until(func(): return get_tree().current_scene != null and get_tree().current_scene.get_instance_id() != old_id, 3.0)
	var release := InputEventAction.new()
	release.action = "jump"
	Input.parse_input_event(release)
	check("pressing jump restarts", restarted)
	if not restarted:
		return
	await frames(10)
	_adopt_scene()
	check("respawned at the room 3 shrine", player.global_position.distance_to(node("R3/Shrine").get_spawn_position()) < 8.0,
		"pos=%s" % player.global_position.round())
	check("respawn is in room 3", current_room_id() == "ch1.r3", current_room_id())
	check("full health after a death", player.current_health == 10)
	# (solved and saved; she is two rooms on, so the way back to it is caged)
	check("solved room stays solved after death, and the way back stays caged", game_state().has_flag("ch1.r1.solved")
		and node("R1/ExitGate").sealed and node("R1/ExitGate").is_fully_closed(), "open %.2f" % node("R1/ExitGate").open_amount)
	check("collected page does not come back", not lvl.has_node("R1/LorePage1"))
	check("the room 3 shrine is lit on respawn", node("R3/Shrine").is_lit)
	check("pages counted for the pause menu", lvl.pages_found() == 1)

	# Restart Chapter from the pause menu wipes progress (after a second press)
	var menu = node("PauseMenu")
	menu._set_open(true)
	check("pause menu pauses the game", get_tree().paused)
	menu._on_restart()
	check("first press only arms Restart Chapter", game_state().has_flag("ch1.r1.solved") and get_tree().paused)
	old_id = lvl.get_instance_id()
	menu._on_restart()
	var reloaded := await wait_until(func(): return get_tree().current_scene != null and get_tree().current_scene.get_instance_id() != old_id, 3.0)
	await frames(10)
	_adopt_scene()
	check("Restart Chapter reloads from the start", reloaded and current_room_id() == "ch1.r1", current_room_id())
	check("Restart Chapter clears saved progress", not game_state().has_flag("ch1.r1.solved") and not game_state().has_flag("ch1.page.1"))


func scenario_reset_rules() -> void:
	print("SCENARIO room reset rules")
	await load_level()
	var block: Node2D = node("R1/Block")
	var start: Vector2 = block.global_position
	await walk_to(540)
	Input.action_press("move_right")
	await seconds(1.2)
	Input.action_release("move_right")
	await frames(10)
	check("block moved before the reset", block.global_position.x > start.x + 40.0)
	lvl.reset_current_room()
	await seconds(1.0)
	check("reset puts the block back", block.global_position.distance_to(start) < 1.0)
	lvl.reset_current_room()
	await seconds(1.0)
	check("resetting twice is the same as once", block.global_position.distance_to(start) < 1.0 and not node("R1/Plate").is_pressed)
	check("controls return after a reset", not player.controls_locked)

	# Echoes and spells in flight are cleared
	var recorder = player.get_node("EchoRecorder")
	await tap_action("echo")
	await walk_to(600)
	await tap_action("echo")
	await frames(30)
	check("an Echo exists before the reset", recorder.echoes.size() == 1)
	lvl.reset_current_room()
	await seconds(1.0)
	check("reset clears Echoes", recorder.echoes.size() == 0)
	check("reset returns the mana cap", player.get_mana_cap() == 100, "cap=%d" % player.get_mana_cap())

	# A solved (saved) puzzle survives a reset of the room she is in (room 2,
	# with room 1's way out caged behind her: she can't go back into room 1)
	await solve_r1()
	var block_at: Vector2 = node("R1/Block").global_position
	lvl.reset_current_room()
	await seconds(0.6)
	check("saved solutions survive a reset", current_room_id() == "ch1.r2" and game_state().has_flag("ch1.r1.solved")
		and node("R1/Block").global_position.distance_to(block_at) < 1.0 and node("R1/ExitGate").sealed, current_room_id())

	# Reset in a creature room puts the watcher back to patrolling
	await enter_room("R4")
	await walk_to(node("R4/Lever").global_position.x)
	await interact()
	await wait_until(func(): return node("R4/Watcher").is_frozen, 1.0)
	lvl.reset_current_room()
	await seconds(1.0)
	check("reset closes the lens and wakes the watcher", not node("R4/Lever").is_on and not node("R4/Watcher").is_frozen)
	var menu = node("PauseMenu")
	menu._set_open(true)
	check("Reset Room is available in the pause menu", not menu._reset_button.disabled)
	menu._set_open(false)


## Room 1's block shoved the wrong way, into the wall: nobody can get behind it
## again, so the room says it can't be finished and how to reset it; Reset
## Room puts the block back.
func scenario_stuck_block() -> void:
	print("SCENARIO a block pushed the wrong way, into the wall")
	await load_level()
	await enter_room("R1")
	var block: PushableBlock = node("R1/Block")
	var start_x := block.global_position.x
	check("the room starts solvable", lvl.broken_reason == "" and node("R1").broken_reason() == "")
	# Round to its right side, then push it left as far as it goes
	await place(Vector2(start_x + 40.0, FLOOR))
	await walk_to(start_x - 520.0, false, 10.0)
	check("the block is shoved up against the wall", block.global_position.x < start_x - 300.0, "x=%.0f" % block.global_position.x)
	check("the room says it can't be finished now", await wait_until(func(): return lvl.broken_reason.contains("against the wall"), 3.0),
		lvl.broken_reason)
	check("the Esc menu is told to open on Reset Room", PauseMenu.reset_suggested)
	lvl.reset_current_room()
	await seconds(1.2)
	check("Reset Room puts the block back and the room is solvable again", lvl.broken_reason == "" and absf(block.global_position.x - start_x) < 2.0
		and not PauseMenu.reset_suggested, "x=%.0f, %s" % [block.global_position.x, lvl.broken_reason])
	# Pushed the right way, onto its plate, it is never "stuck"
	await place(Vector2(start_x - 40.0, FLOOR))
	await walk_to(start_x + 260.0, false, 8.0)
	await frames(20)
	check("on its plate against the kerb it is fine", lvl.broken_reason == "", lvl.broken_reason)


## On into the next room, the gate drops behind her and stays down (whatever
## its circuit says, and through Reset Room); open doorways between rooms get
## gates of their own. Continuing from a shrine in an earlier room leaves the
## way on open; from a shrine further on, the ways back are shut at once.
func scenario_ways_back() -> void:
	print("SCENARIO the way back shuts behind her")
	await load_level()
	game_state().set_flag("ch1.r1.solved")
	await load_level(true)
	await seconds(0.5)
	var gate: PortcullisGate = node("R1/ExitGate")
	check("Room 1's exit gate stands open (its plate was solved)", await wait_until(func(): return gate.open_amount >= 1.0, 3.0))
	var back_gates := lvl.find_children("BackGate", "", true, false)
	check("the open doorways between rooms have gates ready to drop", back_gates.size() >= 4
		and back_gates.all(func(g): return g is PortcullisGate and g.open_amount >= 1.0), str(back_gates.size()))
	# (past Room 1's block, by its open gate)
	await place(Vector2(1180, FLOOR))
	await walk_to(1460.0)
	check("on into Room 2", current_room_id() == "ch1.r2", current_room_id())
	check("the gate drops behind her", await wait_until(func(): return gate.is_fully_closed(), 3.0) and gate.sealed)
	await walk_to(1200.0, false, 3.0)
	check("and there is no walking back through it", player.global_position.x > gate.global_position.x + 10.0,
		"x=%.0f" % player.global_position.x)
	lvl.reset_current_room()
	await seconds(1.2)
	check("Reset Room doesn't raise it", gate.is_fully_closed())
	await shot("ways_back_gate")
	# Continuing from the first shrine (in Room 1): the way on is open again
	game_state().set_checkpoint(LEVEL, "ch1.cp.start")
	await load_level(true)
	await seconds(0.5)
	gate = node("R1/ExitGate")
	check("from the first shrine, the way on into Room 2 is open", current_room_id() == "ch1.r1"
		and gate.open_amount >= 1.0 and not gate.sealed, current_room_id())
	# From Room 3's shrine: the ways back behind it are shut at once
	game_state().set_checkpoint(LEVEL, "ch1.cp.r3")
	await load_level(true)
	await seconds(0.5)
	check("from Room 3's shrine, the ways back are shut already and the way on is not", current_room_id() == "ch1.r3"
		and node("R1/ExitGate").sealed and node("R2/ExitGate").sealed and not node("R3/ExitGate").sealed, current_room_id())


func scenario_hazard_rules() -> void:
	print("SCENARIO hazard damage rules")
	await load_level()
	# Standing in a vent: damage is paced, never every frame
	await enter_room("R5")
	var vent = node("R5/Vent1")
	await place(Vector2(vent.global_position.x, 210))
	player.current_health = 10
	await wait_phase_start(vent, 2)
	await seconds(0.9)
	check("standing in a vent burst costs at most two hits", player.current_health >= 6, "hp=%d" % player.current_health)
	# Bolts hurt when there is no shield
	await load_level()
	await enter_room("R5")
	node("R5/ShieldBlock").global_position.x = 6300
	await place(Vector2(6800, 274))
	var hp: int = player.current_health
	check("an arcane bolt hurts an unshielded player", await wait_until(func(): return player.current_health < hp, 4.0))
	# A crushing piston hurts and never leaves the player inside it
	await load_level()
	await enter_room("R5")
	var piston = node("R5/Piston1")
	await wait_phase_start(piston, 1)
	await place(Vector2(piston.global_position.x + 6.0, 274))
	hp = player.current_health
	await seconds(1.0)
	var head_bottom: float = piston.global_position.y + piston.get_head_bottom()
	var inside: bool = absf(player.global_position.x - piston.global_position.x) < 30.0 and player.global_position.y > head_bottom - 40.0 and piston.progress > 0.5
	check("a falling piston hurts", player.current_health < hp, "hp=%d" % player.current_health)
	check("the player is pushed out from under the head", not inside, "player=%s" % player.global_position.round())
	check("a crush fades the player back to safety, like a spike", recoveries >= 1, "recoveries=%d" % recoveries)
	# Walking the course lights the piston candle; a crush then returns there
	await load_level()
	await enter_room("R5")
	var candle = node("R5/CandlePistons")
	await place(Vector2(candle.global_position.x - 40.0, 274))
	await walk_to(candle.global_position.x + 20.0)
	check("the piston candle lights as you pass", candle.is_active)
	var p1 = node("R5/Piston1")
	await wait_phase_start(p1, 1)
	await place(Vector2(p1.global_position.x, 274))
	await wait_until(func(): return player.hazard_recovery.is_active(), 2.0)
	await wait_until(func(): return not player.hazard_recovery.is_active(), 2.0)
	await frames(6)
	check("a crushed player restarts the pistons from their candle",
		player.global_position.distance_to(candle.get_respawn_position()) < 8.0, "pos=%s" % player.global_position.round())


func scenario_guidance() -> void:
	print("SCENARIO guidance: acts, objectives, links, cues, nudges, map")
	var settings := get_tree().root.get_node("Settings")
	settings.guidance = settings.GUIDANCE_FULL
	await load_level()
	var rooms: Array = lvl.rooms
	check("every room states a goal and has steps", rooms.all(func(r): return r.objective != "" \
		and r.get_steps().any(func(s): return not s.optional)))
	check("the chapter is split into four acts", rooms.filter(func(r): return r.act != "").size() == 4)
	check("each room's lore page shows as an optional step", rooms.filter(func(r): return not r.page_ids.is_empty()) \
		.all(func(r): return r.get_steps().any(func(s): return s.optional)))
	var cards := get_tree().current_scene.get_children().filter(func(n): return n is TitleCard)
	check("the chapter opens with its act card", cards.size() == 1)
	var panel: ObjectivePanel = lvl._objective
	await seconds(1.0)
	check("the objective card shows the room's goal", panel.visible and panel._goal.text == node("R1").objective)
	# Link preview: near a plate, its groove lights toward the gate
	var circuit = node("R1/PlateToGate")
	check("links are quiet from afar", circuit.preview == 0.0)
	await place(Vector2(node("R1/Plate").global_position.x - 40.0, FLOOR))
	await seconds(0.5)
	check("standing near a plate lights the groove to its gate", circuit.preview > 0.9, "%.2f" % circuit.preview)
	# Solving the room ticks its step and marks it cleared
	await enter_room("R1")
	await solve_r1()
	check("solving room 1 completes its step and clears it", node("R1").is_cleared()
		and game_state().has_flag("ch1.clear.r1"))
	# Room 2's steps follow the puzzle in order
	await enter_room("R2")
	var steps: Array = node("R2").get_steps()
	check("a fresh room starts with no steps done", not steps.any(func(s): return s.done and not s.optional))
	await solve_r2()
	check("room 2's steps complete as the puzzle is solved", steps.filter(func(s): return not s.optional).all(func(s): return s.done))
	# Far cue: a lever you can use shows its key from a few steps away
	await load_level()
	await enter_room("R4")
	var lever = node("R4/Lever")
	var cue: Interactable = lever.get_children().filter(func(n): return n is Interactable)[0]
	await place(Vector2(lever.global_position.x + 110.0, FLOOR))
	await seconds(0.4)
	check("a usable thing shows a faint key cue from nearby", cue._prompt.visible and cue._prompt.modulate.a < 0.6
		and cue._label.text.begins_with("["), "alpha %.2f '%s'" % [cue._prompt.modulate.a, cue._label.text])
	# Nudge: after four deaths in a room its hint stone calls out
	var stone = node("R4/HintStone")
	game_state().bump("deaths.ch1.r4", 4)
	await frames(3)
	check("four deaths in a room make its hint stone call out", stone.nudging)
	# The first hint says where to look; arrows come only with the second
	var arrows := func() -> int: return get_tree().current_scene.find_children("*", "Node2D", true, false) \
		.filter(func(n): return n is HintStone.HintMarker).size()
	stone.next_hint()
	await frames(3)
	check("hint 1 shows no arrows", arrows.call() == 0, str(arrows.call()))
	stone.next_hint()
	await frames(3)
	check("hint 2 marks the objects with arrows", arrows.call() > 0, str(arrows.call()))
	# The step pips are for full guidance; at Light the card is just the goal
	check("full guidance shows the step pips", lvl._objective._pips.visible)
	settings.guidance = settings.GUIDANCE_LIGHT
	lvl._objective.refresh()
	check("at Light the card shows only the goal, no pips", not lvl._objective._pips.visible and lvl._objective.visible)
	settings.guidance = settings.GUIDANCE_FULL
	lvl._objective.refresh()
	# The map lists the acts and rooms, with the current one marked
	var menu = node("PauseMenu")
	menu._set_open(true)
	menu._show_map(true)
	await frames(3)
	var lines: Array = menu._map_list.get_children().map(func(l): return l.text)
	menu._set_open(false)
	check("the map marks the current room", lines.any(func(t): return t.contains("▶") and t.contains("The Silent Watcher")), str(lines))
	check("the map hides rooms not yet seen", lines.any(func(t): return t.contains("? ? ?")))
	# Guidance off: no card, no links, no cues
	settings.guidance = settings.GUIDANCE_OFF
	await load_level()
	await seconds(0.5)
	await place(Vector2(node("R1/Plate").global_position.x - 40.0, FLOOR))
	await seconds(0.5)
	check("with guidance off there is no objective card or link glow",
		not lvl._objective.visible and node("R1/PlateToGate").preview == 0.0)
	settings.guidance = settings.GUIDANCE_FULL


func scenario_flame() -> void:
	print("SCENARIO the Room 7 belfry flame is easy to notice")
	await load_level()
	var room = node("R7")
	var flame = node("R7/BelfryFlame")
	var torches := node("R7/Decor").get_children().filter(func(n): return String(n.name).begins_with("Torch145"))
	check("no wall torch under the flame to hide it among", torches.is_empty(), str(torches.map(func(n): return n.name)))
	check("its unlit light is bright enough to find", not flame.is_lit and flame._light.energy >= 0.6, "energy %.2f" % flame._light.energy)
	check("the objective card names the flame until it is lit",
		room.get_steps()[0].todo_label.contains("flame") and not room.get_steps()[0].done)
	# The first time ever in the room the camera glances at it
	var cam = player.get_node("Camera2D")
	await enter_room("R7")
	var peak := 0.0
	for i in 240:
		await get_tree().physics_frame
		peak = maxf(peak, cam._focus_offset.length())
	check("the first time in, the camera glances at the flame", peak > 20.0, "peak offset %.0f" % peak)
	await enter_room("R6")
	await seconds(1.0)
	await enter_room("R7")
	var peak_again := 0.0
	for i in 240:
		await get_tree().physics_frame
		peak_again = maxf(peak_again, cam._focus_offset.length())
	check("and not again on later visits", peak_again < 1.0, "peak offset %.1f" % peak_again)
	# A card line for a step that is not done disappears once it is
	var panel: ObjectivePanel = lvl._objective
	check("the card shows the flame line", panel._todo.visible and panel._todo.text.contains("flame"))
	flame.ignite()
	await seconds(0.4)
	check("and drops it once the flame is lit", not panel._todo.visible)


func scenario_full_run() -> void:
	print("SCENARIO full chapter run, start to finish")
	await load_level()
	monitor_camera = true
	camera_worst = 0.0
	var t0 := Time.get_ticks_msec()
	await solve_r1()
	await solve_r2()
	await solve_r3()
	check("room 3 shrine saved on the way", game_state().get_checkpoint_for(LEVEL) == "ch1.cp.r3")
	await solve_r4()
	await solve_r5()
	# (Walking out of room 5 passes room 6's shrine at its door)
	check("room 5 and 6 shrines saved on the way", game_state().get_checkpoint_for(LEVEL) in ["ch1.cp.r5", "ch1.cp.r6"],
		game_state().get_checkpoint_for(LEVEL))
	await solve_r6()
	await solve_r7()
	check("finale shrine saved on the way", game_state().get_checkpoint_for(LEVEL) == "ch1.cp.finale")
	await solve_r8()
	await solve_r9()
	monitor_camera = false
	check("camera never showed outside the current room", camera_worst <= 0.5, "worst=%.2f %s" % [camera_worst, camera_worst_at])
	check("full run finished alive", ended_alive, "hp=%d" % ended_hp)
	print("  full run took %.0f s of real time" % ((Time.get_ticks_msec() - t0) / 1000.0))
	check("the full run ends with the Part Complete card, after the bell's pictures", results_card != null)
	if results_card:
		var labels: Array = results_card.find_children("*", "Label", true, false).map(func(l): return l.text)
		check("the card shows the run's statistics", labels.has("Time") and labels.has("Deaths") and labels.has("Ledger pages"),
			str(labels))
		results_card._close()
	get_tree().paused = false
