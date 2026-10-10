class_name DailyDifficulty
extends RefCounted

## How hard a generated room is, measured from its data (no playtest needed),
## and what each named difficulty asks for. The game is about reasoning, so
## difficulty mostly means how much thinking a room needs:
##   search     bits of guessing: log2(the sentences the open slots allow /
##              the ones that work). Locks shrink it; a bigger vocabulary
##              grows it; more ways through shrink it.
##   steps      how many things the easiest way needs to have right (cubes to
##              carve, cubes to carry).
##   concept    how deep the idea is (the module says: a push is 1, two winds
##              adding up or lift-not-push is 2).
##   execution  physical demand, kept low on purpose (riding a column of wind).
##   decoys     pieces that mislead.
## R = the weighted sum (WEIGHTS). Every named difficulty is a band of R that
## the generator aims each room at (DailyGenerator), and the Endless mode
## ramps up through them (ramp()). See docs/PROCGEN_DESIGN.md.

const NAMES := ["Gentle", "Steady", "Hard", "Grand", "Master"]
## The weight of each part of R (tune here; see the calibration notes in the
## design doc).
const WEIGHTS := {"search": 1.0, "steps": 0.8, "concept": 1.0, "execution": 0.5, "decoys": 0.6}
## The band of R each difficulty aims its rooms at, 1 (Gentle) to 5 (Master).
## Calibrated against what the module library can make at each word tier
## (tests/daily_suite.gd, "difficulty", prints the spread).
const BANDS := [Vector2(1.5, 3.0), Vector2(3.0, 4.0), Vector2(4.5, 6.7), Vector2(5.3, 7.0), Vector2(6.0, 9.5)]
## The word tier each difficulty lends (DailyKit). More words mean more to
## search, so R jumps with the tier; Gentle and Steady share the first and
## differ by how much of each sentence is carved.
const TIERS := [1, 1, 2, 3, 4]
const MAX_LEVEL := 5.0
## The Endless ramp: a quarter step every RAMP_EVERY rooms, at most a full step
## above the difficulty picked.
const RAMP_EVERY := 5
const RAMP_STEP := 0.25
const RAMP_MAX := 1.0


## The band of R for a level (1.0..5.0; between two named difficulties it is
## interpolated).
static func band(level: float) -> Vector2:
	var l := clampf(level, 1.0, MAX_LEVEL)
	var lo := int(floor(l)) - 1
	var hi := mini(lo + 1, BANDS.size() - 1)
	var t: float = l - floor(l)
	return BANDS[lo].lerp(BANDS[hi], t)


## The parts of R for a room (see the class notes).
static func parts(module: DailyModule, params: Dictionary, kit: PackedStringArray) -> Dictionary:
	return module.score_parts(params, kit)


## R from its parts.
static func total(room_parts: Dictionary) -> float:
	var r := 0.0
	for key in WEIGHTS:
		r += float(WEIGHTS[key]) * float(room_parts.get(key, 0.0))
	return r


## R of one generated room entry ({module, params}) with a vocabulary.
static func room_score(room: Dictionary, kit: PackedStringArray) -> float:
	var module := DailyModules.make(String(room["module"]))
	if module == null:
		return 0.0
	return total(parts(module, room["params"], kit))


## How far R is from a band (0 inside it).
static func miss(r: float, b: Vector2) -> float:
	if r < b.x:
		return b.x - r
	if r > b.y:
		return r - b.y
	return 0.0


## The level of the Endless mode's room `k` (0-based) for a run begun at
## `start` (1..4).
static func ramp(start: int, k: int) -> float:
	var up := minf(RAMP_MAX, RAMP_STEP * floor(float(maxi(k, 0)) / RAMP_EVERY))
	return minf(float(start) + up, MAX_LEVEL)


## The word tier a level uses: the named difficulty it has reached.
static func tier_for(level: float) -> int:
	return TIERS[clampi(int(floor(level + 0.001)), 1, TIERS.size()) - 1]


## Whether rooms at this level keep their chalk waymarks (Grand and above
## leave the way to the player).
static func guided(level: float) -> bool:
	return level < 4.0


## "Steady", or "Steady +2" a couple of quarter steps above it.
static func name_of(level: float) -> String:
	var l := clampf(level, 1.0, MAX_LEVEL)
	var base := int(floor(l + 0.001))
	var quarters := int(round((l - base) * 4.0))
	var text: String = NAMES[base - 1]
	return text if quarters <= 0 else "%s +%d" % [text, quarters]
