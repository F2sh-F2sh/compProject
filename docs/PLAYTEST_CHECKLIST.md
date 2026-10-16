# Chapter 1 Playtest Checklist

For a human playtester. The automated suite checks intended room solutions and selected
rules (see "What the tests already cover" at the end); these checks are about
what a script can't judge: clarity, feel, sound, fairness and comfort.

## New story route — human checks still needed

- [ ] New Game → Lowbell → Nan: her missing name makes the stakes clear without rushing the conversation.
- [ ] The lantern handoff, fire, portraits and camera framing look good at your normal window size.
- [ ] Interact, Jump, controller confirm and the on-screen Continue/Skip buttons work naturally; holding Escape skips without reopening the conversation.
- [ ] The bridge winch is easy to spot; its landing and sound feel convincing. Falling before lowering it returns you safely.
- [ ] The sealed door makes the old-well route clear. You understand why Echidna enters the dungeon.
- [ ] Both passage lamps are visible and the flame-sharing prompts are clear. Missing one never traps you below a landing.
- [ ] Return to Title → Continue restores the bridge, lamps and the latest landing.
- [ ] Completing Chapter 1 → Continue shows the bell's effect on Nan, then explains the Observatory objective.
- [ ] Music, ignition, bridge and bell sounds feel balanced. Automated audio-state checks do not establish this.
- [ ] Confirm the fixed unlit-lamp halos and opened ward door look right in the rendered well scene.
- [ ] Resize Nan's cottage to wide and tall windows during dialogue and movement; inspect the framing and backdrop edges.
- [ ] Try picking up a cube beside walls and using a portal while its exit becomes blocked; check that refusal is clear and movement feels natural.

The October 7 background pass was documented in `BUG_HUNT.md` (removed in the release cleanup; see the git history). Headless gameplay,
physics and layout assertions are separate from the visual checks above. Rendered
light/bloom/glow and graphics-quality checks are skipped in headless mode, and
targeted projectile helpers bypass mouse aim, shoot input, cost and cooldown.

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
- [ ] With the wisp lines gone, the charge glow and the full-charge sparks still make it
      clear when a charged jump is ready.
- [ ] The charge bar over her head is easy to read, and its gold flash and chime make "full"
      obvious without looking at her. The chime isn't annoying after many charges.
- [ ] The small breeze at her feet while charging is noticeable in motion but subtle, and
      doesn't read as "lines"; the dust puff on take-off looks right.
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

## Finite mana (2026-10-01)

- [ ] Mana no longer refills anywhere: R does nothing but hint away from a flame; holding it at a
      shrine, candle, lit brazier or the Kept Flame refills over 1.5 s. Is it clear where to refill?
- [ ] Does running dry feel fair in the Passage slimes, Belfry rooms 3 and 7, and Observatory rooms
      with no shrine (rooms 1, 2, 3, 5, 7)? Do you ever get stuck with mana you cannot get back?
- [ ] Spark motes from slimes: noticeable, and a useful +6?

## Nan's cottage and the earned spells (2026-10-01)

- [ ] **Knocking** at Nan's door in Lowbell now leads into her cottage (the three text cards are
      gone). Does the door opening, Nan in the doorway, then the fade into the cottage feel right?
- [ ] **The cottage.** Does the room read as a cosy, drained-of-colour cottage (stone wall, hearth with
      a low blue fire, table, jar shelf, herbs, candles)? Is Nan, seated and small in her armchair, clear?
- [ ] **The conversation** is short and plain. Each line waits for a press (W, Space or Enter). Is any
      line too long, too slow, or confusing? Does it make clear that Echidna has lost her spells too,
      and why she is going down the cellar?
- [ ] **The fire beat.** Nan asks Echidna to light the fire; the hint tells her to try her fire key;
      it only sputters and she thinks "the word is gone". Does it feel like a story moment (not a
      broken key)? What if you do nothing for 30 seconds (it carries on)?
- [ ] **The lantern** leaves the table and comes to Echidna, and her light grows. Is that clear?
- [ ] **The cellar door** is the way on; the screen fades into **The Novices' Way · Phase 1**.
- [ ] **Earning the spells.** There is no fireball, heal or Echo at the start; the key just sputters.
      Phase 4 (the Kept Flame) gives fire before the pistons that need it; phase 5 (the Spring) gives
      heal after them; phase 7 (the Echo stone) gives Echo before the Echo lesson. After each, a card
      names the word and says what it does, and the spell's slot appears on the HUD.
- [ ] Do the three cards read clearly (and do they overlap any sign badly)? Is the fire card in
      phase 4 enough, now the pistons sign only says to press the fire key?
- [ ] **Saves.** A save from before this change keeps all three spells (open the old save and check the
      slots). Starting Part 2 or Part 3 straight from the title's Tutorial list gives all three.
- [ ] The pause menu's Spells list says "forgotten" for any spell not yet remembered.

## A brighter dungeon, fewer hints, the Novices' Way wording (2026-09-30)

