class_name LightTextures
extends RefCounted

## Shared, cached light textures so every light doesn't build its own.

static var _cache := {}


## Soft round falloff, bright in the centre.
static func radial(size: int) -> Texture2D:
	var key := "radial_%d" % size
	if not _cache.has(key):
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55),
			Color(1, 1, 1, 0.15), Color(1, 1, 1, 0)])
		var tex := GradientTexture2D.new()
		tex.gradient = gradient
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.width = size
		tex.height = size
		_cache[key] = tex
	return _cache[key]


## Even light with no falloff, used to light a sign's plaque evenly.
static func flat(size: int) -> Texture2D:
	var key := "flat_%d" % size
	if not _cache.has(key):
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color.WHITE, Color.WHITE])
		var tex := GradientTexture2D.new()
		tex.gradient = gradient
		tex.width = size
		tex.height = size
		_cache[key] = tex
	return _cache[key]
