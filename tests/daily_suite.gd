extends Node

## The daily puzzle: its random numbers and calendar, the vocabulary it lends,
## the generator and the oracle, and (in the real physics) that every way the
## oracle predicts really solves a generated room and the ways it rules out do
## not. Run with:
##   godot --path . --fixed-fps 60 --script res://tests/run_tests.gd -- daily
## Scenarios (second argument): rng, calendar, kit, generator, fairness,
## level, simulation.

var passed := 0
var failed := 0
var completed := false
var lvl: Node
var player: CharacterBody2D


func check(label: String, ok: bool, detail := "") -> void:
	passed += int(ok)
	failed += int(not ok)
	print("  PASS " if ok else "  FAIL ", label, "  " + detail if detail != "" else "")


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func seconds(s: float) -> void:
	await frames(int(s * 60.0))


func run_suite(filter: String) -> void:
	var table := {
		"endless": scenario_endless,
		"rng": scenario_rng,
		"calendar": scenario_calendar,
		"kit": scenario_kit,
		"generator": scenario_generator,
		"fairness": scenario_fairness,
		"score": scenario_score,
		"code": scenario_code,
		"store": scenario_store,
		"persistence": scenario_persistence,
		"cards": scenario_cards,
		"level": scenario_level,
		"simulation": scenario_simulation,
		"sweep": scenario_sweep,
		"look": scenario_look,
		"screens": scenario_screens,
		"assembly": scenario_assembly,
		"difficulty": scenario_difficulty,
		"sweep_up": scenario_sweep_up,
		"module_probe": scenario_module_probe,
		"render_procgen": scenario_render_procgen,
		"verified_fresh": scenario_verified_fresh,
		"new_modules": scenario_new_modules,
		"chains": scenario_chains,
		"endless_long": scenario_endless_long,
		"calibration": scenario_calibration,
		"endless_persistence": scenario_endless_persistence,
		"cube_help": scenario_cube_help,
		"challenge_rules": scenario_challenge_rules,
		"grand_cheese": scenario_grand_cheese,
		"grand_corpus": scenario_grand_corpus,
		"scale_audit": scenario_scale_audit,
		"all_cheese": scenario_all_cheese,
		"reset_solutions": scenario_reset_solutions,
		"all_corpus": scenario_all_corpus,
		"combo_resets": scenario_combo_resets,
		"impact_reset": scenario_impact_reset,
		"portal_handoff": scenario_portal_handoff,
		"placement_resets": scenario_placement_resets,
		"unlocked_combos": scenario_unlocked_combos,
		"portal_limits": scenario_portal_limits,
		"portal_cargo": scenario_portal_cargo,
		"portal_reset_spam": scenario_portal_reset_spam,
		"stage_reset_spam": scenario_stage_reset_spam,
		"variety": scenario_variety,
		"gentle_profiles": scenario_gentle_profiles,
	}
	for key in table:
		if (filter == "" and key != "sweep" and key != "look" and key != "sweep_up" and key != "module_probe" and key != "endless_long" and key != "render_procgen" and key != "grand_corpus" and key != "scale_audit" and key != "all_corpus" and key != "unlocked_combos") or filter == key:
			await table[key].call()
	await leave()
	completed = true
	print("daily suite: passed=%d failed=%d" % [passed, failed])


## Opens a scene as the current scene.
func open(path: String) -> void:
	get_tree().paused = false
	if is_instance_valid(get_tree().current_scene):
		get_tree().current_scene.queue_free()
		await get_tree().process_frame
	lvl = load(path).instantiate()
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	await frames(8)
	player = lvl.get_node_or_null("Player")


## Leaves the daily level so the story's conditions are put back.
func leave() -> void:
	if is_instance_valid(lvl):
		lvl.queue_free()
		await frames(3)
	DailyRun.spec_override = {}


# ------------------------------------------------------------------ pure logic

func _grand_fixture(second_id: String, second_params: Dictionary) -> Dictionary:
	return {"reuse": true, "beats": [
		{"module": "kindling", "params": {"count": 1, "high": false, "lock": 1, "guided": false}},
		{"module": second_id, "params": second_params}]}


func _open_grand_fixture(params: Dictionary) -> void:
	DailyRun.start("trial", 51515, 0, 4, 4)
	DailyRun.spec_override = spec_for(params, 4, "chain")
	await open(DailyRun.SCENE)
	player.controls_locked = false


func _walk_to(x: float, limit := 300, sprint := false) -> void:
	var direction := "move_right" if x > player.position.x else "move_left"
	Input.action_press(direction)
	if sprint: Input.action_press("sprint")
	for i in limit:
		await frames(1)
		if player.is_dead or absf(player.position.x - x) < 4:
			break
		if (direction == "move_right" and player.position.x >= x) or (direction == "move_left" and player.position.x <= x): break
	Input.action_release(direction)
	Input.action_release("sprint")
	await frames(8)


func _jump_right(charge := false, duration := 80) -> void:
	if charge:
		Input.action_press("crouch")
		await frames(90)
	Input.action_press("jump")
	Input.action_press("move_right")
	Input.action_press("sprint")
	await frames(3)
	Input.action_release("jump")
	Input.action_release("crouch")
	await frames(duration)
	Input.action_release("move_right")
	Input.action_release("sprint")
	await frames(8)


## Teleports only establish an attack's starting fixture; movement, jumps,
## carrying and drops below use the actual player/physics and carrier API.
func scenario_grand_cheese() -> void:
	print("SCENARIO Grand adversarial jumps, cube steps and false milestones")
	var params := _grand_fixture("dark_hall", {"gaps": 1, "guided": false})
	await _open_grand_fixture(params)
	var part: Dictionary = lvl.pieces[0]
	var cube: RuneCube = part["beats"][0]["cubes"].values()[0]
	var gate: PortcullisGate = part["beats"][0]["gate"]
	var carrier: RuneCarrier = RuneManager.get_for(get_tree()).carrier
	player.teleport_to(cube.global_position + Vector2(-28, -2))
	await frames(8)
	player.animated_sprite.flip_h = false
	check("attack picks up the real shared cube", carrier.try_pick_up() == "")
	await _walk_to(gate.position.x - 68)
	check("attack can legally place a cube beside the unsolved gate", carrier.try_place() == "")
	await frames(6)
	Input.action_press("jump")
	await frames(1)
	Input.action_release("jump")
	await _walk_to(cube.position.x, 30)
	await frames(60)
	check("attack stands on the cube as a jumping step", player.is_on_floor() and player.position.y < RoomKit.FLOOR_Y - 20, str(player.position))
	check("internal doorway renders for inspection", get_viewport().get_texture().get_image().save_png(
		ProjectSettings.globalize_path("res://.godot/grand-internal-gate.png")) == OK)
	await _jump_right(true, 60)
	check("cube-assisted charged jump cannot bypass an unsolved beat gate", player.position.x < gate.position.x and not part["beats"][0]["steps"].all(func(step): return step.done), str(player.position))
	check("jump attack did not inscribe any runes", DailyRun.casts == 0)
	player.animated_sprite.flip_h = true
	check("cube remains recoverable after the blocked jump", carrier.try_pick_up() == "")
	await _walk_to(gate.position.x - 17, 30)
	player.animated_sprite.flip_h = false
	check("a carried cube cannot be placed through the closed internal gate", carrier.try_place() != "" and carrier.held != null)
	await leave()
	for gaps in [1, 2]:
		for charged in [false, true]:
			params = _grand_fixture("dark_hall", {"gaps": gaps, "guided": false})
			await _open_grand_fixture(params)
			part = lvl.pieces[0]
			var first: Dictionary = part["beats"][0]
			first["module"].perform(first, first["module"].plans(params["beats"][0]["params"], DailyKit.words(4))[0])
			await frames(100)
			check("dark-hall attack starts after legitimately solving the first beat", first["steps"].all(func(step): return step.done))
			var second: Dictionary = part["beats"][1]
			var edge: float = second["gap_edges"][0]
			player.teleport_to(Vector2(edge - 38, RoomKit.FLOOR_Y - 2))
			await frames(8)
			await _jump_right(charged, 90)
			check("unlit gap %d (%s jump) cannot open the exit by touching its landing area" % [gaps, "charged" if charged else "normal"],
				second["gate"].open_amount < 0.1 and not lvl.rooms[0].is_cleared(), str(player.position))
			check("unlit jump has no revealed stepping stones", second["stones"].all(func(stone): return not stone.is_solid))
			await leave()
	params = _grand_fixture("updraft", {"dist": 1, "rows": 3, "width": 3, "mirror": false, "lock": 0, "guided": false})
	await _open_grand_fixture(params)
	part = lvl.pieces[0]
	cube = part["beats"][0]["cubes"].values()[0]
	cube.recipe = RuneRecipe.from_key("fire/projectile/right/repeat")
	check("a sustained first-beat rune can be activated", cube.activate(false) == "")
	await frames(100)
	check("first-beat Fire cannot pre-complete the second beat's wind objective", not part["beats"][1]["steps"][0].done)
	await leave()
	# Walk into the heavy puzzle stones without any rune force.
	for first_id in ["dead_weight", "burn_through"]:
		var first_params := DeadWeightModule.new().fallback(4) if first_id == "dead_weight" else {"kind": 1, "distance": 2}
		params = _grand_fixture("updraft", {"dist": 1, "rows": 3, "width": 3, "mirror": false, "lock": 0, "guided": false})
		params["beats"][0] = {"module": first_id, "params": first_params}
		await _open_grand_fixture(params)
		part = lvl.pieces[0]
		var first: Dictionary = part["beats"][0]
		var stone: WindBody = first["stone"] if first_id == "dead_weight" else first["impact_stones"][0]
		var stone_x := stone.position.x
		player.teleport_to(stone.position + Vector2(-42, -2))
		await frames(8)
		await _walk_to(stone_x + 150, 240, true)
		check("%s heavy stone cannot be shoved by walking or sprinting" % first_id, absf(stone.position.x - stone_x) < 2, str(stone.position.x - stone_x))
		check("%s cannot clear with manual stone pushing" % first_id, not first["steps"].all(func(step): return step.done) and DailyRun.casts == 0)
		await leave()
	# A valid route with real carrying and continuous movement: no driver
	# teleports, no direct cube placement and no automatic second inscription.
	params = _grand_fixture("updraft", {"dist": 1, "rows": 3, "width": 3, "mirror": false, "lock": 0, "guided": false})
	await _open_grand_fixture(params)
	part = lvl.pieces[0]
	var first: Dictionary = part["beats"][0]
	first["module"].perform(first, first["module"].plans(params["beats"][0]["params"], DailyKit.words(4))[0])
	await frames(100)
	cube = first["cubes"].values()[0]
	await _walk_to(cube.position.x - 28)
	carrier = RuneManager.get_for(get_tree()).carrier
	check("valid route picks up its solved first-beat cube", carrier.try_pick_up() == "")
	var second: Dictionary = part["beats"][1]
	await _walk_to(float(second["reuse_position"].x) - RuneCarrier.PLACE_AHEAD, 600, true)
	check("valid route carries the cube through the open internal doorway", player.position.x > first["gate"].position.x)
	check("valid route can place the cube beside the wind wall", carrier.try_place() == "")
	await frames(5)
	for i in 4: cube.set_slot(i, [&"wind", &"lift", &"up", &"normal"][i])
	check("valid route can reinscribe and activate Lift", cube.activate(false) == "")
	await _walk_to(second["gate"].position.x + 40, 600)
	check("the legitimate carried-cube wind route clears with continuous movement", lvl.rooms[0].is_cleared() and player.position.x > second["gate"].position.x, str(player.position))
	await leave()
	var day := DailyRng.day_index(2026, 10, 11)
	var today := DailyGenerator.generate(DailyGenerator.seed_for_day(day), 4, 4)
	for i in today["rooms"].size():
		await _open_grand_fixture(today["rooms"][i]["params"])
		part = lvl.pieces[0]
		# Repeated charged jumps and sprinting from the actual entrance.
		for attempt in 3:
			await _walk_to(player.position.x + 120, 80, true)
			await _jump_right(true, 70)
			if player.is_dead: break
		check("today's Grand room %d resists entrance jump/sprint spam without inscriptions" % (i + 1), not lvl.rooms[0].is_cleared() and player.position.x < part["gate"].position.x and DailyRun.casts == 0)
		await leave()

## A deterministic corpus covers each first/second mechanism pairing found
## in 1,000 Grand seeds. Two distinct full plans must still clear each pair.
## Additional runtime acceptance: ... -- daily grand_corpus
func scenario_grand_corpus() -> void:
	print("SCENARIO Grand mechanism-pair physical corpus")
	var cases := {}
	var pairs := {}
	for seed in 1000:
		for room in DailyGenerator.generate(seed, 4, 4)["rooms"]:
			var pair := String(room["beats"][0]["module"]) + " -> " + String(room["beats"][1]["module"])
			pairs[pair] = true
			var variant := pair
			if room["beats"][0]["module"] == "burn_through": variant += " barrier=%d" % int(room["beats"][0]["params"]["kind"])
			if room["beats"][1]["module"] == "dark_hall": variant += " gaps=%d" % int(room["beats"][1]["params"]["gaps"])
			if not cases.has(variant): cases[variant] = room["params"]
	check("the corpus covers varied Grand mechanism pairings with a meaningful first choice", pairs.size() >= 8, str(pairs.keys()))
	check("the corpus also covers distinct barriers and unlit gap counts", cases.size() > pairs.size(), str(cases.size()))
	for pair in cases:
		var params: Dictionary = cases[pair]
		var plans := DailyChain.new().plans(params, DailyKit.words(4))
		check(String(pair) + " has multiple verified plans", plans.size() >= 2)
		for plan in [plans[0], plans[-1]]:
			check(String(pair) + " clears with " + String(plan["label"]), await try_plan("chain", params, plan, 24, 4))
	await leave()


func scenario_all_corpus() -> void:
	print("SCENARIO all named difficulties: generated mechanism and barrier corpus")
	var cases := {}
	for level in range(1, 6):
		var tier := DailyDifficulty.tier_for(level)
		for seed in 1000:
			for room in DailyGenerator.generate(seed, level, tier)["rooms"]:
				var variant := "%d" % level
				var beats: Array = room.get("beats", [{"module": room["module"], "params": room["params"]}])
				for beat in beats:
					variant += " / " + String(beat["module"])
					for field in ["kind", "width", "gaps", "rows", "high", "mirror"]:
						if beat["params"].has(field): variant += " %s=%s" % [field, str(beat["params"][field])]
				if not cases.has(variant): cases[variant] = {"room": room, "tier": tier, "level": level}
	check("all-level corpus contains distinct mechanisms and geometry variants", cases.size() > 30, str(cases.size()))
	for label in cases:
		var item: Dictionary = cases[label]
		var room: Dictionary = item["room"]
		await _attack_open(room["module"], room["params"], item["tier"], item["level"])
		for attempt in 2:
			await _walk_to(player.position.x + 140, 80, true)
			await _jump_right(attempt == 1, 90)
			if player.is_dead: break
		check(String(label) + " rejects movement-only completion", not lvl.rooms[0].is_cleared() and player.position.x < lvl.pieces[0]["gate"].position.x)
		await leave()
		var module := DailyModules.make(room["module"])
		var plans := module.plans(room["params"], DailyKit.words(item["tier"]))
		check(String(label) + " retains multiple valid plans", plans.size() >= 2)
		for plan in [plans[0], plans[-1]]:
			check(String(label) + " remains solvable: " + String(plan["label"]), await try_plan(room["module"], room["params"], plan, 24, item["tier"]))
	await leave()


