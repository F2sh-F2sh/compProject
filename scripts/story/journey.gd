class_name Journey
extends RefCounted

## The order of the game, in one place: where each stop is, and where the
## next one goes. Before this, the way on was written into Lowbell, the title
## screen, the tutorial's exit and Chapter 1.
##
##   Title -> story pictures -> the Novices' Way:
##     Part 1 The Passage (tutorial_level) -> Part 2 The Belfry (chapter 1)
##     -> Part 3 The Observatory (chapter 2)
##   -> the Long Stair (the Landing, a small hub with five doors)
##     -> four wings, each two rooms ending in a bell, each followed by a few
##        story pictures and back to the Landing:
##        The Kilnworks (fire), The Drowned Cistern (ice),
##        The Lampworks (light), The Folded Galleries (space)
##     -> The Eye, once all four bells have rung: the great cube, where
##        Echidna writes the last sentence (two endings)
##
## Save flags and ids (tutorial.done, ch1.*, ch2.*) are unchanged by the names
## shown to the player, so old saves keep working. The wings use the flags
## "kiln.", "cistern.", "lamps.", "galleries." and "eye.".

const TITLE := "res://scenes/ui/title_screen.tscn"
const STORY := "res://scenes/story/story_intro.tscn"
const LOWBELL := "res://scenes/story/lowbell.tscn"
const COTTAGE := "res://scenes/story/nan_cottage.tscn"
const PASSAGE := "res://scenes/tutorial_level.tscn"
const BELFRY := "res://scenes/chapter/chapter_1.tscn"
const OBSERVATORY := "res://scenes/chapter/chapter_2.tscn"
## Story pictures after the bell rings (before Part 3) and after the dome opens.
const BELL_INTERLUDE := "res://scenes/story/interlude_bell.tscn"
const DOME_INTERLUDE := "res://scenes/story/interlude_dome.tscn"
## The Long Stair, its four wings and the Eye (tools/build_wings.gd).
const LANDING := "res://scenes/chapter/landing.tscn"
const KILN := "res://scenes/chapter/wing_kiln.tscn"
const CISTERN := "res://scenes/chapter/wing_cistern.tscn"
const LAMPS := "res://scenes/chapter/wing_lamps.tscn"
const GALLERIES := "res://scenes/chapter/wing_galleries.tscn"
const EYE := "res://scenes/chapter/eye.tscn"
## The pictures after each wing's bell, before the Eye, and the two endings.
const KILN_INTERLUDE := "res://scenes/story/interlude_kiln.tscn"
const CISTERN_INTERLUDE := "res://scenes/story/interlude_cistern.tscn"
const LAMPS_INTERLUDE := "res://scenes/story/interlude_lamps.tscn"
const GALLERIES_INTERLUDE := "res://scenes/story/interlude_galleries.tscn"
const EYE_INTERLUDE := "res://scenes/story/interlude_eye.tscn"
const STILLNESS_ENDING := "res://scenes/story/ending_stillness.tscn"
const SKY_ENDING := "res://scenes/story/ending_sky.tscn"

## The four wings in the order they open: scene, the flag set when the bell
## rings, the name, the pictures that follow, and the words the bell teaches
## (every word the ending needs is learned by the end of the Lampworks).
const WINGS := [
	{"scene": KILN, "done": "kiln.complete", "name": "The Kilnworks", "after": KILN_INTERLUDE,
		"words": ["fire", "projectile", "split", "up", "large", "burst", "delay", "explode"]},
	{"scene": CISTERN, "done": "cistern.complete", "name": "The Drowned Cistern", "after": CISTERN_INTERLUDE,
		"words": ["ice", "freeze", "long", "persist", "down_right"]},
	{"scene": LAMPS, "done": "lamps.complete", "name": "The Lampworks", "after": LAMPS_INTERLUDE,
		"words": ["light", "beam", "glow", "self", "bounce", "up_left"]},
	{"scene": GALLERIES, "done": "galleries.complete", "name": "The Folded Galleries", "after": GALLERIES_INTERLUDE,
		"words": ["space", "portal", "repeat", "down_left"]},
]
## The words the Observatory's tablets teach (Part 3).
const OBSERVATORY_WORDS := ["right", "lift", "strong", "bridge", "down", "up_right"]

