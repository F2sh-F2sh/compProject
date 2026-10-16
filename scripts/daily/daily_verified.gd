class_name DailyVerified
extends RefCounted

const PATH := "res://data/daily/verified.json"
static var bypass := false
static var table: Dictionary = {}
static var _plans_cache := {}
static var _params_cache := {}

static func load_table() -> void:
	if not table.is_empty(): return
	if FileAccess.file_exists(PATH):
		var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if value is Dictionary: table = value

static func key_of(params: Dictionary) -> String:
	var keys := params.keys()
	keys.sort()
	var parts := PackedStringArray()
	for key in keys:
		if key in ["guided"]: continue
		var value: Variant = params[key]
		if value is float and value == floor(value): value = int(value)
		parts.append("%s=%s" % [key, JSON.stringify(value)])
	return "|".join(parts)

static func plans(id: String, params: Dictionary, words: PackedStringArray) -> Array:
	load_table()
	var tier := 1
	for i in 5:
		if DailyKit.words(i + 1) == words: tier = i + 1; break
	var lookup := params.duplicate()
	if id in ["gust_alley", "dead_weight", "updraft"]:
		if not lookup.has("mirror"): lookup["mirror"] = false
		if not lookup.has("lock"): lookup["lock"] = 0
		if id == "updraft" and not lookup.has("profile"): lookup["profile"] = 0
	elif id in ["kindling", "frozen_crossing"] and not lookup.has("lock"):
		lookup["lock"] = 0
	elif id == "folded_wall" and not lookup.has("lock"):
		lookup["lock"] = 0
	var rows: Dictionary = table.get("modules", {}).get(id, {}).get(key_of(lookup), {})
	var cache_key := id + "|" + key_of(lookup) + "|" + ",".join(words)
	if _plans_cache.has(cache_key): return _plans_cache[cache_key]
	var out: Array = []
	var slots := DailyModules.make(id).open_slots(params)
	var raw: Array = rows.get(str(tier), [])
	var single_settings := {}
	for plan in raw:
		if plan["cubes"].size() == 1:
			var name := String(plan["cubes"].keys()[0])
			single_settings[name + "|" + String(plan["cubes"][name])] = true
	for plan in raw:
		var known := true
		for name in plan["cubes"]:
			var parts: PackedStringArray = String(plan["cubes"][name]).split("/")
			for kind in slots.get(name, [0,1,2,3]):
				if not words.has(parts[int(kind)]): known = false
		if not known: continue
		# An extra activated cube is not another solution if the smaller plan
		# already does exactly the same job. Keep only minimal inscriptions.
		var redundant := false
		if plan["cubes"].size() > 1:
			for name in plan["cubes"]:
				if single_settings.has(String(name) + "|" + String(plan["cubes"][name])): redundant = true; break
		# Current modules use at most two cubes; retain the general subset check
		# for future modules with three or more.
		if plan["cubes"].size() > 2 and not redundant:
			for simpler in raw:
				if simpler["cubes"].size() >= plan["cubes"].size(): continue
				var subset := true
				for name in simpler["cubes"]:
					if simpler["cubes"][name] != plan["cubes"].get(name, ""): subset = false
				if subset: redundant = true; break
		if not redundant: out.append(plan)
	_plans_cache[cache_key] = out
	return out

static func has_module(id: String, tier: int) -> bool:
	load_table()
	for key in table.get("modules", {}).get(id, {}):
		if plans(id, table["parameters"][id][key], DailyKit.words(tier)).size() >= DailyOracle.MIN_PLANS:
			return true
	return false

static func sample(id: String, rng: DailyRng, tier: int) -> Dictionary:
	load_table()
	var entries: Dictionary = table.get("modules", {}).get(id, {})
	var cache_key := id + ":" + str(tier)
	var candidates: Array = _params_cache.get(cache_key, [])
	if not _params_cache.has(cache_key):
		for key in entries:
			if plans(id, table["parameters"][id][key], DailyKit.words(tier)).size() >= DailyOracle.MIN_PLANS:
				candidates.append(table["parameters"][id][key])
		_params_cache[cache_key] = candidates
	if candidates.is_empty(): return {}
	return (rng.pick(candidates) as Dictionary).duplicate(true)

