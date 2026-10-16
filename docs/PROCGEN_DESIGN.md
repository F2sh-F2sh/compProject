# Generated levels that scale in difficulty, and the Endless mode: a build spec

This document is written so a developer **or another AI** can build the rest of the feature without anything else
to go on. It says how the system works, how it looks and how to build it, step by step, with file names, function
signatures, numbers and tests. Read sections 0–2 before writing any code.

What is already built and tested is marked **[DONE]**; what is left is marked **[TO BUILD]**.

---

## 0. Ground rules (read first)

1. **Engine:** Godot 4.7.2, GDScript. Project root: `C:\Games\CompProject\compProject`.
   Console exe: `C:\Users\Ishaan\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
2. **Never edit the story's levels or their builders** (`scenes/chapter*`, `tools/build_chapter*.gd`,
   `tools/levels/build_wings.gd`, story scripts). The generated content lives only in `scripts/daily/`, `scenes/daily/`,
   `scripts/ui/daily_*.gd` and `tests/daily_suite.gd`. Small additive hooks elsewhere are allowed only where this
   doc names them.
3. **Do not commit or push** without the project owner's explicit OK.
4. **Art rule:** use the pixel-art assets and fonts that exist (`Fonts.TITLE`, `Fonts.UI`, `Fonts.STORY`,
   `DungeonUI.decorate(panel)`, `DungeonUI.divider(width)`, the tiles in `assets/tileset/`). Do not invent new
   drawn shapes for world art.
5. **GDScript is strict here:** warnings are errors. `var x := something_that_returns_Variant` fails to parse. Give
   a type (`var x: float = d["k"]`) whenever the right side is a Dictionary/Array lookup or a Variant.
6. **New `class_name` scripts:** run an import once before tests, or the class is "not declared":
   `"<godot console exe>" --headless --import` (from the project root).
7. **Tests** run in a window (not headless) from the project root:
   ```
   "<godot console exe>" --path . --fixed-fps 60 --disable-vsync --script res://tests/run_tests.gd -- daily <scenario>
   ```
   Omit `<scenario>` to run the whole daily suite. A line `RESULT passed=N failed=M` ends the log. Look for
   `SCRIPT ERROR` lines too: a script error does not always fail a check. Lines saying
   `Identifier not found: GameState/Sfx` near the top are harmless runner noise **unless** checks then fail.
   `tests/run_tests.gd` must never reference a `scripts/daily` class by name at the top level (it breaks the
   compile before autoloads exist). Use `load("res://scripts/daily/x.gd")` there.
8. **Randomness:** never `randi()`, `randf()`, `hash()` in generation. Use `DailyRng` only (deterministic on every
   machine). Every new kind of draw takes its own `rng.fork("label")` so adding a draw never shifts others.
9. **Changing what a seed builds** (new module, new knob, new weights) means bumping
   `DailyGenerator.GEN_VERSION` (it is mixed into the daily seed).
10. **Solvability is sacred.** A generated room must have **at least two** working solutions, and every solution
    the code claims must be proven in the real physics by a test (section 5).

---

## 1. The idea in one page

The game is a reasoning game: Echidna inscribes four-word rune sentences (essence, form, direction, modifier)
on rune cubes to move crates, lift herself, burn, freeze, shine and fold space. A generated room is a
**module** (a puzzle template such as "blow a crate onto a plate") with **knobs** (parameters). The generator
picks modules and knob values from a seed.

**Difficulty is measured, not guessed.** Every room gets a score **R** computed from its data:

| Part | Meaning | How it is computed |
|---|---|---|
| search (S) | bits of guessing | `log2(settings the open slots allow / settings that work)` (exact formula in 2.2) |
| steps (T) | things the easiest solution needs right | cubes to inscribe + cubes to carry |
| concept (C) | depth of the idea | declared by the module (push = 1, two winds adding up = 2, lift-not-push = 2, reflection or portals = 3) |
| execution (E) | physical demand (kept low) | declared by the module (riding a wind column = 1) |
| decoys (X) | pieces that mislead | declared by the module |

`R = 1.0·S + 0.8·T + 1.0·C + 0.5·E + 0.6·X`

Each named difficulty is a **band** of R and a **word tier** (which rune words the player is lent):

| Level | Name | R band | Word tier | Daily rooms | Waymarks |
|---|---|---|---|---|---|
| 1 | Gentle | 1.5 – 3.0 | 1 | 3 (Mon, Tue) | yes |
| 2 | Steady | 3.0 – 4.0 | 1 | 4 (Wed, Thu) | yes |
| 3 | Hard | 4.5 – 6.7 | 2 | 4 (Fri, Sat) | yes |
| 4 | Grand | 5.3 – 7.0 | 3 | 5 (Sun) | no |
| 5 | Master (Endless only) | 6.0 – 9.5 | 4 | – | no |

Between two levels (for example 2.5) the band is interpolated. The generator samples up to 16 times per room and
keeps the first draw that has ≥ 2 solutions **and** an R inside the band. Otherwise it keeps the closest draw with
≥ 2 solutions, and as a last resort the module's hand-checked fallback.

Measured result (`daily difficulty` scenario, 250 seeds per difficulty):

| Difficulty | Mean R | Rooms inside the band |
|---|---|---|
| Gentle | 2.10 | 98% |
| Steady | 3.60 | 99% |
| Hard | 5.65 | 100% |
| Grand | 5.97 | 100% |

Why Gentle and Steady share tier 1: each new word tier adds many directions and modifiers, so search jumps by
1–2 bits per tier. Steady is made harder than Gentle by carving less of the sentence (opening more slots), not
by lending more words.

**Two products use this:**
1. **The Daily Puzzle [DONE]:** one seeded puzzle per local calendar date. Difficulty comes from the weekday.
   It has a score, stars, a streak and a friends board.
2. **The Endless mode [TO BUILD]:** the player picks Gentle/Steady/Hard/Grand and plays room after room. The
   difficulty climbs a quarter step every 5 rooms, up to one full step above the pick. Three lives end the run.

---

## 2. What exists today [DONE]

### 2.1 File map

| File | Role |
|---|---|
| `scripts/daily/daily_rng.gd` (`DailyRng`) | xorshift32 PRNG: `next_u32`, `int_range(lo,hi)`, `chance(p)`, `pick(arr)`, `shuffled(arr)`, `fork(label)`; static `fnv(text)`, `mix(int)`; calendar `day_index(y,m,d)` (day 0 = 2026-01-01), `weekday(day)` (0 = Sunday), `label_of(day)`, `date_of(day)` |
| `scripts/daily/daily_kit.gd` (`DailyKit`) | `words(tier)`: the words lent at tiers 1–5 (start words + Observatory; then + Kiln, Cistern, Lampworks, Galleries); `sentences(kit)`; `has_all(kit, key)` |
| `scripts/daily/daily_module.gd` (`DailyModule`) | Base class of every module (API in 2.2) |
| `scripts/daily/modules/gust_alley.gd`, `dead_weight.gd`, `updraft.gd` | The three wind modules |
| `scripts/daily/daily_modules.gd` (`DailyModules`) | Registry: `IDS`, `make(id)`, `ids_for_tier(tier)` |
| `scripts/daily/daily_oracle.gd` (`DailyOracle`) | `validate(spec)` (≥ 2 plans per room, mana), `ways(spec)`; `MIN_PLANS = 2` |
| `scripts/daily/daily_difficulty.gd` (`DailyDifficulty`) | `WEIGHTS`, `BANDS`, `TIERS`, `band(level)`, `total(parts)`, `room_score(room, kit)`, `miss(r, band)`, `ramp(start, k)`, `tier_for(level)`, `guided(level)`, `name_of(level)` ("Steady +2") |
| `scripts/daily/daily_generator.gd` (`DailyGenerator`) | `GEN_VERSION = 2`, `ROOMS = [3,4,4,5]`, `SALTS = 16`, `BELL_COLUMNS = 10`, `EXIT_COLUMNS = 7`; `seed_for_day`, `difficulty_for_day`, `tier_for_difficulty`, `generate(seed, difficulty, tier)`, **`endless_room(run_seed, k, start, previous)`**, `draw_room(...)`, `digest_of(spec)` |
| `scripts/daily/room_kit.gd` (`RoomKit`) | Runtime builder helpers: `shell`, `make_room`, `gate`, `circuit`, `hint`, `guide`, `step`, `waymarks`, `cube`, `crate`, `stone`, `plate`, `torch`, `curb`, `solid`, `floor_tile`, `group`, `inst`; constants `T = 64`, `FLOOR_Y = 534`, `LOW_CEIL = 4`, `HIGH_CEIL = 0`, `LOCK_ESSENCE = 1`, `LOCK_FORM = 2`, `LOCK_DIRECTION = 4`, `LOCK_MODIFIER = 8`; `cx(col)` = column centre x |
| `scripts/daily/daily_root.gd` (`DailyRoot extends ChapterRoot`) | Builds the spec's rooms, player, camera, HUD, pause menu, rune manager; tracks time/casts/hints/deaths/resets; `finish_chapter()` scores and opens the card; `ways_lines()` |
| `scripts/daily/daily_run.gd` (`DailyRun`) | Static run state that survives the scene reload on death; `start(...)`, `start_day(day)`, `apply()` / `restore()` (lend daily conditions, put the story's back); `spec_override` (a ready-made spec to build) |
| `scripts/daily/daily_score.gd` (`DailyScore`) | `compute(stats, par, rooms)`, `par_seconds(spec)`, share code `encode`/`decode` (`SB1-…`, 13 bytes + 3-byte checksum), `share_text` |
| `scripts/daily/daily_store.gd` (`DailyStore`) | `user://daily.cfg`: results per day, streak with a weekly mend, friends, clock guards; `persist` and `file_path` switches for tests |
| `scripts/ui/daily_menu.gd` (`DailyMenu`) | The Daily Puzzle screen (opened from the title's "Daily Puzzle" word) |
| `scripts/ui/daily_complete.gd` (`DailyComplete`) | The end card (stars, score, deductions, "the ways through", streak, share code) |
| `scenes/daily/daily.tscn` | Just a Node2D with `daily_root.gd` (`DailyRun.SCENE`) |
| `tests/daily_suite.gd` | The tests (scenario list in section 9) |
| `docs/DAILY_PUZZLE.md` | The daily puzzle's guide |

### 2.2 The module API (`DailyModule`)

```gdscript
var id := ""              # "gust_alley"
var title := ""           # "Gust Alley" (room title card, end card)
var objective := ""       # the goal shown in the objective panel, never the solution
var min_tier := 1         # lowest word tier it can be built from
var par_seconds := 60.0   # a careful player's time (score par)

func columns(params) -> int                    # room width in tiles, wall to wall inclusive
func sample(rng: DailyRng, difficulty: int, tier: int) -> Dictionary   # knobs inside the envelope
func fallback(tier: int) -> Dictionary         # knobs that always work
func plans(params, kit: PackedStringArray) -> Array   # [{"label": "Push right, strong", "cubes": {"Gust Cube": "wind/push/right/strong"}}]
func non_plans(params, kit) -> Array           # sentences that must NOT clear it (tests' precision check)
func build(k: RoomKit, room: Room, x0: int, x1: int, params, words) -> Dictionary   # {"cubes": {name: node}, ...}
func perform(pieces, plan) -> String           # tests: put the plan on the cubes and switch them on (override to carry etc.)
func drive(pieces) -> Dictionary               # tests: {"teleport": pos, "hold": [actions], "tap": [actions]} for player movement
func ceiling_row() -> int                      # RoomKit.LOW_CEIL or HIGH_CEIL
func mana_needed(params, key) -> int
# difficulty hooks
func concept_of(params) -> float               # default 1
func open_slots(params) -> Dictionary          # {cube name: [RuneFragments.Kind.*]} the player must choose
func plan_steps(plan) -> float                 # default: cubes in the plan; add carries
func execution_of(params) -> float             # default 0
func decoys_of(params) -> float                # default 0
func score_parts(params, kit) -> Dictionary    # {"search","steps","concept","execution","decoys","plans"} (do not override)
```

**Search formula (`score_parts`):**
1. For each cube in `open_slots`, `choices[cube]` = the product, over its open kinds, of the number of kit words
   of that kind (at least 1).
2. `N` = the product of all `choices`.
3. `W` = the sum over plans of the product of `choices` of the cubes the plan does **not** use (those cubes are
   free).
4. `S = max(0, log2(N / min(W, N)))`. `T` = the smallest `plan_steps` over the plans.

Every module also reads `params.get("guided", true)` and only calls `k.waymarks(room, x0, x1)` when it is true. The
generator sets `guided` from `DailyDifficulty.guided(level)` (false from Grand up).

### 2.3 The three modules and their knobs (measured R)

| Module | Knobs | R (tier 1) | Notes |
|---|---|---|---|
| Gust Alley (blow a crate onto a plate) | `mirror`, `lock` 0 (direction+modifier open) / 1 (form+modifier) / 2 (modifier only), `gap` 2–3, `run` 3–5 | lock 2: 1.80, lock 1: 3.38, lock 0: 3.80 | Crate travel: pushed while within 320 px (560 with Long) of the cube, then coasts 81 px (Normal) / 153 px (Strong); needs `run*64 − 111` px; 12 px margin |
| Dead Weight (stone too heavy for one wind) | `gap`/`run` from `VERIFIED` (6 layouts), `lock` 0 (fixed cube's modifier open) / 1 (+ direction) | lock 0: 3.63, lock 1: 5.63 | Plans: one Strong wind, or carry the loose cube beside the fixed one (two Normals) |
| Updraft (wall too high to jump) | `rows` 3–4, `width` 3–4, `dist` = 1, `lock` 0 (form+modifier open, find Lift) / 1 (Lift carved) | lock 1: 2.30, lock 0: 4.88 | Push can't blow up; Lift can. Only dist 1 is fair |

At higher tiers the same rooms score higher (more words to search). For example, Gust Alley lock 0 scores 5.12 at
tier 2 and 5.38 at tier 3.

### 2.4 Spec format (what the generator returns; plain data)

```gdscript
{ "seed": int, "difficulty": 1..4, "tier": 1..5, "version": GEN_VERSION, "kit": PackedStringArray,
  "rooms": [ {"module": "gust_alley", "params": {...knobs..., "guided": bool}, "r": 3.38, "x0": 0, "x1": 18}, ... ],
  "bell": {"x0": int, "x1": int},                 # daily: the bell hall
  "digest": int }
# an Endless room (DailyGenerator.endless_room) instead has:
#   "level": float (e.g. 2.25), "bell": {}, "exit": {"x0": int, "x1": int}, "endless": true, and one room
```

Rooms share a wall column: room *i*'s `x1` is room *i+1*'s `x0`; the exit gate sits on that column.

---

## 3. The Endless mode [TO BUILD]

### 3.1 How it plays

1. On the Daily Puzzle screen the player clicks **Endless: Gentle / Steady / Hard / Grand**.
2. Room 1 loads at once: one generated puzzle room, then a short **stair hall** with a glowing wooden door at its
   end. A small line at the top centre reads `Endless · Room 1 · Steady · Lives 3`.
3. She solves the room. The exit gate opens, she walks through the hall and into the door. The screen fades,
   and room 2 loads (a new room at the same origin, built fresh).
4. Every 5 rooms the level rises a quarter step: Steady → Steady +1 → +2 → +3 → Hard, then it stays at the cap
   (one full step above the pick). Grand climbs into **Master** (tier 4 words).
5. **Death** costs a life and restarts the **current room** (its pieces reset; the run is kept). At 0 lives the
   run ends and the **run-over card** appears.
6. Every **10 rooms** a **rest card** appears: one life back (max 3), the run so far, and buttons
   "Keep climbing" / "Leave (your record is kept)".
7. Records: for each starting difficulty, the best run (most rooms; on a tie, the higher score) is kept in
   `user://daily.cfg`. It is shown on the Daily Puzzle screen.
8. Nothing touches the story's save: same isolation as the daily (`DailyRun.apply`/`restore`).

### 3.2 How it looks

**Daily Puzzle screen (`DailyMenu`), left column, replacing "Random trial" and the "Trial difficulty" button:**

```
 ┌──────────────────────────── Daily Puzzle ────────────────────────────┐
 │                 <   2026-10-10 · Hard   >                            │
 │ ──────────────────────────── ◆ ───────────────────────────────────── │
 │ Solved: 810 points, 3:18           │ THE BOARD, 2026-10-10           │
 │ ★ ★ ★                              │ Mira          940   2:31        │
 │ Streak: 8 days (best 8)            │ You           810   3:18        │
 │ ▢▢▢▢▣▣▣▢▣▣▣▣▣[▣]                   │ A perfect run 1000              │
 │ [  Practise today's puzzle  ]      │ Add a friend's result           │
 │                                    │ [Name][SB1-...      ][Add]      │
 │ ENDLESS                            │                                 │
 │ [Gentle][Steady][ Hard ][Grand]    │                                 │
 │ Best: Steady, 23 rooms, 18,420     │                                 │
 │                 [          Back          ]                           │
 └──────────────────────────────────────────────────────────────────────┘
```
- "ENDLESS" is a `Fonts.UI` 16 label in the dim colour (`Color("8a8092")`), like "THE BOARD".
- The four buttons sit in an `HBoxContainer` (separation 6), each 96×36, `Fonts.UI` 16, built with the menu's
  `_small_button` style (or a 96-wide `_button`).
- Below them, one `Fonts.STORY` 14 line for the record of the difficulty the focus is on (or the best overall):
  `Best: Steady, 23 rooms, 18,420`, or `No Endless run yet.` if there is none.
- Pad navigation: the row must be reachable with the arrow keys from "Practise…" and down to "Back".
- Keep "Random trial" code paths (mode `"trial"`) in `DailyRun`/`DailyComplete`: the tests use them. Only the
  menu buttons go.

**In the room (top centre, a `CanvasLayer` layer 3, in group `"gameplay_ui"`):**
```
                    Endless · Room 7 · Steady +1 · Lives 2
```
`Fonts.UI` 16, colour `Color("e8dcc0")`, with a soft dark shadow (`font_shadow_color` black 60%). When a life is
lost, flash "Lives" red (`Color("b23a48")`) for 0.6 s.

**The stair hall (after the puzzle room):** `EXIT_COLUMNS = 7` tiles wide, low ceiling, two torches
(`k.torch`). At column `x1 - 2` stands the door: a `Sprite2D` with
`res://assets/tileset/walls/tiles/10_door_wood.png` (`centered = false`, `offset = Vector2(-32, -64)`, positioned
on the floor at `FLOOR_Y`), a blue `PointLight2D` glow (`color (0.5, 0.62, 1)`, energy 1.2, `texture_scale` 1.1,
using `LightTextures.radial(256)`), and optionally the wisps from `scenes/world/level_exit.tscn` (copy its
CPUParticles2D settings). Objective panel: `k.guide(hall, "Go through the door.")`.

**Rest card (every 10 rooms) and run-over card:** same frame as `DailyComplete` (dim backdrop, a
`PanelContainer` decorated with `DungeonUI.decorate`, width 600, centred, pauses the tree):
```
            A REST ON THE STAIR                    THE CLIMB ENDS
        Endless · Steady → Steady +2          Endless · Steady → Hard
        ───────────── ◆ ─────────────         ───────────── ◆ ─────────────
         Rooms climbed        10               Rooms climbed        23
         Score              8,940              Score             18,420
         Hints heard            2              Hints heard            5
         Lives          ♥ ♥ ♥ (one back)       Best from Steady   23 rooms  (new best!)
        Last room: Updraft: Lift, strong      Last room: Dead Weight: Two winds together
                                               SB1-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-X  [Copy]
        [ Keep climbing ] [ Leave ]           [ Climb again ] [ Return to Title ]
```
Lives may be shown as text ("Lives 3") or with the HUD's existing heart sprite (`scenes/heart.tscn` / its
texture). Do not draw hearts with code.

### 3.3 Run state: add to `scripts/daily/daily_run.gd`

`DailyRun.start()` already clears `spec_override`. Add a mode `"endless"` and this section (a reference
implementation, ready to paste):

```gdscript
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
	last_ways = ""
	new_best = false
	prepare_endless_room()

## Generates the current room and gives it fresh per-room numbers.
static func prepare_endless_room() -> void:
	spec_override = DailyGenerator.endless_room(seed_value, endless_k, endless_start, endless_prev)
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
	finished = false

static func level() -> float:
	return DailyDifficulty.ramp(endless_start, endless_k)

## Banks the finished room's score; returns true when a rest stop is due (gives a life back).
static func bank_endless_room(score: int) -> bool:
	run_score += score
	run_rooms += 1
	run_time += time
	run_hints += hints
	endless_prev = String(spec_override["rooms"][0]["module"])
	endless_k += 1
	var rest := endless_k % REST_EVERY == 0
	if rest:
		lives = mini(LIVES, lives + 1)
	return rest

## One life fewer; true when that was the last.
static func lose_life() -> bool:
	lives = maxi(lives - 1, 0)
	return lives == 0
```

`apply()` already lends `spec_override["kit"]` when a spec is set, so the Endless room's words are right.

### 3.4 The level: changes to `scripts/daily/daily_root.gd`

`DailyGenerator.endless_room()` already returns a one-room spec with `"endless": true` and `"exit"`. In
`DailyRoot`:

1. **Build the stair instead of the bell.** In `_build_rooms()`, after the puzzle rooms:
   `if spec.get("endless", false): _build_stair(rooms_spec.size()); return`.
   `_build_stair(index)` does the following:
   - `kit.shell(e.x0, e.x1, RoomKit.LOW_CEIL, false, true)`.
   - `var hall := kit.make_room("R%d" % (index + 1), "The Stair", e.x0, e.x1, RoomKit.LOW_CEIL, Vector2(RoomKit.cx(e.x0 + 2), 530), index, index)`.
   - Add the door (section 3.2) as children of `hall`.
   - Add `exit_door := Area2D` with a `CollisionShape2D` (`RectangleShape2D` size 64×128), centred on the door,
     `collision_mask` covering the player's layer. Check `scenes/player/player.tscn` (a `collision_layer = 2` appears
     there; verify which node). In `body_entered`, compare `body == player`.
   - `kit.guide(hall, "Go through the door.")` and torches.
