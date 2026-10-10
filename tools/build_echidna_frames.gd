extends SceneTree

## Echidna's sprite pipeline. Slices her sheets into clean clips on one
## uniform canvas with a bottom-centre pivot, folds duplicated frames into
## per-frame timing, and writes res://assets/sprites/Echidna/echidna_frames.tres.
## The art is never redrawn: every pixel comes from the original sheets.
##
##   godot --headless --path . --script res://tools/build_echidna_frames.gd
##
## Step 1 also extracts the electric wisps of EchidnaHoldJump.png into their
## own sheet (EchidnaChargeWisps.png: the hold-jump pixels that differ from
## the plain charge pose). If that file is new, import it (open the editor, or
## `godot --headless --path . --import`) and run the tool again.
##
## Timing is in 60 Hz ticks (the clips play at 60 fps; a frame's duration is
## its tick count), tuned for a snappy, readable feel: quick blinks and
## transitions, short holds on key poses, fast recoveries.

const DIR := "res://assets/sprites/Echidna/"
const OUT := DIR + "echidna_frames.tres"
const WISPS := "EchidnaChargeWisps.png"
const CELL := 64
## Every frame is placed on this canvas...
const CANVAS := Vector2i(80, 80)
## ...with the character's contact point here: centred, on the bottom edge
## of this pixel row. The AnimatedSprite2D offset below puts it at the node.
const PIVOT := Vector2i(40, 71)

## align "feet": centre of the feet and hem (bottom 6 rows) over the ground
## frames. align "head": line the eyes of `ground` frames up with the eyes
## of the reference sheet's feet pivot (for poses whose cape flares sideways).
const SHEETS := {
	&"idle": {"file": "EchidnaIdle.png", "ground": [], "align": "feet"},
	&"walk": {"file": "EchidnaWalk.png", "ground": [], "align": "feet"},
	&"charge": {"file": "EchidnaCharge.png", "ground": [], "align": "feet"},
	&"wisps": {"file": WISPS, "pivot_of": &"charge"},
	&"air": {"file": "EchidnaAir.png", "ground": [0, 1], "align": "head", "reference": &"idle"},
}

## name: [sheet, loop, [[source frame, ticks], ...]]
const CLIPS := {
	# Breathing with eased holds, and a quick blink (frames 5-8)
	&"idle": [&"idle", true, [[0, 10], [1, 7], [2, 9], [1, 6], [4, 8], [5, 3], [6, 2], [7, 4], [8, 3],
		[2, 8], [10, 12], [4, 8], [13, 16], [16, 12]]],
	# Stride (lean) - pass - stride (wide) - pass: strides held, passes quick
	&"run": [&"walk", true, [[0, 7], [2, 5], [4, 7], [2, 5]]],
	&"sprint": [&"walk", true, [[0, 5], [2, 3], [4, 5], [2, 3]]],
	# Fast recovery out of a stride into the idle stance
	&"run_stop": [&"walk", false, [[2, 4], [0, 1]]],
	# Anticipation before the charge pose
	&"crouch": [&"air", false, [[0, 5]]],
	# Landing: one short squash frame, then straight back to control
	&"land": [&"air", false, [[0, 4]]],
	&"jump": [&"air", false, [[2, 8]]],
	&"apex": [&"air", false, [[4, 5], [6, 6]]],
	&"fall": [&"air", true, [[6, 8], [4, 7], [10, 9]]],
	&"JumpCharge": [&"charge", true, [[0, 5], [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5], [8, 5], [9, 5]]],
	&"JumpChargeWisps": [&"wisps", true, [[0, 5], [1, 5], [2, 5], [3, 5], [4, 5], [5, 5], [6, 5], [7, 5], [8, 5], [9, 5]]],
}

## Clip frames where a foot plants: footstep sound and dust puff.
const FOOTSTEPS := {&"run": [0, 2], &"sprint": [0, 2]}

var _started := false
var _images := {}
var _pivots := {}


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
		quit()
	return false


func _run() -> void:
	var wisp_path := DIR + WISPS
	if _extract_wisps(wisp_path) or not ResourceLoader.exists(wisp_path):
		print("Wrote %s. Import it (godot --headless --path . --import), then run this tool again." % wisp_path)
		return
	for sheet in SHEETS:
		_images[sheet] = Image.load_from_file(ProjectSettings.globalize_path(DIR + SHEETS[sheet]["file"]))
	for sheet in SHEETS:
		if not SHEETS[sheet].has("pivot_of"):
			_pivots[sheet] = _pivot_for(sheet)
	for sheet in SHEETS:
		if SHEETS[sheet].has("pivot_of"):
			_pivots[sheet] = _pivots[SHEETS[sheet]["pivot_of"]]
		print("pivot %-7s %s" % [sheet, _pivots[sheet]])

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var atlases := {}
	for clip in CLIPS:
		var spec: Array = CLIPS[clip]
		var sheet: StringName = spec[0]
		frames.add_animation(clip)
		frames.set_animation_loop(clip, spec[1])
		frames.set_animation_speed(clip, 60.0)
		for entry in spec[2]:
			var key := "%s:%d" % [sheet, entry[0]]
			if not atlases.has(key):
				atlases[key] = _frame_texture(sheet, entry[0])
			frames.add_frame(clip, atlases[key], float(entry[1]))
	# New hand-drawn 64px pushing poses on the same 80px output canvas.
	frames.add_animation(&"push")
	frames.set_animation_loop(&"push", true)
	frames.set_animation_speed(&"push", 6.0)
	for i in 4:
		var push_texture := AtlasTexture.new()
		push_texture.atlas = load(DIR + "EchidnaPush.png")
		push_texture.region = Rect2(i * 64, 0, 64, 64)
		push_texture.margin = Rect2(8, 8, 16, 16)
		push_texture.filter_clip = true
		frames.add_frame(&"push", push_texture)
	frames.set_meta(&"sprite_offset", Vector2(CANVAS.x / 2.0 - PIVOT.x, CANVAS.y / 2.0 - (PIVOT.y + 1)))
	frames.set_meta(&"footsteps", FOOTSTEPS)
	frames.set_meta(&"pivots", _pivots)
	var err := ResourceSaver.save(frames, OUT)
	print("saved %s (%d clips, %d unique frames): %s" % [OUT, CLIPS.size(), atlases.size(), error_string(err)])


