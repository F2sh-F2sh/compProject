# Frutiger Aero menu revision

The menu follows the supplied console-menu layout: glassy slanted indigo tabs on the left, a three-quarter game-box render on the right, a chrome/aqua/plum title above, and a contextual footer below. Existing ruined-belfry fog, ruins, light shaft, faint wing and snow remain. This revision changes menu presentation and Back navigation, not gameplay art or mechanics.

## Assets and implementation

- `assets/ui/menu/aero_title.png`: glass-and-chrome title, transparent PNG.
- `assets/ui/menu/belfry_box.png`: transparent 3D game-case render with a pixel-art cover showing Echidna and the sealed belfry.
- `scripts/ui/aero_menu_button.gd`: slanted gradient tabs, hover/focus feedback, readable bundled pixel typography.
- `scripts/ui/aero_menu_chrome.gd`: translucent bands and subtle rune rings.
- `scripts/ui/title_screen.gd`: menu layout, artwork, contextual descriptions and Escape/Back routing.

The built-in imagegen tool produced both promotional assets; the box received a second pass to remove its external backdrop. Transparent margins were trimmed with Godot. The current promotional graphics are palette-limited native pixel assets displayed with nearest filtering; see PIXEL_AERO_MENU.md for the refinement and exact dimensions. The old portraits and bell asset are unused in the current menu and were not deleted.

## Verification

18 automated title-flow checks and 93 polish assertions passed. All 272 scene/script resources loaded. 17 native rendered assertions passed for separated artwork/options, initial and hover focus, saved-progress bounds, levels/settings/admin bounds, and Escape navigation. Screenshots of all pages were inspected. Rendering ran on an isolated Windows desktop without switching desktops or sending OS input. This is menu visual verification, not a claim of exhaustive gameplay playtesting. Existing shutdown resource-cleanup warnings still occur.

See `docs/polish_shots/2026-10-09-dark/title_screen.png` and `aero_levels.png`, `aero_settings.png`, `aero_progress.png`, `aero_admin.png` in the same folder. No commit, push or branch switch.

## Built-in generation prompts

### Title logo

Create a standalone GAME TITLE LOGO on transparent background for 'The Sealed Belfry'. Use the reference ONLY for this indie game's palette and identity (dark haunted purple/indigo belfry at night, cold teal, antique muted gold). Logo exact text: 'THE SEALED' on first line, 'BELFRY' large on second line. No other text. A beautifully polished authentic 2005-2008 FRUTIGER AERO / glossy console-game title treatment: rounded bold elegant sans-serif letterforms, cold silver chrome edge bevels, translucent deep-indigo-to-aqua glass interiors, luminous pale teal upper specular reflections, controlled plum shadows and subtle muted-gold accent underline shaped like a small wave. Attractive precise readable typography with smooth contours, restrained crisp highlights, no kitschy rainbow colours, no generic flat text. Preserve haunted storybook identity with a tiny bell shape tucked naturally into the negative space of the logo, very subtle. Compact wide two-line lockup, whole text comfortably within transparent margins, no cropped lettering. No background image, no characters, no packaging, no bubbles surrounding the words, no watermarks. Smooth high-quality UI title graphic is intentional; avoid pixelated typography. The game is called The Sealed Belfry, spell exactly.

### Game box

Create ONE beautiful 3D retail game box product render for the indie game THE SEALED BELFRY on a truly TRANSPARENT background. Reference 1 is only a guide to the upright game-box product format; do NOT copy Mario, Nintendo, GameCube, brands, logos or console markings. Reference 2 is the exact protagonist Echidna: a dark slender shadow witch in a drooping curled purple hat, gold buckle, narrow white eyes, black face with no human features, purple draped sleeves. Reference 3 gives the haunted ruins and dark indigo/teal/plum/muted-gold palette. A slim upright early-2000s premium PC-game case, viewed in refined three-quarter perspective with front dominant, narrow spine on LEFT visible and very slight top edge visible. Tall rectangular box, slight perspective, crisp straight edges, no distorted box. Glossy indigo physical packaging with a polished silver/teal header. Cover illustration itself should be richly composed COARSE PIXEL ART of Echidna small in foreground, looking up at a tall abandoned gothic bell tower, immense sealed bell and curling cold teal magical runes in moonlit fog. Inspired by our game's original pixels, no human face. Epic but quiet nighttime witch adventure, no generic fantasy warrior. Printed logo prominently at top exact words 'THE SEALED BELFRY', arranged two lines, in very readable rounded bold silver/aqua glass letters with indigo shadows, 2000s Frutiger Aero console-game typography. Spine also has readable small 'THE SEALED BELFRY'. Bottom tiny tasteful line 'A WITCH. A HELD NIGHT. A SILENT BELL.' No ratings badges, fake awards, extra logos or unreadable dense labels. Cover image dark indigo with teal and muted gold highlights, a narrow ornamental frame and fine silver edging. Product render has attractive subtle glossy plastic highlight along one edge, realistic thickness, restrained clean rendering, box FLOATS alone no stand or floor and no cast opaque background shadow. Full box fully visible with generous transparent margins, front facing slightly right toward viewer, polished menu showcase prop. This is menu packaging art, not a replacement gameplay sprite.

### Box transparency pass

Edit target: this existing game-box render. Remove ONLY the dark gradient studio backdrop outside the game box and make that entire outside area fully transparent alpha=0. Preserve the box itself EXACTLY: all title text, pixel art cover, spine, glossy plastic edges, perspective, colours, proportions. No floor, no shadow rectangle, no background colour or scenery outside the physical packaging silhouette. Output the one fully visible unchanged physical game box isolated on a truly transparent background with clean alpha edges. Do not redesign or add anything.

Pixel refinement: simplified the box cover while preserving Echidna, replaced smooth button lettering with Pixelify Sans, and converted logo, cover, glass tabs and rune rings to hard pixel edges and stepped shading. See PIXEL_AERO_MENU.md for saved assets, prompts and current validation.