2. **Deaths.** Replace `player.died.connect(func(): DailyRun.deaths += 1)` with `_on_player_died()`, which does
   the following:
   - `DailyRun.deaths += 1`.
   - If Endless and `DailyRun.lose_life()` returned true (that was the last life): stop the death screen's
     restart. Keep a reference to the death screen node when it is created in `_build_player_and_ui`, then
     call `set_process_input(false)` on it. After about 1.5 s (a `get_tree().create_timer(1.5, true)`), call
     `EndlessCard.open(self, "over")`.
   - Otherwise the normal death screen restarts the scene. `SceneFade.restart` reloads `daily.tscn`, and
     `_ready` rebuilds the same `spec_override` (the same room, fresh).
3. **Reaching the door** (`_on_exit_reached`):
   - Guard with `if DailyRun.finished: return`, then set `DailyRun.finished = true`.
   - Score the room with `DailyScore.compute({time, deaths, resets, hints, casts}, module.par_seconds + 10.0, 1)`.
   - `DailyRun.last_ways = ways_lines()[0]` (strip the "1. " prefix).
   - `var rest := DailyRun.bank_endless_room(scored["score"])`.
   - `DailyRun.new_best = DailyStore.record_endless(DailyRun.endless_start, DailyRun.run_rooms, DailyRun.run_score, DailyRun.level()) or DailyRun.new_best`
     (record after every room, so quitting mid-run keeps the record).
   - If `rest`: `EndlessCard.open(self, "rest")`. Otherwise call `DailyRun.prepare_endless_room()` and then
     `SceneFade.change(get_tree(), DailyRun.SCENE)`.
