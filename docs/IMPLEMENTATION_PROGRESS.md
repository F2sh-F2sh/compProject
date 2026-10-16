# Implementation Progress — Chapter 1: The Sealed Belfry

## Story continuation — 30 September 2026

Lowbell now leads into Nan's cottage, a playable pilgrim road and a descending old-well
passage before the existing tutorial/Chapter 1. Nan's failing memory motivates the journey;
the sealed Belfry door explains the dungeon entrance. New interactions lower a bridge and
share Nan's lantern flame between two passage lamps. World flags and landing checkpoints
restore progress through Continue. The original player controller, tutorial, puzzle chapters
and rune rules are retained. Chapter 1's Continue also plays a three-picture bell aftermath
before the Observatory: the bell buys Lowbell time, while the Eye still holds the Hush's source.

Implementation: `scripts/story/witch_prologue.gd`, `story_dialogue.gd`, `bell_aftermath.gd`
and their scenes in `scenes/story/`. These scenes use existing art and synthesized audio;
they are built at runtime like Lowbell, not by the chapter generators.

Verification: the full windowed suite passed **1,021 checks, zero failures** (tutorial 140,
chapter 304, presentation 100, experience 136, rune 304, prologue 37). Final screenshot
review found that a conversation started during a jump froze Echidna in midair; control
locking now keeps gravity, and a final prologue run passed **38/38**, including that case.
Godot import and whitespace checks passed. Rendered screenshots were inspected at normal
and smaller window sizes. This is automated simulated-input testing and screenshot review;
human playtesting and listening to the audio remain on `PLAYTEST_CHECKLIST.md`.

The baseline and milestone entries below are historical records; their branch and
uncommitted-status descriptions do not describe the current checkout.

Living record of the puzzle-chapter work. Companion documents:
[CHAPTER1_SOLUTIONS.md](CHAPTER1_SOLUTIONS.md) (room-by-room solutions, resets, failure
states) and [PLAYTEST_CHECKLIST.md](PLAYTEST_CHECKLIST.md) (what a human still needs to judge).

## Baseline (Milestone 0)

- Engine: Godot 4.7.2 (Forward+, D3D12). No engine, renderer or project-setting changes
  beyond new input actions, autoloads and one physics layer name.
- Branch: `teammate-work`. Everything up to the Great Sluice was committed and merged into `main`
  on GitHub on 2026-10-05 (commit c86804b); work after that is uncommitted until asked.
- Existing systems reused, not replaced: player controller, health/mana, fireball, heal,
  mana reload (R), Echo recording (E) with temporal debt, spike recovery vs real death, the
  death screen, lighting (CanvasModulate + FlickerLights + occluders + PostFX).
- Measured movement (by the tests): walk 115 px/s, sprint 220 px/s, tapped jump ~62 px up,
  fully charged jump ~132 px up, walking jump ~82 px across, sprint jump ~157 px across.
- Baseline tutorial suite: 111/111 before any chapter work.

## Status: all milestones implemented and passing automated tests

Last full run (2026-10-08, after the story, reels and Eye rework): wing 945, chapter 341, presentation 111,
experience 246, rune 304, prologue 38, adversarial 18 all passing; tutorial 172 of 173. The one miss was "now a
fireball flies" in the tutorial `abilities` scenario (code this work did not touch); it passed 4 of 4 reruns on its
own and the whole tutorial suite passed 173 of 173 when rerun, so it is a flake. The run before it (after the
Galleries rebuild): wing 937, tutorial 173, chapter 341, presentation 111, experience 246, rune 304, prologue 38,
adversarial 18, all passing (2,168 checks). The run before that (after the
Hall of Lamps): wing 654, chapter 341, presentation 111, experience 246,
rune 304, prologue 38, adversarial 18 all passing; tutorial 172 of 173. The one tutorial miss is the slime arena in
the `play` scenario ("both slimes defeated with fireballs"): the scripted fight stands and shoots with finite mana
(cap 90 after the Echo, random 3-7 damage) and ends with 1-16 mana to spare when it wins, so it sometimes runs dry
(failed 2 of 5 runs; it now prints mana, slimes left and health). It does not touch anything changed here. The first
full run (2026-09-29) was 561 checks in four suites.

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
- Play: run the project (F5): the title screen, then the tutorial and the chapter. To jump
  straight in, open `res://scenes/chapter/chapter_1.tscn` and press F6.
- **Admin switch (temporary, on as of 2026-10-04):** `Journey.admin_unlock` at the top of
  `scripts/story/journey.gd`. While it is true every door on the Long Stair is open, and the title's
  Choose a Level has "Admin: any wing, any room", which starts any wing's room or the Eye directly with the
  spells and words of everything before it (nothing is marked finished). Set it to false before release.
  The tests always turn it off (`tests/run_tests.gd`); wing `admin` tests it.
- Rebuild the chapter after changing the builder:
  `godot --headless --path . --script res://tools/levels/build_chapter.gd`
  (this **overwrites** `scenes/chapter/chapter_1.tscn` and the component scenes in
  `scenes/puzzle`, `scenes/creatures`, `scenes/traps`).
- Tests (need a window, not `--headless`, because they take screenshots and aim the mouse):
  `godot --path . --fixed-fps 60 --disable-vsync --script res://tests/run_tests.gd -- [tutorial|chapter|presentation|experience|rune|wing|all] [scenario]`
  `--disable-vsync` is optional but recommended: the game time is the same, the run is several times faster, and
  with vsync on a long run can stall while the screen is asleep. Run one test process at a time (the presentation
  audio check measures the real sound output).
  Chapter scenarios: `r1`…`r9`, `save`, `reset`, `stuck`, `ways`, `hazards`, `guide`, `full`, and `look`
  (screenshots of every room into `user://test_shots/`, not run by default). Wing scenarios include `k1`,
  `forge_full`, `forge_broken`, `forge_page3`, `k2`, `heart_full`, `heart_broken`, `c1`, `c1_full`, `c1_short`,
  `c1_broken`, `c2`, `c2_full`, `c2_pages`, `c2_broken`, and `forge_look`, `heart_look`, `c1_look` and `c2_look`
  (screenshots, not run by default).
- Rebuild the Long Stair and its wings after changing `tools/levels/build_wings.gd`:
  `godot --headless --path . --script res://tools/levels/build_wings.gd`, then
  `git checkout -- scenes/puzzle scenes/runes scenes/traps scenes/creatures` to drop the builder's noise.
- Regenerate the sound effects: `godot --headless --path . --script res://tools/audio/generate_sfx.gd`
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

## Enjoyment pass (2026-09-28/29)

Driven by beta-tester feedback and an audit of what made the game less fun. Plan:
`C:\Users\Ishaan\.claude\plans\vectorized-greeting-fern.md`. Local checkpoint commit
`87278ca` was made first (not pushed); everything since is uncommitted.

**Phase 1: beta-tester fixes**
- Jump fires on the frame the press registers, with 0.1 s coyote time; the high jump is
  now crouch (S / Down) then jump. Heights unchanged (tested: 65.5 px tapped, 131.8 px full).
- Footsteps: four soft variants plus an iron-grate tick on a dry "Foley" bus; every second
  plant only, none for taps or below 40 px/s.
- Caged slimes (R2, R7): fireballs can't spawn past a floor, grate or wall; the grate stops
  them; the slimes are warded.
- Visible hazards: an additive glint on spike tips (`assets/shaders/hazard_glint.gdshader`),
  a red floor glow, a warning flare on rising spikes, glowing piston teeth.
- Floating wall tiles: `tools/levels/wall_tile_audit.gd` + `tools/levels/audit_wall_tiles.gd` found 7
  (3 chapter, 4 tutorial) and fixed them; the audit is now a test.
- Tutorial sprint gap: 128 px over a shallow pit (`FallCatcher`) that fades you back
  without damage (`tools/levels/patch_tutorial.gd`).
- Pistons send you back like spikes (R5 has its own candle); healing is a 1.2 s channel
  (`scripts/player/heal_channel.gd`) that moving, jumping, casting or a hit breaks, with
  no heal for 3 s after a hit.

**Phase 2: a clearer Chapter 1**
- Four acts with title cards; per-room goal card with step pips (`ObjectiveStep`,
  `ObjectivePanel`), optional page pips; groove previews near switches; faint key cues
  near usable things; hint stones call out after 90 s or two deaths; Guidance setting
  (Full / Light / Off); chapter map in the pause menu.
- Tutorial split into nine lessons (`LessonZone`) with cards and per-lesson respawn;
  `tutorial.done` flag. Per-scene checkpoints in `GameState`.

**Phase 3: the Echo in Chapter 1**
- Echoes replay lever/rope/mirror use (`Interactable.trigger`); HUD seconds countdown,
  last-3-seconds ticks, hold E to let Echoes fade, notices, one colour per Echo.
- New rooms: R8 The Choir Loft (spring levers, needs an Echo) and R9 The Great Bell
  (an Echo holds the plate for the stairs). R6 shrine added. Slimes drop health orbs.

**Phase 4: front door and ending**
- Title screen (the main scene), story intro, Continue / New Game / Tutorial / Settings,
  project renamed "The Sealed Belfry" with its own icon (old save and settings are
  migrated from the "compProject" user folder).
- The great bell ending (`GreatBell`) and a Chapter Complete card with run statistics;
  page reader on parchment; the Bellkeeper's Ledger in the pause menu; run statistics
  and `user://playtest_log.csv`.

**Phase 5: feel**
- Fireball impact bursts, hit-stop and camera kick (`ImpactFX`); crits (10%, x2) show
  their number; muzzle flash, aim-facing, fizzle, reload sounds; death sound and
  dissolve, retry prompt in ~1.5 s; low-health vignette and heartbeat; slime knockback
  and white flash; gargoyle stone-dust; room-clear chord; per-room colour moods.

**Phase 6: controls, comfort, shipping**
- Gamepad on every action, right-stick aim with light aim assist, pad button prompts;
  key rebinding with swap-on-conflict and reset; assists (damage 100/75/50/25%,
  unlimited mana, always sprint, crouch toggle); fullscreen (F11); lighter effects (since
  replaced by the Low–Elite graphics levels).
- README, CREDITS, `.gitignore` (builds, *.tmp), killzone script, export-safe atmosphere
  colour, a "Windows release" export preset (builds/windows/TheSealedBelfry.exe; the
  existing "Oou" preset is untouched). The exported build boots with a clean log.

**Verification**
- Automated: tutorial, chapter, presentation and new experience suites (see the last
  full-run line below). Every new room is solved with real simulated input.
- Frame rate: 163–165 fps (vsync cap) in all nine rooms, the tutorial and the title on
  the RTX 3060; worst frame 10.4 ms. Not measured on other GPUs.
- Visually inspected: title, intro, page reader, Ledger, objective card, R8/R9, the
  bell ending, spike glint (see `user://test_shots/`, now under "The Sealed Belfry").
