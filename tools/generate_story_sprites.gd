extends SceneTree

## Makes the story's hand-drawn pixel sprites: the people of Lowbell, the
## Choir, Ilse and Wren, and the few objects the surface packs don't have
## (the great bell, rune cubes, wind chimes, a candle). They are drawn here
## as pixel maps in the packs' own palette (assets/surface, assets/town) and
## saved as PNG strips in res://assets/sprites/story/, which the game loads
## (see SurfaceArt.STRIPS for their frame sizes). It also cuts "open door"
## frames from the pack's own houses, for the doors that open in Lowbell.
## Re-run after editing a map:
##   godot --headless --path . --script res://tools/generate_story_sprites.gd

const OUT := "res://assets/sprites/story/"
const PREVIEW := "user://story_sprites_preview.png"

## The packs' palette, one letter each.
const PAL := {
	"o": "0b0d20", "O": "0a0614", "f": "0d0f24",
	"1": "12142e", "2": "1c2149", "3": "2d325c", "4": "3a3f72", "5": "545b86", "6": "6b73aa",
	"7": "8f99cc", "8": "c4cdef", "9": "dde4fa", "k": "7880b4", "l": "98a2d3", "n": "a9b4e0",
	"h": "221a2b", "p": "30253a", "q": "3c3044", "r": "54455c", "s": "6f6078", "i": "433449", "j": "5b4a62",
	"v": "2f2756", "w": "3d3368", "x": "5e4d86", "m": "362c60",
	"t": "1a3740", "u": "27535a", "y": "3a7270", "z": "5f978f",
	"b": "2b6fd6", "c": "4aa8ff", "d": "a9d4ff", "g": "6e6254",
}

# ------------------------------------------------------------------ people
# All face right; the game flips them. A breathing frame and a blink frame
# are made from each (see _person).

const TAM := [
	".....oooooo....",
	"....o444443o...",
	"...o33333332o..",
	"...oooooooooooo",
	"....offffffo...",
	"....off9f9fo...",
	"....offffffo...",
	"....o787878o...",
	"...oyo8787oyo..",
	"..ouyyo77oyyuo.",
	"..ouyyyooyyyuo.",
	"..ouyuyyyyyuuoo",
	"..ouyuyyyyyuoff",
	"..ouuuyyyyyuoqo",
	"..ouuuyyyyyuoq.",
	"..ouuuyyyyyuoq.",
	"..ouuuyyyyyuoq.",
	"..ouuuyyyyyzoq.",
	"..ouuuyyyyyzoq.",
	"..ouuuyyyyyzoq.",
	"..ouuuuyyyyzoq.",
	"..ouuuuyyyyzoq.",
	"...oooooooooqq.",
	"...offo.offo.q.",
	"...ooo..ooo....",
]

const MIRA := [
	"....ooooooo...",
	"...orrrrrrso..",
	"..orrssssssso.",
	"..orsooooooso.",
	"..orsoffffosso",
	"..orsof9f9foso",
	"..orsoffffoso.",
	"...ooooffoooo.",
	"...oqqoooosqo.",
	"..oqqqlllllsqo",
	"..oqqqlnnnlsqo",
	"..oqqqlnnnlsqo",
	".oqqqflnnnlfso",
	".oqqqolnnnlosso",
	".oqqqqlnnnlsqo",
	".oqqqqlnnnlsqo",
	".oqqqqlnnnlsso",
	".oqqqqlllllsso",
	"oqqqqqqqqqqsso",
	"oqqqqqqqqqqsso",
	"oqqqqqqqqqqsso",
	".oooooooooooo.",
	"..offo..offo..",
	"..ooo...ooo...",
]

const PIP := [
	"......o....",
	".....o9o...",
	"....oxo....",
	"...oxxxo...",
	"..oxwxxxo..",
	"..owxwxxxo.",
	".oooooooooo",
	"..offffffo.",
	"..of9f9ffo.",
	"..offffffo.",
	"..occcccco.",
	".ocdcccccco",
	".o44cc4444o",
	".o44444444o",
	".o44444444o",
	"..oooooooo.",
	"..ofo..ofo.",
	"..oo...oo..",
]

