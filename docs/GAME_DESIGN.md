# THE UNWRITTEN SKY — Game Design Document

*Working title. "The Sealed Belfry" stays as the name of the first region.*

*Written 29 Sep 2026. The rune mechanics are as built (`scripts/runes/`, `docs/RUNE_SYSTEM_PROGRESS.md`);
every sentence named here is one the game accepts today, except the optional secret essence in §12.
Plan for a 2-person team submitting to the Congressional App Contest on 20 Oct 2026 (§13).*

## 0. One page

**Logline.** Beneath a village that is going quiet, a young witch learns the forgotten language the
world is written in, and must decide what to do with the last sentence anyone ever wrote in it.

**Central identity.** *Learn a forgotten magical language and use it to manipulate reality.*

**The grammar (unchanged).** A rune cube holds one sentence of four words:

| Slot | Grammar role | Words (33) |
|---|---|---|
| Essence | the noun: what substance | Wind, Fire, Ice, Light, Space |
| Action (called *Form* in the build) | the verb: what it does | Push, Lift, Burst, Projectile, Freeze, Bridge, Beam, Glow, Portal |
| Direction | where | Right, Left, Up, Down, Up-Right, Up-Left, Down-Right, Down-Left, Self |
| Modifier | how | Normal, Strong, Long, Large, Persist, Delay, Repeat, Bounce, Split, Explode |

Written here as `Wind · Push · Right · Strong`.

**Pillars.**
1. **The language is the game.** Every room, enemy, boss, secret and story beat is expressed as a sentence.
2. **Knowledge opens doors, not keys.** The world grows more readable as you learn; the right sentence is always the key.
3. **One new word, one new idea.** A room teaches one thing alone, then combines it with what you know.
4. **Kind to experiment.** Resets are instant, mana never soft-locks, a wrong sentence is refused with a reason and costs nothing.
5. **Silence is the enemy.** The antagonist force is literal quiet; sound, light and names are life.

**Where the touchstones show.**

| Game | What we take |
|---|---|
| Portal | Clean test rooms, one idea each; a friendly voice that turns out to have an agenda; momentum through portals (already built). |
| The Talos Principle | A voice from above guiding you to "collect everything"; a mysterious other traveller leaving messages; an ending that is a choice about the rules themselves. |
| Tunic | An in-world instruction manual written in a script you can't read yet; words translate on screen as you learn them. |
| Outer Wilds | Some doors are gated by understanding, not items: deduce a sentence from murals and you can open it early. |
| Zelda dungeons | Themed regions, each with a new essence, a mini-boss and a boss that tests it; a hub that grows. |

**Length.** Full game about 6–7 hours (9–10 for everything). Contest build about 60–75 minutes (§13).

---

## 1. Core narrative

### The world
**Lowbell** is a small valley village of bells and wind-chimes. Beneath it, cut into the mountain,
lies **Aster Deep**: the monastery, forges, cisterns, reading halls and observatory of the
**Choir of Aster**.

### What the rune language is
The Choir discovered that the night sky is a **text**. Every star is a word in the **First Tongue**;
every constellation is a sentence that keeps one of the world's laws running. The east wind blows
because `Wind · Push · Right · Large` is written in the eastern sky. Rivers freeze in winter because
a winter constellation says so.

The Choir read the sky through the **Eye**, a great lens at the bottom of Aster Deep, and learned to
write small, *local* sentences of their own, carved in stone: **verse-stones**, the rune cubes. A
sentence only takes effect when all four words are present and it is given **breath** (mana),
either the writer's own or the dungeon's, carried through violet **breath-lines** (the channels and
pedestals already in the game).

The metaphor players will feel without being told: runes are **instructions**. Well-formed ones
run; malformed ones are refused; a loop with no way out runs forever.

### Who built it, and what they built
The Choir was founded by **High Cantor Ilse Aster**, astronomer and linguist. Each wing of Aster
Deep served the language:
- **The Belfry**: bells ring the *Waking Tone*; sound keeps words awake.
- **The Kilnworks**: forges where verse-stones were fired.
- **The Drowned Cistern**: water clocks that measured the turning sky.
- **The Lampworks**: reading halls, mirrors and lamplighters (the wisps) that carried light to readers.
- **The Folded Galleries**: rooms stored inside rooms with Space, where the Choir kept its archive.
- **The Eye**: the observatory, where the sky was read and the greatest sentences written.

### The Last Sentence (the secret at the centre)
Ilse's daughter **Wren** fell gravely ill. Ilse carved one sentence on the great cube beneath the
Eye and fed it the breath of the whole dungeon:

> **`Ice · Freeze · Self · Persist`**: hold this moment still, around itself, for as long as it is given breath.

It worked. Wren did not die. Nothing in the Eye did. But the dungeon's breath never runs out, so
the sentence never stops, and a moment held forever is a moment no one ever speaks of again. The
stillness began, very slowly, to **forget**. It spread outward as **the Hush**: first sound, then
colour, then words, then names.

The Choristers caught at its edge were half-held. They became the **Watchers**: they move in
darkness, walking their last task, and turn to stone the moment holy light "reads" them (exactly
how they already behave in the game).

### Why the dungeon was sealed
The survivors, the **Bell Order** led by the young glasswright **Brother Aldous**, learned that the
great bell's Waking Tone pushes the Hush back. They did three things:
1. They rang the bell every day, for sixty years.
2. They broke the First Tongue into fragments and hid them in trials across Aster Deep, so no one
   could reach the great cube and change the sentence, whether to finish it or unmake it. They
   feared both.
3. They sealed the Eye, and later the Belfry.

Nine years ago the last Bellkeeper, **Tobiah Rook**, rang the bell a final time and it cracked. The
monks sealed the Belfry and fled (the existing intro and Ledger pages still hold true). Since then
the Hush has crept upward.

### What happened to the civilisation
- The Choir's **voice** survived in Lowbell: its families became the village witches, who kept one
  spell, **Echo** (hear your own voice return). Echidna's grandmother **Nan Morrow** is one of them.
