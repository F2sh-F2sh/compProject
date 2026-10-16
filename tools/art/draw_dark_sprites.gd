extends SceneTree

## Original native-resolution pixel art. Every drawing is at most 64x64;
## strips contain multiple independent frames, never enlarged old sprites.
## Integer scan conversion, opaque palette pixels, no antialiasing/dithering.
const OUT := "res://assets/sprites/story/"
const PAL := {
	"o": "0b0d20", "f": "0d0f24", "1": "12142e", "2": "1c2149",
	"3": "2d325c", "4": "3a3f72", "5": "545b86", "6": "6b73aa",
	"7": "8f99cc", "8": "c4cdef", "9": "dde4fa", "h": "221a2b",
	"p": "30253a", "q": "3c3044", "r": "54455c", "s": "6f6078",
	"v": "2f2756", "w": "3d3368", "x": "5e4d86",
	"t": "1a3740", "u": "27535a", "y": "3a7270",
	"g": "6e6254", "a": "aa8652", "e": "d6b970", "c": "a9d4ff",
}
var ink: Image
var previews: Array[Image] = []
var labels: Array[String] = []
var save_errors := 0

func _init() -> void:
	for who in ["tam", "mira", "pip", "edda", "nan", "monk", "ilse", "wren", "nan_seated"]:
		var poses: Array[Image] = []
		for pose in 3:
			poses.append(person(who, pose))
		save_strip(OUT + who + ".png", poses, who)
	for who in ["echidna", "nan", "wren", "ilse"]:
		var faces: Array[Image] = []
		for expression in (5 if who == "echidna" else (3 if who == "ilse" else 4)):
			faces.append(portrait(who, expression))
		save_strip(OUT + "portrait_" + who + ".png", faces, "face_" + who)
	save_strip(OUT + "title_bell.png", [title_bell()], "title_bell")
	# EchidnaPush.png is authored against her original animation sheets.
	# Preserve it when regenerating the separate NPC and furniture art.
	# Preserve the separately authored coarse-pixel bat animation as well.
	for prop in ["table", "hearth", "cottage_cupboard", "cottage_bookshelf", "cottage_window", "desk_lantern", "cottage_rug"]:
		var poses: Array[Image] = []
		for i in (3 if prop in ["hearth", "desk_lantern"] else 1):
			poses.append(furniture(prop, i))
		save_strip(OUT + prop + ".png", poses, prop)
	var beds: Array[Image] = []
	for i in 2:
		beds.append(bed(i))
	save_strip(OUT + "wren_bed.png", beds, "wren_bed")
	var sheet := Image.create(6 * 80, ceili(previews.size() / 6.0) * 80, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("12101d"))
	for i in previews.size():
		sheet.blit_rect(previews[i], Rect2i(Vector2i.ZERO, previews[i].get_size()), Vector2i((i % 6) * 80 + 8, (i / 6) * 80 + 8))
	sheet.save_png(ProjectSettings.globalize_path("user://dark_sprite_contact.png"))
	print("DARK ART: ", labels, " — native pixels; all frames <=64x64")
	quit(1 if save_errors > 0 else 0)

func canvas(w := 64, h := 64) -> void:
	ink = Image.create(w, h, false, Image.FORMAT_RGBA8)

func box(x: int, y: int, w: int, h: int, color: String) -> void:
	ink.fill_rect(Rect2i(x, y, w, h).intersection(Rect2i(Vector2i.ZERO, ink.get_size())), Color(PAL[color]))

func poly(points: Array, color: String) -> void:
	var vertices := PackedVector2Array()
	for p in points:
		vertices.append(Vector2(p[0], p[1]))
	for y in ink.get_height():
		for x in ink.get_width():
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), vertices):
				ink.set_pixel(x, y, Color(PAL[color]))

func eye(x: int, y: int, shut: bool, size := 3) -> void:
	box(x, y, size, 1 if shut else 3, "7" if shut else "9")

