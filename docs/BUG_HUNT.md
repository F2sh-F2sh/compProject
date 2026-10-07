# Background bug hunt — October 7, 2026

Work performed directly in this checkout, preserving the existing uncommitted story
work. No branch switch, commit, push, file deletion, desktop keyboard/mouse control,
or visible game launch during the background pass. Test fixture saves live under
`.godot/`; the player's real save and settings are not written.

## Confirmed game defects fixed

Each issue below was reproduced with a failing assertion before its fix. These are
10 defects, not a claim of exhaustive coverage or a fabricated target of 1,000.

| ID | Reproduction and effect | Fix |
| --- | --- | --- |
| 01 | Complete Nan's dialogue: cottage has no pause menu. | Add the existing PauseMenu to the cottage as well as the road and well. |
| 02 | Enter the well before igniting a lamp: its additive glow remains visible despite the hidden lamp. | Parent the halo to the light so visibility follows ignition. |
| 03 | Light both lamps: ward collision disappears but closed door artwork remains. | Hide the closed door when opening the ward, including restored saves. |
| 04 | Fire a projectile down into prologue terrain: it passes through floors. | Register terrain as world geometry and make fireballs detect solid layer 2 as well as enemies on layer 1. |
| 05 | Freeze and then kill a slime: thaw re-enables the defeated enemy's physics. | Let death retain ownership of disabled physics until reset. |
| 06 | Put a thin solid wall between player and cube within pickup range: F picks up the cube through it. | Require clear line of sight for pickup. |
| 07 | Place a portal with its far centre just inside a room edge: part of its exit is outside the room. | Require the full doorway rectangle to fit. |
| 08 | Activate a clear portal, then block its exit with geometry: teleport embeds the traveller. | Recheck the traveller's full translated bounds against solids, room bounds and hazards on transit. Leave it at the entrance when blocked. |
| 09 | Resize the cottage to an ultrawide viewport: camera shows outside the authored backdrop. | Fit framing to viewport and camera position while retaining the cinematic zoom. |
| 10 | Load dictionaries containing invalid checkpoint values, flag keys or statistic values: invalid entries survive outer type checks and can reach typed gameplay code. | Validate each entry while retaining valid flags, statistics and checkpoints. |

## Evidence and limits

Final fresh-process run: **1,013 assertions passed, 0 failed**, exit code 0.
Tutorial 140; Chapter 1 304; presentation state 79; experience 130;
Chapter 2/runes 304; prologue 38; adversarial regressions 18.
Rendered scenarios and compiled graphics-quality checks were skipped explicitly
and are not included in the passed count. `git diff --check` also passed.

`tests/adversarial_suite.gd` checks these cases in real Godot physics worlds and
also checks normal pickup, clear portal transit, velocity preservation, enemy reset
and valid-save preservation. Some cases use added geometry fixtures and explicit
positioning; they are focused reproductions rather than authored-route traversal.

The wider suites traverse the tutorial, all nine Chapter 1 rooms, all eight Chapter
2 rooms, the new prologue and bell aftermath. They cover alternate solutions,
failed jumps, hazards, death, reset, persistence, rune assembly and carry placement,
Echoes, UI transitions and layout. This does not mean every possible action sequence
was tested.

Headless projectile helpers bypass mouse aiming, shoot input, cost and cooldown;
their cast signal still permits Echo recording. A no-mana fizzle uses the player's
real shooting method. Rendered light, bloom, glow, spike luminance and compiled
graphics-quality checks are explicitly skipped. No new screenshots, visual
playtesting, controller hardware testing or listening-based audio judgment occurred.
Lamp/door/camera fixes have scene-state or layout evidence, not rendered verification.

Test infrastructure now avoids OS cursor warping, suppresses screenshots in headless
mode, uses logical viewport resizing, and fails unknown/unloadable suites. Corrupted
save fixtures are written to the project rather than protected application data and
remain available for inspection. Pickup tests wait for deferred object cleanup.
PostFX tolerates unavailable shader defaults under Godot's dummy renderer.

Logs: `.godot/adversarial-before.log`, `adversarial-portals-before.log`,
`adversarial-camera-before.log`, `adversarial-save-before.log`,
`adversarial-final.log`, and `background-verified.log`. Earlier intermediate
runs retain their original failures for comparison; the verified log is the final
run with all fixes and the corrected hit-stop measurement loaded at startup.

Godot also reports a certificate-store access error and resource/object cleanup
warnings in this environment. These are recorded separately from failed gameplay
assertions and are not counted as fixed game defects. Rendered verification remains
on the human checklist in `docs/PLAYTEST_CHECKLIST.md`.
