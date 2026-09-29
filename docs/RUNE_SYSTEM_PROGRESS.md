# Rune-Cube System: progress log

Status of the rune-cube magic and Chapter 2 ("The Sealed Observatory"). Kept current as work
lands. "Automated" means a check in `tests/rune_suite.gd` passed; "inspected" means I looked
at a screenshot from the `look` scenario; **nothing here has been played by a human yet**
(see the Chapter 2 section of `docs/PLAYTEST_CHECKLIST.md`). Sounds were only generated and
checked to exist; nobody has listened to them.

## Launch

- From the title screen: **Chapter 2: The Sealed Observatory** (always offered), or Continue
  after finishing Chapter 1 (its Chapter Complete card now also offers "Continue to the next
  chapter").
- In the editor: open `scenes/chapter/chapter_2.tscn` and press **F6**.
- Rebuild after changing rooms: `godot --headless --path . --script res://tools/build_chapter2.gd`
- Tests: `godot --path . --fixed-fps 60 --script res://tests/run_tests.gd -- rune [scenario]`
  (recipes, r1 ... r8, effects, carry, mana, overview, journal, layout, full; `look` takes
  screenshots only). The `rune` suite is part of `all`.

## Milestones

| Milestone | State |
|---|---|
| M1 core: assembly screen, a cube, a movable object, on/off, wind | Done, automated |
| M2 stacking, mass and breakaway, several cubes, heavy block and spike rooms | Done, automated |
| M3 central mana upkeep, dungeon vs player power, exhaustion, resets | Done, automated |
| M4 Fire / Ice / Light / Space forms, every modifier, environment responses | Done, automated (see gaps below) |
| M5 eight-room chapter, creatures, traps, checkpoints, journal, hints, chapter flow | Done, automated; not playtested |
| M6 polish: sounds, HUD, accessibility, debug view, regression | Done except the items under "Not done" |

## What exists

- **Language** (`scripts/runes/rune_fragments.gd`, `rune_recipe.gd`): 5 essences, 9 forms, 9
  directions, 10 modifiers, each with a vector glyph drawn in code; a rune is four ids in a 2x2
  composite. Gameplay reads ids only. Each cube owns its own recipe.
- **Rules** (`rune_book.gd`): one table of supported essence/form pairs and the directions and
  modifiers each accepts (197 valid combinations; the full list is in
  `docs/CHAPTER2_SOLUTIONS.md`). Anything else is refused with a sentence saying why and costs
  nothing. `spell()` gives the numbers, `describe()` writes the player's text from the same
  numbers.
- **Cubes** (`rune_cube.gd`): solid 32 px stone blocks; states off / on / blocked / no mana /
  broken / carried shown by the rim; locked (carved) quadrants; dungeon-powered, pedestal-fed or
  player-powered; mounted or carryable; `is_powered()` and `power_changed` so they can drive
  circuits and objective steps.
- **Screens** (`ui/`): inscribe screen (pauses; mouse, keyboard and pad), overview on Tab
  (remote switch-off, "Deactivate All Runes"), a HUD strip under the mana bar (a pip per running
  cube with its essence symbol, upkeep per second, "LOW MANA", the room's warding), and the
  **Rune Journal** in the pause menu (fragments known, notes written the first time something
  happens, runes cast).
- **Carrying** (`rune_carrier.gd`, added to the player at runtime): F picks up / sets down; a ghost
  shows the landing spot and, if refused, why (no floor, no room, outside the room, hazard, out
  of reach, moving support); snaps into pedestals.
- **Effects** (`effects/`): wind current (Push, Lift), gust (Burst, Self = outward), fireball
  (the game's own FireBall; Split, Explode), chill (Freeze, via `chill.gd`), ice bridge,
  light beam (the dungeon's own LightBeam; Bounce reflects, otherwise mirrors stop it), glow (a
  magic-light aura), portal (checked before casting; keeps velocity; per-body cooldown). Delay,
  Repeat, Persist, Long, Large and Strong work for every form that accepts them.
- **World pieces**: `wind_body.gd` (crate, stone block, statue), `cracked_wall.gd`,
  `burnable.gd` (brambles and meltable ice), `rune_tablet.gd`, `rune_lectern.gd`,
  `rune_pedestal.gd`, `observatory_seal.gd` (the chapter ending).
- **Chapter 2**: eight rooms, three acts, four shrines, candles over both spike pits, a slime and
  a watcher, a hint stone and objective steps in every room. Room guide:
  `docs/CHAPTER2_SOLUTIONS.md`.

## Decisions (and why)

- **Physics**: movable objects integrate their own motion (gravity + wind / mass; static
  friction until the push beats `0.5 x mass x 980`, then kinetic 0.35 and drag). This makes
  "one wind moves a crate but not a stone; two do" exact and testable.
- **One manager per level** (`rune_manager.gd`) runs before anything moves each physics frame:
  for each object it adds one share per active wind field, never normalising the sum.
- **Obstruction**: walls and gates stop wind (the drawn region is cut to match); an object counts
  if any of three rays from the face reaches it; iron grates (`wind_permeable`) let wind through;
  loose objects don't shield each other (simpler to read, and to design around).
- **Mana**: `player.current_mana` is the only mana. Upkeep drains continuously; a sustained rune
  needs two seconds of upkeep in hand to start (this is what makes Room 7 airtight); running dry
  shuts down every sustained player-powered rune once, with no auto-restart; regeneration
  (20/s after 1.2 s) only while none of her runes runs (repeating and timed ones included);
  refilling with R is refused while they draw. Reset Room restores the mana she entered with.
  A room can hold mana down with `Room.mana_limit` (Room 7: 10).
- **The player is not replaced**: `player.gd` only gained `reload_locked` and a check in
  `start_reload()`; wind reaches her through a `PlayerWind` child (drift 0.03 px/s per unit of
  force, i.e. ~36 px/s in a normal wind; updraft acceleration equal to the force, rise capped at
  190 px/s), carrying through a `RuneCarrier` child.
- **Rooms own their cubes**: leaving a room stops its runes; a cube carried out drifts home;
  Reset Room stops runes first (new `ChapterRoot.room_resetting` / `room_reset_done` signals).
- **Ice bridges** start at the top edge of the cube's face (a cube set into a pit edge, flush
  with the floor, continues the floor); they are one-way from below so they can't trap anyone.
- **Solids** (cubes, cracked walls, brambles, bridges) sit on layers 1+2 so fireballs splash on
  them like on walls.

## Configuration notes (where to tune)

| What | Where | Value |
|---|---|---|
| Wind force normal / strong | `rune_book.gd` WIND_FORCE | 1200 / 2400 |
| Wind reach / Long | WIND_REACH | 320 / 560 px |
| Wind width / Large | WIND_WIDTH | 96 / 288 px |
| Gust impulse | BURST_IMPULSE | 420 (Strong 840) |
| Freeze time, bridge span and time | FREEZE_TIME, BRIDGE_SPAN, BRIDGE_TIME | 6 s, 224 px, 10 s |
| Beam range, glow radius, portal range | BEAM_RANGE, GLOW_RADIUS, PORTAL_RANGE | 900, 104, 224 px |
| Delay, start requirement | DELAY, START_SECONDS | 2 s, 2 s of upkeep |
| Upkeeps and cast costs | `spell()` in `rune_book.gd` | see the recipe table |
| Crate / stone / statue | `wind_body.gd` PRESETS | mass 1 / 3 / 6, mu 0.5 static, 0.35 kinetic |
| Mana regeneration | `rune_manager.gd` REGEN_DELAY, REGEN_RATE | 1.2 s, 20/s |
| Player drift and lift | `player_wind.gd` | 0.03 per force, rise cap 190 px/s |
| Cracked wall | `cracked_wall.gd` break_momentum (per wall) | 800 in Room 4 |
| Room mana limit | `Room.mana_limit` (per room) | 10 in Room 7 |

## Files

New: `scripts/runes/` (rune_fragments, rune_recipe, rune_book, rune_cube, rune_manager,
rune_carrier, player_wind, rune_effects, wind_body, chill, cracked_wall, burnable, rune_tablet,
rune_lectern, rune_pedestal, observatory_seal; effects/ wind_field, wind_burst, rune_fire,
freeze_field, ice_bridge, rune_beam, rune_glow, rune_portal; ui/ rune_assembly, rune_overview,
rune_hud, rune_journal), `tools/build_chapter2.gd`, `scenes/runes/*.tscn`,
`scenes/chapter/chapter_2.tscn`, `tests/rune_suite.gd`, 23 sounds in `assets/audio/sfx/`,
`docs/CHAPTER2_SOLUTIONS.md`.

Changed (small, local): `scripts/player.gd` (reload lock), `scripts/pressure_plate.gd`
(`objects_only`, `stone_weight`), `scripts/puzzle/chapter_root.gd` (room signals,
`next_chapter`), `scripts/puzzle/room.gd` (`mana_limit`), `scripts/puzzle/light_beam.gd`
(`reflects`), `scripts/puzzle/hint_stone.gd` (key names in hints), `scripts/ui/pause_menu.gd`
(journal; Esc ignored while another screen has the game paused; ledger hidden in chapters
without pages), `scripts/ui/chapter_complete.gd` (continue button), `scripts/ui/title_screen.gd`
(Chapter 2 entry), `scripts/ui/settings_panel.gd` and `project.godot` (two new actions),
`tools/build_chapter.gd` (Chapter 1 points on to Chapter 2; its rebuilt scene differs only by
that property and regenerated node ids), `tools/generate_sfx.gd` (new sounds appended; all 64
existing files byte-identical), `tools/audit_wall_tiles.gd` (also checks Chapter 2),
`tests/run_tests.gd` (rune suite in `all`), README.

## Test record

- 2026-09-29, each scenario on its own: recipes 13/13, r1 21/21, r2 17/17, r3 8/8, r4 14/14,
  r5 10/10, r6 9/9, r7 13/13, r8 10/10, effects 24/24, carry 8/8, mana 12/12, overview 4/4,
  journal 25/25 (includes a room-1 solve), layout 12/12 (these two only inside the full run),
  full (all eight rooms in one run, to the Chapter Complete card) 104/104.
- Full regression (`all`): see "Latest full run" below.
- Inspected screenshots: every room, the inscribe screen, the overview, the carry ghost, the
  updraft, the ice bridge, the beam on the frozen watcher, the freeze field, the portal and the
  F3 debug view. Fixed after inspection: faint wind streaks, glyphs overlapping fragment names,
  the HUD calling a player-paid timed bridge "powered by the dungeon", a sign covering the Room 6
  beam, the refused-ghost reason now shown without pressing F.
- Bugs the tests caught and I fixed: wind drift too strong to walk back against in Room 2;
  `is_open` methods on the new wall/brambles clashing with the objective steps' property check;
  freed gust effects still referenced; mana regenerating under a repeating rune; Room 7's
  statue stopping short (plate and kerb moved); Room 7 could be brute-forced by short bursts
  (fixed by the two-seconds-in-hand start rule).

### Latest full run

- 2026-09-29, `all`: **856 passed, 0 failed** (tutorial 140, chapter 274, presentation 88,
  experience 59, rune 295). No script errors in the log. The earlier suites are unchanged in
  count and still pass, so nothing in Chapter 1 or the tutorial regressed.
- Added after that run, and run on their own (`rune effects`, 24/24): a normal updraft lifts a
  crate but not a stone block; a normal beam stops at a mirror and a Bounce beam reflects; a
  Persist bridge outlasts ten seconds at ~5 mana a second and melts when switched off; a rune
  fireball burns brambles and an Explode blast in reach does too. The next `all` run will
  include them (rune suite should then be 304).
- Performance (RTX 3060, windowed, every valid rune in the room switched on): 165 fps average in
  all eight rooms (the display's cap), worst single frame 8.6-10.1 ms.

## Not done / known gaps (honest list)

- No human has played Chapter 2; difficulty, clarity and feel are unknown.
- Sounds are synthesised and unheard; the wind loop in particular may need level tuning.
- Wind does not push creatures (slimes, watchers); it pushes crates, stones, statues and Echidna.
- The Lantern Wisp is not used in Chapter 2 (the spec listed it among the creatures).
- The journal logs runes cast; there is no "saved recipe" you can stamp onto another cube.
- Glow, Explode, Persist, Bounce and Lift-on-objects are checked in the effects scenario, not by a
  room that needs them. Fire Repeat, Freeze Persist/Long/Large and Portal Normal are covered only
  by the recipe rules (valid, described, costed), not by an in-game check.
- The measured frame rate is on a fast desktop GPU only; no integrated-GPU measurement.

## Next task

Human playtesting with `docs/PLAYTEST_CHECKLIST.md` (Chapter 2 section), then tuning from what
testers say (wind drift, bridge time, Room 7's difficulty, sound levels).
