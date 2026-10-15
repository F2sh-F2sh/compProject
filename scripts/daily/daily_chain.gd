class_name DailyChain
extends DailyModule

func _init() -> void:
	id = "chain"
	title = "Two Movements"
	objective = "Open both passages."
	par_seconds = 140

func columns(params: Dictionary) -> int:
	var count := 1
	for beat in params["beats"]:
		count += DailyModules.make(beat["module"]).columns(beat["params"]) - 1
	return count

func ceiling_row() -> int:
	return RoomKit.HIGH_CEIL

func plans(params: Dictionary, words: PackedStringArray) -> Array:
	var a: Dictionary = params["beats"][0]
	var b: Dictionary = params["beats"][1]
	var out: Array = []
	for first in DailyModules.make(a["module"]).plans(a["params"], words):
		for second in DailyModules.make(b["module"]).plans(b["params"], words):
			var cubes := {}
			for name in first["cubes"]: cubes["1: " + name] = first["cubes"][name]
			for name in second["cubes"]: cubes["2: " + name] = second["cubes"][name]
			out.append({"label": first["label"] + "; then " + second["label"], "cubes": cubes, "beats": [first, second]})
	return out

func score_parts(params: Dictionary, words: PackedStringArray) -> Dictionary:
	var sum := {"search": 0.0, "steps": 0.0, "concept": 0.0, "execution": 0.0, "decoys": 0.0, "plans": 1}
	for beat in params["beats"]:
		var part := DailyModules.make(beat["module"]).score_parts(beat["params"], words)
		sum["plans"] *= int(part["plans"])
		for key in ["search", "steps", "execution", "decoys"]: sum[key] += float(part[key])
		sum["concept"] = maxf(float(sum["concept"]), float(part["concept"]))
	sum["concept"] += DailyDifficulty.EXTRA_BEAT_CONCEPT
	if bool(params.get("reuse", false)):
		sum["concept"] += DailyDifficulty.REUSED_CUBE_CONCEPT
		sum["steps"] += 1.0
	return sum

func build(k: RoomKit, room: Room, x0: int, _x1: int, params: Dictionary, words: PackedStringArray) -> Dictionary:
	var built: Array = []
	var cubes := {}
	var x := x0
	for i in params["beats"].size():
		var beat: Dictionary = params["beats"][i]
		var module := DailyModules.make(beat["module"])
		var end := x + module.columns(beat["params"]) - 1
		var before := room.get_children()
		var part := module.build_beat(k, room, x, end, beat["params"], words)
		if not part.has("gate"):
			part["gate"] = k.gate(room, "Beat%dGate" % (i + 1), end)
		# A chain has one outer shell. Close the space above its internal
		# doorway too: a portable cube otherwise makes the low gate jumpable.
		if i < params["beats"].size() - 1:
			for row in range(RoomKit.HIGH_CEIL, 6): k.solid(end, row)
		part["c0"] = x
		part["c1"] = end
		var steps: Array = []
		for child in room.get_children():
			if child is ObjectiveStep and not before.has(child): steps.append(child)
		part["steps"] = steps
		part["module"] = module
		built.append(part)
		for name in part["cubes"]: cubes["%d: %s" % [i + 1, name]] = part["cubes"][name]
		x = end
	if bool(params.get("reuse", false)):
		var first: RuneCube = built[0]["cubes"].values()[0]
		var second: RuneCube = built[1]["cubes"].values()[0]
		built[1]["reuse_position"] = second.position
		first.carryable = true
		first.mounted = false
		# This chain has only one cube. Its doorway is anchored in world
		# space, so it must be possible to carry that cube through the fold.
		if built[0]["module"].id == "folded_wall":
			first.set_meta(&"daily_portal_carry", true)
		built[0]["original_lock"] = first.locked_slots
		for step in built[1]["steps"]:
			if step.target != second: continue
			if built[1]["module"].id == "updraft" and step.condition == ObjectiveStep.Condition.POWERED:
				var source := LiftSource.new()
				source.cube = first
				source.left = float(built[1]["c0"] * RoomKit.T)
				source.right = float(built[1]["c1"] * RoomKit.T)
				room.add_child(source)
				step.target = source
			else:
				step.target = first
		for name in built[1]["cubes"]:
			if built[1]["cubes"][name] == second: built[1]["cubes"][name] = first
		for name in cubes:
			if cubes[name] == second: cubes[name] = first
		second.queue_free()
	var carry_help := ""
	if params.get("reuse", false):
		carry_help = " Carry the first cube to the second passage and carve it again."
		if built[0]["module"].id == "folded_wall":
			carry_help = " Carry the active portal cube through its doorway. Set it down, switch it off and carve the second rune."
	k.guide(room, objective + carry_help)
	return {"cubes": cubes, "beats": built, "gate": built[-1]["gate"], "phase": 0, "reuse": params.get("reuse", false)}

func perform(pieces: Dictionary, plan: Dictionary) -> String:
	pieces["plan"] = plan
	pieces["phase"] = 0
	return pieces["beats"][0]["module"].perform(pieces["beats"][0], plan["beats"][0])

func drive(pieces: Dictionary) -> Dictionary:
	return pieces["beats"][0]["module"].drive(pieces["beats"][0])

func advance(pieces: Dictionary, player: CharacterBody2D, elapsed: float) -> void:
	var phase: int = pieces["phase"]
	var part: Dictionary = pieces["beats"][phase]
	part["module"].advance(part, player, elapsed)
	if phase == 0 and part["steps"].all(func(step): return step.done):
		for action in ["move_left", "move_right", "jump", "sprint"]: Input.action_release(action)
		pieces["phase"] = 1
		part = pieces["beats"][1]
		if pieces["reuse"]:
			var cube: RuneCube = part["cubes"].values()[0]
			cube.deactivate()
			cube.global_position = part["reuse_position"]
		part["module"].perform(part, pieces["plan"]["beats"][1])
		var driving: Dictionary = part["module"].drive(part)
		if not driving.is_empty():
			player.teleport_to(driving["teleport"])
			for action in driving.get("hold", []): Input.action_press(action)
		else:
			var target: Node2D = part["cubes"].values()[0]
			player.teleport_to(target.global_position + Vector2(-64, 0))


func update_runtime(pieces: Dictionary) -> void:
	if pieces.get("reuse", false):
		var first: Dictionary = pieces["beats"][0]
		var cube: RuneCube = first["cubes"].values()[0]
		cube.locked_slots = 0 if first["steps"].all(func(step): return step.done) else int(first["original_lock"])
	for beat in pieces["beats"]:
		beat["module"].update_runtime(beat)
		var complete: bool = beat["steps"].all(func(step): return step.done)
		if complete:
			beat["gate"].set_powered(true)
		elif beat.has("finish_step"):
			# Merely reaching the far bank must not override the crossing's
			# magical prerequisite (revealed stones, bridge, frozen piston).
			beat["gate"].set_powered(false)


class LiftSource extends Node:
	var cube: RuneCube
	var left := 0.0
	var right := 0.0
	func is_powered() -> bool:
		return is_instance_valid(cube) and cube.is_active and not cube.is_carried \
			and is_instance_valid(cube.effect) and cube.recipe.essence == &"wind" \
			and cube.recipe.form == &"lift" and cube.recipe.direction == &"up" \
			and cube.global_position.x >= left and cube.global_position.x < right