- Needs a human: how it all feels and sounds (see PLAYTEST_CHECKLIST.md's new sections).

**Not done (backlog):** the optional three-room Echo wing (Undercroft); gargoyle decoys;
wisp comet trail; painted per-room props; title and ending music themes and per-room music
layers; new enemies and a boss; OFL licence text and tileset credits (need the team);
removing the 7 tracked `.tmp` files and bundling a serif font (need approval).

## Rune cubes and Chapter 2 (2026-09-29)

The rune-cube magic system and an eight-room Chapter 2, "The Sealed Observatory", are
implemented and pass automated tests; nobody has playtested them. Everything about them
(design decisions, tuning, files, test record, gaps) was in `docs/RUNE_SYSTEM_PROGRESS.md` (removed in the release cleanup; see the git history);
room solutions and the full list of accepted runes are in `docs/CHAPTER2_SOLUTIONS.md`.
Chapter 1's ending now offers "Continue to the next chapter", and the title screen has a
Chapter 2 entry.

## Merge repair, held gates, water, graphics levels and the new menu (2026-09-29)

**Why the game stopped opening.** The merge commit `92fff19` ("A LOT", merging `ca7ff5e`
into `7992392`) was committed with unresolved conflict markers in 14 files
(`project.godot`, `player.gd`, `Player.tscn`, `slime.gd`, `hud.gd`, `hud.tscn`, ...). It was
also merged into `main` on GitHub (pull request 15). The two sides were two separate
resolutions of the same earlier `main` merge. For 12 files the other side was the older
`main` version that later work had already rebuilt, so the working tree restores them from
`7992392` (the last build that ran). `TestingPlayerMovement.tscn` takes a clean three-way
merge that keeps Fisch's camera zoom (1.71). Fisch's `player.gd`/`Player.tscn` rewrite in
`960213d` adds a second sprite for a 7-frame jump sheet (`c8844726-….png`, charge sheet
`cahrgeagin.png`). That same jump art already plays at native size through
`EchidnaAir.png`/`echidna_frames.tres`, and his safety fixes (cancel a charge on leaving the
floor, no actions while dead) were already in. His large sheets stay in `assets/`, unused;
check with Fisch. Nothing is committed or pushed; the fix is in the working tree only.
`heart.gd`/`heart.tscn` came back with the merge and are unused.

**Plates and light hold gates only while held.** `Circuit.latch` is off for every plate
and crystal circuit in both chapters (Room 8's spring levers keep theirs). A gate follows
its sources live. When the player walks into a later room while a live circuit with a
`persist_id` is on, it latches and saves, so a gate she has come through stays open
(also after a death). Chapter 1 Room 2 gained a stone block and a kerb for plate B (the
slime now listens 12 s). Room 3's stairs stand while either crystal is lit.

**Draw order.** Slimes draw at z 42 (above props, grates and the 40 thorn frame); damage
numbers and floating text moved to 50; signs to 45. Act and lesson cards moved up under the
HUD, so they no longer cover hanging signs; the room title waits 3.8 s after an act card.

**Water.** `scenes/fx/puddle.tscn` (`scripts/fx/puddle.gd`, `assets/shaders/puddle.gdshader`):
a reflective sheet over the floor that mirrors the scene above it, shimmers, and carries
rings of ripples from footfalls (wet footstep sound), landings (splash, droplets), things
wading through (slimes, blocks) and drips that fall from the ceiling. Each puddle snaps
onto the floor at play time and removes itself on uneven ground. 8 in Chapter 1, 6 in
Chapter 2, 3 in the tutorial.

**Graphics levels and FPS.** `Settings.graphics` Low / Medium / High / Ultra / Elite
(`GRAPHICS_TABLE`): bloom and grain strength, light shadows on/off and their filter
(PCF13 on Ultra/Elite), shadow map size (1024 to 8192), light shafts, ambient mote
count (x0.4 to x1.7), puddle reflections and ripple count, drips. `Settings.show_fps`
shows a live counter in the bottom-left corner. The old "lighter effects" switch is
replaced (old settings files map to Low/High). Nothing about the renderer or project
rendering settings changed; only per-node effects and the canvas shadow-map size at runtime.

**The menu.** `scripts/ui/pause_menu.gd` is rebuilt in the style of the reference image:
Echidna's white card (animated figure in a ring of slots, HP/MP, a description box) on
the left; a column of round icons (Resume, Echidna, Map, Journal, Settings, System) that
ring in orange with an arrow on hover; a dark first list that slides out; a white second
list with fading ends; orange for the active row. Settings → Graphics (the five levels, Show
FPS, fullscreen), Controls (rebind any key; Esc cancels; conflicts swap), Audio (volume
bars), Gameplay (guidance and assists). The map, the Ledger and the rune journal open in the
card. Keys, pad and mouse all work. Three `AudioStreamPlayer`s play new synthesised
cues: `sao_hover` (crisp chime), `sao_select` (solid beep), `sao_open`/`close`/`back`. The
title screen keeps its settings panel, with the graphics levels and Show FPS added.

**Charge lines removed.** The blue wisp lines and the circling wind streaks no longer play
when she charges a jump; a soft glow builds instead and sparks show a full charge.

**Test record (automated, full `all` run, windowed).** 942 passed, 1 failed: tutorial 140,
chapter 304, presentation 87, experience 107 + 1 failure, rune 304. The failure was the
controller aim-assist check: it now locked onto the tutorial's second slime, which had
wandered nearer the aim line (slime wandering shares the global random numbers that
puddle drips now also draw on). The test hides that slime for the check; the `controls`
scenario then passed 19/19, so the suite stands at 943/943. New checks: experience `menu`
(31), `puddles` (9), `layers` (4), the five graphics levels and Show FPS in `controls`,
Room 2 (the gate closes when the slime leaves; saved only once she has gone through) and
Room 3 (turning the beam off the crystal closes the gate) in the chapter suite, and the
"saved once through" checks in both chapters.
**Visually inspected:** menu screenshots (open, Graphics list, Spells hover, map in the
card) and cropped puddle shots (reflection, ripples, splash droplets).
**Not done by a person yet:** how the menu sounds and feels, whether the puddles look
right in every room, how each graphics level looks and runs on other hardware (FPS not
re-measured this session), and whether held gates feel fair (see the checklist).

## The story intro and Lowbell (2026-09-30)

The start of the game from `docs/GAME_DESIGN.md` §1–2. New Game now plays an illustrated
story, then Lowbell, then (as before) the tutorial, or Chapter 1 once the tutorial is done.

**The story** (`scenes/story/story_intro.tscn`, `scripts/story/story_intro.gd`): nine
pictures, each still but for a few small movements, with a slow push-in and one or two
narrated lines (italic serif) beneath:
1. The written sky: a constellation draws itself into the Wind rune over the monastery.
2. The words: WIND · PUSH · RIGHT · LARGE glowing in the sky; firs sway; wind streaks.
3. The Eye: the great lens's light falls on a cube whose four runes light up; the Choir
   gathered round.
4. Ilse and Wren: a candle, a sick child's bed, Ilse reaching out; the great cube behind.
5. "Hold this moment still": ICE · FREEZE · SELF · PERSIST light up; frost creeps out;
   falling snow stops in the air.
6. The Hush: a grey circle spreads from the Eye, draining colour and putting out the stars
   and the village lights.
7. The bell: the great bell swings, its rings of sound pushing the grey back.
8. The crack: the bell cracks, the belfry is sealed, lanterns go down the mountain.
9. Lowbell: the village at dusk as its stars go out.

Space, Enter or a click moves on; holding Esc skips. The pictures are drawn in code
(`story_paint.gd` brushes, `story_nodes.gd` moving parts, `assets/shaders/story_hush.gdshader`),
so Echidna's art is unchanged and no image files were added.

**Lowbell** (`scenes/story/lowbell.tscn`, `scripts/story/lowbell.gd`): a playable village lane
at dusk, drawn in code with parallax (a moon behind the monastery on the mountain, ridges,
woods, a far row of houses). The opening: the camera comes down from the monastery to
Echidna's door; it creaks open, she steps out, looks at the wind chimes swinging without a
sound ("Even the chimes have gone quiet..."), and her name card comes up
("A WITCH OF LOWBELL / Echidna"). Then the player walks the lane: four villagers
(`villager.gd`) speak when she is close, with words the Hush has taken shown as rune glyphs
(`speech_bubble.gd`); a stone stile needs a hop; two puddles; lamp-lit windows; Nan in her
rocking chair by the fire. Knocking at Nan's door (W) ends the scene. **For now** two narrated
cards stand in for Nan's scene (she can't remember Echidna's name; she gives her the lantern
and asks her to ring the bell), then the tutorial begins. Nan's scene is the next piece to
build and will replace those cards.

Entering Lowbell sets the Continue point; the opening plays only once per save. The cave
ambience fades out under the sky and a soft wind loop plays; new sounds `door_creak` and
`knock` (appended to `tools/audio/generate_sfx.gd`; the other 95 sounds are byte-identical).
`AudioDirector.fade_ambience()` is new. The title screen's old four-line text intro is gone.

**Checks:** automated: experience `title` 14/14, `story` 6/6, `lowbell` 15/15; the whole
experience suite 131/131 and presentation 87/87 (windowed). That run logged one script error:
`GameState.count_flags()` compared run statistics (numbers stored with the flags) to `true`,
which New Game's "is there progress?" check hits once Chapter 1 has been played. Fixed
(`has_flag`/`count_flags` now count only true booleans; the title screen's room count uses
`count_flags`). Re-run after the fix: experience 131/131 with no script errors, chapter
`save` 24/24. Visually inspected: screenshots of all nine pictures and of Lowbell's
opening, each villager, the stile and Nan's door, fixed until they read well. Not yet done by
a person: pacing of the narration, how the sounds and music feel, and whether the villagers'
lines land.

## A clearer story, and a charge breeze and bar (2026-09-30)

**The story, told plainly.** The narration was hard to follow (too many invented names and
poetic lines), so it was rewritten in plain words, one idea per line, and now says outright
what the game's systems are:
- The monks (the Choir) found that stars are words.
- Four words make a spell, and the world obeys it.
- They carved spells into **rune cubes**, which work when all four words light up.
- Ilse's daughter Wren was dying, so Ilse wrote ICE · FREEZE · SELF · PERSIST ("freeze
  this moment, and never let it end").
- The spell never stopped, and its stillness spread: **the Hush** fades sound, colour and
  memory.
- Only the great bell pushed it back, rung daily for sixty years.
- Nine years ago the bell cracked, and the monks sealed **the Belfry** and left.
- Now the Hush has reached Lowbell. Someone must get into the Belfry and ring the bell, and
  that someone is **Echidna**.

What changed on screen:
- A small gold label above the words says when each picture happens (LONG AGO, SIXTY YEARS
  AGO, FOR SIXTY YEARS, NINE YEARS AGO, TODAY).
- The pictures now act out the line being read. The constellation draws itself on "the stars
  are words". The cube lights word by word on "when all four words light up". The frost and
  frozen snow come on "time stopped". A picture can hold a movement back for a later line
  (`_cues`).
- The Eye and the High Cantor are no longer named; they come later in the game.

Lowbell changes:
- Echidna's first thought is "The Hush is here. Even the chimes have gone quiet...".
- The goal box reads "Go to Grandma Nan's cottage, at the end of the lane. She will know what
  to do."
- The stand-in for Nan's scene has a third card: Echidna sets off for the sealed Belfry. The
  first card adds that the Hush has reached Nan too.
- Her thought bubble now gives way while a villager is speaking. Walking straight to Tam used
  to put the two bubbles on top of each other.

**Charge breeze and bar.** Charging a jump now shows two things, both created by
`player.gd` at start-up (three lines; no scene edits):
- **Breeze** (`scripts/fx/charge_breeze.gd`): a small breeze of soft dots only. Specks of air
  spiral in toward her and a little dust stirs at her feet. It grows with the charge and warms
  to gold at full. When she leaps, the dust puffs out where she stood. No lines or streaks, so
  the earlier "remove the lines" request still holds; the test checks she has no `Line2D`.
- **Bar** (`scripts/fx/charge_bar.gd`): a small 22×3 bar just above her hat. It appears as
  the charge pose starts (a quick crouch never shows it) and fills as the jump gains power.
  At full power it turns gold, flashes once and plays a new `charge_full` chime once. It fades
  when she leaps or stands up.
- The new sound was appended to `tools/audio/generate_sfx.gd`; the other sounds are byte-identical.
- The old `scripts/charge_wind.gd` (the removed streaks) is still on disk, unused, and was left
  in place (no deletions without approval).

**Checks:**
- Automated (windowed): presentation `charge` 20/20 (new checks: no bar or breeze while idle,
  none on a quick crouch, the bar above her head filling, full and gold at full charge, one
  chime only, the puff on the leap, the bar gone after it, a part charge clears it with no
  chime), chapter `save` 24/24. Full `all` run: **979/979** (tutorial 140, chapter 304,
  presentation 100, experience 131, rune 304), with no script errors.
- Visually inspected: close-ups at each stage of a charge (appearing, filling, the flash, full,
  the leap), a screenshot of every story line, and Lowbell.
- Not yet done by a person: whether the breeze is noticeable enough in motion, whether the
  chime is too loud or quiet, and whether the new narration is clear to a first-time player.

## The story and Lowbell in pixel art (2026-09-30)

At the user's request ("no more shapes for characters and objects"), the story pictures and
Lowbell are now built from two pixel-art packs they supplied, copied into the project as
**`assets/surface/`** (ground tiles, structures and props, nature and creatures, parallax sky,
hills and woods) and **`assets/town/`** (houses, modular parts, silhouettes, a town strip).
Only the 1x sheets and the two mock-ups were copied; nothing was deleted.

**`SurfaceArt`** (`scripts/story/surface_art.gd`) names every sprite on the sheets (measured by
a scan of the sheets, e.g. `house_big`, `lamp_post`, `well`, `crow_fly_a`, `grass_4`). It has
helpers to:
- place a sprite by its feet;
- animate frames;
- lay ground and walls from the 16 px tiles (a `TileMapLayer`);
- repeat the parallax paintings sideways.

**Hand-made pixel sprites for what the packs lack.** `tools/art/generate_story_sprites.gd` draws
them from pixel maps in the packs' own 57-colour palette, with dark faces and pale eyes like
Echidna, and writes PNG strips to `assets/sprites/story/`:
- Tam, Mira, Pip, Edda and Nan (with her lantern), the Choir's monks, Ilse, and Wren in her
  bed. People get standing, breathing and blinking frames.
- The great bell (whole and cracked), the shrine bell, two rune cubes, a wind-chime post and
  tube, and a blue candle.
- Open-door frames cut from the town pack's own houses, so Echidna's and Nan's doors really
  swing open.

**Lowbell.** The pack is drawn at 1.5x, which is 3 screen pixels per art pixel under the 2x
camera. The view shows 384 × 216 art pixels, the same framing as the packs' mock-ups.

The distance, far to near:
- the sky and moon (fixed to the screen) with sparkle stars that go out one by one;
- drifting clouds and bats;
- the hills with the monastery (at 1x, far away);
- the woods;
- the town's rooftops.

On the lane:
- Pack houses: Echidna's home, the bakery, a house gone quiet, a tall house, and Nan's
  cottage. Lit windows glow blue.
- Lamp posts, the chimes, barrels and a crate, a signpost, the well with a crow that flies off
  as she passes, a shrine bell under a ruined arch, a cart, trees and fences.
- Grass tufts and flowers that sway, and leaves blowing along the lane.
- The fallen log she hops is the old "stile" (same place, 19 px tall).
- Knocking now opens Nan's door, and Nan stands in it with her lantern before the bridge
  cards.

**The story.** The pictures use a 384 × 216 art-pixel canvas at 3x, 5x for the close-ups (the
bedroom, the bell) and 2x for the wide views (the Hush, Lowbell today):
1. Three monks on a grassy rise watch the sky over the monastery.
2. Trees bend, grass and leaves blow, and a crow crosses under the four words.
3. The Choir stands round a rune cube in a brick hall under a round window.
4. Ilse watches over Wren's bed by candlelight and moonlight.
5. The great cube.
6. The Hush drains the colour from the monastery and the village.
7. The great bell swings in a frame of old pillars and planks.
8. The bell cracks, the hall is sealed, and the monks walk away with lanterns. The crack now
   comes on "the bell cracked" and the monks leave on "left the mountain".
9. Lowbell today; on the last line, Echidna appears in the street.

Effects stay code-drawn: soft glows, light shafts, frost, sound rings, the constellation and
the rune glyphs (the game's own script, shared with the rune UI). The drawing code for
shapes (mountains, houses, robed figures, bells, firs, wind streaks, grass lines) was removed
from `story_paint.gd` and `story_nodes.gd`.

**Checks:**
- Automated (windowed): experience `story` 7/7 (new: the first picture has sprites and no
  drawn shapes) and `lowbell` 19/19 (new: no drawn shapes in the village apart from the
  puddles' water, the villagers are sprites, the crow flies off, Nan answers the door).
- Full `all` run: 980 passed and 4 failed. The 4 were tutorial fireball checks, a suite
  nothing here touches. The tutorial suite then passed **140/140** on its own straight
  after. Those checks aim by moving the real mouse (`warp_mouse`), so real mouse movement
  during a run can spoil them; that is the likely cause, not confirmed.
- Visually inspected: a screenshot of every story line, and Lowbell from the opening to Nan's
  door, fixed until they read well.

**Not yet done by a person:** whether the hand-made people and objects sit well beside the
packs' art, how the lane feels to walk, and whether the story pictures read at a glance.
**To record:** where the two packs came from and their licence (`CREDITS.md` has a
placeholder).

## The game plan v2, a brighter dungeon, the Room 7 flame, fewer hints (2026-09-30)

**The plan.** `docs/GAME_DESIGN.md` is now the v2 plan (about two hours of new game after a
tutorial section; the old 6 to 7 hour version is kept as `GAME_DESIGN_v1_long.md`, since removed; see the git history).
The early game becomes one tutorial section, "The Novices' Way" (Part 1 The Passage, Part 2
The Sealed Belfry, Part 3 The Sealed Observatory), followed by five new chapters. It covers the
story, the grandma scene, earned fireball/heal/Echo, finite mana, the combat rework, new
creatures, 32 puzzle ideas, the ending and a dated build plan. None of that gameplay is built
yet except the four fixes below.

**Built in this pass**
- **Brightness** (`Settings.brightness`: Dim / Normal / Bright, saved; title-screen settings
  and the pause menu's Graphics list). `PostFX` applies it: the level's ambient light, the
  lantern's gloom and reach, the vignette, a new `shadow_lift` gamma in
  `assets/shaders/dungeon_post.gdshader`, and the player's light. **Dim is the old look**,
  Normal is the default. The builders' ambient went from (0.2, 0.18, 0.3) to (0.5, 0.48, 0.64),
  tile tints and torches are brighter, and the tutorial (hand-built) was brightened by an
  idempotent step in `tools/levels/patch_tutorial.gd`. `Room.mood_ambient` keeps the three watcher
  rooms darker (Belfry 4 and 7, Observatory 6). Lowbell was meant to keep its own look but did not until the 2026-10-01 fix below (`PostFX.follows_brightness`).
- **Room 7 flame.** Every unlit brazier is now a small warm-gold pilot flame with a ring that
  opens every two seconds and a gold light (energy 0.7, was 0.15); the lit fire is still blue.
  The decorative torch under the flame was removed; the first time ever in Room 7 the camera
  glances at it (`Room.glance_at`, `ChapterRoot._glance_at`); the objective card shows one line
  ("Light the flame by the door", `ObjectiveStep.todo_label`) until it is lit.
- **Fewer hints.** Guidance now defaults to Light for new settings files (anyone who already
  saved a choice keeps it); the step pips show only at Full; the skull's first hint is text
  only and the arrows come with the second; the auto-nudge waits 300 s or 4 deaths (was 90 s
  and 2); Chapter 1 has 9 signs (was 23) and Chapter 2 has 6 (was 12).
- **Tutorial-section wording.** The title screen's Tutorial opens a list (Part 1, 2, 3) and the
  separate "Chapter 2" button is gone; progress reads "The Novices' Way ..."; the end cards say
  "Part 1 Complete", "PART 2 COMPLETE" and "TUTORIAL COMPLETE" (new `ChapterRoot` exports
  `complete_heading`, `next_label`, `closing_line`, `unit_name`); act subtitles read "The
  Novices' Way · Part N · ..."; the pause menu says Restart and Room Map. Save flags and ids
  (`tutorial.done`, `ch1.*`, `ch2.*`) are unchanged, so old saves still work.

**Checks (2026-09-30)**
- Automated (windowed, full `all` run): **1008 passed, 0 failed** (tutorial 140, chapter 315,
  presentation 111, experience 138, rune 304). New checks: presentation `brightness` (11: the
  three levels, Dim equals the old gloom, Normal at least 40% brighter on screen, the watcher
  room darker and recovering, the tutorial's lantern, the unlit brazier's glow and colour),
  chapter `flame` (7) and extra `guide` checks (hint arrows, pips at Light), and the title test
  for the Tutorial list. The `post` scenario now measures the lantern falloff with the original
  gloom and no shadow lift, so it keeps testing the shader rather than the setting.
- Measured: mean screen luminance, Normal vs Dim, is +60% to +80% in the tutorial, Belfry
  rooms 1, 4, 7 and Observatory room 6 (for example Belfry room 1: 0.094 to 0.161); Bright
  is about +130%.
- Visually inspected: screenshots of Dim, Normal and Bright in the tutorial and several rooms,
  Room 7 after the glance, and the title screen's Tutorial list.
- **Needs a human:** whether Normal is the right amount of light (and Bright too bright), how
  the gold flame reads in a real playthrough, whether the rooms are still solvable with the
  smaller hint set, and whether any removed sign is missed. All listed in
  `docs/PLAYTEST_CHECKLIST.md`.

**Notes.** Rebuilding the chapters rewrites many unrelated scenes with noise (stripped uids,
new node ids); only `scenes/chapter/*.tscn`, `scenes/world/torch_light.tscn` and
`scenes/tutorial/tutorial_level.tscn` were kept. `chapter_1.tscn` and `chapter_2.tscn` lost their scene
uids in the rebuild (nothing refers to them by uid). In headless runs `PostFX._apply_quality`
prints an old, harmless Nil*float error (no shader defaults without a renderer). Nothing is
committed.

## Milestone 1: Nan's cottage and the earned spells (2026-10-01)

Part of milestone 1 of `docs/GAME_DESIGN.md` §14. Built: the grandma scene, one place for the scene
order, and Fire, Heal and Echo as spells Echidna has to earn. **Not built (still M1):** finite mana
and Kindle points, the glue moments after the bell and the dome, a chapter-select list driven by
`Journey`, and the four-note hum at the Echo Door.

**What changed**
- **Nan's cottage** (`scenes/story/nan_cottage.tscn`, `scripts/story/nan_cottage.gd`). Knocking at
  Nan's door now leads in (the three bridge cards are gone). Echidna walks in, Nan (seated, by the
  hearth) does not know her, her name is four glyph gaps, she tries her fire spell for the fire and it
  only sputters, Nan explains the Hush, the bell and the monks' words, gives her the lantern (it flies
  to her and her light grows), and she goes down the cellar door to the Passage. The scene runs as one
  coroutine and `stage` says where it is. A save that already has her spells skips the fire beat.
  The room and Nan are pixel art: `tools/art/generate_cottage_sprites.gd` makes Nan seated, the hearth, the
  table, the jar shelf and the cellar door in the packs' palette; the wall, floor, window, door, barrel,
  crate, lantern and candles are pack sprites. The scene has no drawn shapes (tested).
- **Earned spells.** `GameState.has_ability("fire" | "heal" | "echo")`: saved flags `ability.*`; a save
  that has done the tutorial or any of Chapters 1 and 2 has all three; `Journey.skipping_to()` grants
  them when a later part is started from the title list; tests set `GameState.all_abilities`.
  `Player` refuses an unearned spell with a faint sputter and an `ability_denied` signal (the cottage
  listens for it); the fire/heal slots on the HUD appear when the spell is remembered; the Crosshair
  stays dim; the pause menu's Spells list says "forgotten" until then.
- **The Passage.** `scripts/puzzle/ability_shrine.gd` is a place where she remembers a word: the Kept
  Flame (fire, phase 4, before the pistons that need it), the Spring (heal, phase 5, after them) and the
  Echo stone (echo, phase 7, before the Echo lesson). Using one grants the spell, flares a ring of
  light, floats "+ FLAME" and shows a card ("YOU REMEMBER A WORD / FLAME" and what it does). Their
  pixel sprites come from `tools/art/generate_shrine_sprites.gd`. The lesson cards now read "PHASE n · name"
  (a new `LessonZone.eyebrow`; a new phase-5 zone, id `lesson.10`). All done in `tools/levels/patch_tutorial.gd`
  (idempotent); the pistons, Echo and Slimes signs were shortened or removed because the cards say it.
- **`scripts/story/journey.gd`** holds the scene order (`LOWBELL`, `COTTAGE`, `PASSAGE`, `BELFRY`,
  `OBSERVATORY`, `after_cottage()`, `next_after()`, `skipping_to()`); Lowbell, the title screen and the
  cottage use it. The tutorial's `LevelExit` and Chapter 1's `next_chapter` still hold the same paths as
  literals (a hand-built scene and a generated one).
- **A correction to the brightness pass.** `PostFX` now has `follows_brightness`; Lowbell and the
  cottage turn it off. Before this, the Brightness setting would also have changed Lowbell's own look
  (its gloom, vignette and a new shadow lift); a test now checks Lowbell's values.

**Checks (2026-10-01)**
- Automated (windowed): full `all` run: **1056 passed, 1 failed** (tutorial 163/1, chapter 315, presentation 111, experience 163, rune 304). The one failure, "both slimes defeated with fireballs", passes when the slimes scenario is run alone (it fights with the real mouse and a time limit). Two earlier full runs the same day had more fireball-aim failures (4 and 53, mostly chapter room 2/3 and a cascade from them); each suite passed when re-run alone, your Godot editor was open and in use during those runs, and the aim helpers now retry until the cursor is where it should be (see below). Not proven to be the cause.
  New: tutorial `abilities` (24: starts without the spells, each key sputters, the order along the
  Passage, the three phase cards, reading each shrine grants its spell and shows its card and slot, the
  spells work afterwards, old saves and the title's jump-ahead have all three); experience `cottage`
  (24: no drawn shapes, the whole conversation line by line, Nan's name as gaps, the sputtering fire
  spell, the lantern, the cellar door leads on, the fire beat is skipped for a save that has the spell)
  and a Lowbell look check.
- Test changes: every suite starts with all spells (`GameState.all_abilities`); the three `aim_and_shoot` helpers retry the mouse warp until the cursor is on target; the Lowbell and title
  scenarios expect the cottage; the glow test now aims its fireball itself, and the slime-orb test waits
  for the orb to be freed, because both depended on the real mouse and frame timing.
- Visually inspected: the cottage at every stage (greeting, talk, the fire prompt, the lantern, the
  cellar door), the three shrines before and after, and the cards.
- **Known flake:** fireball checks that aim with the real mouse (and the chapter room 2 fireball
  checks) can fail when the machine is slow or the mouse moves; they pass when re-run alone.
- **Needs a human:** whether the cottage conversation reads well and feels right, whether the seated Nan
  sprite is clear, how the fire beat and the three "you remember a word" cards feel, and whether the
  Passage still teaches enough with fewer signs. Listed in `docs/PLAYTEST_CHECKLIST.md`.

## Three playtest fixes (2026-10-01)

Reported while playing; each has a test.
- **Chapter 1 Room 5 (Broken Machinery), the skull plaque.** The plaque was drawn 44 px out in front
  of the step's wall with no collision, so the pushable block slid into it. It is now set into the wall
  (its left edge flush with the wall face), so the block can only meet it. Bolts start just outside
  the wall (`ArcaneBoltStatue.muzzle`, 38 for this plaque). The block against the wall still shields
  the bolts. (The report said Room 7; the block-and-plaque step is Room 5.) Test: chapter `r5` (2 new
  checks: the plaque is flush, the bolts start in the open).
- **Chapter 2 Room 4 (The Fractured Seal), the strong wind.** The cube started too far back: its wind
  let go of the stone about 17 px short of the wall, so you had to carry the cube closer first. The
  cube now stands right behind the stone, and the wall needs 640 momentum (was 800; the stone arrives
  with about 937). Switching Strong on breaks the wall at once, with no carrying. Test: rune `r4` no
  longer carries the cube and checks the hit has at least 1.3 times the momentum needed.
- **Chapter 2 Room 8 (The Sealed Observatory), the fire cube.** The optional fire cube, the brambles it
  burned and the Split tablet behind them are gone (they were one optional nook with no use in the
  room). Split is now taught in the Kilnworks (`docs/GAME_DESIGN.md`). The rune suite's fire effect
  test makes its own brambles. Test: rune `r8` and `effects`.
- Rebuilding Chapter 1 and 2 regenerated both scenes (`scenes/chapter/chapter_1.tscn`, `chapter_2.tscn`).
- Full run after these fixes: chapter 319, presentation 111, experience 163 and rune 302 all passed; the tutorial suite had two slime-orb failures, a timing flake in that test (it now heals her first and waits for the orb), passing 4 of 4 runs since.

## Finite mana and Kindle points (2026-10-01)

Mana is now the lantern's flame and no longer refills for free (`docs/GAME_DESIGN.md` §7).
- **Kindle:** R refills mana only while *held* (1.5 s) near a lit flame (`Player.near_kindle()`, group
  `kindle_point`): chapter shrines, candle checkpoints (`HazardCheckpoint`), lit braziers and the Kept
  Flame once remembered. Away from a flame R only floats "Hold R at a lit flame to kindle your lantern".
  Letting go or walking off cancels. The automatic refill at 0 mana is gone. "Assist: unlimited mana"
  still bypasses all of it. A rune drawing on her mana still blocks it.
- **Spark motes:** a defeated slime leaves a +6 mana mote beside its health orb (`Pickup.drop_mote`,
  group `mote`).
- **Trickle:** rune levels' passive regen is 4/s and stops at 25% of the cap (was 20/s to full).
- **Echo** re-casting fireballs for free was already so.
- (Fixed later the same day: every room now has a Kindle flame, see the opening and teaching pass.) Earlier note: Kindle points in every Chapter 2 room (only rooms with a shrine or lit brazier had one:
  rooms 4, 6 and 8 and the start; others rely on the 25% floor and Reset Room), per-region flames, the
  mana-bar "out of flame" prompt art.
- Tests: chapter `r3` (no refill away from a flame, held at a shrine refills, early release gets
  nothing), rune `mana` (trickle floor) and `r8` (kindles first), tutorial `abilities` (Kept Flame
  refills, elsewhere does not) and `slime` (spark mote).

## The glue moments (2026-10-01)

Two short runs of story pictures now sit between the parts of the Novices' Way (`scripts/story/story_interlude.gd`, a `StoryIntro` subclass built from the same pixel art; scenes `interlude_bell.tscn`, `interlude_dome.tscn`; hold Esc skips).
- **After the great bell (Part 2 to 3):** the Part 2 end card now leads here. Lowbell grey at night, the chimes swinging, the colour coming back for a moment and Nan lifting her head ("Someone is ringing..."); then the cracked bell, its tone thin, and a chalk star on the stair that was not there before. Then Part 3.
- **After the dome opens (end of Part 3):** the Observatory's card (now "Continue: the way down") leads to the stars with four dark ones, ICE · FREEZE · SELF · PERSIST, then the lens in the floor showing a frozen room far below. It ends at the title (the Long Stair is not built).
- `Journey` lists both. `StoryIntro` got `_make_pictures()` and `_next_scene()` so it can be reused.
- Test: experience `interludes` (the chapters lead to them; no drawn shapes; each plays through and leads on).
- Needs a human: pacing and wording; the "lens" is a window sprite scaled up, and the chalk star is a pack spark.

## Opening, spells and teaching pass (2026-10-01)

Requested: start the story with the Passage; explain every part of the screen; explain the rune system
in Part 3; hand over fire at the end of one part and heal at the end of the next, each with a reason and
a short explanation; and stop mana from ever stranding the player.

- **New Game flow.** Title -> the nine story pictures -> the Passage (the Belfry if the Passage is already
  done). The last picture now mentions the Novices' Way and that the Hush took some of her spells.
  Lowbell and Nan's cottage are no longer in the flow (their scenes and tests remain; nothing else
  was deleted). `Journey.after_story()` replaces `after_cottage()`.
- **The Passage is reordered** (`tools/levels/patch_tutorial.gd`, step `_fire_last`): 1 The Cellar, 2 The Broken
  Stair, 3 The Novices' Traps, **4 The Echo Door** (Echo stone, plate, gate), **5 The Kept Flame** (fireball
  and the pistons that need it), **6 The Cells** (slimes), then the exit. The Passage ends with fire. The
  Spring and its lesson are gone from the Passage.
- **Heal** now comes back with the third bell picture ("The Spring"): the great bell's ring shakes an old
  spring under the Belfry loose; running water is the one thing the Hush never held still; she cups it and
  remembers SPRING; the last line says what it does (stand still, press Q, 2 health for 20 mana, a hit
  breaks it). It is granted when the pictures end, or when Esc skips them.
- **Save compatibility:** the "old save gets every spell" rule now applies only to saves with progress
  and *no* `ability.*` flag, so a new save part-way through the Belfry does not get heal early.
- **UI tours** (`scripts/ui/ui_tour.gd`, once per save, flag `ui.tour.<id>`; the game pauses; Space/click
  next, Esc closes): `basics` (health bar, the Esc menu) a few seconds into the Passage; `fire` (mana bar,
  spell slots) and `echo` (the Echo tag) after the Kept Flame and the Echo stone; `objective` (the goal card)
  on first entering Belfry room 1; `runes` on first entering Observatory room 1 (four cards: four words per
  cube and W to inscribe; locked words cannot be changed, this room's cube has three locked; Tab shows every
  cube, a running cube must be switched off first; running runes use mana). Rooms use the new `Room.explainer`,
  shrines `AbilityShrine.TOURS`, lessons `LessonZone.tour`.
- **Mana soft-lock fix:** a new pixel-sprite `KindleFlame` (the Kept Flame's pedestal, always lit, a kindle
  point, not a checkpoint) now stands by the entrance of every room that had none: Belfry rooms 2, 4, 8, 9
  and Observatory rooms 2, 3, 5, 7. Every room of both parts now has a flame to kindle at.
- Tests: tutorial `abilities` (Echo before fire, no Spring/heal, zones tile, no early heal for new saves),
  tutorial `play` walks the new order, experience `story`/`title` (pictures lead to the Passage), `interludes`
  (three bell pictures, heal granted), new `tours` and `kindle`. Tours are switched off in all other suites.
- Needs a human: the pacing of the first tour (3.6 s after the first card), whether the rune cards are too
  long, the spring picture, and whether the extra flames feel natural.

## macOS export (2026-10-01)

- The `macOS` preset in `export_presets.cfg` is set up: universal (Intel and Apple Silicon), bundle id
  `com.sealedbelfry.game`, version 1.0.0, output `../../Videogames/Gahh/TheSealedBelfry-macOS.zip`
  (a zip of `The Sealed Belfry.app`). Run it with
  `godot --headless --path . --export-release "macOS"` (the 4.7.2 macOS export template is installed).
- Apple Silicon needs ETC2/ASTC textures, so `textures/vram_compression/import_etc2_astc=true` was added to
  `project.godot` (the project re-imports once; the Windows preset is unaffected).
- Built from Windows, so the app is **not notarized and has no Apple Developer signature** (Godot added its
  own signature only). Verified: the export finishes, the zip holds the .app with Info.plist, icon, .pck and
  _CodeSignature. **Not run on a Mac.** On first launch macOS will block it: right-click the app, choose
  Open, then Open again (or `xattr -dr com.apple.quarantine "The Sealed Belfry.app"`). Public distribution needs
  an Apple Developer ID and notarization.

## Waymarks: arrows that show the way on (2026-10-01)

Requested: make the map easier to understand with arrows that fit the game.
- **The Choir's waymarks** (`scripts/puzzle/waymark.gd`, `scenes/puzzle/waymark.tscn`): a small carved stone slab
  with a softly glowing arrow, pixel art from `tools/art/generate_waymark_sprites.gd` (`waymark.png`, 3 frames, in the
  packs' palette), a dim blue light that breathes, behind the player (z -1), no collision. In the story the monks
  cut them for novices, so they are part of the dungeon, not the interface. `direction` is right, left, up or down.
- **Where:** 11 along the Passage (`tools/levels/patch_tutorial.gd`, step `_waymarks`) and, in every Belfry and
  Observatory room, one soon after the way in, one in the middle of a long room and one before the way out
  (`waymarks()` in `tools/levels/build_chapter.gd`, used by both builders). 26 in the Belfry, 21 in the Observatory.
  They are hidden when guidance is off. New chapters should use the same helper.
- Test: experience `waymarks` (each is a pixel sprite with a known direction, none drawn from shapes, hidden with
  guidance off) and a contact sheet of every arrow in context (`user://test_shots/waymarks_*.png`).
- Looked at: every arrow in context on contact sheets. Arrows are all right-pointing for now; the rooms that go
  up (Belfry R5 lift, R9 stairs) have only right arrows, and a few arrows sit close to a "[W]" prompt.
- Needs a human: whether they are too bright or too frequent, and whether up arrows are wanted at the lift and the
  great bell's stairs.

## The rough game loop after the Novices' Way (2026-10-02)

Requested: "make a rough game loop of this in game". The Observatory now leads on, in the game, all the way to
two endings. It is deliberately rough: playable and tested end to end, but the puzzles are not tuned.

- **Order** (`scripts/story/journey.gd`): Observatory -> dome pictures -> **the Landing** (the foot of the Long
  Stair: five doors, a bell-light over each, a Kindle flame, a shrine) -> **four wings**, each two rooms ending
  in a bell, each followed by two or three story pictures and back to the Landing -> when all four bells have
  rung, the fifth door opens the pictures that lead to **the Eye** -> the great cube and **two endings**.
- **Built by** `tools/levels/build_wings.gd` (extends the Chapter 2 builder; run it to regenerate): `landing.tscn`,
  `wing_kiln.tscn`, `wing_cistern.tscn`, `wing_lamps.tscn`, `wing_galleries.tscn`, `eye.tscn` in
  `scenes/chapter/`. Flags: `kiln.`, `cistern.`, `lamps.`, `galleries.`, `eye.`, and `game.complete`.
- **Rooms** (rough versions of docs/STORY_PLAYTHROUGH.md; all solved by the tests with real input):
  - Kilnworks: *The Cold Forge* (this rough version has since been replaced by the finished room: see the next
    section) and *The Kiln Heart* (a Strong wind drives a stone onto a heavy plate, burn the brambles, ring the
    Forge Bell).
  - Drowned Cistern: *The First Pool* (a slime stands on a stone-only plate; a Long chill freezes it, and a frozen
    creature is heavy as stone) and *The Sluice* (two slimes, two plates, one cube; the Tide Bell).
  - Lampworks: *The Dark Reading Room* (a beam across a pit lights a crystal, which raises a bridge; since
    replaced by *The Hall of Lamps*, see the section of 2026-10-08) and
    *The Lamp Stair* (carry a glow cube under a high crystal; a Large glow reaches it; the Lamp Bell).
  - Folded Galleries: *The First Door* (carry a portal cube, Up-Right and Long, to doorway over a stone wall) and
    *The Fold Bell* (an Echo holds a plate, faint stairs rise to the Fold Bell); both since replaced by *The Folded
    Archive* and *Wren's Test*, see the second section of 2026-10-08.
  - The Eye: the great cube (fed by the dungeon, fully editable). `Light · Beam · Up · Long` is the Rewritten Sky;
    `Ice · Freeze · Self · Large` is the Stillness (a real ending that leads back: "that is not the only
    sentence"); anything else is "not enough". Ilse and Wren's bed are pixel sprites (`RoomSprite`).
- **Words:** each bell teaches its wing's words when it rings (`ChapterRoot.grants_words`), so skipping an optional
  tablet can never make the ending unwritable; every word of both endings is taught by the end of the Lampworks.
- **Pictures** (`StoryInterlude` kinds `kiln`, `cistern`, `lamps`, `galleries`, `eye`, `stillness`, `sky`): reuse
  the existing pixel-art picture builders plus a Landing picture (five doors, bell-lights lit by progress), a
  silent snowy world and a new star. The dome pictures now lead to the Landing, not the title.
- **Other changes:** `Burnable` no longer eats fireballs after it has been cleared (a cleared bramble curtain used
  to swallow a second bolt; found by the Forge test). `Interactable` guards a freed player. Title screen:
  "The Long Stair" entry in the parts list, Continue leads to the Landing once the Observatory is done, and
  the line under the menu counts the bells. Pause-menu words for the new scenes use the existing chapter plumbing.
- **Tests:** new `tests/wing_suite.gd` (`-- wing`: journey, smoke, landing, k1, k2, c1, c2, l1, l2, g1, g2, eye,
  loop) and experience `longstair`. Checked by eye: screenshots of every room, the Landing doors, and the
  bridge, portal and frozen-slime moments.
- **Rough edges, on purpose:** each wing has two rooms, not six and a boss; no new creatures (the Cistern uses
  slimes, the Kiln uses brambles); the puzzles are a notch above the Novices' Way, not the planned difficulty;
  the Eye has no Hush storm or tug of words; the pictures reuse existing art. The player's own fireball
  makes some fire puzzles easier than the rune solution (the Cold Forge is the exception: the brazier is out of its range).
- Needs a human: whether the loop reads, the Landing's doors (they are dark; bell-lights show progress), how hard
  each room is, the pictures' wording, and the two endings' feel.

## The Cold Forge finished, and four playtest fixes (2026-10-02/03)

Requested (the playtest notes, in short): when something a room needs is lost and the room can't be finished,
say so and say how to reset (the example: a slime that had to hold a door open died); choosing Title at the end
of a part skipped the pictures (show the pictures first, then the card with Continue, Title and the run's
numbers); portals only worked one way; nothing said that Tab lists your runes, or when words can and can't be
changed. And: fully make and polish the first room of the Kilnworks, give a good reason to go into that hallway,
and make it take at least 30 minutes.

**1. A room that can't be finished says so.** Anything a puzzle needs that can be destroyed or wedged joins the
group `puzzle_critical` and answers `lost_reason()`; `Room.broken_reason()` asks them. `ChapterRoot` then shows a
red banner (THIS ROOM CAN'T BE FINISHED NOW / why / "Reset the room: press Esc, choose Map, then Reset Room")
once the act card and the room's name have cleared, and the Esc menu opens straight on Map, Reset Room until it is
fixed. In the game: the Cistern's slimes (`Slime.required`), the Cold Forge's coal cart (burned in slag) and bench
stone (`WindBody.required_area`: if it ever came off the bench before breaking the plug), and the Belfry's two push
blocks (`PushableBlock.needed_dir`: shoved the wrong way up against a wall, nobody can get behind them). The
Belfry's bell slimes are warded (they can't be killed), so they never strand a room. **Rule for new rooms:**
anything needed that can be lost or wedged joins `puzzle_critical`.

**2. The end of a part.** A finished part's card waits (`ChapterComplete.pending`) for its story pictures: the
pictures play first, then the card (time, deaths, and resets, hints and pages where counted; Continue and Return to
Title). The Passage's exit shows a Part 1 card the same way (time and deaths under `tutorial.stat.*`). The last
ending shows THE END with the whole run's time and deaths and "Thank you for playing." A card left waiting by a
level that was quit is cleared when a level or the title starts.

**3. Portals work both ways.** Walk into either side and come out of the other, moving as before. A side that has
just let something out won't take it back until it has stepped clear (no bouncing), and a side only carries a
body that is really inside it: an engine area can still list a body for a frame after it was carried away, which
sent Echidna through twice, into the ceiling of the Galleries.

**4. Rune editing explained.** The rune tour (five cards: four words in a cube; words change only while the cube is
OFF; LOCKED words never change; Tab lists your runes; running runes use mana) plays the first time she reaches any
rune cube, wherever she came in, and Esc › Echidna › Runes › "How rune cubes work" plays it again. The inscription
screen marks LOCKED slots with a padlock and RUNNING ones while the cube is on, says why a word was refused, and
carries the rules on its bottom line. The Tab list repeats the rules and has an Inscribe button for the cube she
stands at. A running cube's prompt reads "Running: switch off to edit". Cubes and lecterns win the use key over a
hint stone beside them (`Interactable.use_priority`).

**5. The Cold Forge (Kilnworks room 1), finished.** The chain, the story and the numbers are in
`docs/STORY_PLAYTHROUGH.md`; in short: relight the Great Kiln with coal, air and a bursting flame, all at once.
- **Why she goes in:** the dome's third picture (THE LONG STAIR: rimed doors, warm light under one), the Choir's
  note on the Landing ("Ring the Forge Bell first: its heat runs in the pipes behind every door and thaws the
  next"), frost on the sealed Landing doors and warm light spilling from under the open one.
- **The room:** 45 columns on two levels (the hearth and a slag pit; the hall with the Smith's bench and alcove, a
  perch, the bellows shaft, the Great Kiln, the coal loft and its lift, a cell above it; the Forge Door). Built by
  `kiln_cold_forge()` in `tools/levels/build_wings.gd`; the Kiln Heart moved east (columns 44-68, its cube is "Heart Cube").
- **New pieces:** `GreatKiln` (scripts/puzzle/great_kiln.gd: fuel bay, pipe inlet, firebox, three lamps, feedback
  when a try fails, the roar: light, sound, camera, the hall warms, the frost melts, a kindle spot on its roof),
  `SlagPool` (scripts/traps/slag_pool.gd), `ForgeDoor`, `MeltingFrost`, `RevealTrigger`; `WindBody` sprites,
  burning and the kiln taking its coal; hanging braziers; `CrackedWall` sprites; fire rides wind (`FireBall`: a
  bolt that enters a running current turns with it and its range starts again). All new art is pixel sprites from
  `tools/art/generate_kiln_sprites.gd`. Five hint stones (three stages each) and three ledger pages.

**Fixes found while playing it through with real input.** An updraft now brakes a fall through it
(`PlayerWind.FALL_BRAKE_PER_FORCE`): at the top of a column she settles within about 35 px instead of bobbing about
100, so stepping off onto a ledge no longer needs luck (every lift in the game). The kiln is 260 px tall so its roof
is flush with the ledges beside it (a 4 px lip stopped her). The loft is flat where the lift docks (a rounded cap
tile caught her). The slag no longer burns an object the frame after a reset puts it back (the same stale-area
problem as the portal). "YOUR RUN" sits above the numbers on the card. The red banner no longer covers the act
card. The Landing's warm door now glows from underneath (a light alone barely showed on blue stone), its frost is a
rime crust (it looked like static), and the door names sit above the bell-lights (the floor's grass hid them).

**Tests** (real input unless noted): wing `forge_full` (the whole Cold Forge, 50 checks; the scripted route alone
takes 113 s of game time when it knows every answer), `k1` (part by part, 43), `forge_broken` (12, the stone check by placing it),
`forge_page3` (7), `g1` (both ways through the portal), `eye` (THE END card), `landing`; chapter `stuck` (6) and room
9 (pictures, then the card); tutorial `play` (the Part 1 card, then Continue); experience `tours` (the rune tour on
first reaching a cube, the menu replay) and `interludes` (three dome pictures). Full run of all six suites, all
passing: tutorial 173, chapter 331, presentation 111, experience 241, rune 304, wing 282 (1,442 checks). Two
suites first stalled overnight with vsync on (frames wait for the screen, which was asleep) and were rerun with
`--disable-vsync`, which also makes a run several times faster; the presentation audio check fails only when
another Godot process is running at the same time.

**Looked at** (screenshots): the Cold Forge (hearth, shaft, kiln roof, loft, alcove, cell, the banner), the
Landing (warm door, sealed door), THE END card.

**Needs a human playtest:** whether the Cold Forge takes 30 minutes. The design estimate for a first-time player is
22 to 35 minutes; the tests only prove every step can be done. Also: whether each step reads without hints, the
shaft and lift feel, the roar, the rune tour's length (five cards), the banner's wording, and the Galleries'
portal now that it works both ways (walking under its far side on top of the wall sends you back down, which is
right but may surprise).

## The Kiln Heart rebuilt, and the second playtest list (2026-10-03)

Requested: make the Kilnworks' second room "a lot longer and complicated like room 1", and eight fixes from the
user's playtest list: say which flame refills mana (not "a torch"); arrows that blend into the background; cage the
old room behind her when she enters a new one; the hot spring that gives heal at the end of its part, not in the
pictures; at the end of each part only the title or the next part; after the opening pictures, walk on the surface
to Nan's house instead of dropping straight into the dungeon; call the tutorial "Level 1"; and the interface tour
should point arrows at what it explains (the health bar, then the mana bar and its number), with "MP" renamed MANA
and moved to the left (health to the right).

**1. The Kiln Heart (Kilnworks room 2), rebuilt.** 59 columns (44-102, the old room was 25), five parts, three new
words; the chain and the numbers are in `docs/STORY_PLAYTHROUGH.md`. In short: the Shutter Hall (**Delay**: the
Shutter Cube's bolt waits two seconds while she stands on the plate that holds the shutter open, and lights the Ash
Lamp beyond it, which holds the shutter for good); the Slag Lake (three heat vents, mounted dungeon cubes that run
from the start, and ledges a hand's width from each column); the Coal Racks (**Large**: from the pedestal at the end
of the gallery, a normal gust tips the middle skip of coal into the Heart, a Large one all three); the Heart (**Split**:
`Fire · Projectile · Up-Right · Split` from the pedestal beside it lights its three hanging burners together; each
burns only half a second, so one at a time does nothing); the hoist, the only way up to the Forge Bell. Built by
`kiln_heart()` in `tools/levels/build_wings.gd`.
- **New pieces:** `HeartCrucible` (scripts/puzzle/heart_crucible.gd: coal in its mouth, three lamps, "it's cold: n of 3
  skips" when the burners flare over an empty Heart, the beat: light, sound, camera, a title card, the frost melting,
  its burners burning steady, a kindle point; saved); its pixel sprite (`_heart_crucible` in
  tools/art/generate_kiln_sprites.gd). `WindBody.persist_id` (a skip the Heart took stays taken), `Brazier.persist_id`
  (the Ash Lamp stays lit), a frost patch can melt on any flag. **Iron grates now let wind through** (their bars join
  `wind_permeable`, which WindField's rays already skipped, but nothing had joined it): without it a gust from the
  gallery could never reach the top rack's skip. Running "machinery" cubes (the vents and the Cold Forge's shaft:
  fed by the dungeon, every word carved, on from the start) show "Always on" in the Tab list, and Deactivate All
  leaves them running.
- **Found while testing:** a gap in the first ledge over the lake (the low ledge with the fifth page was unreachable:
  walking off the ledge's end, the second vent's column catches her first); the burners first hung where the zoomed
  camera couldn't see them from the pedestal (now lower, and the camera glances at them the first time she reaches
  the tower floor); after the beat the burners went dark again (they now burn steady).

**2. Which flame.** `KindlePrompt` (scripts/ui/kindle_prompt.gd) floats over the nearest flame she can kindle at
whenever her mana isn't full: a faint "[R]" from 220 px, "[R] Kindle" in reach. Pressing R away from one says which
kinds work (a flame bowl, a shrine, a candle, a lit brazier; "Wall torches won't do") and which side the nearest is
on; the interface tour's mana card says the same.

**3. Arrows that blend in.** Waymarks are chalk now (a pale 24×12 pixel arrow, the faintest light; Wren's chalk in
the lore), and Lowbell has three on the way to Nan's door.

**4. The cage behind her.** Going into a room further on than ever drops the gate or door at its way in for good
(`PortcullisGate.seal()`, `ForgeDoor.seal()`; `ChapterRoot._enter`); doorways with nothing to close them get a raised
"BackGate" at load. On a reload (Continue, or a death) the ways back are shut up to the room she starts in, never
the way out of it, so she can't be shut in.

**5. The hot spring.** At the end of Part 2 (the Belfry's room 9, after the great bell): an `AbilityShrine` showing
the spring (sprite at 2x, steam), "Drink"; it gives heal. The bell's pictures no longer have the spring picture
(they still give heal if the spring was somehow missed).

**6. The end of a part.** The end card has Continue and Return to Title only (the "explore" button is gone).

**7. Walking to Nan's.** After the opening pictures the game goes to Lowbell (`story_intro._next_scene()` returns
`Journey.LOWBELL`): she walks through the village to Nan's door, then the cottage, then the cellar.

**8. Levels.** "Choose a Level" on the title: Level 1 · The Passage (tutorial), Level 2 · The Belfry, Level 3 · The
Observatory; the Passage's first sign and phase card say Level 1; the end cards say LEVEL n COMPLETE ("Continue to
Level 2: The Belfry", "Continue to Level 3: The Observatory"). Internal ids and save flags are unchanged.

**9. The HUD and its tour.** MANA (the bar and "MANA n") on the left, health ("n / max") on the right; the pause menu
says MANA. The interface tour draws gold arrows (numbered when there are two) at the health bar and its number, and
at the mana bar and its number.

**Tests** (real input unless noted): wing `k2` (the Kiln Heart part by part, 51 checks, including the wrong tries: her
own fire from the plate, the cube's bolt on the shut shutter, a normal gust, a burner lit by hand, the burners over an
empty Heart), `heart_full` (the whole room from the Forge Door to the bell with her own feet and no teleports, 19;
the scripted route takes 73 s of game time when it knows every answer), `heart_broken` (a skip on the tower floor or
in the slag; the banner; Reset Room, 5), `heart_look` (screenshots); chapter `ways` (the cage), room 9 (the hot
spring); experience `tours` (the arrows), `lowbell` (the chalk arrows), the story going to Lowbell; tutorial (the
Level 1 card). Three chapter checks and one wing check asserted the old rule that gates behind her stay open (or
that all of the Kilnworks' frost melts with the Great Kiln) and were changed to the new rule. A tutorial check had
a typing warning that stops the suite from compiling (`weakref()` returns a Variant). Full run, all passing:
tutorial 173, chapter 341, presentation 111, experience 243, rune 304, wing 347 (1,519 checks).

**Looked at** (screenshots): every part of the Kiln Heart (hall, shutter, bank, lake, low ledge, gallery, racks,
Heart, burners, hoist, balcony and bell), the tour's arrows on the health and mana cards.

**Needs a human playtest:** the Kiln Heart's length and difficulty (design estimate 12 to 20 minutes for a first-time
player; the tests prove every step can be done, not how long it takes), whether Delay, Large and Up-Right Split can be
worked out from the room and its tablets, whether the three burners can be lit by hand fast enough to skip Split (each
burns half a second), the hop over the Shutter Cube, and the cage dropping behind her (does it read as "go on", not
as a trap?).

## The Still Water: the Cistern's first room, reworked (2026-10-04)

Requested: rework the Drowned Cistern's first room completely, to take about 30 minutes like the Cold Forge, with
a whole new theme based on freezing things.

**The room** (`cistern_still_water()` in `tools/levels/build_wings.gd`, cols 0-56; the Sluice moved east to cols 56-80).
Everything in it is about freezing things, each kind useful in its own way, with one rule: rising water freezes
where it first meets the cold. Water frozen into a floor (two pools: Ice, Freeze, Long); old ice melted by fire
(a plug in the doorway, the Warden's cube behind it); a creature frozen to stone-weight through an iron grate (the
Clock Gate on the walkway); five fountains frozen into a stair by cold laid aslant (**Down-Right** and Long, from a
mounted cube worked at a lectern); and a tide clock stopped at the hour by cold placed just above its mark, which
opens the Sluice Door. The chain is in `docs/STORY_PLAYTHROUGH.md`. Three ledger pages, five hint stones, three
kindle flames, the Hush's frost that melts when the clock strikes. Teaches Ice, Freeze, Long, Down-Right (Persist
stays in the Sluice, "the word that made the silence").

**New pieces.**
- `CisternPool` (scripts/traps/cistern_pool.gd): black water too cold to swim (a hit and back to the candle);
  objects sink (`WindBody.sink`); its surface freezes in 16 px strips wherever the cold reaches, into ice level
  with the banks that holds while the cold lasts and a moment after, flickering before it gives way.
- `Fountain` (scripts/puzzle/fountain.gd): a jet that leaps, holds, falls and rests; cold reaching it holds it as a
  pillar of ice (one-way: land on top, jump up through it). A leaping jet checks the cold a few px at a time, so it
  freezes exactly where it meets it (a fast leap could otherwise overshoot by 17 px, too tall a step).
- `TideClock` (scripts/puzzle/tide_clock.gd): the column, the float, the strike (only when the float is held at the
  mark for 1.5 s; the tide only touches it in passing), the "short of the hour" message, saved.
- `FreezeField` now asks anything in the group "freezable" each frame (`chill_from(field)`); `covers(rect)` samples
  the shape on a 10 px grid and needs a clear line from the cube; ice (the group "ice": frozen water, ice bridges)
  never blocks the cold, iron grates let it through.
- Pixel sprites from `tools/art/generate_cistern_sprites.gd`: the water, the fountain basin, the tide clock's frame and
  float, the Warden's carving, a bronze pipe. The water in the jets and the clock and all the ice are drawn
  effects, like the Ice Bridge.

**Found while testing.** A plain array passed where the freeze check wants a typed one stopped every fountain
freezing (a runtime type error); a slime on the floor path would have attacked her on every pass (it lives in a
cell under a grate now, which also made the cold-through-bars idea); 24 px pillars made the stair a matter of
pixel-perfect jumps (now 32); from the step below the gallery, or the walkway, the gallery and steps block the cold
(so the wrong answer to test is Large, which freezes the tide a stride short); the run-up and jump off the long ice.

**Tests** (real input unless noted): wing `c1` (part by part, 46 checks, with the wrong tries: a normal freeze on
the long pool, the stair without Long), `c1_full` (the whole room with her own feet, 16; the scripted route takes 63
s of game time), `c1_short` (Large holds the tide short, and the room says so, 3), `c1_broken` (the gatekeeper
killed: banner, Reset Room, 3), `c1_look` (screenshots, not run by default). Full run, all passing: tutorial 173,
chapter 341, presentation 111, experience 243, rune 304 (the Observatory's ice runes still work with the new
freezing), wing 405 (1,577 checks).

**Looked at** (screenshots): the stair and pools, the frozen first pool, the island, the far bank and the ice plug,
the tide clock (running, struck), the clock gallery and steps, the walkway and the Clock Gate, the fountain court
(running and frozen into a stair), the door.

**Needs a human playtest:** whether it takes about 30 minutes (the design estimate is 20 to 30; the scripted route
is shorter than the Cold Forge's because the room has less back-and-forth), whether "rising water freezes where it
meets the cold" can be worked out from the fountains and then used at the clock, the fountain climb's timing, and
the switch-on-as-the-tide-rises timing at the clock.

## The Great Sluice: the Cistern's second room, reworked (2026-10-05; made simpler on 2026-10-07, see below)

Requested: rework the second room to take around an hour to beat. Taken to mean the Drowned Cistern's second room
(the Sluice, after the Still Water), since the request before it was about the Cistern's first room.

**The room** (`cistern_great_sluice()` in `tools/levels/build_wings.gd`, cols 56-119, replacing the Sluice). The Warden's
sluice works. The Tide Bell is drowned in its well; the Great Sluice that drains it is balanced on two
counterweights, a weight of three held still on a pan and the tide held at its high mark. It teaches **Persist**
(the cold that never lets go) and uses it four ways, then reuses the room's one free cube:
1. *The Silence Gallery:* a slime in a cell under a grate holds a slow plate (it opens the Silence Gate only after
   8 s held; a freeze lasts 6). Persist on the Keeper Cube (dungeon-powered).
2. *The Tide Hall:* an 18-tile basin set with iron teeth; its tide fills, stands, empties and rests (20.5 s). The
   Tide Lever (a mounted cube over the west doorway, worked from three lecterns, paid with her mana) freezes it:
   switched on while the hall is dry, the rising tide freezes level with the doorways; while it is up, where it
   stands. Persist holds it while she crosses, hops the low pier and takes the Sluice Cube.
3. *The Weigh House:* the pan wants three weights of stone: the Ballast (Strong on the Drover Cube; a kerb by the
   well's wall stops it on the pan) and two slimes hopping on the pan, frozen by the Sluice Cube in the socket under
   the shelf (Ice, Freeze, Right, Persist; free on the socket).
4. *The high mark:* up the lift to the high ledge (through the high door over the hall), where the tide's top and
   the mark can be seen; the lever switched on as the tide stands at its top. With the pan held, two seconds of both
   open the Great Sluice for good (saved): the well drains through the sluice gate.
5. *The fallen span:* the High Walk to the well has a three-tile gap. The Sluice Cube, switched off and taken out of
   its socket (the sluice stays open), set at the edge: Ice, Bridge, Right.
6. Down into the drained well and the Tide Bell (the end of the wing).
Optional: three ledger pages (iv on a high gallery shelf, a charged jump; v washed out past the sluice gate; vi on
the far pier: the tide frozen on its way down from the high ledge, and the Warden's lectern on the pier brings her
down onto the next tide frozen at the doorways). Five hint stones, two kindle flames, three candles, the Hush's frost
melting when the well drains. The admin page's entry is now "Cistern · The Great Sluice".

**New pieces.**
- `TidePool` (scripts/traps/tide_pool.gd): a basin's tide (or a still well) that cycles; too cold to swim (a hit, and
  back to the nearest lit candle of its list); objects sink; cold holds the whole surface as one-way ice where it
  stands, or where the rising water first meets the cold (checked 3 px at a time); `flush_with` makes ice that forms
  within 6 px of a doorway floor flush with it; a circuit drains it for good (saved). The deep water is translucent
  teal with drifting light; the ice sheet is drawn over the surface sprites, which stop and pale while frozen.
- `TideMark` (scripts/puzzle/tide_mark.gd): a power source reading a tide: BELOW (the doorway gates: open while the
  floor is dry or frozen below them) or HELD (the high mark: frozen at or above it).
- `PressurePlate.weight_needed` and `weight()`: a weigh pan wanting several weights at once, with a notch for each,
  lit as they arrive. One weight (the default) behaves exactly as before.
- `FreezeField.covers()` takes a sampling step (the long tide uses 16 px).

**Found while testing** (screenshots and the play-through tests). Tall piers would have blocked the ice crossing (now
a low pier and a floating far pier); "Long and Persist" can't both be written, there is one modifier slot (the lever
moved down over the doorway so a normal-reach Persist freeze catches the tide at the doorways); a 4 px lip between
ice and the doorway floor stopped her (`flush_with`); the well's west wall ended 22 px above the floor and a slime
slipped under it; a Strong wind threw the Ballast 250 px past the pan (the kerb), and a slime could freeze 2 px short
of the pan (the pan now starts at the socket); with the socket at the wall end a stone pushed first would have taken
its place (it is under the shelf now); the high mark needed a wall face (the high ledge and High Walk moved up a row);
the dry basin could be crossed with charged jumps (the iron teeth); the deep water drew as a black block, and the ice
was hidden under the water sprites; a cube must be switched off before it can be carried (the hint says so).

**Tests** (real input unless noted): wing `c2` (part by part, 56 checks, with the wrong tries: the Keeper Cube as
written lets go before the slow plate opens, a steady wind can't shift the Ballast), `c2_full` (the whole room with
her own feet, 49; the scripted route takes 143 s of game time, against 63 s for the Still Water), `c2_pages` (the
charged jump to page iv; page vi with the falling tide frozen under the far pier, and back down with the pier's
lectern), `c2_broken` (the Keeper or a pan slime killed: banner, Reset Room; after the sluice opens nothing breaks,
6), `c2_look` (screenshots, not run by default).
Full run (2026-10-05), all passing: tutorial 173, chapter 341, presentation 111, experience 243, rune 304 (the
Observatory's ice runes still work with the changed freeze), wing 530 (1,702 checks). `c2_pages` is 12 checks.

**Looked at** (screenshots): the gallery and the cell, the Silence Gate, the hall dry, frozen low, frozen at its top
and filling, the low pier and the Sluice Cube, the far pier, the high ledge and the high mark, the Weigh House (pan,
socket, shelf, kerb, slimes), the bridge over the fallen span, the Bell Well full and drained, the outflow.

**Needs a human playtest:** whether it takes about an hour (design estimate 45 to 70 minutes for a first-time player:
the scripted route is 2.3 times the Still Water's, with more to work out; the tests prove it can be done, not how
long it takes); whether the tide rule can be read from trying; the crossing's mana (about 60 of 100 in the tests);
the high-mark timing from the high ledge (about 4 s in each 20 s cycle); whether players think to take the Sluice
Cube back out for the bridge; the slimes on the pan; the far pier as an optional page.

## Smoother motion, scene fades and a steadier camera (2026-10-05)

Requested: polish the game a bit and make it seem smoother.

**What was wrong.** The two screens here run at 120 Hz and 165 Hz, but the game world moves in 60 Hz physics
steps. Echidna, creatures, platforms and cubes therefore moved in uneven two-or-three-frame jumps while the camera
glided every frame: a visible judder, worst at 165 Hz. Several scene changes also cut hard, and on high ledges the
view bobbed up and down with every hop.

**Changes.**
- **Smooth motion** (`Settings.smooth_motion`, on by default, saved; a switch in the pause menu's Graphics list and
  on the title's settings panel): turns on Godot's physics interpolation at run time (`SceneTree.physics_interpolation`,
  with `Engine.physics_jitter_fix` 0), so everything that moves in physics steps is drawn in between them. The
  project file is unchanged. Things animated every drawn frame opt out (`physics_interpolation_mode` OFF) so they
  stay smooth: every CanvasLayer (menus, HUD, cards, story pictures; a hook in Settings catches them as they are
  added), the title screen and story pictures, Lowbell's and the cottage's tweened scenery and intro cameras (Echidna
  and her camera stay interpolated), floating text, damage numbers, the forge door's slide, a ledger page's bob, a
  candle's flame and the parallax backgrounds. Teleports reset the interpolation (spawn placement and Reset Room in
  ChapterRoot; teleport_to, portals, cubes and wind bodies already did).
- **Camera** (`scripts/world/camera_bounds.gd`): with smooth motion, the follow and its offsets (shake, the look at a
  distant point) run in the physics step, so the engine draws camera and world consistently and the offset clamp is
  exact (an earlier version set the offset every drawn frame and could show 1-7 px past a room's edge; the chapter
  suite's camera checks caught it). Without smooth motion it follows every drawn frame as before. New `hop_band`
  (72 px): the camera holds its height while she is within a hop of the floor she last stood on, and follows a
  hop's height behind her once she climbs, falls or rides higher.
- **Scene fades** (`scripts/ui/scene_fade.gd`, `SceneFade.change` / `SceneFade.restart`): every scene change and
  restart fades through black (0.3 s out, 0.45 s in): Landing doors (she stops first), the title's level starts,
  Quit to Title (the world holds still while it fades), the end card's Continue, the ending, and restarting after
  death or from the menu. Scenes that already fade themselves to black (the story pictures, Lowbell, the cottage, a
  chapter's end) now also fade the next scene in instead of popping. Only the fade-out blocks a second request (no
  double loads); the new scene is live while it fades in.

**Measured** (a probe, not part of the suites: uncapped at 165 or 120 fps in a 1152x648 window, sprinting across the
Landing, every drawn frame read back to find a bar riding on her and a bar fixed in the world; "wobble" is how far
each frame lands from where its two neighbours put it):

| | her bar, wobble | world bar, wobble |
|---|---|---|
| 165 fps, before | 3.8 px | 2.8 px |
| 165 fps, smooth motion | 0.4 px | 0.8 px |
| 120 fps, before | 4.0 px | 4.1 px |
| 120 fps, smooth motion | 0.5 px | 1.2 px |

What is left is pixel rounding. Hopping along the High Walk (a high ledge in a tall room), the view moved 103 screen
px up and down over five hops before and 0.1 px after.

**Found while testing.** A static function named `reload` on the fade clashed with `GDScript.reload()` and broke
restarting after death (renamed `restart`); the first fade ignored a scene change asked for while the previous scene
was still fading in (the title's Continue pressed straight away did nothing); the Graphics menu has one more row (the
experience test counts it).

**Tests.** `tests/run_tests.gd` turns smooth motion on (the default), so the suites run with interpolation. The
chapter suite's camera-bounds check waits two steps after a room's slide ends before judging (the slide's last step
is drawn a step later). Full run, 2026-10-06: tutorial 172 of 173, chapter 341, presentation 111, experience 243,
rune 304, wing 530 (1,701 of 1,702). The one failure, "both slimes defeated with fireballs" in the tutorial
playthrough, aims with the real mouse and flakes either way: rerun alone it failed 1 time in 3 with smooth motion
on and 1 in 5 with it off.

**Needs a human look** (on the 120 Hz and 165 Hz screens): whether walking, sprinting, jumping and riding lifts feel
smooth now; anything that looks stepped or laggy (it would be something animated every drawn frame that still
follows physics steps; turning Smooth motion off in the menu brings back the old behaviour for comparison); whether
the steadier camera on high ledges feels better or hides anything you need to see; and the fades' length.

## Merged GitHub main, an instant charged jump, a simpler Great Sluice (2026-10-07)

**Merge.** GitHub `main` had three new commits from a teammate (a playable witch prologue with story dialogue, a
bell aftermath between the Belfry and the Observatory, a background bug hunt with ten fixes (once in `docs/BUG_HUNT.md`, removed in the release cleanup),
headless-friendly tests and two new suites, `prologue` and `adversarial`). The local smooth-motion work was set
aside, `teammate-work` fast-forwarded to `main` (33692f0), and the local work reapplied. One conflict
(`scripts/ui/chapter_complete.gd`): both kept, the bell-aftermath redirect then the scene fade. The new story scenes
were brought in line with the smooth-motion and fade rules (their exits and the prologue's restart go through
`SceneFade`; their per-frame scenery, cameras, bridge and wisp opt out of interpolation, Echidna stays smoothed).
The merged tests aimed fireballs by pushing mouse events, which a desktop window ignores (it reads the OS cursor),
so every windowed fireball check missed (tutorial 20, chapter 62, experience 5 failures). Windowed runs now aim with the
player's new test-only `aim_override` instead of the OS cursor (so a test run no longer moves the mouse, and a moved
mouse no longer spoils a run; the shot still goes through the real shoot input, mana and cooldown); headless runs
keep the teammate's `BackgroundAim`.

**Charged jump.** Requested: the charge should register the moment crouch is pressed, with no delay. It used to do
nothing for a second, then charge for 1.5 s. Now `CHARGE_START_TIME` is 0 and `MAX_CHARGE_TIME` 1.5 s: power, bar,
breeze and glow from the first frame, full after 1.5 s, the same top height. (The breeze's settle no longer divides
by the start time.) The presentation `charge` checks now test the instant start.

**The Great Sluice, simpler and clearer.** Requested: rework it (chosen: "simpler and clearer"). Cut: the high mark
(freezing the tide at its very top, a 4 s window in a 20 s cycle, from the high ledge), the ballast stone and its
Strong-wind Drover Cube and kerb, and the High Walk's fallen span with its ice bridge. The Great Sluice now opens
when its weigh pan holds two weights: the two slimes on it, frozen by the Sluice Cube in the socket (Persist, free
there). The Tide Lever is fed by the dungeon (no mana to budget while crossing), and the tide's dry wait is 4 s
(was 7). The far pier (page vi) stays as an optional challenge from the high ledge. Hints, steps, the Warden's page
v and the room's notes were rewritten to match. Scripted route 97 s of game time (was 143). Design estimate 25 to 40
minutes; it needs a human playtest. Tests: wing `c2` 38, `c2_full` 33, `c2_pages` 12, `c2_broken` 6, `c2_look`.
Full run (2026-10-07, eight suites), all passing: tutorial 173, chapter 341, presentation 111, experience 246,
rune 304, wing 496, prologue 38, adversarial 18 (1,727 checks).

## The Hall of Lamps: the Lampworks' first room, reworked (2026-10-08)

Requested: rework the Lampworks' first room around light so that it takes about an hour to beat. *The Dark
Reading Room* (one beam across one pit, a minute's work) is replaced by **The Hall of Lamps** (`lamps_hall()` in
`tools/levels/build_wings.gd`, columns 0-96; the Lamp Stair moved east with it, `lamps_stair(o)`). One long room in five
parts, each teaching one thing about light and ending with a lamp lit that opens the way on. No timing anywhere.
The story of each part is in docs/STORY_PLAYTHROUGH.md (Chapter 3, item 1).

- **The parts.** *Reading Room* (Light, Beam: a bridge over a spiked pit). *Mirror Gallery* (Bounce; three
  mirrors, two hung high and turned from wheels on the floor, carry the Gallery Cube's beam up, across and down,
  680 px, inside a plain beam's 900). *Watchers' Walk* (Glow, Self: the Watch Cube glowing in a socket on a
  stone-only plate holds the patrolling Watcher there as stone; a Watcher stops where light begins, so Large stops
  him short of the plate). *Watch Lamp* (her fire on a hung brazier holds the second Watcher; from his back a
  charged jump carries her and the cube to a ledge 132 px up, out of reach from the floor). *Dark Stacks* (a
  walkway of light-revealed stones over spikes: a hung brazier lights the first four, the cube on the middle
  pillar one each side or two with Large, the Stacks Lamp the last four; plain leaves a 128 px gap, Large 64,
  none 192). *Great Lamp* (Up-Left on the Door Cube). Learned here: Light, Beam, Bounce, Glow, Self, Up-Left.
- **Making the long room fair.** A low vault over the chasm (underside y 400) caps every jump at about 165 px, so
  the dark can't be jumped without the cube's light (her charged, sprinting jump otherwise carries ~224 px). Gates
  sit in stone walls, never free-standing in the tall hall (a charged jump from the cube's top would clear one).
  The lamps, mirrors and the Great Lamp hang low enough to be seen from the floor (the camera shows about 190 px
  above her). Reset Room here returns her to the last shrine she lit (new opt-in `Room.reset_at_shrine`, used only
  by this room; other rooms still go back to their entrance); the gates behind her are saved open, so nothing is
  out of reach.
- **New pieces.** `HallLamp` (`scripts/puzzle/hall_lamp.gd`, `scenes/puzzle/hall_lamp.tscn`): a hanging pixel-art
  lamp, dark until a circuit lights it. Sprites by `tools/art/generate_lamp_sprites.gd`: `hall_lamp`, `great_lamp`,
  `bookshelf`, `lamplighter_plaque` (registered in `SurfaceArt.STRIPS`). `SpectralPlatform.casts_shadow` (default
  true): when false, a light-revealed platform never shades another one like it (lit stones were shading the
  stones beyond them); it is still solid and still blocks light for everything else. Three Lamplighter's ledger
  pages (`lamps.page.1-3`, `total_pages` 3).
- **Tests** (wing suite): `l1` part by part with the wrong tries (Large off the plate, straight up misses) 61,
  `l1_full` the straight route 56 (98 s of game time), `l1_pages` 43, `l1_dark` 6 (the ledge out of reach from the
  floor; without the cube's light both a running jump and her longest jump fall short; Reset Room to the shrine),
  `l1_look` screenshots and wall/vault probes. `l2` unchanged (it finds the Lamp Stair's pieces by name).
- **Estimate.** Design estimate for a first-time player: about 45 to 60 minutes. That is a guess from the number
  of steps; only a human playtest can confirm it (the room has not been played by a person yet).

## The Folded Galleries rebuilt: the Folded Archive and Wren's Test (2026-10-08)

Requested: fully rework the Galleries so the whole wing takes about two hours, with the detail and depth of the
other three wings. The two one-minute rooms (*The First Door*, *The Fold Bell*) are replaced by two long rooms
built by `galleries_archive()` (cols 0-70) and `galleries_wren()` (cols 70-134) in `tools/levels/build_wings.gd`. Their
story is in docs/STORY_PLAYTHROUGH.md (Chapter 4). Words taught: Space and Portal (the Archive), Repeat and
Down-Left (Wren's Test).

- **The Folded Archive** (five parts): the Sealed Door (a doorway through a frozen door and rock), the Tall
  Stacks (the Archive Cube in a socket, Portal Up: the far doorway hangs over a shelf 196 px up), the Sealed
  Reading Room (an Echo recorded jumping in through the doorway holds a plate in a sealed pocket), the Pillar
  (Right comes out in a hollow inside a pillar of rock, Long goes through; an Echo recorded going in still goes
  in after the cube is rewritten to Long, and holds the gate beyond), the Hearth (fire thrown straight up
  through a doorway hung in the air comes out in a sealed hearth, into its brazier).
- **Wren's Test** (four locks Wren half-wrote, one seal each on her door): Again (Repeat keeps the Ember Lift's
  brazier burning; it burns two seconds), Aslant (Down-Left on the Frost Lock freezes five fountains into a
  stair; the Cistern's fountains mirrored), Two Hearths (two braziers 448 px apart, two seconds each: an Echo
  throws at one while she throws at the other), the Last Crystal (Bounce and three mirrors; the last mirror's
  wheel is in a sealed pocket reached by a doorway Up). Then Wren's door, Wren, and the Fold Bell.
- **Gates held by an Echo stay open once she is through:** each such gate's circuit is ANY of [the plate, a
  latched circuit on a threshold plate just past the gate]. Reset Room returns to the last shrine lit
  (`reset_at_shrine`, as in the Hall of Lamps).
- **Engine changes (shared, small):** fire flies through portals (`RunePortal._carry_fire`: a bolt in one
  doorway comes out of the other with the rest of its range; a bolt that grazes the portal's own cube in its
  doorway passes instead of bursting, `takes_fire_at`, `FireBall._on_body_entered`); a burning brazier hit by
  more fire burns its full time again (`Brazier._set_lit`; before, a second bolt was ignored, so Repeat could
  not keep a short-burning brazier lit).
- **New pieces:** `WrenMeeting` (`scripts/story/wren_meeting.gd`): Wren, who breathes, blinks, turns to look,
  and the first time Echidna is near talks line by line (her bubble, Echidna's thought); saved by
  `galleries.wren_spoke`. Sprites by `tools/art/generate_gallery_sprites.gd`: `wren` (3 frames), `archivist_plaque`,
  `scroll_rack`, `seal_fire/ice/space/light` (2 frames each, shown by `HallLamp`), `chalk_hands`. Five
  Archivist's ledger pages (`galleries.page.1-5`).
- **Found and fixed on the way:** a sideways portal from a cube on the floor is always refused (its far doorway
  dips 6 px into the floor), so such cubes stand 8 px up; the camera shows only ~190 px above her, so the cubes
  and doorways she aims at hang no higher than that; a mirror's wheel reaches up from its point, so the pocket
  wheel sits on the pocket floor; page i's shelf moved off the far doorway's approach.
- **Tests** (wing suite): `g1` 46 and `g2` 45 (part by part, with the wrong tries: Long straight through finds
  the gate shut; a single bolt stops the lift halfway; one pair of hearths by hand goes out), `g1_full` 38 (61 s
  of game time), `g2_full` 39 (112 s, 30 of them Wren talking), `galleries_full` 77 (both rooms in one go, 188
  s), `g1_pages` 10, `g2_pages` 36, `g1_dark` 7 and `g2_dark` 4 (shelves and walkways out of reach, pockets
  sealed, fire into the hearth only through the doorway, Reset Room to the shrine), `g1_look` and `g2_look`
  (screenshots and probes, not in the default run).
- **Estimate.** About 1.5 to 2 hours for a first-time player (ten new ideas, each about 6 to 15 minutes, and the
  pages). A design estimate only: nobody has played it yet.

## One story, an ending that lands, reels staged like Hollow Knight (2026-10-08)

Asked for: an ending with real emotional weight, a much more coherent story, and cutscenes that look like
Hollow Knight's (a small figure before something vast and glowing, chains, deep dark layers). Chosen: the whole
game's reels, pixel art staged the Hollow Knight way, the held moment shown as a great moth in four chains, and
the two bell aftermaths merged into one.

- **The story bible** is the first section of `docs/STORY_PLAYTHROUGH.md`: love that holds on versus love that
  lets go; Echidna losing Nan mirrors Ilse losing Wren; Ilse's lullaby of four notes is the bell's peal (why the
  bell quiets the Hush) and Nan's hum; Wren's chalk stars mean "look up"; the Stillness is Echidna's own
  temptation; the Rewritten Sky gives two stars, Wren's and Ilse's; the cottage promise ("as many times as it
  takes") closes the game.
- **Staging toolkit** `scripts/story/story_stage.gd` (`StoryStage`): depth layers that drift and scale with the
  camera's push (`Layer`), fog bands (`assets/shaders/story_fog.gdshader`), rising embers, hanging snow, washes,
  silhouette pieces, a rising/falling `Beam`, the `Moth` (frozen → kindling → alight, breathing, or folded) and
  the `Chain` (links, a word plate, `snap()`).
- **Presentation** (`StoryIntro`, so every reel): letterbox bars that close in; the words small in the bottom
  bar and the era in the top bar; lore cards (words centred on black between pixel ornaments); a per-shot
  colour grade and vignette (`assets/shaders/story_grade.gdshader`); silent beats (`""` lines); story music cues
  per shot (`"music"`). `AudioDirector.play_cue()/stop_cue()` play a cue once, duck the loops and open the Music
  bus low-pass. The Hush shader can run backwards (`thaw`).
- **New pixel art** `tools/art/generate_story_hk_sprites.gd`: the moth (3 frames) and folded moth, chain link, four
  word plates, Ilse kneeling (3), the lore-card ornament, and silhouettes (stalactites, rocks, crystals, arch,
  pillar, grass, the mountain with the monastery, Lowbell's roofs, the dome's rim).
- **Music cues** `tools/audio/generate_story_music.gd`: `lullaby.wav` (music box over piano, 19 s), `bell_peal.wav`
  (the four notes as bell strikes, 12 s), `ending_swell.wav` (the motif, a rising pad, turning to A major, 46 s).
- **Every reel rewritten and restaged** (shot lists in `docs/STORY_PLAYTHROUGH.md`): the opening 9 → 8, the
  bell 2 → 4 (with the teammate's beats: half a name, the Bellkeeper's last note), the dome 3, the wings 2 each,
  the Eye opens 3, the Stillness 3, the Rewritten Sky 11.
- **The Eye rebuilt as the finale** (`build_eye()`, `scripts/story/eye_scene.gd`): the moth and chains over the
  great cube, hanging snow, Ilse kneeling at the bed by the candle, a darker room (no window or banners; the
  moth and the candle are the light), the camera drawn back to 1.5. Wren meets Echidna at the door and walks
  with her to the cube; Ilse pleads near the cube (the camera leans to her) and Wren answers. The hint stone
  points at the clues and names the sentences only at its last stage. `EyeAltar.wrong_sentence` lets Wren answer
  a wrong sentence (the old toast stays when nothing listens). After the Stillness, Wren has new lines
  (`eye.stillness_seen`).
- **Coherence fixes:** Nan hums the four notes as Echidna comes in (the lullaby plays quietly) and says the bell
  "rang the tune I'm always humming"; Wren's Landing chalk now says "if you get lost, look up" (the scene's one
  text line changed by hand as well as in the builder, so the Landing is not regenerated).
- **Tests:** wing `eye` (24: the moth and four chains, Wren's lines and walk, Ilse's plea, Wren's answers, both
  endings, THE END), `*_look` scenarios that page every reel and save each shot (`intro_look`, `bell_look`,
  `dome_look`, `kiln_look`, `cistern_look`, `lamps_look`, `galleries_look`, `eye_reel_look`, `stillness_look`,
  `sky_look`; screenshots only, not in the default run); experience counts updated (8 opening pictures, 4 bell).
- **Looked at by eye:** every shot of every reel (contact sheets from the look scenarios) and the Eye room in
  play; several framings fixed after looking (plates hidden by the cube, stars under the bar, empty ground,
  the mountain not reading as a silhouette, Ilse off screen during her plea).
- **Not checked by anyone yet:** whether the ending moves a player, the pacing of the reels, whether anything is
  too dark to read on a real screen, and how the generated music sounds.

## The polish pass: one dungeon look, portraits, levels that feel different, creatures, fair puzzles (2026-10-09)

Asked for: polish every part of the game, with five reference images (pastel per-level palettes, a gold and
crimson 9-slice dungeon frame, UnderMine's carved rune wheel, RefRain's big title art, large dialogue portraits).
Chosen with you: free open-licence fonts, our shadow-faced portrait style, creatures in corridors (puzzle spots
stay calm), and targets that can be found without hints (with the hints slowed down).

- **Fonts** (Google Fonts, SIL OFL, each folder has its `OFL.txt`): Jacquard 12 (titles, YOU DIED), Silkscreen
  (HUD, menus, prompts), Pixelify Sans (dialogue, captions), IM Fell English (lore pages, notes), Patrick Hand
  (Wren's chalk). Roles in `scripts/ui/fonts.gd` (`Fonts`); every Orbitron/SystemFont use moved to a role.
- **The dungeon UI kit:** `tools/art/generate_ui_sprites.gd` draws the 9-slice stone panel with gold filigree and
  crimson gems, lighter panel, parchment, button plates, banner, name plate, dividers, slider, checkbox,
  scrollbar and bar frame (`assets/ui/`), and saves the project theme `assets/ui/dungeon_theme.tres` (set in
  `project.godot`). `scripts/ui/dungeon_ui.gd` (`DungeonUI`): palette, styles, corner crests, dividers. Every
  screen reskinned: HUD, pause menu (stone ring and plates), settings, toasts, prompts, signs, page reader
  (parchment), tours, chapter card, death screen, title cards, rune overview and journal.
- **Portraits and the dialogue box:** `tools/art/generate_portraits.gd` (112×136, shown 3×): Echidna (5 faces), Nan
  (4), Wren (4), Ilse (3). `scripts/ui/dialogue_box.gd` (`DialogueBox`): the speaker's portrait on their side, a
  gold name plate, typewriter text with the forgotten-name gaps. Used in Nan's cottage, Wren's meeting, the Eye
  (door talk and Ilse's plea) and in reels (a line can be `{"who", "face", "text"}`).
- **The story's whys** (shown on screen, written into `docs/STORY_PLAYTHROUGH.md`): the cottage is the Choir's
  old gatehouse and Nan their last novice; the mountain road has been frozen shut for nine winters, so the way
  up is the novices' path inside the mountain, under the gatehouse; the Choir sealed the Eye with four bells; at
  the end the great bell hangs silent ("It would never need to ring again") and Lowbell's chimes move in the
  returning wind (no bell sound). Opening, Lowbell, cottage, bell and dome scenes rewritten around this.
- **Title screen:** a full-screen composition: Echidna's portrait large over a crimson lattice banner, the moth's
  wing behind, "The Sealed Belfry" in Jacquard at 84, a gold rule, an italic tagline, angled stone panels and
  snow; the menu as stone plates on the right.
- **Runes:** the rune screen rebuilt as a carved serpent wheel (`tools/art/generate_rune_ui_sprites.gd`) with four
  sockets, a stone eye that opens when the sentence is whole, fragments as tablets, a "WHERE IT GOES" view of
  the aim path, and a parchment info plate (same API, all rune tests pass). `RuneFragments.combo_glow()` gives
  each combination its colour, pattern, size and pulse (broken runes flicker); cubes are carved stone sprites
  lit in that colour. `AimPreview` draws a dotted path to the first solid while aiming.
- **Each level its own feel:** `scripts/fx/level_theme.gd` (`LevelTheme`, applied from `PostFX`): a tile
  recolour shader (`assets/shaders/tile_recolor.gdshader`) maps the shared tileset to three tones per level,
  plus mist, shadow/highlight tints, saturation, torch and shaft colours, drifting air (fireflies, snow, stars,
  frost, embers, drips, dust, paper) and props (`tools/art/generate_level_props.gd`). Passage mossy teal, Belfry
  cold blue, Observatory indigo, Landing dusk violet, Kilnworks ember, Cistern aqua, Lampworks sepia gold,
  Galleries pastel pink, the Eye blue-black. Rooms keep their own moods, leaning toward the level's.
- **Creatures** (`scripts/creatures/creature.gd`, `creature_spawner.gd`, sprites from
  `tools/art/generate_creature_sprites.gd`, shown 3×): bats and star mites (Belfry, Observatory), cinderlings
  (fire-proof) and clinkers (armour cracks first) in the Kilnworks, frostlings and brine jellies in the Cistern,
  lampmoths (Lampworks, Galleries), foldmites that blink (Galleries), hushlings that drain mana (the Eye). They
  are scattered on open floor in each room, never within 170 px of anything with an Area2D or a rune cube, nor
  300 px of a room's way in; a room's own slimes count toward its share. The Passage (the movement lesson)
  keeps only its taught slimes, and the Landing is the safe hub. Tests run with `GameState.calm_creatures`.
- **Sound** (`tools/audio/generate_sfx.gd`, appended so every earlier sound is byte-identical apart from the menu
  sounds re-voiced in stone): creature alert/hurt/die/hop/crack/drain; a full death (`death_fall`: the blow,
  the fall, a minor chord, a heartbeat that stops), a toll under YOU DIED (`death_sting`) and `respawn`;
  footsteps on ash (Kilnworks), wet stone (Cistern) and paper (Galleries); a page turn; the hint skull's
  whisper; and 8 s ambience beds per level (wind, stars, hush, forge with chains, water, lamp hum, folds, the
  Eye's near-silence) on a new `AudioDirector.set_bed()` channel under the cave ambience.
- **Fair puzzles:** the hint skull listens before it speaks: the first hint after about a minute in its room,
  the second 2.5 minutes after that, the solution 4 minutes after that; a gold ring fills round it, the wait
  survives deaths and reloads, a stuck-player nudge waits for it, and the "Hints without waiting" assist turns
  it off. Every target a rune, beam or bolt must reach that is off the screen in the room she is in gets a gold
  pip at the screen's edge pointing at it (`scripts/ui/target_pips.gd`, added by `ChapterRoot`), until it is lit,
  cleared or broken; with the aim preview, nothing has to be found by guessing.
- **Tests:** wing `creatures` (20), `sounds` (13), `hint_wait` (14), `sightlines` (15), `levels_look` (9);
  updated cottage, Eye and experience checks for the dialogue box and the death sounds. Test runs keep hint
  waits off (`Settings.assist_instant_hints`) and creatures calm. All 8 suites pass (2026-10-09): wing 1007,
  tutorial 173, chapter 341, presentation 111, experience 248, rune 304, prologue 38, adversarial 18 (2,240).
  The brighter palettes made spike tips harder to pick out, so the spike glint went from 1.5 to 1.8 and the
  Passage's lightest tone was softened.
- **Looked at by eye:** the title screen, pause menu, tour card, map, dialogue in the cottage and reels, every
  level's palette, the rune wheel, creatures in each level (sprites redrawn for the bat and moth, drawn larger
  after looking), the hint ring and the target pips.
- **Not checked by anyone yet:** how the fonts and UI feel on a real screen, creature difficulty, whether the
  hint waits feel fair, the sound mix (beds, death, stone menus), and each level's timing with creatures in it.

## A handheld build: the Anbernic RG35XX through PortMaster (2026-10-09)

Asked for: a version for the user's Anbernic RG35XX (an H700 model: Plus / H / SP / 2024, on stock firmware).

- **The route:** PortMaster's stock `godot_4.7.1` runtime (a 4.7.2 pck loads on it: same pack format)
  drawn through `weston_pkg_0.2` with the Compatibility renderer (`opengl3_es`), as the community ports
  of Dome Keeper and Pathogenic do on the RG35XX H. **Anbernic's stock firmware can't run it** (no
  OpenGL display for Weston; the stock-OS mod dropped PortMaster): it needs Knulli or muOS.
- **Package** in `port/` (launcher `Sealed Belfry.sh`, `sealedbelfry.gptk` mapping nothing so the game
  reads the pad itself, `port.json`, `gameinfo.xml`, `README.md` with install steps and controls,
  licences); `tools/release/build_handheld_port.sh` exports the pck with the new "Handheld (Linux arm64)" preset
  (ETC2/ASTC, excludes tests/tools/docs) and assembles `builds/handheld/ports/` and a zip (8.4 MB).
  The launcher's controller renumbering is adapted from those ports (MIT, credited).
- **Handheld mode** (`Settings.handheld`, from `--handheld` after `--`): Low graphics on the first
  start, pad prompts from the start, the mouse hidden, Rune Carry on L2 (most H700 models have no stick
  to click for R3; sprint keeps L1), text under 14 px raised to 16. For every controller: with no right
  stick, the d-pad aims fireballs up, down or diagonally.
- **Checked:** every level, the title, the rune wheel and the pause menu drawn by the Compatibility
  renderer at 640×480 on the PC (no shader errors); the exported pck boots on its own with the
  handheld's flags; wing `handheld` (4 checks + screenshots); the launcher passes `bash -n`.
- **Not checked (needs the device):** that it starts under Knulli/muOS, the frame rate on the Mali-G31
  (the reference ports run about 30 fps), the buttons' layout, sound, and whether the text is readable.

## Prompts follow the device, live (2026-10-09)

Asked for: every on-screen key name switches to the controller's button the moment a controller is used
(for example the fire slot's "LMB"), and back when the keyboard or mouse is used.

- `InputLabels.note_event()` flips on a pad button or a pushed stick/trigger, and back on a key, a click
  or a real mouse move (over 4 px; a twitch doesn't count). `InputLabels.watch(node, refresh)` re-runs
  a prompt's text for as long as the node exists; `refresh_all()` runs them on every switch.
- Watched: tutorial signs (the plate resizes), interact prompts, the kindle prompt, the spell slots'
  keys (from the real bindings now, not the scene's "Q" / "LMB"), the death screen, page footers, reel
  hints, Nan's cottage hints, the rune screen's rules ("B: done" / "Esc: done"), the rune overview,
  the room-broken banner, the pause menu's card and controls list, the UI tours (templates filled in
  as each card shows; "A: next · B: close" on a pad) and the settings key list. Toasts and title cards
  that last a few seconds keep the name they were shown with. The rune HUD and Lowbell already redraw
  every frame.
- Tests: wing `prompts` (12: a real pad press, key press and mouse move through the input system);
  all 8 suites pass (2,256).

## Surface, scale, floating props, a painted title, and the status page (2026-10-09)

Asked for: polish the surface after Nan (temp art, the words), fix floating candles and props in the
dungeons, fix the scale of Nan's house, a title screen like Kena's, and remove the circles round
Echidna on the status page.

- **The pilgrim road** (`witch_prologue.gd`, APPROACH): rebuilt in the surface pack's art like Lowbell:
  parallax sky with the moon, the monastery on its crag, bare woods; graves, a signpost and a road lamp;
  a pixel winch (`tools/art/generate_surface_props.gd`: `bridge_winch`, `rope`, `rope_ladder`) with a rope
  that follows the bridge as it lowers; grassy rock steps instead of dungeon bricks; the Belfry's outer
  gate frozen shut. The code-drawn circle winch, rope line and bar are gone; the camera frames the road
  (floor 72 px above the bottom, as in Lowbell) instead of half a screen of dirt. The objective panel
  and heading use the dungeon UI and fonts. The words follow the story: the Choir's pilgrim road, the
  Hush thicker up the mountain, the gate "sealed by the Choir until the bell is whole", four word-hollows
  in the seal. The well's drawn rope ladder is a sprite and its camera sits higher.
- **Nan's cottage at Echidna's scale:** furniture at 1x (a waist-high table, a shelf half again her
  height), doors 1.8x, the panelling at her waist (`cottage_interior.gd`), a closer camera (2.6), the
  floating herbs removed.
- **Floating candles** had one cause: `scripts/fx/world_layout.gd` measured a region sprite's whole
  texture, lifting every checkpoint candle (and its flame) 18 px. It now measures the drawn region and
  leaves checkpoint candles where their checkpoint stands. Wing `floating` checks every level (10 levels,
  nothing floats); the polish suite's floor audit measures regions too.
- **Title screen** (`title_screen.gd`): a painted night scene (the moon, the monastery, the woods, a ruined
  shrine with the cracked bell, flame bowls, Echidna with her lantern, light through the arch, snow),
  the glass logo top left, the menu as plain words with a gold diamond on the chosen one (`MenuWord`),
  the version bottom right. Same buttons and flow.
- **Status page:** the ring of twelve empty slots (and the red dot) is gone; Echidna stands in her
  lantern's glow.
- **Title cards** sit higher (the top 40% of the screen), clear of the tutorial signs.
- Tests: all suites pass except four polish checks that also fail on Fisch's commit (villagers drawn at
  1x; Lowbell scales them to Echidna on purpose). Wing `surface_look` saves screenshots.

## Daily puzzle and generated levels (2026-10-10)

Built for the Congressional App Challenge problem statement (critical thinking and problem solving). Full
guide: `docs/DAILY_PUZZLE.md`.

- **Generator** (`scripts/daily/`): own RNG and calendar (`DailyRng`), word tiers (`DailyKit`), three puzzle
  modules (Gust Alley, Dead Weight, Updraft), an oracle that needs two or more working sentences
  (`DailyOracle`), seeded composition with salted retries and hand-checked fallbacks (`DailyGenerator`), and a
  runtime port of the builder helpers (`RoomKit`). `DailyRoot extends ChapterRoot`.
- **Daily Puzzle** on the title screen (`DailyMenu`): today's puzzle by local date, difficulty by weekday,
  streak with one free mend a week, a 14-day strip, personal bests, a board of friends (pasted share codes or
  `user://friends.txt` on the handheld), practice days with arrows and an **Endless** row with four starts.
- **End card** (`DailyComplete`): stars, score and what was taken off it, "the ways through" (how many
  sentences could clear each room and which was found), streak and a checksummed share code (`SB1-...`).
- **Isolation:** `DailyRun.apply/restore` snapshot and put back flags, checkpoints, abilities, calm creatures
  and `RuneManager.kit_override`; nothing touches the story save.
- **Tests:** `tests/daily_suite.gd` (rng, calendar, kit, generator 1,600 specs, simulation 140/140 through
  the real rune cubes, score, code, store, persistence, fairness, cards, level, look). Note: `run_tests.gd`
  must load `DailyStore` at run time (it reaches autoloads that are not up while the script compiles).
- **Further ideas:** solution codex, medals, Sunday Grand board, online board. The procedural expansion below
  supersedes the old module and Random trial notes.

## Known limitations and decisions

- The title screen is the main scene. Continue goes to the latest shrine or lesson;
  New Game (press twice if there is progress) starts over but keeps a finished tutorial.
- `chapter_1.tscn` is generated. Tune rooms in `tools/levels/build_chapter.gd`, or stop using the
  builder before editing the scene by hand.
- `tutorial_level.tscn` is hand-edited; its original builder is not in the repository.
  Structural edits go through `tools/levels/patch_tutorial.gd` (idempotent patches that change
  only the affected tile-data lines and append nodes).
- Piston heads are solid but fireballs pass through them (so the tutorial's "shoot the
  switch through the running pistons" still works); beams and bolts are stopped.
- The main scene is now the title screen (`scenes/ui/title_screen.tscn`).

## Handoff notes

- If a usage limit interrupts work, resume from this file. Model selection cannot be
  changed from inside the session; use `/model` in the Claude Code UI if needed.
- To add a room: add a `room_N_*()` function to `tools/levels/build_chapter.gd` (shell →
  features → `make_room` → pieces → circuits → hint/page/signs/decor), a `solve_rN()` and
  `scenario_roomN()` to `tests/chapter_suite.gd`, and chain it into `scenario_full_run`.

## Procedural generation expansion — 2026-10-10

Implemented the runtime and developer tooling in `PROCGEN_DESIGN.md`: Endless lives, stair doors, rest/game-over cards, persistent records and share codes; two-beat rooms with Master cube reuse and a different second inscription; eight new module families; GEN_VERSION 3 and a fresh 76-layout solution table; bounded local calibration, fitting and chart tools. Runtime selection requires at least two minimal solutions proven three times in real physics. Single-solution layouts stay excluded. Story scenes, builders and scripts were not edited.

Native QA on isolated Windows desktops (no desktop input takeover; isolated APPDATA):

- Daily: **404 passed, 0 failed**; Endless lifecycle: **20/0** at both 1152×648 and native 640×480; table freshness: **12/0**.
- Endurance repeated: **120 rooms, 720/0** each run; old room roots were freed, scene counts stayed bounded, and all rooms cleared. Slowest generation was 11.8 ms on this Windows PC (11.4 ms in the repeated run), below 50 ms.
- Keyboard and injected-pad menu focus: **12/0** per resolution, including Endless → Back → practice and canvas-size restoration. Inspected idle and active-rune HUDs, both Endless cards, Daily cards, all eight module families and the cracked-wall variant. Corrected native-size rendering, active-rune/Endless HUD overlap and Folded Wall's foreground contrast. Used existing art and fonts.
- Sequential story regressions: prologue **38/0**, tutorial **195/0**, experience **231/0**, rune **304/0**, chapter **341/0**, adversarial **18/0**, wing **1025/0**. Polish **89 passed, 4 failed**: exactly the four NPC 1× checks explicitly allowed by the design.
- Presentation: Windows Forward Plus/D3D12 full suite **111/0**; original-runner full baseline **111/0**. Additional OpenGL full runs intermittently failed the existing spike-tip contrast assertion (110/1), while three isolated original-runner spike repeats passed **6/0** each. Retained the assertion and story hazard code; do not describe this as a clean OpenGL presentation run.
- All **306** scripts/scenes load without parse failures. The load-all validator reports 8 ObjectDB instances and 4 resources at process shutdown; generated-room freeing is checked independently by endurance. The shared rune-assembly preview also emits a Camera2D interpolation warning.
- Handheld PCK exported successfully to ignored QA output and independently loaded to confirm the complete version-3 JSON table is packaged. Fitter/CSV/chart tooling tested with automated QA observations only.

Remaining external acceptance: actual keyboard/pad play to a rest and game over, ARM handheld hardware performance, and a participant solve-time study/chart. Automated movement, injected input and render inspection are not manual hardware playtesting or a guarantee of zero bugs. Master intentionally uses vocabulary tier 4 as documented; Folded Wall is registered and verified at tier 5 for supplied advanced specs.
# Challenge balance revision (generator version 4)

Personal Fire and Echo no longer bypass every generated rune mechanism. Heal remains available, and single flame rooms below Grand explicitly lend personal Fire as an alternative. Room objectives state the spell rule; leaving restores the original story abilities and flags. Physical crate solutions remain legitimate where the room permits them.

Grand and Master now require carrying and reinscribing a shared cube for two incompatible mechanisms. Grand uses tier 4 and R 8–12; Master uses tier 5 and R 10–15. Second beats require vertical wind, hidden-stone light or reflected light. The generator excludes trivial modifier-only beats and bumps seed/share-code revision to 4. Verification metadata was refreshed using unchanged modules' existing three-run proofs.

Validation: full Daily suite 449 passed / 0 failed; final 640×480 spell/balance scenario 29 / 0, including two real-physics solutions for each room of 2026-10-11's Grand; 120-room Endless progression 720 / 0. No GDScript errors in these logs. Inspected the final compact Grand screenshot: room rules, title and health/mana are separated. These are automated engine/physics and render checks, not manual playtesting or measured human difficulty.

## Grand adversarial playtesting (generator version 5)

Reproduced three shortcut defects with native Godot physics: a legally carried cube plus a charged jump bypassed an unsolved internal gate; normal/charged jumps onto an unlit crossing's far bank opened its exit without revealing the stones; a sustained first-beat Fire rune prematurely completed the reused cube's later wind milestone. Fixed these in the generated chain: masonry closes the space above internal gates, crossing exits wait for their other objective steps, and the wind milestone requires actual upward Lift in the second passage. Standalone story modules are unchanged.

Acceptance: full Daily suite 485 passed / 0 failed; final compact 640×480 adversarial scenario 36 / 0; Grand corpus 59 / 0 (all 14 mechanism pairings found across 1,000 seeds, 19 geometry variants, two end-to-end solutions each); 120-room Endless progression 720 / 0. Tests also reject walking/sprinting heavy stones and placing carried cubes through a closed gate. A valid carried-cube wind route passes using actual pickup, continuous walking, placement and reinscription, without driver teleports. The five rooms generated for 2026-10-11 resist entrance jump/sprint spam without inscriptions. Inspected the compact fixed-doorway screenshot. All runs used an isolated hidden desktop, with no desktop input; these are automated playtesting/render checks, not manual human playtesting or proof of every possible route.

## Full difficulty-scale audit (generator version 6)

The audit found and repaired three intermediate Endless problems: Steady +1 reused the same overlapping distribution as Steady; Hard +2/+3 admitted simple rooms below their bands; Gentle +1 could become easier when the previous-room exclusion removed its only suitable mechanism. Fractional draws now fit the band centre, upper Hard steps require two increasingly complex beats, and suitable mechanisms are filtered before the no-repeat preference. A narrow band may repeat its sole suitable mechanism with fresh sampled geometry instead of substituting a below-band room. Named difficulty bands and vocabulary tiers are unchanged.

Sampled 8,500 rooms across 500 seeds per named level, 4,250 independent quarter-step rooms, and 15,000 rooms in 600 complete 25-room Endless sequences: 27,750 total. Named mean structural R scores: Gentle 2.177, Steady 3.529, Hard 5.694, Grand 10.339, Master 12.018. Named in-band coverage is 97.2%, 99.75%, 99.85%, 100%, 100%; every named level has higher mean and median than its predecessor. All 17 quarter levels rise on average, and every actual sequence window rises for each starting choice. Checked solution counts, guidance, spell rules, chain/reuse rates, source verification freshness and actual menu dispatch.

Acceptance: final scale audit 186 passed / 0 failed, including 68 actual-physics solution checks across the sampled low/high extremes of all named and fractional levels; full Daily suite 486 / 0; 120-room Endless progression 720 / 0. No GDScript errors in those logs. Runs stayed on an isolated hidden desktop; the final regressions used separate QA save data. `docs/DIFFICULTY_SCALE_AUDIT.json` preserves the measurements. These are structural estimates and automated engine tests, not participant solve-time measurements or a guarantee that every individual harder-tier room feels harder to every player.

## All-difficulty adversarial playtesting (generator version 7)

Reproduced and fixed seven defects: far-side touches opened standalone Dark Hall, Frozen Crossing and Still Piston exits without their prerequisites; standalone Updraft had an open back gate; a legally floor-placed Master portal cube refused activation because its doorway intersected the floor; falling into an Endless pit never ended the fall or consumed a life; fractional Hard generation repeatedly exceeded its 50 ms budget. Generated exits now respect complete objectives, Updraft owns a goal-controlled gate, generated horizontal portal doorways clear the floor, and falls below bedrock use the normal death/life flow. Authored story portal positions are unchanged.

Hard's nested salt search now caches pure scores with a 4,096-entry limit, preserving every random draw. A before/after comparison of 460 generated outputs was byte-identical. Initial endurance runs had one timing failure at 51.832 ms, then four at 50.893–57.597 ms; after the optimization all 120 generation checks passed (mean 3.993 ms, maximum 34.993 ms). These are observations on the QA machine under background load, not a hardware-wide timing guarantee.

Acceptance: full Daily 673 / 0; expanded all-level corpus 817 / 0, covering 204 observed mechanism/geometry variants from 1,000 seeds at each named difficulty with movement-only attacks and 408 valid-solution checks; final native 640×480 attack sweep 162 / 0 across all 17 quarter levels; solve/reset/re-solve checks 25 / 0 (included in Daily); updated scale audit 186 / 0; optimized 120-room Endless progression 720 / 0; full authored Folded Galleries route 77 / 0. Reverified retained Folded Wall inscriptions three times each and refreshed version-7 proof metadata and `docs/DIFFICULTY_SCALE_AUDIT.json`. All 306 project scenes/scripts load; the load-only helper retains its previously documented eight ObjectDB/four-resource shutdown warnings. No GDScript errors in the final game test logs.

Inspected full-size and compact native captures after physically entering a carried cube's portal. Tests ran on an isolated hidden desktop with separate QA saves and no OS keyboard/mouse input. The last scale/endurance passes disabled rendering to reduce GPU load; compact attack and story regression passes used actual rendering. Movement attacks use actual input actions; fixture setup and separate canonical solution drivers use explicit positioning. This is automated engine playtesting and render inspection, not manual controller acceptance or exhaustive coverage of all possible routes. Existing uncommitted work was preserved; no files were deleted, and nothing was committed or pushed.

## Rune combinations, placements and mid-puzzle resets (2026-10-12, version 8)

Reproduced a reset scoring race with a legal Wind/Burst/Right/Strong cast against a cracked wall. Reset was requested before impact; the moving stone broke the wall during the fade, and the run incorrectly banked one clear even though reset restored the wall. Generated roots now suspend objective/progress processing during resets while keeping challenge time running. They also reject exit transitions during reset. Regression checks confirm neither progress ledger credits the abandoned attempt, the timer advances, the wall/stone state returns, and a later legitimate solution earns exactly one clear.

A continuous Master test exposed an advertised-route problem hidden by the canonical driver's stage relocations: a single Folded Wall cube could not accompany Echidna through its own doorway because pickup required turning the portal off. Generated reused Folded Wall cubes now have a scoped active-portal pickup exception; the doorway stays anchored, then the cube is placed, switched off and reinscribed. Normal active portal cubes and other active runes retain their movement restrictions. Portal transfer checks the held cube's full destination shape too. Both two- and three-column walls now have a complete continuous carried-cube route without stage teleports. Reset while holding closes the anchored portal, clears the hands, returns the original cube/recipe/locks and leaves no credited clear. Story behavior is unchanged.

Final native Daily suite: 1,126 passed / 0 failed. The new scenarios include 272 live-effect/reset checks across 68 samples at all 17 quarter levels; 150 placement/carry/reset checks across 51 generated samples; 8 impact/reset checks; 18 continuous Master handoff/restriction checks; 5 late-obstruction/held-portal reset checks. The optional unlocked-combination sweep passed 1,684 checks over 334 valid learned non-Lift sentences across Grand and Master, with a real first-stage unlock and actual carrying/placement before each attempt. No unrelated sentence counterfeited the second wind milestone or bypassed its final gate. Boundary placements use explicit attack-fixture positions; this is not a claim that the test driver traversed unsolved geometry to reach every fixture.

Reverified retained Folded Wall inscriptions three times each, refreshed complete version-8 proof metadata, and expanded the global source fingerprint to include root/chain/carrier code. Final 120-room Endless progression: 720/0; refreshed difficulty audit: 186/0; authored Folded Galleries route: 77/0. Inspected `res://.godot/master-shared-portal.png` at native 640×480: carried cube clears the hat, the placement preview sits at floor level, and the contextual instructions fit below the health/mana display. All tests used isolated hidden desktops and QA save data. Scale/endurance and combo sweeps disabled rendering; the full Daily suite, story regression and compact capture rendered normally. These are automated engine playtests and rendered inspection, not exhaustive manual playtesting. No commits, pushes or file deletions.

## Portal cargo and stage-boundary reset stress (2026-10-12, version 8)

Reproduced another portal overlap: a player carrying a different stage's inactive cube backward through a stationary portal could put that cargo inside the mounted portal owner. The old clearance rule checked only a carried portal owner. Transfers now validate whichever cube is actually in the carrier's hands, including its room bounds and full solid-geometry clearance. A regression using actual mounted-cube geometry fails twice with the old owner-only condition and passes with the generalized check. Shared portal pickup restrictions remain unchanged; generated layouts and share-code version remain unchanged.

Added default native-engine scenarios: portal cargo 8/0; normal/long shared portal reset spam 80/0 across 16 width/modifier/timing cases (before warp and 0/1/18 physics frames after warp); stage-boundary reset spam 68/0 across all 17 quarter settings. The continuous Master handoff now includes reverse travel and another forward trip with the same active cube, 22/0. Reset requests during the fade count once, restore hands, original cube positions/recipes/locks and controls, close abandoned effects, and retain no stage unlock or unintended completion credit. Tests distinguish initial/boundary fixture positioning from real pickup and portal movement; first-stage solution drivers also use explicit setup positioning.

The rendered full Daily suite passed 1,286 assertions with zero failures. Its initial Endless transitions also exposed four camera errors: restoring the story canvas during a root replacement notified a camera already detached from the tree. Added a guard to the resize callback, then re-ran Endless lifecycle 20/0 and ordinary camera tracking 7/0 with no engine errors in those logs. The authored Folded Galleries second-level route passed 39/0 with the portal fix. Retained Folded Wall inscriptions were reverified three times each and complete version-8 proof metadata refreshed. All 306 scene/script resources load; the load-only helper retains the previously recorded eight ObjectDB/four-resource shutdown warnings.

Inspected a fresh native 640×480 shared-portal handoff capture. The held cube clears the hat, placement preview reaches the floor, and instructions stay below the HUD. Runs used isolated hidden desktops, separate QA save data and no OS input; the full regression, targeted lifecycle/story tests and capture rendered normally. These are automated playtests and rendered inspection, not manual controller acceptance or proof that every conceivable route is bug-free. Existing uncommitted work was preserved. No deletion, branch change, commit or push.

## Difficulty floors and repetitive configurations (2026-10-12, version 9)

Audited the same 2,100 generated Daily configurations and 8,000 Endless configurations before and after the changes. Version 8 had 2 Daily and 8 Endless rooms below their difficulty floor, 96 duplicate configurations inside Daily runs, 161 immediate Endless repeats and 1,004 repeats from the previous four Endless rooms. Version 9 had zero below-floor rooms, zero same-run Daily duplicates, zero immediate Endless repeats and 85 recent repeats. Of those 85, 84 are in Gentle starts with narrow fractional bands and few verified alternatives; 1 is in a Hard start. Mechanic types still recur. `docs/PUZZLE_VARIETY_AUDIT.json` records the scope and comparison; signatures ignore decorative randomness and guidance, and include actual mechanics, geometry and rune locks.

Single-room generation now searches verified in-band alternatives when random salts miss them. Hard requires a meaningful form/direction choice; Grand/Master require one in the first beat, rather than an already-carved answer with only a modifier to choose. Folded Wall adds form-open variants, retaining legacy recipes. Lower Hard stays single-stage; upper Hard quarters use chains. Grand/Master keep broad named-level selection and interpolate their fractional targets between measured attainable named means. An initial revision made lower Hard too hard and Grand +1 easier than Grand; the scale audit caught both, and the final selection rules correct them. A separate midpoint-only revision reduced configuration diversity, so it was replaced before acceptance.

Daily generation consults the current run's signatures. Endless consults four banked signatures, prefers unused variants and rotates oldest-first when the suitable library is exhausted. History clears on starting a run and changes only when banking a completed room; resets/deaths do not reroll it. Version-9 seeds/share codes distinguish the revised generation without deleting old records or changing authored story scenes.

Final scale audit: 186/0 across all named/quarter settings, real sequential history and sampled physical solutions. Named structural means are approximately 2.13, 3.53, 5.51, 11.10 and 12.91; Grand quarters increase from 11.00 to 11.41, 11.81 and 12.63. Sampled Grand band coverage is 97.4%, with rare overshoots; no sampled room is below its floor. R is structural reasoning complexity, not measured human solve difficulty.

Final rendered native Daily suite: 1,633/0, including meaningful choices, configuration repetition, deterministic re-generation and the new form-open portal handoff. The harder pairing corpus scans 1,000 Grand seeds, covers 10 meaningful-first-stage pairings and 14 geometry/barrier variants, and passes 44 checks including two physical solutions per variant. Final 120-room native Endless lifecycle: 720/0; generation mean 4.489 ms, maximum 28.893 ms on the QA machine under concurrent background load. Reverified the expanded Folded Wall table with three physics repetitions and refreshed complete version-9 metadata. All 306 resources load; previously documented load-helper shutdown warnings remain.

All runs used hidden isolated desktops and QA save data, with no OS mouse/keyboard input. The full Daily suite rendered at 640×480; scale/corpus/endurance runs disabled rendering to reduce load. These are automated native-engine playtests and structural audits, not human difficulty calibration or exhaustive player-route/visual acceptance. No deletion, branch switch, commit or push; existing uncommitted work remains.

## Gentle terrain variety without extra difficulty (2026-10-12, version 10)

The remaining Gentle repeats came from fractional bands that had only four qualifying Updraft configurations. Added two actual ground shapes: descending terraces and a lower landing after the first rise. With the original ridge, two existing heights and two existing widths, Gentle now has twelve qualifying configurations. The first barrier height, cube position, rune vocabulary, locked words, allowed modifiers, goal and structural difficulty remain equivalent. The new descents need no extra jumps, hazards, timings or spells. Legacy parameters retain the ridge. Authored story scenes are unchanged.

Expanded the Updraft verification grid and normalized legacy lookups to profile 0. Each admitted inscription was measured in three independent native physics runs, and complete version-10 proof metadata was saved. The new default `gentle_profiles` scenario passed 160/0: all twelve configurations retain their original score and choices, reject charged-jump-only completion, clear through continuous walking and actual normal wind, and reset their cube/gate/controls. Fifty twenty-room Gentle sequences exercise different ground shapes and have no recent repeats. Attack positioning and traversal use actual movement; inscription uses the game's cube methods.

The same 2,100 Daily / 8,000 Endless configuration corpus now has zero below-floor rooms, zero same-run Daily duplicates, zero immediate Endless repeats and zero repeats from the previous four Endless rooms. Version 9 had 85 recent repeats, of which 84 were in Gentle starts. Mechanic types and configurations can still recur outside that bounded history window. The machine-readable report preserves the prior revision comparison.

Final rendered native Daily suite: 1,790/0 at 640×480. Full named/quarter/sequential difficulty audit with physical solutions: 186/0. Final 120-room Endless lifecycle: 720/0, generation mean 3.733 ms and maximum 27.550 ms on the QA machine under background load. All 306 resources load; the previously documented load-helper shutdown warnings remain. Inspected fresh 1152×648 native captures of ridge/terrace/landing after entry fade, using a fixed QA camera to expose the complete masonry; these geometry inspection captures are separate from the ordinary gameplay-camera rendered tests.

Runs stayed on hidden isolated desktops with separate QA save data and no OS input. These are automated engine playtests, structural checks and rendered geometry inspection, not human difficulty ratings or exhaustive manual playtesting. Existing gameplay and uncommitted work were preserved; no files deleted, branch switched, commit or push.
