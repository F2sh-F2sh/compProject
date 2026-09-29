class_name RuneBook
extends RefCounted

## What every supported rune does. Each essence + form pair lists the
## directions and modifiers it accepts; anything else is refused with a
## reason (and costs nothing). spell() turns a valid recipe into concrete
## numbers (force, reach, width, costs...), and describe() writes the text
## the player reads, from those same numbers.
##
## Modifier meanings, the same everywhere: Strong = twice the magnitude;
## Long = more reach or range (not more time); Large = a wider area;
## Persist = a normally temporary effect held while the cube is on, with
## upkeep; Delay = happens 2 s after activation; Repeat = happens every few
## seconds while on; Bounce = reflects from mirrors; Split = three at once;
## Explode = a small blast where it lands.
##
## Kinds of spell and when mana is charged:
##   SUSTAINED  upkeep per second while on (a start cost too for some)
##   ONCE       a single effect; charged when it happens (Delay: when it fires)
##   TIMED      lasts a set time; charged once, at activation
##   REPEAT     charged each time it fires; stops if a charge can't be paid

enum Kind { SUSTAINED, ONCE, TIMED, REPEAT }

const EIGHT := [&"right", &"left", &"up", &"down", &"up_right", &"up_left", &"down_right", &"down_left"]
const SIDEWAYS_AND_DIAGONAL := [&"right", &"left", &"up_right", &"up_left", &"down_right", &"down_left"]

## "essence/form": [allowed directions, allowed modifiers]
const SUPPORTED := {
	"wind/push": [SIDEWAYS_AND_DIAGONAL, [&"normal", &"strong", &"long", &"large"]],
	"wind/lift": [[&"up"], [&"normal", &"strong", &"long", &"large"]],
	"wind/burst": [EIGHT + [&"self"], [&"normal", &"strong", &"large", &"delay", &"repeat"]],
	"fire/projectile": [EIGHT, [&"normal", &"explode", &"split", &"delay", &"repeat"]],
	"ice/freeze": [EIGHT + [&"self"], [&"normal", &"long", &"large", &"persist"]],
	"ice/bridge": [[&"right", &"left"], [&"normal", &"long", &"persist"]],
	"light/beam": [EIGHT, [&"normal", &"long", &"bounce"]],
	"light/glow": [[&"self"], [&"normal", &"large"]],
	"space/portal": [EIGHT, [&"normal", &"long"]],
}

## Tuning (all in one place; see docs/RUNE_SYSTEM_PROGRESS.md)
const WIND_FORCE := 1200.0         # enough for a crate, not for a stone block
const WIND_REACH := 320.0
const WIND_WIDTH := 96.0
const BURST_IMPULSE := 420.0       # velocity change for a mass-1 object
const FREEZE_TIME := 6.0
const BRIDGE_SPAN := 224.0
const BRIDGE_TIME := 10.0
const BEAM_RANGE := 900.0
const GLOW_RADIUS := 104.0
const PORTAL_RANGE := 224.0
const DELAY := 2.0
## A sustained rune only starts with this many seconds of upkeep in hand.
const START_SECONDS := 2.0


## null if valid, otherwise the reason it can't be cast.
static func problem(r: RuneRecipe) -> String:
	if r == null:
		return "There is no rune."
	var missing := PackedStringArray()
	for kind in 4:
		if r.get_slot(kind) == &"":
			missing.append(RuneFragments.KIND_NAMES[kind].to_lower())
	if not missing.is_empty():
		return "The rune is broken: it needs a %s fragment." % " and a ".join(missing)
	var key := "%s/%s" % [r.essence, r.form]
	if not SUPPORTED.has(key):
		var forms := PackedStringArray()
		for k in SUPPORTED:
			if k.begins_with(String(r.essence) + "/"):
				forms.append(RuneFragments.name_of(StringName(k.get_slice("/", 1))))
		return "%s can't take the form %s. %s magic can: %s." % [RuneFragments.name_of(r.essence),
			RuneFragments.name_of(r.form), RuneFragments.name_of(r.essence), ", ".join(forms)]
	var spec: Array = SUPPORTED[key]
	if not spec[0].has(r.direction):
		return "%s %s can't point %s. It can go: %s." % [RuneFragments.name_of(r.essence), RuneFragments.name_of(r.form),
			RuneFragments.name_of(r.direction), _names(spec[0])]
	if not spec[1].has(r.modifier):
		return "%s %s can't be %s. It can be: %s." % [RuneFragments.name_of(r.essence), RuneFragments.name_of(r.form),
			RuneFragments.name_of(r.modifier), _names(spec[1])]
	return ""