func _legal_cube_keys(cube: RuneCube, words: PackedStringArray) -> Array[String]:
	var keys: Array[String] = []
	# Fixed carvings can use a word above the lent tier (e.g. Up on the
	# gentle lift cube). They remain fixed, not newly editable vocabulary.
	var fixed := cube.recipe.to_key().split("/")
	var available := words.duplicate()
	for kind in 4:
		if cube.is_slot_locked(kind) and fixed[kind] != "-" and not available.has(fixed[kind]): available.append(fixed[kind])
	for key in DailyKit.sentences(available):
		var parts := key.split("/")
		var original := cube.recipe.to_key().split("/")
		var allowed := true
		for kind in 4:
			if cube.is_slot_locked(kind) and parts[kind] != original[kind]: allowed = false
		if allowed: keys.append(key)
	return keys


func _inscribe_legal(cube: RuneCube, key: String) -> void:
	var parts := key.split("/")
	for kind in 4: cube.set_slot(kind, StringName(parts[kind]))


func scenario_combo_resets() -> void:
	print("SCENARIO legal unusual inscriptions and resets during live effects")
	for quarter in 17:
		var level := 1.0 + quarter * 0.25
		var tier := DailyDifficulty.tier_for(level)
		for sample in 4:
			var drawn := DailyGenerator.draw_room(DailyRng.new(9411 + sample), level, tier, DailyKit.words(tier), "")
			await _attack_open(drawn["module"], drawn["params"], tier, level)
			var cubes: Array = lvl.pieces[0]["cubes"].values()
			var cube: RuneCube = cubes[sample % cubes.size()]
			var keys := _legal_cube_keys(cube, DailyKit.words(tier))
			check("%.2f/%d has legal inscriptions without bypassing locked slots" % [level, sample], not keys.is_empty())
			if not keys.is_empty():
				_inscribe_legal(cube, keys[(sample * 7 + quarter) % keys.size()])
				cube.activate(false)
			await frames([2, 20, 75, 150][sample])
			var scored := DailyRun.rooms_cleared
			lvl.reset_current_room()
			# Spam the actual carry input while the fade owns player controls.
			Input.action_press("rune_carry")
			await frames(3)
			Input.action_release("rune_carry")
			await frames(70)
			check("%.2f/%d reset returns every cube, recipe and active effect" % [level, sample], cubes.all(func(c): return not c.is_active and not c.is_carried and c.recipe.to_key() == c.start_recipe and c.global_position.distance_to(c._start_position) < 1))
			check("%.2f/%d reset restores controls and clears carrier" % [level, sample], not lvl.is_resetting and not player.controls_locked and RuneManager.get_for(get_tree()).carrier.held == null)
			await frames(180)
			check("%.2f/%d old spells cannot reopen reset objectives or score" % [level, sample], not lvl.rooms[0].is_cleared() and DailyRun.rooms_cleared == scored and lvl.pieces[0]["gate"].open_amount < 0.1)
			await leave()


func scenario_impact_reset() -> void:
	print("SCENARIO reset while a rune-driven impact is still travelling")
	await _attack_open("burn_through", {"kind": 1, "distance": 2}, 2, 3)
	var cube: RuneCube = lvl.pieces[0]["cubes"].values()[0]
	_inscribe_legal(cube, "wind/burst/right/strong")
	check("impact attack uses the legal gust inscription", cube.recipe.to_key() == "wind/burst/right/strong" and cube.activate(false) == "")
	await frames(1)
	check("reset is requested before the wall breaks", not lvl.pieces[0]["barrier"].is_open and DailyRun.rooms_cleared == 0)
	var time_before := DailyRun.time
	lvl.reset_current_room()
	await frames(90)
	check("an impact during the reset fade cannot bank a completed room", DailyRun.rooms_cleared == 0 and DailyRun.solved_with.is_empty(), str(DailyRun.rooms_cleared))
	check("the reset wall and stones are restored", not lvl.pieces[0]["barrier"].is_open and not lvl.rooms[0].is_cleared())
	check("the reset cannot freeze the challenge timer", DailyRun.time > time_before + 1.0)
	check("the parent objective ledger cannot record the abandoned attempt", not GameState.has_flag("%s.clear.%s" % [lvl.chapter_id, lvl.current_room.room_id.get_slice(".", 1)]))
	check("the reset room can still be solved normally", await _solve_loaded({"cubes": {"Puzzle Cube": "wind/push/right/strong"}}))
	check("a later real solution earns exactly one clear", DailyRun.rooms_cleared == 1)
	await leave()


func scenario_portal_handoff() -> void:
	print("SCENARIO continuous Master portal and shared-cube handoff")
	for width in [2, 3]:
		var params := _grand_fixture("updraft", {"dist": 1, "rows": 3, "width": 3, "lock": 0, "mirror": false})
		params["beats"][0] = {"module": "folded_wall", "params": {"width": width, "lock": 1}}
		await _attack_open("chain", params, 5, 5)
		var first: Dictionary = lvl.pieces[0]["beats"][0]
		var second: Dictionary = lvl.pieces[0]["beats"][1]
		var cube: RuneCube = first["cubes"].values()[0]
		var carrier: RuneCarrier = RuneManager.get_for(get_tree()).carrier
		# Only the initial position is fixture setup. The whole handoff is
		# movement, pickup, portal traversal and floor placement thereafter.
		player.teleport_to(cube.global_position + Vector2(-28, 14))
		await frames(8)
		player.animated_sprite.flip_h = false
		cube.set_slot(3, &"normal")
		check("Master width %d cannot skip discovering the Portal form" % width, cube.activate(false) != "" and not cube.is_active)
		cube.set_slot(1, &"portal")
		check("Master width %d activates its portal" % width, cube.activate(false) == "")
		var portal: RunePortal = cube.effect
		cube.remove_meta(&"daily_portal_carry")
		check("an ordinary active portal cube retains its movement restriction", carrier.try_pick_up() != "" and not cube.is_carried)
		cube.set_meta(&"daily_portal_carry", true)
		var picked := carrier.try_pick_up()
		check("Master width %d can take the shared cube through its own doorway" % width, picked == "", picked)
		if picked != "":
			await leave()
			continue
		await _walk_to(float(second["reuse_position"].x) - RuneCarrier.PLACE_AHEAD, 900, true)
		check("Master width %d carries cube and player across the portal and internal gate" % width, portal.carried.has(player) and first["steps"].all(func(step): return step.done) and player.position.x > first["gate"].position.x and carrier.held == cube)
		await _walk_to(cube._start_position.x - 28, 900, true)
		check("Master width %d carries its owner back without an immediate portal bounce" % width, portal.carried_back.has(player) and player.position.x < portal.entrance.x and carrier.held == cube)
		await _walk_to(float(second["reuse_position"].x) - RuneCarrier.PLACE_AHEAD, 900, true)
		check("Master width %d can repeat the forward handoff after reversing" % width, player.position.x > first["gate"].position.x and carrier.held == cube)
		check("Master width %d places the same cube beside the wind wall" % width, carrier.try_place() == "")
		await frames(5)
		cube.deactivate()
		_inscribe_legal(cube, "wind/lift/up/normal")
		check("Master width %d can reinscribe actual upward wind" % width, cube.recipe.to_key() == "wind/lift/up/normal" and cube.activate(false) == "")
		await _walk_to(second["gate"].position.x - 50, 900)
		check("Master width %d completes with continuous movement and real carrying" % width, lvl.rooms[0].is_cleared())
		player.teleport_to(cube.position + Vector2(-28, -2))
		await frames(4)
		check("the shared portal exception cannot carry an active wind rune", carrier.try_pick_up() != "" and not cube.is_carried)
		lvl.reset_current_room()
		await frames(75)
		check("Master width %d reset restores portal recipe and original slot locks" % width, not cube.is_active and not cube.is_carried and cube.recipe.to_key() == cube.start_recipe and cube.locked_slots == first["original_lock"] and not lvl.rooms[0].is_cleared())
		await leave()


func scenario_placement_resets() -> void:
	print("SCENARIO placements against closed gates, gaps and resets while carrying")
	for quarter in 17:
		var level := 1.0 + quarter * 0.25
		var tier := DailyDifficulty.tier_for(level)
		for sample in 3:
			var drawn := DailyGenerator.draw_room(DailyRng.new(9677 + sample), level, tier, DailyKit.words(tier), "")
			await _attack_open(drawn["module"], drawn["params"], tier, level)
			var cube: RuneCube = lvl.pieces[0]["cubes"].values()[0]
			for candidate in lvl.pieces[0]["cubes"].values():
				if candidate.carryable and not candidate.mounted: cube = candidate; break
			var carrier: RuneCarrier = RuneManager.get_for(get_tree()).carrier
			player.teleport_to(cube.position + Vector2(-28, -2))
			await frames(4)
			player.animated_sprite.flip_h = false
			var refusal := carrier.try_pick_up()
			if not cube.carryable or cube.mounted:
				check("%.2f/%d fixed cubes cannot be moved" % [level, sample], refusal != "" and carrier.held == null)
				await leave()
				continue
			check("%.2f/%d portable cube can be picked up" % [level, sample], refusal == "", refusal)
			if refusal != "": await leave(); continue
			var original := cube.recipe.to_key()
			cube.set_slot(3, &"strong")
			check("%.2f/%d carrying cannot edit or activate a rune" % [level, sample], cube.recipe.to_key() == original and cube.activate(false) != "" and not cube.is_active)
			# Boundary positions are setup for placement-query attacks, not
			# a claimed traversal of the room's unsolved obstacles.
			var gate: PortcullisGate = lvl.pieces[0]["gate"]
			player.teleport_to(Vector2(gate.position.x - 18, RoomKit.FLOOR_Y - 2))
			await frames(3)
			player.animated_sprite.flip_h = false
			check("%.2f/%d cannot place a cube across a closed exit" % [level, sample], carrier.try_place() != "" and carrier.held == cube)
			var part: Dictionary = lvl.pieces[0]
			if part.has("beats"): part = part["beats"][-1]
			if part.has("gap_edges") and not part["gap_edges"].is_empty():
				player.teleport_to(Vector2(float(part["gap_edges"][0]) + 2, RoomKit.FLOOR_Y - 2))
				await frames(2)
				check("%.2f/%d cannot drop the cube onto an unsupported gap" % [level, sample], carrier.try_place() != "" and carrier.held == cube)
			var resets := DailyRun.resets
			lvl.reset_current_room()
			await frames(3)
			lvl.reset_current_room()
			await frames(75)
			check("%.2f/%d reset clears hands and restores the carried cube" % [level, sample], carrier.held == null and not cube.is_carried and not cube.is_active and cube.global_position.distance_to(cube._start_position) < 1 and cube.recipe.to_key() == cube.start_recipe and not player.controls_locked)
			check("%.2f/%d reset spam counts one reset and leaves the exit closed" % [level, sample], DailyRun.resets == resets + 1 and not lvl.rooms[0].is_cleared() and gate.open_amount < 0.1)
			await leave()


func scenario_unlocked_combos() -> void:
	print("SCENARIO every unrelated learned rune after a real first-beat unlock")
	for tier in [4, 5]:
		var keys := DailyKit.sentences(DailyKit.words(tier))
		for key in keys:
			# The intended Lift sentences already have positive continuous
			# route coverage. Here every other valid learned sentence attacks
			# the wind milestone after legitimately unlocking all cube slots.
			if key.begins_with("wind/lift/up/"): continue
			var params := _grand_fixture("updraft", {"dist": 1, "rows": 3, "width": 3, "lock": 0, "mirror": false})
			await _attack_open("chain", params, tier, tier)
			var first: Dictionary = lvl.pieces[0]["beats"][0]
			var second: Dictionary = lvl.pieces[0]["beats"][1]
			var cube: RuneCube = first["cubes"].values()[0]
			_inscribe_legal(cube, "fire/projectile/right/normal")
			cube.activate(false)
			await frames(110)
			check("tier %d %s starts from a real first-beat unlock" % [tier, key], first["steps"].all(func(step): return step.done) and cube.locked_slots == 0)
			await _walk_to(cube.position.x - 28, 150)
			var carrier: RuneCarrier = RuneManager.get_for(get_tree()).carrier
			var picked := carrier.try_pick_up()
			await _walk_to(float(second["reuse_position"].x) - RuneCarrier.PLACE_AHEAD, 650, true)
			var placed := carrier.try_place()
			check("tier %d %s reaches a legal second-beat placement" % [tier, key], picked == "" and placed == "", picked + placed)
			_inscribe_legal(cube, key)
			var casts := DailyRun.casts
			var refusal := cube.activate(false)
			if refusal != "":
				check("tier %d %s blocked activation has no live effect or cast credit" % [tier, key], not cube.is_active and DailyRun.casts == casts, refusal)
			await frames(24)
			await _jump_right(false, 70)
			check("tier %d %s cannot counterfeit the second wind milestone" % [tier, key], not second["steps"][0].done and not lvl.rooms[0].is_cleared() and DailyRun.rooms_cleared == 0)
			check("tier %d %s cannot bypass the unsolved final gate" % [tier, key], player.position.x < second["gate"].position.x)
			lvl.reset_current_room()
			await frames(80)
			check("tier %d %s reset restores the original puzzle and locks" % [tier, key], not cube.is_active and cube.recipe.to_key() == cube.start_recipe and cube.locked_slots == first["original_lock"] and not lvl.rooms[0].is_cleared() and not player.controls_locked)
			await leave()


func scenario_portal_limits() -> void:
	print("SCENARIO carried portal cube clearance and reset cancellation")
	var params := _grand_fixture("updraft", {"dist": 1, "rows": 3, "width": 3, "lock": 0, "mirror": false})
	params["beats"][0] = {"module": "folded_wall", "params": {"width": 2}}
	await _attack_open("chain", params, 5, 5)
	var cube: RuneCube = lvl.pieces[0]["beats"][0]["cubes"].values()[0]
	player.teleport_to(cube.position + Vector2(-28, 14))
	await frames(8)
	player.animated_sprite.flip_h = false
	cube.set_slot(3, &"normal")
	check("clearance fixture opens a valid portal", cube.activate(false) == "")
	var portal: RunePortal = cube.effect
	var portal_ref: WeakRef = weakref(portal)
	var carrier: RuneCarrier = RuneManager.get_for(get_tree()).carrier
	check("clearance fixture picks up the portal owner", carrier.try_pick_up() == "")
	# A late obstacle fits above the player's head but through the carried
	# cube. It represents geometry moving into an already-open exit.
	var obstacle := StaticBody2D.new()
	obstacle.collision_layer = 2
	obstacle.collision_mask = 0
	obstacle.position = Vector2(portal.exit_point.x, RoomKit.FLOOR_Y - 58)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(80, 20)
	shape.shape = box
	obstacle.add_child(shape)
	lvl.add_child(obstacle)
	await frames(3)
	await _walk_to(player.position.x + 150, 120, true)
	check("the portal cannot clip its carried cube through an obstructed exit", not portal.carried.has(player) and player.position.x < 5 * RoomKit.T)
	lvl.reset_current_room()
	await frames(80)
	check("reset while carrying closes the anchored portal and clears the hands", portal_ref.get_ref() == null and carrier.held == null and not cube.is_active and not cube.is_carried and cube.global_position.distance_to(cube._start_position) < 1)
	check("reset leaves the first goal and its original slot locks intact", not lvl.rooms[0].is_cleared() and cube.locked_slots == lvl.pieces[0]["beats"][0]["original_lock"] and DailyRun.rooms_cleared == 0)
	await leave()