const EDDA := [
	".....ooooo....",
	"....oxxxxxo...",
	"...oxxwwwxxo..",
	"..oxxwffffwxo.",
	"..oxwff9f9fxo.",
	"..oxwffffffxo.",
	"..oxxwffffwxo.",
	"...oxxwwwwxo..",
	"...otoxxxxotuo",
	"..otuuoxxouuyo",
	"..otuuuuuuuyyo",
	".otuuuuuuuuyyo",
	".otuuuuuuuyyzo",
	".otuuugggguyzo",
	".otuuggrrggyzo",
	".otuugrrrrgyzo",
	".otuuugggguyzo",
	".otuuuuuuuuyzo",
	"otuuuuuuuuuyzo",
	"otuuuuuuuuuyzo",
	"otuuuuuuuuuyzo",
	".oooooooooooo.",
	"..offo..offo..",
	"..ooo...ooo...",
]

## Nan, with the lantern she will give Echidna.
const NAN := [
	"....ooooo.......",
	"...o78887o......",
	"..o7888887o.....",
	"..o7ooooo8o.....",
	"..o7offffo7o....",
	"...oof9f9fo.....",
	"...offffffo.....",
	"...ooffffoo.....",
	"..oxxoooowxo....",
	".oxwwwxxwwwxo...",
	".oxwwwwwwwwxoo..",
	"oxwwqqqqqwwxoffo",
	"oxwqqqqqqqwxo.o.",
	"oxwqqqqqqqwxooooo",
	"oxqqqqqqqqqwoocdo",
	"oxqqqqqqqqqwoc9co",
	"oxqqqqqqqqqwocdco",
	"oqqqqqqqqqqqooooo",
	"oqqqqqqqqqqqo....",
	".ooooooooooo.....",
	"..offo.offo......",
	"..ooo..ooo.......",
]

const MONK := [
	"......oooo....",
	".....owwwwo...",
	"....owwwwwxo..",
	"...owwwwwwxxo.",
	"...owwwwofffo.",
	"...owwwoff9f9o",
	"...owwwofffffo",
	"...owwwwoffffo",
	"..owwwwwwoooo.",
	"..owwwwwwwwxo.",
	".owvwwwwwwwxxo",
	".owvwwwwwwwxxo",
	".owvwwwwwwxxxo",
	".owvwwrrrrrrxo",
	".owvwwwwwrwwxo",
	".owvvwwwwrwwxo",
	".owvvwwwwwwwxo",
	".owvvwwwwwwwxo",
	"owvvwwwwwwwwxo",
	"owvvwwwwwwwwxo",
	"owvvwwwwwwwwxo",
	"owvvvwwwwwwwxo",
	"owvvvwwwwwwwxo",
	"owvvvwwwwwwwxo",
	"owvvvvwwwwwwxo",
	".oooooooooooo.",
]

const ILSE := [
	"......oooooo...",
	".....o222222o..",
	"....o22222222o.",
	"....o2d9c9d92o.",
	"....o22ffff22o.",
	"....o2ff9f9fo..",
	"....o2fffffo...",
	"....o22fffo....",
	"...o2222oo.....",
	"...o222xxxxo...",
	"..o22xxxxxxxo..",
	"..o2xxxwwwxxxoo",
	"..o2xxwwwwwxxff",
	"..o2xwwwwwwwxoo",
	"..o2xwwwwwwwxo.",
	"..o2xwwwddwwxo.",
	"..o2xwwwwwwwxo.",
	"..o2xwwwwwwwxo.",
	"..o2xwwwwwwwxo.",
	"..o22wwwwwwwxo.",
	".o22wwwwwwwwxo.",
	".o22wwwwwwwwxo.",
	".o2wwwwwwwwwxo.",
	".o2wwwwwwwwwxo.",
	"o22wwwwwwwwwxo.",
	"o22wwwwwwwwwxo.",
	"o2wwwwwwwwwwwxo",
	"o2wwwwwwwwwwwxo",
	".ooooooooooooo.",
]

