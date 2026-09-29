# Chapter 1 Playtest Checklist

For a human playtester. The automated suite already proves every room *can* be solved and
that the rules hold (see "What the tests already cover" at the end); these checks are about
what a script can't judge: clarity, feel, sound, fairness and comfort.

Before starting: Title → **New Game** (press twice if there is progress), or delete
`%APPDATA%\Godot\app_userdata\The Sealed Belfry\savegame.cfg`. (The game was renamed from
"compProject"; an old save is copied across automatically the first time it starts.)

The game now records time, deaths, resets and hints for you: each cleared room and each
finished run adds a line to `%APPDATA%\Godot\app_userdata\The Sealed Belfry\playtest_log.csv`.
Only note what confused you, and where.

## Beta-tester fixes (please re-check these first)

- [ ] The jump happens the instant you press it; nothing feels delayed. Jumping just after
      running off a ledge still works.
- [ ] Holding S / Down to crouch, then jumping, is a natural way to get the high jump. The
      tutorial sign and the chapter's page ledges make it clear enough.
- [ ] Footsteps are soft and occasional, with no echo trail; the iron grate sounds metallic.
- [ ] In Rooms 2 and 7 you can't hurt the caged slime, even shooting straight down from
      the grate.
- [ ] Spikes are easy to see in the dark (red-lit tips, faint floor glow); rising spikes
      flare before they rise; piston teeth glow.
- [ ] No pillar or arcade floats on a wall: they all stand on the floor.
- [ ] The tutorial's sprint gap now needs a sprint jump; falling in fades you back without
      damage and never traps you.
- [ ] Pistons can't be walked through and healed off: a crush fades you back. Healing takes
      a moment of standing still and can't start right after a hit. Is 1.2 s right?

## Structure and guidance

- [ ] The act cards and the goal card at the top right make it clear what each room is
      for, without giving the solution away.
- [ ] Step pips and their "✓ ..." lines feel rewarding and show real progress.
- [ ] Standing by a plate or lever lights its groove toward what it controls: helpful, not
      noisy. The faint [W] cue near usable things helps you notice them.
- [ ] When stuck, the hint stone calling out (after 90 s or two deaths) is welcome, not
      pushy. Try Guidance: Light and Off too.
- [ ] The Chapter Map in the pause menu is easy to read.
- [ ] Tutorial lesson cards pace the tutorial well; dying restarts only the current lesson.

## The Echo in Chapter 1

- [ ] Room 8's spring levers make you think of an Echo without a hint; the ring on each
      handle reads as "time left".
- [ ] Room 9's plate and stairs are an easy, satisfying last use of the Echo.
- [ ] The recording countdown (seconds and ticks), "hold E to let Echoes fade", and the
      different Echo colours are clear.

## Front door and ending

- [ ] The title screen, intro text and menu set the mood; Continue goes where you expect.
- [ ] Reading a found page on its parchment, and re-reading it in the Ledger, is pleasant.
- [ ] Ringing the great bell feels like an ending (three tolls, the light returning, the
      last line); the Chapter Complete card's numbers look right.

## Every room

- [ ] The room title appears once on first entry and doesn't hide anything important.
- [ ] Without reading the hint, I understood what each object does within a minute or so.
- [ ] The violet grooves made it clear which plate/lever/crystal drives which gate.
- [ ] Interaction prompts show the right key and only appear on the object I'm next to.
- [ ] Hint stone stages go from a nudge to the full answer; stage 3 was enough to finish.
- [ ] Reset Room put things back sensibly and didn't heal me.
- [ ] Nothing ever trapped me (stuck block, closed gate behind me, platform inside me).
- [ ] The camera never showed the area outside the room; the room-to-room slide felt smooth.
- [ ] When something far away changed (a gate opening, a mirror turning), the camera's
      short look at it helped rather than annoyed.

## Room notes

- [ ] **R1 Forgotten Entrance** — Pushing the block feels weighty, not sticky. The kerb
      stopping it on the plate reads as intentional.
- [ ] **R2 Bellkeeper's Cell** — It is clear the slime is harmless in its cell and walking
      on the grate is safe. The "!" and listening rings read as "it heard the bell".
      Was 9 s long enough / too long? Did anyone try the fireball ring on their own?
- [ ] **R3 Split Flame** — The beam path is readable; mirror silver vs dark back is clear.
      Climbing the spectral stairs with tapped jumps is comfortable.
- [ ] **R4 Silent Watcher** — The heavy plate's carved blocks read as "stone only". The
      windup (red eyes) gives enough warning. Timing the lever feels fair, not fiddly.
