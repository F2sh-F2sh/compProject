# Presentation: rendering, light, audio and Echidna's animation

The dungeon's look and sound, aiming for the layered, moody feel of hand-drawn
games like Hollow Knight while keeping this project's own pixel art. Nothing
here copies another game's assets: every texture, sound and loop is generated
by the tools listed below.

Engine setup is unchanged: Godot 4.7.2, Forward+. No renderer or rendering
project settings were touched. `project.godot` gained one autoload
(`AudioDirector`) and two physics layer names.

## 1. Rendering pipeline

Back to front (z index in brackets):

| Layer | Node | Scroll | What it shows |
|---|---|---|---|
| Distant fog [-40] | `Atmosphere/FarFog` (Parallax2D) | 0.18 x, 0.85 y | A far hall: towers lost in mist, faint lights, soft rays |
| Midground ruins [-30] | `Atmosphere/MidRuins` (Parallax2D) | 0.45 x, 0.92 y | Crumbling arcades, broken columns, hanging chains |
| Back wall [-10] | `Background` tiles | 1 | The brick wall, broken open at the breaches |
| Breach edges [-8] | `Atmosphere/BreachEdges` | 1 | Chipped stone and a shadowed thickness around each hole |
| Playfield [0..1] | tiles, puzzles, Echidna | 1 | Gameplay |
| Light shafts [25] | `Atmosphere/Shaft*` | 1 | Additive beams with dust, plus a real Light2D each |
| Foreground [40] | `Atmosphere/FrontVines` (Parallax2D) | 1.3 x, pinned to the screen vertically | Roots and vines along the top, rocks and curved thorns along the bottom |
| Post pass | `PostFX` (CanvasLayer) | screen | Lantern falloff, bloom, mist, grade, vignette, grain |

- **`scripts/fx/dungeon_atmosphere.gd` (`DungeonAtmosphere`)** builds all of
  this at runtime from a few exports: the back-wall layer to break (`wall_path`),
  the decoration layer it must never break (`decor_path`), the `breaches` (tile
  rectangles), the floor height and a `reference_center`. Add one node to a
  level. Both the tutorial and the chapter have one.
- **Parallax2D quirk (measured in 4.7.2):** a plane's position is
  `(camera centre − viewport size / 2) × (1 − scroll) + scroll_offset`, with the
  viewport size in screen pixels regardless of zoom. The atmosphere sets
  `scroll_offset` every frame so planes line up with the world at
  `reference_center`, and so the foreground stays pinned to the top and bottom
  of the view at any zoom. `tests/presentation_suite.gd` checks both.
- **Art:** `tools/art/generate_atmosphere_art.gd` paints `assets/fx/*.png` (fog, ruins,
  vines, thorns, the shaft light texture, glow and mote sprites) from noise and
  hand-placed shapes with a fixed seed. All layers tile horizontally.

### Camera
`scripts/world/camera_bounds.gd` now trails the player with exponential damping:
7 per second horizontally and 4.5 vertically, so jumps feel weighty. It leans
ahead by 0.24 s of her horizontal speed, up to 56 px, and snaps on teleports,
respawns and room resets. Room limits still clamp it, and shake and camera
looks are clamped too, so the view never shows outside the room. The chapter
tests watch for that on every frame of a full playthrough.

### Post pass (`assets/shaders/dungeon_post.gdshader`)
1. **Lantern falloff:** beyond about 150 px from Echidna the gloom deepens,
   reaching 42% darker by 440 px. Anything already bright keeps its light:
   torches, beams, runes and glows are scaled by their luminance. So only her
   lantern and lit things pierce the dark. `PostFX` feeds her screen position
   every frame.
2. **Soft bloom** from two blurred mip levels of the screen.
3. **World-anchored ground mist** (as before).
4. **Grade:** cold shadows, pale highlights, slight contrast and desaturation.
5. **Cinematic vignette** (wider than tall) and fine grain.

All values are shader uniforms, grouped in the Inspector.

### Light shafts (`scripts/fx/light_shaft.gd`, `assets/shaders/light_shaft.gdshader`)
Each breach pours a leaning beam down to the floor, and neighbouring beams
alternate their lean. A beam is made of:
- a strip of quads drawn with an additive, self-lit shader: soft edges,
  slowly drifting streaks and a faint breathing;
- dust motes drifting inside it;
- a **PointLight2D** of the same shape, set at a height of 80 so the
  normal-mapped bricks are lit face-on. It casts shadows, and it lights Echidna
  when she walks through: a test measured her about 40% brighter in the beam.

### Glow and embers (`scripts/fx/glow_fx.gd`, `assets/shaders/glow_pulse.gdshader`)
- `GlowFX.halo()` gives a soft radial glow that breathes and flickers. Each
  instance's world position offsets its phase, so neighbouring torches never
  pulse in step.
- `GlowFX.embers()` gives additive sparks drifting upward, each born at a
  slightly different brightness.
- Used on: wall torches (`tools/levels/setup_torch_scene.gd` bakes them into
  `scenes/world/torch_light.tscn`), lit braziers, fireballs (halo plus an ember
  trail), lore pages and lit shrines.

