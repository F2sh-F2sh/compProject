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
## Per-room observation baselines survive a death reload.
static var room_started := {}
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
	room_started = {}
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
			"content_scale_size": GameState.get_tree().root.content_scale_size,
		}
	# Generated views adapt to the physical window, including native 640×480.
	# Keep the story's authored canvas size so leaving restores its layout.
	GameState.get_tree().root.content_scale_size = Vector2i.ZERO
	GameState.all_abilities = false
	GameState.calm_creatures = true
	GameState.persist_to_disk = false
	# Personal Fire/Echo otherwise bypass mechanisms without an inscription.
	# Heal remains available; room entry explicitly lends optional Fire routes.
	GameState.set_flag("ability.fire", false)
	GameState.set_flag("ability.echo", false)
	GameState.set_flag("ability.heal", true)
	# Challenge cubes must not interrupt a timed run with story onboarding.
	# This temporary flag is restored with the story snapshot on leaving;
	# the pause menu can still replay the rune tour explicitly (force=true).
	GameState.set_flag("ui.tour.runes")
	RuneManager.kit_override = DailyKit.words(tier) if spec_override.is_empty() else PackedStringArray(spec_override["kit"])


static func room_spells(room_spec: Dictionary) -> void:
	GameState.set_flag("ability.fire", bool(room_spec.get("personal_fire", false)))


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
	GameState.get_tree().root.content_scale_size = saved["content_scale_size"]
	saved = {}
	root = null


# ------------------------------------------------------------------ Endless
const LIVES := 3
const REST_EVERY := 10

static var endless_start := 1        # the difficulty picked (1..4)
static var endless_k := 0            # the room being played (0-based)
static var lives := LIVES
static var run_score := 0
static var run_rooms := 0
static var run_time := 0.0
static var run_hints := 0
static var endless_prev := ""        # module of the room before (never the same twice in a row)
static var endless_recent: Array = []
static var last_ways := ""           # "Updraft: Lift, strong", for the cards
static var new_best := false

static func start_endless(start_difficulty: int, run_seed: int) -> void:
	start("endless", run_seed, 0, start_difficulty, DailyDifficulty.tier_for(start_difficulty))
	endless_start = clampi(start_difficulty, 1, 4)
	endless_k = 0
	lives = LIVES
	run_score = 0
	run_rooms = 0
	run_time = 0.0
	run_hints = 0
	endless_prev = ""
	endless_recent = []
	last_ways = ""
	new_best = false
	prepare_endless_room()

## Generates the current room and gives it fresh per-room numbers.
static func prepare_endless_room() -> void:
	spec_override = DailyGenerator.endless_room(seed_value, endless_k, endless_start, endless_prev, endless_recent)
	difficulty = int(spec_override["difficulty"])
	tier = int(spec_override["tier"])
	respawn_room = 0
	time = 0.0
	deaths = 0
	resets = 0
	hints = 0
	casts = 0
	rooms_cleared = 0
	solved_with = {}
	room_started = {}
	finished = false

static func level() -> float:
	return DailyDifficulty.ramp(endless_start, endless_k)

## Banks the finished room's score; returns true when a rest stop is due (gives a life back).
static func bank_endless_room(score: int) -> bool:
	run_score += score
	run_rooms += 1
	run_time += time
	run_hints += hints
	endless_prev = DailyGenerator.last_module(spec_override["rooms"][0])
	endless_recent.append(DailyGenerator.layout_key(spec_override["rooms"][0]))
	if endless_recent.size() > 4: endless_recent.pop_front()
	endless_k += 1
	var rest := endless_k % REST_EVERY == 0
	if rest:
		lives = mini(LIVES, lives + 1)
	return rest

## One life fewer; true when that was the last.
static func lose_life() -> bool:
	lives = maxi(lives - 1, 0)
	return lives == 0