## Real movement through a portal while holding another stage's portable
## cube. Starting positions are query fixtures; the receiving obstacle is
## the level's actual mounted portal cube, not an injected blocker.
func scenario_portal_cargo() -> void:
	print("SCENARIO portal clearance applies to every carried cube")
	for width in [2, 3]:
		var reverse := true
		var params := {"reuse": false, "beats": [
			{"module": "folded_wall", "params": {"width": width}},
			{"module": "dark_hall", "params": {"gaps": 1}}]}
		await _attack_open("chain", params, 5, 5)
		var owner: RuneCube = lvl.pieces[0]["beats"][0]["cubes"].values()[0]
		var cargo: RuneCube = lvl.pieces[0]["beats"][1]["cubes"].values()[0]
		owner.set_slot(3, &"normal")
		check("cargo fixture activates portal", owner.activate(false) == "")
		var portal: RunePortal = owner.effect
		var start: Vector2 = portal.exit_point if reverse else portal.entrance
		var sign_x := -1.0 if reverse else 1.0
		cargo.global_position = Vector2(start.x - sign_x * 60, RoomKit.FLOOR_Y)
		player.teleport_to(cargo.position - Vector2(sign_x * 28, 2))
		await frames(6)
		player.animated_sprite.flip_h = reverse
		var carrier: RuneCarrier = RuneManager.get_for(get_tree()).carrier
		check("cargo fixture picks up a different inactive cube", carrier.try_pick_up() == "" and carrier.held == cargo)
		await _walk_to(start.x + sign_x * 30, 90, true)
		check("width %d reverse portal cannot overlap different cargo with the mounted owner" % width, not portal.carried.has(player))
		lvl.reset_current_room()
		await frames(80)
		check("cargo reset restores both stage cubes", carrier.held == null and not owner.is_active and not cargo.is_carried and cargo.position.distance_to(cargo._start_position) < 1)
		await leave()


func scenario_portal_reset_spam() -> void:
	print("SCENARIO shared portal reset spam before and after real warps")
	for width in [2, 3]:
		for modifier in [&"normal", &"long"]:
			for delay in [-1, 0, 1, 18]:
				var params := _grand_fixture("updraft", {"dist": 1, "rows": 3, "width": 3, "lock": 0, "mirror": false})
				params["beats"][0] = {"module": "folded_wall", "params": {"width": width}}
				await _attack_open("chain", params, 5, 5)
				var first: Dictionary = lvl.pieces[0]["beats"][0]
				var cube: RuneCube = first["cubes"].values()[0]
				player.teleport_to(cube.position + Vector2(-28, 14))
				await frames(8)
				player.animated_sprite.flip_h = false
				cube.set_slot(3, modifier)
				check("%d/%s/%d portal opens" % [width, modifier, delay], cube.activate(false) == "")
				var portal: RunePortal = cube.effect
				var portal_ref: WeakRef = weakref(portal)
				var carrier: RuneCarrier = RuneManager.get_for(get_tree()).carrier
				check("portal reset fixture picks up owner", carrier.try_pick_up() == "")
				Input.action_press("move_right")
				Input.action_press("sprint")
				if delay >= 0:
					for tick in 120:
						await frames(1)
						if portal.carried.has(player): break
					check("%d/%s/%d reaches a real warp before reset" % [width, modifier, delay], portal.carried.has(player))
					await frames(delay)
				else:
					await frames(1)
					check("pre-warp reset starts before portal transport", not portal.carried.has(player))
				var count := DailyRun.resets
				for tick in 12:
					lvl.reset_current_room()
					await frames(1)
				Input.action_release("move_right")
				Input.action_release("sprint")
				await frames(100)
				check("portal spam restores one reset, hands, controls and anchored effect", DailyRun.resets == count + 1 and carrier.held == null and portal_ref.get_ref() == null and not lvl.is_resetting and not player.controls_locked, "resets=%d expected=%d resetting=%s locked=%s" % [DailyRun.resets, count + 1, lvl.is_resetting, player.controls_locked])
				check("portal spam cannot retain a stage unlock or finish credit", cube.locked_slots == first["original_lock"] and cube.recipe.to_key() == cube.start_recipe and cube.position.distance_to(cube._start_position) < 1 and not lvl.rooms[0].is_cleared() and DailyRun.rooms_cleared == 0 and first["steps"].all(func(step): return not step.done))
				await leave()


func scenario_stage_reset_spam() -> void:
	print("SCENARIO every quarter difficulty resets during stage transitions")
	for quarter in 17:
		var level := 1.0 + quarter * 0.25
		var tier := DailyDifficulty.tier_for(level)
		var drawn := DailyGenerator.draw_room(DailyRng.new(12977), level, tier, DailyKit.words(tier), "")
		await _attack_open(drawn["module"], drawn["params"], tier, level)
		var part: Dictionary = lvl.pieces[0]
		var module := DailyModules.make(drawn["module"])
		var plan: Dictionary = module.plans(drawn["params"], DailyKit.words(tier))[0]
		if part.has("beats"):
			part = part["beats"][0]
			module = part["module"]
			plan = plan["beats"][0]
		check("%.2f first-stage inscription activates" % level, module.perform(part, plan) == "")
		var drive := module.drive(part)
		if not drive.is_empty():
			player.teleport_to(drive["teleport"])
			await frames(4)
			for action in drive.get("hold", []): Input.action_press(action)
		for tick in 120:
			module.advance(part, player, tick * 0.1)
			await frames(6)
			var done: bool = part["steps"].all(func(step): return step.done) if part.has("steps") else lvl.rooms[0].is_cleared()
			if done or player.is_dead: break
		for action in ["move_left", "move_right", "jump", "sprint"]: Input.action_release(action)
		check("%.2f reaches a genuine first-stage clear" % level, not player.is_dead and (part["steps"].all(func(step): return step.done) if part.has("steps") else lvl.rooms[0].is_cleared()))
		# Boundary setup isolates the reset race; not a claimed manual solve.
		player.teleport_to(Vector2(part["gate"].position.x - 35, RoomKit.FLOOR_Y - 2))
		await frames(3)
		var scored := DailyRun.rooms_cleared
		var count := DailyRun.resets
		Input.action_press("move_right")
		Input.action_press("sprint")
		for tick in 12:
			lvl.reset_current_room()
			await frames(1)
		Input.action_release("move_right")
		Input.action_release("sprint")
		await frames(100)
		check("%.2f transition spam counts one reset and restores controls" % level, DailyRun.resets == count + 1 and not lvl.is_resetting and not player.controls_locked)
		check("%.2f transition reset cannot leak completion or cube state" % level, DailyRun.rooms_cleared == scored and not lvl.rooms[0].is_cleared() and lvl.pieces[0]["gate"].open_amount < 0.1 and lvl.pieces[0]["cubes"].values().all(func(c): return not c.is_active and not c.is_carried and c.recipe.to_key() == c.start_recipe and c.position.distance_to(c._start_position) < 1))
		await leave()


func scenario_gentle_profiles() -> void:
	print("SCENARIO Gentle ridge, terrace and landing without extra difficulty")
	var module := UpdraftModule.new()
	for profile in [0, 1, 2]:
		for rows in [3, 4]:
			for width in [3, 4]:
				var params := {"dist": 1, "rows": rows, "width": width, "mirror": false, "lock": 1, "profile": profile}
				var original := params.duplicate()
				original["profile"] = 0
				var label := "profile %d rows %d width %d" % [profile, rows, width]
				check(label + " retains the original difficulty and rune choices", is_equal_approx(DailyDifficulty.room_score({"module": "updraft", "params": params}, DailyKit.words(1)), DailyDifficulty.room_score({"module": "updraft", "params": original}, DailyKit.words(1))) and module.open_slots(params) == module.open_slots(original) and module.plans(params, DailyKit.words(1)).size() == module.plans(original, DailyKit.words(1)).size())
				await _attack_open("updraft", params, 1, 1.25)
				var cube: RuneCube = lvl.pieces[0]["cubes"].values()[0]
				await _walk_to(cube.position.x - 28, 180)
				await _jump_right(true, 70)
				check(label + " cannot be skipped with a charged jump", not lvl.rooms[0].is_cleared() and DailyRun.casts == 0)
				await _walk_to(cube.position.x - 28, 180)
				cube.set_slot(3, &"normal")
				check(label + " uses the same one-word modifier choice", cube.recipe.to_key() == "wind/lift/up/normal" and cube.activate(false) == "")
				var area: Rect2 = lvl.pieces[0]["area"]
				await _walk_to(area.end.x + 50, 900)
				check(label + " clears through continuous walking and actual wind", lvl.rooms[0].is_cleared() and not player.is_dead)
				lvl.reset_current_room()
				await frames(80)
				check(label + " resets its gate, cube and controls", not lvl.rooms[0].is_cleared() and not cube.is_active and cube.recipe.to_key() == cube.start_recipe and not player.controls_locked and lvl.pieces[0]["gate"].open_amount < 0.1)
				await leave()
	# Each of the three fractional Gentle stages previously had too few
	# configurations for four-room history. Check the actual sequence now.
	for seed in 50:
		var previous := ""
		var recent: Array = []
		var repeats := 0
		var profiles := {}
		for k in 20:
			var spec := DailyGenerator.endless_room(seed, k, 1, previous, recent)
			var room: Dictionary = spec["rooms"][0]
			var key := DailyGenerator.layout_key(room)
			repeats += int(recent.has(key))
			if room["module"] == "updraft": profiles[int(room["params"].get("profile", 0))] = true
			recent.append(key)
			if recent.size() > 4: recent.pop_front()
			previous = DailyGenerator.last_module(room)
		check("Gentle seed %d has no recent configuration repeats" % seed, repeats == 0, str(repeats))
		check("Gentle seed %d includes different ground shapes" % seed, profiles.size() >= 2, str(profiles.keys()))
	await leave()


func scenario_variety() -> void:
	print("SCENARIO difficulty floors, meaningful choices and recent layout variety")
	for level in range(1, 6):
		var low := 0
		var duplicates := 0
		var trivial := 0
		for seed in 50:
			var spec := DailyGenerator.generate(seed, level, DailyDifficulty.tier_for(level))
			var seen := {}
			for room in spec["rooms"]:
				low += int(float(room["r"]) < DailyDifficulty.band(level).x - 0.011)
				var key := DailyGenerator.layout_key(room)
				duplicates += int(seen.has(key))
				seen[key] = true
				if level >= 4:
					var first: Dictionary = room["beats"][0]
					trivial += int(not DailyGenerator.meaningful_choice(DailyModules.make(first["module"]), first["params"]))
				elif level == 3:
					var beats: Array = room.get("beats", [{"module": room["module"], "params": room["params"]}])
					trivial += int(not beats.any(func(beat): return DailyGenerator.meaningful_choice(DailyModules.make(beat["module"]), beat["params"])))
		check("level %d never substitutes a room below its band" % level, low == 0, str(low))
		check("level %d avoids duplicate layouts inside one Daily run" % level, duplicates == 0, str(duplicates))
		if level >= 3: check("level %d requires choosing important rune words" % level, trivial == 0, str(trivial))
	for start in range(1, 5):
		var low := 0
		var adjacent := 0
		for seed in 20:
			var previous := ""
			var recent: Array = []
			for k in 40:
				var spec := DailyGenerator.endless_room(seed, k, start, previous, recent)
				var room: Dictionary = spec["rooms"][0]
				var key := DailyGenerator.layout_key(room)
				low += int(float(room["r"]) < DailyDifficulty.band(spec["level"]).x - 0.011)
				adjacent += int(not recent.is_empty() and recent[-1] == key)
				if k in [0, 5, 20, 39]:
					var replay := DailyGenerator.endless_room(seed, k, start, previous, recent)
					check("start %d seed %d room %d regenerates identically without banking history" % [start, seed, k], replay["digest"] == spec["digest"])
				recent.append(key)
				if recent.size() > 4: recent.pop_front()
				previous = DailyGenerator.last_module(room)
		check("Endless start %d keeps every room above its difficulty floor" % start, low == 0, str(low))
		check("Endless start %d never immediately repeats a layout" % start, adjacent == 0, str(adjacent))
	await leave()


func _scale_measure(room: Dictionary, words: PackedStringArray) -> Dictionary:
	var parts := DailyDifficulty.parts(DailyModules.make(room["module"]), room["params"], words)
	var ids: Array = []
	var guided := bool(room["params"].get("guided", true))
	if room.has("beats"):
		for beat in room["beats"]:
			ids.append(beat["module"])
			guided = guided and bool(beat["params"].get("guided", true))
	else: ids.append(room["module"])
	return {"r": DailyDifficulty.total(parts), "parts": parts, "ids": ids,
		"chain": room.has("beats"), "reuse": room.get("reuse", false),
		"personal_fire": room.get("personal_fire", false), "guided": guided}


func _scale_summary(rows: Array, band: Vector2) -> Dictionary:
	var scores: Array = []
	var parts := {"search": 0.0, "steps": 0.0, "concept": 0.0, "execution": 0.0, "decoys": 0.0}
	var ids := {}
	var counts := {"inside": 0, "chain": 0, "reuse": 0, "personal_fire": 0, "guided": 0}
	var sum := 0.0
	var min_plans := 1000000
	for row in rows:
		var r: float = row["r"]
		scores.append(r)
		sum += r
		counts["inside"] += int(DailyDifficulty.miss(r, band) < 0.001)
		for key in ["chain", "reuse", "personal_fire", "guided"]: counts[key] += int(row[key])
		for key in parts: parts[key] += float(row["parts"][key])
		min_plans = mini(min_plans, int(row["parts"]["plans"]))
		for id in row["ids"]: ids[id] = int(ids.get(id, 0)) + 1
	var n := float(rows.size())
	scores.sort()
	for key in parts: parts[key] /= n
	var out := {"rooms": rows.size(), "band": [band.x, band.y], "mean_r": sum / n,
		"min_r": scores[0], "max_r": scores[-1], "median_r": scores[int(n * 0.5)],
		"p10_r": scores[int(n * 0.1)], "p90_r": scores[int(n * 0.9)],
		"mean_parts": parts, "mechanisms": ids, "minimum_plans": min_plans}
	for key in counts: out[key + "_percent"] = 100.0 * float(counts[key]) / n
	return out


