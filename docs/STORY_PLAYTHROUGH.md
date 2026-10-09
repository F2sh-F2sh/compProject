# The rest of the game: a super rough playthrough

## The story (v3, 2026-10-08): the one source every scene follows

**Theme.** Love that holds on, and love that lets go. **The mirror:** Echidna is losing Nan (the Hush has
taken Echidna's name from her) the way Ilse was losing Wren. The ending asks Echidna to do what Ilse could not.

**What is true, everywhere in the game:**
1. **The stars are words.** Four words make a spell. The Choir, monks on the mountain, read them and carved
   their own spells into rune cubes.
2. **The night of the spell.** Sixty years ago Ilse, the Choir's leader, sat every night by her dying
   daughter Wren and sang her a lullaby of **four notes**. Wren always asked: *"Will you be here when I wake
   up?"* One night Ilse wrote ICE · FREEZE · SELF · PERSIST, so that the morning would never come.
3. **The Hush.** The spell is still being cast. To hold the moment it burns the sky's words: **stars go out,
   and people forget words and names.** It spreads from the room where it was written, deep in the mountain.
4. **Why the bell works.** The great bell's peal is Ilse's lullaby, the same four notes. The spell still
   listens to the one song it was made for, and grows quiet while it rings. The monks rang it every day for
   sixty years, so every child in Lowbell grew up with it. **Nan hums it** without knowing what it is.
   Nine years ago the bell cracked; the monks sealed the Belfry and left; the Hush came down the mountain.
5. **The held moment** has grown into a great pale **moth**, its wings made of the frozen night, folded round
   Wren's room the way a moth circles a candle it can't leave. **Four chains**, one for each word, hold it to
   the great cube in the Eye. Ilse kneels at the bed holding Wren's hand. She is the one holding on.
6. **Wren** is awake inside the held night. She can slip a little way out through the folds of the mountain,
   and she leaves **chalk stars** ("look up": her mother taught her that stars are words) to lead someone down
   to end it. She doesn't want her mother to be alone.
7. **The four bells** in the four wings hold the Eye shut (the Choir sealed it after the bell cracked). Ringing
   all four opens it.
8. **The endings.** *The Stillness* (Ice · Freeze · Self · Large) is Echidna's temptation: hold Nan still so
   she never forgets again. It is shown with its full weight; then Wren says *"That's what Mum did."* and the
   cube is in front of her again. *The Rewritten Sky* (Light · Beam · Up · Long): the moth fills with light,
   the chains break one word at a time, Ilse opens her hand, and Wren holds hers out: *"Come with me, Mum.
   You won't be alone."* Two new stars rise side by side where the dark gap was. The Hush thaws, colour and
   the chimes come back to Lowbell, and Nan says *"Echidna."*
9. **The last scene.** Nan: *"I'll lose it again one day, love."* Echidna: *"Then I'll tell you again. As many
   times as it takes."* Two stars over the mountain.

**Set-ups and their pay-offs:** the four notes (Nan's hum at the cottage, every bell, the Eye, the last scene);
*"as many times as it takes"* (Echidna's promise at the cottage, the last scene); *"Will you be here when I
wake up?"* (the night of the spell, shown after the Lampworks; in the Eye Wren answers *"I'm awake, Mum. It's
morning."*); the chalk stars (look up: the word Up); the words over the Eye's door *"What cannot be kept can be sent"*; Wren's
*"I just don't want Mum to be alone"* (the Galleries; the two stars).

**How it is told:** pixel art staged like Hollow Knight's cutscenes: dark layered depth, near-black
silhouettes in front, one glowing thing to look at, drifting motes, a letterbox; most shots without words, and
the few words as lore cards (pale serif text on black) or one short caption. Plain words always.

**The reels as built** (`scripts/story/story_intro.gd`, `story_interlude.gd`, staged with
`scripts/story/story_stage.gd`):
- **The opening (8):** the Choir on a ledge under the stars, which join into a word; a rune cube lighting in
  a dark hall; Ilse kneeling at Wren's bed as four notes rise from her (the lullaby plays), *"Will you be here
  when I wake up?"*; the great cube taking ICE · FREEZE · SELF · PERSIST, the frost, the snow stopping; the moth
  growing behind the mountain as the stars go out; the bell ringing the same four notes (the peal plays) and
  the grey Hush pushed back; the crack and the monks leaving; Lowbell today, and Echidna.
- **The bell (4), merged with the teammate's aftermath beats:** the peal crossing the mountain in rings; Nan by
  her hearth humming along, then half a name, *"Ech..."*; a lore card with the Bellkeeper's last note; the
  cracked bell and the first chalk star on the stair.
- **The dome (3):** the dark gap spelling the sentence under the dome's rim; through the lens, the Eye with the
  moth folded tight over the cube and Ilse at the bed; the Long Stair and the five doors.
- **After each wing (2):** Kilnworks (Nan's cold stove lights itself; the chalk footprints); Cistern (a lore card,
  her notebook; *"Don't use the last one. —W"*); Lampworks (the night of the spell from Ilse's side, sepia, the
  lullaby; *"She was a mother who would not let go."*); Galleries (Wren in her lit doorway; the four lights).
- **The Eye opens (3):** the beam; Nan alone on her porch humming; Echidna going down past the folded moth.
- **The Stillness (3), almost grey:** Lowbell stopped mid-swing; Nan stopped mid-word, *"Echi..."*; Wren takes
  Echidna's hand: *"That's what Mum did."* / *"It isn't keeping someone. It's only stopping."* Back to the Eye.
- **The Rewritten Sky (11):** the cube takes Light · Beam · Up · Long and a beam rises (silent); the four chains
  break, plate by plate (the ending swell starts); the moth fills with light over small Echidna; at the bedside
  Wren: *"I'm awake, Mum. It's morning."* / *"Come with me. You won't be alone."*, the candle goes out, Ilse
  opens her hand, the light takes them; the moth rises through the dome and comes apart into two sparks; a lore
  card, *"What cannot be kept can be sent."*; two new stars where the dark was; the thaw (colour coming back
  from the stars outward, the snow falling); Lowbell's colour and chimes; Nan on her porch: *"Echidna."* /
  *"I'll lose it again one day, love."* / *"Then I'll tell you again. As many times as it takes."* (the lullaby
  plays); two stars over the mountain; THE END card.

**No "why?" left over (the polish pass, 2026-10-09).** Each answer is shown on screen, not only written here:
- *Why is there a dungeon under Nan's house?* The cottage is the Choir's old **gatehouse** at the mountain's foot,
  and Nan was the Choir's last novice as a girl (why she knows the path, the bell and the tune). Since the bell
  cracked the mountain road has been frozen shut for nine winters, so the only way up is the novices' path
  **inside** the mountain, whose door is under the gatehouse. Shown in the opening's last shot, by Edda in
  Lowbell ("The road up the mountain's been frozen shut for nine winters") and by Nan in the cottage.
- *Why ring the cracked bell first?* Its peal is the lullaby, the one thing the Hush gives way to: it pushes the
  Hush off Lowbell for a while, and the Bellkeeper's note sends her on to find what is causing it.
- *Why four bells on the Eye?* The departing Choir sealed it with four bell-locks so only someone who had walked
  every wing, and learned every word, could open it (the Choir's note on the Landing).
- *Why learn words in stone?* The Hush eats spoken words; carved stone remembers ("Stone remembers," Nan says).
- *What are the creatures?* Scraps of the held night that took shape in the dark, each wing's kind shaped by what
  the wing was for (embers in the forge, brine in the cistern, moths at the lamps, folds in the galleries).
- *Why do bells ring at the end, if the Hush is over?* They don't. The great bell hangs silent ("It would never need
  to ring again."), and Lowbell's porch chimes move because the **wind** has come back: wind and chimes only.

The teammate's pilgrim-road prologue and bell aftermath scenes are kept as they were but are not part of the
journey.

---

*Rough on purpose. It follows `GAME_DESIGN.md` (v2) and makes the puzzles harder. I read "the next 5 rooms" as
the next five chapters (the Kilnworks, the Cistern, the Lampworks, the Galleries, the Eye), each a short run
of rooms ending in a set piece. Every sentence below is four words from the existing grammar:
Essence · Action · Direction · Modifier. They are sketches: each gets checked against `RuneBook.SUPPORTED`
and solved by a test before it goes in the game.*

Where we are: Echidna has walked the Novices' Way (the Passage, the Belfry, the Observatory). She has fire,
echo and heal, knows 11 words, rang the great bell once, and has seen the dark gap in the stars:
**ICE · FREEZE · SELF · PERSIST**, the spell that never stopped.

---

## Between the Novices' Way and Chapter 1: the Long Stair

The Observatory's floor lens showed a frozen room far below. The only way is down.

- **The dome's third picture, THE LONG STAIR** (built): under the lens a stair winds down into the mountain to a
  landing of five doors. Four are white with the Hush's rime; under one, warm light still leaks out.
- **The Landing** (built; a small walkable ledge, one minute): five doors, a dark bell-light over each, a Kindle
  flame, a shrine, and Wren's chalk steps. The Choir's last note on the wall says why she goes in, and which way:
  *"Four bells hold the Eye shut. Ring the Forge Bell first: its heat runs in the pipes behind every door and
  thaws the next."* The first door (the Kilnworks) is the warm one: its frost has melted and warm light spills
  from under it. The others are sealed with frost; using one says *"The Hush's frost holds this door shut. The
  heat of the bell before it will thaw it."*
- Each bell she rings lights its lamp over its door, and its heat thaws the next door.

---

## Chapter 1 · The Kilnworks (fire)

**Story.** The Choir fired their rune cubes here. When the Hush came, the furnaces froze mid-burn, so part of
the wall is still glowing and part is dead cold. A Smith's ledger tells her why the wings were split in four:
*"We feared one spell too strong to carry, so we hid its parts apart."* The wing's bell is the **Forge Bell**.

**Rough playthrough, six rooms and a boss** (rooms 1 and 2 are built and finished; the rest of this list is
still a sketch)
1. **The Cold Forge** (built and finished). The Smith let the Great Kiln
   go cold so the Hush's frost would have nothing to hold; relighting it is what thaws the Forge Door. The kiln
   needs three things at once: **coal** in its fuel bay, **air** blowing into the pipe in its left side, and a
   **flame that bursts** reaching the firebox through that pipe (a plain spark only hisses on the frosted coal).
   The chain, in the order most players will find it:
   1. *The Cold Hearth.* `Fire · Projectile` on the Forge Cube (its direction is carved): the first bolt burns the
      brambles, the second lights the pilot flame across the slag, and a bridge forms.
   2. *Fire rides the air.* Her own fireball thrown into the always-on bellows shaft turns and rises with it,
      and lights the brazier hanging above, which raises a bridge over the slag beyond the kiln.
   3. Ride the shaft up (it lifts her too), walk the kiln's roof, jump to the coal loft. Learn Up and Burst there.
   4. `Wind · Push · Left` on the Loft Cube pushes the coal cart off the loft onto the new bridge (before the
      bridge is up it falls in the slag and burns: the room says so and how to reset it).
   5. Carry the cube down the loft's lift and push the cart into the kiln's fuel bay: **coal**.
   6. Carry the cube back up the lift, over the roof, into the shaft from the east and off at the west landing.
      A steady wind only leans on the stone pressed against the slag plug; `Wind · Burst · Left · Strong`, one
      gust, drives it through. The Bench Cube's own first two words are carved, so it can't do it.
   7. Over the stone into the alcove: the Explode tablet and the second ledger page.
   8. The Bench Cube down onto the perch's pedestal, `Wind · Push · Right`: its current blows into the pipe: **air**.
   9. The Loft Cube on the floor below the perch, `Fire · Projectile · Right · Explode`: the bolt rides the shaft
      up, turns into the perch's current and flies down the pipe: **fire**. The kiln roars, the hall warms, the
      frost melts, the Forge Door slides up, and the roaring kiln is a flame to kindle at.
   10. Out the same way (shaft, roof, loft, lift) through the Forge Door.
   Three optional ledger pages (one under a bramble mat in a cell above the loft). Five hint stones, three stages
   each. Design estimate for a first-time player: about 22 to 35 minutes; it needs a human playtest to confirm.
2. **The Kiln Heart** (built and finished). The Great Kiln's heat runs on into the Smith's last forge: a long hall
   over a lake of slag, then the tower where the Forge Bell hangs frozen. The **Heart**, the Smith's crucible sunk
   in the tower floor, wakes it: three skips of coal tipped into it and its three burners lit at the same moment.
   1. *The Shutter Hall (Delay).* The Ash Lamp beyond the shutter is too far for her own fire. The Shutter Cube
      throws further (its first three words are carved: Fire, Projectile, Right), but the shutter stands open only
      while someone is on its plate, and she can't be at the cube and on the plate at once. The Delay tablet:
      inscribe Delay, switch the cube on and run back onto the plate; two seconds later the bolt flies through the
      open shutter and lights the lamp, which holds the shutter open for good.
   2. *The Slag Lake.* Three heat vents (dungeon machinery, always on) rise out of the slag. Walk off the bank into
      the first, ride it up and step onto the first ledge; hop the break in it and walk off its end into the
      second vent; the third lets her off on the gallery. A fall in the slag puts her back at the last candle.
   3. *The Coal Racks (Large).* Three skips of coal sit on three iron racks over the Heart's rim, one above
      another. Carry the gallery's cube to the pedestal at the gallery's end: `Wind · Burst · Right` tips only the
      middle skip into the Heart; with Large (a gust three times as tall) all three go. Wind blows through iron bars.
   4. *The Heart (Split).* Carry the cube down (over the fourth vent onto the middle rack, off its end, over the
      Heart's rim) to the pedestal beside the Heart. Each burner flares and dies in half a second, so lighting them
      one at a time does nothing; `Fire · Projectile · Up-Right · Split` throws one bolt three ways and lights all
      three at once. The Heart beats: the frost lets go of the bell, its burners burn steady, the hoist starts.
   5. *The bell.* The hoist is the only way up to the Forge Bell. Ring it.
   Three optional ledger pages (a shelf over the hall, reached with a charged jump; a low ledge in the lake under
   the break in the first ledge; a ledge beside the hoist halfway up). Four hint stones, three stages each. Design
   estimate for a first-time player: about 12 to 20 minutes; it needs a human playtest to confirm.
3. **The Fuse Row.** Bramble fuses burn along a rail toward the gate. Light them in the order the fuse burns, then
   hold the gate with a Delayed bolt (`Fire · Projectile · Right · Delay`) landing as the moving gate opens.
   Wrong order burns the last fuse and the room resets.
4. **The Cinder Hall.** Cinders are sparks that ignore fire and run toward warmth. Steer them with Strong wind into the
   bramble gate (they ignite it), but stop one cinder before it reaches your own lit brazier.
5. **The Clinker Line.** A slow kiln golem carries a burning coal along a belt. Tip it with `Wind · Push · Right · Strong`
   so the coal spills on a fuse, while a second cube must hold a stone on the weighted plate.
6. **The Bellows.** Fire plus wind: a bellows pushes flame along a channel. `Fire · Burst · Up-Right · Explode` cracks
   the wall; then burn the brambles behind it before the vents lift the flame away.
7. **The Slag Climb.** Vertical room: vents lift Echidna and the Cinders. Time Burst shots to reach three
   ledges without using the second flame. The first mana pool is only enough if she kindles at the midpoint flame.
- **Boss (sketch): the Kiln Heart overheating.** Phase 1 (cold): light three vents with one `Fire · Projectile ·
  Up · Split`. Phase 2 (overheating): blow its cinders into quench puddles and crack its armour with a delayed
  Explode. Phase 3 (settle): drive a stone onto its core with wind to seal it. (The built Kiln Heart, room 2
  above, uses the first phase's idea without the fight.)

**Ends.** The Forge Bell rings, warm gold light along the Landing, and a line of small chalk footprints leads into
the next door. New words: Fire, Projectile, Up, Large, Burst, Delay, Explode.

---

## Between 1 and 2: a bell and a footprint

A short run of pictures. The Forge Bell's four notes run down the mountain. In Lowbell the cold stove in Nan's
kitchen lights by itself, and Nan looks up from her chair and almost says a name. Echidna doesn't see this; the
player does. Then the chalk footprints stop at a flooded door.

---

## Chapter 2 · The Drowned Cistern (ice)

**Story.** The Choir kept water clocks that measured the sky. They all stopped at the same minute, the minute
Ilse cast. A Warden's ledger: *"The water remembers. It has been waiting sixty years to move."* Wren is seen
behind a pane of glass, drawing a star. This is where Echidna learns **Persist**: "the word that made the silence".
The bell is the **Tide Bell**.

**Rough playthrough** (rooms 1 and 2 are built and finished: room 1 replaces the old First Pool sketch and borrows
the tide clock from the Tide Stairs; room 2 takes in the Tide Stairs, the Frozen Weights and the Sluice. The rest is
still a sketch)
1. **The Still Water** (built and finished). The Warden of Waters' clock hall, flooded and stopped. Everything in it
   is about freezing things, and each kind of thing frozen is useful in its own way. The one rule: **rising water
   freezes where it first meets the cold.**
   1. *The Cold Stair.* Two pools of black water, far too cold to swim. `Ice · Freeze` on the Brink Cube (its
      direction is carved) freezes the first pool's top into a floor for a few breaths: hop the cube, walk across.
      On the island, the Long tablet: Long on the Island Cube freezes all but the last stretch of the long second
      pool (a normal freeze reaches well under half); run along the ice and jump the rest.
   2. *The Ice Door.* A plug of old ice fills the doorway to the hall. Her own fire melts it; the Warden's cube,
      hers to carry, waits behind it.
   3. *The Gatekeeper.* A slime shut in a cell under an iron grate sits on a plate that wants stone. Frozen, a
      creature is as heavy as stone, and cold sinks through iron bars: the cube on the grate, `Ice · Freeze ·
      Down`, two seconds on the plate, and the Clock Gate up on the walkway is open for good.
   4. *The Fountain Court.* Five fountains leap and fall; frozen, a fountain is a pillar. The Fountain Cube hangs
      high above them, worked from a lectern on the floor (Ice and Freeze carved). Straight down it freezes two
      jets low and useless. **Down-Right** (the court's tablet) and Long lay the cold aslant across all five:
      each leap freezes where it meets the cold's slanted edge, a stair of pillars up to the walkway (without
      Long only the two tallest). It holds a few breaths: climb quickly, with the cube.
   5. *The Tide Clock.* A glass column the tide fills and empties every twelve seconds, a brass float riding it.
      The clock strikes only when the float is *held* at the hour mark at the top, and its strike opens the
      Sluice Door. Cold across the column stops the tide short; the cold must lie just above the mark. Along the
      walkway, through the Clock Gate and up three steps to the clock gallery, level with the clock's top: the
      cube there, `Ice · Freeze · Left`, switched on as the tide starts to rise. (Large makes the cold taller and
      the tide freezes a stride short; the room says how far short. From the walkway the steps block the cold.)
   6. Down the steps, along the walkway, down to the floor and through the open Sluice Door.
   Three optional ledger pages (a shelf over the island, the top of the Fountain Cube, the clock gallery's
   corner). Five hint stones, three stages each. The scripted route takes 63 s of game time when it knows every
   answer (the Cold Forge's takes 113). Design estimate for a first-time player: about 20 to 30 minutes; it needs
   a human playtest to confirm.
2. **The Great Sluice** (built; made simpler and clearer on 2026-10-07; it ends the wing for now). The Warden's
   sluice works, which fed every water clock in the Cistern. The Warden drowned the Tide Bell in its well, so the
   Hush would not hear it, and set the Great Sluice that drains it on a weigh pan. Here she learns **Persist**, the
   cold that never lets go (the Warden carved it for Ilse, the winter before the Hush), and uses it three times.
   1. *The Silence Gallery.* A slime in a cell under a grate holds a plate that opens the Silence Gate only after
      it has been held eight seconds; a freeze lets go after six. The tablet by the door teaches Persist; on the
      Keeper Cube over the grate (`Ice · Freeze · Down · Persist`, free: the dungeon feeds it) the slime stays
      frozen and the gate opens for good.
   2. *The Tide Hall.* An eighteen-tile basin set with iron teeth. Its tide fills it, stands, empties and rests,
      over and over; while the water is up the doorway gates are shut. The Tide Lever, a cube over the west doorway
      fed by the dungeon and worked from a lectern, freezes the whole tide into a floor of ice: switched on while
      the hall is dry, the rising tide freezes level with the doorways. Its own freeze lets go after six seconds,
      too soon to cross: with Persist it holds while she walks across, hops the low pier and takes the Sluice Cube.
   3. *The Weigh House.* The Great Sluice's pan wants two weights of stone; two slimes hop about on it, too light
      alive. The Sluice Cube in the socket at the pan's end (`Ice · Freeze · Right · Persist`, free on the socket)
      freezes them as they hop into its cold. Held a moment, the sluice opens for good and the well drains.
   4. Up the lift, along the High Walk, down into the drained well, and the Tide Bell.
   Three optional ledger pages: iv on a high shelf in the gallery (a charged jump); v washed out past the sluice gate;
   vi on the far pier, where Wren once dared the Warden to freeze the sea (from the high ledge over the hall, the tide
   frozen on its way down a little under the pier's top; a lectern on the pier brings her down onto the next tide
   frozen at the doorways). Five hint stones, two kindle flames, three candles. The scripted route takes 97 s of game
   time when it knows every answer (the Still Water's takes 63). Design estimate for a first-time player: about 25
   to 40 minutes; it needs a human playtest to confirm.
3. **The Jellies.** Brine Jellies float at tide level and sting. Freeze one as a moving platform (its drift is the
   timing puzzle), or pop one with fire for a three-second steam updraft to reach a ledge no platform reaches.
4. **The Long Bridge.** `Ice · Bridge · Right · Long` with Persist costs upkeep every second. She must budget mana:
   the room is longer than her mana lasts, so she needs the mid-room Kindle flame, and a cube already off.
- **Boss: Mere, the Cistern Leviathan.** Phase 1: freeze footholds before the tide takes them. Phase 2: freeze Mere
  mid-leap with Persist for a walkway (watch upkeep). Phase 3: span its jaws with a Long bridge, then melt its gill
  seal so it coughs up the Tide Bell's clapper.

**Ends.** The Tide Bell rings. Water runs again through every channel and drains away; for a moment the dome
echoes. New words: Ice, Freeze, Long, Persist, Down-Right. (She now holds three quarters of the Hush's own sentence.)

---

## Between 2 and 3: Echidna hears the Hush's sentence

A lore card: her notebook. She writes ICE · FREEZE · SELF · PERSIST and sees she can now cast *two of the four
words* herself. This is the story's quiet scare: she could cast the Hush. Then, on the Landing wall in chalk:
*"Don't use the last one. —W"*.

---

## Chapter 3 · The Lampworks (light)

**Story.** Reading halls and mirrors. The Watchers walk here, and they are the monks: half-frozen, still doing
the work the Hush interrupted. A Lamplighter's ledger: *"We lit lamps so no one would stay in the dark. We did not
think of the ones who would not leave the light."* The wing's bell is the **Lamp Bell**.

**Rough playthrough**
1. **The Hall of Lamps** (built 2026-10-08; it replaced the short Dark Reading Room). The reading halls where the
   Choir read the sky by lamplight. The Lamplighter put the lamps out the night Ilse went down to the Eye, and the
   monks who walk the dark now are the Watchers: light does not hurt them, it holds them still. One long room in
   five parts; each teaches one thing about light and ends with a lamp lit, which opens the way on. Three small
   lamps over the Lamp Door light up as she goes, one for each part. No timing anywhere: every light stays on while
   its cube or its fire does.
   1. *The Reading Room.* Light and Beam on the Reading Cube: the beam crosses a spiked pit, wakes a crystal, and a
      bridge of light forms.
   2. *The Mirror Gallery.* The Gallery Cube's beam is on from the start and stops at the first mirror. With
      **Bounce** it turns at mirrors; three mirrors, each turned from a wheel on the floor, carry it up, across and
      down onto the Gallery Lamp's crystal.
   3. *The Watchers' Walk.* **Glow** and **Self**. A Watcher patrols over a heavy plate that wants stone. The Watch
      Cube glowing in the plate's socket holds him there as stone and the Monks' Gate opens for good. A Watcher stops
      where the light begins, so a Large glow stops him short of the plate.
   4. *The Watch Lamp.* A second Watcher paces under a dark brazier beside a ledge too high to jump to. Her fire
      lights the brazier, its light holds him, and from his back a charged jump takes her and the cube up to the
      socket by the lamp's crystal. (The cube can't do both jobs: it can't be carried while it shines.)
   5. *The Dark Stacks.* A walkway over a spiked chasm, under a low vault, that is there only where light reaches
      it. Fire lights the brazier over the edge; the cube glowing on the pillar in the middle lights the stones round
      it; from the last of them her fire reaches the Stacks Lamp over the far side. Plain, a running jump crosses the
      dark between; Large leaves only a hop. Without the cube's light even her longest jump falls short under the
      vault.
   6. *The Great Lamp.* The Door Cube's beam can go any way, but only **Up-Left** reaches the Great Lamp's crystal.
      The Great Lamp burns and the Lamp Door opens.
   Three optional ledger pages (the Lamplighter's): i on a shelf by the Reading Room's door, ii on a ledge over the
   Gallery Cube (charged jumps), iii on a stone over the walkway that only a Large glow shows. Six hint stones, three
   kindle flames, four shrines; Reset Room brings her back to the last shrine she lit, not the hall's door. The
   scripted route takes 98 s of game time when it knows every answer. Design estimate for a first-time player:
   about 45 to 60 minutes; it needs a human playtest to confirm.
2. **The Mirror Walk.** A Mirror Knight reflects fireballs and beams. She bounces her *own* fireball off its shield
   into a wall switch, and it moves every five seconds.
3. **The Moth Garden.** Lampmoths fly to the brightest light and snuff braziers. She protects hers with a Glow decoy
   in the corner and keeps three braziers lit at once to open the gate.
4. **The Carousel.** A rotating mirror deck. `Wind · Burst · Self · Repeat` spins it on a beat; she has to Bounce a
   beam through three mirrors facing three different ways, and then freeze the deck while the beam is still on.
5. **Two Watchers.** Turn both to stone in the right order and use one as a step and the other as a weight on a
   plate, while a third wanders between them.
6. **The Lamp Stair.** (Built for now as the wing's short second room: a glow cube carried under a high crystal,
   Large, and the Lamp Bell.) Planned: hidden platforms are solid only in light; she climbs in the dark with a
   wisp she calls from bracket to bracket. A wrong bracket drops her to the start.
- **Boss: the Unblinking (the Prior).** Phase 1: Bounce a beam into each eye from the side it isn't watching.
  Phase 2: it breaks the low mirrors, so Glow cubes and the wisp light the high ones. Phase 3: a Repeat carousel
  sweeps a beam across its closing eyes. Finish with `Light · Glow · Self · Large`, and it turns to stone, freed.

**Ends.** The Prior's memory plays: Ilse, frightened, casting the freezing spell over her sleeping daughter.
The Lamp Bell rings. New words: Light, Beam, Glow, Self, Bounce, Up-Left.

---

## Between 3 and 4: Ilse's reason

The memory, from Ilse's side, in faded colour while the lullaby plays: Wren asleep, the healers gone, the
candle low. Ilse could not bear to wait for the morning; she sang the four notes one last time and then wrote
the sentence. On the Landing: *"Ilse was not a villain. She was a mother who would not let go."*

---

## Chapter 4 · The Folded Galleries (space)

**Story.** Rooms stored inside rooms; the Choir's archive. Wren speaks for the first time, through a portal:
*"Mum won't let go. Please."* The wing's bell is the **Fold Bell**.

**Built (2026-10-08): two long rooms, the wing designed for about two hours.** A portal is a doorway by the
cube and another one on in the same direction (224 px; Long 358), through rock and shut doors; whatever goes
in one side comes out the other moving as it was (fire too). An Echo follows the exact path recorded, through
a doorway even after it has gone.
1. **The Folded Archive.** The Archivist folded the Choir's archive of the sky away from the Hush: shelves in
   rooms nobody can walk to, doors into walls.
   1. *The Sealed Door.* The Archive's door is frozen shut, rock behind it. Space and Portal on the Door Cube:
      hop over it into its doorway, out beyond the rock.
   2. *The Tall Stacks.* The lever that opens the way is on a shelf 196 px up. The Archive Cube in the socket
      under it, Portal Up: the far doorway hangs in the air over the shelf.
   3. *The Sealed Reading Room.* The Reading Gate is open only while the plate in a sealed pocket overhead is
      pressed; the only way in is the Archive Cube's doorway Up. An Echo recorded jumping in stays on the plate
      while she walks through. (Once she is through, the gate stays open.)
   4. *The Pillar.* Rock from floor to roof. Right comes out in a hollow inside it, on the plate that holds the
      gate beyond; Long goes all the way through. Record an Echo hopping into the hollow, rewrite the cube to
      Long, go through: the Echo still goes into the hollow and holds the gate.
   5. *The Hearth.* The brazier that opens the Archive Door is shut in a hearth in the wall. The Hearth Cube's
      doorway Right hangs in the air; fire thrown straight up through it comes out in the hearth, still flying
      up, into the brazier.
   Three Archivist's ledger pages (a shelf over the far doorway behind the sealed door, a top shelf over the
   stacks that only Long Up reaches, the pillar's hollow).
2. **Wren's Test.** Wren left a test for whoever came after her: four lock cubes, half a sentence on each in
   her chalk, for Echidna to finish. Each lights one of four seals on Wren's door (fire, ice, space, light).
   1. *Again (Repeat).* The way on is a ledge 324 px up. The Ember Lift rises only while the brazier in a
      chimney over the Ember Lock burns, and it burns two seconds. Wren wrote Fire, Projectile, Up: Repeat
      keeps it burning, and the lift carries her all the way.
   2. *Aslant (Down-Left).* Five leaping fountains (the Cistern's, mirrored) under Wren's Frost Lock (Ice,
      Freeze, Long): Down-Left lays the cold aslant across all five, a stair of ice for a few breaths up to the
      walkway and the seal.
   3. *Two Hearths.* Two braziers in two hearths, each reached by fire thrown up through a doorway, 448 px
      apart; the seal wants both at once and each burns two seconds. An Echo throws at one while she throws at
      the other.
   4. *The Last Crystal.* Wren's Lens Lock (Light, Beam, Right) needs Bounce and three mirrors; the last
      mirror's wheel is in a sealed pocket, reached through the Pocket Cube's doorway Up.
   5. *Wren's Door.* With all four seals lit it opens. Wren is there: "You came all this way. Mum said nobody
      would." She asks Echidna to make it end ("Mum won't let go. Please.", "I want it to end. I just don't
      want Mum to be alone."), and the Fold Bell is hers to ring.
   Two more pages (on top of the Frost Lock; in the Last Crystal's pocket).
   Scripted routes (knowing every answer): the Archive 61 s, Wren's Test 112 s (30 s of it Wren talking), the
   whole wing 188 s. Design estimate for a first-time player: about 1.5 to 2 hours for the wing; it needs a
   human playtest to confirm.

**Rough playthrough (the first plan, kept for reference)**
1. **The First Door.** Portals keep your momentum. She flings herself across a gap she can't jump, then pulls
   herself back with a second portal on the far wall.
2. **Two Rooms.** An Echo goes through a portal and stands in the other room while she holds a plate here. The
   Echo has to be recorded *before* the portal exists, then released.
3. **The Archive.** Hushlings blank one word on a cube. She keeps her sentence intact by lighting them away, and
   rewrites a blanked word under pressure with the door shutting.
4. **Carry the Flame.** Send fire and a beam through a portal to reach the unreachable brazier and lens, in two
   different rooms, with a single cube.
5. **The Sorting Hall.** The first true everything room: five essences, four small tasks, one cube per task, and
   one portal she can only place once. The tasks must be done in the order the room's lamps say.
6. **The Folded Room.** A room that is also its own lock. She solves it from inside and outside at once by
   standing in one half while her Echo works the other half.
- **Boss: Wren's Test.** Not a fight. Wren writes half a sentence on each of four lock cubes (opposites, borrowed words,
  a portal, an Echo) and Echidna finishes each. At the end Wren takes her hand and says what she wants.

**Ends.** The Fold Bell rings. Wren: *"I want it to end. I just don't want Mum to be alone."*
New words: Space, Portal, Repeat, Down-Left. All four bells now hang lit on the Landing.

---

## Between 4 and 5: the Eye opens

The four bell-lights on the Landing join into one beam of light that opens the last door. Nan sits alone on her
porch humming four notes, the same four she hummed when Echidna came to the cottage. Then Echidna goes down a
stair into the dark, past the vast folded wing of something breathing.

---

## Chapter 5 · The Eye (the ending)

**As built (2026-10-08): one dark chamber, staged like the reels** (`build_eye()` in `tools/build_wings.gd`,
`scripts/story/eye_scene.gd`). The camera draws back. The held moment hangs over the great cube as a vast pale moth,
wings of frozen night, breathing; four chains run from it to the floor round the cube, their plates marked ICE,
FREEZE, SELF and PERSIST. Snow hangs in the air and does not fall. Ilse kneels at the head of Wren's bed holding
her hand, by the candle; the room is dark but for the door's torch, the candle and the moth's own cold light.
- **Wren comes in with Echidna.** At the door: *"This is my room. It's still the same night."* ... *"The words are
  on the big cube. I drew them for you, on the stone."* ... *"Don't be scared. I'm not."* Then she walks with
  Echidna to the cube.
- **Ilse pleads** when Echidna nears the cube (the camera leans toward her): *"Please. Don't. She'll wake in the
  morning."* / *"I'll be here when she does. I promised her."* Wren: *"It's been morning for sixty years, Mum."*
  Echidna thinks: *"Nan's forgetting me. If I held her still, she never would."* Wren: *"That's what Mum did.
  Look at her."*
- **The clues, no spoilers:** over the door, *"What cannot be kept can be sent."*; Wren's chalk on the plinth: a
  star, and one line drawn straight up from it, on and on. The hint stone points at these two and names the two
  sentences only at its last stage.
- **A wrong sentence** gets Wren's answer instead of a system message (*"That's a spell. It isn't the one."*).
  The Rewritten Sky: Wren says *"Thank you."*, Ilse looks up, the chains break and the moth begins to warm
  before the pictures. The Stillness: *"Echidna... no."* Coming back from the Stillness, Wren says *"You came
  back."* and *"Holding on isn't the same as keeping someone."*

**The older rough plan** (kept for reference; not built):
1. **The Hush Storm.** Hushlings pour in and blank her words. She keeps a `Light · Glow · Self · Large` running while she
   reroutes the dome's breath-lines to wake four lock pedestals. (Unlocks the Modifier slot.)
2. **The Choir.** Ilse wakes the Stone Choristers. Turn them to stone as platforms and open the shutters with a Bounce
   beam. (Unlocks Direction.)
3. **The Tug of Words.** Ilse rewrites the cube every few seconds. Echidna records an Echo editing one slot while she
   edits another. (Unlocks Essence and Action.)
4. **The Choice.** The rune screen opens on the great cube.

---

## The ending

Echidna writes on the great cube. Two sentences are answered; anything else gets Wren's reply.

- **The Stillness** (`Ice · Freeze · Self · Large`): Echidna's temptation, to hold Nan still so she never
  forgets again. Three almost grey pictures: Lowbell stopped, Nan stopped mid-word (*"Echi..."*), and Wren:
  *"That's what Mum did."* It leads back to the cube.
- **The Rewritten Sky** (`Light · Beam · Up · Long`): the chains break, the moth fills with light, Wren comes to
  her mother (*"I'm awake, Mum. It's morning."* / *"Come with me. You won't be alone."*), the candle goes out and
  Ilse lets go; two new stars rise side by side where the dark gap was; the Hush thaws and the snow falls; Nan
  says **"Echidna."**; and the promise from the cottage is kept: *"Then I'll tell you again. As many times as it
  takes."* The last shot is the mountain under the two stars, then THE END.

The clues were there the whole way: Wren's chalk stars (*"if you get lost, look up"*, on the Landing), her chalk
on the plinth (a star, a line straight up, on and on), the words over the Eye's door *"What cannot be kept can
be sent"*, and every word of the answer learned by the end of the Lampworks.

---

## The map arrows (done in the game now)

Arrows chalked on the walls, the Choir's **waymarks**, now sit along the whole Passage, in all 17 rooms of the
Belfry and the Observatory, in the wings, and on the way through Lowbell to Nan's door: one soon after the way in,
one in the middle of a long room, one before the way out, and up arrows where the way on is a column of air. They
are pale pixel-art chalk with only a faint light, so they blend into the stone (they were glowing slabs, which
looked like part of the interface), and they are hidden when guidance is off. In the lore Wren chalked them for
whoever comes after her (the same chalk as her steps and stars), so they belong to the dungeon and not the
interface.

---

## Status: the rough loop is in the game (2026-10-02)

A first rough version of this playthrough is playable from the end of the Observatory to both endings: the
Landing, four wings of two rooms each (a bell at the end of every wing), the Eye and the two endings, with the
story pictures between. Every room is solved by an automated test. The rooms are simpler than the ones above
(no bosses, no new creatures, one idea each), and the puzzles still need tuning toward the harder versions in
this document. Details: `docs/IMPLEMENTATION_PROGRESS.md`, "The rough game loop after the Novices' Way".