4. **The HUD line.** Build it in `_build_player_and_ui` when Endless (section 3.2). Update it in
   `_physics_process` only when the text changes.
5. **The clock.** `_physics_process` already adds `delta` to `DailyRun.time` until `finished`. Keep that.
6. **Leaving.** The existing `_exit_tree` / `_after_exit` already restores the story's conditions when no new
   `DailyRoot` takes over. A room-to-room change is a new `DailyRoot`, so the conditions stay lent.

### 3.5 New file: `scripts/ui/endless_card.gd` (`class_name EndlessCard extends CanvasLayer`)

`static func open(host: Node, kind: String) -> EndlessCard` with `kind` = `"rest"` or `"over"`. Copy the structure
of `scripts/ui/daily_complete.gd`: `_build()` sets `layer = 8`, `PROCESS_MODE_ALWAYS`, pauses the tree and calls
`Crosshair.arrow()`, dim backdrop, `PanelContainer` + `DungeonUI.decorate`, `VBoxContainer`, `_line()` and
`_button()` helpers, a fade-in tween. It holds the content from section 3.2, and exposes `keep_button`,
`leave_button`, `again_button`, `title_button` for the tests. The buttons do the following:
- **Keep climbing:** unpause, `DailyRun.prepare_endless_room()`, `SceneFade.change(get_tree(), DailyRun.SCENE)`.
- **Leave / Return to Title:** unpause, `SceneFade.change(get_tree(), "res://scenes/ui/title_screen.tscn")`.
- **Climb again:** `DailyRun.start_endless(DailyRun.endless_start, DailyRng.mix(Time.get_ticks_usec()))`, then
  change to `DailyRun.SCENE`.
