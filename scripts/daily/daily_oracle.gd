class_name DailyOracle
extends RefCounted

## Decides, without running the game, whether a generated puzzle is worth
## building: every room must be one of the library's modules with parameters
## inside its envelope, offer at least MIN_PLANS different ways to solve it
## with the vocabulary on offer, and need no more mana than the player can
## have. It is pure data (RuneBook and the modules), fast, and runs anywhere.
## The test suite then proves its predictions against the real physics.

const MIN_PLANS := 2
## Mana at most; the player's cap is 100.
const MANA_CAP := 60


## {"ok": bool, "plans": [per room: the plans], "reasons": [text]}
static func validate(spec: Dictionary) -> Dictionary:
	var reasons := PackedStringArray()
	var all_plans: Array = []
	var kit: PackedStringArray = spec["kit"]
	var rooms: Array = spec["rooms"]
	if rooms.is_empty():
		reasons.append("no rooms")
	for i in rooms.size():
		var room: Dictionary = rooms[i]
		var module := DailyModules.make(String(room["module"]))
		if module == null:
			reasons.append("room %d: unknown module %s" % [i + 1, room["module"]])
			all_plans.append([])
			continue
		if module.min_tier > int(spec["tier"]):
			reasons.append("room %d: %s needs vocabulary tier %d" % [i + 1, module.id, module.min_tier])
		var plans := module.plans(room["params"], kit)
		all_plans.append(plans)
		if plans.size() < MIN_PLANS:
			reasons.append("room %d: only %d way(s) to solve %s" % [i + 1, plans.size(), module.id])
		for plan in plans:
			for cube_name in plan["cubes"]:
				if module.mana_needed(room["params"], plan["cubes"][cube_name]) > MANA_CAP:
					reasons.append("room %d: a plan needs more than %d mana" % [i + 1, MANA_CAP])
	return {"ok": reasons.is_empty(), "plans": all_plans, "reasons": reasons}


## How many ways each room can be solved.
static func ways(spec: Dictionary) -> Array:
	var counts: Array = []
	for plans in validate(spec)["plans"]:
		counts.append(plans.size())
	return counts