func person(who: String, pose: int) -> Image:
	canvas()
	var seated := who == "nan_seated"
	var small := who == "pip"
	var top := 12 if small else 2
	var lift := 1 if pose == 1 else 0
	var coat := "u" if who in ["tam", "edda"] else "w"
	if who == "mira": coat = "q"
	if who == "monk": coat = "3"
	if who == "ilse": coat = "2"
	if seated:
		box(12, 13, 33, 47, "o")
		box(15, 16, 27, 38, "q")
		box(17, 19, 23, 31, "r")
		box(12, 42, 43, 8, "h")
		box(15, 43, 38, 3, "s")
		box(14, 51, 5, 13, "h")
		box(48, 50, 5, 14, "h")
		box(15, 60, 4, 4, "r")
		box(49, 60, 4, 4, "r")
		top = 7
	# Wide lower hems, narrow shoulders, full pixel silhouette, boots grounded.
	poly([[24, top + 23 - lift], [38, top + 23 - lift], [45, 51], [43, 59], [18, 59], [18, 49]], "o")
	poly([[25, top + 25 - lift], [37, top + 25 - lift], [42, 56], [21, 56], [21, 48]], coat)
	poly([[26, top + 26 - lift], [30, top + 29], [27, 54], [23, 56], [23, 44]], "t" if coat == "u" else "v")
	box(34, 35, 3, 19, "y" if coat == "u" else "x")
	box(22, 59, 7, 5, "o")
	box(34, 59, 9, 5, "o")
	box(24, 59, 4, 2, "r")
	box(36, 60, 6, 1, "r")
	# Head is newly drawn, with the same shadow face and pale eyes as Echidna.
	box(23, top + 9 - lift, 20, 18, "o")
	box(26, top + 11 - lift, 15, 13, "f")
	if who in ["nan", "nan_seated", "ilse", "edda"]:
		poly([[20, top + 9], [24, top + 3], [35, top], [41, top + 4], [44, top + 12], [40, top + 17], [39, top + 8], [28, top + 7], [25, top + 18], [22, top + 20]], "o")
		poly([[23, top + 9], [26, top + 4], [35, top + 2], [40, top + 5], [41, top + 10], [36, top + 8], [28, top + 8], [24, top + 16]], "6" if who != "edda" else "r")
		box(27, top + 4, 9, 2, "7" if who != "edda" else "s")
		if who.begins_with("nan"):
			box(17, top + 5, 9, 9, "o")
			box(19, top + 6, 5, 6, "5")
			box(20, top + 6, 3, 2, "7")
	elif who in ["tam", "pip"]:
		poly([[18, top + 12], [24, top + 3], [36, top], [43, top + 8], [48, top + 11], [48, top + 15], [18, top + 15]], "o")
		poly([[21, top + 11], [26, top + 5], [35, top + 3], [40, top + 10], [45, top + 11], [45, top + 13], [21, top + 13]], "4" if not small else "w")
		box(25, top + 10, 15, 2, "6" if not small else "x")
	elif who == "monk":
		poly([[20, 24], [23, 8], [29, 2], [39, 4], [46, 20], [44, 30], [39, 29], [41, 13], [27, 13], [24, 29]], "o")
		poly([[22, 22], [26, 9], [30, 5], [37, 7], [42, 18], [39, 11], [28, 11], [24, 26]], "4")
	else:
		poly([[20, 16], [22, 7], [29, 2], [38, 4], [45, 12], [45, 28], [40, 28], [40, 10], [27, 11], [23, 26], [19, 26]], "h")
		box(24, 7, 13, 4, "r")
		box(21, 15, 3, 11, "q")
		if who == "wren":
			box(20, 23, 4, 14, "r")
			box(19, 32, 6, 3, "6")
	eye(29, top + 16 - lift, pose == 2)
	eye(37, top + 16 - lift, pose == 2)
	if who == "tam":
		poly([[27, top + 21], [40, top + 21], [38, top + 31], [34, top + 34], [29, top + 29]], "5")
		box(31, top + 24, 6, 3, "7")
		box(48, 31, 3, 33, "h")
		box(49, 33, 1, 29, "s")
		box(44, 31, 6, 3, "g")
	if who in ["nan", "nan_seated", "mira"]:
		poly([[28, 35], [37, 35], [40, 52], [26, 52]], "5")
		box(29, 38, 7, 2, "6")
		box(30, 44, 6, 5, "3")
	if who == "pip":
		box(24, 37, 18, 5, "u")
		box(26, 41, 4, 8, "y")
		box(44, 40, 6, 7, "7")
		box(46, 41, 2, 4, "8")
	if who == "edda":
		box(41, 42, 9, 9, "q")
		box(43, 39, 2, 6, "y")
		box(46, 36, 2, 9, "u")
	if who in ["wren", "monk"]:
		box(37, 41, 13, 12, "o")
		box(39, 42, 9, 8, "p")
		box(46, 43, 2, 7, "7")
		box(39, 50, 8, 1, "g")
	if who == "ilse":
		box(32, 30, 2, 10, "7")
		box(31, 37, 4, 4, "8")
	# Mittens are part of each authored frame, not separate drawn overlays.
	box(39, 39 - lift, 5, 4, "g" if not seated else "7")
	if seated:
		box(33, 51, 16, 8, "q")
		box(41, 60, 9, 4, "o")
	return ink