## 2. Echidna's sprite pipeline

`tools/art/build_echidna_frames.gd` generates `assets/sprites/echidna/echidna_frames.tres`.
`tools/levels/setup_echidna_player.gd` wires it into `scenes/player/player.tscn`.

- **Sheets used, all unchanged:** `EchidnaIdle.png`, `EchidnaWalk.png`,
  `EchidnaHoldJump.png`, and the jump sheet. There is no `Echidna.png` in the
  project. The base sheet is `test-Sheet.png`, and `EchidnaAir.png` (its
  colour-matched copy from the earlier colour-shift fix) supplies the jump
  poses.
- **Slicing:** each sheet is a 64 px grid. Duplicate frames are detected and
  folded into longer holds (idle's 18 frames hold 11 unique poses). Each frame
  is trimmed to its pixels and placed on one uniform 80×80 canvas through
  AtlasTexture margins, so no pixel is resampled or redrawn.
- **Pivots:** every clip's contact point sits at the bottom centre of the canvas
  (x 40, bottom edge of row 71). The sprite node is at her feet with offset
  (0, −32), so squash and stretch scale around the feet and she never hovers.
  - Idle, walk and charge align on the centre of the feet and hem.
  - The jump sheet aligns so her head matches idle, because its crouch flares
    the cape sideways. Without this her head would jump 5 px on take-off.
  - Tests confirm her head moves by no more than 3 px between idle, walk,
    charge and crouch.
- **Charge glow (no lines):** the charge shows as her crouch pose, a soft blue
  glow that builds with the charge, and a few sparks once it is full. The
  electric wisp lines and the circling wind streaks were removed from the
  player at the team's request (the `ChargeWisps`, `ChargeWindBack` and
  `ChargeWindFront` nodes). The art is untouched: `EchidnaChargeWisps.png`, its
  `JumpChargeWisps` clip and `scripts/charge_wind.gd` are still on disk, unused.

### Timing (60 Hz ticks per frame)

| Clip | Frames (source frame: ticks) | Total |
|---|---|---|
| idle | 0:10 1:7 2:9 1:6 4:8, blink 5:3 6:2 7:4 8:3, 2:8 10:12 4:8 13:16 16:12 | 1.95 s |
| run (walk) | stride 0:7, pass 2:5, stride 4:7, pass 2:5 | 0.40 s |
| sprint | 0:5 2:3 4:5 2:3 | 0.27 s |
| run_stop (recovery) | 2:4 0:1 | 0.08 s |
| crouch (charge anticipation) | 0:5 | 0.08 s |
| land (recovery) | 0:4 | 0.07 s |
| jump / apex / fall | 2:8 / 4:5 6:6 / 6:8 4:7 10:9 (loop) | |
| JumpCharge / JumpChargeWisps | 10 frames × 5 | 0.83 s |

The feel comes from short holds on key poses, a quick blink, a stride cadence
twice as fast as before, and fast recoveries. A landing or stop is cut short
the moment she moves again, so control never lags. Walk and sprint still scale
their speed to her velocity, so her feet don't slide.

Movement physics was not changed. Acceleration was already instant, and the
chapter's puzzles are tuned to her exact jump heights and distances.

### Echidna's lighting (`assets/shaders/character_lit.gdshader`)
Her pixels are left alone. The shader derives a surface normal from her
silhouette, so the rims of the hat and cape face outward. A torch, a light
shaft or her own lantern catches the edge that faces it and leaves the far
edge dark, which keeps her outline defined against dark stone. A soft contact
shadow under her feet fades as she leaves the ground.

### Contextual particles
- **Footfalls:** on the clip frames where a foot plants (stored in the frames
  resource), a dust puff and a footstep sound play, and a `footstep` signal
  fires. That is about 5 per second walking and 7 sprinting.
- **Sprint dust and landing dust** as before.

## 3. Adaptive audio

### Channels (`scripts/autoload/settings.gd` builds the bus layout)
```
Master
├─ Music    three adaptive layers; its low-pass opens as combat rises
├─ Ambient  cave ambience bed (drips, wind)
└─ SFX      every sound effect
    ├─ ReverbCorridor  (room 0.5, wet 0.26, 28 ms predelay)
    ├─ ReverbHall      (room 0.78, wet 0.34, 55 ms predelay)
    └─ ReverbCavern    (room 0.94, wet 0.42, 85 ms predelay + echo taps at 260 and 494 ms)
```
The pause menu has Master, Music, Ambience and Effects sliders, saved to
`user://settings.cfg`.

### Music (`scripts/autoload/audio_director.gd`, autoload `AudioDirector`)
| Layer | Loop | Exploring | Combat |
|---|---|---|---|
| drone: low echoing cave drone in A | 32 s | −9 dB | −3.5 dB (swells) |
| piano: melancholic lament, A minor, 60 bpm | 32 s | −7 dB | −12 dB (steps back) |
| pulse: heartbeat at 75 bpm, tremolo strings, dissonant shimmer | 16 s | silent | −8 dB |
| Music low-pass | | 2.4 kHz | 9 kHz |

