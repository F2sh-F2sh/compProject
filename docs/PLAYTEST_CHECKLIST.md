# Chapter 1 Playtest Checklist

For a human playtester. The automated suite already proves every room *can* be solved and
that the rules hold (see "What the tests already cover" at the end); these checks are about
what a script can't judge: clarity, feel, sound, fairness and comfort.

Before starting: Pause → **Restart Chapter** (press twice) for a clean run, or delete
`%APPDATA%\Godot\app_userdata\compProject\savegame.cfg`.

Record for each room: time taken, deaths, resets used, hints used (1/2/3), and anything
that confused you.

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
- [ ] Master and Effects sliders in the pause menu change volume immediately and are
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
