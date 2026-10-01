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

Last full run (2026-09-29, after the enjoyment pass): `tutorial suite: passed=140 failed=0`,
`chapter suite: passed=274 failed=0`, `presentation suite: passed=88 failed=0`,
`experience suite: passed=59 failed=0` (`RESULT passed=561 failed=0`).

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
- Rebuild the chapter after changing the builder:
  `godot --headless --path . --script res://tools/build_chapter.gd`
  (this **overwrites** `scenes/chapter/chapter_1.tscn` and the component scenes in
  `scenes/puzzle`, `scenes/creatures`, `scenes/traps`).
- Tests (need a window, not `--headless`, because they take screenshots and aim the mouse):
  `godot --path . --fixed-fps 60 --script res://tests/run_tests.gd -- [tutorial|chapter|presentation|experience|all] [scenario]`
  Chapter scenarios: `r1`…`r9`, `save`, `reset`, `hazards`, `guide`, `full`, and `look`
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
- Floating wall tiles: `tools/wall_tile_audit.gd` + `tools/audit_wall_tiles.gd` found 7
  (3 chapter, 4 tutorial) and fixed them; the audit is now a test.
- Tutorial sprint gap: 128 px over a shallow pit (`FallCatcher`) that fades you back
  without damage (`tools/patch_tutorial.gd`).
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
(design decisions, tuning, files, test record, gaps) is in `docs/RUNE_SYSTEM_PROGRESS.md`;
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
`knock` (appended to `tools/generate_sfx.gd`; the other 95 sounds are byte-identical).
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
- The new sound was appended to `tools/generate_sfx.gd`; the other sounds are byte-identical.
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

**Hand-made pixel sprites for what the packs lack.** `tools/generate_story_sprites.gd` draws
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

## Known limitations and decisions

- The title screen is the main scene. Continue goes to the latest shrine or lesson;
  New Game (press twice if there is progress) starts over but keeps a finished tutorial.
- `chapter_1.tscn` is generated. Tune rooms in `tools/build_chapter.gd`, or stop using the
  builder before editing the scene by hand.
- `tutorial_level.tscn` is hand-edited; its original builder is not in the repository.
  Structural edits go through `tools/patch_tutorial.gd` (idempotent patches that change
  only the affected tile-data lines and append nodes).
- Piston heads are solid but fireballs pass through them (so the tutorial's "shoot the
  switch through the running pistons" still works); beams and bolts are stopped.
- The main scene is now the title screen (`scenes/ui/title_screen.tscn`).

## Handoff notes

- If a usage limit interrupts work, resume from this file. Model selection cannot be
  changed from inside the session; use `/model` in the Claude Code UI if needed.
- To add a room: add a `room_N_*()` function to `tools/build_chapter.gd` (shell →
  features → `make_room` → pieces → circuits → hint/page/signs/decor), a `solve_rN()` and
  `scenario_roomN()` to `tests/chapter_suite.gd`, and chain it into `scenario_full_run`.