## Audit both the named choices and EVERY Endless quarter step. This is a
## structural model audit; solver speed is not a human difficulty measure.
func scenario_scale_audit() -> void:
	print("SCENARIO full puzzle difficulty scale audit")
	await leave()
	var report := {"generator_version": DailyGenerator.GEN_VERSION, "seeds_per_named_level": 500,
		"seeds_per_quarter_level": 250, "named": [], "quarters": [],
		"scope": "Generated structural difficulty, engine solutions and menu wiring; not measured human solve times."}
	var representatives := {}
	var all_valid := true
	var scores_match := true
	for level in range(1, 6):
		var rows: Array = []
		var tier := DailyDifficulty.tier_for(level)
		var low := INF
		var high := -INF
		for seed in 500:
			var value := DailyRng.fnv("scale-audit-%d" % seed)
			var spec := DailyGenerator.endless_room(value, 20, 4) if level == 5 else DailyGenerator.generate(value, level, tier)
			all_valid = all_valid and DailyOracle.validate(spec)["ok"]
			for room in spec["rooms"]:
				var row := _scale_measure(room, spec["kit"])
				rows.append(row)
				var r: float = row["r"]
				scores_match = scores_match and absf(r - float(room["r"])) <= 0.011
				if r < low: low = r; representatives["%d low" % level] = room
				if r > high: high = r; representatives["%d high" % level] = room
		var summary := _scale_summary(rows, DailyDifficulty.band(level))
		summary["name"] = DailyDifficulty.name_of(level)
		summary["tier"] = tier
		report["named"].append(summary)
		print("  SCALE %s mean=%.3f p10=%.3f median=%.3f p90=%.3f in-band=%.1f%% chain=%.1f%% reuse=%.1f%%" %
			[summary["name"], summary["mean_r"], summary["p10_r"], summary["median_r"], summary["p90_r"], summary["inside_percent"], summary["chain_percent"], summary["reuse_percent"]])
		check(summary["name"] + " meets its band in at least 90% of sampled rooms", summary["inside_percent"] >= 90)
		check(summary["name"] + " has at least two verified plans in every room", summary["minimum_plans"] >= 2)
		check(summary["name"] + " follows its chalk-guidance rule", summary["guided_percent"] == (100 if level < 4 else 0))
		if level >= 4:
			check(summary["name"] + " consistently uses two beats, reinscription and sealed personal Fire", summary["chain_percent"] == 100 and summary["reuse_percent"] == 100 and summary["personal_fire_percent"] == 0)
	check("all named specs pass the oracle", all_valid)
	check("stored difficulty matches recomputed difficulty", scores_match)
	for i in range(1, 5):
		check("%s has higher mean and median difficulty than %s" % [report["named"][i]["name"], report["named"][i - 1]["name"]],
			report["named"][i]["mean_r"] > report["named"][i - 1]["mean_r"] and report["named"][i]["median_r"] > report["named"][i - 1]["median_r"])
	var previous_mean := -INF
	for quarter in 17:
		var level := 1.0 + float(quarter) * 0.25
		var tier := DailyDifficulty.tier_for(level)
		var words := DailyKit.words(tier)
		var rows: Array = []
		var low := INF
		var high := -INF
		for seed in 250:
			var room := DailyGenerator.draw_room(DailyRng.new(DailyRng.fnv("quarter-audit-%d" % seed)), level, tier, words, "")
			DailyGenerator.set_spell_rule(room, level)
			var row := _scale_measure(room, words)
			rows.append(row)
			var r: float = row["r"]
			if quarter % 4 != 0:
				if r < low: low = r; representatives["%.2f quarter low" % level] = room
				if r > high: high = r; representatives["%.2f quarter high" % level] = room
		var summary := _scale_summary(rows, DailyDifficulty.band(level))
		summary["level"] = level
		summary["name"] = DailyDifficulty.name_of(level)
		report["quarters"].append(summary)
		print("  QUARTER %.2f mean=%.3f in-band=%.1f%%" % [level, summary["mean_r"], summary["inside_percent"]])
		check("%.2f quarter-step rooms meet the band" % level, summary["inside_percent"] >= 90)
		check("%.2f quarter-step mean does not regress" % level, float(summary["mean_r"]) + 0.02 >= previous_mean)
		if quarter > 0:
			check("%.2f quarter-step mean increases measurably" % level, float(summary["mean_r"]) > previous_mean + 0.05)
		previous_mean = summary["mean_r"]
	check("the physics verification table is fresh", DailyVerified.fresh())
	# Real sequential runs include the previous-module exclusion, which a
	# direct draw cannot exercise. Audit each five-room ramp window too.
	report["sequential_endless"] = []
	for start in range(1, 5):
		var windows: Array = [[], [], [], [], []]
		for seed in 150:
			var previous := ""
			var recent: Array = []
			var value := DailyRng.fnv("sequence-audit-%d" % seed)
			for k in 25:
				var spec := DailyGenerator.endless_room(value, k, start, previous, recent)
				var room: Dictionary = spec["rooms"][0]
				windows[int(k / 5.0)].append(_scale_measure(room, spec["kit"]))
				previous = DailyGenerator.last_module(room)
				recent.append(DailyGenerator.layout_key(room))
				if recent.size() > 4: recent.pop_front()
		var earlier := -INF
		for window in 5:
			var level := DailyDifficulty.ramp(start, window * 5)
			var summary := _scale_summary(windows[window], DailyDifficulty.band(level))
			summary["start"] = start
			summary["level"] = level
			report["sequential_endless"].append(summary)
			print("  SEQUENCE start=%d level=%.2f mean=%.3f in-band=%.1f%%" % [start, level, summary["mean_r"], summary["inside_percent"]])
			check("Endless start %d at %.2f meets its band with previous-room constraints" % [start, level], summary["inside_percent"] >= 90)
			if window > 0:
				check("Endless start %d at %.2f gets harder in actual sequences" % [start, level], float(summary["mean_r"]) > earlier + 0.02)
			earlier = summary["mean_r"]
	# Buttons must dispatch the chosen difficulty, not a captured loop value.
	for start in range(1, 5):
		await open("res://scenes/ui/title_screen.tscn")
		var menu := DailyMenu.open(lvl)
		await frames(5)
		check("menu button %d carries its correct label" % start, menu.endless_buttons[start - 1].text == DailyDifficulty.name_of(start))
		menu.endless_buttons[start - 1].pressed.emit()
		await seconds(1.5)
		lvl = get_tree().current_scene
		player = lvl.get_node_or_null("Player")
		check("menu choice %d starts the selected difficulty, vocabulary and HUD" % start,
			lvl is DailyRoot and DailyRun.endless_start == start and lvl.spec["level"] == start and lvl.spec["tier"] == DailyDifficulty.tier_for(start) and lvl.endless_label.text.contains(DailyDifficulty.name_of(start)))
		await leave()
	# Real-physics acceptance at the low and high ends of every named scale.
	for label in representatives:
		var level := float(String(label).split(" ")[0])
		var room: Dictionary = representatives[label]
		var module := DailyModules.make(room["module"])
		var tier := DailyDifficulty.tier_for(level)
		var plans := module.plans(room["params"], DailyKit.words(tier))
		for plan in [plans[0], plans[-1]]:
			check("scale %s extreme has a real-physics solution: %s" % [label, plan["label"]], await try_plan(room["module"], room["params"], plan, 24 if room.has("beats") else 10, tier))
	await leave()
	report["passed"] = passed
	report["failed"] = failed
	var file := FileAccess.open("res://.godot/difficulty-scale-audit.json", FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(report, "\t")); file.close()


func _attack_open(id: String, params: Dictionary, tier: int, level: float) -> void:
	DailyRun.start("trial", 72727, 0, int(floor(level)), tier)
	DailyRun.spec_override = spec_for(params, tier, id)
	DailyGenerator.set_spell_rule(DailyRun.spec_override["rooms"][0], level)
	await open(DailyRun.SCENE)
	player.controls_locked = false


func scenario_all_cheese() -> void:
	print("SCENARIO all difficulties adversarial movement, resets and portals")
	# Lower-level standalone crossings must enforce the same prerequisites
	# as Grand chains, including advanced templates used by supplied specs.
	for id in ["dark_hall", "frozen_crossing", "still_piston"]:
		var module := DailyModules.make(id)
		var params := module.fallback(module.min_tier)
		await _attack_open(id, params, module.min_tier, 3)
		var part: Dictionary = lvl.pieces[0]
		var start := RoomKit.cx(2)
		if id == "dark_hall": start = float(part["gap_edges"][0]) - 38
		if id == "frozen_crossing": start = 5 * RoomKit.T - 38
		if id == "still_piston": start = float(part["cubes"].values()[0].position.x) + 20
		player.teleport_to(Vector2(start, RoomKit.FLOOR_Y - 2))
		await frames(8)
		await _jump_right(true, 120)
		check(id + " cannot open its exit solely by touching the far-side objective", part["gate"].open_amount < 0.1 and not lvl.rooms[0].is_cleared(), str(player.position))
		await leave()
	# Updraft used to rely on an open back gate rather than a goal exit.
	await _attack_open("updraft", UpdraftModule.new().fallback(1), 1, 1)
	check("a standalone wind room keeps its exit closed until solved", lvl._gates_into(1).all(func(gate): return gate.open_amount < 0.1))
	await leave()
	# Use the real carrier to put a Master portal cube on ordinary ground.
	var params := _grand_fixture("updraft", {"dist": 1, "rows": 3, "width": 3, "lock": 0, "mirror": false})
	params["beats"][0] = {"module": "folded_wall", "params": {"width": 2}}
	await _attack_open("chain", params, 5, 5)
	var cube: RuneCube = lvl.pieces[0]["beats"][0]["cubes"].values()[0]
	player.teleport_to(cube.position + Vector2(-28, 0))
	await frames(8)
	player.animated_sprite.flip_h = false
	var carrier: RuneCarrier = RuneManager.get_for(get_tree()).carrier
	check("Master portal cube can be picked up", carrier.try_pick_up() == "")
	check("Master portal cube can be legally set on the floor", carrier.try_place() == "")
	await frames(4)
	cube.set_slot(3, &"normal")
	var refusal := cube.activate(false)
	check("a carried portal cube works after a legal floor placement", refusal == "", refusal)
	await _jump_right(false, 100)
	check("Master can physically enter the floor portal and reach the next beat", lvl.pieces[0]["beats"][0]["steps"].all(func(step): return step.done), str(player.position))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/master-floor-portal.png")
	await leave()
	DailyRun.start_endless(4, 8181)
	DailyRun.spec_override = spec_for({"gaps": 1}, 4, "dark_hall")
	DailyRun.spec_override["endless"] = true
	DailyRun.spec_override["bell"] = {}
	var end: int = DailyRun.spec_override["rooms"][0]["x1"]
	DailyRun.spec_override["exit"] = {"x0": end, "x1": end + DailyGenerator.EXIT_COLUMNS - 1}
	await open(DailyRun.SCENE)
	player.controls_locked = false
	player.teleport_to(Vector2(5 * RoomKit.T - 20, RoomKit.FLOOR_Y - 2))
	await frames(8)
	await _walk_to(player.position.x + 200, 180, true)
	check("falling into an Endless pit ends the fall and consumes exactly one life", player.is_dead and DailyRun.lives == 2 and DailyRun.deaths == 1, str(player.position))
	await leave()
	# Each available quarter level, three independent room draws. No test
	# driver advances or teleports between beats during these attacks.
	for quarter in 17:
		var level := 1.0 + quarter * 0.25
		var tier := DailyDifficulty.tier_for(level)
		for seed in 3:
			var room := DailyGenerator.draw_room(DailyRng.new(8100 + seed), level, tier, DailyKit.words(tier), "")
			await _attack_open(room["module"], room["params"], tier, level)
			for attempt in 2:
				await _walk_to(player.position.x + 150, 100, true)
				await _jump_right(attempt == 1, 85)
				if player.is_dead: break
			check("%.2f room %d cannot clear by walking, sprinting and jump spam alone" % [level, seed], not lvl.rooms[0].is_cleared() and DailyRun.casts == 0)
			check("%.2f room %d keeps the player before the exit" % [level, seed], player.position.x < RoomKit.cx(lvl.spec["rooms"][0]["x1"]))
			if not player.is_dead:
				lvl.reset_current_room()
				await frames(70)
				check("%.2f room %d reset restores unsolved objectives and player controls" % [level, seed], not lvl.rooms[0].is_cleared() and not player.controls_locked and not lvl.is_resetting)
			await leave()


func _solve_loaded(plan: Dictionary) -> bool:
	var module := DailyModules.make(lvl.spec["rooms"][0]["module"])
	if module.perform(lvl.pieces[0], plan) != "": return false
	var drive := module.drive(lvl.pieces[0])
	if not drive.is_empty():
		player.teleport_to(drive["teleport"])
		await frames(4)
		for action in drive.get("hold", []): Input.action_press(action)
	for tick in 120:
		module.advance(lvl.pieces[0], player, tick * 0.1)
		await frames(6)
		if lvl.rooms[0].is_cleared() or player.is_dead: break
	for action in drive.get("hold", []): Input.action_release(action)
	Input.action_release("jump")
	Input.action_release("sprint")
	await frames(60)
	return lvl.rooms[0].is_cleared()


func scenario_reset_solutions() -> void:
	print("SCENARIO solved rooms reset and re-solve without duplicate scoring")
	for level in [1.0, 2.0, 3.0, 4.0, 5.0]:
		var tier := DailyDifficulty.tier_for(level)
		var drawn := DailyGenerator.draw_room(DailyRng.new(9234), level, tier, DailyKit.words(tier), "")
		# Include the previously ungated standalone wind mechanism.
		if level == 1: drawn = {"module": "updraft", "params": UpdraftModule.new().fallback(tier)}
		await _attack_open(drawn["module"], drawn["params"], tier, level)
		var module := DailyModules.make(drawn["module"])
		var plans := module.plans(drawn["params"], DailyKit.words(tier))
		check("%.0f initial valid solution clears" % level, await _solve_loaded(plans[0]))
		check("%.0f solved exit opens" % level, lvl.pieces[0]["gate"].open_amount > 0.9)
		lvl.reset_current_room()
		await frames(70)
		check("%.0f reset closes exit and restores controls" % level, not lvl.rooms[0].is_cleared() and lvl.pieces[0]["gate"].open_amount < 0.1 and not player.controls_locked)
		check("%.0f a different valid inscription re-solves" % level, await _solve_loaded(plans[1]))
		check("%.0f exit reopens without scoring twice" % level, lvl.pieces[0]["gate"].open_amount > 0.9 and DailyRun.rooms_cleared == 1)
		await leave()


func scenario_challenge_rules() -> void:
	print("SCENARIO rune requirements and optional personal magic")
	await leave()
	var story_flags := GameState.flags.duplicate(true)
	var story_abilities := GameState.all_abilities
	var pad_before := InputLabels.use_pad
	var params := {"kind": 0, "distance": 2}
	for optional in [false, true]:
		DailyRun.start("trial", 4242, 0, 3, 2)
		DailyRun.spec_override = spec_for(params, 2, "burn_through")
		DailyRun.spec_override["rooms"][0]["personal_fire"] = optional
		await open(DailyRun.SCENE)
		var part: Dictionary = lvl.pieces[0]
		var barrier: Burnable = part["barrier"]
		player.controls_locked = false
		player.teleport_to(barrier.global_position + Vector2(-90, -2))
		await frames(6)
		InputLabels.use_pad = true
		player.animated_sprite.flip_h = false
		var mana_before: float = player.current_mana
		player.shoot_fireball()
		await seconds(1.0)
		check("personal Fire follows the room rule (%s)" % optional, GameState.has_ability("fire") == optional)
		check("brambles resist a denied spell, but accept an explicitly allowed Fire route (%s)" % optional,
			barrier.is_cleared == optional and (player.current_mana < mana_before if optional else player.current_mana == mana_before))
		check("the optional Fire route needs no cube cast (%s)" % optional, DailyRun.casts == 0)
		check("Heal is available and Echo cannot substitute for rune machinery", GameState.has_ability("heal") and not GameState.has_ability("echo"))
		await shot("spell_rule_%s" % optional)
		lvl._on_room_entered(lvl.rooms[-1])
		check("leaving an optional room seals personal Fire again", not GameState.has_ability("fire"))
		await leave()
		check("room spell rules leave story progress intact", GameState.flags == story_flags and GameState.all_abilities == story_abilities)
	InputLabels.use_pad = pad_before
	var module := BurnThroughModule.new()
	for plan in module.plans(params, DailyKit.words(2)).slice(0, 2):
		check("a required bramble room still has a working rune solution: " + plan["label"], await try_plan("burn_through", params, plan, 6, 2))
	await leave()
	var strict := true
	var optional_count := 0
	var second_mechanisms := {}
	var grand_tier := DailyDifficulty.tier_for(4)
	for seed in 100:
		var grand := DailyGenerator.generate(seed, 4, grand_tier)
		for room in grand["rooms"]:
			strict = strict and room.has("beats") and room.get("reuse", false) and not room.get("personal_fire", true)
			var second_id := String(room["beats"][1]["module"])
			strict = strict and second_id in ["updraft", "dark_hall", "prism_relay"]
			second_mechanisms[second_id] = true
		for room in DailyGenerator.generate(seed, 3, 2)["rooms"]:
			optional_count += int(room.get("personal_fire", false))
	check("Grand always requires reused-cube magic and a non-bypassable mechanism", strict)
	check("Grand varies vertical wind, hidden stones and reflected light", second_mechanisms.size() == 3)
	check("Hard still includes intentional personal Fire alternatives", optional_count > 0, str(optional_count))
	# Reproduce today's complete Grand, proving two working solutions per room.
	var today := DailyRng.day_index(2026, 10, 11)
	var today_spec := DailyGenerator.generate(DailyGenerator.seed_for_day(today), 4, grand_tier)
	check("the reported date is Grand and its new spec is oracle-valid", DailyGenerator.difficulty_for_day(today) == 4 and DailyOracle.validate(today_spec)["ok"])
	DailyRun.start_day(today)
	await open(DailyRun.SCENE)
	await seconds(0.6)
	check("Grand rule screen renders to an inspection image", get_viewport().get_texture().get_image().save_png(
		ProjectSettings.globalize_path("res://.godot/challenge-grand.png")) == OK)
	await leave()
	for i in today_spec["rooms"].size():
		var room: Dictionary = today_spec["rooms"][i]
		for plan in DailyChain.new().plans(room["params"], today_spec["kit"]).slice(0, 2):
			check("today's Grand room %d clears with %s" % [i + 1, plan["label"]], await try_plan("chain", room["params"], plan, 22, grand_tier))
	await leave()