- The Choir's **ink** became the Bellbound slimes: living ink escaped from the scriptorium vats. It
  follows bells because the Choir wrote to their ringing ("Some say they think the bell is their
  mother": Ledger ii).
- The Choir's **lamplighters** became the Lantern Wisps: still doing their job, still not liking to
  be hurried (Ledger vi).
- The **Choristers** are the Watchers.

### Why the player enters
The Hush has reached Lowbell. The chimes are silent, the colours are going grey, and people are
losing words. In the opening minute Nan, Echidna's grandmother and teacher, cannot remember
Echidna's name. She presses her lantern into Echidna's hands:
*"The bell. Somebody has to ring the bell."*

### The final mystery (asked early, answered late)
1. **What is the Hush?** A sentence that is still running.
2. **Who is the Masked Scribe**, the girl in the paper mask who is always one room ahead,
   stealing fragments and leaving chalk messages? **Wren**, still inside her mother's sentence: an
   echo who cannot end. She has been testing Echidna, making her strong enough to change it.
3. **Whose is the warm voice in the Orrery** that praises Echidna and urges her to "gather every
   word"? **Ilse**, frozen at the heart of the Eye. She needs a living witch's breath to widen the
   sentence from `Persist` to **`Large`**, so the stillness covers the whole world and no one ever
   loses anyone again.

### What the ending reveals
The language is not a set of commands; it is a **conversation**. The sky is a sentence everyone
keeps saying together. Echidna doesn't delete the Last Sentence; she **rewrites** it, word by word,
into `Light · Beam · Up · Long`: the held moment becomes light sent up into the empty sky, and Wren
becomes the **first new star in sixty years**. Ilse lets go. The Hush thaws. Names come back. In the
last shot, Nan says Echidna's name.

### Themes
- **Learning a language is gaining agency.** Every new word is a new verb for the player.
- **Grief and letting go.** `Persist` is love refusing change; `Long` is love that reaches.
- **Instructions have consequences.** A perfect sentence with the wrong intent is a loop with no exit.
- **Memory.** Echo is Echidna's inheritance: the Choir could write; only its descendants can remember.

### How the story is told (almost no cutscenes)
Only three short in-engine moments: the opening with Nan (about 40 s), the reveal in the Folded
Galleries (about 60 s), the ending (about 90 s). Everything else is found:
- **Inscriptions** that translate as you learn words.
- **Rune Memories:** ghostly replays of the Choir's last days (built on the Echo replay tech).
- **Primer pages** (the Choir's illustrated handbook) and the **Bellkeeper's Ledger**.
- **NPC dialogue with gaps:** Hushed words show as glyphs until you learn them.
- The **Scribe's chalk messages**.

### Timeline

| When | Event |
|---|---|
| ~300 years ago | The Choir of Aster reads the sky through the Eye |
| 60 years ago | Ilse writes the Last Sentence; the Hush begins; the Bell Order seals the Eye |
| 60–9 years ago | The Bellkeepers ring the Waking Tone daily |
| 9 years ago | The bell cracks; the Belfry is sealed; the monks flee |
| Now | The Hush reaches Lowbell; Nan forgets Echidna's name |

---

## 2. Opening sequence (the first 15–20 minutes)

> **Built so far (30 Sep):** before Lowbell, New Game plays an illustrated story in nine
> animated pictures (the written sky, the Choir and the Eye, Ilse and Wren, the Last Sentence,
> the Hush spreading, the bell, its cracking, Lowbell). Lowbell is playable up to Nan's door:
> the camera comes down from the monastery, Echidna steps out, and villagers with glyph-gapped
> lines line the lane. Nan's cottage now has a conversation and lantern handoff. The
> pilgrim road has a bridge winch, ruined steps, the sealed Belfry door and an eastern well.
> The well passage has two flame-sharing lamps, a light ward, safe return steps and landing
> checkpoints before the existing tutorial. A three-picture bell aftermath connects the
> Belfry to the Observatory. The cottage's proposed Echo lesson remains in the original
> tutorial; the wider chapter plan below is still a design, not implemented content.

The goal: an emotional hook in the first minute, the mechanic's "aha" by minute 10, a mystery by
minute 15, and a clear goal by minute 20.

| Time | Where | What happens | Hook |
|---|---|---|---|
| 0:00 | Title | A night sky with no stars; one star flickers and goes out. *New Game*. | Mystery |
| 0:30 | **Lowbell at dusk** | A grey village. The chimes swing without a sound. Villagers' speech bubbles have glyph-shaped gaps ("Have you seen my ▢▢▢?"). Walk and jump over a fence. | The Hush is visible |
| 1:30 | **Nan's cottage** | Nan by the fire: *"There you are, my... my... I know it."* Three lines, no cutscene. She gives Echidna her lantern. | Emotional hook |
| 2:30 | **Nan's garden** | Nan teaches **Echo** ("our family's voice"): record yourself holding the garden gate's lever, then walk through while your Echo holds it. | First "I did it" |
| 3:30 | **The Belfry door** | Sealed with a rune seal Echidna can't read yet. The only way in is down the old well. | Curiosity |
| 4:00–10:00 | **The Undercroft** (5 short rooms, today's tutorial compressed) | Lantern; sprint; charged jump; spikes and candles; fireball lights a brazier; a Watcher glimpsed in the dark, frozen in a shaft of light; the first Ledger page. **Wick** the wisp flees, then follows once Echidna lights its perch. | Wick (warmth) |
| 10:00 | **The Broken Inscription** (today's Ch2 R1) | **First rune discovery.** A cube reads `Wind · Push · ▢ · Normal`; its direction is broken. Reading the tablet plays the **Glyph Bloom**: every *Right* glyph on screen lights up and translates. Write *Right*: the wind slides a crate onto a plate. | The core "aha" |
| 13:00 | **Too Heavy for One** (today's Ch2 R2) | **First real puzzle:** two winds add up. On a far ledge, **the Masked Scribe** takes a tablet before Echidna can reach it and leaves chalk: "▢▢▢ ▢▢▢" (it later reads "TOO SLOW"). | The rival |
| 16:00 | **The Scriptorium gate** | **First NPC: Brother Aldous**, half his words lost: *"The ▢▢▢ must be... rung. Four... four bells."* He gives the **Reading Lamp** (inscriptions near you translate the words you know) and the first goal. | Clear goal |
| 18:00 | **The Scriptorium** (hub) | Dark, silent, safe. Objective card: **Ring the Great Bell.** | Home base |

Rules for the opening: no text box longer than two lines, the first rune by minute 10 (by
minute 5 in the contest build), and never more than 90 seconds without Echidna doing something new.

---

## 3. World structure

```
                 LOWBELL (surface, prologue and interludes)
                        |
          THE BELFRY · the Sounding Stair (Region 1, Wind)
                        |
                THE SCRIPTORIUM (hub)
             /          |           \
   THE KILNWORKS   (either order)   THE DROWNED CISTERN
      (Fire)                           (Ice)
             \                      /
              THE LAMPWORKS (Light) -- needs a Fire+Ice sentence to enter
                        |
          THE FOLDED GALLERIES (Space)
                        |
          THE EYE OF ASTER (finale)
```

**Progression: semi-linear, hub and spoke, with knowledge gates.**
- **Linear:** Prologue, then Region 1, then the hub. This teaches the grammar without choices getting in the way.
- **Branch:** the Kilnworks and the Cistern open together; play either first. Each ends with a bell.
- **Converge:** the Lampworks door needs a Fire Explode and an Ice Bridge together, so it tests both regions.
- **Linear finale:** the Galleries, then the Eye.
- **Metroidvania-lite:** every region shows optional places you can't reach yet (a frozen waterfall in
  Region 1 needs Fire; a mirror alcove in the Kilnworks needs Light; portal ledges everywhere need
  Space). They are optional, never required.
- **Outer Wilds-style shortcuts:** some gates can be opened early by a player who deduces the
  sentence from murals and already knows the words.
- **Travel:** one-way shortcut gates inside each region (as in today's Room 5/6), and **Bell Shrines**
  for fast travel from the hub's Orrery.

| Region | Essence | Look and sound | Introduces | Reuses today's |
|---|---|---|---|---|
| Lowbell | none | Grey dusk village; colour returns bell by bell | Walking, Echo, the Hush | New (small) |
| The Undercroft | none | Dark cells, candles | Movement, hazards, fireball, wisps | Tutorial lessons |
| **1 · The Sounding Stair** | Wind | Bronze, rope, cold blue; hollow bell tones | Wind physics, updrafts, bursts, pedestals, bells and slimes, Echo with runes | Ch1 R1, R2, R8, R9; Ch2 R1–R3 |
| Scriptorium (hub) | none | Candlelit cloister, card-catalogue stacks | Journal, practice, upgrades | New (one room first) |
| **2 · The Kilnworks** | Fire | Forge amber, chains, soot; bellows rhythm | Bolts, splitting, timing, explosions, burning | Ch1 R5, Ch2 R4, Ch2 R8 |
| **3 · The Drowned Cistern** | Ice | Teal water halls, water clocks, puddles | Freezing water and creatures, bridges, Persist upkeep, tides | Ch2 R5; puddle tech |
| **4 · The Lampworks** | Light | Gold and violet reading halls, mirrors | Beams, bounce, glow, self, watchers as tools | Ch1 R3, R4, R6, R7; Ch2 R6 |
| **5 · The Folded Galleries** | Space | Impossible galleries, star-painted walls | Portals with momentum, combining everything | Ch2 R7, R8 |
| **The Eye of Aster** | all | A dome frozen mid-moment: snow hanging in the air, a bell note visible as a ring | Editing the world's sentence | Ch2 observatory seal (reworked) |

**How areas teach.** Every region runs the same arc:
(1) the essence's first action alone → (2) its second action → (3) its modifiers →
(4) combinations with earlier essences → (5) a mini-boss using one trick → (6) the boss testing all of it.

---

## 4. Chapter breakdown

### Prologue — *The Quiet* (15–20 min)
- **Theme:** things are being forgotten.
- **Goal:** get into Aster Deep and reach the Scriptorium.
- **Words:** Wind, Push, Left, Normal (already carved on the first cube); **Right** (tablet).
- **Mechanics:** movement, lantern, fireball, heal, Echo, Reading Lamp, the rune screen, mana basics.
- **Enemies:** Bellbound slimes (harmless in their cells); one Watcher glimpsed.
- **Puzzles:** Echo holds a gate; the broken inscription; two winds add up.
- **Revelations:** the Hush takes names; someone else is down here.
- **Mini-boss / boss:** none. The prologue is about wonder.

### Chapter 1 — *The Sounding Stair* (Wind, 45–60 min)
- **Theme:** breath and voice.
- **Goal:** ring the Great Bell.
- **Words:** Lift, Up, Burst, Strong, Large.
- **Mechanics:**
  - Wind physics: mass, breakaway force, adding winds together.
  - Riding updrafts; single-shove bursts.
  - Carrying cubes; pedestals and breath-lines.
  - Bells call slimes; slimes weigh down plates.
  - Echo working with runes (your Echo stands on a plate while your wind runs).
- **Enemies:** Bellbound slimes (living weights; wind moves them); **Tollers** (bats nesting in bells that scatter at gusts, shaking loose ropes).
- **Puzzle concepts:**
  - Stacking forces; weight classes (crate, stone, statue).
  - Updraft routes; herding slimes with bells.
  - Burst timing against swinging weights; "your Echo writes half the sentence".
- **Revelations:** the Ledger (Tobiah rang for years; the bell cracked nine years ago); the Hush pools inside the bell.
- **Mini-boss:** *Mother Ink*, a huge bell-slime squatting on the master plate. Ring side bells to pull her off and wind-herd her into the vat.
- **Boss:** *The Cracked Bell* (§9).

### Chapter 2 — *The Kilnworks* (Fire, 50–70 min)
- **Theme:** making, and the heat that comes with it.
- **Goal:** relight the Kiln Heart and ring the Forge Bell.
- **Words:** Fire, Projectile, Up-Right, Down-Right, Delay, Split, Explode.
- **Mechanics:**
  - Fire bolts; braziers; bramble fuses that burn in chains.
  - Cracked walls: Explode, or momentum from a wind-driven stone (already built).
  - Pistons and conveyors carrying cubes; puddles that put fire out; heat zones.
- **Enemies:** **Emberlings** (living sparks); **Clinkers** (small kiln golems carrying coals).
- **Puzzle concepts:**
  - One bolt, three targets (Split).
  - Delayed shots timed to moving targets; the order things are destroyed in.
  - Chain reactions; fire carried on the wind.
- **Revelations:**
  - Aldous's Rune Memory: he ground the Eye's lens.
  - The **Orrery voice** speaks for the first time ("You write beautifully").
- **Mini-boss:** *The Great Bellows*, a construct that blows your fires out. Turn its own draught with Wind, then burn its intake.
- **Boss:** *The Kiln Heart* (§9).

### Chapter 3 — *The Drowned Cistern* (Ice, 50–70 min)
- **Theme:** time and stillness (the water clocks).
- **Goal:** calm the flood and ring the Tide Bell.
- **Words:** Ice, Freeze, Bridge, Down, Long, Persist.
- **Mechanics:**
  - Water surfaces freeze into platforms; tides rise and fall on a clock.
  - Ice bridges; frozen creatures weigh as much as stone (already built).
  - Fire melts ice; crates slide far on ice.
  - **Persist** upkeep against your mana.
- **Enemies:** **Brine Jellies** (float on the tide); drowned Watchers.
- **Puzzle concepts:**
  - Tide timing; persistence versus budget.
  - Sliding physics; freeze a creature to carry its weight; melt at the right moment.
- **Revelations:**
  - Every water clock stopped at the same minute.
  - A Rune Memory shows a little girl in the cistern gardens wearing a paper mask she made.
- **Mini-boss:** *The Clockwork Weir*, a sluice machine. Freeze its wheel at the right tide.
- **Boss:** *Mere, the Cistern Leviathan* (§9).

### Chapter 4 — *The Lampworks* (Light, 60–80 min)
- **Theme:** seeing and being seen.
- **Goal:** relight the Great Reading Lamp and ring the Lamp Bell.
- **Words:** Light, Beam, Glow, Up-Left, Down-Left, Self, Bounce, Repeat.
- **Mechanics:**
  - Beams, mirrors, crystals and lenses (built); Bounce off mirrors.
  - Glow auras; Self-centred effects; Repeat pulses (with Burst and Projectile).
  - Holy light turns Watchers to stone (built); wisp light makes platforms solid (built).
  - **Wick grows** and can light braziers.
- **Enemies:** Watchers at full use; **Mirror Knights**; **Lampmoths**.
- **Puzzle concepts:**
  - Routing light; herding Watchers and freezing them as platforms or weights.
  - Routes through darkness; pulse timing; mirrors that move.
- **Revelations:**
  - The Watchers are the Choir.
  - The Prior's memory reveals the exact Last Sentence: `Ice · Freeze · Self · Persist`.
- **Mini-boss:** *The Twin Watchers*: two that move only while the other is lit.
- **Boss:** *The Unblinking* (§9).

### Chapter 5 — *The Folded Galleries* (Space, 50–70 min)
- **Theme:** distance, perspective, identity.
- **Goal:** open the Eye's four locks.
- **Words:** Space, Portal. (This is a combination chapter: few new words, many new sentences.)
- **Mechanics:**
  - Portals keep your momentum (built).
  - Wind through portals; beams and fire through portals; Echo through portals.
  - Galleries whose doors lead elsewhere depending on which portal reach is running.
- **Enemies:** **Scribe-mites** (carry words between cubes); **Hushlings** in numbers.
- **Puzzle concepts:** momentum flings; carrying a sentence's effect elsewhere; archive rooms that need the whole vocabulary.
- **Revelations:**
  - The Scribe is **Wren**.
  - The Orrery voice is **Ilse**, and she wants `Large`.
- **Mini-boss:** *The Folded Room*: a room that is also its own lock. Solve it from inside and outside at once, with Echo.
- **Boss:** *The Scrivener's Duel* (§9).

### Chapter 6 — *The Eye of Aster* (finale, 40–60 min)
- **Theme:** letting go.
- **Goal:** rewrite the Last Sentence.
- **Words:** no new ones. The secret essence, *Echo*, is optional (§12).
- **Mechanics:**
  - Hush zones (mana drains unless a Glow runs).
  - Hushlings that blank out words on your cubes.
  - Editing the great locked cube.
- **Enemies:** Hushlings; singing Stone Choristers.
- **Boss:** *The Last Sentence* (§9, §12).

### Progression curve

| Chapter | New words | Words known | New mechanics | Steps per main puzzle | Rooms |
|---|---|---|---|---|---|
| Prologue | 5 | 5 | 6 | 1–2 | 8 |
| 1 Wind | 5 | 10 | 5 | 2–3 | 10 + boss |
| 2 Fire | 7 | 17 | 4 | 3–4 | 10 + boss |
| 3 Ice | 6 | 23 | 4 | 3–4 | 10 + boss |
| 4 Light | 8 | 31 | 5 | 4–5 | 12 + boss |
| 5 Space | 2 | 33 | 3 | 5–6 | 10 + boss |
| 6 Eye | 0 (+1 secret) | 33 (34) | 2 | 6+ | 4 + boss |

The shape: a steep start (learn the grammar), a plateau in each region (master one essence), then
the curve turns from *learning words* to *writing sentences* in Chapters 5–6.

---

## 5. NPCs

### Brother Aldous — the guide
- **Appearance:** a very old glasswright with round spectacles (one lens silvered), a patched robe, and a small mirror strapped to his back like a shield.
- **Personality:** gentle, stubborn, funny about his own forgetting, and guilty.
- **Purpose:** guide, hints, the Reading Lamp and its upgrades.
- **Story arc:**
  1. He stayed behind when the Order fled and is half-Hushed: he has lost most nouns.
  2. As Echidna learns words, his old lines become readable (the journal keeps them, re-translated).
  3. In Chapter 2, his Rune Memory shows he ground the Eye's lens.
  4. By Chapter 4 he admits it made the Last Sentence possible.
  5. In the finale he holds the lens steady while Echidna writes.
- **Dialogue style:** warm, short, full of gaps ("Mind the ▢▢▢, child; it bites."). Never a lecture.
- **Gameplay:** optional three-tier hints (gentle → specific → solution), matching today's hint stones; Reading Lamp upgrades.

### Sister Vell — the archivist
- **Appearance:** middle-aged, ink to the elbows, a cloak sewn from index cards that rustles like moth wings.
- **Personality:** brisk, precise, dry wit, secretly terrified of the language.
- **Purpose:** keeps the Rune Journal, translates Primer pages, runs the Sentence Catalogue.
- **Story arc:**
  1. She has hidden in the archive for nine years and refuses to cast ("Words did this").
  2. She warms to Echidna's care with language.
  3. When the Hush attacks the hub, she writes her first sentence (`Light · Glow · Self · Large`) to protect the children's shelves.
- **Dialogue style:** footnotes, corrections, lists ("Three things. One: you're dripping on my floor.").
- **Gameplay:** collectible turn-ins (Primer pages → translations and hints), upgrades (Echo length, saved sentences), the catalogue of every valid sentence discovered.

### Wick — the friendly creature
- **Appearance:** a thumb-sized flame inside a glass bell, with moth wings; its glow changes colour with its mood.
- **Personality:** curious, skittish, loves bells, hates being rushed (Ledger vi).
- **Purpose:** companion light and quiet guide.
- **Story arc:**
  - Wick is the last lamplighter, looking for the Great Reading Lamp.
  - When it is relit in Chapter 4, Wick grows and can carry flame.
  - In the true ending, Wick lights the first lamp of the new constellation.
- **Dialogue style:** no words; a small bubble with one rune glyph (Light when happy, the Hush symbol when afraid).
- **Gameplay:**
  - Sent to wisp perches (built); its light makes hidden platforms solid (built).
  - It chirps near secrets and dims when the Hush is close, as a danger warning.

### The Masked Scribe (Wren) — the rival and mystery
- **Appearance:** a slight girl in a white paper mask painted with the *Persist* glyph, an ink-black cloak that frays into static, and a stylus as tall as she is.
- **Personality:** playful, cryptic, competitive, lonely.
- **Purpose:** the recurring rival who is always one room ahead.
- **Story arc:**
  1. She steals fragments first, so you must find another source (her chalk copy, a Rune Memory, a deduction).
  2. She solves rooms her own way and leaves the cubes behind as hints.
  3. She taunts, then helps.
  4. At the Chapter 5 reveal: she is Wren, held inside the sentence, testing Echidna.
  5. She asks to be let go.
- **Dialogue style:** chalk messages in rune script, often rhymes and riddles ("Two winds, one stone. Can't lift alone."). She never says her name until the reveal.
- **Gameplay:** race rooms, the duel boss, a few secret hints, and her mask (needed for the secret ending).

### The Orrery voice / High Cantor Ilse Aster — the late reveal
- **Appearance:** first only a warm voice from the brass orrery in the hub. In the finale, a tall woman of stone and starlight, half-frozen, with constellations on her robes and her face behind a lens.
- **Personality:** brilliant, grieving, persuasive; never cruel.
- **Purpose:** mentor turned antagonist (think Portal and Talos).
- **Story arc:**
  - She encourages you to gather every word and unlocks fast travel.
  - Her praise gradually becomes possessive ("Every word. Bring them all to me.").
  - Revealed in Chapter 5; faced in Chapter 6; she lets go in the true ending.
- **Dialogue style:** formal and complete. She is the language's greatest writer, the only character who never has gaps in her speech.
- **Gameplay:** fast travel, lore, and the pressure of the final choice.

### Nan Morrow — the anchor
- **Appearance:** a small, sharp-eyed hedge-witch with ash on her sleeves.
- **Purpose:** the emotional stakes.
- **Story arc:** after each bell, a letter from Nan arrives in the hub, each with more of her words back. In the ending she says Echidna's name.
- **Dialogue style:** teasing, practical, loving.

### Tobiah Rook, the last Bellkeeper (appears only in memories)
Heard through the seven Ledger pages and one Rune Memory: the man who rang the bell until it cracked.

---

## 6. Mana system design

### Kept as it is (already built and tested)
- 100 mana. Fireball 5, heal 20. Each Echo lowers the cap by 10.
- Refill with R over 2 s; refused while any of your runes draws on you.
- Regeneration of 20/s starts 1.2 s after you stop, only while none of your runes runs.
- A sustained rune needs its start cost plus 2 s of upkeep in hand.
- Running dry switches off every rune you power.
- Pedestals and breath-lines feed cubes for free; ward circles cap your mana in a room.
- Reset Room gives back the mana you entered with; leaving a room stops your runes.

### Additions
| System | Rule | Why |
|---|---|---|
| **Starwells** | A basin of starlight. Standing in one refills you instantly; a cube on its rim is fed like a pedestal. Some are dry until you solve something (light the brazier above, thaw the pipe). | A visible, fair "recharge here", and a puzzle object. |
| **Breath-line capacity** | Each breath-line carries a set amount of upkeep (shown as notches on the groove). Overload it and every cube on it goes out. | Budgeting puzzles: which cube runs on the dungeon and which on you. |
| **Resonance** | Ringing a bell doubles regeneration for 8 s and removes the refill wait. | Ties bells (voice) to breath; rewards thinking about sound. |
| **Star Charts** | Five hidden charts, each +10 to the cap at the hub Starwell (max 150). | An exploration reward that widens experimentation. |
| **Hush zones** (Chapters 5–6) | Regeneration stops and 1/s drains, unless a Glow runs nearby. | Late-game pressure that is still readable and has an answer. |
| **Saved Sentences** (QoL) | Up to four remembered sentences can be written onto a cube in one step. | Less menu time late in the game. |

### Puzzle mana management
- Early rooms teach the costs; each has a Starwell next to its door.
- Mid-game rooms mix free and personal power (today's Room 7, *The Limited Circuit*, is the model).
- Bosses force a split: part of the solution on pedestals, part on you, and timing to regenerate
  between bursts.

### Laws that prevent soft-locks (the design team never breaks these)
1. The intended solution fits in the room's cap using its own free sources plus regeneration.
2. Running dry never destroys an object or undoes progress.
3. Reset Room always returns the room and your entry mana.
4. Any room with a ward has a pedestal, breath-line or Starwell.
5. Mana never blocks the way *out* of a room.
6. Refusing an unaffordable rune costs nothing and says what it needs ("needs 16 in hand").
7. Assist: unlimited mana (built) and a "gentle mana" option (double regeneration).

---

## 7. Rune discovery system

### Sources of new words (each should feel different)
| Source | How it feels | Example |
|---|---|---|
| **Tablet** | Clear and taught: read it, learn it. | *Right*, *Lift*, *Fire* |
| **Rune Memory** | Watch a ghost of the Choir cast; reproduce the sentence once to own the word. | *Burst* (a monk shoving the bell), *Bridge* (Wren crossing) |
| **Deduction** | A mural or constellation depicts a sentence; work out the word, write it at the "word altar" to claim it. | *Up-Right* from the forge's spark diagrams |
| **Discovered by doing** | Do the thing, and the journal names it. | Stack two winds on one stone → "the Choir called this **Strong**". Watch a beam turn off a mirror → **Bounce**. |
| **Mini-boss reward** | Earned by a climax, just before the boss needs it. | *Explode* (Kilnworks), *Repeat* (Lampworks) |
| **Chalk copy** | The Scribe stole the tablet but left a copy, sometimes half wrong. | *Lift* in Chapter 1 |

### The Glyph Bloom (the signature moment)
When you learn a word, every inscription on screen containing it lights up and **translates in
place**: murals, door lintels, the Primer, Aldous's old dialogue. The world becomes readable one
word at a time. This is the single most important feel feature in the game.

### Word unlock table (all 33)
| Chapter | Critical | How |
|---|---|---|
| Prologue | Wind, Push, Left, Normal | Carved on the first cube |
| Prologue | Right | Tablet |
| 1 | Lift, Up | Scribe's chalk copy; tablet |
| 1 | Burst | Rune Memory |
| 1 | Strong | Discovered (stack two winds), tablet as backup |
| 1 | Large | Deduction ("the eastern wind is wide" mural) |
| 2 | Fire, Projectile | Tablet at the Kiln gate |
| 2 | Up-Right, Down-Right | Deduction (spark diagrams) |
| 2 | Delay | Discovered (light a fuse and wait) |
| 2 | Split | Rune Memory |
| 2 | Explode | Mini-boss |
| 3 | Ice, Freeze | Tablet |
| 3 | Down | Deduction (every water clock points down) |
| 3 | Bridge | Rune Memory (Wren crossing) |
| 3 | Long | Deduction (a bridge that falls short beside a mural of a longer one) |
| 3 | Persist | Tablet in the Cistern's deepest hall, framed as "the word that made the silence" |
| 4 | Light, Beam | Tablet |
| 4 | Glow | Wick grows and teaches it |
| 4 | Up-Left, Down-Left | Deduction (mirror angles) |
| 4 | Self | Rune Memory (the Prior) |
| 4 | Bounce | Discovered |
| 4 | Repeat | Mini-boss |
| 5 | Space, Portal | Tablet |
| Secret | **Echo** (sixth essence) | All 12 Rune Memories + Wren's mask (§12) |

### Hidden rooms, optional secrets, rewards
- **Word altars** in hidden rooms let a player claim a deduced word early (Outer Wilds-style),
  skipping part of a region.
- Every region has 3 optional rooms: 1 Echo Trial, 1 Riddle Door, 1 knowledge-gated alcove.
- **Rewards:** Primer pages, Star Charts, Rune Memories, Hymn Cylinders, lantern colours,
  Sentence Catalogue milestones (discover 20 / 40 / 60 valid sentences → hub upgrades).

---

## 8. Enemy ecosystem

Every creature is a noun the language can act on. None is only a damage sponge.

| Creature | Behaviour | Weakness | Rune interactions | Puzzle uses |
|---|---|---|---|---|
| **Bellbound Slime** (ink; built) | Wanders; hears bells and sits under them for 12 s | Fire | Wind pushes it; Freeze makes it weigh as much as stone; Portal carries it | Living plate weights; herding |
| **Watcher** (Chorister; built) | Walks in darkness, strikes up close; stone in holy light | Light | Beam or Glow freezes it into a platform or heavy weight; too heavy for Wind once stone | Stepping stones, weights, beam blockers |
| **Toller** (Chapter 1) | A bat that roosts inside bells; a gust scatters the flock, which shakes loose ropes and chains | Fire | Burst scatters them (dropping ropes you need); Glow keeps them roosting | Timing gusts to drop ropes; quiet routes past a roost |
| **Lantern Wisp** (lamplighter; built, neutral) | Goes to called perches; its light makes hidden platforms solid | none | Wind blows it along; Glow draws it; the Hush dims it | A moving light source |
| **Hushling** | A drifting patch of silence, drawn to sound and light; touching a cube **blanks one word** (Modifier first) | Light (Glow dissolves it), bells scatter it | Wind passes through it; Freeze makes a *silence crystal* | Protect your sentence; carry silence crystals to mute a bell |
| **Emberling** | A spark that seeks warmth and ignites what it touches | Water puddles | Wind blows it (light, so easy to steer); Freeze makes a warm coal block that melts ice it rests on | Living fuses; delivering fire |
| **Clinker** | A little kiln golem hauling a coal; walks set routes | Ice | Freeze stops it; Strong wind tips it over, spilling coal | Moving heat source; a timed obstacle |
| **Brine Jelly** | Floats, rising and falling with the tide; stings on contact | Fire (turns to steam) | Freeze makes a floating platform (Persist keeps it); steam acts as a short updraft | Moving platforms; a lift |
| **Mirror Knight** | Patrols with a mirror shield that reflects beams and fireballs | From behind | A Bounce beam reflects off its shield; Burst turns it around; Portal gets you behind it | A walking mirror |
| **Scribe-mite** | Tiny ink creature that moves a word from one cube to another | Freeze (catch it, get the word back) | Drawn to running cubes | Lure it to bring you the word locked in another cube |
| **Stone Chorister** (finale) | A Watcher that sings; each beat turns nearby cubes' directions | Silence it with Ice; stone it with Light | Its rotation can aim your beams for you | Timing beams to the beat |

---

## 9. Boss design (puzzles first, combat second)

Each boss: three phases, one per idea, then a finish that uses all of them. You never deplete a
health bar with fireballs; you **change the situation**.

### The Cracked Bell (Chapter 1, Wind)
- **Lore:** Tobiah's bell, cracked nine years ago. The Hush pooled inside it and it swallows sound.
- **Arena:** the belfry shaft, a tall vertical room. The bell hangs in the middle; ledges hold wind cubes on pedestals; slime cells lie below.
- **Mechanic:** the bell sends out rings of silence that knock the *Direction* word off any cube they touch, so you have to rewrite it.
- **Phases:**
  1. *Stir.* Stack winds to push counterweight crates onto the bell's rope cradle, tilting the bell to expose the clapper.
  2. *Swing.* Use Burst in time with the bell's swing, like pushing a swing. Bells call slimes; herd them onto the brake plates to hold each gain.
  3. *Toll.* Record an Echo running an updraft (`Wind · Lift · Up · Strong`) while you ride it to the clapper. At the top of the swing, strike it with a fireball.
- **Finish:** the bell rings. The Hush bursts out of it, sound floods back, and colour returns to Lowbell's banners.
- **Tests:** adding forces, mass, timing, Echo with runes, rewriting under pressure.

### The Kiln Heart (Chapter 2, Fire)
- **Lore:** the furnace golem that kept the kilns lit. The Hush chilled it; now it lurches between cold and overheating.
- **Arena:** a forge hall with three vents at different heights, conveyor pistons and cracked plates.
- **Phases:**
  1. *Cold.* Light all three vents at once with one mounted cube: `Fire · Projectile · Up · Split`.
  2. *Overheating.* Emberlings feed it. Blow them into quench puddles instead; crack its armour with a delayed Explode timed to its patrol.
  3. *Settle.* Its core drops into the floor socket. Seal it with a stone driven by `Wind · Push · Right · Strong`.
- **Finish:** the golem calms and becomes the hub Kiln (the Saved Sentences upgrade).
- **Tests:** Split, Delay, Explode, Fire with Wind, sequencing.

### Mere, the Cistern Leviathan (Chapter 3, Ice)
- **Lore:** an eel that kept the cistern clean. The Hush made it hungry for sound, and it swallowed the Tide Bell's clapper.
- **Arena:** a flooding vertical chamber; the tide rises and falls on a clock.
- **Phases:**
  1. *Rising water.* Freeze the surface into footholds (`Ice · Freeze · Down · Large`) before the tide takes them.
  2. *The leap.* When Mere jumps, freeze its body mid-arc (Freeze with Persist) to make a walkway, and manage the upkeep.
  3. *The throat.* Span the gap to its head with `Ice · Bridge · Right · Long`, then melt the frozen gill-seal with fire so it coughs up the clapper.
- **Finish:** Mere, freed of the Hush, sinks peacefully; the Tide Bell rings.
- **Tests:** freezing, Persist budget, bridges, Fire against Ice, tide timing.

### The Unblinking (Chapter 4, Light)
- **Lore:** the Prior of the Lampworks, the largest Watcher, now nothing but eyes. Where it looks, your runes stall.
- **Arena:** a mirror cathedral with rotating mirrors, crystals, hidden platforms and Wick.
- **Phases:**
  1. *Three eyes.* Route `Light · Beam · Up-Left · Bounce` through mirrors to strike each eye from the side it isn't watching.
  2. *Shattered mirrors.* It breaks the low mirrors. Send Wick and Glow cubes up to light hidden platforms and reach the high ones.
  3. *The carousel.* `Wind · Burst · Self · Repeat` spins a mirror carousel every few seconds, sweeping a beam across its closing eyes on the beat.
- **Finish:** `Light · Glow · Self · Large` on the cube it clutches. It turns fully to stone, and is freed; its memory shows the Last Sentence.
- **Tests:** light routing, Self, Repeat, Wick, working in darkness.

### The Scrivener's Duel (Chapter 5, Space)
- **Lore:** Wren guards the Eye's four locks, and she wants to see whether Echidna can out-write her.
- **Arena:** a folded gallery. Four rooms are joined by portals, and each has a lock cube you and Wren both write on.
- **Mechanic:** a duel of words, not blows. Wren rewrites your cubes; you answer. Portals carry effects between the rooms.
- **Phases:**
  1. *Mirror me.* Answer each of her sentences with its opposite (her wind pushes left, yours pushes right).
  2. *Borrowed words.* Her Scribe-mites carry words between locks. Freeze them to take the words back.
  3. *Fold.* Power all four locks at once, using Echo in one room and portals to carry a beam, a wind and a fire into the others.
- **Finish:** Wren takes off her mask. The reveal (60 s).
- **Tests:** everything, especially Space combined with the rest.

### The Last Sentence (finale) — see §12.

**Mini-bosses** (one trick each): Mother Ink, the Great Bellows, the Clockwork Weir, the Twin
Watchers, the Folded Room.

---

## 10. Collectibles and secrets

| Collectible | Count | Where | Reward |
|---|---|---|---|
| **Primer pages** | 24 | Everywhere, often hidden | Tunic-style handbook pages in rune script that translate as you learn. Hints, maps, the secret ending's clues. |
| **Rune Memories** | 12 | One or two per region, hidden or behind puzzles | Ghostly replays of the Choir's last days; lore, some words, and Choristers' names. All 12 are needed for the secret ending. |
| **Star Charts** | 5 | Optional rooms | +10 maximum mana each |
| **Bellkeeper's Ledger** | 7 | Region 1 (exists) | Tobiah's story |
| **Hymn Cylinders** | 6 | One per region | Restore a layer of the hub's music; all 6 play the Choir's hymn in the ending |
| **Choristers' Names** | 12 | Watchers' plinths and memories | Secret ending: the Watchers wake as people |

**Secret puzzles**
- **Riddle Doors:** the lintel reads half a sentence ("Fire that ▢▢▢ reaches three ways"); write the rest.
- **Constellation Locks:** a star pattern seen in one region is the sentence that opens a door in another.
- **Echo Trials:** one per region, co-op puzzles with your own Echoes (today's Choir Loft is the model).
- **Unwritten Rooms:** rooms with no floor, where you build the way across from ice and portals.
- **Word altars:** claim a deduced word early.

**Incentives:** the map marks rooms with unfound secrets (built), the journal shows *x / y* per
region, the Sentence Catalogue fills in, the hub changes visibly, and the secret ending exists.

---

## 11. Hub: the Scriptorium

**Purpose:** safety, understanding, progress, and a sense of home that changes as you succeed.

| Place | Function |
|---|---|
| **Great Lectern** | The Rune Journal: words, sentences found, notes, memories, translations |
| **Practice Hall** | A free sandbox: every known sentence on crates, stones, mirrors and dummies, costing no mana. Invaluable for experimenting. |
| **Starwell** | Refills mana; turn in Star Charts |
| **The Orrery** | Fast travel between Bell Shrines; Ilse's voice |
| **Vell's Archive** | Primer translations, collectible turn-ins, the Sentence Catalogue, Echo upgrades |
| **Aldous's Workshop** | Hints, Reading Lamp upgrades |
| **The Kiln** (after Chapter 2) | Saved Sentences |
| **Bell rope to Lowbell** | Visit Nan; see the village change |

**Upgrades**
| Upgrade | Levels | Source |
|---|---|---|
| Reading Lamp | Translate nearby → reveal hidden inscriptions → hint an unknown word's kind by colour | Aldous, Chapters 1, 2, 4 |
| Echo | 8 s → 10 s; 2 Echoes → 3 | Vell (Primer pages); all Echo Trials |
| Mana cap | 100 → 150 | Star Charts |
| Saved Sentences | 2 → 4 slots | The Kiln; catalogue milestones |

**How it changes over the game**
| After | The hub |
|---|---|
| Prologue | Dark, silent; only Aldous |
| Bell 1 | Banners regain colour; Vell emerges; first music layer; Nan's first letter |
| Kilnworks | The Kiln burns; Clinkers carry books |
| Cistern | Fountains run; a water clock ticks |
| Lampworks | Freed Choristers sing (music layers); the Orrery lights up |
| Galleries | **The Hush attacks the hub:** a defence set-piece; Vell writes her first sentence |
| Ending | It becomes a school where Lowbell's children learn the First Tongue |

---

## 12. Final act

### The region: the Eye of Aster
Three approach rooms combining everything, with Hush zones and Hushlings, lead to **the Dome**:
snow hangs motionless in the air, a bell note is visible as a frozen ring, and at the centre floats
the great cube reading `Ice · Freeze · Self · Persist`, bound to Ilse.

### Revelations, in order
1. Aldous confesses the lens.
2. Ilse speaks face to face: she asks for `Large`, to hold the whole world still ("No one will ever lose anyone again").
3. Wren asks to be let go.
4. The Hymn (if you found every cylinder) plays as Echidna writes.

### Final boss: the Last Sentence (mana ward: cap 30, pedestals ring the dome)
1. **The Hush Storm.** Hushlings pour in and blank out your cubes' words. Keep a
   `Light · Glow · Self · Large` running on a pedestal while you reroute the dome's breath-lines,
   within their capacity, to wake four lock pedestals. **Unlocks the Modifier quadrant.**
2. **The Choir.** Ilse wakes the Stone Choristers. Turn them to stone with beams to make
   platforms and heavy weights, and open the Eye's shutters with `Light · Beam · Up-Right · Bounce`.
   **Unlocks the Direction quadrant.**
3. **The Tug of Words.** Ilse rewrites the cube every few seconds. Record an Echo editing one
   quadrant while you edit another; your Echo repeats your inscription. **Unlocks the Essence and
   Action quadrants.**
4. **The Choice.** The giant rune screen opens (today's rune screen at full scale). You write the
   sentence. Any other valid sentence "answers, but isn't enough": Wren's hint, then a retry.

### Endings
| Ending | Sentence | What happens |
|---|---|---|
| **The Stillness** | `Ice · Freeze · Self · Large` (do as Ilse asks) | The whole world holds still. The credits roll in silence, with no stars. A deliberate, haunting "wrong" ending. |
| **The Rewritten Sky** (true) | `Light · Beam · Up · Long` | The held moment becomes light sent into the empty sky. Wren becomes the first new star; Wick lights the first lamp of her constellation; Ilse lets go; the Hush thaws; Nan says Echidna's name. |
| **The Remembered** (secret) | `Echo · Beam · Up · Long` | Needs the secret sixth essence **Echo**: all 12 Rune Memories plus Wren's mask, turned in at a hidden altar in the Galleries. Everyone Hushed remembers: the Watchers wake as the Choir (their names spoken), Ilse and Wren rise together, and the stars return all at once. The credits are written in runes you can now read completely. |

The secret essence is an **addition**. It accepts only this one sentence, plus a couple of
cosmetic ones in the Practice Hall.

**Epilogue.** Lowbell in full colour and full sound. The Scriptorium is a school. A new
constellation shaped like a girl with a stylus. The post-game offers the Sentence Catalogue,
missed secrets and the other endings.

---

## 13. Congressional App Contest focus (submission 20 Oct 2026, 2 people, 3 weeks)

> Check the current official rules (video length, submission form, platform notes) on the contest
> site before building the submission. Judges often form their view from the **demo video and the
> first few minutes**, so those carry the most weight.

### 13.1 What will impress judges most
1. **An idea they understand in 30 seconds:** "write a sentence, and the world obeys it". Show one
   wind changing direction in the first minute of the video.
2. **A complete story arc** (beginning, middle, end), even if short.
3. **Polish and feel** (already a strength: the menu, the lighting, the water, the sound, the
   controller support).
4. **Depth from a small system:** 33 words, thousands of sentences, emergent combinations.
5. **Craft behind the scenes:** 943 automated gameplay tests, generated levels and sound, graphics
   levels from Low to Elite, rebinding and assists. Say this in the submission text.
6. **Accessibility:** assists, reduce motion, rebinding, symbols as well as colours, and a
   no-soft-lock design.

### 13.2 Essential systems (contest build)
| System | Status now | Contest work |
|---|---|---|
| Rune cubes, rune screen, 5 essences, journal, mana laws | **Built and tested** | Reuse |
| Existing rooms (tutorial, Ch1, Ch2) | Built | **Reorder** into one continuous game |
| Prologue: Lowbell and Nan (grey village, 3 lines, Echo lesson) | New, small | Build (code-drawn village, reuse tiles and props) |
| Dialogue box with glyph gaps | New, small | Build |
| **Glyph Bloom** translation effect | New, high impact | Build |
| Hub-lite: one Scriptorium room with Aldous and Vell, the Starwell and the journal | New | Build (one room, no upgrades) |
| The Cracked Bell boss | Great Bell room exists | Rework into 3 phases |
| The Last Sentence finale plus the true ending | Observatory seal and locked slots exist | Build one dome room; the Choice uses the existing rune screen on a locked cube |
| Scribe appearances (3, scripted) | New | Build |
| Ending card, credits, title | Built | Re-skin with the new story |

### 13.3 Optional (after the contest)
Full Kilnworks, Cistern and Lampworks regions; bosses 2–5; mini-bosses; Hushlings; new creatures
(Emberlings, Jellies, Mirror Knights, Scribe-mites); Starwells and breath-line capacity; Star
Charts; Primer pages beyond a handful; Rune Memories; hub upgrades and fast travel; hub evolution;
the Stillness and Remembered endings; the Echo essence; Nan's letters.

### 13.4 What to cut first if time runs short (in this order)
1. The Scribe's third appearance.
2. Vell (Aldous alone runs the hub).
3. Phase 2 of the bell boss (keep Stir and Toll).
4. Lowbell as a walkable village (use a painted title-card scene with Nan's three lines instead).
5. The Glyph Bloom animation (keep the instant translation).

**Never cut:** the opening hook, the first rune by minute 5, one boss, the finale choice, the ending.

### 13.5 The minimum version that still feels complete: *"The Unwritten Sky: First Verse"* (60–75 min)
Lowbell (90 s) → the Undercroft (3 rooms) → **the Broken Inscription (first rune by minute 5)**
→ the Sounding Stair (wind and bell rooms) → **the Cracked Bell** → the Scriptorium (hub-lite)
→ three short wings built from existing rooms (Fire and Ice; Light and Watchers; Space)
→ the Eye (the Last Sentence choice) → the true ending.
The story is complete in miniature: Nan forgets; the Scribe appears three times; the voice speaks
only in the Eye; Wren's reveal and the choice happen in the finale.

### 13.6 Reusing what exists
| Today | Becomes |
|---|---|
| Tutorial lessons 1–6 | The Undercroft (compressed to 3–5 rooms) |
| Ch1 R1 (block and plate), R2 (bell, slime, plates) | Sounding Stair, rooms 1–2 |
| Ch2 R1 (Broken Inscription), R2 (Too Heavy), R3 (Across the Teeth) | First rune, the Scribe's first theft, updrafts |
| Ch1 R8 (Choir Loft, Echo levers), R9 (Great Bell) | Echo Trial; the Cracked Bell boss |
| Ch1 R5 (machinery), Ch2 R4 (cracked wall), Ch2 R8 fire alcove | Fire wing |
| Ch2 R5 (Frozen Crossing), the puddles | Ice wing |
| Ch1 R3 (split flame), R4 (watcher), R6 (wisp crossing), R7 (belfry seal); Ch2 R6 | Light wing |
| Ch2 R7 (limited circuit), R8 (portal balcony, observatory seal) | Space wing; the doorway to the Eye |
| Ledger pages i–vii | Unchanged, in the Sounding Stair |
| New menu, graphics levels, puddles | Unchanged |

### 13.7 Three-week schedule (A = content and writing, B = systems, UI and build)
| Dates | A | B | Milestone |
|---|---|---|---|
| 30 Sep – 6 Oct | Lock the script (≤ 1 page per character); reorder rooms in the builders; Lowbell layout | Dialogue box with glyph gaps; Glyph Bloom; hub-lite room | **6 Oct:** play from the title to the hub |
| 7 – 13 Oct | Bell boss phases; wing signage and text; the Scribe's 3 scenes | The Eye dome and the Choice; ending sequence; the Orrery voice | **13 Oct:** feature complete; full playthrough |
| 14 – 20 Oct | **Feature freeze 14 Oct.** Playtest with 5+ new players; fix | Performance on a weak laptop (Low graphics); Windows export; bug fixes | **17–18 Oct:** record the demo video. **19 Oct:** final build and text. **20 Oct:** submit early in the day |

**Every day:** keep a playable build, run the automated suites each night, and add a
`solve_rN()` test for every new or changed room.

### 13.8 Risks
| Risk | Mitigation |
|---|---|
| Too much story text | A 1-page script limit; glyph gaps do half the storytelling |
| Boss complexity | Three simple phases built from existing pieces; cut phase 2 if late |
| Late bugs | Feature freeze on 14 Oct; nightly tests; the reset rules already prevent soft-locks |
| Judges don't reach the good part | First rune by minute 5; the video opens on a wind changing direction |

### 13.9 Technical direction (for the team)
- **Levels** stay generated by the builders (`tools/build_chapter*.gd`); regions become builder files.
- **Dialogue and inscriptions** go in data files. Gaps are words the player doesn't know yet
  (`RuneManager.knows()` already answers that).
- **The Last Sentence** is a mounted rune cube with `locked_slots` (already supported), unlocking one quadrant per phase.
- **Save flags** keep today's scheme (`region.room.solved`, `rune.frag.*`, `rune.note.*`, `rune.cast.*`).
- **Performance** budget: 160 fps on the development PC on High, smooth on Low on a weak laptop.
