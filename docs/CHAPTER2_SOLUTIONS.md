# Chapter 2 — The Sealed Observatory: Solution Guide

Eight rooms built around rune cubes. Every solution below is played by `tests/rune_suite.gd`
with simulated input and Echidna's real movement (scenario names in brackets; `full` plays
all eight in a row). Layout and tuning live in `tools/build_chapter2.gd`; rebuild after
changes. Open `scenes/chapter/chapter_2.tscn` and press F6 to play it directly, or choose
"Chapter 2" on the title screen.

## How rune cubes work (what the player is told, and the rules underneath)

- A cube carries one rune: **essence** (top left), **form** (top right), **direction**
  (bottom left), **modifier** (bottom right). Use a cube (W) to inscribe it; the game pauses.
  A small square in a quadrant's corner means that fragment is carved in and can't change.
- Fragments are learned from **tablets** (W to read). At the start she knows Wind, Push,
  Left and Normal.
- A running cube must be switched off before its rune is changed or it is carried.
- **F** picks up a cube that is off; F again sets it down where the ghost outline shows. A red
  ghost says why it can't go there (no floor, no room, off the room, on a hazard, out of reach).
  A cube belongs to its room: carried out of it, it drifts back.
- **Tab** lists the room's cubes: switch any of them off from anywhere, or all at once.
- **Mana**: a cube with the violet channel under it (or standing in a pedestal) is fed by the
  dungeon and costs nothing. Any other cube uses Echidna's own mana: a cost to cast, an
  upkeep per second, or a cost each time it fires. A sustained rune needs two seconds of
  upkeep in hand to start. If her mana runs dry, every rune she is powering goes out and
  stays out. Mana comes back by itself (after 1.2 s, 20 a second) only while none of her
  runes runs; refilling with R is refused while they draw on it.
- **Wind** adds up: every cube's wind on an object is added, never averaged. A crate needs
  490 to start sliding, a stone block 1470, the statue 2940. A normal wind is 1200, a strong
  one 2400. Walls and gates stop wind (the region is cut short and drawn that way); iron
  grates let it through.
- Reset Room switches the room's runes off, puts every cube, crate and stone back, and gives
  back the mana she had when she came in.
- Gates worked by plates are open only while the plates are held. Once she walks through
  into the next room, the room is saved as solved and the gate stays open behind her. (In
  Room 6 that matters: leaving the room switches her runes there off, the watcher thaws and
  plate A lifts, but the gate she came through stays open.)

## Room 1 — The Broken Inscription  [r1]
Goal: open the far gate. The cube is dungeon-powered, carved Wind / Push / ? / Normal (its
Direction is broken). The crate must reach a plate marked with a crate (only loose objects
press it).
1. Read the tablet: learn **Right**.
2. Use the cube, put Right in the broken quadrant, Switch on.
3. The wind slides the crate onto the plate; the kerb stops it there, and the gate is open while it rests there.

## Room 2 — Too Heavy for One  [r2]
Goal: stone block onto the heavy plate. The fixed cube (Wind / Push / Right / Normal) makes
the stone strain and grind but not move (1200 < 1470).
1. Switch on the fixed cube (optional, it shows the problem).
2. Hop over the fixed cube, the stone, the plate and the kerb to the loose cube past them.
3. Pick it up (F), carry it back and set it down just behind the stone, between the fixed
   cube and the stone.
4. Inscribe **Right** (it starts as Left) and switch it on: 2400 > 1470, the stone slides onto
   the plate and stays there against the kerb, so the gate stays open.

## Room 3 — Across the Teeth  [r3]
Goal: onto the high wall past the spiked pit. The cube on a pillar in the pit is out of reach;
the lectern at the pit's edge opens it. It is carved Wind / Push / Up / Large, which is
refused ("Wind Push can't point Up").
1. Read the tablet: learn **Lift**.
2. At the lectern, change the Form to Lift and switch it on: a wide updraft rises from the pit.
3. **Jump** into the updraft (walking off the edge drops you onto the spikes; the candle brings
   you back), let it carry you up, and drift right onto the wall.

## Room 4 — The Fractured Seal  [r4]
Goal: break through the cracked wall. The loose cube has no channel: it uses her own mana.
1. Read the tablet: learn **Strong** (8 mana a second; needs 16 to start).
2. Carry the cube right behind the stone block (from where it starts, its wind lets go of the
   stone too early).
3. Inscribe Strong and switch it on. The stone reaches the wall at about 310 px/s (momentum
   ~937 against the wall's 800) and breaks it. A crate can never break it (its top speed gives
   less than 800). If the stone stops short, blow it back Left and try again.

