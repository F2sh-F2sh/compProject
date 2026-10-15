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
const GEN_VERSION := 10
## Rooms by difficulty 1..4 (not counting the bell hall).
const ROOMS := [3, 4, 4, 5]
const BELL_COLUMNS := 10
## The Endless mode's stair out of each room.
const EXIT_COLUMNS := 7
const SALTS := 16
static var _band_module_cache := {}
static var _score_cache := {}


## Fractional chains compare many salted draws of the same verified
## layouts. Reuse their pure scores without changing any random draws.
static func _score_parts(module: DailyModule, params: Dictionary, kit: PackedStringArray) -> Dictionary:
	if DailyVerified.bypass: return module.score_parts(params, kit)
	var key := module.id + "|" + JSON.stringify(params) + "|" + ",".join(kit)
	if not _score_cache.has(key):
		# Bound the cache during long runs and offline seed sweeps.
		if _score_cache.size() >= 4096: _score_cache.clear()
		_score_cache[key] = module.score_parts(params, kit)
	return _score_cache[key]


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
	var recent: Array = []
	for i in count:
		var room := draw_room(rng.fork("room%d" % i), float(difficulty), tier, kit, previous, recent)
		# Guarantee one real rune mechanism even on the easier days. Other
		# rooms retain physical solutions and explicitly allowed personal Fire.
		if i == 0 and difficulty == 1:
			room = _draw_single(rng.fork("required_room"), float(difficulty), tier, kit, previous, true)
		set_spell_rule(room, float(difficulty))
		var module := DailyModules.make(String(room["module"]))
		room["x0"] = x
		room["x1"] = x + module.columns(room["params"]) - 1
		place_beats(room, x)
		rooms.append(room)
		x = room["x1"]
		previous = last_module(room)
		recent.append(layout_key(room))
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
static func endless_room(run_seed: int, k: int, start: int, previous := "", recent: Array = []) -> Dictionary:
	var level := DailyDifficulty.ramp(start, k)
	var tier := DailyDifficulty.tier_for(level)
	var kit := DailyKit.words(tier)
	var room_seed := DailyRng.new(run_seed).fork("room%d" % k).next_u32()
	var room := draw_room(DailyRng.new(room_seed), level, tier, kit, previous, recent)
	set_spell_rule(room, level)
	var module := DailyModules.make(String(room["module"]))
	room["x0"] = 0
	room["x1"] = module.columns(room["params"]) - 1
	place_beats(room, 0)
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


## Fractional levels choose toward the middle of their interpolated band;
## otherwise a broad overlap can return the exact same draw as the base.
## Inside-band candidates always outrank outside ones.
static func _fit_cost(r: float, target: Vector2, level: float) -> float:
	var miss := DailyDifficulty.miss(r, target)
	if is_equal_approx(level, floor(level)): return miss
	var desired := (target.x + target.y) * 0.5
	# Named Grand/Master keep their broad in-band variety. Their measured
	# meaningful-choice means (11.1/12.9) sit above the band midpoints, so
	# target the ramp between those attainable means rather than dipping
	# back to an easier midpoint at Grand +1.
	if level > 4.0 and level < 5.0: desired = lerpf(11.1, 12.9, level - 4.0)
	return miss * 100.0 + absf(r - desired)


## Narrow fractional bands sometimes have only one suitable mechanism.
## Prefer a different mechanism when possible, but do not exclude the only
## suitable one and silently substitute a room easier than the base level.
static func _band_modules(candidates: Array, kit: PackedStringArray, target: Vector2, meaningful := false) -> Array:
	if DailyVerified.bypass: return candidates
	var key := ",".join(candidates) + "|" + ",".join(kit) + "|" + str(target) + str(meaningful)
	if _band_module_cache.has(key): return _band_module_cache[key]
	var eligible: Array = []
	DailyVerified.load_table()
	for id in candidates:
		var module := DailyModules.make(id)
		for params in DailyVerified.table.get("parameters", {}).get(id, {}).values():
			if meaningful and not meaningful_choice(module, params): continue
			if module.plans(params, kit).size() < DailyOracle.MIN_PLANS: continue
			var r := DailyDifficulty.total(_score_parts(module, params, kit))
			if DailyDifficulty.miss(r, target) < 0.001:
				eligible.append(id)
				break
	_band_module_cache[key] = eligible
	return eligible


