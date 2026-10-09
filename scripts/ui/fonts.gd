class_name Fonts
extends RefCounted

## The game's type, one face for each kind of text (all SIL Open Font
## Licence, in assets/fonts with their licence files):
##   TITLE  Jacquard 12, a pixel blackletter: the game's name, chapter, card
##          and screen headings (set in Title Case: its capitals are hard to
##          read on their own)
##   UI     Silkscreen, pixel small capitals: buttons, menus, the HUD,
##          prompts, short labels
##   STORY  Pixelify Sans: dialogue, captions, signs, toasts, any running text
##   BOOK   IM Fell English: ledger pages, lore cards, notes from the past
##   HAND   Patrick Hand: Wren's chalk, and anything else written by hand
## The pixel faces read cleanest at multiples of their grid: TITLE at
## 24/36/48/72, UI at 8/16/24; STORY at 16 to 28.

const TITLE := preload("res://assets/fonts/jacquard12/Jacquard12-Regular.ttf")
const UI := preload("res://assets/fonts/silkscreen/Silkscreen-Regular.ttf")
const UI_BOLD := preload("res://assets/fonts/silkscreen/Silkscreen-Bold.ttf")
const STORY := preload("res://assets/fonts/pixelify_sans/PixelifySans.ttf")
const BOOK := preload("res://assets/fonts/im_fell_english/IMFellEnglish-Regular.ttf")
const BOOK_ITALIC := preload("res://assets/fonts/im_fell_english/IMFellEnglish-Italic.ttf")
const HAND := preload("res://assets/fonts/patrick_hand/PatrickHand-Regular.ttf")
