extends SceneTree

## Native physics sweep. Optional argument: one module id. Each allowed
## inscription is tried; retained solutions clear in three independent runs.
## Partial output is saved per layout so the sweep can be resumed.
func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var library: GDScript = load("res://scripts/daily/daily_verified.gd")
	library.bypass = true
	root.get_node("GameState").persist_to_disk = false
	root.get_node("GameState").all_abilities = true
	root.get_node("GameState").calm_creatures = true
	root.get_node("Settings").persist_to_disk = false
	root.get_node("Settings").fullscreen = false
	var store: GDScript = load("res://scripts/daily/daily_store.gd")
	store.persist = false
	var calibration: GDScript = load("res://scripts/daily/daily_calibration.gd")
	calibration.persist = false
	var tour: GDScript = load("res://scripts/ui/ui_tour.gd")
	tour.enabled = false
	var suite: Node = load("res://tests/daily_suite.gd").new()
	root.add_child(suite)
	var registry: GDScript = load("res://scripts/daily/daily_modules.gd")
	var kit_script: GDScript = load("res://scripts/daily/daily_kit.gd")
	var generator: GDScript = load("res://scripts/daily/daily_generator.gd")
	var output := {"verification_rules": 2, "version": generator.GEN_VERSION, "source_hash": library.source_hash(), "modules": {}, "parameters": {}, "complete": false, "repeats": 3, "measurements": {}, "module_hashes": {}}
	if FileAccess.file_exists(library.PATH):
		var previous: Variant = JSON.parse_string(FileAccess.get_file_as_string(library.PATH))
		if previous is Dictionary:
			if int(previous.get("source_hash", -1)) == int(output["source_hash"]):
				output = previous
			else:
				output["verification_rules"] = int(previous.get("verification_rules", 1))
				for id in registry.IDS:
					var recorded := int(previous.get("module_hashes", {}).get(id, -1))
					# Accept the previous exact-source fingerprint when introducing
					# canonical newlines. Changed source still fails both checks.
					if recorded != library.module_hash(id) and recorded != library.module_hash(id, false): continue
					if previous.get("modules", {}).has(id):
						output["modules"][id] = previous["modules"][id]
						output["parameters"][id] = previous["parameters"][id]
					for key in previous.get("measurements", {}):
						if String(key).begins_with(id + "|"): output["measurements"][key] = previous["measurements"][key]
	# Rule 2 lends carved words only to their locked slots. The old enumerator
	# omitted Updraft at tier 1 because Up is carved but not yet in that kit.
	if int(output.get("verification_rules", 1)) < 2:
		output["modules"].erase("updraft")
		output["parameters"].erase("updraft")
	output["verification_rules"] = 2
	# Resumed proofs retain their physics hashes, but follow the current
	# generator revision when only composition/balance has changed.
	output["version"] = generator.GEN_VERSION
	output["complete"] = false
	# JSON reads integers as floats. Canonicalize equivalent numeric layouts
	# without losing their three-run proofs.
	for id in output["modules"]:
		var layouts := {}
		var parameters := {}
		for old_key in output["modules"][id]:
			var params: Dictionary = output["parameters"][id][old_key]
			var key: String = library.key_of(params)
			layouts[key] = output["modules"][id][old_key]
			parameters[key] = params
		output["modules"][id] = layouts
		output["parameters"][id] = parameters
	if not output.has("module_hashes"): output["module_hashes"] = {}
	for id in registry.IDS: output["module_hashes"][id] = library.module_hash(id)
	if not output.has("measurements"): output["measurements"] = {}
	var args := OS.get_cmdline_user_args()
	for id in registry.IDS:
		if args.size() and args[0] != id: continue
		var module: RefCounted = registry.make(id)
		if not output["modules"].has(id): output["modules"][id] = {}; output["parameters"][id] = {}
		for params in library.grid(module):
			var key: String = library.key_of(params)
			if output["modules"][id].has(key): continue
			var tiers := {}
			for tier in range(module.min_tier, 6):
				# Read the real starting recipes and locks, rather than a guessed answer list.
				var run: GDScript = load("res://scripts/daily/daily_run.gd")
				run.start("trial", 4242, 0, 1, tier)
				run.spec_override = suite.spec_for(params, tier, id)
				await suite.open(run.SCENE)
				var choices: Dictionary = allowed(suite.lvl.pieces[0], kit_script.words(tier), kit_script)
				var candidates: Array = combinations(choices)
				var working: Array = []
				for plan in candidates:
					# Vocabulary only controls which inscriptions are allowed. All cubes are
					# dungeon-powered, so the same key/geometry has identical physics at
					# higher tiers. Reuse a 3-run result while enumerating every tier.
					var measurement: String = id + "|" + key + "|" + JSON.stringify(plan["cubes"], "", true)
					var successes := int(output["measurements"].get(measurement, -1))
					if successes < 0:
						successes = 0
						for repeat in 3:
							if await suite.try_plan(id, params, plan, 9.0, tier): successes += 1
							else: break
						output["measurements"][measurement] = successes
					if successes == 3: working.append(plan)
					print("VERIFY ", id, " ", key, " tier ", tier, " ", plan["label"], " ", successes, "/3")
				tiers[str(tier)] = working
			output["modules"][id][key] = tiers
			output["parameters"][id][key] = params
			write_output(output, library.PATH)
	var complete := true
	for id in registry.IDS:
		if not output["modules"].has(id): complete = false; continue
		for params in library.grid(registry.make(id)):
			if not output["modules"][id].has(library.key_of(params)): complete = false
	output["complete"] = complete
	if complete: output.erase("measurements")
	write_output(output, library.PATH)
	await suite.leave()
	print("VERIFICATION complete=", complete)
	quit(0)

func allowed(pieces: Dictionary, words: PackedStringArray, kit_script: GDScript) -> Dictionary:
	var choices := {}
	for name in pieces["cubes"]:
		var cube: Node = pieces["cubes"][name]
		var base: PackedStringArray = cube.start_recipe.split("/")
		var keys: Array = []
		var vocabulary := words.duplicate()
		for i in 4:
			if cube.locked_slots & (1 << i) and not vocabulary.has(base[i]): vocabulary.append(base[i])
		for key in kit_script.sentences(vocabulary):
			var parts: PackedStringArray = key.split("/")
			var fits := true
			for i in 4:
				if cube.locked_slots & (1 << i) and base[i] != parts[i]: fits = false
			if fits: keys.append(key)
		choices[name] = keys
	return choices

func combinations(choices: Dictionary) -> Array:
	var out: Array = [{"label": "", "cubes": {}}]
	for name in choices:
		var next: Array = []
		var options: Array = choices[name].duplicate()
		if choices.size() > 1: options.append("")
		for entry in out:
			for key in options:
				var plan: Dictionary = entry.duplicate(true)
				if key != "": plan["cubes"][name] = key
				next.append(plan)
		out = next
	out = out.filter(func(plan): return not plan["cubes"].is_empty())
	for plan in out:
		var parts := PackedStringArray()
		for name in plan["cubes"]: parts.append("%s: %s" % [name, plan["cubes"][name].replace("/", ", ")])
		plan["label"] = "; ".join(parts)
	return out

func write_output(output: Dictionary, path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "\t", true))
	file.close()