## Wren asleep in her bed (the frame and a breathing frame).
const WREN_BED := [
	"oooo................................",
	"orro................................",
	"orso................................",
	"orso................................",
	"orso..ooooo.........................",
	"orso.o22222o........................",
	"orsoo2ffff22o.............oooooooo..",
	"orso2ffffff2oooooooooooooowwwwwwxo..",
	"orsonffffffnoxxxxxxxxxxxxxxxxxxxxoooo",
	"orsonnnnnnnnoxwwwwwwwwwwwwwwwwwwwxorso",
	"orsooooooooooxwwwwwwwwwwwwwwwwwwwxorso",
	"orsoqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqorso",
	"orsorrrrrrrrrrrrrrrrrrrrrrrrrrrrrrorso",
	"orsoooooooooooooooooooooooooooooooorso",
	"oqqo..oqo.....................oqo.oqqo",
	"oooo..ooo.....................ooo.oooo",
]

# ------------------------------------------------------------------ objects

const BELL := [
	"............oo............",
	"...........o66o...........",
	"...........o6o6o..........",
	"...........oo.oo..........",
	".........oooooooo.........",
	"........o45666654o........",
	".......o3456776654o.......",
	"......o34567887654o.......",
	"......o3456788765o........",
	"......o34567887654o.......",
	".....o345667887654o.......",
	".....o345667887654o.......",
	".....o3456678876543o......",
	"....o34566788876543o......",
	"....o345667888766543o.....",
	"...o3345667888766543o.....",
	"...o33456678887665433o....",
	"..o333456678887665433o....",
	".oo3334566788876654333oo..",
	"o4555666777888777666555o..",
	"o3444555666777666555444o..",
	".oooooooooo22oooooooooo...",
	"...........o5o............",
	"...........ooo............",
]

## The little bell of the village shrine.
const SHRINE_BELL := [
	"......o......",
	".....o6o.....",
	"....ooooo....",
	"....o456o....",
	"...o45786o...",
	"...o45786o...",
	"...o45786o...",
	"..o3457864o..",
	"..o3457864o..",
	".o334578643o.",
	"o44556786554o",
	"o33444555444o",
	".ooooo5ooooo.",
	".....ooo.....",
]

## Where the crack runs down the bell (drawn on a copy for the cracked frame).
const BELL_CRACK := [
	Vector2i(14, 6), Vector2i(14, 7), Vector2i(15, 8), Vector2i(15, 9), Vector2i(14, 10),
	Vector2i(14, 11), Vector2i(15, 12), Vector2i(16, 13), Vector2i(16, 14), Vector2i(15, 15),
	Vector2i(15, 16), Vector2i(16, 17), Vector2i(17, 18), Vector2i(17, 19), Vector2i(16, 20),
]

const CANDLE := [
	[
		"...o...",
		"..odo..",
		"..ocdo.",
		".ocd9o.",
		".oc9co.",
		"..oco..",
		"..o8o..",
		".o888o.",
		".o7887o",
		".o7887o",
		".o7887o",
		".o7887o",
		"oooooooo",
		"orrrrrro",
		"oooooooo",
	],
	[
		"..o....",
		".odo...",
		".ocdo..",
		".ocd9o.",
		"..oc9o.",
		"..oco..",
		"..o8o..",
		".o888o.",
		".o7887o",
		".o7887o",
		".o7887o",
		".o7887o",
		"oooooooo",
		"orrrrrro",
		"oooooooo",
	],
	[
		"....o..",
		"...odo.",
		"..odco.",
		".o9dco.",
		".oc9co.",
		"..oco..",
		"..o8o..",
		".o888o.",
		".o7887o",
		".o7887o",
		".o7887o",
		".o7887o",
		"oooooooo",
		"orrrrrro",
		"oooooooo",
	],
]

## One chime: a string and a small metal tube.
const CHIME_TUBE := [
	".o.",
	".o.",
	".o.",
	"ooo",
	"o8o",
	"o9o",
	"o8o",
	"o7o",
	"o8o",
	"o7o",
	"o7o",
	"olo",
	"olo",
	"ooo",
]

var _preview_items: Array = []


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var bell := _map(BELL)
	var cracked := bell.duplicate()
	for p in BELL_CRACK:
		cracked.set_pixelv(p, Color(PAL["O"]))
		if p.x + 1 < cracked.get_width() and cracked.get_pixelv(p + Vector2i(1, 0)).a > 0.5:
			cracked.set_pixelv(p + Vector2i(1, 0), Color(PAL["8"]))
	_save_strip("great_bell", [bell, cracked])
	_save_strip("shrine_bell", [_map(SHRINE_BELL)])
	var candle: Array = []
	for f in CANDLE:
		candle.append(_map(f))
	_save_strip("candle", candle)
	_save_strip("chime_tube", [_map(CHIME_TUBE)])
	_save_strip("chime_post", [_chime_post()])
	_save_strip("rune_cube", [_cube(22)])
	_save_strip("rune_cube_great", [_cube(34)])
	_door_frames("door_echidna", Rect2i(99, 48, 90, 80), Rect2i(39, 49, 13, 28))
	_door_frames("door_nan", Rect2i(210, 16, 108, 112), Rect2i(45, 76, 16, 33))
	_save_preview()
	print("STORY SPRITES DONE")
	quit()