## A room aimed at `level`'s band: {module, params, r}.
static func _draw_single(draw: DailyRng, level: float, tier: int, kit: PackedStringArray, previous: String, rune_required := false) -> Dictionary:
	var target := DailyDifficulty.band(level)
	var candidates := DailyModules.ids_for_tier(tier)
	if rune_required:
		candidates = candidates.filter(func(id): return id in ["updraft", "frozen_crossing", "still_piston", "prism_relay", "dark_hall"])
	var eligible := _band_modules(candidates, kit, target, level >= 3.0)
	if not eligible.is_empty(): candidates = eligible
	var best := {}
	var best_miss := INF
	for salt in SALTS:
		var attempt := draw.fork("salt%d" % salt)
		var pool := candidates.duplicate()
		if pool.size() > 1:
			pool.erase(previous)
		var id: String = attempt.pick(pool)
		var m := DailyModules.make(id)
		var p := m.sample(attempt.fork("params"), int(round(level)), tier) if DailyVerified.bypass else DailyVerified.sample(id, attempt.fork("params"), tier)
		if p.is_empty(): continue
		if level >= 3.0 and not meaningful_choice(m, p): continue
		p["guided"] = DailyDifficulty.guided(level)
		if m.plans(p, kit).size() < DailyOracle.MIN_PLANS:
			continue
		var r := DailyDifficulty.total(_score_parts(m, p, kit))
		var miss := DailyDifficulty.miss(r, target)
		var cost := _fit_cost(r, target, level)
		if cost < best_miss:
			best_miss = cost
			best = {"module": id, "params": p, "r": snappedf(r, 0.01)}
		if miss == 0.0 and is_equal_approx(level, floor(level)):
			break
	# Random salts may miss an available in-band variant. Search verified
	# alternatives before falling back to an easier room.
	if best.is_empty() or DailyDifficulty.miss(float(best["r"]), target) > 0.011:
		for id in candidates:
			var m := DailyModules.make(String(id))
			for source in DailyVerified.table.get("parameters", {}).get(id, {}).values():
				var p: Dictionary = source.duplicate(true)
				if level >= 3.0 and not meaningful_choice(m, p): continue
				if m.plans(p, kit).size() < DailyOracle.MIN_PLANS: continue
				p["guided"] = DailyDifficulty.guided(level)
				var r := DailyDifficulty.total(_score_parts(m, p, kit))
				var cost := _fit_cost(r, target, level)
				if cost < best_miss:
					best_miss = cost
					best = {"module": id, "params": p, "r": snappedf(r, 0.01)}
	if best.is_empty():
		var id := String(candidates[0])
		var m := DailyModules.make(id)
		var p := m.fallback(tier) if DailyVerified.bypass else DailyVerified.sample(id, draw.fork("fallback"), tier)
		p["guided"] = DailyDifficulty.guided(level)
		best = {"module": id, "params": p, "r": snappedf(DailyDifficulty.total(_score_parts(m, p, kit)), 0.01)}

	return best


static func meaningful_choice(module: DailyModule, params: Dictionary) -> bool:
	return module.open_slots(params).values().any(func(slots): return slots.any(func(kind): return int(kind) < 3))


static func layout_key(room: Dictionary) -> String:
	var keys := PackedStringArray()
	for beat in room.get("beats", [{"module": room["module"], "params": room["params"]}]):
		keys.append(String(beat["module"]) + ":" + DailyVerified.key_of(beat["params"]))
	return " -> ".join(keys)


