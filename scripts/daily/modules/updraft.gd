class_name UpdraftModule
extends DailyModule

## Updraft: a wall of stone higher than a charged jump, a cube whose direction
## is carved "up", and nothing else. Push can't blow upward (the rune book
## says so), Lift can: raise a column of wind, rise in it and drift onto the
## wall (the story's Observatory Room 3, "Across the Teeth", without the
## spikes). The exit is open once she is over the wall.
##
## Parameters
##   dist    columns from the cube to the wall (always 1: the wall stands right
##           beside the cube; one column further, only the wide Large column
##           reaches it, which would be a one-answer puzzle)
##   rows    wall height in tiles (3 or 4: 192 or 256 px; a charged jump is 132)
##   width   wall width in columns (3..4)
##   lock    0: the form and modifier are open (find Lift); 1: Lift is carved
##           too, only the modifier is open (the gentlest)
##   guided  chalk waymarks on the walls (off at Grand and above)
##   profile 0: level ridge; 1: descending steps; 2: a lower landing.
##           The first rise and its wind demand are identical in all three.
##
## Which sentences are claimed (VERIFIED) was measured in the real physics.

## "rows/dist": the sentences measured to work there, with room to spare.
const VERIFIED := {
	"3/1": ["normal", "strong", "long", "large"],

	"4/1": ["normal", "strong", "long", "large"],

}


func _init() -> void:
	id = "updraft"
	title = "Updraft"
	objective = "Get over the wall."
	min_tier = 1
	par_seconds = 50.0


func ceiling_row() -> int:
	return RoomKit.HIGH_CEIL


func columns(params: Dictionary) -> int:
	return 10 + int(params["dist"]) + int(params["width"])


func sample(rng: DailyRng, _difficulty: int, _tier: int) -> Dictionary:
	return {"dist": 1, "rows": rng.int_range(3, 4), "width": rng.int_range(3, 4), "mirror": false, "lock": rng.int_range(0, 1)}


func fallback(_tier: int) -> Dictionary:
	return {"dist": 1, "rows": 4, "width": 3, "mirror": false, "lock": 0}


func plans(params: Dictionary, kit: PackedStringArray) -> Array:
	if not DailyVerified.bypass: return DailyVerified.plans(id, params, kit)
	return raw_plans(params, kit)


func raw_plans(params: Dictionary, kit: PackedStringArray) -> Array:
	var out: Array = []
	var layout := "%d/%d" % [params["rows"], params["dist"]]
	if not VERIFIED.has(layout) or not kit.has("wind") or not kit.has("lift"):
		return out
	for modifier in VERIFIED[layout]:
		# (the direction, Up, is carved into the cube, so it need not be known)
		if kit.has(modifier):
			out.append({"label": "Lift, %s" % modifier, "cubes": {"Lift Cube": "wind/lift/up/%s" % modifier}})
	return out


## Lift-not-push is the idea; with Lift carved it is only a push upward.
func concept_of(params: Dictionary) -> float:
	return 1.0 if int(params.get("lock", 0)) == 1 else 2.0


func open_slots(params: Dictionary) -> Dictionary:
	if int(params.get("lock", 0)) == 1:
		return {"Lift Cube": [RuneFragments.Kind.MODIFIER]}
	return {"Lift Cube": [RuneFragments.Kind.FORM, RuneFragments.Kind.MODIFIER]}


## Stepping into the column and drifting onto the wall.
func execution_of(_params: Dictionary) -> float:
	return 1.0


func non_plans(_params: Dictionary, kit: PackedStringArray) -> Array:
	var out: Array = []
	if kit.has("push") and kit.has("normal"):
		# Push can't point up: the rune book refuses it
		out.append({"label": "Push can't blow up", "cubes": {"Lift Cube": "wind/push/up/normal"}})
	return out


## The player's part: stand in the column and hold right.
func drive(pieces: Dictionary) -> Dictionary:
	var cube: Node2D = pieces["cubes"]["Lift Cube"]
	return {"teleport": cube.global_position + Vector2(-6, -8), "hold": ["move_right"], "tap": []}


func build(k: RoomKit, room: Room, x0: int, x1: int, params: Dictionary, _words: PackedStringArray) -> Dictionary:
	var dist: int = params["dist"]
	var rows: int = params["rows"]
	var width: int = params["width"]
	var profile := int(params.get("profile", 0))
	var cube_col := x0 + 4
	var wall_c0 := cube_col + dist
	var top_row := 8 - rows
	# The wall: stone down to the floor, a cap on top (walkable)
	for x in range(wall_c0, wall_c0 + width):
		var cap := top_row
		if profile == 1: cap += mini(x - wall_c0, 2)
		elif profile == 2 and x > wall_c0: cap += 1
		k.ground.erase_cell(Vector2i(x, 8))
		for y in range(cap + 1, 9):
			k.solid(x, y)
		k.floor_tile(x, cap)
	if params.get("guided", true):
		k.waymarks(room, x0, x1)
	var carved := int(params.get("lock", 0)) == 1
	var cube := k.cube(room, "Lift Cube", RoomKit.cx(cube_col), "wind/lift/up/-" if carved else "wind/-/up/-",
		{"dungeon_powered": true, "carryable": false,
		"locked_slots": RoomKit.LOCK_ESSENCE | RoomKit.LOCK_DIRECTION | (RoomKit.LOCK_FORM if carved else 0)})
	var top_y := top_row * RoomKit.T + 22.0
	var area := Rect2(wall_c0 * RoomKit.T, top_y - 90.0, width * RoomKit.T, 90.0)
	k.guide(room, "Ride the wind onto the high step." if profile == 1 else ("Ride the wind onto the landing." if profile == 2 else objective))
	k.step(room, "The wind rises", ObjectiveStep.Condition.POWERED, cube)
	k.step(room, "On top of the wall", ObjectiveStep.Condition.REACHED, null, {"area": area})
	var lines := [
		"The wall is too high to jump, and the cube's direction is carved: Up.",
		"Push can't blow upward. Which form of wind can?",
		"Inscribe Lift as the cube's Form, pick a modifier, switch it on, then step into the wind and drift onto the wall.",
	]
	if carved:
		lines = [
			"The wall is too high to jump, and the cube is carved to lift upward.",
			"Only its modifier is open. Any that raises a column of wind will do.",
			"Pick a modifier, switch the cube on, then step into the wind and drift onto the wall.",
		]
	k.hint(room, Vector2(RoomKit.cx(x0 + 1) + 20, RoomKit.FLOOR_Y), lines, [cube])
	var deco := k.group(room, "Decor")
	for col in [x0 + 2, x1 - 2]:
		k.torch(deco, col)
	for col in [x0 + 9, wall_c0 + width - 1]:
		k.torch(deco, col, 1)
	return {"cubes": {"Lift Cube": cube}, "area": area}
