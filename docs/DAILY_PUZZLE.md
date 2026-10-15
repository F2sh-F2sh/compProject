# The Daily Puzzle and generated levels

A new puzzle every day, the same for everyone, built in code from a seed, with a score, a streak and a board,
and an *Endless* run with a fresh seed and a choice of four starting difficulties. It lives next to the story and does not touch it:
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
   machine and engine version. `GEN_VERSION` is mixed in to separate generator revisions; the current version is 6.
2. **Difficulty by weekday.** Mon/Tue gentle (3 rooms), Wed/Thu steady (4), Fri/Sat hard (4), Sunday grand (5).
   Each room is aimed at its difficulty's band of the measured difficulty score R (`DailyDifficulty`; how R is
   computed, the bands and word tiers: `docs/PROCGEN_DESIGN.md`).
3. **Rooms.** Each room is drawn from the module library (below), preferring a different mechanism from the previous room. A narrow intermediate Endless band may repeat its only suitable mechanism, using fresh sampled layout parameters, rather than drop below the promised difficulty. The
   parameters are drawn from the physics-verified table; a draw is kept only if `DailyOracle` finds at least two ways
   to solve it and its R lies in the band (sixteen salted tries; else the closest two-way draw), then the
   module's hand-checked fallback. It never hands back a puzzle
   that fails the oracle.