## The stops in order: scene, the flag set when it is finished, and its name.
const STOPS := [
	{"scene": PASSAGE, "done": "tutorial.done", "name": "The Passage"},
	{"scene": BELFRY, "done": "ch1.complete", "name": "The Sealed Belfry"},
	{"scene": BELL_INTERLUDE, "done": "", "name": "Far below"},
	{"scene": OBSERVATORY, "done": "ch2.complete", "name": "The Sealed Observatory"},
	{"scene": DOME_INTERLUDE, "done": "", "name": "The dome"},
	{"scene": LANDING, "done": "", "name": "The Long Stair"},
	{"scene": KILN, "done": "kiln.complete", "name": "The Kilnworks"},
	{"scene": KILN_INTERLUDE, "done": "", "name": "A footprint"},
	{"scene": CISTERN, "done": "cistern.complete", "name": "The Drowned Cistern"},
	{"scene": CISTERN_INTERLUDE, "done": "", "name": "The Hush's sentence"},
	{"scene": LAMPS, "done": "lamps.complete", "name": "The Lampworks"},
	{"scene": LAMPS_INTERLUDE, "done": "", "name": "Ilse's reason"},
	{"scene": GALLERIES, "done": "galleries.complete", "name": "The Folded Galleries"},
	{"scene": GALLERIES_INTERLUDE, "done": "", "name": "Wren"},
	{"scene": EYE_INTERLUDE, "done": "", "name": "The Eye opens"},
	{"scene": EYE, "done": "eye.complete", "name": "The Eye"},
]


## Where the way on leads after the story pictures: the Passage, or
## straight to the Belfry for anyone who has already walked it.
static func after_story() -> String:
	return BELFRY if GameState.has_flag("tutorial.done") else PASSAGE


## The stop after a scene, or "" if it is the last (or not a stop).
static func next_after(scene_path: String) -> String:
	for i in STOPS.size():
		if STOPS[i]["scene"] == scene_path:
			return STOPS[i + 1]["scene"] if i + 1 < STOPS.size() else ""
	return ""


## What a stop is called.
static func name_of(scene_path: String) -> String:
	for stop in STOPS:
		if stop["scene"] == scene_path:
			return stop["name"]
	return ""


# ------------------------------------------------------------------ the Long Stair

## Whether wing `i` (0 to 3) has been opened: the first once the Observatory
## is done, each next one once the one before has rung its bell.
static func wing_open(i: int) -> bool:
	if i <= 0:
		return GameState.has_flag("ch2.complete")
	return GameState.has_flag(WINGS[i - 1]["done"])


static func wing_done(i: int) -> bool:
	return GameState.has_flag(WINGS[i]["done"])


static func bells_rung() -> int:
	var n := 0
	for i in WINGS.size():
		if wing_done(i):
			n += 1
	return n


## The Eye opens when all four bells have rung.
static func eye_open() -> bool:
	return bells_rung() >= WINGS.size()


## The pictures that follow a wing's bell ("" for a scene that is not a wing).
static func wing_after(scene_path: String) -> String:
	for w in WINGS:
		if w["scene"] == scene_path:
			return w["after"]
	return ""


## Teaches the words a wing's bell gives (saved).
static func teach_words(words: Array) -> void:
	for w in words:
		GameState.set_flag("rune.frag.%s" % w)


## Where "Continue" goes once the Novices' Way is done and nothing more
## specific is saved: the Landing, or the Eye once it is open and not yet done.
static func after_novices_way() -> String:
	if not GameState.has_flag("ch2.complete"):
		return ""
	return LANDING


## Starting a later part straight from the title (or testing one) gives Echidna
## the spells she would have remembered on the way there, and the words the
## parts before it teach.
static func skipping_to(scene_path: String) -> void:
	var later := [BELFRY, OBSERVATORY, LANDING, KILN, CISTERN, LAMPS, GALLERIES, EYE]
	if not later.has(scene_path):
		return
	GameState.grant_all_abilities()
	if scene_path == BELFRY or scene_path == OBSERVATORY:
		return
	teach_words(OBSERVATORY_WORDS)
	GameState.set_flag("ch1.complete")
	GameState.set_flag("ch2.complete")
	if scene_path == LANDING:
		return
	# A wing (or the Eye) also has the words of the wings before it
	for i in WINGS.size():
		if WINGS[i]["scene"] == scene_path:
			return
		teach_words(WINGS[i]["words"])
		GameState.set_flag(WINGS[i]["done"])
