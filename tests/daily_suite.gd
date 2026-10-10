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
	}
	for key in table:
		if (filter == "" and key != "sweep" and key != "look" and key != "sweep_up") or filter == key:
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
	check("everyone has the three abilities", state.has_ability("fire") and state.has_ability("heal") and state.has_ability("echo"))
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
		await frames(6)
		t += 0.1
		cleared = room.is_cleared()
	for action in drive.get("hold", []):
		Input.action_release(action)
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
