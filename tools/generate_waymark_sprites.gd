extends SceneTree

## Makes the pixel sprite for the waymarks (scripts/puzzle/waymark.gd): an
## arrow drawn in chalk straight on the wall, the way Wren marks the way on for
## whoever comes after her (her chalk steps and stars are in the same chalk).
## No slab and no glow of its own, so it reads as part of the wall. Three
## frames, a few grains of chalk dust catching the light differently in each.
## Drawn at 1x and saved as a PNG strip in res://assets/sprites/story/
## (SurfaceArt.STRIPS lists its frame count). Re-run after editing:
##   godot --headless --path . --script res://tools/generate_waymark_sprites.gd

const OUT := "res://assets/sprites/story/waymark.png"
## Chalk, as in tools/generate_kiln_sprites.gd: dust, a worn stroke, a fresh one.
const CHALK := ["8890b0", "b8c0d8", "e4e8f4"]
## The arrow, pointing right, as two quick strokes: "#" the line, "." bare wall.
const ARROW := [
	"..............##........",
	"...............##.......",
	"................##......",
	".................##.....",
	"..................##....",
	"###.###############.#...",
	".##############.#####...",
	"..................##....",
	".................##.....",
	"................##......",
	"...............##.......",
	"..............##........",
]
const W := 24
const H := 12
const FRAMES := 3

var _started := false
var rng := RandomNumberGenerator.new()


func _process(_delta: float) -> bool:
	if not _started:
		_started = true
		_run()
	return false


func _run() -> void:
	rng.seed = 5113
	var strip := Image.create(W * FRAMES, H, false, Image.FORMAT_RGBA8)
	var stroke := _stroke_shades()
	for f in FRAMES:
		strip.blit_rect(_frame(stroke, f), Rect2i(0, 0, W, H), Vector2i(f * W, 0))
	strip.save_png(ProjectSettings.globalize_path(OUT))
	print("WAYMARK SPRITE DONE: %d frames of %dx%d" % [FRAMES, W, H])
	quit()


# One fixed shading for the strokes (worn here, fresh there), the same in
# every frame so the arrow itself never flickers
func _stroke_shades() -> Dictionary:
	var shades := {}
	for r in ARROW.size():
		for c in W:
			if ARROW[r][c] == "#":
				shades[Vector2i(c, r)] = 2 if rng.randf() < 0.55 else 1
	return shades


func _frame(stroke: Dictionary, f: int) -> Image:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for p: Vector2i in stroke:
		img.set_pixel(p.x, p.y, Color(CHALK[stroke[p]]))
	# Chalk dust round the strokes: a few grains, different in each frame
	var dust := RandomNumberGenerator.new()
	dust.seed = 77 + f * 13
	for p: Vector2i in stroke:
		for n in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var q: Vector2i = p + n
			if q.x < 0 or q.y < 0 or q.x >= W or q.y >= H or stroke.has(q):
				continue
			if dust.randf() < 0.07:
				var grain := Color(CHALK[0])
				grain.a = 0.75
				img.set_pixel(q.x, q.y, grain)
	return img
