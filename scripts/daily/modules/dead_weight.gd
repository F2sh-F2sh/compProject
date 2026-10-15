class_name DeadWeightModule
extends DailyModule

## Dead Weight: a stone block that one normal wind only strains against (a
## stone needs 1470 force to start, a normal wind is 1200), a plate that only
## stone presses, a fixed cube blowing at it and a loose cube lying past the
## plate (the story's Observatory Room 2, "Too Heavy for One").
##
## Two ways to move it, and both are real:
##   one strong wind (2400) from the fixed cube, or
##   two winds stacked: carry the loose cube beside the fixed one and switch
##   both on (1200 + 1200).
##
## Parameters
##   gap  columns from the fixed cube to the stone (2..3)
##   run  columns from the stone to the kerb (3..5)
##   lock 0: only the fixed cube's modifier is open; 1: its direction too
##   guided  chalk waymarks on the walls (off at Grand and above)
##
## The layouts a plan is claimed for are the ones the physics sweep
## (tests/daily_suite.gd) measured to work with room to spare; see VERIFIED.

## "gap/run" of the layouts proven to work, for both plans.
const VERIFIED := ["2/3", "2/4", "2/5", "3/3", "3/4", "3/5"]


func _init() -> void:
	id = "dead_weight"
	title = "Dead Weight"
	objective = "Move the stone block onto the heavy plate."
	min_tier = 1
	par_seconds = 70.0


func columns(params: Dictionary) -> int:
	return 15 + int(params["gap"]) + int(params["run"])


func sample(rng: DailyRng, _difficulty: int, _tier: int) -> Dictionary:
	var layouts := VERIFIED.duplicate()
	var pick: String = rng.pick(layouts)
	return {"gap": int(pick.get_slice("/", 0)), "run": int(pick.get_slice("/", 1)), "mirror": false, "lock": rng.int_range(0, 1)}


func fallback(_tier: int) -> Dictionary:
	return {"gap": 3, "run": 5, "mirror": false, "lock": 0}


func plans(params: Dictionary, kit: PackedStringArray) -> Array:
	if not DailyVerified.bypass: return DailyVerified.plans(id, params, kit)
	return raw_plans(params, kit)


func raw_plans(params: Dictionary, kit: PackedStringArray) -> Array:
	var out: Array = []
	var layout := "%d/%d" % [params["gap"], params["run"]]
	if not VERIFIED.has(layout) or not kit.has("wind") or not kit.has("push") or not kit.has("right"):
		return out
	if kit.has("strong"):
		out.append({"label": "One strong wind", "cubes": {"Fixed Cube": "wind/push/right/strong"}})
	if kit.has("normal"):
		out.append({"label": "Two winds together", "cubes": {
			"Fixed Cube": "wind/push/right/normal", "Loose Cube": "wind/push/right/normal"}})
	return out


func concept_of(_params: Dictionary) -> float:
	return 2.0


func open_slots(params: Dictionary) -> Dictionary:
	var fixed: Array = [RuneFragments.Kind.MODIFIER]
	if int(params.get("lock", 0)) == 1:
		fixed = [RuneFragments.Kind.DIRECTION, RuneFragments.Kind.MODIFIER]
	return {"Fixed Cube": fixed, "Loose Cube": [RuneFragments.Kind.DIRECTION, RuneFragments.Kind.MODIFIER]}


## Two winds means carrying the loose cube as well.
func plan_steps(plan: Dictionary) -> float:
	return float(plan["cubes"].size()) + (1.0 if plan["cubes"].has("Loose Cube") else 0.0)


func non_plans(params: Dictionary, kit: PackedStringArray) -> Array:
	var out: Array = []
	if kit.has("normal"):
		out.append({"label": "One normal wind strains and fails", "cubes": {"Fixed Cube": "wind/push/right/normal"}})
	return out


## What a player does for a plan: carries the loose cube beside the fixed one
## when the plan uses it, and switches the cubes on.
func perform(pieces: Dictionary, plan: Dictionary) -> String:
	var cubes: Dictionary = pieces["cubes"]
	if plan["cubes"].has("Loose Cube"):
		var fixed: Node2D = cubes["Fixed Cube"]
		var loose: Node2D = cubes["Loose Cube"]
		loose.global_position = fixed.global_position + Vector2(-36, 0)
	var problem := ""
	for cube_name in plan["cubes"]:
		var cube: RuneCube = cubes[cube_name]
		cube.recipe = RuneRecipe.from_key(plan["cubes"][cube_name])
		var err := cube.activate(false)
		if err != "":
			problem = err
	return problem


func build(k: RoomKit, room: Room, x0: int, x1: int, params: Dictionary, _words: PackedStringArray) -> Dictionary:
	var gap: int = params["gap"]
	var run: int = params["run"]
	var fixed_col := x0 + 4
	var stone_col := fixed_col + gap
	var kerb_col := stone_col + run
	var loose_col := kerb_col + 5
	k.curb(kerb_col)
	if params.get("guided", true):
		k.waymarks(room, x0, x1)
	var lock := int(params.get("lock", 0))

	var fixed := k.cube(room, "Fixed Cube", RoomKit.cx(fixed_col), "wind/push/right/-" if lock == 0 else "wind/push/-/-",
		{"dungeon_powered": true, "carryable": false,
		"locked_slots": RoomKit.LOCK_ESSENCE | RoomKit.LOCK_FORM | (RoomKit.LOCK_DIRECTION if lock == 0 else 0)})
	var block := k.stone(room, "Stone", RoomKit.cx(stone_col))
	var plate := k.plate(room, "StonePlate", kerb_col * RoomKit.T - 48.0, {"stone_only": true, "width": 48.0})
	var loose := k.cube(room, "Loose Cube", RoomKit.cx(loose_col), "wind/push/left/normal",
		{"dungeon_powered": true, "locked_slots": RoomKit.LOCK_ESSENCE | RoomKit.LOCK_FORM})
	var exit_gate := k.gate(room, "ExitGate", x1)
	k.circuit(room, "PlateToGate", [plate], [exit_gate], {"reveal_target": true, "channel_y": 440.0, "symbol": 1})
	k.guide(room, objective)
	k.step(room, "A wind pushes at the stone", ObjectiveStep.Condition.POWERED, fixed)
	k.step(room, "The stone on the plate: the gate opens", ObjectiveStep.Condition.OPEN, exit_gate)
	k.hint(room, Vector2(RoomKit.cx(x0 + 1) + 20, RoomKit.FLOOR_Y), [
		"The stone is heavier than a crate. One ordinary wind only makes it strain.",
		"A stronger wind would move it. So would two winds together: another cube lies at the far end, and cubes can be carried.",
		"Either inscribe Strong on the fixed cube, or carry the far cube ({rune_carry}) beside it, point it the same way, and switch both on.",
	], [fixed, block, loose])
	var signs := k.group(room, "Signs")
	k.inst("res://scenes/tutorial_sign.tscn", signs, "Carry", Vector2(RoomKit.cx(loose_col - 2), RoomKit.FLOOR_Y - 78.0),
		{"text": "{rune_carry}: pick up a cube that is off, and set it down where its outline shows.", "width": 190.0})
	var deco := k.group(room, "Decor")
	for col in [x0 + 3, x0 + 9, x1 - 3]:
		k.torch(deco, col)
	return {"cubes": {"Fixed Cube": fixed, "Loose Cube": loose}, "gate": exit_gate, "plate": plate, "stone": block}
