# The Daily Puzzle and generated levels

A new puzzle every day, the same for everyone, built in code from a seed, with a score, a streak and a board,
and a *Random trial* that builds a different level every time. It lives next to the story and does not touch it:
the story's levels, builders and save are unchanged.

## Why it exists (the problem it addresses)

The team's problem statement is *building critical thinking and problem solving through a puzzle game*
(sources and wording: the plan in `.claude/plans`, and `docs/IMPLEMENTATION_PROGRESS.md`). The daily puzzle is the
part of the game that serves it directly:

- **No walkthrough to copy.** A seed makes a new puzzle; the answer to yesterday's doesn't help.
- **Many ways to solve a room.** Each room accepts any rune sentence that works; the end card says how many
  ways there were and which one you found.
- **Thinking before acting is rewarded.** Casting runes at random, resetting and asking for hints all cost points.
- **A reason to come back.** A short daily puzzle, a streak (with one forgiven missed day a week), personal
  bests and a board to compare with friends.

## How a day is made

`DailyGenerator.generate(seed, difficulty, tier)` returns plain data; `DailyRoot` builds it.

1. **Seed.** `DailyGenerator.seed_for_day(day)`: FNV-1a of `"belfry-daily|v<GEN_VERSION>|<day>"`. A day number is
   days since 2026-01-01 of the *local calendar date* (`DailyRng.day_index`). All random numbers come from
   `DailyRng` (xorshift32); Godot's `hash()`/`randi()` are not used, so a seed gives the same puzzle on every
   machine and engine version. `GEN_VERSION` is mixed in: change the generator, bump it, and old dates keep
   their old puzzles.
2. **Difficulty by weekday.** Mon/Tue gentle (3 rooms), Wed/Thu steady (4), Fri/Sat hard (4), Sunday grand (5).
   Each room is aimed at its difficulty's band of the measured difficulty score R (`DailyDifficulty`; how R is
   computed, the bands and word tiers: `docs/PROCGEN_DESIGN.md`).
3. **Rooms.** Each room is drawn from the module library (below), never the same module twice in a row. The
   parameters are drawn from the module's envelope; a draw is kept only if `DailyOracle` finds at least two ways
   to solve it and its R lies in the band (sixteen salted tries; else the closest two-way draw), then the
   module's hand-checked fallback. It never hands back a puzzle
   that fails the oracle.
4. **Build.** `RoomKit` (a run-time port of the story builders' helpers) paints the tiles and places the
   pieces; rooms share a wall column like the story's; a short bell hall ends the puzzle.
5. **Play.** `DailyRoot extends ChapterRoot`, so the HUD, hints, Reset Room, pause menu and rune screens are the
   story's own. Dying reloads the scene: the same seed rebuilds the same puzzle and she starts in the furthest
   room reached (earlier gates stay shut behind her).

## The module library

All measured in the real physics (`tests/daily_suite.gd`, scenario `simulation`): every way listed is fired
through the actual rune cubes and has to clear the room, and the ways ruled out have to fail.

| Module (story room it follows) | The idea | Ways it accepts | Envelope |
|---|---|---|---|
| **Gust Alley** (Observatory R1) | Blow a crate onto a plate with a wind cube whose direction/form is open | `wind/push` along the carved heading with Normal, Strong (tier 1); Long, Large (tier 3) | gap 2-3, run 3-5 (shorter when gap is 3), mirrored or not, two lock variants |
| **Dead Weight** (Observatory R2) | A stone one normal wind can't move | one **Strong** wind, or **two winds** (carry the loose cube beside the fixed one) | six verified layouts |
| **Updraft** (Observatory R3) | A wall too high to jump, a cube carved "Up": Push can't blow up, Lift can | `wind/lift/up` with Normal, Strong (tier 1); Long, Large (tier 3) | wall 3 or 4 tiles high, 3-4 wide, right beside the cube |

How far a push carries a crate was measured, not guessed (Gust Alley): a wind pushes while the crate is inside the
cube's 320 px reach (560 with Long), then it coasts about 81 px (Normal) or 153 px (Strong). Updraft's one-column
gap was dropped because only the wide Large column reached the wall: a one-answer puzzle.

## Fairness

- Everyone gets the **same words**: `RuneManager.kit_override` (set by `DailyRun.apply`) replaces the story's
  vocabulary with a tier from `DailyKit` (the story's own word order: start words + Observatory, then Kiln,
  Cistern, Lampworks, Galleries: 6, 52, 98, 145, 197 sentences).
- Everyone has fire, heal and echo; creatures are off. The story's save, flags and Continue are untouched
  while a run is on, and put back afterwards (`DailyRun.restore`).
- Assists are allowed (accessibility) and recorded as a bitmask in the result and the share code.
- The first completion of *today's* date is ranked; later runs are practice.

## Score

1000, minus: time over par (up to 300), 40 per Reset Room (200), 60 per hint (240), 25 per death (150), 10 per
cast beyond two a room (150). Three stars: 800 points and no hints; two: 500; a finished run is one.
(`DailyScore`.)

## Streak, the clock and the board

- Streak: a ranked completion on consecutive days. One missed day a week is forgiven (a "mend"); two missed
  days break it.
- Clock: ranked needs a date that is not before this build (2026-10-10) nor before a day already seen. A
  handheld with no battery clock reports 1970: practice stays open, the daily says why.
- Board: you, friends whose **share codes** you pasted (`SB1-XXXXX-...`, 16 bytes with a checksum, no server),
  and a "perfect run" row for reference. On the handheld, put `Name CODE` lines in `user://friends.txt`.
- Nothing is sent anywhere. The file is `user://daily.cfg` (`DailyStore`), validated on load.

## Files

`scripts/daily/`: `daily_rng`, `daily_kit`, `daily_module` + `modules/*`, `daily_modules`, `daily_oracle`,
`daily_generator`, `room_kit`, `daily_root`, `daily_run`, `daily_score`, `daily_store`.
`scripts/ui/`: `daily_menu`, `daily_complete`. `scenes/daily/daily.tscn` (just the root script).
Small additions elsewhere: `RuneManager.kit_override`, `LevelTheme.BY_CHAPTER["daily"]`, a title menu word.

## Adding a module

1. Subclass `DailyModule` in `scripts/daily/modules/`: `columns`, `sample`, `fallback`, `plans`, `non_plans`,
   `build` (return `{"cubes": {...}}`), and `perform`/`drive` if a player must carry something or move.
2. Register it in `DailyModules`.
3. Add its layouts to `scenario_simulation` in `tests/daily_suite.gd` and run
   `... run_tests.gd -- daily simulation`. Claim only what passes. Sweeps for measuring thresholds:
   `daily sweep`, `daily sweep_up`.

## Not built (yet)

The Endless mode, verified tables, two-beat rooms and more modules are specified in `docs/PROCGEN_DESIGN.md`.
Modules 4-7 (Kindling, Fractured Seal, Frozen Crossing, Prism Relay), the solution codex, medals, the Sunday
Grand's own board, an online board. See the plan.