func portrait(who: String, expression: int) -> Image:
	if who == "echidna":
		return echidna_portrait(expression)
	canvas()
	poly([[7, 64], [12, 49], [23, 40], [45, 40], [55, 48], [61, 64]], "o")
	poly([[10, 64], [15, 51], [24, 43], [43, 43], [52, 51], [57, 64]], "w" if who != "ilse" else "3")
	poly([[14, 64], [22, 49], [32, 54], [31, 64]], "v")
	box(24, 26, 24, 23, "o")
	box(27, 28, 18, 16, "f")
	if who == "nan":
		poly([[17, 37], [16, 21], [23, 12], [37, 10], [47, 17], [51, 30], [48, 42], [44, 37], [44, 25], [26, 25], [24, 39]], "o")
		poly([[19, 32], [19, 23], [25, 15], [36, 13], [43, 18], [47, 27], [43, 27], [40, 23], [26, 23], [22, 35]], "6")
		box(24, 16, 13, 3, "7")
		box(10, 18, 11, 12, "o")
		box(12, 20, 7, 8, "5")
		box(13, 20, 4, 2, "7")
	elif who == "wren":
		poly([[17, 39], [17, 21], [24, 13], [37, 12], [48, 19], [50, 45], [44, 51], [42, 24], [26, 25], [23, 51], [17, 51]], "h")
		box(24, 16, 15, 6, "r")
		box(18, 29, 4, 22, "q")
		box(44, 28, 4, 24, "q")
		box(17, 46, 7, 3, "6")
		box(43, 47, 7, 3, "6")
	else:
		poly([[14, 46], [17, 22], [24, 12], [38, 10], [49, 19], [53, 55], [45, 59], [42, 24], [25, 25], [22, 56]], "o")
		poly([[18, 44], [21, 23], [27, 15], [37, 14], [46, 21], [46, 39], [42, 24], [27, 22], [24, 47]], "5")
		box(27, 16, 11, 3, "7")
	var ey := 32
	var sad := (who == "nan" and expression == 2) or (who == "ilse" and expression == 1)
	var bright := (who == "nan" and expression == 3) or (who == "wren" and expression == 3)
	var peaceful := who == "ilse" and expression == 2
	eye(29, ey + (1 if sad else 0), sad or peaceful, 4)
	eye(39, ey + (1 if sad else 0), sad or peaceful, 4)
	if bright:
		box(29, ey - 1, 4, 5, "9")
		box(39, ey - 1, 4, 5, "9")
	if (who == "nan" and expression == 1) or (who == "ilse" and expression == 0) or (who == "wren" and expression == 2):
		box(29, ey - 2, 3, 1, "6")
		box(40, ey - 2, 3, 1, "6")
	if who == "wren" and expression == 1:
		box(29, ey, 4, 1, "f")
		box(39, ey, 4, 1, "f")
	if who == "nan":
		box(27, ey - 1, 8, 1, "g")
		box(37, ey - 1, 8, 1, "g")
		box(27, ey + 4, 8, 1, "g")
		box(37, ey + 4, 8, 1, "g")
		box(34, ey + 1, 3, 1, "a")
		box(28, 48, 16, 4, "5")
	box(32, 53, 4, 4, "g")
	box(33, 54, 2, 2, "e")
	return ink