## Exercise onboarding with tours enabled: the normal runner disables them.
func scenario_cube_help() -> void:
	print("SCENARIO challenge cube help stays optional")
	await leave()
	var original_flags := GameState.flags.duplicate(true)
	var tours_enabled := UiTour.enabled
	UiTour.enabled = true
	GameState.flags.erase("ui.tour.runes")
	for mode in ["daily", "practice", "endless"]:
		if mode == "endless":
			DailyRun.start_endless(1, 12345)
		else:
			DailyRun.start(mode, 12345, 300, 1, 1)
		await open(DailyRun.SCENE)
		for attempt in 2:
			var cube := get_tree().get_first_node_in_group("rune_cube") as RuneCube
			player.teleport_to(cube.global_position + Vector2(-140, -2))
			await frames(10)
			player.teleport_to(cube.global_position + Vector2(-30, -2))
			await seconds(1.5)
			check("%s cube approach %d does not open or pause a tutorial" % [mode, attempt + 1],
				not is_instance_valid(UiTour.current) and not get_tree().paused)
			if is_instance_valid(UiTour.current):
				UiTour.current.close()
				await frames(3)
		# Reload the generated scene as a death/restart does.
		await open(DailyRun.SCENE)
		var reloaded_cube := get_tree().get_first_node_in_group("rune_cube") as RuneCube
		reloaded_cube._on_reached(player)
		await seconds(1.5)
		check("%s reload does not bring automatic cube help back" % mode,
			not is_instance_valid(UiTour.current) and not get_tree().paused)
		if is_instance_valid(UiTour.current):
			UiTour.current.close()
			await frames(3)
		var help := UiTour.play(lvl, "runes", true)
		check("%s explicit rune help still opens" % mode, is_instance_valid(help) and get_tree().paused)
		if is_instance_valid(help):
			help.close()
			await frames(3)
		await leave()
		check("%s leaves story rune onboarding unseen" % mode, not GameState.has_flag("ui.tour.runes"))
	GameState.flags["ui.tour.runes"] = true
	DailyRun.start("daily", 12345, 300, 1, 1)
	await open(DailyRun.SCENE)
	await leave()
	check("an existing story rune tutorial flag is preserved", GameState.has_flag("ui.tour.runes"))
	GameState.flags = original_flags
	UiTour.enabled = tours_enabled

func scenario_rng() -> void:
	print("SCENARIO the daily random numbers")
	var a := DailyRng.new(12345)
	var b := DailyRng.new(12345)
	var same := true
	for i in 50:
		same = same and a.next_u32() == b.next_u32()
	check("the same seed gives the same numbers", same)
	var c := DailyRng.new(12346)
	var first_a := DailyRng.new(12345).next_u32()
	check("a different seed gives different numbers", first_a != c.next_u32())
	# Golden values: if these change, every daily puzzle ever shared changes
	check("FNV-1a of the empty string is the offset basis", DailyRng.fnv("") == 0x811C9DC5)
	check("FNV-1a of 'a' matches the reference value", DailyRng.fnv("a") == 0xE40C292C, str(DailyRng.fnv("a")))
	var golden := DailyRng.new(1)
	var g := [golden.next_u32(), golden.next_u32(), golden.next_u32()]
	print("  golden xorshift values for seed 1: ", g)
	check("numbers stay in 32 bits", g.all(func(v): return v >= 0 and v <= 0xFFFFFFFF))
	var ranged := DailyRng.new(9)
	var in_range := true
	var seen := {}
	for i in 400:
		var v := ranged.int_range(3, 7)
		in_range = in_range and v >= 3 and v <= 7
		seen[v] = true
	check("int_range stays inside its bounds and reaches both ends", in_range and seen.has(3) and seen.has(7))
	var items := [1, 2, 3, 4, 5, 6]
	var s1 := DailyRng.new(5).shuffled(items)
	var s2 := DailyRng.new(5).shuffled(items)
	var sorted := s1.duplicate()
	sorted.sort()
	check("a shuffle is deterministic and keeps every item", s1 == s2 and sorted == items)
	var base := DailyRng.new(77)
	var f1 := base.fork("rooms").next_u32()
	var f2 := base.fork("decor").next_u32()
	check("forks with different labels are independent", f1 != f2)
	check("forking does not move the parent", DailyRng.new(77).next_u32() == base.next_u32())


func scenario_calendar() -> void:
	print("SCENARIO the daily calendar")
	check("day 0 is 2026-01-01", DailyRng.day_index(2026, 1, 1) == 0)
	check("2026-10-10 is day 282", DailyRng.day_index(2026, 10, 10) == 282, str(DailyRng.day_index(2026, 10, 10)))
	check("2026-01-01 was a Thursday", DailyRng.weekday(0) == 4)
	check("2026-10-10 is a Saturday", DailyRng.weekday(282) == 6)
	var round_trip := true
	for i in range(-400, 3000):
		var d := DailyRng.date_of(i)
		round_trip = round_trip and DailyRng.day_index(d["year"], d["month"], d["day"]) == i
	check("every date from 2025 to 2034 round-trips", round_trip)
	var leap := DailyRng.day_index(2028, 2, 29)
	check("2028-02-29 exists and is followed by March 1", DailyRng.day_index(2028, 3, 1) == leap + 1)
	check("2100 is not a leap year", DailyRng.day_index(2100, 3, 1) == DailyRng.day_index(2100, 2, 28) + 1)
	check("labels read 2026-10-10", DailyRng.label_of(282) == "2026-10-10")


func scenario_kit() -> void:
	print("SCENARIO the vocabulary kits")
	var counts := []
	for tier in range(1, DailyKit.MAX_TIER + 1):
		counts.append(DailyKit.sentences(DailyKit.words(tier)).size())
	print("  sentences by tier: ", counts)
	check("tier 1 can make 6 sentences (the Observatory's)", counts[0] == 6, str(counts))
	check("tier 5 can make all 197", counts[4] == 197, str(counts))
	var growing := true
	for i in range(1, counts.size()):
		growing = growing and counts[i] > counts[i - 1]
	check("each tier knows more than the last", growing)
	var every_valid := true
	for key in DailyKit.sentences(DailyKit.words(5)):
		every_valid = every_valid and RuneBook.is_valid(RuneRecipe.from_key(key))
	check("every sentence the kit lists is valid", every_valid)
	check("tier 1 does not know fire", not DailyKit.words(1).has("fire"))
	check("tier 2 knows fire", DailyKit.words(2).has("fire"))


func scenario_generator() -> void:
	print("SCENARIO the generator and the oracle")
	var a := DailyGenerator.generate(DailyGenerator.seed_for_day(300), 1, 1)
	var b := DailyGenerator.generate(DailyGenerator.seed_for_day(300), 1, 1)
	check("the same day gives the same puzzle", a["digest"] == b["digest"] and JSON.stringify(a["rooms"]) == JSON.stringify(b["rooms"]))
	var c := DailyGenerator.generate(DailyGenerator.seed_for_day(301), 1, 1)
	check("another day gives another puzzle", a["digest"] != c["digest"])
	print("  digests: day 300 = %d, day 301 = %d" % [a["digest"], c["digest"]])
	check("the version is mixed into the seed", DailyGenerator.seed_for_day(5) != DailyRng.fnv("belfry-daily|v0|5"))
	var all_ok := true
	var contiguous := true
	var wide_enough := true
	var distinct := {}
	for day in 400:
		for difficulty in range(1, 5):
			var spec := DailyGenerator.generate(DailyGenerator.seed_for_day(day), difficulty, DailyGenerator.tier_for_difficulty(difficulty))
			var verdict := DailyOracle.validate(spec)
			all_ok = all_ok and verdict["ok"]
			var rooms: Array = spec["rooms"]
			for i in rooms.size():
				wide_enough = wide_enough and rooms[i]["x1"] - rooms[i]["x0"] >= 12
				if i > 0:
					contiguous = contiguous and rooms[i]["x0"] == rooms[i - 1]["x1"]
			contiguous = contiguous and spec["bell"]["x0"] == rooms[rooms.size() - 1]["x1"]
			distinct[spec["digest"]] = true
	check("1,600 generated puzzles all pass the oracle", all_ok)
	check("rooms are wide enough and share their wall column", contiguous and wide_enough)
	check("different days and difficulties make different puzzles", distinct.size() > 1500, str(distinct.size()))
	var spec := DailyGenerator.generate(7, 4, 1)
	check("a hard day has 5 rooms and a bell hall", spec["rooms"].size() == 5 and spec["bell"]["x1"] > spec["bell"]["x0"])
	check("every room offers at least two ways to solve it", DailyOracle.ways(spec).all(func(n): return n >= 2), str(DailyOracle.ways(spec)))
	var bad := a.duplicate(true)
	bad["rooms"][0]["module"] = "no_such_module"
	check("the oracle refuses an unknown module", not DailyOracle.validate(bad)["ok"])
	var thin := a.duplicate(true)
	thin["kit"] = PackedStringArray(["wind", "push", "left", "right"])
	check("the oracle refuses a room with fewer than two ways", not DailyOracle.validate(thin)["ok"])
	var weekdays := {}
	for d in 14:
		weekdays[DailyGenerator.difficulty_for_day(d)] = true
	check("every weekday has a difficulty from 1 to 4", weekdays.size() == 4)


# ------------------------------------------------------------------ fairness

func scenario_fairness() -> void:
	print("SCENARIO everyone gets the same words")
	var state := get_tree().root.get_node("GameState")
	state.set_flag("rune.frag.fire")
	state.set_flag("rune.frag.portal")
	check("the story's words are known without a kit", RuneManager.knows(&"fire") and RuneManager.knows(&"portal"))
	RuneManager.kit_override = DailyKit.words(1)
	check("with a kit, a story word outside it is unknown", not RuneManager.knows(&"fire") and not RuneManager.knows(&"portal"))
	check("with a kit, its words are known", RuneManager.knows(&"right") and RuneManager.knows(&"strong"))
	check("with a kit, a word never learned in the story is still known if lent", RuneManager.knows(&"lift"))
	RuneManager.kit_override = PackedStringArray()
	state.set_flag("rune.frag.fire", false)
	state.set_flag("rune.frag.portal", false)
	check("clearing the kit restores the story's rules", not RuneManager.knows(&"fire"))


# ------------------------------------------------------------------ the level

func spec_for(params: Dictionary, tier := 1, module_id := "gust_alley") -> Dictionary:
	var module := DailyModules.make(module_id)
	var cols := module.columns(params)
	var spec := {
		"seed": 4242, "difficulty": 1, "tier": tier, "version": DailyGenerator.GEN_VERSION,
		"kit": DailyKit.words(tier),
		"rooms": [{"module": module_id, "params": params, "x0": 0, "x1": cols - 1}],
		"bell": {"x0": cols - 1, "x1": cols - 1 + DailyGenerator.BELL_COLUMNS - 1},
	}
	spec["digest"] = DailyGenerator.digest_of(spec)
	return spec


func scenario_level() -> void:
	print("SCENARIO the generated level")
	var state := get_tree().root.get_node("GameState")
	var abilities_before: bool = state.all_abilities
	var calm_before: bool = state.calm_creatures
	var persist_before: bool = state.persist_to_disk
	state.set_flag("rune.frag.fire")
	# a Monday or Tuesday (difficulty 1: the smallest vocabulary)
	var easy_day := 0
	while DailyGenerator.difficulty_for_day(easy_day) != 1:
		easy_day += 1
	DailyRun.start_day(easy_day)
	await open(DailyRun.SCENE)
	check("the daily level opens as a chapter root", lvl is DailyRoot and lvl.is_in_group("chapter_root"))
	var spec: Dictionary = lvl.spec
	check("it built one room per module plus the bell hall", lvl.rooms.size() == spec["rooms"].size() + 1, str(lvl.rooms.size()))
	check("the player stands in the first room", lvl.current_room != null and lvl.current_room.room_id == "daily.r1")
	check("rune rooms lend Heal but seal personal Fire and Echo", not state.has_ability("fire") and state.has_ability("heal") and not state.has_ability("echo"))
	check("the story's save is not written during the run", not state.persist_to_disk)
	check("the lent vocabulary replaces the story's", RuneManager.knows(&"right") and not RuneManager.knows(&"fire"))
	var cubes := get_tree().get_nodes_in_group("rune_cube")
	check("every room has a rune cube", cubes.size() >= spec["rooms"].size(), str(cubes.size()))
	var pieces: Array = lvl.pieces
	check("the modules reported their pieces", pieces.size() == spec["rooms"].size() and pieces.all(func(p): return p.has("cubes") and not p["cubes"].is_empty()))
	check("the bell is in the last room", lvl.bell != null and lvl.current_room != null)
	# Dying reloads the scene: the same puzzle and the same starting room
	var digest: int = spec["digest"]
	DailyRun.respawn_room = 1
	await leave()
	await open(DailyRun.SCENE)
	check("a reload builds the same puzzle", lvl.spec["digest"] == digest)
	check("a reload starts in the furthest room reached", lvl.current_room != null and lvl.current_room.room_id == "daily.r2", str(lvl.current_room.room_id if lvl.current_room else "none"))
	check("no checkpoint was written for the title's Continue", state.checkpoint_scene == "" or state.checkpoint_scene != DailyRun.SCENE)
	# Leaving puts the story's conditions back
	await leave()
	if is_instance_valid(get_tree().current_scene):
		get_tree().current_scene.queue_free()
	await frames(4)
	check("leaving restores the abilities, creatures and save rules",
		state.all_abilities == abilities_before and state.calm_creatures == calm_before and state.persist_to_disk == persist_before)
	check("leaving restores the story's vocabulary", RuneManager.knows(&"fire") and RuneManager.kit_override.is_empty())
	state.set_flag("rune.frag.fire", false)


# ------------------------------------------------------------------ the physics