- [ ] **R5 Broken Machinery** — Piston and vent rhythms are learnable; bolt statue charge-up
      is visible before each shot; the lift ride isn't tedious; the shortcut reveal is
      satisfying. Is the damage (2 per hit, 10 health) fair for this gauntlet?
- [ ] **R6 Lantern Crossing** — Dotted outlines read as "a platform could be here". Calling
      the wisp from the rune stones is discoverable. Cracked ledges' warning is visible.
      Recovering after a fall (calling the wisp back) is not frustrating.
- [ ] **R7 Sealed Belfry** — The chain (flame → window → mirror → plate → seal) is
      understandable with at most hint 2. The seal ceremony feels like a finale.

## Audio (listen with headphones)

- [ ] Every interaction has a sound: plate down/up, lever, bell, mirror turn, brazier,
      crystal on/off, gate rumble/slam, wisp call/arrive, gargoyle windup/strike/freeze,
      slime alert/hurt, piston warn/slam, vent warn/burst, bolt charge/fire, crumble,
      checkpoint, page collect, hint, room reset, UI.
- [ ] No sound is painfully loud, harsh or repetitive (pistons and vents repeat often).
- [ ] The volume sliders (Pause or Title → Settings & Controls) change volume immediately and are
      remembered after restarting the game.

## Look, feel and music (presentation pass)

- [ ] The camera's soft follow feels weighty but never loses Echidna; the lean
      ahead while running helps rather than distracts; jumps don't feel floaty.
- [ ] The new walk cadence, the quick stop and the landing recovery feel
      responsive; tapping left and right still shows steps.
- [ ] The charge-jump wisps read as "building power" and aren't too bright.
- [ ] Light shafts and the parallax behind the broken walls add depth without
      pulling focus from puzzles.
- [ ] The lantern gloom is moody but never hides a hazard, lever or plate you
      need; torches stay readable.
- [ ] The foreground thorns and vines never cover something you need to see.
- [ ] The piano and drone set a melancholic mood without becoming tiring; the
      combat swell in Rooms 4 and 7 (and the tutorial slime arena) is
      noticeable but gentle, and settles when you leave.
- [ ] Footsteps, spell casts and landings echo convincingly, more in the tall
      rooms (3, 5, 7) than in corridors, without muddying other sounds.
- [ ] The Music and Ambience sliders work and are remembered.

## Accessibility and comfort

- [ ] "Reduce camera shake and flashes" removes shake (pistons, bells, seal) and softens the
      hurt flash. The setting is remembered.
- [ ] Text on signs, prompts and toasts is readable at the default window size and fullscreen.
- [ ] Nothing depends on telling colours apart alone (grooves also use symbols; heavy
      plates also have carved blocks).
- [ ] No flashing is uncomfortable.

## Saving

- [ ] Quit mid-chapter, relaunch, walk through the tutorial exit: I continue from my last
      shrine with solved rooms still solved and pages still collected.
- [ ] Dying respawns me at the last shrine I walked past, with full health.

## What the tests already cover (automated, not needed by hand)

`godot --path . --fixed-fps 60 --script res://tests/run_tests.gd -- chapter`

- Each room solved with simulated input and real movement, and one continuous run through
  all seven rooms (camera checked for leaving room bounds throughout).
- Room 1: the kerb stops the block on the plate; tap vs charged jump reach.
- Room 2: one plate alone does nothing; slime stays off plate A on its own; rope and
  fireball both ring the bell; reset revives a killed slime; reset doesn't heal.
- Room 3: the mirror's back stops the beam; reload refills mana; stairs stay after stage 2.
- Room 4: torches don't freeze the watcher; the lens freezes it anywhere; the player can't
  press the heavy plate; strikes hurt and aren't spike recoveries; the frozen watcher can be
  stood on.
- Room 5: shield block stops bolts; lift, spikes, pistons, vents crossed without damage on
  the intended timing; the shortcut stays open after a reload.
- Room 6: chasm hit returns to the candle (not a death); hidden platforms solid only in light.
- Room 7: closed window blocks the beam; seal lights rune by rune; window stays open after
  the slime leaves; exit loads the next level.
- Saving: shrine respawn after death; solved rooms and pages persist; Restart Chapter wipes.
- Reset: idempotent; clears Echoes and restores the mana cap; keeps saved solutions.
- Hazards: vent hits are paced; unshielded bolts hurt; pistons hurt and push the player
  out from under the head.

---

