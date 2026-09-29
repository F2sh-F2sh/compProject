class_name RuneJournal
extends RefCounted

## The rune journal (a page of the pause menu): every fragment the player
## knows, with its glyph and meaning; the rules of rune magic she has seen
## for herself (each written down the first time it happens); and every
## rune she has cast, with what it does. All of it is saved (GameState
## flags "rune.frag.<id>", "rune.note.<id>", "rune.cast.<recipe>").

const FONT := preload("res://assets/Text/Orbitron-Bold.ttf")

## id: what she writes down the first time she sees it happen.
const NOTES := {
	"moves": "Wind moves loose things. Light crates slide at once; stone digs in.",
	"strain": "A wind too weak for something heavy only makes it strain and grind.",
	"stack": "Winds that overlap add together. Two gentle winds can shift what one cannot.",
	"mana": "A cube without the dungeon's channel feeds on my own mana for as long as it runs.",
	"exhaust": "When my mana ran dry, every rune I was holding went dark at once.",
	"pedestal": "A pedestal feeds the cube that stands in it. The dungeon pays, not me.",
	"impact": "Something heavy, moving fast, breaks cracked stone.",
	"lift": "Rising air carries me. Jump into it; it will not catch a fall.",
	"bridge": "Ice holds its shape long enough to walk on, then it goes.",
	"light": "Holy light from a rune stills a watcher just as a lamp does.",
	"chill": "Cold holds a creature fast, and a frozen thing is as heavy as stone.",
	"portal": "A portal keeps how you were moving: fall in fast, fly out fast.",
	"fire": "Rune fire is fire: it lights, it burns, it melts.",
}


static func note(id: String) -> void:
	if not GameState.has_flag("rune.note." + id):
		GameState.set_flag("rune.note." + id)


static func note_cast(recipe: RuneRecipe) -> void:
	GameState.set_flag("rune.cast." + recipe.to_key())


## Fills `list` with the journal's three sections.
static func fill(list: VBoxContainer, tree: SceneTree) -> void:
	for child in list.get_children():
		child.queue_free()
	list.add_child(_heading("FRAGMENTS YOU KNOW"))
	for kind in 4:
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 10)
		row.add_theme_constant_override("v_separation", 6)
		var any := false
		for id in RuneFragments.of_kind(kind):
			if RuneManager.knows(id, tree):
				row.add_child(_fragment(id, kind))
				any = true
		if any:
			list.add_child(_label(RuneFragments.KIND_NAMES[kind], 12, Color("a99ccf")))
			list.add_child(row)
	list.add_child(_heading("WHAT YOU HAVE SEEN"))
	var notes := 0
	for id in NOTES:
		if GameState.has_flag("rune.note." + id):
			var l := _label("·  " + NOTES[id], 13, Color("e4ddf2"))
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(520, 0)
			list.add_child(l)
			notes += 1
	if notes == 0:
		list.add_child(_label("Nothing yet. Try a cube.", 13, Color("9d93b8")))
	list.add_child(_heading("RUNES YOU HAVE CAST"))
	var cast := 0
	for key in GameState.flags:
		if String(key).begins_with("rune.cast."):
			var recipe := RuneRecipe.from_key(String(key).trim_prefix("rune.cast."))
			if RuneBook.is_valid(recipe):
				var d := RuneBook.describe(recipe)
				var parts := PackedStringArray()
				for kind in 4:
					parts.append(RuneFragments.name_of(recipe.get_slot(kind)))
				var l := _label("%s  ·  %s" % [" / ".join(parts), d["title"]], 13, Color("a8e0ff"))
				list.add_child(l)
				cast += 1
	if cast == 0:
		list.add_child(_label("None yet.", 13, Color("9d93b8")))


static func _fragment(id: StringName, kind: int) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.tooltip_text = RuneFragments.meaning_of(id)
	var glyph := Control.new()
	glyph.custom_minimum_size = Vector2(26, 26)
	glyph.draw.connect(func():
		var col := RuneFragments.essence_color(id) if kind == RuneFragments.Kind.ESSENCE else RuneFragments.NEUTRAL
		RuneFragments.draw_glyph(glyph, id, Vector2(13, 13), 22.0, col, 1.5))
	box.add_child(glyph)
	box.add_child(_label(RuneFragments.name_of(id), 13, Color("e4ddf2")))
	return box


static func _heading(text: String) -> Label:
	return _label(text, 14, Color("cbbdf2"))


static func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