static func draw_room(draw: DailyRng, level: float, tier: int, kit: PackedStringArray, previous: String, recent: Array = []) -> Dictionary:
	var best := _draw_candidate(draw, level, tier, kit, previous)
	var target := DailyDifficulty.band(level)
	if not recent.has(layout_key(best)): return best
	var oldest := recent.find(layout_key(best))
	for attempt in range(1, 5):
		var candidate := _draw_candidate(draw.fork("variety%d" % attempt), level, tier, kit, previous)
		# Variety never buys its way in with an easier, out-of-band room.
		if DailyDifficulty.miss(float(candidate["r"]), target) > DailyDifficulty.miss(float(best["r"]), target) + 0.011: continue
		if not recent.has(layout_key(candidate)): return candidate
		var age := recent.find(layout_key(candidate))
		if age < oldest:
			oldest = age
			best = candidate
	# At low tiers only one mechanic may fit a fractional band. Exhaust its
	# verified layout variants before repeating, then rotate oldest first.
	if best["module"] != "chain":
		var alternatives: Array = []
		var pool := _band_modules(DailyModules.ids_for_tier(tier), kit, target, level >= 3.0)
		for id in pool:
			var module := DailyModules.make(String(id))
			for source in DailyVerified.table.get("parameters", {}).get(id, {}).values():
				var params: Dictionary = source.duplicate(true)
				if level >= 3.0 and not meaningful_choice(module, params): continue
				if module.plans(params, kit).size() < DailyOracle.MIN_PLANS: continue
				params["guided"] = DailyDifficulty.guided(level)
				var r := DailyDifficulty.total(_score_parts(module, params, kit))
				if DailyDifficulty.miss(r, target) > 0.001: continue
				var candidate := {"module": id, "params": params, "r": snappedf(r, 0.01)}
				var age := recent.find(layout_key(candidate))
				if age < oldest:
					oldest = age
					alternatives.clear()
				if age == oldest: alternatives.append(candidate)
		if not alternatives.is_empty(): return draw.fork("fresh_layout").pick(alternatives)
	return best