## Room 5 — The Frozen Crossing  [r5]
Goal: across the spiked pit. A cube is set into the pit's edge, its top flush with the floor,
carved Ice / ? / Right / Long.
1. Read the tablet: learn **Bridge**.
2. Stand on the cube, inscribe Bridge, switch it on (12 mana, once): a 288 px bridge of ice
   spans the pit for ten seconds (it flickers in its last two).
3. Walk across. A slime keeps the far side.

## Room 6 — The Watcher's Lock  [r6]
Goal: both heavy plates held at once (for 0.5 s, the gate opens). A cube hangs from the ceiling
over plate A, carved Light / Beam / ? / Normal, reached from the lectern.
1. Read the tablet: learn **Down**.
2. At the lectern inscribe Down and switch it on. Step back out of the watcher's sight so it
   goes back to its rounds; it turns to stone the moment it walks under the beam, on plate A.
3. Hop over the frozen watcher to the loose cube behind the stone, inscribe **Strong**, switch
   it on: the stone slides onto plate B against the kerb. The gate opens while both are held.

## Room 7 — The Limited Circuit  [r7]
Goal: statue onto the heavy plate. A warding circle holds her mana to 10 here. The statue
needs 3600 (Strong + Normal together) against its 2940; the Strong cube needs 16 in hand to
start, so from her own mana it never can.
1. Carry the Strong cube into the pedestal behind the statue (it drops into the socket and is
   then fed by the dungeon).
2. Carry the Normal cube to just behind the statue.
3. Switch on the Strong cube (free), then the Normal one (3 a second from her 10). The statue
   slides onto the plate and rests there; the gate opens while it does.
Known alternative: the Normal cube in the pedestal and the Strong one on her own mana can't
start (needs 16), so the only working split is the intended one.

## Room 8 — The Sealed Observatory  [r8] (finale)
Goal: the seal on the balcony. A portal cube, carved Space / Portal / ? / Long. Its doorway is
just off the cube's upper-right corner; the far side opens 253 px right and 253 px up.
1. Read the tablet: learn **Up-Right**.
2. Hop over the fire cube, pick up the portal cube and carry it close to the balcony wall
   (from its starting spot the far side opens in empty air; the test uses x 9736).
3. Inscribe Up-Right and switch it on (10 mana, then 8 a second).
4. Jump into the doorway over the cube: you come out above the balcony still moving as you
   were, and land on it. Open the seal (W): Chapter 2 is complete.
Optional: carry the fire cube past the portal cube and switch it on to burn the brambles; the
alcove behind them has a tablet teaching **Split**.

## Every rune the cubes accept

Anything else is refused with the reason, and costs nothing. "Needs N to start" applies to
her own mana (sustained runes need two seconds of upkeep in hand).

| Essence / Form | Directions | Modifiers and what they do | Mana (own) |
|---|---|---|---|
| Wind / Push | Right, Left, the four diagonals | Normal 1200 over 320 x 96 px; Strong 2400; Long reach 560; Large width 288 | 3 / 8 / 4 / 5 per second |
| Wind / Lift | Up | as Push | as Push |
| Wind / Burst | all eight, Self (outward) | Normal shove 420; Strong 840; Large wide; Delay (2 s later); Repeat (every 2.5 s) | 5 each shove (8 Strong) |
| Fire / Projectile | all eight | Normal one fireball; Explode (bursts 56 px); Split (three); Delay; Repeat (every 1.6 s) | 5 each (8 Explode or Split) |
| Ice / Freeze | all eight, Self | Normal 6 s over 160 x 96 px; Long reach 304; Large width 230; Persist (while on) | 8 once, or 4 per second (Persist) |
| Ice / Bridge | Right, Left | Normal 224 px for 10 s; Long 380 px for 10 s; Persist 224 px while on | 12 once, or 5 per second (Persist) |
| Light / Beam | all eight | Normal 900 px, stops at mirrors; Long 1620 px; Bounce reflects up to 6 times | 2 per second (3 Bounce) |
| Light / Glow | Self | Normal radius 104; Large radius 177 | 2 per second (3 Large) |
| Space / Portal | all eight | Normal far side 224 px away; Long 358 px | 10 to cast, then 8 per second |

## Saved ids

- Solutions: `ch2.r1.solved`, `ch2.r2.solved`, `ch2.r4.wall`, `ch2.r6.solved`, `ch2.r7.solved`;
  the chapter: `ch2.complete`.
- Shrines: `ch2.cp.start`, `ch2.cp.r4`, `ch2.cp.r6`, `ch2.cp.r8`.
- Rune knowledge (kept across chapters): `rune.frag.<id>` fragments learned, `rune.note.<id>`
  journal notes, `rune.cast.<essence/form/direction/modifier>` runes cast.