# Chapter 2 (The Sealed Observatory) and the rune cubes

Start it from the title screen ("Chapter 2") or by opening `scenes/chapter/chapter_2.tscn`
and pressing F6. Solutions are in `docs/CHAPTER2_SOLUTIONS.md` (read them only after trying).
Nothing in this chapter has been played by a human yet; everything below is unchecked.

## The rune screens
- [ ] The first cube (Room 1): is it clear that W opens it, and that the red "(broken)"
      quadrant needs a fragment? Is the tablet's link to the broken quadrant obvious?
- [ ] The inscribe screen is readable at the default window size: quadrant glyphs, fragment
      buttons, the description and the cost line. It works with mouse, keyboard and pad.
- [ ] Refusals make sense (try Push + Up in Room 3, or a Strong rune on 10 mana in Room 7).
- [ ] Tab overview: easy to find, and "Deactivate All Runes" does what you expect.
- [ ] The rune journal (pause menu) is worth opening: fragments, notes, runes cast.

## Carrying (F)
- [ ] Picking up and setting down feels predictable; the ghost shows where the cube will land.
- [ ] Red ghosts say why a spot is refused, and the reasons are fair.
- [ ] Carrying a cube out of its room (it drifts back) is clear rather than confusing.

## Wind
- [ ] You can see where a wind blows (streaks and the dashed region) in every room.
- [ ] A crate sliding, a stone straining (shiver + grinding) and a stone moving under two
      winds all read clearly. Two winds adding up is understandable without the sign.
- [ ] Standing in a wind (drift, about a third of walking speed) is noticeable but not annoying;
      walking back against it is not frustrating.
- [ ] Room 3's updraft: jumping into it is discoverable; walking off the edge (spikes) feels fair.

## Mana
- [ ] The first player-powered cube (Room 4) makes it clear it uses your mana. The HUD strip
      under the mana bar (upkeep per second, pips per running cube) is noticed.
- [ ] Running dry (all your runes go out at once) is understandable, not a surprise.
- [ ] Room 7: the warding (mana held to 10) and the pedestal idea click. Time to solve it: ____

## Other magic
- [ ] Room 4: the stone breaking the cracked wall is satisfying (dust, shake, sound); a stone that
      stops short can be blown back and retried.
- [ ] Room 5: the ice bridge's ten seconds are enough, and the last-two-seconds flicker warns you.
- [ ] Room 6: the beam and the watcher freezing on plate A read well; the watcher isn't unfair
      while you use the lectern.
- [ ] Room 8: the portal doorway (off the cube's upper-right corner) is findable; coming out
      above the balcony feels good. The ending sequence works.
- [ ] Optional: burning the brambles with the fire cube is discoverable.

## Sound (checked only numerically so far)
- [ ] New sounds: rune on / off / refused, placing a cube, the pedestal socket, a fragment learned,
      mana running dry, gusts, the shared wind loop (it should sit under everything), the wall
      breaking, portal open / warp, ice forming / cracking, the beam, fire blast, brambles.

## What the tests already cover for Chapter 2 (automated)

`godot --path . --fixed-fps 60 --script res://tests/run_tests.gd -- rune`

- Every supported recipe (197 combinations) is valid, described and costed; unsupported ones are
  refused with a reason (missing quadrant, wrong form, direction, modifier).
- Each room solved with simulated input and real movement, and one continuous run through all
  eight rooms to the Chapter Complete card.
- Wind: one wind can't move the stone (it strains); two add up to exactly 2400 (not normalised);
  editing one cube never changes another.
- Carrying: fixed and running cubes can't be picked up; walls refuse placement with a reason and
  keep the cube in hand; the ghost snaps into pedestals; Reset Room returns cubes.
- Mana: upkeep drains ~3/s; dungeon cubes cost nothing; refilling is refused while runes draw;
  running dry shuts player-powered runes (not dungeon ones) with no restart; regeneration only
  while none of hers runs; too little mana refuses a start and charges nothing; Reset Room
  restores the room's starting mana.
- Effects: gust shoves once, Delay waits 2 s, Repeat charges each shot; Split fires three;
  a portal into rock is refused for free; Freeze holds a slime (heavy while frozen) and thaws;
  an updraft lifts a crate but not a stone; Normal beams stop at mirrors, Bounce reflects;
  a Persist bridge outlasts ten seconds; rune fire and Explode blasts burn brambles;
  Glow and Beam freeze a watcher; the cracked wall needs momentum 800 (a fast crate can't).
- Layout: every room has a goal, steps and a hint stone; no wall tile floats.