func echidna_portrait(expression: int) -> Image:
	# The reference-guided 64px bust keeps the original player's nine colours.
	# Eye-only variations preserve her silhouette across all dialogue moods.
	var art := Image.load_from_file(ProjectSettings.globalize_path(OUT + "portrait_echidna_base.png"))
	if expression == 0:
		return art
	var white := Color.WHITE
	var shadow := Color8(6, 6, 8)
	for y in range(29, 39):
		for x in range(35, 45):
			if art.get_pixel(x, y) == white:
				art.set_pixel(x, y, shadow)
	match expression:
		1: # Worried: a slight uneven, lowered gaze.
			art.fill_rect(Rect2i(36, 33, 1, 4), white)
			art.fill_rect(Rect2i(37, 32, 1, 4), white)
			art.fill_rect(Rect2i(42, 33, 1, 3), white)
			art.fill_rect(Rect2i(43, 32, 1, 4), white)
		2: # Determined: focused eyes, still vertical rather than eyebrows.
			art.fill_rect(Rect2i(36, 34, 2, 3), white)
			art.fill_rect(Rect2i(37, 33, 1, 1), white)
			art.fill_rect(Rect2i(42, 33, 2, 3), white)
		3: # Sad: shorter downcast eyes.
			art.fill_rect(Rect2i(36, 35, 2, 3), white)
			art.fill_rect(Rect2i(42, 34, 2, 3), white)
		4: # Surprised: taller eyes; no invented human facial features.
			art.fill_rect(Rect2i(36, 31, 2, 7), white)
			art.fill_rect(Rect2i(42, 30, 2, 7), white)
	return art

func title_bell() -> Image:
	canvas()
	# A quiet heraldic emblem: the cracked bell bound shut by iron chains.
	# All details are native pixels; muted brass matches the menu's trim.
	poly([[10, 3], [54, 3], [56, 6], [54, 9], [10, 9], [8, 6]], "o")
	box(11, 4, 42, 3, "g")
	box(13, 4, 38, 1, "a")
	box(15, 7, 34, 1, "h")
	for x in [22, 39]:
		for y in range(9, 18, 3):
			box(x, y, 3, 3, "o")
			box(x + 1, y, 1, 2, "5")
	box(27, 14, 10, 7, "o")
	box(29, 15, 6, 5, "g")
	box(30, 15, 3, 2, "a")
	poly([[29, 18], [35, 18], [42, 22], [45, 30], [47, 40], [52, 46], [54, 48], [54, 53], [10, 53], [10, 48], [12, 46], [17, 40], [19, 30], [22, 22]], "o")
	poly([[29, 20], [35, 20], [40, 23], [43, 31], [45, 41], [49, 46], [15, 46], [19, 41], [21, 31], [24, 23]], "g")
	poly([[25, 24], [29, 21], [32, 21], [28, 26], [26, 34], [24, 42], [20, 44], [22, 33]], "a")
	box(26, 25, 2, 5, "e")
	poly([[36, 22], [40, 24], [43, 34], [44, 42], [47, 45], [38, 45], [39, 32]], "h")
	box(13, 47, 38, 5, "g")
	box(15, 47, 34, 1, "a")
	box(13, 51, 38, 1, "h")
	box(19, 49, 25, 1, "a")
	# A jagged crack and two diagonal chains carry the story's held silence.
	poly([[34, 23], [33, 29], [36, 32], [33, 36], [35, 41], [33, 46], [31, 46], [33, 41], [31, 36], [34, 32], [31, 29]], "h")
	for i in 9:
		var y := 24 + i * 3
		for x in [15 + i * 3, 46 - i * 3]:
			box(x - 1, y - 1, 5, 4, "o")
			box(x, y, 3, 2, "3")
			box(x, y, 2, 1, "6")
	poly([[28, 37], [35, 37], [38, 40], [38, 46], [35, 49], [28, 49], [25, 46], [25, 40]], "o")
	poly([[29, 38], [34, 38], [36, 40], [36, 45], [34, 47], [29, 47], [27, 45], [27, 40]], "h")
	box(29, 40, 5, 1, "a")
	box(31, 41, 1, 4, "a")
	box(28, 43, 7, 1, "g")
	box(29, 54, 6, 3, "o")
	box(30, 54, 4, 2, "g")
	poly([[30, 57], [34, 57], [36, 59], [36, 61], [28, 61], [28, 59]], "o")
	box(30, 58, 4, 2, "a")
	return ink

