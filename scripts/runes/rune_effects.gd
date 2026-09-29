class_name RuneEffects
extends RefCounted

## Makes the effect node for a spell (see RuneBook.spell). Sustained effects
## live as a child of their cube and stop when it switches off; one-off
## effects (a gust, a fireball) play out on their own.

const BUILT := ["wind/push", "wind/lift", "wind/burst", "fire/projectile", "ice/freeze", "ice/bridge",
	"light/beam", "light/glow", "space/portal"]


static func is_built(key: String) -> bool:
	return BUILT.has(key)


## "" if the spell can start from where the cube is, otherwise why not
## (checked before any mana is taken).
static func problem(cube: RuneCube, spell: Dictionary) -> String:
	match spell["key"]:
		"space/portal":
			return RunePortal.problem(cube, spell)
		"ice/bridge":
			if IceBridge.measure(cube, signf((spell["direction"] as Vector2).x), spell["span"]) < 24.0:
				return "There is no room for a bridge on that side."
	return ""


static func create(cube: RuneCube, spell: Dictionary) -> Node:
	var node: Node = null
	match spell["key"]:
		"wind/push", "wind/lift":
			node = WindField.new()
		"wind/burst":
			node = WindBurst.new()
		"fire/projectile":
			node = RuneFire.new()
		"ice/freeze":
			node = FreezeField.new()
		"ice/bridge":
			node = IceBridge.new()
		"light/beam":
			node = RuneBeam.new()
		"light/glow":
			node = RuneGlow.new()
		"space/portal":
			node = RunePortal.new()
	if node == null:
		return null
	node.name = String(spell["key"]).replace("/", "_").to_pascal_case()
	# Bolts outlive their cube's "on" moment, so they live in the room
	var host: Node = cube.get_parent() if spell["key"] == "fire/projectile" else cube
	host.add_child(node)
	node.setup(cube, spell)
	return node
