extends SceneTree

## Makes the pixel sprite for the Choir's waymarks (scripts/puzzle/waymark.gd):
## a small carved stone slab with a glowing arrow, the way the monks marked the
## path for novices. Three frames (the glow breathing), drawn at 1x in the
## packs' palette and saved as a PNG strip in res://assets/sprites/story/
## (SurfaceArt.STRIPS lists its frame count). Re-run after editing:
##   godot --headless --path . --script res://tools/generate_waymark_sprites.gd

const OUT := "res://assets/sprites/story/waymark.png"
const PAL := {
	"o": "0b0d20", "2": "1c2149", "3": "2d325c", "4": "3a3f72", "5": "545b86", "6": "6b73aa",
	"b": "2b6fd6", "c": "4aa8ff", "d": "a9d4ff", "9": "dde4fa",
}
## The arrow, pointing right: "c" is its edge, "d" its core.
const ARROW := [
	"......cc.....",
	"......cdc....",
	"ccccccccdc...",
	"cddddddddddc.",
	"ccccccccdc...",
	"......cdc....",
	"......cc.....",
]
## Edge and core colours for the three frames of the glow.
const GLOW := [["b", "c"], ["c", "d"], ["d", "9"]]
const W := 22
const H := 15

var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	var strip := Image.create(W * GLOW.size(), H, false, Image.FORMAT_RGBA8)
	for f in GLOW.size():
		strip.blit_rect(_frame(GLOW[f][0], GLOW[f][1]), Rect2i(0, 0, W, H), Vector2i(f * W, 0))
	strip.save_png(ProjectSettings.globalize_path(OUT))
	print("WAYMARK SPRITE DONE: %d frames of %dx%d" % [GLOW.size(), W, H])
	quit()


func _col(ch: String) -> Color:
	return Color(PAL[ch])


func _frame(edge: String, core: String) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	# the slab: outline, a lit top and left edge, a dark bottom and right edge
	img.fill_rect(Rect2i(0, 0, W, H), _col("o"))
	img.fill_rect(Rect2i(1, 1, W - 2, H - 2), _col("4"))
	img.fill_rect(Rect2i(1, 1, W - 2, 1), _col("6"))
	img.fill_rect(Rect2i(1, 1, 1, H - 2), _col("6"))
	img.fill_rect(Rect2i(W - 3, 2, 2, H - 3), _col("3"))
	img.fill_rect(Rect2i(1, H - 2, W - 2, 1), _col("2"))
	# the carved hollow the arrow sits in
	img.fill_rect(Rect2i(3, 3, W - 6, H - 6), _col("2"))
	# chisel marks in the corners
	for p in [Vector2i(2, 2), Vector2i(W - 3, 2), Vector2i(2, H - 3), Vector2i(W - 3, H - 3)]:
		img.set_pixel(p.x, p.y, _col("5"))
	for r in ARROW.size():
		var row: String = ARROW[r]
		for c in row.length():
			if row[c] != ".":
				img.set_pixel(4 + c, 4 + r, _col(edge if row[c] == "c" else core))
	return img