func witch(push: bool, pose: int) -> Image:
	canvas()
	var lean: int = [0, 1, 1, 0][pose] if push else 0
	# Complete bespoke silhouette: title holds a lantern; push braces both arms.
	poly([[15, 62], [17, 53], [23 + lean, 29], [37 + lean, 29], [45, 54], [43, 60], [33, 57], [26, 62]], "o")
	poly([[18, 59], [22, 44], [25 + lean, 31], [35 + lean, 31], [41, 53], [38, 57], [31, 54], [26, 59]], "w")
	poly([[20, 54], [26, 33], [29, 37], [26, 52], [31, 55], [24, 58]], "v")
	poly([[32, 36], [36, 37], [40, 53], [33, 51]], "u")
	box(20, 60, 8, 4, "o")
	box(35, 59, 9, 5, "o")
	box(23, 60, 4, 1, "5")
	box(37, 61, 5, 1, "5")
	box(24 + lean, 20, 16, 16, "o")
	box(27 + lean, 22, 12, 11, "f")
	eye(29 + lean, 26, false)
	eye(36 + lean, 26, false)
	poly([[6, 22], [14, 17], [22, 8], [27, 1], [38, 5], [42, 19], [50, 24], [48, 27], [9, 27]], "o")
	poly([[11, 22], [18, 17], [24, 9], [28, 4], [35, 7], [39, 20], [45, 23], [44, 24], [11, 24]], "w")
	poly([[25, 9], [28, 5], [33, 7], [28, 11], [26, 17], [22, 17]], "x")
	box(19, 19, 21, 3, "v")
	box(30, 18, 6, 5, "e")
	box(32, 19, 2, 3, "g")
	box(22, 28, 3, 10, "5")
	box(39, 29, 2, 8, "6")
	if push:
		poly([[34, 35], [41, 33 - lean], [52, 31 - lean], [55, 34 - lean], [52, 38 - lean], [42, 38], [37, 41]], "o")
		poly([[36, 36], [43, 35 - lean], [51, 33 - lean], [52, 36 - lean], [43, 37], [37, 39]], "x")
		box(52, 32 - lean, 4, 5, "5")
		poly([[32, 43], [43, 40], [52, 40], [54, 43], [53, 46], [40, 46], [32, 47]], "o")
		box(36, 43, 17, 2, "w")
		box(52, 41, 4, 5, "6")
		# The rear boot transfers weight; the arms stay braced against stone.
		if pose >= 2:
			box(20, 60, 8, 4, "o")
			box(21, 61, 4, 1, "5")
			box(24, 48, 2, 4, "x")
	else:
		poly([[36, 35], [42, 34], [46, 28], [50, 28], [51, 33], [46, 41], [39, 41]], "o")
		poly([[38, 36], [43, 36], [46, 31], [48, 31], [46, 37], [42, 39], [39, 39]], "x")
		box(47, 28, 4, 4, "6")
		var lamp := lantern(0)
		ink.blend_rect(lamp, Rect2i(Vector2i.ZERO, lamp.get_size()), Vector2i(45, 33))
	return ink