# ------------------------------------------------------------------ building

func _map(rows: Array) -> Image:
	var w := 0
	for r in rows:
		w = maxi(w, String(r).length())
	var img := Image.create(w, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			if not PAL.has(ch):
				push_error("unknown colour '%s'" % ch)
				continue
			img.set_pixel(x, y, Color(PAL[ch]))
	return img


## A person: standing, breathing (the head and shoulders dip a pixel), and
## blinking (eyes shut).
func _person(sprite_name: String, rows: Array) -> void:
	var stand := _map(rows)
	var chest := _chest_row(rows)
	var breath := _breathe(rows, 0, chest, 0, rows.size())
	var blink_rows: Array = []
	for r in rows:
		blink_rows.append(String(r).replace("9", "f") if _is_face_row(r) else r)
	_save_strip(sprite_name, [stand, breath, _map(blink_rows)])


func _is_face_row(row: String) -> bool:
	return row.contains("f9") or row.contains("9f")


## The first row below the face: everything above it dips on the breath.
func _chest_row(rows: Array) -> int:
	var last_face := 0
	for y in rows.size():
		if _is_face_row(rows[y]):
			last_face = y
	return mini(last_face + 3, rows.size() - 4)


## A copy where rows [top, split) move down one pixel (the row at `split`
## is covered), for a gentle breathing frame.
func _breathe(rows: Array, top: int, split: int, _unused_a: int, _unused_b: int) -> Image:
	var moved: Array = rows.duplicate()
	for y in range(split, top, -1):
		moved[y] = rows[y - 1]
	moved[top] = ".".repeat(String(rows[top]).length())
	return _map(moved)


func _chime_post() -> Image:
	# A wooden post with an arm, for the chimes to hang from
	var img := Image.create(30, 62, false, Image.FORMAT_RGBA8)
	var o := Color(PAL["o"])
	img.fill_rect(Rect2i(2, 0, 5, 62), o)
	img.fill_rect(Rect2i(3, 1, 3, 60), Color(PAL["q"]))
	img.fill_rect(Rect2i(5, 1, 1, 60), Color(PAL["r"]))
	img.fill_rect(Rect2i(2, 3, 28, 4), o)
	img.fill_rect(Rect2i(3, 4, 26, 2), Color(PAL["q"]))
	img.fill_rect(Rect2i(3, 4, 26, 1), Color(PAL["s"]))
	# a little brace under the arm
	for k in 5:
		img.set_pixel(6 + k, 11 - k, o)
		img.set_pixel(6 + k, 10 - k, Color(PAL["q"]))
	img.fill_rect(Rect2i(0, 59, 9, 3), o)
	img.fill_rect(Rect2i(1, 59, 7, 1), Color(PAL["r"]))
	return img


## A carved stone rune cube (size × size) with four dark sockets for the
## words; the game draws the glowing runes into them.
func _cube(size: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var o := Color(PAL["o"])
	img.fill_rect(Rect2i(0, 0, size, size), o)
	img.fill_rect(Rect2i(1, 1, size - 2, size - 2), Color(PAL["4"]))
	img.fill_rect(Rect2i(1, 1, size - 2, 2), Color(PAL["6"]))
	img.fill_rect(Rect2i(1, 1, 1, size - 2), Color(PAL["5"]))
	img.fill_rect(Rect2i(size - 3, 3, 2, size - 4), Color(PAL["3"]))
	img.fill_rect(Rect2i(1, size - 3, size - 2, 2), Color(PAL["2"]))
	var gap := 2 if size < 30 else 3
	var cell := (size - 2 - 3 * gap) / 2
	for i in 4:
		var cx := 1 + gap + (i % 2) * (cell + gap)
		var cy := 1 + gap + (i / 2) * (cell + gap)
		img.fill_rect(Rect2i(cx, cy, cell, cell), Color(PAL["1"]))
		img.fill_rect(Rect2i(cx, cy, cell, 1), o)
		img.fill_rect(Rect2i(cx, cy, 1, cell), o)
		img.fill_rect(Rect2i(cx, cy + cell - 1, cell, 1), Color(PAL["3"]))
	# Wear: a chip, a crack and a fleck of moss
	img.set_pixel(size - 2, 1, o)
	img.set_pixel(size - 3, 1, Color(PAL["4"]))
	for k in 3:
		img.set_pixel(3 + k, size - 4 - k, Color(PAL["2"]))
	img.set_pixel(2, size - 3, Color(PAL["y"]))
	img.set_pixel(3, size - 3, Color(PAL["u"]))
	return img


## Two frames of a pack house's door opening (ajar, then open), cut from the
## house itself: the door's wood gives way to the dark room inside, the
## panel narrowing toward its hinge (left).
func _door_frames(sprite_name: String, house: Rect2i, door: Rect2i) -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path("res://assets/town/sheetA_buildings.png"))
	sheet.convert(Image.FORMAT_RGBA8)
	var frames: Array = []
	# The doorway, row by row: from the first to the last wood pixel (its
	# iron straps included)
	var spans := {}
	var x0 := door.size.x
	var x1 := 0
	for y in door.size.y:
		for x in door.size.x:
			var c := sheet.get_pixel(house.position.x + door.position.x + x, house.position.y + door.position.y + y)
			if _is_wood(c):
				var s: Vector2i = spans.get(y, Vector2i(x, x))
				spans[y] = Vector2i(mini(s.x, x), maxi(s.y, x))
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
	for keep in [0.45, 0.16]:
		var img := Image.create(door.size.x, door.size.y, false, Image.FORMAT_RGBA8)
		var hinge := x0 + int(round((x1 - x0 + 1) * keep))
		for y in spans:
			var s: Vector2i = spans[y]
			for x in range(s.x, s.y + 1):
				var c := sheet.get_pixel(house.position.x + door.position.x + x, house.position.y + door.position.y + y)
				if x < hinge:
					# The panel, swung in and seen edge-on: darker
					img.set_pixel(x, y, c.darkened(0.3))
				elif x == hinge:
					img.set_pixel(x, y, Color(PAL["h"]))
				else:
					img.set_pixel(x, y, Color(PAL["O"]))
		frames.append(img)
	_save_strip(sprite_name, frames)
	print("  %s: door at %s in %s" % [sprite_name, door, house])


func _is_wood(c: Color) -> bool:
	return c.a > 0.5 and c.h > 0.71 and c.h < 0.83 and c.s > 0.2 and c.v < 0.45


func _save_strip(sprite_name: String, frames: Array) -> void:
	var w := 0
	var h := 0
	for f in frames:
		w = maxi(w, f.get_width())
		h = maxi(h, f.get_height())
	var strip := Image.create(w * frames.size(), h, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		var f: Image = frames[i]
		# Bottom-aligned, centred in its cell
		strip.blit_rect(f, Rect2i(Vector2i.ZERO, f.get_size()), Vector2i(i * w + (w - f.get_width()) / 2, h - f.get_height()))
	strip.save_png(ProjectSettings.globalize_path(OUT + sprite_name + ".png"))
	_preview_items.append([sprite_name, strip, w, h, frames.size()])
	print("  %s: %d frame(s) of %dx%d" % [sprite_name, frames.size(), w, h])


## Every sprite at 6x on a dusk-coloured card, for checking by eye.
func _save_preview() -> void:
	var k := 6
	var pad := 12
	var width := 0
	var height := pad
	for item in _preview_items:
		width = maxi(width, item[1].get_width() * k + pad * 2)
		height += item[1].get_height() * k + pad
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color("3b3a55"))
	var y := pad
	for item in _preview_items:
		var strip: Image = item[1]
		var big := strip.duplicate()
		big.resize(strip.get_width() * k, strip.get_height() * k, Image.INTERPOLATE_NEAREST)
		img.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(pad, y))
		y += big.get_height() + pad
	img.save_png(ProjectSettings.globalize_path(PREVIEW))
	print("  preview: ", ProjectSettings.globalize_path(PREVIEW))