- [ ] **Brightness.** On Normal you can see the walls, floor and props properly, and it still
      feels like a dungeon, not an office. Compare Dim (the old look), Normal and Bright in
      Settings, in the Passage, Room 1 and Room 7. Is Normal the right default?
- [ ] The watcher rooms (Belfry rooms 4 and 7, Observatory room 6) still feel dark, and the
      watchers are still readable. Does anything feel unfairly hard to see?
- [ ] **Room 7's flame.** Walking into Room 7 the first time, the camera looks up at the
      belfry flame for a moment. Is it clear that this small gold flame is the thing to
      light? Is the card line ("Light the flame by the door") needed, or too much?
- [ ] Every unlit brazier now has a small warm-gold flame and a ring that opens out of it.
      Does it read as "light me" everywhere, and do the lit blue ones still look right?
- [ ] **Fewer hints.** With the new default (Light guidance) nobody needs the cards at the top
      of the screen to find the room goal, and the rooms still make sense. Which rooms made
      you stuck for more than a couple of minutes? (The log records time per room.)
- [ ] The skull hints: the first one only says where to look; the arrows come with the second.
- [ ] Do you miss any of the removed signs (pushing a block, ringing a bell, the lift, bolts,
      vents, crumbling ledges, the Observatory's plates and edge cube)? Note which.
- [ ] **Wording.** The title screen's Tutorial opens "The Novices' Way" with Part 1 The Passage,
      Part 2 The Belfry and Part 3 The Observatory. The cards read "Part 1 Complete",
      "PART 2 COMPLETE" and "TUTORIAL COMPLETE", and the pause menu says Restart and Room Map.
      Anything still saying "Chapter 1" or "Chapter 2" for the early game?

## The story intro and Lowbell (2026-09-30)

- [ ] The story: each picture is on screen long enough to read and to watch its movement,
      but never drags; the narration reads well aloud; nothing important is hidden under the
      words. Time how long you watched before pressing on: ____
- [ ] It is clear what the Hush is and why the bell matters by the end of the story.
- [ ] Ask a first-time player afterwards, without prompting: what are rune cubes, what is the
      Hush, why did the bell stop, and what does Echidna need to do? (All four should come back
      right after the rewrite; note any that don't.) ____
- [ ] The time labels (LONG AGO … TODAY) make the order of events clear.
- [ ] Pixel art (2026-09-30): the hand-made people, monks, bells and cubes sit well beside
      the surface and town packs; nothing looks like a flat drawn shape; pixels look crisp
      (no shimmering) during the slow push-ins, in a window and fullscreen.
- [ ] Lowbell: the crow on the well, the bats, the blowing leaves and the swaying grass feel
      alive but don't distract; Nan appearing in her doorway reads as her answering the knock.
- [ ] Lowbell: the opening (camera down from the monastery, the door, the chimes, the name
      card) feels like meeting Echidna, not a delay. Skipping with Space works.
- [ ] The villagers' missing words (rune glyphs) read as "they've forgotten a word", and the
      lines are touching or funny rather than confusing.
- [ ] The lane is easy to follow to Nan's door; the stile hint is enough; nothing looks broken
      at the edges of the screen on a wide monitor.

## Held gates, water, graphics levels and the menu (2026-09-29)

- [ ] Plates and crystals: it's clear that a gate is open only while its plate is held or
      its crystal lit (Room 1 sign, Room 2 hints), and it never feels unfair that a gate
      shuts. Room 2 with the block and 12 s of slime feels right, not rushed or trivial.
- [ ] Slimes are never hidden by the thorns along the bottom of the screen or by props;
      signs are never covered by light shafts or vines; act/lesson cards don't cover signs.
- [ ] Puddles look like water in every room they're in (reflection of Echidna and the
      walls, rim highlight, ripples) and not like a glitchy strip; the wet steps, the
      splash and the drips sound right and aren't too loud or too frequent.
- [ ] Graphics: Low looks acceptable on a weak machine; each step up (Medium, High, Ultra,
      Elite) looks at least as good as the one before; Elite keeps a smooth frame rate on
      the target PC (turn on Show FPS). Note the FPS per level here: ____
- [ ] The menu: hovering and arrow-key navigation feel snappy; the chime on hover and the
      beep on select sound like a "system menu" and aren't annoying after a minute;
      rebinding from Settings → Controls works for keys and mouse buttons; the map, Ledger
      and rune journal are readable in the card.

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

## Opening, spells and teaching pass (needs a human)

- [ ] New Game plays the nine pictures and then drops straight into the Passage (no village, no cottage).
- [ ] The last picture mentions the Novices' Way and her lost spells; it reads clearly.
- [ ] The Passage order: cellar, broken stair, traps, **Echo Door**, **Kept Flame** (fireball), **Cells** (slimes), exit.
      Reading the Kept Flame gives fire and the Passage ends soon after; no Spring anywhere.
- [ ] A tour appears a few seconds in (health, then the Esc menu); another after the Echo stone (the Echo tag)
      and after the Kept Flame (mana, spell slots). Each shows once, pauses, and Esc closes it.
- [ ] Belfry room 1 shows the goal-card tour once.
- [ ] After the great bell: three pictures; the third gives back heal with a reason and says what it does.
      Heal does not work in the Belfry and works in the Observatory.
- [ ] Observatory room 1: the rune tour (4 cards) explains locked words, Tab, switching a running cube off, and mana.
      Is it too long? Does the room's cube really have only its direction editable?
- [ ] Run out of mana in Belfry rooms 2, 4, 8, 9 and Observatory rooms 2, 3, 5, 7: the entrance flame is there,
      holding R refills, and you never have to go back a room.

## Waymarks (needs a human)

- [ ] Chalk arrows on the walls point the way on through the Passage and every Belfry and Observatory room.
- [ ] They read as part of the dungeon (Wren's chalk), not as interface; not too bright, not too many.
- [ ] They disappear when Guidance is set to Off.
- [ ] Rooms that climb (Belfry R5 lift, R9 great bell stairs): is a right arrow enough, or should one point up?

## The rough loop after the Novices' Way (needs a human)

- [ ] After the dome pictures the game drops onto the Landing: five doors, only the first open, a Kindle flame, a shrine.
- [ ] Kilnworks: the Cold Forge and the Kiln Heart (both long rooms now: see their own sections below).
- [ ] Cistern: the Still Water and the Great Sluice (both long rooms now: see their own sections below).
- [ ] Lampworks: the Hall of Lamps (a long room now: see its own section below); then carry the glow cube under the high crystal (the Lamp Stair).
- [ ] Galleries: the Folded Archive and Wren's Test (both long rooms now: see their own sections below).
- [ ] After each bell: 2 or 3 pictures straight away, then the card with your time and deaths (Continue / Return to Title),
      then back on the Landing with that wing's bell-light lit and the next door open.
- [ ] After four bells the fifth door shows the pictures and opens the Eye.
- [ ] The Eye: any other sentence says "not enough"; Ice Freeze Self Large shows the Stillness and brings you back; Light Beam Up Long ends
      the game with the two closing pictures, then THE END card (the whole run's time and deaths, "Thank you for playing."),
      and Return to Title, which then says the game is complete.

## The Cold Forge (needs a human; time it)

Play it cold, without reading docs/STORY_PLAYTHROUGH.md first. Note the time from the Landing door to walking through
the Forge Door, how many hints you used, and where you got stuck.
- [ ] The Landing makes clear why you go in: the Choir's note, the warm first door with light under it, frost on the rest.
- [ ] The Cold Hearth: is it clear the cube has to fire twice (brambles first, then the pilot flame)?
- [ ] Throwing your own fire into the bellows shaft: do you think of it? Does the turning bolt read as "air carries fire"?
- [ ] Riding the shaft: you settle near the top and can step off left or right onto the ledges without precise timing.
- [ ] The kiln roof and the jump to the coal loft feel fair (a sprint jump).
- [ ] The cart: pushing it off before the slag bridge is up burns it; the red banner says why and how to reset; Esc opens on
      Reset Room; Reset Room brings the cart back. Does the bridge-first order feel fair or like a trap?
- [ ] Carrying the cube down and up the loft's lift, and into the shaft from the roof side.
- [ ] The slag plug: does "a steady wind only leans, a gust strikes" come across from trying both?
- [ ] Getting past the cube on the landing and the stone into the alcove, and back out with the Bench Cube.
- [ ] The kiln's three lamps (coal, air, fire) and its messages when a try fails ("only hisses", "no coal", "no air")
      tell you what is missing.
- [ ] The finale (perch current + bursting bolt up the shaft into the pipe): satisfying, or too hard to see?
- [ ] The roar: light, sound, the frost melting, the door sliding up, the camera moment. Too long? Too short?
- [ ] The three ledger pages: can you find them all? (The third is in a small cell high above the coal loft.)
- [ ] Total time. The target is at least 30 minutes for a first-time player; the design estimate is 22 to 35.

## The Kiln Heart (needs a human; time it)

Play it cold. Note the time from the Forge Door to the Forge Bell, the hints you used, and where you got stuck.
- [ ] Walking in, the Forge Door drops shut behind you, and the camera glances at the Ash Lamp beyond the shutter.
- [ ] The Shutter Hall: is it clear that your own fire can't reach the lamp, and that the cube can't fire while you
      hold the plate? Does Delay ("a flame that waits, then flies") click? Two seconds: too long, too short?
- [ ] The cube by the shutter is in the way: is the hop over it annoying?
- [ ] The shelf over the hall (a charged jump) with the fourth ledger page: findable?
- [ ] The Slag Lake: riding three heat vents and stepping off onto the ledges feels fair (no luck needed); falling puts you
      back at the last candle. Is the break in the first ledge (hop it, or drop to the low ledge with page v) clear?
- [ ] The gallery: the camera shows the Heart and the racks; the Large tablet, the cube and the pedestal at the end.
- [ ] A normal gust tips only the middle skip; is it obvious why, and that Large is the answer (the dashed area shows the
      gust's size)? Do the skips land in the Heart every time?
- [ ] Getting the cube down to the Heart: over the fourth vent onto the middle rack, off its end, over the Heart's rim.
      Natural, or confusing? If you fall to the tower floor early, the fourth vent takes you back up.
- [ ] The burners: the camera glances at them the first time you reach the tower floor; lighting one by hand says the
      Heart wants all three at once. Can they be lit by hand anyway (three fast shots in half a second)? That would skip
      Split; say if it happens.
- [ ] Up-Right Split from the pedestal lights all three; the Heart's beat (card, light, the frost melting, its burners
      burning steady) and the hoist starting. Is Up-Right guessable from where the burners hang?
- [ ] The hoist up to the Forge Bell; the sixth ledger page on the ledge beside the hoist (step off on the way past).
- [ ] Lose a skip (push it off a rack the wrong way): the red banner, Reset Room puts it back.
- [ ] Total time. The design estimate for a first-time player is 12 to 20 minutes.

## The Still Water, the Cistern's first room (needs a human; time it)

Play it cold. Note the time from the Landing's second door to walking through the Sluice Door, the hints you used,
and where you got stuck. The target is about 30 minutes for a first-time player; the design estimate is 20 to 30.
- [ ] The first pool: does "Ice, Freeze" on the Brink Cube read as "freeze the water to walk on it"? Is it clear how
      long the ice lasts (it flickers before it gives way)? Falling in: back to the candle, one hit.
- [ ] The second pool: a normal freeze reaches less than half; Long all but the last stretch. Is the running jump off
      the end of the ice fair?
- [ ] The shelf over the island (a charged jump) with the first ledger page: findable?
- [ ] The plug of old ice in the doorway: obvious that fire melts it?
- [ ] The gatekeeper: does "cold sinks through iron bars" come across (the cube on the grate, Freeze Down)? Is it
      clear the slime must not be killed (if it is, the red banner and Reset Room)?
- [ ] The Fountain Court: does the stair of fountains come from the tablet and the lectern, or only from the hint?
      Straight down freezes two jets low; without Long only the two tallest freeze. Is the climb (a few breaths,
      with the cube in hand) exciting or too tight?
- [ ] The tide clock: is it clear the float must be HELD at the mark (the tide touches it every twelve seconds and
      nothing happens)? Does "the cold just above the mark" come from trying? The messages when it is held short
      ("a hand's width / a stride / far short of the hour mark"). Switching on as the tide rises: findable?
- [ ] The strike: the card, the bell, the frost melting, the Sluice Door opening (the camera shows the clock, not
      the door: is that enough?).
- [ ] The three ledger pages (the island shelf, the top of the Fountain Cube, the clock gallery's corner).
- [ ] Total time.

## The Great Sluice, the Cistern's second room (needs a human; time it)

Made simpler and clearer on 2026-10-07 (one counterweight, no timing at the tide's top, a free Tide Lever, no
ballast stone, no fallen span). Play it cold. Note the time from the Sluice Door to the Tide Bell, the hints you
used, and where you got stuck. The design estimate is 25 to 40 minutes for a first-time player.
- [ ] The Silence Gallery: the cube as written freezes the slime on the plate, but it thaws before the slow plate opens
      the gate. Does that make you read the Persist tablet? Is the hop over the cube on the grate annoying?
- [ ] The Tide Hall: does the tide's rhythm read (fills, stands, empties, rests; the doorway gates shut while the water
      is up)? Do the iron teeth in the dry basin say "not this way"?
- [ ] The Tide Lever: switched on while the hall is dry, the rising tide freezes level with the doorways. Can you work
      that out from trying? Persist holds it while you cross (it costs no mana now).
- [ ] The crossing: the low pier hop, taking the Sluice Cube, the walk out.
- [ ] The Weigh House: does "two weights of stone, two slimes, a socket at the end" read at a glance? Do the slimes
      freeze on the pan reliably? The pan's notches lighting one by one.
- [ ] The Great Sluice opening: the camera's glance at the well, the well draining, the frost melting. Enough of a moment?
- [ ] Up the lift, along the High Walk, dropping into the drained well, the page in the outflow past the sluice gate,
      the bell.
- [ ] The far pier (page vi, optional): freezing the falling tide a little under the pier's top from the high ledge,
      and getting down again with the Warden's lectern on the pier. Too fiddly for an optional page?
- [ ] The gallery's high shelf (page iv, a charged jump): findable?
- [ ] Reset Room in this big room: the Silence Gate and the Great Sluice stay open (saved); the crossing does not.
- [ ] Total time.

## Smooth motion, scene fades, steadier camera (2026-10-05, needs a human)

Play on the 120 Hz and the 165 Hz screen (windowed and fullscreen). Pause > Graphics > Smooth motion switches it
off and on for comparison.
- [ ] Walking, sprinting and jumping: Echidna and the background glide; no stutter or doubled edges when the camera
      follows her. Compare with Smooth motion off.
- [ ] Moving platforms and lifts (the Weigh House lift, the Kiln hoist), slimes hopping, a carried cube, an Echo
      replaying, the lantern wisp: all smooth, nothing lagging a frame behind her.
- [ ] Anything that now looks stepped or a little behind (that would be something animated every frame that still
      follows physics steps): note what and where.
- [ ] The camera on high ledges (the High Walk, the Kiln's balconies): it no longer bobs with each hop. It follows
      once she climbs higher, falls or rides a lift. Does it ever hide something you need to see above or below?
- [ ] Camera glances at a distant point and screen shake still look right; the view never shows past a room's edge.
- [ ] Scene changes fade through black: a Landing door, a level from the title, Quit to Title, the end card's
      Continue, restarting after death and from the menu, the story pictures into Lowbell and the cottage into the
      Passage. Too long, too short? Any double fade or a flash of the old scene?

## Instant charged jump (2026-10-07, needs a human)

- [ ] Hold crouch (S): the charge starts the moment you press it (bar, breeze and glow at once) and is full after
      1.5 seconds; a quick crouch-jump goes a little higher than a tap jump. Does it feel responsive, and is the full
      charge still easy to judge?

## The Hall of Lamps, the Lampworks' first room (2026-10-08, needs a human; time it)

The goal is about an hour for a first-time player. Write down the time for each part.
- [ ] The whole room: how long from the door to the Lamp Door? (Target about 45-60 minutes.) Too long anywhere,
      too empty anywhere? Do the three little lamps over the Lamp Door read as "one per part"?
- [ ] Reading Room: Light and Beam, the bridge. Is the page i shelf by the door noticed (a charged jump)?
- [ ] Mirror Gallery: is it clear that the beam stopping at the first mirror means "it needs Bounce"? Are the
      wheels on the floor for the high mirrors easy to find, and is it clear which wheel turns which mirror?
- [ ] Watchers' Walk: does the Watcher stopping where the light begins read? Does anyone try Large, see him stop
      short of the plate, and understand why? Getting the cube back out past the waking Watcher: fair or annoying?
- [ ] Watch Lamp: is the idea "light the brazier so the Watcher holds still and stand on him" found without the
      hint stone? Is the charged jump from his back to the ledge easy enough while carrying the cube?
- [ ] Dark Stacks: do the stones appearing in light read clearly (and the faint outlines of the dark ones)? With a
      plain glow the last gap is a running jump: too hard? With Large it is a hop: is Large's benefit noticed?
- [ ] Dark Stacks: does the low vault look like part of the hall (the book stacks), not a bug?
- [ ] Great Lamp: Up-Left found quickly? Is the Great Lamp lighting and the door opening a big enough finish?
- [ ] Reset Room in the middle of the hall: you come back at the last shrine you passed (not the hall's door), the
      gates behind you stay open, and the Watch Cube is back at its stand in the Watchers' Walk.
- [ ] The hall is dimmer than other rooms (ambient 85%) so lamps and glows stand out: too dark anywhere?

## The Folded Galleries: the Folded Archive and Wren's Test (2026-10-08, needs a human; time it)

The goal is about two hours for the whole wing. Write down the time for each part.
- [ ] The whole wing: how long from the Archive's door to the Fold Bell? (Target about 2 hours; the estimate is
      1.5 to 2.) Anything too long, too empty, or too fiddly?
- [ ] Sealed Door: is "hop over the Door Cube into its doorway" found? Does coming out beyond the rock read?
- [ ] Tall Stacks: is the shelf and its lever noticed from the floor (the camera glances at it once)? Is it clear
      that the doorway Up hangs in the air over the shelf?
- [ ] Sealed Reading Room: is the pocket overhead noticed? How long until someone thinks of the Echo? Is it clear
      the gate stays open once you are through?
- [ ] Pillar: does a player try Long first, find the gate shut, and work out "Echo into the hollow, then Long"?
      Is rewriting the cube while the Echo still goes into the hollow surprising in a good way?
- [ ] Hearth: is "throw fire straight up through the doorway" found? Is the spot to stand under the doorway easy
      to hit (about 35 px wide)?
- [ ] Again: does the stalling lift (one bolt, two seconds) teach Repeat? Boarding the moving lift: fine?
- [ ] Aslant: is Down-Left found (it is the Cistern's fountain stair, mirrored)? Is the climb too rushed?
- [ ] Two Hearths: how long until the Echo idea comes? Is syncing your throw with the Echo's comfortable (each fire
      burns two seconds)?
- [ ] The Last Crystal: the pocket with the last mirror's wheel: found without the hint stone?
- [ ] Wren: does she read as a child in a nightdress (pixel art)? Her lines: clear, too many, too slow (3.8 s
      each)? Does it feel like a moment worth the climb?
- [ ] Reset Room in either room: back at the last shrine passed, gates behind you still open, cubes back home.

## The story, the reels and the ending (2026-10-08, needs a human)

Play the opening, every reel between the parts, and the Eye with both endings, with sound on. Everything here was
looked at only as still screenshots; nobody has watched the reels move or heard the music.

- [ ] **Does the ending land?** From writing Light · Beam · Up · Long to the two stars over the mountain: is it moving,
      or does it drag? Note any line that feels flat or too much.
- [ ] The story makes sense in one sitting: the four notes (Nan's hum at the cottage, the bell's peal, the night of
      the spell, the last scene), why the bell quiets the Hush, who leaves the chalk stars and why, what the moth is,
      why the Stillness is tempting, and why there are two stars at the end.
- [ ] Reels read clearly: the letterbox, the small words in the bottom bar, the lore cards; nothing too dark to make
      out on your screen (try the dark shots: the Choir on the ledge, the dome, the Eye, the Stillness).
- [ ] The depth layers drift smoothly as the camera pushes in; nothing shows an edge or a gap at the sides of the frame
      (try a wide window too).
- [ ] Music: the lullaby (opening, Lampworks memory, the porch scenes), the bell peal (opening, the bell reel) and the
      ending swell (the Rewritten Sky) start where they should, are not too loud or too quiet against the loops, and
      stop cleanly when a reel is skipped with Esc. The music-box tone is pleasant, not harsh.
- [ ] Nan hums when Echidna comes into the cottage, and stops when she speaks.
- [ ] The Eye: the moth over the cube is in view without looking for it; Wren meets you at the door and walks to the
      cube; Ilse's plea is readable and you can see her while she speaks; a wrong sentence gets Wren's answer; the room
      is dark but the floor is clear to walk; the hint stone's first two stages point you at the clues without giving
      the answer away. Time how long the Eye takes.
- [ ] The Stillness: it feels like a real temptation, not a fail screen; back in the Eye, Wren's "You came back." lines
      play.
- [ ] The Rewritten Sky: the chains break one at a time, the candle goes out, the snow starts falling again, Nan says
      "Echidna.", and THE END card follows with the run's time and deaths.

## The polish pass (2026-10-09, needs a human)

Play from the title screen through at least the Kilnworks and one more wing, with sound on, with the default settings
(hint waits on, creatures roaming). The new look was checked as still screenshots and the new sounds only by test
counters: nobody has heard them or fought the creatures.

- [ ] **Title screen:** the portrait, banner and big title fit your window (try a wide and a narrow one); the menu
      buttons are easy to read and click.
- [ ] **Fonts and UI:** every text is readable at your screen size (the small Silkscreen labels on the HUD, the
      pause menu's plates, the parchment pages); nothing is cut off or overlaps; the stone and gold look holds up.
- [ ] **Dialogue:** the portraits in the cottage, Wren's meeting and the Eye look right (faces match the lines), the
      typewriter is a good speed, and pressing skips then advances as you'd expect.
- [ ] **Story:** after the opening and the cottage, can you say why there's a dungeon under Nan's house (the gatehouse,
      the frozen road)? At the end, is it clear the bell is silent and only the wind moves the chimes?
- [ ] **Levels feel different:** each wing's colours, drifting air and props read as its own place; nothing is too
      dark or too saturated on your screen.
- [ ] **Creatures:** fights feel fair (not too many, not too tanky); none blocks a puzzle or stands where you have to
      think; cinderlings shrug off fire, clinkers crack then break, jellies and hushlings are readable threats. Note any
      room where they get in the way. Time each wing again with creatures in it.
- [ ] **Sound:** the beds (Belfry wind, forge, water, lamp hum, paper folds, the Eye's silence) sit under the music, not
      over it; dying sounds heavy but not too long; the stone menu clicks are pleasant; footsteps on ash, wet stone and
      paper sound right.
- [ ] **Hint waits:** a minute before the first hint feels fair, not punishing; the ring is noticed; the message when it
      isn't ready is clear. Try the "Hints without waiting" assist.
- [ ] **Target pips:** the gold pips at the screen's edge help you find off-screen targets without giving the puzzle
      away; they vanish when the target is lit; they're not distracting.
- [ ] **Rune wheel:** reading a combination, the glow colours and the "WHERE IT GOES" view make aiming feel informed.

## The second playtest list (2026-10-03, needs a human)

- [ ] Mana: whenever it isn't full, a faint "[R]" floats over the nearest flame you can kindle at, and "[R] Kindle" once
      you're close enough; pressing R away from one says which kinds of flame work (a flame bowl, a shrine, a candle, a
      lit brazier; not wall torches) and which side the nearest is on. Wall torches never get the cue.
- [ ] Chalk arrows on the walls show the way on and blend into the stone (Lowbell has three on the way to Nan's door).
- [ ] Going into the next room drops the cage (or the Forge Door) behind you; you never need to go back. Reloading a save
      keeps the ways back shut.
- [ ] Belfry room 9: the hot spring after the great bell; drinking from it gives heal (the pictures no longer do).
- [ ] The end of each level: only Continue and Return to Title, no staying in the level.
- [ ] After the opening pictures you are on the surface in Lowbell and walk to Nan's house yourself.
- [ ] The title says "Choose a Level": Level 1 The Passage (tutorial), Level 2 The Belfry, Level 3 The Observatory; the
      Passage's first sign says Level 1; the end cards say LEVEL n COMPLETE.
- [ ] The HUD: MANA on the left, health on the right. The interface tour points arrows at the health bar and its number,
      then at the mana bar and its number (numbered when there are two).

## Playtest fixes (2026-10-02, needs a human)

- [ ] A room that can no longer be finished (the coal cart burned; a slime that had to hold a plate killed) shows the red
      banner after the room's title has gone, and Esc opens straight on Map, Reset Room.
- [ ] Choosing Return to Title at the end of a part no longer skips the pictures: the pictures come first, then the card.
- [ ] Portals work both ways: walk back into the far side and you come out of the near one.
- [ ] Rune editing is explained: the rune tour plays the first time you reach any cube (5 cards: four words, words change
      only while the cube is OFF, LOCKED words never change, Tab lists your runes, running runes use mana); the cube's
      prompt says "Running: switch off to edit" while it runs; locked slots show a padlock and LOCKED; the Tab list
      repeats the rules and has an Inscribe button; Esc, Echidna, Runes, "How rune cubes work" plays the tour again.
- [ ] Title: Continue goes to the Landing after the Observatory; the progress line counts bells; the Long Stair is in the parts list.

## Daily puzzle (2026-10-10, needs a human)

- [ ] Title: "Daily Puzzle" sits after "Choose a Level"; all six words fit above the description.
- [ ] Daily menu shows today's date and difficulty, streak, 14-day strip, board and the buttons; Esc closes it;
      with a pad, focus lands on "Play today's puzzle" and the arrows reach every button.
- [ ] Play today: 3 to 5 rooms and a bell hall; every room can be solved with more than one sentence; dying
      reloads the same puzzle at the furthest room; Reset Room works; hints work and cost points.
- [ ] End card: stars, score, the deductions, "the ways through", streak, share code; Copy puts
      "Sealed Belfry ..." text on the clipboard; "Try it again" starts practice of the same day.
- [ ] A second run of the same day is practice and does not change the streak.
- [ ] Add a friend: paste a code from another install; the row appears on the board; a typo is refused.
- [ ] Endless: Gentle, Steady, Hard and Grand each start a fresh seeded run; the row is reachable from the
      practice button and leads down to Back with keyboard/controller focus.
- [ ] Back in the story afterwards: Continue, runes and abilities are exactly as they were.
- [ ] Handheld (640x480): the menu fits, no typing is asked for, friends.txt is read, a 1970 clock says why
      the daily is closed but practice still works.

## Generated puzzles and Endless

- Run `daily verified_fresh`, `new_modules`, `chains`, `endless`, `endless_persistence` and `calibration`, then the complete daily suite.
- Run `daily endless_long`: 30 rooms per starting difficulty, using real physics, checking room freeing, one-time completion, generation latency and the ramp.
- Run daily, polish, prologue, tutorial, experience, presentation, rune, chapter, adversarial and wing suites sequentially. Check script-error lines as well as result counts; distinguish the four documented baseline NPC-scale checks from new regressions.
- Render the Daily Puzzle menu, stair HUD, tenth-room rest card and third-death run-over card at normal size and native 640×480. Inspect text wrapping, panel bounds, focus visibility, floors, gates, torches, cubes and platform spacing.
- Keyboard/controller manual acceptance: complete an Endless run to a rest stop and game over, navigate each difficulty button and return to the title. Automated action injection and screenshots are not manual controller playtesting.
- Confirm story checkpoint, flags, vocabulary, abilities and save-persistence rules are restored after leaving. Confirm records are kept after each room and corrupted records do not crash loading.
- Collect actual participant solve observations before presenting a calibration chart as evidence from a playtest group. The local fitting tool does not manufacture study data.

### Automated/render acceptance recorded 2026-10-10

- [x] Complete version-3 table: 76 layouts; retained inscriptions pass three physics runs; runtime excludes layouts with fewer than two minimal solutions.
- [x] Full Daily 404/0; Endless 20/0 at both resolutions; freshness 12/0; native keyboard/injected-pad focus 12/0 per resolution.
- [x] Repeated 120-room endurance: 720/0, scene roots freed and generation below 50 ms on the Windows QA machine.
- [x] Inspected normal and native 640×480 menus/cards, active-rune HUD separation, full module geometry and active effects. Scrolling follows focus to Back and the end-card buttons.
- [x] All listed story suites run sequentially. Windows D3D12 presentation passes 111/0; four documented NPC-scale failures remain in polish. Extra OpenGL presentation runs retain an intermittent spike-contrast assertion failure; see IMPLEMENTATION_PROGRESS.
- [x] Exported handheld resource pack contains the complete verified table. This is a packaging check, not an ARM hardware run.
- [ ] Physical keyboard/controller acceptance and actual ARM handheld performance.
- [ ] Participant calibration data and a chart based on their solve observations.

### All-difficulty automated acceptance recorded 2026-10-11

- [x] Version-7 standalone exits, floor-placed Master portals, pit death/life accounting and bounded score caching regressions.
- [x] All 17 difficulty steps attacked with normal/charged jumps and sprinting; compact native run 162/0.
- [x] 204 observed mechanism/geometry cases across 1,000 seeds per named difficulty: movement attacks and two distinct solutions each, 817/0.
- [x] Every named difficulty solves, resets and re-solves with a different inscription; exits reopen and scoring is not duplicated, 25/0.
- [x] Full Daily 673/0; updated difficulty audit 186/0; optimized 120-room Endless 720/0; authored Folded Galleries 77/0.
- [x] 460 before/after generator outputs identical; final generation maximum 34.993 ms across 120 rooms after repeated Hard timing failures were fixed.
- [x] Final full-size/compact native render inspection and scene/script loading; existing load-helper shutdown warnings remain documented.
- [ ] Manual player/controller acceptance and additional creative routes beyond the automated corpus.

### Rune/reset adversarial acceptance recorded 2026-10-12

- [x] Legal live-effect reset sweep at all 17 difficulty steps, including fixed carvings above the lent word tier: 272/0.
- [x] Fixed/portable cube restrictions, closed exits, unsupported gaps, held-cube resets and reset spam: 150/0.
- [x] Gust impact during reset cannot credit an abandoned clear; timer keeps running and a later solution remains valid: 8/0.
- [x] Master shared portal cube has a continuous handoff route; ordinary active-cube restrictions remain: 18/0.
- [x] Carried portal cube cannot clip through a late exit obstruction; reset cleans its anchored portal: 5/0.
- [x] All 334 valid learned non-Lift sentences tried after Grand/Master first-stage unlock and real carrying/placement: 1,684/0.
- [x] Full native Daily 1,126/0; Endless 720/0; updated scale audit 186/0; authored story portal route 77/0.
- [x] Complete version-8 verification metadata and native 640×480 carried-portal render inspection.
- [ ] Manual controller testing and further unusual timings/object arrangements beyond these fixtures.

### Portal and stage-transition stress recorded 2026-10-12

- [x] Carrying another stage's cube backward cannot overlap the mounted portal owner; old rule reproduces two failures, corrected rule 8/0.
- [x] Shared portal owner can reverse through its fold and repeat the forward handoff; extended continuous route 22/0.
- [x] Reset spam before warp and 0/1/18 frames after normal/long warps through two-/three-column walls: 80/0.
- [x] Genuine first-stage clears followed by moving/reset spam at the gate across all 17 difficulty settings: 68/0.
- [x] Full rendered Daily assertions 1,286/0. Detached camera errors found during its Endless transitions were fixed; targeted Endless lifecycle 20/0 and ordinary camera tracking 7/0 have clean error logs.
- [x] Authored Folded Galleries second level 39/0; affected portal proofs repeated three times and complete metadata refreshed.
- [x] Fresh compact native render inspected and 306 resources loaded; pre-existing load-helper shutdown warnings remain.
- [ ] Manual controller acceptance and arrangements/timings beyond the automated fixtures.

### Difficulty and configuration variety recorded 2026-10-12 (version 9)

- [x] Same-corpus comparison: 2,100 Daily and 8,000 Endless configurations; below-floor rooms 10 → 0, same-run Daily duplicates 96 → 0, immediate Endless repeats 161 → 0, recent repeats 1,004 → 85.
- [x] Hard requires meaningful rune-word choice; Grand/Master first stages do too. Form-open portal handoff and legacy portal recipes remain valid.
- [x] Repeated/reset/death regeneration preserves the same puzzle; history changes only on completed-room banking.
- [x] Final named/quarter/sequential-history scale audit 186/0, with physical solutions and increasing means throughout the ramp.
- [x] Final rendered Daily 1,633/0; meaningful Grand corpus 44/0 over 10 pairings/14 variants; 120-room Endless 720/0, generation maximum 28.893 ms.
- [x] Complete version-9 physics proof metadata and machine-readable variety/difficulty reports saved; 306 resources load.
- [ ] Human difficulty calibration, further creative routes, and additional mechanisms for constrained Gentle ramp bands. Existing mechanisms still recur.

### Gentle ground-shape variety recorded 2026-10-12 (version 10)

- [x] Qualifying Gentle Updraft configurations expanded from 4 to 12 with ridge, descending terraces and lower landing geometry.
- [x] Same first rise, rune vocabulary, modifier choices and structural score; no added hazards or timing requirements. Legacy ridge lookups remain valid.
- [x] All twelve configurations: continuous normal-wind solve, charged-jump attack, cube/gate reset and unchanged-score checks; focused scenario 160/0.
- [x] Same-corpus 8,000-room Endless audit has zero four-room-history repeats, including Gentle; 2,100 Daily configurations have no same-run duplicates or below-floor rooms.
- [x] Complete three-run Updraft physics proofs and version-10 metadata; final rendered Daily 1,790/0, scale audit 186/0, 120-room Endless 720/0.
- [x] Native ridge/terrace/landing geometry captures inspected with a fixed QA camera; ordinary gameplay-camera tests rendered separately. All 306 resources load.
- [ ] Human beginner difficulty calibration and routes beyond the automated corpus. Finite configurations and mechanic types can recur later.
