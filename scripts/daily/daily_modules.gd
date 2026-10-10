class_name DailyModules
extends RefCounted

## The library of puzzle modules, by id (see DailyModule).

## Every module id, in a fixed order (the generator's choices depend on it).
const IDS := ["gust_alley", "dead_weight", "updraft"]


static func make(id: String) -> DailyModule:
	match id:
		"gust_alley":
			return GustAlleyModule.new()
		"dead_weight":
			return DeadWeightModule.new()
		"updraft":
			return UpdraftModule.new()
	return null


## The ids that can be built from a vocabulary tier.
static func ids_for_tier(tier: int) -> Array:
	var out: Array = []
	for id in IDS:
		if make(id).min_tier <= tier:
			out.append(id)
	return out
