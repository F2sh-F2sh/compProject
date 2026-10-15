class_name DailyModules
extends RefCounted

## The library of puzzle modules, by id (see DailyModule).

## Every module id, in a fixed order (the generator's choices depend on it).
const IDS := ["gust_alley", "dead_weight", "updraft", "frozen_crossing", "kindling", "burn_through", "prism_relay", "folded_wall", "together", "still_piston", "dark_hall"]


static func make(id: String) -> DailyModule:
	match id:
		"frozen_crossing": return FrozenCrossingModule.new()
		"kindling": return KindlingModule.new()
		"burn_through": return BurnThroughModule.new()
		"prism_relay": return PrismRelayModule.new()
		"folded_wall": return FoldedWallModule.new()
		"together": return TogetherModule.new()
		"still_piston": return StillPistonModule.new()
		"dark_hall": return DarkHallModule.new()
		"chain": return DailyChain.new()
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
		if make(id).min_tier <= tier and (DailyVerified.bypass or DailyVerified.has_module(id, tier)):
			out.append(id)
	return out