## Loads one Gust Alley with `params`, puts `key` on its cube and returns
## whether the gate opens within `wait` seconds.
## Loads one room of `module_id` with `params`, has a player carry out `plan`
## and returns whether the room clears (its steps all done) within `wait`
## seconds.
func try_plan(module_id: String, params: Dictionary, plan: Dictionary, wait := 7.0, tier := 1) -> bool:
	DailyRun.start("trial", 4242, 0, 1, tier)
	DailyRun.spec_override = spec_for(params, tier, module_id)
	await open(DailyRun.SCENE)
	var module := DailyModules.make(module_id)
	var err := module.perform(lvl.pieces[0], plan)
	if err != "":
		print("    (refused: %s)" % err)
		if module_id != "updraft":
			return false
	# What the player does besides the cubes (stand in the wind, hold right)
	var drive := module.drive(lvl.pieces[0])
	if not drive.is_empty():
		player.teleport_to(drive["teleport"])
		await frames(4)
		for action in drive["hold"]:
			Input.action_press(action)
	var room: Room = lvl.rooms[0]
	var cleared := false
	var t := 0.0
	while t < wait and not cleared:
		module.advance(lvl.pieces[0], player, t)
		await frames(6)
		t += 0.1
		cleared = room.is_cleared()
	for action in drive.get("hold", []):
		Input.action_release(action)
	Input.action_release("jump")
	Input.action_release("sprint")
	return cleared


## Gust Alley with a single sentence on its cube.
func try_sentence(params: Dictionary, key: String, wait := 7.0, tier := 1) -> bool:
	return await try_plan("gust_alley", params, {"cubes": {"Gust Cube": key}}, wait, tier)


func scenario_simulation() -> void:
	print("SCENARIO every predicted way solves the room, and no ruled-out way does")
	# Each module at the corners of its envelope; a second set at tier 3 (Long
	# and Large known as well)
	var cases := []
	for mirror in [false, true]:
		for lock in [0, 1]:
			for pair in [[2, 3], [2, 5], [3, 3], [3, 4]]:
				cases.append({"module": "gust_alley", "tier": 1, "params": {"mirror": mirror, "lock": lock, "gap": pair[0], "run": pair[1]}})
	for mirror in [false, true]:
		cases.append({"module": "gust_alley", "tier": 3, "params": {"mirror": mirror, "lock": 0, "gap": 3, "run": 4}})
		cases.append({"module": "gust_alley", "tier": 3, "params": {"mirror": mirror, "lock": 1, "gap": 2, "run": 5}})
	# All but the modifier carved (the gentlest), both ways round
	for mirror in [false, true]:
		cases.append({"module": "gust_alley", "tier": 1, "params": {"mirror": mirror, "lock": 2, "gap": 3, "run": 4}})
	cases.append({"module": "gust_alley", "tier": 2, "params": {"mirror": false, "lock": 2, "gap": 2, "run": 5}})
	for layout in DeadWeightModule.VERIFIED:
		cases.append({"module": "dead_weight", "tier": 1, "params": {"gap": int(layout.get_slice("/", 0)), "run": int(layout.get_slice("/", 1)), "mirror": false, "lock": 0}})
	# The fixed cube's direction open as well
	cases.append({"module": "dead_weight", "tier": 1, "params": {"gap": 3, "run": 5, "mirror": false, "lock": 1}})
	cases.append({"module": "dead_weight", "tier": 2, "params": {"gap": 2, "run": 3, "mirror": false, "lock": 1}})
	for rows in [3, 4]:
		for width in [3, 4]:
			cases.append({"module": "updraft", "tier": 1, "params": {"dist": 1, "rows": rows, "width": width, "mirror": false, "lock": 0}})
	# Tier 3 knows Long and Large as well: the tallest and the lowest layouts
	cases.append({"module": "updraft", "tier": 3, "params": {"dist": 1, "rows": 4, "width": 4, "mirror": false, "lock": 0}})
	cases.append({"module": "updraft", "tier": 3, "params": {"dist": 1, "rows": 3, "width": 3, "mirror": false, "lock": 0}})
	# Lift carved, only the modifier open
	cases.append({"module": "updraft", "tier": 1, "params": {"dist": 1, "rows": 4, "width": 4, "mirror": false, "lock": 1}})
	cases.append({"module": "updraft", "tier": 2, "params": {"dist": 1, "rows": 3, "width": 3, "mirror": false, "lock": 1}})
	for c in cases:
		var params: Dictionary = c["params"]
		var module := DailyModules.make(c["module"])
		var kit := DailyKit.words(c["tier"])
		var tag := "%s tier %d %s" % [c["module"], c["tier"], str(params).replace("{", "").replace("}", "").replace("\"", "")]
		var plans := module.plans(params, kit)
		check("[%s] offers at least two ways" % tag, plans.size() >= 2, str(plans.size()))
		for plan in plans:
			var opened: bool = await try_plan(c["module"], params, plan, 9.0, c["tier"])
			check("[%s] %s clears the room" % [tag, plan["label"]], opened)
		for plan in module.non_plans(params, kit).slice(0, 1):
			var opened: bool = await try_plan(c["module"], params, plan, 5.0, c["tier"])
			check("[%s] %s does not" % [tag, plan["label"]], not opened)


# ------------------------------------------------------------------ diagnostics

## Not part of the default run: prints, for every layout and modifier, where
## the crate ends up, to read the real thresholds off the physics.
##   ... -- daily sweep
func scenario_sweep() -> void:
	print("SCENARIO sweep (diagnostic)")
	for mirror in [false, true]:
		for gap in [2, 3]:
			for run in [3, 4, 5, 6]:
				for modifier in ["normal", "strong"]:
					var params := {"mirror": mirror, "lock": 0, "gap": gap, "run": run}
					var way := "left" if mirror else "right"
					var opened: bool = await try_sentence(params, "wind/push/%s/%s" % [way, modifier], 8.0)
					var crate: Node2D = lvl.pieces[0]["crate"]
					var plate: Node2D = lvl.pieces[0]["plate"]
					print("  SWEEP mirror=%s gap=%d run=%d %-6s opened=%s crate_x=%.0f plate_x=%.0f vy=%s" % [
						mirror, gap, run, modifier, opened, crate.global_position.x, plate.global_position.x, str(crate.get("velocity"))])


## Screenshots of a generated day for a look (to user://test_shots/daily_*.png).
##   ... -- daily look
func scenario_look() -> void:
	print("SCENARIO a look at a generated day")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_shots"))
	var day := 0
	while DailyGenerator.difficulty_for_day(day) != 2:
		day += 1
	DailyRun.start_day(day)
	await open(DailyRun.SCENE)
	var spots := [["start", lvl.rooms[0].entry_spawn]]
	for i in lvl.rooms.size() - 1:
		var room: Room = lvl.rooms[i]
		spots.append(["room%d" % (i + 1), Vector2(room.bounds.get_center().x, 530)])
	spots.append(["bell", lvl.bell.global_position + Vector2(-120, 80)])
	for s in spots:
		player.teleport_to(s[1])
		await seconds(1.4)
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("user://test_shots/daily_%s.png" % s[0]))
	print("  saved ", spots.size(), " shots; day ", day, " ", str(DailyOracle.ways(lvl.spec)))


## Not part of the default run: Updraft layouts against every modifier.
##   ... -- daily sweep_up
func scenario_sweep_up() -> void:
	print("SCENARIO sweep_up (diagnostic)")
	var module := UpdraftModule.new()
	for dist in [1, 2]:
		for rows in [3, 4]:
			for modifier in ["normal", "strong", "long", "large"]:
				var params := {"dist": dist, "rows": rows, "width": 3, "mirror": false, "lock": 0}
				var plan := {"label": "x", "cubes": {"Lift Cube": "wind/lift/up/%s" % modifier}}
				var cleared: bool = await try_plan("updraft", params, plan, 8.0, 3)
				print("  SWEEPUP dist=%d rows=%d %-7s cleared=%s player=(%.0f,%.0f)" % [dist, rows, modifier, cleared, player.global_position.x, player.global_position.y])


# ------------------------------------------------------------------ score and code

func scenario_score() -> void:
	print("SCENARIO the score")
	var perfect := DailyScore.compute({"time": 30.0, "deaths": 0, "resets": 0, "hints": 0, "casts": 6}, 100.0, 3)
	check("a perfect run scores 1000 and three stars", perfect["score"] == 1000 and perfect["stars"] == 3, str(perfect))
	var hinted := DailyScore.compute({"time": 30.0, "deaths": 0, "resets": 0, "hints": 1, "casts": 6}, 100.0, 3)
	check("a hint costs 60 and the third star", hinted["score"] == 940 and hinted["stars"] == 2, str(hinted))
	var slow := DailyScore.compute({"time": 400.0, "deaths": 0, "resets": 0, "hints": 0, "casts": 0}, 100.0, 3)
	check("time over par is capped at 300 points", slow["parts"]["time"] == 300 and slow["score"] == 700, str(slow))
	var messy := DailyScore.compute({"time": 1000.0, "deaths": 30, "resets": 30, "hints": 30, "casts": 300}, 100.0, 3)
	check("a terrible run still finishes with one star and never goes below 0", messy["score"] == 0 and messy["stars"] == 1, str(messy))
	var casts := DailyScore.compute({"time": 10.0, "deaths": 0, "resets": 0, "hints": 0, "casts": 10}, 100.0, 3)
	check("two casts a room are free, the rest cost 10 each", casts["parts"]["casts"] == 40, str(casts["parts"]))
	var parts_sum := 0
	for k in perfect["parts"]:
		parts_sum += perfect["parts"][k]
	check("the parts add up to the points taken off", 1000 - parts_sum == perfect["score"])
	var spec := DailyGenerator.generate(DailyGenerator.seed_for_day(300), 1, 1)
	check("par comes from the rooms' modules", DailyScore.par_seconds(spec) > 100.0, str(DailyScore.par_seconds(spec)))


func sample_result(day := 300) -> Dictionary:
	return {"day": day, "version": 1, "difficulty": 2, "tier": 2, "score": 842, "time": 192.4, "deaths": 1,
		"resets": 2, "hints": 0, "casts": 9, "assist": 0, "stars": 3}


func scenario_code() -> void:
	print("SCENARIO the share code")
	var result := sample_result()
	var code := DailyScore.encode(result)
	print("  code: ", code)
	check("a code has the prefix and groups of five", code.begins_with("SB1-") and code.length() == 4 + 26 + 5, str(code.length()))
	var back := DailyScore.decode(code)
	check("a code reads back to the same result", back["day"] == 300 and back["score"] == 842 and back["difficulty"] == 2
		and back["tier"] == 2 and back["deaths"] == 1 and back["resets"] == 2 and back["hints"] == 0
		and back["casts"] == 9 and int(back["time"]) == 192 and back["version"] == 1, str(back))
	check("a code survives lower case and stray spaces", DailyScore.decode(" " + code.to_lower().replace("-", " - ") + " ").get("score", -1) == 842)
	var typo := code.substr(0, 8) + ("A" if code[8] != "A" else "B") + code.substr(9)
	check("a typo is caught by the checksum", DailyScore.decode(typo).is_empty())
	var edited := result.duplicate()
	edited["score"] = 1000
	var forged := DailyScore.encode(edited)
	var mixed := code.substr(0, 14) + forged.substr(14)
	check("pieces of two codes don't make a valid one", DailyScore.decode(mixed).is_empty() or DailyScore.decode(mixed) != DailyScore.decode(forged))
	check("garbage is refused", DailyScore.decode("hello").is_empty() and DailyScore.decode("").is_empty() and DailyScore.decode("SB1-").is_empty())
	check("a wrong prefix is refused", DailyScore.decode("XX1" + code.substr(3)).is_empty())
	var extremes := {"day": 70000, "version": 99, "difficulty": 9, "tier": 99, "score": 5000, "time": 99999.0,
		"deaths": 999, "resets": 999, "hints": 999, "casts": 999, "assist": 999}
	var ext := DailyScore.decode(DailyScore.encode(extremes))
	check("out-of-range fields are clamped, not corrupted", not ext.is_empty() and ext["score"] == 1023 and ext["deaths"] == 255, str(ext))
	check("the share text names the day and the points", DailyScore.share_text(sample_result(), code).contains("2026-10-28") and DailyScore.share_text(sample_result(), code).contains("842"))


# ------------------------------------------------------------------ the store

## Makes the store use `day` as today.
func set_today(day: int) -> void:
	DailyStore.now_provider = func(): return DailyRng.date_of(day)


## A ranked result for `day` (the clock is set to that day first).
func finish_day(day: int, score := 800) -> Dictionary:
	set_today(day)
	var r := sample_result(day)
	r["mode"] = "daily"
	r["score"] = score
	return DailyStore.record(r)


func scenario_store() -> void:
	print("SCENARIO the daily store")
	DailyStore.persist = false
	DailyStore.forget()
	DailyStore._loaded = true
	set_today(300)
	check("an ordinary date is ok", DailyStore.clock_status() == "ok")
	set_today(DailyStore.BUILD_DAY - 1)
	check("a date before this build is a wrong clock", DailyStore.clock_status() == "too_early")
	set_today(0)
	check("1970 (a dead battery) reads as 2026-01-01 at best, so it is a wrong clock", DailyStore.clock_status() == "too_early")
	DailyStore.now_provider = func(): return {"year": 1970, "month": 1, "day": 1}
	check("a literal 1970 clock is a wrong clock", DailyStore.clock_status() == "too_early")

	# a first ranked result, then the same day again is practice
	DailyStore.forget()
	DailyStore._loaded = true
	var first := finish_day(300, 800)
	check("the first completion is ranked and starts a streak", first["ranked"] and first["streak"] == 1, str(first))
	var again := finish_day(300, 950)
	check("the same day again is not ranked and keeps the streak", not again["ranked"] and again["streak"] == 1, str(again))
	check("but a better practice score is remembered", DailyStore.practice["300"] == 950 and DailyStore.result_for(300)["score"] == 800)
	var next := finish_day(301)
	check("the next day extends the streak", next["ranked"] and next["streak"] == 2)
	var mended := finish_day(303)
	check("one missed day is forgiven by the weekly mend", mended["ranked"] and mended["mended"] and mended["streak"] == 3, str(mended))
	var lost := finish_day(306)
	check("two missed days break the streak", lost["ranked"] and lost["streak"] == 1 and not lost["mended"], str(lost))
	finish_day(307)
	var no_mend := finish_day(309)
	check("the mend takes a week to come back", no_mend["streak"] == 1 and not no_mend["mended"], str(no_mend))
	check("the best streak is kept", DailyStore.best_streak == 3)
	set_today(309)
	check("the streak shows as alive the day it was made", DailyStore.current_streak() == 1)
	set_today(312)
	check("and lapses once days have been missed", DailyStore.current_streak() == 0)

	# the clock going backwards
	DailyStore.forget()
	DailyStore._loaded = true
	set_today(320)
	DailyStore.note_today()
	set_today(318)
	check("a clock set back is flagged", DailyStore.clock_status() == "rewound")
	var rewound := finish_day(318)
	check("and cannot make a ranked result", not rewound["ranked"] and DailyStore.result_for(318).is_empty(), str(rewound))
	set_today(320)
	var wrong_day := DailyStore.record({"day": 250, "mode": "daily", "score": 900, "time": 60.0, "stars": 3})
	check("a result for another day than today is practice", not wrong_day["ranked"])
	var trial := DailyStore.record({"day": 320, "mode": "trial", "score": 900, "time": 60.0, "stars": 3})
	check("a trial never ranks", not trial["ranked"])
	DailyStore.now_provider = Callable()
	DailyStore.forget()
	DailyStore._loaded = true