- **Copy** (over card only): `DisplayServer.clipboard_set(DailyScore.share_text(result, code))`.

### 3.6 Records: add to `scripts/daily/daily_store.gd`

```gdscript
## "1".."4" -> {"rooms", "score", "level"}: the best Endless run from each starting difficulty.
static var endless_best := {}

static func endless_best_for(start: int) -> Dictionary:
	_ensure_loaded()
	return endless_best.get(str(start), {})

## Keeps a run if it beats the record (more rooms, or as many and a higher score). True if it did.
static func record_endless(start: int, rooms: int, score: int, level: float) -> bool:
	_ensure_loaded()
	if rooms <= 0:
		return false
	var best := endless_best_for(start)
	if not best.is_empty() and (rooms < int(best["rooms"]) or (rooms == int(best["rooms"]) and score <= int(best["score"]))):
		return false
	endless_best[str(start)] = {"rooms": rooms, "score": score, "level": snappedf(level, 0.25)}
	save()
	return true
```
Also update the following functions:
- `forget()`: `endless_best = {}`.
- `save()`: `file.set_value("daily", "endless_best", endless_best)`.
- `load_file()`: read it back, keeping only keys "1"–"4" whose values are Dictionaries. Clamp
  `rooms` 0..100000 and `score` 0..100000000 with `_int_in`, and `level` to 1.0..5.0 (non-numbers become 1.0).

