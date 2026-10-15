class_name DailyModule
extends RefCounted

## One kind of puzzle room a daily puzzle is made from: a template with a
## bounded envelope of parameters, built from pieces the story's rooms already
## use and already proved solvable. A module can
##   sample()    pick parameters (from a seeded generator) inside its envelope;
##   plans()     list every way it can be solved with a given vocabulary (the
##               oracle needs at least two, and the end card says how many);
##   build()     put its pieces into a room.
## A room is cleared by what happens in the world (a plate pressed, a gate
## opened), never by matching a stored answer: any sentence that works counts.

## "gust_alley"
var id := ""
var title := ""
## The goal shown in the objective panel (never the solution).
var objective := ""
## The lowest vocabulary tier it can be built from (see DailyKit).
var min_tier := 1
## About how long a careful player takes, in seconds (the score's par).
var par_seconds := 60.0


## How many columns of wall to wall the room needs, inclusive.
func columns(_params: Dictionary) -> int:
	return 19


## Parameters inside the envelope, drawn from `rng`.
func sample(_rng: DailyRng, _difficulty: int, _tier: int) -> Dictionary:
	return {}


## Parameters that always work (checked by hand and by the tests), used when
## sampling keeps failing.
func fallback(_tier: int) -> Dictionary:
	return {}


## Every way to solve it with `kit`, as [{"label": text, "cubes": {cube name:
## sentence key}}]. Only what is known to work is claimed.
func plans(_params: Dictionary, _kit: PackedStringArray) -> Array:
	return []


## Sentences the kit allows that are known NOT to solve it (for the tests'
## precision check).
func non_plans(_params: Dictionary, _kit: PackedStringArray) -> Array:
	return []


## Puts the room's pieces in `room` (columns x0..x1). Returns the pieces the
## tests drive: {"cubes": {name: node}, "gate": node, ...}.
func build(_kit: RoomKit, _room: Room, _x0: int, _x1: int, _params: Dictionary, _words: PackedStringArray) -> Dictionary:
	return {}


## What a player does to carry out `plan` in the room `build()` made: puts
## each sentence on its cube and switches it on (a module that needs more,
## such as carrying a cube, overrides this). Used by the tests to prove, in
## the real physics, that a plan the oracle predicts really solves the room.
## Returns "" or the refusal the rune book gave.
func perform(pieces: Dictionary, plan: Dictionary) -> String:
	var problem := ""
	for cube_name in plan["cubes"]:
		var cube: RuneCube = pieces["cubes"][cube_name]
		cube.recipe = RuneRecipe.from_key(plan["cubes"][cube_name])
		var err := cube.activate(false)
		if err != "":
			problem = err
	return problem


## The most mana a plan can need, for the oracle (0 = dungeon powered).
func mana_needed(_params: Dictionary, _recipe_key: String) -> int:
	return 0


## The room's ceiling row: RoomKit.LOW_CEIL, or HIGH_CEIL for a tall room.
func ceiling_row() -> int:
	return RoomKit.LOW_CEIL


## What the player must do besides inscribing the cubes (the tests do it for
## her): {"teleport": where to stand, "hold": [actions], "tap": [actions]},
## or {} when the cubes are all there is.
func drive(_pieces: Dictionary) -> Dictionary:
	return {}


# ------------------------------------------------------------------ difficulty
# (what DailyDifficulty measures; see its notes)

## How deep the idea is (1 a plain push, 2 two winds adding up or lift not
## push, 3 reflecting or folding space).
func concept_of(_params: Dictionary) -> float:
	return 1.0


## The slots the player has to choose, per cube: {cube name: [RuneFragments.Kind]}.
func open_slots(_params: Dictionary) -> Dictionary:
	return {}


## How many things a plan needs to have right (cubes to carve; a module whose
## plan carries a cube adds it).
func plan_steps(plan: Dictionary) -> float:
	return float(plan["cubes"].size())


## Physical demand (riding a column of wind, timing).
func execution_of(_params: Dictionary) -> float:
	return 0.0


## Pieces that mislead.
func decoys_of(_params: Dictionary) -> float:
	return 0.0


## The parts of the difficulty score R for these parameters and words:
## {"search", "steps", "concept", "execution", "decoys", "plans"}.
func score_parts(params: Dictionary, kit: PackedStringArray) -> Dictionary:
	var open := open_slots(params)
	var all_plans := plans(params, kit)
	# The choices each cube's open slots allow with these words
	var choices := {}
	var total := 1.0
	for cube_name in open:
		var n := 1.0
		for kind in open[cube_name]:
			n *= maxf(1.0, float(words_of_kind(kit, int(kind))))
		choices[cube_name] = n
		total *= n
	# The settings that solve it: each plan fixes its own cubes and leaves the
	# others free
	var working := 0.0
	var fewest_steps := INF
	for plan in all_plans:
		var free := 1.0
		for cube_name in choices:
			if not plan["cubes"].has(cube_name):
				free *= choices[cube_name]
		working += free
		fewest_steps = minf(fewest_steps, plan_steps(plan))
	var search := 0.0
	if working > 0.0:
		search = maxf(0.0, log(total / minf(working, total)) / log(2.0))
	return {
		"search": search,
		"steps": fewest_steps if fewest_steps != INF else 1.0,
		"concept": concept_of(params),
		"execution": execution_of(params),
		"decoys": decoys_of(params),
		"plans": all_plans.size(),
	}


## How many of the kit's words are of a kind (essence, form, direction, modifier).
static func words_of_kind(kit: PackedStringArray, kind: int) -> int:
	var n := 0
	for w in kit:
		if RuneFragments.kind_of(StringName(w)) == kind:
			n += 1
	return n


## A beat owns its own puzzle gate, but never builds another shell.
func build_beat(k: RoomKit, room: Room, c0: int, c1: int, params: Dictionary, words: PackedStringArray) -> Dictionary:
	return build(k, room, c0, c1, params, words)

## Optional deterministic physical driver, used only by verification tools.
func advance(_pieces: Dictionary, _player: CharacterBody2D, _elapsed: float) -> void:
	pass


func update_runtime(_pieces: Dictionary) -> void:
	pass
