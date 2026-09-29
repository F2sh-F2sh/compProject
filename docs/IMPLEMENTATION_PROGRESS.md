# Implementation Progress — Chapter 1: The Sealed Belfry

Living record of the puzzle-chapter work. Companion documents:
[CHAPTER1_SOLUTIONS.md](CHAPTER1_SOLUTIONS.md) (room-by-room solutions, resets, failure
states) and [PLAYTEST_CHECKLIST.md](PLAYTEST_CHECKLIST.md) (what a human still needs to judge).

## Baseline (Milestone 0)

- Engine: Godot 4.7.2 (Forward+, D3D12). No engine, renderer or project-setting changes
  beyond new input actions, autoloads and one physics layer name.
- Branch: `teammate-work`. All of this work is **uncommitted** in the working tree. Nothing
  has been committed or pushed.
- Existing systems reused, not replaced: player controller, health/mana, fireball, heal,
  mana reload (R), Echo recording (E) with temporal debt, spike recovery vs real death, the
  death screen, lighting (CanvasModulate + FlickerLights + occluders + PostFX).
- Measured movement (by the tests): walk 115 px/s, sprint 220 px/s, tapped jump ~62 px up,
  fully charged jump ~132 px up, walking jump ~82 px across, sprint jump ~157 px across.
- Baseline tutorial suite: 111/111 before any chapter work.

## Status: all milestones implemented and passing automated tests

Last full run: `tutorial suite: passed=111 failed=0`, `chapter suite: passed=216 failed=0`,
`presentation suite: passed=82 failed=0` (`RESULT passed=409 failed=0`). All 73 scripts compile.

| Milestone | Status |
|---|---|
| 0 Baseline | Done |
| 1 Shared vocabulary, reset, saving, audio, pause/settings, Room 1 | Done, tested |
| 2 Creatures (Bellbound Slime, Watcher Gargoyle, Lantern Wisp) and rooms 2, 3, 4, 6 | Done, tested |
| 3 Traps (retracting spikes, solid crushers, bolt statues, crumbling ledges, vents, lift) and room 5 | Done, tested |
| 4 Chapter flow: 4 shrines, 2 persistent shortcuts, finale seal, tutorial → chapter → next level | Done, tested |
| 5 Presentation, audio, accessibility pass | Done; needs human judgement (see checklist) |
| 6 Regression tests and docs | Done |

## How to run

- Play: run the project (main scene is still the tutorial; its exit door leads to the
  chapter) or open `res://scenes/chapter/chapter_1.tscn` and press F6.
- Rebuild the chapter after changing the builder:
  `godot --headless --path . --script res://tools/build_chapter.gd`
  (this **overwrites** `scenes/chapter/chapter_1.tscn` and the component scenes in
  `scenes/puzzle`, `scenes/creatures`, `scenes/traps`).
- Tests (need a window, not `--headless`, because they take screenshots and aim the mouse):
  `godot --path . --fixed-fps 60 --script res://tests/run_tests.gd -- [tutorial|chapter] [scenario]`
  Chapter scenarios: `r1`…`r7`, `save`, `reset`, `hazards`, `full`, and `look`
  (screenshots of every room into `user://test_shots/`, not run by default).
- Regenerate the sound effects: `godot --headless --path . --script res://tools/generate_sfx.gd`
  then let the editor import them.

## Architecture

- **Autoloads:** `GameState` (flags, last shrine, save file `user://savegame.cfg`),
  `Settings` (master/effects volume, reduce motion; `user://settings.cfg`), `Sfx`
  (positional one-shot sounds with throttling).
- **Power protocol:** sources emit `power_changed(bool)` and answer `is_powered()`;
  consumers implement `set_powered(bool)`. `Circuit` joins them (All/Any, invert, latch,
  hold time, persistent id, optional camera reveal) and draws the violet grooves.
- **Reset protocol:** nodes in group `resettable` implement `reset_state()`; `Room.reset()`
  calls them. Persisted latches re-power their targets after a reset.
- **Light rule:** `MagicLight` (beams: `LightBeam` raycasts with mirror bounces; auras:
  radius + line of sight). Solid things block both. Torches never count.
- **Loading rule:** gates and the seal snap to saved state during the first two physics
  frames, then animate normally.
- **Chapter:** `ChapterRoot` (rooms, camera bounds per room, room titles, toasts, Reset Room,
  shrine respawn); `Room` (bounds, entry spawn, title); `PauseMenu`.
- **New pieces:** `scripts/puzzle/` (circuit, interactable, pushable_block, lever, room,
  chapter_root, chapter_checkpoint, lore_page, hint_stone, magic_light, light_beam, mirror,
  light_receiver, brazier, light_lens, spectral_platform, wisp_perch, puzzle_bell,
  rune_seal, iron_grate), `scripts/creatures/` (lantern_wisp, watcher_gargoyle),
  `scripts/traps/` (arcane_bolt, arcane_bolt_statue, crumbling_platform, magic_vent,
  moving_platform), `scripts/ui/pause_menu.gd`, `scripts/autoload/`.
- **Upgraded existing scripts:** `pressure_plate.gd` (power, latch, stone-only plates),
  `portcullis_gate.gd` (power, reset, load snap), `fireball_switch.gd`, `piston_trap.gd`
  (solid head, sideways push, eject), `retracting_spikes.gd`, `slime.gd` (bells, lunge
  telegraph, room-reset respawn), `camera_bounds.gd` (room slides, shake, focus, clamped
  offsets), `player.gd` (block pushing, hurt sound, reduced flash).