### 3.7 Share code: `scripts/daily/daily_score.gd`

Byte 2's lowest bit is spare (`... | 0`). Set it to 1 for an Endless result and decode it as `"endless": bool`. For
an Endless result the fields mean the following:

| Field | Meaning in an Endless code |
|---|---|
| `day` | rooms climbed |
| `score` | average points per room (0–1000) |
| `time` | total seconds |
| `difficulty` | the starting difficulty |
| `tier` | quarter steps climbed above it (0–4) |

`share_text` for Endless: `"The Sealed Belfry Endless, Steady: 23 rooms, 801 pts a room  5 hint(s)\n<code>"`.
`DailyStore.add_friend` must refuse an Endless code ("That is an Endless run; the board is for daily puzzles.").

### 3.8 The menu: `scripts/ui/daily_menu.gd`

- Replace the `trial_button` and the "Trial difficulty" button with the ENDLESS block (section 3.2).
- Expose `endless_buttons: Array[Button]` (index 0 = Gentle) for the tests.
- Each button calls `DailyRun.start_endless(i + 1, DailyRng.mix(Time.get_ticks_usec()))`, then
  `SceneFade.change(get_tree(), DailyRun.SCENE)`.
- The `trial_difficulty` static can go. Check that `tests/daily_suite.gd` "cards" and "screens" still pass and
  update them if they used `trial_button`.

