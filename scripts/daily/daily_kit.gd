class_name DailyKit
extends RefCounted

## The rune words a daily puzzle lends the player, so that everyone has the
## same vocabulary whatever they have learned in the story (a fair board, and
## no spoilers). Tiers follow the story's own order (Journey), so there is one
## source of truth for which word comes when.
##   1  the start words and the Observatory's words
##   2  + the Kilnworks   3  + the Cistern   4  + the Lampworks   5  + the Galleries
## RuneManager.kit_override carries the kit into the game.

const MAX_TIER := 5
## What every player starts with (RuneManager.starting_fragments).
const START := ["wind", "push", "left", "normal"]


## Every word of a tier (and the tiers below it).
static func words(tier: int) -> PackedStringArray:
	var out := PackedStringArray(START)
	for w in Journey.OBSERVATORY_WORDS:
		out.append(w)
	for i in clampi(tier, 1, MAX_TIER) - 1:
		for w in Journey.WINGS[i]["words"]:
			out.append(w)
	return out


## Every sentence ("wind/push/right/strong") the words can make that the
## rune book accepts, as keys.
static func sentences(kit: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for pair in RuneBook.SUPPORTED:
		var essence := String(pair).get_slice("/", 0)
		var form := String(pair).get_slice("/", 1)
		if not kit.has(essence) or not kit.has(form):
			continue
		var spec: Array = RuneBook.SUPPORTED[pair]
		for direction in spec[0]:
			if not kit.has(String(direction)):
				continue
			for modifier in spec[1]:
				if kit.has(String(modifier)):
					out.append("%s/%s/%s/%s" % [essence, form, direction, modifier])
	return out


## True if the kit has all four words of a sentence key.
static func has_all(kit: PackedStringArray, key: String) -> bool:
	for part in key.split("/"):
		if part != "-" and not kit.has(part):
			return false
	return true