func lantern(pose: int) -> Image:
	var previous := ink
	canvas(16, 24)
	box(5, 0, 6, 2, "o")
	box(4, 2, 2, 5, "g")
	box(10, 2, 2, 5, "g")
	poly([[2, 8], [5, 5], [11, 5], [14, 8], [14, 10], [2, 10]], "o")
	box(4, 7, 8, 2, "a")
	box(3, 10, 10, 11, "o")
	box(5, 10, 6, 10, "g")
	box(6, 12, 4, 7, "a")
	box(7 + pose % 2, 13 - pose % 2, 2, 5, "e")
	box(7, 16, 2, 2, "9")
	box(2, 21, 12, 3, "o")
	box(4, 21, 8, 1, "a")
	var result := ink
	ink = previous
	return result

func bat(pose: int) -> Image:
	canvas()
	var tip: int = [5, 20, 39, 22][pose]
	poly([[27, 27], [17, 15], [3, tip], [6, 35], [11, 33], [15, 40], [21, 36], [28, 42]], "o")
	poly([[26, 28], [17, 18], [6, tip + 3], [8, 31], [13, 30], [16, 36], [21, 33], [27, 37]], "w")
	poly([[37, 27], [47, 15], [61, tip], [58, 35], [53, 33], [49, 40], [43, 36], [36, 42]], "o")
	poly([[38, 28], [47, 18], [58, tip + 3], [56, 31], [51, 30], [48, 36], [43, 33], [37, 37]], "v")
	poly([[17, 20], [24, 27], [27, 36], [25, 33]], "x")
	poly([[47, 20], [40, 27], [37, 36], [39, 33]], "w")
	poly([[23, 29], [24, 17], [30, 23], [35, 23], [41, 17], [42, 29], [38, 42], [26, 42]], "o")
	box(27, 27, 11, 11, "3")
	box(28, 25, 8, 3, "4")
	eye(28, 29, false, 2)
	eye(35, 29, false, 2)
	box(31, 36, 3, 2, "7")
	box(29, 43, 2, 3, "r")
	box(35, 43, 2, 3, "r")
	return ink

func wood(x: int, y: int, w: int, h: int) -> void:
	box(x, y, w, h, "o")
	box(x + 2, y + 2, w - 4, h - 4, "q")
	box(x + 2, y + 2, w - 4, 2, "s")
	box(x + 3, y + 5, w - 6, 1, "r")