---

## 4. Two-beat rooms [TO BUILD after Endless]

Harder rooms chain two puzzles ("beats") inside one room. This raises steps (T) and concept (C) without new
words.
- **Room shape by level:** 1 beat below 3.0; 1 or 2 beats from 3.0; 2 beats from 4.0; 2 beats with a **reused
  cube** from 5.0. With a reused cube, one cube must be re-inscribed between the beats, for example push a crate,
  then turn the same cube into a lift.
- **Spec:** a room gets `"beats": [{"module", "params", "c0", "c1"}, ...]` instead of one module. Each beat owns
  a column range inside the room and builds its pieces there. Only the last beat's gate is real. Earlier beats
  open an inner gate (`k.gate` on the boundary column) that their own objective opens.
- **Building:** add `build_beat(k, room, c0, c1, params, words)` to `DailyModule`. Its default calls `build` with
  `x0 = c0`, `x1 = c1`. A beat must not create the room's shell or exit gate when it isn't the last.
- **R of a compound room:** `S` is the sum of the beats' `S`, `T` is the sum of `T`, and `C` is the max of `C` +
  0.5 per extra beat (+1.0 for a reused cube). Put these numbers in `DailyDifficulty` constants.
- **Proof:** each beat is verified alone (its plans), and the simulation test also clears whole two-beat rooms
  end to end for a sample of layouts.

---

## 5. Verified tables [TO BUILD; needed before many new modules]

Hand-written `plans()` and `VERIFIED` lists don't scale. Instead:
- **`tools/procgen/verify_modules.gd`** (a SceneTree script, run windowed like the tests) loops over every module,
  every parameter set on its grid and every tier 1–5. For each **sentence the open slots allow**, it builds the
  room (reuse the test helpers' approach: `DailyRun.start("trial", …)`, `DailyRun.spec_override = spec_for(...)`,
  open `DailyRun.SCENE`, `module.perform`, `module.drive`, wait up to 9 s for `room.is_cleared()`). It writes
  `data/daily/verified.json`:
  ```json
  {"version": 3, "source_hash": "<fnv of the module scripts + RuneBook tuning constants>",
   "modules": {"gust_alley": {"mirror=0|lock=0|gap=2|run=4": {"1": ["wind/push/right/normal", ...], "2": [...]}}}}
  ```