All layers start on the same sample and stay in step. Intensity eases between
0 and 1 over 2.5 s with a smoothstep curve, so combat "intensifies slightly"
instead of switching.

**Triggers.** Anything can call `AudioDirector.set_combat(source, active)`:
- a chapter `Room` with `combat = true` (Rooms 4 and 7, which have gargoyles);
- a `CombatZone` area (the tutorial's slime arena).

**The loops** come from `tools/audio/generate_music.gd`: additive synthesis, a
piano-like voice with inharmonic partials and a hammer knock, and a circular
reverb. Loops are seamless by construction, and a test checks each join
against the local waveform slope. No external music tool was called, since
none is available here. The tool's header holds a ready-to-paste prompt for a
music generation tool; replacements only need the same file names and loop
lengths.

### Reverb zones (`scripts/audio/reverb_zone.gd`)
A `ReverbZone` uses Godot's Area2D audio bus override. Every positional sound
starting inside it goes through that zone's reverb bus: footfalls, spell casts,
jumps and landings, gates, pistons, creatures. The zones sit on their own
physics layer (6, "AudioZones"), and `Sfx` players listen only to that layer,
so the zones never touch gameplay.
- Chapter: every Room gets one. Tall chambers (Rooms 3, 5, 7) use Cavern, the
  chasm (Room 6) uses Hall, and the rest use Corridor.
- Tutorial: one Corridor zone over the whole level.
- A test samples the floor every 64 px across the chapter and finds no gap, and
  it measures a real sound reaching the cavern bus.
- There is no sword in this game. Her spell casts, jumps, landings and
  footsteps are what echo.

## 4. How to rebuild

```
godot --headless --path . --script res://tools/art/generate_atmosphere_art.gd
godot --headless --path . --script res://tools/audio/generate_music.gd
godot --headless --path . --script res://tools/audio/generate_sfx.gd
godot --headless --path . --import
godot --headless --path . --script res://tools/art/build_echidna_frames.gd
godot --headless --path . --script res://tools/levels/setup_echidna_player.gd
godot --headless --path . --script res://tools/levels/setup_torch_scene.gd
godot --headless --path . --script res://tools/levels/build_chapter.gd
```
Tests (need a window): `godot --path . --fixed-fps 60 --script res://tests/run_tests.gd -- presentation [scenario]`

## 5. Verification record

**Automated** (`tests/presentation_suite.gd`, 82 checks):
- Sprite pipeline: every clip present, one canvas, ground poses on the pivot
  row, per-frame timing, fast recoveries, shared duplicate textures, art
  unchanged (the wisp layer rebuilds the hold-jump sheet pixel for pixel),
  head stays put across clips.
- Motion: footfall rate for walk and sprint, stop and landing recoveries,
  taps show a stride, contact shadow.
- Charge: no wisp or wind nodes on the player; the glow builds with the
  charge, sparks at full charge, gone on release.
- Camera: snaps on teleport, lags a sudden move and settles within a second,
  leans ahead, follows softer vertically, trails into a jump.
- Parallax: three planes in the right order, each drifting at its scroll ratio
  (within 1.5 px), placed from the reference camera, vines pinned to the top
  edge; breaches never break torches or windows.
- Light: one shaft per breach, reaching the floor, with a real light and dust;
  Echidna measurably brighter in the beam.
- Post: lantern centred on her, gloom deepening away from her, a distant torch
  keeping its brightness, vignette darkening the edges.
- Glow: torches, braziers (only when lit), fireballs.
- Audio: channels, reverb buses and echo, layers loaded, looping and in step,
  seamless loops, combat room swell and settle, tutorial arena zone, reverb
  coverage of the whole chapter, a real sound reaching the cavern bus, the
  pause menu sliders.
- The tutorial (111) and chapter (216) suites still pass with the new camera,
  animation and audio.

**Visually inspected** (screenshots): every chapter room with parallax,
breaches, shafts, vines and thorns; the charge pose enlarged 4×; the pause
menu. Fixed during inspection:
- beams too faint, then fading out before the visible band in tall rooms;
- the shaft light only grazing edges (it needed height);
- an over-dark first post pass;
- clip-art-looking ruins;
- thorns crowding the floor line.

Frame rate: 164–165 fps (vsync cap) in every room on an RTX 3060, with all of
the above.

**Needs a human:**
- **Listening:** all music and effects are synthesised and were checked only
  numerically (loop joins, levels, bus routing). Tone, mix balance, how
  melancholic the piano really sounds, the reverb amount, footstep volume and
  repetition.
- **Feel:** the camera damping and look-ahead, and the new walk cadence and
  recoveries, on real hardware with a real player.
- **Taste:** how dark is too dark (lantern gloom and vignette strength), how
  much the foreground thorns cover, and whether the painted layers sit well
  behind the pixel-art tiles.
- **Other hardware:** frame rate on weaker GPUs.