static func grid(module: DailyModule) -> Array:
	if module is DailyMechanism: return module.parameter_grid()
	var out: Array = []
	match module.id:
		"gust_alley":
			for mirror in [false, true]:
				for lock in [0,1,2]:
					for gap in [2,3]:
						for run in range(3, 6 if gap == 2 else 5): out.append({"mirror": mirror, "lock": lock, "gap": gap, "run": run})
		"dead_weight":
			for lock in [0,1]:
				for gap in [2,3]:
					for run in [3,4,5]: out.append({"gap": gap, "run": run, "lock": lock, "mirror": false})
		"updraft":
			for lock in [0,1]:
				for rows in [3,4]:
					for width in [3,4]:
						for profile in [0,1,2]: out.append({"dist": 1, "rows": rows, "width": width, "mirror": false, "lock": lock, "profile": profile})
	return out

static func source_hash() -> int:
	var paths: Array[String] = []
	for directory in ["res://scripts/daily/modules", "res://scripts/runes/effects"]:
		for file in DirAccess.get_files_at(directory):
			if file.ends_with(".gd"): paths.append(directory.path_join(file))
	paths.append_array(["res://scripts/daily/daily_verified.gd", "res://scripts/daily/daily_kit.gd", "res://tools/procgen/verify_modules.gd", "res://scripts/daily/daily_module.gd", "res://scripts/daily/daily_mechanism.gd",
		"res://scripts/daily/daily_piston.gd", "res://scripts/daily/daily_chain.gd", "res://scripts/daily/daily_root.gd",
		"res://scripts/runes/rune_carrier.gd", "res://scripts/daily/room_kit.gd", "res://scripts/runes/rune_book.gd",
		"res://scripts/runes/wind_body.gd", "res://scripts/runes/rune_cube.gd", "res://scripts/player/player.gd",
		"res://scripts/traps/piston_trap.gd", "res://scripts/puzzle/circuit.gd", "res://scripts/puzzle/spectral_platform.gd"])
	paths.sort()
	var combined := ""
	for path in paths: combined += path + "\n" + FileAccess.get_file_as_string(path).replace("\r\n", "\n") + "\n"
	return DailyRng.fnv(combined)

static func fresh() -> bool:
	load_table()
	return int(table.get("version", -1)) == DailyGenerator.GEN_VERSION and int(table.get("source_hash", -1)) == source_hash()


## A per-module fingerprint lets an offline sweep resume unaffected proofs
## after editing a different module. The final table still has one whole-
## library fingerprint for the runtime freshness check.
static func module_hash(id: String, normalize_lines := true, scoped_portal := true) -> int:
	var paths: Array[String] = []
	for directory in ["res://scripts/runes/effects"]:
		for file in DirAccess.get_files_at(directory):
			# Only Folded Wall can inscribe a portal: every other standalone
			# template locks its essence to wind, fire, ice or light.
			if scoped_portal and file == "rune_portal.gd" and id != "folded_wall": continue
			if file.ends_with(".gd"): paths.append(directory.path_join(file))
	paths.append_array(["res://scripts/daily/modules/" + id + ".gd", "res://scripts/daily/daily_module.gd",
		"res://scripts/daily/room_kit.gd", "res://scripts/runes/rune_book.gd", "res://scripts/runes/rune_cube.gd",
		"res://scripts/runes/wind_body.gd", "res://scripts/player/player.gd", "res://scripts/traps/piston_trap.gd",
		"res://scripts/puzzle/circuit.gd", "res://scripts/puzzle/spectral_platform.gd"])
	if id not in ["gust_alley", "dead_weight", "updraft"]:
		paths.append_array(["res://scripts/daily/daily_mechanism.gd", "res://scripts/daily/daily_piston.gd"])
	paths.sort()
	var combined := ""
	for path in paths:
		var source := FileAccess.get_file_as_string(path)
		if normalize_lines: source = source.replace("\r\n", "\n")
		combined += path + "\n" + source + "\n"
	return DailyRng.fnv(combined)