- At run time, `sample()` picks only parameter sets present in the table, and `plans()` returns the table's
  sentences for the tier (labels made from the words, for example "Push right, strong").
- **Staleness test:** `daily verified_fresh` recomputes `source_hash` and fails if it differs from the file.
- Keep a safety margin: a sentence counts only if it clears the room **in 3 of 3 runs** (physics can vary).
- Run time is long (minutes), so it is a tool, not part of the default test run.

---

## 6. New modules [TO BUILD, in this order]

Each follows the recipe in section 7. The pieces already exist in the game. **Read the story room named in each row
and copy its setup.**

| Module | Tier | Idea and pieces | Knobs | Concept | Story room to copy |
|---|---|---|---|---|---|
| **Frozen Crossing** | 3 (ice) | A pit too wide to jump; an ice cube carved `ice/-/right/-` builds a bridge (`ice/bridge`), *long* for a wide pit | pit width 3–5 tiles; lock (form open / form+modifier open) | 2 | `tools/levels/build_chapter2.gd` ~line 395 ("Edge Cube", `ice/-/right/long`) |
| **Kindling** | 2 (fire) | Light one or two braziers (`scenes/puzzle/brazier.tscn`, `Brazier.power_changed`) with `fire/projectile`; *split* hits two at once, *up* for a high one; braziers feed a `Circuit` (mode ALL) to the gate | brazier count 1–2, heights, lock | 2 | `tools/levels/build_wings.gd` `kiln_cold_forge()` (~337) |
| **Burn Through** | 2 | A `Burnable` (brambles; signal `cleared`) or `CrackedWall` (signal `broken`, `break_momentum` 660) blocks the way; fire projectile vs *explode* (or a strong wind burst for the cracked wall) | barrier kind, distance | 2 | `scripts/runes/burnable.gd`, `cracked_wall.gd`; Kiln rooms |
| **Prism Relay** | 4 (light) | A `light/beam` must reach a `LightReceiver` via a fixed `Mirror` (`facing` NE/NW/…, `rotatable=false`) or *bounce* | mirror placement, receiver height | 3 | `tools/levels/build_wings.gd` `lamps_hall()` (~1248), "Gallery Cube" (~1282) |
| **Folded Wall** | 5 (space) | A thick wall with a pocket beyond; `space/portal` through it, *long* for a thicker wall | wall thickness 2–4 | 3 | `tools/levels/build_wings.gd` `galleries_archive()` (~1581), "Pillar Cube" (~1654) |
| Together | 2 | `delay` so two things happen at once (a plate and a timed gate) | timing window | 3 | Kiln Heart |
| Still Piston | 3 | `ice/freeze` a piston (`scenes/traps/piston_trap.tscn`) long enough to pass | piston speed | 2 | Cistern rooms |
| Dark Hall | 4 | `light/glow` reveals `SpectralPlatform`s (`mode` REVEALED) | gap count | 2 | Lampworks |

Each new module raises the variety at Hard and above, and lets the bands be tightened later.

---

## 7. Recipe: adding one module

1. **Read** its story room in the builder named in section 6. Note piece scenes, properties, distances, and what the
   story's tests (`tests/wing_suite.gd`, `tests/rune_suite.gd`) do to solve it.
2. **Write** `scripts/daily/modules/<name>.gd` (`class_name <Name>Module extends DailyModule`):
   - Fill in `_init()` (id, title, objective, min_tier, par_seconds).
   - Write `columns`, `sample`, `fallback`, `plans`, `non_plans` and `build`. `build` must call
     `k.guide(room, objective)`, at least one `k.step(...)` per goal, `k.hint(...)` with **three escalating
     lines** (notice, idea, how), torches, and `k.waymarks` only if `params.get("guided", true)`.
   - Write the difficulty hooks: `concept_of`, `open_slots`, and `plan_steps`, `execution_of`, `decoys_of` when
     they differ from the defaults.
   - Write `perform`/`drive` if the player must carry, stand or jump.
3. **Register** the id in `DailyModules.IDS` (append to the end: order matters for seeds) and in `make()`.
4. **Measure:**
   - Add a sweep scenario like `scenario_sweep` to find the real thresholds.
   - Add the layouts to `scenario_simulation`. Every claimed plan must clear its room; one non-plan must not.
5. **Bump** `DailyGenerator.GEN_VERSION`.
6. **Run** `daily difficulty` and check that every band still has ≥ 90% of rooms in band and the means stay
   ordered. Adjust the module's knobs (not the bands) first.
7. **Run** the whole daily suite, then all suites (section 9).

---

## 8. Calibration [stretch]

- After every finished room (daily or Endless), append `{module, params, tier, r, time, resets, hints, deaths}` to
  `user://puzzle_stats.cfg` (local only, capped at 2,000 rows).
- `tools/procgen/fit_difficulty.gd` reads it and prints, per module, the mean solve time against R. It also prints a
  least-squares fit of time ≈ a + b·R and suggests new `WEIGHTS` and `par_seconds`.
