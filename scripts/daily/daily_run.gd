class_name DailyRun
extends RefCounted

## The daily puzzle's run state, kept in statics because dying reloads the
## scene (SceneFade.restart): everything that has to survive a reload lives
## here, and nothing here is written to the story's save. The title screen
## (or the tests) call start() before the level scene opens.

const SCENE := "res://scenes/daily/daily.tscn"

## "daily" (today's puzzle, ranked once), "practice" (a date again) or
## "trial" (a random seed).
static var mode := "daily"
static var seed_value := 0
static var day_index := 0
static var difficulty := 1
static var tier := 1
## The furthest room she has come into (0-based): where a respawn starts.
static var respawn_room := 0
## The run's numbers.
static var time := 0.0
static var deaths := 0
static var resets := 0
static var hints := 0
static var casts := 0
static var rooms_cleared := 0
## The sentences used to clear each room (room index -> [keys]).
static var solved_with := {}
## True once the bell has been rung (the clock stops).
static var finished := false
## The level root now running, and what to put back when it ends.
static var root: Node
static var saved := {}
## Tests (and later, shared puzzles) can hand the level a ready-made spec
## instead of generating one from the seed.
static var spec_override := {}


## Begins a run: a fresh set of numbers for this seed.
static func start(run_mode: String, seed_for_run: int, for_day: int, run_difficulty: int, run_tier: int) -> void:
	mode = run_mode
	seed_value = seed_for_run
	day_index = for_day
	difficulty = run_difficulty
	tier = run_tier
	respawn_room = 0
	time = 0.0
	deaths = 0
	resets = 0
	hints = 0
	casts = 0
	rooms_cleared = 0
	solved_with = {}
	finished = false
	spec_override = {}


## Today's puzzle.
static func start_day(for_day: int) -> void:
	var difficulty_of_day := DailyGenerator.difficulty_for_day(for_day)
	start("daily", DailyGenerator.seed_for_day(for_day), for_day, difficulty_of_day,
		DailyGenerator.tier_for_difficulty(difficulty_of_day))


## Lends the player the daily's conditions: the same words and abilities for
## everyone, no creatures, and the story's save left alone. Called each time
## the level loads; the first call remembers what to put back.
static func apply() -> void:
	if saved.is_empty():
		saved = {
			"abilities": GameState.all_abilities,
			"calm": GameState.calm_creatures,
			"persist": GameState.persist_to_disk,
			"kit": RuneManager.kit_override,
			"flags": GameState.flags.duplicate(true),
			"session": GameState.session.duplicate(true),
			"checkpoint_scene": GameState.checkpoint_scene,
			"checkpoint_id": GameState.checkpoint_id,
			"checkpoints": GameState.checkpoints.duplicate(true),
		}
	GameState.all_abilities = true
	GameState.calm_creatures = true
	GameState.persist_to_disk = false
	RuneManager.kit_override = DailyKit.words(tier) if spec_override.is_empty() else PackedStringArray(spec_override["kit"])


## Puts the story's conditions back (the daily's flags, words and checkpoints
## are forgotten; the story's save was never written).
static func restore() -> void:
	if saved.is_empty():
		return
	GameState.all_abilities = saved["abilities"]
	GameState.calm_creatures = saved["calm"]
	GameState.persist_to_disk = saved["persist"]
	RuneManager.kit_override = saved["kit"]
	GameState.flags = saved["flags"]
	GameState.session = saved["session"]
	GameState.checkpoint_scene = saved["checkpoint_scene"]
	GameState.checkpoint_id = saved["checkpoint_id"]
	GameState.checkpoints = saved["checkpoints"]
	saved = {}
	root = null