func furniture(kind: String, pose: int) -> Image:
	if kind == "desk_lantern": return lantern(pose)
	canvas(64, 40 if kind == "table" else (8 if kind == "cottage_rug" else 64))
	match kind:
		"table":
			wood(3, 8, 58, 8)
			wood(9, 15, 6, 25)
			wood(49, 15, 6, 25)
			wood(13, 29, 37, 5)
			box(30, 8, 22, 3, "5")
			box(36, 4, 12, 4, "o")
			box(38, 5, 8, 2, "r")
			box(39, 3, 4, 2, "g")
			box(50, 3, 6, 5, "o")
			box(51, 3, 3, 4, "6")
		"cottage_bookshelf", "cottage_cupboard":
			wood(9, 0, 46, 64)
			box(13, 5, 38, 52, "h")
			for y in [20, 37, 55]:
				wood(12, y, 40, 4)
			for i in 6:
				box(16 + i * 5, 8 + i % 3, 4, 12 - i % 3, ["3", "w", "r", "u", "5", "q"][i])
				box(17 + i * 5, 10 + i % 3, 2, 1, "g")
			if kind == "cottage_cupboard":
				wood(13, 27, 18, 29)
				wood(33, 27, 18, 29)
				box(27, 40, 2, 3, "a")
				box(35, 40, 2, 3, "a")
			else:
				wood(19, 26, 13, 11)
				box(22, 29, 7, 5, "3")
				box(24, 30, 3, 3, "7")
				box(38, 28, 9, 8, "u")
				box(40, 25, 2, 4, "y")
				for i in 5:
					box(16 + i * 6, 43, 5, 12, ["r", "3", "q", "u", "w"][i])
			box(12, 58, 6, 6, "h")
			box(46, 58, 6, 6, "h")
		"cottage_window":
			wood(9, 4, 46, 54)
			box(13, 8, 38, 44, "1")
			box(17, 13, 30, 36, "2")
			box(40, 16, 2, 2, "7")
			box(22, 26, 1, 1, "8")
			box(30, 8, 4, 43, "q")
			box(13, 30, 38, 3, "q")
			poly([[11, 6], [22, 6], [18, 25], [17, 48], [11, 52]], "v")
			poly([[43, 6], [53, 6], [53, 52], [46, 48], [47, 24]], "w")
			box(12, 25, 7, 2, "g")
			box(46, 25, 7, 2, "g")
			wood(6, 54, 52, 6)
		"cottage_rug":
			box(0, 2, 64, 4, "q")
			box(3, 2, 58, 1, "g")
			box(3, 5, 58, 1, "g")
			for x in range(5, 60, 6): box(x, 3, 3, 2, "w")
		"hearth":
			box(5, 1, 54, 63, "o")
			box(9, 6, 46, 52, "3")
			for y in range(8, 55, 8):
				box(9, y, 46, 1, "2")
				for x in range(12 + (y % 16), 55, 16): box(x, y, 1, 8, "2")
			poly([[18, 58], [18, 36], [24, 29], [40, 29], [46, 36], [46, 58]], "o")
			box(21, 38, 22, 18, "h")
			poly([[23, 55], [25, 43], [29, 46], [33 + pose, 35], [35, 47], [40, 42], [41, 55]], "g")
			poly([[27, 54], [29, 47], [31, 49], [34, 42 + pose], [38, 54]], "a")
			box(32, 49, 3, 5, "e")
			wood(2, 20, 60, 8)
			box(2, 59, 60, 5, "2")
			box(5, 59, 54, 1, "5")
			box(12, 10, 7, 10, "q")
			box(13, 9, 5, 2, "g")
			box(45, 12, 6, 8, "5")
	return ink

func bed(pose: int) -> Image:
	canvas()
	wood(1, 12, 8, 52)
	wood(54, 30, 8, 34)
	wood(7, 52, 49, 7)
	box(10, 35, 43, 17, "v")
	box(12, 32 - pose, 40, 16, "w")
	box(12, 33 - pose, 39, 2, "x")
	box(11, 32, 13, 7, "5")
	box(16, 28, 11, 8, "h")
	box(18, 30, 6, 5, "f")
	eye(21, 32, true, 2)
	for x in [29, 39, 49]: box(x, 38, 2, 8, "v")
	return ink

func save_strip(path: String, poses: Array[Image], label: String) -> void:
	var first := poses[0]
	var strip := Image.create(first.get_width() * poses.size(), first.get_height(), false, Image.FORMAT_RGBA8)
	for i in poses.size():
		strip.blit_rect(poses[i], Rect2i(Vector2i.ZERO, poses[i].get_size()), Vector2i(i * first.get_width(), 0))
	var disk_path := ProjectSettings.globalize_path(path)
	var existing := Image.load_from_file(disk_path) if FileAccess.file_exists(path) else null
	# Unchanged files must not provoke the editor's live import watcher.
	if existing == null or existing.get_data() != strip.get_data():
		var error := strip.save_png(disk_path)
		if error != OK:
			save_errors += 1
			push_error("Cannot save %s: %s" % [path, error_string(error)])
	previews.append(first)
	labels.append(label)