# ---------------------------------------------------------------- wisps

## Writes the wisp layer if it is missing or out of date; true if written.
func _extract_wisps(path: String) -> bool:
	var hold := Image.load_from_file(ProjectSettings.globalize_path(DIR + "EchidnaHoldJump.png"))
	var body := Image.load_from_file(ProjectSettings.globalize_path(DIR + "EchidnaCharge.png"))
	hold.convert(Image.FORMAT_RGBA8)
	body.convert(Image.FORMAT_RGBA8)
	var wisps := Image.create(hold.get_width(), hold.get_height(), false, Image.FORMAT_RGBA8)
	for y in hold.get_height():
		for x in hold.get_width():
			var h := hold.get_pixel(x, y)
			if h.a > 0.0 and not h.is_equal_approx(body.get_pixel(x, y)):
				wisps.set_pixel(x, y, h)
	var existing := Image.load_from_file(ProjectSettings.globalize_path(path)) if FileAccess.file_exists(path) else null
	if existing:
		existing.convert(Image.FORMAT_RGBA8)
		if existing.get_data() == wisps.get_data():
			return false
	wisps.save_png(ProjectSettings.globalize_path(path))
	return true


# ---------------------------------------------------------------- pivots

func _frame(sheet: StringName, index: int) -> Image:
	var img: Image = _images[sheet]
	var per_row := img.get_width() / CELL
	return img.get_region(Rect2i((index % per_row) * CELL, (index / per_row) * CELL, CELL, CELL))


func _frame_count(sheet: StringName) -> int:
	var img: Image = _images[sheet]
	var count := 0
	for i in (img.get_width() / CELL) * (img.get_height() / CELL):
		if _frame(sheet, i).get_used_rect().size.x > 0:
			count = i + 1
	return count


func _ground_frames(sheet: StringName) -> Array:
	var listed: Array = SHEETS[sheet].get("ground", [])
	return listed if not listed.is_empty() else range(_frame_count(sheet))


func _feet(img: Image) -> Vector2:
	var bottom := img.get_used_rect().end.y - 1
	var sum := 0.0
	var count := 0
	for y in range(bottom - 5, bottom + 1):
		for x in CELL:
			if img.get_pixel(x, y).a > 0.5:
				sum += x
				count += 1
	return Vector2(sum / maxf(count, 1), bottom)


## Centre of the eyes (the only near-white pixels), or null with eyes shut.
func _eyes(img: Image) -> Variant:
	var sum := Vector2.ZERO
	var count := 0
	for y in CELL:
		for x in CELL:
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and c.r > 0.8 and c.g > 0.8 and c.b > 0.8:
				sum += Vector2(x, y)
				count += 1
	return sum / count if count >= 8 else null


func _median(values: Array) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]


func _pivot_for(sheet: StringName) -> Vector2i:
	var xs := []
	var bottoms := []
	var eyes := []
	for i in _ground_frames(sheet):
		var img := _frame(sheet, i)
		var feet := _feet(img)
		xs.append(feet.x)
		bottoms.append(feet.y)
		var e: Variant = _eyes(img)
		if e != null:
			eyes.append(e.x)
	var bottom := int(bottoms.max())
	if SHEETS[sheet]["align"] == "head":
		# Keep the head where the reference sheet's head sits over its feet
		var ref: StringName = SHEETS[sheet]["reference"]
		var ref_eyes := []
		for i in _ground_frames(ref):
			var e: Variant = _eyes(_frame(ref, i))
			if e != null:
				ref_eyes.append(e.x)
		var ref_pivot: Vector2i = _pivots[ref]
		var head_over_feet := _median(ref_eyes) - ref_pivot.x
		return Vector2i(roundi(_median(eyes) - head_over_feet), bottom)
	return Vector2i(roundi(_median(xs)), bottom)


# ---------------------------------------------------------------- textures

func _frame_texture(sheet: StringName, index: int) -> AtlasTexture:
	var img: Image = _images[sheet]
	var per_row := img.get_width() / CELL
	var origin := Vector2i((index % per_row) * CELL, (index / per_row) * CELL)
	var used := _frame(sheet, index).get_used_rect()
	var shift: Vector2i = PIVOT - _pivots[sheet]
	var dest := used.position + shift
	if dest.x < 0 or dest.y < 0 or dest.x + used.size.x > CANVAS.x or dest.y + used.size.y > CANVAS.y:
		push_error("%s frame %d does not fit the canvas" % [sheet, index])
	var tex := AtlasTexture.new()
	tex.atlas = load(DIR + SHEETS[sheet]["file"])
	tex.region = Rect2(Vector2(origin + used.position), Vector2(used.size))
	tex.margin = Rect2(Vector2(dest), Vector2(CANVAS - used.size))
	tex.filter_clip = true
	return tex