- For the submission: a chart of "predicted difficulty vs real solve time" from a playtest group shows the
  measure is real.

---

## 9. Tests and acceptance criteria

All of these go in `tests/daily_suite.gd`. Register each scenario in the table at the top of `run_suite`. Helpers
that already exist:
- `check(label, cond, detail)`, `frames(n)`, `seconds(s)`.
- `open(path)` (loads a scene as the current one), `leave()` (frees it and clears `spec_override`).
- `try_plan(module_id, params, plan, wait, tier)`, `spec_for(params, tier, module_id)`.
- `set_today(day)`, `finish_day(day, score)`, `sample_result(day)`, `shot(name)` (a screenshot to
  `user://test_shots/daily_<name>.png`).

**Existing scenarios (must keep passing):** rng, calendar, kit, generator, score, code, store, persistence,
fairness, cards, level, simulation, look, screens, assembly, difficulty. The whole suite currently reports
**297 passed, 0 failed**.

**New: `endless` scenario.** It must check the following:
1. `DailyRun.start_endless(2, 1234)` gives `mode == "endless"`, `lives == 3`, `endless_k == 0`, and an Endless
   `spec_override` with one room and an `exit`.
2. Open `DailyRun.SCENE`: the level has a room R1, a stair room R2 and a door (`lvl.exit_door != null`); the HUD
   line reads "Room 1" and "Lives 3".
3. Solve room 1 with its first plan (`module.perform(lvl.pieces[0], plan)` plus `drive`), then teleport the player
   into the door. `endless_k == 1` and `run_rooms == 1`, and after the fade a new `DailyRoot` has a different
   digest.
4. Kill the player (`player.take_damage(999)` or `player.die()`) twice: lives 2, then 1, and the same room
   rebuilds each time (same digest). A third death opens an `EndlessCard` of kind `"over"`, and the death screen
   does not restart.
5. Set `DailyRun.endless_k = 9`, then clear a room: a rest card opens, lives go up by one (never above 3), and
   "Keep climbing" loads room 11.
6. `DailyStore.record_endless` keeps the better run (more rooms; on a tie, the higher score). The record survives a
   save/load round trip. A damaged `endless_best` entry is dropped on load.
7. An Endless share code decodes with `endless == true`, and `add_friend` refuses it.
8. Leaving to the title restores the story's conditions (abilities, `kit_override`, flags), the same check as the
   "level" scenario.
9. A screenshot of the HUD, the rest card and the over card (`shot("endless_hud")` etc.). Look at them: the text
   fits, and nothing overlaps the mana/health bars.

**New: `endless_long` (not in the default run).** Drive 30 rooms per starting difficulty through the real
physics, solving each with a known plan. Check:
- every room clears;
- the node count after each room change stays flat (rooms are freed);
- generation takes < 50 ms per room;
- the levels reached follow `DailyDifficulty.ramp`.

**All suites** must still pass:
`daily polish prologue tutorial experience presentation rune chapter adversarial wing`. Four polish checks
("tam/mira/pip/edda draws new art at 1x") fail on the team's base commit too; ignore those. A full run takes
about 30 minutes. Run suites one after another, never two at once (they share `/tmp` logs and the window).

**By hand:**
- An Endless run to a rest stop and to game over on Windows with keyboard and with a pad.
- The handheld build at 640×480 (`bash tools/release/build_handheld_port.sh`): the Endless row fits, pad focus moves
  through it, and room loads are quick.

**Definition of done for the Endless mode:**
- The `endless` scenario passes, the whole daily suite passes, and all other suites pass (apart from the four
  known polish checks).
- Screenshots look right.
- `docs/DAILY_PUZZLE.md`, `docs/IMPLEMENTATION_PROGRESS.md` and `docs/PLAYTEST_CHECKLIST.md` have short Endless
  sections.

---

## 10. Pitfalls already met (save yourself the time)

- **A runtime error in the rune preview** once crashed the daily: `RuneBook.spell()` is called on half-finished
  sentences while the player picks words. Any new `spell()` lookup must use `.get(key, default)`, never
  `dict[key]` on a fragment that may be empty.
- **Two test runners at once** write the same logs and give nonsense. `pkill` doesn't exist in Git Bash; stop
  Godot with PowerShell (`Get-Process Godot* | Stop-Process`). Stopping a background job does not stop its child
  script.
- **`PostFX` needs its `Screen` child** before the node enters the tree (see `_build_player_and_ui`).
- **Physics thresholds are not what the constants suggest:** a pushed crate coasts after the wind stops. Always
  sweep and measure (the `sweep` / `sweep_up` scenarios), and claim only what clears with a margin.
- **Updraft at distance 2** only works with the wide Large column, which makes it a one-answer puzzle. It stays
  excluded.
- **`DailyStore.now_provider`** must be reset to `Callable()` at the end of any test that sets it, or the engine
  can crash at exit.
- **Build order:** `RoomKit.shell` must be called before `make_room`. A room's pieces go under the `Room` node so
  Reset Room can restore them.
- **Title screen:** the word list has 6 entries. Do not add a seventh; Endless lives in the Daily Puzzle screen.
