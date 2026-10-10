# Dark pixel art revision — 9 October 2026

This revision replaces the failed attempt’s font download; its smooth generated illustrations were never imported into the game.

## Art

Current artwork is drawn directly at native resolution by `tools/draw_dark_sprites.gd`. The retired menu portrait is kept as an unused asset; it is not referenced by the title screen. Every individual frame is at most 64×64. Animation strips exceed 64 pixels only because they hold several frames. Integer pixel fills use the surface packs’ charcoal, indigo, plum, muted teal and silver palette. No enlarged legacy NPC art, antialiasing or smooth painted source images are used.

24 sprite sets: eight standing NPCs, seated Nan, four expression portrait strips, a chained bell menu emblem, a four-frame pushing strip, four bat wingbeats, seven cottage props and Wren’s bed. Existing sprite paths were replaced to preserve scene references. Older generators no longer overwrite retired designs. Run the dark sprite tool, import PNGs, then run `tools/build_echidna_frames.gd` to rebuild the player resource.

NPCs draw at native scale in gameplay; cinematic staging keeps its authored screen heights. The pushing texture uses the player’s shared 80px presentation canvas with a padded 64px cell and the same foot pivot. UI uses the bundled Pixelify Sans font for body text and status values; IM Fell remains on storybook headings. The cottage has separate floor bays for furniture, a lantern on its tabletop, windows above furniture and herbs attached to ceiling beams.

## Gameplay and presentation

The movement tutorial has no spell shrines. The subsequent abbey entrance inscriptions explain why Echo and Fire return; the healing spring grants Heal without removing learned spells. The main story leaves through Nan’s garden for the pilgrim road and bellkeepers’ well. Mouse click completes/advances dialogue. Hint stones answer immediately. R reloads mana anywhere (player-powered active runes still enforce their upkeep restriction).

31 dedicated refill-post instances were removed from eight scenes, and level builders no longer recreate them. Puzzle braziers, checkpoint lamps and the cottage hearth remain. Signs use outlined edge captions with a transparent background; captions yield to room-title cards and messages. Loose floor props are grounded and separated by WorldLayout. MovingPlatform travel stays above intersecting masonry where a platform moves into it. Bats pursue a visible nearby player through repeated swoops with brief circling recoveries; their collision covers the body instead of their wing tips.

## Verification

Tests press actions inside Godot; they do not send desktop input or alter the real save. Headless checks verify progression, interactions, route physics and asset dimensions. Native screenshots and rendered presentation checks run on a separate Windows desktop that is never switched onto the user’s screen. Screenshot inspection is visual verification; neither screenshot capture nor headless scripting is exhaustive human playtesting.

See `docs/polish_shots/2026-10-09-dark/` and `docs/dark_sprite_contact.png`. The complete automated run passed 2,291 assertions with zero failed assertions. Native rendered presentation checks passed 111 assertions. Subsequent font changes passed 107 targeted UI assertions, another 31 pause-menu assertions, and the final polish suite passed 93 assertions. All 270 scene/script resources loaded successfully. No commit, push, branch switch or merge abort is performed.

Godot still reports ObjectDB/resource-in-use warnings during process shutdown, including four looping audio resources in the minimal startup check. These warnings remain unresolved; successful assertions and inspected screenshots are not a claim that the game has no remaining bugs or that every route has received human playtesting.

Menu portrait follow-up: replaced the lantern pose with a new 64×64 three-quarter portrait matching the in-game curled hat, brim charms, narrow pale eyes, shadow face and purple cloak.

Final menu replacement: the earlier geometric portrait has been replaced with a built-in imagegen redraw using EchidnaIdle.png as the design reference. The delivered asset is assets/sprites/story/echidna_title.png: 64×64, binary transparency, restricted to the original player sprite’s nine colours. Its native rendered menu was inspected on the isolated desktop. The art generator preserves this asset during rebuilds.

Prompt used for the built-in tool:

Reference image is the ORIGINAL CHARACTER DESIGN, a sheet of small repeated Echidna sprites. Draw ONE new main-menu sprite portrait of THIS EXACT CHARACTER, not a sheet. Authored low-resolution 64x64 pixel art, displayed with enlarged square pixels. One uniform 64x64 pixel grid; no smaller subpixels, no antialiasing, no gradients. Transparent background. Very faithful dark purple witch Echidna: long crooked floppy hat with tip curling left/down, wide slanted brim, small bright yellow buckle, tiny hanging brim cords/charms. Head/face is pitch-dark and NARROW, two slim luminous white eyes with dark separation. NO visible human skin, hair, mouth or smile. Small narrow body in charcoal cloak with flowing plum-purple flared sleeves, pointed dark shoes. Palette and proportions closely reproduce the reference, subtle purple stepped highlights and clean hand-placed clusters rather than giant flat polygons. New three-quarter standing pose facing right, head subtly tilted toward viewer, one sleeve gathered near chest and the other draped down, cloak curling in a graceful silhouette. Full character including hat and feet fills most of square while leaving transparent margins. Visually appealing refined indie gothic pixel art matching original sprite. Not a generic witch, not humanoid wizard robes, no lantern or scarf, no teal. NO background, no border, no text, no glow haze, no smooth painting or vector art. The native design must be legible as 64x64 pixels, not a detailed high-resolution drawing.

Current menu direction supersedes the portrait revisions above: Echidna is removed from the title screen. A new 64×64 cracked brass bell, bound by dark iron chains and a seal, sits on the crimson banner. Its display uses nearest filtering at integer 5× scale, without character bobbing. Native rendered menu inspected; 93 polish assertions passed. No gameplay changes, commits or pushes in this follow-up.

Final menu layout: removed the banner, side lettering, character/emblem and decorative menu cards. The title, tagline, buttons and progress text are centred over the existing fog, ruins, light shaft, faint wing and snow background. Native screenshot inspected; all 93 polish assertions passed, including centred-title and centred-button checks.

Current menu presentation supersedes the previous centred layout: see AERO_MENU.md for the requested glossy console-style menu, title logo and 3D game-box art. Gameplay sprites remain unchanged.
