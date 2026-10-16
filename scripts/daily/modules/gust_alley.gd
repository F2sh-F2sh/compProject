class_name GustAlleyModule
extends DailyModule

## Gust Alley: blow a crate along the floor onto a plate to open the gate
## (based on the Observatory's first room).
##
## Parameters: mirror (blow left instead of right), lock (0: choose direction
## and modifier, 1: form and modifier, 2: only the modifier), guided (chalk
## waymarks), gap (cube to crate, 2-3 columns), run (crate to kerb, 3-5).
##
## Measured in the physics (the daily suite's "sweep"): wind pushes the crate
## while it is within 320 px of the cube (560 with Long), then it coasts about
## 81 px (Normal) or 153 px (Strong). The crate must travel run * 64 - 111 px;
## a sentence only counts if it gets there with a margin.

const PUSH_MODIFIERS := ["normal", "strong", "long", "large"]
const REACH := 320.0
const LONG_REACH := 560.0
const COAST_NORMAL := 81.0
const COAST_STRONG := 153.0
## Pixels to spare before a sentence is claimed to work.
const MARGIN := 12.0


func _init() -> void:
	id = "gust_alley"
	title = "Gust Alley"
	objective = "Open the gate at the far end."
	min_tier = 1
	par_seconds = 45.0


func columns(params: Dictionary) -> int:
	return 10 + int(params["gap"]) + int(params["run"])


func sample(rng: DailyRng, _difficulty: int, _tier: int) -> Dictionary:
	var gap := rng.int_range(2, 3)
	# A wider gap leaves the wind less time to push, so the kerb is nearer
	var run := rng.int_range(3, 5 if gap == 2 else 4)
	return {"mirror": rng.chance(0.5), "lock": rng.int_range(0, 2), "gap": gap, "run": run}


func fallback(_tier: int) -> Dictionary:
	return {"mirror": false, "lock": 0, "gap": 2, "run": 4}


## The direction the wind has to blow.
func heading(params: Dictionary) -> String:
	return "left" if params["mirror"] else "right"


## How far the crate travels from its start with this modifier.
static func travel(modifier: String, gap: int) -> float:
	var reach := LONG_REACH if modifier == "long" else REACH
	var coast := COAST_STRONG if modifier == "strong" else COAST_NORMAL
	return reach - 64.0 * gap + coast


## How far it has to travel to rest on the plate.
static func needed(run: int) -> float:
	return run * 64.0 - 111.0


func plans(params: Dictionary, kit: PackedStringArray) -> Array:
	if not DailyVerified.bypass: return DailyVerified.plans(id, params, kit)
	return raw_plans(params, kit)


func raw_plans(params: Dictionary, kit: PackedStringArray) -> Array:
	var out: Array = []
	var way := heading(params)
	for modifier in PUSH_MODIFIERS:
		var key := "wind/push/%s/%s" % [way, modifier]
		# The heading is carved into the cube when `lock` is 1, so it need not
		# be a word the player knows; the modifier always has to be.
		var words_ok := kit.has("wind") and kit.has("push") and kit.has(modifier) and (int(params["lock"]) != 0 or kit.has(way))
		if not words_ok or not RuneBook.is_valid(RuneRecipe.from_key(key)):
			continue
		if travel(modifier, int(params["gap"])) < needed(int(params["run"])) + MARGIN:
			continue
		out.append({"label": "Push %s, %s" % [way, modifier], "cubes": {"Gust Cube": key}})
	return out


func open_slots(params: Dictionary) -> Dictionary:
	var kinds: Array = [[RuneFragments.Kind.DIRECTION, RuneFragments.Kind.MODIFIER],
		[RuneFragments.Kind.FORM, RuneFragments.Kind.MODIFIER], [RuneFragments.Kind.MODIFIER]][int(params["lock"])]
	return {"Gust Cube": kinds}


func non_plans(params: Dictionary, kit: PackedStringArray) -> Array:
	var out: Array = []
	var wrong := "right" if params["mirror"] else "left"
	for modifier in PUSH_MODIFIERS:
		if kit.has(modifier) and kit.has(wrong):
			out.append({"label": "Push the wrong way (%s)" % wrong, "cubes": {"Gust Cube": "wind/push/%s/%s" % [wrong, modifier]}})
	return out


func build(k: RoomKit, room: Room, x0: int, x1: int, params: Dictionary, _words: PackedStringArray) -> Dictionary:
	var mirror: bool = params["mirror"]
	var gap: int = params["gap"]
	var run: int = params["run"]
	var way := heading(params)
	# Columns of the pieces
	var kerb_col: int
	var crate_col: int
	var cube_col: int
	var plate_x: float
	if not mirror:
		cube_col = x0 + 4
		crate_col = cube_col + gap
		kerb_col = crate_col + run
		plate_x = kerb_col * RoomKit.T - 42.0
	else:
		kerb_col = x0 + 4
		crate_col = kerb_col + run
		cube_col = crate_col + gap
		plate_x = (kerb_col + 1) * RoomKit.T + 42.0
	k.curb(kerb_col)
	if params.get("guided", true):
		k.waymarks(room, x0, x1)

	var lock := int(params["lock"])
	var locks := RoomKit.LOCK_ESSENCE | (RoomKit.LOCK_FORM if lock == 0 else RoomKit.LOCK_DIRECTION)
	var recipe := "wind/push/-/-" if lock == 0 else "wind/-/%s/-" % way
	if lock == 2:
		locks = RoomKit.LOCK_ESSENCE | RoomKit.LOCK_FORM | RoomKit.LOCK_DIRECTION
		recipe = "wind/push/%s/-" % way
	var cube := k.cube(room, "Gust Cube", RoomKit.cx(cube_col), recipe,
		{"dungeon_powered": true, "carryable": false, "locked_slots": locks})
	var box := k.crate(room, "Crate", RoomKit.cx(crate_col))
	var plate := k.plate(room, "CratePlate", plate_x, {"objects_only": true})
	var exit_gate := k.gate(room, "ExitGate", x1)
	k.circuit(room, "PlateToGate", [plate], [exit_gate], {"reveal_target": true, "channel_y": 440.0, "symbol": 0})
	k.guide(room, objective)
	k.step(room, "The cube's wind blows", ObjectiveStep.Condition.POWERED, cube)
	k.step(room, "The crate on the plate: the gate opens", ObjectiveStep.Condition.OPEN, exit_gate)
	var open_text: String = ["direction and modifier", "form and modifier", "modifier"][lock]
	k.hint(room, Vector2(RoomKit.cx(x0 + 1) + 20, RoomKit.FLOOR_Y), [
		"Use the cube to read its rune. Some quadrants are open.",
		"The crate has to reach the plate, and the cube blows wind. Which way must it blow, and how hard?",
		"Fill the open quadrants (%s) so the wind pushes toward the plate, then switch the cube on." % open_text,
	], [cube, box])
	var deco := k.group(room, "Decor")
	for col in [x0 + 3, x0 + 9, x1 - 3]:
		k.torch(deco, col)
	return {"cubes": {"Gust Cube": cube}, "gate": exit_gate, "plate": plate, "crate": box}