static func is_valid(r: RuneRecipe) -> bool:
	return problem(r) == ""


static func _names(ids: Array) -> String:
	var out := PackedStringArray()
	for id in ids:
		out.append(RuneFragments.name_of(id))
	return ", ".join(out)


## Everything the effect needs, computed from the fragments. Call only on a
## valid recipe.
static func spell(r: RuneRecipe) -> Dictionary:
	var m := r.modifier
	var s := {
		"key": "%s/%s" % [r.essence, r.form],
		"direction": RuneFragments.direction_vector(r.direction),
		"kind": Kind.SUSTAINED,
		"start_cost": 0,
		"upkeep": 0.0,
		"repeat_cost": 0,
		"repeat_every": 0.0,
		"delay": DELAY if m == &"delay" else 0.0,
		"duration": 0.0,
	}
	match s["key"]:
		"wind/push", "wind/lift":
			s["force"] = WIND_FORCE * (2.0 if m == &"strong" else 1.0)
			s["reach"] = WIND_REACH * (1.75 if m == &"long" else 1.0)
			s["width"] = WIND_WIDTH * (3.0 if m == &"large" else 1.0)
			s["upkeep"] = {&"normal": 3.0, &"strong": 8.0, &"long": 4.0, &"large": 5.0}[m]
		"wind/burst":
			s["kind"] = Kind.REPEAT if m == &"repeat" else Kind.ONCE
			s["impulse"] = BURST_IMPULSE * (2.0 if m == &"strong" else 1.0)
			s["reach"] = WIND_REACH * 0.8
			s["width"] = WIND_WIDTH * (3.0 if m == &"large" else 1.0)
			s["start_cost"] = 8 if m == &"strong" else 5
			s["repeat_cost"] = s["start_cost"]
			s["repeat_every"] = 2.5
		"fire/projectile":
			s["kind"] = Kind.REPEAT if m == &"repeat" else Kind.ONCE
			s["start_cost"] = 8 if m in [&"explode", &"split"] else 5
			s["repeat_cost"] = s["start_cost"]
			s["repeat_every"] = 1.6
			s["count"] = 3 if m == &"split" else 1
			s["explode_radius"] = 56.0 if m == &"explode" else 0.0
		"ice/freeze":
			s["kind"] = Kind.SUSTAINED if m == &"persist" else Kind.TIMED
			s["reach"] = 160.0 * (1.9 if m == &"long" else 1.0)
			s["width"] = WIND_WIDTH * (2.4 if m == &"large" else 1.0)
			s["duration"] = FREEZE_TIME
			s["start_cost"] = 0 if m == &"persist" else 8
			s["upkeep"] = 4.0 if m == &"persist" else 0.0
		"ice/bridge":
			s["kind"] = Kind.SUSTAINED if m == &"persist" else Kind.TIMED
			s["span"] = BRIDGE_SPAN * (1.7 if m == &"long" else 1.0)
			s["duration"] = BRIDGE_TIME
			s["start_cost"] = 0 if m == &"persist" else 12
			s["upkeep"] = 5.0 if m == &"persist" else 0.0
		"light/beam":
			s["range"] = BEAM_RANGE * (1.8 if m == &"long" else 1.0)
			s["bounces"] = 6 if m == &"bounce" else 0
			s["upkeep"] = 3.0 if m == &"bounce" else 2.0
		"light/glow":
			s["radius"] = GLOW_RADIUS * (1.7 if m == &"large" else 1.0)
			s["upkeep"] = 3.0 if m == &"large" else 2.0
		"space/portal":
			s["range"] = PORTAL_RANGE * (1.6 if m == &"long" else 1.0)
			s["start_cost"] = 10
			s["upkeep"] = 8.0
	return s