func scenario_persistence() -> void:
	print("SCENARIO the daily file")
	var test_path := "user://daily_test.cfg"
	DailyStore.forget()
	DailyStore._loaded = true
	DailyStore.persist = true
	DailyStore.file_path = test_path
	finish_day(300, 880)
	finish_day(301, 760)
	DailyStore.set_player_name("Ishaan")
	check("a friend's code is accepted", DailyStore.add_friend("Sam", DailyScore.encode(sample_result(301))) == "")
	check("a bad code is refused with a reason", DailyStore.add_friend("Sam", "SB1-NOPE") != "")
	check("the file was written", FileAccess.file_exists(test_path))
	DailyStore.forget()
	DailyStore._loaded = false
	DailyStore.now_provider = func(): return DailyRng.date_of(301)
	check("it reads back (results, streak, name, friends)",
		DailyStore.result_for(300).get("score", -1) == 880 and DailyStore.result_for(301).get("score", -1) == 760
		and DailyStore.streak == 2 and DailyStore.player_name == "Ishaan" and DailyStore.friends.size() == 1, str(DailyStore.days))
	var board := DailyStore.board_for(301)
	check("the board lists you and the friend, best first", board.size() == 2 and board[0]["name"] == "Sam" and board[1]["you"], str(board))
	# a damaged file
	var broken := FileAccess.open(test_path, FileAccess.WRITE)
	broken.store_string("[daily]\ndays={\"300\": 5, \"abc\": {\"score\": 99}, \"301\": {\"score\": \"lots\", \"stars\": 9, \"time\": -4}}\nstreak=\"many\"\nbest_streak=1e300\nfriends=[1, \"x\", {\"name\": 3}]\nplayer_name=12\n")
	broken.close()
	DailyStore.forget()
	DailyStore._loaded = false
	DailyStore.load_file()
	check("a damaged file loads without crashing or inventing results", DailyStore.result_for(300).is_empty() and DailyStore.streak == 0
		and DailyStore.friends.is_empty() and DailyStore.player_name == "")
	var kept: Dictionary = DailyStore.result_for(301)
	check("a result with bad fields is clamped", kept.is_empty() or (kept["stars"] >= 1 and kept["stars"] <= 3 and kept["score"] >= 0 and kept["time"] >= 0.0), str(kept))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	DailyStore.persist = false
	DailyStore.file_path = DailyStore.PATH
	DailyStore.forget()
	DailyStore._loaded = true
	DailyStore.now_provider = Callable()
	check("with persistence off nothing is written", true)
	var story_file_before := FileAccess.file_exists(GameState.SAVE_PATH)
	DailyStore.save()
	check("and the story's save is never touched by the daily store", FileAccess.file_exists(GameState.SAVE_PATH) == story_file_before)


# ------------------------------------------------------------------ the cards

func scenario_cards() -> void:
	print("SCENARIO the daily screen and the result card")
	DailyStore.persist = false
	DailyStore.forget()
	DailyStore._loaded = true
	set_today(300)
	# the title has the entry and it opens the screen
	await open("res://scenes/ui/title_screen.tscn")
	check("the title menu has a Daily Puzzle word", lvl.daily_button != null and lvl.daily_button.text == "Daily Puzzle")
	lvl._on_daily()
	await frames(4)
	var menu: DailyMenu = null
	for child in lvl.get_children():
		if child is DailyMenu:
			menu = child
	check("it opens the Daily Puzzle screen", menu != null and menu.play_button != null)
	check("the screen offers today's puzzle, ranked", menu != null and menu.play_button.text == "Play today's puzzle")
	if menu:
		check("it shows the board with a perfect run on it", menu._body != null)
		menu._close()
	await frames(3)
	# a finished puzzle's card
	DailyRun.start_day(300)
	await open(DailyRun.SCENE)
	DailyRun.time = 140.0
	DailyRun.deaths = 0
	DailyRun.resets = 1
	DailyRun.hints = 0
	DailyRun.casts = 5
	DailyRun.solved_with = {0: {"Gust Cube": "wind/push/right/strong"}}
	lvl.finish_chapter()
	await frames(10)
	var card: DailyComplete = null
	for child in lvl.get_children():
		if child is DailyComplete:
			card = child
	check("finishing opens the daily card", card != null)
	if card:
		check("the card has a share code that decodes to the run", DailyScore.decode(card.code_field.text).get("day", -1) == 300)
		check("the card says how many ways each room had", card.data["ways"].size() == lvl.spec["rooms"].size() and String(card.data["ways"][0]).contains("ways in all"))
		check("the ranked result was written down", DailyStore.has_ranked(300) and DailyStore.streak == 1)
		check("the card's buttons exist", card.again_button != null and card.title_button != null)
		card.queue_free()
		get_tree().paused = false
	await leave()
	DailyStore.forget()
	DailyStore._loaded = true
	DailyStore.now_provider = Callable()


## Screenshots of the title, the Daily Puzzle screen (empty and with results and
## friends) and the end card (to user://test_shots/daily_screen_*.png).
##   ... -- daily screens
func scenario_screens() -> void:
	print("SCENARIO the daily screens")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://test_shots"))
	DailyStore.persist = false
	DailyStore.forget()
	DailyStore._loaded = true
	for d in [290, 291, 292, 294, 295, 296, 297, 298]:
		finish_day(d, 600 + (d % 5) * 70)
	set_today(298)
	var friend := sample_result(298)
	friend["score"] = 940
	friend["time"] = 151.0
	DailyStore.add_friend("Mira", DailyScore.encode(friend))
	friend["score"] = 710
	friend["time"] = 240.0
	DailyStore.add_friend("Tam", DailyScore.encode(friend))
	await open("res://scenes/ui/title_screen.tscn")
	await seconds(1.0)
	shot("screen_title")
	lvl._on_daily()
	await seconds(0.6)
	shot("screen_menu")
	for child in lvl.get_children():
		if child is DailyMenu:
			child._go_day(299)
	set_today(299)
	await seconds(0.4)
	shot("screen_menu_today")
	await leave()
	DailyRun.start_day(299)
	await open(DailyRun.SCENE)
	DailyRun.time = 187.0
	DailyRun.resets = 1
	DailyRun.hints = 1
	DailyRun.casts = 9
	DailyRun.solved_with = {0: {"Gust Cube": "wind/push/right/strong"}}
	lvl.finish_chapter()
	await seconds(1.4)
	shot("screen_card")
	get_tree().paused = false
	await leave()
	DailyStore.forget()
	DailyStore._loaded = true
	DailyStore.now_provider = Callable()


func shot(name: String) -> void:
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("user://test_shots/daily_%s.png" % name))


## Choosing words on a daily cube with open slots: the aim preview works out the
## spell for every half-finished sentence on the way (this once raised a script
## error on a wind rune with no modifier yet). A script error shows in the log.
##   ... -- daily assembly
func scenario_assembly() -> void:
	print("SCENARIO choosing words on a cube with open slots")
	var spell := RuneBook.spell(RuneRecipe.from_key("wind/push/right/-"))
	check("a wind rune with no modifier still has a spell to preview", spell.has("upkeep") and spell["key"] == "wind/push")
	spell = RuneBook.spell(RuneRecipe.from_key("wind/-/up/-"))
	check("so does one with no form and no modifier", spell.has("key"))
	var day := 0
	var found: RuneCube = null
	while found == null and day < 40:
		DailyRun.start_day(day)
		await open(DailyRun.SCENE)
		for node in get_tree().get_nodes_in_group("rune_cube"):
			if node is RuneCube and node.recipe.get_slot(RuneFragments.Kind.MODIFIER) == &"":
				found = node
				break
		if found == null:
			await leave()
			day += 1
	check("some daily level has a cube with an open slot", found != null, "day %d" % day)
	if found != null:
		var manager: RuneManager = RuneManager.get_for(get_tree())
		manager.assembly.open(found)
		await frames(3)
		for id in [&"wind", &"push", &"lift", &"left", &"right", &"up", &"normal", &"strong", &"long", &"large"]:
			manager.assembly.choose(id)
			await frames(1)
		check("choosing words through the assembly kept it open", manager.assembly.is_open)
		manager.assembly.close()
		await leave()


## The difficulty score R: each knob moves it the right way, every band can
## be reached, and the named difficulties are ordered over many seeds.
##   ... -- daily difficulty
func scenario_difficulty() -> void:
	print("SCENARIO the difficulty score and the bands")
	# The spread of R the library can make, per module, knob and tier
	for id in DailyModules.IDS:
		var module := DailyModules.make(id)
		for tier in range(1, DailyKit.MAX_TIER + 1):
			var kit := DailyKit.words(tier)
			if module is DailyMechanism:
				if tier < module.min_tier: continue
				var params := DailyVerified.sample(id, DailyRng.new(205).fork(id + str(tier)), tier)
				var measured := module.score_parts(params, kit)
				print("  R %s tier %d: %.2f, %d verified ways, %s" % [id, tier, DailyDifficulty.total(measured), measured["plans"], params])
				continue
			var line := "  R %-12s tier %d:" % [id, tier]
			for lock in [0, 1, 2]:
				var p := module.fallback(tier)
				p["lock"] = lock
				if id != "gust_alley" and lock == 2:
					continue
				var parts := module.score_parts(p, kit)
				line += "  lock %d R=%.2f (S %.2f T %.1f C %.1f E %.1f, %d ways)" % [lock, DailyDifficulty.total(parts),
					parts["search"], parts["steps"], parts["concept"], parts["execution"], parts["plans"]]
			print(line)
	# Each knob moves R the right way
	var gust := GustAlleyModule.new()
	var kit1 := DailyKit.words(1)
	var r_open := DailyDifficulty.total(gust.score_parts({"mirror": false, "lock": 0, "gap": 2, "run": 4}, kit1))
	var r_carved := DailyDifficulty.total(gust.score_parts({"mirror": false, "lock": 2, "gap": 2, "run": 4}, kit1))
	check("carving more of the sentence makes a room easier", r_carved < r_open, "%.2f < %.2f" % [r_carved, r_open])
	var r_tier3 := DailyDifficulty.total(gust.score_parts({"mirror": false, "lock": 0, "gap": 2, "run": 4}, DailyKit.words(3)))
	check("more words make the same room harder to search", r_tier3 > r_open, "%.2f > %.2f" % [r_tier3, r_open])
	var up := UpdraftModule.new()
	var r_lift := DailyDifficulty.total(up.score_parts({"dist": 1, "rows": 4, "width": 3, "lock": 0}, kit1))
	var r_lift_carved := DailyDifficulty.total(up.score_parts({"dist": 1, "rows": 4, "width": 3, "lock": 1}, kit1))
	check("finding Lift yourself is harder than having it carved", r_lift > r_lift_carved, "%.2f > %.2f" % [r_lift, r_lift_carved])
	# The bands and the ramp
	check("the bands rise with the difficulty", DailyDifficulty.band(1).x < DailyDifficulty.band(2).x
		and DailyDifficulty.band(2).x < DailyDifficulty.band(3).x and DailyDifficulty.band(3).x < DailyDifficulty.band(4).x)
	check("a level between two difficulties has a band between theirs",
		DailyDifficulty.band(2.5).x > DailyDifficulty.band(2).x and DailyDifficulty.band(2.5).x < DailyDifficulty.band(3).x)
	check("the ramp starts at the difficulty picked", DailyDifficulty.ramp(2, 0) == 2.0 and DailyDifficulty.ramp(2, 4) == 2.0)
	check("it climbs a quarter step every five rooms", DailyDifficulty.ramp(2, 5) == 2.25 and DailyDifficulty.ramp(2, 14) == 2.5)
	check("and stops a full step above", DailyDifficulty.ramp(2, 20) == 3.0 and DailyDifficulty.ramp(2, 400) == 3.0)
	check("Grand ramps into Master", DailyDifficulty.ramp(4, 30) == 5.0 and DailyDifficulty.name_of(5.0) == "Master")
	check("levels have names", DailyDifficulty.name_of(2.5) == "Steady +2" and DailyDifficulty.name_of(1.0) == "Gentle")
	# Over many seeds: each difficulty's rooms are harder on average, and most
	# land in their band
	var means := []
	for difficulty in [1, 2, 3, 4]:
		var sum := 0.0
		var count := 0
		var inside := 0
		var b := DailyDifficulty.band(difficulty)
		for s in 250:
			var spec := DailyGenerator.generate(DailyRng.fnv("diff%d" % s), difficulty, DailyGenerator.tier_for_difficulty(difficulty))
			for room in spec["rooms"]:
				var r := DailyDifficulty.room_score(room, spec["kit"])
				sum += r
				count += 1
				if DailyDifficulty.miss(r, b) == 0.0:
					inside += 1
		means.append(sum / count)
		print("  difficulty %d: mean R %.2f, %d%% of %d rooms in the band %s" % [difficulty, sum / count, inside * 100 / count, count, str(b)])
		check("%s rooms mostly land in their band" % DailyDifficulty.NAMES[difficulty - 1], inside * 100 / count >= 90, "%d%%" % (inside * 100 / count))
	check("each named difficulty is harder on average than the one before",
		means[0] < means[1] and means[1] < means[2] and means[2] < means[3], str(means))
	# The Endless rooms climb as well
	var early := 0.0
	var late := 0.0
	for s in 60:
		early += float(DailyGenerator.endless_room(DailyRng.fnv("run%d" % s), 0, 1)["rooms"][0]["r"])
		late += float(DailyGenerator.endless_room(DailyRng.fnv("run%d" % s), 25, 1)["rooms"][0]["r"])
	print("  endless from Gentle: room 1 mean R %.2f, room 26 mean R %.2f" % [early / 60.0, late / 60.0])
	check("an Endless run's later rooms are harder", late > early)
	var room := DailyGenerator.endless_room(77, 3, 2)
	check("an Endless room is one room and a stair out", room["rooms"].size() == 1 and room.has("exit") and room["endless"])
	check("the same run seed and room number give the same room", DailyGenerator.endless_room(77, 3, 2)["digest"] == room["digest"])