4. **Build.** `RoomKit` (a run-time port of the story builders' helpers) paints the tiles and places the
   pieces; rooms share a wall column like the story's; a short bell hall ends the puzzle.
5. **Play.** `DailyRoot extends ChapterRoot`, so the HUD, hints, Reset Room, pause menu and rune screens are the
   story's own. Dying reloads the scene: the same seed rebuilds the same puzzle and she starts in the furthest
   room reached (earlier gates stay shut behind her).

Daily, Practice and Endless suppress the automatic rune-cube tutorial during a run. Help remains available
from the pause menu's **How rune cubes work** action. This does not mark the story tutorial as seen or alter
the story save. The `daily cube_help` regression enables UI tours and checks cube approaches, reloads,
explicit help and restoration of the story's tutorial flag.

## The module library

All measured in the real physics (`tests/daily_suite.gd`, scenario `simulation`): every way listed is fired
through the actual rune cubes and has to clear the room, and the ways ruled out have to fail.

| Module (story room it follows) | The idea | Ways it accepts | Envelope |
|---|---|---|---|
| **Gust Alley** (Observatory R1) | Blow a crate onto a plate with a wind cube whose direction/form is open | `wind/push` along the carved heading with Normal, Strong (tier 1); Long, Large (tier 3) | gap 2-3, run 3-5 (shorter when gap is 3), mirrored or not, two lock variants |
| **Dead Weight** (Observatory R2) | A stone one normal wind can't move | one **Strong** wind, or **two winds** (carry the loose cube beside the fixed one) | six verified layouts |
| **Updraft** (Observatory R3) | A wall too high to jump, a cube carved "Up": Push can't blow up, Lift can | `wind/lift/up` with Normal, Strong (tier 1); Long, Large (tier 3) | wall 3 or 4 tiles high, 3-4 wide, right beside the cube |
| **Frozen Crossing** | Shape ice over a pit, then cross | Bridge Right with Normal, Long or Persist | widths 3–5; layouts with only one valid inscription are excluded |
| **Kindling** | Light the marked bowls, including a raised or second bowl | Fire projectiles; Split and Explode reach paired bowls | floor, hanging and paired bowls, with two lock variants |
| **Burn Through** | Burn brambles or drive a heavy stone into cracked masonry | Fire projectiles; Strong Push and Strong Burst use different stone routes | bramble distances 2–3; cracked-wall distance 2 |
| **Prism Relay** | Turn a beam through fixed mirrors into a crystal | Bounce Right or Up | mirror/receiver distances 2–3 |
| **Folded Wall** | Fold a doorway across foreground masonry | Portal Right, Normal or Long | widths 2–3; width 4 has only one solution and is excluded |
| **Together** | Feed a plate and temporary fire circuit together | Plain, delayed or repeated fire with a timed run | burn windows 1.0 or 1.5 seconds |
| **Still Piston** | Freeze a raised ram and pass underneath | Freeze Right with verified duration/coverage modifiers | slam speeds 400 or 520 |
| **Dark Hall** | Reveal solid stepping stones with magical light | Glow Self, Normal or Large | one or two gaps around a central pillar |

How far a push carries a crate was measured, not guessed (Gust Alley): a wind pushes while the crate is inside the
cube's 320 px reach (560 with Long), then it coasts about 81 px (Normal) or 153 px (Strong). Updraft's one-column
gap was dropped because only the wide Large column reached the wall: a one-answer puzzle.

## Fairness

- Everyone gets the **same words**: `RuneManager.kit_override` (set by `DailyRun.apply`) replaces the story's
  vocabulary with a tier from `DailyKit` (the story's own word order: start words + Observatory, then Kiln,
  Cistern, Lampworks, Galleries: 6, 52, 98, 145, 197 sentences).
- Heal is available throughout. Personal Fire is explicitly allowed in single Kindling/bramble rooms below Grand;
  elsewhere Fire and Echo are sealed so they cannot replace the rune mechanisms. Room objectives name this rule.
  Physical solutions (such as pushing a light crate) remain valid where the geometry permits them. Creatures are off. The story's save, flags and Continue are untouched
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

## Further ideas

The solution codex, medals, a separate Sunday Grand board and an online board remain outside the
`PROCGEN_DESIGN.md` expansion. Endless, verified tables, two-beat rooms and the eight specified new modules
are implemented below.

## Endless and the expanded generator

The Daily Puzzle menu offers Endless at Gentle, Steady, Hard and Grand. Each room ends at a glowing stair door. A run has three lives, gains a quarter difficulty step every five completed rooms (capped one level above its start), and offers a rest with one life restored every ten rooms. Records are separate for each starting difficulty and are saved after each completed room in `user://daily.cfg`; story saves and vocabulary are restored when leaving. Endless share codes encode rooms climbed and average points per room and cannot be added to the daily board.

Hard may chain two puzzles. Grand and Master always chain two mechanisms and require carrying and reinscribing a shared cube. Their second mechanism requires vertical wind, hidden-stone light, or reflected light, so walking, jumping or a personal fireball cannot finish the whole room. Both beats require meaningful word choices and incompatible inscriptions. Grand targets R 8–12; Master targets R 10–15. The module library adds Frozen Crossing, Kindling, Burn Through, Prism Relay, Folded Wall, Together, Still Piston and Dark Hall using the existing story puzzle nodes. Only layouts with at least two measured solutions should be sampled from `data/daily/verified.json`. Unsupported layouts stay in the offline sweep but are excluded from generation.

Regenerate the solution table with Godot's native runner: `godot --path . --windowed --fixed-fps 60 --disable-vsync --script res://tools/verify_modules.gd`. An optional module id after `--` limits the sweep. Each retained inscription must solve three independent runs; identical dungeon-powered physics measurements are reused across vocabulary tiers, while each tier's allowed inscriptions are enumerated separately. The table records its source fingerprint and completion state. `daily verified_fresh` checks both. Bump the generator version when generation changes.

Local calibration keeps the last 2,000 completed-room observations in `user://puzzle_stats.cfg`. `godot --path . --headless --script res://tools/fit_difficulty.gd` reports module means, a least-squares time/R fit and exploratory coefficients for the difficulty parts. These are suggestions, not automatic tuning changes or substitute player-study data.

Daily menus and generated levels use the physical window's canvas size so 640×480 text stays readable. Closing the menu or leaving the run restores the story's authored canvas size. The existing rune-status strip and the Endless room/lives row occupy separate lines below the mana bar. Compact menus and end cards scroll to keep focused buttons visible.

`tools/fit_difficulty.gd` also exports validated observations to `user://difficulty_observations.csv` (an optional second argument chooses its output path). Run `python tools/plot_difficulty.py <observations.csv> <chart.png>` to draw predicted R against recorded solve time. This optional developer tool requires matplotlib; the game and Godot fitter do not depend on Python. Use participant observations for submission charts; automated solver timings are not human playtest evidence.

The version-4 balance revision lends tier 4 (including light) to Grand, and tier 5 (including space) to Master. This broadens the harder rooms beyond repeated wind puzzles. The original tier/band table in `PROCGEN_DESIGN.md` predates this revision. Existing results remain stored; version-4 seeds and share codes distinguish the revised puzzles.

Version 5 closes reproduced Grand shortcuts: internal doorways have solid masonry above their gates, unlit crossing exits wait for their magical prerequisite, and a reused cube only counts as rising wind when it is actually running upward Lift in the second passage. `daily grand_cheese` exercises charged cube-step jumps, unlit pit jumps, through-gate placement, heavy-stone pushing and a continuous legitimate carried-cube route. `daily grand_corpus` checks two full physics solutions for each mechanism pairing found across 1,000 generated Grand seeds, with separate bramble/cracked-wall and dark-gap variants. These are automated native-engine checks; they do not prove every possible player route.

Version 6 repairs the intermediate Endless curve. Fractional levels select toward the centre of their interpolated band instead of accepting the same overlapping draw as the base difficulty. Hard +2/+3 always use two beats, with each beat selected for the increasing level. Suitable mechanisms are filtered before applying the previous-room exclusion; this prevents Gentle +1 from dropping back to a base-level room when Updraft is its only in-band mechanism.

`daily scale_audit` checks 500 seeds at each named level, 250 at each of the 17 quarter levels, and 150 complete 25-room sequences for each of the four selectable starting levels. It verifies mean/median ordering, band coverage, minimum solution counts, chalk guidance, personal-spell rules, actual menu dispatch and two physical solutions for each sampled low/high extreme. The latest machine-readable result is `docs/DIFFICULTY_SCALE_AUDIT.json`. R estimates structural complexity; these results are not measured human solve times.

Version 7 extends shortcut protection to standalone generated mechanisms. Dark Hall, Frozen Crossing and Still Piston cannot open their exits through a far-side touch alone; Updraft now has an actual goal-controlled exit. Resetting a solved room closes the exit and a fresh solution opens it again without awarding a second clear. Falls below the generated dungeon's bedrock use the normal death flow and consume one Endless life.

Generated horizontal portal doorways have an opt-in eight-pixel floor clearance, so a legally carried and placed Master cube can activate. Authored story portals retain their original positions. Folded Wall's retained inscriptions were rechecked three times each; other standalone templates cannot cast portals and retain their unchanged physics proofs. The global verification fingerprint still covers every rune effect.

`daily all_cheese` attacks all 17 difficulty steps with real walking, sprinting, ordinary and charged jumps, plus standalone far-bank bypasses, floor-placed portals and pit deaths. `daily reset_solutions` solves, resets and re-solves every named difficulty with a different valid inscription, checking gates, controls and scoring. Both are included in the default Daily suite. Fixture positioning and the separate valid-solution solver use explicit setup teleports; movement attacks do not teleport between objectives. These are automated native-engine tests on an isolated desktop, not exhaustive route coverage or manual human playtesting.

The optional `daily all_corpus` scans 1,000 seeds per named difficulty and groups their observed mechanism pairings and relevant geometry (barrier kind, wall/platform width, gap count, platform height, hanging targets and mirroring). Each representative rejects sprint/jump/charged-jump-only completion and retains two distinct full physics solutions. It complements the quarter-step attack sweep; neither corpus claims to enumerate every inscription, timing or possible object arrangement.

Fractional Hard chains reuse bounded cached scores for identical layouts and vocabulary instead of recomputing them throughout the nested salt search. Offline bypass calculations are not cached. This optimization preserves the random sequence and puzzle data; a before/after comparison checked 460 complete generated outputs, including all quarter levels and four 30-room Endless sequences.

Version 8 fixes the actual Master handoff: a reused Folded Wall cube can be carried while its portal remains anchored at the original doorway positions. This exception applies only to that generated shared cube, while its effect is a portal. Other active cubes retain the switch-off-before-moving rule. Place the cube, switch the portal off and reinscribe it for the second passage. Destination checks include the carried cube's full shape. The contextual room instructions explain the exception; authored story portals are unchanged.

Resetting now suppresses both parent objective credit and challenge progress throughout the fade, while challenge time continues. A moving stone could previously break its wall during that fade and bank an abandoned room clear before the reset restored the wall. Resetting cannot trigger an Endless exit transition either.

New default regressions: `daily combo_resets` tests legal inscriptions and live-effect resets at all 17 steps (including pre-carved words above the lent vocabulary); `daily placement_resets` covers fixed-cube restrictions, legal pickups, closed exits, unsupported gaps, held-cube recovery and reset spam; `daily impact_reset` reproduces the moving-stone scoring race; `daily portal_handoff` completes a Master route using actual pickup, movement, portal traversal, placement and reinscription; `daily portal_limits` checks late destination obstructions and cancellation while holding the active portal cube. Optional `daily unlocked_combos` tries every learned non-Lift sentence after legitimately unlocking, carrying and placing a shared cube in Grand/Master. Unrelated spells must not counterfeit the wind milestone; valid alternative solutions are not rejected merely for differing from the oracle's plan list.

The whole verification fingerprint now includes the generated root, chain and carrier as well as the effect library. Module-level proofs still resume only when their measured source dependencies match. Version-8 verification metadata and the difficulty audit are recorded with the code.

Portal clearance now checks whichever cube Echidna is holding, including an inactive cube from another stage carried backward through a stationary portal. Previously only the portal's own shared cube was checked, allowing other cargo to overlap the mounted portal cube at the receiving doorway. Transfers must fit the traveller and cargo inside their room bounds and clear solid geometry. This correction does not change the generated layouts or share-code version.

Additional default regressions: `daily portal_cargo` reproduces the reverse-cargo overlap against actual mounted-cube geometry; `daily portal_reset_spam` sends repeated reset requests immediately before and at 0/1/18 frames after actual normal/long portal warps through two- and three-column walls; `daily stage_reset_spam` clears a first stage then races movement and reset requests at its gate at all 17 difficulty settings. First-stage solution setup and boundary positioning use fixtures; warp movement, pickup and reset cancellation use native engine physics. `daily portal_handoff` also checks a reverse trip and repeated forward handoff while carrying the shared cube.

Camera resize callbacks ignore detached cameras. Endless transitions restore the story canvas while the previous root is waiting for deletion; its still-connected camera previously attempted to query a viewport after leaving the scene tree.

Version 9 checks difficulty floors and repetition together. If random single-room draws miss an available in-band configuration, the generator searches the verified alternatives instead of quietly substituting an easier room. Hard requires an open form or direction somewhere in the puzzle; Grand and Master require that meaningful choice in their first stage. Their shared cube still opens all its slots for the second stage. Folded Wall adds verified variants with the Portal form left for the player to discover; legacy pre-carved variants remain available for easier fixtures and existing scenes.

Lower Hard uses meaningful single mechanisms; its upper quarter steps use two beats. Named Grand/Master retain broad in-band selection. Their fractional ramp targets the measured attainable named-level means (11.1 to 12.9), avoiding the previous dip from Grand into its first quarter step. The renewed scale audit checks all named and quarter settings, actual sequential history and physical solutions; structural R remains an estimate, not measured human difficulty.

Each Daily run avoids configurations already generated in that run. Endless keeps four banked configuration signatures and prefers unused configurations, rotating the oldest when a narrow band has too few alternatives. Signatures include mechanics, geometry and rune locks, and ignore decorative randomness and chalk guidance. History changes only on banking a completed room, so deaths and resets do not reroll puzzles. New run starts clear it. Selection does not trade its difficulty band for variety. Gentle fractional stages can still repeat the same mechanic because the verified library has few qualifying variants.

`daily variety` checks the difficulty floors, meaningful choices, within-run duplicate configurations, immediate Endless repeats and deterministic regeneration. It joins the default native suite. Version-9 seeds/share codes distinguish these generation changes; existing records and story gameplay are preserved.

Version 10 expands Gentle's qualifying Updraft configurations from four to twelve. Alongside the level ridge, rooms can descend through terraces or offer a lower landing after the first rise. All use the same first-rise height, vocabulary, locked rune words, modifier choices and structural score. They introduce no new hazards or timing requirements. The tiles remain grounded masonry in the existing dungeon style. Legacy parameters without `profile` retain the original ridge.

`daily gentle_profiles` checks all twelve Gentle configurations for unchanged difficulty/choices, charged-jump bypasses, continuous normal-wind traversal and reset recovery. It also checks varied ground shapes and four-room history in fifty Gentle sequences. The three terrain profiles were verified in the native physics table, with three runs for each admitted inscription. The updated same-seed audit found zero recent repeats across 8,000 Endless configurations; signatures still ignore decorative randomness. This is a four-room repetition window, not a promise that finite puzzle configurations never recur later.
