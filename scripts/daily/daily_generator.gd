class_name DailyGenerator
extends RefCounted

## Composes a generated puzzle: rooms drawn from the module library, each with
## parameters inside its envelope and aimed at a difficulty band
## (DailyDifficulty), then a bell hall (a daily puzzle) or a stair out (one
## room of the Endless mode). The result is plain data (a Dictionary), the
## same for the same inputs on every machine, and is checked by DailyOracle
## before anything is built.
##
## How a room is drawn: up to SALTS times, pick a module (not the one before),
## sample its knobs, and keep the draw if it has at least two ways through and
## its difficulty score R lies in the band. If none lands in the band, the
## closest draw with two ways is kept; if none has two ways, the module's
## hand-checked fallback. It never hands back a room that fails the oracle.

## Bump when the generator changes what a seed produces: it is mixed into the
## seed and the share code, so an old date's puzzle never silently changes.
##   1  first daily puzzle
##   2  rooms aimed at a difficulty band; lock and waymark knobs
const GEN_VERSION := 2
## Rooms by difficulty 1..4 (not counting the bell hall).
const ROOMS := [3, 4, 4, 5]
const BELL_COLUMNS := 10
## The Endless mode's stair out of each room.
const EXIT_COLUMNS := 7
const SALTS := 16


## The seed of a day (a day_index from DailyRng).
static func seed_for_day(day_index: int) -> int:
	return DailyRng.fnv("belfry-daily|v%d|%d" % [GEN_VERSION, day_index])


## Monday and Tuesday are gentle; Sunday is the grand puzzle.
static func difficulty_for_day(day_index: int) -> int:
	match DailyRng.weekday(day_index):
		1, 2:
			return 1
		3, 4:
			return 2
		5, 6:
			return 3
	return 4


## The vocabulary tier a difficulty uses.
static func tier_for_difficulty(difficulty: int) -> int:
	return DailyDifficulty.tier_for(float(difficulty))


## {"seed", "difficulty", "tier", "kit": words, "rooms": [{module, params, r,
## x0, x1}], "bell": {x0, x1}, "version", "digest"}
static func generate(seed_value: int, difficulty: int, tier: int) -> Dictionary:
	var rng := DailyRng.new(seed_value)
	var kit := DailyKit.words(tier)
	var count: int = ROOMS[clampi(difficulty, 1, ROOMS.size()) - 1]
	var rooms: Array = []
	var x := 0
	var previous := ""
	for i in count:
		var room := draw_room(rng.fork("room%d" % i), float(difficulty), tier, kit, previous)
		var module := DailyModules.make(String(room["module"]))
		room["x0"] = x
		room["x1"] = x + module.columns(room["params"]) - 1
		rooms.append(room)
		x = room["x1"]
		previous = room["module"]
	var spec := {
		"seed": seed_value,
		"difficulty": difficulty,
		"tier": tier,
		"version": GEN_VERSION,
		"kit": kit,
		"rooms": rooms,
		"bell": {"x0": x, "x1": x + BELL_COLUMNS - 1},
	}
	spec["digest"] = digest_of(spec)
	return spec


## One room of an Endless run: room `k` (0-based) of a run with `run_seed`,
## begun at difficulty `start`, after a room of module `previous`. The level
## ramps up as the run goes on (DailyDifficulty.ramp). Instead of a bell hall
## it ends in a stair out ("exit").
static func endless_room(run_seed: int, k: int, start: int, previous := "") -> Dictionary:
	var level := DailyDifficulty.ramp(start, k)
	var tier := DailyDifficulty.tier_for(level)
	var kit := DailyKit.words(tier)
	var room_seed := DailyRng.new(run_seed).fork("room%d" % k).next_u32()
	var room := draw_room(DailyRng.new(room_seed), level, tier, kit, previous)
	var module := DailyModules.make(String(room["module"]))
	room["x0"] = 0
	room["x1"] = module.columns(room["params"]) - 1
	var spec := {
		"seed": room_seed,
		"difficulty": clampi(int(floor(level + 0.001)), 1, 4),
		"level": level,
		"tier": tier,
		"version": GEN_VERSION,
		"kit": kit,
		"rooms": [room],
		"bell": {},
		"exit": {"x0": room["x1"], "x1": room["x1"] + EXIT_COLUMNS - 1},
		"endless": true,
	}
	spec["digest"] = digest_of(spec)
	return spec


## A room aimed at `level`'s band: {module, params, r}.
static func draw_room(draw: DailyRng, level: float, tier: int, kit: PackedStringArray, previous: String) -> Dictionary:
	var target := DailyDifficulty.band(level)
	var candidates := DailyModules.ids_for_tier(tier)
	var best := {}
	var best_miss := INF
	for salt in SALTS:
		var attempt := draw.fork("salt%d" % salt)
		var pool := candidates.duplicate()
		if pool.size() > 1:
			pool.erase(previous)
		var id: String = attempt.pick(pool)
		var m := DailyModules.make(id)
		var p := m.sample(attempt, int(round(level)), tier)
		p["guided"] = DailyDifficulty.guided(level)
		if m.plans(p, kit).size() < DailyOracle.MIN_PLANS:
			continue
		var r := DailyDifficulty.total(m.score_parts(p, kit))
		var miss := DailyDifficulty.miss(r, target)
		if miss < best_miss:
			best_miss = miss
			best = {"module": id, "params": p, "r": snappedf(r, 0.01)}
		if miss == 0.0:
			break
	if best.is_empty():
		var id := String(candidates[0])
		var m := DailyModules.make(id)
		var p := m.fallback(tier)
		p["guided"] = DailyDifficulty.guided(level)
		best = {"module": id, "params": p, "r": snappedf(DailyDifficulty.total(m.score_parts(p, kit)), 0.01)}
	return best


## A short fingerprint of what a spec builds (the same spec, the same digest).
static func digest_of(spec: Dictionary) -> int:
	var plain := {"seed": spec["seed"], "difficulty": spec["difficulty"], "tier": spec["tier"],
		"version": spec["version"], "rooms": spec["rooms"], "bell": spec["bell"]}
	return DailyRng.fnv(JSON.stringify(plain, "", true))