## "rightward", "up and to the left", "around the cube".
static func direction_words(d: StringName) -> String:
	match d:
		&"right": return "rightward"
		&"left": return "leftward"
		&"up": return "upward"
		&"down": return "downward"
		&"self": return "around the cube"
	return RuneFragments.name_of(d).to_lower().replace("-", " and ") + "ward"


## The rune in plain words: what it does and what it costs.
static func describe(r: RuneRecipe, dungeon_powered := false) -> Dictionary:
	var why := problem(r)
	if why != "":
		return {"title": "An unfinished rune", "effect": why, "cost": "", "valid": false}
	var s := spell(r)
	var dir := direction_words(r.direction)
	var strength := "strong " if r.modifier == &"strong" else ""
	var title := ""
	var effect := ""
	match s["key"]:
		"wind/push":
			title = "%s%s wind" % [strength.capitalize(), dir]
			effect = "Pushes loose objects and creatures inside the marked area (%d px long, %d px wide)." % [s["reach"], s["width"]]
		"wind/lift":
			title = "%supward current" % strength.capitalize()
			effect = "Lifts light objects inside the marked column (%d px high, %d px wide). Heavy stone stays put." % [s["reach"], s["width"]]
		"wind/burst":
			title = "%s%s gust" % [strength.capitalize(), dir if r.direction != &"self" else "outward"]
			effect = "A single shove to loose objects in the marked area."
			if r.modifier == &"repeat":
				effect = "A shove every %.1f seconds while the cube is on." % s["repeat_every"]
			elif r.modifier == &"delay":
				effect = "A single shove, %d seconds after the cube is switched on." % s["delay"]
		"fire/projectile":
			title = "%s fireball" % dir.capitalize()
			effect = "Lights braziers, burns vines and melts marked ice."
			if s["count"] > 1:
				effect = "Three fireballs in a fan. " + effect
			if s["explode_radius"] > 0.0:
				effect += " Bursts where it lands, reaching anything nearby that it can see."
			if r.modifier == &"repeat":
				effect += " Fires every %.1f seconds while on." % s["repeat_every"]
			elif r.modifier == &"delay":
				effect += " Fires %d seconds after activation." % s["delay"]
		"ice/freeze":
			title = "%s chill" % dir.capitalize()
			effect = "Freezes creatures in the marked area"
			effect += " for as long as the cube is on." if r.modifier == &"persist" else " for %d seconds." % s["duration"]
		"ice/bridge":
			title = "%s ice bridge" % dir.capitalize()
			effect = "A bridge of solid ice up to %d px long, level with the cube's top" % s["span"]
			effect += ", held while the cube is on." if r.modifier == &"persist" else ", melting after %d seconds." % s["duration"]
		"light/beam":
			title = "%s beam of light" % dir.capitalize()
			effect = "Powers crystals and stills watchers it touches."
			effect += " Reflects from mirrors." if s["bounces"] > 0 else " Stops at mirrors."
		"light/glow":
			title = "Pool of light"
			effect = "Lights everything within %d px of the cube that it can see." % s["radius"]
		"space/portal":
			title = "%s portal" % dir.capitalize()
			effect = "Links the cube's doorway to a spot %d px %s. Carries you and loose objects." % [s["range"], dir]
	title = title.substr(0, 1).to_upper() + title.substr(1)
	return {"title": title, "effect": effect, "cost": cost_text(s, dungeon_powered), "valid": true}


static func cost_text(s: Dictionary, dungeon_powered := false) -> String:
	if dungeon_powered:
		return "Powered by the dungeon: costs you nothing."
	var parts := PackedStringArray()
	if s["start_cost"] > 0 and s["kind"] != Kind.REPEAT:
		parts.append("%d mana to cast" % s["start_cost"])
	if s["upkeep"] > 0.0:
		var hold := int(s["start_cost"]) + ceili(s["upkeep"] * START_SECONDS) if s["kind"] == Kind.SUSTAINED else 0
		parts.append("%s mana per second while on" % _num(s["upkeep"]) + (" (needs %d in hand to start)" % hold if hold > 0 else ""))
	if s["kind"] == Kind.REPEAT:
		parts.append("%d mana each time it fires" % s["repeat_cost"])
	if parts.is_empty():
		return "Costs no mana."
	return "Costs " + ", then ".join(parts) + "."


static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v