func scenario_endless() -> void:
	print("SCENARIO Endless lifecycle, records and sharing")
	var story_canvas := get_tree().root.content_scale_size
	var story_abilities := GameState.all_abilities
	var story_kit := RuneManager.kit_override.duplicate()
	var story_flags := GameState.flags.duplicate(true)
	DailyStore.persist = false
	DailyRun.start_endless(2, 1234)
	check("Endless starts with three lives and a stair spec", DailyRun.mode == "endless" and DailyRun.lives == 3 and DailyRun.endless_k == 0 and DailyRun.spec_override.has("exit"))
	await open(DailyRun.SCENE)
	check("puzzle and stair are built", lvl.rooms.size() == 2 and lvl.exit_door != null and lvl.bell == null)
	check("Endless HUD shows the room and lives", lvl.endless_label.text.contains("Room 1") and lvl.endless_label.text.contains("Lives 3"))
	check("generated UI uses the physical window size", get_viewport().get_visible_rect().size == Vector2(get_tree().root.size))
	await seconds(1.5)
	await shot("endless_hud")
	var entry: Dictionary = lvl.spec["rooms"][0]
	var module := DailyModules.make(entry["module"])
	var plan: Dictionary = module.plans(entry["params"], lvl.spec["kit"])[0]
	check("first Endless room solves in physics", await try_plan(module.id, entry["params"], plan, 9, DailyRun.tier))
	await leave()
	DailyRun.start_endless(2, 1234)
	await open(DailyRun.SCENE)
	entry = lvl.spec["rooms"][0]
	module = DailyModules.make(entry["module"])
	plan = module.plans(entry["params"], lvl.spec["kit"])[0]
	module.perform(lvl.pieces[0], plan)
	var drive := module.drive(lvl.pieces[0])
	if not drive.is_empty():
		player.teleport_to(drive["teleport"])
		for action in drive.get("hold", []): Input.action_press(action)
	await seconds(9)
	for action in drive.get("hold", []): Input.action_release(action)
	var rune_hud: RuneHud = lvl.get_node("RuneManager").hud
	check("active rune status and Endless HUD occupy separate rows", lvl.endless_label.get_global_rect().position.y >= rune_hud._panel.get_global_rect().end.y + 2)
	shot("endless_hud_active")
	var digest: int = lvl.spec["digest"]
	player.teleport_to(lvl.exit_door.global_position)
	await seconds(2)
	lvl = get_tree().current_scene
	player = lvl.get_node("Player")
	check("door advances and generates a fresh room without counting the old room again", DailyRun.rooms_cleared == 0 and DailyRun.endless_k == 1 and DailyRun.run_rooms == 1 and lvl.spec["digest"] != digest)
	digest = lvl.spec["digest"]
	for life in [2, 1]:
		player.die()
		await seconds(2)
		check("death removes one life", DailyRun.lives == life)
		lvl.death_screen.restart_level()
		await seconds(2)
		lvl = get_tree().current_scene
		player = lvl.get_node("Player")
		check("death rebuilds the same room", lvl.spec["digest"] == digest)
		check("observation baseline survives death", DailyRun.room_started.has(0) and DailyRun.room_started[0]["deaths"] == 0)
	player.die()
	await seconds(2)
	var card: EndlessCard
	for child in lvl.get_children():
		if child is EndlessCard: card = child
	check("third death ends the climb without restart input", card != null and card.kind == "over" and not lvl.death_screen.is_processing_input())
	await seconds(1)
	await shot("endless_over")
	check("Endless share code round trips and the board refuses it", bool(DailyScore.decode(card.code).get("endless", false)) and DailyStore.add_friend("Test", card.code).contains("Endless"))
	get_tree().paused = false
	await leave()
	DailyRun.start_endless(2, 1234)
	DailyRun.endless_k = 9
	DailyRun.run_rooms = 9
	DailyRun.lives = 1
	DailyRun.prepare_endless_room()
	await open(DailyRun.SCENE)
	entry = lvl.spec["rooms"][0]
	module = DailyModules.make(entry["module"])
	plan = module.plans(entry["params"], lvl.spec["kit"])[0]
	module.perform(lvl.pieces[0], plan)
	drive = module.drive(lvl.pieces[0])
	if not drive.is_empty():
		player.teleport_to(drive["teleport"])
		for action in drive.get("hold", []): Input.action_press(action)
	await seconds(9)
	for action in drive.get("hold", []): Input.action_release(action)
	player.teleport_to(lvl.exit_door.global_position)
	await seconds(1)
	card = null
	for child in lvl.get_children():
		if child is EndlessCard: card = child
	check("tenth room gives a rest and one life back", card != null and card.kind == "rest" and DailyRun.lives == 2 and DailyRun.endless_k == 10)
	await seconds(1)
	await shot("endless_rest")
	if card: card.keep_button.pressed.emit()
	await seconds(2)
	lvl = get_tree().current_scene
	check("keep climbing loads room eleven", lvl is DailyRoot and lvl.endless_label.text.contains("Room 11"))
	DailyStore.endless_best = {}
	check("record keeps rooms before score and resolves ties", DailyStore.record_endless(2, 10, 8000, 2.5) and not DailyStore.record_endless(2, 9, 9000, 2.5) and DailyStore.record_endless(2, 10, 8100, 2.5) and not DailyStore.record_endless(2, 10, 8000, 2.5))
	await leave()
	check("leaving restores the story canvas size", get_tree().root.content_scale_size == story_canvas)
	check("leaving Endless restores story abilities, vocabulary and flags", GameState.all_abilities == story_abilities and RuneManager.kit_override == story_kit and GameState.flags == story_flags)


func scenario_module_probe() -> void:
	var measured := {}
	for id in ["folded_wall", "together", "burn_through", "dark_hall"]:
		var module := DailyModules.make(id) as DailyMechanism
		var entries: Array = []
		for params in module.parameter_grid():
			var working: Array = []
			for plan in module.plans(params, DailyKit.words(5)):
				var cleared: bool = await try_plan(id, params, plan, 9.0, 5)
				print("PROBE ", id, " ", params, " ", plan["label"], " ", cleared)
				if cleared: working.append(plan)
			entries.append({"params": params, "plans": working})
		measured[id] = entries
		var file := FileAccess.open("res://.godot/module-probe.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(measured, "\t"))
		file.close()


func scenario_verified_fresh() -> void:
	check("the verified table is complete and matches the current physics sources", DailyVerified.fresh() and bool(DailyVerified.table.get("complete", false)))
	for id in DailyModules.IDS:
		var module := DailyModules.make(id)
		check("%s has a layout with two physics-verified solutions at its first tier" % id, DailyVerified.has_module(id, module.min_tier))

func scenario_new_modules() -> void:
	for id in DailyModules.IDS.slice(3):
		var module := DailyModules.make(id)
		var params := DailyVerified.sample(id, DailyRng.new(4142).fork(id), module.min_tier)
		check("%s samples a verified layout" % id, not params.is_empty())
		if params.is_empty(): continue
		for plan in module.plans(params, DailyKit.words(module.min_tier)):
			check("%s: %s clears in real physics" % [id, plan["label"]], await try_plan(id, params, plan, 9, module.min_tier))
		var wrong: Dictionary = module.non_plans(params, DailyKit.words(module.min_tier))[0]
		check("%s rejects an unrelated rune" % id, not await try_plan(id, params, wrong, 9, module.min_tier))

	var impact := DailyModules.make("burn_through")
	var impact_params := {"kind": 1, "distance": 2}
	var impact_plans := impact.plans(impact_params, DailyKit.words(2))
	check("cracked masonry offers sustained-wind and burst routes", impact_plans.size() >= 2)
	for plan in impact_plans:
		check("cracked wall: %s clears in rendered physics" % plan["label"], await try_plan("burn_through", impact_params, plan, 9, 2))

func scenario_chains() -> void:
	for level in [3.0, 4.0, 5.0]:
		var entry := DailyGenerator.draw_room(DailyRng.new(221), level, DailyDifficulty.tier_for(level), DailyKit.words(DailyDifficulty.tier_for(level)), "")
		if level == 3.0 and not entry.has("beats"): continue
		check("level %.0f has two beats with the required reuse rule" % level, entry["beats"].size() == 2 and bool(entry.get("reuse", false)) == (level >= 4))
		var module := DailyChain.new()
		var plans := module.plans(entry["params"], DailyKit.words(DailyDifficulty.tier_for(level)))
		check("chain has multiple verified combinations", plans.size() >= 2)
		if level >= 4:
			var first_module := DailyModules.make(entry["beats"][0]["module"])
			var second_module := DailyModules.make(entry["beats"][1]["module"])
			var first_name := String(first_module.open_slots(entry["beats"][0]["params"]).keys()[0])
			var second_name := String(second_module.open_slots(entry["beats"][1]["params"]).keys()[0])
			var different := true
			for plan in plans:
				if plan["beats"][0]["cubes"].get(first_name, "") == plan["beats"][1]["cubes"].get(second_name, ""): different = false
			check("Grand and Master require a new inscription on the reused cube", different)
		for plan in plans.slice(0,2):
			check("chain %.0f: %s clears end to end" % [level, plan["label"]], await try_plan("chain", entry["params"], plan, 22, DailyDifficulty.tier_for(level)))

func scenario_endless_long() -> void:
	for start in range(1,5):
		DailyRun.start_endless(start, 51454)
		for room_number in 30:
			var tick := Time.get_ticks_usec()
			DailyRun.prepare_endless_room()
			var generation_ms := (Time.get_ticks_usec() - tick) / 1000.0
			check("%d/%d generates in under 50 ms" % [start,room_number + 1], generation_ms < 50, str(generation_ms))
			check("%d/%d follows the ramp" % [start,room_number + 1], DailyRun.spec_override["level"] == DailyDifficulty.ramp(start,room_number))
			await open(DailyRun.SCENE)
			var room: Dictionary = lvl.spec["rooms"][0]
			var module := DailyModules.make(room["module"])
			var plan: Dictionary = module.plans(room["params"], lvl.spec["kit"])[0]
			module.perform(lvl.pieces[0], plan)
			var drive := module.drive(lvl.pieces[0])
			if not drive.is_empty():
				player.teleport_to(drive["teleport"])
				for action in drive.get("hold", []): Input.action_press(action)
			var elapsed := 0.0
			while elapsed < 22 and not lvl.rooms[0].is_cleared():
				module.advance(lvl.pieces[0], player, elapsed)
				await frames(6)
				elapsed += 0.1
			for action in ["move_left", "move_right", "jump", "sprint"]: Input.action_release(action)
			check("%d/%d solves in real physics" % [start,room_number + 1], lvl.rooms[0].is_cleared(), room["module"])
			var old: WeakRef = weakref(lvl)
			var nodes := get_tree().get_node_count()
			check("%d/%d keeps a bounded scene tree" % [start,room_number + 1], nodes < 2400, str(nodes))
			player.teleport_to(lvl.exit_door.global_position)
			await seconds(1.5)
			lvl = get_tree().current_scene
			var rest: EndlessCard
			for child in lvl.get_children():
				if child is EndlessCard: rest = child
			if rest:
				rest.keep_button.pressed.emit()
				await seconds(1.5)
				lvl = get_tree().current_scene
			check("old room is freed on transition", old.get_ref() == null)
			check("room completion counted once", DailyRun.run_rooms == room_number + 1 and DailyRun.endless_k == room_number + 1)
		await leave()

func scenario_calibration() -> void:
	var previous := DailyCalibration.file_path
	DailyCalibration.file_path = "user://calibration-test.cfg"
	DailyCalibration.persist = true
	var file := ConfigFile.new()
	var rows: Array = []
	for i in 2005:
		rows.append({"module": "gust_alley", "params": {}, "tier": 1, "r": 2.0, "time": float(i), "resets": 0, "hints": 0, "deaths": 0})
	rows.append({"module": "damaged"})
	file.set_value("stats", "rows", rows)
	file.save(DailyCalibration.file_path)
	DailyCalibration.append({"module": "updraft", "params": {}, "tier": 1, "r": 3.0, "time": 40.0, "resets": 1, "hints": 1, "deaths": 0})
	file.load(DailyCalibration.file_path)
	var stored := DailyCalibration.read_rows(file)
	check("calibration stores only the last 2000 valid local observations", stored.size() == 2000 and stored[-1]["module"] == "updraft")
	DailyCalibration.file_path = previous
	DailyCalibration.persist = false


func scenario_endless_persistence() -> void:
	var previous := DailyStore.file_path
	DailyStore.file_path = "user://endless-test.cfg"
	DailyStore.persist = true
	DailyStore.forget()
	DailyStore._loaded = true
	DailyStore.record_endless(2, 12, 11450, 2.5)
	DailyStore.forget()
	DailyStore._loaded = false
	var saved := DailyStore.endless_best_for(2)
	check("Endless record survives a save/load round trip", saved.get("rooms") == 12 and saved.get("score") == 11450 and saved.get("level") == 2.5)
	var file := ConfigFile.new()
	file.set_value("daily", "endless_best", {"1": 42, "2": {"rooms": 12}, "5": {"rooms": 10, "score": 9000, "level": 3}, "3": {"rooms": -3, "score": "bad", "level": INF}})
	file.save(DailyStore.file_path)
	DailyStore.forget()
	DailyStore.load_file()
	check("damaged Endless entries are dropped and unsafe fields clamped", not DailyStore.endless_best.has("1") and not DailyStore.endless_best.has("2") and not DailyStore.endless_best.has("5") and DailyStore.endless_best_for(3) == {"rooms": 0, "score": 0, "level": 1.0})
	DailyStore.file_path = previous
	DailyStore.persist = false
	DailyStore.forget()
	DailyStore._loaded = true


## Native screenshots and focus navigation at both desktop and handheld sizes.
func scenario_render_procgen() -> void:
	set_today(300)
	await open("res://scenes/ui/title_screen.tscn")
	var story_canvas := get_tree().root.content_scale_size
	var menu := DailyMenu.open(lvl)
	await seconds(1.5)
	check("Daily menu uses a native-size canvas", get_viewport().get_visible_rect().size == Vector2(get_tree().root.size))
	menu.endless_buttons[0].grab_focus()
	await frames(2)
	shot("procgen_menu")
	for device in ["keyboard", "pad"]:
		menu.endless_buttons[0].grab_focus()
		await frames(2)
		for i in range(1,4):
			var event: InputEvent
			if device == "keyboard":
				var key := InputEventKey.new()
				key.keycode = KEY_RIGHT
				key.pressed = true
				event = key
			else:
				var button := InputEventJoypadButton.new()
				button.button_index = JOY_BUTTON_DPAD_RIGHT
				button.pressed = true
				event = button
			Input.parse_input_event(event)
			await frames(2)
			event.set("pressed", false)
			Input.parse_input_event(event)
			check("%s focus moves right to choice %d" % [device, i + 1], menu.endless_buttons[i].has_focus())
		for direction in ["down", "up", "up"]:
			var event: InputEvent
			if device == "keyboard":
				var key := InputEventKey.new()
				key.keycode = KEY_DOWN if direction == "down" else KEY_UP
				key.pressed = true
				event = key
			else:
				var button := InputEventJoypadButton.new()
				button.button_index = JOY_BUTTON_DPAD_DOWN if direction == "down" else JOY_BUTTON_DPAD_UP
				button.pressed = true
				event = button
			Input.parse_input_event(event)
			await frames(3)
			event.set("pressed", false)
			Input.parse_input_event(event)
			if direction == "down":
				check("%s reaches Back from Endless" % device, menu.back_button.has_focus())
				shot("procgen_menu_back")
		check("%s returns through Endless to the practice button" % device, menu.play_button.has_focus())
	menu.queue_free()
	await frames(2)
	check("closing Daily menu restores the title canvas size", get_tree().root.content_scale_size == story_canvas)
	await leave()
	for visual_id in DailyModules.IDS.slice(3) + ["burn_through_cracked"]:
		var id: String = "burn_through" if visual_id == "burn_through_cracked" else visual_id
		var module := DailyModules.make(id)
		var params := {"kind": 1, "distance": 2} if visual_id == "burn_through_cracked" else DailyVerified.sample(id, DailyRng.new(321).fork(id), module.min_tier)
		if params.is_empty(): continue
		DailyRun.start("trial", 321, 0, 1, module.min_tier)
		DailyRun.spec_override = spec_for(params, module.min_tier, id)
		await open(DailyRun.SCENE)
		var cube: Node2D = lvl.pieces[0]["cubes"].values()[0]
		player.teleport_to(cube.global_position + Vector2(-80,0))
		await seconds(2)
		shot("module_" + visual_id)
		# Inspect the complete world geometry separately from close-up HUD renders.
		lvl.get_node("HUD").visible = false
		lvl.get_node("AmmoUI").visible = false
		lvl._title.visible = false
		lvl._objective.visible = false
		player.get_node("Camera2D").enabled = false
		var overview := Camera2D.new()
		overview.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
		var bounds: Rect2 = lvl.rooms[0].bounds
		var view := get_viewport().get_visible_rect().size
		var zoom := minf((view.x - 32.0) / bounds.size.x, (view.y - 32.0) / bounds.size.y)
		overview.zoom = Vector2(zoom, zoom)
		overview.position = bounds.get_center()
		lvl.add_child(overview)
		overview.make_current()
		await frames(6)
		shot("overview_" + visual_id)
		var plan: Dictionary = module.plans(params, lvl.spec["kit"])[0]
		module.perform(lvl.pieces[0], plan)
		await seconds(1)
		shot("active_" + visual_id)
		await leave()
	DailyStore.now_provider = Callable()