## Verification record

### Automated (tests/chapter_suite.gd, tests/tutorial_suite.gd)
- Every room solved with simulated input and real movement; one continuous run through all
  seven rooms; camera never leaves the current room's bounds.
- Room-specific rules (see the checklist's last section for the full list): kerb stops the
  block; both-plates rule; bell by rope and by fireball; reset revives puzzle slimes and
  never heals; mirror backs block beams; stairs persist; torches don't freeze watchers;
  lens freezes anywhere; player can't press heavy plates; watcher strikes hurt; frozen
  watcher is standable; bolts stopped by the block; lift carries; shortcut persists across
  reloads; chasm hits are recoveries not deaths; hidden platforms solid only in light;
  closed window blocks the beam; seal sequence; window stays open after the slime leaves.
- Saving: death → shrine respawn with full health; solved rooms and pages persist;
  Restart Chapter (two presses) wipes progress.
- Reset: idempotent; clears Echoes and restores the mana cap; keeps saved solutions.
- Hazards: vents paced (≤2 hits per burst), unshielded bolts hurt, pistons hurt and push
  the player out from under the head.
- Tutorial regressions after the shared-script upgrades: 111/111.

### Visually inspected (screenshots from the `look` scenario and scenario runs)
- Every room at its key spots, the pause menu, a hint stage 1 with its markers, Room 3
  stairs and solved beam path, Room 4 solved, Room 7 solved.
- Fixed from inspection: tall-room mechanisms were above the camera's view from the floor
  (lowered); toasts covered the floor (moved to the bottom edge); signs overlapped the bell
  and the HUD (moved/shortened); power grooves looked like beams (now violet, rerouted);
  remote mirror wheels turned an off-screen mirror (camera now shows it).
- Frame rate: 165 fps (vsync cap) in every room on an RTX 3060. Not measured elsewhere.

### Still needs human playtesting
- Puzzle clarity without hints, difficulty and pacing, hint wording.
- Sound: the 40 effects are synthesised placeholders — loudness, harshness, repetition.
- Art consistency of the code-drawn pieces (mirrors, braziers, grates, seal) next to the
  tileset art; readability in the dark on other monitors.
- Reduce-motion setting in practice; keyboard-only feel; any gamepad play (no gamepad
  bindings were added).
- Alternative solutions using an Echo (Rooms 2 and 7) — expected to work, not tested.

## Presentation and audio pass (2026-09-28)

Details, timing tables and the full verification record are in
[PRESENTATION.md](PRESENTATION.md).

- **Rendering:** a reusable `DungeonAtmosphere` in both levels:
  - three parallax planes (distant fog, mid-ground ruins, foreground vines and
    thorns);
  - breaches broken into the back wall with crumbled edges;
  - leaning light shafts with dust and real Light2Ds.
  The post pass adds lantern falloff that leaves lit things bright, soft
  bloom, a grade and a cinematic vignette. Pulsing glows and embers are on
  torches, braziers, fireballs, pages and shrines. The camera now follows with
  damping and a speed-based look-ahead.
- **Echidna:** a sprite pipeline slicing her original sheets into clips on one
  80×80 canvas with a bottom-centre pivot, with per-frame timing (quick blink,
  brisk stride, fast stop and landing recoveries). The hold-jump electric
  wisps are extracted as a charge-only overlay. Footfalls trigger dust and
  sound. Her lighting material derives rim normals from her silhouette, and
  she has a contact shadow. Her art and her movement physics are unchanged.
- **Audio:** Music, Ambient and SFX channels, plus Corridor, Hall and Cavern
  reverb buses. `AudioDirector` plays three synchronised loops (cave drone,
  piano lament, combat pulse) and an ambience bed, easing into combat in
  Rooms 4 and 7 and the tutorial slime arena. ReverbZones cover every room.
  Music, Ambience and Effects sliders are in the pause menu.
- **Tests:** `tests/presentation_suite.gd` (82 checks) was added to
  `run_tests.gd`'s default run. The tutorial (111) and chapter (216) suites
  still pass.

## Known limitations and decisions

- There is no title menu. The chapter continues from the last shrine whenever it is
  entered; Pause → Restart Chapter starts it fresh.
- `chapter_1.tscn` is generated. Tune rooms in `tools/build_chapter.gd`, or stop using the
  builder before editing the scene by hand.
- `tutorial_level.tscn` was hand-edited this session (exit now leads to the chapter; pause
  menu added). Its original builder is not in the repository.
- Piston heads are solid but fireballs pass through them (so the tutorial's "shoot the
  switch through the running pistons" still works); beams and bolts are stopped.
- The main scene is unchanged (tutorial).

## Handoff notes

- If a usage limit interrupts work, resume from this file. Model selection cannot be
  changed from inside the session; use `/model` in the Claude Code UI if needed.
- To add a room: add a `room_N_*()` function to `tools/build_chapter.gd` (shell →
  features → `make_room` → pieces → circuits → hint/page/signs/decor), a `solve_rN()` and
  `scenario_roomN()` to `tests/chapter_suite.gd`, and chain it into `scenario_full_run`.