static func _draw_candidate(draw: DailyRng, level: float, tier: int, kit: PackedStringArray, previous: String) -> Dictionary:
	# Lower Hard fits meaningful single mechanisms. Its upper ramp needs
	# two beats; do not spend salts on chains that exceed the lower band.
	var chained := level >= 3.5
	if not chained: return _draw_single(draw, level, tier, kit, previous)
	var target := DailyDifficulty.band(level)
	var best := {}
	var best_miss := INF
	for salt in SALTS:
		var attempt := draw.fork("chain%d" % salt)
		var first: Dictionary
		var second: Dictionary
		if level >= 4.0:
			var first_pool := DailyModules.ids_for_tier(tier)
			for unsafe in ["frozen_crossing", "still_piston", "updraft", "gust_alley", "dark_hall", previous]: first_pool.erase(unsafe)
			var first_id: String = attempt.fork("first_kind").pick(first_pool)
			var second_pool := DailyModules.ids_for_tier(tier)
			second_pool = second_pool.filter(func(id): return id in ["updraft", "dark_hall", "prism_relay"] and id != first_id)
			var second_id: String = attempt.fork("second_kind").pick(second_pool)
			var a := DailyModules.make(first_id)
			var b := DailyModules.make(second_id)
			var ap := a.sample(attempt.fork("first"), 4, tier) if DailyVerified.bypass else DailyVerified.sample(a.id, attempt.fork("first"), tier)
			var bp := b.sample(attempt.fork("second"), 4, tier) if DailyVerified.bypass else DailyVerified.sample(b.id, attempt.fork("second"), tier)
			if ap.is_empty() or bp.is_empty() or a.plans(ap, kit).size() < 2 or b.plans(bp, kit).size() < 2: continue
			if not meaningful_choice(a, ap): continue
			# Do not inflate difficulty with a cube that only asks for an
			# interchangeable modifier; each beat must need a meaningful choice.
			if float(_score_parts(a, ap, kit)["search"]) < 1.0 or float(_score_parts(b, bp, kit)["search"]) < 1.0: continue
			var first_name := String(a.open_slots(ap).keys()[0])
			var second_name := String(b.open_slots(bp).keys()[0])
			var first_keys: Array = []
			for plan in a.plans(ap, kit): first_keys.append(plan["cubes"].get(first_name, ""))
			var overlaps := false
			for plan in b.plans(bp, kit):
				if first_keys.has(plan["cubes"].get(second_name, "")): overlaps = true
			if overlaps: continue
			first = {"module": a.id, "params": ap}
			second = {"module": b.id, "params": bp}
		else:
			var beat_level := level - 1.0
			first = _draw_single(attempt.fork("first"), beat_level, tier, kit, previous)
			second = _draw_single(attempt.fork("second"), beat_level, tier, kit, String(first["module"]))
			if not meaningful_choice(DailyModules.make(first["module"]), first["params"]) and not meaningful_choice(DailyModules.make(second["module"]), second["params"]): continue
		for beat in [first, second]: beat["params"]["guided"] = DailyDifficulty.guided(level)
		var params := {"beats": [first, second], "reuse": level >= 4.0}
		var chain := DailyChain.new()
		var r := DailyDifficulty.total(_score_parts(chain, params, kit))
		var miss := DailyDifficulty.miss(r, target)
		var cost := _fit_cost(r, target, level)
		if cost < best_miss:
			best_miss = cost
			best = {"module": "chain", "params": params, "beats": params["beats"], "reuse": level >= 4.0, "r": snappedf(r, 0.01)}
		if miss == 0 and is_equal_approx(level, floor(level)): break
	# The lower Hard band cannot always fit a meaningful two-beat room.
	# Keep a genuine single-stage choice rather than overshooting its scale.
	if level < 3.5 and (best.is_empty() or DailyDifficulty.miss(float(best["r"]), target) > 0.011):
		return _draw_single(draw.fork("single_fit"), level, tier, kit, previous)
	if best.is_empty():
		# Wind followed by vertical wind always requires a new inscription.
		var first_id := "dead_weight" if previous == "gust_alley" else "gust_alley"
		var second_id := "updraft"
		var a := DailyModules.make(first_id)
		var b := DailyModules.make(second_id)
		var ap := a.fallback(tier) if DailyVerified.bypass else DailyVerified.sample(first_id, draw.fork("safe_first"), tier)
		var bp := b.fallback(tier) if DailyVerified.bypass else DailyVerified.sample(second_id, draw.fork("safe_second"), tier)
		ap["lock"] = 0
		bp["lock"] = 0
		ap["guided"] = DailyDifficulty.guided(level)
		bp["guided"] = DailyDifficulty.guided(level)
		var params := {"beats": [{"module": first_id, "params": ap}, {"module": second_id, "params": bp}], "reuse": level >= 4.0}
		best = {"module": "chain", "params": params, "beats": params["beats"], "reuse": level >= 4.0,
			"r": snappedf(DailyDifficulty.total(_score_parts(DailyChain.new(), params, kit)), 0.01)}
	return best


static func set_spell_rule(room: Dictionary, level: float) -> void:
	# Single flame rooms below Grand intentionally admit a personal spell
	# alternative. Chains and other mechanisms require their rune magic.
	room["personal_fire"] = level < 4.0 and (room["module"] == "kindling" or
		(room["module"] == "burn_through" and int(room["params"].get("kind", 0)) == 0))

static func place_beats(room: Dictionary, x0: int) -> void:
	if not room.has("beats"): return
	var x := x0
	for beat in room["beats"]:
		beat["c0"] = x
		beat["c1"] = x + DailyModules.make(beat["module"]).columns(beat["params"]) - 1
		x = beat["c1"]


## A short fingerprint of what a spec builds (the same spec, the same digest).
static func digest_of(spec: Dictionary) -> int:
	var plain := {"seed": spec["seed"], "difficulty": spec["difficulty"], "tier": spec["tier"],
		"version": spec["version"], "rooms": spec["rooms"], "bell": spec["bell"],
		"exit": spec.get("exit", {}), "endless": spec.get("endless", false), "level": spec.get("level", spec["difficulty"])}
	return DailyRng.fnv(JSON.stringify(plain, "", true))


static func last_module(room: Dictionary) -> String:
	return String(room["beats"][-1]["module"]) if room.has("beats") else String(room["module"])
